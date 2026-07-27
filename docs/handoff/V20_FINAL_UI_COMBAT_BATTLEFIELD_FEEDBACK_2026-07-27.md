# 제품 2.0 최종 UI 전투 전장·HUD 피드백 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-room-route`
- 세션 기준 SHA: `3d97313afae00de95763f071d495448a57bb38e7`
- 기준 브랜치 및 SHA: `release/v2.0@9e96a0901070694d784f6196d01a74b661775f3f`
- 마지막 코드·테스트 커밋 SHA: `065e2034981c94cb92497a64ed7eba630ec0486d`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 전투 화면에서 침입 경로와 방별 방어 의도를 확실히 읽을 수 있는 맵을 구현하고, 전장을 압도하던 HUD를 단순화한다.
- 완료 조건: 1920×1080과 1280×720에서 전장이 화면의 주 시각 요소가 되고, `성문 전초 → 가시 회랑 → 중앙 전투실 → 왕좌 전실 → 왕좌`가 맵 위에서 방향과 상태로 읽히며, 캐릭터와 명령 UI가 식별 가능해야 한다.
- 범위에서 제외한 사항: 전투 밸런스, spawn, HP/ATK, AI 이동·표적·공격, 배치 규칙, 신규 그래픽·오디오 자산, 전체 회귀·전체 플레이·별도 검수 에이전트, build·배포·태그·Release.

## 3. 완료한 작업

- 전장 자동 프레이밍: 고정 `960×540`, 배율 1.0 카메라 대신 실제 다섯 전투 구역의 bounds를 계산해 해상도별로 자동 확대·중앙 정렬한다. 1920×1080에서는 방어 동선이 화면 폭을 사용하고 1280×720에서는 전체 핵심 경로를 보존한다.
- 전투 의도 표현: 흐린 방 사각형과 가는 붉은 선을 제거했다. 어두운 받침 위에 굵은 방향 경로, 1~4 번호, 왕좌 목표, 현재 구역 금색, 돌파 구역 적색, 대기 구역 회색을 표시한다.
- 현재 교전 강조: 현재 구역만 원형 광원과 `구역·상태·수비 대 침입 수` 요약을 노출한다. 요약은 유닛 이름·HP와 겹치지 않도록 방 상단 바깥에 연결선과 함께 배치한다.
- 캐릭터 가독성: 수비 몬스터는 녹색, 침입 적은 적색 반원형 지면 표식으로 진영을 즉시 구분한다. 전투 카메라 확대와 함께 기존 캐릭터·이름·HP도 더 크게 보인다.
- HUD 단순화: 상단 상태 높이, 배속 폭, 방어 단계 높이, 위협 패널 크기를 줄였다. 하단 명령 바는 전체 폭에서 최대 980px 중앙 바 형태로 줄이고 정상 상태의 반복 `사용 가능` 문구를 제거했다.
- 대상 선택·피드백: 기존 명령 기능은 유지하면서 대상 안내와 성공/실패 toast를 더 작게 만들었다.
- 스토리·데이터·밸런스·저장: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | 해상도별 전장 프레이밍, 방향 경로·방 번호·현재 교전·진영 표식 | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 상단·단계·위협·배속·명령·대상 안내 HUD 단순화 | 완료 |
| `tools/tests/V20InformationArchitectureTest.gd` | 간결 HUD 최대 폭·높이와 정상 상태 문구 생략 계약 | 완료 |
| `tools/tests/V20TacticalCommandsTest.gd` | 단순화한 기본 명령 문구와 기존 기능 계약 | 완료 |
| `tools/tests/V20OnboardingRetrySaveTest.gd` | 실제 전장 자동 배율과 1920×1080·1280×720 GPU 캡처 | 완료 |
| `docs/handoff/V20_FINAL_UI_COMBAT_BATTLEFIELD_FEEDBACK_2026-07-27.md` | 구현·검증·미해결 사항 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 단일 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: 기존 마왕성 맵·유닛 자산 재사용
- 프롬프트/후처리/크롭/알파 처리 요약: 신규 자산·후처리 없음
- 게임 연결 및 실제 렌더 확인 결과: 기존 맵을 카메라 프레이밍과 런타임 draw overlay로 재구성해 1920×1080·1280×720에서 확인

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20InformationArchitectureTest.tscn` headless | PASS, 118 assertions | 1280×720·1366×768·1920×1080 간결 HUD 구조 |
| 2 | `V20TacticalCommandsTest.tscn` headless | PASS, 29 assertions | 네 명령·비용·대상 선택·실패 불변·cooldown |
| 3 | `V20FinalUIFlowSmokeTest.tscn` headless | PASS, 22 assertions | 배치→전투→명령→결과 기본 흐름 |
| 4 | `V20OnboardingRetrySaveTest.tscn -- --capture-v20-combat-root`, Windows Vulkan | PASS, 64 assertions | 실제 GameRoot 카메라·전장·명령·재도전 |
| 5 | 1920×1080 실제 렌더 육안 확인 | PASS | `.godot/v20-combat-rework-render-appdata-3/.../v20_combat_battlefield_1920x1080.png` |
| 6 | 1280×720 실제 렌더 육안 확인 | PASS | `.godot/v20-combat-rework-render-appdata-3/.../v20_combat_battlefield_1280x720.png` |
| 7 | `git diff --check` | PASS | 공백 오류 0건 |
| 8 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | U0 계약에 따라 F1 전 실행하지 않음 |

Windows 실행의 `Failed to read the root certificate store`는 네트워크를 사용하지 않는 로컬 테스트 시작 시 출력되는 환경 경고이며, 각 테스트와 캡처는 정상 완료했다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| - | NOT_REQUESTED | 전투 전장·HUD 피드백 수정 | `065e2034981c94cb92497a64ed7eba630ec0486d` | N/A | N/A | 직접 관련 자동 테스트와 실제 GPU 렌더 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 사용자 요청이 없었고 F1 전 금지다.
- PASS 이후 기능·데이터·자산 변경 여부: 0건. Reviewed SHA 뒤에는 이 handoff와 `CURRENT.md`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 065e2034981c94cb92497a64ed7eba630ec0486d
- Review range: 3d97313afae00de95763f071d495448a57bb38e7..065e2034981c94cb92497a64ed7eba630ec0486d
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 실제 전투가 시작되면 동일 방의 유닛 수에 따라 기존 이름 Label이 가까워질 수 있다. 이번 수정은 카메라 확대와 진영 지면 표식으로 식별성을 높였지만, AI anchor·유닛 Label 배치 자체는 동결 범위라 변경하지 않았다.
- 플레이어의 마우스 휠 확대/축소는 기존대로 동작한다. 창 크기가 바뀌면 경로 프레이밍으로 다시 맞춘다.
- 신규 전투 아트가 아니라 기존 맵의 구도와 표시 위계를 고친 변경이다.
- 빌드·배포·후보 hash 갱신은 수행하지 않았다.

## 8. 다음 작업 순서

1. 사용자가 실제 후보에서 전투 흐름과 캐릭터 식별성을 확인한다.
2. 추가 수정 요청이 있으면 전투 표시 범위 안에서 조정하고 새 source SHA·실제 캡처를 만든다.
3. 명시적 `V20_UI_OWNER_ACCEPTED` 전에는 정식 출시선 이식 P0를 시작하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 문서 종료 변경만 존재
- 미커밋 파일: 이 handoff와 `docs/handoff/CURRENT.md`
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: `v20-u0`
- 빌드/캡처 산출물 위치: `.godot/v20-combat-rework-*-appdata*`, Git 미추적·미커밋

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 실제 렌더 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료 — 요청되지 않음
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료 — 신규 자산 없음
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 코드·테스트 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 — 요청되지 않아 수행하지 않음
