"""Check the exact achievements, image alpha, Windows DLLs and exported PCK index."""
import hashlib
import json
import struct
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '_mockup/game_step13_ach'
checks = []


def check(value, name):
    checks.append(dict(name=name, passed=bool(value)))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pck_index(path):
    with path.open('rb') as stream:
        assert stream.read(4) == b'GDPC'
        version, = struct.unpack('<I', stream.read(4))
        assert version == 3
        stream.seek(32)
        offset, = struct.unpack('<Q', stream.read(8))
        stream.seek(offset)
        count, = struct.unpack('<I', stream.read(4))
        names = []
        for _ in range(count):
            length, = struct.unpack('<I', stream.read(4))
            assert length < 100000
            names.append(stream.read(length).rstrip(b'\0').decode())
            stream.read(8+8+16+4)
        return names


catalog = json.loads((ROOT / 'data/v130r/achievements/achievements.json').read_text(encoding='utf8'))
design = json.loads((ROOT / 'assets/source/imagegen/achievements_v130/design/achievements_v130.json').read_text(encoding='utf8'))
check(len(catalog['achievements']) == len(design) == 100, '100 approved achievements')
check(len(catalog['sets']) == 8, '8 sets')
check(sum(row['hidden'] for row in catalog['achievements']) == 8, '8 hidden')
approved = {row['api_name']: row for row in design}
for row in catalog['achievements']:
    check(all(row[key] == value for key, value in approved[row['api_name']].items()), row['api_name']+' exact design fields')
    for locale in ['ko','en','zh_cn']:
        check(bool(row['name_'+locale]) and bool(row['desc_'+locale]), row['api_name']+' '+locale)
    icon = ROOT / row['icon_path'].removeprefix('res://')
    check(Image.open(icon).size == (256,256), row['api_name']+' icon 256px')
frame = Image.open(ROOT / 'assets/achievements/v130/toast_frame.png')
check(frame.mode == 'RGBA' and frame.getextrema()[3] == (0,255), 'toast native transparency preserved')
for name in ['ach_menu_ko','ach_menu_en','ach_toast','ach_progress']:
    check(Image.open(OUT / (name+'.png')).size == (1280,720), name+' individual reduced capture')
for mode in ['direct','capture','offline']:
    report = json.loads((OUT / (mode+'_checks.json')).read_text(encoding='utf8'))
    check(not report['failures'] and len(report['coverage']) == 100, mode+' 100/100 and no failures')
    check(not (ROOT / 'tmp/v130r_step13' / (mode+'.err.log')).read_text(encoding='utf8').strip(), mode+' stderr empty')
manifest = json.loads((ROOT / 'addons/godotsteam/PROVENANCE.json').read_text(encoding='utf8'))
for name, receipt in manifest['files'].items():
    check(sha(ROOT / name) == receipt['sha256'], 'official vendor hash '+name)
    if name.endswith('.dll'):
        check(receipt['sha256'] == receipt['official_sha256'], 'unmodified official DLL '+name)
export = ROOT / 'tmp/v130r_step13/export'
for name in ['libgodotsteam.windows.template_release.x86_64.dll','steam_api64.dll']:
    check(sha(export / name) == sha(ROOT / 'addons/godotsteam/win64' / name), 'Windows exported DLL '+name)
check(not list(export.rglob('steam_appid.txt')), 'no loose exported app ID')
names = pck_index(export / 'MawangCastle.pck')
check(not any('steam_appid' in name for name in names), 'no app ID inside PCK')
check(not any(name.startswith(('assets/source/','_mockup/','tools/','tmp/')) for name in names), 'no source/QA/test artifacts inside PCK')
for row in catalog['achievements']:
    check(row['icon_path'].removeprefix('res://')+'.import' in names, row['api_name']+' exported icon')
for name in ['data/v130r/achievements/runtime_rules.json','data/v130r/achievements/achievements.json','addons/godotsteam/godotsteam.gdextension']:
    check(name in names, 'exported '+name)
check(not (ROOT / 'tmp/v130r_step13/export_smoke.err.log').read_text(encoding='utf8').strip(), 'exported release boot stderr empty')
result = dict(checks=len(checks), failures=[row['name'] for row in checks if not row['passed']],
              exported_files=len(names), vendor=manifest, results=checks)
(OUT / 'artifact_checks.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
print(json.dumps({key: result[key] for key in ['checks','failures','exported_files']}))
raise SystemExit(bool(result['failures']))
