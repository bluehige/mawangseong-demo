# V1.2.2 Q1-S P2 재현 — 전투 story overlay와 후일담 자동 저장 경계

## 목적과 범위

- 감사일: 2026-08-02
- 대상 버전: 제품 1.2.2
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 재현 ID: `Q1-S-INTEGRATION-02`
- 범위: 실제 전투 시작 → story combat overlay 표시 → overlay 닫기 → 전투 결산 → 결과 story → 엔딩 → 후일담 관리 autosave
- 변경: 런타임 0, 데이터 0, 그래픽·오디오 자산 0, 빌드 0

Q1-S 본 감사에서 확인된 `CampaignSaveLoadSmokeTest` 실패 4건의 원인이 런타임 결함인지 테스트 호출 경계인지 분리하기 위한 최소 재현이다. 임시 Godot 테스트는 `tmp/` 아래에만 두었고 사용자 저장 경로 대신 `user://q1_s_story_autosave_repro.json`을 사용한 뒤 정리했다.

## 실행 결과

실행 명령:

```text
godot.cmd --headless --path . --scene res://tmp/v122_release_polish/q1_s_integration_story/Q1SStoryAutosaveRepro.tscn
```

결과: `Q1_S_STORY_AUTOSAVE_REPRO: PASS (11 assertions)`, 종료 코드 0.

검증한 경계는 다음과 같다.

1. 전투 전 DAY 30 관리 체크포인트가 저장된다.
2. 실제 `_start_combat()` 후 story combat overlay가 열린다.
3. 모든 story cue를 진행해 overlay를 닫으면 전투가 다시 재생된다.
4. `_finish_combat()` 뒤 결과 story를 닫으면 결과 화면으로 돌아오며 안전하지 않은 story 복귀 오류가 없다.
5. 엔딩을 거쳐 후일담 관리로 들어가도 checkpoint가 유효하고 `campaign_save_error`가 비어 있다.

## 결론

실제 overlay 종료를 포함한 흐름에서는 후일담 autosave와 이어하기용 checkpoint가 모두 유효했다. 따라서 기존 스모크의 다음 호출 순서가 원인으로 확인된다.

- `tools/CampaignSaveLoadSmokeTest.gd:401-416`이 `_start_combat()` 직후 `_finish_combat()`을 직접 호출한다.
- 그 사이 실제 사용자 흐름에서 필요한 story combat overlay cue 진행·닫힘이 없다.
- 그 결과 `pending_return_screen = combat`인 활성 story가 남은 상태로 autosave가 시도되고, `StorySaveState`가 안전하지 않은 복귀 화면으로 거부한다.

이 항목은 런타임 P2 결함이 아니라 `HARNESS_GAP_CONFIRMED_RUNTIME_FLOW_PASS`로 재분류한다. 기존 스모크가 실제 흐름을 대표하도록 보강할지는 별도 테스트 개선 패킷에서 결정하며, 이번 단계에서 테스트나 런타임을 수정하지 않았다.

## 주의 사항

Godot headless 종료 시 ObjectDB resource leak 경고 1건이 출력됐지만, 재현 테스트의 최종 결과와 종료 코드는 PASS였다. 이 경고는 이번 autosave 경계 판정의 실패로 계산하지 않는다.

## 기계 산출물

- `tmp/v122_release_polish/q1_s_integration_story/Q1SStoryAutosaveRepro.gd` (임시)
- `tmp/v122_release_polish/q1_s_integration_story/Q1SStoryAutosaveRepro.tscn` (임시)
- `tmp/v122_release_polish/q1_s_integration_story/q1_s_story_autosave_repro.log`
- `tmp/v122_release_polish/q1_s_integration_story/q1_s_story_inventory.json`
- `tmp/v122_release_polish/q1_s_integration_story/q1_s_story_inventory.tsv`

## 다음 순서

Q1-S의 남은 재현은 Stage 04 `area_room_count`와 `QuarterDungeonRenderer`의 full-grid 시각 object 투영 수를 분리하는 계약 패킷이다. 그 결과를 기록한 뒤 Q1-I 입력·IME 감사로 이동한다.

Related tests: `Q1SStoryAutosaveRepro` PASS(11 assertions), 기존 `CampaignSaveLoadSmokeTest`의 story autosave 4건은 harness gap으로 재분류
UI check: 실제 UI를 수정하지 않은 headless 사용자 흐름 재현이며 별도 화면 캡처는 실행하지 않음
Unresolved issues: 기존 스모크 테스트 harness 보강 여부, Stage 04 투영 계약 P2 재현, 실제 1.2.1 원본 hash/mtime·이어하기 소유자 검수
