import { useEffect, useRef, useState } from 'react'

/** Onceki render'daki degeri dondurur. */
export function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T | undefined>(undefined)
  useEffect(() => {
    ref.current = value
  }, [value])
  return ref.current
}

/** Hedef sayiya ease-out ile animasyonlu sayar. */
export function useCountUp(target: number, duration = 650): number {
  const [display, setDisplay] = useState(target)
  const fromRef = useRef(target)
  const rafRef = useRef<number | null>(null)

  useEffect(() => {
    const from = fromRef.current
    const to = target
    if (from === to) return
    const start = performance.now()
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (reduce) {
      fromRef.current = to
      setDisplay(to)
      return
    }
    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / duration)
      const eased = 1 - Math.pow(1 - t, 4) // ease-out-quart
      const val = Math.round(from + (to - from) * eased)
      setDisplay(val)
      if (t < 1) {
        rafRef.current = requestAnimationFrame(tick)
      } else {
        fromRef.current = to
      }
    }
    rafRef.current = requestAnimationFrame(tick)
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current)
      fromRef.current = to
    }
  }, [target, duration])

  return display
}

/** Deger her degistiginde kisa bir "flash" bayragi doner (className toggle icin). */
export function useFlashOnChange<T>(value: T, ms = 700): boolean {
  const [flash, setFlash] = useState(false)
  const prev = usePrevious(value)
  useEffect(() => {
    if (prev === undefined || prev === value) return
    setFlash(true)
    const id = window.setTimeout(() => setFlash(false), ms)
    return () => window.clearTimeout(id)
  }, [value, prev, ms])
  return flash
}

/**
 * Sure halkasi yuzdesi: lot icinde gorulen en yuksek timeLeft'i "tam" kabul eder.
 * Anti-snipe uzatmalarinda taban yukselirse tabana uyar. 0-100 doner.
 */
export function useTimerPct(lotIndex: number | undefined, timeLeft: number | undefined): number {
  const ref = useRef<{ lot?: number; full: number }>({ full: 1 })
  if (lotIndex !== ref.current.lot) {
    ref.current = { lot: lotIndex, full: Math.max(1, timeLeft ?? 1) }
  } else if ((timeLeft ?? 0) > ref.current.full) {
    ref.current.full = timeLeft ?? ref.current.full
  }
  const pct = Math.max(0, Math.min(100, ((timeLeft ?? 0) / ref.current.full) * 100))
  return pct
}

export interface FeedEntry {
  id: number
  name: string
  amount: number
}

/**
 * highBid artislarindan istemci-tarafli "son teklifler" akisi turetir.
 * lotIndex degisince akis sifirlanir. Server degisikligi gerektirmez.
 */
export function useBidFeed(
  lotIndex: number | undefined,
  hasBid: boolean | undefined,
  highBid: number | undefined,
  name: string | null | undefined,
  max = 5,
): FeedEntry[] {
  const [feed, setFeed] = useState<FeedEntry[]>([])
  const lastRef = useRef<{ lot?: number; amount: number }>({ amount: 0 })
  const idRef = useRef(0)

  useEffect(() => {
    if (lotIndex !== lastRef.current.lot) {
      lastRef.current = { lot: lotIndex, amount: 0 }
      setFeed([])
      return
    }
    if (hasBid && typeof highBid === 'number' && highBid > lastRef.current.amount) {
      lastRef.current.amount = highBid
      const entry: FeedEntry = { id: ++idRef.current, name: name || '???', amount: highBid }
      setFeed((f) => [entry, ...f].slice(0, max))
    }
  }, [lotIndex, hasBid, highBid, name, max])

  return feed
}
