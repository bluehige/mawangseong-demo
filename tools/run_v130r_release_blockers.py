"""Serial, isolated release-blocker checks. Logs stay in tmp; console is concise."""
import argparse
import json
import os
import re
import subprocess
import time
from pathlib import Path
import psutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tmp/v130r_release_blockers'

def engines():
    return [p.info for p in psutil.process_iter(['pid', 'name'])
            if 'godot_v' in (p.info['name'] or '').lower()
            or (p.info['name'] or '').lower().startswith('mawangcastle')]

def engine():
    wrapper = Path(subprocess.check_output(['where.exe', 'godot.cmd'], text=True).splitlines()[0])
    return Path(re.search(r'"([^"\r\n]+\.exe)"', wrapper.read_text()).group(1).replace('_console.exe', '.exe'))

def run(mode):
    assert not engines(), engines()
    OUT.mkdir(parents=True, exist_ok=True)
    profile = OUT/'profiles'/('campaign_final' if mode in ['campaign','resume'] else 'exe' if mode in ['exe','exe_resume'] else mode)
    for folder in ['appdata','localappdata']: (profile/folder).mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(APPDATA=str(profile/'appdata'), LOCALAPPDATA=str(profile/'localappdata'), MAWANG_DISABLE_STEAM='1')
    exe_mode = mode in ['exe','exe_resume']
    command = [str(OUT/'export/MawangCastle.exe' if exe_mode else engine())]
    if not exe_mode: command += ['--path', str(ROOT), '--rendering-method', 'gl_compatibility']
    command += ['--windowed', '--resolution', '900x506', '--max-fps', '120']
    if mode not in ['exe','exe_resume','layout']: command.append('--headless')
    modes = {
        'boot': ['--quit-after','30'],
        'unit': ['--scene','res://tools/tests/V130RReleaseBlockersTest.tscn'],
        'layout': ['--scene','res://tools/tests/V130RReleaseLayoutTest.tscn'],
        'campaign': ['--scene','res://tools/tests/V130RReleaseCampaign.tscn','--','seed=130401'],
        'resume': ['--scene','res://tools/tests/V130RReleaseCampaign.tscn','--','seed=130401','resume=true'],
        'export': ['--export-release','Windows Desktop',str(OUT/'export/MawangCastle.exe')],
        'legacy': ['--scene','res://tools/tests/V130RReleaseLegacyTest.tscn'],
    }
    if mode=='export':
        (OUT/'export').mkdir(exist_ok=True)
        templates = profile/'appdata/Godot/export_templates'
        templates.parent.mkdir(parents=True, exist_ok=True)
        if not templates.exists():
            subprocess.run(['cmd','/c','mklink','/J',str(templates),str(Path(os.environ['APPDATA'])/'Godot/export_templates')],check=True,capture_output=True)
    if not exe_mode: command += modes[mode]
    logs = OUT/'logs'; logs.mkdir(exist_ok=True)
    timeout = 2400 if mode in ['campaign','exe','exe_resume'] else 300
    started = time.monotonic(); timed_out = False
    with (logs/(mode+'.stdout.log')).open('wb') as stdout, (logs/(mode+'.stderr.log')).open('wb') as stderr:
        proc = subprocess.Popen(command,cwd=OUT/'export' if exe_mode else ROOT,env=env,stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
        (OUT/'active.json').write_text(json.dumps({'pid':proc.pid,'mode':mode,'command':command,'profile':str(profile)},ensure_ascii=False,indent=2),encoding='utf-8')
        try: proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out=True; proc.kill(); proc.wait()
    text = (logs/(mode+'.stdout.log')).read_text(encoding='utf-8',errors='replace')+(logs/(mode+'.stderr.log')).read_text(encoding='utf-8',errors='replace')
    result = {'id':mode,'exit_code':proc.returncode,'seconds':round(time.monotonic()-started,2),'timeout':timed_out,'error_lines':len(re.findall(r'(?m)^(?:SCRIPT )?ERROR:',text)),'warning_lines':len(re.findall(r'(?m)^WARNING:',text)),'engines_after':engines()}
    (OUT/'runs').mkdir(exist_ok=True)
    (OUT/'runs'/(mode+'.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result),flush=True)
    return int(bool(proc.returncode or timed_out or result['error_lines']))

if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('mode',choices=['boot','unit','layout','campaign','resume','export','exe','exe_resume','legacy'])
    raise SystemExit(run(parser.parse_args().mode))
