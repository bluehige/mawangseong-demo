"""Single-engine UI/EXE checks, isolated profiles and concise log summaries."""
from pathlib import Path
import argparse
import json
import os
import re
import shutil
import subprocess
import time
import psutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tmp/playtest_ui_20261019'

def active():
    return [p.info for p in psutil.process_iter(['pid', 'name'])
            if 'godot' in (p.info['name'] or '').lower()
            or (p.info['name'] or '').lower().startswith(('mawangcastle','mawangplaytest','mawangdialogue'))]

def link(target, source):
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(['cmd','/c','mklink','/J',str(target),str(source)],check=True,capture_output=True)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('phase',choices=['before','after','export-before','export-after','launch-before','launch-after','import','headless'])
    args=parser.parse_args(); phase=args.phase
    OUT.mkdir(parents=True,exist_ok=True)
    running=active()
    if running: raise RuntimeError('Existing game/engine: '+json.dumps(running))
    wrapper=Path(shutil.which('godot-gui.cmd'))
    engine=Path(re.search(r'"([^"\r\n]+\.exe)"',wrapper.read_text()).group(1))
    env=os.environ.copy()
    env['APPDATA']=str(OUT/'profiles'/phase/'appdata')
    env['LOCALAPPDATA']=str(OUT/'profiles'/phase/'localappdata')
    env['MAWANG_DISABLE_STEAM']='1'
    for key in ['APPDATA','LOCALAPPDATA']: Path(env[key]).mkdir(parents=True,exist_ok=True)
    project=OUT/'baseline_project' if phase.endswith('before') or phase=='before' else ROOT
    cmd=[str(engine),'--path',str(project),'--audio-driver','Dummy']
    if phase in ['before','after','headless']:
        if project!=ROOT:
            shutil.copytree(ROOT/'tools/tests',project/'tools/tests',dirs_exist_ok=True)
            (project/'tmp/playtest_ui_20261019').mkdir(parents=True,exist_ok=True)
        if phase=='headless':cmd+=['--headless']
        else:cmd+=['--rendering-method','gl_compatibility']
        cmd+=['res://tools/tests/PlaytestUIFixTest.tscn','--','--phase='+('after' if phase=='headless' else phase)]
    elif phase=='import':
        cmd+=['--headless','--editor','--import']
    elif phase.startswith('export'):
        export=OUT/('export_project_'+phase.split('-')[1])
        for folder in ['scripts','scenes','data','addons']:shutil.copytree(project/folder,export/folder,dirs_exist_ok=True)
        for name in ['project.godot','export_presets.cfg']:shutil.copy2(project/name,export/name)
        link(export/'assets',ROOT/'assets')
        (export/'.godot').mkdir(exist_ok=True)
        link(export/'.godot/imported',ROOT/'.godot/imported')
        for name in ['global_script_class_cache.cfg','uid_cache.bin']:
            if (ROOT/'.godot'/name).exists():shutil.copy2(ROOT/'.godot'/name,export/'.godot'/name)
        probe=export/'scripts/tests/PlaytestExeProbe.gd';probe.parent.mkdir(exist_ok=True)
        shutil.copy2(ROOT/'tools/tests/PlaytestExeProbe.gd',probe)
        project_file=export/'project.godot'
        text=project_file.read_text(encoding='utf-8-sig').replace('[debug]','PlaytestExeProbe="*res://scripts/tests/PlaytestExeProbe.gd"\n\n[debug]',1)
        project_file.write_text(text,encoding='utf-8')
        link(Path(env['APPDATA'])/'Godot/export_templates',Path(os.environ['APPDATA'])/'Godot/export_templates')
        destination=OUT/('exe_'+phase.split('-')[1])/'MawangPlaytest.exe';destination.parent.mkdir(exist_ok=True)
        cmd=[str(engine),'--path',str(export),'--headless','--export-release','Windows Desktop',str(destination)]
    else:
        exe=OUT/('exe_'+phase.split('-')[1])/'MawangPlaytest.exe'
        cmd=[str(exe),'--windowed','--audio-driver','Dummy']
    # Shared import metadata is snapshotted so the user's preexisting edits survive.
    imports={p:p.read_bytes() for p in (ROOT/'assets').rglob('*.import')}
    log=OUT/(phase+'.log')
    started=time.monotonic()
    with log.open('wb') as stream:
        proc=subprocess.Popen(cmd,cwd=project,env=env,stdout=stream,stderr=subprocess.STDOUT)
        (OUT/'active.json').write_text(json.dumps({'phase':phase,'pid':proc.pid,'profile':env['APPDATA']},indent=2),encoding='utf-8')
        print('OWNED_PID',proc.pid,flush=True)
        try: code=proc.wait(timeout=1800 if phase.startswith('launch') else 600)
        except subprocess.TimeoutExpired: proc.kill();proc.wait();raise
        finally:
            for p,data in imports.items():
                if p.read_bytes()!=data:p.write_bytes(data)
    if project!=ROOT and phase=='before':
        for p in (project/'tmp/playtest_ui_20261019').glob('before_*'):shutil.copy2(p,OUT/p.name)
    text=log.read_text(encoding='utf-8',errors='replace')
    errors=[line for line in text.splitlines() if any(s in line for s in ['SCRIPT ERROR','Parse Error','ERROR:','WARNING:','backtrace','crashed'])]
    result={'phase':phase,'exit':code,'seconds':round(time.monotonic()-started,1),'diagnostics':errors[:6],'diagnostic_count':len(errors),'engines_after':active()}
    (OUT/(phase+'_run.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result),flush=True)
    raise SystemExit(code or bool(errors))

if __name__=='__main__':main()
