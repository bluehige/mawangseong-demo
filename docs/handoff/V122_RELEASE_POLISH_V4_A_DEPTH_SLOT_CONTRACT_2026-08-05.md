# V122 Release Polish Handoff — V4-A-02 DEPTH-SLOT-CONTRACT

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 미커밋)
- 패킷: `V4-A-02-DEPTH-SLOT-CONTRACT`
- 결과: `DEPTH_SLOT_CONTRACT_PASS`
- QA: `docs/qa/V122_V4_A_DEPTH_SLOT_CONTRACT_2026-08-05.md`

## 2. 완료 내용

- `QuarterDungeonRenderer`에 유닛 depth 슬롯(`-40..44`), walkable Y 정규화, `FrontWallLayer=50` 경계, N/W 후면·E/S 전면 occluder 계약 API를 추가했다.
- `Unit`의 무제한 `z_index = int(global_position.y)`를 제거하고 renderer 슬롯을 사용하도록 변경했다. renderer 미준비 시에도 같은 범위를 지키는 fallback을 둔다.
- `QuarterDungeonWallCanvas`가 `wall_front` 전용 draw 범위와 occlusion 계약을 읽기 전용으로 노출한다.
- VFX 연결은 `PENDING_V5`로 유지했다.

## 3. 변경 파일

| 경로 | 내용 |
|---|---|
| `scripts/units/Unit.gd` | 유닛 depth 슬롯 갱신·fallback |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 슬롯 계산·경계·occlusion 계약 API |
| `scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd` | front-only 계약 조회 |
| `tools/tests/V122V4ADepthSlotContractTest.gd` | V4-A 계약 정적 직접 테스트 |
| `docs/qa/V122_V4_A_DEPTH_SLOT_CONTRACT_2026-08-05.md` | QA 기록 |
| `docs/handoff/V122_RELEASE_POLISH_V4_A_DEPTH_SLOT_CONTRACT_2026-08-05.md` | 세션 핸드오프 |
| `docs/handoff/CURRENT.md` | 다음 패킷·현재 상태 갱신 |

그래픽·오디오·스토리·밸런스 데이터 변경은 없다.

## 4. 검수

```text
godot.cmd --headless --path . --script tools/tests/V122V4ADepthSlotContractTest.gd --quit-after 30
V122_V4_A_DEPTH_SLOT_CONTRACT_TEST: PASS

godot.cmd --headless --path . --check-only --quit
PASS
```

대표 화면, 전체 회귀, 전체 플레이, 빌드와 검수 에이전트는 사용자 요청 범위가 아니어서 실행하지 않았다.

## 5. 미해결 및 다음 순서

- 실제 `1280×720` 전면 벽 가림 화면과 지면·몸·공중 VFX 연결은 V5 범위에 남아 있다.
- 다음 제안 패킷은 `V4-B-01-UI-ANCHOR-DISCOVERY`다. 이름·HP·피해 숫자 앵커의 현재 부모·좌표·겹침 원인을 읽기 전용으로 조사하며, 이번 패킷 완료 보고 뒤에만 시작한다.

## 6. 작업 트리

- 기존 Luna·사용자 미커밋 변경을 보존했으며, 이번 패킷도 아직 커밋하지 않았다.
- 빌드 산출물·캡처·`output/`·`web_Demo/`는 생성하지 않았다.
- 원격 푸시: 없음.

## 7. 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
