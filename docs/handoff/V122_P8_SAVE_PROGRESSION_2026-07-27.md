# v1.2.2 P8 저장·진행도 호환

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v122-save-progression`
- 기준 브랜치 및 SHA: `codex/v122-ui-combat-result@84272fd855d1ebe32379f63a9cd42c36d51e5c90`
- 기능 커밋 SHA: `7c4c73af8c0aba1413b88d30b76659cd1689bf6e`
- 원격 푸시: 미실행

## 2. 완료한 작업

- 정식 `CampaignSaveStore` v1 payload에 optional `v122_battle_plan` 확장을 추가하고 기존 v1.2.0·v1.2.1 저장은 필드 누락 상태로 계속 허용했다.
- 제품 `ModuleGraph`에서 만든 battle plan, 시설·몬스터 slot 배치, 마지막 확정 배치, 일반전·DAY 30 retry snapshot, 명령 설정과 최소 UI 접기 상태를 저장·복원한다.
- 전투 시작 직전 확정 배치와 지침을 snapshot으로 고정하고 일반전과 최종전 재시도에서 같은 배치를 복원한다.
- actor 현재 HP, cooldown, command points, combat elapsed 같은 전투 중간 transient 상태는 저장하지 않는다.
- 기존 temp 검증→backup→rename 원자 저장 절차를 유지하고 migration 검증 실패 시 이전 원본이 바뀌지 않음을 고정했다.
- v1→v2→v3→v4→v5 보조 migration chain이 v1.2.2 optional payload를 `legacy_payload`에 보존하도록 기존 구조 안에서 검증했다.
- DAY 5→6, DAY 30→엔딩, 성장 버튼, 재도전과 안전 저장 화면의 기존 제품 흐름을 유지했다.

## 3. 테스트

| 방법 | 결과 |
|---|---|
| `V122SaveProgressionTest` 전체 fixture·원자 복구·transient 제외 | PASS |
| 기존 `CampaignSaveLoadSmokeTest` | PASS, 252 assertions |
| 기존 `SaveV5MigrationTest` | PASS, 37 assertions |
| 제품 전체 `DemoSmokeTest` | PASS |
| v1.2.0·v1.2.1·DAY 3/5/12/20/25/29/30·엔딩·Update 4 | PASS |
| corrupt·`.tmp`·`.bak`·migration 실패 원복 | PASS |
| 일반전·DAY 30 확정 배치 retry | PASS |
| Full·전체 플레이 | NOT_RUN, RC 이전 정책에 따라 제외 |

손상 fixture는 의도적으로 깨진 JSON을 읽기 때문에 Godot가 parse error를 출력하지만 테스트는 `STATUS_CORRUPT` 차단과 invalid marker를 확인한 뒤 PASS한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 7c4c73af8c0aba1413b88d30b76659cd1689bf6e
- Review range: 84272fd855d1ebe32379f63a9cd42c36d51e5c90..7c4c73af8c0aba1413b88d30b76659cd1689bf6e
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 4. 다음 작업

1. P9에서 DAY 1~5 실제 제품 fixture를 기준으로 계산 계수를 보정하고 기준 대비 오차를 ±10% 이내로 고정한다.
2. P10~P14는 P9에서 고정한 단일 계산 모델을 사용해 DAY 6~30 구간과 보스를 순차 재계산한다.
