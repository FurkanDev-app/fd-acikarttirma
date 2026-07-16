-- fd-acikarttirma | client ana: blip, giris bolgesi, fis noktasi, komut, NUI kopru

local NuiOpen = false
local State = nil          -- son bilinen mezat durumu
local UsesOxTarget = GetResourceState('ox_target') == 'started'

-----------------------------------------------------------------------------
-- NUI ACMA / KAPATMA
-----------------------------------------------------------------------------
local function openNui(view)
    if NuiOpen then return end
    NuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', view = view, state = State })
end

local function closeNui()
    if not NuiOpen then return end
    NuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeNui()
    cb({ ok = true })
end)

-- NUI aksiyonlarini server callback'lerine kopru
local function relay(name)
    RegisterNUICallback(name, function(data, cb)
        local res = lib.callback.await('fd-acikarttirma:' .. name, false, data)
        cb(res or { ok = false })
    end)
end

relay('createAuction')
relay('addLot')
relay('startAuction')
relay('nextLot')
relay('closeAuction')
relay('placeBid')
relay('placeAutoBid')
relay('buyout')
relay('buyTicket')

RegisterNUICallback('getState', function(_, cb)
    local res = lib.callback.await('fd-acikarttirma:getState', false)
    State = res
    cb(res or { active = false })
end)

-----------------------------------------------------------------------------
-- KOMUT: /mezat
-----------------------------------------------------------------------------
RegisterCommand(Config.Command, function()
    local res = lib.callback.await('fd-acikarttirma:getState', false)
    State = res
    if not res or not res.active then
        -- Aktif mezat yok: sadece mezatci panel acabilir (yeni mezat icin)
        local job = Bridge.GetJob()
        if job and Utils.IsAuctioneer(job.name, job.grade) then
            openNui('auctioneer')
        else
            Bridge.Notify(locale('no_auction'), 'error')
        end
        return
    end

    if res.isAuctioneer then
        openNui('auctioneer')
    elseif res.isParticipant then
        openNui('bid')
    else
        Bridge.Notify(locale('need_ticket_desk'), 'error')
    end
end, false)

RegisterKeyMapping(Config.Command, 'Mezat menusunu ac', 'keyboard', '')

-----------------------------------------------------------------------------
-- STATE / LOT GUNCELLEMELERINI NUI'YE ILET
-----------------------------------------------------------------------------
RegisterNetEvent('fd-acikarttirma:client:auctionState', function(view)
    State = view
    if NuiOpen then SendNUIMessage({ action = 'state', state = view }) end
end)

RegisterNetEvent('fd-acikarttirma:client:lotUpdate', function(lot)
    if NuiOpen then SendNUIMessage({ action = 'lot', lot = lot }) end
end)

RegisterNetEvent('fd-acikarttirma:client:sold', function(data)
    if NuiOpen then SendNUIMessage({ action = 'sold', data = data }) end
    Bridge.Notify(
        data.winnerName and locale('lot_sold_to', data.label, data.winnerName, Utils.FormatMoney(data.price))
            or locale('lot_unsold', data.label),
        'inform')
end)

RegisterNetEvent('fd-acikarttirma:client:announce', function(data)
    lib.notify({
        title = locale('announce_title'),
        description = locale('announce_body', data.label, Utils.FormatMoney(data.fee)),
        type = 'inform',
        duration = 12000,
    })
end)

-----------------------------------------------------------------------------
-- BLIP + GIRIS BOLGESI + FIS NOKTASI
-----------------------------------------------------------------------------
CreateThread(function()
    local L = Config.Location

    if L.blip.enabled then
        local blip = AddBlipForCoord(L.center.x, L.center.y, L.center.z)
        SetBlipSprite(blip, L.blip.sprite)
        SetBlipColour(blip, L.blip.color)
        SetBlipScale(blip, L.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(L.label)
        EndTextCommandSetBlipName(blip)
    end

    -- Giris bolgesi (fis kontrolu)
    lib.zones.sphere({
        coords = L.entryZone.coords,
        radius = L.entryZone.radius,
        onEnter = function()
            local res = lib.callback.await('fd-acikarttirma:checkEntry', false)
            if res and res.hasAuction and not res.allowed then
                lib.notify({
                    title = locale('entry_title'),
                    description = locale('entry_denied'),
                    type = 'error',
                    duration = 8000,
                })
            end
        end,
    })
end)

-----------------------------------------------------------------------------
-- FIS SATIS NOKTASI (ox_target ya da yaklas-tusla fallback)
-----------------------------------------------------------------------------
local function buyTicketFlow()
    local res = lib.callback.await('fd-acikarttirma:getState', false)
    if not res or not res.active then
        Bridge.Notify(locale('no_auction'), 'error')
        return
    end
    local confirm = lib.alertDialog({
        header = locale('buy_ticket_header'),
        content = locale('buy_ticket_content', Utils.FormatMoney(res.fee)),
        centered = true,
        cancel = true,
    })
    if confirm ~= 'confirm' then return end
    local r = lib.callback.await('fd-acikarttirma:buyTicket', false)
    if r and r.ok then
        Bridge.Notify(locale('ticket_bought'), 'success')
    else
        Bridge.Notify((r and r.msg) or locale('ticket_failed'), 'error')
    end
end

CreateThread(function()
    local desk = Config.Location.ticketDesk
    if not desk then return end

    if desk.useTarget and UsesOxTarget then
        exports.ox_target:addSphereZone({
            coords = desk.coords,
            radius = desk.targetRadius or 1.5,
            debug = Config.Debug,
            options = {
                {
                    name = 'fd_mezat_ticket',
                    icon = 'fa-solid fa-ticket',
                    label = locale('target_buy_ticket'),
                    onSelect = buyTicketFlow,
                },
            },
        })
    else
        -- Fallback: yaklas + [E]
        lib.zones.sphere({
            coords = desk.coords,
            radius = desk.targetRadius or 2.0,
            inside = function()
                if IsControlJustReleased(0, 38) then buyTicketFlow() end
            end,
            onEnter = function()
                lib.showTextUI(locale('press_buy_ticket'))
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })
    end
end)

-- Baslangic senkronu: mezat devam ederken giren oyuncular DUI'leri gorsun
CreateThread(function()
    Wait(2000)
    local res = lib.callback.await('fd-acikarttirma:getState', false)
    if res and res.active then
        State = res
        TriggerEvent('fd-acikarttirma:client:auctionState', {
            active = true,
            id = res.id, label = res.label, state = res.state, fee = res.fee,
            auctioneerId = res.auctioneerId, participants = res.participants,
            lot = res.lot,
        })
        if res.lot then TriggerEvent('fd-acikarttirma:client:lotUpdate', res.lot) end
    end
end)

-- ESC ile kapat
CreateThread(function()
    while true do
        if NuiOpen then
            if IsControlJustReleased(0, 322) then closeNui() end
            Wait(0)
        else
            Wait(300)
        end
    end
end)
