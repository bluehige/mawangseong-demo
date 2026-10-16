"""Publish native viewport PNGs with UTF-8 paths and single reduced previews."""
from pathlib import Path
from PIL import Image
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2]
LOCAL=ROOT/'tmp/v130r_step4'
DEST=Path('C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step4_battle')
NAMES=['battle_01_start','battle_02_contact','battle_03_trap','battle_04_skill','battle_05_command_bar','battle_06_result']

def main():
    DEST.mkdir(parents=True,exist_ok=True); (DEST/'previews').mkdir(exist_ok=True)
    for name in NAMES:
        image=Image.open(LOCAL/(name+'.png')); assert image.size==(1920,1080),(name,image.size)
        shutil.copy2(LOCAL/(name+'.png'),DEST/(name+'.png'))
        image.thumbnail((1000,600),Image.Resampling.LANCZOS); image.save(DEST/'previews'/(name+'.png'))
    mockup=Image.open(DEST.parent/'ui_icons_v1/ui_preview_battle.png').convert('RGB').resize((1920,1080),Image.Resampling.LANCZOS)
    actual=Image.open(LOCAL/'battle_04_skill.png').convert('RGB')
    comparison=Image.new('RGB',(3840,1080)); comparison.paste(mockup,(0,0)); comparison.paste(actual,(1920,0))
    comparison.save(DEST/'compare_battle_vs_mockup.png')
    comparison.thumbnail((1000,600),Image.Resampling.LANCZOS); comparison.save(DEST/'previews/compare_battle_vs_mockup.png')
    previous=json.loads((LOCAL/'existing_hashes.json').read_text(encoding='utf-8'))
    changed=[p for p,h in previous.items() if not (ROOT/p).is_file() or hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
    assert not changed,changed
    for mode in ['direct','capture','performance']:
        result=json.loads((LOCAL/(mode+'_result.json')).read_text(encoding='utf-8'))
        assert result['result']=='TARGETED_PASS',(mode,result)
        shutil.copy2(LOCAL/(mode+'_result.json'),DEST/(mode+'_result.json'))
    performance=json.loads((LOCAL/'performance_result.json').read_text(encoding='utf-8'))['evidence']['performance']
    lines=['# 성능 — 사용자 확인 대기','','실제 1920×1080 / OpenGL Compatibility / 최대 60fps / 준비 2초, 측정 18초. i5-13500, RTX 3060 Ti.','',
           '생산 명단은 14개체 고유성을 유지한다. 성능 시험에만 같은 기존 그림 4개체를 추가한 18 대 10 합성 부하를 사용했다. DAY 7 원본은 적 6명이며 별도로 완주했다.','','| 항목 | 측정값 |','|---|---:|']
    for key,value in performance.items(): lines.append(f'| {key} | {value} |')
    (DEST/'performance.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    (DEST/'differences.md').write_text('''# 전투 목업·기획과 다른 점 — 사용자 확인 대기

| 항목 | 목업·기획 | 이번 실제 게임 |
|---|---|---|
| 지도 | 평면 칸·원형 유닛 기호 | 기존 GPT 조립 지도·기존 GPT 애니메이션 |
| HUD | 상단 한 줄 전체 자원·옥좌·금고 | 기존 좌측 자원 HUD + 좌측 전투 상태·옥좌·도난 금액. 금고 건물 HP 신규 도입 없음 |
| 속도 | 우측 별도 4아이콘 | 요청에 따라 하단 명령 바 오른쪽 4아이콘 |
| 명령 | 비용을 쓸 수 있다는 기획 예시 | 기존 전술 지침 배율 재사용. 새 명령 비용은 근거 수치가 없어 추가하지 않음 |
| 직접 조종 | skill_direct_control_v2 | 신규 GPT 네이티브 투명 아이콘. 우클릭 길 이동, 재클릭 자동 복귀 |
| 스킬 연출 | 몬스터 옆 | 실제 몬스터 위치를 따라가는 기존 기술 아이콘. 기존 1초 화면 전환 연출은 전장 내 시전으로 치환, 효과·비용·재사용 시간 재사용 |
| 영향범위 | 건물 영향범위 | 기존 중심 반경 + 해당 건물 수비 칸. 5×5 회복 건물의 반경2.5가 외부 길에 닿지 않던 빈 구간 보정 |
| 감시탑 | 사거리 보너스 | 기존 노출 피해 배율1.18을 사거리1.18배로 매핑. 피해/감속 이중 적용 없음 |
| 목줄 | 구체 거리 미지정 | 기본 수비 칸에서 길3칸 상당 거리. 명령6초 또는 직접 조종 중 명시 이동 허용, 해제 시 복귀 |
| DAY 7 | 목업 적9·웨이브2/3 예시 | waves.json 원본 탐험가4·도둑2, 시간/능력치 배율 유지. 검수는 고유7명 Lv1 배치 |
| 성능 | 몬스터18 + 적10, 60fps 목표 | 별도 합성 부하로 측정. 실제 수치는 performance.md, DAY7 구성과 구분 |
| 세이브 | 본편 전투 합류 | 0089 안전 미리보기의 전투 탭에 연결. 사용자 세이브 접근·수정 없음, 개인 캠페인 합류는 별도 |
| 설계서3-1/3-3 | 기준 원문 | 지정 _design 폴더에는 몬스터 문서만 있음. 원문 미확인, 제공 목업2개·몬스터4장·기존 코드 기준 |
| 신규 몬스터 | 신규10종 스킬 | 이 작업은 칸 태그·임시 함정 API 제공. 새 몬스터 콘텐츠 자체는 별도 브랜치 대상 |
''',encoding='utf-8')
    report={'result':'TARGETED_PASS','captures':6,'existing_files_preserved':len(previous),'changed_existing':changed,'preview_max':[1000,600]}
    (DEST/'capture_audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(report))
if __name__=='__main__': main()
