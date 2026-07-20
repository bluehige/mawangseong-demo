# 제품 2.0 Phase 2 PC 정보 구조 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p02-ui-information-architecture`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `7c7cc306b5a78932cfddfd44ac4e7985638c5173`
- 마지막 제품 커밋 SHA: `b52a07c859a38c7ecf9239a5bc684f23046e7a72`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #46

## 2. 이번 세션 목표

- 요청 사항: PC 관리·전투 HUD의 상시 정보를 줄이고 중앙 전장을 주 작업면으로 다시 구성한다.
- 완료 조건: 관리 주 행동 5개 이하, 전투 전술 명령 4개 이하, 1280×720 이상 비겹침, 방·유닛·로그 상세의 컨텍스트 드로어 이동.
- 범위에서 제외한 사항: 모바일 UI, 배치 입력, 실제 명령 효과, 경로·시설·Encounter 수치와 신규 자산.

## 3. 완료한 작업

- 구현: 독립 `V20InformationHUD` scene과 관리·전투 controller의 비활성 v2 진입 훅을 추가했다.
- 스토리 및 데이터: 변경하지 않았다.
- 밸런스: 변경하지 않았다.
- UI/UX: 중앙 작업면, 상단 임무/자원 또는 목표/예고, 하단 단일 action dock, 선택 시에만 여는 오른쪽 drawer로 재구성했다.
- 저장 및 호환성: 저장 계약을 변경하지 않았다. v1.2 런타임은 v2 세션 게이트가 생기기 전까지 기존 HUD를 그대로 사용한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scenes/v20/ui/V20InformationHUD.tscn` | v2 PC HUD 독립 scene | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 반응형 관리·전투 정보 구조와 context drawer | 완료 |
| `scripts/game/ManagementSceneController.gd` | 향후 v2 세션용 관리 HUD 조립 경계 | 완료 |
| `scripts/game/CombatSceneController.gd` | 향후 v2 세션용 전투 HUD 조립 경계 | 완료 |
| `tools/tests/V20InformationArchitectureTest.*` | 3개 해상도 구조·signal·실제 렌더 검증 | 완료 |
| `tools/tests/core_verification_suite.json` | Phase 2 검사를 quick/full 목록에 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 기존 폰트와 색 체계만 재사용했다.
- 게임 연결 및 실제 렌더 확인 결과: 1280×720 관리·전투 캡처를 생성해 상단 문구 경계와 drawer 줄바꿈을 수정한 뒤 다시 확인했다. 캡처는 `user://`에만 두고 커밋하지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20InformationArchitectureTest.tscn` headless | PASS, 33 assertions | 1280×720·1366×768·1920×1080 구조 |
| 2 | 동일 test OpenGL 실제 렌더 `--capture-v20-ui` | PASS, 35 assertions | `user://v20_phase2_*_1280x720.png` |
| 3 | 캡처 육안 확인 후 상단 문구·drawer 수정 및 재렌더 | PASS | 관리·전투 1280×720 |
| 4 | `DemoSmokeTest.tscn` | PASS | 기존 부팅·controller parse |
| 5 | `V20DecisionContractsTest.tscn` | PASS, 21 assertions | Phase 1 계약 회귀 |
| 6 | 전체 회귀 테스트 | NOT_REQUESTED | 관련 검사만 실행 |
| 7 | 전체 실플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `b52a07c859a38c7ecf9239a5bc684f23046e7a72` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. Phase 2 관련 해상도와 실제 렌더를 확인했다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: b52a07c859a38c7ecf9239a5bc684f23046e7a72
- Review range: 7c7cc306b5a78932cfddfd44ac4e7985638c5173..b52a07c859a38c7ecf9239a5bc684f23046e7a72
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: v2 HUD는 실제 세션 게이트가 아직 없어 독립 scene과 controller 훅으로만 존재한다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 전략 보드 중앙은 기존 쿼터뷰가 붙을 자리만 확보했으며 Phase 4 전까지 경로 guide만 표시한다.
- 외부 환경/도구 제약: 모바일은 승인 범위대로 연기했다.

## 8. 다음 작업 순서

1. Phase 3에서 시설 슬롯 클릭→시설 클릭 즉시 설치와 한 단계 Undo state를 별도 service로 구현한다.
2. 몬스터 초상→방 drag를 기본 입력으로, 클릭→클릭을 접근성 대체 입력으로 연결한다.
3. 파괴적 교체만 3동작 확인을 요구하고 저장 왕복 관련 테스트를 통과한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 의도한 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `user://v20_phase2_management_1280x720.png`, `user://v20_phase2_combat_1280x720.png` (커밋 안 함).

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
