-- fd-acikarttirma | duyuru / telefon entegrasyon noktasi
-- Mezatci telefon uygulamasindan mezat saatini duyuracaksa, telefon resource'u
-- buradaki export'u cagirir. (config.lua Config.Phone server tarafi hook'tur.)

--- Telefon app'i / harici resource mezatci panelini acmak icin bunu cagirir.
-- Ornek (lb-phone app'inden):  exports['fd-acikarttirma']:OpenPanel()
local function openPanel()
    local job = Bridge.GetJob()
    if not (job and Utils.IsAuctioneer(job.name, job.grade)) then
        Bridge.Notify(locale('not_auctioneer'), 'error')
        return false
    end
    ExecuteCommand(Config.Command)
    return true
end
exports('OpenPanel', openPanel)

--- Telefon app'inden dogrudan zamanli duyuru yapmak isteyenler icin
-- (istege bagli). Bu sadece bir chat/notify duyurusu tetikler; asil mezat
-- olusturma NUI panelinden yapilir.
RegisterNetEvent('fd-acikarttirma:client:phoneAnnounce', function(data)
    lib.notify({
        title = locale('announce_title'),
        description = locale('announce_scheduled', data.label or Config.Location.label, data.time or '-'),
        type = 'inform',
        duration = 12000,
    })
end)
