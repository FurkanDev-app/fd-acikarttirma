Locales = Locales or {}

Locales['tr'] = {
    -- yetki / durum
    not_auctioneer = 'Bu islem icin mezatci yetkisi gerekli.',
    auction_exists = 'Zaten aktif bir mezat var.',
    lots_locked = 'Mezat basladiktan sonra lot eklenemez.',
    invalid_lot_type = 'Gecersiz lot turu.',
    no_lots = 'Once en az bir lot ekleyin.',
    no_auction = 'Aktif bir mezat yok.',
    not_live = 'Mezat henuz canli degil.',
    auctioneer_cant_bid = 'Mezatci teklif veremez.',
    need_ticket = 'Teklif vermek icin fisiniz olmali.',
    need_ticket_desk = 'Once fis satis noktasindan fis almalisiniz.',
    no_active_lot = 'Su an aktif bir lot yok.',
    registration_closed = 'Fis satisi kapandi.',

    -- teklif
    bid_too_low = 'En az %s $ teklif vermelisiniz.',
    not_enough_money = 'Yeterli paraniz yok.',
    bid_insolvent = 'Bakiyeniz yetmedi, teklifiniz iptal edildi.',
    autobid_disabled = 'Otomatik teklif kapali.',
    buyout_disabled = 'Anlik al kapali.',
    no_buyout = 'Bu lot icin anlik al yok.',

    -- fis
    already_have_ticket = 'Zaten bir fisiniz var.',
    capacity_full = 'Katilim kontenjani doldu.',
    cant_carry_ticket = 'Fis envanterinize sigmadi.',
    ticket_bought = 'Fis alindi. Mezat alanina girebilirsiniz.',
    ticket_failed = 'Fis alinamadi.',
    ticket_detail = 'Mezat: %s | No: #%d | Tarih: %s | Odenen: %s $',
    buy_ticket_header = 'Mezat Fisi',
    buy_ticket_content = 'Katilim ucreti **%s $**. Fis almak istiyor musunuz?',
    press_buy_ticket = '[E] Fis Al',
    target_buy_ticket = 'Fis Al',

    -- giris
    entry_title = 'Mezat Evi',
    entry_denied = 'Bu alana girmek icin gecerli bir fisiniz olmali.',

    -- teslim
    won_lot = 'Kazandiniz: %s (%s $)',
    delivery_failed = 'Odul teslim edilemedi, paraniz iade edildi.',
    delivered_vehicle = 'Arac teslim edildi: %s (%s)',
    delivered_business = 'Isletme teslim edildi: %s',
    delivered_item = '%dx %s teslim edildi.',

    -- yayin
    lot_sold_to = '%s -> %s (%s $)',
    lot_unsold = '%s satilmadi.',
    announce_title = 'Mezat Duyurusu',
    announce_body = '%s basladi! Katilim ucreti: %s $. Fisinizi alip alana gelin.',
    announce_scheduled = '%s | Baslangic: %s',
}
