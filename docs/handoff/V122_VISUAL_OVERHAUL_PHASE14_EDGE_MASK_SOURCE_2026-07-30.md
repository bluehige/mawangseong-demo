# v1.2.2 시각 개편 14단계 Stage 01 암벽 가장자리 마스크 생성 원본 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 직접 선택이 필요한 상황 전까지 순차 작업을 계속한다.
- 완료 조건:
  - 1920 full-canvas와 1366/1280 compact에 공통 사용 가능한 9-slice 암벽 frame을 만든다.
  - 중앙 작업면은 비우고 외곽 검정을 Stage 01 암벽으로 연결한다.
  - 하단 명령 rail과 경쟁하지 않게 bottom middle을 얇게 한다.
  - chroma 혼색 안개를 제거하고 암벽 표면의 저채도 보라 반사만 유지한다.
  - alpha와 프롬프트를 기록한다.
- 범위 제외: exact optimization, runtime manifest/renderer, 화면·플레이·전체 QA, 빌드·커밋·푸시.

## 3. 완료한 작업

- `imagegen` 스킬과 GPT 내부 이미지 생성 경로를 사용했다.
- Stage 01 cave background를 재질 기준, 비교 보드를 full-canvas·compact 맥락 기준으로 사용했다.
- 첫 후보의 두꺼운 하단과 높은 보라 휘도를 낮추고 edge middle strip을 단순화했다.
- chroma key와 섞여 청록회색으로 남는 안개 protrusion은 제거하고 암벽 표면의 보라 반사만 유지했다.
- 암벽이 border 전체에 닿아 auto-key가 검정을 고르는 문제를 발견하고 `#00ff00` 명시 key로 교정했다.
- 중앙은 runtime `draw_center=false`로 제외하고 code-native 저채도 보라 feather를 암벽 뒤에 두는 계약을 고정했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v122_stage01_spatial/cavern_edge_mask_9slice/*intermediate*` | 두께·key 혼색·안개 중간 후보 | 보존 |
| `assets/source/imagegen/v122_stage01_spatial/cavern_edge_mask_9slice/cavern_edge_mask_9slice_selected_raw_chroma.png` | 선택한 GPT 생성 원본 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/cavern_edge_mask_9slice/cavern_edge_mask_9slice_selected_alpha_preview.png` | alpha 후보 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/cavern_edge_mask_9slice/SOURCE.md` | 모델·프롬프트·후처리·9-slice 계약 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE14_EDGE_MASK_SOURCE_2026-07-30.md` | 이번 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점 갱신 | 완료 |

## 5. 그래픽 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본:
  - `assets/source/imagegen/v122_stage01_spatial/cavern_edge_mask_9slice/cavern_edge_mask_9slice_selected_raw_chroma.png`
- alpha 후보:
  - `assets/source/imagegen/v122_stage01_spatial/cavern_edge_mask_9slice/cavern_edge_mask_9slice_selected_alpha_preview.png`
- 런타임 최종 자산: 없음

## 6. 테스트 및 검수

| 순서 | 검수 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | alpha 원본 시각 확인 | PASS | 중앙 개방, 얇은 하단, 9-slice middle strip |
| 2 | image mode·size | PASS | `1254×1254`, RGBA |
| 3 | center 처리 계약 | PASS | runtime `draw_center=false` |
| 4 | greenish alpha pixel 검사 | PASS | `0` |
| 5 | alpha pixel 분류 | PASS | transparent 1,254,028 / partial 12,200 / opaque 306,288 |
| 6 | exact optimization | DEFERRED | runtime 연결 단계 |
| 7 | 런타임 테스트 | NOT_REQUIRED | 런타임 미변경 |
| 8 | 전체 회귀·플레이 검수 | NOT_REQUESTED | 사용자 요청 전 보류 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- runtime 9-slice margin과 보라 feather 강도는 실제 renderer 크기에 맞춰 고정해야 한다.
- 암벽 frame은 world보다 앞, HUD보다 뒤에 있어야 하며 입력을 차단하면 안 된다.
- compact에서 corner가 세계 영역을 과도하게 좁히지 않는지 직접 확인해야 한다.

## 8. 다음 작업 순서

1. 전체 Stage 01 공간 source를 exact runtime size로 slicing·최적화한다.
2. asset manifest와 QuarterDungeonRenderer에 역할 기반 lookup을 연결한다.
3. 1920·1280 직접 영향 테스트와 path/walk 일치 검사를 수행한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 HEAD: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 이번 단계 source PNG·문서가 미커밋 상태다.
- 기존 대규모 코드·데이터·`.import` 변경은 보존했다.
- 빌드·커밋·푸시하지 않았다.

## 10. 종료 체크리스트

- [x] imagegen 스킬 사용
- [x] 9-slice 암벽 frame 생성
- [x] 하단·측면 두께 교정
- [x] chroma 안개 혼색 제거
- [x] 명시 key alpha 제거·검증
- [x] 생성 출처·프롬프트 기록
- [x] 전체 회귀·플레이 검수 미실행 기록
- [ ] exact optimization
- [ ] runtime 연결
- [ ] 1920·1280 확인
- [ ] 커밋·푸시
