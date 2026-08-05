# V1.2.2 그래픽 통일 Phase 10~13 — Stage 01 텍스처 필터·해상도 일관성

## 1. 메타데이터

- 작성일: 2026-08-01
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: `f9a912b8217f58b1e023dae4739cf37bc307d49b` (이번 변경은 미커밋)
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 도로·통로 교체 뒤에도 남아 있던 자글자글한 타일과 고해상도 방 소품의 표시 밀도를 Stage 01 실제 화면에서 통일한다.
- 완료 조건: Stage 01 월드의 배경·타일·벽·문턱·도로·통로·방 소품이 같은 선형 밉맵 필터를 사용하고, 1280×720 DAY 3 화면 및 관련 자동 검사를 통과한다.
- 범위에서 제외한 사항: HUD와 메뉴 UI의 전역 기본 필터, Stage 02 이후의 미술 교체, 전체 회귀·전체 플레이·Windows/Web 빌드.

## 3. 완료한 작업

- 구현: `GameRoot` 아래 월드 렌더링에만 선형 밉맵 필터를 지정했다. 밉맵은 원본을 여러 축소 크기로 미리 만든 텍스처 단계라, 고해상도 소품과 작은 타일이 함께 축소될 때 계단·깜빡임을 줄인다.
- 구현: 동굴 배경판과 `CanvasLayer`에 있는 가장자리 마스크도 같은 필터를 명시해 별도 캔버스에서만 다시 거칠어지는 문제를 막았다.
- 그래픽: `cave_v2` 80개, Stage 01 공간 자산 13개, Stage 01 방 소품 7개, 배경·가장자리 마스크 2개, 총 102개 월드 텍스처 import의 `mipmaps/generate`를 켰고 Godot 재임포트를 완료했다.
- 그래픽 감사: 실제 Stage 01 방 소품(입구·왕좌·보물·무기 거치대·회복 둥지·건설 표시)은 모두 동일한 어두운 석재·금속·보라 동굴 팔레트와 아이소메트릭 투영을 이미 사용한다. 이번 화면 이질감의 직접 원인은 새 그림체 교체가 아니라 최근접 축소 샘플링이었으므로, 정상 자산을 불필요하게 다시 생성하지 않았다.
- UI/UX: 프로젝트의 전역 기본 필터값 `0`은 유지했다. HUD는 별도 `CanvasLayer`이므로 기존 선명도를 보존한다.
- 저장 및 호환성: 저장 데이터, 전투 규칙, 맵 연결 데이터는 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | Stage 01 월드·배경·가장자리 마스크의 선형 밉맵 필터 | 완료 |
| `assets/tiles/cave_v2/**/*.png.import` | 바닥·벽·모서리·문 80개 밉맵 생성 | 완료 |
| `assets/tiles/stage_01/**/*.png.import` | 문턱·도로·일반 통로·DAY 3 접속석 밉맵 생성 | 완료 |
| `assets/props/stage_01/*.png.import` | Stage 01 방 소품 7개 밉맵 생성 | 완료 |
| `assets/backgrounds/v2/bg_cave_f_3x3_01.png.import` | 동굴 배경 밉맵 생성 | 완료 |
| `assets/ui/stage_01/cavern_edge_mask_stage01_9slice.png.import` | 동굴 가장자리 마스크 밉맵 생성 | 완료 |
| `tools/tests/V122VisualTextureConsistencyTest.gd` | 실제 import 밉맵과 월드 전용 필터 계약 검사 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 Phase에서는 새 이미지 생성 없음. 앞 Phase에서 생성한 도로·접속석 원본을 그대로 사용했다.
- 생성 모델: 기존 신규 자산은 `GPT internal image generation`.
- 생성 원본 경로: `assets/source/imagegen/v122_stage01_spatial/road_autotile_v2/`, `assets/source/imagegen/v122_stage01_spatial/defender_connector_junction_v1/`
- `SOURCE.md` 경로: 위 각 원본 폴더의 `SOURCE.md`
- 런타임 최종 자산 경로: `assets/tiles/stage_01/spatial_road_autotile_v2/`, `assets/tiles/stage_01/spatial_passage_v1/`
- 프롬프트/후처리/크롭/알파 처리 요약: 새 생성·크롭·알파 처리는 없었다. 기존 런타임 PNG와 Stage 01 월드 자산을 밉맵 포함 텍스처로 재임포트했다.
- 게임 연결 및 실제 렌더 확인 결과: DAY 3 관리 화면에서 연결 mask 기반 바닥, 연속 석벽, 방어자 지름길 접속석과 방 소품이 같은 축소 필터로 렌더됨을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122VisualTextureConsistencyTest.tscn` | PASS | 102개 import 설정 및 대표 7개 실제 밉맵 존재 검사 |
| 2 | `V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | 도로 16방향 mask·문턱·통로·접속석 런타임 계약 |
| 3 | `V122DefenderConnectorTest.tscn` | PASS | DAY 3 방어자 지름길 동작 계약 |
| 4 | `V122RoadAutotileCapture.tscn` (1280×720) | PASS | `tmp/v122_road_autotile_review/stage_01_day03_connector_built_1280x720.png` |
| 5 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 밖 |
| 6 | 전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 밖 |

- 남은 P1/P2 지적: 없음.
- 실행하지 못한 필수 검수와 이유: 없음. 전체 회귀와 전체 플레이는 현재 요청에 없어서 실행하지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: 0
- Final review result: TARGETED_PASS

Related tests: `V122VisualTextureConsistencyTest`, `V122Stage01SpatialVisualRuntimeTest`, `V122DefenderConnectorTest`, `V122RoadAutotileCapture` — 모두 PASS
UI check: 실제 Stage 01 DAY 3 관리 화면 1280×720에서 월드 타일·방 소품·도로·통로의 축소 표시와 UI 선명도를 확인함
Unresolved issues: Stage 01 범위의 필터·해상도 불일치는 해결됨. 다른 스테이지의 개별 그림체 교체는 별도 사용자 요청이 있을 때 자산별로 진행함

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 밉맵은 텍스처 메모리를 추가로 사용한다. 적용 범위는 현재 화면에 실제로 함께 표시되는 Stage 01 월드 자산으로 제한했다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 없음. 도로 바닥은 GPT 생성 최종 자산을 사용하고, 통로 벽은 기존 Stage 01 석벽 bitmap을 재사용한다.
- 외부 환경/도구 제약: 캡처는 OpenGL 호환 렌더러에서 실행했다. headless 화면 캡처는 프레임 대기 문제 때문에 사용하지 않았다.

## 8. 다음 작업 순서

1. 사용자 화면 검토에서 특정 자산이 여전히 그림체와 맞지 않는다고 지적되면 해당 자산만 `assets/source/imagegen/` 원본과 함께 새로 생성하고 manifest 연결을 교체한다. 완료 조건은 지적 자산의 실제 Stage 화면 확인이다.
2. 사용자 요청이 있을 때만 다른 스테이지에도 동일한 월드 필터·밉맵 원칙을 적용한다. 완료 조건은 해당 스테이지 1280×720 대표 화면 확인이다.
3. 사용자가 빌드·커밋·푸시를 요청하면 이 변경만 명시적으로 스테이징하고 태그 기준 빌드 절차를 진행한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 기존 도로·통로 변경과 이번 필터 변경이 모두 미커밋 상태이며, 브랜치는 원격보다 커밋 1개 앞서 있다.
- 미커밋 파일: 도로·통로 생성 원본/런타임 자산·도구·테스트·문서, renderer, manifest, 그리고 이번 Stage 01 월드 텍스처 import 102개.
- 의도하지 않은 기존 변경: `assets/sprites/enemies/update4/region/*.png.import` 등 기존 작업 트리 변경은 건드리지 않았다.
- 스태시 또는 별도 작업공간: 사용하지 않음.
- 빌드/캡처 산출물 위치: `tmp/v122_road_autotile_review/`이며 커밋 대상이 아니다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [ ] 요청받은 경우에만 전체 회귀·검수 에이전트 완료 (요청 없음)
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋 (요청 없음)
- [ ] 원격 푸시 및 PR/태그 상태 기록 (요청 없음)
