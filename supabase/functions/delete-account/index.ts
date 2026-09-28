import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.57.4'
import { revokeAppleRefreshToken } from '../_shared/apple.ts'

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json; charset=utf-8' },
})

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)
  const authorization = request.headers.get('authorization') ?? ''
  if (!authorization.startsWith('Bearer ')) return json({ error: 'Authentication required' }, 401)

  const url = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const caller = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization } },
  })
  const { data: { user }, error: userError } = await caller.auth.getUser()
  if (userError || !user) return json({ error: 'Invalid or expired session' }, 401)

  const admin = createClient(url, serviceKey, { auth: { persistSession: false } })

  // Apple requires revoking the Sign in with Apple grant when a linked
  // account is deleted (App Store guideline 5.1.1(v)). Best-effort: a
  // revocation failure must never block the user from deleting their account.
  const { data: appleToken } = await admin
    .from('apple_oauth_tokens')
    .select('refresh_token')
    .eq('user_id', user.id)
    .maybeSingle()
  if (appleToken?.refresh_token) {
    try {
      await revokeAppleRefreshToken(appleToken.refresh_token)
    } catch (e) {
      console.error('[delete-account] Apple token revocation failed', e)
    }
  }

  // Custom scenarios use ON DELETE SET NULL, so remove them explicitly.
  const { error: scenarioError } = await admin.from('scenarios').delete().eq('created_by', user.id)
  if (scenarioError) return json({ error: 'Could not delete account data' }, 500)

  // All remaining user-owned rows cascade from profiles/auth.users, including apple_oauth_tokens.
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id)
  if (deleteError) return json({ error: 'Could not delete account' }, 500)
  return json({ deleted: true })
})
