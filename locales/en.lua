Locales = Locales or {}

Locales['en'] = {
    not_auctioneer = 'You need auctioneer permission for this.',
    auction_exists = 'There is already an active auction.',
    lots_locked = 'Cannot add lots after the auction started.',
    invalid_lot_type = 'Invalid lot type.',
    no_lots = 'Add at least one lot first.',
    no_auction = 'There is no active auction.',
    not_live = 'The auction is not live yet.',
    auctioneer_cant_bid = 'The auctioneer cannot bid.',
    need_ticket = 'You need a ticket to bid.',
    need_ticket_desk = 'Buy a ticket at the ticket desk first.',
    no_active_lot = 'There is no active lot right now.',
    registration_closed = 'Ticket sales are closed.',

    bid_too_low = 'You must bid at least $%s.',
    not_enough_money = 'You do not have enough money.',
    bid_insolvent = 'Insufficient balance, your bid was cancelled.',
    autobid_disabled = 'Auto bidding is disabled.',
    buyout_disabled = 'Buyout is disabled.',
    no_buyout = 'This lot has no buyout.',

    already_have_ticket = 'You already have a ticket.',
    capacity_full = 'Participation capacity is full.',
    cant_carry_ticket = 'The ticket did not fit in your inventory.',
    ticket_bought = 'Ticket purchased. You may enter the auction area.',
    ticket_failed = 'Could not buy the ticket.',
    ticket_detail = 'Auction: %s | No: #%d | Date: %s | Paid: $%s',
    buy_ticket_header = 'Auction Ticket',
    buy_ticket_content = 'Entry fee is **$%s**. Do you want to buy a ticket?',
    press_buy_ticket = '[E] Buy Ticket',
    target_buy_ticket = 'Buy Ticket',

    entry_title = 'Auction House',
    entry_denied = 'You need a valid ticket to enter this area.',

    won_lot = 'You won: %s ($%s)',
    delivery_failed = 'The prize could not be delivered, you were refunded.',
    delivered_vehicle = 'Vehicle delivered: %s (%s)',
    delivered_business = 'Business delivered: %s',
    delivered_item = 'Delivered %dx %s.',

    lot_sold_to = '%s -> %s ($%s)',
    lot_unsold = '%s was not sold.',
    announce_title = 'Auction Announcement',
    announce_body = '%s has started! Entry fee: $%s. Get your ticket and come over.',
    announce_scheduled = '%s | Starts: %s',
}
