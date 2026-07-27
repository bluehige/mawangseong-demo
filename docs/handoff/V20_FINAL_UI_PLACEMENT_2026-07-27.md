# 제품 2.0 최종 UI U2 배치 화면 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-placement`
- 기준 브랜치 및 SHA: `release/v2.0@ee2caf96b34651b55e1afffd652f45bd3c03facf`
- Reviewed SHA: `c5a29a335bd607652f7dde255bb88fbb3b633304`
- 마지막 커밋 SHA: handoff·`CURRENT.md` 종료 커밋 전 기준 `c5a29a335bd607652f7dde255bb88fbb3b633304`
- 원격 푸시 여부: 작성 시점 미푸시
- 관련 PR 또는 태그: U2 PR 생성 전, 태그·Release 변경 없음

## 2. 이번 세션 목표

- 요청 사항: `V20_FINAL_UI_RELEASE_TRANSPLANT_PLAN.md`의 U2에 따라 중앙 고정 지도, 오른쪽 시설·몬스터 카드, 하단 상태·되돌리기·방어 시작으로 배치 화면을 최종화한다.
- 완료 조건: 시설 설치·교체·이동·제거·Undo와 몬스터 이동을 직접 조작할 수 있고, drag 중 유효·비유효 슬롯을 구분하며, 잘못된 drop은 상태를 바꾸지 않고 사용자 문장으로 이유를 표시한다.
- 범위에서 제외한 사항: 전투 HUD, 결과 화면, 밸런스·AI·spawn·HP/ATK·시설/몬스터 효과, 신규 콘텐츠·자산, 전체 회귀·전체 플레이·별도 검수 에이전트, build·배포·태그·Release.

## 3. 완료한 작업

- 중앙 지도: 확정 침입로와 4개 배치 구역의 위치를 고정했다. 구역 선택 전후 지도 rect는 변하지 않으며 상시 대형 inspector를 노출하지 않는다.
- 시설 카드: 이름·건설 비용·한 줄 효과·drag affordance를 카드에 직접 표시했다. drag 중 설치 가능한 슬롯만 금색으로 강조하고, 같은 시설·자원 부족·배치 불가 구역은 흐리게 표시한다.
- 시설 행동: 새 설치, 한 번만 나타나는 교체 확인, 선택 시설 이동·제거·교체 안내, 하단 되돌리기를 기존 `V20PlacementService` 상태 계약에 연결했다.
- 몬스터 카드: 초상·이름·한 단어 역할·현재 위치·drag affordance를 표시했다. 이동 직후 카드 위치와 지도 몬스터 토큰을 같은 상태에서 다시 그린다.
- 오류 피드백: 잘못된 drop 전후 직렬화 fingerprint가 같도록 유지하고, 지도 하단 toast에 거부 이유를 한국어 사용자 문장으로 표시한다.
- 하단 행동: `배치 상태 → 되돌리기 → 방어 시작` 순서로 정리했다. 방어 시작은 유일한 주 행동이며, 차단 시 첫 오류를 `임프를 몬스터 슬롯에 배치하세요.` 같은 문장으로 즉시 갱신한다.
- 밸런스 및 콘텐츠: 변경 없음. 기존 시설 비용·효과, 몬스터 능력, 적 구성, 고정 경로와 전투 판정을 그대로 사용한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/v20/placement/V20PlacementBoard.gd` | 고정 지도·카드 도구함·drag 대상·시설 행동·toast·선택 요약 | 완료 |
| `scripts/v20/placement/V20PlacementRoomButton.gd` | 유효·비유효 target 시각 상태와 drop 거부 이유 전달 | 완료 |
| `scripts/v20/placement/V20MonsterDragButton.gd` | 시설·몬스터 카드의 명시적 정보 구조와 공통 최소 글꼴 | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 배치 상태·되돌리기·방어 시작 하단 행동과 실시간 차단 문구 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 배치 변경 검증·되돌리기·HUD 상태 연결 | 완료 |
| `tools/tests/V20PlacementUxTest.gd` | 설치·교체·이동·제거·Undo·drop 불변성·실제 렌더 검증 | 완료 |
| `tools/tests/V20InformationArchitectureTest.gd` | 3해상도 하단 행동·차단 이유·지도 고정 계약 | 완료 |
| `docs/handoff/V20_FINAL_UI_PLACEMENT_2026-07-27.md` | U2 검수 근거와 다음 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업을 U2/U3 기준으로 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: N/A
- 기존 자산 재사용: 고정 마왕성 배경과 기존 몬스터 초상을 그대로 사용
- 신규·수정 그래픽/오디오 asset: 0건

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V20PlacementUxTest.tscn` headless | PASS | 배치 service·UI 42 assertions |
| 2 | `V20InformationArchitectureTest.tscn` headless | PASS | 1280×720·1366×768·1920×1080 IA 100 assertions |
| 3 | `V20OnboardingRetrySaveTest.tscn` headless, 격리 `user://` | PASS | 실제 GameRoot 진행·재도전·저장 56 assertions |
| 4 | `V20PlacementUxTest.tscn -- --capture-v20-ui-placement`, Windows OpenGL | PASS | 초기·drag 강조·drop 거부·시설/몬스터 적용 4개 실제 GPU 렌더, 총 46 assertions |
| 5 | 실제 캡처 육안 확인 | PASS | 1280×720 카드 잘림·겹침·화면 이탈 0건, toast와 하단 행동 위계 확인 |
| 6 | `git diff --check`와 staged 범위 확인 | PASS | Reviewed SHA의 의도한 runtime/test 7개 파일만 포함 |
| 7 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | U0 계약에 따라 F1 전 실행 금지 |

첫 실제 렌더에서 세 번째 몬스터 카드가 선택 요약과 약 5px 겹치는 문제를 발견했다. 시설 영역·간격·요약 높이를 재배분하고 `1280×720 몬스터 카드 3개 최소 높이·선택 요약 비겹침` 단언을 추가한 뒤 headless와 Windows OpenGL 렌더를 다시 통과했다. 로컬 로그와 캡처는 `.godot/`에만 두고 커밋하지 않았다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| - | NOT_REQUESTED | U2 배치 UI | `c5a29a335bd607652f7dde255bb88fbb3b633304` | N/A | N/A | 직접 관련 자동 테스트와 실제 렌더 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 F1 전 실행 금지 항목이다.
- PASS 이후 기능·데이터·자산 변경 여부: 0건. Reviewed SHA 뒤에는 이 handoff와 `CURRENT.md`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: c5a29a335bd607652f7dde255bb88fbb3b633304
- Review range: ee2caf96b34651b55e1afffd652f45bd3c03facf..c5a29a335bd607652f7dde255bb88fbb3b633304
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- drag 대상 판정은 기존 시설 placement tag와 자원 계산을 그대로 사용한다. 모든 현재 방이 같은 허용 tag를 가지므로 비유효 시각 검증은 동일 시설이 이미 설치된 슬롯과 나머지 슬롯의 혼합 상태로 고정했다.
- 배치 차단 문구는 현재 `V20DayFlowService` 오류 키를 사용자 문장으로 매핑한다. 새 오류 키가 추가되면 일반 fallback 문구가 표시된다.
- 밸런스는 동결했다. 기존 PR 4 후보는 F1 전체 검수 전까지 공식 PASS가 아니다.
- source SHA·Windows/Web debug build hash 동결은 U5에서 수행한다.

## 8. 다음 작업 순서

1. U2 PR을 `release/v2.0` 대상으로 열고 원격 `repository-policy` PASS 뒤 merge commit으로 병합한다.
2. U2 merge SHA에서 `codex/v20-final-ui-combat`를 만들고 U3 전투 HUD만 수정한다.
3. U3에서는 목표·구간·다음 패턴·명령 대상·일시정지/속도와 실제 전투 캡처만 직접 검증한다.
4. U3 merge 전 U4를 시작하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: handoff·`CURRENT.md` 종료 변경만 존재
- 미커밋 파일: `docs/handoff/V20_FINAL_UI_PLACEMENT_2026-07-27.md`, `docs/handoff/CURRENT.md`
- 의도하지 않은 기존 변경: U2 worktree에는 없음. 원래 `게임소스/` worktree의 사용자 미추적 파일은 건드리지 않았다.
- 스태시 또는 별도 작업공간: 별도 worktree `v20-u0`
- 빌드/캡처 산출물 위치: `.godot/v20-u2-render-appdata/`와 `.godot/*.log`, Git 미추적·미커밋

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 자동 테스트 통과
- [x] 사용자 요청 범위의 실제 배치 흐름 렌더 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료 — 요청되지 않았고 계획상 F1 전 금지
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료 — 신규 자산 없음
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR 상태 기록
