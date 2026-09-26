"""
Quick smoke test to validate VERTEX_AGENT_PLATFORM_API_KEY for Live Avatar.
Run: python test_avatar_key.py
"""
import os
import sys
from pathlib import Path

# Load .env
env_path = Path(__file__).resolve().parents[1] / '.env'
if env_path.exists():
    for line in env_path.read_text(encoding='utf-8-sig').splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            name, value = line.split('=', 1)
            os.environ.setdefault(name.strip(), value.strip().strip('"').strip("'"))

key = os.environ.get('VERTEX_AGENT_PLATFORM_API_KEY', '')
std_key = os.environ.get('GEMINI_API_KEY', '')
location = os.environ.get('GEMINI_AVATAR_LOCATION', 'us-central1')

print("VERTEX_AGENT_PLATFORM_API_KEY: " + ('OK set (' + key[:12] + '...)' if key else 'NOT SET'))
print("GEMINI_API_KEY:                " + ('OK set (' + std_key[:12] + '...)' if std_key else 'NOT SET'))
print("Keys are SAME: " + str(key == std_key))
print("GEMINI_AVATAR_LOCATION: " + location)
print()

try:
    from google import genai
except ImportError:
    print("FAIL: google-genai not installed. Run: pip install google-genai")
    sys.exit(1)

print("--- Test 1: Standard client (GEMINI_API_KEY) ---")
try:
    c = genai.Client(api_key=std_key)
    resp = c.models.generate_content(
        model='gemini-2.0-flash-lite',
        contents='Say hello in 3 words.'
    )
    print("PASS Standard client OK: " + resp.text.strip()[:60])
except Exception as e:
    print("FAIL Standard client: " + str(e))

print()
print("--- Test 2: Enterprise avatar client (VERTEX_AGENT_PLATFORM_API_KEY) ---")
try:
    c2 = genai.Client(api_key=key, enterprise=True, location=location)
    models = list(c2.models.list())
    live_models = [m.name for m in models if 'live' in m.name.lower()]
    print("PASS Enterprise client authenticated! Found " + str(len(models)) + " models total.")
    print("  Live models: " + str(live_models[:5] if live_models else '(none - may need allowlist)'))
except Exception as e:
    print("FAIL Enterprise client: " + str(e))
    print()
    print("Diagnosis:")
    err = str(e).lower()
    if 'api key' in err or 'invalid' in err or '401' in err or '403' in err:
        print("  -> Key is INVALID or not provisioned for Enterprise Agent Platform.")
        print("  -> Go to: https://console.cloud.google.com -> Vertex AI -> Agent Platform")
        print("  -> Or use ADC: gcloud auth application-default login")
    elif 'not found' in err or '404' in err:
        print("  -> Key auth OK but endpoint not found.")
        print("  -> Live Avatar may require allowlist. Contact Google Cloud support.")
    else:
        print("  -> Unknown error: " + str(e))
