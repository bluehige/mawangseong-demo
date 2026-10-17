"""D/C evidence aggregation; never changes measured outcomes or wave values."""
from pathlib import Path
import json
import subprocess
from statistics import mean
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'_mockup/game_step10_dc'
DAYS=[20,21,22,23,24,25,26,27,28,30]
MODES=['recommended','anchor_cluster','final_line','first_line']
CAPTURES=['d_full','c_full','d_start','c_start','e_to_d_before','e_to_d_after','d_to_c_before','d_to_c_after','battle_d_day22','battle_c_day30','compare_d_vs_plan','compare_c_vs_plan']

def target(day):
    return (70,90,35,55) if day==30 else (70,90,40,65) if day>=27 else (80,95,45,65) if day in [20,21,26] else (80,95,50,75)

def metrics(rows):
    return dict(n=len(rows), win=mean(bool(r.get('win')) for r in rows)*100,
        hp=mean(r['throne_hp']/r['throne_max'] for r in rows)*100,
        gold=mean(r['gold_loss'] for r in rows),
        facilities=mean(len({v['building'] for v in r.get('facility_losses',[]) if v['building'] not in ['entrance','throne','vault']}) for r in rows),
        count=mean(len(r['assignments']) for r in rows),upkeep=mean(r['fixture']['upkeep'] for r in rows))

def previews():
    dest=OUT/'previews';dest.mkdir(exist_ok=True)
    for p in OUT.glob('*.png'):
        im=Image.open(p);im.thumbnail((1000,600));im.save(dest/p.name)

def comparisons():
    for grade in ['d','c']:
        plan=Image.open(ROOT/f'_mockup/plan/plan_{grade.upper()}.png').convert('RGB')
        actual=Image.open(OUT/f'{grade}_full.png').convert('RGB')
        canvas=Image.new('RGB',(3840,1080),(20,21,27))
        plan.thumbnail((1920,1080));actual.thumbnail((1920,1080))
        canvas.paste(plan,((1920-plan.width)//2,(1080-plan.height)//2))
        canvas.paste(actual,(1920+(1920-actual.width)//2,(1080-actual.height)//2))
        canvas.save(OUT/f'compare_{grade}_vs_plan.png')

def report(name='final_rows'):
    path=OUT/f'{name}.json'
    rows=json.loads(path.read_text(encoding='utf-8')) if path.exists() else []
    old=json.loads((ROOT/'_mockup/game_step8b_spread/trial_rows.json').read_text(encoding='utf-8'))
    summary={}; issues=[]
    lines=['# Step10 D/C 전투 재측정 — 사용자 확인 대기','',
      '60Hz, seed130800~130809. DAY20~26=D, DAY27~30=C, DAY29 준비일(전투 없음).',
      '날짜별 독립 상태, 기존0104/0106 성장·해금 명단·식량·옥좌1500/금1200/마나600 유지. 전문화·기억·수동 스킬 없음.',
      'E의 기존8개 건물만 소유한 상태를 이전, Lv1 및 D+2/C+3 정원. 새 부지는 빈자리이며 무료 건물·병력·함정 없음.',
      '추천/합법 집중은 같은 보유 명단과 예산을 사용하고 실제 수비 칸·정원을 지킨다. 미출전은 대기.',
      '기존 E/Lv1과 새 지도의 결과를 구분한다. 시설은 중복 이벤트를 제거한 일시 무력화 고유 시설 수이며 영구 파괴가 아니다.', '',
      '| DAY/지도 | 목표 승률/HP | 기존0106 E 추천 | 새 추천 | 집중① 병영·결계핵·옥좌 | 집중② 최종선 | 집중③ 1차선 | 곡선/추천우위 |',
      '|---|---|---|---|---|---|---|---|']
    def cell(m): return '미측정' if not m else f"{m['win']:.0f}% / {m['hp']:.1f}% / {m['gold']:.0f}금 / {m['facilities']:.1f}개 (n={m['n']})"
    for day in DAYS:
        groups={mode:[r for r in rows if r['day']==day and r['layout']==mode] for mode in MODES}
        ms={k:metrics(v) for k,v in groups.items() if v};summary[str(day)]=ms
        reference=metrics([r for r in old if r['day']==day and r['layout']=='recommended'])
        lo,hi,hlo,hhi=target(day);rec=ms.get('recommended')
        curve=bool(rec and rec['n']==10 and lo<=rec['win']<=hi and hlo<=rec['hp']<=hhi and rec['gold']<=150)
        superior=bool(rec and len(ms)==4 and all(v['n']==10 and v['win']<=rec['win'] and v['hp']<=rec['hp']+.0001 for k,v in ms.items() if k!='recommended'))
        if not curve or not superior: issues.append(dict(day=day,curve=curve,superior=superior))
        lines.append(f"| {day}/{'D' if day<27 else 'C'} | {lo}~{hi}% / {hlo}~{hhi}% | {reference['win']:.0f}% / {reference['hp']:.1f}% | "+' | '.join(cell(ms.get(k)) for k in MODES)+f" | {'충족' if curve else '미충족/미완료'} / {'충족' if superior else '미충족/미완료'} |")
    lines+=['| 29/C | 준비일 | — | — | — | — | — | 전투 없음 |','',
      '각 결과: 승률 / 패배0 포함 평균 옥좌HP / 금고 순손실 / 고유 시설 일시 무력화. 10회 표본은 누적 캠페인 승률 추정이 아니다.','',
      '## 출전 인원 / 식량 유지비','', '| DAY | 추천 | 집중① | 집중② | 집중③ |','|---|---|---|---|---|']
    for day in DAYS:
        lines.append(f'| {day} | '+' | '.join(f"{summary[str(day)][k]['count']:.0f}명 / {summary[str(day)][k]['upkeep']:.0f}" if k in summary[str(day)] else '미측정' for k in MODES)+' |')
    unique={(r['day'],r['layout'],r['trial']) for r in rows}
    checks=dict(rows=len(rows),expected=400,unique=len(unique),complete=len(rows)==400 and len(unique)==400,curve_and_comparison_pass=not issues,issues=issues,
        legal=bool(rows) and all(r['fixture']['legal'] and r['fixture']['upkeep']<=r['fixture']['budget'] for r in rows),no_timeout=bool(rows) and all(not r['timeout'] for r in rows),
        correct_map=bool(rows) and all(r['day'] in DAYS and r['trial'] in range(10) and r['grade']==('D' if r['day']<27 else 'C') and r['simulation_hz']==60 and r['seed']==130800+r['trial'] for r in rows))
    waves=json.loads((ROOT/'data/waves.json').read_text(encoding='utf-8'))
    before=json.loads(subprocess.check_output(['git','show','648f46c7c334d62ea231ab9afaa0100b7d9014f8:data/waves.json'],cwd=ROOT,encoding='utf-8'))
    stripped={key:[{k:v for k,v in row.items() if k!='grade_routes'} for row in value] for key,value in waves.items()}
    checks['legacy_wave_fields_unchanged']=stripped==before
    checks['day29_empty']=waves.get('day_29')==[]
    checks['measured_wave_matches_runtime']=bool(rows) and all(r['wave_entries']==waves['day_'+str(r['day'])] for r in rows)
    checks['only_requested_wave_days']=all(int(day.removeprefix('day_')) in DAYS for day,entries in waves.items() if any('grade_routes' in row for row in entries))
    checks['complete_and_pass']=all(value for key,value in checks.items() if key not in ['rows','expected','unique','issues'])
    lines+=['','## 채택한 지도·목표 규칙','',
      '- D의 레인1 진격은 아래 최종 다리를 경유한다. C는 기존 레인0/1을 서문/남문에 대응시킨다. 추가 난수 없음.',
      '- 두 칸 문 중앙을 목적지로 사용하며 실제 이동·공격·옥좌 도달이 같은 점을 참조한다. 도발·시설 목표가 우선한다.',
      '- 새 자동 추천은 돌콩·벙벙·핀·꼬깃의 옥좌 네 자리를 먼저 확보하고 C에서는 두 문으로 나눈다. 기존 저장 배치는 자동 교체하지 않는다.',
      '- 지정한 진격 행의 우회 레인은 문 도착 후 옥좌를 우선 공격한다. 다른 레인은 기존 교전 규칙을 따르고 도발은 두 경우 모두 우선한다.',
      '- 경유·목표 우선 후보를 먼저 시험한 뒤 아래 등급별 수치만 보정했다. 몬스터 기본 능력·스킬·성장·보유·식량은 변경하지 않았다.','',
      '## waves.json 변경값','', '| DAY | 행(1부터)/적 | 지도 | 필드 | 기존 | 적용 |','|---|---|---|---|---|---|']
    changed=0
    for day in DAYS:
        for index,row in enumerate(waves['day_'+str(day)],1):
            for grade,fields in row.get('grade_routes',{}).items():
                for field,value in fields.items():
                    changed+=1
                    lines.append(f"| {day} | {index}/{row['enemy_id']} | {grade} | {field} | {row.get(field,'없음')} | {value} |")
    if not changed: lines.append('| — | — | — | 변경 없음 | — | — |')
    lines+=['','## 완료 상태','',f"- 실측 {len(rows)}/400행, 중복 제외 {len(unique)}행.",f"- 목표 이탈 또는 미완료: {', '.join(str(i['day']) for i in issues) or '없음'}.",'- DAY29 준비일 유지. 전체 회귀·전체 캠페인·출시 검수는 미요청.','- 사용자 확인 대기.']
    (OUT/'balance_dc.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    (OUT/'balance_summary.json').write_text(json.dumps(dict(checks=checks,summary=summary),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(checks,ensure_ascii=False))

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('--name',default='final_rows');parser.add_argument('--images',action='store_true')
    parser.add_argument('--prepare',action='store_true');parser.add_argument('--days',default=','.join(map(str,DAYS)))
    parser.add_argument('--layouts',default=','.join(MODES));parser.add_argument('--trials',type=int,default=10)
    parser.add_argument('--reference-e',action='store_true');parser.add_argument('--door-center',action='store_true')
    args=parser.parse_args()
    if args.prepare:
        config=dict(name=args.name,days=[int(v) for v in args.days.split(',')],layouts=args.layouts.split(','),trials=args.trials,reference_e=args.reference_e,door_goal_center=args.door_center)
        dest=ROOT/'tmp/v130r_step10/config.json';dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_text(json.dumps(config,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print(dest);raise SystemExit(0)
    if args.images: comparisons();previews()
    report(args.name)
