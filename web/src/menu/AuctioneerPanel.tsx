import { useState } from 'react'
import { fetchNui } from '../shared/nui'
import type { AuctionState, LotType, LotView, CallResult } from '../shared/types'
import { money, secs, LOT_LABELS } from '../shared/format'

interface Props {
  state: AuctionState
  lot: LotView | null
  refresh: () => Promise<void>
  notify: (msg: string, ok: boolean) => void
}

export default function AuctioneerPanel({ state, lot, refresh, notify }: Props) {
  // --- yeni mezat olustur ---
  if (!state.active) {
    return <CreateForm refresh={refresh} notify={notify} />
  }

  if (state.state === 'live') {
    return <LiveControl state={state} lot={lot} refresh={refresh} notify={notify} />
  }

  // registration
  return <Registration state={state} refresh={refresh} notify={notify} />
}

function CreateForm({ refresh, notify }: { refresh: () => Promise<void>; notify: Props['notify'] }) {
  const [label, setLabel] = useState('Mezat Evi')
  const [fee, setFee] = useState('5000')

  const create = async () => {
    const res = await fetchNui<CallResult>('createAuction', { label, fee: Number(fee) })
    if (res?.ok) {
      notify('Mezat oluşturuldu. Şimdi lot ekleyin.', true)
      refresh()
    } else notify(res?.msg ?? 'Hata', false)
  }

  return (
    <>
      <div className="empty">
        <div className="big">⚖</div>
        <div>Aktif mezat yok. Yeni bir mezat başlatın.</div>
      </div>
      <div className="grid-2">
        <div className="field">
          <label>Mezat Adı</label>
          <input value={label} onChange={(e) => setLabel(e.target.value)} />
        </div>
        <div className="field">
          <label>Katılım Ücreti (fiş)</label>
          <input type="number" min={0} value={fee} onChange={(e) => setFee(e.target.value)} />
        </div>
      </div>
      <button className="btn primary wide" onClick={create}>Mezatı Oluştur</button>
    </>
  )
}

function Registration({ state, refresh, notify }: { state: AuctionState; refresh: () => Promise<void>; notify: Props['notify'] }) {
  const [type, setType] = useState<LotType>('vehicle')
  const [label, setLabel] = useState('')
  const [startPrice, setStartPrice] = useState('50000')
  const [minInc, setMinInc] = useState('1000')
  const [buyout, setBuyout] = useState('')
  // payload alanlari
  const [pv, setPv] = useState({ model: '', plate: '', garage: '' })
  const [pb, setPb] = useState({ businessId: '', label: '' })
  const [pi, setPi] = useState({ item: '', count: '1' })

  const addLot = async () => {
    let payload: Record<string, unknown> = {}
    let lotLabel = label
    if (type === 'vehicle') {
      if (!pv.model) return notify('Araç modeli gerekli', false)
      payload = { model: pv.model, plate: pv.plate || undefined, garage: pv.garage || undefined }
      lotLabel = label || pv.model
    } else if (type === 'business') {
      if (!pb.businessId) return notify('İşletme ID gerekli', false)
      payload = { businessId: pb.businessId, label: pb.label || undefined }
      lotLabel = label || pb.label || pb.businessId
    } else {
      if (!pi.item) return notify('Item adı gerekli', false)
      payload = { item: pi.item, count: Number(pi.count) || 1 }
      lotLabel = label || `${pi.count}x ${pi.item}`
    }

    const res = await fetchNui<CallResult>('addLot', {
      type,
      label: lotLabel,
      startPrice: Number(startPrice),
      minIncrement: Number(minInc),
      buyout: buyout ? Number(buyout) : undefined,
      payload,
    })
    if (res?.ok) {
      notify('Lot eklendi', true)
      setLabel(''); setPv({ model: '', plate: '', garage: '' }); setPb({ businessId: '', label: '' }); setPi({ item: '', count: '1' })
      refresh()
    } else notify(res?.msg ?? 'Hata', false)
  }

  const start = async () => {
    const res = await fetchNui<CallResult>('startAuction')
    if (res?.ok) { notify('Mezat başladı!', true); refresh() }
    else notify(res?.msg ?? 'Hata', false)
  }

  const closeAuction = async () => {
    const res = await fetchNui<CallResult>('closeAuction')
    if (res?.ok) { notify('Mezat kapatıldı', true); refresh() }
  }

  const lots = state.lots ?? []

  return (
    <>
      <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        <span className="badge">👤 {state.participants ?? 0} katılımcı</span>
        <span className="badge">🎟 {money(state.fee)} $ fiş</span>
        <span className="badge">📦 {lots.length} lot</span>
      </div>

      <div>
        <div className="section-title">Lot Ekle</div>
        <div className="grid-2" style={{ marginTop: 10 }}>
          <div className="field">
            <label>Tür</label>
            <select value={type} onChange={(e) => setType(e.target.value as LotType)}>
              <option value="vehicle">Araç</option>
              <option value="business">Benzinlik / İşletme</option>
              <option value="item">Item</option>
            </select>
          </div>
          <div className="field">
            <label>Etiket (opsiyonel)</label>
            <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Görünen ad" />
          </div>
        </div>

        {type === 'vehicle' && (
          <div className="grid-2" style={{ marginTop: 12 }}>
            <div className="field"><label>Araç modeli (spawn)</label><input value={pv.model} onChange={(e) => setPv({ ...pv, model: e.target.value })} placeholder="ör. adder" /></div>
            <div className="field"><label>Plaka (opsiyonel)</label><input value={pv.plate} onChange={(e) => setPv({ ...pv, plate: e.target.value })} placeholder="otomatik" /></div>
          </div>
        )}
        {type === 'business' && (
          <div className="grid-2" style={{ marginTop: 12 }}>
            <div className="field"><label>İşletme ID</label><input value={pb.businessId} onChange={(e) => setPb({ ...pb, businessId: e.target.value })} placeholder="ör. benzinlik_1" /></div>
            <div className="field"><label>İşletme adı</label><input value={pb.label} onChange={(e) => setPb({ ...pb, label: e.target.value })} placeholder="LTD Benzinlik" /></div>
          </div>
        )}
        {type === 'item' && (
          <div className="grid-2" style={{ marginTop: 12 }}>
            <div className="field"><label>Item adı</label><input value={pi.item} onChange={(e) => setPi({ ...pi, item: e.target.value })} placeholder="ör. lockpick" /></div>
            <div className="field"><label>Adet</label><input type="number" min={1} value={pi.count} onChange={(e) => setPi({ ...pi, count: e.target.value })} /></div>
          </div>
        )}

        <div className="grid-2" style={{ marginTop: 12 }}>
          <div className="field"><label>Başlangıç fiyatı (alt limit)</label><input type="number" min={0} value={startPrice} onChange={(e) => setStartPrice(e.target.value)} /></div>
          <div className="field"><label>Min. artış</label><input type="number" min={1} value={minInc} onChange={(e) => setMinInc(e.target.value)} /></div>
        </div>
        <div className="field" style={{ marginTop: 12 }}>
          <label>Anlık Al fiyatı (opsiyonel)</label>
          <input type="number" min={0} value={buyout} onChange={(e) => setBuyout(e.target.value)} placeholder="boş = kapalı" />
        </div>
        <button className="btn wide" style={{ marginTop: 14 }} onClick={addLot}>+ Lot Ekle</button>
      </div>

      {lots.length > 0 && (
        <div>
          <div className="section-title">Lotlar</div>
          <div className="lot-list" style={{ marginTop: 10 }}>
            {lots.map((l) => (
              <div className="lot-card" key={l.index}>
                <div className="lot-idx">{l.index}</div>
                <div className="lot-main">
                  <div className="name">{l.label}</div>
                  <div className="meta">{money(l.startPrice)} $ · +{money(l.minIncrement)}{l.buyout ? ` · Anlık ${money(l.buyout)} $` : ''}</div>
                </div>
                <span className="lot-type-tag">{LOT_LABELS[l.type]}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="btn-row">
        <button className="btn primary" onClick={start} disabled={lots.length === 0} style={{ flex: 1 }}>▶ Mezatı Başlat</button>
        <button className="btn danger" onClick={closeAuction}>İptal</button>
      </div>
    </>
  )
}

function LiveControl({ state, lot, refresh, notify }: { state: AuctionState; lot: LotView | null; refresh: () => Promise<void>; notify: Props['notify'] }) {
  const next = async () => {
    const res = await fetchNui<CallResult & { finished?: boolean }>('nextLot')
    if (res?.ok) { notify(res.finished ? 'Mezat tamamlandı' : 'Sonraki lota geçildi', true); refresh() }
    else notify(res?.msg ?? 'Hata', false)
  }
  const closeAuction = async () => {
    const res = await fetchNui<CallResult>('closeAuction')
    if (res?.ok) { notify('Mezat kapatıldı', true); refresh() }
  }
  const urgent = (lot?.timeLeft ?? 99) <= 10

  return (
    <>
      <div className="live-hero">
        {lot ? (
          <>
            <div className="lot-sub">Lot {lot.index} / {lot.total} · {LOT_LABELS[lot.type]}</div>
            <div className="lot-name">{lot.label}</div>
            <div className="price-big">{money(lot.hasBid ? lot.highBid : lot.startPrice)} $</div>
            <div className="price-label">{lot.hasBid ? 'Güncel Teklif' : 'Başlangıç Fiyatı'}</div>
            {lot.hasBid && <div className="leader-line">Lider: <b>{lot.highBidderName}</b></div>}
            <div className={`timer ${urgent ? 'urgent' : ''}`}><span className="dot" />{secs(lot.timeLeft)}</div>
          </>
        ) : (
          <div className="hint">Aktif lot yok</div>
        )}
      </div>
      <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        <span className="badge">👤 {state.participants ?? 0} katılımcı</span>
      </div>
      <div className="btn-row">
        <button className="btn primary" onClick={next} style={{ flex: 1 }}>⏭ Sonraki Lot / Çekiç</button>
        <button className="btn danger" onClick={closeAuction}>Bitir</button>
      </div>
      <div className="hint">Süre dolunca lot otomatik satılır. "Sonraki Lot" ile erken çekiç indirebilirsiniz.</div>
    </>
  )
}
