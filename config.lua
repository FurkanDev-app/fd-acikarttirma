Config = {}

-----------------------------------------------------------------------------
-- GENEL
-----------------------------------------------------------------------------
Config.Debug = false
Config.Locale = 'tr' -- 'tr' | 'en'

-- Framework otomatik algilanir; zorlamak istersen: 'qbx' | 'qb' | 'esx'
Config.Framework = 'auto'

-- Ekonomi hesabi: 'bank' | 'cash' | 'money'
-- Teklif/escrow bu hesaptan blokelenir.
Config.Account = 'bank'

-----------------------------------------------------------------------------
-- YETKI (MEZATCI)
-----------------------------------------------------------------------------
-- Mezat acabilecek / yonetebilecek job(lar). Anahtar = job adi, deger = min grade.
Config.AuctioneerJobs = {
    ['mezat'] = 0,
    -- ['police'] = 3,
}

-- Mezat komutu (mezatci paneli acar)
Config.Command = 'mezat'

-----------------------------------------------------------------------------
-- KONUM
-----------------------------------------------------------------------------
-- Mezat alani merkezi + giris kontrol bolgesi (fis olmadan girilemez)
Config.Location = {
    label = 'Mezat Evi',
    -- Alan merkezi (blip + duyuru marker)
    center = vec3(-1370.0, -466.0, 33.0),
    blip = {
        enabled = true,
        sprite = 500,
        color = 46,
        scale = 0.8,
    },
    -- Giris bolgesi (fis kontrolu) - ox_lib sphere zone
    entryZone = {
        coords = vec3(-1370.0, -466.0, 33.0),
        radius = 25.0,
    },
    -- Fis satis noktasi (ox_target)
    ticketDesk = {
        coords = vec3(-1360.0, -470.0, 33.0),
        heading = 120.0,
        model = 'a_m_y_business_01', -- ped model (opsiyonel; nil ise sadece target zone)
        useTarget = true,
        targetRadius = 1.5,
    },
    -- Mezatci sahne noktasi (podyum) - tabela propu burada tutulur gibi referans
    stage = vec3(-1371.0, -462.0, 33.0),
}

-----------------------------------------------------------------------------
-- DUI - BUYUK EKRAN
-----------------------------------------------------------------------------
-- Alandaki ekran objesi. Bu objenin texture'i runtime txd ile degistirilir.
Config.Screen = {
    enabled = true,
    -- Ekran olarak kullanilacak world prop/objesi (haritada olmali) ya da spawn edilecek prop.
    prop = 'prop_tv_flat_02',
    spawn = true, -- true: prop'u biz spawnlariz; false: haritadaki mevcut objeyi kullan
    coords = vec4(-1371.5, -461.0, 34.2, 210.0),
    -- Degistirilecek texture dictionary/name (prop'a gore). prop_tv_flat_02 icin:
    txd = 'prop_tv_flat_02',
    txn = 'p_tv_flat_02_screen',
    -- DUI cozunurlugu
    duiWidth = 1280,
    duiHeight = 720,
}

-----------------------------------------------------------------------------
-- DUI - TABELA PROPU (MEZATCININ ELINDE)
-----------------------------------------------------------------------------
-- Mezatci teklif verdiginde/gosterdiginde elinde tuttugu tabela; ustunde rakam yazar.
Config.SignProp = {
    model = 'prop_cs_protest_sign_01',
    -- El bone (sag el = 28422 / 18905). Attach ofsetleri prop'a gore ayarla.
    bone = 28422,
    pos = vec3(0.12, 0.0, -0.02),
    rot = vec3(-90.0, 0.0, 0.0),
    -- Degistirilecek texture
    txd = 'prop_cs_protest_sign_01',
    txn = 'protest_sign_01',
    duiWidth = 512,
    duiHeight = 512,
}

-----------------------------------------------------------------------------
-- FIS (KATILIM)
-----------------------------------------------------------------------------
Config.Ticket = {
    item = 'mezat_fisi',      -- ox_inventory item adi (items.lua'ya eklenmeli)
    defaultFee = 5000,        -- varsayilan katilim ucreti (mezatci degistirebilir)
    refundLosers = false,     -- true: kazanamayanlara fis ucreti iade
    capacityEnabled = false,  -- true: kapasite limiti uygula
    capacity = 30,            -- max katilimci (capacityEnabled ise)
    removeOnEntry = false,    -- true: alana girince fis tuketilir; false: mezat boyunca durur
}

-----------------------------------------------------------------------------
-- TEKLIF
-----------------------------------------------------------------------------
Config.Bidding = {
    defaultMinIncrement = 1000, -- varsayilan minimum artis
    lotDuration = 60,           -- her lot icin saniye
    antiSnipe = 10,             -- son X sn'de teklif gelirse
    antiSnipeExtend = 15,       -- sure X sn uzar
    allowBuyout = true,         -- anlik al destegi (mezatci lot basina belirler)
    allowAutoBid = true,        -- otomatik (proxy) teklif
}

-----------------------------------------------------------------------------
-- LOT TIPLERI
-----------------------------------------------------------------------------
-- Satilabilecek urun tipleri. Teslim mantigi server/delivery.lua + asagidaki hook.
Config.LotTypes = {
    vehicle = { enabled = true, label = 'Arac' },
    business = { enabled = true, label = 'Benzinlik / Isletme' },
    item = { enabled = true, label = 'Item' },
}

-- Arac teslim ayarlari
Config.Vehicle = {
    defaultGarage = 'pillboxgarage',
    plateFormat = 'MEZAT###', -- # = rakam, @ = harf
}

-----------------------------------------------------------------------------
-- TESLIM HOOK'LARI
-- Kazanan belli olunca cagrilir. return true = basarili.
-----------------------------------------------------------------------------
Config.Delivery = {
    -- Benzinlik / isletme teslimi. Kendi management sistemine burada bagla.
    -- payload = mezatcinin lot eklerken girdigi { businessId = ..., label = ... }
    business = function(src, payload)
        -- ORNEK (qbx_management vb.):
        -- exports['qbx_management']:SetBoss(payload.businessId, Bridge.GetIdentifier(src))
        -- return true
        print(('[fd-acikarttirma] Isletme teslimi (HOOK BOS): src=%s payload=%s'):format(src, json.encode(payload)))
        return true
    end,
}

-----------------------------------------------------------------------------
-- LOG (DISCORD WEBHOOK)
-----------------------------------------------------------------------------
Config.Webhook = {
    enabled = false,
    url = '', -- https://discord.com/api/webhooks/...
    botName = 'Mezat',
    color = 3447003,
}

-----------------------------------------------------------------------------
-- TELEFON HOOK (opsiyonel)
-- Mezat duyurusu yapilinca cagrilir (server-side). lb-phone/qb-phone app'i buraya baglanabilir.
-----------------------------------------------------------------------------
Config.Phone = {
    enabled = false,
    notify = function(auction)
        -- ORNEK: tum oyunculara telefon bildirimi gonder
        -- return
    end,
}
