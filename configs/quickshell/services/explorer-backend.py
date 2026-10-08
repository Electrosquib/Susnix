#!/usr/bin/env python3
"""Event-driven directory metadata and explicit user-requested file operations."""
import ctypes
import datetime
import errno
import json
import os
from pathlib import Path
import re
import select
import shutil
import stat
import subprocess
import sys
import time
from urllib.parse import quote

TEXT_EXT={'.txt','.md','.json','.qml','.lua','.sh','.py','.ini','.conf','.html','.css','.js','.ts','.rs','.c','.h','.xml','.log','.yaml','.yml'}
IMAGE_EXT={'.png','.jpg','.jpeg','.svg','.webp','.gif','.bmp'}
def emit(data):print(json.dumps(data,ensure_ascii=True),flush=True)
def normalize(value):
    path=Path(value).expanduser()
    if not path.is_absolute():raise ValueError('Choose an absolute path.')
    return path

def kind(path,is_dir):
    if is_dir:return 'Folder'
    return {'.md':'Markdown','.py':'Python','.qml':'QML','.sh':'Shell','.json':'JSON','.lua':'Lua'}.get(path.suffix.lower(),path.suffix[1:].upper()+' file' if path.suffix else 'File')
def entry(path):
    try:
        data=path.stat();is_dir=path.is_dir()
        return dict(name=path.name,path=str(path),url=path.as_uri(),isDir=is_dir,isLink=path.is_symlink(),size=0 if is_dir else data.st_size,modified=data.st_mtime,type=kind(path,is_dir),permissions=stat.filemode(data.st_mode))
    except OSError:return None

def snapshot(path):
    try:
        entries=[item for p in path.iterdir() if (item:=entry(p)) is not None]
        disk=shutil.disk_usage(path)
        mount='/'
        for line in Path('/proc/mounts').read_text().splitlines():
            candidate=line.split()[1].replace('\\040',' ')
            if (str(path)==candidate or str(path).startswith(candidate.rstrip('/')+'/')) and len(candidate)>len(mount):mount=candidate
        branch=''
        try:branch=subprocess.check_output(['git','-C',str(path),'branch','--show-current'],stderr=subprocess.DEVNULL,text=True,timeout=1).strip()
        except (OSError,subprocess.SubprocessError):pass
        return dict(path=str(path),entries=entries,totalBytes=sum(x['size'] for x in entries),free=disk.free,total=disk.total,mount=mount,branch=branch,error='')
    except OSError as error:return dict(path=str(path),entries=[],error=str(error))

def details(path):
    result=entry(path)
    if result is None:raise ValueError('The selected file is no longer accessible.')
    result['git']='Not tracked'
    try:
        git=subprocess.check_output(['git','-C',str(path.parent),'status','--porcelain','--',path.name],stderr=subprocess.DEVNULL,text=True,timeout=1).strip()
        if git:result['git']='Untracked' if git.startswith('??') else 'Modified'
        elif subprocess.run(['git','-C',str(path.parent),'ls-files','--error-unmatch','--',path.name],capture_output=True,timeout=1).returncode==0:result['git']='Clean'
    except (OSError,subprocess.SubprocessError):pass
    if result['isDir']:
        children=[x for p in path.iterdir() if (x:=entry(p)) is not None]
        result.update(items=len(children),immediateBytes=sum(x['size'] for x in children),folders=[x['name'] for x in children if x['isDir']][:8])
    elif path.suffix.lower() in IMAGE_EXT:result['image']=path.as_uri()
    elif path.suffix.lower() in TEXT_EXT and result['size']<1024*1024:
        with path.open(errors='replace') as stream:text=stream.read(10000)
        # Lightweight highlighting, rather than executing or importing selected code.
        pattern=re.compile(r'("[^"\n]*"|\'[^\'\n]*\'|#[^\n]*|//[^\n]*|\b(?:def|class|import|from|return|if|else|for|while|function|const|let|var|true|false|null|None|local|end)\b)')
        tokens=[];start=0
        for match in pattern.finditer(text):
            tokens.append(dict(text=text[start:match.start()],role='textMuted'))
            part=match.group();tokens.append(dict(text=part,role='system' if part.startswith(('#','//')) else 'success' if part.startswith(('"',"'")) else 'secondary'));start=match.end()
        tokens.append(dict(text=text[start:],role='textMuted'));result['tokens']=tokens
    return result

def move_no_replace(source,destination):
    if destination.exists() or destination.is_symlink():raise FileExistsError('Destination already exists; nothing was overwritten.')
    libc=ctypes.CDLL(None,use_errno=True)
    result=libc.renameat2(-100,os.fsencode(source),-100,os.fsencode(destination),1)
    if result==0:return
    code=ctypes.get_errno()
    if code!=errno.EXDEV:raise OSError(code,os.strerror(code))
    copy_no_replace(source,destination)
    if source.is_symlink() or source.is_file():source.unlink()
    else:shutil.rmtree(source)

def copy_no_replace(source,destination):
    if source.is_symlink():destination.symlink_to(os.readlink(source),target_is_directory=source.is_dir())
    elif source.is_dir():
        if destination.resolve().is_relative_to(source.resolve()):raise ValueError('Cannot copy a folder inside itself.')
        shutil.copytree(source,destination,symlinks=True)
    else:
        # Exclusive creation prevents overwriting even if another process races us.
        with source.open('rb') as src,destination.open('xb') as dst:shutil.copyfileobj(src,dst)
        shutil.copystat(source,destination)

def operate(data):
    action=data['action'];source=normalize(data['source'])
    if action=='details':return {'details':details(source)}
    if action=='rename':
        name=data['name'].strip()
        if name in ('','.','..') or '/' in name or '\x00' in name:raise ValueError('Enter a filename, without a directory path.')
        destination=source.parent/name;move_no_replace(source,destination)
    elif action in ('copy','move'):
        target=normalize(data['target'])
        if not target.is_dir():raise ValueError('Destination folder does not exist.')
        destination=target/source.name
        if action=='copy':copy_no_replace(source,destination)
        else:
            if source.is_dir() and destination.resolve().is_relative_to(source.resolve()):raise ValueError('Cannot move a folder inside itself.')
            move_no_replace(source,destination)
    elif action=='trash':
        # Home trash, with freedesktop .trashinfo; no permanent-delete UI action.
        trash=Path(os.environ.get('XDG_DATA_HOME',Path.home()/'.local/share'))/'Trash'
        (trash/'files').mkdir(parents=True,exist_ok=True);(trash/'info').mkdir(exist_ok=True)
        name=source.name
        while (trash/'files'/name).exists() or (trash/'info'/(name+'.trashinfo')).exists():name=source.name+'.'+str(time.time_ns())
        info=trash/'info'/(name+'.trashinfo')
        info.write_text('[Trash Info]\nPath='+quote(str(source),safe='/')+'\nDeletionDate='+datetime.datetime.now().isoformat(timespec='seconds')+'\n')
        try:move_no_replace(source,trash/'files'/name)
        except Exception:info.unlink();raise
        destination=trash/'files'/name
    elif action=='mkdir':
        name=data['name'].strip()
        if name in ('','.','..') or '/' in name or '\x00' in name:raise ValueError('Enter a folder name.')
        destination=source/name;destination.mkdir()
    else:raise ValueError('Unknown action.')
    return {'ok':True,'destination':str(destination)}

def watch(path):
    libc=ctypes.CDLL(None,use_errno=True);fd=libc.inotify_init1(os.O_NONBLOCK|os.O_CLOEXEC)
    if fd<0:raise OSError(ctypes.get_errno(),'Cannot watch directory')
    try:
        watch_id=libc.inotify_add_watch(fd,os.fsencode(path),0x00000FCE)
        emit(snapshot(path))
        if watch_id<0:return
        while True:
            select.select([fd],[],[])
            time.sleep(.08) # Coalesce atomic editor saves / burst file operations.
            try:os.read(fd,65536)
            except BlockingIOError:continue
            emit(snapshot(path))
    finally:os.close(fd)

def main():
    try:
        if sys.argv[1]=='watch':watch(normalize(sys.argv[2]))
        elif sys.argv[1]=='snapshot':emit(snapshot(normalize(sys.argv[2])))
        else:emit(operate(json.loads(sys.argv[1])))
    except (OSError,ValueError,KeyError) as error:emit({'error':str(error)})
if __name__=='__main__':main()
