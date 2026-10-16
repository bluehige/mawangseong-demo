"""Publish actual F viewport evidence; UTF-8 paths, one reduced preview per file."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT/'tmp/v130r_step5'
DEST = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step5_gradeF')
NAMES = ['f_full', 'f_start', 'f_battle_day3', 'f_to_e_transition_before', 'f_to_e_transition_after']


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST/'previews').mkdir(exist_ok=True)
    for name in NAMES:
        picture = Image.open(LOCAL/(name+'.png'))
        assert picture.size == (1920,1080), (name, picture.size)
        shutil.copy2(LOCAL/(name+'.png'), DEST/(name+'.png'))
        picture.thumbnail((1000,600), Image.Resampling.LANCZOS)
        picture.save(DEST/'previews'/(name+'.png'))
    plan = Image.open(DEST.parent/'plan/plan_F.png').convert('RGB')
    fitted = ImageOps.contain(plan, (1920,1080), Image.Resampling.LANCZOS)
    left = Image.new('RGB', (1920,1080), plan.getpixel((0,0)))
    left.paste(fitted, ((1920-fitted.width)//2, (1080-fitted.height)//2))
    comparison = Image.new('RGB', (3840,1080))
    comparison.paste(left, (0,0))
    comparison.paste(Image.open(LOCAL/'f_full.png').convert('RGB'), (1920,0))
    comparison.save(DEST/'compare_f_vs_plan.png')
    comparison.thumbnail((1000,600), Image.Resampling.LANCZOS)
    comparison.save(DEST/'previews/compare_f_vs_plan.png')
    prior = json.loads((LOCAL/'existing_hashes.json').read_text(encoding='utf-8'))
    changed = [p for p,h in prior.items() if not (ROOT/p).is_file() or hashlib.sha256((ROOT/p).read_bytes()).hexdigest() != h]
    assert not changed, changed
    results = {}
    for mode in ['direct','capture']:
        result = json.loads((LOCAL/(mode+'_result.json')).read_text(encoding='utf-8'))
        assert result['result'] == 'TARGETED_PASS', (mode, result['failures'])
        shutil.copy2(LOCAL/(mode+'_result.json'), DEST/(mode+'_result.json'))
        results[mode] = result['checks']
    regression_path = ROOT/'tmp/v130r_step4/direct_result.json'
    regression = json.loads(regression_path.read_text(encoding='utf-8'))
    assert regression['result'] == 'TARGETED_PASS', regression['failures']
    results['E_battle_regression'] = regression['checks']
    shutil.copy2(regression_path, DEST/'e_battle_regression_result.json')
    alpha = {}
    for side in ['down','up']:
        path = ROOT/f'assets/maps/v130r_step5/cliff_{side}_cell.png'
        alpha[side] = Image.open(path).getchannel('A').getextrema()
        assert alpha[side] == (0,255), alpha
        source = ROOT/f'assets/source/imagegen/v130r_step5/approved_cliff_{side}_flat.png'
        assert source.read_bytes() == (ROOT/f'assets/maps/v130r_step1/cliff/straight_{side}_flat.png').read_bytes()
    (DEST/'differences.md').write_text('''# F 도면·기획과 다른 점 — 사용자 확인 대기

| 항목 | 기준 도면/기획 | 실제 게임 |
|---|---|---|
| 부지·시설·물·길·함정 | 22×16, 건물 6개, 길 함정 4개 | 칸 데이터 그대로. 길/수비칸/다리로 표시된 74칸과 물길 44칸 일치, 다리 8칸. 자동 길 조립 결과의 누락·추가 0칸 |
| 투영 | 왼쪽 입구→오른쪽 옥좌의 평면도 | E와 같은 등각 투영식, W=22. 평면도와 방향이 달라 보이며 좌표 데이터는 동일 |
| 그림 | 색 직사각형·글자·빗벽 기호 | 기존 assets_v7d GPT 건물/바닥/물/다리/절벽/동굴. 신규 그림 생성 호출 0, 코드 그림/글씨 버튼 추가 0 |
| 등급 F 분위기 | 비 새는 동굴·축축한 원룸 | E와 같은 기존 돌바닥/동굴/호화 옥좌·금고 재사용. 별도 누수·작은 F 옥좌 그림은 만들지 않음 |
| 시작 카메라 | 0087과 같은 화면당 칸 수 | 1920×1080에서 배율0.75, 칸96×48, world2560×1440. F 중심(2112,1120). 옥좌 위·외부 다리 끝 일부가 잘리며 F 전체 보기로 확인 |
| 수비 칸 | m 기호 15칸 | 기본 위치 6시설은 지정 15칸과 정확히 일치. 이동/추가 건물만 기존 문 앞 자동 규칙을 사용. 빈 칸은 옅은 GPT 하이라이트 |
| E 지도 | E 도면에는 회복 둥지·결계핵도 있음 | F에서 가진 6건물만 이전. E 전환으로 새 건물을 무료 지급하지 않으며, 이후 해금/건설 규칙 사용 |
| 전환 캡처 | F→E | DAY14 F→DAY15 E, 같은 기본4명. 옥좌/금고/세 배치시설 좌표 이동, 입구는 도면 좌표(0,7)가 양쪽 동일하며 투영 위치는 변함 |
| 실제 DAY3 | 원본 웨이브 | 탐험가3·도둑1·수습 용사1, 기존 HP/공격 배율/시간/스킬 유지. 기본4명 Lv1, 원본 전투 완주. 첫 교전 장면은 잠시 일시정지하여 캡처 |
| 결과 이어가기 | 등급 진행 | 기존 결과의 다음 날 콜백으로 격리 미리보기에서 날짜/지도 교체. 개인 캠페인 저장·스토리·식량 정산 통합은 기존 단계와 마찬가지로 별도 |
| D·C | 도면 미정 | 3·4단계의 기능 단계만 진행, 지도는 E 유지. 이번 맵 선택 기준일은 DAY21/28(기존 승리후20/27 기준), F→E는 명시 지시대로 DAY15 |

전체 회귀·전체 캠페인·외부 배포는 이번 검수 범위가 아니다. 기하학/전투 검사는 통과했으며 화면·가정은 사용자 확인 대기.
''', encoding='utf-8')
    (DEST/'transition_rules.md').write_text('''# F→E 이전 규칙 — 사용자 확인 대기

| 대상 | 규칙 | 보존/예외 |
|---|---|---|
| 등급 | stage_01 DAY1–14=F, stage_02 DAY15부터=E | stage_03/04도 E. 날짜 역행 거부 |
| 입구 | (0,7,3,3)→(0,7,3,3), E 고정 문 사용 | ID·강화·수용량·지불금 유지, W22→W32 투영 위치 이동 |
| 옥좌 | (17,0,5,5)→(27,0,5,5) | E 고정 문/수비 칸 재계산 |
| 금고 | (18,11,4,4)→(28,11,4,4) | E 고정 문/수비 칸 재계산 |
| 병영 | (3,0,5,5)→기본 (10,1,5,5) | 기존 ID/종류·강화·수용량·지불금 유지 |
| 감시탑 | (3,11,3,3)→기본 (3,3,3,3) | 같은 종류 기본자리 우선 |
| 미끼보물실 | (7,11,3,3)→기본 (3,12,3,3) | 같은 종류 기본자리 우선 |
| 추가/이동 건물 | 같은 종류 E 기본 자리, 불가하면 y→x 순 빈 자리 | 물/고정시설/2칸 통로 연결·문 검사를 통과한 첫 자리. 같은 종류 기본 위치는 한 건물만 차지 |
| 공간 부족 | 이전 전체 거부, 이전 상태 보존 | 건물 삭제·무료 환급/자동 철거 없음 |
| 몬스터 | 같은 건물 ID의 같은 슬롯 우선, 불가하면 그 건물 첫 빈 슬롯 | 해당 건물에 자리가 없으면 대기(배치 사전에서 해제), 다른 건물에 자동 배치하지 않음 |
| 함정 | 원래 좌표에 가장 가까운 마른 E 길 | 맨해튼 거리→y→x 순, 종류/개수 유지, 다리 제외, 중복 칸 제외 |
| 자원·ID | 전체 자원·serial 유지 | 결과 이어가기는 기존 정산 후 잔액 사용. 사용자 세이브는 읽거나 수정하지 않음 |
| 3·4단계 | E 지도 그대로 | 등급별 무료 건물·자동 수용량 증가 추가 없음 |

좌표는 (x,y,가로,세로), 0부터 시작. 직접 검사에는 정상 F 데이터, 추가 병영의 빈자리 이전, 공간 부족 거부, 초과 몬스터 대기를 포함했다.
''', encoding='utf-8')
    report = dict(result='TARGETED_PASS', captures=5, comparison=[3840,1080], preview_max=[1000,600],
                  existing_files_preserved=len(prior), changed_existing=changed, checks=results, cliff_alpha=alpha)
    (DEST/'capture_audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__': main()
