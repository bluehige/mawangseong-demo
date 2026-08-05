# v1.2.2 시각 개편 12단계 Stage 01 저채도 복도 표면 생성 원본 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: W 문턱 다음 작업을 진행한다.
- 해석: `진행해`를 W 문턱 시각 승인과 저채도 복도 표면 순차 제작 승인으로 기록했다.
- 완료 조건:
  - 승인된 문턱 family와 이어지는 저채도 2셀 복도 표면 원본 한 종을 만든다.
  - 일반 복도가 황금 안내선이 아닌 상시 보행 가능한 거친 석재로 읽히게 한다.
  - 문턱 seam·목재·황동·방 쪽 대형 석판을 복사하지 않는다.
  - native 축소에서 뭉치지 않도록 slab 밀도를 교정한다.
  - 초록 key를 alpha로 제거하고 출처·프롬프트를 기록한다.
  - 사용자 승인 전 런타임에 연결하지 않는다.
- 범위 제외: 공통 폐색 그림자, 가장자리 마스크, exact slicing, runtime manifest/renderer, 화면·플레이·전체 QA, 빌드·커밋·푸시.

## 3. 완료한 작업

- `imagegen` 스킬과 GPT 내부 이미지 생성 경로를 사용했다.
- 2×2 W guide를 footprint 기준, 승인된 W 문턱의 upper-left corridor slab을 재질 기준으로 분리했다.
- 첫 후보에서 저채도·무방향·연속형 복도 표면을 확보했지만 석재 수가 지나치게 많아 중간본으로 보존했다.
- 두 번째 교정에서 다이아몬드 형상·색·광원을 유지하고 slab 수만 줄여 native 축소 가독성을 높였다.
- 전체 표면을 charcoal·violet-gray·iron-gray로 낮추고 황금 경로선·목재·황동·중앙 문양을 제외했다.
- flat chroma key를 공식 helper로 제거하고 alpha 승인 후보를 만들었다.
- 생성 결과의 canvas 점유율은 exact guide보다 커 native slicing 단계로 유보했다.
- 런타임 자산과 manifest는 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/corridor_surface_2cell_intermediate_dense_raw_chroma.png` | 과밀 slab 중간 후보 | 보존 |
| `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/corridor_surface_2cell_selected_raw_chroma.png` | 선택한 GPT 생성 원본 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/corridor_surface_2cell_selected_alpha_preview.png` | 사용자 승인용 alpha 후보 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/SOURCE.md` | 모델·날짜·프롬프트·후처리·정합 유보 기록 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE12_CORRIDOR_SURFACE_SOURCE_2026-07-30.md` | 이번 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본 경로:
  - `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/corridor_surface_2cell_selected_raw_chroma.png`
- `SOURCE.md` 경로:
  - `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/SOURCE.md`
- 런타임 최종 자산 경로: 없음
- alpha 승인 후보:
  - `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/corridor_surface_2cell_selected_alpha_preview.png`
- 게임 연결 및 실제 렌더 확인 결과: 미연결

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 선택 alpha 원본 시각 확인 | PASS | 연속 표면, 저채도, seam·금빛·장애물 없음 |
| 2 | image mode·size | PASS | `1254×1254`, RGBA |
| 3 | corner alpha 4곳 | PASS | 모두 `0` |
| 4 | greenish alpha pixel 검사 | PASS | `0` |
| 5 | alpha pixel 분류 | PASS | transparent 1,107,075 / partial 3,004 / opaque 462,437 |
| 6 | exact guide canvas 점유율 | DEFERRED | 전체 공간 자산 승인 뒤 native slicing 단계에서 fit |
| 7 | 런타임 관련 테스트 | NOT_REQUIRED | 런타임 미변경 |
| 8 | 전체 회귀·플레이 검수 | NOT_REQUESTED | 사용자 요청 전 보류 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 사용자 복도 표면 시각 승인 전이다.
- 현재 후보의 slab 크기가 방 바닥과 충분히 구분되는지는 전체 contact sheet에서 다시 확인해야 한다.
- alpha bbox는 guide bbox보다 크므로 runtime에 직접 연결할 수 없다.
- 반복 배치 시 눈에 띄는 패턴과 직선·코너·교차 파생 정합은 exact slicing·runtime 단계에서 별도 확인해야 한다.

## 8. 다음 작업 순서

1. 사용자가 복도 표면의 저채도, slab 크기, 방 바닥 대비를 승인 또는 수정 지시한다.
2. 승인되면 같은 투영·광원 기준으로 공통 폐색 그림자 한 종을 제작한다.
3. 폐색 그림자 승인 뒤 암벽·보라 안개 가장자리 마스크 한 종을 제작한다.
4. 전체 Stage 01 공간 자산 승인 뒤 exact contact sheet·native slicing·runtime lookup을 적용한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 HEAD: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 이번 단계 source PNG·문서가 미커밋 상태다.
- 기존 대규모 코드·데이터·`.import` 변경은 보존했다.
- 빌드·커밋·푸시하지 않았다.

## 10. 종료 체크리스트

- [x] imagegen 스킬 사용
- [x] exact footprint·승인된 W corridor material reference 분리
- [x] 저채도 2셀 복도 표면 원본 생성
- [x] 과밀 slab 중간 후보 분리
- [x] slab 밀도 교정
- [x] alpha 제거·검증
- [x] 생성 출처·프롬프트 기록
- [x] exact slicing 유보 상태 기록
- [x] 런타임 미연결
- [x] 전체 회귀·플레이 검수 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 사용자 복도 표면 시각 승인
- [ ] 공통 폐색 그림자 생성
- [ ] runtime 연결
- [ ] 커밋·푸시
