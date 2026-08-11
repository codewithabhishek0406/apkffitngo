import type { VerificationStatus } from '../../types'
import { CheckCircle, Clock, AlertCircle, RefreshCw, HelpCircle } from 'lucide-react'

interface Props {
  status: VerificationStatus
}

const CONFIG: Record<
  VerificationStatus,
  { label: string; className: string; Icon: React.FC<{ size?: number }> }
> = {
  verified:     { label: 'Verified',      className: 'badge-verified', Icon: CheckCircle },
  imported:     { label: 'Imported',      className: 'badge-imported', Icon: RefreshCw },
  under_review: { label: 'Under Review',  className: 'badge-review',   Icon: Clock },
  unverified:   { label: 'Unverified',    className: 'badge-unverified', Icon: HelpCircle },
  outdated:     { label: 'Outdated',      className: 'badge-outdated', Icon: AlertCircle },
}

export function StatusBadge({ status }: Props) {
  const { label, className, Icon } = CONFIG[status] ?? CONFIG.unverified
  return (
    <span className={className}>
      <Icon size={10} />
      {label}
    </span>
  )
}
