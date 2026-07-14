# v0.4 순차 개발 마감 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-14
- 목표 버전: v0.4 (정식 `v0.4.0` 태그 생성 전 개발 완료본)
- 작업 브랜치: `codex/v04-sequential-development`
- 기준 브랜치 및 SHA: `origin/main` / `af9ff09cd47fce181e9457b32b9409fa54b9a816`
- 마지막 기능·검수 커밋 SHA: `46d09f8d904b96963fbcd3870161cd30ff3ae0d9`
- 원격 푸시 여부: 예. `origin/codex/v04-sequential-development`에 푸시함
- 관련 PR 또는 태그: PR #12 (`codex/v04-sequential-development` → `release/v0.4`), 태그는 생성하지 않음

## 2. 이번 세션 목표

- 요청 사항: v0.4 Phase 0→36을 계획 순서대로 끝까지 구현하고 최신 v0.3 튜토리얼 적 클릭 버그픽스를 포함한다.
- 완료 조건: 관련 자동 테스트와 최종 버그 테스트 통과, `release/v0.4`와 `main`에 merge commit 방식 PR 통합 준비, 후속 업데이트가 가능한 버전별 구조 유지.
- 범위에서 제외한 사항: 정식 `v0.4.0` 태그와 출시 빌드. 전체 검수 에이전트는 v0.4~v0.6 전체 완료 뒤 실행한다.

## 3. 완료한 작업

- 구현: 의회 회차 DAY 1~30, 지역 선택·전초기지·다층 던전, 의결·왕관·대표·최종 선언 필수 선택, 지역 웨이브와 DAY 25/30 라이벌 보스, E17~E22 엔딩과 연대기 저장을 실제 `GameRoot` 진행 경로에 통합했다.
- 스토리 및 데이터: 세 지역 의제·라이벌·결말, 왕관 진화 6종, 계약 몬스터 연출, 의회 연대기와 접근성 데이터를 Phase별로 분리했다.
- 밸런스: 지역 위협도, 전초기지 효과, 다층 이동, 신규 적·라이벌 보스 패턴, 의결 실패와 대체 인장 지급을 고정 데이터와 서비스로 관리한다.
- UI/UX: 의결·왕관·최종 선언 오버레이, 다층 HUD, 지역·전초기지·엔딩·연대기 화면을 연결하고 1920×1080 및 1366×768에서 필수 화면을 확인했다.
- 저장 및 호환성: 캠페인 저장 v5 마이그레이션과 v0.4 의회 회차 기록을 추가했다. 기준 `main`의 최신 v0.3 튜토리얼 적 클릭 버그픽스 `91acdec6ec00c65a438cba9f6cf88e0cfa829744`를 포함한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/systems/campaign/` | 의회 회차, 지역, 의결, 다층, 대표와 Phase 36 런타임 서비스 | 완료 |
| `scripts/systems/crown/`, `scripts/systems/enemies/`, `scripts/systems/bosses/` | 왕관 진화와 신규 적·라이벌 보스 규칙 | 완료 |
| `scripts/game/GameRoot.gd`, `scripts/game/CombatSceneController.gd`, `scripts/game/ManagementSceneController.gd` | 실제 DAY 1~30 관리·전투·결말 경로 통합 | 완료 |
| `scripts/ui/`, `scenes/ui/` | 의회 필수 선택, 지역·전초기지·다층·연대기 표시 | 완료 |
| `data/update4/` | v0.4 데이터 계약과 콘텐츠 정의 | 완료 |
| `assets/` | v0.4 런타임 그래픽·음향 자산 | 완료 |
| `assets/source/imagegen/` | GPT 생성 원본과 출처 문서 | 완료 |
| `tools/tests/`, `tools/DemoSmokeTest.gd` | Phase별 계약 및 최종 통합·회귀 테스트 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예. 그래픽 Phase에서만 사용했으며 Phase 36에는 신규 이미지를 생성하지 않았다.
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/update4_*`
- `SOURCE.md` 경로: 각 `assets/source/imagegen/update4_*/SOURCE.md`
- 런타임 최종 자산 경로: `assets/sprites/**/update4/`, `assets/ui/**/update4/`, `assets/tiles/update4/`, `assets/props/update4/`
- 프롬프트/후처리/크롭/알파 처리 요약: 자산별 `SOURCE.md`에 날짜, 대상 버전, 생성 원본, 런타임 경로와 후처리를 기록했다.
- 게임 연결 및 실제 렌더 확인 결과: 자산 계약 테스트와 1920×1080·1366×768 실제 화면 확인 PASS.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | v0.4 Phase별 관련 자동 테스트 36종 | PASS | `tools/tests/` |
| 2 | Phase 36 DAY 1~30 통합 테스트 | PASS, 285 assertions | `tools/tests/Update4ReleaseCandidatePhase36Test.tscn` |
| 3 | 최신 v0.3 튜토리얼 적 클릭 회귀 | PASS | `tools/TutorialFlowSmokeTest.tscn` |
| 4 | 데모 핵심 관리·전투·결말 스모크 | PASS, 누수 경고 없음 | `tools/DemoSmokeTest.tscn` |
| 5 | Phase 10 다층 그래프 형식 수정 후 재검사 | PASS, 16 assertions | `tools/tests/MultiFloorGraphPhase10Test.tscn` |
| 6 | 의결·왕관·최종 선언 UI 1920×1080 및 1366×768 확인 | PASS | Godot 사용자 데이터 캡처(저장소 외부) |
| 7 | 저장소 정책·빌드 매니페스트·정책 자체 테스트 | PASS | `tools/ci/` |
| 8 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | v0.4~v0.6 전체 완료 후 실행 예정 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | `af9ff09cd47fce181e9457b32b9409fa54b9a816..46d09f8d904b96963fbcd3870161cd30ff3ae0d9` | `46d09f8d904b96963fbcd3870161cd30ff3ae0d9` | 별도 에이전트 검수 미요청 | 관련 자동 테스트와 최종 버그 테스트 수행 | `tools/tests/`, `tools/ci/` | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 별도 검수 에이전트는 현재 버전에서 요청되지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 검수 SHA 이후에는 이 핸드오프와 `CURRENT.md`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 46d09f8d904b96963fbcd3870161cd30ff3ae0d9
- Review range: af9ff09cd47fce181e9457b32b9409fa54b9a816..46d09f8d904b96963fbcd3870161cd30ff3ae0d9
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 필수 테스트에서 재현된 미해결 오류 없음.
- 밸런스 관찰 항목: 정식 출시 전 실제 플레이 기반 지역 위협도·라이벌 보스 난이도 버그픽스가 필요할 수 있다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: GitHub의 실제 게임용 `core-verification`, `web-export-smoke` 필수 체크는 아직 Ruleset 적용 전이다.

## 8. 다음 작업 순서

1. PR #12를 merge commit으로 `release/v0.4`에 통합하고 필수 체크를 확인한다.
2. `release/v0.4` → `main` PR을 merge commit으로 통합하되 정식 `v0.4.0` 태그는 만들지 않는다.
3. 후속 버그픽스와 출시 검증 뒤 `v0.4.0` 태그를 만들고, 최신 `main`에서 v0.5 순차 개발을 시작한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 문서 작성 전 clean, `origin/codex/v04-sequential-development`와 동기화.
- 미커밋 파일: 이 핸드오프와 `CURRENT.md`만 문서 커밋 예정.
- 의도하지 않은 기존 변경: 없음.
- 스태시 또는 별도 작업공간: v0.4 전용 worktree `마왕성_goal_v04` 사용, 스태시 없음.
- 빌드/캡처 산출물 위치: 저장소 안에 신규 빌드 산출물 없음. UI 캡처는 Godot 사용자 데이터 폴더에만 존재.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR/태그 상태 기록
