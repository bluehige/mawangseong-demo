# V130R 2E — 원형 메뉴 반지름 축소

## 1. 메타데이터

- 작성일: 2026-10-16 KST
- WORKSTREAM_ID: V130R_STEP2E_RADIAL
- 목표 버전: 1.3.0 별도 안전 미리보기
- 작업 브랜치: `codex/v130r-defense-layout` 유지
- 기준 SHA: `7d28603d1fe792043525dfaafa1871e907c19a06` (0087 시작 카메라·폰트 완료)
- 마지막 구현·검증 SHA: `7edacee99619bb0e757f174da4fd1f2893c9d88c`
- 영어 로컬 커밋: `Shrink facility radial menus and turn edge actions inward`
- 본 인계/CURRENT는 후속 영어 로컬 문서 커밋. 최종 문서 SHA는 `git log -1`로 확인한다.
- 원격 조회/fetch·push·merge·PR·태그·Steam 모두 미실행.
- 권위 제한: 로컬 main 없음. `origin/main` 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, `v1.2.5` `f757ffa9f9e962158f2123856c8568a3163ecb6c`. 캐시 AGENTS/CURRENT는 읽었으나 원격 최신 권위 미확정. 사용자 지정 0087 위·같은 브랜치 작업을 따른다.
- 선행 인계: [0087 카메라·폰트](V130R_STEP2D_CAMERA_FONT_2026-10-16.md).

## 2. 이번 세션 목표

- 건물에 가까운 작은 원/호, 같은 반지름의 반투명 원판, 안쪽 가장자리 메뉴, 인접 정보창.
- 0087 시작 카메라 기준 실제1920×1080 요청4장·축소본 개별 확인·직접 검사·영어 로컬 커밋.
- 제외: 사용자 세이브 변경, 전투 연결, 전체 회귀/전체 플레이/별도 검수 에이전트, export·외부 배포.

## 3. 완료한 작업

- 원인이던 방 바닥·벽 전체의 외곽 계산을 원형 메뉴 크기/중심에서 제외했다. 실제 시설 그림의 알파 외곽 사각형 중심과 긴 축의 절반을 사용한다. 방 전체의 화면/UI 경계 검사는 유지한다.
- 아이콘 중심 반지름은 `max(시설 외곽 반경+8px, 100/(2*sin(PI/5)))`. 상수는1920 기준 UI 단위이며 다른 해상도에서는 기존 ui_unit으로 비례한다. 외곽 여백은 최대48px 요구 안의8px이다. 아이콘/이름80×88px와 최소100px 중심 간격, 이름 사이4px 여백을 검사한다.
- 0087 시작 배율0.75에서 병영173px(외곽165), 감시탑143px(135), 금고116.75px(108.75). 병영은 그림 자체가330px 폭이므로 요청의 대략110~150보다 크다. 그림을 덮도록150px에 강제 제한하지 않았다.
- 단일 반투명 원판 반지름도 아이콘 중심 반지름과 정확히 동일하다. 기존의 추가52px 확장을 제거했다. 금빛 방 둘레와 메뉴 이름은 유지한다.
- 가장자리 거리<반지름+88px이면 화면 안쪽을 향하는180도 반원을 먼저 시도한다. 기존270/225도 호는 제거했다. 반원의 아이콘 최소 간격이 안 나오면 원을 시도하고, 어떤 배치도 들어가지 않으면 기존0.28초 부드러운 카메라 이동으로 건물과 메뉴를 함께 옮긴다. 실제 감시탑 캡처는180도 안쪽 반원이다.
- 정보창은 같은 원 바로 바깥 좌/우 중 화면 여유가 있는 쪽, 가까운 변까지반지름+56px에 붙인다. 아이콘/이름과의 충돌도 명시적으로 검사한다. 먼 지도 빈자리 검색은 하지 않는다.
- 0087 시작 카메라(1930,1390)/0.75와 Bold/Light 폰트 유지. 스토리·데이터·밸런스·저장 형식 변경0. 선택/강화 정보 열기만 검사하고 강화/해체 확정은 하지 않았다.

## 4. 변경 파일

- `scripts/map_builder/ApprovedPlacementLayout.gd`: 가장자리 안쪽 반원 우선·정보창 충돌.
- `scripts/map_builder/ApprovedPlacementView.gd`: 시설 알파 외곽 중심/반경·작은 원판.
- `tools/run_v130r_step2e.ps1`: 기존 공식 실행기 탐색·단일 Godot·APPDATA 격리.
- `tools/tests/V130RStep2ETest.gd`, `tools/tests/V130RStep2ETest.tscn`: 직접/입력/캡처 검사.
- `tools/tests/v130r_step2e_capture_audit.py`: UTF-8 Python 한글 경로 저장·축소본·독립 기하/보존 감사.
- `docs/handoff/V130R_STEP2E_RADIAL_2026-10-16.md`, `docs/handoff/CURRENT.md`: 인계.

## 5. 그래픽 및 오디오 자산

- 새 생성·새 이미지/오디오·원본/폰트 파일 변경0. 기존 GPT 시설 그림·흑요석 원판·하이라이트만 재사용.
- 기존 출처: `assets/source/imagegen/v130r_step2/SOURCE.md`, `assets/source/imagegen/uiux_obsidian_20260912/SOURCE.md` 및 선행2C 인계.
- 원판 크기만 런타임 메모리에서 변경했다. 캡처는 실제 Godot 뷰포트, 축소본만 확인용 후처리.

## 6. 테스트 및 검수

| 명령/방법 | 결과 | 근거 |
|---|---|---|
|`powershell -ExecutionPolicy Bypass -File tools/run_v130r_step2e.ps1 -Mode direct`|2,523 checks / 실패0|`tmp/v130r_step2e/direct_result.json`|
|같은 실행기 `-Mode capture`|709 checks / 실패0|`capture_result.json`|
|`python tools/tests/v130r_step2e_capture_audit.py`|220 checks / 실패0, 기존1,386파일 해시변경0|외부 `capture_audit.json`|
|Python AST·PowerShell 파서·`git diff --cached --check`|PASS|실행 결과|
|요청4장 실제1920×1080·축소본 한 장씩 확인|완료|외부 `previews/`|
|전체 회귀·전체 플레이·별도 검수 에이전트·export|NOT_REQUESTED / 미실행|범위 준수|

직접 검사는8개 시설 선택/정보창, 근접 확대, 반지름 상한/하한, 원판 일치, 라벨 분리, UI/화면 경계, 인접 정보창, 합성 가장자리의 안쪽 반원과 실제 카메라 tween 시작/이동/완료를 확인했다. 실제 입력은 병영 클릭→강화→해체 정보→닫기, 감시탑/금고 선택이다. 시험 배치 파일 바이트 비변경, 최종 stderr 빈 파일이다. 최초 반원 시험의 화면 중심을 향한 사선과 수평 가정을 혼동한 단언은 화면 중간 높이의 왼쪽 경계 사례로 수정 후 통과했다.

산출물: `C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step2e/`

- `radial_barracks.png`, `radial_watchtower_edge.png`, `radial_vault.png`, `info_upgrade.png`: 실제1920×1080 원본4장.
- `previews/`: 1000px 이하 축소본4장, 최종 버전을 한 장씩 확인 완료.
- 직접/캡처 결과·좌표 metrics·로그·감사JSON. 로컬 캡처는 소스 커밋에 포함하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 7edacee99619bb0e757f174da4fd1f2893c9d88c
- Review range: 7d28603d1fe792043525dfaafa1871e907c19a06..7edacee99619bb0e757f174da4fd1f2893c9d88c
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

이 SHA 이후에는 docs/handoff 문서만 수정한다. 표적 검사 통과이며 사용자 화면 승인이 아니다.

## 7. 미해결 항목과 위험

- 자동 검사 실패0. 원형 메뉴 크기와 시설 그림 중심 해석의 최종 판단은 **사용자 확인 대기**.
- 병영173px는 실제 외곽165px를 유지한 결과다. 방 바닥/벽 대신 시설 본체를 외곽으로 해석했다.
- 금고116.75px에서는5개80×88px 이름을180도 안에 분리할 수 없어 원 배치와 카메라 이동을 사용한다. 최소 간격을 위한 예외이며 아이콘별로 흩어지지 않는다.
- 원격 최신 main 권위는 미확정. 기존 미리보기의 전투 미연결·임시 비용/영향 범위는 유지한다.

## 8. 다음 작업 순서

1. `game_step2e/previews/`4장 **사용자 확인 대기**.
2. 후속 사용자 지시만 반영한다. 전투 연결·push·merge·태그·Steam으로 진행하지 않는다.

## 9. 작업 트리 상태

- 기존 혼합 변경1,386파일 SHA-256 변경0. 기존 import/UID/설계 문서 보존.
- 개인 사용자 세이브 경로 미접근·미수정. APPDATA/LOCALAPPDATA는 ignored `tmp/v130r_step2e/`로 격리했고 기존 시험 배치도 바이트 비변경.
- 이번6개 구현/시험 파일과2개 인계 문서만 명시적으로 스테이징/커밋. 기존 변경은 미커밋 그대로다.
- 브랜치 전환·stash·별도 worktree 없음. 캡처/로그는 ignored tmp와 외부 mockup에만 저장.
- Godot 시작0·직렬 실행·동시 최대1·종료0. 원격/배포 조치0.

## 10. 종료 체크리스트

- [x] 반지름 축소·같은 크기 원판·안쪽 반원·카메라 이동·인접 정보창
- [x] 직접/실제 입력 검사·필수1920캡처4장·축소본 개별 확인
- [x] 기존 파일/사용자 세이브 보존·Godot 종료0
- [x] 영어 로컬 구현 커밋·인계/CURRENT 후속 문서 커밋
- [x] 전체 검수 미요청·원격/배포 미실행 기록
- [ ] 사용자 화면 확인

**사용자 확인 대기.**
