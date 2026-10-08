#!/usr/bin/env python3
"""Exercise real filesystem operations, no-overwrite behavior and idle watching."""
import importlib.util
import json
import os
from pathlib import Path
import select
import subprocess
import tempfile
import unittest
import sys
sys.dont_write_bytecode=True
from unittest.mock import patch

HELPER=Path(__file__).resolve().parents[1]/'configs/quickshell/services/explorer-backend.py'
spec=importlib.util.spec_from_file_location('explorer',HELPER);backend=importlib.util.module_from_spec(spec);spec.loader.exec_module(backend)

class ExplorerBackend(unittest.TestCase):
    def test_copy_move_rename_and_no_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);source=root/'space $ filename.md';source.write_text('hello')
            target=root/'target';target.mkdir()
            result=backend.operate(dict(action='copy',source=str(source),target=str(target)))
            self.assertEqual(Path(result['destination']).read_text(),'hello')
            with self.assertRaises(FileExistsError):backend.operate(dict(action='copy',source=str(source),target=str(target)))
            with self.assertRaises(FileExistsError):backend.operate(dict(action='move',source=str(source),target=str(target)))
            self.assertTrue(source.exists())
            with self.assertRaises(ValueError):backend.operate(dict(action='rename',source=str(source),name='../escape'))
            result=backend.operate(dict(action='rename',source=str(source),name='renamed.md'))
            self.assertFalse(source.exists());renamed=Path(result['destination'])
            backend.operate(dict(action='move',source=str(renamed),target=str(target)))
            self.assertFalse(renamed.exists());self.assertEqual((target/'renamed.md').read_text(),'hello')

    def test_folder_copy_symlinks_and_self_recursion(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);source=root/'source';source.mkdir();(source/'file').write_text('x');(source/'link').symlink_to('file');target=root/'target';target.mkdir()
            backend.operate(dict(action='copy',source=str(source),target=str(target)))
            self.assertTrue((target/'source/link').is_symlink())
            with self.assertRaises(ValueError):backend.operate(dict(action='copy',source=str(source),target=str(source)))
            with self.assertRaises(ValueError):backend.operate(dict(action='move',source=str(source),target=str(source)))

    def test_trash_metadata_and_source_preview(self):
        with tempfile.TemporaryDirectory() as directory,patch.dict(os.environ,{'XDG_DATA_HOME':directory+'/data'}):
            source=Path(directory)/'example.py';source.write_text('def hello():\n    return "<safe>"\n')
            details=backend.details(source)
            self.assertEqual(''.join(t['text'] for t in details['tokens']),source.read_text())
            self.assertIn('secondary',[t['role'] for t in details['tokens']])
            backend.operate(dict(action='trash',source=str(source)))
            self.assertFalse(source.exists())
            trash=Path(directory)/'data/Trash';self.assertTrue((trash/'files/example.py').exists());self.assertIn('Path=',(trash/'info/example.py.trashinfo').read_text())

    def test_watcher_is_idle_then_reports_real_file_change(self):
        with tempfile.TemporaryDirectory() as directory:
            process=subprocess.Popen(['python',str(HELPER),'watch',directory],stdout=subprocess.PIPE,text=True)
            try:
                initial=json.loads(process.stdout.readline());self.assertEqual(initial['entries'],[])
                self.assertFalse(select.select([process.stdout],[],[],.3)[0],'watcher continuously refreshed while idle')
                (Path(directory)/'new.txt').write_text('abc')
                self.assertTrue(select.select([process.stdout],[],[],2)[0])
                updated=json.loads(process.stdout.readline());self.assertEqual(updated['entries'][0]['name'],'new.txt')
                self.assertFalse(select.select([process.stdout],[],[],.3)[0],'directory reads created a refresh loop')
            finally:process.terminate();process.wait(timeout=5);process.stdout.close()

if __name__=='__main__':unittest.main()
