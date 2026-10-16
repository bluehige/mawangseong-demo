# V130R 2D — 시작 카메라 재설정·한글 폰트 교체

## 1. 메타데이터

- 작성일: 2026-10-16 KST. 사용자 지시: 10/16 18:33.
- WORKSTREAM_ID: V130R_STEP2D_CAMERA_FONT
- 목표 버전: 1.3.0 별도 안전 미리보기
- 브랜치: `codex/v130r-defense-layout` 유지
- 기준 SHA: `056d3c5a2a5e20485ae2c9d62588cc84e0815471` (0086 완료, 구현 `307537d5bff87a58ba42fad4d01b1b85aa057cb8` 포함)
- 마지막 구현·검증 SHA: `31f051d5ec7b71bd3abc93a8390ce894f0309aa4`
- 영어 로컬 커밋: `Restore approved combat framing and use MapleStory preview fonts`
- 이 인계/CURRENT는 후속 영어 로컬 문서 커밋으로 기록한다. 최종 문서 커밋 SHA는 `git log -1`로 확인한다.
- 원격 조회/fetch·push·merge·PR·태그·Steam: 모두 미실행.
- 권위 제한: 로컬 `main` 없음. `origin/main` 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, `v1.2.5` `f757ffa9f9e962158f2123856c8568a3163ecb6c`. 캐시 정책/CURRENT는 읽었으나 원격 최신 권위는 미확정이다. 사용자 지정 브랜치·0086·이번 지시를 따른다.
- 선행 인계: [2C 원형 메뉴](V130R_STEP2C_RADIAL_2026-10-16.md). 이번 변경은 2B의 시작 옥좌·입구 맞춤 정책을 대체한다.

## 2. 이번 세션 목표

- 승인된 `game_step2b/radial_edge.png`의 카메라를 시작 기본값과 키2 복귀로 사용한다.
- 미리보기의 한글을 제공된 MapleStory Bold/Light로 표시하고 정보창 글자 넘침을 방지한다.
- 실제 캡처·축소본 개별 확인·직접 검사·인계·영어 로컬 커밋까지 수행한다.
- 제외: 세이브 변경, 전투 연결, 전체 회귀/플레이/검수 에이전트, 빌드 export와 외부 배포.

## 3. 완료한 작업

- **카메라 근거:** `tools/tests/V130RStep2BTest.gd`의 `gui()`에서 `radial_edge` 캡처 직전에 `view.set_camera(Vector2(1930,1390),.75)`를 호출한다. 실제 기준 이미지와 새 캡처도 대조했다.
- **시작값:** 중심 `(1930,1390)`, 배율 `0.75 × min(화면폭/1920, 화면높이/1080)`. 0085의 `ScreenLayout.solve(size,start_targets(),ui_rects)`를 시작 기본값에서 제외했다. 계산 함수와 `start_targets()`는 남겼다.
- 같은 종횡비에서 보이는 칸 수가 동일하다. 종횡비가 다르면 지도/칸 비율을 왜곡하지 않고 짧은 축의 범위를 유지하며 긴 축에 여분의 칸을 보여준다. 서로 다른 종횡비에서 양축 칸 수를 모두 고정하는 왜곡/레터박스는 추가하지 않았다.
- 키2는 이 시작 화면, F는 전체 지도다. 미니맵 사각형의 위치·크기 갱신과 미니맵 클릭 이동을 실제 입력으로 확인했다.
- **폰트:** 탭·건설 이름·원형 메뉴 이름·정보창 제목·미니맵 제목은 `NEXON_Maplestory_Bold.otf`. HUD 수치·건설 비용·정보 수치/설명·상태 문구·툴팁은 `NEXON_Maplestory_Light.otf`. 이 미리보기의 라벨/툴팁에서 상속된 Noto 사용을 제거했다. 다른 미리보기의 공통 부모 폰트는 변경하지 않았다.
- 정보창 제목 기본20px, 실제 폭270px를 넘으면 최소12px까지 줄여 우상단 닫기와 겹침을 막는다. 다른 이름/본문 크기는 기존15~18px 등을 유지했다. 검사 중 모든 표시 라벨이 화면 안, 정보창 라벨이360×268px 창 안에 있음을 확인했다.
- 스토리·밸런스·게임 데이터·저장 스키마·기존 이미지/폰트 파일 변경 없음.

### 해상도별 시작 계산표

중심은 모든 행 `(1930,1390)`. 칸 투영 기본128×64 world px, 화면의 칸 다이아몬드 폭/높이는 이 값×배율이다. 보이는 world 범위는 화면 크기÷배율이다.

| 실제 해상도 | 비례 계수 | 배율 | 화면 칸 폭×높이(px) | 보이는 world 폭×높이 |
|---|---:|---:|---:|---:|
|1920×1080|1|0.75|96×48|2560×1440|
|1280×720|2/3|0.5|64×32|2560×1440|
|2560×1440|4/3|1.0|128×64|2560×1440|
|1920×1200|1|0.75|96×48|2560×1600|
|1280×800|2/3|0.5|64×32|2560×1600|
|2560×1600|4/3|1.0|128×64|2560×1600|

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
|`scripts/map_builder/ApprovedPlacementView.gd`|시작 카메라·Bold/Light 역할·제목 폭 조절|
|`tools/run_v130r_step2d.ps1`|기존 공식 Godot 탐색·단일 실행·APPDATA 격리 재사용|
|`tools/tests/V130RStep2DTest.gd`|6해상도·실제 키/미니맵·모든 건물 정보/강화/환불 폰트와 경계·저장 보존|
|`tools/tests/V130RStep2DTest.tscn`|안전 검사 진입점|
|`tools/tests/v130r_step2d_capture_audit.py`|UTF-8 Python으로 한글 외부 경로 쓰기·원본 복사·축소·나란히 비교·기준 픽셀/기존파일 감사|
|`docs/handoff/V130R_STEP2D_CAMERA_FONT_2026-10-16.md`|이번 인계|
|`docs/handoff/CURRENT.md`|브랜치 로컬 진입점 갱신|

## 5. 그래픽 및 오디오 자산

- GPT 생성0, 새 이미지/오디오 자산0. 제공된 기존 Bold/Light만 연결했다. 폰트/이미지 원본·import 파일 수정 없음.
- 캡처는 실제 Godot 렌더이며 비교 이미지만 좌우 합성했다. 축소본은 확인용으로만 사용했다.

## 6. 테스트 및 검수

| 명령/방법 | 결과 | 근거 |
|---|---|---|
|`powershell -ExecutionPolicy Bypass -File tools/run_v130r_step2d.ps1 -Mode direct`|5,184 checks / 실패0|`tmp/v130r_step2d/direct_result.json`|
|같은 실행기 `-Mode capture`|5,192 checks / 실패0|`capture_result.json`, 실제 화면 PNG|
|`python tools/tests/v130r_step2d_capture_audit.py`|11 checks / 실패0|외부 `capture_audit.json`|
|Python AST·PowerShell 파서·`git diff --cached --check`|PASS|명령 결과|
|요청한5장 축소본을 한 장씩 확인|완료|외부 `previews/`|
|전체 회귀·전체 플레이·별도 검수 에이전트·export|NOT_REQUESTED / 미실행|사용자 요청 범위 준수|

기준 이미지와 새 시작의 가림 없는 지도 영역 `(720,300)-(1300,650)`은 **픽셀100% 일치**했다. 나란히 비교에서 카메라 구도가 같고, 기준의 선택 메뉴가 새 시작에는 없으며 폰트가 바뀐 차이를 확인했다. 모든 검사 stderr는 비어 있다. 실제 캡처 중1920·1280으로 창 크기를 바꾸며 뷰포트 원본 크기를 검사했다.

산출물: `C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step2d/`

- `start_1920.png`: 실제1920×1080 시작 화면
- `start_1280.png`: 실제1280×720 시작 화면, 동일 지도 범위
- `compare_start.png`: 기존 radial_edge/새 시작 좌우 비교3840×1120
- `font_info.png`: 실제1920×1080 병영 강화 정보·원형 이름
- `font_bar.png`: 실제1920×1080 건설 바·HUD·탭
- `previews/`: 화면1000px 이하, 비교1600px 이하 축소본. 한 장씩 시각 확인 완료.
- 로그·해상도/기하 metrics·결과JSON·`capture_audit.json`: 검증 근거

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 31f051d5ec7b71bd3abc93a8390ce894f0309aa4
- Review range: 056d3c5a2a5e20485ae2c9d62588cc84e0815471..31f051d5ec7b71bd3abc93a8390ce894f0309aa4
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

이 SHA 이후에는 인계/CURRENT 문서만 변경했다. 결과는 정식 출시·전체 플레이·사용자 화면 승인이 아니다.

## 7. 미해결 항목과 위험

- 이번 범위의 검사 실패 없음. 화면 구도·서체 최종 판단은 **사용자 확인 대기**.
- 종횡비가 달라지면 긴 축에 추가 칸을 표시한다. 옥좌·입구 전체가 보이는 것은 시작 조건이 아니다.
- 기존 전투 미연결·임시 가격/영향 범위는 유지한다. 원격 최신 main 권위는 미확정이다.

## 8. 다음 작업 순서

1. `game_step2d/previews/` 및 비교 화면의 사용자 확인 대기.
2. 사용자 후속 지시에 따른 수정만 수행한다. 전투 연결·배포로 자동 진행하지 않는다.

## 9. 작업 트리 상태

- 기존 혼합 변경1,386파일 SHA-256 변경0. 기존 `.import`/UID/미추적 설계 문서 보존. 사용자 세이브 경로는 열거나 수정하지 않았다.
- 검사 APPDATA/LOCALAPPDATA는 `tmp/v130r_step2d/`에 격리. 기존 시험 배치 파일도 바이트 비변경. 건설 확정·강화 확정·해체 확정은 실행하지 않았다.
- 작업 파일7개만 명시적으로 스테이징/커밋. 기존 변경은 그대로 미커밋. 브랜치 전환·stash·별도 worktree 없음.
- 캡처/로그는 ignored tmp와 외부 mockup에만 저장, 소스 커밋에 포함하지 않았다.
- Godot 시작0·직렬 실행·동시 최대1·종료0. push·merge·태그·Steam 없음.

## 10. 종료 체크리스트

- [x] 0086 결과 위에서 카메라·폰트 구현 및 요구 대조
- [x] 6해상도 계산·키2/F·미니맵·폰트/프레임 표적 검사
- [x] 필수 실제 캡처·기준 나란히 비교·축소본 개별 확인
- [x] 세이브·기존 혼합 변경 보존, Godot 종료0
- [x] 영어 로컬 구현 커밋·인계/CURRENT 후속 문서 커밋
- [x] 외부 조치 미실행·전체 검수 미요청 기록
- [ ] 사용자 화면 확인

**사용자 확인 대기.**
