# v1.2.2 UI 단순화 S00~S09 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-28
- 목표 버전: 마왕성 v1.2.2 사용자 QA 후보
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-release-readiness` / `321d56afe264488bb85593d2d1954b092d80532e`
- 구현 커밋 SHA: `d7f5051b4adda50f85aa26553c5dc2b1471f330f`
- 원격 푸시: `origin/codex/v122-ui-simplification`
- QA Web 저장소: `bluehige/mawangseong-web-playtest`
- 최신 QA 채널: `v122-ui-s09-day2-overlay-playtest`
- QA Web 배포 PR: [#15](https://github.com/bluehige/mawangseong-web-playtest/pull/15)
- 최신 빌드만 유지하는 정리 PR: [#16](https://github.com/bluehige/mawangseong-web-playtest/pull/16)
- 공개 주소: https://bluehige.github.io/mawangseong-web-playtest/
- 정식 출시 태그: 생성하지 않음

## 2. 이번 작업 목표

- 사용자 피드백에 따라 v1.2.2 관리·전투 UI를 PC 기준으로 단순화한다.
- 카드와 확인 창을 반복해서 거치지 않고 지도와 전장에서 직접 대상을 선택하게 한다.
- 전체 지침, 방 지침, 전술 명령의 역할과 실제 AI 동작을 분리한다.
- 성 구조 편집 버튼, 배치 화면의 이전 전투 액터 등 현재 흐름에 필요 없는 요소를 제거한다.
- DAY 1~2 튜토리얼이 실제 클릭 대상을 가리지 않도록 레이어와 배치를 바로잡는다.
- 사용자 직접 최종검수 전까지 최신 PC Web QA 빌드를 제공한다.

범위에서 제외:

- 모바일 Web 빌드
- 정식 Windows/Steam 후보 배포
- 출시 태그와 GitHub Release
- 사용자 요청 이후의 전체 회귀·검수 에이전트 실행

## 3. 완료한 작업

### 관리 UI

- 시설 카드와 몬스터 카드를 화면에 전부 펼쳐놓던 구조를 제거했다.
- 지도에서 방을 선택하면 해당 방에서 교체 가능한 시설 목록이 문맥 패널에 표시된다.
- 몬스터는 초상 이미지 중심의 가로 로스터로 표시하고 지도 슬롯으로 직접 드래그해 배치한다.
- 배치 화면에서는 이전 전투의 몬스터 액터와 효과 노드를 숨겨 배치 표식과 겹치지 않게 했다.
- 현재 사용하지 않는 `성 구조 편집` 버튼을 관리 하단 메뉴에서 제거했다.
- 침입 정보, 배치, 전투 시작 전 확인, 결과 화면의 정보 우선순위를 정리했다.

### 지침과 전술 명령

- DAY 01 전체 지침은 `사수`가 이미 적용된 고정 기본값으로 표시하며 다시 선택시키지 않는다.
- 전체 지침의 `총공격`과 선택 방의 `기본`·`후퇴선 유지`를 별도 범위와 설명으로 구분했다.
- 집결·집중 공격·비상 후퇴 등 전술 명령은 버튼을 누른 뒤 전장 위 유효 대상이 강조된다.
- 별도 확인 창 없이 강조된 방·시설·적을 클릭하는 즉시 명령이 발동한다.
- 명령 결과를 `V122CommandService`와 실제 몬스터 이동·전투 AI에 연결했다.
- 전투 상세는 건물 설명 대신 선택한 아군 몬스터 또는 적의 전투 정보를 표시한다.

### 지도와 이동

- 입구에서 왕좌까지의 필수 연결 경로를 실제 walk-cell과 방 그래프에 연결했다.
- 복도형 방 판정과 순찰 경로를 추가해 두 명 이상 배치된 몬스터가 좁은 지점에서 왕복하지 않고 긴 복도를 순환하도록 했다.
- 몬스터 배치 슬롯과 실제 이동 가능 영역의 연결을 보정했다.

### 튜토리얼과 레이어

- 튜토리얼 오버레이를 관리 상세 서랍보다 위에 표시하되 입력 대상은 막지 않도록 구성했다.
- DAY 2 `가시 복도` 단계에서 안내 패널의 상세 서랍 회피 정렬이 노란 클릭 표식을 덮던 문제를 수정했다.
- 가시 복도 노란 표식과 안내 패널 사이를 분리하고, 방 클릭 즉시 기존 안내를 제거한 뒤 `함정 유도` 단계로 전환한다.
- 고블린 단계는 별도 명령을 강요하는 절차가 아니라 기본 AI와 집중 명령의 차이를 설명하는 관찰 단계로 정리했다.

### 저장·결과·호환성

- 새 관리·전투 상태와 명령 기록을 저장·복원 경로에 반영했다.
- 결과 화면의 성장·전투 요약을 간소화하고 DAY 1~3 진행 계약을 유지했다.
- QA용 Windows export preset은 설정으로만 유지하며 이번 요청에서는 Windows 빌드를 생성하지 않았다.

## 4. 주요 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | 화면 전환, 튜토리얼 오버레이, 직접 대상 선택, 저장 연결 | 구현 완료 |
| `scripts/game/ManagementSceneController.gd` | 문맥형 시설 교체, 몬스터 드래그 로스터, 하단 메뉴 단순화 | 구현 완료 |
| `scripts/game/CombatSceneController.gd` | 전장 명령 대상 선택과 아군·적 상세 정보 | 구현 완료 |
| `scripts/ui/HUDController.gd` | 공통 지침·버튼·상세 UI와 레이어 정리 | 구현 완료 |
| `scripts/dungeon_quarter/ModuleGraph.gd` | 복도 판정과 장거리 순찰 경로 | 구현 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 지도 대상·명령·배치 시각 표시 | 구현 완료 |
| `scripts/v122/combat/V122CommandService.gd` | 실제 명령 발동과 AI 이동 효과 | 구현 완료 |
| `scripts/v122/combat/V122BattleLedger.gd` | 전술 명령 기록 | 구현 완료 |
| `scripts/v122/spatial/V122PlacementSlotAdapter.gd` | 배치 슬롯과 이동 영역 연결 | 구현 완료 |
| `scripts/v122/ui/V122ManagementViewModel.gd` | 관리 화면 표시 데이터 단순화 | 구현 완료 |
| `scripts/v122/ui/V122CombatResultViewModel.gd` | 전투 결과 정보 단순화 | 구현 완료 |
| `data/v122/command_rules.json` | 전술 명령 정의와 대상 계약 | 구현 완료 |
| `data/onboarding_flow_dialogue_v0.4.json` | DAY 1~3 튜토리얼 안내 문구·단계 | 구현 완료 |
| `export_presets.cfg` | PC Web과 QA export 설정 | 구현 완료 |
| `tools/tests/V122*Test.*` | 변경 기능의 직접 영향 검사 계약 | 추가·갱신 |
| `tools/V122Day02VisualCapture.*` | DAY 2 화면 재현 도구 | 추가 |

## 5. 그래픽 및 오디오 자산

- 신규 이미지 생성: 없음
- 신규 오디오 생성: 없음
- 기존 마왕성 UI 프레임, 초상, 방·몬스터 이미지를 재사용했다.
- 이번 커밋에는 대량 자동 갱신된 `.import` 파일을 포함하지 않았다.

## 6. 테스트 및 검수 기록

사용자가 이 핸드오프 요청에서 검수를 실행하지 말라고 지시했으므로 추가 검수는 수행하지 않았다.

| 순서 | 명령 또는 방법 | 결과 | 비고 |
|---:|---|---|---|
| 1 | S09 전 `TutorialFlowSmokeTest.tscn` | PASS | 가시 복도 표식 비가림과 클릭 후 `함정 유도` 전환 포함 |
| 2 | Godot 4.5.2 `Web` export | PASS | `tmp/v122_ui_s09_web/` |
| 3 | GitHub Pages S09 배포 | 완료 | QA PR #15, merge `5a6f2078e16278537929d4cc6553f43b0beaa9d0` |
| 4 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 이번 요청에서 실행하지 않음 |
| 5 | 사용자 최종검수 | PENDING | 공개 PC Web에서 사용자가 직접 진행 |

- S09 PCK 크기: `242,757,652`바이트
- S09 PCK SHA-256: `d76ffc00d8afe4874699ea5986d242353913b00b4b4d1397d97c82cfad79eea4`
- S09 WASM SHA-256: `6ead2ac528d007fe9627aae650444f9187f89420d7603c22460d8f3279545240`

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: d7f5051b4adda50f85aa26553c5dc2b1471f330f
- Review range: 321d56afe264488bb85593d2d1954b092d80532e..d7f5051b4adda50f85aa26553c5dc2b1471f330f
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

`TARGETED_PASS`는 이미 수행한 직접 영향 검사만 뜻한다. 전체 회귀나 사용자 최종검수 PASS를 뜻하지 않는다.

## 7. QA 빌드 보관 상태

- 공개 QA 저장소에는 루트의 S09 PC Web 빌드만 유지한다.
- 과거 `v20-p11`, `v20-p11r`, `v20-p11s`, `v20-p11t` 디렉터리는 QA PR #16에서 제거했다.
- 삭제한 구빌드는 Git 이력에서 복구할 수 있다.
- 로컬 QA export도 `tmp/v122_ui_s09_web/`만 유지하고 S08 export는 삭제했다.
- 모바일 Web 및 Windows QA 산출물은 이번 최신 QA 저장소에 포함하지 않는다.

## 8. 미해결 항목과 위험

- 사용자 최종검수가 아직 남아 있다.
- 소스 작업공간에는 Godot가 자동 갱신한 `.import` 파일과 기존 스크립트의 미추적 `.uid`가 남을 수 있으며 구현 커밋에서는 제외했다.
- 현재 QA 빌드는 `local-working-tree-candidate` 출처로 생성됐다. 정식 출시 전에는 사용자 PASS 이후 고정 커밋에서 새 후보를 export해야 한다.
- 모바일 Web은 의도적으로 이번 범위에서 제외됐다.

## 9. 다음 작업 순서

1. 사용자가 공개 S09 PC Web에서 DAY 1~2 관리·전투·튜토리얼을 직접 확인한다.
2. FAIL 피드백이 있으면 `d7f5051b4adda50f85aa26553c5dc2b1471f330f` 기준으로 해당 화면만 수정하고 QA 루트 빌드를 교체한다.
3. 사용자 PASS 뒤에만 전체 회귀, 고정 SHA 후보 export, 태그, Release를 진행한다.

## 10. 종료 체크리스트

- [x] S00~S09 구현 커밋 고정
- [x] 최신 S09 PC Web QA 빌드 공개
- [x] 구 QA 빌드 제거
- [x] 모바일·Windows QA 빌드 제외
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 사용자 요청에 따라 추가 검수 생략
- [ ] 사용자 최종검수
- [ ] 정식 후보 SHA 고정 및 출시 절차
