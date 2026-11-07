import { Link } from 'react-router-dom'
export function StatCard({ label, value, detail, to }: { label: string; value: string; detail?: string; to?: string }) { const content = <><span>{label}</span><strong>{value}</strong>{detail && <small>{detail}</small>}</>; return to ? <Link className="stat-card stat-card-link" to={to}>{content}</Link> : <article className="stat-card">{content}</article> }
