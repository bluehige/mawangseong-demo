"""Generate honest UTF-8 story, duo and paired balance evidence from local runs."""
from pathlib import Path
from collections import Counter, defaultdict
from statistics import mean
import json
import subprocess
import hashlib
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '_mockup/game_step11_story'
STORY = ROOT / 'data/v130r/story'
FILES = ['join_scenes', 'day_overlays', 'barks', 'bond_scenes', 'duo_scenes']
DAYS = [20, 24, 27, 30]
LAYOUTS = ['recommended', 'anchor_cluster', 'final_line', 'first_line']
CAPTURES = ['join_scene_ko', 'join_scene_en', 'day_overlay_d20', 'bark_battle', 'bond_scene', 'duo_new']


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, value):
    path.write_text(value if isinstance(value, str) else json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')


def cues(doc):
    for scene in doc['scenes']:
        for block in scene.get('segments', [scene]):
            yield from block['cues']


def emotions():
    stats = defaultdict(lambda: [Counter(), Counter()])
    changed, text_changes = [], []
    for name in FILES:
        path = f'data/v130r/story/{name}.json'
        original = json.loads(subprocess.check_output(['git', 'show', '15b6f24e:'+path], cwd=ROOT))
        old = {c['id']: c for c in cues(original)}
        for c in cues(read(ROOT/path)):
            a = old[c['id']]
            stats[c['speaker_label']][0][a['emotion_direction']] += 1
            stats[c['speaker_label']][1][c['emotion_direction']] += 1
            if c['emotion_direction'] != a['emotion_direction']:
                changed.append((c['id'], c['speaker_label'], a['emotion_direction'], c['emotion_direction'], c['portrait_emotion'], c['text']))
            if c['text'] != a['text']:
                text_changes.append((c['id'], a['text'], c['text']))
        for locale in ['en', 'zh_cn']:
            source = json.loads(subprocess.check_output(['git', 'show', f'15b6f24e:data/v130r/story/localization_story_{locale}.json'], cwd=ROOT))
            actual = read(STORY/f'localization_story_{locale}.json')
            for a, b in zip(cues(source['documents'][name+'.json']), cues(actual['documents'][name+'.json'])):
                assert a['id'] == b['id'] and a['text'] == b['text'], f'{locale} body changed: {a["id"]}'
    lines = ['# 감정 재지정 — 사용자 확인 대기', '',
             'Claude 호출 도구가 없어 Claude 재검수는 미실행. 제공된 지적을 반영한 문맥·성격별 수정이다. 세 언어 본문 930턴씩 보존. 새로운 표정 그림은 만들지 않았다.', '',
             '| 화자 | 이전 담담 | 이후 담담 | 최종 감정 집계 |', '|---|---:|---:|---|']
    for name, (before, after) in stats.items():
        lines.append(f'| {name} | {before["담담"]} | {after["담담"]} | '+', '.join(f'{k} {v}' for k, v in after.items())+' |')
    lines += ['', f'감정 변경 {len(changed)}턴. 마왕 허세→proud·당황→flustered·억울→offended·결심→serious, 바티 건조→dry·냉정→stern. 골딘은 accounting 외 별도 당황 그림이 없어 base를 사용한다.', '',
              '| 대사 ID | 화자 | 이전 | 이후 | 실제 초상화 슬롯 | 본문(보존) |', '|---|---|---|---|---|---|']
    lines += ['| '+' | '.join(str(v).replace('|', '/') for v in row)+' |' for row in changed]
    lines += ['', '## 문장 수정표', '', '없음 — 명백한 오류로 확정할 문장이 없어 본문을 유지했다.']
    assert not text_changes
    write(OUT/'emotion_table.md', '\n'.join(lines)+'\n')
    return len(changed)


def duos():
    definitions = read(ROOT/'data/v130r/duo_links_new.json')
    descriptions = {
        'web_bridge': '최대 3명 속박 2초·둔화 4초(속도 65%)',
        'slippery_flame': '최대 3명 피해 18·둔화 4초(속도 65%)',
        'toll_vault': '최대 2명 피해 24·보유한 도난 금화 50% 회수',
        'marked_ambush': '1명 피해 36·표식 5초',
        'plate_exchange': '주변 아군 보호막 30·방어 +2/5초',
        'candle_ember': '최대 3명 피해 20·표식 5초',
        'underground_march': '최대 3명 피해 16·사기 피해 20, 주변 아군 방어 +2/4초',
        'false_map': '최대 3명 속박 1.5초·표식 5초',
        'false_treasure': '최대 2명 속박 2초·보유한 도난 금화 50% 회수',
        'sewn_bond': '주변 아군 보호막 28·즉시 회복 12·부정 상태 1개 정화',
    }
    lines = ['# 신규 합동기 10개 — 사용자 확인 대기', '',
             '전부 각자 유대 45·개인 기억 1개·서로 다른 함께 출전일 3일·양쪽 역할조합 5회에서 해금한다. 최대 2개 장착, 멤버 중복 참여 금지, 둘 다 출전·생존해야 한다. 게이지 0→100, 행동당 최대 +10, 전투당 1회. 기존 Unit의 피해·속박·둔화·표식·보호막·회복 함수를 조합한다.', '',
             '신규 수치는 이번 구현 가정이며 몬스터 기본·개인 스킬·웨이브 수치는 변경하지 않았다. 공격은 양쪽 멤버 중 한 명의 반경 안에 대상이 있을 때만 게이지를 소비한다. 지원도 두 멤버 반경 안에만 적용한다. 발동 후 두 멤버 행동 잠금 0.6초.', '',
             '| 이름 / 짝 | 효과 처리 함수 | 효과 | 반경(월드px) | 게이지(멤버 순) |', '|---|---|---|---:|---|']
    for key, d in definitions.items():
        handler = d['effect_handler'].removeprefix('v130r_')
        gauge = ', '.join(f'{s["source_id"]} {s["threshold"]}회/피해당 +{s["gain"]}' for s in d['gauge_sources'])
        lines.append(f'| {d["display_name"]} / {"+".join(d["member_names"])} | `{d["effect_handler"]}` | {descriptions[handler]} | {d["effect"]["radius"]:.0f} | {gauge} |')
    lines += ['', '수치 검증: `duo_effect_checks.json`, 전체 직접 시험: `direct_checks.json`. 재측정의 해금·장착 가정은 `balance_table.md`에 명시한다. 지원 보호막은 기존 duo_barrier 방식으로 전투 종료/소모까지 유지되며 시간제 보호막으로 소개하지 않는다.']
    write(OUT/'duo_table.md', '\n'.join(lines)+'\n')


def metric(rows):
    return {'n': len(rows), 'win': mean(bool(r.get('win')) for r in rows)*100,
            'hp': mean(r['throne_hp']/r['throne_max'] for r in rows)*100,
            'gold_loss': mean(r['gold_loss'] for r in rows),
            'uses': sum(len(r.get('activations', [])) for r in rows)}


def balance():
    rows = {c: read(OUT/f'{c}_rows.json') if (OUT/f'{c}_rows.json').exists() else [] for c in ['off', 'on']}
    expected = {(d, m, n) for d in DAYS for m in LAYOUTS for n in range(10)}
    complete = all({(r['day'], r['layout'], r['trial']) for r in v} == expected and len(v)==160 for v in rows.values())
    lines = ['# Step11 합동기 영향 재측정 — 사용자 확인 대기', '',
             '현재 D/C 지도·0108b 웨이브, 각 DAY 독립 스냅샷. 기존 성장 공식·모리/돌콩 계약·식량·합법 정원·금1200/마나600·옥좌1500·전문화 없음 유지. 각 배치 동일 시드130800~130809, 60Hz. DAY29는 전투 없는 준비일이다.', '',
             '**OFF:** 합동기 미해금·미장착. **ON:** 신규10개를 과거에 해금했다고 가정하되 bond 스탯 보너스는 추가하지 않는다. 현재 출전한 두 멤버가 모두 있는 합동기를 ID 사전순으로 최대2개, 멤버 중복 없이 장착한다. 실제 행동으로 게이지0부터 충전하고 자동 발동하며 100강제충전은 하지 않는다. 등장·계약 조건과 추천 병력은 바꾸지 않는다. 자연 캠페인에서 이 날짜까지 모두 해금된다는 증거가 아니다.', '',
             '각 행 원자료에 unlocked/equipped/duo_states/activations를 남긴다. 양쪽 출전 합동기가 없으면 ON도 장착0으로 기록한다. 승률은 10표본이며 평균HP에는 패배0HP가 포함된다.', '',
             '| DAY | 배치 | OFF 표본/승률/평균HP | ON 표본/승률/평균HP | ON 실제 사용 |', '|---:|---|---|---|---:|']
    summary = {}
    for day in DAYS:
        for mode in LAYOUTS:
            values = {}
            for condition, values_rows in rows.items():
                subset = [r for r in values_rows if r['day']==day and r['layout']==mode]
                if subset: values[condition] = metric(subset)
            summary[f'{day}:{mode}'] = values
            def label(c):
                m = values.get(c)
                return f'{m["n"]}/ {m["win"]:.0f}% / {m["hp"]:.1f}%' if m else '미실행'
            lines.append(f'| {day} | {mode} | {label("off")} | {label("on")} | {values.get("on",{}).get("uses","-")} |')
    historical = {20: ['90/62.4', '90/62.4', '80/50.6'], 24: ['80/57.1', '80/57.1', '90/56.5'], 27: ['90/41.1', '90/43.2', '70/42.5'], 30: ['80/38.7', '90/44.0', '80/48.5']}
    lines += ['', '## 과거 기준표 (추천 승률% / 평균HP%, 재실행값 아님)', '', '| DAY | 0104 E | 0106 E | 0108b D/C |', '|---:|---|---|---|']
    lines += [f'| {d} | '+' | '.join(historical[d])+' |' for d in DAYS]
    lines += ['', '0104/0106/0108b의 기존 표를 비교 기준으로 보존했다. 이번 OFF/ON은 현재 0108b 위의 합동기 영향 측정이며 과거판을 새 조건으로 다시 실행한 값으로 부르지 않는다. 과거 0104 정원초과 몰빵은 합법 집중과 같은 배치가 아니다.', '', f'완료 여부: {"320회 완료" if complete else "진행 중 또는 외부 Godot 사용으로 대기"}. 전체 캠페인·전체 회귀·export 미실행.']
    if complete:
        assert all(r['simulation_hz']==60 and r['day']!=29 for v in rows.values() for r in v)
        assert all(r['fixture']['legal'] for v in rows.values() for r in v)
        off = {(r['day'],r['layout'],r['trial']):r for r in rows['off']}
        for r in rows['on']:
            a = off[(r['day'],r['layout'],r['trial'])]
            assert a['assignments']==r['assignments'] and a['wave_entries']==r['wave_entries']
        previous = {(r['day'],r['layout'],r['trial']):r for r in read(ROOT/'_mockup/game_step10_dc/final_rows.json')}
        differences = []
        for key, r in off.items():
            for field in ['win', 'throne_hp', 'duration', 'gold_loss', 'spawned']:
                if r.get(field) != previous[key].get(field):
                    differences.append([*key, field])
        lines += ['', f'OFF의 기존 0108b 시드별 승패·HP·시간·금고손실·출현수 대조: 차이 {len(differences)}건.']
        summary['off_baseline_differences'] = differences
        assert not differences, differences[:5]
        lines += ['', '## 추천 배치의 기존 목표 곡선과 ON 관측', '', '| DAY | 기존 승률/HP 목표 | ON 판정 |', '|---:|---|---|']
        for day in DAYS:
            limits = {20:(80,95,45,65),24:(80,95,50,75),27:(70,90,40,65),30:(70,90,35,55)}[day]
            m = summary[f'{day}:recommended']['on']
            within = limits[0] <= m['win'] <= limits[1] and limits[2] <= m['hp'] <= limits[3]
            lines.append(f'| {day} | {limits[0]}–{limits[1]}% / {limits[2]}–{limits[3]}% | {"범위 내" if within else "범위 밖(관측값 유지)"} |')
        lines += ['', '범위 밖 수치는 측정 실패로 숨기거나 웨이브를 조정하지 않는다. 해금 가정을 포함한 표본 변화로 기록한다.']
    write(OUT/'balance_table.md','\n'.join(lines)+'\n')
    write(OUT/'balance_summary.json',{'complete':complete,'row_counts':{k:len(v) for k,v in rows.items()},'summary':summary})
    return complete


def previews():
    folder = OUT/'previews'; folder.mkdir(exist_ok=True)
    found = []
    for name in CAPTURES:
        path = OUT/(name+'.png')
        if path.exists():
            image = Image.open(path); image.thumbnail((960,540)); image.save(folder/path.name)
            found.append(name)
    return found


if __name__ == '__main__':
    OUT.mkdir(exist_ok=True)
    changed = emotions(); duos(); complete = balance(); captures = previews()
    print(json.dumps({'emotion_changes':changed,'balance_complete':complete,'captures':captures},ensure_ascii=False))
