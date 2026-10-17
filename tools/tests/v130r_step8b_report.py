"""Validate and report actual, paired native-60Hz legal concentration trials."""
from pathlib import Path
from statistics import mean
from collections import defaultdict
import argparse
import hashlib
import json
import shutil

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step8b'
DEST = ROOT / '_mockup/game_step8b_spread'
LAYOUTS = ['recommended', 'anchor_cluster', 'final_line', 'first_line', 'over_capacity']
LABELS = {'recommended': '추천', 'anchor_cluster': '병영·결계핵·옥좌 집중',
          'final_line': '최종선 집중', 'first_line': '1차선 집중', 'over_capacity': '정원초과 참고'}
FACILITIES = {'watchtower', 'bait_treasure', 'barracks', 'recovery_nest', 'ward_core'}
BOSSES = {15, 20, 21, 26, 30}


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def targets(day):
    if day < 27:
        return (80, 95), (45, 65) if day in BOSSES else (50, 75)
    return (70, 90), (35, 55) if day == 30 else (40, 65)


def actual_facility_events(row):
    return [e for e in row['facility_losses'] if e['building'] in FACILITIES]


def stats(rows):
    return dict(win=100 * mean(bool(r.get('win')) for r in rows),
                hp=100 * mean(r['throne_hp'] / r['throne_max'] for r in rows),
                gold=mean(r['gold_loss'] for r in rows),
                buildings=mean(len({e['building'] for e in actual_facility_events(r)}) for r in rows),
                disables=mean(len(actual_facility_events(r)) for r in rows),
                deployed=len(rows[0]['assignments']), upkeep=rows[0]['fixture']['upkeep'])


def validate_rows(rows, baseline=False):
    waves = read(LOCAL / 'waves_0105.json') if baseline else read(ROOT / 'data/waves.json')
    assert waves['day_29'] == [], 'DAY29 must remain a preparation-only day'
    pairs = set()
    for r in rows:
        key = (r['day'], r['layout'], r['trial'])
        assert key not in pairs, ('duplicate trial', key)
        pairs.add(key)
        assert r['day'] != 29 and r['simulation_hz'] == 60 and not r['timeout'], key
        assert r['seed'] == 130800 + r['trial'], key
        assert r['wave_entries'] == waves[f"day_{r['day']}"], ('stale waves', key)
        assert r['fixture']['legal'] == (r['layout'] != 'over_capacity'), key
        if r['layout'] != 'over_capacity':
            assert r['fixture']['upkeep'] <= r['fixture']['budget'], key
            for b, count in r['fixture']['counts'].items():
                assert count <= r['fixture']['capacity'][b] and count <= r['fixture']['slots'][b], key
    return pairs


def baseline_parity(rows):
    previous = read(ROOT / 'tmp/v130r_step8/after.json')
    indexed = {(r['day'], 'over_capacity' if r['layout'] == 'bad' else r['layout'], r['trial']): r
               for r in previous if r['day'] != 29}
    fields = ['win', 'throne_hp', 'duration', 'spawned', 'gold_loss', 'thefts', 'escaped',
              'levels', 'assignments', 'wave_entries', 'simulation_hz']
    checked = 0
    for row in rows:
        key = row['day'], row['layout'], row['trial']
        if key not in indexed:
            continue
        if row['wave_entries'] != indexed[key]['wave_entries']:
            continue
        for field in fields:
            assert row[field] == indexed[key][field], ('observation changed production behavior', key, field)
        checked += 1
    return checked


def groups(rows):
    grouped = defaultdict(list)
    for r in rows:
        grouped[r['day'], r['layout']].append(r)
    return grouped


def comparison(grouped, days):
    advantage = []
    for day in days:
        rec = stats(grouped[day, 'recommended'])
        for layout in LAYOUTS[1:4]:
            s = stats(grouped[day, layout])
            if s['win'] > rec['win'] or s['hp'] > rec['hp'] + 1e-8:
                advantage.append(dict(day=day, layout=layout, recommended=rec, concentration=s))
    return advantage


def preservation():
    initial = read(LOCAL / 'preservation.json')
    changed = [p for p, digest in initial.items()
               if not (ROOT / p).is_file() or hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != digest]
    assert not changed, ('existing worktree files changed', changed)
    return len(initial)


def merge_evidence(names, name):
    waves = read(ROOT / 'data/waves.json')
    selected, manifest = {}, []
    checked = 0
    fields = ['win', 'throne_hp', 'duration', 'spawned', 'skills', 'gold_loss', 'thefts',
              'escaped', 'assignments', 'levels', 'goals', 'facility_losses', 'road_traces']
    for source_name in names:
        path = LOCAL / source_name
        checks = read(LOCAL / (path.stem + '_checks.json'))
        assert not checks['failures'], (source_name, checks)
        stderr_path = LOCAL / (path.stem + '.err.log')
        stderr = stderr_path.read_text(encoding='utf-8')
        assert not any(marker in stderr for marker in ['ERROR:', 'SCRIPT ERROR', 'ObjectDB instances leaked']), (source_name, stderr)
        checked += checks['checks']
        accepted = 0
        for row in read(path):
            if row['day'] == 29 or row['wave_entries'] != waves[f"day_{row['day']}"]:
                continue
            key = row['day'], row['layout'], row['trial']
            if key in selected:
                for field in fields:
                    assert row[field] == selected[key][field], ('duplicate evidence disagrees', key, field)
                continue
            selected[key] = dict(row, evidence_source=source_name)
            accepted += 1
        manifest.append(dict(source=source_name, sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                             stderr_sha256=hashlib.sha256(stderr_path.read_bytes()).hexdigest(),
                             selected_rows=accepted, checks=checks['checks']))
    result = sorted(selected.values(), key=lambda r: (r['day'], LAYOUTS.index(r['layout']), r['trial']))
    assert len(result) == 750, ('incomplete final matrix', len(result))
    validate_rows(result)
    (LOCAL / f'{name}.json').write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    (LOCAL / f'{name}_checks.json').write_text(json.dumps(dict(checks=checked, failures=[], source_manifest=manifest), indent=2), encoding='utf-8')
    print(dict(merged_rows=len(result), source_manifest=manifest))


def verify_captures():
    split = read(LOCAL / 'split_route_day24_state.json')
    enemies = [u for u in split['units'] if u['faction'] == 'enemy' and u['alive']]
    assert any(u['goal'] == 'throne' and u['cell'][0] >= 8 for u in enemies)
    assert any((u['goal'] == 'bait_treasure' and u['cell'][1] >= 10) or
               (u['goal'] == 'ward_core' and u['cell'][0] >= 16) or
               (u['goal'] == 'vault' and u['cell'][0] >= 25 and u['cell'][1] >= 10)
               for u in enemies), 'Capture must show an actual side road beyond the entrance fork'
    crowd = read(LOCAL / 'crowded_fail_day27_state.json')
    assert crowd['fixture']['legal'] and sum(crowd['fixture']['counts'].values()) == 9
    assert any(e['building'] == 'recovery_nest' and e['disabled_until'] > crowd['time']
               for e in crowd['facility_losses']), 'Capture must show real recovery-nest loss'
    return dict(split_time=split['time'], crowded_time=crowd['time'], result='PASS')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('inputs', nargs='*')
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--name', default='matrix')
    parser.add_argument('--days', default='15,16,17,18,19,21,22,23,25,26,28')
    parser.add_argument('--layouts', default=','.join(LAYOUTS))
    parser.add_argument('--trials', type=int, default=10)
    parser.add_argument('--capture', action='store_true')
    parser.add_argument('--fixtures-only', action='store_true')
    parser.add_argument('--preparation-day', action='store_true')
    parser.add_argument('--fast-cosmetics', action='store_true')
    parser.add_argument('--route-checks', action='store_true')
    parser.add_argument('--merge', action='store_true')
    parser.add_argument('--reproduction', action='store_true')
    args = parser.parse_args()
    if args.merge:
        merge_evidence(args.inputs, args.name)
        return
    if args.prepare:
        config = dict(name=args.name, days=[int(d) for d in args.days.split(',') if d],
                      layouts=args.layouts.split(','), trials=args.trials, capture=args.capture,
                      fixtures_only=args.fixtures_only, preparation_day=args.preparation_day,
                      fast_cosmetics=args.fast_cosmetics, route_checks=args.route_checks)
        (LOCAL / 'config.json').write_text(json.dumps(config, indent=2), encoding='utf-8')
        print(config)
        return
    rows = [r for name in args.inputs for r in read(LOCAL / name)]
    for name in args.inputs:
        checks = read(LOCAL / (Path(name).stem + '_checks.json'))
        assert checks['checks'] > 0 and not checks['failures'], (name, checks)
    validate_rows(rows, args.reproduction)
    parity = baseline_parity(rows)
    grouped = groups(rows)
    days = [20, 24, 27, 30] if args.reproduction else [d for d in range(15, 31) if d != 29]
    modes = LAYOUTS[:4] if args.reproduction else LAYOUTS
    for day in days:
        for mode in modes:
            assert len(grouped[day, mode]) == 10, (day, mode, len(grouped[day, mode]))
            assert {r['trial'] for r in grouped[day, mode]} == set(range(10))
    advantages = comparison(grouped, days)
    curve_misses = []
    for day in days:
        s = stats(grouped[day, 'recommended']); wr, hp = targets(day)
        gold_ok = not any(r['thieves'] for r in grouped[day, 'recommended']) or 0 <= s['gold'] <= 150
        if not (wr[0] <= s['win'] <= wr[1] and hp[0] <= s['hp'] <= hp[1] and gold_ok):
            curve_misses.append(day)
    summary = dict(rows=len(rows), parity_rows=parity, advantages=advantages,
                   curve_misses=curve_misses, preserved_files=preservation())
    if args.reproduction:
        (LOCAL / 'reproduction_summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
        print(json.dumps(summary, ensure_ascii=False))
        return
    DEST.mkdir(parents=True, exist_ok=True)
    summary['captures'] = verify_captures()
    captured_rows = read(LOCAL / 'captures.json')
    captured_checks = read(LOCAL / 'captures_checks.json')
    assert len(captured_rows) == 2 and not captured_checks['failures']
    for captured in captured_rows:
        counterpart = next(r for r in rows if (r['day'], r['layout'], r['trial']) ==
                           (captured['day'], captured['layout'], captured['trial']))
        assert captured['captured']
        for field in ['win', 'throne_hp', 'duration', 'spawned', 'gold_loss', 'assignments', 'wave_entries']:
            assert captured[field] == counterpart[field], ('rendered battle differs', captured['day'], field)
    summary['captures']['parity_trials'] = len(captured_rows)
    audit = read(LOCAL / 'fixture_audit.json')
    audit_checks = read(LOCAL / 'fixture_audit_checks.json')
    assert len(audit) == 75 and not audit_checks['failures']
    assert {(r['day'], r['layout']) for r in audit} == set(grouped)
    for fixture in audit:
        counterpart = grouped[fixture['day'], fixture['layout']][0]
        for field in ['fixture', 'assignments']:
            assert fixture[field] == counterpart[field], ('fixture audit differs', fixture['day'], fixture['layout'], field)
    preparation = read(LOCAL / 'day29_preparation_checks.json')
    assert preparation['checks'] == 7 and not preparation['failures'] and preparation['day'] == 29
    assert not preparation['start_state']['can_start'] and preparation['start_state']['reason_code'] == 'management_only'
    routes = read(LOCAL / 'spread_route_checks.json')
    assert routes['checks'] == 78 and len(routes['visits']) == 12 and not routes['failures']
    summary['direct_checks'] = dict(fixtures=audit_checks['checks'], day29=7, routes=78)
    old_waves, final_waves = read(LOCAL / 'waves_0105.json'), read(ROOT / 'data/waves.json')
    assert old_waves.keys() == final_waves.keys()
    changes = []
    for day in range(1, 31):
        before, after = old_waves[f'day_{day}'], final_waves[f'day_{day}']
        assert len(before) == len(after), ('enemy groups changed', day)
        for index, (b, a) in enumerate(zip(before, after)):
            if b == a:
                continue
            keys = {k for k in b.keys() | a.keys() if b.get(k) != a.get(k)}
            assert keys and keys <= {'target_room_id', 'waypoint_room_id'}, ('unexpected balance change', day, index, keys)
            for field in sorted(keys):
                changes.append(dict(day=day, index=index, enemy=a['enemy_id'], count=a['count'], field=field,
                                    before=b.get(field, '기존 목표·경유 규칙'), after=a[field]))
    summary['wave_changes'] = changes
    for filename in ['fast_parity_summary.json', 'kernel_parity_summary.json']:
        result = read(LOCAL / filename)
        assert result['result'] == 'PASS' and result['trials'] == 16, filename
    cleanup = read(LOCAL / 'cleanup_summary.json')
    assert cleanup['result'] == 'PASS', 'Test teardown cleanup must retain identical battle results'
    lines = ['# Step8B 합법 집중 배치 비교', '',
             '기준 0105: 414c8881b7f7664563e8843f29e8c4adc8286602. E 지도, 날짜별 독립 스냅샷, 기본 물리 60Hz, seed130800~130809의 대응 비교.',
             '각 전투일×배치5종×10회. 승률은 표본 비율이며 실제 누적 캠페인 승률의 추정값이 아니다. 패배의 옥좌HP0도 평균에 포함한다.',
             '0104 곡선과 함께 도둑 등장일의 추천 금고 순손실 평균0~150금 조건도 유지한다.',
             '성장·소유·식량·자원은0104와 동일: Lv=1+floor((DAY−합류DAY)/3), 기본4종과 모리/돌콩 계약DAY1, 신규는join_day, 전문화/기억/승급/수동스킬/이월부상 없음. 옥좌1500, 금1200, 마나600.',
             '시설은0104와 같은 기본E배치·Lv1이며 강화·이동·증설은 하지 않는다. 9/6/5명은 이 조건의 최대 집중 인원이며 강화 이후의 최대 정원까지 일반화하지 않는다.',
             '추천과 동일한 실제 해금 명단에서 역할 우선순위와 식량 한도를 유지해 대상 수비 칸을 최대한 채운다. 들어가지 못하는 병력은 대기한다. 슬롯 중복·정원 초과·무료 추가 병력 없음.',
             '집중① 병영·결계핵·옥좌의 고유 칸만 사용. 집중② 실제 방어선 태그final의 칸만 사용. 집중③ 실제 방어선 태그1의 칸만 사용. 건물·길·정원은 이동/확장하지 않는다.',
             '정원초과 열은0104의 배치 조건(추천 병력 전원을 병영4칸에 중복 배치)을 최종 웨이브로 재실행한 불법 스트레스 참고값으로, 합법 배치 판정에서 제외한다.',
             '각 셀: **승률% / 평균 옥좌HP% / 금고 순손실(금) / 무력화된 고유 시설 수(평균)**. 시설 손실은 실제 일시 무력화이며 영구 파괴로 표기하지 않는다. 고정 입구·옥좌·금고는 시설 무력화 집계에서 제외한다.', '',
             '| DAY | 목표 승률/HP | 추천 | 집중① 병영·결계핵·옥좌 | 집중② 최종선 | 집중③ 1차선 | 정원초과 참고 | 추천 우위 / 곡선 |',
             '|---:|---|---|---|---|---|---|---|']
    for day in range(15, 31):
        if day == 29:
            lines.append('| 29 | 준비일(전투 없음) | — | — | — | — | — | 전투 통계 제외 |')
            continue
        ss = [stats(grouped[day, m]) for m in LAYOUTS]
        text = lambda s: f"{s['win']:.0f} / {s['hp']:.1f} / {s['gold']:.0f} / {s['buildings']:.1f}"
        wr, hp = targets(day)
        advantage = any(a['day'] == day for a in advantages)
        lines.append(f"| {day} | {wr[0]}~{wr[1]}% / {hp[0]}~{hp[1]}% | " + ' | '.join(text(s) for s in ss) + f" | {'미달' if advantage else '충족'} / {'미달' if day in curve_misses else '충족'} |")
    lines += ['', '## 배치별 출전 인원 / 식량 유지비', '', '| DAY | 추천 | 집중① | 집중② | 집중③ | 정원초과 |', '|---:|---|---|---|---|---|']
    for day in days:
        ss = [stats(grouped[day, m]) for m in LAYOUTS]
        lines.append(f'| {day} | ' + ' | '.join(f"{s['deployed']}명 / {s['upkeep']}" for s in ss) + ' |')
    lines += ['', '## 판정', '',
              f'- 합법 집중의 승률 또는 평균 옥좌HP 우위: {advantages or "없음"}.',
              f'- 추천0104 목표 곡선 이탈: {curve_misses or "없음"}.',
              f'- 재실행 {len(rows)}행, 0104 추천/정원초과 시드별 핵심 필드 일치 {parity}행, 기존 혼합 파일 {summary["preserved_files"]}개 바이트 보존.',
              '- DAY29 웨이브·준비일 게이트·스토리 변경 없음. 적 목표·경유만 분산했다. 적 수·체력·공격력·스킬·생성 시각과 아군 수치는 그대로다.',
              '- 전체 회귀·전체 플레이·성능·export·별도 검수 에이전트는 요청 범위 밖으로 실행하지 않았다.',
              '- 사용자 확인 대기.', '', '## 적용한 최소 변경', '',
              '| DAY / 웨이브 행(1부터) | 적 / 수 | 변경 필드 | 이전 | 이후 |', '|---|---|---|---|---|']
    for change in changes:
        lines.append(f"| {change['day']} / {change['index']+1} | {change['enemy']} / {change['count']} | {change['field']} | {change['before']} | {change['after']} |")
    lines += ['', '과밀 페널티(b)·아이콘·새 범위 공격 적/스킬(c)은 추가하지 않았다.', '',
              '## 1차 재현과 최종 비교', '',
              '| DAY | 0105 추천 승률/HP | 0105 합법 집중① 승률/HP | 최종 추천 승률/HP | 최종 합법 집중① 승률/HP |',
              '|---:|---|---|---|---|']
    reproduction = groups(read(LOCAL / 'reproduction.json'))
    for key, group in groups([r for r in read(LOCAL / 'matrix_candidates.json') if not r.get('candidate_id')]).items():
        if key not in reproduction:
            reproduction[key] = group
    for day in sorted({20, 24, 27, 30} | {change['day'] for change in changes}):
        ss = [stats(reproduction[day, 'recommended']), stats(reproduction[day, 'anchor_cluster']),
              stats(grouped[day, 'recommended']), stats(grouped[day, 'anchor_cluster'])]
        lines.append(f'| {day} | ' + ' | '.join(f"{s['win']:.0f}% / {s['hp']:.1f}%" for s in ss) + ' |')
    lines += ['', '화면 효과 생략 경로16회 및 새 경유 옵션을 사용하지 않는 경로16회가 각각 기존 계산과15개 필드(승패·HP·시간·스킬·실제 길·시설 손실 등)에서 일치했다. 미변경 날짜의 행은 이 기본 동작 일치를 확인한 뒤 재사용했다. 투사체 도착·피해 콜백과 기본60Hz 계산은 유지한다. 캡처에는 화면 효과를 생략하지 않는다.', '']
    (DEST / 'result_table.md').write_text('\n'.join(lines), encoding='utf-8')
    (DEST / 'trial_rows.json').write_text(json.dumps(rows, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    (DEST / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
    for name in ['reproduction.json', 'reproduction_summary.json', 'fast_parity_summary.json', 'kernel_parity_summary.json',
                 'fixture_audit.json', 'fixture_audit_checks.json', 'day29_preparation_checks.json', 'spread_route_checks.json',
                 'cleanup_summary.json', 'captures.json', 'captures_checks.json']:
        assert (LOCAL / name).is_file(), ('missing required verification evidence', name)
        shutil.copy2(LOCAL / name, DEST / name)
    shutil.copy2(LOCAL / 'final_rows_checks.json', DEST / 'verification_manifest.json')
    for name in ['split_route_day24', 'crowded_fail_day27']:
        source = LOCAL / f'{name}.png'
        assert source.is_file(), ('missing requested capture', name)
        shutil.copy2(source, DEST / source.name)
        preview = DEST / 'previews'; preview.mkdir(exist_ok=True)
        im = Image.open(source)
        assert im.size == (1920, 1080), (name, im.size)
        im.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        im.save(preview / source.name)
        shutil.copy2(LOCAL / f'{name}_state.json', DEST / f'{name}_state.json')
    external = Path.home() / 'Desktop' / '진행중인프로젝트' / '_mockup'
    if external.is_dir():
        shutil.copytree(DEST, external / DEST.name, dirs_exist_ok=True)
    print(json.dumps(summary, ensure_ascii=False))
    assert not advantages and not curve_misses, 'Requested comparison target remains unmet'


if __name__ == '__main__':
    main()
