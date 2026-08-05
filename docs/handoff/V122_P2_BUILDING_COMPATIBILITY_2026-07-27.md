# v1.2.2 P2 건물 호환

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-building-compatibility`
- 기준 브랜치 및 SHA: `codex/v122-source-audit@1ffc81dc19d8e3f1056bcd541811721c1d6ceb7b`
- 기능 커밋 SHA: `9090f1c7048fb2ebdeaa95dc590f7ba69440bf0a`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 1.2.1 제품의 건물 ID, room blueprint, object, stage sprite, facing, slot과 전투 대상·결산 연결을 하나의 호환 계약으로 검증한다.
- 기존 제품 prop을 우선 사용하고 v20 시험용 건물 ID나 신규 그래픽을 제품 건물로 등록하지 않는다.
- 출시 금지 상태인 누락 object, label-only, 잘못된 anchor·facing, 클릭·대상·저장 불일치를 0으로 만든다.

## 3. 완료한 작업

- `V122BuildingCompatibilityAdapter`가 제품 room, 실제 배치 module, asset manifest를 읽어 건물별 호환 descriptor를 만든다.
- entrance, throne, barracks, recovery, treasure, build slot, watch post, heart chamber, ward core를 제품 ID와 기존 runtime asset에 연결했다.
- heart chamber는 기존 heart sheet 전용 renderer를 유지하고 ward core는 foundation prop의 stage별 NW override를 사용한다.
- v20 barricade와 watch post 명칭은 각각 제품 entrance와 watch post role alias로만 해석하며 저장 ID를 만들지 않는다.
- 기본, 선택, 발동, cooldown, 공병 목표, 무력화, 손상, 파괴 상태의 단일 판정을 추가했다.
- 기존 `watch_post`의 pressure room, slow, bonus damage, 공병 목표, 무력화 timer와 결과 통계 연결을 감사표에 확정했다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `scripts/v122/buildings/V122BuildingCompatibilityAdapter.gd` | 제품 건물 descriptor·alias·상태 판정 |
| `tools/tests/V122BuildingCompatibilityTest.gd` | 건물 ID·object·sprite·facing·대상·상태 검증 |
| `tools/tests/V122BuildingCompatibilityTest.tscn` | 관련 Godot test scene |
| `tools/tests/core_verification_suite.json` | P2 검사를 Quick·Full catalog에 등록 |
| `docs/design/v122/V122_BUILDING_COMPATIBILITY_MATRIX.md` | P2 폐쇄 결과와 금지 상태 0 기록 |
| `docs/handoff/CURRENT.md` | 다음 P3 진입점 |

## 5. 그래픽 및 오디오 자산

- 신규 자산: 없음
- 기존 runtime asset 내용 변경: 없음
- LFS hydration과 Godot import가 만든 작업 사본 변경은 검증 뒤 포인터·기존 import metadata로 복원했다.

## 6. 테스트 및 검수

| 순서 | 방법 | 결과 |
|---:|---|---|
| 1 | `V122BuildingCompatibilityTest.tscn` 직접 실행 | PASS |
| 2 | `RunCoreVerification.ps1 -Mode Quick` | PASS, 73/73 |
| 3 | 기존 `QuarterModuleSmokeTest`·`EngineerPerformanceSmokeTest` | PASS, Quick에 포함 |
| 4 | suite JSON parse·`git diff --check` | PASS |
| 5 | repository policy | PASS |
| 6 | 전체 회귀 Full·전체 플레이 | NOT_RUN, RC 이전 정책에 따라 제외 |

Quick 최초 시도는 Codex 호스트의 `Path`/`PATH` 중복과 샌드박스의 `user://logs` 쓰기 제한으로 실행 환경에서 중단됐다. 프로세스 범위 환경 키만 정규화하고 Godot 사용자 로그 쓰기를 허용한 재실행에서 73/73을 통과했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 9090f1c7048fb2ebdeaa95dc590f7ba69440bf0a
- Review range: 1ffc81dc19d8e3f1056bcd541811721c1d6ceb7b..9090f1c7048fb2ebdeaa95dc590f7ba69440bf0a
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 건물 자체의 제품 연결은 폐쇄했다. P3에서 같은 ModuleGraph 좌표를 관리와 전투 계획이 공유하는지 별도로 고정해야 한다.
- 실제 Windows·Web 시각 비교와 사용자의 전 건물 수동 클릭 확인은 최종 RC 검수 항목이다.

## 8. 다음 작업 순서

1. P3 `V122BattlePlanAdapter`에서 ModuleGraph snapshot을 전투 room·object·spawn 좌표로 변환한다.
2. 실제 연결 socket을 따라 방어 구간을 만들고 관리 배치와 전투 좌표의 일치를 검증한다.
3. 관련 spatial test, Quick, repository policy만 실행한다.

## 9. 종료 체크리스트

- [x] 제품 건물 ID·object·stage sprite·facing descriptor
- [x] 공병 목표·시설 명령·무력화·결산 계약
- [x] v20 시험용 건물 저장 ID 0
- [x] 건물 출시 금지 상태 0
- [x] 관련 test·Quick·policy 통과
- [x] 신규 그래픽·오디오 0
