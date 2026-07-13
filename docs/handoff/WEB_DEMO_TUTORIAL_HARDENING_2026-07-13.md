# Web 데모 튜토리얼 포커스 재발 방지 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-13
- 목표 버전: v0.3 Web 데모
- 작업 브랜치: `codex/v03-tutorial-overlay-hardening`
- 기준 브랜치 및 SHA: `origin/main` / `13a84506885516cd4c6a79000a3fe81c58a4fec0`
- 마지막 소스·워크플로 커밋 SHA: `994855bf079d4d233c6748bb5f14f5178092c9f9`
- 원격 푸시 여부: 이 문서 작성 시점 미푸시
- 관련 PR 또는 태그: 이 문서 작성 시점 미생성

## 2. 이번 세션 목표

- 실제 선택 방 지시 컨트롤과 무관한 과거 고정 좌표에 튜토리얼 포커스가 표시되는 문제를 제거한다.
- 사용자가 다른 방을 눌렀거나 저장 상태가 어긋나도 현재 튜토리얼에 필요한 방과 실제 컨트롤을 복구한다.
- 수정되지 않은 Web 릴리즈가 다시 배포되지 않도록 산출물과 공개 Pages를 해시로 검증한다.

## 3. 완료한 작업

- 방 지시 튜토리얼 단계마다 필요한 방을 동기화하고 관리 UI를 다시 구성하도록 수정했다.
- 실제 UI 컨트롤이 필요한 튜토리얼 대상에서는 고정 좌표 폴백을 제거했다. 대상 컨트롤이 없으면 오해를 부르는 포커스 오버레이를 표시하지 않는다.
- 클릭 배지 후보 위치를 화면 경계와 메시지 패널·포커스 사각형을 함께 고려하도록 보강했다.
- 선택 방 지시 `OptionButton`에 안정적인 노드 이름을 부여했다.
- 회귀 테스트가 실제 `OptionButton.get_global_rect()`와 포커스 링을 독립적으로 비교하고, 다른 방 선택 복구와 대상 소실 시 폴백 미표시를 검증하도록 확장했다.
- DAY 2 함정 유도 단계를 실제 UI 캡처 검증에 추가했다.
- 레거시 Web 배포가 ZIP SHA-256, 소스 커밋, PCK SHA-256·바이트 크기, HTML 표기 크기를 모두 확인하도록 워크플로를 강화했다.
- 배포 후 공개 Pages의 마커·HTML·PCK 크기와 실제 PCK SHA-256까지 일치해야 성공하도록 했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | 필수 방 동기화, 실컨트롤 없는 포커스 차단, 고정 좌표 제거, 배지 배치 보강 | 완료 |
| `scripts/ui/HUDController.gd` | 선택 방 지시 컨트롤 이름 고정 | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 실제 컨트롤 정렬·방 복구·폴백 제거 회귀 검사 | 완료 |
| `tools/TutorialUxCapture.gd` | DAY 2 함정 유도 실화면 정렬 검사 | 완료 |
| `.github/workflows/deploy-web-demo.yml` | 릴리즈 및 공개 Pages 산출물 핀 검증 | 완료 |

## 5. 그래픽과 오디오 자산

- 신규 이미지 생성: 없음
- 런타임 그래픽·오디오 변경: 없음

## 6. 테스트 및 검증

| 순서 | 검증 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `TutorialFlowSmokeTest.tscn` 헤드리스 실행 | PASS | 함정 유도 실제 컨트롤 정렬, 다른 방 선택 복구, 대상 소실 시 폴백 미표시 포함 |
| 2 | `TutorialUxCapture.tscn` 헤드리스 실행 | PASS | `tmp/tutorial_ux_verification/08_day2_trap_lure_task.png` 육안 확인 포함 |
| 3 | `OnboardingFlowSmokeTest.tscn` 헤드리스 실행 | PASS | 종료 시 기존 ObjectDB·리소스 경고 외 실패 없음 |
| 4 | Godot Web release export | PASS | 정상 종료 코드 0, PCK 181,259,832바이트 |
| 5 | Web PCK SHA-256 및 `index.html` 크기 표기 | PASS | `e8ed913edcdd40289fdf24b765673979c0ba094594e853876ae495cf4106e56b` |
| 6 | 워크플로 YAML 파싱 및 모든 Bash 블록 `bash -n` | PASS | 로컬 정적 검증 |
| 7 | 릴리즈 provenance 단계 로컬 시뮬레이션 | PASS | 핀된 마커·PCK 검증 성공 |
| 8 | 공개 Pages 검증 단계 로컬 HTTP 시뮬레이션 | PASS | 실제 PCK 다운로드 후 SHA-256 검증 성공 |
| 9 | 전체 게임·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위가 버그 수정과 재배포였으므로 관련 검증만 실행 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 994855bf079d4d233c6748bb5f14f5178092c9f9
- Review range: 13a84506885516cd4c6a79000a3fe81c58a4fec0..994855bf079d4d233c6748bb5f14f5178092c9f9
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 이 문서 작성 시점에는 소스 PR 병합, `test/web-v0.3` 산출물 교체, Release 자산 교체와 Pages 재배포가 남아 있다.
- Web export와 로컬 캡처는 소스 브랜치에 추가하지 않는다.

## 8. 다음 작업 순서

1. 소스·배포 가드 PR을 `main`에 merge commit으로 병합한다.
2. `test/web-v0.3`을 최신 `main`과 병합하고 PCK·WASM을 Git LFS로 추적해 새 export를 푸시한다.
3. 핀된 ZIP으로 GitHub Release 자산을 교체하고 Pages 워크플로를 실행한다.
4. 공개 주소의 마커, PCK 해시와 실제 브라우저 로드를 확인한 뒤 이 핸드오프를 배포 결과로 갱신한다.

## 9. 작업 트리 상태

- 의도한 소스 변경은 `a216d8d`, 원격 워크플로 변경은 `994855b`에 커밋했다.
- Godot import 과정에서 생긴 추적 파일 변경은 작업자가 만든 생성 부작용으로 확인해 복구했고, 소스 브랜치에 Web 산출물을 추가하지 않았다.
- 원래 작업공간의 동시 진행 변경은 건드리지 않고 별도 clean worktree에서 작업했다.
