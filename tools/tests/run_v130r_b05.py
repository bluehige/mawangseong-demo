"""Serial B05 localization checks. All writable profiles are under tmp/."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import time
from run_v130r_b02_b03 import engines

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tmp/v130r_b05'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--rendered', action='store_true')
    parser.add_argument('--scene', default='V130RFixB05Test')
    args = parser.parse_args()
    assert not engines(), engines()
    profile = 'zh_cn_fix_20261007' if args.scene == 'ChineseLocalizationTest' else args.scene
    folder = OUT / (profile + ('_rendered' if args.rendered else '_headless'))
    folder.mkdir(parents=True, exist_ok=True)
    wrapper = Path(subprocess.check_output(['where.exe', 'godot.cmd'], text=True).splitlines()[0])
    exe = re.search(r'"([^"\r\n]+\.exe)"', wrapper.read_text()).group(1).replace('_console.exe', '.exe')
    env = os.environ.copy()
    env.update(APPDATA=str(folder/'appdata'), LOCALAPPDATA=str(folder/'localappdata'), MAWANG_DISABLE_STEAM='1')
    for key in ('APPDATA','LOCALAPPDATA'): Path(env[key]).mkdir(exist_ok=True)
    command = [exe, '--path', str(ROOT), '--rendering-method', 'gl_compatibility', '--resolution', '1280x720']
    if not args.rendered: command += ['--headless']
    command += ['--scene', f'res://tools/tests/{args.scene}.tscn', '--', '--checks-only']
    started = time.monotonic()
    peak = 0
    with (folder/'stdout.log').open('w',encoding='utf-8') as stdout, (folder/'stderr.log').open('w',encoding='utf-8') as stderr:
        process = subprocess.Popen(command,cwd=ROOT,env=env,stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            while process.poll() is None:
                peak=max(peak,len(engines()))
                errors=(folder/'stderr.log').read_text(encoding='utf-8',errors='replace')
                if time.monotonic()-started>360 or 'SCRIPT ERROR' in errors or peak>1:
                    process.kill(); break
                time.sleep(.25)
            process.wait(timeout=10)
        finally:
            if process.poll() is None: process.kill(); process.wait()
    errors=(folder/'stderr.log').read_text(encoding='utf-8',errors='replace')
    result=dict(command=command,exit_code=process.returncode,seconds=round(time.monotonic()-started,2),peak_godot=peak,godot_after=engines(),stderr=errors,tail=(folder/'stdout.log').read_text(encoding='utf-8',errors='replace')[-2500:])
    (folder/'run.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=True))
    return 0 if process.returncode==0 and not result['godot_after'] and 'ERROR:' not in errors else 1

if __name__=='__main__': raise SystemExit(main())
