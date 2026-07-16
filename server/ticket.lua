-- fd-acikarttirma | fis (katilim) item + giris dogrulama

local ACCOUNT = Config.Account

-- cid -> src eslemesi (iade / giris kontrolu icin)
local ParticipantSrc = {}

--- cid'den online src bul
function Mezat.SrcFromCid(cid)
    if ParticipantSrc[cid] and Bridge.GetIdentifier(ParticipantSrc[cid]) == cid then
        return ParticipantSrc[cid]
    end
    for _, pid in ipairs(GetPlayers()) do
        local id = tonumber(pid)
        if Bridge.GetIdentifier(id) == cid then
            ParticipantSrc[cid] = id
            return id
        end
    end
    return nil
end

--- Fis satin al (katilim ucreti ode, metadata'li item ver)
lib.callback.register('fd-acikarttirma:buyTicket', function(src)
    local auction = Mezat.GetActive()
    if not auction then return { ok = false, msg = locale('no_auction') } end
    if auction.state ~= 'registration' and auction.state ~= 'live' then
        return { ok = false, msg = locale('registration_closed') }
    end

    local cid = Bridge.GetIdentifier(src)
    if not cid then return { ok = false } end
    if auction.participants[cid] then return { ok = false, msg = locale('already_have_ticket') } end

    -- Kapasite
    if Config.Ticket.capacityEnabled and Mezat.CountParticipants() >= Config.Ticket.capacity then
        return { ok = false, msg = locale('capacity_full') }
    end

    -- Ucret
    if auction.fee > 0 then
        if Bridge.GetMoney(src, ACCOUNT) < auction.fee then
            return { ok = false, msg = locale('not_enough_money') }
        end
        if not Bridge.RemoveMoney(src, ACCOUNT, auction.fee, 'mezat-fis') then
            return { ok = false, msg = locale('not_enough_money') }
        end
    end

    -- Metadata'li fis item
    local dateStr = os.date('%d.%m.%Y %H:%M')
    local meta = {
        auctionId = auction.id,
        date = dateStr,
        fee = auction.fee,
        buyer = cid,
        label = auction.label,
        description = ('Mezat: %s\nMezat No: #%d\nTarih: %s\nKatilim Ucreti: %s $'):format(
            auction.label, auction.id, dateStr, Utils.FormatMoney(auction.fee)),
    }

    local given = Bridge.AddItem(src, Config.Ticket.item, 1, meta)
    if not given then
        -- item verilemedi -> ucreti iade et
        if auction.fee > 0 then Bridge.AddMoney(src, ACCOUNT, auction.fee, 'mezat-fis-iade') end
        return { ok = false, msg = locale('cant_carry_ticket') }
    end

    auction.participants[cid] = true
    ParticipantSrc[cid] = src

    Mezat.Log('ticket', ('%s fis aldi (#%d)'):format(GetPlayerName(src), auction.id))
    return { ok = true, fee = auction.fee }
end)

--- Giris bolgesine girince: katilimci mi?
lib.callback.register('fd-acikarttirma:checkEntry', function(src)
    local auction = Mezat.GetActive()
    if not auction then return { allowed = true, hasAuction = false } end
    local ok = Mezat.IsParticipant(src)
    return { allowed = ok, hasAuction = true, state = auction.state }
end)

-----------------------------------------------------------------------------
-- FIS ITEM KULLANIMI (ox_inventory) -> detay goster
-- items.lua'da: ['mezat_fisi'] = { ..., server = { export = 'fd-acikarttirma.useTicket' } }
-----------------------------------------------------------------------------
if UsesOxInventory then
    exports('useTicket', function(event, item, inventory, slot, data)
        if event ~= 'usingItem' then return end
        local src = inventory.id or inventory
        local meta = item and item.metadata or {}
        Bridge.Notify(src, locale('ticket_detail',
            meta.label or '-', meta.auctionId or 0, meta.date or '-', Utils.FormatMoney(meta.fee or 0)), 'inform')
        -- item tuketilmesin
        return false
    end)
end
