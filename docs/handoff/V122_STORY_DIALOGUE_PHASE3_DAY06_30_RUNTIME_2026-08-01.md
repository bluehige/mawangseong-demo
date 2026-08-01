# V122 스토리 대사 Phase 3 — DAY 6~30 런타임·초상화·기본 엔딩

최종 갱신: 2026-08-01

## 결론

- 사용자의 DAY 1~5 Web 테스트 통과 승인 뒤, 승인 대사집의 DAY 6~30과 기본 엔딩 E00~E04를 실제 게임 trigger에 연결했다.
- DAY 1~5 JSON과 그 원문 고정 계약은 유지했다. DAY 6~30만 새 원문 snapshot에서 생성한다.
- DAY 6~30은 25개 데이터 파일, 169개 scene, 1,545개 cue로 구성된다. 원문 문장을 코드에서 임의로 고치지 않았다.
- 커밋·푸시·빌드는 이번 작업에서 수행하지 않았다.

## 원문 및 생성 계약

- 승인 원문 snapshot: `data/story/source/V122_MAIN_SCENARIO_DIALOGUE_BOOK_APPROVED_2026-07-31.md`
- 승인 원문 SHA-256: `d421651b49739c88706c48c1482a3a1dc8dc7d697b017870f5f8ead19014914b`
- 생성기: `tools/story/generate_v122_story_day06_30.mjs`
- 생성 확인: `node tools/story/generate_v122_story_day06_30.mjs --check`
- manifest는 DAY 6~30 원문 SHA와 별도로 DAY 1~5의 기존 원문 SHA/snapshot을 계속 보존한다.

## 런타임 연결

- 관리, 전투 직전, 전투 중, 결산, 분기, DAY 29 관리 전용 선언, DAY 30 승패와 기본 엔딩을 기존 StoryDirector trigger에 연결했다.
- 전투 중 scene은 기존처럼 전투 simulation을 멈춘 상태에서 열린다. 읽은 대화는 기존 입력/Auto/스킵 규칙을 따른다.
- `첫 승급자`, `두번째 승급자`, `먼저 승급한 몬스터`는 실제 승급 순서를 campaign 저장에 보존하고, 그 순서에 맞는 이름·초상화·표정을 즉시 해석한다. 구 저장은 기존 roster 순서로 안전하게 보정한다.
- 마왕, 바티, 골딘, 푸딩, 곱, 핀, 로로, 밀로, 니아, 레온, 아이리스, 셀렌, 로만은 기존 해당 캐릭터 초상화를 사용한다. 특정 인물이 아닌 병사·경비·군중은 잘못된 캐릭터 그림을 붙이지 않고 이름만 표시한다.
- DAY 30은 실제 결산 뒤 `ending_entered` 대사를 열고, 완료 시 기존 엔딩 UI에 계산된 E00~E04 결과를 전달한다.

## 변경 파일

| 경로 | 목적 |
|---|---|
| `data/story/v122_main/day_06.json` ~ `day_30.json` | DAY 6~30/엔딩 대사 데이터 |
| `data/story/v122_main/manifest.json` | 새 day 파일 및 원문 이력 |
| `data/story/source/V122_MAIN_SCENARIO_DIALOGUE_BOOK_APPROVED_2026-07-31.md` | 검증 가능한 승인 원문 snapshot |
| `tools/story/generate_v122_story_day06_30.mjs` | 원문→JSON 생성·정합 검사 |
| `scripts/game/GameRoot.gd` | 승급 순서 저장, 동적 초상화, ending trigger/context |
| `scripts/story/StoryDialoguePresenter.gd` | 동적 화자·초상화·표정 해석 |
| `tools/tests/V122StoryDay06To30Test.gd/.tscn` 및 기존 story 테스트 | 데이터/분기/저장/초상화 계약 |

## 검증

| 검증 | 결과 |
|---|---|
| DAY 6~30 generator check | PASS, 26 files |
| DAY 6~30 데이터·분기·엔딩 계약 | PASS, 7,747 assertions |
| 전체 story schema | PASS, 19,395 assertions |
| DAY 1~5 회귀 | PASS, 216 assertions |
| story runtime 동적 초상화·엔딩 연결 | PASS, 55 assertions |
| story 저장 호환 | PASS |
| 제품 흐름·전투 정지 | PASS, 33 assertions |
| Godot 스크립트 parsing | PASS |
| `git diff --check` | PASS |

Godot 편집기 parsing 중 기존 133 bytes WAV 3개의 import 경고가 보였으나, 이번 story 코드/데이터 변경과 무관한 기존 오디오 자산 문제다. 편집기가 생성한 `.import`/`.uid` 메타데이터는 작업 범위에서 제외해 정리했다.

`V122StorySaveStateTest`와 `V122StoryProductFlowTest`는 assertion PASS 및 process exit 0 뒤 Godot headless의 `1 resources still in use at exit` 종료 메시지를 각각 한 번 출력한다. 이번 대사 변경의 assertion 실패나 실행 실패는 아니며, 별도 test teardown 정리 대상으로만 기록한다.

## 검수 정책 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `UNCOMMITTED worktree (base e5facb1)`
- Review range: `N/A — 사용자 요청 범위의 대상 테스트만 수행`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 다음 작업

1. 사용자가 DAY 6~30을 실제 플레이하며 대사 타이밍, 분기, 실제 승급자 초상화, DAY 29 선언, DAY 30 기본 엔딩을 확인한다.
2. 피드백이 있으면 해당 DAY/분기만 원문 기준으로 수정하고 대상 테스트를 다시 실행한다.
3. 사용자 최종검수 후에만 Full 검증과 테스트 빌드/배포 여부를 결정한다.

## 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `e5facb1`
- 이번 작업 변경은 아직 커밋·푸시하지 않았다.
