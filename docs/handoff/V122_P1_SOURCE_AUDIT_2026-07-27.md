# v1.2.2 P1 source audit

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-source-audit`
- 기준 브랜치 및 SHA: `codex/v122-integration-contract@64b4a3327af45ff033c1bd4e73f3063d7ca6cf00`
- 감사 커밋 SHA: `f255ee6fe722e0ba15dff0aee817179677d53f8f`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 세 기준점의 역할을 실제 파일·함수로 대조하고 코드 수정 전 대응표 6종을 완성한다.
- 완료 조건: 필수 파일 6개 존재, 허용 처리 방식으로 모든 행 분류, 대응표 내부 `UNKNOWN` 0.
- 범위에서 제외한 사항: runtime/data/scene/asset 구현과 전체 검수.

## 3. 완료한 작업

- 제품 기준: DAY 1~30, 건물, 성장, 저장, Update 2~4, 엔딩과 플랫폼의 정식 소유자를 고정했다.
- 전투 기준: spatial, placement, facility, monster/enemy role, command, encounter, event ledger, A/B/C/D의 behavior contract를 고정했다.
- UI 기준: 타이틀은 이식하지 않고 briefing·배치·HUD·결과의 정보 구조만 제품 view model에 연결하도록 고정했다.
- 저장 기준: CampaignSaveStore migration chain을 보존하고 optional `v122_battle_plan` 확장만 허용했다.
- 밸런스 기준: DAY 1~5 보정 뒤 DAY 6~30을 B1~B5 순서로 재계산하는 공식을 고정했다.
- 건물 감사: 기존 제품 object를 기준으로 삼고 `watch_post` 전투 상태 연결을 P2 폐쇄 항목으로 분류했다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `docs/design/v122/V122_SOURCE_OF_TRUTH_MATRIX.md` | 제품 단일 기준 |
| `docs/design/v122/V122_COMBAT_TRANSPLANT_MATRIX.md` | 전투 behavior 이식 |
| `docs/design/v122/V122_UI_TRANSPLANT_MATRIX.md` | UI view-state 이식 |
| `docs/design/v122/V122_BUILDING_COMPATIBILITY_MATRIX.md` | 제품 건물 object·상태 |
| `docs/design/v122/V122_SAVE_COMPATIBILITY_MATRIX.md` | 저장 fixture·확장 |
| `docs/design/v122/V122_BALANCE_RECALCULATION_MATRIX.md` | 계산식·DAY 구간 |
| `docs/handoff/CURRENT.md` | 다음 P2 진입점 |
| `docs/handoff/V122_P1_SOURCE_AUDIT_2026-07-27.md` | 세션 기록 |

## 5. 그래픽 및 오디오 자산

- 신규 자산: 없음
- 런타임 자산 변경: 없음
- 이미지 생성: 사용하지 않음

## 6. 테스트 및 검수

| 순서 | 방법 | 결과 |
|---:|---|---|
| 1 | 필수 대응표 6종 존재 검사 | PASS |
| 2 | 대응표 6종 `UNKNOWN` 검색 | PASS, 0건 |
| 3 | `git diff --check 64b4a3327af45ff033c1bd4e73f3063d7ca6cf00..f255ee6fe722e0ba15dff0aee817179677d53f8f` | PASS |
| 4 | repository policy | PASS, `8 final files, 1 commits inspected` |
| 5 | 전체 회귀·실플레이 | NOT_REQUESTED, P1에서 실행하지 않음 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: f255ee6fe722e0ba15dff0aee817179677d53f8f
- Review range: `64b4a3327af45ff033c1bd4e73f3063d7ca6cf00..f255ee6fe722e0ba15dff0aee817179677d53f8f`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- `watch_post`는 제품 object·role이 있으나 신규 reveal·상태·ledger 연결이 필요하다.
- v20 수치는 제품 성장 상태에서 재계측하기 전까지 제품 수치로 사용하지 않는다.
- UI는 U5 scene을 복사하지 않고 기존 모든 제품 기능의 진입점을 유지해야 한다.

## 8. 다음 작업 순서

1. P2에서 건물 object와 시설 role을 실제 runtime 상태 adapter에 연결한다.
2. 건물 누락·label-only·wrong anchor/facing·상태 불일치 검사를 자동화한다.
3. 관련 건물·renderer 테스트와 Quick·repository policy만 실행한다.

## 9. 작업 트리 상태

- 기준 SHA에서 문서 파일만 변경했다.
- runtime/data/scene/asset 변경: 0
- LFS: 포인터 checkout, P1 문서 감사에는 영향 없음

## 10. 종료 체크리스트

- [x] 대응표 6종 작성
- [x] 대응표 `UNKNOWN` 0
- [x] 코드·데이터·씬·자산 변경 0
- [x] `CURRENT.md` 갱신
- [x] diff·policy 통과 후 커밋
