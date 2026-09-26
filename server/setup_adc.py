"""
Replaces 'gcloud auth application-default login' without needing gcloud CLI.
This writes Application Default Credentials to the standard ADC path so the
google-genai SDK can pick them up automatically.

Run: python setup_adc.py
"""
import json
import os
import sys
import webbrowser
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs, urlencode
from urllib.request import urlopen, Request
import threading
import secrets
import base64
import hashlib

# ADC file location (same path gcloud uses)
ADC_PATH = Path(os.environ.get('APPDATA', '')) / 'gcloud' / 'application_default_credentials.json'

# Google OAuth2 endpoints
AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
TOKEN_URL = 'https://oauth2.googleapis.com/token'

# Google Cloud SDK client credentials (public, same as gcloud uses)
CLIENT_ID = '764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com'
CLIENT_SECRET = 'd-FL95Q19q7MQmFpd7hHD0Ty'

SCOPES = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/accounts.reauth',
]

REDIRECT_PORT = 8085
REDIRECT_URI = f'http://localhost:{REDIRECT_PORT}'

auth_code = None
auth_error = None

class CallbackHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global auth_code, auth_error
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        if 'code' in params:
            auth_code = params['code'][0]
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(b'<html><body><h2>Authentication successful!</h2><p>You can close this tab and return to the terminal.</p></body></html>')
        elif 'error' in params:
            auth_error = params.get('error', ['unknown'])[0]
            self.send_response(400)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(f'<html><body><h2>Error: {auth_error}</h2></body></html>'.encode())
        else:
            self.send_response(400)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress server logs

def generate_pkce():
    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode()).digest()
    ).rstrip(b'=').decode()
    return verifier, challenge

def main():
    print("=" * 55)
    print("  Google Application Default Credentials Setup")
    print("=" * 55)
    print()

    if ADC_PATH.exists():
        print("Existing ADC found at:")
        print(f"  {ADC_PATH}")
        ans = input("Overwrite? (y/n): ").strip().lower()
        if ans != 'y':
            print("Aborted.")
            return

    verifier, challenge = generate_pkce()

    params = {
        'client_id': CLIENT_ID,
        'redirect_uri': REDIRECT_URI,
        'response_type': 'code',
        'scope': ' '.join(SCOPES),
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
    }
    url = AUTH_URL + '?' + urlencode(params)

    # Start local callback server
    server = HTTPServer(('localhost', REDIRECT_PORT), CallbackHandler)
    thread = threading.Thread(target=server.handle_request)
    thread.daemon = True
    thread.start()

    print("Opening browser for Google sign-in...")
    print("If the browser doesn't open, visit this URL manually:")
    print()
    print(url)
    print()
    webbrowser.open(url)

    print("Waiting for browser callback...")
    thread.join(timeout=120)
    server.server_close()

    if auth_error:
        print(f"Auth error: {auth_error}")
        sys.exit(1)
    if not auth_code:
        print("Timed out waiting for auth callback.")
        sys.exit(1)

    print("Auth code received. Exchanging for tokens...")

    token_data = urlencode({
        'code': auth_code,
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'redirect_uri': REDIRECT_URI,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
    }).encode()

    req = Request(TOKEN_URL, data=token_data, method='POST')
    req.add_header('Content-Type', 'application/x-www-form-urlencoded')
    with urlopen(req) as resp:
        tokens = json.load(resp)

    if 'error' in tokens:
        print(f"Token error: {tokens}")
        sys.exit(1)

    # Write ADC file in the same format gcloud uses
    adc = {
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'refresh_token': tokens['refresh_token'],
        'type': 'authorized_user',
        'universe_domain': 'googleapis.com',
    }
    ADC_PATH.parent.mkdir(parents=True, exist_ok=True)
    ADC_PATH.write_text(json.dumps(adc, indent=2))

    print()
    print("SUCCESS! ADC credentials saved to:")
    print(f"  {ADC_PATH}")
    print()
    print("Now get your Google Cloud Project ID from:")
    print("  https://console.cloud.google.com")
    print("And set it in your .env file:")
    print("  GOOGLE_CLOUD_PROJECT=your-project-id")

if __name__ == '__main__':
    main()
