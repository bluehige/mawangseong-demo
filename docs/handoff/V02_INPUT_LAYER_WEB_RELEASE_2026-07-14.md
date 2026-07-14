# v0.2.1 입력 레이어 핫픽스·Web 릴리즈 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-14
- 목표 버전: v0.2.1
- 작업 브랜치: `hotfix/v0.2.1-input-layer`, `codex/v02-hotfix-main-lineage`
- 기준 브랜치 및 SHA: `v.02` / `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69`, `main` / `490ef34a916571515c80549afbeeaffed823a2a8`
- 마지막 기능 커밋 SHA: `3b1a0edd6b0389f7be8b4c88fe8ca45046d623b3`
- `main` 계보 검토 SHA: `77423e73717c03c3beb9d0aa2377a6436a1d4d33`
- 원격 푸시 여부: v0.2 핫픽스 푸시 및 PR #16 병합 완료, main 계보 브랜치는 문서 작성 시점 미푸시
- 관련 PR 또는 태그: PR #16, 태그는 문서 작성 시점 생성 전

## 2. 이번 세션 목표

- 요청 사항: 레이어 순서 때문에 보여야 할 버튼이 클릭되지 않는 v0.2 Web 버그를 수정하고 공개 Web 릴리즈를 갱신한다.
- 완료 조건: 장식 UI는 클릭을 통과시키고 실제 입력 위젯과 모달은 입력을 소유하며, v0.2 Full 검증·Web export·Release·Pages 공개 검증이 통과한다.
- 범위에서 제외한 사항: v0.2 콘텐츠·스토리·밸런스 변경, 신규 그래픽, 별도 검수 에이전트.

## 3. 완료한 작업

- v0.2.1 구현: 공용 장식 `Panel`, 온보딩 자식 패널, 유닛 이름, 전투 피드백 라벨을 `MOUSE_FILTER_IGNORE`로 고정했다.
- 입력 소유권: 버튼·슬라이더·선택 메뉴는 `MOUSE_FILTER_STOP`을 명시하고 전체 화면 온보딩·확인 모달 차단은 유지했다.
- 회귀 방지: 높은 장식 패널 아래 버튼의 실제 클릭과 공용·온보딩·전투 입력 계약 10개 assertion을 Quick/Full에 등록했다.
- 버전: 프로젝트, 타이틀과 export 메타데이터를 `0.2.1`로 올렸다.
- 계보: PR #16을 merge commit으로 `v.02`에 반영했다. `main`에는 v0.4의 동일 수정이 이미 있으므로 `ours` merge로 소스 트리를 유지하고 v0.2.1 커밋의 조상 관계만 기록했다.
- 스토리·데이터·밸런스·저장 포맷: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/ui/HUDController.gd` | 장식 패널 기본 클릭 통과, 인터랙티브 위젯 입력 소유 | v0.2.1 완료 |
| `scripts/game/GameRoot.gd` | 온보딩 자식 패널 클릭 통과와 v0.2.1 표기 | v0.2.1 완료 |
| `scripts/game/CombatSceneController.gd` | 전투 피드백 라벨 클릭 통과 | v0.2.1 완료 |
| `scripts/units/Unit.gd` | 유닛 이름 라벨 클릭 통과 | v0.2.1 완료 |
| `project.godot`, `export_presets.cfg` | v0.2.1 버전 메타데이터 | v0.2.1 완료 |
| `tools/UIInputLayerSmokeTest.gd`, `tools/UIInputLayerSmokeTest.tscn` | 입력 레이어 회귀 테스트 | v0.2.1 완료 |
| `tools/tests/core_verification_suite.json` | Quick/Full 검증 등록 | v0.2.1 완료 |
| `docs/handoff/CURRENT.md`, 이 문서 | 유지보수·출시 계보 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: 기존 자산을 사용한 Full UI·전투 캡처 통과

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `Godot --headless --scene res://tools/UIInputLayerSmokeTest.tscn` | PASS, 10/10 | 콘솔 출력 |
| 2 | `tools/tests/RunCoreVerification.ps1 -Mode Full` | PASS, 45/45, 802.52초 | v0.2.1 worktree `tmp/core_verification/latest.json` |
| 3 | Full 내 1920×1080·1366×768 UI 및 전투 캡처 | PASS | v0.2.1 worktree `tmp/castle_stage_review/`, `tmp/ui_regression_review/`, `tmp/action_feel_review/` |
| 4 | `git merge-base --is-ancestor 3b1a0ed... 77423e7...` | PASS | exit code 0 |

- 별도 검수 에이전트: 사용자 요청이 없어 실행하지 않음
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 공개 Web 검증은 Release·Pages 배포 뒤 실행 예정
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `main` 계보 merge 뒤 `docs/handoff/`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 77423e73717c03c3beb9d0aa2377a6436a1d4d33
- Review range: 490ef34a916571515c80549afbeeaffed823a2a8..77423e73717c03c3beb9d0aa2377a6436a1d4d33
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동 검증 범위에서는 없음. 공개 Pages에서 문제 화면의 실제 클릭 확인이 남아 있다.
- 밸런스 관찰 항목: 변경 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: Web export, GitHub Release와 Pages 배포는 원격 서비스 상태에 의존한다.

## 8. 다음 작업 순서

1. `codex/v02-hotfix-main-lineage` PR을 `main`에 merge commit으로 반영한다.
2. 기존 v0.2 완성 SHA에 `v0.2.0`, 검증 소스 SHA에 `v0.2.1` 태그를 만든다.
3. manifest와 검증 증빙을 포함한 `mawangseong-v0.2.1-web.zip`을 Release에 게시한다.
4. Pages를 v0.2.1로 갱신하고 공개 Web에서 로드·클릭을 확인한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v02-hotfix-main-lineage`, 문서 변경만 존재
- 미커밋 파일: 문서 작성 시점 `docs/handoff/` 2개
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: v0.2.1 전용 worktree `마왕성_v021_web_release`
- 빌드/캡처 산출물 위치: v0.2.1 worktree의 비추적 `tmp/`

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 릴리즈 Full 자동 검증 통과
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처 변경 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] main 계보 PR merge
- [ ] SemVer 태그·Release·Pages 배포
- [ ] 공개 Web 실제 클릭 확인
