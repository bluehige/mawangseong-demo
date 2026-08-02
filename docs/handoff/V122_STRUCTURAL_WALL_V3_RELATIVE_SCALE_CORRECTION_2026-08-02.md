# V1.2.2 구조 벽 V3 상대 비율 보정 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-02
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: 작업 시작 기준 `codex/v122-ui-simplification@f9a912b8217f58b1e023dae4739cf37bc307d49b`, 제품 기준 `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 직전 기준 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 완료 커밋: 이 문서와 구현을 같은 체크포인트 커밋으로 묶는다. 정확한 완료 SHA는 해당 커밋의 `git log` 기록을 기준으로 한다.
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 승인 기준 이미지와 현재 맵의 비례를 다시 비교해, 낮고 얇은 구조 벽을 절대 화면 픽셀이 아닌 맵 한 칸 대비 상대 크기로 수정한다.
- 완료 조건: 높은 4단 회흑색 벽, 빈 연결 통로, 연속된 외곽 벽, 낮은 전면 가림을 Stage 01~04와 사용자 맵 공용 구조로 적용하고 실제 `1280×720` 화면을 확인한다.
- 범위에서 제외한 사항: 전체 회귀, 전체 플레이, 출시 빌드, 푸시.

## 3. 완료한 작업

- 구현:
  - 논리 셀의 사선 모서리 길이를 `E`로 정의하고 벽 표시 크기를 `E` 비율로 계산하도록 V3 프로필을 추가했다.
  - 실제 직선벽 측정값을 길이 `1.13975E`, 중심 단면 높이 `1.60347E`, 전면 가림 깊이 `0.45662E`로 맞췄다.
  - 전체 벽 몸체는 유닛 뒤에 한 번만 그리고, 남·동쪽 벽의 낮은 `front_occluder`만 유닛 앞에 그리도록 렌더 계층을 분리했다.
  - 앞가림 자산이 없을 때 높은 벽 전체를 앞에 대신 그리는 처리를 제거했다.
  - 긴 팔을 가진 모서리·끝·T분기 원본을 직선벽 위에 중복 합성하지 않고 `vertex_render_policy=edge_overlap`으로 접합한다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음.
- UI/UX: 낮은 2단 난간처럼 보이던 벽을 높은 4단 구조 벽으로 교체했고 보라색 대신 저채도 회흑색으로 통일했다.
- 저장 및 호환성: 저장 형식 변경 없음. Stage 01~04와 사용자 맵이 같은 활성 세트 `cave_v2_boundary_v3`를 사용한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v122_structural_wall_kit_v3/` | GPT 생성 원본, 알파 원본, 출처와 후처리 기록 | 완료 |
| `assets/tiles/cave_v2/structural_walls_v3/` | 직선·방향별 정점·전면 가림 런타임 PNG | 완료 |
| `tools/prepare_v122_structural_wall_kit_v3.py` | V3 크롭·정규화·전면 가림 생성 | 완료 |
| `data/dungeon_quarter/wall_asset_catalog.json` | schema 3 상대 비율, V3 자산과 접합 정책 | 완료 |
| `data/dungeon_quarter/asset_manifest.json` | 활성 구조 벽 세트를 V3로 전환 | 완료 |
| `scripts/dungeon_quarter/WallAssetCatalog.gd` | 상대 비율·출처·전면 가림·접합 정책 검증 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 전체 몸체/낮은 앞가림 레이어 분리와 V3 배율 적용 | 완료 |
| `tools/tests/V122WallAssetCatalogTest.gd` | V3 catalog 회귀 검사 | 완료 |
| `tools/tests/V122StructuralWallPixelContractTest.gd` | 실제 PNG 비율·알파·회흑색·방향 검사 | 완료 |
| `tools/tests/V122CorridorWallTopologyTest.gd` | 실제 런타임 E 비율과 벽 배치 검사 | 완료 |
| `tools/tests/V122CorridorTopologyLayoutMatrixTest.gd` | Stage 01~04·사용자 맵 공용 V3 검사 | 완료 |
| `tools/QuarterModuleSmokeTest.gd` | 활성 벽 세트 기대값을 V3로 갱신 | 벽 관련 항목 완료, 범위 밖 기존 실패 있음 |
| `docs/design/v122/V122_STRUCTURAL_WALL_RESOURCE_CONTRACT_V3_2026-08-02.md` | 상대 비율과 자산 사용 규칙 고정 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/v122_structural_wall_kit_v3/`
- `SOURCE.md` 경로: `assets/source/imagegen/v122_structural_wall_kit_v3/SOURCE.md`
- 런타임 최종 자산 경로: `assets/tiles/cave_v2/structural_walls_v3/`
- 프롬프트/후처리/크롭/알파 처리 요약: 2:1 아이소메트릭 4단 회흑색 석벽을 방향별로 생성하고, 녹색 크로마를 알파로 제거한 뒤 직선 connector를 `96×48` 사선으로 정규화했다. 남·동쪽 자산은 바닥 접점 부근만 별도 앞가림 PNG로 분리했다.
- 게임 연결 및 실제 렌더 확인 결과: `cave_v2_boundary_v3` 활성화 후 Stage 01~04 및 custom 캡처가 생성됐고, 대표 Stage 01 `1280×720` 렌더를 육안 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `godot.cmd --headless --path . res://tools/tests/V122WallAssetCatalogTest.tscn` | PASS | 콘솔 `V122_WALL_ASSET_CATALOG_TEST: PASS` |
| 2 | `godot.cmd --headless --path . res://tools/tests/V122StructuralWallPixelContractTest.tscn` | PASS, 285 assertions | 콘솔 `V122_STRUCTURAL_WALL_PIXEL_CONTRACT_TEST: PASS` |
| 3 | `godot.cmd --headless --path . res://tools/tests/V122CorridorWallTopologyTest.tscn` | PASS | 콘솔 상대 비율 실측 및 `V122_CORRIDOR_WALL_TOPOLOGY_TEST: PASS` |
| 4 | `godot.cmd --headless --path . res://tools/tests/V122CorridorTopologyLayoutMatrixTest.tscn` | PASS | 콘솔 `V122_CORRIDOR_TOPOLOGY_LAYOUT_MATRIX_TEST: PASS` |
| 5 | `godot.cmd --path . --rendering-method gl_compatibility res://tools/V122StructuralWallCapture.tscn` | PASS | `tmp/v122_structural_wall_review/` |
| 6 | `godot.cmd --headless --path . res://tools/QuarterModuleSmokeTest.tscn` | 범위 밖 기존 항목 FAIL | 벽 관련 V3 항목은 모두 PASS했으나 `front-view generated room sprite is rejected without iso projection metadata`에서 실패 |
| 7 | `godot.cmd --headless --path . res://tools/tests/V122VisualTextureConsistencyTest.tscn` | PASS | V2·V3 구조 벽을 포함한 Stage 01 월드 텍스처의 축소 표시용 밉맵 생성 확인 |
| 8 | `godot.cmd --headless --path . res://tools/tests/V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | Stage 01 공간 자산 런타임 연결 확인 |
| 9 | 전체 회귀·전체 플레이 | NOT_REQUESTED | 실행하지 않음 |

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

Related tests: 구조 벽 catalog, PNG 비율, 텍스처 축소 표시, 실제 런타임 벽 토폴로지, Stage 01 공간 자산, Stage 01~04·custom 레이아웃 테스트 PASS. 전체 Quarter smoke는 벽과 무관한 기존 room sprite metadata 항목에서 FAIL.
UI check: `1280×720` Stage 01 실제 GPU 렌더 PASS. 캡처 `tmp/v122_structural_wall_review/stage_01_cave_map_crop.png`.
Unresolved issues: 긴 팔이 포함된 방향별 정점 원본은 접합부 전용으로 다시 국소화하기 전까지 런타임 중복 합성을 금지하고 edge overlap을 사용한다. 전체 회귀·출시 빌드·푸시는 수행하지 않았다.

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 상판과 수직면은 한 PNG 안에 있어 각각의 알파 경계를 자동 분리 측정하지 못한다. 대신 중심 전체 높이, 4단 석재, 실제 화면을 함께 검사한다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 방향별 정점 자산은 분류·보존하지만 현재는 긴 팔의 중복을 피하기 위해 화면에 덧그리지 않는다.
- 외부 환경/도구 제약: 없음.

## 8. 다음 작업 순서

1. 사용자가 현재 실제 화면을 확인하고 벽의 체감 높이와 두께를 승인한다.
2. 접합부의 형태를 더 세밀하게 만들 필요가 있으면 한 칸 팔이 없는 국소 corner/cap/T patch를 별도 생성한다.
3. 정식 출시 마무리 계획에서는 캐릭터 접지, 전투 타격감, BGM·효과음 상태를 우선 감사하고 사용자와 기준을 확정한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`, 원격보다 1커밋 앞섬, 기존 변경과 이번 V3 변경이 함께 있는 혼합 작업 트리.
- 체크포인트 포함 파일: 도로·통로·구조 벽 V1~V3 원본과 런타임 자산, 데이터·코드·관련 테스트·문서만 명시적으로 스테이징했다.
- 체크포인트 제외 파일: Update 4 적 스프라이트 `.import` 6개와 이 작업과 무관하게 생성된 `.uid` 7개는 사용자 작업으로 보존했다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 빌드 없음. 캡처는 기존 검수 폴더 `tmp/v122_structural_wall_review/`에만 생성.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·전체 플레이는 실행하지 않음
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 명시적으로 스테이징하고 체크포인트 커밋 범위 확정
- [ ] 원격 푸시 및 PR/태그 상태 기록
