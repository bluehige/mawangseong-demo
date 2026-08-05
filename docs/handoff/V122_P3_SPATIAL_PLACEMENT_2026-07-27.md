# v1.2.2 P3 공간·배치 adapter

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-spatial-placement-adapter`
- 기준 브랜치 및 SHA: `codex/v122-building-compatibility@a7f0642c88712266d34714b48953ce765c8128bb`
- 기능 커밋 SHA: `e3e5a181d0319d80859980e1bb12692cc50392b1`
- 원격 푸시 여부: 미푸시

## 2. 완료한 작업

- `V122BattlePlanAdapter`가 현재 제품 ModuleGraph에서 layout ID·fingerprint, room, corridor, route, 목표, slot, placement, world anchor와 combat bounds를 만든다.
- 실제 외부 적 진입점에서 왕좌까지의 socket route를 사용한다. DAY 1~5는 4개 방어 구간, 이후는 route 길이에 따라 3~6개로 구성한다.
- `V122PlacementSlotAdapter`가 제품 room 수용량과 object slot을 시설·몬스터 배치 view model로 바꾼다.
- 관리에서 지정한 monster room이 전투 spawn·home anchor를 결정하며 동일 입력을 재생성하면 fingerprint와 placement가 같다.
- Stage 1~4 확장과 user custom layout을 동일 adapter로 지원한다.
- 별도 v20 지도와 zone translation table을 추가하지 않았다.

## 3. 변경 파일

| 경로 | 목적 |
|---|---|
| `scripts/v122/spatial/V122BattlePlanAdapter.gd` | 제품 ModuleGraph 기반 전투 snapshot |
| `scripts/v122/spatial/V122DefenseSegmentBuilder.gd` | 실제 route 기반 3~6개 방어 구간 |
| `scripts/v122/spatial/V122PlacementSlotAdapter.gd` | 시설·몬스터 slot과 placement view model |
| `tools/tests/V122SpatialPlacementTest.gd` | Stage 1~4·저장 재생성·custom layout 검증 |
| `tools/tests/core_verification_suite.json` | P3 검사를 Quick·Full에 등록 |
| `docs/design/v122/V122_COMBAT_TRANSPLANT_MATRIX.md` | P3 이식 결과 |
| `docs/handoff/CURRENT.md` | 다음 P4 진입점 |

## 4. 자산

- 신규·변경 그래픽, 오디오, LFS runtime asset: 없음
- Godot import가 만든 metadata 변경은 검증 뒤 기존 상태로 복원했다.

## 5. 테스트 및 검수

| 방법 | 결과 |
|---|---|
| `V122SpatialPlacementTest.tscn` 직접 실행 | PASS |
| Stage 1~4 ModuleGraph validation | PASS |
| 저장 입력 재생성 fingerprint·placement | PASS |
| user custom layout 명시 지원 | PASS |
| `RunCoreVerification.ps1 -Mode Quick` | PASS, 74/74 |
| suite JSON parse·`git diff --check` | PASS |
| repository policy | PASS |
| 전체 회귀 Full·전체 플레이 | NOT_RUN, RC 이전 정책에 따라 제외 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: e3e5a181d0319d80859980e1bb12692cc50392b1
- Review range: a7f0642c88712266d34714b48953ce765c8128bb..e3e5a181d0319d80859980e1bb12692cc50392b1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 다음 작업

1. P4 command·facility·monster·enemy rule adapter와 battle ledger를 구현한다.
2. P3 snapshot의 실제 room·anchor에서만 효과가 적용되도록 한다.
3. DAY 1 fixture의 명령·배치 인과와 관련 Quick·policy를 검증한다.
