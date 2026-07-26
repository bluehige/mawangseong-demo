# V20 핵심 재미 UI 구현 핸드오프

## 메타데이터

- 작성일: 2026-07-26
- 목표 버전: `2.0.0`
- 작업 브랜치: `codex/v20-important-revision`
- 기준 브랜치와 SHA: `origin/release/v2.0` / `b63a5f13476f7d28ffa974dacc9a3186e76b67b7`
- 작업 시작 SHA: `86cee02ab16b6afdab94af7d6152866de4eeed61`
- 마지막 커밋 SHA: 이 문서를 포함하는 현재 Git HEAD 참조
- 원격 푸시 여부: `origin/codex/v20-important-revision`

## 요청과 범위

- 요청 사항:
  - 핵심 재미인 건물 배치와 몬스터 육성을 더 명확하고 간단하게 만든다.
  - 승인된 시안을 기준으로 실제 UI를 구현한다.
  - 양산할 이미지 계획표를 만든다.
  - 검수는 핵심만 남긴다.
- 완료 조건:
  - `건물 배치 → 몬스터 육성 → 수비대 배치`가 실제로 동작한다.
  - 실제 푸딩·곱·핀과 실제 특화 데이터를 사용한다.
  - 성장 상태가 저장·복원된다.
  - 관련 테스트 1종과 대표 `1280×720` 화면을 통과한다.
- 이번에 하지 않은 것:
  - 정식 시설 이미지 20장 생성
  - Web 친구 테스트 빌드 재생성·배포
  - 전체 회귀·전체 플레이·별도 검수 에이전트

## 완료한 작업

- 구현:
  - 준비 화면을 시설·육성·몬스터 배치 세 단계로 분리했다.
  - 시설 카드는 실제 효과·비용·기존 prop을 사용한다.
  - 선택 시설을 지도 토큰으로 표시한다.
  - 육성 화면에 실제 캐릭터 초상, 레벨, EXP, 유대와 특화 두 갈래를 연결했다.
  - 특화 추천 건물은 `facility_synergy`에서 읽는다.
  - 특화·레벨·EXP·유대를 V20 세션과 저장에 보존한다.
  - 기존 친구 테스트 저장 호환을 위해 schema 3을 유지했다.
- 문서:
  - DAY 1~5 계약을 실제 구현과 맞췄다.
  - 시설 5종×4방향 20장의 그래픽 양산 계획표를 작성했다.
  - 폐기된 이전 UI 초안은 제거했다.
- 데이터·밸런스:
  - 새로운 수치나 가짜 능력은 추가하지 않았다.
  - 일일 훈련은 비용·해금·횟수 계약이 없어 제외했다.
- UI·그래픽:
  - 공식 제목과 기존 마왕성 지도, 푸딩·곱·핀 초상을 바꾸지 않았다.
  - 기존 v3 시설 prop은 기능 확인용으로만 임시 사용한다.

## 주요 변경 파일

| 경로 | 변경 목적 |
|---|---|
| `scripts/v20/session/V20SessionService.gd` | 준비 단계와 성장 상태 생성·검증·저장 |
| `scripts/v20/flow/V20DayFlowService.gd` | 성장 상태를 유지한 DAY runtime |
| `scripts/game/GameRoot.gd` | 준비 단계 전환, 특화 선택과 복원 연결 |
| `scripts/game/ManagementSceneController.gd` | HUD·보드 신호와 준비 데이터 연결 |
| `scripts/v20/ui/V20InformationHUD.gd` | 3단계 탭과 단계별 단일 주 행동 |
| `scripts/v20/placement/V20PlacementBoard.gd` | 시설·육성·수비대 화면 분리와 실제 데이터 표시 |
| `scripts/v20/placement/V20MonsterDragButton.gd` | 시설 카드와 몬스터 카드 표시 |
| `scripts/v20/placement/V20PlacementRoomButton.gd` | 지도 위 시설 그림 표시 |
| `tools/tests/V20PlacementUxTest.gd` | 준비 단계·성장·저장·UI 핵심 검사 |
| `docs/design/V20_DAY1_5_VALIDATION_CONTRACT.md` | 한 번의 특화 선택 계약 |
| `docs/design/V20_CORE_FUN_ART_PRODUCTION_PLAN_2026-07-26.md` | 정식 시설 이미지 양산표 |

## 자산 기록

- 생성 모델: 없음
- 생성 원본과 `SOURCE.md`: 없음
- 최적화 runtime 자산: 없음
- 실제 연결 확인: 기존 저장소의 지도·초상·v3 시설 prop만 코드로 연결

## 최소 검수

- Related tests:
  - `Godot_v4.5.2-stable_win64_console.exe --headless --path . --scene res://tools/tests/V20PlacementUxTest.tscn`
  - 결과: 35개 항목 PASS
- UI check:
  - Windows OpenGL `1280×720`에서 같은 테스트 씬을 실제 렌더
  - 결과: 캡처 항목을 포함한 36개 PASS
  - 건물 배치 대표 화면의 지도, 시설 카드, 탭과 하단 버튼에 겹침·잘림 없음
- 스크립트 확인:
  - Godot headless editor 시작·종료 성공
  - 파싱 오류 없음
- 전체 검수:
  - Review task ID: `NOT_REQUESTED`
  - Remaining P1/P2: `N/A`
  - Final review result: `TARGETED_PASS`

## 미해결 문제와 다음 작업

1. 바리케이드 4방향 기준 시트를 먼저 생성하고 사용자에게 시각 승인을 받는다.
2. 승인된 기준으로 나머지 4개 시설을 양산한다.
3. runtime 20장을 `assets/props/v20/`에 연결한다.
4. 친구 테스트 요청이 오면 Web 빌드를 새 커밋 기준으로 갱신한다.

## 작업 트리와 원격 상태

- 미커밋 파일: 이 문서를 포함한 의도한 변경을 커밋할 예정
- 로컬 캡처: Git 바깥의 Godot 사용자 데이터 폴더에 있으며 커밋하지 않음
- Godot 자동 생성 `.import`·`.uid` 잡파일: 커밋하지 않음
- 원격 푸시: `origin/codex/v20-important-revision`
