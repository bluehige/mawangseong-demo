# V1.2.2 Q1-S P2 재현 핸드오프 — Stage 04 투영 계약

## 기본 정보

- 목표 버전: 제품 1.2.2
- 패킷: `Q1-S-INTEGRATION-01`
- 브랜치: `codex/v122-ui-simplification`
- 기준·마지막 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 커밋·푸시: 하지 않음

## 완료 내용

Stage 04를 읽기 전용으로 구성해 `area_room_count=11`과 renderer full-grid 투영 수를 분리 측정했다. 제품 기본 layout `stage01_dual_front_candidate_01`에서 object slot은 13개, full-grid 투영 슬롯은 12개이며, 그중 `service_entrance`가 두 번째 입구 object로 포함된다. `spike_corridor`는 `spike_floor` 예외라 full-grid에서 제외된다.

따라서 기존 smoke의 “실제 쿼터뷰 구역 11개 투영” assertion은 진행 계약과 시각 object 계약을 한 숫자로 묶은 P2 통합 계약 공백이다. 이번 패킷에서는 제품 결정을 임의로 하지 않았고 renderer·데이터·테스트를 수정하지 않았다.

## 변경·산출물

- 보고서: `docs/qa/V122_Q1S_STAGE04_PROJECTION_CONTRACT_2026-08-02.md`
- 임시 재현기·보고서: `tmp/v122_release_polish/q1_s_projection/`
- 런타임·데이터·자산·빌드 변경: 없음

## 다음 작업

1. 제품 기준을 결정한다: `service_entrance`를 시각 투영 12개에 포함하거나 별도 entry visual로 분류한다.
2. 구역 계약 assertion과 시각 투영 assertion을 분리한 전용 테스트를 만든다.
3. 제품 결정 후에만 최소 범위의 테스트·renderer 경계 수정 여부를 정한다.
4. Q1-S 기록을 마치고 계획 순서대로 Q1-I 입력·IME 감사를 시작한다.

## 정책 고정 필드

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
Review range: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d..efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
Remaining P1/P2: Stage 04 투영 계약 P2 결정·전용 테스트 분리, 실제 1.2.1 원본·후보 빌드 소유자 검수
Final review result: `TARGETED_PASS_WITH_DOCUMENTED_CONTRACT_GAP`

Related tests: `Q1SProjectionContractRepro` 종료 코드 0, 11 대 12 집계 차이 확인
UI check: headless 구조 재현, UI·renderer·자산 변경 없음
Unresolved issues: `service_entrance` 포함 여부, smoke assertion 분리, 실제 1.2.1 hash/mtime·이어하기 소유자 검수
