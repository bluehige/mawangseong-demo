# v1.2.2 시각 개편 15단계 Stage 01 공간 자산 런타임 연결 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 단계 목표

- 승인된 Stage 01 왕좌·문턱·복도·폐색·암벽 frame 원본을 exact runtime 크기로 변환한다.
- 생성 원본과 런타임 자산을 분리하고, 변환을 결정적으로 재실행할 수 있게 한다.
- 자산 역할을 manifest에 기록하고 Stage 01에서만 renderer lookup을 사용한다.
- 보이는 문턱과 복도, 벽의 합성 순서를 이동 경로 구조와 일치시킨다.
- 외곽 frame은 world보다 앞, HUD보다 뒤에 두고 전투 입력을 받지 않게 한다.

## 3. 구현 결과

### 결정적 자산 준비

- `tools/prepare_v122_stage01_spatial_assets.py`를 추가했다.
- 스크립트는 승인된 alpha source에 crop·resize·diamond masking·9-slice 고립 alpha 제거만 수행한다.
- 회화적 재생성이나 런타임 원본 덮어쓰기는 하지 않는다.
- 복도 2셀 원본은 번호가 고정된 `00/10/01/11` 4개 셀로 잘라 임의 길이 복도에서도 재사용한다.
- 문턱은 N/E/S/W 모두 `256×128`, 복도 셀은 `128×64`, 왕좌는 `640×640`, frame은 `1024×1024`로 고정했다.

### manifest와 renderer

- `data/dungeon_quarter/asset_manifest.json`의 `stage_spatial_visuals.stage_01_cave`에 역할 기반 경로를 추가했다.
- Stage 01 왕좌 `SW/back`만 새 exact 자산으로 바꾸고 Stage 2 이후 자산은 그대로 유지했다.
- `QuarterDungeonRenderer`는 Stage 01일 때만 새 복도 셀·문턱·폐색·외곽 frame을 사용한다.
- N/W 문턱은 후면 벽 전에, E/S 문턱은 전면 벽 뒤에 합성한다.
- 기존 황금 연결선과 중복 doorway 선은 Stage 01에서 생략한다.
- 외곽 암벽은 `NinePatchRect.draw_center=false`로 중앙을 비우고 code-native 저채도 보라 feather를 분리했다.
- 외곽 overlay는 `MOUSE_FILTER_IGNORE`이며 관리·전투의 quarter map에서만 보인다.

### 생성 원본 provenance

- 왕좌·문턱 4종·복도·폐색·frame의 `SOURCE.md`에 런타임 경로와 `RUNTIME_CONNECTED` 상태를 기록했다.
- 원본은 `assets/source/imagegen/v122_stage01_spatial/`, 런타임은 `assets/props`, `assets/tiles`, `assets/ui` 아래에 분리했다.

## 4. 주요 변경 파일

| 경로 | 목적 |
|---|---|
| `tools/prepare_v122_stage01_spatial_assets.py` | 승인 원본의 결정적 exact 변환 |
| `data/dungeon_quarter/asset_manifest.json` | Stage 01 역할 기반 lookup |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 복도·문턱·폐색·frame 런타임 합성 |
| `tools/tests/V122Stage01SpatialVisualRuntimeTest.gd` | 크기·lookup·레이어·입력 계약 검증 |
| `tools/tests/V122Stage01SpatialVisualRuntimeTest.tscn` | 전용 headless 테스트 진입점 |
| `assets/tiles/stage_01/spatial/` | 복도·문턱·폐색 런타임 자산 |
| `assets/props/stage_01/room_throne_stage01_SW_open_s_back.png` | Stage 01 exact 왕좌 |
| `assets/ui/stage_01/cavern_edge_mask_stage01_9slice.png` | Stage 01 외곽 암벽 frame |

## 5. 대상 테스트

실행:

```powershell
..\v20-u0\tmp\tools\godot-4.5.2\Godot_v4.5.2-stable_win64_console.exe --headless --path . --scene res://tools/tests/V122Stage01SpatialVisualRuntimeTest.tscn
```

결과:

- `V122_STAGE01_SPATIAL_VISUAL_RUNTIME_TEST: PASS`
- Stage 01 공간 texture 10종 로드: PASS
- native runtime 크기: PASS
- Stage 01 왕좌 한정 및 Stage 2 비침범: PASS
- N/W 후면·E/S 전면 문턱 합성 순서: PASS
- 9-slice 중앙·고립 alpha 제거: PASS
- 외곽 overlay 입력 비차단: PASS

전체 회귀, 플레이 검수, Windows/Web 빌드는 사용자의 현 단계 요청 범위에 따라 수행하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 남은 직접 영향

- 실제 1920 full-canvas와 1366/1280 compact 화면의 최종 미감은 캐릭터 접지·HUD 레이어 정리 뒤 함께 확인한다.
- frame과 HUD의 최종 시각 간격은 전투 HUD 단계에서 조정한다.
- Stage 2~4는 이번 Stage 01 자산으로 덮어쓰지 않았다.

## 7. 다음 작업 순서

1. 캐릭터 contact shadow와 선택 표시를 배경 투영에 맞춘다.
2. 이름·체력·VFX의 상시 노출을 줄여 `바닥 → 접지 → 선택 → 캐릭터 → VFX → 이름·체력 → 경고` 순서를 고정한다.
3. 1920 full-canvas와 1366/1280 compact 전투 HUD의 중첩을 정리한다.
4. 관련 대상 테스트와 핸드오프를 갱신한다.

## 8. 작업 트리 상태

- 대규모 기존 사용자 변경과 `.import` 변경을 보존했다.
- 이번 단계 파일은 미커밋 상태다.
- 빌드·커밋·푸시하지 않았다.
