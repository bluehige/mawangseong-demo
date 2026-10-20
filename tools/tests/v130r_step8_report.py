"""Rebuild the Step8 report from actual battle rows; never invent missing trials."""
from pathlib import Path
import argparse
import json
import shutil
import subprocess
from statistics import mean

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step8'
WORKSPACE_DEST = ROOT / '_mockup/game_step8_balance'
EXTERNAL_MOCKUP = Path.home() / 'Desktop' / '진행중인프로젝트' / '_mockup'
DEST = EXTERNAL_MOCKUP / 'game_step8_balance' if (EXTERNAL_MOCKUP / 'game_step7_monsters').is_dir() else WORKSPACE_DEST
BOSSES = {15, 20, 21, 26, 30}
BASE_SHA = '35de2147fb75e097abefa5abf5d5436e627b8771'


def prepare(mode, days, trials, hz, name):
    LOCAL.mkdir(parents=True, exist_ok=True)
    config = {'name': name or ('baseline_rows' if mode == 'before' else mode),
              'days': days, 'trials': trials, 'hz': hz,
              'layouts': ['recommended', 'bad']}
    if mode == 'before':
        for source, destination in [('data/waves.json', 'waves_before.json'),
                                    ('scripts/map_builder/ApprovedMonsterPlacement.gd', 'MembersBefore.gd')]:
            data = subprocess.check_output(['git', 'show', f'{BASE_SHA}:{source}'], cwd=ROOT)
            (LOCAL / destination).write_bytes(data)
        config.update(baseline=True, waves='res://tmp/v130r_step8/waves_before.json')
    elif mode == 'capture':
        config.update(kkogit=True, capture=True, trials=1, layouts=['recommended'])
        config['days'] = days if days != list(range(1, 31)) else [7, 15, 30]
        rows = json.loads((LOCAL / 'after.json').read_text(encoding='utf-8'))
        config['seed_by_day'] = {}
        for day in config['days']:
            winners = [r for r in rows if r['day'] == day and r['layout'] == 'recommended' and r.get('win') and r['throne_hp'] < 1400]
            assert winners, ('no throne engagement to capture', day)
            selected = min(winners, key=lambda r: abs(100*r['throne_hp']/1500 - mean(targets(day)[1])))
            config['seed_by_day'][str(day)] = selected['trial']
    elif mode == 'direct':
        config.update(direct=True, days=[])
    (LOCAL / 'config.json').write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(config, ensure_ascii=False))


def targets(day):
    if day < 5:
        return (100, 100), (85, 95)
    if day < 15:
        return (90, 100), (60, 85)
    if day < 27:
        return (80, 95), ((45, 65) if day in BOSSES else (50, 75))
    return (70, 90), ((35, 55) if day == 30 else (40, 65))


def summarize(rows, day, layout):
    group = [r for r in rows if r['day'] == day and r['layout'] == layout]
    assert len(group) == 10, (day, layout, len(group))
    assert len({r['seed'] for r in group}) == 10
    assert not any(r['timeout'] for r in group), (day, layout, 'timeout')
    hp = [100 * r['throne_hp'] / r['throne_max'] for r in group]
    return dict(win=10 * sum(bool(r.get('win')) for r in group), hp=mean(hp),
                lo=min(hp), hi=max(hp), gold=mean(r['gold_loss'] for r in group),
                variance=len(set(round(h, 4) for h in hp)),
                thieves=max(r['thieves'] for r in group))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--prepare', choices=['before', 'after', 'capture', 'direct'])
    parser.add_argument('--days', default=','.join(map(str, range(1, 31))))
    parser.add_argument('--trials', type=int, default=10)
    parser.add_argument('--hz', type=int, default=60)
    parser.add_argument('--name')
    parser.add_argument('--allow-missing-captures', action='store_true')
    parser.add_argument('--require-targets', action='store_true')
    args = parser.parse_args()
    if args.prepare:
        prepare(args.prepare, [int(x) for x in args.days.split(',')], args.trials, args.hz, args.name)
        return
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'previews').mkdir(exist_ok=True)
    baseline_path = LOCAL / 'baseline_rows.json'
    old = json.loads(baseline_path.read_text(encoding='utf-8'))
    new = json.loads((LOCAL / 'after.json').read_text(encoding='utf-8'))
    assert len(old) == len(new) == 600
    assert all(r['simulation_hz'] == 60 for r in old+new), 'Final results must use the native 60Hz physics step.'
    assert all(r['baseline_recommendation'] for r in old), 'Before rows must use the pinned original recommendation.'
    assert not any(r['baseline_recommendation'] for r in new), 'After rows must use the revised recommendation.'
    final = json.loads((ROOT / 'data/waves.json').read_text(encoding='utf-8'))
    for row in new:
        assert row['wave_entries'] == final[f"day_{int(row['day'])}"], ('stale wave', row['day'], row['seed'])
    food_catalog = json.loads((ROOT / 'data/v130r/upkeep.json').read_text(encoding='utf-8'))['monsters']
    lines = ['# DAY 1~30 난이도 이전 / 이후', '',
             '실제 게임 전투·AI·피해·스킬을 사용한 날짜별 독립 시험. 날짜×배치 2종×seed 10회, 이전/이후 각600회 실행(이전 DAY29의20회는 무전투).',
             '승률은 10회 표본의 비율이며 실제 캠페인 모집단의 승률 추정이나 신뢰구간을 뜻하지 않는다. 패배 시 옥좌 0도 평균에 포함한다.',
             '기본 옥좌1500, 금1200, 마나600, 식량은 당일 수입 예산. 전문화·기억·승급·이월 부상/굶주림·칙령·수동 스킬 없음.',
             '기본4종과 모리/돌콩 계약, 신규는 join_day 도달분. 전선/의회 미완료이므로 24종 전원 출전 조건이 아니다.',
             '예상 Lv = 1 + floor((DAY − 합류 DAY)/3), 최소1. 기존4종/계약은 DAY1, 신규는 데이터 join_day. 레벨당 HP+20/공격+3/방어+1.',
             'DAY1~14 F, DAY15~30 E 지도. D/C 도면은 미확정. 몬스터 기본 스탯/스킬 수치는 바꾸지 않았다.',
             '나쁜 배치: 추천과 같은 병력을 한 병영 앞에 강제로 모은 스트레스 조건(중복 슬롯). 일반 UI 정원을 넘는 의도적 시험 배치로, 합법 수동 배치의 승률과 동일시할 수 없다.',
             '이전은 0102 원본 웨이브/추천, 이후는 최종 웨이브/추천. 이후에 무작위 생성시각 ±0.35초와 입구 갈림을 사용한다.',
             '프로젝트 기본 물리 갱신과 같은 1/60초 고정 간격을 사용한다. 초기 1/15초 후보는 1/30초 대조에서 차이가 확인돼 폐기했다. 원본 DAY29는 적0의 비전투일이므로 이전 표의100%/100%는 무전투 종료 값이다.', '',
             '| DAY | 목표 승률 / HP | 이전 추천 승률 / HP | 이후 추천 승률 / HP (최소~최대) | 추천 인원/유지비 이전→이후 | 이전 몰빵 승률 / HP | 이후 몰빵 승률 / HP | 금 손실 이전→이후 (추천 / 몰빵) | 곡선 |',
             '|---:|---|---|---|---|---|---|---|---|']
    failures = []
    summaries = []
    for day in range(1, 31):
        b, a = summarize(old, day, 'recommended'), summarize(new, day, 'recommended')
        bb, ab = summarize(old, day, 'bad'), summarize(new, day, 'bad')
        wr, hr = targets(day)
        ok = wr[0] <= a['win'] <= wr[1] and hr[0] <= a['hp'] <= hr[1]
        gold_ok = not a['thieves'] or 0 <= a['gold'] <= 150
        if not ok or not gold_ok:
            failures.append(dict(day=day, curve=ok, gold=gold_ok))
        gold = f"{b['gold']:.0f}→{a['gold']:.0f} / {bb['gold']:.0f}→{ab['gold']:.0f}" if a['thieves'] or ab['thieves'] else '—'
        old_roster = next(r['levels'] for r in old if r['day'] == day and r['layout'] == 'recommended')
        new_roster = next(r['levels'] for r in new if r['day'] == day and r['layout'] == 'recommended')
        upkeep = lambda roster: sum(food_catalog[k]['upkeep_food'] for k in roster)
        roster_text = f'{len(old_roster)}/{upkeep(old_roster)}→{len(new_roster)}/{upkeep(new_roster)}'
        lines.append(f"| {day} | {wr[0]}~{wr[1]}% / {hr[0]}~{hr[1]}% | {b['win']:.0f}% / {b['hp']:.1f}% | {a['win']:.0f}% / {a['hp']:.1f}% ({a['lo']:.1f}~{a['hi']:.1f}) | {roster_text} | {bb['win']:.0f}% / {bb['hp']:.1f}% | {ab['win']:.0f}% / {ab['hp']:.1f}% | {gold} | {'충족' if ok and gold_ok else '미달'} |")
        summaries.append(dict(day=day, before=b, after=a, before_bad=bb, after_bad=ab, curve_pass=ok, gold_pass=gold_ok))
    lines += ['', '## DAY별 가정 레벨', '', '| DAY | 기본4종·계약 Lv | 신규종 Lv |', '|---:|---:|---|']
    for day in range(1, 31):
        row = next(r for r in new if r['day'] == day and r['layout'] == 'recommended')
        extra = ', '.join(f'{k}:{v}' for k, v in row['levels'].items() if k not in ['slime', 'goblin', 'imp', 'kobold_scout', 'spore_healer', 'stone_sentinel'])
        lines.append(f"| {day} | {1+(day-1)//3} | {extra or '—'} |")
    bad_f_losses = sum(s['after_bad']['win'] < 100 for s in summaries if 5 <= s['day'] <= 14)
    actual_theft = sum(r['gold_loss'] for r in new if r['layout'] == 'recommended')
    assert bad_f_losses > 0, 'The requested bad-placement failure case was not observed.'
    assert actual_theft > 0, 'The requested real treasury loss was not observed.'
    lines += ['', f'F구간 몰빵 패배 발생 날짜: {bad_f_losses}/10. 추천 배치의 실제 금고 순손실 합계: {actual_theft}금.']
    verification_path = LOCAL / 'timestep30.json'
    if verification_path.exists():
        verification = json.loads(verification_path.read_text(encoding='utf-8'))
        lines += ['', '## 계산 간격 민감도 확인', '',
                  '아래는 같은 시드 3개의 60Hz→30Hz 비교다. 전체 30일 곡선 판정은 위의 60Hz·10시드 표이며, 이 소표는 간격 차이의 영향만 보여 준다.', '',
                  '| DAY | 같은 3시드 60Hz 승률 / HP | 30Hz 승률 / HP |', '|---:|---|---|']
        for day in [7, 15, 30]:
            group = [r for r in verification if r['day'] == day]
            assert len(group) == 3 and not any(r['timeout'] for r in group)
            for row in group:
                assert row['wave_entries'] == final[f'day_{day}'] and row['simulation_hz'] == 30
            seeds = {r['seed'] for r in group}
            original_group = [r for r in new if r['day'] == day and r['layout'] == 'recommended' and r['seed'] in seeds]
            text = lambda g: f"{100*mean(bool(r.get('win')) for r in g):.1f}% / {mean(100*r['throne_hp']/r['throne_max'] for r in g):.1f}%"
            lines.append(f'| {day} | {text(original_group)} | {text(group)} |')
    lines += ['', '## 판정', '', f'곡선/금 손실 미달 DAY: {failures or "없음"}.',
              f'추천 배치에서 HP가 seed별로 달라진 날짜: {sum(s["after"]["variance"] > 1 for s in summaries)}/30.',
              '사용자 확인 대기.', '']
    (DEST / 'balance_before_after.md').write_text('\n'.join(lines), encoding='utf-8')
    original = json.loads((LOCAL / 'waves_before.json').read_text(encoding='utf-8'))
    table = ['# 변경 수치', '', '| DAY / 행 / 적 | HP 배율 이전→이후 | 공격 배율 이전→이후 | 수 이전→이후 | 간격 이전→이후 | 생성 지연 이전→이후 | 목표/경로 |', '|---|---|---|---|---|---|---|']
    for day in range(1, 31):
        offset = int(final[f'day_{day}'][0].get('formation') == 'front_pressure')
        for index, r in enumerate(final[f'day_{day}']):
            old_index = index - offset
            previous = original[f'day_{day}'][old_index] if 0 <= old_index < len(original[f'day_{day}']) else {}
            val = lambda key, default: f"{previous.get(key, default) if previous else '—'}→{r.get(key, default)}"
            table.append(f"| {day}/{index+1}/{r['enemy_id']}{' (추가)' if not previous else ''} | {val('hp_scale',1)} | {val('atk_scale',1)} | {val('count',0)} | {val('spawn_interval',1.2)} | {val('spawn_delay',0)} | {r.get('formation','기본')}, 목표 전진 확률 {r.get('objective_priority',0):g} |")
    table += ['', '몬스터 기본 수치·스킬 수치: 변경 없음. 생성 jitter=±0.35초 및 경로 선택은 별도 전투 로직 변경.', '']
    (DEST / 'changed_values.md').write_text('\n'.join(table), encoding='utf-8')
    images = ['kkogit_battle'] + [f'battle_day{d}' for d in [7, 15, 30]]
    for name in images:
        p = LOCAL / f'{name}.png'
        if not p.exists() and args.allow_missing_captures:
            continue
        im = Image.open(p)
        assert im.size == (1920, 1080), (name, im.size)
        shutil.copy2(p, DEST / p.name)
        im.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        im.save(DEST / 'previews' / p.name)
    for source, name in [(baseline_path, 'before_rows.json'), (LOCAL / 'after.json', 'after_rows.json')]:
        shutil.copy2(source, DEST / name)
    evidence_files = [('timestep30.json', 'timestep30_rows.json'), ('captures.json', 'capture_rows.json'),
                      ('objective_checks.json', 'direct_checks.json'), ('asset_checks.json', 'asset_checks.json')]
    for source_name, name in evidence_files:
        source = LOCAL / source_name
        if source.exists():
            shutil.copy2(source, DEST / name)
    (DEST / 'summary.json').write_text(json.dumps({'summaries': summaries, 'target_misses': failures}, ensure_ascii=False, indent=2), encoding='utf-8')
    if DEST != WORKSPACE_DEST:
        WORKSPACE_DEST.mkdir(parents=True, exist_ok=True)
        (WORKSPACE_DEST / 'previews').mkdir(exist_ok=True)
        names = ['balance_before_after.md', 'changed_values.md', 'before_rows.json', 'after_rows.json', 'summary.json']
        names += [name for _, name in evidence_files]
        names += [f'{name}.png' for name in images] + [f'previews/{name}.png' for name in images]
        for name in names:
            source = DEST / name
            if source.is_file(): shutil.copy2(source, WORKSPACE_DEST / name)
    print(json.dumps({'trials': [len(old), len(new)], 'target_misses': failures}, ensure_ascii=False))
    if args.require_targets and failures:
        raise SystemExit('Requested curve targets remain unmet; inspect summary.json.')


if __name__ == '__main__':
    main()
