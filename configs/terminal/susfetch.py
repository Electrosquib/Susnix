#!/usr/bin/env python3
"""Small, honest system summary. No daemon, polling, or fabricated specs."""
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys

assets=Path(os.environ.get('SUSNIX_TERMINAL_ASSETS',Path(__file__).parent))
config=Path(os.environ.get('XDG_CONFIG_HOME',Path.home()/'.config'))/'susnix/colors.json'
def read(path):
    try:return json.loads(path.read_text())
    except (OSError,ValueError):return {}
settings=read(config)
colors=read(assets/'themes/Nyx.json').get('colors',{})
theme=settings.get('theme','Nyx')
if theme in ('Nyx','Aurora','Void','Sakura','Terminal','Ember'):
    colors.update(read(assets/f'themes/{theme}.json').get('colors',{}))
colors.update(settings.get('colors',{}))
def tint(role):
    # Palette-driven ANSI slots let a running terminal recolor previous output.
    return {'primary':'\033[34m','secondary':'\033[35m','text':'\033[39m'}.get(role,'\033[39m')
reset='\033[0m'
def command(args):
    try:return subprocess.check_output(args,text=True,stderr=subprocess.DEVNULL,timeout=1).strip()
    except (OSError,subprocess.SubprocessError):return ''
def info():
    os_release=platform.freedesktop_os_release()
    uptime=float(Path('/proc/uptime').read_text().split()[0]);hours=int(uptime//3600);mins=int(uptime%3600//60)
    memory={line.split(':')[0]:int(line.split()[1]) for line in Path('/proc/meminfo').read_text().splitlines()}
    cpu=next((line.split(':',1)[1].strip() for line in Path('/proc/cpuinfo').read_text().splitlines() if line.startswith('model name')),platform.machine())
    return [('OS',os_release.get('PRETTY_NAME','Linux')),('Host',platform.node()),('Kernel',platform.release()),('Uptime',f'{hours}h {mins}m'),('Shell',Path(os.environ.get('SHELL','/bin/bash')).name),('Desktop',os.environ.get('XDG_CURRENT_DESKTOP','Hyprland' if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE') else '—')),('Terminal','Susnix Term / QTermWidget'),('CPU',cpu),('Memory',f"{(memory['MemTotal']-memory['MemAvailable'])/1048576:.1f} / {memory['MemTotal']/1048576:.1f} GiB"),('Theme',theme)]
logo=[
'        ▄▄▄▄▄▄▄▄▄▄',
'      ▄████▀▀▀▀▀▀▀',
'    ▄███▀    ▄▄▄▄▄',
'   ████    ▄██▀▀▀▀',
'    ▀████▄▄  ▀██▄',
'      ▀▀████▄  ███',
'   ▄▄▄▄▄▄▄██▀ ▄██▀',
'   ▀▀▀▀▀▀▀▀▀▀▀▀▀',
'',
'  S U S N I X',
'  BUILD DIFFERENT',
]
if '--json' in sys.argv:
    print(json.dumps(dict(info())));sys.exit(0)
width=shutil.get_terminal_size((80,24)).columns
rows=info();print()
for i in range(max(len(logo),len(rows))):
    mark=logo[i] if i<len(logo) else ''
    details=(tint('primary')+f'{rows[i][0]+":":<11}'+tint('text')+rows[i][1]) if i<len(rows) else ''
    if width>=84:print(' '+tint('primary' if i<4 else 'secondary')+f'{mark:<24}'+reset+' '+details+reset)
    elif i<len(rows):print(' '+details+reset)
print()
