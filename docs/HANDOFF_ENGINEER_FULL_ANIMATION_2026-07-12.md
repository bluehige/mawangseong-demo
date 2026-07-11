이 파일이 왜 필요한지: DAY 20 왕국 공병의 임시 변형 프레임을 실제 연속 동작 원화로 교체한 기준, 생성 출처, 검수 결과를 다음 작업자가 바로 확인할 수 있게 남긴다.

# 왕국 공병 전체 애니메이션 핸드오프

작성일: 2026-07-12

## 결론

왕국 공병의 대기·이동·공격·시설 교란·쓰러짐을 프로젝트 규칙에 맞는 총 16개의 실제 연속 동작 프레임으로 교체했다.

- 대기 `idle_down`: 2프레임, 5 FPS
- 이동 `move_down`: 4프레임, 10 FPS
- 공격 `attack_down`: 4프레임, 10 FPS
- 시설 교란 `skill_down`: 4프레임, 8 FPS
- 쓰러짐 `down`: 2프레임, 7 FPS

각 프레임은 내장 이미지 생성기가 새로 그린 원화다. 기존처럼 한 장을 확대·회전·이동해서 동작처럼 보이게 만드는 방식은 사용하지 않는다.

## 동작 설계

- 대기: 들숨과 날숨에 따라 어깨, 몸통, 옷자락, 손과 장비가 자연스럽게 이동한다.
- 이동: 왼발 접지 → 통과 자세 → 오른발 접지 → 반대 통과 자세의 보행 순환이다.
- 공격: 준비 → 가속 → 쇠지렛대 타격 → 복귀의 비반복 동작이다.
- 시설 교란: 장치 내리기 → 바닥 설치 → 상단 조작부 누르기 → 손을 떼고 일어나기의 비반복 동작이다.
- 쓰러짐: 균형 상실 → 바닥에 옆으로 완전히 쓰러짐의 비반복 동작이다.

## 그래픽 출처

투명 배경으로 정리한 제작 원본:

- `assets/source/imagegen/engineer/CHR_ENGINEER_idle_sheet_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_move_sheet_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_attack_sheet_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_skill_sheet_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_down_sheet_imagegen.png`

상세 생성 프롬프트와 내장 이미지 생성기의 원본 저장 경로는 `assets/source/imagegen/engineer/SOURCE.md`에 기록했다.

런타임 파일:

- `assets/sprites/enemies/enemy_engineer_idle_down_00~01.png`
- `assets/sprites/enemies/enemy_engineer_move_down_00~03.png`
- `assets/sprites/enemies/enemy_engineer_attack_down_00~03.png`
- `assets/sprites/enemies/enemy_engineer_skill_down_00~03.png`
- `assets/sprites/enemies/enemy_engineer_down_00~01.png`

`tools/prepare_engineer_enemy_assets.py`는 원본 시트를 읽기 순서대로 자르고 전체 칸을 192×192로 축소한다. 동작을 만드는 회전·이동·변형은 하지 않으며, 투명 배경 가장자리에 남은 작은 조각만 제거한다.

## 자동 검수 보강

`tools/DemoSmokeTest.gd`에 다음 검사를 추가했다.

- 다섯 imagegen 원본 시트 존재
- 애니메이션별 정확한 프레임 수
- 같은 애니메이션 안에서 모든 프레임의 픽셀 데이터가 서로 다름
- 애니메이션별 FPS가 규칙과 일치
- 공격 4프레임을 모두 보여 줄 재생 시간 확보
- 공병이 시설에 도착하면 `skill_down`이 재생되고 시설이 10초간 무력화됨

## 검수 결과

1. `python tools/prepare_engineer_enemy_assets.py`
   - 총 16프레임 생성 성공
   - 모든 프레임의 투명 여백과 경계 접촉 검사 통과
   - 검수용 연속 시트: `tmp/asset_previews/engineer_animation_sequences.png`
2. `godot --headless --path . --import`
   - 종료 코드 0
3. `godot --headless --path . --scene res://tools/DemoSmokeTest.tscn`
   - 종료 코드 0
   - `DEMO_SMOKE_TEST: PASS`
4. `godot --path . --scene res://tools/UIRegressionVisualReview.tscn`
   - 종료 코드 0
   - DAY 20 공병 목표 이동, 시설 교란, 결과 화면 캡처 확인
   - 공병의 전장 표시 크기, 투명 외곽, 시설 설치 자세, 무력화 표시와 결산 문구가 정상

## 다음 작업

공병 애니메이션은 완료 상태다. 다음 캠페인 제작은 DAY 22 기획·구현으로 이어가면 된다.
