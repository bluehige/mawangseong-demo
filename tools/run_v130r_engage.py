"""Isolated engagement regressions and a real Windows export for manual CU."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

from run_v130r_b04 import engines

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tmp/v130r_engage'


def junction(destination, source):
    if destination.exists():
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['cmd', '/c', 'mklink', '/J', str(destination), str(source)],
                   check=True, capture_output=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('phase', choices=['unit', 'export', 'exe'])
    args = parser.parse_args()
    assert not engines(), engines()
    phase = args.phase
    folder = OUT / phase
    folder.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(APPDATA=str(folder/'appdata'), LOCALAPPDATA=str(folder/'localappdata'),
               MAWANG_DISABLE_STEAM='1')
    for key in ['APPDATA', 'LOCALAPPDATA']:
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    wrapper = Path(shutil.which('godot-gui.cmd'))
    engine = re.search(r'"([^"\r\n]+\.exe)"', wrapper.read_text()).group(1)
    project = ROOT
    command = [engine, '--path', str(ROOT), '--headless', '--audio-driver', 'Dummy',
               '--scene', 'res://tools/tests/V130REngagementTest.tscn']
    if phase == 'export':
        project = OUT/'export_project'
        for name in ['scripts', 'scenes', 'data', 'addons']:
            shutil.copytree(ROOT/name, project/name, dirs_exist_ok=True)
        for name in ['project.godot', 'export_presets.cfg']:
            shutil.copy2(ROOT/name, project/name)
        junction(project/'assets', ROOT/'assets')
        junction(project/'.godot/imported', ROOT/'.godot/imported')
        for name in ['global_script_class_cache.cfg', 'uid_cache.bin']:
            if (ROOT/'.godot'/name).exists():
                shutil.copy2(ROOT/'.godot'/name, project/'.godot'/name)
        # Package the normal main scene. The isolated test probe restores copies,
        # records contacts and takes screenshots only on manual function keys.
        probe = project/'scripts/tests/V130REngagementExe.gd'
        probe.parent.mkdir(exist_ok=True)
        probe.write_text((ROOT/'tools/tests/V130REngagementExe.gd').read_text(encoding='utf-8').replace('res://tools/tests/', 'res://scripts/tests/'), encoding='utf-8')
        for name in ['V130RB04Campaign.gd', 'V130RB04Stacking.gd', 'V130RB04RandomState.gd',
                     'V130RB04FastController.gd', 'V130RB04FastUnit.gd', 'V130RB04FastMap.gd']:
            target = project/'scripts/tests'/name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text((ROOT/'tools/tests'/name).read_text(encoding='utf-8').replace('res://tools/tests/', 'res://scripts/tests/'), encoding='utf-8')
        selection=json.loads((OUT/'selection.json').read_text(encoding='utf-8'))
        checkpoint_label=selection['label']
        assert re.fullmatch(r'[a-zA-Z0-9_-]+',checkpoint_label)
        for day in [1, 5]:
            source = OUT/checkpoint_label/'checkpoints'/f'130401_{day}.json'
            assert source.exists(), 'Actual selected campaign must have reached the visual sample date'
            target = project/'data/test_engage'/source.name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
        config = project/'project.godot'
        text = config.read_text(encoding='utf-8-sig')
        # This diagnostic binary stays isolated even if opened without the runner.
        # The boot autoload runs before the production achievement/Steam service.
        (probe.parent/'V130REngagementBoot.gd').write_text('extends Node\nfunc _init() -> void:\n\tOS.set_environment("MAWANG_DISABLE_STEAM","1")\n', encoding='utf-8')
        text = re.sub(r'(?m)^config/custom_user_dir_name=.*$', 'config/custom_user_dir_name="Godot/app_userdata/v130r_engage_exe_test"', text, count=1)
        text = text.replace('[autoload]', '[autoload]\n\nEngagementBoot="*res://scripts/tests/V130REngagementBoot.gd"', 1)
        text = text.replace('[debug]', 'EngagementExe="*res://scripts/tests/V130REngagementExe.gd"\n\n[debug]', 1)
        config.write_text(text, encoding='utf-8')
        junction(Path(env['APPDATA'])/'Godot/export_templates',
                 Path(os.environ['APPDATA'])/'Godot/export_templates')
        destination = OUT/'exe/MawangEngage.exe'
        destination.parent.mkdir(exist_ok=True)
        command = [engine, '--path', str(project), '--headless', '--export-release',
                   'Windows Desktop', str(destination)]
    elif phase == 'exe':
        command = [str(OUT/'exe/MawangEngage.exe'), '--windowed', '--resolution',
                   '900x506', '--audio-driver', 'Dummy']
    imports = {p: p.read_bytes() for p in (ROOT/'assets').rglob('*.import')}
    started = time.monotonic()
    with (folder/'stdout.log').open('wb') as stdout, (folder/'stderr.log').open('wb') as stderr:
        process = subprocess.Popen(command, cwd=project, env=env, stdout=stdout, stderr=stderr,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        (OUT/'active.json').write_text(json.dumps({'phase':phase,'pid':process.pid,'command':command}), encoding='utf-8')
        print('OWNED_PID', process.pid, flush=True)
        try:
            process.wait(timeout=1800 if phase == 'exe' else 600)
        except subprocess.TimeoutExpired:
            process.kill(); process.wait()
        finally:
            for path, data in imports.items():
                if path.read_bytes() != data: path.write_bytes(data)
    errors = (folder/'stderr.log').read_text(encoding='utf-8', errors='replace')
    summary = {'phase':phase, 'exit':process.returncode,'seconds':round(time.monotonic()-started,1),
               'diagnostic_count':sum('ERROR:' in line or 'WARNING:' in line for line in errors.splitlines()),
               'godot_after':engines()}
    if phase == 'export':
        summary['files'] = {p.name:hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in (OUT/'exe').glob('*') if p.is_file()}
        summary['checkpoint_source']=checkpoint_label
        inputs=['scripts/game/ApprovedBattleController.gd','scripts/units/ApprovedBattleUnit.gd',
                'scripts/game/GameRoot.gd','data/waves.json','data/v122/dual_front_day01_05_waves.json']
        summary['source_hashes']={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in inputs}
        summary['export_source_matches_workspace']=all(
            hashlib.sha256((project/p).read_bytes()).hexdigest()==digest
            for p,digest in summary['source_hashes'].items())
        assert summary['export_source_matches_workspace']
    (folder/'run.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    print(json.dumps(summary), flush=True)
    return int(process.returncode != 0 or summary['diagnostic_count'] != 0 or bool(engines()))


if __name__ == '__main__':
    raise SystemExit(main())
