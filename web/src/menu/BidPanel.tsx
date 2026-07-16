import { useEffect, useState } from 'react'
import { fetchNui } from '../shared/nui'
import type { AuctionState, LotView, CallResult } from '../shared/types'
import { money } from '../shared/format'
import { useBidFeed } from '../shared/motion'
import LiveHero from './LiveHero'

interface Props {
  state: AuctionState
  lot: LotView | null
  notify: (msg: string, ok: boolean) => void
}

export default function BidPanel({ state, lot, notify }: Props) {
  const [custom, setCustom] = useState('')
  const [auto, setAuto] = useState('')
  const [mine, setMine] = useState(false)

  const feed = useBidFeed(lot?.index, lot?.hasBid, lot?.highBid, lot?.highBidderName)

  // lider degisince "sizin" durumunu guncelle (teklif sonucu leader alanindan gelir)
  useEffect(() => {
    if (!lot?.hasBid) setMine(false)
  }, [lot?.index, lot?.hasBid])

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

  const bid = async (amount: number) => {
    if (!amount || amount < nextMin) return notify(`En az ${money(nextMin)} $ vermelisiniz`, false)
    const res = await fetchNui<CallResult & { leader?: boolean }>('placeBid', amount)
    if (res?.ok) { setMine(!!res.leader); notify(res.leader ? 'En yüksek teklif sizin!' : 'Teklif verildi', true); setCustom('') }
    else notify(res?.msg ?? 'Hata', false)
  }

  const autoBid = async () => {
    const m = Number(auto)
    if (!m || m < nextMin) return notify(`Otomatik tavan en az ${money(nextMin)} $ olmalı`, false)
    const res = await fetchNui<CallResult & { leader?: boolean }>('placeAutoBid', m)
    if (res?.ok) { setMine(!!res.leader); notify('Otomatik teklif ayarlandı', true); setAuto('') }
    else notify(res?.msg ?? 'Hata', false)
  }

  const buyout = async () => {
    const res = await fetchNui<CallResult>('buyout')
    if (res?.ok) notify('Anlık satın alındı!', true)
    else notify(res?.msg ?? 'Hata', false)
  }

  const quick = [lot.minIncrement, lot.minIncrement * 5, lot.minIncrement * 10]

  return (
    <div className="stagger" style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <LiveHero lot={lot} mine={mine} />

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

      {feed.length > 0 && (
        <div>
          <div className="section-title">Son Teklifler</div>
          <div className="feed" style={{ marginTop: 10 }}>
            {feed.map((f) => (
              <div className="feed-row" key={f.id}>
                <span className="fr-name">{f.name}</span>
                <span className="fr-amt">{money(f.amount)} $</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="hint">Teklif verdiğinizde tutar bankanızdan bloke edilir; geçilirseniz iade edilir.</div>
    </div>
  )
}
