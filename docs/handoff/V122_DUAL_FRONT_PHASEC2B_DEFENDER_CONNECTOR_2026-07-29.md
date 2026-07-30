# v1.2.2 이중 전선 Phase C-2b 방어자 전용 연결로 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 다음 순서인 DAY 3 방어자 전용 연결로를 구현한다.
- 완료 조건:
  - DAY 3부터 금화 1000·마나 100으로 한 번만 건설할 수 있다.
  - 건설 전에는 A/B 전선이 분리되고, 건설 뒤에는 방어 몬스터만 연결로를 횡단한다.
  - 적의 공용 이동 그래프와 진입 경로는 건설 전후 동일하다.
  - 건설 상태와 DAY가 관리 확정 저장·retry에 보존되며 구저장은 안전한 미건설 상태로 열린다.
- 범위에서 제외한 사항: 후보의 Stage 2~4 room descriptor·시설 socket 이식, 제품 기본값 활성화, 전체 QA·실플레이·밸런스 확정, 빌드·배포.

## 3. 완료한 작업

- 건설 규칙:
  - 후보 레이아웃의 `connector_contract`를 전투 snapshot의 `defender_connector`로 변환한다.
  - DAY 3 이전, 자원 부족, 이미 건설된 상태에서는 구매를 거부한다.
  - DAY 3부터 정확히 금화 1000·마나 100을 차감하며 캠페인 동안 영구 유지한다.
  - 관리 화면의 표준 되돌리기는 같은 관리 세션에서 연결로 상태와 자원을 함께 복구한다.
- 방어자 전용 이동:
  - 연결로를 공용 `ModuleGraph` edge나 공용 walk map에 추가하지 않았다.
  - 방어 몬스터가 반대 전선의 방으로 이동할 때만 입구 지점→연결로 중심→출구 지점을 경로에 삽입한다.
  - 실제 `Unit`의 경로 설정과 매 프레임 바닥 보정도 방어자에게만 연결로 폭을 임시 보행면으로 인정한다.
  - 적은 건설 뒤에도 기존 공용 그래프만 사용하며 연결로 중심으로 보정되거나 횡단하지 않는다.
- 관리 UI와 지도:
  - 추가 작전에 연결로 건설 상태·잠금 DAY·비용·자원 부족 설명을 표시한다.
  - 미건설 연결로는 끊어진 흐린 선과 중심 표식, DAY 3 해금 뒤에는 금색 표식으로 표시한다.
  - 건설 뒤에는 두 구간을 연결한 청록·금색 연결로로 표시한다.
- 저장 및 호환성:
  - 기존 schema version을 올리지 않고 optional `connector_state`를 추가했다.
  - 관리 확정 저장과 일반/최종전 retry가 `connector_id`, `built`, `built_day`를 보존한다.
  - 필드가 없는 구저장과 legacy retry는 미건설 `false`로 정규화한다.
  - 구조 fingerprint는 건설 여부와 독립적이어서 건설 전후 레이아웃 정합성이 유지된다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/v122/spatial/V122BattlePlanAdapter.gd` | 연결로 계약·상태·경로 지점 snapshot | 완료 |
| `scripts/v122/save/V122SaveProgressionAdapter.gd` | optional 연결로 상태·retry·구저장 호환 | 완료 |
| `scripts/game/GameRoot.gd` | DAY·비용·영구 건설·되돌리기·방어자 보행 판정 | 완료 |
| `scripts/game/CombatSceneController.gd` | 방어 몬스터의 전선 간 연결로 경로 합성 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 연결로 추가 작전·잠금·비용·상태 표시 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 미건설·해금·건설 연결로 시각화 | 완료 |
| `scripts/units/Unit.gd` | 유닛별 전투 보행면 보정 hook | 완료 |
| `tools/tests/V122DefenderConnectorTest.gd` | 건설·비용·되돌리기·저장·retry·실제 Unit 경로 검증 | 완료 |
| `tools/tests/V122DefenderConnectorTest.tscn` | 전용 headless 테스트 scene | 완료 |
| `tools/tests/V122DualFrontLayoutContractTest.gd` | 연결로 snapshot·fingerprint 계약 검증 | 완료 |
| `tools/tests/V122EnemyLaneRoutingTest.gd` | 방어자 횡단·적 경로 불변 검증 | 완료 |
| `tools/tests/V122SaveZonePlacementCompatibilityTest.gd` | 연결로 구저장·retry 호환 검증 | 완료 |
| `docs/handoff/V122_DUAL_FRONT_PHASEC2B_DEFENDER_CONNECTOR_2026-07-29.md` | 세션 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 기존 절차형 지도 렌더에 선·표식만 추가했다. 시각·실플레이 검수는 이번 범위에서 요청되지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122DefenderConnectorTest.tscn` | PASS | `.godot/V122DefenderConnectorTest-phasec2b-final.log` |
| 2 | `V122EnemyLaneRoutingTest.tscn` | PASS | `.godot/V122EnemyLaneRoutingTest-phasec2b-final.log` |
| 3 | `V122DualFrontLayoutContractTest.tscn` | PASS | `.godot/V122DualFrontLayoutContractTest-phasec2b-final.log` |
| 4 | `V122SaveZonePlacementCompatibilityTest.tscn` | PASS | `.godot/V122SaveZonePlacementCompatibilityTest-phasec2b-final.log` |
| 5 | `V122SaveProgressionTest.tscn` | PASS | `.godot/V122SaveProgressionTest-phasec2b-escalated.log` |
| 6 | `V122ManagementUIContractTest.tscn` | PASS | `.godot/V122ManagementUIContractTest-phasec2b-final.log` |
| 7 | `V122ManagementInteractionTest.tscn` | PASS | `.godot/V122ManagementInteractionTest-phasec2b.log` |
| 8 | `V122CombatRuleAdapterTest.tscn` | PASS | `.godot/V122CombatRuleAdapterTest-phasec2b.log` |
| 9 | `V122DualFrontDay01To05WaveTest.tscn` | PASS | `.godot/V122DualFrontDay01To05WaveTest-phasec2b.log` |
| 10 | `V122FacilityZoneCombatConsumerTest.tscn` | PASS | `.godot/V122FacilityZoneCombatConsumerTest-phasec2b.log` |
| 11 | `V122Day01To05ParityTest.tscn` | PASS | `.godot/V122Day01To05ParityTest-phasec2b.log` |
| 12 | 직접 영향 파일 `git diff --check` | PASS | 줄 끝 변환 경고만 존재 |
| 13 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 지시에 따라 보류 |
| 14 | 시각/실플레이 검수 | NOT_REQUESTED | 사용자 최종 테스트 전까지 보류 |

Windows root certificate store 읽기 경고는 기존 headless 환경 경고이며 전용 테스트의 종료 코드와 단언 결과에는 영향을 주지 않았다. `V122DefenderConnectorTest` 종료 시 테스트 fixture 정리와 관련된 ObjectDB/resource 경고가 있으나 단언과 종료 코드는 PASS다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | 미커밋 작업 트리 | 전체 검수 미요청 | 직접 영향 계약 테스트만 수행 | 위 테스트 로그 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 회귀·실플레이는 이번 작업의 필수 범위가 아니다.
- PASS 이후 기능·데이터·자산 변경 여부: 핸드오프 문서와 `CURRENT.md`만 변경.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 후보 레이아웃은 아직 제품 기본값이 아니므로 일반 플레이에서는 새 연결로가 활성화되지 않는다.
- 후보 좌표와 기존 Stage 2~4 확장 모듈을 함께 적용하면 `watch_post_01`·`ward_core_01`·`slot_02`와 후보 방/통로 일부가 겹친다.
- 위 충돌은 연결로 기능의 결함이 아니라 후보 전용 room descriptor·확장 socket migration이 아직 없는 문제다. 이를 해결하기 전에는 후보를 제품 기본값으로 활성화하면 안 된다.
- 실제 전투에서 1000골드·100마나의 선택 압력과 방어자 횡단 체감은 사용자 플레이 피드백으로 확정해야 한다.
- 전체 플레이·렌더·빌드는 실행하지 않았다.

## 8. 다음 작업 순서

1. 후보 전용 room descriptor와 Stage 2~4 확장·시설 socket migration을 설계해 기존 확장 모듈과의 좌표 중복을 제거한다.
2. 기존 저장의 Stage 시설·몬스터 배치를 후보의 교체식 시설 slot과 방어구역에 결정적으로 매핑한다.
3. Stage 1~4 재생성·구저장·retry·전선 경로 전용 테스트를 실행한다.
4. 위 조건을 모두 통과한 뒤에만 `stage01_dual_front_candidate_01`의 제품 기본값 활성화를 검토한다.
5. 구조가 고정된 뒤 Stage 01 셀 정합형 그래픽 제작과 캐릭터·배경 융화를 재개한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`에 미커밋 변경이 존재한다.
- 미커밋 파일: 이번 Phase C-2b 구현·테스트·핸드오프 외에 Phase A/B/C-1/C-2a 및 이전 UI·설정 변경이 함께 남아 있다.
- 의도하지 않은 기존 변경: 다수 `.import`와 이전 UI·오디오·설정 변경을 보존했으며 정리하거나 되돌리지 않았다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 없음. 전용 테스트 로그만 `.godot/`에 있다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
