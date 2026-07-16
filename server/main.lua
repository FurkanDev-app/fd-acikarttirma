-- fd-acikarttirma | server ana mantik: state machine + teklif motoru + escrow
-- Ayni anda tek aktif mezat desteklenir.

local ACCOUNT = Config.Account
local ActiveAuction = nil

-- Disari acilan referanslar (ticket.lua / delivery.lua / logs.lua kullanir)
Mezat = {}

-----------------------------------------------------------------------------
-- YARDIMCILAR
-----------------------------------------------------------------------------
local function isAuctioneer(src)
    local job = Bridge.GetJob(src)
    if not job then return false end
    return Utils.IsAuctioneer(job.name, job.grade)
end

local function playerName(src)
    if not src then return '???' end
    return GetPlayerName(src) or ('ID '..src)
end

function Mezat.GetActive()
    return ActiveAuction
end

function Mezat.IsParticipant(src)
    if not ActiveAuction then return false end
    local cid = Bridge.GetIdentifier(src)
    return cid ~= nil and ActiveAuction.participants[cid] == true
end

function Mezat.CountParticipants()
    if not ActiveAuction then return 0 end
    local n = 0
    for _ in pairs(ActiveAuction.participants) do n = n + 1 end
    return n
end

--- Aktif lot (canli) dondurur
local function currentLot()
    if not ActiveAuction or ActiveAuction.state ~= 'live' then return nil end
    return ActiveAuction.lots[ActiveAuction.currentLotIndex]
end

-----------------------------------------------------------------------------
-- YAYIN (BROADCAST)
-----------------------------------------------------------------------------
local function publicLotView(lot)
    if not lot then return nil end
    return {
        index = lot.index,
        total = #ActiveAuction.lots,
        type = lot.type,
        label = lot.label,
        startPrice = lot.startPrice,
        minIncrement = lot.minIncrement,
        buyout = lot.buyout,
        highBid = lot.highBidder and lot.highBid or 0,
        hasBid = lot.highBidder ~= nil,
        highBidderName = lot.highBidder and playerName(lot.highBidder) or nil,
        timeLeft = lot.endsAt and math.max(0, lot.endsAt - os.time()) or 0,
        running = lot.running == true,
    }
end

local function broadcastLot()
    local lot = currentLot()
    TriggerClientEvent('fd-acikarttirma:client:lotUpdate', -1, publicLotView(lot))
end

local function broadcastState()
    local view = nil
    if ActiveAuction then
        view = {
            id = ActiveAuction.id,
            label = ActiveAuction.label,
            state = ActiveAuction.state,
            fee = ActiveAuction.fee,
            auctioneerId = ActiveAuction.auctioneer,
            participants = Mezat.CountParticipants(),
            lot = publicLotView(currentLot()),
        }
    end
    TriggerClientEvent('fd-acikarttirma:client:auctionState', -1, view)
end

-----------------------------------------------------------------------------
-- TEKLIF MOTORU (klasik + proxy birlesik "max" modeli)
-- Her katilimcinin lot.maxBid[src] = odemeye razi oldugu tavan degeri.
-- Klasik teklif = tam o rakam kadar tavan. Proxy = girilen butce.
-----------------------------------------------------------------------------
local function resolve(lot)
    local inc = lot.minIncrement
    -- Bootstrap: lider yoksa, startPrice'i karsilayan en yuksek tavana sahip kisi lider olur (fiyat = startPrice)
    if not lot.highBidder then
        local bestSrc, bestMax, bestTime
        for s, m in pairs(lot.maxBid) do
            if m >= lot.startPrice then
                if not bestMax or m > bestMax or (m == bestMax and lot.maxTime[s] < bestTime) then
                    bestSrc, bestMax, bestTime = s, m, lot.maxTime[s]
                end
            end
        end
        if not bestSrc then return end
        lot.highBidder = bestSrc
        lot.highBid = lot.startPrice
    end

    -- Yaris cozumu (proxy)
    local guard = 0
    while true do
        guard = guard + 1
        if guard > 128 then break end

        local leader = lot.highBidder
        local leaderMax = lot.maxBid[leader] or 0

        -- Lidere meydan okuyabilecek en yuksek tavan
        local chSrc, chMax, chTime
        for s, m in pairs(lot.maxBid) do
            if s ~= leader and m > lot.highBid then
                if not chMax or m > chMax or (m == chMax and lot.maxTime[s] < chTime) then
                    chSrc, chMax, chTime = s, m, lot.maxTime[s]
                end
            end
        end

        if not chSrc then break end
        local required = lot.highBid + inc

        if chMax > leaderMax then
            -- Meydan okuyan kazanir, fiyat = min(kendi tavani, liderin tavani + inc)
            lot.highBidder = chSrc
            lot.highBid = math.min(chMax, leaderMax + inc)
        elseif chMax == leaderMax then
            -- Beraberlik: once teklif veren lider kalir, fiyat tavana ciyar
            if lot.maxTime[chSrc] < lot.maxTime[leader] then
                lot.highBidder = chSrc
            end
            lot.highBid = leaderMax
            break
        else
            -- Meydan okuyan tavani liderden dusuk: lider kalir, fiyat = min(liderTavan, chMax + inc)
            if chMax >= required then
                lot.highBid = math.min(leaderMax, chMax + inc)
            end
            break
        end
    end
end

--- resolve sonrasi parayi lider uzerinde bloke et; odeyemeyeni ele; stabil olana kadar done.
local function reconcile(lot)
    local guard = 0
    while true do
        guard = guard + 1
        if guard > 64 then break end

        resolve(lot)
        local newSrc, newAmt = lot.highBidder, lot.highBid

        if not newSrc then
            if lot.blockedSrc then
                Bridge.AddMoney(lot.blockedSrc, ACCOUNT, lot.blockedAmount, 'mezat-iade')
                lot.blockedSrc, lot.blockedAmount = nil, 0
            end
            return
        end

        if lot.blockedSrc == newSrc then
            local delta = newAmt - lot.blockedAmount
            if delta == 0 then return end
            if delta > 0 then
                if Bridge.RemoveMoney(newSrc, ACCOUNT, delta, 'mezat-teklif') then
                    lot.blockedAmount = newAmt
                    return
                else
                    -- artik odeyemiyor: bloke edileni iade et, ele, yeniden coz
                    Bridge.AddMoney(newSrc, ACCOUNT, lot.blockedAmount, 'mezat-iade')
                    Bridge.Notify(newSrc, locale('bid_insolvent'), 'error')
                    lot.maxBid[newSrc] = nil
                    lot.highBidder = nil
                    lot.blockedSrc, lot.blockedAmount = nil, 0
                end
            else
                Bridge.AddMoney(newSrc, ACCOUNT, -delta, 'mezat-iade')
                lot.blockedAmount = newAmt
                return
            end
        else
            if lot.blockedSrc then
                Bridge.AddMoney(lot.blockedSrc, ACCOUNT, lot.blockedAmount, 'mezat-iade')
                lot.blockedSrc, lot.blockedAmount = nil, 0
            end
            if Bridge.RemoveMoney(newSrc, ACCOUNT, newAmt, 'mezat-teklif') then
                lot.blockedSrc, lot.blockedAmount = newSrc, newAmt
                return
            else
                Bridge.Notify(newSrc, locale('bid_insolvent'), 'error')
                lot.maxBid[newSrc] = nil
                lot.highBidder = nil
            end
        end
    end
end

--- Teklif sonrasi: kayit + yayin + anti-snipe
local function afterBid(lot, isAuto)
    if lot.highBidder then
        MySQL.insert('INSERT INTO fd_auction_bids (auction_id, lot_id, bidder, amount, is_auto) VALUES (?, ?, ?, ?, ?)', {
            ActiveAuction.id, lot.dbId, Bridge.GetIdentifier(lot.highBidder) or 'unknown', lot.highBid, isAuto and 1 or 0,
        })
    end
    -- Anti-snipe
    if lot.endsAt then
        local left = lot.endsAt - os.time()
        if left <= Config.Bidding.antiSnipe then
            lot.endsAt = os.time() + Config.Bidding.antiSnipeExtend
        end
    end
    broadcastLot()
end

-----------------------------------------------------------------------------
-- LOT TIMER + CEKIC (HAMMER)
-----------------------------------------------------------------------------
local function hammer(lot)
    if lot.hammered then return end
    lot.hammered = true
    lot.running = false
    lot.endsAt = nil

    if lot.highBidder and lot.blockedSrc == lot.highBidder then
        -- Kazanan: bloke edilen para zaten alindi -> teslim et
        local winner = lot.highBidder
        local price = lot.blockedAmount
        lot.blockedSrc, lot.blockedAmount = nil, 0

        MySQL.update('UPDATE fd_auction_lots SET winner = ?, final_price = ?, sold = 1 WHERE id = ?', {
            Bridge.GetIdentifier(winner) or 'unknown', price, lot.dbId,
        })

        local delivered = Mezat.Deliver(winner, lot)
        if delivered then
            Bridge.Notify(winner, locale('won_lot', lot.label, Utils.FormatMoney(price)), 'success')
            Mezat.Log('sold', ('%s -> %s | %s $'):format(lot.label, playerName(winner), Utils.FormatMoney(price)))
        else
            -- Teslim basarisiz: parayi iade et
            Bridge.AddMoney(winner, ACCOUNT, price, 'mezat-teslim-hata')
            Bridge.Notify(winner, locale('delivery_failed'), 'error')
            Mezat.Log('delivery_fail', ('%s -> %s'):format(lot.label, playerName(winner)))
        end
        TriggerClientEvent('fd-acikarttirma:client:sold', -1, {
            label = lot.label, price = price, winnerName = playerName(winner),
        })
    else
        -- Teklif yok / satilmadi
        if lot.blockedSrc then
            Bridge.AddMoney(lot.blockedSrc, ACCOUNT, lot.blockedAmount, 'mezat-iade')
            lot.blockedSrc, lot.blockedAmount = nil, 0
        end
        Mezat.Log('unsold', lot.label)
        TriggerClientEvent('fd-acikarttirma:client:sold', -1, { label = lot.label, price = 0, winnerName = nil })
    end

    broadcastLot()
    broadcastState()
end
Mezat.Hammer = hammer

local function startLotTimer(lot)
    lot.running = true
    lot.hammered = false
    lot.endsAt = os.time() + Config.Bidding.lotDuration
    CreateThread(function()
        while lot.running and not lot.hammered do
            if lot.endsAt and os.time() >= lot.endsAt then
                hammer(lot)
                break
            end
            broadcastLot()
            Wait(1000)
        end
    end)
end

-----------------------------------------------------------------------------
-- CALLBACKLAR: MEZATCI AKSIYONLARI
-----------------------------------------------------------------------------
lib.callback.register('fd-acikarttirma:createAuction', function(src, data)
    if not isAuctioneer(src) then return { ok = false, msg = locale('not_auctioneer') } end
    if ActiveAuction then return { ok = false, msg = locale('auction_exists') } end

    local fee = math.max(0, math.floor(tonumber(data and data.fee) or Config.Ticket.defaultFee))
    local label = (data and data.label ~= nil and tostring(data.label)) or Config.Location.label

    local id = MySQL.insert.await('INSERT INTO fd_auctions (auctioneer, label, fee, state, start_time) VALUES (?, ?, ?, ?, ?)', {
        Bridge.GetIdentifier(src) or 'unknown', label, fee, 'registration', os.time(),
    })
    if not id then return { ok = false, msg = 'DB error' } end

    ActiveAuction = {
        id = id,
        auctioneer = src,
        label = label,
        fee = fee,
        state = 'registration',
        participants = {},
        lots = {},
        currentLotIndex = 0,
    }

    -- Telefon / duyuru hook
    if Config.Phone.enabled and type(Config.Phone.notify) == 'function' then
        pcall(Config.Phone.notify, { id = id, label = label, fee = fee })
    end

    Mezat.Log('created', ('%s | %s tarafindan | katilim: %s $'):format(label, playerName(src), Utils.FormatMoney(fee)))
    TriggerClientEvent('fd-acikarttirma:client:announce', -1, { label = label, fee = fee })
    broadcastState()
    return { ok = true, id = id }
end)

lib.callback.register('fd-acikarttirma:addLot', function(src, data)
    if not ActiveAuction or ActiveAuction.auctioneer ~= src then return { ok = false, msg = locale('not_auctioneer') } end
    if ActiveAuction.state ~= 'registration' then return { ok = false, msg = locale('lots_locked') } end
    if type(data) ~= 'table' then return { ok = false } end

    local t = data.type
    if not Config.LotTypes[t] or not Config.LotTypes[t].enabled then
        return { ok = false, msg = locale('invalid_lot_type') }
    end

    local startPrice = math.max(0, math.floor(tonumber(data.startPrice) or 0))
    local minIncrement = math.max(1, math.floor(tonumber(data.minIncrement) or Config.Bidding.defaultMinIncrement))
    local buyout = data.buyout and math.floor(tonumber(data.buyout)) or nil
    if buyout and buyout <= startPrice then buyout = nil end

    local label = tostring(data.label or Config.LotTypes[t].label)
    local payload = data.payload or {}

    local index = #ActiveAuction.lots + 1
    local dbId = MySQL.insert.await(
        'INSERT INTO fd_auction_lots (auction_id, lot_index, type, label, payload, start_price, min_increment, buyout_price) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { ActiveAuction.id, index, t, label, json.encode(payload), startPrice, minIncrement, buyout }
    )

    ActiveAuction.lots[index] = {
        dbId = dbId, index = index, type = t, label = label, payload = payload,
        startPrice = startPrice, minIncrement = minIncrement, buyout = buyout,
        highBid = 0, highBidder = nil,
        maxBid = {}, maxTime = {},
        blockedSrc = nil, blockedAmount = 0,
        running = false, hammered = false, endsAt = nil,
    }
    return { ok = true, index = index }
end)

lib.callback.register('fd-acikarttirma:startAuction', function(src)
    if not ActiveAuction or ActiveAuction.auctioneer ~= src then return { ok = false, msg = locale('not_auctioneer') } end
    if #ActiveAuction.lots == 0 then return { ok = false, msg = locale('no_lots') } end
    ActiveAuction.state = 'live'
    ActiveAuction.currentLotIndex = 1
    startLotTimer(ActiveAuction.lots[1])
    Mezat.Log('live', ActiveAuction.label)
    broadcastState()
    broadcastLot()
    return { ok = true }
end)

lib.callback.register('fd-acikarttirma:nextLot', function(src)
    if not ActiveAuction or ActiveAuction.auctioneer ~= src then return { ok = false, msg = locale('not_auctioneer') } end
    if ActiveAuction.state ~= 'live' then return { ok = false } end

    local lot = ActiveAuction.lots[ActiveAuction.currentLotIndex]
    if lot and not lot.hammered then hammer(lot) end

    local nextIndex = ActiveAuction.currentLotIndex + 1
    if not ActiveAuction.lots[nextIndex] then
        -- son lot bitti -> mezati kapat
        Mezat.Close(src)
        return { ok = true, finished = true }
    end
    ActiveAuction.currentLotIndex = nextIndex
    startLotTimer(ActiveAuction.lots[nextIndex])
    broadcastState()
    broadcastLot()
    return { ok = true, index = nextIndex }
end)

--- Mezati kapat (mezatci ya da otomatik). Bloke tekliflerin hepsini iade eder.
function Mezat.Close(src)
    if not ActiveAuction then return end
    for _, lot in ipairs(ActiveAuction.lots) do
        lot.running = false
        if lot.blockedSrc then
            Bridge.AddMoney(lot.blockedSrc, ACCOUNT, lot.blockedAmount, 'mezat-iade')
            lot.blockedSrc, lot.blockedAmount = nil, 0
        end
    end

    -- Kaybedenlere fis ucreti iadesi (opsiyonel)
    if Config.Ticket.refundLosers and ActiveAuction.fee > 0 then
        for cid in pairs(ActiveAuction.participants) do
            local psrc = Mezat.SrcFromCid and Mezat.SrcFromCid(cid) or nil
            if psrc then Bridge.AddMoney(psrc, ACCOUNT, ActiveAuction.fee, 'mezat-fis-iade') end
        end
    end

    MySQL.update('UPDATE fd_auctions SET state = ?, closed_at = NOW() WHERE id = ?', { 'closed', ActiveAuction.id })
    Mezat.Log('closed', ActiveAuction.label)
    ActiveAuction = nil
    broadcastState()
end

lib.callback.register('fd-acikarttirma:closeAuction', function(src)
    if not ActiveAuction or ActiveAuction.auctioneer ~= src then return { ok = false, msg = locale('not_auctioneer') } end
    Mezat.Close(src)
    return { ok = true }
end)

-----------------------------------------------------------------------------
-- CALLBACKLAR: TEKLIF
-----------------------------------------------------------------------------
local function validateBidder(src)
    if not ActiveAuction then return false, locale('no_auction') end
    if ActiveAuction.state ~= 'live' then return false, locale('not_live') end
    if src == ActiveAuction.auctioneer then return false, locale('auctioneer_cant_bid') end
    if not Mezat.IsParticipant(src) then return false, locale('need_ticket') end
    local lot = currentLot()
    if not lot or not lot.running then return false, locale('no_active_lot') end
    return true, nil, lot
end

lib.callback.register('fd-acikarttirma:placeBid', function(src, amount)
    local ok, msg, lot = validateBidder(src)
    if not ok then return { ok = false, msg = msg } end

    amount = math.floor(tonumber(amount) or 0)
    local minRequired = lot.highBidder and (lot.highBid + lot.minIncrement) or lot.startPrice
    if amount < minRequired then
        return { ok = false, msg = locale('bid_too_low', Utils.FormatMoney(minRequired)) }
    end
    if Bridge.GetMoney(src, ACCOUNT) < amount then
        return { ok = false, msg = locale('not_enough_money') }
    end

    lot.maxBid[src] = amount
    lot.maxTime[src] = os.clock()
    reconcile(lot)
    afterBid(lot, false)
    return { ok = true, highBid = lot.highBid, leader = lot.highBidder == src }
end)

lib.callback.register('fd-acikarttirma:placeAutoBid', function(src, maxBudget)
    if not Config.Bidding.allowAutoBid then return { ok = false, msg = locale('autobid_disabled') } end
    local ok, msg, lot = validateBidder(src)
    if not ok then return { ok = false, msg = msg } end

    maxBudget = math.floor(tonumber(maxBudget) or 0)
    local minRequired = lot.highBidder and (lot.highBid + lot.minIncrement) or lot.startPrice
    if maxBudget < minRequired then
        return { ok = false, msg = locale('bid_too_low', Utils.FormatMoney(minRequired)) }
    end
    if Bridge.GetMoney(src, ACCOUNT) < maxBudget then
        return { ok = false, msg = locale('not_enough_money') }
    end

    lot.maxBid[src] = maxBudget
    lot.maxTime[src] = os.clock()
    reconcile(lot)
    afterBid(lot, true)
    return { ok = true, highBid = lot.highBid, leader = lot.highBidder == src }
end)

lib.callback.register('fd-acikarttirma:buyout', function(src)
    if not Config.Bidding.allowBuyout then return { ok = false, msg = locale('buyout_disabled') } end
    local ok, msg, lot = validateBidder(src)
    if not ok then return { ok = false, msg = msg } end
    if not lot.buyout then return { ok = false, msg = locale('no_buyout') } end
    if Bridge.GetMoney(src, ACCOUNT) < lot.buyout then
        return { ok = false, msg = locale('not_enough_money') }
    end

    -- Onceki lideri iade et, alici uzerine bloke et
    if lot.blockedSrc and lot.blockedSrc ~= src then
        Bridge.AddMoney(lot.blockedSrc, ACCOUNT, lot.blockedAmount, 'mezat-iade')
        lot.blockedSrc, lot.blockedAmount = nil, 0
    end
    local need = lot.buyout - (lot.blockedSrc == src and lot.blockedAmount or 0)
    if need > 0 and not Bridge.RemoveMoney(src, ACCOUNT, need, 'mezat-buyout') then
        return { ok = false, msg = locale('not_enough_money') }
    end
    lot.highBidder = src
    lot.highBid = lot.buyout
    lot.blockedSrc = src
    lot.blockedAmount = lot.buyout
    hammer(lot)
    return { ok = true }
end)

-----------------------------------------------------------------------------
-- DURUM SORGUSU (UI)
-----------------------------------------------------------------------------
lib.callback.register('fd-acikarttirma:getState', function(src)
    if not ActiveAuction then return { active = false } end
    local isAuc = ActiveAuction.auctioneer == src
    local lots = nil
    if isAuc then
        lots = {}
        for _, lot in ipairs(ActiveAuction.lots) do
            lots[#lots + 1] = {
                index = lot.index, type = lot.type, label = lot.label,
                startPrice = lot.startPrice, minIncrement = lot.minIncrement,
                buyout = lot.buyout, sold = lot.hammered == true,
            }
        end
    end
    return {
        active = true,
        id = ActiveAuction.id,
        label = ActiveAuction.label,
        state = ActiveAuction.state,
        fee = ActiveAuction.fee,
        auctioneerId = ActiveAuction.auctioneer,
        participants = Mezat.CountParticipants(),
        isAuctioneer = isAuc,
        isParticipant = Mezat.IsParticipant(src),
        lotCount = #ActiveAuction.lots,
        lots = lots,
        lot = publicLotView(currentLot()),
    }
end)

-----------------------------------------------------------------------------
-- OYUNCU AYRILINCA: bloke parayi kaybetmesin (lider ayrilirsa iade + yeniden coz)
-----------------------------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    if not ActiveAuction then return end
    local lot = currentLot()
    if lot and lot.running and lot.maxBid[src] then
        lot.maxBid[src] = nil
        if lot.highBidder == src then
            if lot.blockedSrc == src then
                -- ayrilan lidere iade et (offline hesabina yatar)
                Bridge.AddMoney(src, ACCOUNT, lot.blockedAmount, 'mezat-iade')
                lot.blockedSrc, lot.blockedAmount = nil, 0
            end
            lot.highBidder = nil
            reconcile(lot)
            broadcastLot()
        end
    end
end)

-- Resource durursa aktif blokeleri iade et (para kaybi olmasin)
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if not ActiveAuction then return end
    for _, lot in ipairs(ActiveAuction.lots) do
        if lot.blockedSrc then
            Bridge.AddMoney(lot.blockedSrc, ACCOUNT, lot.blockedAmount, 'mezat-iade')
        end
    end
end)
