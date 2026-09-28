// Shared helpers for talking to Apple's Sign in with Apple REST API
// (token exchange + revocation), used by apple-link-token and delete-account.
import { SignJWT, importPKCS8 } from 'https://esm.sh/jose@5.9.6'

function requireEnv(name: string): string {
  const value = Deno.env.get(name)
  if (!value) throw new Error(`Missing required secret: ${name}`)
  return value
}

// client_id is the app's Bundle ID for authorization codes minted by the
// native AuthenticationServices flow (iOS/macOS), per Apple's docs.
async function clientSecret(): Promise<string> {
  const teamId = requireEnv('APPLE_TEAM_ID')
  const keyId = requireEnv('APPLE_KEY_ID')
  const clientId = requireEnv('APPLE_SIGN_IN_CLIENT_ID')
  const privateKeyPem = requireEnv('APPLE_PRIVATE_KEY').replace(/\\n/g, '\n')

  const key = await importPKCS8(privateKeyPem, 'ES256')
  return await new SignJWT({})
    .setProtectedHeader({ alg: 'ES256', kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt()
    .setExpirationTime('5m')
    .setAudience('https://appleid.apple.com')
    .setSubject(clientId)
    .sign(key)
}

export async function exchangeAppleAuthorizationCode(code: string): Promise<string> {
  const clientId = requireEnv('APPLE_SIGN_IN_CLIENT_ID')
  const secret = await clientSecret()
  const response = await fetch('https://appleid.apple.com/auth/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: secret,
      code,
      grant_type: 'authorization_code',
    }),
  })
  const body = await response.json()
  if (!response.ok || !body.refresh_token) {
    throw new Error(`Apple token exchange failed: ${JSON.stringify(body)}`)
  }
  return body.refresh_token as string
}

export async function revokeAppleRefreshToken(refreshToken: string): Promise<void> {
  const clientId = requireEnv('APPLE_SIGN_IN_CLIENT_ID')
  const secret = await clientSecret()
  const response = await fetch('https://appleid.apple.com/auth/revoke', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: secret,
      token: refreshToken,
      token_type_hint: 'refresh_token',
    }),
  })
  if (!response.ok) {
    const text = await response.text()
    throw new Error(`Apple token revocation failed: ${text}`)
  }
}
