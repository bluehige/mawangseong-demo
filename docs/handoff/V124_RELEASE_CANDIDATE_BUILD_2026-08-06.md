# v1.2.4 정식 후보 Web·Windows 빌드 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: `1.2.4`
- 작업 브랜치: `main`
- 기준 브랜치 및 SHA: `main@5082a86f5a25d098b7f1c040958bd14da703e578`
- 마지막 커밋 SHA: `5082a86f5a25d098b7f1c040958bd14da703e578` (빌드 대상 수정은 미커밋)
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 최근 수정 사항을 `1.2.4` Web과 Windows 정식 후보 빌드에 반영한다.
- 완료 조건: Web·Windows export 성공, Web 대표 화면 부팅 확인, 배포 가능한 ZIP 생성, 검증 제한 사항 기록.
- 범위에서 제외한 사항: 커밋·푸시·태그·GitHub Release, 정상 Godot 런타임이 필요한 전체 회귀와 실제 전투 소유자 검수.

## 3. 완료한 작업

- 구현: `project.godot` 버전을 `1.2.4`로 맞추고 Windows Desktop/QA/Steam export 버전을 `1.2.4.0`으로 맞췄다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음.
- UI/UX: 집결·집중 입력 보정과 관리 몬스터 전경 레이어 수정이 export에 포함됐다.
- 저장 및 호환성: 저장 포맷 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `project.godot` | 제품 버전 `1.2.4` 반영 | 완료 |
| `export_presets.cfg` | Windows export 파일·제품 버전 `1.2.4.0` 반영 | 완료 |
| `scripts/game/CombatSceneController.gd` | 실시간 명령 상태 기반 대상 지정 | 완료 |
| `scripts/game/GameRoot.gd` | 실제 마우스 월드 좌표와 집결 표식 선택 보정 | 완료 |
| `scripts/map/DungeonRenderer.gd` | 관리 화면 몬스터 미리보기 전경 레이어 보정 | 완료 |
| `scripts/ui/HUDController.gd` | 집결·집중 버튼 상태 표시 보정 | 완료 |
| `tools/tests/V122DefenderConnectorTest.gd` | 곱 도둑 추격 회귀 검사 추가 | 검증 대기 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 기존 자산 사용
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: Web 타이틀 화면 및 새 게임 진입 화면을 1280×720에서 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `git diff --check` | PASS | 명령 출력 |
| 2 | Godot `--export-release Web` | PASS | `tmp/v124_release_candidate/web/` |
| 3 | Godot `--export-release "Windows Steam"` | PASS | `tmp/v124_release_candidate/windows/` |
| 4 | Playwright Web 1280×720 부팅 및 `새 게임` 클릭 | PASS | `tmp/v124_release_candidate/playwright/shot-0.png`, `tmp/v124_release_candidate/playwright_new_game/shot-0.png` |
| 5 | Windows 일반 실행 6초 유지 | PASS (smoke) | `tmp/v124_release_candidate/windows/MawangCastle.exe` |
| 6 | Windows headless 실행 | BLOCKED: `0xC0000005` | Godot signal 11 출력 |
| 7 | `V122CommandButtonIntegrationTest.tscn` 직접 실행 | BLOCKED: `0xC0000005` | Godot signal 11 출력 |
| 8 | `V122DefenderConnectorTest.tscn` 직접 실행 | BLOCKED: `0xC0000005` | Godot signal 11 출력 |
| 9 | Full core verification 156개 | BLOCKED | 첫 실행은 Windows `Path`/`PATH` 중복 키, 정리 실행은 Godot 프로세스 충돌/정지로 완료 보고 미생성 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|---|
| 1 | 없음 | 미커밋 작업 트리 | N/A | 런타임 검증 환경의 Godot signal 11 | 정상 Godot 환경에서 재실행 필요 | 본 문서 6절 | BLOCKED |

- 남은 P1/P2 지적: 정상 Godot 환경에서 명령 버튼·도둑 추격·전경 레이어 직접 검증 전까지 출시 판정 보류.
- 실행하지 못한 필수 검수와 이유: Full 회귀 및 직접 Godot 테스트는 격리 Godot `0xC0000005` 충돌로 완료하지 못했다.
- PASS 이후 기능·데이터·자산 변경 여부: 해당 없음. 이번 빌드는 미커밋 작업 트리에서 생성한 후보다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_BLOCKED

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 명령 버튼과 도둑 추격은 직접 Godot 테스트가 충돌해 제품 런타임에서의 최종 체감이 아직 미확정이다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 격리 Godot 4.5.2가 headless 테스트 씬 실행 중 signal 11/Windows `0xC0000005`로 종료했다. 일반 Windows export 프로세스는 6초 유지됐다.

## 8. 다음 작업 순서

1. 정상 Godot 런타임에서 `V122CommandButtonIntegrationTest.tscn`과 `V122DefenderConnectorTest.tscn`을 재실행하고 실패 시 원인별로 수정한다.
2. Web과 Windows를 최종 커밋 SHA에서 재export하고 Full 156개 검증을 완료한다.
3. 검증 SHA·manifest·해시를 고정한 뒤에만 태그·GitHub Release·Pages 배포를 진행한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `main` 기준 작업 트리 dirty.
- 미커밋 파일: 최근 게임 코드·테스트·핸드오프·버전/export 설정. 다수 `.import` 파일은 export 과정의 줄바꿈 상태 표시이며 HEAD와 내용 해시는 동일하다.
- 의도하지 않은 기존 변경: 확인된 기능 파일에는 없음. `.import` 상태 표시는 기존 생성 산출물 상태다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/v124_release_candidate/`

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] Web·Windows export 성공
- [x] Web 대표 화면 부팅 확인
- [ ] 사용자 요청 범위의 실제 전투·관리 검수
- [ ] 전체 회귀·검수 에이전트 완료
- [ ] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료 (신규 자산 없음)
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
