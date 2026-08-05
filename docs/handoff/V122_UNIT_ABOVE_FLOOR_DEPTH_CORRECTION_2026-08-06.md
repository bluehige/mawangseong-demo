> 2026-08-06 사용자 UI 검수 후 **SUPERSEDED / Fix2 사용 중단**. 이 문서의 유닛·바닥 깊이 보정은 유효하지만, Fix2는 1280×720에서 방 지침 글자가 지나치게 작아 새 Fix3 빌드로 교체됐다. 현재 권위 문서는 `docs/handoff/V122_ROOM_DIRECTIVE_READABILITY_2026-08-06.md`다.

# V1.2.2 전투 유닛 바닥 뒤 렌더링 깊이 보정

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `origin/main` / `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `a0973152132b725d7dc4631c1837386fce3244b4`
- 원격 푸시 여부: 미푸시. 현재 브랜치는 원격 작업 브랜치보다 4커밋 앞서며 이번 수정은 미커밋이다.
- 관련 PR 또는 태그: 기존 Draft PR #80. 사용자 화면 승인 전에는 푸시·PR 갱신·병합·태그·Release를 진행하지 않는다.
- 현재 사용자 테스트 빌드: `tmp/v122_unit_above_floor_fix2/20260806_012035/MawangCastle-v1.2.2-UnitAboveFloor-Fix2-Windows.zip`

## 2. 이번 세션 목표

- 요청 사항: 전면 벽 반투명 빌드에서 몬스터가 벽뿐 아니라 바닥보다도 뒤에서 싸우는 기본 깊이 오류를 고치고 새 Windows 빌드를 제공한다.
- 완료 조건: 맵의 최상단부터 최하단까지 모든 유닛이 정적 바닥보다 앞에 있고, 전면 구조벽보다는 뒤에 있으며, 실제 캡처·관련 회귀·Windows 부팅에서 같은 결과를 확인한다.
- 범위에서 제외한 사항: 정식 출시 전체 회귀 156개, 전체 플레이, 별도 검수 에이전트, 커밋·푸시·PR·병합·태그·Release.

## 3. 완료한 작업

- 원인 재현: 전투 유닛 깊이 범위가 `-40..44`였고 정적 바닥은 `z=0`이었다. 따라서 맵 위쪽 유닛은 음수 깊이가 되어 바닥 뒤에 그려졌다.
- 검증 허점 확인: 직전 강제 겹침 캡처는 맵 중앙의 양수 깊이 유닛만 사용해 최상단 음수 범위를 놓쳤다.
- 테스트 우선 보정: 기대 계약을 먼저 `바닥 0 < 유닛 1..44 < 전면 벽 50`으로 바꾸고, 수정 전 정적·실시간 테스트가 실제로 실패하는 것을 확인했다.
- 구현: 렌더러와 `Unit` fallback의 유닛 최솟값을 `1`로 올렸고, 렌더러 미준비 시 VFX fallback도 `1`로 맞췄다.
- 화면 검증: 기존 전면 벽 강제 겹침 외에 맵 최상단·최하단 보행 셀 유닛 캡처를 추가했다. 두 위치 모두 유닛이 바닥 위에 보였고, 전면 벽은 반투명 구조를 유지했다.
- UI/UX: 카메라 뒤쪽 N/W 벽은 0.94, 카메라 앞쪽 E/S 벽은 0.46 반투명인 직전 방향 정책을 유지했다. 이번 수정은 그 아래의 전역 유닛-바닥 깊이 계약만 바로잡았다.
- 스토리·데이터·밸런스·저장 형식: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 유닛 깊이 `1..44`, 정적 바닥 0, 전면 벽 50 계약 | PASS |
| `scripts/units/Unit.gd` | 렌더러 미준비 fallback 깊이 하한 1 | PASS |
| `scripts/game/CombatSceneController.gd` | renderer 미준비 VFX fallback 깊이 1 | PASS |
| `tools/tests/V122V4ADepthSlotContractTest.gd` | 정적 바닥보다 위인 유닛 범위 회귀 | PASS |
| `tools/tests/V122CombatVfxDepthLiveContractTest.gd` | 맵 최상단 1·최하단 44와 VFX 실시간 회귀 | PASS, 23 assertions |
| `tools/RoleCombatLayoutCapture.gd` | 최상단·최하단 유닛 화면 07·08 추가 | PASS |
| `data/dungeon_quarter/asset_manifest.json` | 직전 전면 벽 반투명 프로필 | PASS |
| `scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd` | 직전 전면 벽 반투명 canvas 계약 | PASS |
| `tools/tests/V122FrontWallActorVisibilityTest.gd` | 전면 벽 방향·반투명 회귀 | PASS, 20 assertions |
| `docs/handoff/CURRENT.md` | 실패 빌드 폐기와 Fix2 안내 | 완료 |
| `docs/handoff/V122_FRONT_WALL_TRANSLUCENCY_CORRECTION_2026-08-06.md` | 직전 빌드 REJECTED 표시 | 완료 |
| `docs/handoff/V122_STRUCTURAL_WALL_VISIBILITY_CORRECTION_2026-08-05.md` | 최초 빌드 REJECTED·최신 문서 연결 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 없음
- 생성 모델: 해당 없음
- 생성 원본 경로: 변경 없음
- `SOURCE.md` 경로: 변경 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: PNG·오디오 파일을 변경하지 않았다.
- 게임 연결 및 실제 렌더 확인 결과: Vulkan 1920×1080 캡처에서 맵 최상단·최하단 유닛이 바닥 위에 렌더링됨을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 보정 전 `V122V4ADepthSlotContractTest.gd` | 기대대로 FAIL | `tmp/v122_depth_floor_repro_static.log` |
| 2 | 보정 전 `V122CombatVfxDepthLiveContractTest.gd` | 기대대로 FAIL, 최상단 유닛이 바닥 뒤임을 재현 | `tmp/v122_depth_floor_repro_live.log` |
| 3 | 보정 후 `V122V4ADepthSlotContractTest.gd` | PASS | `tmp/v122_fix2_depth_static.log` |
| 4 | 보정 후 `V122CombatVfxDepthLiveContractTest.gd` | PASS, 23 assertions | `tmp/v122_fix2_depth_live.log` |
| 5 | `V122FrontWallActorVisibilityTest.gd` | PASS, 20 assertions | `tmp/v122_fix2_front_wall.log` |
| 6 | `V122CorridorWallTopologyTest.tscn` | PASS | `tmp/v122_fix2_corridor_wall.log` |
| 7 | `V122CorridorTopologyLayoutMatrixTest.tscn` | PASS | `tmp/v122_fix2_corridor_matrix.log` |
| 8 | `V122StructuralWallPixelContractTest.tscn` | PASS, 285 assertions | `tmp/v122_fix2_wall_pixels.log` |
| 9 | `V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | `tmp/v122_fix2_stage01_visual.log` |
| 10 | `QuarterModuleSmokeTest.tscn` | PASS | `tmp/v122_fix2_quarter_smoke.log` |
| 11 | `RoleCombatLayoutCapture.tscn` 실제 Vulkan | PASS | `tmp/v122_unit_above_floor_visual.log` |
| 12 | 맵 최상단 유닛 실제 화면 | PASS, 바닥 위 표시 | `tmp/role_combat_verification/07_combat_top_floor_depth.png` |
| 13 | 맵 최하단 유닛 실제 화면 | PASS, 바닥 위·전면 벽 아래 표시 | `tmp/role_combat_verification/08_combat_bottom_floor_depth.png` |
| 14 | Windows Desktop release export | PASS, EXE/PCK 생성 | `tmp/v122_unit_above_floor_fix2/20260806_012035/export.log` |
| 15 | 새 EXE 1280×720 10초 실제 부팅 | PASS, 프로세스 생존·조기 종료 없음·오류 0건 | `tmp/v122_unit_above_floor_fix2/20260806_012035/boot.log` |
| 16 | ZIP 엔트리·SHA-256 | PASS, EXE/PCK 2개 | SHA-256 `1EE17F8E4DECBB9DA986F86CC80CDAB0EA38CA0E3538F86041144A4D6ADDA15B` |
| 17 | 전체 회귀 테스트 | NOT_REQUESTED | 실행하지 않음 |
| 18 | 전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 실행하지 않음 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A. 전체 검수는 요청되지 않았다.
- 실행하지 못한 필수 검수와 이유: 없음. 현재 결함에 직접 관련된 코드·화면·빌드 검증은 완료했다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 핸드오프 문서만 갱신했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: 7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..UNCOMMITTED_WORKTREE
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동·실제 GPU 캡처·Windows 부팅에서는 해결됐다. 사용자의 실제 전투 체감 확인은 남아 있다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 테스트의 `user://C:` 및 Windows 루트 인증서 메시지는 sandbox 사용자 경로 제한에서만 발생하며 테스트 종료 코드는 모두 0이었다.
- 사용 금지 빌드: `tmp/v122_wall_fix_test/20260805_235830/`와 `tmp/v122_wall_transparency_test/20260806_004048/`는 각각 벽 가림·바닥 뒤 렌더링 결함이 있으므로 테스트에 사용하지 않는다.

## 8. 다음 작업 순서

1. 사용자가 Fix2 ZIP을 별도 폴더에 풀고 실제 초반 전투에서 맵 위·중앙·아래 몬스터와 전면 벽 겹침을 확인한다. 완료 조건은 바닥 뒤로 사라지는 몬스터가 없고 통로 구조가 읽히는 것이다.
2. 화면 승인을 받으면 현재 코드·데이터·도구·핸드오프 파일만 명시적으로 스테이징하고 기능 커밋을 만든다.
3. 사용자의 출시 진행 지시에 따라 기능 SHA에서 공식 Full 검수, 푸시, PR merge commit, `v1.2.2` 태그와 GitHub Release를 재개한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`이 원격보다 4커밋 앞서며 이번 수정은 미커밋이다.
- 미커밋 파일: 변경 파일 표의 코드·데이터·캡처 도구·테스트·핸드오프.
- 의도하지 않은 기존 변경: 없음. 직전 벽 수정과 이번 깊이 수정이 같은 사용자 검수 흐름에 포함된다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/v122_unit_above_floor_fix2/20260806_012035/`, `tmp/role_combat_verification/` (Git 비추적).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 수정 전 결함 재현
- [x] 관련 테스트 통과
- [x] 맵 최상단·최하단 실제 GPU 화면 확인
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 사실 기록
- [x] 검수 대상이 미커밋 작업 트리임을 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 새 Windows 사용자 테스트 빌드·부팅·ZIP 완료
- [ ] 사용자 시각 승인
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
