# v1.2.3 정식판 버그 수정본 덮어쓰기 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: `1.2.3` hotfix overwrite
- 작업 브랜치: `codex/v124-release-candidate`
- 기준 브랜치 및 SHA: `main@5082a86f5a25d098b7f1c040958bd14da703e578`
- 마지막 커밋 SHA: `00aa5e4` + 버전 재정렬 커밋 예정
- 원격 푸시 여부: 후보 브랜치 푸시 완료, 정식 태그·Release 교체 진행 중
- 관련 PR 또는 태그: 기존 `v1.2.3`을 사용자 승인으로 이동 예정

## 2. 이번 세션 목표

- 요청 사항: 버그가 남아 있는 기존 정식 `v1.2.3`을 최근 수정본으로 덮어쓰고 기존 GitHub Release·Pages 링크를 갱신한다.
- 완료 조건: 기존 버전 표시 유지, Web·Windows 재export, 기존 Release 자산 교체, 공개 Pages 링크 재배포.
- 범위에서 제외한 사항: 기존 태그·Release 불변 정책. 사용자가 명시적으로 덮어쓰기를 승인했다.

## 3. 완료한 작업

- 구현: 집결·집중 실제 입력 좌표 및 live command 상태, 곱 도둑 추격 우선순위, 관리 몬스터 미리보기 전경 레이어를 반영했다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음.
- UI/UX: 집결·집중 버튼 표시·대상 선택, 몬스터 전경 표시 수정.
- 저장 및 호환성: 저장 포맷 변경 없음.
- 버전: 프로젝트와 Windows 파일/product version을 `1.2.3`으로 재정렬했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `project.godot` | 기존 정식 표시 버전 유지 | 완료 |
| `export_presets.cfg` | 기존 Release 파일명·Windows 버전 유지 | 완료 |
| `scripts/game/CombatSceneController.gd` | 명령 상태와 대상 지정 보정 | 완료 |
| `scripts/game/GameRoot.gd` | 마우스 월드 좌표·집결 표식·도둑 추격 보정 | 완료 |
| `scripts/map/DungeonRenderer.gd` | 관리 몬스터 전경 레이어 보정 | 완료 |
| `scripts/ui/HUDController.gd` | 명령 버튼 live 상태 보정 | 완료 |
| `tools/tests/V122DefenderConnectorTest.gd` | 곱 도둑 추격 회귀 검사 | 검증 대기 |
| `docs/handoff/CURRENT.md` | 정식판 덮어쓰기 상태 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 기존 자산 사용
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: Web export는 이전 후보에서 타이틀·새 게임 진입을 확인했고, 이번 버전 재export가 성공했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `git diff --check` | PASS | 커밋 전 검사 |
| 2 | Godot Web export | PASS | `tmp/v123_hotfix_overwrite/web/` |
| 3 | Godot Windows Steam export | PASS | `tmp/v123_hotfix_overwrite/windows/` |
| 4 | Web 대표 화면 부팅 | PASS, 이전 후보에서 1280×720 타이틀·새 게임 진입 | `tmp/v124_release_candidate/playwright/`, `playwright_new_game/` |
| 5 | Windows 일반 실행 | PASS, 6초 유지 | 이전 후보 Windows smoke |
| 6 | Godot 관련 테스트·Full 156개 | BLOCKED, 격리 Godot `0xC0000005`/signal 11 | `tmp/core_verification/latest.json` 및 콘솔 출력 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_BLOCKED

## 7. 미해결 항목과 위험

- 기존 v1.2.3 태그를 새 커밋으로 강제 이동하고 Release 자산을 교체한다.
- Pages workflow는 기존 `build-manifest.json` provenance 검사를 요구하므로, 사용자 지시대로 기존 정식 링크를 덮으려면 이번 수동 hotfix 배포 경로가 필요하다.
- 정상 Godot 런타임에서 명령 버튼·도둑 추격 직접 테스트를 완료하지 못했다.

## 8. 다음 작업 순서

1. 버전 재정렬과 핸드오프를 커밋·푸시한다.
2. 기존 `v1.2.3` 태그와 GitHub Release 자산을 수정본으로 교체한다.
3. GitHub Pages에 수정 Web을 배포하고 공개 URL에서 1280×720 부팅을 확인한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 후보 브랜치에서 버전 재정렬·핸드오프 수정 후 커밋 예정.
- 미커밋 파일: 버전 재정렬, CURRENT, 본 핸드오프.
- 의도하지 않은 기존 변경: 다수 `.import` 줄바꿈 상태 표시는 스테이징하지 않는다.
- 빌드 산출물 위치: `tmp/v123_hotfix_overwrite/`

## 10. 종료 체크리스트

- [x] 수정 구현과 기존 정식판 덮어쓰기 요구 대조
- [x] Web·Windows export 성공
- [ ] 기존 Release 자산 교체
- [ ] 기존 공개 Pages 링크 갱신
- [ ] 공개 URL 부팅 확인
- [ ] Full 회귀 검수
- [x] `docs/handoff/CURRENT.md` 갱신
