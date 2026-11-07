import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = { 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS' }

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return Response.json({ error: 'Yalnızca POST isteği desteklenir.' }, { status: 405, headers: corsHeaders })
  const authorization = request.headers.get('Authorization')
  if (!authorization) return Response.json({ error: 'Yetkilendirme gerekli.' }, { status: 401, headers: corsHeaders })

  const url = Deno.env.get('SUPABASE_URL')!
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const callerClient = createClient(url, publishableKey, { global: { headers: { Authorization: authorization } } })
  const { data: { user }, error: userError } = await callerClient.auth.getUser()
  if (userError || !user) return Response.json({ error: 'Geçersiz oturum.' }, { status: 401, headers: corsHeaders })
  const { data: isAdmin, error: adminError } = await callerClient.rpc('is_admin')
  if (adminError || isAdmin !== true) return Response.json({ error: 'Yönetici yetkisi gerekli.' }, { status: 403, headers: corsHeaders })

  const body = await request.json().catch(() => null)
  const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : ''
  if (!/^\S+@\S+\.\S+$/.test(email)) return Response.json({ error: 'Geçerli bir e-posta adresi girin.' }, { status: 400, headers: corsHeaders })

  const adminClient = createClient(url, serviceRoleKey)
  const { data: existingUsers, error: lookupError } = await adminClient.auth.admin.listUsers({ page: 1, perPage: 1000 })
  if (lookupError) return Response.json({ error: 'Davet durumu doğrulanamadı.' }, { status: 500, headers: corsHeaders })
  const existingUser = existingUsers.users.find((candidate) => candidate.email?.toLowerCase() === email)
  if (existingUser) {
    const { data: existingAdmin, error: existingAdminError } = await adminClient.from('admin_users').select('id').eq('id', existingUser.id).maybeSingle()
    if (existingAdminError) return Response.json({ error: 'Davet durumu doğrulanamadı.' }, { status: 500, headers: corsHeaders })
    if (existingAdmin) return Response.json({ error: 'Bu e-posta adresi zaten yönetici erişimine sahip.' }, { status: 409, headers: corsHeaders })
  }
  const { data: invitation, error: inviteError } = await adminClient.auth.admin.inviteUserByEmail(email)
  if (inviteError || !invitation.user) return Response.json({ error: 'Davet oluşturulamadı.' }, { status: 409, headers: corsHeaders })
  const { error: registrationError } = await adminClient.from('admin_users').insert({ id: invitation.user.id })
  if (registrationError) {
    if (!existingUser) await adminClient.auth.admin.deleteUser(invitation.user.id)
    return Response.json({ error: 'Davet tamamlanamadı; yönetici erişimi verilmedi.' }, { status: 500, headers: corsHeaders })
  }
  return Response.json({ ok: true }, { headers: corsHeaders })
})
