# V1.2.2 구조벽 높이·캐릭터 가림 보정

> **2026-08-06 사용자 검수 결과: REJECTED / 사용 금지.** 이 문서의 `WallFix` 빌드는 전투 유닛이 구조벽 뒤로 사라지는 결함이 남아 있다. 그 다음 `WallTransparency` 빌드도 유닛이 정적 바닥 뒤에 그려지는 결함으로 폐기됐다. 현재 권위 문서와 대체 Fix2 빌드는 `docs/handoff/V122_UNIT_ABOVE_FLOOR_DEPTH_CORRECTION_2026-08-06.md`를 따른다.

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `origin/main` / `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `a0973152132b725d7dc4631c1837386fce3244b4`
- 원격 푸시 여부: 미푸시. 현재 브랜치는 원격보다 4커밋 앞서며 이번 구조벽 수정은 미커밋이다.
- 관련 PR 또는 태그: 기존 Draft PR #80. 푸시·PR 갱신·병합·태그·Release는 사용자 화면 승인 전까지 중단한다.
- 사용자 테스트 빌드: `tmp/v122_wall_fix_test/20260805_235830/MawangCastle-v1.2.2-WallFix-Test-Windows.zip`

## 2. 이번 세션 목표

- 요청 사항: 벽을 거의 없앤 것처럼 보이게 만든 낮은 경계와 캐릭터 앞에 튀어나와 가리는 구조벽 조각을 Stage 01뿐 아니라 끝까지 모든 맵에서 수정한다.
- 완료 조건: 4단 구조벽 높이와 방 경계를 복원하고, 구조벽이 캐릭터·방 표식보다 앞에서 가리지 않으며, Stage 01~04 및 전투 대표 화면에서 같은 결과를 확인한다.
- 범위에서 제외한 사항: 출시 전체 회귀, 원격 푸시, PR 갱신, 병합, 태그, GitHub Release.

## 3. 완료한 작업

- 구현: `BackWallLayer(-70)` 뒤에서 바닥에 묻히던 구조벽 본체를 정적 맵 그리기 순서로 옮겨 바닥 위에 한 번만 표시했다.
- 구현: 구조벽 본체를 캐릭터·방 오브젝트보다 먼저 그려 관리 화면 표식과 전투 캐릭터가 벽 위에 보이도록 했다.
- 구현: `FrontWallLayer(50)`에서 항상 캐릭터를 덮던 E/S 방향의 얇은 `front_occluder`와 돌출 조각 렌더링을 비활성화했다.
- UI/UX: Stage 01~04 모두 4단 석벽 경계가 다시 보이며, 관리 화면 캐릭터 표식과 전투 유닛은 벽에 묻히지 않는다.
- 저장 및 호환성: 저장 데이터와 맵 topology는 변경하지 않았다. 기존 wall canvas 노드는 씬 호환용으로 유지하되 구조벽을 중복 렌더링하지 않는다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 구조벽 본체 draw 순서 복원, 전면 고정 가림 비활성화 | 사용자 화면 승인 필요 |
| `scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd` | 호환 canvas의 무렌더 계약 명시 | 완료 |
| `tools/tests/V122FrontWallActorVisibilityTest.gd` | 벽-오브젝트 순서와 전면 돌출 제거 계약 | PASS |
| `tools/tests/V122V4ADepthSlotContractTest.gd` | 구조벽 캐릭터 비가림 계약 갱신 | PASS |
| `docs/handoff/CURRENT.md` | 현재 출시 중단 상태와 다음 단계 갱신 | 완료 |
| `docs/handoff/V122_STRUCTURAL_WALL_VISIBILITY_CORRECTION_2026-08-05.md` | 이번 수정·검증·미해결 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 없음. 기존 승인된 V3 구조벽 PNG를 그대로 사용했다.
- 생성 모델: 해당 없음
- 생성 원본 경로: `assets/source/imagegen/v122_structural_wall_kit_v3/`
- `SOURCE.md` 경로: `assets/source/imagegen/v122_structural_wall_kit_v3/SOURCE.md`
- 런타임 최종 자산 경로: `assets/tiles/cave_v2/structural_walls_v3/`
- 프롬프트/후처리/크롭/알파 처리 요약: 자산 픽셀은 변경하지 않고 렌더 순서만 보정했다.
- 게임 연결 및 실제 렌더 확인 결과: Stage 01~04 1280×720 및 역할 전투 1920×1080 실제 Vulkan 캡처에서 구조벽 복원과 캐릭터 비가림을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122FrontWallActorVisibilityTest.gd` | PASS, 15 assertions | 터미널 출력 |
| 2 | `V122V4ADepthSlotContractTest.gd` | PASS | 터미널 출력 |
| 3 | `V122CorridorWallTopologyTest.tscn` | PASS | 터미널 출력 |
| 4 | `V122StructuralWallPixelContractTest.tscn` | PASS, 285 assertions | 터미널 출력 |
| 5 | `V122CorridorTopologyLayoutMatrixTest.tscn` | PASS | 터미널 출력 |
| 6 | `V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | 터미널 출력 |
| 7 | `QuarterModuleSmokeTest.tscn` | PASS | 터미널 출력 |
| 8 | `V122StructuralWallCapture.tscn` 실제 Vulkan | PASS, Stage 01~04 + custom | `tmp/v122_structural_wall_review/` |
| 9 | `RoleCombatLayoutCapture.tscn` 실제 Vulkan | PASS | `tmp/role_combat_verification/` |
| 10 | Windows Desktop release export | PASS, EXE/PCK 생성 | `tmp/v122_wall_fix_test/20260805_235830/windows/` |
| 11 | 새 EXE 1280×720 10초 실제 부팅 | PASS, 조기 종료 없음·오류 0건 | `tmp/v122_wall_fix_test/20260805_235830/windows/windows_boot_smoke.log` |
| 12 | 사용자 테스트 ZIP 엔트리·SHA-256 | PASS, EXE/PCK 2개 | `tmp/v122_wall_fix_test/20260805_235830/SHA256SUMS.txt` |
| 13 | 전체 회귀 테스트 | NOT_REQUESTED | 실행하지 않음 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A. 전체 검수는 요청되지 않았다.
- 실행하지 못한 필수 검수와 이유: 사용자 시각 승인 전이라 공식 출시 Full 검수는 의도적으로 재개하지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 현재 수정은 미커밋 작업 트리이며 사용자 승인 뒤 기능 SHA를 만든 후 관련 테스트를 다시 묶는다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: 7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..UNCOMMITTED_WORKTREE
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동·대표 캡처는 통과했으나 벽 체감 높이는 사용자의 직접 화면 승인이 남아 있다.
- 임시 구현 또는 대체 자산: 없음. 기존 front occluder 파일은 catalog 호환과 이력 보존을 위해 남지만 런타임 구조벽 앞가림으로 호출되지 않는다.
- 외부 환경/도구 제약: 실제 GPU 캡처는 Windows Vulkan에서 확인했다.

## 8. 다음 작업 순서

1. 사용자가 `tmp/v122_wall_fix_test/20260805_235830/MawangCastle-v1.2.2-WallFix-Test-Windows.zip`을 풀고 새 EXE에서 실제 벽 높이와 돌출 제거를 확인한다.
2. 승인되면 의도한 코드·테스트·핸드오프만 커밋하고 동일 관련 테스트와 캡처를 최종 SHA에 다시 묶는다.
3. 그 뒤에만 중단했던 정식 출시 Full 검수와 푸시·PR·병합·태그·Release 절차를 재개한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`이 원격보다 4커밋 앞서며 구조벽 코드·테스트·핸드오프가 미커밋이다.
- 미커밋 파일: 본 문서의 변경 파일 표에 기록한 경로.
- 의도하지 않은 기존 변경: 없음.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/v122_wall_fix_test/20260805_235830/`, `tmp/v122_structural_wall_review/`, `tmp/role_combat_verification/` (Git 비추적).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 Stage 01~04·전투 대표 캡처 완료
- [x] 벽 수정 반영 Windows 사용자 테스트 빌드·부팅·ZIP 완료
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 사실 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 사용자 시각 승인
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
