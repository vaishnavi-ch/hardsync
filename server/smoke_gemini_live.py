"""Small, secret-safe connectivity check for the configured Gemini Live model."""

import asyncio
import os

from google.genai import types

from gemini_live_bridge import client


async def main() -> None:
    model = os.environ.get('GEMINI_LIVE_MODEL', 'gemini-3.8-live')
    config = types.LiveConnectConfig(
        response_modalities=['AUDIO'],
        system_instruction='Reply briefly and clearly.',
        output_audio_transcription={},
    )

    print(f'Connecting to {model}...')
    async with client().aio.live.connect(model=model, config=config) as live:
        print('Gemini Live connected.')
        await live.send_client_content(
            turns=[types.Content(
                role='user',
                parts=[types.Part(text='Say: Gemini Live audio is working.')],
            )],
            turn_complete=True,
        )

        audio_bytes = 0
        transcript = ''
        async with asyncio.timeout(30):
            async for response in live.receive():
                content = getattr(response, 'server_content', None)
                if not content:
                    continue
                output = getattr(content, 'output_transcription', None)
                transcript += getattr(output, 'text', '') if output else ''
                turn = getattr(content, 'model_turn', None)
                for part in getattr(turn, 'parts', []) if turn else []:
                    inline = getattr(part, 'inline_data', None)
                    if inline and inline.data and (inline.mime_type or '').startswith('audio/'):
                        audio_bytes += len(inline.data)
                if getattr(content, 'turn_complete', False):
                    break

        if audio_bytes == 0:
            raise RuntimeError('Gemini completed the turn without returning audio.')
        print(f'Audio received: {audio_bytes} bytes.')
        if transcript.strip():
            print(f'Transcript: {transcript.strip()}')


if __name__ == '__main__':
    asyncio.run(main())
