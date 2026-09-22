# 1.2.9 Steam 심사 반려 입력 수정

## 1. 메타데이터
- 작성일: 2026-09-22
- 목표 버전: 1.2.9
- 작업 브랜치: codex/v128-steam-review-fix
- 기준 브랜치 및 SHA: origin/main / 1be65978fd7b0489647415ce9784e35e58a380f6
- 마지막 구현 커밋 SHA: be8176ca39a2f3ebf85740ae7c5ab82cc5a729b0
- 원격 푸시 여부: PR 생성 전
- WORKSTREAM_ID: STEAM_REVIEW_FIRST_PLAY_INPUT_20260922

## 2. 목표와 원인
사용자 제공 반려 원문 및 Steamworks에서 App5267750 / Build25423797의 시설 드래그·몬스터 배치 불가, Defense 비활성, 회색 UI 차단을 확인했다. `_management_ui_at`이 `MOUSE_FILTER_IGNORE`인 전체 화면 TutorialOverlay까지 Panel이라는 이유로 입력 차단 영역으로 판정했다. 실제 GUI 드래그/배치는 실패하고 필수 고블린 배치 튜토리얼을 끝낼 수 없었다. 기존 관리 화면 검사는 튜토리얼을 건너뛰거나 내부 배치 함수를 호출하여 이 결함을 놓쳤다.

## 3. 완료한 구현
- Control의 실제 mouse_filter와 화면 좌표를 따르도록 수정. 안내 전용 패널은 통과시키며 자식 버튼·팝업은 계속 입력을 차단한다. 숨김·클리핑된 자식은 차단하지 않는다.
- 새 게임/필수 튜토리얼 상태에서 시설 드래그, 확정 비용1회, 고블린 클릭 및 드래그, 안내막 종료, Defense 활성화, 전투 적/수비대 생성을 실제 viewport 입력으로 검사했다. 인트로 대사 진행만 내부 함수를 사용한다.
- 기본 Quick/Full 검사 목록에 영어 새 게임 입력 회귀를 등록했다.
- 기존1.2.8을 보존하고 프로젝트/Windows 제품 버전을1.2.9로 구분했다.
- 스토리·밸런스·저장 형식·그래픽/오디오 자산 변경 없음. 신규 이미지 생성 없음.

## 4. 변경 파일
- scripts/game/GameRoot.gd: 수동 UI 영역 판정 수정
- tools/SteamFirstPlayInputTest.gd/.gd.uid/.tscn: 실제 입력 회귀
- tools/tests/core_verification_suite.json: 기본 검사 등록
- project.godot, export_presets.cfg, docs/PRODUCT_VERSIONING.md: 패치 버전
- docs/handoff/CURRENT.md 및 본 문서: 근거/후속 단계

## 5. 검증
Godot4.6.3.stable.official.7d41c59c4, 독립된 APPDATA 사용. 근거 루트 `tmp/steam_review_fix/`.

| 검사 | 결과 | 근거 |
|---|---|---|
| 수정 전 같은 새 게임 입력 | FAIL: 시설 드롭/고블린 배치/Defense 진행 차단 재현 | before_en.log |
| 영문1280×720 실제 그래픽/클릭 | PASS31 | en_click.log, en_click/*.png |
| 한국어1920×1080 실제 그래픽/몬스터 드래그 | PASS28 | ko_drag.log, ko_drag/*.png |
| 기본 headless 입력 회귀 | PASS26, exit0 | final_headless.log |
| 기존 건설·Undo·UI·4성 단계 회귀 | PASS344 | build_placement.log |
| 튜토리얼 흐름 | PASS177 | TutorialFlowSmokeTest.log |
| UI 입력 계층 | PASS35 | UIInputLayerSmokeTest.log |
| 초기 진행 DAY5/저장 호환 | PASS57 | OnboardingFlowSmokeTest.log |
| git diff --check | PASS | 로컬 실행 |

실제 캡처에서 안내막 제거·활성 Defense·전투 적/수비대를 확인했다. 숨긴 Windows 테스트 창에서는 OS 포인터가 프레임 간 버튼 hover를 바꾸므로 클릭 press/release를 같은 프레임에 주입한다. 시설/몬스터 드래그는 여러 프레임으로 검사한다. headless 종료 일부에서 ObjectDB/resource 정리 경고가 남으며 assertion 실패나 SCRIPT ERROR는 없다. 그래픽 첫 플레이 로그에는 해당 종료 경고가 없다. Steam 클라이언트 설치 테스트나 사람이 조작한 검수로 표현하지 않는다. 전체 캠페인/전체 회귀/별도 검수 에이전트는 NOT_REQUESTED.

### 정책 CI용 최종 승인 필드
- Review task ID: NOT_REQUESTED
- Reviewed SHA: be8176ca39a2f3ebf85740ae7c5ab82cc5a729b0
- Review range: 1be65978fd7b0489647415ce9784e35e58a380f6..be8176ca39a2f3ebf85740ae7c5ab82cc5a729b0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 남은 작업
1. 정책 CI 통과 후 PR merge commit, 불변v1.2.9 태그.
2. 태그 Windows Steam export, 패키지/실행 검증, ZIP 업로드 후 새 Build를 default로 지정.
3. 수정점과 첫 플레이 조작 순서를 포함해 빌드 재심사 제출. 실제 제출 결과·빌드ID를 이 문서에 추가한다.
4. Valve 승인과 상점 심사/Coming Soon 대기 요건은 별도 외부 상태다. 한국등급 등록·Cloud 설정·가격·출시일은 변경하지 않는다.

## 7. 작업 트리
기존 루트의 혼합 작업 트리는 보존했다. 최신 main 기반 tmp/uiux_v2 작업트리에서 수행했다. 에디터가 갱신한194개 import 파일은 HEAD와 줄바꿈 외 내용이 동일함을 검사하고 원복했다. 빌드/캡처는 무시 경로에만 둔다.
