export function money(n: number | undefined | null): string {
  const v = Math.floor(Number(n ?? 0))
  return v.toLocaleString('tr-TR')
}

export function secs(n: number | undefined | null): string {
  const s = Math.max(0, Math.floor(Number(n ?? 0)))
  const m = Math.floor(s / 60)
  const r = s % 60
  return `${m}:${r.toString().padStart(2, '0')}`
}

export const LOT_LABELS: Record<string, string> = {
  vehicle: 'Araç',
  business: 'Benzinlik / İşletme',
  item: 'Item',
}
