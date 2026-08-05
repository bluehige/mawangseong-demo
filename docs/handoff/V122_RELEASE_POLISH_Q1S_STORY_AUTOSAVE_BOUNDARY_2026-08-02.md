# V1.2.2 Q1-S P2 재현 핸드오프 — story overlay·후일담 autosave

## 기본 정보

- 목표 버전: 제품 1.2.2
- 패킷: `Q1-S-INTEGRATION-02`
- 브랜치: `codex/v122-ui-simplification`
- 기준·마지막 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 커밋·푸시: 하지 않음

## 완료 내용

기존 저장 스모크에서 보인 후일담 체크포인트 실패 4건을 실제 story overlay 종료를 포함하는 최소 흐름으로 재현했다. 전투 전 관리 저장, overlay 표시와 종료, 결과 story 종료, 엔딩, 후일담 관리 autosave를 모두 통과했고 최종 `Q1_S_STORY_AUTOSAVE_REPRO: PASS (11 assertions)`를 확인했다.

따라서 문제는 런타임 저장 로직이 아니라 `CampaignSaveLoadSmokeTest`가 전투 시작 직후 결산을 직접 호출해 활성 `combat` story 복귀 화면을 남기는 테스트 harness 경계로 재분류했다. 이번 패킷에서 테스트 harness나 런타임 코드는 수정하지 않았다.

## 변경·산출물

- 보고서: `docs/qa/V122_Q1S_STORY_AUTOSAVE_BOUNDARY_2026-08-02.md`
- 임시 재현기와 로그: `tmp/v122_release_polish/q1_s_integration_story/`
- 저장 파일은 테스트 종료 시 `user://q1_s_story_autosave_repro.json` 및 표식을 삭제했다.

## 다음 작업

1. Stage 04의 `area_room_count` 계약과 full-grid 시각 object 투영 수를 분리해 재현한다.
2. 그 결과에 따라 저장 payload 결함인지 renderer/test 계약인지 확정한다.
3. Q1-S 두 재현을 마치면 Q1-I 입력·IME 감사로 이동한다.

## 정책 고정 필드

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
Review range: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d..efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
Remaining P1/P2: `Q1-S` Stage 04 투영 계약 P2 재현, 기존 smoke harness 보강 여부
Final review result: `TARGETED_PASS_WITH_HARNESS_GAP_CONFIRMED`

Related tests: `Q1SStoryAutosaveRepro` PASS(11 assertions), 종료 코드 0
UI check: headless 실제 흐름 재현, UI·자산 변경 없음
Unresolved issues: Stage 04 투영 계약 P2 재현, smoke harness 보강 여부, 실제 1.2.1 hash/mtime·이어하기 소유자 검수
