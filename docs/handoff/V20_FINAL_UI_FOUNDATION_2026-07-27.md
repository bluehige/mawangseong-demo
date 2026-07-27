# 제품 2.0 최종 UI U1 공통 기반·타이틀·침입 브리핑 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-foundation`
- 기준 브랜치 및 SHA: `release/v2.0@a79fe40afb54526bd4370b519994a6541824a25d`
- Reviewed SHA: `dd293e6c9d6aa3ee959a651ab9bd0eaf0d375eee`
- 마지막 커밋 SHA: handoff·`CURRENT.md` 종료 커밋 전 기준 `dd293e6c9d6aa3ee959a651ab9bd0eaf0d375eee`
- 원격 푸시 여부: 작성 시점 미푸시
- 관련 PR 또는 태그: U1 PR 생성 전, 태그·Release 변경 없음

## 2. 이번 세션 목표

- 요청 사항: `V20_FINAL_UI_RELEASE_TRANSPLANT_PLAN.md`의 U1에 따라 공통 UI 규격을 만들고 타이틀과 침입 확인 화면을 단순화한다.
- 완료 조건: 타이틀과 침입 확인의 주 행동을 각각 하나로 제한하고, 유효 저장에만 이어하기를 표시하며, 침입 적·목표·고정 경로·DAY 주의를 읽을 수 있게 하고, 관련 자동 테스트와 1280×720·1366×768·1920×1080 실제 렌더를 통과한다.
- 범위에서 제외한 사항: 배치 보드 UX, 전투 HUD 재설계, 결과 화면, 밸런스·AI·spawn·HP/ATK·시설/몬스터 효과, 신규 자산, 전체 회귀·전체 플레이·별도 검수 에이전트, build·배포·태그·Release.

## 3. 완료한 작업

- 구현: `V20UITheme`에 색·폰트 최소 크기·여백·44px 버튼 높이·공통 버튼 상태·debug build badge 규격을 집중했다.
- 스토리 및 데이터: 변경 없음. 침입 브리핑은 기존 encounter·enemy·spatial catalog의 계산 결과만 읽는 UI view adapter다.
- 밸런스: 변경 없음. 전투 결과, spawn, HP/ATK, 목표 판정과 시설·몬스터 효과를 수정하지 않았다.
- UI/UX: 타이틀을 `마왕성 → DAY 1~5 전술 방어 테스트 → 새 테스트 시작` 순서로 단순화했다. 단일 고정 난이도 선택 UI를 제거하고 유효 저장에만 `이어하기 · DAY N`을 표시한다. 침입 화면은 적 대표 이미지·이름, 적 목표, 고정 침입 순서, DAY 주의와 `배치 시작` 하나만 노출한다.
- 저장 및 호환성: 저장 schema와 읽기·쓰기 로직은 변경하지 않았다. 기존 1.2 저장 격리 안내를 유지했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/v20/ui/V20UITheme.gd` | 공통 색·타이포·간격·버튼·debug badge 규격 | 완료 |
| `scripts/v20/ui/V20UITheme.gd.uid` | 새 공통 UI script UID | 완료 |
| `scripts/v20/ui/V20TitleEntryPanel.gd` | 가짜 난이도 제거, 새 시작 주 행동과 유효 저장 이어하기 단순화 | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 공통 theme 적용과 침입 브리핑 전용 상태 구성 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 기존 catalog를 읽는 침입 브리핑 view adapter | 완료 |
| `tools/tests/V20InformationArchitectureTest.gd` | theme·타이틀·침입 계약과 3해상도 실제 캡처 추가 | 완료 |
| `docs/handoff/V20_FINAL_UI_FOUNDATION_2026-07-27.md` | U1 검수 근거와 다음 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업을 U1/U2 기준으로 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: N/A
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: 기존 공병 sprite를 침입 대표 이미지로 재사용했다. 신규·수정 asset은 0건이다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V20InformationArchitectureTest.tscn` headless | PASS | theme·타이틀·침입·기존 관리/전투 IA 94 assertions |
| 2 | `V20OnboardingRetrySaveTest.tscn` headless, 격리 `user://` | PASS | 저장 왕복·침입→배치→방어·재도전 56 assertions |
| 3 | `V20InformationArchitectureTest.tscn -- --capture-v20-ui-foundation`, Windows OpenGL | PASS | 1280×720·1366×768·1920×1080 타이틀·침입 6개 실제 GPU 렌더, 총 100 assertions |
| 4 | 실제 캡처 육안 확인 | PASS | 글자·버튼·경계 선명, 화면 이탈·겹침 0건 |
| 5 | `git diff --check`와 staged 범위 확인 | PASS | Reviewed SHA의 의도한 runtime/test 6개 파일만 포함 |
| 6 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | U0 계약에 따라 F1 전 실행 금지 |

첫 Godot 실행은 sandbox의 기본 `%APPDATA%` 쓰기 제한으로 `user://` 저장이 실패했다. 같은 테스트를 저장소 `.godot/` 아래 격리 사용자 데이터 경로에서 다시 실행해 56/56 PASS를 확인했다. 로컬 로그와 캡처는 `.godot/`에만 두고 커밋하지 않았다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| - | NOT_REQUESTED | U1 공통 UI·타이틀·침입 브리핑 | `dd293e6c9d6aa3ee959a651ab9bd0eaf0d375eee` | N/A | N/A | 직접 관련 자동 테스트와 실제 렌더 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 F1 전 실행 금지 항목이다.
- PASS 이후 기능·데이터·자산 변경 여부: 0건. Reviewed SHA 뒤에는 이 handoff와 `CURRENT.md`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: dd293e6c9d6aa3ee959a651ab9bd0eaf0d375eee
- Review range: a79fe40afb54526bd4370b519994a6541824a25d..dd293e6c9d6aa3ee959a651ab9bd0eaf0d375eee
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 침입 문구는 기존 catalog ID를 UI용 한국어로 매핑한다. 새 encounter objective나 special pattern이 추가되면 fallback 문구가 표시된다.
- 밸런스 관찰 항목: 밸런스는 동결했다. 기존 PR 4 후보는 F1 전체 검수 전까지 공식 PASS가 아니다.
- 임시 구현 또는 대체 자산: 신규 자산 없이 기존 적 sprite를 대표 이미지로 사용했다.
- 외부 환경/도구 제약: 원격 `repository-policy`는 PR 생성 뒤 확인해야 한다. debug badge의 정확한 source SHA·build flavor는 U5 export 환경 변수로 고정한다.

## 8. 다음 작업 순서

1. U1 PR을 `release/v2.0` 대상으로 열고 원격 `repository-policy` PASS 뒤 merge commit으로 병합한다.
2. U1 merge SHA에서 `codex/v20-final-ui-placement`를 만들고 U2 배치 화면만 수정한다.
3. U2에서는 설치·교체·이동·제거·Undo, 잘못된 drop 피드백, 관련 UI 테스트와 필요한 실제 drag/click 캡처만 확인한다.
4. U2 merge 전 U3를 시작하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: handoff·`CURRENT.md` 종료 변경만 존재
- 미커밋 파일: `docs/handoff/V20_FINAL_UI_FOUNDATION_2026-07-27.md`, `docs/handoff/CURRENT.md`
- 의도하지 않은 기존 변경: U1 worktree에는 없음. 원래 `게임소스/` worktree의 사용자 미추적 파일은 건드리지 않았다.
- 스태시 또는 별도 작업공간: 별도 worktree `v20-u0`
- 빌드/캡처 산출물 위치: `.godot/v20-u1-render-appdata/`와 `.godot/*.log`, Git 미추적·미커밋

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 자동 테스트 통과
- [x] 사용자 요청 범위의 실제 3해상도 렌더 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료 — 요청되지 않았고 계획상 F1 전 금지
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료 — 신규 자산 없음
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR 상태 기록
