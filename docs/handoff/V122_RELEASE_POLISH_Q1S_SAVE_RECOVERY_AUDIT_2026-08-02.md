# V1.2.2 정식 출시 마무리 Q1-S 저장·복구 감사 핸드오프

## 기본 정보

- 목표 버전: 제품 1.2.2
- 작업 패킷: Q1-S 저장·복구 상세 감사
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시: 하지 않음
- 커밋: 하지 않음

## 완료 내용

저장소의 저장 계약과 관련 테스트를 읽기 전용으로 대조했다. `CampaignSaveStore`의 `.tmp/.bak` 원자적 쓰기·복구 순서, 손상·미지원 버전 차단, `StorySaveState`의 안전 복귀 화면 조건을 확인했다.

핵심 테스트 결과는 다음과 같다.

- `V122SaveProgressionTest`: PASS
- `SaveV4MigrationTest`: PASS, 42 assertions
- `SaveV5MigrationTest`: PASS, 37 assertions
- `CampaignSaveLoadSmokeTest`: 246 assertions 중 8건 실패

스모크 테스트의 8건은 Stage 04 쿼터뷰 투영 계약 4건과 전투 overlay가 남은 상태에서 후일담 autosave를 시도하는 통합 경계 4건으로 분리했다. 저장 파일 본문 손상이나 `.tmp/.bak` 복구 실패로 확정하지 않았다.

## 변경 파일

- `docs/qa/V122_Q1S_SAVE_RECOVERY_AUDIT_2026-08-02.md`
- `docs/handoff/V122_RELEASE_POLISH_Q1S_SAVE_RECOVERY_AUDIT_2026-08-02.md`
- `tmp/v122_release_polish/q1_s/q1_s_inventory.json` (임시 산출물)
- `tmp/v122_release_polish/q1_s/q1_s_inventory.tsv` (임시 산출물)

이번 패킷에서 런타임 코드, 데이터, 그래픽·오디오 자산, 빌드 산출물은 변경하지 않았다.

## 검수 기록

- 관련 테스트: 위 4개 Godot headless 테스트 실행
- `V122SaveProgressionTest`의 손상 fixture JSON 파싱 오류는 의도된 검증 출력이며 최종 PASS를 확인했다.
- `CampaignSaveLoadSmokeTest`의 전체 로그는 `tmp/v122_release_polish/q1_s_campaign_save_load_smoke.log`에 보존했다.
- 실제 1.2.1 원본 SHA-256·수정 시각, Windows 후보 빌드 이어하기, 실제 전투 종료 후 후일담 저장은 소유자 검수로 남겼다.
- UI 변경·자산 변경이 없으므로 이번 패킷의 별도 화면 캡처는 실행하지 않았다.

## 다음 작업

1. 실제 전투 종료와 overlay 닫힘을 포함하는 최소 사용자 흐름으로 후일담 autosave 경계를 재현한다.
2. `area_room_count`와 full-grid 시각 object 투영 수를 분리해 Stage 04 투영 계약을 재현한다.
3. 두 재현 결과를 각각 별도 P2 패킷에 기록한 뒤 Q1-I 입력·IME 감사로 진행한다.
4. 사용자가 제공하는 1.2.1 원본과 후보 Windows 빌드가 준비되면 hash/mtime·이어하기 소유자 검수를 수행한다.

## 정책 고정 필드

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
Review range: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d..efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
Remaining P1/P2: `Q1-S` 통합 재현 2건(P2_REVIEW_REQUIRED), 실제 1.2.1 원본·후보 빌드 소유자 검수 대기
Final review result: `TARGETED_PASS_WITH_DOCUMENTED_GAPS`

Related tests: `V122SaveProgressionTest` PASS, `SaveV4MigrationTest` PASS(42), `SaveV5MigrationTest` PASS(37), `CampaignSaveLoadSmokeTest` 8건 실패를 통합 경계로 분리
UI check: 읽기 전용 감사, UI·자산을 변경하지 않아 별도 화면 검수 없음
Unresolved issues: Stage 04 투영 계약과 전투 overlay 종료 후 후일담 autosave의 P2 재현, 실제 1.2.1 hash/mtime·이어하기 검수
