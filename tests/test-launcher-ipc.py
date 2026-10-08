#!/usr/bin/env python3
"""An IPC message is not success merely because Quickshell exits zero."""
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
class LauncherIPC(unittest.TestCase):
    def test_zero_exit_not_ready_is_retried_without_double_toggle(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);(root/'susnix').mkdir();(root/'bin').mkdir()
            (root/'susnix/bar-config').write_text(str(ROOT/'configs/quickshell')+'\n')
            qs=root/'bin/quickshell';qs.write_text('''#!/usr/bin/env python3
import os,sys
from pathlib import Path
base=Path(os.environ['XDG_RUNTIME_DIR']);counter=base/'counter'
if sys.argv[-1]=='currentTheme':
 n=int(counter.read_text()) if counter.exists() else 0;counter.write_text(str(n+1));print('Not ready to accept queries yet.' if n<2 else 'Nyx')
else:
 with (base/'calls').open('a') as file:file.write(sys.argv[-1]+'\\n')
''');qs.chmod(0o755)
            ctl=root/'bin/systemctl';ctl.write_text('#!/bin/sh\nif [ "$2" = show-environment ]; then exit 0; fi\necho unexpected-systemctl >&2\nexit 99\n');ctl.chmod(0o755)
            env=dict(os.environ,PATH=str(root/'bin')+':'+os.environ['PATH'],XDG_RUNTIME_DIR=str(root),WAYLAND_DISPLAY='wayland-test')
            with socket.socket(socket.AF_UNIX) as display:
                display.bind(str(root/'wayland-test'))
                result=subprocess.run(['bash',str(ROOT/'configs/quickshell/bar.sh'),'applications'],env=env,capture_output=True,text=True,timeout=5)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual((root/'counter').read_text(),'3');self.assertEqual((root/'calls').read_text(),'applications\n')
            self.assertNotIn('unexpected-systemctl',result.stderr)
if __name__=='__main__':unittest.main()
