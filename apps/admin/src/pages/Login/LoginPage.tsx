import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { isConfigured, supabase } from '../../services/supabase'
export function LoginPage() {
  const [message, setMessage] = useState('')
  const navigate = useNavigate()
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase) { setMessage('Supabase yapılandırılmadı. .env dosyanıza yayınlanabilir anahtarı ekleyin.'); return }
    const data = new FormData(event.currentTarget)
    const { error } = await supabase.auth.signInWithPassword({ email: String(data.get('email')), password: String(data.get('password')) })
    if (error) { setMessage('E-posta veya parola doğrulanamadı.'); return }
    const { data: isAdmin, error: accessError } = await supabase.rpc('is_admin')
    if (accessError || !isAdmin) { await supabase.auth.signOut(); setMessage('Bu hesap yönetici erişimine sahip değil.'); return }
    navigate('/')
  }
  return <div className="login"><form onSubmit={submit}><div className="logo">🐾</div><h1>Campus Dogs</h1><p>Yönetim paneline erişmek için giriş yapın.</p><label>E-posta<input name="email" type="email" required disabled={!isConfigured} /></label><label>Parola<input name="password" type="password" required disabled={!isConfigured} /></label>{message && <p className="notice">{message}</p>}<button type="submit" disabled={!isConfigured}>Giriş yap</button>{!isConfigured && <small>Supabase yapılandırılana kadar oturum açma kullanılamaz.</small>}</form></div>
}
