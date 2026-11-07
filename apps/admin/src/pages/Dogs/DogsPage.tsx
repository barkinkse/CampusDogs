import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import { Link, useParams, useSearchParams } from 'react-router-dom'
import { StatusBadge } from '../../components/StatusBadge'
import { useAsyncData } from '../../hooks/useAsyncData'
import { adminRepository, type DogRow } from '../../services/adminRepository'
import { CareIconGlyph } from '../CareIcons/CareIconsPage'

const label = (value: string) => ({ normal: 'Normal', under_observation: 'Gözlem Altında', under_treatment: 'Tedavi Altında', recovering: 'İyileşiyor' }[value] ?? value)
function optionalDate(value: FormDataEntryValue | null): string | null {
  if (typeof value !== 'string') return null
  const date = value.trim()
  if (!date) return null
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error('Tahmini doğum tarihi YYYY-AA-GG biçiminde olmalıdır.')
  return date
}
function optionalText(value: FormDataEntryValue | null): string | null {
  return typeof value === 'string' && value.trim() ? value.trim() : null
}
const Photo = ({ path }: { path: string | null }) => {
  const [url, setUrl] = useState<string | null>(null)
  useEffect(() => { void adminRepository.dogPhotoUrl(path).then(setUrl) }, [path])
  return url ? <img className="dog-photo" src={url} alt="Köpek fotoğrafı" /> : <span className="dog-placeholder">🐾</span>
}

function DogForm({ dog, onDone }: { dog?: DogRow; onDone: () => void }) {
  const [file, setFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [remove, setRemove] = useState(false)
  const [message, setMessage] = useState('')
  const [saving, setSaving] = useState(false)
  const [savedDog, setSavedDog] = useState<DogRow | null>(null)
  const currentDog = savedDog ?? dog

  useEffect(() => {
    if (!file) return
    const url = URL.createObjectURL(file)
    setPreview(url)
    return () => URL.revokeObjectURL(url)
  }, [file])

  function pick(selected?: File) {
    if (!selected) return
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(selected.type) || selected.size > 5 * 1024 * 1024) {
      setMessage('Yalnızca en fazla 5 MB JPEG, PNG veya WebP seçin.')
      return
    }
    setMessage('')
    setFile(selected)
    setRemove(false)
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setSaving(true)
    setMessage('')
    const form = new FormData(event.currentTarget)
    const existingDog = currentDog
    const wasNew = !existingDog
    try {
      const estimatedBirthDate = optionalDate(form.get('birth'))
      const saved = await adminRepository.saveDog({
        name: String(form.get('name')).trim(),
        gender: String(form.get('gender')) as DogRow['gender'],
        estimated_birth_date: estimatedBirthDate,
        description: optionalText(form.get('description')),
        public_health_status: String(form.get('health')) as DogRow['public_health_status'],
        public_care_info: optionalText(form.get('care')),
        is_active: form.get('active') === 'on',
      }, existingDog?.id)
      setSavedDog(saved)

      const oldPath = existingDog?.photo_path ?? null
      if (file) {
        let newPath: string
        try {
          newPath = await adminRepository.uploadDogPhoto(saved.id, file)
        } catch (error) {
          const reason = error instanceof Error ? error.message : 'Fotoğraf yüklenemedi.'
          setMessage(`${wasNew ? 'Köpek oluşturuldu' : 'Köpek bilgileri kaydedildi'}, ancak ${reason.charAt(0).toLocaleLowerCase('tr-TR')}${reason.slice(1)} Bu profilden yeniden deneyebilirsiniz.`)
          return
        }
        try {
          const withPhoto = await adminRepository.saveDog({ photo_path: newPath }, saved.id, 'photo-reference')
          setSavedDog(withPhoto)
        } catch {
          await adminRepository.removeDogPhoto(newPath).catch(() => undefined)
          setMessage('Fotoğraf veritabanına bağlanamadı. Yeni yükleme temizlendi; önceki fotoğraf korunuyor.')
          return
        }
        if (oldPath && oldPath !== newPath) {
          try { await adminRepository.removeDogPhoto(oldPath) } catch {
            setMessage('Yeni fotoğraf kaydedildi; önceki fotoğraf depolamadan kaldırılamadı.')
            onDone()
            return
          }
        }
      } else if (remove && oldPath) {
        try { await adminRepository.saveDog({ photo_path: null }, saved.id, 'photo-reference') } catch (error) {
          setMessage(error instanceof Error ? error.message : 'Fotoğraf veritabanından kaldırılamadı.')
          return
        }
        try { await adminRepository.removeDogPhoto(oldPath) } catch {
          setMessage('Fotoğraf profilden kaldırıldı; depolamadaki eski dosya kaldırılamadı.')
          onDone()
          return
        }
      }
      setMessage('Köpek bilgileri kaydedildi.')
      onDone()
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Köpek bilgileri kaydedilemedi.')
    } finally {
      setSaving(false)
    }
  }

  return <form className="form-grid" onSubmit={submit}>
    <label>Ad<input name="name" defaultValue={dog?.name} required /></label>
    <label>Fotoğraf<input type="file" accept="image/jpeg,image/png,image/webp" onChange={event => pick(event.target.files?.[0])} /></label>
    <div className="photo-editor">{preview ? <img src={preview} alt="Yeni fotoğraf önizlemesi" /> : <Photo path={currentDog?.photo_path ?? null} />} {currentDog?.photo_path && !file && <label><input type="checkbox" checked={remove} onChange={event => setRemove(event.target.checked)} /> Fotoğrafı kaldır</label>}</div>
    <label>Cinsiyet<select name="gender" defaultValue={dog?.gender ?? 'unknown'}><option value="female">Dişi</option><option value="male">Erkek</option><option value="unknown">Bilinmiyor</option></select></label>
    <label>Tahmini doğum tarihi<input name="birth" type="date" defaultValue={dog?.estimated_birth_date ?? ''} /></label>
    <label>Sağlık<select name="health" defaultValue={dog?.public_health_status ?? 'normal'}><option value="normal">Normal</option><option value="under_observation">Gözlem altında</option><option value="under_treatment">Tedavi altında</option><option value="recovering">İyileşiyor</option></select></label>
    <label className="full">Açıklama<textarea name="description" defaultValue={dog?.description ?? ''} /></label>
    <label className="full">Herkese açık bakım bilgisi<textarea name="care" defaultValue={dog?.public_care_info ?? ''} /></label>
    <label><input name="active" type="checkbox" defaultChecked={dog?.is_active ?? true} /> Aktif</label>
    <button disabled={saving}>{saving ? 'Kaydediliyor…' : 'Kaydet'}</button>
    {message && <p className="notice">{message}</p>}
  </form>
}

export function DogsPage() {
  const [create, setCreate] = useState(false)
  const [params, setParams] = useSearchParams()
  const query = useAsyncData(useCallback(() => adminRepository.listDogs(), []))
  const requestedKey = params.get('sort')
  const sort = requestedKey === 'health' || requestedKey === 'active' ? requestedKey : 'name'
  const direction = params.get('dir') === 'desc' ? 'desc' : 'asc'
  const health = params.get('health')
  const active = params.get('active')
  const dogs = useMemo(() => {
    const healthRank: Record<string, number> = { normal: 0, under_observation: 1, under_treatment: 2, recovering: 3 }
    const filtered = (query.data ?? []).filter(dog => (!health || dog.public_health_status === health) && (active === null || dog.is_active === (active === 'true')))
    return [...filtered].sort((left, right) => {
      const a = sort === 'name' ? left.name : sort === 'health' ? healthRank[left.public_health_status] : Number(!left.is_active)
      const b = sort === 'name' ? right.name : sort === 'health' ? healthRank[right.public_health_status] : Number(!right.is_active)
      const result = typeof a === 'string' ? a.localeCompare(String(b), 'tr') : Number(a) - Number(b)
      return direction === 'asc' ? result : -result
    })
  }, [active, direction, health, query.data, sort])
  function toggle(key: 'name' | 'health' | 'active') { const nextDirection = key === sort ? (direction === 'asc' ? 'desc' : 'asc') : 'asc'; const next = new URLSearchParams(params); next.set('sort', key); next.set('dir', nextDirection); setParams(next) }
  const heading = (title: string, key: 'name' | 'health' | 'active') => <button className="sort-button" onClick={() => toggle(key)} aria-pressed={sort === key}>{title}<span aria-hidden="true">{sort === key ? (direction === 'asc' ? ' ↑' : ' ↓') : ' ↕'}</span></button>
  return <section className="panel"><div className="panel-title"><div><h2>Köpekler</h2><p>Profil ve herkese açık sağlık bilgileri.</p></div><button onClick={() => setCreate(!create)}>+ Köpek ekle</button></div>{create && <DogForm onDone={() => { setCreate(false); void query.refresh() }} />}<div className="table-wrap" tabIndex={0} aria-label="Köpekler tablosu"><table><thead><tr><th>Fotoğraf</th><th>{heading('Ad', 'name')}</th><th>{heading('Sağlık', 'health')}</th><th>{heading('Durum', 'active')}</th><th aria-label="İşlemler"/></tr></thead><tbody>{dogs.map(dog => <tr key={dog.id}><td><Photo path={dog.photo_path} /></td><td>{dog.name}</td><td><StatusBadge>{label(dog.public_health_status)}</StatusBadge></td><td>{dog.is_active ? 'Aktif' : 'Pasif'}</td><td><Link to={`/dogs/${dog.id}`}>Yönet</Link></td></tr>)}</tbody></table></div></section>
}

export function DogDetailPage() {
  const { id = '' } = useParams()
  const query = useAsyncData(useCallback(async () => {
    const [dog, icons, assignedIconIDs] = await Promise.all([adminRepository.dog(id), adminRepository.icons(), adminRepository.dogIconIds(id)])
    return { dog, icons: icons.filter(icon => assignedIconIDs.includes(icon.id)) }
  }, [id]))
  if (!query.data) return <p className="loading">Profil yükleniyor…</p>
  if (!query.data.dog) return <section className="panel"><div className="empty">Köpek profili bulunamadı.</div></section>
  return <section className="panel dog-profile-page"><div className="dog-profile-header"><div><p className="eyebrow">Köpek profili</p><h2>{query.data.dog.name}</h2></div><Photo path={query.data.dog.photo_path} /></div>{query.data.icons.length > 0 && <section className="dog-profile-care-icons" aria-label="Atanmış bakım ikonları">{query.data.icons.map(icon => <div key={icon.id}><CareIconGlyph iconKey={icon.icon_key} size={24} /><span><strong>{icon.name}</strong><small>{icon.description}</small></span></div>)}</section>}<div className="dog-profile-content"><DogForm dog={query.data.dog} onDone={() => void query.refresh()} /></div></section>
}
