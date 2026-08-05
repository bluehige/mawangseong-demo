# v1.2.2 시각 개편 8단계 Stage 01 N 문턱 생성 원본 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 왕좌 다음 작업을 진행한다.
- 해석: `다음꺼 진행해`를 왕좌 시각 방향 승인과 N 문턱 순차 제작 승인으로 기록했다.
- 완료 조건:
  - N 방향 2셀 문턱 생성 원본 한 종을 만든다.
  - Stage 01 왕좌의 재질·광원과 N exact guide의 seam 방향을 함께 사용한다.
  - 문턱이 장애물로 보이지 않도록 바닥 매입형으로 만든다.
  - 초록 key를 alpha로 제거하고 출처·프롬프트를 기록한다.
  - 사용자 승인 전 런타임에 연결하지 않는다.
- 범위 제외: E/S/W 문턱, 복도 표면, native slicing, runtime manifest/renderer, 화면·플레이·전체 QA, 빌드·커밋·푸시.

## 3. 완료한 작업

- `imagegen` 스킬과 GPT 내부 이미지 생성 경로를 사용했다.
- exact N guide를 geometry edit target, 승인된 왕좌를 재질·광원 reference로 분리했다.
- 첫 후보에서 charcoal stone과 방·복도 재질 구분은 확보했지만 patch가 guide보다 크고 황동 띠가 장애물처럼 보여 제외했다.
- 두 번째 후보에서 황동·목재 경계를 바닥 매입형으로 낮추고 두 통행 셀을 열어 선택했다.
- flat chroma key를 공식 helper로 제거하고 alpha 승인 후보를 만들었다.
- 생성 모델이 exact guide의 캔버스 점유율까지 지키지 못한 사실을 기록했으며, 현재 파일을 runtime에 바로 사용하지 않는다.
- 런타임 자산과 manifest는 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_intermediate_raised_seam.png` | 탈락한 첫 후보와 보정 근거 보존 | 보존 |
| `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_selected_raw_chroma.png` | 선택한 GPT 생성 원본 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_selected_alpha_preview.png` | 사용자 승인용 alpha 후보 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/SOURCE.md` | 모델·날짜·프롬프트·후처리·정합 유보 기록 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE08_THRESHOLD_N_SOURCE_2026-07-29.md` | 이번 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본 경로:
  - `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_selected_raw_chroma.png`
- `SOURCE.md` 경로:
  - `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/SOURCE.md`
- 런타임 최종 자산 경로: 없음
- alpha 승인 후보:
  - `assets/source/imagegen/v122_stage01_spatial/threshold_n_2cell/threshold_n_2cell_selected_alpha_preview.png`
- 게임 연결 및 실제 렌더 확인 결과: 미연결

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 선택 alpha 원본 시각 확인 | PASS | seam이 바닥 매입형이며 통행 폭을 막지 않음 |
| 2 | image mode·size | PASS | `1254×1254`, RGBA |
| 3 | corner alpha 4곳 | PASS | 모두 `0` |
| 4 | greenish opaque pixel 검사 | PASS | `0` |
| 5 | alpha pixel 분류 | PASS | transparent 1,124,189 / partial 3,034 / opaque 445,293 |
| 6 | exact guide canvas 점유율 | DEFERRED | 승인 뒤 native slicing 단계에서 결정적으로 fit |
| 7 | 런타임 관련 테스트 | NOT_REQUIRED | 런타임 미변경 |
| 8 | 전체 회귀·플레이 검수 | NOT_REQUESTED | 사용자 요청 전 보류 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 사용자 N 문턱 시각 승인 전이다.
- alpha bbox는 guide bbox보다 크므로 runtime에 직접 연결할 수 없다.
- native `256×128` 축소에서 석재와 목재 디테일이 뭉개질 수 있어 contact sheet에서 확인해야 한다.
- N은 `back` 레이어이며 실제 합성 순서는 runtime 연결 단계에서 별도 확인해야 한다.

## 8. 다음 작업 순서

1. 사용자가 N 문턱의 재질 구분, 매입형 seam, 통행 가독성을 승인 또는 수정 지시한다.
2. 승인되면 같은 기준으로 E 방향 2셀 문턱 하나를 생성한다.
3. E 승인 뒤 S, W를 각각 순차 제작한다.
4. 네 문턱 승인 뒤 저채도 복도 표면과 공통 폐색 그림자를 제작한다.
5. 전체 Stage 01 공간 자산 승인 뒤 exact slicing과 runtime lookup을 적용한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 HEAD: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 이번 단계 source PNG·문서가 미커밋 상태다.
- 기존 대규모 코드·데이터·`.import` 변경은 보존했다.
- 빌드·커밋·푸시하지 않았다.

## 10. 종료 체크리스트

- [x] imagegen 스킬 사용
- [x] exact N guide·승인된 왕좌 reference 분리
- [x] N 문턱 원본 생성
- [x] 장애물처럼 보이는 seam 보정
- [x] alpha 제거·검증
- [x] 생성 출처·프롬프트 기록
- [x] exact slicing 유보 상태 기록
- [x] 런타임 미연결
- [x] 전체 회귀·플레이 검수 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 사용자 N 문턱 시각 승인
- [ ] E/S/W 문턱 생성
- [ ] runtime 연결
- [ ] 커밋·푸시
