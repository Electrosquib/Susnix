#!/usr/bin/env python3
"""Ensure every palette produces a valid native terminal theme without eval input."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO=Path(__file__).resolve().parents[1]
HELPER=REPO/'configs/quickshell/services/desktop-appearance.sh'
PALETTES=REPO/'configs/quickshell/theme/themes'
KEYS=['background','backgroundRaised','surface','surfaceRaised','primary','secondary','accent','text','textMuted','border','success','warning','danger','dev','browser','ai','media','system']

class DesktopAppearance(unittest.TestCase):
    def test_every_palette_generates_valid_foot_configuration(self):
        defaults=json.loads((PALETTES/'Nyx.json').read_text())['colors']
        with tempfile.TemporaryDirectory(prefix='susnix-appearance-') as directory:
            env=os.environ.copy();env.update(HOME=directory,XDG_CONFIG_HOME=directory)
            env.pop('HYPRLAND_INSTANCE_SIGNATURE',None)
            for palette in sorted(PALETTES.glob('*.json')):
                with self.subTest(palette=palette.stem):
                    colors=defaults|json.loads(palette.read_text())['colors']
                    subprocess.run(['bash',str(HELPER),*[colors[key] for key in KEYS]],env=env,check=True,capture_output=True)
                    config=Path(directory)/'susnix/foot.ini'
                    self.assertIn('background='+colors['background'][1:],config.read_text())
                    self.assertIn('regular4='+colors['primary'][1:],config.read_text())
                    self.assertIn('regular5='+colors['secondary'][1:],config.read_text())
                    subprocess.run(['foot','--check-config','--config',str(config)],env=env,check=True,capture_output=True)
            rejected=subprocess.run(['bash',str(HELPER),*(['#000000']*17),';touch /tmp/unsafe'],env=env,capture_output=True)
            self.assertEqual(rejected.returncode,2)

if __name__=='__main__':unittest.main()
