fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'fd-acikarttirma'
author 'FurkanDev'
description 'FiveM acik arttirma (mezat) scripti - arac / benzinlik / item, klasik + otomatik teklif, DUI ekran ve tabela'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/tr.lua',
    'locales/en.lua',
    'shared/locale.lua',
    'shared/utils.lua',
}

client_scripts {
    'bridge/loader.lua',
    'bridge/qbx.lua',
    'bridge/qb.lua',
    'bridge/esx.lua',
    'client/main.lua',
    'client/announce.lua',
    'client/dui_screen.lua',
    'client/dui_prop.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/loader.lua',
    'bridge/qbx.lua',
    'bridge/qb.lua',
    'bridge/esx.lua',
    'server/main.lua',
    'server/ticket.lua',
    'server/delivery.lua',
    'server/logs.lua',
}

-- NUI (Vite + React + TS build ciktisi)
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/screen.html',
    'html/prop.html',
    'html/assets/**',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
