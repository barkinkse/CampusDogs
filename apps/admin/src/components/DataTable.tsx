import type { ReactNode } from 'react'
export function DataTable({ headings, children }: { headings: string[]; children: ReactNode }) { return <div className="table-wrap" tabIndex={0} aria-label="Veri tablosu"><table><thead><tr>{headings.map(h => <th key={h}>{h}</th>)}</tr></thead><tbody>{children}</tbody></table></div> }
