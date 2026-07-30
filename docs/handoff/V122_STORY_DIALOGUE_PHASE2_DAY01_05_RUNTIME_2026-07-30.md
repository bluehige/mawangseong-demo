# V122 스토리 대사 Phase 2 — DAY 1~5 런타임·Web 테스트

최종 갱신: 2026-07-30

## 결론

- 승인된 현재 대사집의 DAY 1~5를 실제 게임 흐름에 연결했다.
- 소스 구현 커밋은 `a5679c0fe2b092dd745d0fdb0d3fbe27b2708a22`이며 `codex/v122-ui-simplification`에 푸시했다.
- 빠른 PC Web 테스트 배포 커밋은 `097eea72c6ae6d9bee0e5a7728674e33a9ac1e63`이다.
- 공개 테스트 주소는 <https://bluehige.github.io/mawangseong-web-playtest/>이다.
- 다음 작업은 사용자의 DAY 1~5 직접 테스트다. 사용자가 통과를 명시하기 전에는 DAY 6~30 대사를 연결하지 않는다.

## 대사 원본 고정

- 전체 대사집:
  `작업문서/시나리오_v122/V122_MAIN_SCENARIO_DIALOGUE_BOOK_DRAFT_2026-07-30.md`
- 전체 원본 SHA-256:
  `6753f68e5cfb4662ee2ff978af5d39c73d5157bd595995438c1b4bf2de821f58`
- 저장소 안 DAY 1~5 원문 snapshot:
  `data/story/source/V122_MAIN_SCENARIO_DIALOGUE_BOOK_DAY01_05_2026-07-30.md`
- DAY 1~5 snapshot SHA-256:
  `886f27b8f07c2d8e613f7b0d7708878a436fb0ac62d0913289eff514a565e940`
- 대사 문장은 코드에서 따로 고치지 않는다. 원문 Markdown이 유일한 텍스트 기준이며
  `tools/story/generate_v122_story_day01_05.mjs`가 DAY별 JSON 5개와 manifest를 만든다.
- 원본 승인·분기 해석은
  `docs/handoff/V122_STORY_DIALOGUE_PHASE0_SOURCE_GATE_2026-07-30.md`를 따른다.

## 연결한 제품 흐름

- 관리 진입, 곱 전열·후열 배치, 전투 직전, 전투 시간 경과, 보스 체력 임계치,
  전투 결산, DAY 4 표지판 원정, DAY 5 보급 표식에 대사 trigger를 연결했다.
- 전투 결과 값은 먼저 확정하고 결과 대사를 읽은 뒤 결과 UI를 연다.
- 전투 대화는 `SCREEN_COMBAT`를 유지한 전체 화면 overlay다. 전투 시간, 유닛 physics,
  전투 tween, AnimatedSprite2D가 모두 정지하며 대화 종료 뒤 기존 배속으로 복귀한다.
- 초회 대사는 스킵할 수 없고, 이미 읽은 대사의 재열람은 스킵할 수 있다.
- `다음`, `Space`, `Enter`로 진행한다. Auto는 사용자가 켜는 기능이며 수동 진행 시 꺼진다.
- 새 대사가 있음을 알리는 표현은 `대화 알람`으로 고정했다.
- 읽은 장면과 battle/raid 범위를 optional `story` 저장 payload에 기록한다.
  구 저장에는 필드가 없어도 정상이며 튜토리얼 단계 ID는 바꾸지 않았다.
- 패배 후 같은 전투 재도전에서는 전투 단위 대사를 다시 열되 이미 읽었으므로 스킵할 수 있다.

## DAY별 중요 계약

- DAY 1: 푸딩은 전열, 핀은 후열 고정이며 곱은 전열 봉쇄/후열 화력을 직접 선택한다.
  선택 위치는 실제 생성 위치와 결산까지 이어지고 배치 대사는 전투 시도별로 다시 열린다.
- DAY 2: 금고가 손상된 분기는 충돌하는 기존 줄을 대체한다. 해당 대사가 없는 일반 방어/패배는
  기존 제품 흐름을 유지한다.
- DAY 3: 전투 대사와 보스 임계치 대사를 전투 완전 정지 상태로 읽는다.
- DAY 4: 미리보기 이탈로 필수 `d04_signpost_flip` 원정을 건너뛸 수 없다.
  원정 완료 전 전투를 막고 완료 뒤에만 방어 도착 대사를 허용한다.
  로로는 전역 고정 원정 지휘관이며 선택 슬롯에서 제외하고 악명 +10%를 적용한다.
- DAY 5: `d05_supply_tag` 뒤 보급 표식 대사를 연결한다.

## 검증

| 검증 | 결과 |
|---|---|
| DAY 1~5 generator 정합 | PASS, 6 files |
| 대사 schema | PASS, 2,191 assertions |
| DAY 1~5 대사 계약 | PASS, 216 assertions |
| story 저장 호환 | PASS |
| story runtime 통합 | PASS, 47 assertions |
| 제품 흐름·전투 완전 정지 | PASS, 33 assertions |
| DAY 1~3 튜토리얼 전체 흐름 | PASS |
| DAY 1~5 onboarding 흐름 | PASS |
| 전투 직전 UI 계약 | PASS, 40 assertions |
| 결과 UI 계약 | PASS, 37 assertions |
| 최종 정적 P0/P1/P2 검토 | 0건 |
| 의도 파일 diff check | PASS |

`CampaignSaveLoadSmokeTest`의 방 수 11 기대값과 현재 제품 12개 방 사이의 기존 stale assertion
4건은 이 스토리 변경과 무관하다. 이번 대사 작업의 실패로 처리하지 않았으며 별도 정리 대상이다.

## 빠른 Web 테스트 배포

- Godot: `4.5.2`
- 채널: `v122-story-day01-05-web-playtest`
- PCK: `242,710,612` bytes
- PCK SHA-256:
  `d9fa65585ac8e61398967ef54481962f4496c86e508c3a14f5b819c02ab9cffe`
- WASM: `38,047,590` bytes
- WASM SHA-256:
  `6ead2ac528d007fe9627aae650444f9187f89420d7603c22460d8f3279545240`
- Pages run:
  <https://github.com/bluehige/mawangseong-web-playtest/actions/runs/30541955986>
- Pages 결과: `success`
- 공개 1280×720 1회 부팅:
  title `마왕님, 마왕성은 누가 지켜요?`, canvas CSS `1280×720`,
  backing buffer `1920×1080`, loading 종료, 브라우저 error `0`

사용자 지시대로 비정식 테스트 게시에는 다중 해상도, 전체 회귀, Windows, Steam, Release,
별도 PR 절차를 추가하지 않았다.

## 다음 세션 시작 조건

1. 사용자가 공개 Web에서 DAY 1~5를 직접 플레이한다.
2. 대사 시점, 대화량, 어투, 전투 정지, 재도전, DAY 4 원정, 결산 연결 피드백을 받는다.
3. 발견된 DAY 1~5 결함만 먼저 수정하고 다시 빠른 테스트 빌드를 게시한다.
4. 사용자가 DAY 1~5 통과를 명시한 뒤에만 같은 구조로 DAY 6~30을 진행한다.
