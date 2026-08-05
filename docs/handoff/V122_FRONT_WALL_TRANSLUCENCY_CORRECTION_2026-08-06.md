# V1.2.2 전면 구조벽 반투명·캐릭터 가시성 보정

> **2026-08-06 사용자 검수 결과: REJECTED / 이 문서의 빌드 사용 금지.** 전면 벽은 반투명해졌지만 맵 위쪽 전투 유닛 깊이가 음수여서 정적 바닥 뒤에 그려지는 결함이 남아 있었다. 현재 권위 문서와 대체 Fix2 빌드는 `docs/handoff/V122_UNIT_ABOVE_FLOOR_DEPTH_CORRECTION_2026-08-06.md`를 따른다.

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `origin/main` / `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `a0973152132b725d7dc4631c1837386fce3244b4`
- 원격 푸시 여부: 미푸시. 원격 작업 브랜치보다 4커밋 앞서며 이번 보정은 미커밋이다.
- 관련 PR 또는 태그: 기존 Draft PR #80. 사용자 화면 승인 전에는 푸시·PR 갱신·병합·태그·Release를 진행하지 않는다.
- 사용자 테스트 빌드: `tmp/v122_wall_transparency_test/20260806_004048/MawangCastle-v1.2.2-WallTransparency-Test-Windows.zip`

## 2. 이번 세션 목표

- 요청 사항: 4단 벽을 복원한 1차 빌드에서 몬스터가 벽 뒤로 사라지는 문제를 수정하고, 다른 등각 시점 게임의 처리 방식을 조사해 벽과 통로 형태를 유지하면서 캐릭터를 읽을 수 있게 한다.
- 완료 조건: 카메라 뒤쪽 벽은 깊이감을 유지하고, 카메라 앞쪽 벽은 캐릭터를 완전히 지우지 않으며, 얇은 돌출 가림 조각 없이 Stage 01~04·분기형 맵·강제 겹침 전투 화면과 Windows 빌드에서 동작한다.
- 범위에서 제외한 사항: 정식 출시 전체 회귀, 전체 플레이, 별도 검수 에이전트, 원격 푸시, PR 갱신, 병합, 태그, GitHub Release.

## 3. 완료한 작업

- 구현: 2026-08-05 `WallFix` 빌드는 사용자 검수에서 REJECTED로 판정했다. 코드상 먼저 그린 구조벽도 음수 깊이 슬롯의 전투 유닛보다 앞에 남을 수 있어 몬스터가 다시 벽 뒤로 들어갔다.
- 구현: 구조벽을 방향별로 분리했다. N/W 후면 본체는 바닥 위 정적 맵에 0.94 불투명도로 남기고, E/S 전면 본체는 `FrontWallLayer`에서 0.46 알파로 그린다.
- 구현: 전면에는 기존의 얇은 `front_occluder` 조각을 쓰지 않고 4단 벽 전체를 반투명으로 그린다. 따라서 통로 높이·석재 윤곽은 남고 뒤의 캐릭터 색·실루엣은 보인다.
- 구현: 코너·끝점·분기 정점도 전면 방향 포함 여부로 나눠 몸체와 같은 알파 정책을 적용해 불투명 기둥 하나가 캐릭터를 다시 지우는 틈을 막았다.
- UI/UX: 심즈·프로젝트 좀보이드의 카메라 방향 컷어웨이와 디아블로 계열의 벽 투명화 원칙을 결합했다. 이번 구현은 이동 중 깜빡임과 구조벽 전체 재계산을 피하기 위해 캐릭터 근접 시점이 아니라 카메라 방향에 따른 안정적인 상시 컷어웨이를 사용한다.
- 스토리 및 데이터: 스토리·진행 데이터 변경 없음. 공통 벽 렌더 프로필에 `front_occlusion_alpha: 0.46`만 추가했다.
- 밸런스: 변경 없음.
- 저장 및 호환성: 저장 형식과 topology는 변경하지 않았다. 기존 wall canvas 노드와 front occluder 자산은 호환·이력용으로 유지한다.

### 조사 근거

- Blizzard의 Diablo 매뉴얼은 캐릭터가 벽·문에 가까워질 때 벽을 투명하게 만들어 뒤의 아이템과 생물을 놓치지 않도록 설명한다.
- The Sims는 Walls Up, Cutaway, Down의 벽 표시 단계를 제공한다.
- Project Zomboid는 캐릭터 기준 컷어웨이 벽과 전환 깜빡임을 줄이는 타이머를 개선해 왔다.
- Larian 지원 자료도 캐릭터가 뒤로 이동하는 벽을 반투명 또는 ghost 처리하는 방식을 설명한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/dungeon_quarter/asset_manifest.json` | 전면 구조벽 알파 0.46 공통 프로필 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | N/W 후면 불투명·E/S 전면 전체 반투명 렌더 분리 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd` | 전면 반투명 wall canvas 계약 | 완료 |
| `tools/RoleCombatLayoutCapture.gd` | 유닛을 전면 벽 뒤에 강제로 놓는 06번 캡처 추가 | PASS |
| `tools/tests/V122FrontWallActorVisibilityTest.gd` | 방향 분리·전체 본체·알파 범위 계약 | PASS, 20 assertions |
| `tools/tests/V122V4ADepthSlotContractTest.gd` | 후면 불투명·전면 반투명 깊이 계약 | PASS |
| `docs/handoff/CURRENT.md` | 실패한 1차 빌드 폐기와 새 테스트 빌드 안내 | 완료 |
| `docs/handoff/V122_STRUCTURAL_WALL_VISIBILITY_CORRECTION_2026-08-05.md` | 1차 접근 REJECTED·대체 문서 표시 | 완료 |
| `docs/handoff/V122_FRONT_WALL_TRANSLUCENCY_CORRECTION_2026-08-06.md` | 이번 수정·검증·다음 작업 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 없음
- 생성 모델: 해당 없음
- 생성 원본 경로: `assets/source/imagegen/v122_structural_wall_kit_v3/`
- `SOURCE.md` 경로: `assets/source/imagegen/v122_structural_wall_kit_v3/SOURCE.md`
- 런타임 최종 자산 경로: `assets/tiles/cave_v2/structural_walls_v3/`
- 프롬프트/후처리/크롭/알파 처리 요약: PNG 픽셀은 변경하지 않고 런타임 방향·알파 합성만 변경했다.
- 게임 연결 및 실제 렌더 확인 결과: Stage 01~04와 custom map 1280×720, 일반 전투와 강제 벽 겹침 1920×1080 실제 Vulkan 캡처에서 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122FrontWallActorVisibilityTest.gd` | PASS, 20 assertions | `tmp/v122_front_wall_actor_visibility.log` |
| 2 | `V122V4ADepthSlotContractTest.gd` | PASS | `tmp/v122_depth_slot_contract.log` |
| 3 | `V122CorridorWallTopologyTest.tscn` | PASS | `tmp/V122CorridorWallTopologyTest.translucent_wall.log` |
| 4 | `V122CorridorTopologyLayoutMatrixTest.tscn` | PASS | `tmp/V122CorridorTopologyLayoutMatrixTest.translucent_wall.log` |
| 5 | `V122StructuralWallPixelContractTest.tscn` | PASS, 285 assertions | `tmp/V122StructuralWallPixelContractTest.translucent_wall.log` |
| 6 | `V122Stage01SpatialVisualRuntimeTest.tscn` | PASS | `tmp/V122Stage01SpatialVisualRuntimeTest.translucent_wall.log` |
| 7 | `QuarterModuleSmokeTest.tscn` | PASS | `tmp/QuarterModuleSmokeTest.translucent_wall.log` |
| 8 | `V122StructuralWallCapture.tscn` 실제 Vulkan | PASS, Stage 01~04 + custom | `tmp/v122_structural_wall_review/` |
| 9 | `RoleCombatLayoutCapture.tscn` 실제 Vulkan | PASS, 전면 벽 강제 겹침 포함 | `tmp/role_combat_verification/06_combat_front_wall_transparency.png` |
| 10 | Windows Desktop release export | PASS, EXE/PCK 생성 | `tmp/v122_wall_transparency_test/20260806_004048/windows/` |
| 11 | 새 EXE 1280×720 10초 실제 부팅 | PASS, 조기 종료 없음·오류 0건 | `tmp/v122_wall_transparency_test/20260806_004048/windows/windows_boot_smoke.log` |
| 12 | ZIP 엔트리·SHA-256 | PASS, EXE/PCK 2개 | ZIP SHA-256 `DA8A2FB62FD344E88966E4ECF66753339018B882BEE07E15B5D74D3E2400AA09` |
| 13 | 전체 회귀 테스트 | NOT_REQUESTED | 실행하지 않음 |
| 14 | 전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 실행하지 않음 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A. 전체 검수는 요청되지 않았다.
- 실행하지 못한 필수 검수와 이유: 없음. 현재 요청에 필요한 관련 테스트와 화면·빌드 검증은 완료했다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 문서만 갱신했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: 7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..UNCOMMITTED_WORKTREE
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동·GPU 캡처에서는 해결됐지만 최종 체감 알파와 통로 가독성은 사용자의 새 Windows 빌드 직접 확인이 남아 있다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 없음. 방향 기반 상시 컷어웨이는 의도한 안정 정책이며 캐릭터 근접식 동적 페이드는 사용하지 않는다.
- 외부 환경/도구 제약: 첫 sandbox export는 AppData의 Godot export template 접근 제한으로 실패했으나 권한 승인 후 같은 소스의 export가 성공했다. 제품 오류가 아니다.

## 8. 다음 작업 순서

1. 사용자가 새 ZIP을 풀어 실제 전투에서 벽 뒤 몬스터 가시성, 벽 높이, 통로 형태를 확인한다. 변경 경로 없음, 완료 조건은 사용자 화면 승인이다.
2. 승인되면 위 표의 코드·데이터·도구·핸드오프만 명시적으로 스테이징하고 기능 커밋을 만든다. 완료 조건은 의도한 diff만 포함된 새 SHA다.
3. 사용자 지시에 따라 그 SHA에서 공식 Full 검수와 푸시·PR·병합·`v1.2.2` 태그·Release를 재개한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`이 원격보다 4커밋 앞서며 이번 구조벽 수정이 미커밋이다.
- 미커밋 파일: 변경 파일 표의 데이터·렌더러·canvas·캡처·테스트·핸드오프.
- 의도하지 않은 기존 변경: 없음.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/v122_wall_transparency_test/20260806_004048/`, `tmp/v122_structural_wall_review/`, `tmp/role_combat_verification/` (Git 비추적).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 사실 기록
- [x] 검수 대상이 미커밋 작업 트리임을 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 새 Windows 사용자 테스트 빌드·부팅·ZIP 완료
- [ ] 사용자 시각 승인
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
