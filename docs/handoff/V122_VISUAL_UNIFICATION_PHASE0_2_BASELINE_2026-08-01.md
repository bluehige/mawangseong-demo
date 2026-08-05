# v1.2.2 그래픽 통일 Phase 0~2 기준선·기술 시험 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-01
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: 현재 브랜치 기준 `f9a912b8217f58b1e023dae4739cf37bc307d49b`
- 마지막 커밋 SHA: 문서 작성 시점 미커밋
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 테스트 피드백의 자글거림, 도로 타일, 코드 도형 통로 문제를 페이즈별로 수정하기 위한 실제 런타임 기준을 고정한다.
- 완료 조건:
  - 실제 화면에 사용되는 그래픽 파일과 렌더러 연결 지점을 목록화한다.
  - 공통 아트 기준과 자산 규격을 고정한다.
  - 자글거림이 해상도·필터 문제인지 그림 자체의 질감 문제인지 대표 자산으로 분리한다.
- 범위에서 제외한 사항: 신규 도로·통로 원화 생성, 전체 캐릭터 교체, 전체 회귀 검수, 최종 빌드.

## 3. 완료한 작업

### Phase 0 — 런타임 그래픽 전수표

- Stage 01 환경은 `data/dungeon_quarter/asset_manifest.json`의 `stage_spatial_visuals.stage_01_cave`에서 복도 셀 4종, 문턱 4종, 폐색 그림자, 외곽 마스크를 읽는다.
- 바닥 타일은 `data/dungeon_quarter/tile_variant_manifest.json`의 `cave_v2` 128×64 규격과 16개 mask를 사용한다.
- 방·시설 랜드마크는 `assets/props/stage_01/`의 방향별 이미지와 `assets/ui/room_v2/`의 모듈 이미지를 함께 사용한다.
- 물리적 연결 통로는 `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`의 `_draw_connection_bridge`, `_draw_v122_defender_connector`, `_draw_connected_path_mouth_layer`에서 선·원 도형으로 그려지는 경로가 남아 있다.
- 현재 대표 런타임 크기:

| 자산 | 런타임 크기 | 현재 역할 | 관찰 위험 |
|---|---:|---|---|
| `corridor_surface_stage01_cell_00~11.png` | 128×64 | Stage 01 복도 반복 셀 | 작은 셀에 세부 격자 반복 |
| `threshold_stage01_N/E/S/W_2cell.png` | 256×128 | 방·복도 문턱 | 복도와 질감 밀도 차이 |
| `floor_cave_v2_mask_00.png` | 128×64 | 바닥 mask 타일 | 방 이미지와 투영·질감 불일치 |
| `room_throne_stage01_SW_open_s_back.png` | 640×640 | Stage 01 왕좌 | 다른 방과 화풍·해상도 대비 큼 |
| `cavern_edge_mask_stage01_9slice.png` | 1024×1024 | 외곽 암벽 frame | 축소 시 알파 경계 확인 필요 |

### Phase 1 — 공통 아트 기준

- 기준 방향은 기존 감사 문서와 동일하게 어둡고 장중한 다크 판타지 성으로 고정한다.
- 환경 시점은 30~35도 하향 이소메트릭, 좌상단 온광·보라 환경 반사광, 낮고 부드러운 접촉 그림자를 사용한다.
- 밝은 황금은 현재 선택·주 행동에만 사용하고, 일반 도로·통로는 저채도 철색·보라 회색 재질로 제한한다.
- 모든 신규 환경 원화는 2배 이상 마스터 해상도로 만들고, 런타임 타일은 결정적으로 축소·분할한다.
- 파이썬 도구는 crop·resize·mask·검증에만 사용하며 최종 도로·통로 모양을 코드로 그리지 않는다.

### Phase 2 — 기술 시험 기준

- 대표 자산 6종은 복도 셀 2종, 방 랜드마크 2종, 캐릭터·UI 대표 2종으로 잡는다.
- 공통 import 상태는 현재 `mipmaps/generate=false`, `compress/mode=0`, `process/fix_alpha_border=true`이다.
- 프로젝트 기본 텍스처 필터는 `project.godot`의 `textures/canvas_textures/default_texture_filter=0`이며, 특정 자산별 필터 고정은 아직 없다.
- 따라서 자글거림은 다음 두 축으로 분리해서 판정한다.
  1. 동일 원본을 100%·75%·50% 표시할 때 이동 중 패턴이 떨리는지
  2. 정지 화면에서도 타일 내부 질감 주파수가 과해 계단·점무늬처럼 보이는지
- 전역 필터 값을 즉시 변경하지 않고, 대표 자산 A/B 결과 승인 후 범주별 import 정책을 적용한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/handoff/V122_VISUAL_UNIFICATION_PHASE0_2_BASELINE_2026-08-01.md` | Phase 0~2 기준선과 핸드오프 | 완료 |
| `data/dungeon_quarter/asset_manifest.json` | 읽기 전용 점검 | 변경 없음 |
| `data/dungeon_quarter/tile_variant_manifest.json` | 읽기 전용 점검 | 변경 없음 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 코드 도형 통로 위치 확인 | 변경 없음 |
| `project.godot` 및 대표 `.png.import` | 필터·밉맵 현황 확인 | 변경 없음 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요. 이 세션은 기준선·기술 시험 설계 단계다.
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 기존 Stage 01 원본 문서 유지
- 런타임 최종 자산 경로: 기존 자산 유지
- 프롬프트/후처리/크롭/알파 처리 요약: 신규 생성·후처리 없음
- 게임 연결 및 실제 렌더 확인 결과: 정적 manifest·renderer 연결 확인. 실제 화면 캡처는 다음 실행 페이즈에서 수행한다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | manifest·renderer·import 정적 점검 | PASS | 본 문서 3절 |
| 2 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |
| 3 | 시각/실플레이 검수 | REQUESTED_PENDING | Phase 2 대표 A/B 캡처에서 수행 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 복도 셀 내부의 반복 질감이 실제 화면에서 어느 배율에서 자글거리는지 아직 캡처하지 않았다.
- Stage 01 복도는 이미지 셀을 사용하지만 일반 연결 통로와 DAY 3 수비대 지름길은 여전히 코드 선·원 도형이다.
- 공통 아트 기준은 고정했지만 사용자 승인용 도로·통로 comparison board가 아직 없다.

## 8. 다음 작업 순서

1. Godot 대표 화면을 1280×720에서 캡처하고 동일 장면의 기술 A/B 표시를 비교한다.
2. 승인된 기준으로 도로 2셀 직선·끝·코너 시안을 생성한다.
3. 도로 시안 승인 뒤 통로 연결부와 DAY 3 지름길 원화를 생성하고 renderer의 코드 도형 경로를 교체한다.

## 9. 작업 트리 상태

- `git status --short --branch`: `codex/v122-ui-simplification`, 기존 브랜치가 원격보다 1커밋 앞섬
- 미커밋 파일: 본 핸드오프 문서, Phase 2 대표 텍스처 테스트
- 의도하지 않은 기존 변경: 확인되지 않음
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물 위치: 생성하지 않음

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [ ] 관련 테스트 통과
- [ ] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트는 실행하지 않음
- [x] 검수 대상 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 상태 기록
- [ ] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
