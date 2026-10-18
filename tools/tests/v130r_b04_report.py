"""Summarize real uninterrupted campaigns, including honest unreachable rows."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "_mockup/game_step15_rebalance"
TMP = ROOT / "tmp/v130r_b04"
SEEDS = list(range(130401, 130411))
BASE = "0a90971c970ac2a65ed6c6661b5c9d66a3e07704"

def read(label):
    return json.loads((TMP / label / "days.json").read_text(encoding="utf-8"))

def verify_run(label, current=True):
    folder=TMP/label
    info=json.loads((folder/'run.json').read_text(encoding='utf-8'))
    checks=json.loads((folder/'checks.json').read_text(encoding='utf-8'))
    hashes=json.loads((folder/'input_hashes.json').read_text(encoding='utf-8'))
    assert info['exit_code']==0 and info['inputs_unchanged'] and not info['godot_after']
    assert info['peak_godot']==1 and not checks['failures'] and not info['stderr'].strip()
    if current:
        assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in hashes.items()), f'Stale source evidence: {label}'
    return info,checks,hashes

def target(day):
    if day <= 4: return 100, 100, 85, 95
    if day <= 14: return 90, 100, 60, 85
    if day <= 26: return 80, 95, 45 if day in [15, 20, 21, 26] else 50, 65 if day in [15, 20, 21, 26] else 75
    return 70, 90, 35 if day == 30 else 40, 55 if day == 30 else 65

def first_life_rows(rows):
    alive=set(SEEDS)
    result=[]
    for row in rows:
        if row['seed'] not in alive: continue
        item={k:v for k,v in row.items() if k!='retry'}
        result.append(item)
        if not row.get('win') and not row.get('preparation_only'): alive.remove(row['seed'])
    return result

def summarize(rows, seeds=SEEDS, denominator="cohort"):
    lookup = {(r["seed"], r["day"]): r for r in rows if "day" in r}
    daily = {}
    for day in range(1, 31):
        reached = [lookup[(seed, day)] for seed in seeds if (seed, day) in lookup and "error" not in lookup[(seed, day)]]
        battles = [r for r in reached if not r.get("preparation_only")]
        wins = sum(bool(r.get("win")) for r in battles)
        hp = [100 * r["hp"] / r["max_hp"] for r in battles]
        observed_rate = 100 * wins / len(battles) if battles else None
        observed_hp = sum(hp) / len(hp) if hp else None
        cohort_rate,cohort_hp=100*wins/len(seeds),sum(hp)/len(seeds)
        rate,mean=(cohort_rate,cohort_hp) if denominator=='cohort' else (observed_rate,observed_hp)
        lo, hi, hlo, hhi = target(day)
        daily[day] = dict(reached=len(reached), wins=wins, rate=rate, hp=mean, total_rate=cohort_rate, cohort_hp=cohort_hp, conditional_rate=observed_rate,conditional_hp=observed_hp, passed=(rate is not None and lo<=rate<=hi and hlo<=mean<=hhi) if day!=29 else bool(reached))
    return lookup, daily

def paired_report(labels, lookup, selected_days, source):
    modes=["recommended","anchor_cluster","final_line","first_line"]
    pairs={}
    for label in labels:
        info,checks,_=verify_run(label)
        assert 'stack_source='+source in info['command'] and checks['source']==source, 'Pairs must restore this exact primary campaign'
        for r in read(label):
            key=(r["seed"],r["day"])
            group=pairs.setdefault(key,{})
            assert r["layout"] not in group, f"Duplicate pair {key} {r['layout']}"
            group[r["layout"]]=r
    for key,group in pairs.items():
        assert set(group)==set(modes), f"Incomplete pair {key}"
        assert len({r["entry_sha256"] for r in group.values()})==1, f"Unequal entry {key}"
        assert len({json.dumps(r["wallet_before"],sort_keys=True) for r in group.values()})==1, f"Unequal wallet {key}"
    text=["# 실제 캠페인 진입 상태의 배치 비교", "", "완주·난이도 곡선은 새 게임 연속 10회만 사용한다. 이 표는 각 실제 DAY 진입 사본에서 레벨·EXP·유대·특화·전직·HP·자원·건물·이전 선택을 동일하게 복원한 비교다. 인위적인 날짜별 성장/예산을 주입하지 않는다. 각 쌍은 seed+DAY×1000의 공통 실험 RNG로 첫 전투만 비교한다.", "", "집중① 병영·결계핵·옥좌, 집중② 최종선, 집중③ 1차선. 실제 합류·고유 수비 칸·건물 정원·당일 식량 한도를 검사한다. 미도달 회차는 해당 날짜 비교에 포함하지 않는다. 집중 영역의 실제 정원 때문에 배치 가능한 인원이 달라질 수 있어 평균 배치 수도 표시한다.", "", "| DAY | 등급 | 짝 표본 | 배치 | 평균배치 | 승률% | 평균HP% (패배0) | 추천≥집중 |", "|---:|---|---:|---|---:|---:|---:|---|"]
    failures,missing=[],[]
    text += ['', '비교 날짜: '+', '.join(map(str,selected_days))+'. 등급 전환·기존 결함·후반 곡선 날짜를 대상으로 한 표적 비교이며, 다른 날짜의 우위를 추정하지 않는다.', '']
    for day in selected_days:
        if day==29: continue
        expected={(s,day) for s in SEEDS if (s,day) in lookup}
        available={key for key in pairs if key[1]==day}
        missing.extend(sorted(expected-available))
        groups=[pairs[key] for key in sorted(available)]
        if not groups:
            text.append(f"| {day} | — | 0 | {'미실행' if expected else '미도달'} | — | — | — | NOT_TESTED |")
            continue
        stats={mode:(100*sum(bool(g[mode].get('win')) for g in groups)/len(groups),sum(100*g[mode]['hp']/g[mode]['max_hp'] for g in groups)/len(groups)) for mode in modes}
        rw,rh=stats['recommended']
        grade='F' if day<15 else 'E' if day<20 else 'D' if day<27 else 'C'
        for mode,(win,hp) in stats.items():
            passed=rw>=win and rh+.001>=hp
            if mode!='recommended' and not passed and day in [20,21,26]: failures.append([day,mode])
            result='기준' if mode=='recommended' else 'PASS' if passed else 'FAIL'
            deployed=sum(len(g[mode].get('assignments',{})) for g in groups)/len(groups)
            text.append(f"| {day} | {grade} | {len(groups)} | {mode} | {deployed:.2f} | {win:.2f} | {hp:.2f} | {result} |")
    text += ['', '등급별 전체 비교와 기존 문제일 DAY20·21·26의 개별 우위를 완료 기준으로 판정한다. 위 날짜별 세부값도 숨기지 않고 모두 제시한다.', '', '| 등급 | 전투 진입 표본 | 배치 | 승률% | 평균HP% | 추천≥집중 |', '|---|---:|---|---:|---:|---|']
    for grade,days in [('F',range(1,15)),('E',range(15,20)),('D',range(20,27)),('C',[27,28,30])]:
        groups=[g for (seed,day),g in pairs.items() if day in days]
        if not groups: continue
        stats={mode:(100*sum(bool(g[mode].get('win')) for g in groups)/len(groups),sum(100*g[mode]['hp']/g[mode]['max_hp'] for g in groups)/len(groups)) for mode in modes}
        rw,rh=stats['recommended']
        for mode,(win,hp) in stats.items():
            passed=rw>=win and rh+.001>=hp
            if mode!='recommended' and not passed: failures.append([grade,mode])
            result='기준' if mode=='recommended' else 'PASS' if passed else 'FAIL'
            text.append(f'| {grade} | {len(groups)} | {mode} | {win:.2f} | {hp:.2f} | {result} |')
    text += ["",f"미측정 실제 진입 상태: {len(missing)}개. 추천 우위 미달: {failures or '없음'}."]
    (OUT/'stacking_compare.md').write_text('\n'.join(text)+'\n',encoding='utf-8')
    return failures,missing

def changed_report():
    text=["# B04 변경 값", "", "몬스터 종족·레벨 성장·건물 기본 수치와 웨이브 HP/ATK 계수 변경 없음. 웨이브의 수량·등장 간격·경유·목표 우선만 조정한다. 탐색 중 DAY30 ATK -20% 후보는 지도 강화 상태가 누락된 비교에 근거한 것으로 확인해 원복하고 채택하지 않았다.", ""]
    def table(title,a,b):
        text.extend([title,"","| DAY | 행(1부터) | 필드 | 이전 | 이후 |","|---|---:|---|---|---|"])
        def walk(x,y,path):
            if isinstance(x,dict) and isinstance(y,dict):
                for k in sorted(x.keys()|y.keys(),key=lambda k:(0,int(k[4:])) if not path and k.startswith('day_') else (1,k)): walk(x.get(k),y.get(k),path+[str(k)])
            elif isinstance(x,list) and isinstance(y,list) and len(x)==len(y):
                for i,(xx,yy) in enumerate(zip(x,y)):walk(xx,yy,path+[str(i)])
            elif x!=y:
                text.append('| '+' | '.join([path[0],str(int(path[1])+1) if len(path)>1 else '—','.'.join(path[2:]) or 'rows',json.dumps(x,ensure_ascii=False),json.dumps(y,ensure_ascii=False)])+' |')
        walk(a,b,[])
        text.append('')
    head=json.loads(subprocess.check_output(['git','show',BASE+':data/waves.json']))
    table('`data/waves.json` — 이번 B04 (0118 커밋 대비)',head,json.loads((ROOT/'data/waves.json').read_text(encoding='utf-8')))
    table('`data/v122/dual_front_day01_05_waves.json` — 실제 DAY1~5 선택 파일',json.loads(subprocess.check_output(['git','show',BASE+':data/v122/dual_front_day01_05_waves.json'])),json.loads((ROOT/'data/v122/dual_front_day01_05_waves.json').read_text(encoding='utf-8')))
    table('중지된 0115 미커밋 보정→0118 복원 (원문: superseded_0115_waves.json)',json.loads((OUT/'superseded_0115_waves.json').read_text(encoding='utf-8')),head)
    text += ['코드 변경:','','- `GameRoot._open_intrusion_brief`: 진행 중인 본편/합류 대사를 예약된 관리 복귀가 덮어쓰지 않도록 보호.','- `ApprovedBattleController.spawn_enemy`: 명시적 옥좌 우선 공격·경유를 F/E에서도 지정 웨이브에 적용. 공병·도둑의 최종 목표 정책은 유지.','- `ApprovedMonsterPlacement.auto_place`: D는 실제 가용 탱커 2명을 옥좌 호위로 우선 배치. C는 입구 슬라임을 유지하고 가용 다리 트롤·접착 달팽이 등을 양쪽 옥좌 입구에 분산.','','웨이브 SHA-256: `'+hashlib.sha256((ROOT/'data/waves.json').read_bytes()).hexdigest()+'`.']
    (OUT/'changed_values.md').write_text('\n'.join(text)+'\n',encoding='utf-8')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--recommended", default="final_recommended")
    parser.add_argument("--paired", nargs="*", default=[])
    parser.add_argument('--curve-denominator',choices=['cohort','reached'],default='cohort')
    parser.add_argument('--completion-policy',choices=['no_retry','one_retry'],default='no_retry')
    parser.add_argument('--stack-days',default='4,14,15,19,20,21,22,23,26,27,28,30')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    rows = read(args.recommended)
    actual_seeds={r.get("seed") for r in rows}
    assert set(SEEDS)<=actual_seeds, f"Seeds were never started: {set(SEEDS)-actual_seeds}"
    info,checks,hashes=verify_run(args.recommended)
    assert not any(a.startswith(("checkpoint=","stack_source=")) for a in info["command"]), "Primary evidence must start fresh"
    if args.completion_policy=='no_retry':
        assert 'retries=0' in info['command'], 'Final no-retry evidence must actually stop at its first defeat'
    lookup, daily = summarize(rows,denominator=args.curve_denominator)
    progression=[]
    for r in rows:
        if r.get('preparation_only'): continue
        item={k:r[k] for k in ['seed','day','grade','hp_start','hp','max_hp','assignments','wallet_before','wallet_after'] if k in r}
        for stage,roster in [('before',r.get('roster_before',{})),('after_first',r.get('roster_after',{})),('after_retry',r.get('retry',{}).get('roster_after',{}))]:
            item[stage]={id:{k:m[k] for k in ['species_id','level','exp','bond','bond_rank','promotion_id','promotion_stage','specialization_id','growth_preparation_id','growth_preparation_day','unlocked_memory_ids'] if k in m} for id,m in roster.items()}
        progression.append(item)
    (OUT/'progression.json').write_text(json.dumps(progression,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'construction_log.json').write_bytes((TMP/args.recommended/'purchases.json').read_bytes())
    with (OUT / "campaign_10runs.csv").open("w", newline="", encoding="utf-8-sig") as f:
        fields = ["seed", "day", "status", "win", "throne_hp_entered", "throne_hp", "throne_max_hp", "throne_hp_pct", "grade", "available", "deployed", "level_before", "max_level", "gold", "mana", "food", "duration_s", "retry_win", "retry_hp", "retry_max_hp"]
        writer = csv.DictWriter(f, fieldnames=fields); writer.writeheader()
        for seed in SEEDS:
            for day in range(1, 31):
                r = lookup.get((seed, day), {})
                settled = r.get('retry',r)
                status = "NOT_REACHED" if not r else "HARNESS_ERROR" if "error" in r else "PREPARATION_ONLY" if r.get("preparation_only") else "WIN" if r.get("win") else "RETRY_WIN" if r.get("retry", {}).get("win") else "LOSS"
                writer.writerow(dict(seed=seed, day=day, status=status, win=int(r["win"]) if "win" in r else "", throne_hp_entered=r.get('hp_start',''), throne_hp=r.get("hp", ""), throne_max_hp=r.get("max_hp", ""), throne_hp_pct=round(100*r["hp"]/r["max_hp"], 3) if "hp" in r else "", grade=r.get("grade", ""), available=len(r['roster_before']) if 'roster_before' in r else '', deployed=len(r["assignments"]) if "assignments" in r else "", level_before=max((m.get('level',1) for m in r.get('roster_before',{}).values()),default=''), max_level=max((m.get("level", 1) for m in settled.get("roster_after", {}).values()), default=""), gold=settled.get("wallet_after", {}).get("gold", ""), mana=settled.get("wallet_after", {}).get("mana", ""), food=settled.get('wallet_after',{}).get('food',''), duration_s=round(r["duration"], 3) if "duration" in r else "", retry_win=int(r["retry"]["win"]) if "win" in r.get("retry", {}) else "", retry_hp=r.get("retry", {}).get("hp", ""), retry_max_hp=r.get("retry", {}).get("max_hp", "")))
    completed = sum(bool(lookup.get((seed, 30), {}).get("win") or lookup.get((seed, 30), {}).get("retry", {}).get("win")) for seed in SEEDS)
    endings=[]
    for seed in SEEDS:
        ending=TMP/args.recommended/('ending_'+str(seed)+'.json')
        if ending.exists():
            assert json.loads(ending.read_text(encoding='utf-8'))['completed']
            endings.append(seed)
    assert len(endings)==completed, 'DAY30 victory must reach the normal ending'
    assert all(not r.get('timeout',False) and 'error' not in r and 'error' not in r.get('retry',{}) and not r.get('retry',{}).get('timeout',False) for r in rows)
    no_retry_completed=sum(seed in endings and all(r.get('win') or r.get('preparation_only') for r in rows if r['seed']==seed) for seed in SEEDS)
    completion_count=no_retry_completed if args.completion_policy=='no_retry' else completed
    text = [f"# B04 실제 연속 캠페인 — {completed}/10 완주", "", "고정 시드 130401~130410, 새 게임부터 자연 정산·레벨/집중 성장·필수 선택·정상 비용 도면 건설/강화·제품 추천 배치·기본 수비 지침을 이어간다. 첫 3일 x1, 정상 해금 후 x3. 같은 날 정상 재도전 1회(0112 기준 승계), 2연패 시 회차 종료. HP·성장·자원을 직접 보충하지 않는다. 재도전 HP 복구는 제품 기존 버튼 경로만 사용한다. DAY29 무전투.", "", f"주판정 분모: `{args.curve_denominator}`. `cohort`는 시작한 10회에 대해 중도 종료를 이후 생존 실패·HP 0인 흡수 상태로 집계한다. `reached`는 그날 실제 도달한 표본만 사용한다. 패배 HP는 두 방식 모두 0이다. CSV의 미도달 전투값은 빈칸으로 남기므로 가상의 전투 관측을 만들지 않는다. 두 집계를 모두 표시하며, 재도전은 첫 시도 곡선에 섞지 않는다. 재도전 없는 완주는 {no_retry_completed}/10이다.", "", "| DAY | 도달 | 첫 승수 | 시작10회 승률%/HP% | 도달회차 승률%/HP% | 목표 승률/HP | 주판정 |", "|---:|---:|---:|---:|---:|---|---|"]
    if args.completion_policy=='no_retry':
        text[2]=text[2].replace('같은 날 정상 재도전 1회(0112 기준 승계), 2연패 시 회차 종료.','재도전 없이 첫 패배에서 회차 종료.').replace('재도전 HP 복구는 제품 기존 버튼 경로만 사용한다. ','')
    for day, r in daily.items():
        if day==29:
            text.append(f"| 29 | {r['reached']} | — | — | — | 무전투 준비 | {'PASS' if r['reached'] else 'NOT_REACHED'} |")
            continue
        lo, hi, hlo, hhi = target(day)
        hp = f"{r['conditional_hp']:.2f}" if r['conditional_hp'] is not None else "—"
        rate=f"{r['conditional_rate']:.2f}" if r['conditional_rate'] is not None else "—"
        text.append(f"| {day} | {r['reached']} | {r['wins']} | {r['total_rate']:.2f}/{r['cohort_hp']:.2f} | {rate}/{hp} | {lo}~{hi}/{hlo}~{hhi} | {'PASS' if r['passed'] else 'FAIL'} |")
    text += ["", f"완주 정책: `{args.completion_policy}`. 재도전 없는 완주 {no_retry_completed}/10, 정상 재도전 포함 실제 엔딩 {completed}/10. 주 완주 목표(≥7/10): {'PASS' if completion_count>=7 else 'FAIL'}. 날짜 곡선 범위 밖: "+", ".join(str(d) for d,r in daily.items() if d!=29 and not r['passed'])+".", "", "건설 자동화 가정: 제품에 별도 건설 추천 서비스가 없어 승인 도면의 빈 부지를 결계핵·병영·회복 둥지·감시탑·미끼 금고 순으로 구매한다. 실제 추천 배치의 배치 인원 또는 선호 시설 점수가 좋아지는 강화만 낮은 레벨 순으로 구매한다. 모든 구매 뒤 마나 60을 남겨 필수 승급 비용을 보존하며, 실제 구매 API의 해금·부지·수량·가격·잔액 검사를 사용한다. 필수 특화/승급/원정/선언은 선택 가능한 첫 정상 선택지를 사용한다.", "", "저장 증빙 범위: 격리 프로필의 새 게임 런타임을 연속 진행한다. 테스트 씬의 기존 저장 비활성 규칙을 유지하므로 정식 저장/이어하기 게이트 G01 통과 근거가 아니다."]
    (OUT / "day_curve.md").write_text("\n".join(text)+"\n", encoding="utf-8")
    selected_days=sorted(set(map(int,args.stack_days.split(','))))
    assert {4,14,15,19,20,21,22,23,26,27,28,30}<=set(selected_days)
    stack_failures, missing = paired_report(args.paired, lookup,selected_days,args.recommended)
    changed_report()
    result=dict(completed=completed,completed_without_retry=no_retry_completed,curve_failures=[d for d,r in daily.items() if d!=29 and not r['passed']],stack_failures=stack_failures,unmeasured_paired_entries=len(missing))
    result['curve_denominator']=args.curve_denominator
    result['curve_failures_by_denominator']={mode:[d for d,r in summarize(rows,denominator=mode)[1].items() if d!=29 and not r['passed']] for mode in ['cohort','reached']}
    result['completion_policy']=args.completion_policy
    prefix=first_life_rows(rows)
    result['first_life_completed']=sum(r['day']==30 and bool(r.get('win')) for r in prefix)
    first_life=summarize(prefix,denominator='cohort')[1]
    result['first_life_curve_failures']=[d for d,r in first_life.items() if d!=29 and not r['passed']]
    (OUT/'first_life_curve.json').write_text(json.dumps(first_life,indent=2)+'\n',encoding='utf-8')
    result['accepted']=completion_count>=7 and not result['curve_failures'] and not stack_failures and not missing
    evidence=dict(primary=args.recommended,paired=args.paired,paired_days=selected_days,input_hashes=hashes,checks=checks,completed_seeds=endings,raw_sha256={name:hashlib.sha256((TMP/args.recommended/name).read_bytes()).hexdigest() for name in ['days.json','purchases.json','checks.json','run.json']})
    (OUT/'evidence_manifest.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result))

if __name__ == "__main__": main()
