import { useState } from 'react'
import { useDuiEvent, isEnvBrowser } from '../shared/nui'
import { money } from '../shared/format'
import { useCountUp, useFlashOnChange } from '../shared/motion'

interface PropData {
  amount: number
  label?: string
}

export default function Prop() {
  const [data, setData] = useState<PropData>(isEnvBrowser() ? { amount: 640000, label: 'Adder' } : { amount: 0 })

  useDuiEvent('prop', (msg) => {
    if (msg.data) setData(msg.data)
  })

  const shown = useCountUp(data.amount, 500)
  const flash = useFlashOnChange(data.amount)

  return (
    <div className="sign">
      <div className={`sign-inner ${flash ? 'lit' : ''}`}>
        <div className="sign-cur">$</div>
        <div className={`sign-amount ${flash ? 'flash' : ''}`}>{money(shown)}</div>
        <div className="sign-mezat">MEZAT</div>
      </div>
    </div>
  )
}
