#!/usr/bin/env python3
"""Launcher persistence, bounded file index, metadata and explicit argv actions."""
import json
import os
from pathlib import Path
import shlex
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from urllib.parse import unquote, urlparse

HOME=Path.home()
STATE=Path(os.environ.get('XDG_STATE_HOME',HOME/'.local/state'))/'susnix/launcher.json'
CACHE=Path(os.environ.get('XDG_CACHE_HOME',HOME/'.cache'))/'susnix/launcher-files.sqlite'
INDEX_MAX=50000
INDEX_SECONDS=2
IGNORED={'.git','node_modules','__pycache__','build','target','.venv','venv','vendor'}
def normalized(data):
    if not isinstance(data,dict):raise ValueError('Invalid launcher state')
    favorites=data.get('favorites',[]);folders=data.get('folders',[]);recent=data.get('recent',[])
    if not isinstance(favorites,list) or not isinstance(folders,list) or not isinstance(recent,list) or not all(isinstance(x,str) and 0<len(x)<512 for x in favorites):raise ValueError('Invalid favorites')
    clean=[];assigned=set()
    for folder in folders[:64]:
        if not isinstance(folder,dict) or not isinstance(folder.get('id'),str) or not isinstance(folder.get('name'),str):raise ValueError('Invalid app folder')
        apps=folder.get('apps',[])
        if not isinstance(apps,list) or not all(isinstance(x,str) for x in apps):raise ValueError('Invalid folder members')
        members=[x for x in dict.fromkeys(apps) if x not in assigned];assigned.update(members)
        if members:clean.append(dict(id=folder['id'][:128],name=folder['name'][:80],apps=members))
    recents=[]
    for item in recent[:40]:
        if isinstance(item,dict) and item.get('kind') in ('app','file') and isinstance(item.get('id'),str) and isinstance(item.get('name'),str):
            recents.append({k:item[k] for k in ('kind','id','name','path','isDir','time') if k in item})
    return dict(initialized=bool(data.get('initialized')),favorites=list(dict.fromkeys(favorites))[:64],folders=clean,recent=recents)
def save(data):
    data=normalized(data);STATE.parent.mkdir(parents=True,exist_ok=True)
    fd,temp=tempfile.mkstemp(prefix='.launcher-',dir=STATE.parent)
    try:
        with os.fdopen(fd,'w') as stream:json.dump(data,stream,indent=2);stream.write('\n')
        os.replace(temp,STATE)
    finally:
        if os.path.exists(temp):os.unlink(temp)
    return data
def recent_files():
    path=Path(os.environ.get('XDG_DATA_HOME',HOME/'.local/share'))/'recently-used.xbel'
    result=[]
    try:
        if path.stat().st_size>4*1024*1024:return []
        tree=ET.parse(path)
        for bookmark in sorted(tree.getroot().findall('bookmark'),key=lambda b:b.get('modified',''),reverse=True):
            uri=urlparse(bookmark.get('href',''))
            if uri.scheme!='file' or uri.netloc not in ('','localhost'):continue
            file=Path(unquote(uri.path))
            if file.exists():result.append(dict(kind='file',id=str(file),path=str(file),name=file.name,isDir=file.is_dir()))
            if len(result)>=16:break
    except (OSError,ET.ParseError):pass
    return result
def load():
    try:data=normalized(json.loads(STATE.read_text()))
    except (OSError,ValueError,TypeError):data=normalized({})
    data['recent']=[x for x in data['recent'] if x['kind']=='app' or (isinstance(x.get('path'),str) and Path(x['path']).exists())]
    known={x['id'] for x in data['recent']};data['recent'] += [x for x in recent_files() if x['id'] not in known]
    return data

def roots():
    configured=os.environ.get('SUSNIX_LAUNCHER_ROOTS')
    if configured:return [Path(p).expanduser() for p in configured.split(os.pathsep) if p]
    # Respect localized XDG user directories without sourcing a shell file.
    places=[HOME/'Projects',HOME/'Radar',HOME/'susnix']
    conf=Path(os.environ.get('XDG_CONFIG_HOME',HOME/'.config'))/'user-dirs.dirs'
    try:
        for line in conf.read_text().splitlines():
            if line.startswith('XDG_') and '=' in line:
                value=shlex.split(line.split('=',1)[1])
                if value:places.append(Path(value[0].replace('$HOME',str(HOME))))
    except (OSError,ValueError):pass
    places += [HOME/name for name in ('Desktop','Documents','Downloads','Pictures','Music','Videos')]
    return list(dict.fromkeys(p for p in places if p.is_dir() and p!=HOME))
def index():
    CACHE.parent.mkdir(parents=True,exist_ok=True)
    db=sqlite3.connect(CACHE,timeout=3)
    db.execute('CREATE TABLE IF NOT EXISTS files(path TEXT PRIMARY KEY,name TEXT,is_dir INTEGER,modified REAL)')
    db.execute('CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY,value TEXT)')
    last=db.execute("SELECT value FROM meta WHERE key='updated'").fetchone()
    if last and time.time()-float(last[0])<60:return db
    rows=[];seen=set();start=time.monotonic();limited=False
    for base in roots():
        try:
            info=base.stat();rows.append((str(base),base.name,1,info.st_mtime));seen.add(str(base))
        except OSError:continue
        for directory,dirs,files in os.walk(base,followlinks=False):
            dirs[:]=sorted(d for d in dirs if d not in IGNORED and not d.startswith('.'))
            for name in dirs+sorted(files):
                if len(rows)>=INDEX_MAX or time.monotonic()-start>INDEX_SECONDS:limited=True;break
                if name.startswith('.'):continue
                path=Path(directory)/name
                if str(path) in seen:continue
                try:info=path.stat()
                except OSError:continue
                seen.add(str(path));rows.append((str(path),name,int(path.is_dir()),info.st_mtime))
            if limited:break
        if limited:break
    with db:
        db.execute('DELETE FROM files');db.executemany('INSERT OR REPLACE INTO files VALUES(?,?,?,?)',rows)
        db.execute("INSERT OR REPLACE INTO meta VALUES('updated',?)",(str(time.time()),))
        db.execute("INSERT OR REPLACE INTO meta VALUES('limited',?)",(str(int(limited)),))
    return db
def search(query):
    query=query.strip()[:160];db=index()
    try:
        if not query:sql='SELECT * FROM files ORDER BY modified DESC LIMIT 48';args=()
        else:
            escaped=query.replace('\\','\\\\').replace('%','\\%').replace('_','\\_')
            sql="SELECT * FROM files WHERE name LIKE ? ESCAPE '\\' OR path LIKE ? ESCAPE '\\' ORDER BY CASE WHEN lower(name)=lower(?) THEN 0 WHEN name LIKE ? ESCAPE '\\' THEN 1 ELSE 2 END,modified DESC LIMIT 60"
            args=('%'+escaped+'%','%'+escaped+'%',query,escaped+'%')
        rows=[dict(kind='file',id=p,path=p,name=n,isDir=bool(d)) for p,n,d,m in db.execute(sql,args) if Path(p).exists()]
        limited=db.execute("SELECT value FROM meta WHERE key='limited'").fetchone()
        return dict(query=query,files=rows,limited=bool(limited and limited[0]=='1'),roots=[str(x) for x in roots()])
    finally:db.close()
def app_info(data):
    cmd=data.get('command',[])
    executable=shutil.which(cmd[0]) if cmd else None
    package='';version='';desktop=''
    if executable:
        try:
            package=subprocess.check_output(['pacman','-Qoq',executable],stderr=subprocess.DEVNULL,text=True,timeout=2).splitlines()[0]
            version=subprocess.check_output(['pacman','-Q',package],stderr=subprocess.DEVNULL,text=True,timeout=2).strip().split(' ',1)[1]
        except (OSError,subprocess.SubprocessError,IndexError):pass
    ident=data.get('id','')
    if '/' not in ident:
        for base in [Path(os.environ.get('XDG_DATA_HOME',HOME/'.local/share'))]+[Path(x) for x in os.environ.get('XDG_DATA_DIRS','/usr/local/share:/usr/share').split(':')]:
            path=base/'applications'/(ident if ident.endswith('.desktop') else ident+'.desktop')
            if path.is_file():desktop=str(path);break
    return dict(id=ident,executable=executable or (cmd[0] if cmd else ''),package=package,version=version or 'Not provided',desktop=desktop)
def backdrop(monitor):
    directory=Path(os.environ['XDG_RUNTIME_DIR'])/'susnix';directory.mkdir(exist_ok=True,mode=0o700)
    target=directory/('launcher-backdrop-'+str(time.time_ns())+'.png')
    raw=target.with_suffix('.raw.png')
    try:
        subprocess.run(['grim','-o',monitor,'-s','0.25',str(raw)],check=True,timeout=2,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        subprocess.run([str(HOME/'.local/bin/susnix-backdrop'),str(raw),str(target)],check=True,timeout=2)
        # Retain only the latest two captures; the displayed image may still be loaded.
        for old in sorted(directory.glob('launcher-backdrop-*.png'))[:-2]:old.unlink(missing_ok=True)
        return dict(image=target.as_uri())
    finally:raw.unlink(missing_ok=True)
def execute(data):
    action=data['action']
    if action=='restart-audio':cmd=['systemctl','--user','restart','pipewire.service','pipewire-pulse.service','wireplumber.service']
    elif action=='bluetooth-off':cmd=['bluetoothctl','power','off']
    elif action=='copy-path':
        cmd=['wl-copy','--',data['path']]
    elif action=='workspace':
        args=data['command'];workspace=int(data.get('workspace',2))
        if not 1<=workspace<=10 or not args or not all(isinstance(x,str) for x in args):raise ValueError('Invalid launch')
        # Shell quoting and Lua string escaping are separate; JSON strings are Lua-compatible here.
        shell=shlex.join(args)
        lua='hl.dispatch(hl.dsp.exec_cmd('+json.dumps(shell,ensure_ascii=False)+',{workspace='+json.dumps(str(workspace))+'}))'
        cmd=['hyprctl','eval',lua]
    elif action=='run-file':
        path=Path(data['path']);suffix=path.suffix.lower()
        if not path.is_file():raise ValueError('Select a file to run')
        program=['python',str(path)] if suffix=='.py' else ['bash',str(path)] if suffix=='.sh' else [str(path)] if os.access(path,os.X_OK) else None
        if not program:raise ValueError('Run supports Python, shell scripts, and executable files.')
        # Keep short-lived output visible; positional argv avoids shell interpolation.
        review=['bash','-c','"$@"; susnix_status=$?; printf "\\nExited (%s). Press Enter to close.\\n" "$susnix_status"; IFS= read -r susnix_reply; exit "$susnix_status"','susnix-run']+program
        subprocess.Popen([str(HOME/'.local/bin/susnix-terminal'),'--working-directory',str(path.parent),'--']+review,start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);return dict(ok=True)
    elif action in ('root','update'):
        args=data.get('command',[]) if action=='root' else ['pacman','-Syu']
        if not args or not all(isinstance(x,str) for x in args):raise ValueError('Invalid application command')
        program=['sudo','env','WAYLAND_DISPLAY='+os.environ.get('WAYLAND_DISPLAY',''),'XDG_RUNTIME_DIR='+os.environ.get('XDG_RUNTIME_DIR','')]+args
        subprocess.Popen([str(HOME/'.local/bin/susnix-terminal'),'--']+program,start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);return dict(ok=True)
    else:raise ValueError('Unknown launcher action')
    reply=subprocess.run(cmd,capture_output=True,text=True,timeout=12)
    if reply.returncode:raise ValueError(reply.stderr.strip() or reply.stdout.strip() or 'Action failed')
    return dict(ok=True)
def main(data):
    action=data['action']
    if action=='load':return dict(state=load())
    if action=='save':return dict(state=save(data['state']))
    if action=='search':return search(data.get('query',''))
    if action=='info':return app_info(data)
    if action=='ai-context':
        path=Path(data['path'])
        if not path.is_file():raise ValueError('Choose a file for AI context')
        with path.open('rb') as stream:raw=stream.read(4096)
        try:
            text=raw.decode('utf-8')
            if '\x00' in text:raise UnicodeError()
            content='\n\nFile excerpt (up to 4096 bytes):\n'+text
        except UnicodeError:content='\nBinary file; '+str(path.stat().st_size)+' bytes.'
        return dict(prompt='Help me understand this file: '+str(path)+content)
    if action=='backdrop':return backdrop(data['monitor'])
    return execute(data)
if __name__=='__main__':
    try:print(json.dumps(main(json.loads(sys.argv[1]))))
    except (OSError,ValueError,KeyError,TypeError,subprocess.SubprocessError) as error:print(json.dumps(dict(error=str(error))))
