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
    def test_login_service_discovers_display_without_inherited_environment(self):
        with tempfile.TemporaryDirectory(prefix='susnix-clipboard-login-') as directory:
            root=Path(directory);bin_dir=root/'bin';bin_dir.mkdir()
            session=root/'hypr'/'new-login';session.mkdir(parents=True)
            marker=root/'client-started'
            client=bin_dir/'VBoxClient'
            client.write_text('#!/usr/bin/python\nimport os,time\nfrom pathlib import Path\nPath(os.environ["CLIPBOARD_TEST_MARKER"]).write_text(os.environ["WAYLAND_DISPLAY"]+"/"+os.environ["HYPRLAND_INSTANCE_SIGNATURE"])\ntime.sleep(60)\n')
            client.chmod(0o755)
            (bin_dir/'pgrep').write_text('#!/bin/sh\n[ -n \"$CLIPBOARD_TEST_LEGACY_PID\" ] && echo \"$CLIPBOARD_TEST_LEGACY_PID\"\nexit 0\n')
            (bin_dir/'pgrep').chmod(0o755)
            legacy=subprocess.Popen(['python','-c','import ctypes,time; ctypes.CDLL(None).prctl(15,b"VBoxClient",0,0,0); time.sleep(60)','--clipboard'])
            env=os.environ.copy()
            env['CLIPBOARD_TEST_LEGACY_PID']=str(legacy.pid)
            for name in ('WAYLAND_DISPLAY','HYPRLAND_INSTANCE_SIGNATURE','DISPLAY'):env.pop(name,None)
            env.update(HOME=str(root),PATH=str(bin_dir)+':'+env['PATH'],XDG_RUNTIME_DIR=str(root),CLIPBOARD_TEST_MARKER=str(marker))
            compositor=subprocess.Popen(['python','-c','import ctypes,time; ctypes.CDLL(None).prctl(15,b"Hyprland",0,0,0); time.sleep(60)'])
            server=socket.socket(socket.AF_UNIX)
            process=subprocess.Popen(['bash',str(HELPER),'watch'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,start_new_session=True)
            try:
                time.sleep(.3)
                self.assertIsNone(process.poll(),'login watcher exited without a desktop environment')
                self.assertFalse(marker.exists())
                # Ignore stale lock files, including live PIDs that are not Hyprland.
                (session/'hyprland.lock').write_text(str(os.getpid())+'\nwayland-7\n')
                server.bind(str(root/'wayland-7'))
                time.sleep(2.2)
                self.assertFalse(marker.exists(),'watcher selected a non-compositor PID')
                (session/'hyprland.lock').write_text(str(compositor.pid)+'\nwayland-7\n')
                deadline=time.monotonic()+5
                while not marker.exists() and time.monotonic()<deadline:time.sleep(.05)
                self.assertEqual(marker.read_text(),'wayland-7/new-login')
                self.assertIsNone(process.poll())
                legacy.wait(timeout=2)
                self.assertEqual(legacy.returncode,-signal.SIGTERM,
                                 'watcher failed to retire the legacy bridge')
                # A second compositor must get a fresh clipboard connection.
                marker.unlink()
                compositor.terminate();compositor.wait(timeout=5)
                compositor=subprocess.Popen(['python','-c','import ctypes,time; ctypes.CDLL(None).prctl(15,b"Hyprland",0,0,0); time.sleep(60)'])
                time.sleep(.1)
                (session/'hyprland.lock').write_text(str(compositor.pid)+'\nwayland-7\n')
                deadline=time.monotonic()+8
                while not marker.exists() and time.monotonic()<deadline:time.sleep(.05)
                self.assertEqual(marker.read_text(),'wayland-7/new-login')
            finally:
                os.killpg(process.pid,signal.SIGTERM)
                output=process.communicate(timeout=5)[0]
                compositor.terminate();compositor.wait(timeout=5);server.close()
                if legacy.poll() is None:legacy.terminate();legacy.wait(timeout=5)
            self.assertIn('Watching for an active Hyprland session',output)
            self.assertEqual(process.returncode,0)

    @unittest.skipUnless(Path('/dev/vboxguest').exists(), 'requires a VirtualBox guest')
    def test_waits_for_missing_and_empty_session_file(self):
        with tempfile.TemporaryDirectory(prefix='susnix-clipboard-boot-') as directory:
            root=Path(directory);bin_dir=root/'bin';bin_dir.mkdir()
            session=root/'hypr'/'delayed-session';session.mkdir(parents=True)
            marker=root/'client-started'
            client=bin_dir/'VBoxClient'
            client.write_text('#!/usr/bin/python\nimport os,time\nfrom pathlib import Path\nPath(os.environ["CLIPBOARD_TEST_MARKER"]).write_text("started")\ntime.sleep(60)\n')
            client.chmod(0o755)
            env=os.environ.copy();env.update(HOME=str(root),PATH=str(bin_dir)+':'+env['PATH'],XDG_RUNTIME_DIR=str(root),WAYLAND_DISPLAY='wayland-test',HYPRLAND_INSTANCE_SIGNATURE='delayed-session',CLIPBOARD_TEST_MARKER=str(marker))
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
