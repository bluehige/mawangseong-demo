# 제품 2.0 Phase 3 직접 배치 UX 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p03-placement-ux`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `e6af3e18591f5956689db4864623ec512391dc92`
- 마지막 제품 커밋 SHA: `b81bbce9842ba6c40376cb9ced697e8e1108bdc5`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #47

## 2. 이번 세션 목표

- 요청 사항: 시설과 몬스터 배치를 짧고 안전한 직접 조작으로 다시 만든다.
- 완료 조건: 신규 시설 2동작 즉시 설치+Undo, 파괴 교체 3동작, 몬스터 drag 1동작과 click→click 대체 입력, 저장 왕복.
- 범위에서 제외한 사항: weighted path, 시설 전략 수치, 실제 전투 AI, 모바일, 신규 자산.

## 3. 완료한 작업

- 구현: `GameRoot.gd`와 분리된 순수 placement state/service, 공간형 placement board, drag source와 room drop target을 추가했다.
- 스토리 및 데이터: Phase 3 입력·interaction·Undo 정책을 `data/v20/placement_rules.json`에 고정했다.
- 밸런스: 시설 비용은 테스트 fixture뿐이며 실제 수치는 Phase 5·9에서 정한다.
- UI/UX: 왼쪽 roster, 중앙 직접 room 배치, 선택 시에만 오른쪽 유효 시설 palette를 노출한다.
- 저장 및 호환성: 시설·몬스터·건설 자원은 JSON 왕복하며 임시 선택·pending·Undo는 저장 payload에서 제외한다. 1.2 저장은 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/placement_rules.json` | 상호작용 수와 입력 계약 | 완료 |
| `scripts/v20/placement/V20PlacementService.gd` | 설치·교체·Undo·drag·click-click·저장 state | 완료 |
| `scripts/v20/placement/V20PlacementBoard.gd` | PC 공간 배치 UI | 완료 |
| `scripts/v20/placement/V20MonsterDragButton.gd` | 초상 drag source | 완료 |
| `scripts/v20/placement/V20PlacementRoomButton.gd` | 방 drop target | 완료 |
| `scenes/v20/placement/V20PlacementBoard.tscn` | placement scene | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 중앙 전략 workspace 장착 경계 | 완료 |
| `scripts/core/DataRegistry.gd` | placement rule 별도 로드 | 완료 |
| `tools/tests/V20PlacementUxTest.*` | 계약·UI·저장·렌더 검증 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 기존 v2 HUD 색·폰트만 재사용했다.
- 게임 연결 및 실제 렌더 확인 결과: placement board 1280×720 캡처를 `user://`에 생성하고 roster·지도·palette 분리를 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20PlacementUxTest.tscn` headless | PASS, 29 assertions | 설치·교체·Undo·drag·click-click·JSON |
| 2 | 동일 test OpenGL `--capture-v20-placement` | PASS, 30 assertions | `user://v20_phase3_placement_1280x720.png` |
| 3 | 실제 1280×720 캡처 육안 확인 | PASS | roster·room map·facility palette |
| 4 | `V20InformationArchitectureTest.tscn` | PASS, 33 assertions | Phase 2 HUD 회귀 |
| 5 | `DemoSmokeTest.tscn` | PASS | 기존 부팅 회귀 |
| 6 | JSON parse, `git diff --check` | PASS | 변경 파일 |
| 7 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `b81bbce9842ba6c40376cb9ced697e8e1108bdc5` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: b81bbce9842ba6c40376cb9ced697e8e1108bdc5
- Review range: e6af3e18591f5956689db4864623ec512391dc92..b81bbce9842ba6c40376cb9ced697e8e1108bdc5
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: Phase 10 v2 session이 placement state를 실제 저장에 연결해야 한다.
- 밸런스 관찰 항목: 실제 시설 비용·배치 정원은 Phase 5·9에서 결정한다.
- 임시 구현 또는 대체 자산: room node는 전략 동작 검증용 UI이며 기존 쿼터뷰 연결은 Phase 4 범위다.
- 외부 환경/도구 제약: 모바일 drag UX는 연기했다.

## 8. 다음 작업 순서

1. Phase 4에서 두 경로·두 방어선 board와 weighted path 서비스를 추가한다.
2. 문·시설·위험·적 역할·목표 선호 6개 비용 항을 경로 결과에 실제 반영한다.
3. 최소 세 배치가 서로 다른 경로 또는 첫 교전 위치를 만드는 고정 seed 검사를 통과한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 의도한 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `user://v20_phase3_placement_1280x720.png` (커밋 안 함).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 실제 1280×720 렌더 확인
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
