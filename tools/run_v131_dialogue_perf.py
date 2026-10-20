"""Isolated serial Windows EXE profiling; artifacts stay under ignored tmp/."""
from pathlib import Path
import argparse
import csv
import io
import json
import os
import re
import shutil
import subprocess
import tarfile
import time

from run_v131_ui_feedback import engine

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tmp/v131_dialogue_perf'
BASE = '085a32f2b58d6cb59c1ec2b47508df30b7e0835f'


def idle():
    rows = csv.reader(subprocess.check_output(['tasklist.exe', '/fo', 'csv', '/nh'], text=True).splitlines())
    live = [r[0] for r in rows if r and r[0].lower().startswith(('godot', 'mawang'))]
    if live:
        raise RuntimeError('Existing engine/game: ' + ', '.join(live))


def instrument(path, names, owner):
    source = path.read_text(encoding='utf-8-sig')
    for name in names:
        match = re.search(r'^(static )?func ' + name + r'\(([^\n]*)\)( -> [^:]+)?:', source, re.M)
        if not match:
            continue
        static = match.group(1) or ''
        args = match.group(2)
        result = match.group(3) or ''
        params = [p.split(':')[0].split('=')[0].strip() for p in args.split(',') if p.strip()]
        returns = bool(result and result != ' -> void')
        source = source.replace('func ' + name + '(', 'func _profiled_' + name + '(', 1)
        lookup = 'Engine.get_main_loop().root' if static else owner + '.get_tree().root'
        source += (f'\n{static}func {name}({args}){result}:\n\tvar perf_start := Time.get_ticks_usec()\n'
                   f'\t{"var perf_result = " if returns else ""}_profiled_{name}({", ".join(params)})\n'
                   f'\t{lookup}.get_node("V131DialoguePerfProbe").record_cost("{path.stem}.{name}",Time.get_ticks_usec()-perf_start)\n'
                   + ('\treturn perf_result\n' if returns else ''))
    path.write_text(source, encoding='utf-8')


def environment(label):
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        env[key] = str(OUT / 'profiles' / label / key)
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    env['MAWANG_DISABLE_STEAM'] = '1'
    return env


def run(command, label, env, timeout=1200):
    idle()
    log = OUT / (label + '.log')
    metadata = {p: p.read_bytes() for p in (ROOT / 'assets').rglob('*.import')}
    started = time.monotonic()
    with log.open('w', encoding='utf-8') as stream:
        proc = subprocess.Popen(command, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT)
        (OUT / 'active.json').write_text(json.dumps({'pid': proc.pid, 'label': label, 'appdata': env['APPDATA']}))
        print('OWNED_PID', proc.pid, flush=True)
        try:
            deadline = time.monotonic() + timeout
            while proc.poll() is None:
                time.sleep(.2)
                if time.monotonic() > deadline:
                    raise subprocess.TimeoutExpired(command, timeout)
                if 'SCRIPT ERROR' in log.read_text(encoding='utf-8', errors='replace'):
                    proc.terminate(); proc.wait(); break
            code = proc.returncode
        except subprocess.TimeoutExpired:
            proc.terminate()
            proc.wait()
            raise
        finally:
            for p, content in metadata.items():
                if p.read_bytes() != content:
                    p.write_bytes(content)
    lines = log.read_text(encoding='utf-8', errors='replace').splitlines()
    errors = [x for x in lines if any(t in x for t in ('SCRIPT ERROR', 'Parse Error', 'ERROR:', 'crashed'))]
    result = dict(label=label, exit=code, seconds=round(time.monotonic()-started, 1), error_count=len(errors), errors=errors[:4], summary=[x for x in lines if x.startswith(('PERF_', 'PASS', 'FAIL'))][-4:])
    (OUT / (label + '.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False), flush=True)
    idle()
    if code or errors:
        raise SystemExit(1)


def export(label):
    project = OUT / ('project-' + label)
    for folder in ('scripts', 'scenes', 'data', 'addons'):
        shutil.copytree(ROOT / folder, project / folder, dirs_exist_ok=True)
    for filename in ('project.godot', 'export_presets.cfg'):
        shutil.copy2(ROOT / filename, project / filename)
    if label == 'before':
        archive = subprocess.check_output(['git', 'archive', BASE, 'scripts', 'scenes', 'data', 'project.godot', 'export_presets.cfg'], cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            for member in tar:
                if member.isfile():
                    target = project / member.name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(tar.extractfile(member).read())
    for folder in ('assets', '.godot/imported'):
        dest = project / folder
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.exists():
            # Windows directory junction only; no delete or move operation.
            subprocess.run(['cmd.exe', '/c', 'mklink', '/J', str(dest), str(ROOT / folder)], check=True, capture_output=True)
    for filename in ('global_script_class_cache.cfg', 'uid_cache.bin'):
        shutil.copy2(ROOT / '.godot' / filename, project / '.godot' / filename)
    shutil.copy2(ROOT / 'tools/tests/V131DialoguePerfProbe.gd', project / 'scripts/V131DialoguePerfProbe.gd')
    settings = project / 'project.godot'
    settings.write_text(settings.read_text(encoding='utf-8-sig').replace('[debug]', 'V131DialoguePerfProbe="*res://scripts/V131DialoguePerfProbe.gd"\n\n[debug]', 1), encoding='utf-8')
    instrument(project / 'scripts/game/GameRoot.gd', ['_set_screen', '_load_png', '_onboarding_portrait_texture'], 'self')
    instrument(project / 'scripts/story/StoryDialoguePresenter.gd', ['_standing', '_paginate', '_background', '_build_shared_frame'], 'root')
    instrument(project / 'scripts/ui/kit/UIKit.gd', ['scaled_theme', 'apply_scale'], 'root')
    env = environment('export-' + label)
    templates = Path(env['APPDATA']) / 'Godot/export_templates'
    templates.parent.mkdir(parents=True, exist_ok=True)
    if not templates.exists():
        subprocess.run(['cmd.exe', '/c', 'mklink', '/J', str(templates), str(Path(os.environ['APPDATA']) / 'Godot/export_templates')], check=True, capture_output=True)
    target = OUT / ('exe-' + label) / 'MawangDialogue.exe'
    target.parent.mkdir(parents=True, exist_ok=True)
    run([engine(), '--path', str(project), '--headless', '--export-release', 'Windows Desktop', str(target)], 'export-' + label, env)


def summarize():
    result = {}
    for label in ('before', 'after'):
        files = sorted((OUT / 'profiles').glob('bench-' + label + '*/APPDATA/**/benchmark.json'))
        valid = [json.loads(p.read_text(encoding='utf-8')) for p in files if not (p.parent / 'superseded.txt').exists()]
        valid = [proof for proof in valid if not proof['failures']]
        rows = [r for proof in valid for r in proof['samples']]
        rows += [dict(r, kind='all_advance') for r in rows if r['kind'] in ('same_portrait', 'portrait_change', 'long_text', 'long_page', 'story_advance')]
        # First manual next after entry is also reported separately; it remains
        # a subset of the same-portrait group rather than an extra observation.
        rows += [dict(next(r for r in proof['samples'] if r['kind'] == 'same_portrait'), kind='first_advance') for proof in valid]
        groups = {}
        for kind in sorted({r['kind'] for r in rows}):
            selected = [r for r in rows if r['kind'] == kind]
            stats = {}
            for metric in ('blocking_ms', 'frame_ms'):
                values = sorted(r[metric] for r in selected)
                stats[metric] = dict(mean=round(sum(values)/len(values), 3), p95=round(values[max(0, __import__('math').ceil(.95*len(values))-1)], 3), max=round(max(values), 3))
            totals = {}
            for row in selected:
                for key, cost in row['costs'].items():
                    totals.setdefault(key, dict(calls=0, ms=0.0))
                    totals[key]['calls'] += cost['calls']; totals[key]['ms'] += cost['ms']
            groups[kind] = dict(n=len(selected), **stats, costs=totals)
        result[label] = groups
    (OUT / 'comparison.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({label: {k: {x: v for x, v in row.items() if x != 'costs'} for k, row in groups.items()} for label, groups in result.items()}, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('phase', choices=['export', 'benchmark', 'launch', 'summary', 'test'])
    parser.add_argument('label', nargs='?', default='after')
    parser.add_argument('--run', default='1')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    (ROOT / 'tmp/.gdignore').write_text('')
    if args.phase == 'export':
        idle(); export(args.label)
    elif args.phase in ('benchmark', 'launch'):
        label = ('bench-' if args.phase == 'benchmark' else 'manual-') + args.label + '-' + args.run
        run([str(OUT / ('exe-' + args.label) / 'MawangDialogue.exe'), '--windowed', '--resolution', '1920x1080', '--position', '0,0', '--audio-driver', 'Dummy', '--', *(['--qa-benchmark'] if args.phase == 'benchmark' else []), *(['--qa-expect-reuse'] if args.label == 'after' else [])], label, environment(label))
    elif args.phase == 'test':
        run([engine(), '--path', str(ROOT), '--headless', '--audio-driver', 'Dummy', 'res://tools/tests/' + args.label + '.tscn'], 'test-' + args.label, environment('test-' + args.label))
    else:
        summarize()


if __name__ == '__main__':
    main()
