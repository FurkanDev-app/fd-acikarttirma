-- fd-acikarttirma | Discord webhook loglari

local TITLES = {
    created = 'Mezat Olusturuldu',
    live = 'Mezat Basladi',
    ticket = 'Fis Satisi',
    sold = 'Lot Satildi',
    unsold = 'Lot Satilmadi',
    delivery_fail = 'Teslim Hatasi',
    closed = 'Mezat Kapandi',
}

--- Log gonder (Discord webhook). type = TITLES anahtari, msg = aciklama
function Mezat.Log(logType, msg)
    if Config.Debug then
        print(('[fd-acikarttirma][%s] %s'):format(logType, msg))
    end
    if not Config.Webhook.enabled or Config.Webhook.url == '' then return end

    local embed = {{
        title = TITLES[logType] or logType,
        description = tostring(msg),
        color = Config.Webhook.color,
        footer = { text = ('fd-acikarttirma | %s'):format(os.date('%d.%m.%Y %H:%M:%S')) },
    }}

    PerformHttpRequest(Config.Webhook.url, function() end, 'POST', json.encode({
        username = Config.Webhook.botName,
        embeds = embed,
    }), { ['Content-Type'] = 'application/json' })
end
