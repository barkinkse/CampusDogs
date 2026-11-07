import { useEffect, useState, type ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { isConfigured, supabase } from '../services/supabase'

type AccessState = 'checking' | 'allowed' | 'denied' | 'configurationError'

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AccessState>(isConfigured ? 'checking' : 'configurationError')

  useEffect(() => {
    if (!supabase) return
    const client = supabase as NonNullable<typeof supabase>
    let mounted = true
    async function verifyAdminAccess() {
      const { data: { session } } = await client.auth.getSession()
      if (!session) { if (mounted) setState('denied'); return }
      const { data: isAdmin, error } = await client.rpc('is_admin')
      if (mounted) setState(!error && isAdmin === true ? 'allowed' : 'denied')
    }
    void verifyAdminAccess()
    return () => { mounted = false }
  }, [])

  if (state === 'checking') return <p className="loading">Yönetici yetkisi denetleniyor…</p>
  if (state === 'configurationError') return <main className="configuration-state"><h1>Yapılandırma gerekli</h1><p>Yönetim paneli için Supabase bağlantı bilgileri tanımlanmadı. <code>.env</code> dosyasına yayınlanabilir URL ve anahtarı ekleyin.</p></main>
  return state === 'allowed' ? <>{children}</> : <Navigate to="/login" replace />
}
