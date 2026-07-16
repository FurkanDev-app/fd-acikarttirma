-- Basit locale sistemi (ox_lib convar bagimliligindan bagimsiz).
-- locales/tr.lua ve en.lua `Locales` tablosunu doldurur.

Locales = Locales or {}

--- Global ceviri fonksiyonu: locale('key', ...) -> string.format
function locale(key, ...)
    local lang = (Config and Config.Locale) or 'tr'
    local pack = Locales[lang] or Locales['en'] or {}
    local str = pack[key]
    if str == nil then
        -- fallback: diger dilde ara, yoksa key'i dondur
        str = (Locales['en'] and Locales['en'][key]) or key
    end
    if select('#', ...) > 0 then
        local ok, res = pcall(string.format, str, ...)
        if ok then return res end
    end
    return str
end
