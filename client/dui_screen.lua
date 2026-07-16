-- fd-acikarttirma | alandaki buyuk ekran DUI (urun + guncel teklif)
if not Config.Screen.enabled then return end

local dui, txd, screenProp
local created = false

local function currentPayload(lot)
    if not lot then
        return { active = false }
    end
    return {
        active = true,
        label = lot.label,
        type = lot.type,
        index = lot.index,
        total = lot.total,
        startPrice = lot.startPrice,
        highBid = lot.hasBid and lot.highBid or lot.startPrice,
        hasBid = lot.hasBid,
        leader = lot.highBidderName,
        buyout = lot.buyout,
        timeLeft = lot.timeLeft or 0,
    }
end

local function sendScreen(lot)
    if not created or not dui then return end
    SendDuiMessage(dui, json.encode({ target = 'screen', data = currentPayload(lot) }))
end

local function createScreen()
    if created then return end
    created = true

    local url = ('nui://%s/html/screen.html'):format(GetCurrentResourceName())
    dui = CreateDui(url, Config.Screen.duiWidth, Config.Screen.duiHeight)
    local handle = GetDuiHandle(dui)

    txd = CreateRuntimeTxd('fd_mezat_screen_txd')
    CreateRuntimeTextureFromDuiHandle(txd, 'fd_screen', handle)
    AddReplaceTexture(Config.Screen.txd, Config.Screen.txn, 'fd_mezat_screen_txd', 'fd_screen')

    if Config.Screen.spawn then
        local model = joaat(Config.Screen.prop)
        RequestModel(model)
        local tries = 0
        while not HasModelLoaded(model) and tries < 100 do Wait(10); tries = tries + 1 end
        if HasModelLoaded(model) then
            local c = Config.Screen.coords
            screenProp = CreateObject(model, c.x, c.y, c.z, false, false, false)
            SetEntityHeading(screenProp, c.w)
            FreezeEntityPosition(screenProp, true)
            SetModelAsNoLongerNeeded(model)
        end
    end
end

local function destroyScreen()
    if not created then return end
    created = false
    RemoveReplaceTexture(Config.Screen.txd, Config.Screen.txn)
    if dui then DestroyDui(dui); dui = nil end
    if screenProp and DoesEntityExist(screenProp) then DeleteObject(screenProp) end
    screenProp = nil
end

-- Mezat basladiginda olustur, kapandiginda yok et
RegisterNetEvent('fd-acikarttirma:client:auctionState', function(view)
    if view and view.active ~= false then
        createScreen()
        Wait(200) -- DUI'nin yuklenmesine kucuk sure
        sendScreen(view and view.lot)
    else
        destroyScreen()
    end
end)

RegisterNetEvent('fd-acikarttirma:client:lotUpdate', function(lot)
    if not created then createScreen(); Wait(200) end
    sendScreen(lot)
end)

RegisterNetEvent('fd-acikarttirma:client:sold', function(data)
    if not created or not dui then return end
    SendDuiMessage(dui, json.encode({ target = 'screen', event = 'sold', data = data }))
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then destroyScreen() end
end)
