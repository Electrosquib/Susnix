#!/usr/bin/env python3
"""Reproduce delayed Hyprland startup with a fake clipboard client, without rebooting."""
import os
from pathlib import Path
import signal
import socket
import subprocess
import tempfile
import time
import unittest

HELPER=Path(__file__).resolve().parents[1]/'configs/virtualbox/clipboard.sh'

class ClipboardStartup(unittest.TestCase):
    @unittest.skipUnless(Path('/dev/vboxguest').exists(), 'requires a VirtualBox guest')
    def test_waits_for_missing_and_empty_session_file(self):
        with tempfile.TemporaryDirectory(prefix='susnix-clipboard-boot-') as directory:
            root=Path(directory);bin_dir=root/'bin';bin_dir.mkdir()
            session=root/'hypr'/'delayed-session';session.mkdir(parents=True)
            marker=root/'client-started'
            client=bin_dir/'VBoxClient'
            client.write_text('#!/usr/bin/python\nimport os,time\nfrom pathlib import Path\nPath(os.environ["CLIPBOARD_TEST_MARKER"]).write_text("started")\ntime.sleep(60)\n')
            client.chmod(0o755)
            env=os.environ.copy();env.update(PATH=str(bin_dir)+':'+env['PATH'],XDG_RUNTIME_DIR=str(root),WAYLAND_DISPLAY='wayland-test',HYPRLAND_INSTANCE_SIGNATURE='delayed-session',CLIPBOARD_TEST_MARKER=str(marker))
            server=socket.socket(socket.AF_UNIX);server.bind(str(root/'wayland-test'))
            process=subprocess.Popen(['bash',str(HELPER),'run'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,start_new_session=True)
            try:
                time.sleep(.3)
                self.assertIsNone(process.poll(),'launcher quit before the session marker existed')
                self.assertFalse(marker.exists(),'client started before the session was ready')
                (session/'hyprland.lock').touch()
                time.sleep(.2)
                self.assertIsNone(process.poll(),'launcher quit on an empty session file')
                self.assertFalse(marker.exists())
                (session/'hyprland.lock').write_text(str(os.getpid())+'\nwayland-test\n')
                deadline=time.monotonic()+3
                while not marker.exists() and time.monotonic()<deadline:time.sleep(.05)
                self.assertTrue(marker.exists(),'client did not start after the session became ready')
                self.assertIsNone(process.poll())
            finally:
                os.killpg(process.pid,signal.SIGTERM)
                output=process.communicate(timeout=5)[0]
                server.close()
            self.assertIn('Waiting for the Hyprland clipboard session',output)
            self.assertEqual(process.returncode,0)

if __name__=='__main__':unittest.main()
