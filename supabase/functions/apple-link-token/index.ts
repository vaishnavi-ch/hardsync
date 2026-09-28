import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.4'
import { exchangeAppleAuthorizationCode } from '../_shared/apple.ts'

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json; charset=utf-8' },
})

// Called right after a native Sign in with Apple, with the one-time
// authorization code. Exchanges it for a refresh token and stores it so
// account deletion can later revoke the Apple grant (guideline 5.1.1(v)).
// Best-effort: never blocks or fails the sign-in that already succeeded.
Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)
  const authorization = request.headers.get('authorization') ?? ''
  if (!authorization.startsWith('Bearer ')) return json({ error: 'Authentication required' }, 401)

  let body: { authorization_code?: string }
  try {
    body = await request.json()
  } catch {
    return json({ error: 'Invalid request body' }, 400)
  }
  const code = body.authorization_code
  if (!code) return json({ error: 'authorization_code is required' }, 400)

  const url = Deno.env.get('SUPABASE_URL')!
  const caller = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization } },
  })
  const { data: { user }, error: userError } = await caller.auth.getUser()
  if (userError || !user) return json({ error: 'Invalid or expired session' }, 401)

  try {
    const refreshToken = await exchangeAppleAuthorizationCode(code)
    const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
      auth: { persistSession: false },
    })
    const { error } = await admin.from('apple_oauth_tokens').upsert({
      user_id: user.id,
      refresh_token: refreshToken,
      updated_at: new Date().toISOString(),
    })
    if (error) throw error
    return json({ linked: true })
  } catch (e) {
    console.error('[apple-link-token]', e)
    return json({ linked: false })
  }
})
