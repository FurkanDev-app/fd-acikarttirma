import { useCallback, useEffect, useState } from 'react'
import { fetchNui, useNuiEvent, isEnvBrowser } from '../shared/nui'
import type { AuctionState, LotView } from '../shared/types'
import AuctioneerPanel from './AuctioneerPanel'
import BidPanel from './BidPanel'

type View = 'auctioneer' | 'bid'

export default function App() {
  const [visible, setVisible] = useState(isEnvBrowser())
  const [view, setView] = useState<View>('auctioneer')
  const [state, setState] = useState<AuctionState>({ active: false })
  const [lot, setLot] = useState<LotView | null>(null)
  const [flash, setFlash] = useState<{ msg: string; ok: boolean } | null>(null)

  const refresh = useCallback(async () => {
    const res = await fetchNui<AuctionState>('getState')
    if (res) {
      setState(res)
      setLot(res.lot ?? null)
    }
  }, [])

  useNuiEvent('open', (p) => {
    setView(p.view)
    if (p.state) {
      setState(p.state)
      setLot(p.state.lot ?? null)
    }
    setVisible(true)
    refresh()
  })

  useNuiEvent('close', () => setVisible(false))
  useNuiEvent('state', (p) => {
    setState(p.state ?? { active: false })
    setLot(p.state?.lot ?? null)
  })
  useNuiEvent('lot', (p) => setLot(p.lot ?? null))
  useNuiEvent('sold', (p) => {
    setFlash({ ok: true, msg: p.data?.winnerName ? `${p.data.label} satıldı` : `${p.data?.label} satılmadı` })
  })

  const close = useCallback(() => {
    fetchNui('close')
    setVisible(false)
  }, [])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [close])

  const notify = useCallback((msg: string, ok: boolean) => {
    setFlash({ msg, ok })
    window.setTimeout(() => setFlash((f) => (f && f.msg === msg ? null : f)), 3200)
  }, [])

  if (!visible) return null

  return (
    <div className="overlay" onMouseDown={(e) => e.target === e.currentTarget && close()}>
      <div className="panel">
        <header className="panel-head">
          <h1>
            <span className="gavel">⚖</span>
            {view === 'auctioneer' ? 'Mezat Yönetimi' : 'Mezat'}
            {state.active && state.label ? <span className="sub">· {state.label}</span> : null}
          </h1>
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            {state.active && (
              <span className={`badge ${state.state === 'live' ? 'live' : 'reg'}`}>
                {state.state === 'live' ? 'CANLI' : state.state === 'registration' ? 'KAYIT' : 'KAPALI'}
              </span>
            )}
            <button className="icon-btn" onClick={close} title="Kapat (ESC)">✕</button>
          </div>
        </header>

        {flash && (
          <div
            style={{
              padding: '10px 22px',
              fontSize: '0.86rem',
              color: flash.ok ? 'var(--success)' : 'var(--danger)',
              borderBottom: '1px solid var(--border)',
              background: 'var(--surface-2)',
            }}
          >
            {flash.msg}
          </div>
        )}

        <div className="panel-body">
          {view === 'auctioneer' ? (
            <AuctioneerPanel state={state} lot={lot} refresh={refresh} notify={notify} />
          ) : (
            <BidPanel state={state} lot={lot} notify={notify} />
          )}
        </div>
      </div>
    </div>
  )
}
