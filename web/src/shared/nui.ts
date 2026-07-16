import { useEffect, useRef } from 'react'

declare global {
  interface Window {
    GetParentResourceName?: () => string
    invokeNative?: unknown
  }
}

export const RESOURCE = () => window.GetParentResourceName?.() ?? 'fd-acikarttirma'

/** FiveM NUI icinde mi calisiyoruz (yoksa tarayici dev)? */
export const isEnvBrowser = () => typeof window.invokeNative === 'undefined'

export async function fetchNui<T = unknown>(event: string, data?: unknown): Promise<T | null> {
  if (isEnvBrowser()) return null
  try {
    const resp = await fetch(`https://${RESOURCE()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    })
    return (await resp.json()) as T
  } catch {
    return null
  }
}

type Handler = (data: any) => void

/** window message dinleyicisi: action alanina gore handler cagirir. */
export function useNuiEvent(action: string, handler: Handler) {
  const saved = useRef<Handler>(handler)
  saved.current = handler
  useEffect(() => {
    const listener = (e: MessageEvent) => {
      const payload = e.data
      if (payload && payload.action === action) saved.current(payload)
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [action])
}

/** DUI mesaj dinleyicisi: SendDuiMessage -> {target, data, event} */
export function useDuiEvent(target: string, handler: (msg: any) => void) {
  const saved = useRef(handler)
  saved.current = handler
  useEffect(() => {
    const listener = (e: MessageEvent) => {
      const payload = e.data
      if (payload && payload.target === target) saved.current(payload)
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [target])
}
