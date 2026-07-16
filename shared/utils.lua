Utils = {}

--- Para formatla: 12345 -> "12,345"
function Utils.FormatMoney(amount)
    local formatted = tostring(math.floor(amount + 0.5))
    local k
    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

--- Config.Vehicle.plateFormat'a gore rastgele plaka uret (# = rakam, @ = harf)
function Utils.GeneratePlate(format)
    format = format or 'MEZAT###'
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local out = format:gsub('[#@]', function(c)
        if c == '#' then
            return tostring(math.random(0, 9))
        else
            local i = math.random(1, #letters)
            return letters:sub(i, i)
        end
    end)
    return out:upper()
end

--- Mezatci job yetkisi kontrolu (job adi + grade)
function Utils.IsAuctioneer(jobName, jobGrade)
    if not jobName then return false end
    local min = Config.AuctioneerJobs[jobName]
    if min == nil then return false end
    return (jobGrade or 0) >= min
end

--- Basit deep copy
function Utils.Copy(t)
    if type(t) ~= 'table' then return t end
    local r = {}
    for k, v in pairs(t) do r[k] = Utils.Copy(v) end
    return r
end
