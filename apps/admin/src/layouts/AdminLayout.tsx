import { useEffect, useState } from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { isConfigured, supabase } from '../services/supabase'

const links = [['/', 'Dashboard'], ['/dogs', 'Köpekler'], ['/health', 'Sağlık & Tedavi Kayıtları'], ['/care-icons', 'Bakım İkonları'], ['/collars', 'Tasmalar'], ['/reports', 'Gözlem Bildirimleri'], ['/announcements', 'Duyurular'], ['/dog-map', 'Köpek Haritası']]

export function AdminLayout() {
  const navigate = useNavigate()
  const [menuOpen, setMenuOpen] = useState(false)
  useEffect(() => { if (!menuOpen) return; const close = (event: KeyboardEvent) => { if (event.key === 'Escape') setMenuOpen(false) }; window.addEventListener('keydown', close); return () => window.removeEventListener('keydown', close) }, [menuOpen])
  async function logout() { await supabase?.auth.signOut(); setMenuOpen(false); navigate('/login') }
  return <div className={`shell${menuOpen ? ' menu-open' : ''}`}><aside id="primary-navigation"><div className="brand"><span>🐾</span> Campus Dogs<small>Yönetim Paneli</small></div><nav aria-label="Ana menü">{links.map(([to, label]) => <NavLink key={to} to={to} end={to === '/'} onClick={() => setMenuOpen(false)}>{label}</NavLink>)}</nav><button className="text-button" onClick={logout}>Oturumu kapat</button></aside>{menuOpen&&<button className="menu-scrim" aria-label="Menüyü kapat" onClick={() => setMenuOpen(false)}/>}<main><header><div className="heading-row"><button className="menu-toggle" type="button" aria-label={menuOpen?'Menüyü kapat':'Menüyü aç'} aria-expanded={menuOpen} aria-controls="primary-navigation" onClick={() => setMenuOpen(open => !open)}><span/><span/><span/></button><div><p>Üniversite Hayvan Refahı</p><h1>Yönetim Merkezi</h1></div></div><span className={isConfigured ? 'configured' : 'demo'}>{isConfigured ? 'Supabase bağlı' : 'Geliştirme verisi'}</span></header><Outlet /></main></div>
}
