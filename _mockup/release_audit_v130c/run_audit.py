"""Targeted audit only: immutable product, fresh evidence, isolated profiles."""
import argparse
import concurrent.futures
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import psutil

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
STATE = ROOT / 'tmp/release_audit_v130c_v130r_release_blockers'

def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')

def engines():
    return [p.info for p in psutil.process_iter(['pid', 'name']) if 'godot' in (p.info['name'] or '').lower() or (p.info['name'] or '').lower().startswith(('mawangcastle', 'mawangdialogue'))]

def engine():
    wrapper = Path(subprocess.check_output(['where.exe','godot.cmd'],text=True).splitlines()[0])
    return re.search(r'"([^"\r\n]+\.exe)"',wrapper.read_text())[1].replace('_console.exe','.exe')

def profile(name):
    folder = STATE / 'profiles' / name
    env = os.environ.copy()
    for key, sub in [('APPDATA','appdata'),('LOCALAPPDATA','localappdata')]:
        (folder/sub).mkdir(parents=True,exist_ok=True)
        env[key] = str(folder/sub)
    env.update(MAWANG_DISABLE_STEAM='1',PYTHONIOENCODING='utf-8')
    return folder,env

def run(name,args,gui=False,timeout=300,profile_name=None,exe=None,project=None):
    assert not engines(), engines()
    folder,env=profile(profile_name or name)
    command=[str(exe or engine())]
    if not exe: command+=['--path',str(project or ROOT),'--rendering-method','gl_compatibility']
    command+=['--windowed','--resolution','900x506','--max-fps','120']
    if not gui: command+=['--headless']
    command+=args
    logs=OUT/'logs'; logs.mkdir(exist_ok=True)
    start=time.monotonic(); timed_out=False
    with (logs/(name+'.stdout.log')).open('wb') as stdout,(logs/(name+'.stderr.log')).open('wb') as stderr:
        proc=subprocess.Popen(command,env=env,cwd=Path(exe).parent if exe else ROOT,stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
        write(OUT/'active.json',dict(id=name,pid=proc.pid,profile=str(folder),command=command))
        try: proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired: timed_out=True; proc.kill(); proc.wait()
    text=(logs/(name+'.stdout.log')).read_text(encoding='utf-8',errors='replace')+(logs/(name+'.stderr.log')).read_text(encoding='utf-8',errors='replace')
    result=dict(id=name,exit_code=proc.returncode,seconds=round(time.monotonic()-start,2),timeout=timed_out,error_lines=len(re.findall(r'(?m)^(?:SCRIPT )?ERROR:',text)),warning_lines=len(re.findall(r'(?m)^WARNING:',text)),command=command,profile=str(folder),engines_after=engines())
    write(OUT/'runs'/(name+'.json'),result)
    print(json.dumps({k:result[k] for k in ['id','exit_code','seconds','timeout','error_lines','warning_lines']}),flush=True)
    return result

def clone(name):
    text=(ROOT/'tools/tests'/(name+'.gd')).read_text(encoding='utf-8')
    # Keep dependencies and all product calls unchanged; only evidence paths move.
    text=text.replace('res://tmp/v130r_release_blockers/','res://_mockup/release_audit_v130c/')
    if name=='DialogueOverflowTest': text=text.replace('res://tmp/dialogue_overflow/','res://_mockup/release_audit_v130c/dialogue/')
    path=OUT/'harness'/(name+'.gd'); path.parent.mkdir(exist_ok=True)
    path.write_text(text,encoding='utf-8')
    scene=path.with_suffix('.tscn')
    # Context preserves the original tools/tests safety guards.
    wrapper=path.with_name(name+'Context.gd')
    wrapper.write_text('extends "res://'+path.relative_to(ROOT).as_posix()+'"\nfunc _enter_tree() -> void:\n\tscene_file_path="res://tools/tests/'+name+'.tscn"\n',encoding='utf-8')
    scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://'+wrapper.relative_to(ROOT).as_posix()+'" id="1"]\n[node name="TargetedAudit" type="Node"]\nscript=ExtResource("1")\n',encoding='utf-8')
    return 'res://'+scene.relative_to(ROOT).as_posix()

def prepare():
    assert not engines(), engines()
    paths=subprocess.check_output(['git','ls-files','-z','--cached','--others','--exclude-standard'],cwd=ROOT).decode('utf-8').split('\0')
    manifest={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths if p and (ROOT/p).is_file() and not p.startswith(('_mockup/release_audit_v130c/','tmp/','output/','builds/'))}
    write(OUT/'baseline_manifest.json',manifest)
    write(OUT/'baseline_git.json',dict(head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),branch=subprocess.check_output(['git','branch','--show-current'],text=True).strip(),origin_main_cached=subprocess.check_output(['git','rev-parse','origin/main'],text=True).strip(),main='ABSENT',remote_freshness='NOT_QUERIED',status=subprocess.check_output(['git','status','--porcelain'],text=True).splitlines(),engines=engines()))
    for name in ['V130RReleaseCampaign','V130RReleaseLegacyTest','V130RReleaseLayoutTest','DialogueOverflowTest']: clone(name)
    subprocess.run([sys.executable,str(OUT/'prepare_ocr.py')],check=True)
    (OUT/'dialogue').mkdir(exist_ok=True)
    spec=importlib.util.spec_from_file_location('overflow',ROOT/'tools/run_dialogue_overflow.py'); module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    module.OUT=OUT/'dialogue'; module.prepare()
    print('baseline_files='+str(len(manifest)),flush=True)

def campaigns():
    for seed in [130401,130402,130403]:
        scene='res://_mockup/release_audit_v130c/harness/V130RReleaseCampaign.tscn'
        run('campaign_'+str(seed),['--scene',scene,'--','seed='+str(seed)],timeout=3000,profile_name='campaign_'+str(seed))
        if (OUT/('campaign_'+str(seed)+'_postgame_before.json')).exists():
            run('restart_'+str(seed),['--scene',scene,'--','seed='+str(seed),'resume=true'],profile_name='campaign_'+str(seed))
    write(OUT/'campaigns_complete.json',dict(complete=True,engines=engines()))

def static_one(name,command):
    started=time.monotonic(); p=subprocess.run(command,cwd=ROOT,capture_output=True,timeout=300)
    logs=OUT/'logs'; logs.mkdir(exist_ok=True)
    (logs/(name+'.stdout.log')).write_bytes(p.stdout); (logs/(name+'.stderr.log')).write_bytes(p.stderr)
    result=dict(id=name,exit_code=p.returncode,seconds=round(time.monotonic()-started,2),command=command)
    if '--json' in command:
        data=json.loads(p.stdout.decode('utf-8-sig')); write(OUT/(name+'.json'),data)
        result.update({k:data[k] for k in ['result','checks','errors'] if k in data})
    write(OUT/'runs'/(name+'.json'),result); print(json.dumps(result,ensure_ascii=True),flush=True)

def static():
    jobs=[('data_monsters',[sys.executable,'-X','utf8','tools/content/validate_v130r_monsters.py','--json']),('data_story',[sys.executable,'-X','utf8','tools/content/validate_v130r_story.py','--json']),('validator_tests',[sys.executable,'-X','utf8','-m','unittest','discover','-s','tools/content','-p','test_validate_v130r_story.py'])]
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(lambda job:static_one(*job),jobs))

def suite():
    run('legacy',['--scene','res://_mockup/release_audit_v130c/harness/V130RReleaseLegacyTest.tscn'])
    run('layout',['--scene','res://_mockup/release_audit_v130c/harness/V130RReleaseLayoutTest.tscn'],gui=True)
    for phase in ['after','behavior']:
        run('dialogue_'+phase,['--scene','res://_mockup/release_audit_v130c/harness/DialogueOverflowTest.tscn','--','--dialogue-phase='+phase],timeout=1200)

def export():
    assert not engines(), engines()
    folder,env=profile('export')
    source=Path(os.environ['APPDATA'])/'Godot/export_templates'
    for template in source.glob('*/windows_release_x86_64.exe'):
        dest=Path(env['APPDATA'])/'Godot/export_templates'/template.parent.name/template.name
        dest.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(template,dest)
    originals={p:p.read_bytes() for p in ROOT.rglob('*.import') if p.is_file() and not any(x in p.relative_to(ROOT).parts for x in ['tmp','output','builds','.git','.godot'])}
    dest=STATE/'export/MawangCastle.exe'; dest.parent.mkdir(parents=True,exist_ok=True)
    try: run('windows_export',['--export-release','Windows Desktop',str(dest)],timeout=1200,profile_name='export')
    finally:
        restored=[]
        for path,data in originals.items():
            if path.read_bytes()!=data:
                path.write_bytes(data); restored.append(path.relative_to(ROOT).as_posix())
        write(OUT/'export_import_preservation.json',dict(checked=len(originals),restored=restored))
    write(OUT/'build_files.json',[dict(path=str(p.relative_to(ROOT)),bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in dest.parent.rglob('*') if p.is_file()])

def launch():
    assert not engines(), engines()
    folder,env=profile('computer_use')
    user=folder/'appdata/Godot/app_userdata/마왕님, 마왕성 지켜주세요! Demo'
    user.mkdir(parents=True,exist_ok=True)
    settings=user/'settings.cfg'
    if not settings.exists(): settings.write_text('[interface]\nlocale="en"\n',encoding='utf-8')
    exe=STATE/'export/MawangCastle.exe'
    logs=OUT/'logs'; logs.mkdir(exist_ok=True)
    command=[str(exe),'--windowed','--resolution','900x506','--position','40,40','--max-fps','60']
    history=json.loads((OUT/'exe_launches.json').read_text()) if (OUT/'exe_launches.json').exists() else []
    name='exe_new_game' if not history else 'exe_restart_'+str(len(history))
    start=time.monotonic()
    with (logs/(name+'.stdout.log')).open('wb') as stdout,(logs/(name+'.stderr.log')).open('wb') as stderr:
        proc=subprocess.Popen(command,cwd=exe.parent,env=env,stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
    event=dict(pid=proc.pid,profile=str(folder),command=command,started=time.time())
    history.append(event); write(OUT/'exe_launches.json',history)
    write(OUT/'active_exe.json',event)
    print(json.dumps(event),flush=True)
    timed_out=False
    try: proc.wait(timeout=1800)
    except subprocess.TimeoutExpired: timed_out=True; proc.kill(); proc.wait()
    text=(logs/(name+'.stdout.log')).read_text(encoding='utf-8',errors='replace')+(logs/(name+'.stderr.log')).read_text(encoding='utf-8',errors='replace')
    result=dict(id=name,exit_code=proc.returncode,seconds=round(time.monotonic()-start,2),timeout=timed_out,error_lines=len(re.findall(r'(?m)^(?:SCRIPT )?ERROR:',text)),warning_lines=len(re.findall(r'(?m)^WARNING:',text)),command=command,profile=str(folder),engines_after=engines())
    write(OUT/'runs'/(name+'.json'),result)
    print(json.dumps(result),flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('mode',choices=['prepare','campaigns','static','suite','export','launch']); args=parser.parse_args()
    globals()[args.mode]()
