"""Authenticated browser-to-Gemini Live bridge for HardSync.

Run separately from app.py. app.py issues a five-minute signed connection URL;
this process verifies that URL, then keeps the Google Cloud connection private.
"""
import asyncio
import base64
import hashlib
import hmac
import json
import os
import time
import traceback
from contextlib import suppress
from pathlib import Path
from urllib.parse import quote
from urllib.request import Request, urlopen

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from google import genai
from google.genai import types

app = FastAPI()

def load_project_environment():
    path = Path(__file__).resolve().parents[1] / '.env'
    if path.exists():
        for line in path.read_text(encoding='utf-8-sig').splitlines():
            if '=' in line and not line.lstrip().startswith('#'):
                name, value = line.split('=', 1)
                os.environ.setdefault(name.strip(), value.strip().strip('"').strip("'"))
    os.environ.setdefault('SUPABASE_URL', os.environ.get('NEXT_PUBLIC_SUPABASE_URL', ''))
    os.environ.setdefault('SUPABASE_ANON_KEY', os.environ.get(
        'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY', os.environ.get('SUPABASE_PUBLISHABLE_KEY', '')))

load_project_environment()

def require_ticket(session_id: str, owner: str, expires: str, signature: str) -> None:
    secret = os.environ.get('GEMINI_LIVE_SHARED_SECRET', '')
    if not secret or not session_id or not owner or not expires or not signature:
        raise ValueError('Missing session ticket.')
    if int(expires) < int(time.time()):
        raise ValueError('Session ticket expired.')
    message = f'{session_id}.{owner}.{expires}'.encode()
    expected = hmac.new(secret.encode(), message, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, signature):
        raise ValueError('Invalid session ticket.')

def client():
    # Credentials stay on this local server and are never sent to the browser.
    provider = os.environ.get('GEMINI_LIVE_API_PROVIDER', '').lower()
    if provider == 'gemini':
        key = os.environ.get('GEMINI_API_KEY', '')
        if key:
            return genai.Client(api_key=key)

    key = os.environ.get('GEMINI_LIVE_API_KEY', '')
    if key:
        return genai.Client(vertexai=True, api_key=key)

    # Standard Agent Platform projects use ADC.
    project = os.environ.get('GOOGLE_CLOUD_PROJECT', '')
    if project:
        return genai.Client(vertexai=True, project=project,
                            location=os.environ.get('GOOGLE_CLOUD_LOCATION', 'global'))
    raise RuntimeError('Set GEMINI_LIVE_API_KEY (Express Mode) or configure GOOGLE_CLOUD_PROJECT with ADC.')

def avatar_client():
    # Live Avatar (video mode) only exists on the Gemini Enterprise Agent
    # Platform endpoints, reached with `enterprise=True` + an Agent Platform
    # API key. This is a distinct credential/endpoint from the plain Gemini
    # Developer API key `client()` uses for audio/text and vision analysis.
    key = os.environ.get('VERTEX_AGENT_PLATFORM_API_KEY', '')
    if not key:
        raise RuntimeError('Set VERTEX_AGENT_PLATFORM_API_KEY to enable Live Avatar video calls.')
    return genai.Client(api_key=key, enterprise=True,
                        location=os.environ.get('GEMINI_AVATAR_LOCATION', 'us-central1'))

def scenario_prompt(session_id: str, owner: str, access_token: str) -> tuple[str, str, str, str]:
    """Read roleplay context (persona voice, mode, avatar) with the signed-in user's RLS-scoped token."""
    url = os.environ.get('SUPABASE_URL', '').rstrip('/')
    key = os.environ.get('SUPABASE_ANON_KEY', '')
    if not url or not key:
        raise RuntimeError('Supabase public configuration is missing.')
    try:
        headers = {'apikey': key, 'Authorization': 'Bearer ' + access_token}
        with urlopen(Request(url + '/auth/v1/user', headers=headers), timeout=10) as response:
            user = json.load(response)
        if user.get('id') != owner:
            raise RuntimeError('Authenticated user does not own this session.')
        endpoint = (url + '/rest/v1/practice_sessions?select=context,voice_name,mode,avatar_name&id=eq.' +
                    quote(session_id, safe='') + '&user_id=eq.' + quote(owner, safe='') +
                    '&provider=eq.gemini_live&limit=1')
        request = Request(endpoint, headers=headers)
        with urlopen(request, timeout=10) as response:
            rows = json.load(response)
        if not rows:
            raise RuntimeError('Session not found.')
        row = rows[0]
        return (str(row.get('context') or ''), str(row.get('voice_name') or ''),
                str(row.get('mode') or ''), str(row.get('avatar_name') or ''))
    except (OSError, ValueError, KeyError) as error:
        raise RuntimeError('Could not load the session from Supabase.') from error

async def relay_from_browser(socket: WebSocket, live, vision_state: dict):
    while True:
        message = await socket.receive_json()
        kind = message.get('type')
        if kind == 'audio':
            await live.send_realtime_input(audio=types.Blob(
                data=base64.b64decode(message['data']), mime_type='audio/pcm;rate=16000'))
        elif kind == 'video':
            frame = base64.b64decode(message['data'])
            vision_state['frame'] = frame
            await live.send_realtime_input(video=types.Blob(
                data=frame, mime_type='image/jpeg'))
        elif kind == 'text':
            await live.send_client_content(turns=[types.Content(
                role='user', parts=[types.Part(text=str(message.get('data', '')))])], turn_complete=True)
        elif kind == 'end':
            return

async def relay_from_gemini(socket: WebSocket, live):
    # Some SDK versions finish an individual receive iterator at turn boundaries.
    # Re-enter it so a completed Gemini response never ends the browser call.
    while True:
        async for response in live.receive():
            content = getattr(response, 'server_content', None)
            if not content:
                continue
            if getattr(content, 'interrupted', False):
                await socket.send_json({'type': 'interrupted'})
            for attr, event_name in (('input_transcription', 'utterance'), ('output_transcription', 'utterance')):
                item = getattr(content, attr, None)
                text = getattr(item, 'text', None) if item else None
                if text:
                    print(f'[DEBUG] {event_name} ({attr}): {text!r}', flush=True)
                    await socket.send_json({'type': event_name,
                        'role': 'user' if attr == 'input_transcription' else 'replica', 'text': text})
            turn = getattr(content, 'model_turn', None)
            for part in getattr(turn, 'parts', []) if turn else []:
                inline = getattr(part, 'inline_data', None)
                if inline and inline.data:
                    mime = inline.mime_type or ''
                    if mime.startswith('audio/'):
                        await socket.send_json({'type': 'audio', 'data': base64.b64encode(inline.data).decode()})
                    elif mime.startswith('video/'):
                        print(f'[DEBUG] relaying avatar_video chunk mime={mime} bytes={len(inline.data)}', flush=True)
                        await socket.send_json({'type': 'avatar_video', 'mime': mime,
                                                'data': base64.b64encode(inline.data).decode()})
            if getattr(content, 'turn_complete', False):
                print('[DEBUG] turn_complete', flush=True)
                await socket.send_json({'type': 'turn_complete'})

ANALYSIS_INTERVAL_SECONDS = 6
ANALYSIS_PROMPT = (
    'You are an expert executive-presence coach observing one still frame from a live '
    'video rehearsal call. Judge only what is visible: facial expression, eye contact with '
    'the camera, and posture/body language. Respond with ONLY compact JSON, no markdown, '
    'matching exactly this shape: '
    '{"confidence": <integer 0-100>, "expression": "<2-3 word label>", '
    '"eyeContact": "<direct|looking away|looking down>", "posture": "<2-3 word label>", '
    '"tip": "<one short, actionable coaching sentence>"}'
)

async def periodic_visual_analysis(socket: WebSocket, vision_state: dict):
    """Piggybacks on the video frames already streamed to Gemini Live to give the
    user a live, real confidence/expression readout instead of a static mock value."""
    model = os.environ.get('GEMINI_ANALYSIS_MODEL', 'gemini-3.6-flash')
    while True:
        await asyncio.sleep(ANALYSIS_INTERVAL_SECONDS)
        frame = vision_state.get('frame')
        if not frame or vision_state.get('busy'):
            continue
        vision_state['busy'] = True
        try:
            response = await client().aio.models.generate_content(
                model=model,
                contents=[types.Content(role='user', parts=[
                    types.Part(inline_data=types.Blob(data=frame, mime_type='image/jpeg')),
                    types.Part(text=ANALYSIS_PROMPT),
                ])],
                config=types.GenerateContentConfig(response_mime_type='application/json'),
            )
            raw = (getattr(response, 'text', None) or '').strip()
            parsed = json.loads(raw)
            payload = {
                'type': 'analysis',
                'confidence': max(0, min(100, int(parsed.get('confidence', 0)))),
                'expression': str(parsed.get('expression', ''))[:40],
                'eyeContact': str(parsed.get('eyeContact', ''))[:40],
                'posture': str(parsed.get('posture', ''))[:40],
                'tip': str(parsed.get('tip', ''))[:160],
            }
            await socket.send_json(payload)
        except Exception:
            pass  # A missed analysis tick should never interrupt the call.
        finally:
            vision_state['busy'] = False

@app.websocket('/api/gemini-live')
async def gemini_live(socket: WebSocket):
    try:
        require_ticket(socket.query_params.get('sessionId', ''), socket.query_params.get('owner', ''),
                       socket.query_params.get('expires', ''), socket.query_params.get('signature', ''))
    except (ValueError, TypeError):
        await socket.close(code=1008)
        return
    await socket.accept()
    try:
        auth = await asyncio.wait_for(socket.receive_json(), timeout=10)
        auth_data = auth.get('data', {})
        access_token = auth_data.get('accessToken') if auth.get('type') == 'auth' else None
        if not isinstance(access_token, str) or not access_token:
            raise RuntimeError('Sign in again to start a Gemini Live session.')
        prompt_context, voice_name, mode, avatar_name = scenario_prompt(
            socket.query_params['sessionId'], socket.query_params['owner'], access_token)
        prompt = ('You are a realistic leadership-roleplay counterpart in HardSync. Stay in character, '
                  'listen closely, challenge vague answers politely, and keep spoken replies concise. '
                  'Do not say the user cut you off or interrupted you unless their speech clearly overlaps '
                  'your spoken reply. Brief pauses, background noise, and silence are not interruptions.\n\n'
                  + prompt_context)
        use_avatar = mode == 'video' and bool(avatar_name)
        print(f'[DEBUG] session mode={mode!r} voice_name={voice_name!r} avatar_name={avatar_name!r} use_avatar={use_avatar}', flush=True)
        config_kwargs = dict(
            response_modalities=['VIDEO'] if use_avatar else ['AUDIO'],
            system_instruction=prompt,
            input_audio_transcription={}, output_audio_transcription={})
        if use_avatar:
            config_kwargs['avatar_config'] = types.AvatarConfig(avatar_name=avatar_name)
        if voice_name:
            config_kwargs['speech_config'] = types.SpeechConfig(
                voice_config=types.VoiceConfig(
                    prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=voice_name)))
        config = types.LiveConnectConfig(**config_kwargs)
        live_client = avatar_client() if use_avatar else client()
        async with live_client.aio.live.connect(
            model=os.environ.get('GEMINI_LIVE_MODEL', 'gemini-3.8-live'), config=config) as live:
            await socket.send_json({'type': 'connected'})
            vision_state = {'frame': None, 'busy': False}
            browser = asyncio.create_task(relay_from_browser(socket, live, vision_state))
            responses = asyncio.create_task(relay_from_gemini(socket, live))
            analysis = asyncio.create_task(periodic_visual_analysis(socket, vision_state))
            done, pending = await asyncio.wait(
                (browser, responses, analysis), return_when=asyncio.FIRST_COMPLETED)
            for task in pending:
                task.cancel()
                with suppress(asyncio.CancelledError):
                    await task
            for task in done:
                if task is not analysis:
                    task.result()
    except WebSocketDisconnect:
        return
    except Exception as exc:
        print(f'[DEBUG] gemini_live failed: {exc!r}', flush=True)
        traceback.print_exc()
        with suppress(Exception):
            await socket.send_json({'type': 'error', 'message': f'Gemini Live connection failed: {exc}'})
        with suppress(Exception):
            await socket.close(code=1011)
