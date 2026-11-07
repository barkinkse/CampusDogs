import { Fragment, useCallback, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { StatusBadge } from '../../components/StatusBadge'
import { useAsyncData } from '../../hooks/useAsyncData'
import { adminRepository, type ReportRow } from '../../services/adminRepository'

const severityLabel = (value: string) => ({ low: 'Düşük', medium: 'Orta', high: 'Yüksek' }[value] ?? value)
const statusLabel = (value: string) => ({ new: 'Yeni', reviewing: 'İnceleniyor', resolved: 'Çözüldü', dismissed: 'Kapatıldı' }[value] ?? value)
const severityRank: Record<string, number> = { low: 0, medium: 1, high: 2 }
const statusRank: Record<string, number> = { new: 0, reviewing: 1, resolved: 2, dismissed: 3 }
type SortKey = 'dog' | 'category' | 'severity' | 'createdAt' | 'status'
type SortDirection = 'asc' | 'desc'

export function ReportsPage() {
  const [selected, setSelected] = useState<ReportRow | null>(null)
  const [params, setParams] = useSearchParams()
  const requestedKey = params.get('sort')
  const sortKey: SortKey = ['dog', 'category', 'severity', 'createdAt', 'status'].includes(requestedKey ?? '') ? requestedKey as SortKey : 'createdAt'
  const direction: SortDirection = params.get('dir') === 'asc' ? 'asc' : 'desc'
  const load = useCallback(async () => { const [reports, dogs] = await Promise.all([adminRepository.listReports(), adminRepository.listDogs()]); return { reports, names: new Map(dogs.map(dog => [dog.id, dog.name])) } }, [])
  const q = useAsyncData(load)
  const rows = useMemo(() => {
    if (!q.data) return []
    const value = (report: ReportRow): string | number => ({ dog: q.data!.names.get(report.dog_id) ?? '', category: report.category, severity: severityRank[report.severity] ?? -1, status: statusRank[report.status] ?? 99, createdAt: new Date(report.created_at).getTime() }[sortKey])
    return [...q.data.reports].sort((left, right) => { const a = value(left), b = value(right), comparison = typeof a === 'number' && typeof b === 'number' ? a - b : String(a).localeCompare(String(b), 'tr'); return direction === 'asc' ? comparison : -comparison })
  }, [direction, q.data, sortKey])
  function toggle(key: SortKey) { const nextDirection: SortDirection = key === sortKey ? (direction === 'asc' ? 'desc' : 'asc') : key === 'createdAt' ? 'desc' : 'asc'; setParams({ sort: key, dir: nextDirection }) }
  const heading = (title: string, key: SortKey) => <button className="sort-button" onClick={() => toggle(key)} aria-label={title + ' alanına göre sırala'} aria-pressed={sortKey === key}>{title}<span aria-hidden="true">{sortKey === key ? (direction === 'asc' ? ' ↑' : ' ↓') : ' ↕'}</span></button>
  async function save() { if (!selected) return; await adminRepository.updateReport(selected.id, { status: selected.status, resolution_description: selected.resolution_description || null, resolved_at: selected.status === 'resolved' ? new Date().toISOString() : null }); setSelected(null); void q.refresh() }

  return <section className="panel"><h2>Gözlem Bildirimleri</h2><p>Kimlik bilgisi içermeyen üye bildirimleri.</p>{q.loading ? <p>Yükleniyor…</p> : q.error ? <p>{q.error}</p> : <div className="table-wrap" tabIndex={0} aria-label="Gözlem bildirimleri tablosu"><table><thead><tr><th>{heading('Köpek', 'dog')}</th><th>{heading('Kategori', 'category')}</th><th>Açıklama</th><th>{heading('Önem', 'severity')}</th><th>{heading('Tarih', 'createdAt')}</th><th>{heading('Durum', 'status')}</th><th aria-label="İşlemler"/></tr></thead><tbody>{rows.map(report => <Fragment key={report.id}><tr><td>{q.data?.names.get(report.dog_id) ?? 'Bilinmeyen'}</td><td>{report.category}</td><td className="report-description">{report.description}</td><td><StatusBadge>{severityLabel(report.severity)}</StatusBadge></td><td>{new Date(report.created_at).toLocaleString('tr-TR')}</td><td>{statusLabel(report.status)}</td><td><button onClick={() => setSelected(current => current?.id === report.id ? null : { ...report })}>{selected?.id === report.id ? 'Kapat' : 'İncele'}</button></td></tr>{selected?.id === report.id && <tr className="inline-editor-row"><td colSpan={7}><div className="editor"><h3>Bildirim ayrıntısı</h3><p>{selected.description}</p><p className="notice">Bu durum yalnızca yönetim amacıyla kullanılır ve member kullanıcılarına gösterilmez.</p><label>Durum<select value={selected.status} onChange={event => setSelected({ ...selected, status: event.target.value as ReportRow['status'] })}><option value="new">Yeni</option><option value="reviewing">İnceleniyor</option><option value="resolved">Çözüldü</option><option value="dismissed">Kapatıldı</option></select></label><label>Çözüm notu<textarea value={selected.resolution_description ?? ''} onChange={event => setSelected({ ...selected, resolution_description: event.target.value })} /></label><div className="row-actions"><button onClick={() => void save()}>Güncelle</button><button className="secondary-button" onClick={() => setSelected(null)}>Vazgeç</button></div></div></td></tr>}</Fragment>)}</tbody></table></div>}</section>
}
