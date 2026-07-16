-- Bridge yukleyici: aktif framework'u algilar, tek `Bridge` API'sini olusturur.
-- qbx.lua / qb.lua / esx.lua dosyalari bu tabloyu doldurur.

Bridge = {}

local function detect()
    if Config and Config.Framework and Config.Framework ~= 'auto' then
        return Config.Framework
    end
    if GetResourceState('qbx_core') == 'started' then return 'qbx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    return 'unknown'
end

FrameworkName = detect()

if FrameworkName == 'unknown' then
    print('^1[fd-acikarttirma] HATA: Desteklenen framework bulunamadi (qbx_core / qb-core / es_extended).^0')
else
    print(('^2[fd-acikarttirma] Framework: %s^0'):format(FrameworkName))
end

-- ox_inventory kullaniliyor mu? (fis metadata + item teslimi icin tercih edilir)
UsesOxInventory = GetResourceState('ox_inventory') == 'started'
