#!/usr/bin/env python3
"""Offline CLI checks: configuration, requests, streaming and failure modes."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError

spec = importlib.util.spec_from_file_location('susnix_ask', Path(__file__).resolve().parents[1] / 'apps/ask/ask.py')
ask = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ask)


def stream(*chunks, done=True):
    lines = [b': keepalive\n\n']
    for chunk in chunks:
        lines.append(('data: ' + json.dumps(chunk) + '\n\n').encode())
    if done:
        lines.append(b'data: [DONE]\n\n')
    return io.BytesIO(b''.join(lines))


class FakeOpener:
    def __init__(self, response=None, error=None):
        self.response = response
        self.error = error

    def open(self, request, timeout):
        self.request, self.timeout = request, timeout
        if self.error:
            raise self.error
        return self.response


class AskTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        (self.home / 'Desktop').mkdir()
        self.env = {'HOME': str(self.home)}
        self.settings = ('test-key', 'https://api.deepseek.com', 'deepseek-flash', 120)

    def write_env(self, text):
        (self.home / 'Desktop/.env').write_text(text)

    def test_missing_key_and_help(self):
        with self.assertRaisesRegex(ask.AskError, 'Set DEEPSEEK_API_KEY'):
            ask.load_settings(self.env)
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(ask.main(['--help']), 0)
            self.assertEqual(ask.main([]), 2)

    def test_desktop_env_quotes_comments_and_overrides(self):
        self.write_env('export DEEPSEEK_API_KEY="file-key" # comment\nDEEPSEEK_MODEL=custom\nASK_TIMEOUT=30\n')
        self.assertEqual(ask.load_settings(self.env), ('file-key', 'https://api.deepseek.com', 'custom', 30))
        self.env.update(DEEPSEEK_API_KEY='shell-key', DEEPSEEK_MODEL='deepseek-flash')
        self.assertEqual(ask.load_settings(self.env)[0:3:2], ('shell-key', 'deepseek-flash'))
        self.env['DEEPSEEK_API_KEY'] = ''
        with self.assertRaises(ask.AskError):
            ask.load_settings(self.env)

    def test_xdg_desktop_and_explicit_file(self):
        (self.home / '.config').mkdir()
        (self.home / '.config/user-dirs.dirs').write_text('XDG_DESKTOP_DIR="$HOME/Work Desk"\n')
        (self.home / 'Work Desk').mkdir()
        (self.home / 'Work Desk/.env').write_text('DEEPSEEK_API_KEY=xdg-key\n')
        self.assertEqual(ask.load_settings(self.env)[0], 'xdg-key')
        custom = self.home / 'other.env'
        custom.write_text('DEEPSEEK_API_KEY=explicit-key\n')
        self.env['ASK_ENV_FILE'] = str(custom)
        self.assertEqual(ask.load_settings(self.env)[0], 'explicit-key')
        custom.unlink()
        with self.assertRaisesRegex(ask.AskError, 'does not exist'):
            ask.load_settings(self.env)

    def test_env_is_never_executed(self):
        marker = self.home / 'executed'
        self.write_env(f'DEEPSEEK_API_KEY="$(touch {marker})"\nUNKNOWN="unterminated\n')
        self.assertEqual(ask.load_settings(self.env)[0], f'$(touch {marker})')
        self.assertFalse(marker.exists())

    def test_configuration_errors(self):
        for value in ['0', '-2', 'NaN', 'inf', 'slow']:
            with self.subTest(timeout=value), self.assertRaises(ask.AskError):
                ask.load_settings(dict(self.env, DEEPSEEK_API_KEY='key', ASK_TIMEOUT=value))
        for url in ['http://example.com', 'https://key@example.com', 'https://example.com?key=secret', 'https://[invalid']:
            with self.subTest(url=url), self.assertRaises(ask.AskError):
                ask.load_settings(dict(self.env, DEEPSEEK_API_KEY='key', DEEPSEEK_BASE_URL=url))
        self.write_env('DEEPSEEK_API_KEY="unfinished\n')
        with self.assertRaisesRegex(ask.AskError, 'line 1'):
            ask.load_settings(self.env)

    def test_stream_and_request(self):
        opener = FakeOpener(stream(
            {'choices': [{'delta': {'reasoning_content': 'hidden'}}]},
            {'choices': [{'delta': {'content': 'Moon: '}}]},
            {'choices': [{'delta': {'content': '7.34 × 10²² kg.'}, 'finish_reason': 'stop'}]},
        ))
        output = io.StringIO()
        ask.ask('whats the weight of the moon', self.settings, output, opener)
        self.assertEqual(output.getvalue(), 'Moon: 7.34 × 10²² kg.\n')
        request = opener.request
        self.assertEqual(request.full_url, 'https://api.deepseek.com/chat/completions')
        self.assertEqual(request.get_header('Authorization'), 'Bearer test-key')
        payload = json.loads(request.data)
        self.assertEqual(payload['messages'][0]['content'], 'whats the weight of the moon')
        self.assertEqual(payload['model'], 'deepseek-flash')
        self.assertTrue(payload['stream'])
        self.assertEqual(opener.timeout, 120)

    def test_main_joins_arguments(self):
        with patch.object(ask, 'load_settings', return_value=self.settings), patch.object(ask, 'ask') as call:
            self.assertEqual(ask.main(['whats', 'the', 'weight', 'of', 'the', 'moon']), 0)
            self.assertEqual(call.call_args.args[0], 'whats the weight of the moon')

    def test_http_and_network_errors_do_not_leak_secrets(self):
        for code in [400, 401, 402, 403, 404, 429, 500, 302]:
            error = HTTPError('https://api.deepseek.com', code, 'test-key', {}, io.BytesIO(b'test-key'))
            with self.subTest(code=code), self.assertRaises(ask.AskError) as caught:
                ask.ask('test', self.settings, io.StringIO(), FakeOpener(error=error))
            self.assertNotIn('test-key', str(caught.exception))
            self.assertIn(str(code), str(caught.exception))
        with self.assertRaisesRegex(ask.AskError, 'Cannot reach'):
            ask.ask('test', self.settings, io.StringIO(), FakeOpener(error=URLError('secret')))

    def test_empty_malformed_and_interrupted_streams(self):
        for response in [stream(), io.BytesIO(b'data: invalid json\n\n'), stream({'choices': [{'delta': {'content': 'partial'}}]}, done=False), stream({'error': {'message': 'secret'}})]:
            with self.subTest(response=response), self.assertRaises(ask.AskError):
                ask.ask('test', self.settings, io.StringIO(), FakeOpener(response))

    def test_no_terminal_control_sequences(self):
        response = stream({'choices': [{'delta': {'content': 'safe\x1b[31m\x00\x9btext'}}]})
        output = io.StringIO()
        ask.ask('test', self.settings, output, FakeOpener(response))
        self.assertEqual(output.getvalue(), 'safe[31mtext\n')

    def test_truncated_answer_is_reported(self):
        response = stream({'choices': [{'delta': {'content': 'partial'}, 'finish_reason': 'length'}]})
        output = io.StringIO()
        with self.assertRaisesRegex(ask.AskError, 'truncated'):
            ask.ask('test', self.settings, output, FakeOpener(response))
        self.assertEqual(output.getvalue(), 'partial\n')

    def test_closed_output_pipe_is_not_a_network_error(self):
        class ClosedOutput:
            def write(self, text):
                raise BrokenPipeError()
        response = stream({'choices': [{'delta': {'content': 'answer'}}]})
        with self.assertRaises(BrokenPipeError):
            ask.ask('test', self.settings, ClosedOutput(), FakeOpener(response))

    def test_redirects_are_refused(self):
        self.assertIsNone(ask.NoRedirect().redirect_request(None, None, 302, '', {}, 'https://other.example'))


if __name__ == '__main__':
    unittest.main()
