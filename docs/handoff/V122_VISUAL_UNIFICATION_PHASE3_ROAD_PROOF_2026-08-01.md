# v1.2.2 그래픽 통일 Phase 3 도로 시안 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-01
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: 문서·시안 미커밋
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 단계 목표

- 기존 격자형 복도 표면을 도로로 읽히는 불규칙 석판 도로 시안으로 교체할 후보를 만든다.
- 같은 2×2 이소메트릭 투영을 유지해 기존 문턱·방과 연결할 수 있게 한다.
- 사용자 승인 전에는 runtime manifest, 타일 분할, renderer를 변경하지 않는다.

## 3. 완료한 작업

- 기존 후보 `corridor_surface_2cell_selected_alpha_preview.png`를 편집 기준으로 사용했다.
- 규칙적인 작은 사각 타일 반복을 제거했다.
- 길의 긴 축을 따라 읽히는 큰 불규칙 석판과 낡은 균열을 적용했다.
- 금색 경로선, UI, 벽, 문, 계단, 소품은 넣지 않았다.
- 생성 결과가 검정 배경으로 반환되어 검정 가장자리를 alpha로 분리한 승인용 미리보기를 만들었다.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/road_surface_2cell_generated_raw_black.png` | GPT 생성 원본 | 시안 |
| `assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/road_surface_2cell_alpha_preview.png` | 검정 배경 제거 alpha 후보 | 시안 |
| `assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/SOURCE.md` | 생성 출처·프롬프트·후처리 기록 | 완료 |
| `docs/handoff/V122_VISUAL_UNIFICATION_PHASE3_ROAD_PROOF_2026-08-01.md` | Phase 3 핸드오프 | 완료 |
| `assets/tiles/stage_01/spatial/*corridor*` | 기존 런타임 도로 | 변경하지 않음 |
| `data/dungeon_quarter/asset_manifest.json` | 기존 lookup | 변경하지 않음 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/road_surface_2cell_generated_raw_black.png`
- `SOURCE.md` 경로: `assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/SOURCE.md`
- 런타임 최종 자산 경로: 없음 — 승인 후 exact slicing 예정
- 후처리: 검정 배경을 `remove_chroma_key.py --auto-key border --soft-matte --despill`로 alpha 분리
- 게임 연결 및 실제 렌더 확인 결과: 아직 연결하지 않음

## 6. 테스트 및 검수

| 순서 | 검수 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 생성 원본 시각 확인 | PASS | 큰 불규칙 석판, 길 방향, 저채도 확인 |
| 2 | alpha 후보 시각 확인 | PASS | 외부 배경 분리 후보 생성 |
| 3 | exact 256×128 fit/slicing | DEFERRED | 사용자 시각 승인 전 유보 |
| 4 | 런타임 공간 테스트 | PASS | 기존 자산·manifest를 변경하지 않아 기존 테스트 유지 |
| 5 | 전체 회귀·플레이 검수 | NOT_REQUESTED | 현재 요청 범위 아님 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 승인 요청

- 이 후보를 `assets/tiles/stage_01/spatial/`에 연결하지 않았다.
- 256×128로 축소했을 때 석판 경계가 충분히 읽히는지 확인해야 한다.
- 직선·코너·교차 파생 시 반복 패턴이 생기지 않는지 확인해야 한다.
- 사용자 승인 전에는 기존 도로 디자인이 유지된다.

## 8. 다음 작업 순서

1. 사용자 시각 승인 또는 수정 지시를 받는다.
2. 승인되면 exact 256×128 패치와 128×64 parity 셀 4종을 결정적으로 생성한다.
3. 도로 1차 런타임 연결 후 Stage 01 공간 테스트와 1280×720 대표 화면을 다시 확인한다.

## 9. 작업 트리 상태

- 미커밋 파일: Phase 0~3 핸드오프, Phase 2 테스트, 도로 시안 source·SOURCE.md, 1280 baseline review 도구
- 기존 런타임 도로·manifest·renderer: 변경 없음
- 빌드·푸시: 하지 않음
