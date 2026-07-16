import type { CSSProperties } from 'react'
import type { LotView } from '../shared/types'
import { money, secs, LOT_LABELS } from '../shared/format'
import { useCountUp, useFlashOnChange, useTimerPct } from '../shared/motion'

interface Props {
  lot: LotView
  mine?: boolean
}

export default function LiveHero({ lot, mine }: Props) {
  const value = lot.hasBid ? lot.highBid : lot.startPrice
  const shown = useCountUp(value)
  const flash = useFlashOnChange(value)
  const pct = useTimerPct(lot.index, lot.timeLeft)
  const urgent = lot.timeLeft <= 10

  return (
    <div className={`live-hero ${mine ? 'mine' : ''}`}>
      <div className="lot-sub">Lot {lot.index} / {lot.total} · {LOT_LABELS[lot.type]}</div>
      <div className="lot-name">{lot.label}</div>
      <div className={`price-big ${flash ? 'flash' : ''}`}>{money(shown)} $</div>
      <div className="price-label">{lot.hasBid ? 'Güncel Teklif' : 'Başlangıç Fiyatı'}</div>

      {mine ? (
        <div className="mine-tag">★ En yüksek teklif sizde</div>
      ) : lot.hasBid ? (
        <div className="leader-line">Lider: <b>{lot.highBidderName}</b></div>
      ) : (
        <div className="leader-line">Henüz teklif yok</div>
      )}

      <div style={{ display: 'flex', justifyContent: 'center', marginTop: 16 }}>
        <div className={`ring ${urgent ? 'urgent' : ''}`} style={{ '--pct': pct } as CSSProperties}>
          <span className="ring-val">{secs(lot.timeLeft)}</span>
        </div>
      </div>
    </div>
  )
}
