-- ESX (es_extended) bridge implementasyonu
if FrameworkName ~= 'esx' then return end

local ESX = exports['es_extended']:getSharedObject()
local isServer = IsDuplicityVersion()

-- ESX hesap adi eslemesi: bizim 'bank'/'cash' -> ESX account/money
local function esxAccount(account)
    if account == 'cash' or account == 'money' then return 'money' end
    return 'bank'
end

if isServer then
    -----------------------------------------------------------------------
    -- SERVER
    -----------------------------------------------------------------------
    function Bridge.GetPlayer(src)
        return ESX.GetPlayerFromId(src)
    end

    function Bridge.GetIdentifier(src)
        local p = Bridge.GetPlayer(src)
        return p and p.identifier or nil
    end

    function Bridge.GetJob(src)
        local p = Bridge.GetPlayer(src)
        if not p then return nil end
        return { name = p.job.name, grade = p.job.grade }
    end

    function Bridge.GetMoney(src, account)
        local p = Bridge.GetPlayer(src)
        if not p then return 0 end
        if esxAccount(account) == 'money' then
            return p.getMoney()
        end
        local acc = p.getAccount('bank')
        return acc and acc.money or 0
    end

    function Bridge.RemoveMoney(src, account, amount)
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        if esxAccount(account) == 'money' then
            if p.getMoney() < amount then return false end
            p.removeMoney(amount)
        else
            local acc = p.getAccount('bank')
            if not acc or acc.money < amount then return false end
            p.removeAccountMoney('bank', amount)
        end
        return true
    end

    function Bridge.AddMoney(src, account, amount)
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        if esxAccount(account) == 'money' then
            p.addMoney(amount)
        else
            p.addAccountMoney('bank', amount)
        end
        return true
    end

    function Bridge.CanCarry(src, item, count)
        if UsesOxInventory then
            return exports.ox_inventory:CanCarryItem(src, item, count)
        end
        local p = Bridge.GetPlayer(src)
        return p ~= nil and p.canCarryItem(item, count)
    end

    function Bridge.AddItem(src, item, count, meta)
        if UsesOxInventory then
            return exports.ox_inventory:AddItem(src, item, count, meta)
        end
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        p.addInventoryItem(item, count)
        return true
    end

    function Bridge.RemoveItem(src, item, count, meta)
        if UsesOxInventory then
            return exports.ox_inventory:RemoveItem(src, item, count, meta)
        end
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        p.removeInventoryItem(item, count)
        return true
    end

    function Bridge.GetItemCount(src, item)
        if UsesOxInventory then
            return exports.ox_inventory:GetItemCount(src, item) or 0
        end
        local p = Bridge.GetPlayer(src)
        if not p then return 0 end
        local it = p.getInventoryItem(item)
        return it and it.count or 0
    end

    function Bridge.GiveVehicle(src, model, plate, garage)
        local p = Bridge.GetPlayer(src)
        if not p then return false end
        MySQL.insert.await(
            'INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)',
            {
                p.identifier,
                plate,
                json.encode({ model = joaat(model), plate = plate }),
                'car',
                1,
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
        local data = ESX.GetPlayerData()
        if not data or not data.job then return nil end
        return { name = data.job.name, grade = data.job.grade }
    end

    function Bridge.Notify(msg, type)
        lib.notify({ description = msg, type = type or 'inform' })
    end
end
