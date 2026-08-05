# V1.2.2 Q1-P 성능·메모리 상세 감사 핸드오프

## 1. 기본 정보

- 목표 버전: 제품 `1.2.2`
- 작업 패킷: `Q1-P 성능·메모리`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 커밋하지 않음)
- PR·푸시: 없음

## 2. 완료 내용

기존 `EngineerPerformanceSmokeTest`와 전투 시각 계층 계약을 재실행하고, 임시 합성 재현기로 idle·동적 전투 표식 20개·타격 효과 24개·함정·시설 카운트다운·복합 효과를 시나리오당 120프레임 계측했다. 모든 시나리오에서 정적 던전 전체 redraw는 0회였고, headless wall p95는 동적 표식 15.034ms, 타격 15.955ms, 함정 15.954ms, 복합 효과 15.129ms였다.

이 결과는 headless CPU/process 계측이다. 실제 Windows GPU, 저사양 작업 관리자 메모리/RSS, 장시간 발열·메모리 누수는 실행하지 못해 `OWNER_QA_PENDING`으로 인계한다. Q1-P에서 런타임·데이터·그래픽·오디오를 수정하지 않았다.

## 3. 산출물과 변경 파일

- `docs/qa/V122_Q1P_PERFORMANCE_AUDIT_2026-08-02.md`
- `docs/handoff/V122_RELEASE_POLISH_Q1P_PERFORMANCE_AUDIT_2026-08-02.md`
- `tmp/v122_release_polish/q1_p/q1_p_inventory.json`
- `tmp/v122_release_polish/q1_p/q1_p_inventory.tsv`
- `tmp/v122_release_polish/q1_p/Q1PPerformanceRepro.gd`
- `tmp/v122_release_polish/q1_p/Q1PPerformanceRepro.tscn`
- `tmp/v122_release_polish/q1_p/*.log`

임시 재현기·로그·기계 결과는 `tmp/` 아래에만 둔다. 사용자의 기존 `.png.import` 6개와 `.uid` 7개 변경은 건드리지 않았다.

## 4. 검수

| 항목 | 결과 |
|---|---|
| 전투 오버레이·함정·시설 성능 스모크 | PASS (20 assertions) |
| 전투 시각 계층 계약 | PASS |
| Q1-P 복합 headless 계측 | PASS (5 assertions, 6 시나리오 × 120프레임) |
| 정적 맵 전체 redraw | PASS (모든 시나리오 0회) |
| 실제 Windows GPU·저사양 RSS·장시간 전투 | 미실행 — 소유자 검수 필요 |

## 5. 발견 사항과 다음 작업

1. `Q1-P-PASS-01`: 동적 overlay·타격·함정·시설 분리 구조는 현재 기준에서 회귀하지 않았다.
2. `Q1-P-OWNER-01`: 새 Windows QA 후보에서 1280×720 대표 전투를 최소 10분 실행하고 FPS p95·최대 frame time·작업 관리자 메모리 시작/최대/종료를 기록한다.
3. headless 직접 전투 시작에 따른 autosave 요약 경고와 ObjectDB/RID cleanup은 harness noise로 기록하며 제품 결함으로 수정하지 않는다.
4. 다음 계획 패킷은 `Q1-R 권리·출처·deprecated 감사`이며 Q1-P owner 검수와 런타임 수정은 섞지 않는다.

## 6. 정책 고정 필드

Related tests: `EngineerPerformanceSmokeTest` PASS(20), `V122CombatVisualHierarchyTest` PASS, `Q1PPerformanceRepro` PASS(5)
UI check: headless Windows full 프로필의 6개 전투 시나리오에서 정적 맵 redraw 0회와 wall p95를 확인했으며 실제 GPU 화면은 미검수
Unresolved issues: 실제 Windows GPU·저사양 RSS·장시간 전투 검수, headless autosave/ObjectDB/RID cleanup 경고(harness noise)

## 7. 범위 경계

- 코드·데이터·그래픽·오디오 변경: 0
- 빌드·export: 실행하지 않음
- Full 회귀·전체 플레이·별도 검수 에이전트: 실행하지 않음
- 커밋·푸시: 실행하지 않음
