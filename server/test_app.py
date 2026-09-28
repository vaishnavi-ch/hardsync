import base64
import json
import unittest
from unittest.mock import MagicMock, patch

from server import app


class OnlineBackendTests(unittest.TestCase):
    def setUp(self):
        app.ANALYSIS_JOBS.clear()
        self.env = patch.object(app, 'ENV', {
            **app.ENV,
            'SUPABASE_URL': 'https://project.supabase.co',
            'SUPABASE_ANON_KEY': 'publishable',
            'SUPABASE_SERVICE_ROLE_KEY': 'service-role',
            'GEMINI_API_KEY': 'gemini',
            'GEMINI_LIVE_BRIDGE_URL': 'wss://live.example/api/gemini-live',
            'GEMINI_LIVE_SHARED_SECRET': 'shared',
            # Pin explicitly so a developer's local .env (which may have this
            # true for manual testing) can't silently skip the tier/credit
            # gate tests below.
            'REVENUECAT_USE_TEST_STORE': 'false',
        })
        self.env.start()

    def tearDown(self):
        self.env.stop()

    def test_account_reads_supabase_and_never_local_storage(self):
        with patch.object(app, 'supabase_rest', return_value=[{'id': 'user', 'credits': 25}]) as rest:
            result = app.account('00000000-0000-0000-0000-000000000001', 'jwt')
        self.assertEqual(result, {'tier': 'free', 'credits': 25, 'testCalls': False})
        self.assertIn('profiles?select=id', rest.call_args.args[0])

    def test_reservation_uses_atomic_rpc(self):
        with patch.object(app, 'expire_sessions'), patch.object(
            app, 'account', return_value={'tier': 'free'}
        ), patch.object(app, 'supabase_rpc', return_value=[{'id': 'session-id', 'rate_per_minute': 0, 'max_seconds': None}]) as rpc:
            reservation = app.reserve('user', 'text', 'gemini_text', 'context', 'scenario', 'jwt')
        self.assertEqual(reservation, {'id': 'session-id', 'rateCreditsPerMinute': 0, 'maxSeconds': None})
        self.assertEqual(rpc.call_args.args[0], 'reserve_practice_session')
        self.assertEqual(rpc.call_args.args[1]['p_scenario_id'], 'scenario')

    def test_paid_modes_require_verified_entitlement(self):
        with patch.object(app, 'expire_sessions'), patch.object(
            app, 'account', return_value={'tier': 'free', 'credits': 0}
        ), patch.object(app, 'supabase_rpc') as rpc:
            with self.assertRaises(app.ApiError) as error:
                app.reserve('user', 'audio', 'gemini_live', access_token='jwt')
        self.assertEqual(error.exception.status, 403)
        rpc.assert_not_called()

    def test_pro_allows_audio(self):
        with patch.object(app, 'expire_sessions'), patch.object(
            app, 'account', return_value={'tier': 'pro', 'credits': 0}
        ), patch.object(app, 'supabase_rpc', return_value=[
            {'id': 'audio-session', 'rate_per_minute': 1, 'max_seconds': 600},
        ]) as rpc:
            self.assertEqual(
                app.reserve('user', 'audio', 'gemini_live', access_token='jwt')['id'],
                'audio-session',
            )
        rpc.assert_called_once()

    def test_pro_video_blocked_without_credits(self):
        with patch.object(app, 'expire_sessions'), patch.object(
            app, 'account', return_value={'tier': 'pro', 'credits': 0}
        ), patch.object(app, 'supabase_rpc') as rpc:
            with self.assertRaises(app.ApiError) as error:
                app.reserve('user', 'video', 'gemini_live', access_token='jwt')
        self.assertEqual(error.exception.status, 403)
        rpc.assert_not_called()

    def test_ultra_allows_audio_and_video(self):
        with patch.object(app, 'expire_sessions'), patch.object(
            app, 'account', return_value={'tier': 'ultra', 'credits': 0}
        ), patch.object(app, 'supabase_rpc', side_effect=[
            [{'id': 'audio-session', 'rate_per_minute': 1, 'max_seconds': 600}],
            [{'id': 'video-session', 'rate_per_minute': 6, 'max_seconds': 300}],
        ]) as rpc:
            self.assertEqual(
                app.reserve('user', 'audio', 'gemini_live', access_token='jwt')['id'],
                'audio-session',
            )
            self.assertEqual(
                app.reserve('user', 'video', 'gemini_live', access_token='jwt')['id'],
                'video-session',
            )
        self.assertEqual(rpc.call_count, 2)

    def test_credit_pack_unlocks_audio_and_video_on_free_tier(self):
        with patch.object(app, 'expire_sessions'), patch.object(
            app, 'account', return_value={'tier': 'free', 'credits': 6}
        ), patch.object(app, 'supabase_rpc', side_effect=[
            [{'id': 'audio-session', 'rate_per_minute': 1, 'max_seconds': 360}],
            [{'id': 'video-session', 'rate_per_minute': 6, 'max_seconds': 60}],
        ]) as rpc:
            self.assertEqual(
                app.reserve('user', 'audio', 'gemini_live', access_token='jwt')['id'],
                'audio-session',
            )
            self.assertEqual(
                app.reserve('user', 'video', 'gemini_live', access_token='jwt')['id'],
                'video-session',
            )
        self.assertEqual(rpc.call_count, 2)

    def test_credit_pack_below_one_minute_still_blocked(self):
        with patch.object(app, 'expire_sessions'), patch.object(
            app, 'account', return_value={'tier': 'free', 'credits': 5}
        ), patch.object(app, 'supabase_rpc') as rpc:
            with self.assertRaises(app.ApiError) as error:
                app.reserve('user', 'video', 'gemini_live', access_token='jwt')
        self.assertEqual(error.exception.status, 403)
        rpc.assert_not_called()

    def test_insufficient_credits_surfaces_as_payment_required(self):
        with patch.object(app, 'expire_sessions'), patch.object(
            app, 'account', return_value={'tier': 'pro', 'credits': 0}
        ), patch.object(app, 'supabase_rest', side_effect=app.ApiError(
            'Not enough practice credits for this call. Buy more credits or upgrade your plan.', 402,
        )):
            with self.assertRaises(app.ApiError) as error:
                app.reserve('user', 'audio', 'gemini_live', access_token='jwt')
        self.assertEqual(error.exception.status, 402)

    def test_failed_gemini_live_setup_cancels_reservation(self):
        with patch.object(app, 'reserve', return_value={'id': 'sid', 'rateCreditsPerMinute': 0, 'maxSeconds': None}), patch.object(
            app, 'gemini_live_url', side_effect=app.ApiError('unavailable', 503)
        ), patch.object(app, 'cancel_unconnected_session') as cancel:
            with self.assertRaises(app.ApiError):
                app.create_session('user', {'mode': 'video'}, 'jwt')
        cancel.assert_called_once_with('user', 'sid', 'jwt')

    def test_video_uses_signed_gemini_live_url(self):
        with patch.object(app, 'reserve', return_value={'id': 'sid', 'rateCreditsPerMinute': 6, 'maxSeconds': 300}):
            result = app.create_session('user', {'mode': 'video'}, 'jwt')
        self.assertEqual(result['realtimeProvider'], 'gemini_live')
        self.assertEqual(result['rateCreditsPerMinute'], 6)
        self.assertEqual(result['maxSeconds'], 300)
        self.assertTrue(result['liveUrl'].startswith('wss://live.example/api/gemini-live?'))
        self.assertIn('signature=', result['liveUrl'])

    def test_audio_uses_signed_gemini_live_url(self):
        with patch.object(app, 'reserve', return_value={'id': 'sid', 'rateCreditsPerMinute': 1, 'maxSeconds': 600}):
            result = app.create_session('user', {'mode': 'audio'}, 'jwt')
        self.assertEqual(result['realtimeProvider'], 'gemini_live')
        self.assertEqual(result['rateCreditsPerMinute'], 1)
        self.assertTrue(result['liveUrl'].startswith('wss://live.example/api/gemini-live?'))
        self.assertIn('signature=', result['liveUrl'])

    def test_generation_consumes_server_quota_before_provider_call(self):
        row = {'id': 'sid', 'state': 'active', 'mode': 'text', 'requests': 0}
        response = {'candidates': [{'content': {'parts': [{'text': 'Hello'}]}}]}
        with patch.object(app, 'session_for', return_value=row), patch.object(
            app, 'supabase_rpc', return_value=1
        ) as rpc, patch.object(app, 'gemini_generate', return_value=(response, 'model')):
            self.assertEqual(app.generate('user', {'sessionId': 'sid', 'payload': {'contents': []}}, 'jwt'), response)
        self.assertEqual(rpc.call_args.args[0], 'consume_practice_generation')

    def test_invalid_generation_does_not_consume_quota(self):
        row = {'id': 'sid', 'state': 'active', 'mode': 'text', 'requests': 0}
        with patch.object(app, 'session_for', return_value=row), patch.object(app, 'supabase_rpc') as rpc:
            with self.assertRaises(app.ApiError):
                app.generate('user', {'sessionId': 'sid', 'payload': None}, 'jwt')
        rpc.assert_not_called()

    def test_revenuecat_webhook_is_authenticated(self):
        app.ENV['REVENUECAT_WEBHOOK_AUTHORIZATION'] = 'Bearer webhook'
        payload = {'api_version': '1.0', 'event': {
            'id': 'evt-1', 'type': 'VIRTUAL_CURRENCY_TRANSACTION', 'source': 'in_app_purchase',
            'app_user_id': '00000000-0000-0000-0000-000000000001',
            'adjustments': [{'amount': 3, 'currency': {'code': 'CR'}}],
        }}
        with self.assertRaises(app.ApiError) as error:
            app.apply_revenuecat_webhook(payload, 'wrong')
        self.assertEqual(error.exception.status, 401)

    def test_revenuecat_webhook_grants_virtual_currency(self):
        app.ENV['REVENUECAT_WEBHOOK_AUTHORIZATION'] = 'Bearer webhook'
        payload = {'api_version': '1.0', 'event': {
            'id': 'evt-1', 'type': 'VIRTUAL_CURRENCY_TRANSACTION', 'source': 'in_app_purchase',
            'app_user_id': '00000000-0000-0000-0000-000000000001',
            'adjustments': [{'amount': 250, 'currency': {'code': 'CR'}}],
        }}
        with patch.object(app, 'supabase_rpc_service', return_value=260) as rpc:
            result = app.apply_revenuecat_webhook(payload, 'Bearer webhook')
        self.assertEqual(result, {'received': True, 'applied': True, 'balance': 260})
        rpc.assert_called_once_with('apply_credit_event', {
            'p_user_id': '00000000-0000-0000-0000-000000000001',
            'p_event_id': 'evt-1', 'p_amount': 250, 'p_reason': 'revenuecat_virtual_currency',
        })

    def test_revenuecat_webhook_ignores_unrelated_events(self):
        app.ENV['REVENUECAT_WEBHOOK_AUTHORIZATION'] = 'Bearer webhook'
        payload = {'api_version': '1.0', 'event': {
            'id': 'evt-2', 'type': 'INITIAL_PURCHASE',
            'app_user_id': '00000000-0000-0000-0000-000000000001',
        }}
        with patch.object(app, 'supabase_rpc_service') as rpc:
            result = app.apply_revenuecat_webhook(payload, 'Bearer webhook')
        self.assertFalse(result['applied'])
        rpc.assert_not_called()

    def test_revenuecat_webhook_ignores_non_credit_currency(self):
        app.ENV['REVENUECAT_WEBHOOK_AUTHORIZATION'] = 'Bearer webhook'
        payload = {'api_version': '1.0', 'event': {
            'id': 'evt-3', 'type': 'VIRTUAL_CURRENCY_TRANSACTION',
            'app_user_id': '00000000-0000-0000-0000-000000000001',
            'adjustments': [{'amount': 3, 'currency': {'code': 'GOLD'}}],
        }}
        with patch.object(app, 'supabase_rpc_service') as rpc:
            result = app.apply_revenuecat_webhook(payload, 'Bearer webhook')
        self.assertFalse(result['applied'])
        rpc.assert_not_called()

    def test_recording_uploads_are_disabled(self):
        with self.assertRaises(app.ApiError) as raised:
            app.recording_chunk('user', 'sid', {
                'mime': 'video/webm', 'offset': 0,
                'chunk': 'YWJj', 'complete': True,
            }, 'jwt')
        self.assertEqual(raised.exception.status, 410)

if __name__ == '__main__':
    unittest.main()
