# 현재 작업 핸드오프

최종 갱신: 2026-07-28

이 파일은 다음 세션의 단일 진입점이다. 2026-07-27까지 누적된 전체 상세 이력은 [`CURRENT_HISTORY_2026-07-27.md`](CURRENT_HISTORY_2026-07-27.md)에 원문 그대로 보존했다.

## 현재 우선 진입점

- 마왕성 UI·UX 프로젝트 스킬: [`.agents/skills/mawangseong-ui-ux/SKILL.md`](../../.agents/skills/mawangseong-ui-ux/SKILL.md)
- UI·UX 스킬 도입 핸드오프: [`V20_UI_UX_SKILL_2026-07-28.md`](V20_UI_UX_SKILL_2026-07-28.md)
- 공개 범용 코어: [Game UI/UX Rules v1.0.0](https://github.com/bluehige/study)
- 제품 2.0 최종 UI 수정·출시 선별 이식 계획: [`V20_FINAL_UI_RELEASE_TRANSPLANT_PLAN.md`](../design/V20_FINAL_UI_RELEASE_TRANSPLANT_PLAN.md)
- U5 사용자 테스트 후보 핸드오프: [`V20_FINAL_UI_CANDIDATE_2026-07-27.md`](V20_FINAL_UI_CANDIDATE_2026-07-27.md)
- U5 후보 매니페스트: [`V20_FINAL_UI_CANDIDATE_MANIFEST_2026-07-27.json`](V20_FINAL_UI_CANDIDATE_MANIFEST_2026-07-27.json)
- DAY 1~5 상위 제품 계약: [`V20_DAY1_5_VALIDATION_CONTRACT.md`](../design/V20_DAY1_5_VALIDATION_CONTRACT.md)
- 사용자 UI 승인·정식 출시 직전 검수: [`DAY1_5_ACCEPTANCE_PROTOCOL.md`](../playtest/v20/DAY1_5_ACCEPTANCE_PROTOCOL.md)

## 현재 제품 상태

- `release/v2.0`은 정식 제품 출시선이 아니라 DAY 1~5 행동 계약 검증선이다.
- U0~U5 최종 UI 작업은 `release/v2.0`에 병합됐다.
- U5 source full SHA·Reviewed SHA: `5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`
- U5 Windows debug ZIP SHA-256: `437a27a391a9fe883da99889157199151b874a9498f02548f63f147bd4d6d8a0`
- U5 Web PCK SHA-256: `2def8a3f314ef816bc47d74d33fe18c9868ff1f972e3905aa8704706fc05db4c`
- U5 관련 UI 검사 309 assertions, Windows 부팅, Web 1280×720·1366×768 흐름과 console error·warning 0건은 targeted PASS다.
- 현재 게이트는 `G1_OWNER_PLAY_PENDING`이다.
- 사용자의 명시적 `V20_UI_OWNER_ACCEPTED` 전에는 P0와 `release/v2.0-product`를 시작하지 않는다.
- 게임 진행 단순성, 배치 재미, 전투 밸런스의 세 제품 가설은 계속 `PENDING`이다.
- 현재 하루 흐름은 `침입 확인 → 배치 → 방어 시작 → 전투 → 결과` 다섯 상태다.
- 기존 `v1.2.1` tag·Release·저장·PC/모바일 공개본은 변경하지 않는다.

## UI·UX 스킬 적용 상태

- 저장소 범위 스킬은 `.agents/skills/mawangseong-ui-ux/`에 있다.
- 범용 코어 `Game UI/UX Rules v1.0.0`을 참조하고, 범용 원칙을 저장소에 중복 복제하지 않는다.
- 프로젝트 스킬 기능 Reviewed SHA: `f6517e1de02a1ed4407f9e210440a85207c34bb4`
- 스킬은 타이틀, 침입 확인, 배치, countdown, 전투 HUD, 결과 화면의 계약·디자인 시스템·Godot 구현 경계·검증 매트릭스를 제공한다.
- 이번 도입은 문서와 Agent Skill만 추가했다. runtime, data, scene, asset, 밸런스, 저장, 빌드, 공개본 변경은 0건이다.
- 자동 테스트와 실제 렌더는 구조적 증거이며, 실제 사용자 UX 승인은 E4와 명시적 사용자 판정이 있어야 한다.

## 현재 실행 원칙

1. 모든 작업은 `AGENTS.md`, 이 파일, 대상 버전 최신 handoff를 먼저 읽는다.
2. UI 작업은 `.agents/skills/mawangseong-ui-ux/`의 화면 계약과 검증 매트릭스를 적용한다.
3. UI 수정에 밸런스, AI, spawn, HP/ATK, 시설·몬스터 효과, 콘텐츠, 저장 schema 변경을 섞지 않는다.
4. U0~U5와 P0~P4에서는 직접 관련 테스트와 필요한 해상도 렌더만 수행한다. 전체 검수는 동결 제품 RC의 F1에서만 수행한다.
5. `release/v2.0` 전체 merge, commit range cherry-pick, 디렉터리·핵심 controller 전체 덮어쓰기를 금지한다.
6. 사용자 승인 뒤에만 `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`에서 `release/v2.0-product`를 만들고 P0~P4를 작은 PR로 선별 재구현한다.
7. F0에서 RC SHA를 동결하고 F1에서 자동 계약, x1 60 Hz 실제 물리 70전, 숙련 QA 24전, 초회 사용자 10명 무설명 플레이를 같은 source SHA와 build hash에서 실행한다.
8. F1 뒤 runtime 변경이 생기면 새 RC에서 전체 검수를 다시 수행한다.

## 다음 작업 순서

1. 사용자가 U5 고정 Windows 또는 Web debug build를 정해진 12단계로 직접 플레이한다.
2. 수정 요청이면 해당 U1~U4 화면 계약으로 돌아가 새 source SHA와 build hash를 만든다.
3. 사용자가 정확한 SHA/hash에 대해 `V20_UI_OWNER_ACCEPTED`를 명시하면 P0를 시작한다.
4. P0~P4 선별 재구현 뒤 F0 RC 동결 → F1 전체 검수 → F2 최종 빌드를 수행한다.

## 검수 정책 필드

### 현재 U5 제품 후보

- Review task ID: NOT_REQUESTED
- Reviewed SHA: `5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`
- Review range: `380b8ad6c931739b8424ac05cca1384f5719f22e..5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

### UI·UX 프로젝트 스킬

- Review task ID: NOT_REQUESTED
- Reviewed SHA: `f6517e1de02a1ed4407f9e210440a85207c34bb4`
- Review range: `9e96a0901070694d784f6196d01a74b661775f3f..f6517e1de02a1ed4407f9e210440a85207c34bb4`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
