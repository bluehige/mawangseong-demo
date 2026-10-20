"""Concise, paired behavior and honest uninterrupted-campaign reports."""
import argparse
import hashlib
import json
from pathlib import Path

import v130r_b04_report as b04

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'tmp/v130r_engage'


def load(path):
    return json.loads(path.read_text(encoding='utf-8'))


def verify_measurement(label, current=True, diagnostic=False):
    folder=OUT/label
    info=load(folder/'run.json'); checks=load(folder/'checks.json')
    hashes=load(folder/'input_hashes.json')
    assert info['inputs_unchanged'] and not info['godot_after'] and info['peak_godot']==1
    if diagnostic:
        assert info['exit_code']==1 and checks['failures']
        assert all(f=='battle completes before timeout' for f in checks['failures'])
    else:
        assert info['exit_code']==0 and not checks['failures']
    diagnostics=[line for line in info['stderr'].splitlines() if 'ERROR:' in line or 'WARNING:' in line or 'SCRIPT ERROR' in line]
    known="ERROR: Signal 'resized' is already connected to given callable 'RefCounted(StoryDialoguePresenter)::_layout_monster_standing' in that object."
    allowed=[known]+(['ERROR: B04 battle completes before timeout'] if diagnostic else [])
    assert all(line in allowed for line in diagnostics), diagnostics[:3]
    if current:
        assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
    evidence={'preexisting_portrait_diagnostics':sum(line==known for line in diagnostics),'checks':checks['checks'],'failures':checks['failures'],'diagnostic_only':diagnostic}
    extension=folder/'watchdog_extension.json'
    if extension.exists():
        guard=load(extension)
        assert guard['peak_godot']==1 and guard['engine_exit']==(1 if diagnostic else 0) and not guard.get('stopped_by_guard')
        evidence['watchdog_extension']=guard
    return evidence


def behavior(before, after):
    evidence={'before':verify_measurement(before,False),'after':verify_measurement(after)}
    old = load(OUT/before/'days.json')
    new = load(OUT/after/'days.json')
    assert len(old) == len(new) == 18
    assert {(r['seed'], r['day'], r['entry_file_sha256']) for r in old} == {
        (r['seed'], r['day'], r['entry_file_sha256']) for r in new}
    lines = ['# 동일 진입 사본 교전 전후', '',
             '0119c 실제 1회차 진입 사본, 130401~130403 × 6일. 몬스터의 공격 사거리 안에 들어온 적-몬스터 쌍을 한 접촉으로 센다. 교전은 해당 몬스터에 접근/정지하여 공격 대상으로 삼거나 실제 공격한 경우다. 통과는 양쪽 생존·무교전 상태로 사거리를 벗어나 목표 방향 뒤편 16px 이상으로 전진한 경우다. 원거리 몬스터가 멀리서 공격한 접촉과 적이 반응 전에 처치된 경우도 분모에 포함하므로 이 비율을 적 근접 교전 성공률로 해석하지 않는다.', '',
             '| 등급 / DAY | 전 접촉 | 전 교전률 | 전 무시 통과 | 후 접촉 | 후 교전률 | 후 무시 통과 | 후 일반/역할 통과 |',
             '|---|---:|---:|---:|---:|---:|---:|---:|']
    result = {}
    for day in [1, 5, 15, 20, 27, 30]:
        parts = []
        for rows in [old, new]:
            rows = [r for r in rows if r['day'] == day]
            totals = {key:sum(r['engagement'][key] for r in rows)
                      for key in ['contacts','engaged','attacks','ignored_passes','killed_before_response']}
            totals['rate'] = 100*totals['engaged']/max(1, totals['contacts'])
            totals['normal_passes'] = sum(x['passed'] and not x['objective'] for r in rows for x in r['engagement']['rows'])
            totals['role_passes'] = totals['ignored_passes']-totals['normal_passes']
            parts.append(totals)
        a, z = parts
        grade = next(r['grade'] for r in new if r['day'] == day)
        lines.append(f"| {grade} / {day} | {a['contacts']} | {a['rate']:.1f}% | {a['ignored_passes']} | {z['contacts']} | {z['rate']:.1f}% | {z['ignored_passes']} | {z['normal_passes']}/{z['role_passes']} |")
        result[day] = {'before':a, 'after':z}
    lines+=['', '기존 대화 초상 중복 신호 진단(전/후): '+str(evidence['before']['preexisting_portrait_diagnostics'])+'/'+str(evidence['after']['preexisting_portrait_diagnostics'])+'건. 기계 검증 실패와 다른 오류는 허용하지 않는다.']
    (OUT/'engagement_before_after.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    return result


def campaign(label, paired, diagnostic=False):
    reference = '../v130r_engage/'+label
    rows = b04.read(reference)
    evidence=verify_measurement(label,current=not diagnostic,diagnostic=diagnostic)
    info=load(OUT/label/'run.json')
    assert 'retries=1' in info['command']
    assert not any(x.startswith(('checkpoint=', 'stack_source=')) for x in info['command'])
    validation = b04.validate_actual_records(rows, reference)
    timeouts=[{'seed':r['seed'],'day':r['day'],'attempt':attempt} for r in rows for attempt,a in [('first',r),('retry',r.get('retry',{}))] if a.get('timeout')]
    curve_rows=[r for r in rows if not r.get('timeout')]
    lookup, daily = b04.summarize(curve_rows)
    endings = [s for s in b04.SEEDS if (OUT/label/f'ending_{s}.json').exists()
               and load(OUT/label/f'ending_{s}.json')['completed']]
    no_retry = sum(all(r.get('win') or r.get('preparation_only') for r in rows if r['seed']==s) for s in endings)
    completion=[]
    complete_lines=['# 시드별 완주', '', '| 시드 | 정상 엔딩 | 무재도전 완주 | 최종 진입 DAY | 재도전 DAY | 시간 초과 |', '|---:|---|---|---:|---|---|']
    for seed in b04.SEEDS:
        trials=[r for r in rows if r['seed']==seed]
        one={'seed':seed,'completed':seed in endings,'no_retry':seed in endings and all(r.get('win') or r.get('preparation_only') for r in trials),
             'last_day':max(r['day'] for r in trials),'retry_days':[r['day'] for r in trials if 'retry' in r],
             'timeouts':[t for t in timeouts if t['seed']==seed]}
        completion.append(one)
        complete_lines.append(f"| {seed} | {'예' if one['completed'] else '아니오'} | {'예' if one['no_retry'] else '아니오'} | {one['last_day']} | {','.join(map(str,one['retry_days'])) or '—'} | {len(one['timeouts'])} |")
    if diagnostic: complete_lines+=['', '실패한 진단 라운드다. 시간 초과를 정상 패배나 채택 가능 결과로 취급하지 않는다.']
    (OUT/f'{label}_completion.md').write_text('\n'.join(complete_lines)+'\n',encoding='utf-8')
    lines = [f'# 새 게임 10시드 곡선 — {len(endings)}/10 완주', '',
             '시드130401~130410, 실제 합류·성장·구매·정산·엔딩 연속 진행. 정상 재도전은 같은 날1회. 곡선은 도달 회차의 첫 전투, 실패 HP0; 성 등급 변경으로 정산에 더해진 HP는 검증된 차이만 분리한다. 재도전 없는 완주 '+str(no_retry)+'/10.', '',
             '| DAY | 도달 | 첫 승률 | 평균 전투 HP | 목표 승률 / HP | 판정 |',
             '|---:|---:|---:|---:|---|---|']
    if diagnostic:
        lines[2:2]=['**실패한 진단 라운드이며 채택/검증 PASS가 아니다. 시간 초과 전투는 승패·HP 평균에서 제외하고 별도로 기록한다.**', '']
    for day, r in daily.items():
        if day == 29:
            lines.append(f"| 29 | {r['reached']} | 무전투 | 준비일 | 무전투 유지 | {'PASS' if r['passed'] else 'FAIL'} |")
            continue
        lo, hi, hlo, hhi = b04.target(day)
        rate = 'N/A' if r['rate'] is None else f"{r['rate']:.1f}%"
        hp = 'N/A' if r['hp'] is None else f"{r['hp']:.2f}%"
        lines.append(f"| {day} | {r['reached']} | {rate} | {hp} | {lo}~{hi}% / {hlo}~{hhi}% | {'PASS' if r['passed'] else 'FAIL'} |")
    (OUT/f'{label}_curve.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    comparison = {}
    if paired:
        pair_evidence=verify_measurement(paired)
        assert load(OUT/paired/'checks.json')['source']==reference
        pair_rows = b04.read('../v130r_engage/'+paired)
        groups = {}
        for row in pair_rows:
            original=OUT/label/'checkpoints'/f"{row['seed']}_{row['day']}.json"
            assert hashlib.sha256(original.read_bytes()).hexdigest()==row['entry_file_sha256']
            groups.setdefault((row['seed'], row['day']), {})[row['layout']]=row
        assert all(set(g)=={'recommended','anchor_cluster','final_line','first_line'} for g in groups.values())
        lines = ['# 같은 진입 상태 배치 비교', '',
                 '| DAY | 표본/배치 | 추천 승률/HP | 병영 집중 | 최종선 집중 | 1차선 집중 | 추천 ≥ 집중 |',
                 '|---:|---:|---:|---:|---:|---:|---|']
        for day in sorted({d for _, d in groups}):
            values = {}
            for mode in ['recommended','anchor_cluster','final_line','first_line']:
                subset = [g[mode] for (s,d),g in groups.items() if d == day]
                values[mode]={'n':len(subset),'wins':100*sum(r.get('win',False) for r in subset)/len(subset),
                              'hp':sum(100*r['hp']/r['max_hp'] for r in subset)/len(subset)}
            a=values['recommended']
            passed=all(a['wins']>=v['wins'] and a['hp']+.001>=v['hp'] for k,v in values.items() if k!='recommended')
            cells=[f"{values[m]['wins']:.0f}%/{values[m]['hp']:.2f}%" for m in values]
            lines.append(f"| {day} | {a['n']} | "+' | '.join(cells)+f" | {'PASS' if passed else 'FAIL'} |")
            comparison[day]={'values':values,'passed':passed}
        (OUT/f'{label}_stacking.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
    result={'label':label,'completed':len(endings),'no_retry_completed':no_retry,'completion':completion,'validation':validation,'evidence':evidence,'diagnostic_only':diagnostic,'timeouts':timeouts,'comparison_status':'NOT_RUN' if not paired else ('PASS' if all(v['passed'] for v in comparison.values()) else 'FAIL'),
            'curve':daily,'curve_fail_days':[d for d,v in daily.items() if d!=29 and not v['passed']],
            'comparison':comparison,'comparison_fail_days':[d for d,v in comparison.items() if not v['passed']]}
    (OUT/f'{label}_summary.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    return result


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--before', default='behavior_before_clean')
    parser.add_argument('--after')
    parser.add_argument('--campaign')
    parser.add_argument('--paired')
    parser.add_argument('--diagnostic', action='store_true')
    args=parser.parse_args()
    if args.after:
        result=behavior(args.before,args.after)
        print(json.dumps({'behavior_days':len(result),'ignored_passes_before':sum(v['before']['ignored_passes'] for v in result.values()),'ignored_passes_after':sum(v['after']['ignored_passes'] for v in result.values())}))
    if args.campaign:
        result=campaign(args.campaign,args.paired,args.diagnostic)
        print(json.dumps({k:result[k] for k in ['label','completed','no_retry_completed','curve_fail_days','comparison_fail_days']}))


if __name__=='__main__': main()
