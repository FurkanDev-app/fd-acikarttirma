import { useState } from 'react'
import { fetchNui } from '../shared/nui'
import type { AuctionState, LotView, CallResult } from '../shared/types'
import { money, secs, LOT_LABELS } from '../shared/format'

interface Props {
  state: AuctionState
  lot: LotView | null
  notify: (msg: string, ok: boolean) => void
}

export default function BidPanel({ state, lot, notify }: Props) {
  const [custom, setCustom] = useState('')
  const [auto, setAuto] = useState('')

  if (state.state !== 'live' || !lot || !lot.running) {
    return (
      <div className="empty">
        <div className="big">⏳</div>
        <div>{state.state === 'registration' ? 'Mezat henüz başlamadı. Lütfen bekleyin.' : 'Şu an aktif lot yok.'}</div>
      </div>
    )
  }

  const base = lot.hasBid ? lot.highBid : lot.startPrice
  const nextMin = lot.hasBid ? lot.highBid + lot.minIncrement : lot.startPrice
  const urgent = lot.timeLeft <= 10

  const bid = async (amount: number) => {
    if (!amount || amount < nextMin) return notify(`En az ${money(nextMin)} $ vermelisiniz`, false)
    const res = await fetchNui<CallResult>('placeBid', amount)
    if (res?.ok) { notify(res.leader ? 'En yüksek teklif sizin!' : 'Teklif verildi', true); setCustom('') }
    else notify(res?.msg ?? 'Hata', false)
  }

  const autoBid = async () => {
    const m = Number(auto)
    if (!m || m < nextMin) return notify(`Otomatik tavan en az ${money(nextMin)} $ olmalı`, false)
    const res = await fetchNui<CallResult>('placeAutoBid', m)
    if (res?.ok) { notify('Otomatik teklif ayarlandı', true); setAuto('') }
    else notify(res?.msg ?? 'Hata', false)
  }

  const buyout = async () => {
    const res = await fetchNui<CallResult>('buyout')
    if (res?.ok) notify('Anlık satın alındı!', true)
    else notify(res?.msg ?? 'Hata', false)
  }

  const quick = [lot.minIncrement, lot.minIncrement * 5, lot.minIncrement * 10]

  return (
    <>
      <div className="live-hero">
        <div className="lot-sub">Lot {lot.index} / {lot.total} · {LOT_LABELS[lot.type]}</div>
        <div className="lot-name">{lot.label}</div>
        <div className="price-big">{money(base)} $</div>
        <div className="price-label">{lot.hasBid ? 'Güncel Teklif' : 'Başlangıç Fiyatı'}</div>
        {lot.hasBid && <div className="leader-line">Lider: <b>{lot.highBidderName}</b></div>}
        <div className={`timer ${urgent ? 'urgent' : ''}`}><span className="dot" />{secs(lot.timeLeft)}</div>
      </div>

      <div>
        <div className="section-title">Hızlı Teklif</div>
        <div className="quick-bids" style={{ marginTop: 10 }}>
          {quick.map((q, i) => (
            <button key={i} className="btn" onClick={() => bid(base + q)}>+{money(q)}</button>
          ))}
        </div>
      </div>

      <div className="grid-2">
        <div className="field">
          <label>Özel Teklif ($)</label>
          <input type="number" min={nextMin} value={custom} onChange={(e) => setCustom(e.target.value)} placeholder={`min ${money(nextMin)}`} />
        </div>
        <div className="field" style={{ justifyContent: 'flex-end' }}>
          <button className="btn primary" onClick={() => bid(Number(custom))}>Teklif Ver</button>
        </div>
      </div>

      <div className="grid-2">
        <div className="field">
          <label>Otomatik Teklif — Max Bütçe ($)</label>
          <input type="number" min={nextMin} value={auto} onChange={(e) => setAuto(e.target.value)} placeholder="sistem sizin için artırır" />
        </div>
        <div className="field" style={{ justifyContent: 'flex-end' }}>
          <button className="btn" onClick={autoBid}>Otomatik Ayarla</button>
        </div>
      </div>

      {lot.buyout ? (
        <button className="btn wide" style={{ borderColor: 'var(--gold-deep)', color: 'var(--gold)' }} onClick={buyout}>
          ⚡ Anlık Al — {money(lot.buyout)} $
        </button>
      ) : null}

      <div className="hint">Teklif verdiğinizde tutar bankanızdan bloke edilir; geçilirseniz iade edilir.</div>
    </>
  )
}
