"""Assemble an already exported v1.3.0 payload; never call Steam or access user saves."""
import argparse
import csv
import hashlib
import importlib.util
import json
import re
import shutil
import struct
import subprocess
import sys
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
TEMPLATES = Path(__file__).resolve().parent


def digest(path, algorithm='sha256'):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, algorithm).hexdigest()


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding='utf-8')


def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def catalog_check(root):
    data = root / 'data/v130r/achievements'
    catalog = json.loads((data / 'achievements.json').read_text(encoding='utf-8'))
    rows = catalog['achievements']
    ids = {r['api_name'] for r in rows}
    stats = read_csv(data / 'stats.csv')
    stat_ids = {r['api_name'] for r in stats}
    assert len(rows) == len(ids) == 100
    assert len(stats) == len(stat_ids) == 20
    assert ids == set(json.loads((data / 'runtime_rules.json').read_text(encoding='utf-8')))
    definitions = read_csv(data / '5267750-achievements-definitions.template.csv')
    assert len(definitions) == 100 and {r['api_name'] for r in definitions} == ids
    assert {r['api_name'] for r in catalog['stats']} == stat_ids
    assert {r['progress_stat'] for r in rows if r['progress_stat']} == stat_ids
    assert {r['api_name'] for r in read_csv(data / 'steamworks_import.csv')} == ids
    localization = read_csv(data / '5267750-achievements-localization.csv')
    assert len(localization) == 200
    assert {(r['api_name'],r['field']) for r in localization} == {(i,f) for i in ids for f in ('name','description')}
    assert all(r[locale] for r in localization for locale in ('koreana','english','schinese'))
    assert sum(r['hidden'] for r in rows) == 8
    assert sum(r['spoiler'] == 'true' for r in definitions) == 8
    by_stat = {r['api_name']:r for r in stats}
    for row in definitions:
        if row['progress_stat_name']:
            stat = by_stat[row['progress_stat_name']]
            assert int(stat['min']) <= int(row['progress_stat_min']) < int(row['progress_stat_max']) <= int(stat['max'])
            assert row['permission'] == stat['permission'] == 'Client'
    # Runtime service reads this same catalog, rather than a second hardcoded list.
    assert 'res://data/v130r/achievements/achievements.json' in (root/'scripts/achievements/AchievementService.gd').read_text(encoding='utf-8')
    assert 'res://data/v130r/achievements/runtime_rules.json' in (root/'scripts/achievements/AchievementRules.gd').read_text(encoding='utf-8')
    for row in rows:
        icon = root / row['icon_path'].removeprefix('res://')
        assert icon.name == row['api_name'] + '_ACHIEVED.png'
        with icon.open('rb') as stream:
            header = stream.read(24)
        assert header[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',header[16:24]) == (256,256)
    return catalog, stats


def assemble(args):
    root, ready = args.source.resolve(), args.ready.resolve()
    sha = subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip()
    assert (root/'project.godot').is_file()
    assert 'config/version="1.3.0"' in (root/'project.godot').read_text(encoding='utf-8')
    ready.mkdir(parents=True, exist_ok=True)
    content, evidence = ready/'Content', ready/'Evidence'
    evidence.mkdir(exist_ok=True)
    (content/'licenses').mkdir(parents=True, exist_ok=True)
    for name in ('MawangCastle.exe','MawangCastle.pck','steam_api64.dll','libgodotsteam.windows.template_release.x86_64.dll'):
        assert (content/name).is_file(), name
    for name in ('NotoSansCJK_LICENSE.txt','NEXON_Maplestory_LICENSE.txt'):
        shutil.copy2(root/'assets/fonts'/name, content/'licenses'/name)
    shutil.copy2(args.godot_copyright, content/'licenses/Godot-COPYRIGHT.txt')
    shutil.copy2(root/'addons/godotsteam/license.md', content/'licenses/GodotSteam_LICENSE.txt')
    shutil.copy2(root/'legal/THIRD_PARTY_NOTICES.txt',content/'THIRD_PARTY_NOTICES.txt')
    for name in ('VerifyContent.py','Upload.py','Upload_1.3.0.cmd','START_HERE_KO.md',
                 'PATCH_NOTES_KO.txt','PATCH_NOTES_EN.txt','PATCH_NOTES_ZH_CN.txt'):
        shutil.copy2(TEMPLATES/name, ready/name)
    desc = 'v1.3.0 - ' + sha[:12]
    identity = dict(version='1.3.0',source_commit=sha,description=desc,steamcmd=str(args.steamcmd))
    write(ready/'Scripts/package_identity.json',json.dumps(identity,indent=2)+'\n')
    # Resolve content relative to the VDF. BuildOutput is absolute to avoid cwd ambiguity.
    vdf = '''"AppBuild"
{
    "AppID" "5267750"
    "Desc" "DESC"
    "ContentRoot" "../Content"
    "BuildOutput" "OUTPUT"
    "SetLive" ""
    "Depots"
    {
        "5267751"
        {
            "FileMapping" { "LocalPath" "*" "DepotPath" "." "Recursive" "1" }
            "FileExclusion" "steam_appid.txt"
            "FileExclusion" "*.pdb"
        }
    }
}
'''.replace('DESC',desc).replace('OUTPUT',(ready/'SteamPipeOutput').as_posix())
    write(ready/'Scripts/app_build_5267750.vdf',vdf)
    write(ready/'OpenSteamworksBuilds.cmd','@echo off\nstart "" "https://partner.steamgames.com/apps/builds/5267750"\n')
    achievements = ready/'Achievements'
    data = root/'data/v130r/achievements'
    (achievements/'data/v130r/achievements').mkdir(parents=True, exist_ok=True)
    for file in data.iterdir():
        if file.suffix in ('.json','.csv'):
            shutil.copy2(file, achievements/'data/v130r/achievements'/file.name)
    (achievements/'tools/achievements').mkdir(parents=True, exist_ok=True)
    shutil.copy2(root/'tools/achievements/prepare_steam_import.py',achievements/'tools/achievements/prepare_steam_import.py')
    for name in ('Make_Achievement_CSV.py','Make_Achievement_CSV.cmd','STEAMWORKS_ACHIEVEMENTS_KO.md'):
        shutil.copy2(TEMPLATES/name,achievements/name)
    catalog, stats = catalog_check(root)
    icons = achievements/'Icons'
    icons.mkdir(exist_ok=True)
    for row in catalog['achievements']:
        file = root/row['icon_path'].removeprefix('res://')
        shutil.copy2(file,icons/file.name)
    with zipfile.ZipFile(achievements/'Icons_100_ACHIEVED.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for file in sorted(icons.glob('*.png')):
            archive.write(file,file.name)
    # Official documentation lists these properties in this order; physical UI layout is unverified.
    fields = ['순서','Type','API Name','Set By','Increment Only','Max Change','Min Value','Max Value','Default Value','Aggregated']
    table = ['# 스탯20종 입력표','', '공식 속성 설명 순서입니다. 로그인한 Stats UI의 실제 필드 배치는 확인 필요입니다. ID는 Steam 자동 생성입니다.', '',
             '| '+' | '.join(fields)+' |','|'+'|'.join(['---']*len(fields))+'|']
    for i,row in enumerate(stats,1):
        table.append('| '+' | '.join(map(str,[i,row['type'],row['api_name'],row['permission'],'켜기','미설정',row['min'],row['max'],row['default'],'끄기']))+' |')
    table += ['', '표의 Max Value는 해제 목표가 아닌 스탯 저장 상한입니다. 통합 stats.csv는 Steam 자동 가져오기 파일이 아닙니다.',
              '', '공식 근거: https://partner.steamgames.com/doc/features/achievements?l=english (2026-10-19).']
    write(achievements/'STATS_20_INPUT_ORDER.md','\n'.join(table)+'\n')
    sets = ['# 추가 세트7개 이름','', '기본 캠페인은 기본 세트로 유지합니다. 아래7개만 만들고 실제 숫자 ID를 입력합니다.', '',
            '| ID 입력 키 | 한국어 | English | 简体中文 |','|---|---|---|---|']
    for row in catalog['sets']:
        if row['id'] != 'base_campaign':
            sets.append('| '+' | '.join(row[k] for k in ('id','name_ko','name_en','name_zh_cn'))+' |')
    write(achievements/'SETS_7_NAMES.md','\n'.join(sets)+'\n')
    vendor = json.loads((root/'addons/godotsteam/PROVENANCE.json').read_text(encoding='utf-8'))
    dlls = {}
    for name in ('steam_api64.dll','libgodotsteam.windows.template_release.x86_64.dll'):
        digest_expected = vendor['files']['addons/godotsteam/win64/'+name]['official_sha256']
        assert digest(content/name) == digest_expected
        dlls[name] = digest_expected
    artifacts = [dict(path=p.relative_to(content).as_posix(),bytes=p.stat().st_size,sha256=digest(p),sha1=digest(p,'sha1'))
                 for p in sorted(content.rglob('*')) if p.is_file() and p.name != 'steam-build-manifest.json']
    manifest = dict(version='1.3.0',source_commit=sha,branch='codex/v130r-defense-layout',export_preset='Windows Steam',
        godot='4.6.3.stable.official.7d41c59c4',steam_enabled=True,test_steam_block=False,
        app_id=5267750,depot_id=5267751,pe_version='1.3.0.0',vendor_dll_sha256=dlls,artifacts=artifacts)
    write(content/'steam-build-manifest.json',json.dumps(manifest,indent=2)+'\n')
    subprocess.run([sys.executable,str(ready/'VerifyContent.py')],check=True)
    spec = importlib.util.spec_from_file_location('pck_audit',REPO/'tools/release/validate_steam_release.py')
    audit = importlib.util.module_from_spec(spec);spec.loader.exec_module(audit)
    paths = audit.list_pck_paths(content/'MawangCastle.pck')
    forbidden = ('assets/source/','_mockup/','builds/','docs/','tools/','tmp/','output/','web_Demo/')
    assert not any(p.removeprefix('res://').startswith(forbidden) or 'steam_appid' in p for p in paths)
    assert not any('data/v130r/achievements/' in p and ('.csv' in p or '.translation' in p) for p in paths)
    assert any(p.endswith('data/v130r/achievements/achievements.json') for p in paths)
    assert any(p.endswith('data/v130r/achievements/runtime_rules.json') for p in paths)
    write(evidence/'pck-paths.json',json.dumps(paths,indent=2))
    zip_path = ready/('MawangCastle-v1.3.0-SteamContent-'+sha[:12]+'.zip')
    with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for file in sorted(content.rglob('*')):
            if file.is_file(): archive.write(file,file.relative_to(content).as_posix())
    with zipfile.ZipFile(zip_path) as archive:
        actual = {p.relative_to(content).as_posix():p for p in content.rglob('*') if p.is_file()}
        assert set(archive.namelist()) == set(actual)
        for name,file in actual.items():
            with archive.open(name) as stream:
                assert hashlib.file_digest(stream,'sha256').hexdigest() == digest(file)
    write(evidence/'package-checks.json',json.dumps(dict(result='TARGETED_PASS',source_commit=sha,achievement_api_count=100,
        stat_api_count=20,extra_set_count=7,icons_256x256=100,pck_entries=len(paths),no_achievement_csv_translation=True,
        zip_file=zip_path.name,zip_sha256=digest(zip_path),zip_bytes=zip_path.stat().st_size,zip_files=len(actual),
        steam_operations='NOT_RUN',godotsteam_provenance=vendor['archive_url']),indent=2))
    write(evidence/'expected-server-files.json',json.dumps([dict(path=n,bytes=p.stat().st_size,sha1=digest(p,'sha1'),sha256=digest(p)) for n,p in sorted(actual.items())],indent=2))
    http = f'''# 1.3.0 — Steamworks HTTP 전체 ZIP 업로드 (사용자 직접)

**아직 실행하지 않았습니다.** SteamCMD 로그인이 막힌 경우 사용하는 대안입니다. 두 경로로 중복 업로드하지 마세요.

파일: `{zip_path.name}` ({zip_path.stat().st_size:,} bytes)
SHA256: `{digest(zip_path)}`
Notes: `{desc}`
소스 SHA: `{sha}`

1. `OpenSteamworksBuilds.cmd`로 같은 Notes의 완료 빌드가 없는지 먼저 확인합니다. 이미 있으면 다시 올리지 않습니다.
2. 새 탭에서 https://partner.steamgames.com/apps/depotuploads/5267750 을 엽니다. **Depot5267751 / Standard** 전체 업로드를 선택하고 위 ZIP을 지정합니다. `Merge With Baseline`은 선택하지 않습니다. Standard의 현재 UI는 로그인하지 않아 **확인 필요**입니다(1.2.12 성공 선례를 따름).
3. Notes를 위 값으로 입력하고 `Upload`를 한 번 누릅니다. 실제 전송·처리 후 새 Depot Manifest를 확인합니다. 기존 완료 탭의 파일명만 바꾸는 것으로 새 업로드가 되지 않습니다.
4. `Commit` 화면에서 **Branch=`None`** 으로 한 번 완료합니다. 버튼·순서가 다르면 확인이 필요합니다. 새 BuildID와 Manifest를 기록합니다. default는 바뀌지 않습니다.
5. `Evidence/upload-result.txt`에 BuildID/Manifest/Notes/Branch=None을 기록합니다. Builds의 실제 서버 파일 목록을 `Evidence/expected-server-files.json`과 비교합니다. 업적 게시 후 원할 때만 default 지정·공지로 이어갑니다.

불명확하면 재전송/Commit을 반복하지 말고 Builds부터 확인합니다. ZIP은 Content 전체 {len(actual)}파일이며 EXE/PCK/DLL은 최상위, licenses는 하위 경로를 유지합니다. 준비 도구·세이브·로그·인증값은 들어 있지 않습니다.

공식 근거: https://partner.steamgames.com/doc/sdk/uploading , https://partner.steamgames.com/doc/sdk/updating/partial_depot (후자는 부분 갱신 문서이므로 Standard 전체 업로드 UI의 근거로 확대하지 않음). 확인일2026-10-19.
'''
    write(ready/'HTTP_UPLOAD_1.3.0_KO.md',http)
    print('READY PACKAGE:',ready,'\nSOURCE:',sha,'\nZIP:',zip_path.name)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',type=Path,required=True)
    parser.add_argument('--ready',type=Path,required=True)
    parser.add_argument('--steamcmd',type=Path,required=True)
    parser.add_argument('--godot-copyright',type=Path,required=True)
    assemble(parser.parse_args())
