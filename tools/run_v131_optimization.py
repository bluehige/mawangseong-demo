"""Serial optimization audit. QA copies and new profiles only; no release folders."""
from pathlib import Path
import argparse
import collections
import csv
import hashlib
import json
import os
import re
import shutil
import statistics
import struct
import subprocess
import time

import psutil
from PIL import Image
from run_v131_ui_feedback import engine

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tmp/v131_optimization'
BASE = 'f3a0c617288f83758db83cc4974fb280569f7fbe'


def idle():
    live = [p.info['name'] for p in psutil.process_iter(['name'])
            if (p.info['name'] or '').lower().startswith(('godot', 'mawang'))]
    if live:
        raise RuntimeError('Engine/game already running: ' + ','.join(live))


def environment(label):
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        env[key] = str(OUT / 'profiles' / label / key)
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    env['MAWANG_DISABLE_STEAM'] = '1'
    return env


def execute(command, label, timeout=900):
    idle()
    env = environment(label)
    templates = Path(env['APPDATA']) / 'Godot/export_templates'
    if not templates.exists():
        templates.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(['cmd.exe', '/c', 'mklink', '/J', str(templates), str(Path(os.environ['APPDATA']) / 'Godot/export_templates')], check=True, capture_output=True)
    start = time.perf_counter()
    memory = []
    with (OUT / (label + '.log')).open('w', encoding='utf-8') as log:
        proc = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
        (OUT / 'active.json').write_text(json.dumps(dict(pid=proc.pid, label=label, appdata=env['APPDATA'])))
        print('OWNED_PID', proc.pid, flush=True)
        observed = psutil.Process(proc.pid)
        try:
            while proc.poll() is None:
                try:
                    info = observed.memory_info()
                    memory.append(dict(seconds=round(time.perf_counter()-start, 3), rss=info.rss, private=getattr(info, 'private', 0)))
                except psutil.NoSuchProcess:
                    pass
                if time.perf_counter()-start > timeout:
                    proc.terminate()
                    raise TimeoutError(label)
                time.sleep(.1)
        finally:
            if proc.poll() is None:
                proc.terminate()
            proc.wait()
    lines = (OUT / (label + '.log')).read_text(encoding='utf-8', errors='replace').splitlines()
    errors = [x for x in lines if any(t in x for t in ('SCRIPT ERROR', 'Parse Error', 'ERROR:', 'crashed'))]
    result = dict(label=label, exit=proc.returncode, seconds=round(time.perf_counter()-start, 3),
                  error_count=len(errors), errors=errors[:3], warnings=sum('WARNING:' in x for x in lines),
                  summary=[x for x in lines if x.startswith(('OPT_', 'PASS', 'FAIL'))][-6:])
    (OUT / (label + '.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    (OUT / (label + '-memory.json')).write_text(json.dumps(memory))
    print(json.dumps(result, ensure_ascii=False), flush=True)
    idle()
    if proc.returncode or errors:
        raise SystemExit(1)


def prepare(label):
    idle()
    project = OUT / ('project-' + label)
    project.mkdir(parents=True, exist_ok=True)
    for folder in ('scripts', 'scenes', 'data', 'addons', 'assets', '.godot/imported'):
        if folder == 'assets' and (project / folder).exists():
            continue
        shutil.copytree(ROOT / folder, project / folder, dirs_exist_ok=True)
    for name in ('project.godot', 'export_presets.cfg', '.godot/global_script_class_cache.cfg', '.godot/uid_cache.bin'):
        shutil.copy2(ROOT / name, project / name)
    shutil.copy2(ROOT / 'tools/tests/V131OptimizationProbe.gd', project / 'scripts/V131OptimizationProbe.gd')
    if label == 'before':
        for rel in ('scripts/ui/ApprovedBattleUI.gd',):
            (project / rel).write_bytes(subprocess.check_output(['git', 'show', BASE+':'+rel], cwd=ROOT))
    settings = project / 'project.godot'
    source = settings.read_text(encoding='utf-8-sig').replace('[debug]', 'V131OptimizationProbe="*res://scripts/V131OptimizationProbe.gd"\n\n[debug]', 1)
    settings.write_text(source, encoding='utf-8')
    # Instrument copied scripts only. Keep each call separate: autoload and GameRoot both load all data.
    for rel, name, owner in [('scripts/core/DataRegistry.gd', 'load_all', 'self'),
                              ('scripts/game/GameRoot.gd', '_load_textures', 'self')]:
        path = project / rel
        source = path.read_text(encoding='utf-8-sig').replace('func '+name+'(', 'func _opt_original_'+name+'(', 1)
        source += ('\nfunc '+name+'() -> void:\n\tvar started := Time.get_ticks_usec()\n\t_opt_original_'+name+'()\n'
                   '\t'+owner+'.get_tree().root.set_meta("opt_'+name+'", '+owner+'.get_tree().root.get_meta("opt_'+name+'", []) + [(Time.get_ticks_usec()-started)/1000.0])\n')
        path.write_text(source, encoding='utf-8')
    path = project / 'scripts/ui/ApprovedBattleUI.gd'
    source = path.read_text(encoding='utf-8-sig')
    for name in ('position_skills', 'layout_vitals', 'refresh'):
        source = source.replace('func '+name+'(', 'func _opt_original_'+name+'(', 1)
        source += ('\nfunc '+name+'() -> void:\n\tvar calls: Dictionary = get_tree().root.get_meta("opt_visual_calls",{})\n'
                   '\tcalls["'+name+'"] = int(calls.get("'+name+'",0))+1\n'
                   '\tget_tree().root.set_meta("opt_visual_calls",calls)\n\t_opt_original_'+name+'()\n')
    path.write_text(source, encoding='utf-8')
    print('PREPARED', label, flush=True)


def pck_entries(path):
    with path.open('rb') as f:
        magic, version = struct.unpack('<II', f.read(8))
        assert magic == 0x43504447 and version == 3, (magic, version)
        f.seek(32)
        directory = struct.unpack('<Q', f.read(8))[0]
        f.seek(directory)
        count, = struct.unpack('<I', f.read(4))
        entries = []
        for _ in range(count):
            length, = struct.unpack('<I', f.read(4))
            name = f.read(length).rstrip(b'\0').decode('utf-8')
            offset, size = struct.unpack('<QQ', f.read(16))
            digest = f.read(16).hex()
            flags, = struct.unpack('<I', f.read(4))
            entries.append(dict(path=name, offset=offset, bytes=size, md5=digest, flags=flags))
        return entries


def audit(label):
    project = OUT / ('project-' + label)
    pck = OUT / ('exe-' + label) / 'MawangOptimization.pck'
    entries = pck_entries(pck)
    sizes = {row['path'].removeprefix('res://'): row['bytes'] for row in entries}
    files = sorted(entries, key=lambda r: r['bytes'], reverse=True)
    folders = collections.Counter()
    for row in entries:
        path = row['path'].removeprefix('res://')
        folders['/'.join(path.split('/')[:2])] += row['bytes']
    source_files = [p for folder in ('scripts', 'scenes', 'data') for p in (ROOT / folder).rglob('*') if p.suffix in ('.gd', '.tscn', '.tres', '.json')]
    texts = [(p.relative_to(ROOT).as_posix(), p.read_text(encoding='utf-8-sig', errors='replace')) for p in source_files]
    hashes = collections.defaultdict(list)
    rows = []
    for p in sorted((project / 'assets').rglob('*.png')):
        rel = p.relative_to(project).as_posix()
        imp = p.with_suffix('.png.import')
        if not imp.exists():
            continue
        settings = imp.read_text(encoding='utf-8-sig')
        imported = re.findall(r'path="res://([^"]+)"', settings)
        packed = [name for name in imported if name in sizes]
        if not packed:
            continue
        with Image.open(p) as im:
            width, height = im.size
        digest = hashlib.sha256(p.read_bytes()).hexdigest()
        hashes[digest].append(rel)
        refs = [name for name, text in texts if rel in text or p.name in text]
        params = dict(re.findall(r'^([\w/]+)=([^\n]+)', settings, re.M))
        rows.append(dict(path=rel, width=width, height=height, png_bytes=p.stat().st_size,
                         packed_bytes=sum(sizes[name] for name in packed), imported=packed,
                         rgba_bytes=width*height*4, compress_mode=params.get('compress/mode'),
                         mipmaps=params.get('mipmaps/generate'), size_limit=params.get('process/size_limit'),
                         sha256=digest, references=refs, reference_status='literal' if refs else 'no_literal_reference_dynamic_unresolved'))
    report = dict(label=label, pck_bytes=pck.stat().st_size, file_count=len(entries),
                  included_png_count=len(rows), png_bytes=sum(r['png_bytes'] for r in rows),
                  texture_packed_bytes=sum(r['packed_bytes'] for r in rows),
                  top30_files=files[:30], top30_folders=folders.most_common(30),
                  duplicates=[v for v in hashes.values() if len(v)>1],
                  no_literal_reference_count=sum(not r['references'] for r in rows),
                  compression=dict(collections.Counter(r['compress_mode'] for r in rows)),
                  mipmaps=dict(collections.Counter(r['mipmaps'] for r in rows)))
    source_by_import = {name:r['path'] for r in rows for name in r['imported']}
    texture_folders = collections.Counter()
    for name, source in source_by_import.items():
        texture_folders[str(Path(source).parent).replace('\\','/')] += sizes[name]
    report['top30_texture_source_folders'] = texture_folders.most_common(30)
    for name, data in [('inventory-'+label, rows), ('pck-'+label, entries), ('audit-'+label, report)]:
        (OUT / (name+'.json')).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if not k.startswith('top30') and k!='duplicates'} | dict(duplicate_groups=len(report['duplicates'])), ensure_ascii=False))


def summarize():
    result = {}
    observations = {}
    for label, run in [('before', '3'), ('after', '1')]:
        paths = list((OUT / 'profiles' / ('run-'+label+'-'+run)).rglob('optimization.json'))
        assert len(paths) == 1
        proof = json.loads(paths[0].read_text(encoding='utf-8'))
        assert not proof['failures']
        observations[label] = proof
        memory = json.loads((OUT / ('run-'+label+'-'+run+'-memory.json')).read_text())
        scenarios = []
        for row in proof['samples']:
            assert row['window'] == '(1920, 1080)'
            stats = {key: round(statistics.mean(c[key] for c in row['counters']), 3)
                     for key in ('draw_calls', 'video_bytes', 'process_ms', 'physics_ms', 'nodes')}
            scenarios.append({key: row[key] for key in ('scenario', 'window', 'fps', 'frame_ms', 'p95_ms', 'max_ms', 'max_enemies', 'council', 'visual_calls')} | stats)
        result[label] = dict(boot_ms=proof['boot_ms'], data_load_ms=proof['startup_data_load_ms'][:2],
                             textures_load_ms=proof['startup_textures_ms'][0],
                             peak_rss=max(r['rss'] for r in memory), peak_private=max(r['private'] for r in memory),
                             pck_bytes=(OUT/('exe-'+label)/'MawangOptimization.pck').stat().st_size,
                             scenarios=scenarios)
    (OUT / 'comparison.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    inventory = json.loads((OUT / 'inventory-before.json').read_text(encoding='utf-8'))
    fields = ['path','width','height','png_bytes','packed_bytes','compress_mode','mipmaps','size_limit','sha256',
              'sample_max_x','sample_max_y','sample_max_scale_x','sample_max_scale_y','atlas_regions_observed',
              'sample_oversized','rgba_saving_estimate_bytes','bound_status','references']
    csv_path = ROOT / 'docs/handoff/V131_OPTIMIZATION_IMAGES_2026-10-20.csv'
    with csv_path.open('w', newline='', encoding='utf-8-sig') as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for row in inventory:
            sampled = [proof['textures'].get('res://'+row['path']) for proof in observations.values()]
            sampled = [r for r in sampled if r is not None]
            max_x = max((r['display_x'] for r in sampled), default=0)
            max_y = max((r['display_y'] for r in sampled), default=0)
            atlas = []
            for proof in observations.values():
                for key, value in proof['textures'].items():
                    if key.startswith('res://'+row['path']+'#'):
                        region = re.search(r'S: \(([-.\d]+), ([-.\d]+)\)', key)
                        if region and float(region[1]) and float(region[2]):
                            atlas.append((value['display_x']/float(region[1]), value['display_y']/float(region[2])))
            scale_x = max([max_x/row['width']] + [v[0] for v in atlas])
            scale_y = max([max_y/row['height']] + [v[1] for v in atlas])
            if atlas:
                max_x = max(max_x,row['width']*scale_x)
                max_y = max(max_y,row['height']*scale_y)
            factor = min(1, max(2*max_x/row['width'], 2*max_y/row['height'])) if max_x and max_y else 1
            # Sampling gives candidates, never proof of a global maximum. Atlas
            # coordinates, zoom, alternate screens and higher resolutions still apply.
            out = {key:row[key] for key in fields if key in row}
            out.update(sample_max_x=round(max_x,2), sample_max_y=round(max_y,2),
                       sample_max_scale_x=round(scale_x,4), sample_max_scale_y=round(scale_y,4), atlas_regions_observed=len(atlas),
                       sample_oversized=factor<1, rgba_saving_estimate_bytes=round(row['rgba_bytes']*(1-factor*factor)),
                       bound_status='SAMPLED_ATLAS_COORDINATES_REQUIRED' if atlas else 'SAMPLED_ONLY_NO_GLOBAL_BOUND' if sampled else 'DYNAMIC_OR_UNSAMPLED',
                       references=';'.join(row['references']))
            writer.writerow(out)
    print(json.dumps(result, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('phase', choices=['prepare', 'export', 'run', 'manual', 'checks', 'audit', 'summary', 'test'])
    parser.add_argument('label', default='before', nargs='?')
    parser.add_argument('--run', default='1')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    (ROOT / 'tmp/.gdignore').write_text('')
    if args.phase == 'prepare':
        prepare(args.label)
    elif args.phase == 'export':
        target = OUT / ('exe-'+args.label) / 'MawangOptimization.exe'
        target.parent.mkdir(parents=True, exist_ok=True)
        execute([engine(), '--headless', '--path', str(OUT/('project-'+args.label)), '--export-release', 'Windows Desktop', str(target)], 'export-'+args.label)
    elif args.phase in ('run', 'manual', 'checks'):
        execute([str(OUT/('exe-'+args.label)/'MawangOptimization.exe'), '--windowed', '--resolution', '900x506' if args.phase=='manual' else '1920x1080', '--position', '20,20', '--audio-driver', 'Dummy', '--', '--unlock-all', '--opt-'+args.phase], args.phase+'-'+args.label+'-'+args.run)
    elif args.phase == 'audit':
        audit(args.label)
    elif args.phase == 'summary':
        summarize()
    else:
        execute([engine(), '--headless', '--path', str(ROOT), '--audio-driver', 'Dummy', 'res://tools/tests/'+args.label+'.tscn'], 'test-'+args.label)


if __name__ == '__main__':
    main()
