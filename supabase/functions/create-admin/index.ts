import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const allowedOrigins = new Set([
  'http://localhost:5173',
  'http://127.0.0.1:5173'
])

function isAllowedOrigin(request: Request) {
  const origin = request.headers.get('Origin')
  return !origin || allowedOrigins.has(origin)
}

function corsHeaders(request: Request) {
  const origin = request.headers.get('Origin')
  const headers: Record<string, string> = {
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin'
  }

  if (origin && allowedOrigins.has(origin)) {
    headers['Access-Control-Allow-Origin'] = origin
  }

  return headers
}

function json(request: Request, body: Record<string, unknown>, status = 200) {
  return Response.json(body, { status, headers: corsHeaders(request) })
}

Deno.serve(async request => {
  if (request.method === 'OPTIONS') {
    if (!isAllowedOrigin(request)) {
      return json(request, { error: 'Bu origin için CORS izni yok.' }, 403)
    }

    return new Response(null, { status: 204, headers: corsHeaders(request) })
  }

  if (!isAllowedOrigin(request)) {
    return json(request, { error: 'Bu origin için CORS izni yok.' }, 403)
  }

  if (request.method !== 'POST') {
    return json(request, { error: 'Yalnızca POST isteği desteklenir.' }, 405)
  }

  try {
    const auth = request.headers.get('Authorization')
    if (!auth) {
      return json(request, { error: 'Yetkilendirme gerekli.' }, 401)
    }

    const url = Deno.env.get('SUPABASE_URL')!
    const anon = Deno.env.get('SUPABASE_ANON_KEY')!
    const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const caller = createClient(url, anon, { global: { headers: { Authorization: auth } } })
    const { data: { user } } = await caller.auth.getUser()
    const { data: master } = await caller.rpc('is_super_admin')

    if (!user || master !== true) {
      return json(request, { error: 'Master admin yetkisi gerekli.' }, 403)
    }

    const body = await request.json().catch(() => null)
    const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : ''
    const password = typeof body?.password === 'string' ? body.password : ''

    if (!/^\S+@\S+\.\S+$/.test(email) || password.length === 0) {
      return json(request, { error: 'Geçerli e-posta ve şifre gereklidir.' }, 400)
    }

    const admin = createClient(url, service)
    const { data, error } = await admin.auth.admin.createUser({ email, password, email_confirm: true })

    if (error || !data.user) {
      return json(request, { error: 'Hesap oluşturulamadı; e-posta zaten kullanımda olabilir.' }, 409)
    }

    const { error: insertError } = await admin.from('admin_users').insert({ id: data.user.id, is_super_admin: false })
    if (insertError) {
      await admin.auth.admin.deleteUser(data.user.id)
      return json(request, { error: 'Hesap yetkilendirilemedi; işlem geri alındı.' }, 500)
    }

    return json(request, { ok: true, email })
  } catch {
    return json(request, { error: 'Hesap oluşturma sırasında beklenmeyen bir hata oluştu.' }, 500)
  }
})
