-- Qbox (qbx_core) bridge implementasyonu
if FrameworkName ~= 'qbx' then return end

local isServer = IsDuplicityVersion()

if isServer then
    -----------------------------------------------------------------------
    -- SERVER
    -----------------------------------------------------------------------
    function Bridge.GetPlayer(src)
        return exports.qbx_core:GetPlayer(src)
    end

    function Bridge.GetIdentifier(src)
        local p = Bridge.GetPlayer(src)
        return p and p.PlayerData.citizenid or nil
    end

    function Bridge.GetJob(src)
        local p = Bridge.GetPlayer(src)
        if not p then return nil end
        local job = p.PlayerData.job
        return { name = job.name, grade = job.grade.level }
    end

    function Bridge.GetMoney(src, account)
        local p = Bridge.GetPlayer(src)
        if not p then return 0 end
        return p.PlayerData.money[account] or 0
    end

    function Bridge.RemoveMoney(src, account, amount, reason)
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        return p.Functions.RemoveMoney(account, amount, reason or 'mezat')
    end

    function Bridge.AddMoney(src, account, amount, reason)
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        return p.Functions.AddMoney(account, amount, reason or 'mezat')
    end

    function Bridge.CanCarry(src, item, count)
        if UsesOxInventory then
            return exports.ox_inventory:CanCarryItem(src, item, count)
        end
        return true
    end

    function Bridge.AddItem(src, item, count, meta)
        if UsesOxInventory then
            return exports.ox_inventory:AddItem(src, item, count, meta)
        end
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        return p.Functions.AddItem(item, count, nil, meta)
    end

    function Bridge.RemoveItem(src, item, count, meta)
        if UsesOxInventory then
            return exports.ox_inventory:RemoveItem(src, item, count, meta)
        end
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        return p.Functions.RemoveItem(item, count)
    end

    function Bridge.GetItemCount(src, item)
        if UsesOxInventory then
            return exports.ox_inventory:GetItemCount(src, item) or 0
        end
        local p = Bridge.GetPlayer(src)
        if not p then return 0 end
        local it = p.Functions.GetItemByName(item)
        return it and it.amount or 0
    end

    --- Kazanana arac ver (owned vehicle). return true/false
    function Bridge.GiveVehicle(src, model, plate, garage)
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        local cid = p.PlayerData.citizenid
        MySQL.insert.await(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            {
                p.PlayerData.license,
                cid,
                model,
                joaat(model),
                json.encode({}),
                plate,
                1,
                garage or 'pillboxgarage',
            }
        )
        return true
    end

    function Bridge.Notify(src, msg, type)
        TriggerClientEvent('ox_lib:notify', src, { description = msg, type = type or 'inform' })
    end
else
    -----------------------------------------------------------------------
    -- CLIENT
    -----------------------------------------------------------------------
    function Bridge.GetJob()
        local data = exports.qbx_core:GetPlayerData()
        if not data or not data.job then return nil end
        return { name = data.job.name, grade = data.job.grade.level }
    end

    function Bridge.Notify(msg, type)
        lib.notify({ description = msg, type = type or 'inform' })
    end
end
