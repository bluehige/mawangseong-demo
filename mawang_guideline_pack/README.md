# 마왕님, 마왕성은 누가 지켜요? — 제작 전 지침 패키지

이 압축 파일은 본격 제작 전에 새 세션, Codex 작업, 아트 생성, QA 작업에 반복해서 붙여 넣을 수 있는 기준 문서 묶음이다.

## 구성

| 파일 | 용도 |
|---|---|
| `docs/00_PROJECT_CORE_INSTRUCTIONS.md` | 프로젝트 전체에 항상 적용할 핵심 지침 |
| `docs/01_SESSION_START_COMMANDS.md` | 새 세션 시작 전에 붙여 넣을 공통/세션별 명령문 |
| `docs/02_CODEX_IMPLEMENTATION_PLAYBOOK.md` | Godot 4.5/Codex 구현 세션용 제작 순서와 지시문 |
| `docs/03_ASSET_GENERATION_GUIDE_GPT_IMAGE_2.md` | gpt-image-2 이미지 리소스 생성 지침과 프롬프트 |
| `docs/04_SESSION_ROADMAP_AND_DELIVERABLES.md` | 세션별 목표, 산출물, 완료 조건 |
| `docs/05_QA_BALANCE_CHECKLIST.md` | 기능 테스트, 밸런스, 버그 검수 체크리스트 |
| `docs/06_DECISION_LOG_TEMPLATE.md` | 의사결정/변경사항 기록 템플릿 |
| `docs/07_QUICK_START_CHEATSHEET.md` | 가장 짧은 요약본 |
| `docs/08_CURRENT_QUARTERVIEW_GUIDELINES.md` | 현재 제작에 바로 적용할 쿼터뷰/핸드오프 통합 지침 |
| `reference/99_REFERENCE_quarterview_demo_spec.md` | 직전 작성한 쿼터뷰 데모 상세 기획서 백업 |

## 권장 사용법

1. 새 ChatGPT/기획 세션을 시작할 때 `00_PROJECT_CORE_INSTRUCTIONS.md`와 `01_SESSION_START_COMMANDS.md`를 먼저 붙여 넣는다.
2. Codex 구현 세션을 시작할 때 `00_PROJECT_CORE_INSTRUCTIONS.md`와 `02_CODEX_IMPLEMENTATION_PLAYBOOK.md`를 붙여 넣는다.
3. 이미지 리소스를 만들 때 `03_ASSET_GENERATION_GUIDE_GPT_IMAGE_2.md`의 프롬프트를 사용한다.
4. 구현 완료 후 `05_QA_BALANCE_CHECKLIST.md`로 검수한다.
5. 변경된 결정은 `06_DECISION_LOG_TEMPLATE.md`에 기록한다.
6. 세션을 넘길 때는 `08_CURRENT_QUARTERVIEW_GUIDELINES.md`의 핸드오프 작성 기준을 따른다.
