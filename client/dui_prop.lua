-- fd-acikarttirma | mezatcinin elindeki tabela propu (ustunde guncel rakam DUI ile)
-- Prop, mezatcinin pedine bagli (networked, herkes gorur); texture her client'ta
-- lokal olarak DUI ile degistirilir (herkes rakami gorur).

local SP = Config.SignProp

local dui
local txdReplaced = false
local signObj          -- sadece mezatci client'inda olusturulur (networked)
local amAuctioneer = false
local liveNow = false

-----------------------------------------------------------------------------
-- DUI (texture kaynagi) - tum clientlarda
-----------------------------------------------------------------------------
local function ensureDui()
    if dui then return end
    local url = ('nui://%s/html/prop.html'):format(GetCurrentResourceName())
    dui = CreateDui(url, SP.duiWidth, SP.duiHeight)
    local handle = GetDuiHandle(dui)
    local runtimeTxd = CreateRuntimeTxd('fd_mezat_sign_txd')
    CreateRuntimeTextureFromDuiHandle(runtimeTxd, 'fd_sign', handle)
    AddReplaceTexture(SP.txd, SP.txn, 'fd_mezat_sign_txd', 'fd_sign')
    txdReplaced = true
end

local function clearDui()
    if txdReplaced then
        RemoveReplaceTexture(SP.txd, SP.txn)
        txdReplaced = false
    end
    if dui then DestroyDui(dui); dui = nil end
end

local function sendSign(amount, label)
    if not dui then return end
    SendDuiMessage(dui, json.encode({
        target = 'prop',
        data = { amount = amount or 0, label = label or '' },
    }))
end

-----------------------------------------------------------------------------
-- PROP OBJESI (sadece mezatci olusturur, networked)
-----------------------------------------------------------------------------
local function attachSign()
    if signObj and DoesEntityExist(signObj) then return end
    local model = joaat(SP.model)
    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 100 do Wait(10); tries = tries + 1 end
    if not HasModelLoaded(model) then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    signObj = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(signObj, ped, GetPedBoneIndex(ped, SP.bone),
        SP.pos.x, SP.pos.y, SP.pos.z, SP.rot.x, SP.rot.y, SP.rot.z,
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

local function removeSign()
    if signObj and DoesEntityExist(signObj) then DeleteObject(signObj) end
    signObj = nil
end

-----------------------------------------------------------------------------
-- DURUM TAKIBI
-----------------------------------------------------------------------------
local function goLive(view)
    liveNow = true
    amAuctioneer = view.auctioneerId ~= nil and view.auctioneerId == GetPlayerServerId(PlayerId())
    ensureDui()
    if amAuctioneer then attachSign() end
end

local function goIdle()
    liveNow = false
    removeSign()
    clearDui()
end

RegisterNetEvent('fd-acikarttirma:client:auctionState', function(view)
    if view and view.state == 'live' then
        goLive(view)
        if view.lot then sendSign(view.lot.hasBid and view.lot.highBid or view.lot.startPrice, view.lot.label) end
    else
        goIdle()
    end
end)

RegisterNetEvent('fd-acikarttirma:client:lotUpdate', function(lot)
    if not liveNow or not lot then return end
    if not dui then ensureDui() end
    sendSign(lot.hasBid and lot.highBid or lot.startPrice, lot.label)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then goIdle() end
end)
