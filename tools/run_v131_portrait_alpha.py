"""Serial portrait checks and QA-only EXE with isolated local save directories."""
from pathlib import Path
import argparse
import csv
import json
import os
import shutil
import subprocess
import time

from run_v131_ui_feedback import engine

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'tmp/portrait_alpha_20261020'


def idle():
    rows = csv.reader(subprocess.check_output(['tasklist.exe', '/fo', 'csv', '/nh'], text=True).splitlines())
    live = [row[0] for row in rows if row and row[0].lower().startswith(('godot', 'mawang'))]
    if live:
        raise RuntimeError('Existing game/engine: '+', '.join(live))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('phase', choices=['import', 'test', 'export', 'launch'])
    parser.add_argument('--portrait', choices=['nia', 'milo', 'leon'], default='nia')
    args = parser.parse_args()
    label = args.phase+'-'+args.portrait if args.phase == 'launch' else args.phase
    idle()
    OUT.mkdir(parents=True, exist_ok=True)
    (ROOT/'tmp/.gdignore').write_text('')
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        env[key] = str(OUT/'profiles'/(args.phase+'-'+args.portrait)/key)
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    env['MAWANG_DISABLE_STEAM'] = '1'
    command = [engine(), '--path', str(ROOT), '--audio-driver', 'Dummy']
    if args.phase == 'import':
        command += ['--headless', '--editor', '--import']
    elif args.phase == 'test':
        command += ['--headless', 'res://tools/tests/V131PortraitAlphaTest.tscn']
    elif args.phase == 'export':
        project = OUT/'export_project'
        for folder in ('scripts', 'scenes', 'data', 'addons'):
            shutil.copytree(ROOT/folder, project/folder, dirs_exist_ok=True)
        for filename in ('project.godot', 'export_presets.cfg'):
            shutil.copy2(ROOT/filename, project/filename)
        for folder in ('assets', '.godot/imported'):
            dest = project/folder
            dest.parent.mkdir(parents=True, exist_ok=True)
            if not dest.exists():
                subprocess.run(['cmd.exe', '/c', 'mklink', '/J', str(dest), str(ROOT/folder)], check=True, capture_output=True)
        for filename in ('global_script_class_cache.cfg', 'uid_cache.bin'):
            shutil.copy2(ROOT/'.godot'/filename, project/'.godot'/filename)
        shutil.copy2(ROOT/'tools/tests/V131PortraitExeProbe.gd', project/'scripts/V131PortraitExeProbe.gd')
        settings = project/'project.godot'
        settings.write_text(settings.read_text(encoding='utf-8-sig').replace('[debug]', 'V131PortraitExeProbe="*res://scripts/V131PortraitExeProbe.gd"\n\n[debug]', 1), encoding='utf-8')
        templates = Path(env['APPDATA'])/'Godot/export_templates'
        templates.parent.mkdir(parents=True, exist_ok=True)
        if not templates.exists():
            subprocess.run(['cmd.exe', '/c', 'mklink', '/J', str(templates), str(Path(os.environ['APPDATA'])/'Godot/export_templates')], check=True, capture_output=True)
        (OUT/'exe').mkdir(exist_ok=True)
        command = [engine(), '--path', str(project), '--headless', '--export-release', 'Windows Desktop', str(OUT/'exe/MawangPortrait.exe')]
    else:
        command = [str(OUT/'exe/MawangPortrait.exe'), '--windowed', '--resolution', '920x518', '--position', '80,80', '--audio-driver', 'Dummy', '--', '--qa-portrait='+args.portrait]
    metadata = {p: p.read_bytes() for p in [*(ROOT/'assets').rglob('*.import'), *ROOT.glob('*.import')]}
    start = time.monotonic()
    with (OUT/(label+'.log')).open('w', encoding='utf-8') as log:
        proc = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
        (OUT/'active.json').write_text(json.dumps({'phase': args.phase, 'pid': proc.pid, 'appdata': env['APPDATA']}))
        print('OWNED_PID', proc.pid, flush=True)
        try:
            code = proc.wait(timeout=1200)
        except subprocess.TimeoutExpired:
            proc.terminate()
            proc.wait()
            raise
        finally:
            for path, data in metadata.items():
                if path.read_bytes() != data:
                    path.write_bytes(data)
    lines = (OUT/(label+'.log')).read_text(encoding='utf-8', errors='replace').splitlines()
    diagnostics = [line for line in lines if any(s in line for s in ('SCRIPT ERROR', 'Parse Error', 'ERROR:', 'crashed'))]
    result = {'phase': args.phase, 'exit': code, 'seconds': round(time.monotonic()-start, 1), 'diagnostics': diagnostics[:5], 'diagnostic_count': len(diagnostics)}
    (OUT/(label+'_run.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False))
    idle()
    raise SystemExit(code or bool(diagnostics))


if __name__ == '__main__':
    main()
