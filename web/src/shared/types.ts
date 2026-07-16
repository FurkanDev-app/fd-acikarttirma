export type LotType = 'vehicle' | 'business' | 'item'

export interface LotView {
  index: number
  total: number
  type: LotType
  label: string
  startPrice: number
  minIncrement: number
  buyout?: number | null
  highBid: number
  hasBid: boolean
  highBidderName?: string | null
  timeLeft: number
  running: boolean
}

export interface LotSummary {
  index: number
  type: LotType
  label: string
  startPrice: number
  minIncrement: number
  buyout?: number | null
  sold: boolean
}

export interface AuctionState {
  active: boolean
  id?: number
  label?: string
  state?: 'registration' | 'live' | 'closed'
  fee?: number
  auctioneerId?: number
  participants?: number
  isAuctioneer?: boolean
  isParticipant?: boolean
  lotCount?: number
  lots?: LotSummary[] | null
  lot?: LotView | null
}

export interface CallResult {
  ok: boolean
  msg?: string
  [k: string]: unknown
}
