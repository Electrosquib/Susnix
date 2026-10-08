#!/usr/bin/env python3
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('launcher',ROOT/'configs/quickshell/services/launcher-backend.py')
backend=importlib.util.module_from_spec(spec);spec.loader.exec_module(backend)
class LauncherBackend(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup);self.directory=Path(self.temp.name)
        self.env=patch.dict(os.environ,{'SUSNIX_LAUNCHER_ROOTS':str(self.directory/'Projects'),'XDG_DATA_HOME':str(self.directory/'data')});self.env.start();self.addCleanup(self.env.stop)
        self.state=patch.object(backend,'STATE',self.directory/'state/launcher.json');self.state.start();self.addCleanup(self.state.stop)
        self.cache=patch.object(backend,'CACHE',self.directory/'cache/index.sqlite');self.cache.start();self.addCleanup(self.cache.stop)
        (self.directory/'Projects/radar').mkdir(parents=True)
    def test_persistence_folders_favorites_and_recents(self):
        file=self.directory/'Projects/radar/a.py';file.write_text('print(1)')
        data={'initialized':True,'favorites':['code','terminal','code'],'folders':[{'id':'folder:1','name':'Dev','apps':['code','terminal']}],'recent':[{'kind':'file','id':str(file),'name':'a.py','path':str(file)}]}
        saved=backend.save(data);self.assertEqual(saved['favorites'],['code','terminal']);self.assertEqual(backend.load(),saved)
        self.assertEqual(backend.STATE.stat().st_mode&0o777,0o600)
        with self.assertRaises(ValueError):backend.save({'favorites':'code'})
        self.assertEqual(backend.load(),saved)
        file.unlink();self.assertEqual(backend.load()['recent'],[])
    def test_file_search_literal_unicode_and_exclusions(self):
        root=self.directory/'Projects/radar';(root/'SFCW.py').write_text('print(1)');(root/'100%_Ω.md').write_text('notes')
        (root/'.git').mkdir();(root/'.git/secret-radar').write_text('x')
        result=backend.search('SFCW');self.assertEqual([x['name'] for x in result['files']],['SFCW.py'])
        self.assertEqual(backend.search('%_Ω')['files'][0]['name'],'100%_Ω.md')
        self.assertFalse(any('.git' in x['path'] for x in backend.search('radar')['files']))
        (root/'SFCW.py').unlink();self.assertEqual(backend.search('SFCW')['files'],[])
    def test_index_refreshes_when_search_roots_change(self):
        (self.directory/'Projects/radar/old.py').write_text('x')
        self.assertEqual(len(backend.search('old.py')['files']),1)
        other=self.directory/'Other';other.mkdir();(other/'new.py').write_text('x')
        with patch.dict(os.environ,{'SUSNIX_LAUNCHER_ROOTS':str(other)}):
            self.assertEqual(backend.search('old.py')['files'],[])
            self.assertEqual(backend.search('new.py')['files'][0]['path'],str(other/'new.py'))
    def test_index_enforces_limit_inside_a_large_directory(self):
        root=self.directory/'Projects/radar'
        for number in range(20):(root/str(number)).write_text('x')
        with patch.object(backend,'INDEX_MAX',5):
            result=backend.search('')
            self.assertTrue(result['limited']);self.assertEqual(len(result['files']),5)
    def test_recent_xbel_accepts_local_existing_files(self):
        file=self.directory/'Projects/radar/a notes.md';file.write_text('hello')
        base=self.directory/'data';base.mkdir();(base/'recently-used.xbel').write_text('<xbel><bookmark href="'+file.as_uri()+'" modified="2026-10-08"/><bookmark href="https://example.com"/></xbel>')
        self.assertEqual(backend.recent_files()[0]['path'],str(file));self.assertEqual(len(backend.load()['recent']),1)
    def test_ai_context_is_bounded_and_explicit(self):
        file=self.directory/'Projects/radar/a.py';file.write_text('print(1)\n'*1000)
        prompt=backend.main({'action':'ai-context','path':str(file)})['prompt']
        self.assertIn('print(1)',prompt);self.assertLess(len(prompt),4300)
        with self.assertRaises(ValueError):backend.main({'action':'ai-context','path':str(file.parent)})
    def test_workspace_launch_quotes_shell_and_lua(self):
        completed=subprocess.CompletedProcess([],0,'ok','')
        with patch.object(subprocess,'run',return_value=completed) as run:
            backend.execute({'action':'workspace','workspace':2,'command':['program','a file','$(touch /tmp/nope)','quote"']})
            args=run.call_args.args[0];self.assertEqual(args[:2],['hyprctl','eval']);self.assertIn('workspace="2"',args[2]);self.assertIn("'$(touch /tmp/nope)'",args[2])
        with self.assertRaises(ValueError):backend.execute({'action':'workspace','workspace':0,'command':['foo']})
    def test_run_file_selects_interpreter_and_refuses_plain_document(self):
        root=self.directory/'Projects/radar';script=root/'radar.py';script.write_text('print(1)');doc=root/'notes.md';doc.write_text('x')
        with patch.object(subprocess,'Popen') as start:
            backend.execute({'action':'run-file','path':str(script)})
            self.assertEqual(start.call_args.args[0][-2:],['python',str(script)])
        with self.assertRaises(ValueError):backend.execute({'action':'run-file','path':str(doc)})
    def test_system_commands_use_explicit_provider_arguments(self):
        completed=subprocess.CompletedProcess([],0,'ok','')
        with patch.object(subprocess,'run',return_value=completed) as run:
            backend.execute({'action':'restart-audio'})
            self.assertEqual(run.call_args.args[0],['systemctl','--user','restart','pipewire.service','pipewire-pulse.service','wireplumber.service'])
        with patch.object(subprocess,'Popen') as start:
            backend.execute({'action':'update'})
            command=start.call_args.args[0]
            self.assertEqual(command[-2:],['pacman','-Syu']);self.assertIn('sudo',command)
            backend.execute({'action':'root','command':['bash','-l']})
            self.assertEqual(start.call_args.args[0][-2:],['bash','-l'])
        with self.assertRaises(ValueError):backend.execute({'action':'not-a-command'})
if __name__=='__main__':unittest.main()
