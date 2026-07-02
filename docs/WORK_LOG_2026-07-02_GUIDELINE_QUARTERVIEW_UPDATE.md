이 파일이 왜 필요한지: 2026-07-02 지침 패키지를 현재 목표인 2D 쿼터뷰 기준으로 전환하고, 핸드오프 작성 기준을 확인/정리한 작업 내역을 백업한다.

# 작업 로그: 지침 패키지 쿼터뷰 전환

작성일: 2026-07-02

## 요청

사용자가 `mawang_guideline_pack`의 지침서 전체를 확인하고, 현재 목표가 쿼터뷰로 바뀌었으므로 기존 탑뷰 기준을 쿼터뷰 기준으로 바꾸라고 요청했다.

추가로 핸드오프 문서 작성 요령이 있으니 확인하고, 앞으로 그 기준에 맞춰 세션을 넘기라고 요청했다.

## 확인한 파일

- `mawang_guideline_pack/README.md`
- `mawang_guideline_pack/docs/00_PROJECT_CORE_INSTRUCTIONS.md`
- `mawang_guideline_pack/docs/00A_PROJECT_CORE_COPYPASTE.txt`
- `mawang_guideline_pack/docs/01_SESSION_START_COMMANDS.md`
- `mawang_guideline_pack/docs/02_CODEX_IMPLEMENTATION_PLAYBOOK.md`
- `mawang_guideline_pack/docs/03_ASSET_GENERATION_GUIDE_GPT_IMAGE_2.md`
- `mawang_guideline_pack/docs/04_SESSION_ROADMAP_AND_DELIVERABLES.md`
- `mawang_guideline_pack/docs/05_QA_BALANCE_CHECKLIST.md`
- `mawang_guideline_pack/docs/06_DECISION_LOG_TEMPLATE.md`
- `mawang_guideline_pack/docs/07_QUICK_START_CHEATSHEET.md`
- `mawang_guideline_pack/reference/99_REFERENCE_topview_demo_spec.md`

## 작업 내용

- 모든 지침 문서의 기존 탑뷰 기준을 2D 쿼터뷰 기준으로 전환했다.
- 레퍼런스 파일명을 `99_REFERENCE_quarterview_demo_spec.md`로 변경했다.
- 쿼터뷰 구현이 완전 3D 전환으로 오해되지 않도록 다음 기준을 명시했다.
  - 2D 좌표계 유지
  - 발밑 피벗
  - 화면 y값 기반 Y-sort
  - 작은 발밑 충돌체
  - 쿼터뷰 배경/스프라이트
- 이미지 생성 지침을 3/4 하향 쿼터뷰 프롬프트로 보강했다.
- QA 체크리스트에 쿼터뷰 가독성, 가림 처리, 발밑 피벗, 앞뒤 정렬 검증 항목을 추가했다.
- `docs/08_CURRENT_QUARTERVIEW_GUIDELINES.md`를 추가해 현재 제작에 바로 적용할 통합 지침으로 정리했다.
- `01_SESSION_START_COMMANDS.md`와 `06_DECISION_LOG_TEMPLATE.md`에 핸드오프 문서 작성 기준을 명확히 추가했다.

## 핸드오프 작성 기준 확인 결과

앞으로 세션을 넘길 때는 다음 두 문서를 분리해서 남긴다.

- 핸드오프 문서: 현재 목표, 최신 결정, 변경 파일, 완료 기능, 검증 결과, 미완성 항목, 다음 첫 작업, 리스크, 새 세션 시작 문장
- 작업 로그: 요청, 작업 전 판단, 실제 작업 내용, 검증 결과, 남은 판단 사항

다음 작업부터는 `mawang_guideline_pack/docs/08_CURRENT_QUARTERVIEW_GUIDELINES.md`를 우선 기준으로 삼는다.

## 검증 결과

- `rg`로 `탑뷰`, `top-down`, `topview`, `REFERENCE_topview` 잔여 표현을 확인했다.
- 과거 탑뷰 기준 표현은 활성 지침에서 제거되었다.
- 남은 `폐기` 표현은 `기존 평면 기준은 폐기하고, 쿼터뷰만 제작 기준으로 사용한다`라는 의도된 문장이다.

## 남은 판단 사항

- 실제 게임 코드는 아직 쿼터뷰 렌더링으로 전환되지 않았다. 이번 작업은 지침 패키지 정리다.
- 다음 구현 세션에서는 `08_CURRENT_QUARTERVIEW_GUIDELINES.md`를 읽고 실제 맵/유닛 렌더링 전환 계획을 세워야 한다.
