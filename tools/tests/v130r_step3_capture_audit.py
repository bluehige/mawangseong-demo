"""Publish real viewport captures and individual reduced previews using UTF-8 paths."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'tmp/v130r_step3'
DEST = Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step3_place')
MOCKUP = DEST.parent / 'ui_icons_v1/ui_preview_place.png'
NAMES = ['place_01_roster', 'place_02_drag', 'place_03_placed', 'place_04_info', 'place_05_auto', 'place_06_food_warn']

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    (DEST / 'previews').mkdir(exist_ok=True)
    checks = []
    for name in NAMES:
        im = Image.open(LOCAL / f'{name}.png')
        assert im.size == (1920, 1080), (name, im.size)
        shutil.copy2(LOCAL / f'{name}.png', DEST / f'{name}.png')
        im.thumbnail((1000, 600), Image.Resampling.LANCZOS)
        im.save(DEST / 'previews' / f'{name}.png')
        checks.append(f'1920x1080 actual viewport: {name}')
    left = Image.open(MOCKUP).convert('RGB').resize((1920, 1080), Image.Resampling.LANCZOS)
    right = Image.open(LOCAL / 'place_03_placed.png').convert('RGB')
    compare = Image.new('RGB', (3840, 1080))
    compare.paste(left, (0, 0)); compare.paste(right, (1920, 0))
    compare.save(DEST / 'compare_place_vs_mockup.png')
    compare.thumbnail((1000, 600), Image.Resampling.LANCZOS)
    compare.save(DEST / 'previews/compare_place_vs_mockup.png')
    existing = json.loads((LOCAL / 'existing_hashes.json').read_text(encoding='utf-8'))
    changed = [p for p, h in existing.items() if not (ROOT/p).is_file() or hashlib.sha256((ROOT/p).read_bytes()).hexdigest() != h]
    assert not changed, changed
    for mode in ['direct', 'capture']:
        result = json.loads((LOCAL / f'{mode}_result.json').read_text(encoding='utf-8'))
        assert result['result'] == 'TARGETED_PASS', result
        shutil.copy2(LOCAL / f'{mode}_result.json', DEST / f'{mode}_result.json')
    (DEST / 'differences.md').write_text('''# 배치 목업 대비 차이 — 사용자 확인 대기

| 항목 | 목업·기획 | 이번 실제 게임 |
|---|---|---|
| 지도 | 평면 색상 격자·원형 몬스터 기호 | 0088 GPT 조립 지도·기존 GPT 개체 그림 |
| 하단 명단 | 예시 7장·이니셜 카드 | 기존 14개체 초상화·역할·레벨·유지비, 복제 없음 |
| 상단 | 한 줄 전체 자원 HUD | 기존 좌측 HUD 유지, 식량 현재량과 유지비 추가 |
| 배치 수 | 목업 예시 12/18 | 현재 지도에서 계산한 실제 수비 칸 수 표시 |
| 식량 수입 | E등급 23/일 | 23/일, 수동 초과 허용·굶주림 위험, 실제 차감 미연결(0095) |
| 정보 | 병영 4/4 시설 설명 예시 | 클릭한 개체 바로 옆 GPT 패널·실제 스탯·기술 2~3개 |
| 수비 방향 | 입구 방향 | 기존 정면 대기 그림을 좌우 반전해 입구 방향. 14종 기본 시트에 별도 사선 방향 프레임 없음 |
| 로로 | 새 기획 배치 가능 | 미리보기 배치 가능. 기존 본편의 원정 전용 속성은 수정 안 함 |
| 합류 | 기존 계약·전선·의회 조건 | 기본 4명 해금, 미합류 잠금. --unlock-all 시험 플래그로 14명. 캠페인 합류 연결은 후속 |
| 스킬 | 새 지도·영향범위 | 기존 실제 이름/설명을 표시하고 방 단위 표현만 영향범위로 정리. 전투 효과 미연결 |
| 저장 | 사용자 세이브와 연동 | tmp/v130r_step3/copies/placement_test.json 격리 저장, 재실행 복원 |
| 설계서 | 설계서 3-3 | 지정 _design에는 몬스터 MD/JSON만 존재. 목업2개와 선행 인계로 배치 구조 확인, 3-3 원문 미확인 |
''', encoding='utf-8')
    result = {'result': 'TARGETED_PASS', 'captures': len(NAMES), 'existing_files_preserved': len(existing), 'changed_existing': changed, 'checks': checks}
    (DEST / 'capture_audit.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(result, ensure_ascii=True))

if __name__ == '__main__':
    main()
