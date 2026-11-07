import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { useAsyncData } from '../../hooks/useAsyncData'
import { adminRepository, type IconRow } from '../../services/adminRepository'
import recoveryIcon from '../../assets/care-icons/recovery.svg'
import limitRunningIcon from '../../assets/care-icons/limit-running.svg'
import specialDietIcon from '../../assets/care-icons/special-diet.svg'
import visionSensitivityIcon from '../../assets/care-icons/vision-sensitivity.svg'
import hearingSensitivityIcon from '../../assets/care-icons/hearing-sensitivity.svg'
import regularCheckupIcon from '../../assets/care-icons/regular-checkup.svg'
import otherIcon from '../../assets/care-icons/other.svg'

const iconCategories = [
  { key: 'recovery', title: 'İyileşme Süreci' },
  { key: 'limit_running', title: 'Koşmayı Sınırla' },
  { key: 'special_diet', title: 'Özel Beslenme' },
  { key: 'vision_sensitivity', title: 'Görme Hassasiyeti' },
  { key: 'hearing_sensitivity', title: 'İşitme Hassasiyeti' },
  { key: 'regular_checkup', title: 'Düzenli Kontrol' }
] as const

function knownCategory(key: string) { return iconCategories.some(category => category.key === key) ? key : 'other' }

export function CareIconGlyph({ iconKey, size = 28 }: { iconKey: string; size?: number }) {
  const icon = { recovery: recoveryIcon, limit_running: limitRunningIcon, special_diet: specialDietIcon, vision_sensitivity: visionSensitivityIcon, hearing_sensitivity: hearingSensitivityIcon, regular_checkup: regularCheckupIcon, other: otherIcon }[iconKey] ?? otherIcon
  return <img aria-hidden="true" className="care-icon-glyph" src={icon} width={size} height={size} alt="" />
}

export function CareIconsPage() {
  const [tab, setTab] = useState<'library' | 'assignments'>('library')
  const [edit, setEdit] = useState<IconRow | null>(null)
  const [message, setMessage] = useState('')
  const [dogID, setDogID] = useState('')
  const [selectedIconIDs, setSelectedIconIDs] = useState<string[]>([])
  const [savingAssignments, setSavingAssignments] = useState(false)
  const q = useAsyncData(useCallback(async () => ({ icons: await adminRepository.icons(), dogs: await adminRepository.listDogs() }), []))
  const assignments = useAsyncData(useCallback(() => dogID ? adminRepository.dogIconIds(dogID) : Promise.resolve([]), [dogID]), Boolean(dogID))

  useEffect(() => { setSelectedIconIDs(assignments.data ?? []) }, [assignments.data])
  const selectedDog = q.data?.dogs.find(dog => dog.id === dogID)

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    const category = String(form.get('category'))
    const iconKey = category === 'other' && edit?.id ? edit.icon_key : category
    if (q.data?.icons.some(icon => icon.icon_key === iconKey && icon.id !== edit?.id)) {
      setMessage('Bu görsel kategori için zaten bir bakım ikonu var.')
      return
    }
    try {
      await adminRepository.saveIcon({ name: String(form.get('name')).trim(), icon_key: iconKey, description: String(form.get('description')).trim() }, edit?.id)
      setEdit(null); setMessage('Bakım ikonu kaydedildi.'); void q.refresh()
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Kaydedilemedi.') }
  }

  function toggleIcon(iconID: string) { setSelectedIconIDs(current => current.includes(iconID) ? current.filter(id => id !== iconID) : [...current, iconID]) }
  async function saveAssignments() {
    if (!dogID) return
    setSavingAssignments(true)
    try { await adminRepository.setDogIcons(dogID, [...new Set(selectedIconIDs)]); setMessage('Köpeğin bakım ikonları güncellendi.'); await assignments.refresh() }
    catch (error) { setMessage(error instanceof Error ? error.message : 'Bakım ikonları güncellenemedi.') }
    finally { setSavingAssignments(false) }
  }

  return <section className="panel care-icons-page">
    <div className="panel-title"><div><h2>Bakım İkonları</h2><p>Profilde gösterilen bakım bilgilerini yönetin.</p></div>{tab === 'library' && <button onClick={() => setEdit({ id: '', name: '', icon_key: 'recovery', description: '', created_at: '', updated_at: '' })}>+ İkon ekle</button>}</div>
    <div className="tabs" role="tablist" aria-label="Bakım ikonları bölümleri"><button role="tab" aria-selected={tab === 'library'} className={tab === 'library' ? 'active' : ''} onClick={() => setTab('library')}>İkon Kütüphanesi</button><button role="tab" aria-selected={tab === 'assignments'} className={tab === 'assignments' ? 'active' : ''} onClick={() => setTab('assignments')}>Köpek Bakım İkonları</button></div>
    {message && <p className="notice">{message}</p>}
    {tab === 'library' ? <>
      {edit && <form className="form-grid" onSubmit={save}><label>Görünen ad<input name="name" defaultValue={edit.name} required /></label><label>Görsel kategori<select name="category" defaultValue={knownCategory(edit.icon_key)}>{iconCategories.map(category => <option key={category.key} value={category.key}>{category.title}</option>)}{knownCategory(edit.icon_key) === 'other' && <option value="other">Mevcut özel kategori</option>}</select></label><label className="full">Türkçe açıklama<textarea name="description" defaultValue={edit.description} required /></label><div className="form-actions"><button>Kaydet</button><button type="button" className="secondary-button" onClick={() => setEdit(null)}>Vazgeç</button></div></form>}
      <div className="care-icon-library">{q.data?.icons.map(icon => <article className="row-card care-icon-card" key={icon.id}><CareIconGlyph iconKey={icon.icon_key} /><div><strong>{icon.name}</strong><p>{icon.description}</p></div><button onClick={() => setEdit(icon)}>Düzenle</button></article>)}</div>
    </> : <div className="care-assignment-layout">
      <div className="care-dog-picker"><div className="care-dog-list" aria-label="Köpek seçimi">{q.data?.dogs.map(dog => <button type="button" key={dog.id} className={dog.id === dogID ? 'selected' : ''} onClick={() => setDogID(dog.id)}><strong>{dog.name}</strong><small>{dog.is_active ? 'Aktif' : 'Pasif'}</small></button>)}</div></div>
      <div className="care-assignment-content">{selectedDog ? <><div className="assignment-heading"><div><h3>{selectedDog.name}</h3><p>Bu köpeğin profilinde gösterilecek ikonları seçin.</p></div><button disabled={savingAssignments || assignments.loading} onClick={() => void saveAssignments()}>{savingAssignments ? 'Kaydediliyor…' : 'Değişiklikleri kaydet'}</button></div>{assignments.loading ? <p className="loading">Bakım ikonları yükleniyor…</p> : <div className="care-icon-choice-grid">{q.data?.icons.map(icon => <label className={selectedIconIDs.includes(icon.id) ? 'selected' : ''} key={icon.id}><input type="checkbox" checked={selectedIconIDs.includes(icon.id)} onChange={() => toggleIcon(icon.id)} /><CareIconGlyph iconKey={icon.icon_key} /><span><strong>{icon.name}</strong><small>{icon.description}</small></span></label>)}</div>}</> : <div className="empty">Atamalarını düzenlemek için bir köpek seçin.</div>}</div>
    </div>}
  </section>
}
