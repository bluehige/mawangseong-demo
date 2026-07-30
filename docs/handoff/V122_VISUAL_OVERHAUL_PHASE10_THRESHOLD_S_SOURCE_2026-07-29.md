# v1.2.2 시각 개편 10단계 Stage 01 S 문턱 생성 원본 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: E 문턱 다음 작업을 진행한다.
- 해석: `다음거 진행해`를 E 문턱 시각 방향 승인과 S 문턱 순차 제작 승인으로 기록했다.
- 완료 조건:
  - S 방향 2셀 문턱 생성 원본 한 종을 만든다.
  - 승인된 N/E 문턱 재질 family와 S exact guide의 passage 방향을 함께 사용한다.
  - N과 같은 seam 사선을 유지하되 room·corridor 표면 측을 반대로 배치한다.
  - 초록 key를 alpha로 제거하고 출처·프롬프트를 기록한다.
  - 사용자 승인 전 런타임에 연결하지 않는다.
- 범위 제외: W 문턱, 복도 표면, native slicing, runtime manifest/renderer, 화면·플레이·전체 QA, 빌드·커밋·푸시.

## 3. 완료한 작업

- `imagegen` 스킬과 GPT 내부 이미지 생성 경로를 사용했다.
- exact S guide를 geometry 기준, N/E 문턱을 재질 family 기준으로 분리했다.
- 첫 후보에서 좌상단→우하단 seam과 screen lower-left passage를 확보했다.
- upper-right에는 대형 정돈 slab, lower-left에는 소형 거친 slab을 배치해 N과 surface side를 반대로 만들었다.
- 첫 후보 중앙 목재의 녹갈색 얼룩을 발견해 중간 후보로 보존했다.
- 두 번째 precise edit에서 geometry를 유지하고 얼룩만 적갈 목재로 교정해 선택했다.
- flat chroma key를 공식 helper로 제거하고 alpha 승인 후보를 만들었다.
- 생성 결과의 canvas 점유율은 exact guide보다 커 native slicing 단계로 유보했다.
- 런타임 자산과 manifest는 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/threshold_s_2cell_intermediate_green_stain_raw.png` | 얼룩이 남은 첫 후보와 보정 근거 | 보존 |
| `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/threshold_s_2cell_intermediate_green_stain_alpha.png` | 첫 후보 alpha 확인본 | 보존 |
| `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/threshold_s_2cell_selected_raw_chroma.png` | 선택한 GPT 생성 원본 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/threshold_s_2cell_selected_alpha_preview.png` | 사용자 승인용 alpha 후보 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/SOURCE.md` | 모델·날짜·프롬프트·후처리·정합 유보 기록 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE10_THRESHOLD_S_SOURCE_2026-07-29.md` | 이번 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본 경로:
  - `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/threshold_s_2cell_selected_raw_chroma.png`
- `SOURCE.md` 경로:
  - `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/SOURCE.md`
- 런타임 최종 자산 경로: 없음
- alpha 승인 후보:
  - `assets/source/imagegen/v122_stage01_spatial/threshold_s_2cell/threshold_s_2cell_selected_alpha_preview.png`
- 게임 연결 및 실제 렌더 확인 결과: 미연결

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 선택 alpha 원본 시각 확인 | PASS | seam 좌상단→우하단, lower-left passage, 녹갈 얼룩 제거 |
| 2 | image mode·size | PASS | `1254×1254`, RGBA |
| 3 | corner alpha 4곳 | PASS | 모두 `0` |
| 4 | greenish opaque pixel 검사 | PASS | `0` |
| 5 | alpha pixel 분류 | PASS | transparent 1,098,954 / partial 3,018 / opaque 470,544 |
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

- 사용자 S 문턱 시각 승인 전이다.
- alpha bbox는 guide bbox보다 크므로 runtime에 직접 연결할 수 없다.
- native `256×128` 축소에서 slab 구분과 목재 seam이 뭉개질 수 있어 contact sheet에서 확인해야 한다.
- S는 `front` 레이어이며 실제 unit·room 합성 순서는 runtime 연결 단계에서 별도 확인해야 한다.

## 8. 다음 작업 순서

1. 사용자가 S 문턱의 seam 방향, 표면 반전, 통행 가독성을 승인 또는 수정 지시한다.
2. 승인되면 같은 기준으로 W 방향 2셀 문턱 하나를 생성한다.
3. 네 문턱 승인 뒤 저채도 복도 표면과 공통 폐색 그림자를 제작한다.
4. 전체 Stage 01 공간 자산 승인 뒤 exact slicing과 runtime lookup을 적용한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 HEAD: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 이번 단계 source PNG·문서가 미커밋 상태다.
- 기존 대규모 코드·데이터·`.import` 변경은 보존했다.
- 빌드·커밋·푸시하지 않았다.

## 10. 종료 체크리스트

- [x] imagegen 스킬 사용
- [x] exact S guide·승인된 N/E 문턱 reference 분리
- [x] S 문턱 원본 생성
- [x] N과 반대 surface side 배치
- [x] 녹갈색 얼룩 제거
- [x] alpha 제거·검증
- [x] 생성 출처·프롬프트 기록
- [x] exact slicing 유보 상태 기록
- [x] 런타임 미연결
- [x] 전체 회귀·플레이 검수 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 사용자 S 문턱 시각 승인
- [ ] W 문턱 생성
- [ ] runtime 연결
- [ ] 커밋·푸시
