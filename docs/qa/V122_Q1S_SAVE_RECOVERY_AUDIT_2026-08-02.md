# V1.2.2 Q1-S 저장·복구 상세 감사

## 감사 범위

- 감사일: 2026-08-02
- 대상 버전: 1.2.2 정식 출시 마무리선
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 방식: 읽기 전용 코드·데이터·테스트 계약 대조
- 이번 패킷의 변경: 런타임 코드 0, 데이터 0, 그래픽·오디오 자산 0, 빌드 0

이번 패킷은 저장 파일을 지우거나 사용자의 1.2.1 원본을 덮어쓰지 않고, 저장소에 이미 있는 계약과 자동 테스트의 동작만 확인했다. 실제 1.2.1 원본의 SHA-256·수정 시각·Windows 후보 빌드 이어하기는 사용자 소유 검수 항목으로 남겼다.

## 확인한 저장 계약

`scripts/core/CampaignSaveStore.gd`와 `scripts/story/StorySaveState.gd`를 기준으로 다음을 확인했다.

- 저장 버전은 1, 캠페인 마지막 날짜는 DAY 30, 기본 저장 경로는 `user://campaign_save_v1.json`이다.
- 쓰기는 `.tmp`에 기록하고 다시 읽어 검증한 뒤 기존 본문을 `.bak`으로 옮기고 본문을 교체한다. 교체 후 본문을 다시 검증하고 정상일 때 오래된 백업을 정리한다.
- 본문이 없거나 손상되면 유효한 `.tmp`, 그 다음 `.bak`만 복구 후보로 사용한다. 지원하지 않는 버전은 승격하지 않는다.
- `.invalid`, `.unrestorable`, `.delete_pending` 표식은 이어하기 가능 여부와 삭제 중단 상태를 구분한다.
- 진행 중 스토리는 안전한 복귀 화면만 저장할 수 있다. `combat`와 `dialogue`는 활성 스토리 복귀 화면으로 허용되지 않는다.

## 대상 테스트 결과

| 테스트 | 결과 | 근거 |
|---|---|---|
| `V122SaveProgressionTest` | PASS | `tmp/v122_release_polish/q1_s/q1_s_v122_save_progression.log` |
| `SaveV4MigrationTest` | PASS, 42 assertions | `tmp/v122_release_polish/q1_s/q1_s_save_v4_migration.log` |
| `SaveV5MigrationTest` | PASS, 37 assertions | `tmp/v122_release_polish/q1_s/q1_s_save_v5_migration.log` |
| `CampaignSaveLoadSmokeTest` | FAIL_WITH_SCOPE_BOUNDARY, 246 assertions 중 8건 실패 | `tmp/v122_release_polish/q1_s_campaign_save_load_smoke.log` |

첫 세 테스트는 버전 마이그레이션, 재시도, 임시 파일·백업 파일 복구, 손상·미지원 저장 거부를 통과했다. 첫 번째 테스트에서 보이는 JSON 파싱 오류와 ObjectDB 누수 경고는 손상 fixture를 검증하기 위한 예상 출력이며 테스트 최종 결과는 PASS다.

## 스모크 실패 8건의 분류

### A. Stage 04 쿼터뷰 투영 계약 4건

다음 복원 지점에서 `실제 쿼터뷰 구역 11개 투영` 기대가 반복해서 실패했다.

1. 1차 복원
2. 2차 복원
3. 후일담 진입
4. 후일담 복원

같은 호출은 `Stage 04 구역 계약 11개`, 신규 건물 보존, 진화 이력 보존을 통과한다. 즉 저장 payload 안의 Stage 04 계약 값이 바로 소실됐다는 증거가 아니라, `area_room_count = 11`과 `QuarterDungeonRenderer.debug_full_grid_room_projection_count()`가 세는 시각 object 슬롯의 의미가 섞인 계약 공백으로 분리했다.

근거는 `tools/CampaignSaveLoadSmokeTest.gd:637-643`, `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:444-450,2868-2870`, `data/castle_evolution_stages.json:63-77`이다. 이 항목은 저장 포맷 수정이 아니라 투영 계약을 별도 P2 패킷으로 재현해야 한다.

### B. 후일담·자동 저장 통합 경계 4건

다음 항목이 연쇄적으로 실패했다.

1. 후일담 관리 체크포인트 요약 저장
2. 제목 화면의 후일담 체크포인트 노출
3. 후일담·승리 완료 상태 복원
4. 후일담에서 날짜 진행 시 DAY 31 대신 엔딩 재표시

로그에는 `스토리 복귀 화면이 안전하지 않습니다`라는 자동 저장 경고가 함께 남는다. 테스트가 `_start_combat()` 직후 `_finish_combat()`을 직접 호출해 실제 전투 overlay가 닫히는 경계를 거치지 않으므로, `pending_return_screen = combat` 상태에서 후일담 자동 저장을 시도한 것으로 분리했다. 실제 사용자 흐름에서 전투 종료·overlay 닫힘 뒤에도 같은 경고가 재현되는지는 아직 확인하지 않았다.

근거는 `tools/CampaignSaveLoadSmokeTest.gd:401-416`, `scripts/game/GameRoot.gd:10835-10898,6603-6609,8772-8779`, `scripts/story/StorySaveState.gd:123-136`이다. 이 항목도 저장 파일 자체의 손상으로 단정하지 않고, 실제 흐름 재현용 P2 패킷으로 분리한다.

## 미실행 소유자 검수

- 실제 1.2.1 원본 파일의 별도 복사와 원본 SHA-256·수정 시각 전후 비교
- 후보 Windows 빌드에서 실제 `이어하기` 실행
- 실제 사용자가 전투 종료 후 후일담까지 진행한 저장·복원 흐름

위 항목은 `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md`에 따라 사용자 원본과 후보 빌드가 준비된 뒤 실행한다. 이 감사에서는 개인 저장 파일을 만들거나 변경하지 않았다.

## 결론과 다음 순서

- 저장 버전 마이그레이션과 원자적 `.tmp/.bak` 복구 계약: 대상 테스트 PASS
- 통합 스모크: 8건 실패. 저장 본문 손상으로 확정할 근거는 없음
- Q1-S 상태: `OWNER_QA_PENDING` 및 P2 통합 재현 필요
- 다음 패킷 1: 실제 전투 종료·overlay 닫힘 뒤 후일담 자동 저장/이어하기 최소 재현
- 다음 패킷 2: `area_room_count`와 full-grid 시각 object 투영 수를 분리한 Stage 04 계약 재현
- 두 재현 결과를 기록한 뒤 계획 순서대로 Q1-I 입력·IME 감사로 이동

## 기계 산출물

- `tmp/v122_release_polish/q1_s/q1_s_inventory.json`
- `tmp/v122_release_polish/q1_s/q1_s_inventory.tsv`
- `tmp/v122_release_polish/q1_s/q1_s_v122_save_progression.log`
- `tmp/v122_release_polish/q1_s/q1_s_save_v4_migration.log`
- `tmp/v122_release_polish/q1_s/q1_s_save_v5_migration.log`
- `tmp/v122_release_polish/q1_s_campaign_save_load_smoke.log`

Related tests: `V122SaveProgressionTest` PASS, `SaveV4MigrationTest` PASS(42), `SaveV5MigrationTest` PASS(37), `CampaignSaveLoadSmokeTest` 246 assertions 중 8건 실패(통합 경계로 분리)
UI check: 저장 파일과 화면을 변경하지 않은 읽기 전용 감사이며 별도 UI 수정·캡처는 실행하지 않음
Unresolved issues: 실제 1.2.1 원본 hash/mtime·이어하기 미검수, Stage 04 투영 계약 P2 재현 필요, 전투 overlay 종료 후 후일담 autosave P2 재현 필요
