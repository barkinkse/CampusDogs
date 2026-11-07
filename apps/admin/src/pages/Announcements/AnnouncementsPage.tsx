import { useCallback, useState, type FormEvent } from 'react'
import { useAsyncData } from '../../hooks/useAsyncData'
import { adminRepository } from '../../services/adminRepository'

export function AnnouncementsPage() {
  const [open, setOpen] = useState(false)
  const [message, setMessage] = useState('')
  const [pendingDelete, setPendingDelete] = useState<{ id: string; title: string } | null>(null)
  const [deleting, setDeleting] = useState(false)
  const q = useAsyncData(useCallback(() => adminRepository.listAnnouncements(), []))

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget), published = form.get('published') === 'on'
    try {
      await adminRepository.saveAnnouncement({ title: String(form.get('title')).trim(), body: String(form.get('body')).trim(), is_published: published, published_at: published ? new Date().toISOString() : null })
      setMessage('Duyuru kaydedildi.'); setOpen(false); void q.refresh()
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Kaydedilemedi.') }
  }

  async function deleteAnnouncement() {
    if (!pendingDelete) return
    setDeleting(true)
    try { await adminRepository.deleteAnnouncement(pendingDelete.id); setMessage('Duyuru kalıcı olarak silindi.'); setPendingDelete(null); await q.refresh() }
    catch (error) { setMessage(error instanceof Error ? error.message : 'Duyuru silinemedi.') }
    finally { setDeleting(false) }
  }

  return <section className="panel announcements-page"><div className="panel-title"><div><h2>Duyurular</h2><p>Yayınlanan duyurular iOS uygulamasında görünür.</p></div><button onClick={() => setOpen(!open)}>+ Duyuru oluştur</button></div>{open && <form className="form-grid" onSubmit={submit}><label className="full">Başlık<input name="title" required /></label><label className="full">Açıklama<textarea name="body" required /></label><label className="checkbox-inline"><input name="published" type="checkbox" /> <span>Hemen yayınla</span></label><button>Kaydet</button></form>}{message && <p className="notice">{message}</p>}{q.loading ? <p>Yükleniyor…</p> : q.error ? <p>{q.error}</p> : q.data?.map(announcement => <article className="row-card announcement-card" key={announcement.id}><strong>{announcement.title}</strong><p>{announcement.body}</p><small>{announcement.is_published ? 'Yayınlandı' : 'Taslak'}</small><div className="row-actions compact-actions"><button onClick={async () => { try { await adminRepository.saveAnnouncement({ is_published: !announcement.is_published, published_at: !announcement.is_published ? new Date().toISOString() : null }, announcement.id); void q.refresh() } catch (error) { setMessage(error instanceof Error ? error.message : 'Duyuru güncellenemedi.') } }}>{announcement.is_published ? 'Yayından kaldır' : 'Yayınla'}</button><button className="danger-button" onClick={() => setPendingDelete({ id: announcement.id, title: announcement.title })}>Sil</button></div></article>)}{pendingDelete && <div className="confirm-backdrop" role="presentation"><section className="confirm-dialog announcement-dialog" role="dialog" aria-modal="true" aria-labelledby="delete-announcement-title"><h3 id="delete-announcement-title">Duyuru silinsin mi?</h3><p><strong>{pendingDelete.title}</strong> kalıcı olarak silinecek. Bu işlem geri alınamaz.</p><div className="dialog-actions balanced-dialog-actions"><button type="button" className="secondary-button" disabled={deleting} onClick={() => setPendingDelete(null)}>Vazgeç</button><button type="button" className="danger-button" disabled={deleting} onClick={() => void deleteAnnouncement()}>{deleting ? 'Siliniyor…' : 'Kalıcı olarak sil'}</button></div></section></div>}</section>
}
