"""Local, serial audit runner. Never points Godot at the player's profile."""
import argparse, hashlib, json, os, re, subprocess, time
from pathlib import Path
import psutil

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
STATE = ROOT / 'tmp/release_audit_v130'
WRAPPER = subprocess.check_output(['where.exe', 'godot.cmd'], text=True).strip().splitlines()[0]
EXE = Path(re.search(r'"([^"\r\n]+\.exe)"', Path(WRAPPER).read_text()).group(1).replace('_console.exe', '.exe'))

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')

def engines():
    result=[]
    for p in psutil.process_iter(['name','cmdline']):
        if not ('godot' in (p.info['name'] or '').lower() or (p.info['name'] or '').lower().startswith('mawangcastle')): continue
        try:
            command=' '.join(p.info['cmdline'] or []).replace('\\','/').lower()
            if str(ROOT).replace('\\','/').lower() in command or Path(p.cwd()).resolve()==ROOT:
                result.append({'pid':p.pid,'name':p.info['name']})
        except psutil.Error: pass
    return result

def read_log(path):
    raw=path.read_bytes()
    try: return raw.decode('utf-8')
    except UnicodeDecodeError: return raw.decode('cp949',errors='replace')

def run(name, args, timeout=180, gui=False, executable=None, steam=False):
    assert not engines(), engines()
    folder = STATE / name
    if name.startswith('ChineseLocalizationTest'): folder = folder/'zh_cn_work_20261007'
    if name.startswith('PlayerContinuityTest'): folder = folder/'continuity_review'
    if name.startswith('SkillActionDuoTest'): folder = folder/'skill_action_review'
    folder.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(APPDATA=str(folder/'appdata'), LOCALAPPDATA=str(folder/'localappdata'), MAWANG_DISABLE_STEAM='0' if steam else '1', PYTHONIOENCODING='utf-8')
    Path(env['APPDATA']).mkdir(exist_ok=True); Path(env['LOCALAPPDATA']).mkdir(exist_ok=True)
    if '--export-release' in args:
        target = folder/'appdata/Godot/export_templates/4.6.3.stable'
        target.parent.mkdir(parents=True,exist_ok=True)
        source = Path(os.environ['APPDATA'])/'Godot/export_templates/4.6.3.stable'
        if not target.exists():
            subprocess.run(['powershell','-NoProfile','-Command',f"New-Item -ItemType Junction -Path '{target}' -Target '{source}' | Out-Null"],check=True)
    command = [str(executable or EXE)]
    if executable is None: command += ['--path',str(ROOT)]
    command += ['--rendering-method','gl_compatibility','--resolution','1920x1080','--max-fps','120']
    if not gui: command += ['--headless']
    command += args
    log = OUT/'logs'/f'{name}.stdout.log'; err = OUT/'logs'/f'{name}.stderr.log'
    log.parent.mkdir(exist_ok=True)
    started=time.time(); memory=[]; timed_out=False; script_error=False
    with log.open('w',encoding='utf-8') as stdout, err.open('w',encoding='utf-8') as stderr:
        p=subprocess.Popen(command,cwd=Path(executable).parent if executable else ROOT,env=env,stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            while p.poll() is None:
                try: memory.append(psutil.Process(p.pid).memory_info().rss)
                except psutil.Error: pass
                if time.time()-started>timeout: timed_out=True; p.kill(); break
                if 'SCRIPT ERROR' in err.read_text(encoding='utf-8',errors='replace'):
                    script_error=True; p.kill(); break
                time.sleep(.25)
            p.wait(timeout=10)
        finally:
            if p.poll() is None: p.kill(); p.wait()
    errors=read_log(err); output=read_log(log)
    for path, value in [(log,output),(err,errors)]:
        try: path.read_bytes().decode('utf-8')
        except UnicodeDecodeError:
            path.with_suffix(path.suffix+'.raw').write_bytes(path.read_bytes())
            path.write_text(value,encoding='utf-8')
    result={'id':name,'command':command,'exit_code':p.returncode,'seconds':round(time.time()-started,3),'timeout':timed_out,'script_error':script_error,'peak_rss_bytes':max(memory,default=0),'stdout':str(log.relative_to(ROOT)),'stderr':str(err.relative_to(ROOT)),'error_lines':len(re.findall(r'(?m)^(?:SCRIPT )?ERROR:',errors+output)),'warning_lines':len(re.findall(r'(?m)^WARNING:',errors+output)),'summary':output[-1800:],'engines_after':engines()}
    write(OUT/'runs'/f'{name}.json',result)
    print(json.dumps(result,ensure_ascii=True),flush=True)
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('mode'); parser.add_argument('extra',nargs='*'); a=parser.parse_args()
    if a.mode=='scene':
        run(a.extra[0],['--scene','res://tools/tests/'+a.extra[0]+'.tscn','--']+a.extra[1:])
    elif a.mode=='harness':
        run('_'.join(a.extra).replace('=',''),['--scene','res://_mockup/release_audit_v130/Audit.tscn','--']+a.extra,timeout=1200,gui='capture' in a.extra or 'perf' in a.extra)
    elif a.mode=='export':
        dest=STATE/'export/MawangCastle.exe'; dest.parent.mkdir(parents=True,exist_ok=True)
        run('windows_export',['--export-release','Windows Desktop',str(dest)],timeout=900)
        write(OUT/'build_files.json',[{'path':str(p.relative_to(ROOT)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in dest.parent.rglob('*') if p.is_file()])
    elif a.mode=='export_smoke':
        run('export_smoke',['--quit-after','180'],timeout=120,executable=STATE/'export/MawangCastle.exe',steam=True,gui=True)
    elif a.mode=='suite':
        cases=['V130RStep1MapTest','V130RStep2PlacementTest','V130RStep3PlacementTest','V130RStep4BattleTest','V130RStep5GradeFTest','V130RStep6FoodTest','V130RStep7MonstersTest','V130RStep9SpecTest','V130RStep10DCTest','V130RStep11StoryTest','V130RStep12HPBarTest','V130RStep13AchievementTest','SaveV4MigrationTest','SaveV5MigrationTest','EnglishTranslationTest','ChineseLocalizationTest','Update3DataContractTest','Update4DataContractTest','CampaignModePhase3Test','DuoLinksPhase24Test','Update4EndingsPhase32Test','Update4EndingsPhase33Test','PlayerContinuityTest']
        for case in cases:
            scene=ROOT/'tools/tests'/f'{case}.tscn'
            if not scene.exists(): continue
            run(case,['--scene','res://'+scene.relative_to(ROOT).as_posix(),'--','--checks-only','--mode=direct','--ach-mode=direct'])
