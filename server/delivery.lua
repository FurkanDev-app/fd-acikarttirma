-- fd-acikarttirma | kazanana urun teslimi (arac / benzinlik / item)

--- Kazanana lot'u teslim et. return true = basarili.
function Mezat.Deliver(src, lot)
    local t = lot.type
    local payload = lot.payload or {}

    if t == 'vehicle' then
        local model = payload.model
        if not model then return false end
        local plate = payload.plate
        if not plate or plate == '' then
            plate = Utils.GeneratePlate(Config.Vehicle.plateFormat)
        end
        local garage = payload.garage or Config.Vehicle.defaultGarage
        local ok = Bridge.GiveVehicle(src, model, plate, garage)
        if ok then
            Bridge.Notify(src, locale('delivered_vehicle', model, plate), 'success')
        end
        return ok

    elseif t == 'business' then
        -- Config hook: sunucu kendi management sistemine baglar
        if type(Config.Delivery.business) ~= 'function' then return false end
        local ok = false
        local success, res = pcall(Config.Delivery.business, src, payload)
        if success then ok = res == true or res == nil else ok = false end
        if ok then
            Bridge.Notify(src, locale('delivered_business', payload.label or lot.label), 'success')
        end
        return ok

    elseif t == 'item' then
        local item = payload.item
        local count = math.max(1, math.floor(tonumber(payload.count) or 1))
        if not item then return false end
        if not Bridge.CanCarry(src, item, count) then
            -- tasiyamiyorsa yine de teslim etmeye calis; ox_inventory zaten yer yoksa false doner
        end
        local ok = Bridge.AddItem(src, item, count, payload.metadata)
        if ok then
            Bridge.Notify(src, locale('delivered_item', count, item), 'success')
        end
        return ok
    end

    return false
end
