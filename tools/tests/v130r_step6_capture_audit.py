"""Publish actual viewport captures and single reduced previews using UTF-8 paths."""
from pathlib import Path
import csv
import hashlib
import json
import re
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step6'
DEST = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step6_food')
NAMES = ['food_01_hud', 'food_02_settlement', 'food_03_hungry', 'join_01_scene']


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'previews').mkdir(exist_ok=True)
    for name in NAMES:
        picture = Image.open(LOCAL / (name + '.png'))
        assert picture.size == (1920, 1080), (name, picture.size)
        shutil.copy2(LOCAL / (name + '.png'), DEST / (name + '.png'))
        picture.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        picture.save(DEST / 'previews' / (name + '.png'))
    checks = {}
    for mode in ['direct', 'capture']:
        result = json.loads((LOCAL / (mode + '_result.json')).read_text(encoding='utf-8'))
        assert result['result'] == 'TARGETED_PASS', result
        assert not (LOCAL / (mode + '.err.log')).read_text(encoding='utf-8').strip()
        checks[mode] = result['checks']
        shutil.copy2(LOCAL / (mode + '_result.json'), DEST / (mode + '_result.json'))
    regression_path = ROOT / 'tmp/v130r_step4/direct_result.json'
    regression = json.loads(regression_path.read_text(encoding='utf-8'))
    assert regression['result'] == 'TARGETED_PASS', regression['failures']
    assert not (regression_path.parent / 'direct.err.log').read_text(encoding='utf-8').strip()
    checks['E_battle_regression'] = regression['checks']
    shutil.copy2(regression_path, DEST / 'E_battle_regression.json')
    heart_log = (LOCAL / 'heart.log').read_text(encoding='utf-8')
    heart = re.search(r'HUNGRY_HEART_PHASE6_TEST: PASS \((\d+) assertions\)', heart_log)
    assert heart and not (LOCAL / 'heart.err.log').read_text(encoding='utf-8').strip()
    checks['heart_regression'] = int(heart.group(1))
    shutil.copy2(LOCAL / 'heart.log', DEST / 'heart_regression.log')
    previous = json.loads((LOCAL / 'existing_hashes.json').read_text(encoding='utf-8'))
    changed = [p for p, digest in previous.items()
               if not (ROOT / p).is_file() or hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != digest]
    assert not changed, changed
    simulations = json.loads((LOCAL / 'simulation.json').read_text(encoding='utf-8'))
    shutil.copy2(LOCAL / 'simulation.json', DEST / 'simulation.json')
    rows = []
    for scenario, days in simulations.items():
        assert len(days) == 30
        for row in days:
            rows.append(dict(scenario=scenario, **{k: row[k] for k in
                ['day', 'before', 'income', 'count', 'due', 'paid', 'shortfall', 'overflow', 'after', 'capacity']},
                hungry=';'.join(row['hungry'])))
    with (DEST / 'food_day01_30.csv').open('w', encoding='utf-8-sig', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    # The complete table is also committed in the handoff, not in a build/output folder.
    table = ['# DAY 1–30 식량 시뮬레이션', '',
             '기존 14마리를 DAY1부터 전원 해금한 **경제 부하 시험**이다. 실제 계약·전선·의회 합류 일정으로 오인하지 않는다. '
             '시작 식량18, 원정/칙령/심장 보너스0, E 도면의 수비칸을 사용한다. '
             '추천은 실제 역할 자동 배치와 당일 수입 한도, 풀 배치는14마리29/일이다. '
             'F 부지에서 필요한 시설을 짓는 비용·실제 전투·신규10마리는 포함하지 않는다. '
             '두 경우 모두 런타임 `MonsterFoodService.settle()`을 매일 호출했다.', '',
             '| DAY | 수입 | 창고 | 추천 인원/유지비 | 추천 잔액 | 추천 미지급 | 풀14 잔액 | 풀14 미지급 | 풀14 굶주림 수 |',
             '|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for rec, full in zip(simulations['recommended'], simulations['full_14']):
        table.append(f"| {rec['day']} | {rec['income']} | {rec['capacity']} | {rec['count']}/{rec['due']} | "
                     f"{rec['after']} | {rec['shortfall']} | {full['after']} | {full['shortfall']} | {len(full['hungry'])} |")
    table += ['', '고정 지급 우선순위: `MonsterFoodService.COSTS` 순서. 부분 지급은 소모되며 해당 개체는 굶주림. '
              '수입→유지비→창고 초과 소실. 대기는0이며 다음 정산에서 배치 해제된 개체의 굶주림은 해제된다.', '']
    markdown = '\n'.join(table)
    (DEST / 'food_day01_30.md').write_text(markdown, encoding='utf-8')
    (ROOT / 'docs/handoff/V130R_STEP6_FOOD_SIMULATION_2026-10-16.md').write_text(markdown, encoding='utf-8')
    report = dict(result='TARGETED_PASS', captures=4, dimensions=[1920, 1080], preview_max=[1000, 600],
                  existing_files_preserved=len(previous), changed_existing=changed, checks=checks,
                  simulation_rows=len(rows), save_scope='test copies only')
    for path in [LOCAL / 'capture_audit.json', DEST / 'capture_audit.json']:
        path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    main()
