# V1.2.2 Q1-L UI·현지화·placeholder 상세 감사 핸드오프

## 1. 기본 정보

- 목표 버전: 제품 `1.2.2`
- 작업 패킷: `Q1-L UI·현지화·placeholder`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 커밋하지 않음)
- PR·푸시: 없음

## 2. 완료 내용

현지화 카탈로그의 한·영 키 대칭과 빈 값, 이름 placeholder, 개발용 임시 문구를 확인하고 관리·튜토리얼·전투·결산 UI 계약을 대상 테스트로 재실행했다. 합성 화면에서 활성 의회 왕관 후보의 `MON_GOBLIN`, 전투 목표의 `throne`, 활성 경로의 `entrance → spike_corridor → throne`이 사용자 문구로 노출되는 P3를 재현했다. S09의 과거 `trap` 노출은 현재 기준 SHA와 다르므로 carry-forward로 분리했다.

Q1-L에서는 런타임·데이터·그래픽·오디오를 수정하지 않았다. 모든 자동 테스트는 exit 0이며 실제 Windows 후보 화면의 버튼·최대 글꼴·긴 문구·dead click 검수는 `OWNER_QA_PENDING`이다.

## 3. 산출물과 변경 파일

- `docs/qa/V122_Q1L_UI_LOCALIZATION_PLACEHOLDER_AUDIT_2026-08-02.md`
- `docs/handoff/V122_RELEASE_POLISH_Q1L_UI_LOCALIZATION_PLACEHOLDER_AUDIT_2026-08-02.md`
- `tmp/v122_release_polish/q1_l/q1_l_inventory.json`
- `tmp/v122_release_polish/q1_l/q1_l_inventory.tsv`
- `tmp/v122_release_polish/q1_l/Q1LUiLocalizationRepro.gd`
- `tmp/v122_release_polish/q1_l/Q1LUiLocalizationRepro.tscn`
- `tmp/v122_release_polish/q1_l/*.log`
- `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md` 및 `docs/handoff/CURRENT.md`는 다음 순서 갱신에 포함한다.

임시 재현기와 로그는 `tmp/` 아래에만 두며 소스 브랜치에 커밋하지 않는다. 기존 사용자의 `.png.import` 6개와 `.uid` 7개 변경은 건드리지 않았다.

## 4. 검수

| 항목 | 결과 |
|---|---|
| 한·영 Stage 10 현지화 | PASS (ko/en 각 142키, 누락·빈 값 0) |
| 스토리 제품 흐름 | PASS (33 assertions) |
| 튜토리얼 안내 수준 | PASS |
| 관리 UI 계약 | PASS |
| 전투 UI 단순화 | PASS (85 assertions, failure_count 0) |
| 전투 결과 UI 계약 | PASS |
| Q1-L 합성 문구 재현 | PASS_WITH_FINDINGS (8 assertions, P3 3종 재현) |
| 실제 Windows 후보 전체 UI | 미실행 — 소유자 검수 필요 |

## 5. 발견 사항과 다음 작업

1. `Q1-L-P3-01`: `Update4CouncilDecisionOverlay.gd:108`의 후보 instance ID 표시를 별도 UI 문구 패킷에서 제거한다.
2. `Q1-L-P3-03`: 전투 목표·활성 경로에 room display name adapter를 연결하는 별도 전투 UI 패킷을 만든다.
3. `Q1-L-P3-04`: 새 room ID의 결산 fallback 표시 정책을 별도로 결정한다.
4. `Q1-L-P3-02`: 현재 후보 DAY 2 가시 복도에서 과거 `trap` 노출을 재확인한다.
5. 계획 순서의 다음 패킷은 `Q1-P 성능 상세 감사`다. Q1-L P3를 Q1-P와 같은 수정에 섞지 않는다.
6. 사용자는 1280×720 대표 화면에서 버튼·최대 글꼴·긴 문구·dead click을 직접 확인한다.

## 6. 정책 고정 필드

Related tests: `V122Stage10LocalizationTest` PASS, `V122StoryProductFlowTest` PASS(33), `V122TutorialGuidanceLevelTest` PASS, `V122ManagementUIContractTest` PASS, `V122CombatUISimplificationTest` PASS(85), `V122CombatResultUIContractTest` PASS, `Q1LUiLocalizationRepro` PASS_WITH_FINDINGS(8)
UI check: headless 합성에서 의회 후보·전투 목표·활성 경로의 내부 ID 노출을 확인했으며 실제 1280×720 Windows 후보 화면은 미검수
Unresolved issues: Q1-L-P3-01·03 수정, S09 `trap` 재확인, 미지 room fallback, 전체 UI/max font/long text/dead click 소유자 검수

## 7. 범위 경계

- 코드·데이터·그래픽·오디오 변경: 0
- 빌드·export: 실행하지 않음
- Full 회귀·전체 플레이·별도 검수 에이전트: 실행하지 않음
- 커밋·푸시: 실행하지 않음
