# v1.2.2 시각 개편 4단계 Stage 01 조사 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 마왕성 v1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `origin/codex/v122-ui-simplification` / `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 순차 시각 개편의 다음 작업인 4단계 성 배경·공간 연결을 진행한다.
- 완료 조건:
  - Stage 01의 실제 렌더·이동 데이터 소유자를 확인한다.
  - 현재 여섯 랜드마크를 같은 크기로 비교한다.
  - 자산 수정 전 제작 범위와 불변 조건을 고정한다.
  - 사용자 승인용 한 장 보드와 한 가지 결정 질문을 만든다.
- 범위에서 제외한 사항:
  - 사용자 승인 전 신규 그래픽 생성·런타임 연결
  - 방 위치, walkable, collider 성격, AI, 순찰, 밸런스, 저장 변경
  - 모바일 웹
  - 전체 QA·빌드·커밋·푸시

## 3. 완료한 작업

- 조사:
  - 현재 기본 지도는 `QuarterDungeonRenderer`와 `ModuleGraph`를 사용함을 확인했다.
  - 과거 connected map과 module visual PNG는 현재 기본 Stage 01 렌더의 주 기준이 아님을 확인했다.
  - 28×26 마스터 그리드, 5×5 방, 2셀 복도, 88 floor/walk 셀, 14 bridge·7 paired 접합군을 확인했다.
- 시각 분석:
  - 입구·병영·회복실·보물실·건설 슬롯은 유지 후보로 분류했다.
  - 왕좌는 픽셀 밀도와 선 굵기가 달라 우선 교체 후보로 분류했다.
  - 복도·bridge·문턱에 반복되는 황금색이 석재 공간보다 UI 경로처럼 읽히는 원인을 코드에서 확인했다.
- 문서:
  - 시각 논지, 제작안 비교, 불변 조건과 승인 질문을 계약 문서로 만들었다.
  - 기존 사용자 캡처와 실제 자산·데이터 구조를 한 장의 로컬 review board로 만들었다.
- 스토리·데이터·밸런스·저장: 변경 없음
- 런타임 코드·그래픽 자산: 변경 없음

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/design/v122/V122_STAGE01_SPATIAL_ART_CONTRACT_2026-07-29.md` | Stage 01 공간·아트 제작 범위와 불변 조건 | 완료 |
| `tools/build_stage01_phase4_review_board.mjs` | 현재 캡처·랜드마크·walkable 구조 비교 보드 생성 | 완료 |
| `docs/plans/V122_VISUAL_OVERHAUL_SEQUENTIAL_PLAN_2026-07-29.md` | 4단계 조사 완료·제작 승인 대기 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 현재 상태와 다음 승인 단위 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 비교 보드: `C:\Users\LDK-6248\.codex\visualizations\2026\07\27\019fa2ea-5220-7fd2-9355-4b09f55558ad\v122_phase4_stage01_review_board.png`
- 보드 입력: 사용자가 제공한 기존 캡처, 현재 Stage 01 런타임 PNG 6종, 현재 JSON 셀 데이터

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 보드 생성 스크립트 실행 | PASS | review board PNG 생성 |
| 2 | 생성 보드 원본 해상도 시각 확인 | PASS | 캡처·6종 자산·정확한 셀 구조 표시 |
| 3 | 런타임 자동 테스트 | NOT_REQUIRED | 런타임 코드·데이터·자산 변경 없음 |
| 4 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 실행하지 않음 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: `49388876d50009ed87655fffb2bf6974098b2f6c + UNCOMMITTED_DOCUMENTATION`
- Review range: `49388876d50009ed87655fffb2bf6974098b2f6c..UNCOMMITTED_DOCUMENTATION`
- Remaining P1/P2: N/A
- Final review result: `OWNER_SCOPE_APPROVAL_PENDING`

## 7. 미해결 항목과 위험

- 사용자 결정: `Option A — 셀 정합형 부분 교체` 승인 여부
- 승인 전 금지: 신규 왕좌·transition 생성, renderer·manifest 연결
- 렌더 위험: Stage 01 full-grid 랜드마크와 절차형 복도 사이의 투영·alpha 경계를 exact guide 없이 수정하면 현재 단절이 반복될 수 있다.
- 기능 위험: connected background 한 장 방식으로 돌아가면 방 교체·Stage 확장과 walkable 셀이 불일치할 수 있다.

## 8. 다음 작업 순서

1. 사용자에게 Option A 승인 여부를 한 질문으로 확인한다.
2. 승인 시 왕좌와 N/E/S/W 2셀 문턱의 exact 투영 guide를 만든다.
3. guide 승인 뒤 GPT 내부 이미지 생성으로 자산을 제작한다.
4. Stage 01 시각 레이어에만 연결하고 관련 화면·이동 정합을 확인한다.

## 9. 작업 트리 상태

- 기존 Phase 1~3 미커밋 변경과 Godot `.import` 자동 변경을 보존했다.
- 이번 단계 신규 변경은 조사 계약·보드 도구·계획·CURRENT·핸드오프 문서다.
- 로컬 review board는 별도 시각화 경로에 있으며 저장소에 추가하지 않았다.
- 빌드·커밋·푸시하지 않았다.

## 10. 종료 체크리스트

- [x] 실제 렌더·이동 데이터 소유자 확인
- [x] 대표 자산 6종 비교
- [x] 제작안·불변 조건 문서화
- [x] 승인용 보드 생성·시각 확인
- [x] 런타임 자산 미변경
- [x] 전체 검수·빌드·커밋·푸시 미실행
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 사용자 Option A 승인
- [ ] 신규 자산 생성·런타임 연결
