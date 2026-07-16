import { useState } from 'react'
import { useDuiEvent, isEnvBrowser } from '../shared/nui'
import { money } from '../shared/format'

interface PropData {
  amount: number
  label?: string
}

export default function Prop() {
  const [data, setData] = useState<PropData>(isEnvBrowser() ? { amount: 640000, label: 'Adder' } : { amount: 0 })

  useDuiEvent('prop', (msg) => {
    if (msg.data) setData(msg.data)
  })

  return (
    <div className="sign">
      <div className="sign-inner">
        <div className="sign-cur">$</div>
        <div className="sign-amount">{money(data.amount)}</div>
        <div className="sign-mezat">MEZAT</div>
      </div>
    </div>
  )
}
