"""Serial, isolated local UI checks/export. Never touches Steam Ready or personal saves."""
import argparse
import csv
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import io
import tarfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tmp/v131_ui'
RUN_ID = uuid.uuid4().hex[:8]

def engine():
    wrapper = Path(shutil.which('godot-gui.cmd'))
    return re.search(r'"([^"]+\.exe)"', wrapper.read_text()).group(1)

def idle():
    rows = csv.reader(subprocess.check_output(['tasklist.exe','/fo','csv','/nh'],text=True).splitlines())
    live = [r[0] for r in rows if r and (r[0].lower().startswith('godot') or r[0].lower().startswith('mawangui'))]
    if live: raise RuntimeError('Existing engine/game must finish first: '+','.join(live))

def environment(label):
    env = os.environ.copy()
    label += '-v130r_b01' if 'BattleButtonHotfix' in label or 'V131TutorialFlow' in label else ''
    label += '-'+RUN_ID
    for key in ('APPDATA','LOCALAPPDATA'):
        env[key] = str(OUT / 'profiles' / label / key)
        Path(env[key]).mkdir(parents=True,exist_ok=True)
    env['MAWANG_DISABLE_STEAM'] = '1'
    return env

def run(args, label, root=ROOT):
    idle()
    OUT.mkdir(parents=True,exist_ok=True)
    (ROOT/'tmp/.gdignore').write_text('',encoding='utf-8')
    log = OUT / (label+'.log')
    with log.open('w',encoding='utf-8') as stream:
        result = subprocess.Popen([engine(),'--path',str(root),*args],cwd=root,env=environment(label),stdout=stream,stderr=subprocess.STDOUT)
        deadline=time.monotonic()+1200
        while result.poll() is None:
            time.sleep(0.2)
            content=log.read_text(encoding='utf-8',errors='replace')
            if 'SCRIPT ERROR:' in content or time.monotonic()>deadline:
                result.terminate(); result.wait(); break
    lines = log.read_text(encoding='utf-8',errors='replace').splitlines()
    errors = [l for l in lines if 'SCRIPT ERROR:' in l or l.startswith('ERROR:')]
    print(json.dumps(dict(label=label,exit=result.returncode,errors=errors[:4],tail=lines[-3:]),ensure_ascii=False))
    idle()
    if result.returncode or errors: raise SystemExit(1)

def export(label):
    idle()
    root = OUT / ('project-'+label)
    root.mkdir(parents=True,exist_ok=True)
    for folder in ('scripts','scenes','addons','data'):
        shutil.copytree(ROOT/folder,root/folder,dirs_exist_ok=True)
    for filename in ('project.godot','export_presets.cfg'):
        shutil.copy2(ROOT/filename,root/filename)
    if label=='before':
        archive=subprocess.check_output(['git','archive','2d31e7aa','scripts','scenes','project.godot','export_presets.cfg'],cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            for member in tar:
                if member.isfile():
                    target=root/member.name
                    target.parent.mkdir(parents=True,exist_ok=True)
                    target.write_bytes(tar.extractfile(member).read())
    # Assets and import cache are reused read-only by the export; metadata restored below.
    for folder in ('assets','.godot/imported'):
        dest=root/folder
        dest.parent.mkdir(parents=True,exist_ok=True)
        if not dest.exists():
            subprocess.run(['cmd.exe','/c','mklink','/J',str(dest),str(ROOT/folder)],check=True,stdout=subprocess.DEVNULL)
    for filename in ('global_script_class_cache.cfg','uid_cache.bin'):
        shutil.copy2(ROOT/'.godot'/filename,root/'.godot'/filename)
    harness = ROOT/'tools/tests/V131ExeProbe.gd'
    shutil.copy2(harness,root/'scripts/V131ExeProbe.gd')
    project = root/'project.godot'
    project.write_text(project.read_text(encoding='utf-8-sig').replace('[debug]','V131ExeProbe="*res://scripts/V131ExeProbe.gd"\n\n[debug]',1),encoding='utf-8')
    env=environment('export-'+label)
    source=Path(os.environ['APPDATA'])/'Godot/export_templates/4.6.3.stable'
    dest=Path(env['APPDATA'])/'Godot/export_templates/4.6.3.stable'
    dest.mkdir(parents=True,exist_ok=True)
    for filename in ('windows_release_x86_64.exe',): shutil.copy2(source/filename,dest/filename)
    target=OUT/('exe-'+label)/'MawangUI.exe'
    target.parent.mkdir(parents=True,exist_ok=True)
    metadata={p:p.read_bytes() for p in (ROOT/'assets').rglob('*.import')}
    try: run(['--headless','--export-release','Windows Desktop',str(target)],'export-'+label,root)
    finally:
        for p,b in metadata.items():
            if p.read_bytes()!=b:p.write_bytes(b)

def main():
    p=argparse.ArgumentParser()
    p.add_argument('stage',choices=['import','test','render','export','launch','check-exe'])
    p.add_argument('name',nargs='?',default='after')
    p.add_argument('--resolution',default='920x518')
    p.add_argument('--map',action='store_true')
    a=p.parse_args()
    if a.stage=='import': run(['--headless','--editor','--import'],'import')
    elif a.stage=='export':export(a.name)
    elif a.stage in ('test','render'):run((['--headless'] if a.stage=='test' else [])+['--audio-driver','Dummy','--resolution','1920x1080','res://tools/tests/'+a.name+'.tscn','--','case=replay','--start-mode=after','out=res://tmp/v131_ui/replay'],a.stage+'-'+a.name)
    else:
        idle()
        log=(OUT/('exe-'+a.name+'.log')).open('w',encoding='utf-8')
        env=environment('exe-'+a.name)
        proc=subprocess.Popen([str(OUT/('exe-'+a.name)/'MawangUI.exe'),'--resolution',a.resolution,'--position','60,60','--audio-driver','Dummy','--','--qa-resolution='+a.resolution,*(['--qa-map'] if a.map else [])],cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
        (OUT/'exe-pid.txt').write_text(str(proc.pid))
        (OUT/'last-launch.json').write_text(json.dumps(dict(pid=proc.pid,appdata=env['APPDATA'],label=a.name)),encoding='utf-8')
        print('Isolated EXE PID '+str(proc.pid),flush=True)
        if a.stage=='check-exe':
            deadline=time.monotonic()+30
            samples=[]
            while time.monotonic()<deadline and not samples and proc.poll() is None:
                samples=list(Path(env['APPDATA']).rglob('sample-0-*.json'))
                time.sleep(0.2)
            if not samples: raise RuntimeError('Native EXE did not finish its fixture')
            proof=json.loads(samples[0].read_text(encoding='utf-8'))
            expected='('+a.resolution.replace('x',', ')+')'
            if proof['window_size']!=expected or proof['render_size']!=expected:raise RuntimeError('Native size mismatch: '+str(proof))
            (OUT/('native-'+a.resolution+'.json')).write_text(json.dumps(proof,ensure_ascii=False),encoding='utf-8')
            print('Native EXE '+a.resolution+' render verified; waiting for Computer Use F10.',flush=True)
            code=proc.wait(timeout=90)
            (OUT/('native-'+a.resolution+'-exit.txt')).write_text(str(code))
            print('Native EXE exit='+str(code),flush=True)
            if code:raise SystemExit(1)

if __name__=='__main__':main()
