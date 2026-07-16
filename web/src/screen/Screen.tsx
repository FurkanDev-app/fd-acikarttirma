import { useEffect, useState } from 'react'
import { useDuiEvent, isEnvBrowser } from '../shared/nui'
import { money, secs, LOT_LABELS } from '../shared/format'

interface ScreenData {
  active: boolean
  label?: string
  type?: string
  index?: number
  total?: number
  startPrice?: number
  highBid?: number
  hasBid?: boolean
  leader?: string | null
  buyout?: number | null
  timeLeft?: number
}

const DEMO: ScreenData = isEnvBrowser()
  ? { active: true, label: 'Pegassi Adder', type: 'vehicle', index: 1, total: 4, startPrice: 500000, highBid: 640000, hasBid: true, leader: 'Furkan', timeLeft: 23 }
  : { active: false }

export default function Screen() {
  const [data, setData] = useState<ScreenData>(DEMO)
  const [sold, setSold] = useState<{ label: string; price: number; winnerName?: string | null } | null>(null)

  useDuiEvent('screen', (msg) => {
    if (msg.event === 'sold') {
      setSold(msg.data)
      window.setTimeout(() => setSold(null), 5000)
      return
    }
    if (msg.data) setData(msg.data)
  })

  useEffect(() => {
    if (sold) setData((d) => ({ ...d }))
  }, [sold])

  if (sold) {
    return (
      <div className="screen sold-screen">
        <div className="brand">⚖ MEZAT</div>
        <div className="sold-stamp">{sold.winnerName ? 'SATILDI' : 'SATILMADI'}</div>
        <div className="sold-name">{sold.label}</div>
        {sold.winnerName ? (
          <div className="sold-info">
            <b>{sold.winnerName}</b> — {money(sold.price)} $
          </div>
        ) : (
          <div className="sold-info">Teklif alınamadı</div>
        )}
      </div>
    )
  }

  if (!data.active) {
    return (
      <div className="screen idle-screen">
        <div className="brand big">⚖ MEZAT EVİ</div>
        <div className="idle-sub">Bir sonraki lot birazdan başlıyor…</div>
      </div>
    )
  }

  const price = data.hasBid ? data.highBid : data.startPrice
  const urgent = (data.timeLeft ?? 99) <= 10

  return (
    <div className="screen">
      <div className="screen-top">
        <div className="brand">⚖ MEZAT</div>
        <div className="lot-count">LOT {data.index} / {data.total}</div>
      </div>

      <div className="screen-mid">
        <div className="type-tag">{LOT_LABELS[data.type ?? ''] ?? data.type}</div>
        <h1 className="s-lot-name">{data.label}</h1>
        <div className="s-price">{money(price)} <span className="cur">$</span></div>
        <div className="s-price-label">{data.hasBid ? 'GÜNCEL TEKLİF' : 'BAŞLANGIÇ FİYATI'}</div>
      </div>

      <div className="screen-bottom">
        <div className="s-leader">
          {data.hasBid ? <>En yüksek: <b>{data.leader}</b></> : 'Henüz teklif yok'}
        </div>
        <div className={`s-timer ${urgent ? 'urgent' : ''}`}>{secs(data.timeLeft)}</div>
      </div>
    </div>
  )
}
