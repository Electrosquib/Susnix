#!/usr/bin/env python3
"""Exercise system-action boundaries using fake providers, never the real session."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / 'configs/quickshell/services/desktop-control.sh'

class DesktopActions(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        self.env = os.environ.copy()
        self.env.update(PATH=str(self.directory)+':'+self.env['PATH'], XDG_RUNTIME_DIR=str(self.directory), ACTION_LOG=str(self.directory/'actions'))
        for name in ('systemctl','hyprctl','brightnessctl','busctl','hyprlock'):
            script = self.directory/name
            script.write_text('#!/bin/bash\nprintf "%s" "${0##*/}" >> "$ACTION_LOG"\nprintf " <%s>" "$@" >> "$ACTION_LOG"\nprintf "\\n" >> "$ACTION_LOG"\n'+
                ('cat "$2" > "$XDG_RUNTIME_DIR/lock-captured"\n' if name=='hyprlock' else ''))
            script.chmod(0o755)
    def tearDown(self):
        self.temp.cleanup()
    def run_action(self,*args):
        return subprocess.run(['bash',str(HELPER),*args],env=self.env,text=True,capture_output=True)
    def log(self):
        path=self.directory/'actions'
        return path.read_text() if path.exists() else ''
    def test_invalid_brightness_never_reaches_provider(self):
        for invalid in ('0','101','-1','50; touch /tmp/pwned','$(echo 50)'):
            self.assertNotEqual(self.run_action('brightness',invalid).returncode,0)
        self.assertEqual(self.log(),'')
        self.assertEqual(self.run_action('brightness','40').returncode,0)
        self.assertIn('<40%>',self.log())
    def test_session_dispatch_only_accepts_fixed_actions(self):
        self.assertNotEqual(self.run_action('reboot; echo bad').returncode,0)
        self.assertEqual(self.log(),'')
        for action in ('logout','reboot','poweroff'):
            self.assertEqual(self.run_action(action).returncode,0)
        self.assertIn('hyprctl <dispatch> <exit>',self.log())
        self.assertIn('systemctl <reboot>',self.log())
        self.assertIn('systemctl <poweroff>',self.log())
    def test_bluetooth_path_and_method_validation(self):
        self.assertNotEqual(self.run_action('bluetooth','/tmp/not-bluez','Connect').returncode,0)
        self.assertNotEqual(self.run_action('bluetooth','/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF','RemoveDevice').returncode,0)
        self.assertEqual(self.log(),'')
        self.assertEqual(self.run_action('bluetooth','/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF','Connect').returncode,0)
        self.assertIn('<org.bluez.Device1> <Connect>',self.log())
    def test_lock_uses_current_palette_and_removes_temporary_config(self):
        result=self.run_action('lock','#050711','#E4ECFF','#00C8FF')
        self.assertEqual(result.returncode,0,result.stderr)
        config=(self.directory/'lock-captured').read_text()
        for color in ('050711','E4ECFF','00C8FF'):
            self.assertIn('rgb('+color+')',config)
        self.assertEqual(list((self.directory/'susnix').glob('lock.*.conf')),[])
        before=self.log()
        self.assertNotEqual(self.run_action('lock','#050711','bad; command','#00C8FF').returncode,0)
        self.assertEqual(self.log(),before)

if __name__=='__main__':
    unittest.main()
