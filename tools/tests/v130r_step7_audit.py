"""Publish actual game captures, simulation tables and preservation evidence."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step7'
DEST = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step7_monsters')


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'previews').mkdir(exist_ok=True)
    before = json.loads((LOCAL / 'before.json').read_text(encoding='utf-8'))
    changed = [p for p, digest in before.items()
               if not (ROOT / p).is_file() or hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != digest]
    names = ['roster_24', 'battle_new_day15', 'directions', 'join_scene', 'compare_scale']
    names += ['skill_' + skill for skill in ['tongue_snag', 'no_passage', 'peekaboo', 'tunnel_hop', 'cheese_reclaim', 'reassemble']]
    for name in names:
        source = LOCAL / (name + '.png')
        im = Image.open(source)
        assert im.size == (1920, 1080), (name, im.size)
        shutil.copy2(source, DEST / source.name)
        im.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        im.save(DEST / 'previews' / source.name)
    direct = json.loads((LOCAL / 'direct_result.json').read_text(encoding='utf-8'))
    capture = json.loads((LOCAL / 'capture_result.json').read_text(encoding='utf-8'))
    balance = json.loads((LOCAL / 'balance_result.json').read_text(encoding='utf-8'))
    for result in [direct, capture, balance]:
        assert result['result'] == 'TARGETED_PASS', result['failures']
    duos = direct['evidence']['duos']
    duo_text = ['# 합동기 해금 직접 검사', '', '실제 `_grant_monster_bond`로 유대25→45, 유효한 기억1개 이상을 얻었다.',
                '함께 출전3일·역할 조합5회는 서비스 API로 기록한 시험 데이터다. 개인 세이브를 읽거나 수정하지 않았다.', '',
                '| 합동기 | 기억 이벤트 | 결과 |', '|---|---|---|']
    mapping = {'link_spore_jelly_shelter': '포자 젤리 피난처', 'link_stone_march': '석상 행진곡', 'link_false_beacon_vault': '가짜 등대 금고'}
    for key in duos['catalog']:
        duo_text.append(f'| {mapping[key]} | {key} | 유효 기억 획득→기억 이벤트 자격→해금 PASS |')
    (DEST / 'duo_unlock_test.md').write_text('\n'.join(duo_text) + '\n', encoding='utf-8')
    rows = balance['evidence']['balance']
    table = ['# DAY별 추천 배치 자동 전투', '',
             '실제 ApprovedBattleController/Unit/원본 DAY 웨이브를 1/30초 간격으로 실행했다. 같은 프로세스에서 10개 seed씩 반복했다.',
             'Tween은 같은 simulation delta로 custom_step했다. 결과 UI·정산만 시험 컨트롤러에서 생략했다.',
             '초기 옥좌1500, 몬스터 Lv1, 기존 계약 모리·돌콩 선택, 전선·의회 미완료, 신규종은 join_day 도달분만 포함한다.',
             '매일 독립 시험이며 이전 날 성장·부상·기억·전문화·원정/칙령·굶주림을 이월하지 않는다. 식량은 하루 수입 안에서 기본 자동 추천한다.',
             'DAY20 이후 D/C 도면이 없어 기존 정책대로 E 지도를 사용한다. 이 표는 전체 캠페인 승률 추정이 아니다.',
             '동일 배치·결정적인 전투라 seed별 결과가 같으면 확률적인 난이도 근거로 해석하지 않는다. 수치 조정 없음.', '',
             '| DAY | 시험 수 | 출전(신규) | 유지비/수입 | 승률 | 평균 옥좌 HP | 최소–최대 | 판정 |', '|---|---:|---:|---:|---:|---:|---:|---|']
    for day in [5, 10, 15, 20, 25, 30]:
        group = [r for r in rows if r['day'] == day]
        assert len(group) == 10
        rate = 100 * sum(r.get('win', False) for r in group) / len(group)
        hp = [100 * r['throne_hp'] / r['throne_max'] for r in group]
        avg = sum(hp) / len(hp)
        first = group[0]
        members = first['assignments']
        new_count = sum(key.startswith('mon_v130r_') for key in members)
        flag = '너무 쉬움' if rate == 100 and avg >= 95 else '너무 어려움' if rate <= 50 else '범위 내'
        income = 15 if day < 15 else 23 if day < 20 else 30 if day < 27 else 34
        table.append(f"| {day} | {len(group)} | {len(members)}({new_count}) | {first['upkeep']}/{income} | {rate:.0f}% | {avg:.1f}% | {min(hp):.1f}–{max(hp):.1f}% | {flag} |")
    (DEST / 'balance_sim.md').write_text('\n'.join(table) + '\n', encoding='utf-8')
    alpha = []
    for folder in sorted((ROOT / 'assets/sprites/v130r/quarter_final').iterdir()):
        for suffix in ['_sheet.png', '_sheet_ne.png']:
            path = folder / (folder.name + suffix)
            image = Image.open(path)
            assert image.mode == 'RGBA', path
            extrema = image.getchannel('A').getextrema()
            assert extrema[0] == 0 and extrema[1] >= 192, path
            alpha.append({'path': path.relative_to(ROOT).as_posix(), 'size': image.size, 'alpha': extrema})
    assert len(alpha) == 48
    for name in ['direct_result.json', 'capture_result.json', 'balance_result.json', 'balance_rows.json']:
        shutil.copy2(LOCAL / name, DEST / name)
    report = {'prior_files': len(before), 'prior_changed': changed, 'native_alpha_sheets': alpha,
              'captures': names, 'direct_checks': direct['checks'], 'capture_checks': capture['checks'],
              'balance_checks': balance['checks'], 'balance_trials': len(rows)}
    (DEST / 'audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    assert not changed, changed
    print(json.dumps({k: v for k, v in report.items() if k != 'native_alpha_sheets'}, ensure_ascii=False))


if __name__ == '__main__':
    main()
