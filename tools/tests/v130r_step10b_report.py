"""Report paid D/C benchmarks without changing outcomes or combat data."""
from pathlib import Path
import json
import subprocess
import argparse
from v130r_step10_report import metrics as legacy_metrics, target, DAYS, MODES

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '_mockup/game_step10b_dc_spread'
PROBLEM_DAYS = [20, 21, 22, 23, 24, 26, 27]
BASE_SHA = '18931a116c5562c2bddd12be08da76882e6c1921'


def metrics(rows):
    assert rows and all(r['throne_max'] == 1500 for r in rows)
    result = legacy_metrics(rows)
    # Average integer HP first so exact target boundaries remain exact.
    result['hp'] = sum(r['throne_hp'] for r in rows) / len(rows) / 15
    return result


def read(name):
    return json.loads((OUT / name).read_text(encoding='utf-8-sig'))


def prepare(args):
    dest = ROOT / 'tmp/v130r_step10b'
    dest.mkdir(parents=True, exist_ok=True)
    reference = subprocess.check_output(['git', 'show', BASE_SHA + ':data/waves.json'], cwd=ROOT, encoding='utf-8')
    (dest / 'reference_waves.json').write_text(reference, encoding='utf-8')
    config = dict(name=args.name, days=[int(d) for d in args.days.split(',')], layouts=args.layouts.split(','), trials=args.trials, omit_achievement_observers=not args.keep_achievement_observers)
    if args.route == 'paid': config['waves'] = 'res://tmp/v130r_step10b/reference_waves.json'
    if args.route != 'paid':
        waves = json.loads(reference)
        for day in PROBLEM_DAYS:
            grade = 'D' if day < 27 else 'C'
            rows = waves[f'day_{day}']
            row = next(r for r in rows if r['enemy_id'] == 'investigator') if args.route in ['scout', 'siege_scout'] else rows[1]
            sites = ['watchtower_2', 'bait_treasure_2']
            if args.route == 'upper': sites[1] = row.get('waypoint_room_id', '')
            if args.route == 'lower': sites[0] = row.get('waypoint_room_id', '')
            row.setdefault('grade_routes', {}).setdefault(grade, {})['waypoint_room_ids'] = sites
            if args.route == 'siege_scout': row['grade_routes'][grade]['attack_throne'] = True
        wave_path = dest / (args.route + '_routes.json')
        wave_path.write_text(json.dumps(waves, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        config['waves'] = 'res://' + wave_path.relative_to(ROOT).as_posix()
    (dest / 'config.json').write_text(json.dumps(config, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(config))


def bounded_partial(ms, baseline, curve):
    rec, base = ms['recommended'], baseline['recommended']
    return (curve and rec['win'] >= base['win'] and rec['hp'] + .000001 >= base['hp']
            and (rec['win'] > base['win'] or rec['hp'] > base['hp'] + .000001)
            and rec['gold'] <= base['gold']
            and all(m['win'] - rec['win'] <= baseline[mode]['win'] - base['win'] + .000001
                    and m['hp'] - rec['hp'] <= baseline[mode]['hp'] - base['hp'] + .000001
                    for mode, m in ms.items() if mode != 'recommended'))


def anchor_repair(ms, baseline, curve):
    """Resolve the user's primary cluster while retaining the approved curve.

    Preserve every already-won comparison and never enlarge an unresolved
    concentration advantage. Absolute HP may move within the approved curve.
    """
    rec, base = ms['recommended'], baseline['recommended']
    anchor = ms['anchor_cluster']
    if not curve or rec['win'] < anchor['win'] or rec['hp'] + .000001 < anchor['hp']:
        return False
    for mode, other in ms.items():
        if mode == 'recommended': continue
        old = baseline[mode]
        was_ahead = base['win'] >= old['win'] and base['hp'] + .000001 >= old['hp']
        now_ahead = rec['win'] >= other['win'] and rec['hp'] + .000001 >= other['hp']
        if was_ahead and not now_ahead: return False
        if not was_ahead and (other['win'] - rec['win'] > old['win'] - base['win'] + .000001
                              or other['hp'] - rec['hp'] > old['hp'] - base['hp'] + .000001):
            return False
    return True


def select_routes(name, alternate='upper_trials'):
    rows = read(name + '.json') if (OUT / (name + '.json')).exists() else []
    baseline = read('paid_baseline.json')
    second = read(alternate + '.json') if (OUT / (alternate + '.json')).exists() else []
    assert len(rows) == len({(r['day'], r['layout'], r['trial']) for r in rows})
    assert all(not r['timeout'] and r['fixture']['legal'] for r in rows)
    assert len(second) == len({(r['day'], r['layout'], r['trial']) for r in second})
    assert all(not r['timeout'] and r['fixture']['legal'] for r in second)
    assert len(baseline) == len({(r['day'], r['layout'], r['trial']) for r in baseline}) == 400
    assert all(not r['timeout'] and r['fixture']['legal'] for r in baseline)
    source = json.loads(subprocess.check_output(['git', 'show', BASE_SHA + ':data/waves.json'], cwd=ROOT, encoding='utf-8'))
    selection = dict(accepted_days=[], partial_improvement_days=[], rejected_days=[], construction_resolves_days=[], alternate_candidate=alternate, decisions={})
    for day in PROBLEM_DAYS:
        base_groups = {mode: [r for r in baseline if r['day'] == day and r['layout'] == mode] for mode in MODES}
        candidate_groups = {mode: [r for r in rows if r['day'] == day and r['layout'] == mode] for mode in MODES}
        candidate_complete = all(len(group) == 10 for group in candidate_groups.values())
        candidate_ms = {mode: metrics(group) for mode, group in candidate_groups.items() if group}
        groups = candidate_groups if candidate_complete else base_groups
        assert all(len(group) == 10 for group in groups.values())
        assert all(len(group) == 10 for group in base_groups.values())
        for mode in MODES:
            for a in candidate_groups[mode]:
                b = next(r for r in base_groups[mode] if r['trial'] == a['trial'])
                assert all(a[key] == b[key] for key in ['buildings', 'wallet', 'assignments', 'levels', 'fixture'])
            for a, b in zip(sorted(groups[mode], key=lambda r: r['trial']), sorted(base_groups[mode], key=lambda r: r['trial'])):
                assert all(a[key] == b[key] for key in ['buildings', 'wallet', 'assignments', 'levels', 'fixture'])
        ms = {mode: metrics(group) for mode, group in groups.items()}
        base_ms = {mode: metrics(group) for mode, group in base_groups.items()}
        rec = ms['recommended']
        lo, hi, hlo, hhi = target(day)
        curve = lo <= rec['win'] <= hi and hlo <= rec['hp'] <= hhi and rec['gold'] <= 150
        dominates = all(rec['win'] >= m['win'] and rec['hp'] + .000001 >= m['hp'] for mode, m in ms.items() if mode != 'recommended')
        base_rec, base_anchor = base_ms['recommended'], base_ms['anchor_cluster']
        needs_spread = base_anchor['win'] > base_rec['win'] or base_anchor['hp'] > base_rec['hp'] + .000001
        base_curve = lo <= base_rec['win'] <= hi and hlo <= base_rec['hp'] <= hhi and base_rec['gold'] <= 150
        base_dominates = all(base_rec['win'] >= m['win'] and base_rec['hp'] + .000001 >= m['hp'] for mode, m in base_ms.items() if mode != 'recommended')
        if base_curve and base_dominates: selection['construction_resolves_days'].append(day)
        variant = 'scout'
        second_groups = {mode: [r for r in second if r['day'] == day and r['layout'] == mode] for mode in MODES}
        second_ms = {mode: metrics(group) for mode, group in second_groups.items() if group}
        second_complete = all(len(group) == 10 for group in second_groups.values())
        for mode in MODES:
            for a in second_groups[mode]:
                b = next(r for r in base_groups[mode] if r['trial'] == a['trial'])
                assert all(a[key] == b[key] for key in ['buildings', 'wallet', 'assignments', 'levels', 'fixture'])
        if needs_spread and not (curve and dominates) and second_complete:
            candidate = second_ms['recommended']
            second_curve = lo <= candidate['win'] <= hi and hlo <= candidate['hp'] <= hhi and candidate['gold'] <= 150
            second_dominates = all(candidate['win'] >= m['win'] and candidate['hp'] + .000001 >= m['hp'] for mode, m in second_ms.items() if mode != 'recommended')
            second_partial = bounded_partial(second_ms, base_ms, second_curve)
            current_partial = bounded_partial(ms, base_ms, curve)
            second_anchor = anchor_repair(second_ms, base_ms, second_curve)
            current_anchor = anchor_repair(ms, base_ms, curve)
            if ((second_curve and second_dominates)
                    or (second_anchor and (not current_anchor or (candidate['win'], candidate['hp']) > (rec['win'], rec['hp'])))
                    or (second_partial and not current_anchor and (not current_partial or (candidate['win'], candidate['hp']) > (rec['win'], rec['hp'])))):
                groups, ms, curve, dominates, variant = second_groups, second_ms, second_curve, second_dominates, alternate
        rec = ms['recommended']
        # A bounded partial result must preserve/repair the curve and improve
        # recommendation without enlarging any relative concentration advantage.
        # It is still explicitly short of the user's complete resolution goal.
        primary_repair = needs_spread and anchor_repair(ms, base_ms, curve)
        metric_improvement = needs_spread and bounded_partial(ms, base_ms, curve)
        partial_repair = primary_repair or metric_improvement
        partial_reason = 'anchor_resolved_other_cluster_remains' if primary_repair and not dominates else 'bounded_metric_improvement' if metric_improvement and not dominates else ''
        source_file = (name if variant == 'scout' else alternate) + '.json'
        selection['decisions'][day] = dict(curve=curve, dominates=dominates, needs_spread=needs_spread, baseline_curve=base_curve, baseline_dominates=base_dominates, baseline_metrics=base_ms, metrics=ms, variant=variant, source_file=source_file, partial_repair=partial_repair, partial_reason=partial_reason, candidate_metrics=candidate_ms, candidate_complete=candidate_complete, second_attempt_metrics=second_ms, second_attempt_complete=second_complete)
        if needs_spread and curve and (dominates or partial_repair):
            selection['accepted_days'].append(day)
            if partial_repair and not dominates: selection['partial_improvement_days'].append(day)
            # Preserve every original numeric literal, copying only the route.
            grade = 'D' if day < 27 else 'C'
            for old, measured in zip(source[f'day_{day}'], groups['recommended'][0]['wave_entries']):
                assert {k: v for k, v in old.items() if k != 'grade_routes'} == {k: v for k, v in measured.items() if k != 'grade_routes'}
                a, b = old.get('grade_routes', {}).get(grade, {}), measured.get('grade_routes', {}).get(grade, {})
                assert {k: v for k, v in old.get('grade_routes', {}).items() if k != grade} == {k: v for k, v in measured.get('grade_routes', {}).items() if k != grade}
                for field in set(a) | set(b):
                    if a.get(field) == b.get(field): continue
                    assert field in ['waypoint_room_ids', 'attack_throne'] and field in b
                    old.setdefault('grade_routes', {}).setdefault(grade, {})[field] = b[field]
        else:
            selection['rejected_days'].append(day)
    (ROOT / 'tmp/v130r_step10b/selected_waves.json').write_text(json.dumps(source, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (OUT / 'selection.json').write_text(json.dumps(selection, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(selection, ensure_ascii=False, indent=2))


def compose(name):
    selection = read('selection.json')
    paid = read('paid_baseline.json')
    rows = []
    for day in DAYS:
        if day not in selection['accepted_days']: pool = paid
        else: pool = read(selection['decisions'][str(day)]['source_file'])
        rows.extend(r for r in pool if r['day'] == day)
    assert len(rows) == len({(r['day'], r['layout'], r['trial']) for r in rows}) == 400
    production = json.loads((ROOT / 'data/waves.json').read_text(encoding='utf-8'))
    assert all(r['wave_entries'] == production[f"day_{int(r['day'])}"] for r in rows)
    rows.sort(key=lambda r: (r['day'], MODES.index(r['layout']), r['trial']))
    (OUT / 'final_rows.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Composed 400 unique rows matching production waves.')


def report(name, wave_source='data/waves.json'):
    rows = read(name + '.json')
    economy = read('economy.json')
    summary = {}
    issues = []
    checks = dict(rows=len(rows), unique=len({(r['day'], r['layout'], r['trial']) for r in rows}))
    checks['complete'] = checks['rows'] == checks['unique'] == 400
    checks['legal'] = all(r['fixture']['legal'] and r['fixture']['upkeep'] <= r['fixture']['budget'] for r in rows)
    checks['no_timeout'] = all(not r['timeout'] and isinstance(r.get('win'), bool) for r in rows)
    checks['native_hz_seed'] = all(r['simulation_hz'] == 60 and r['seed'] == 130800 + r['trial'] and r['trial'] in range(10) for r in rows)
    checks['finite_hp_duration'] = all(0 <= r['throne_hp'] <= 1500 and 0 < r.get('duration', 0) <= 360 for r in rows)
    checks['correct_map'] = all(r['day'] in DAYS and r['grade'] == ('D' if r['day'] < 27 else 'C') and len(r['buildings']) == len(economy['layouts'][r['grade']]['buildings']) for r in rows)
    checks['no_free_upgrades'] = all(b['level'] == 1 for r in rows for b in r['buildings'])
    checks['settled_daily_budget'] = all(all(r['wallet'][key] == economy['daily_wallets'][str(int(r['day']))][key] for key in ['gold', 'mana']) for r in rows)
    waves = json.loads((ROOT / wave_source).read_text(encoding='utf-8'))
    product_waves = json.loads((ROOT / 'data/waves.json').read_text(encoding='utf-8'))
    checks['runtime_waves_match'] = all(r['wave_entries'] == waves[f"day_{int(r['day'])}"] for r in rows)
    checks['product_uses_trial_waves'] = product_waves == waves
    checks['day29_empty'] = waves['day_29'] == [] and all(r['day'] != 29 for r in rows)
    checks['equal_ownership_wallet'] = True
    lines = ['# Step10B D/C 유료 추천 건설·분산 비교 — 사용자 확인 대기', '',
             '**최종 비교: 제품의 현재 경로 기준**' if checks['product_uses_trial_waves'] else '**미채택 경유 후보의 격리 시험 결과. 제품 waves.json에는 이 후보를 적용하지 않았다.**', '',
             f'60Hz, seed130800~130809, 실측 {len(rows)}/400회, 날짜·배치당 목표 10회. DAY20~26 D / DAY27~30 C.',
             '0104/0106 명단·레벨·식량·옥좌1500을 유지한 날짜별 독립 전투다. 전문화·기억·수동 스킬·합동기 보너스 없음.',
             '네 배치는 같은 유료 건물·금·마나·해금 명단을 보유하며, 실제 칸과 정원에 따라 출전/대기를 나눈다.',
             '표의 값: 승률 / 패배0 포함 평균 옥좌HP / 평균 금고 순손실 / 고유 시설 일시 무력화 수.', '',
             '| DAY/지도 | 0104/0106 목표 승률 / HP | 추천 | 집중① 병영·결계핵·옥좌 | 집중② 최종선 | 집중③ 1차선 | 곡선 / 추천 우위 |',
             '|---|---|---|---|---|---|---|']

    def cell(m):
        if not m: return '미측정'
        suffix = f" [n={m['n']}/10]" if m['n'] != 10 else ''
        return f"{m['win']:.0f}% / {m['hp']:.2f}% / {m['gold']:.0f}금 / {m['facilities']:.1f}개" + suffix

    for day in range(20, 31):
        if day == 29:
            lines.append('| 29/C | 준비일 | — | — | — | — | 전투 없음 |')
            continue
        selected = [r for r in rows if r['day'] == day]
        # Godot resumes JSON numbers as floats: 1 and 1.0 are equal ownership.
        checks['equal_ownership_wallet'] &= all(r['buildings'] == selected[0]['buildings'] and r['wallet'] == selected[0]['wallet'] for r in selected)
        ms = {mode: metrics([r for r in selected if r['layout'] == mode]) for mode in MODES if any(r['layout'] == mode for r in selected)}
        summary[str(day)] = ms
        lo, hi, hlo, hhi = target(day)
        rec = ms.get('recommended', {})
        curve = bool(rec and rec['n'] == 10 and lo <= rec['win'] <= hi and hlo <= rec['hp'] <= hhi and rec['gold'] <= 150)
        better = bool(rec and len(ms) == 4 and all(m['n'] == 10 and m['win'] <= rec['win'] and m['hp'] <= rec['hp'] + .000001 for k, m in ms.items() if k != 'recommended'))
        if not curve or not better:
            issues.append(dict(day=day, curve=curve, superiority=better))
        curve_label = '충족' if curve else '미충족' if rec and rec['n'] == 10 else '미측정'
        better_label = '충족' if better else '미충족' if len(ms) == 4 and all(m['n'] == 10 for m in ms.values()) else '미측정'
        lines.append(f"| {day}/{'D' if day < 27 else 'C'} | {lo}~{hi}% / {hlo}~{hhi}% | " + ' | '.join(cell(ms.get(k)) for k in MODES) + f" | {curve_label} / {better_label} |")
    checks['curve'] = not any(not i['curve'] for i in issues)
    checks['recommendation_dominates'] = not any(not i['superiority'] for i in issues)
    checks['issues'] = issues
    checks['construction_paid'] = len(economy['purchases']) == 4 and all(p['ok'] == p['affordable'] and all(p['before'][k] - p['after'][k] == (p['cost'].get(k, 0) if p['ok'] else 0) for k in ['gold', 'mana']) for p in economy['purchases'])
    checks['native_zero_passive_income'] = economy['economy_version'] == 3 and all(s['daily_income'] == {'gold': 0, 'mana': 0} and s['next'] == s['settled'] for s in economy['settlements'])
    before = json.loads(subprocess.check_output(['git', 'show', '18931a116c5562c2bddd12be08da76882e6c1921:data/waves.json'], cwd=ROOT, encoding='utf-8'))
    changes = []
    allowed = {'waypoint_room_id', 'waypoint_room_ids', 'target_room_id', 'throne_door', 'attack_throne', 'attack_throne_lane', 'objective_priority', 'route_variation'}
    for day, entries in waves.items():
        for i, entry in enumerate(entries):
            old = before[day][i]
            for key in set(old) | set(entry):
                if old.get(key) == entry.get(key):
                    continue
                if key != 'grade_routes':
                    changes.append((day, i, key, False))
                    continue
                for grade in set(old.get(key, {})) | set(entry.get(key, {})):
                    a, b = old.get(key, {}).get(grade, {}), entry.get(key, {}).get(grade, {})
                    for field in set(a) | set(b):
                        if a.get(field) != b.get(field):
                            changes.append((day, i, grade + '.' + field, grade in ['D', 'C'] and field in allowed and int(day[4:]) in [20, 21, 22, 23, 24, 26, 27]))
    checks['only_routing_changes'] = all(c[-1] for c in changes) and set(waves) == set(before) and all(len(v) == len(before[k]) for k, v in waves.items())
    checks['wave_changes'] = changes
    lines += ['', '## 건설·승급 예산', '',
              '개인 세이브는 접근하지 않았다. 0104/0106의 DAY19 전투 전 금1200·마나600 시험 상태를 시작점으로 삼았다.',
              'DAY19와 DAY20~28의 첫 승리 시드에서 실제 격퇴 보상·약탈 보너스·금고 손실을 관찰하고 기존 자원 정산 함수와 지도 전용 등급 진행 함수를 적용했다. 지도 전용 날짜 이동은 일반 캠페인의 금32/마나18 수입을 지급하지 않는다.',
              '이는 누적 캠페인의 생존·HP·성장 검증이 아닌 자원 기준 경로다. 선택 지출/추가 보상은 없다. DAY28은 DAY27 정산, DAY29는 DAY28 정산을 반영하고, DAY30은 전투·정산 없는 DAY29의 보유 자원을 그대로 사용한다.', '',
              '자원 기준 경로는 수정 전 기준 SHA의 웨이브로 산출해 후보와 최종 비교에 동일하게 고정했다. 경유 수정 뒤 전체 캠페인의 자원 경로를 다시 정산한 결과나 개인 플레이어 잔액을 뜻하지 않는다.', '',
              '| 승급 / 건설 | 건설 전 금 / 마나 | 비용 금 / 마나 | 건설 후 금 / 마나 | 결과 |',
              '|---|---|---|---|---|']
    for p in economy['purchases']:
        lines.append(f"| {p['grade']} / {p['site']} | {p['before']['gold']:.0f} / {p['before']['mana']:.0f} | {p['cost'].get('gold',0):.0f} / {p['cost'].get('mana',0):.0f} | {p['after']['gold']:.0f} / {p['after']['mana']:.0f} | {'구매' if p['ok'] else '예산 부족·미구매'} |")
    lines += ['', '| DAY | 비교 시작 금 | 비교 시작 마나 |', '|---|---:|---:|']
    for day in range(20, 31):
        wallet = economy['daily_wallets'][str(day)]
        lines.append(f"| {day}{' 준비일' if day == 29 else ''} | {wallet['gold']:.0f} | {wallet['mana']:.0f} |")
    lines += ['', f"D 보유 {len(economy['layouts']['D']['buildings'])}개, C 보유 {len(economy['layouts']['C']['buildings'])}개. D: 감시탑 II → 미끼 보물실 II. C: 유료 D 건물 이전 → 병영 II → 회복둥지 II 순서로 예산 안에서만 구매했다. 모두 Lv1이며 무료 강화/병력/함정 지급은 없다.", '',
              '## 출전 인원 / 식량 유지비', '', '| DAY | 추천 | 집중① | 집중② | 집중③ |', '|---|---|---|---|---|']
    for day in DAYS:
        lines.append(f'| {day} | ' + ' | '.join(f"{summary[str(day)][k]['count']:.0f}명 / {summary[str(day)][k]['upkeep']:.0f}" if k in summary[str(day)] else '미측정' for k in MODES) + ' |')
    if name == 'final_rows' and (OUT / 'selection.json').exists():
        selected = read('selection.json')
        lines += ['', '## 경유 후보의 채택·제외', '',
                  '정찰·조사관의 기존 입구 레인을 감시탑 II / 미끼 보물실 II에 대응시키는 후보를 필요한 날짜에 시험했다. 채택에는 네 배치 각 10회 측정을 요구했다. 수치는 바꾸지 않았다.',
                  '건설·정산 기준을 보정한 기준선에서도 집중①이 유리한 날짜만 경유 수정 대상으로 삼았다. 곡선과 세 집중 배치 대비 동시 우위가 완전 해결이다. 부분 결과는 ① 곡선 안에서 집중①을 해소하고 이미 앞선 비교를 유지하며 남은 집중 이점도 확대하지 않는 변경 ② 추천 승률·HP를 모두 악화시키지 않으면서 하나 이상 개선하고 모든 상대 격차도 늘리지 않는 변경만 채택했다. 전자는 HP가 곡선 안에서 소폭 낮아질 수 있다. 완전 해결로 세지 않는다. 나머지는 기존 경로를 유지했다. 건설 효과와 자원 변화 효과를 분리한 실험은 아니다.', '',
                  '| DAY | 조사관 후보 추천 승률 / HP | 조사관 후보 집중① 승률 / HP | 곡선 / 추천 우위 | 채택 |', '|---|---|---|---|---|']
        def pair(m):
            return f"{m['win']:.0f}% / {m['hp']:.2f}% (n={m['n']})" if m else '미측정'
        for day in PROBLEM_DAYS:
            decision = selected['decisions'][str(day)]
            probe = decision['candidate_metrics']
            rec, anchor = probe.get('recommended'), probe.get('anchor_cluster')
            lo, hi, hlo, hhi = target(day)
            probe_curve = bool(rec and rec['n'] == 10 and lo <= rec['win'] <= hi and hlo <= rec['hp'] <= hhi and rec['gold'] <= 150)
            probe_dominates = bool(rec and decision['candidate_complete'] and all(rec['win'] >= m['win'] and rec['hp'] + .000001 >= m['hp'] for mode, m in probe.items() if mode != 'recommended'))
            curve_label = ('충족' if probe_curve else '미충족') if rec and rec['n'] == 10 else '미측정'
            dominance_label = ('충족' if probe_dominates else '미충족') if decision['candidate_complete'] else '네 배치 미측정'
            adoption = '부분 개선 반영·우위 미달 유지' if day in selected['partial_improvement_days'] else '완전 충족 반영' if day in selected['accepted_days'] else '건설·정산 보정으로 충족·경유 불필요' if day in selected['construction_resolves_days'] else '제외·기존 경로 유지'
            if decision['variant'] != 'scout' and day in selected['accepted_days']:
                adoption = '조사관 제외·추가 후보 ' + ('부분 개선 반영' if day in selected['partial_improvement_days'] else '목표 충족 반영')
            lines.append(f"| {day} | {pair(rec)} | {pair(anchor)} | {curve_label} / {dominance_label} | {adoption} |")
        if any(d['second_attempt_metrics'] for d in selected['decisions'].values()):
            lines += ['', f"추가 경유·목표 후보는 `{selected['alternate_candidate']}`다. 건설 기준선에서 집중①의 이점이 남은 날짜만 시험했다. 아래 부분 비교는 최종 400행을 대체하지 않는다.", '',
                      '| DAY | 추가 후보 추천 승률 / HP | 집중① 승률 / HP | 네 배치 측정 완료 |', '|---|---|---|---|']
            for day in PROBLEM_DAYS:
                decision = selected['decisions'][str(day)]
                second = decision['second_attempt_metrics']
                if not second: continue
                a, b = second.get('recommended'), second.get('anchor_cluster')
                adoption = ('부분 개선 반영' if day in selected['partial_improvement_days'] else '목표 충족 반영') if day in selected['accepted_days'] and decision['variant'] != 'scout' else '미채택'
                lines.append(f"| {day} | {pair(a)} | {pair(b)} | {'완료' if decision['second_attempt_complete'] else '일부 배치만'} / {adoption} |")
        lines += ['', '채택 경유 날짜: ' + (', '.join(map(str, selected['accepted_days'])) or '없음 — 제품 전투 데이터 유지') + '.']
    uncovered = {}
    for day in DAYS:
        first = next((r for r in rows if r['day'] == day and r['layout'] == 'recommended'), None)
        if first:
            secondary = [b for b in first['buildings'] if b.get('plan_site_id', '').endswith('_2')]
            uncovered[day] = [b['plan_site_id'] for b in secondary if not any(a['building'] == b['id'] for a in first['assignments'].values())]
    checks['unguarded_secondary_recommendation'] = uncovered
    lines += ['', '## 판정·제한', '', f"- 실측 {len(rows)}/400행. 곡선 미달: {', '.join(str(i['day']) for i in issues if not i['curve']) or '없음'}.",
              f"- 추천 승률·평균HP 동시 우위 미달: {', '.join(str(i['day']) for i in issues if not i['superiority']) or '없음'}.",
              f'- 전투 원자료: [{name}.json]({name}.json). 자원 정산: [economy.json](economy.json).',
              '- 건물·몬스터 수치와 DAY29 무전투를 유지했다. 전체 회귀·전체 캠페인·출시 검수 미요청/미실행.',
              '- 10회 표본의 비교이며 누적 캠페인 승률이나 모든 배치에 대한 최적성 증명은 아니다.',
              '- 사용자 확인 대기.']
    if any(uncovered.values()):
        lines += ['', '## 남은 원인과 선택지', '',
                  '실제 추천 배치 기록에서 추가 건물이 무수비로 남는 날짜가 있다. 건설은 수비 슬롯을 추가하지만 자동 추천은 기존 시설의 같은 역할 슬롯부터 채운다.',
                  '같은 해금 명단·식량 한도를 사용한다. C에서는 새 병영 슬롯으로 기존 대기 인원이 출전하기도 하지만, 기존 핵심 수비 인원의 소속까지 바뀔 수 있다. 모든 추가 시설이 자동으로 수비되는 것은 아니다.',
                  '미달이 남으면 다음 선택지는 ① 결계핵·금고·옥좌의 기존 핵심 수비를 유지하며 추가 시설을 채우도록 추천 우선순위 조정 ② 날짜별 경유 대상을 추가 탐색이다. 몬스터·건물 수치 조정과 DAY29 전투 추가는 이번 선택지에 포함하지 않는다.', '',
                  '집중①의 이점이 없는 날짜는 이번 조건에 따라 경로 수정 대상에서 제외한다. 그런 날짜의 곡선 미달을 고치기 위한 별도 추천 정책 수정이나 경유 실험은 다음 작업 범위를 결정해야 한다.', '',
                  '| DAY | 추천에서 무수비인 추가 부지 |', '|---|---|']
        for day, sites in uncovered.items(): lines.append(f"| {day} | {', '.join(sites) or '없음'} |")
    if (OUT / 'day30_budget_diagnostics.json').exists():
        diagnostics = read('day30_budget_diagnostics.json')
        lines += ['', '## DAY30 별도 원인 대조', '',
                  '동일한 12개 건물·명단·배치·시드130803에서 실제 잔액과 과거 마나600 조건을 따로 비교했다. 600은 원인 조사용이며 위 공정 비교표나 실제 보유 예산에 포함하지 않았다.', '',
                  '| 조건 | 초기 마나 | 종료 마나 | 승패 | 옥좌HP |', '|---|---:|---:|---|---:|']
        for r in diagnostics:
            label = '실제 정산 잔액' if r['diagnostic_only'] == 'actual_settlement_budget' else '마나600 대조·미채택'
            lines.append(f"| {label} | {r['wallet']['mana']:.0f} | {r['end_mana']:.0f} | {'승리' if r['win'] else '패배'} | {r['throne_hp']:.0f} |")
        lines += ['', '마나600에서도 같은 시드가 패배했으므로 단순히 마나만 늘리면 해결된다고 판정하지 않았다. 건물 추가 시 기존 수비의 소속이 바뀌는 실제 추천 배치도 함께 점검해야 한다.']
    historical_path = ROOT / '_mockup/game_step10_dc/final_rows.json'
    if name == 'final_rows' and historical_path.exists():
        historical = json.loads(historical_path.read_text(encoding='utf-8-sig'))
        old = next(r for r in historical if r['day'] == 30 and r['layout'] == 'recommended' and r['trial'] == 0)
        new = next(r for r in rows if r['day'] == 30 and r['layout'] == 'recommended' and r['trial'] == 0)
        lines += ['', '## C 추천 소속 변화의 실제 기록', '',
                  f"0108b의 8개 건물과 이번 {len(new['buildings'])}개 건물에서 DAY30 추천 소속을 비교했다. 건설·예산이 함께 달라진 비교이므로 이 표만으로 개별 원인의 기여도를 확정하지 않는다. 슬롯은 원자료와 같은 0부터 표시한다.", '',
                  '| 기존 해금 인스턴스 | 0108b 추천 | 이번 추천 |', '|---|---|---|']
        def assignment(a):
            return f"{a['building']} / 슬롯 {int(a['slot'])}" if a else '대기'
        for key in sorted(old['assignments'].keys() | new['assignments'].keys()):
            a, b = old['assignments'].get(key), new['assignments'].get(key)
            if a != b: lines.append(f'| {key} | {assignment(a)} | {assignment(b)} |')
        lines += ['', '`barracks_owned_3`는 이번에 비용을 낸 병영 II다. 텅텅은 결계핵에서, 쉿은 금고에서 병영 II로 옮겨지고, 대기하던 파파가 결계핵에 출전했다. 추천 우선순위는 이번 작업에서 수정하지 않았다.']
    (OUT / 'result_table.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    (OUT / (name + '_summary.json')).write_text(json.dumps(dict(checks=checks, summary=summary), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(checks, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--name', default='final_rows')
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--route', choices=['paid', 'scout', 'siege_scout', 'both', 'upper', 'lower'], default='paid')
    parser.add_argument('--days', default=','.join(map(str, DAYS)))
    parser.add_argument('--layouts', default=','.join(MODES))
    parser.add_argument('--trials', type=int, default=10)
    parser.add_argument('--wave-source', default='data/waves.json')
    parser.add_argument('--keep-achievement-observers', action='store_true')
    parser.add_argument('--select', action='store_true')
    parser.add_argument('--alternate', default='upper_trials')
    parser.add_argument('--compose', action='store_true')
    args = parser.parse_args()
    if args.prepare: prepare(args)
    elif args.select: select_routes(args.name, args.alternate)
    elif args.compose: compose(args.name)
    else: report(args.name, args.wave_source)
