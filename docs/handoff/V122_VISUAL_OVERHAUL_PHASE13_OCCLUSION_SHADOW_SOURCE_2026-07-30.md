# v1.2.2 시각 개편 13단계 Stage 01 공통 폐색 그림자 생성 원본 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 사용자가 직접 선택해야 하는 상황 전까지 정해진 순서를 계속 진행한다.
- 해석: 복도 표면을 승인하고 공통 폐색 그림자 제작을 계속한다.
- 완료 조건:
  - 방·복도·문턱에 공통 적용 가능한 shadow-only 원본 한 종을 만든다.
  - 좌상단 광원과 반대인 하단 두 변에만 얇은 폐색을 둔다.
  - 중앙 보행면과 상단 변을 비워 캐릭터·바닥을 가리지 않는다.
  - 초록 key를 alpha로 제거하고 출처·프롬프트를 기록한다.
- 범위 제외: 가장자리 마스크, exact slicing, runtime manifest/renderer, 화면·플레이·전체 QA, 빌드·커밋·푸시.

## 3. 완료한 작업

- `imagegen` 스킬과 GPT 내부 이미지 생성 경로를 사용했다.
- 승인된 복도 표면을 projection·canvas 기준, exact guide를 footprint 기준으로 사용했다.
- 첫 후보에서 하단 두 변만 따라가는 V형 폐색과 우하단의 약간 깊은 음영을 확보했다.
- 중앙·상단·외부를 비우고 floor·stone·wall·decal 없는 shadow-only 자산으로 분리했다.
- flat chroma key를 공식 helper로 제거하고 alpha source를 만들었다.
- 런타임 자산과 manifest는 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/common_occlusion_shadow_2cell_selected_raw_chroma.png` | 선택한 GPT 생성 원본 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/common_occlusion_shadow_2cell_selected_alpha_preview.png` | alpha 후보 | 완료 |
| `assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/SOURCE.md` | 모델·프롬프트·후처리 기록 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE13_OCCLUSION_SHADOW_SOURCE_2026-07-30.md` | 이번 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본:
  - `assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/common_occlusion_shadow_2cell_selected_raw_chroma.png`
- `SOURCE.md`:
  - `assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/SOURCE.md`
- 런타임 최종 자산: 없음
- alpha 후보:
  - `assets/source/imagegen/v122_stage01_spatial/common_occlusion_shadow_2cell/common_occlusion_shadow_2cell_selected_alpha_preview.png`

## 6. 테스트 및 검수

| 순서 | 검수 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | alpha 원본 시각 확인 | PASS | 하단 두 변만 음영, 중앙·상단 비움 |
| 2 | image mode·size | PASS | `1254×1254`, RGBA |
| 3 | corner alpha 4곳 | PASS | 모두 `0` |
| 4 | greenish alpha pixel 검사 | PASS | `0` |
| 5 | alpha pixel 분류 | PASS | transparent 1,490,541 / partial 64,885 / opaque 17,090 |
| 6 | exact fit | DEFERRED | 전체 source 완성 뒤 native slicing |
| 7 | 런타임 테스트 | NOT_REQUIRED | 런타임 미변경 |
| 8 | 전체 회귀·플레이 검수 | NOT_REQUESTED | 사용자 요청 전 보류 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- source canvas와 exact guide의 점유율이 달라 native slicing이 필요하다.
- shadow overlay가 black background에서는 거의 보이지 않으므로 실제 바닥 위 합성 강도는 runtime 단계에서 확인해야 한다.
- 반복 적용 시 하단 꼭짓점이 과도하게 어두워지지 않도록 중복 합성을 막아야 한다.

## 8. 다음 작업 순서

1. 암벽·보라 안개 불규칙 가장자리 마스크 한 종을 제작한다.
2. 전체 Stage 01 공간 source를 exact contact sheet로 정합한다.
3. 승인 자산을 runtime lookup에 연결하고 직접 영향 테스트를 수행한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 HEAD: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 이번 단계 source PNG·문서가 미커밋 상태다.
- 기존 대규모 코드·데이터·`.import` 변경은 보존했다.
- 빌드·커밋·푸시하지 않았다.

## 10. 종료 체크리스트

- [x] imagegen 스킬 사용
- [x] 공통 폐색 그림자 원본 생성
- [x] 하단 두 변·좌상단 광원 계약
- [x] 중앙·상단 비움
- [x] alpha 제거·검증
- [x] 생성 출처·프롬프트 기록
- [x] 런타임 미연결
- [x] 전체 회귀·플레이 검수 미실행 기록
- [ ] 가장자리 마스크 생성
- [ ] exact slicing
- [ ] runtime 연결
- [ ] 커밋·푸시
