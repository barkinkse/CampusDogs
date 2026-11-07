import { useCallback, useState, type FormEvent } from 'react'
import { useAsyncData } from '../../hooks/useAsyncData'
import { adminRepository, type HealthRow } from '../../services/adminRepository'

const tr = (value: string) => ({ normal: 'Normal', under_observation: 'Gözlem Altında', under_treatment: 'Tedavi Altında', recovering: 'İyileşiyor' }[value] ?? value)

export function HealthPage() {
  const [dog, setDog] = useState('')
  const [edit, setEdit] = useState<HealthRow | null>(null)
  const [pendingDelete, setPendingDelete] = useState<HealthRow | null>(null)
  const [message, setMessage] = useState('')
  const [tab, setTab] = useState<'current' | 'history'>('current')
  const [deleting, setDeleting] = useState(false)
  const q = useAsyncData(useCallback(async () => ({ dogs: await adminRepository.listDogs(), records: await adminRepository.listHealth() }), []))
  const shown = q.data?.records.filter(record => !dog || record.dog_id === dog) ?? []

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    try {
      const dogId = String(form.get('dog'))
      await adminRepository.saveHealth({ dog_id: dogId, title: String(form.get('title')).trim(), description: String(form.get('description')) || null, status: String(form.get('status')) as HealthRow['status'], is_public: form.get('public') === 'on', recorded_at: String(form.get('recorded')) || new Date().toISOString() }, edit?.id)
      if (!edit?.id) await adminRepository.saveDog({ public_health_status: String(form.get('status')) as HealthRow['status'] }, dogId)
      setMessage(edit?.id ? 'Sağlık kaydı güncellendi.' : 'Sağlık kaydı eklendi.'); setEdit(null); void q.refresh()
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Kaydedilemedi.') }
  }

  async function changeStatus(dogId: string, status: HealthRow['status']) {
    try { await adminRepository.saveDog({ public_health_status: status }, dogId); setMessage('Mevcut sağlık durumu güncellendi.'); void q.refresh() }
    catch (error) { setMessage(error instanceof Error ? error.message : 'Durum güncellenemedi.') }
  }

  async function deleteHealthRecord() {
    if (!pendingDelete) return
    setDeleting(true)
    try { await adminRepository.deleteHealth(pendingDelete.id); setMessage('Sağlık kaydı kalıcı olarak silindi.'); setPendingDelete(null); await q.refresh() }
    catch (error) { setMessage(error instanceof Error ? error.message : 'Sağlık kaydı silinemedi.') }
    finally { setDeleting(false) }
  }

  return <section className="panel health-page"><div className="panel-title"><div><h2>Sağlık & Tedavi Kayıtları</h2><p>Köpeklerin güncel sağlık durumlarını ve geçmiş sağlık olaylarını yönetin.</p></div>{tab === 'history' && <button onClick={() => setEdit({ id: '', dog_id: dog || q.data?.dogs[0]?.id || '', title: '', description: null, status: 'normal', is_public: false, recorded_at: new Date().toISOString(), created_at: '', updated_at: '' })}>+ Kayıt ekle</button>}</div><div className="tabs"><button className={tab === 'current' ? 'active' : ''} onClick={() => setTab('current')}>Mevcut Sağlık Durumları</button><button className={tab === 'history' ? 'active' : ''} onClick={() => setTab('history')}>Sağlık Geçmişi</button></div>{message && <p className="notice">{message}</p>}{tab === 'current' ? <div>{q.data?.dogs.filter(item => item.is_active).map(item => <article className="row-card health-card" key={item.id}><strong>{item.name}</strong><p>{tr(item.public_health_status)} · Son güncelleme: {new Date(item.updated_at).toLocaleString('tr-TR')}</p><label>Mevcut durum<select value={item.public_health_status} onChange={event => void changeStatus(item.id, event.target.value as HealthRow['status'])}><option value="normal">Normal</option><option value="under_observation">Gözlem altında</option><option value="under_treatment">Tedavi altında</option><option value="recovering">İyileşiyor</option></select></label></article>)}</div> : <><label className="history-filter">Köpeğe göre filtrele <select value={dog} onChange={event => setDog(event.target.value)}><option value="">Tüm köpekler</option>{q.data?.dogs.map(item => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label>{edit && <form className="form-grid health-record-form" onSubmit={submit}><label>Köpek<select name="dog" defaultValue={edit.dog_id} required>{q.data?.dogs.map(item => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label><label>Kayıt türü / durum<select name="status" defaultValue={edit.status}><option value="normal">Genel Sağlık Gözlemi</option><option value="under_observation">Veteriner Kontrolü</option><option value="under_treatment">Tedavi</option><option value="recovering">İyileşme</option></select></label><label className="full">Başlık<input name="title" defaultValue={edit.title} required /></label><label className="full">Açıklama / tedavi ayrıntısı<textarea name="description" defaultValue={edit.description ?? ''} /></label><label>Tarih<input name="recorded" type="datetime-local" defaultValue={edit.recorded_at.slice(0, 16)} /></label><label className="checkbox-inline"><input name="public" type="checkbox" defaultChecked={edit.is_public} /><span>Üyelere açık bilgi</span></label><div className="form-actions"><button>Kaydet</button><button type="button" className="secondary-button" onClick={() => setEdit(null)}>Vazgeç</button></div></form>}{shown.length === 0 ? <div className="empty">Bu seçim için sağlık kaydı yok.</div> : <div>{shown.map(record => <article className="row-card health-card" key={record.id}><strong>{record.title}</strong><p>{record.description}</p><small>{tr(record.status)} · {record.is_public ? 'Üyelere açık' : 'Özel'} · {new Date(record.recorded_at).toLocaleString('tr-TR')}</small><div className="row-actions compact-actions"><button onClick={() => setEdit(record)}>Düzenle</button><button className="danger-button" onClick={() => setPendingDelete(record)}>Sil</button></div></article>)}</div>}</>}{pendingDelete && <div className="confirm-backdrop" role="presentation"><section className="confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="delete-health-title"><h3 id="delete-health-title">Sağlık kaydı silinsin mi?</h3><p><strong>{pendingDelete.title}</strong> kaydı kalıcı olarak silinecek. Bu işlem köpeğin profilini veya diğer kayıtları silmez.</p><div className="dialog-actions balanced-dialog-actions"><button type="button" className="secondary-button" disabled={deleting} onClick={() => setPendingDelete(null)}>Vazgeç</button><button type="button" className="danger-button" disabled={deleting} onClick={() => void deleteHealthRecord()}>{deleting ? 'Siliniyor…' : 'Kalıcı olarak sil'}</button></div></section></div>}</section>
}
