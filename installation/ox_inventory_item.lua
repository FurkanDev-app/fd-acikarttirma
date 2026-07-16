-- ox_inventory 'data/items.lua' dosyasina ekleyin:
-- (Config.Ticket.item ile ayni ad olmali: varsayilan 'mezat_fisi')

['mezat_fisi'] = {
    label = 'Mezat Fisi',
    weight = 0,
    stack = false,   -- her fis benzersiz metadata tasir
    close = true,
    description = 'Mezata katilim fisi.',
    client = {
        image = 'mezat_fisi.png',
    },
    -- Fis kullaninca detay gostersin (server/ticket.lua -> useTicket)
    server = {
        export = 'fd-acikarttirma.useTicket',
    },
},
