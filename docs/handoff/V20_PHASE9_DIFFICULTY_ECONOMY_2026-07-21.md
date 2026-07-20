# 제품 2.0 Phase 9 난이도·경제 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p09-difficulty-economy`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `655f6ad1e218ac41c54f9c671b5cd8a8075c3d1d`
- 마지막 제품 커밋 SHA: `6eaac768da1f82d3400fd3c87129f5a8817b58a9`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #53

## 2. 이번 세션 목표

- 요청 사항: 초반 난이도를 적 HP와 대기 시간 대신 예산·동시 목표·예고 시간·명령 자원 선택 압박으로 재설계한다.
- 완료 조건: 난이도 상승 시 판단 부하가 증가하고 spawn 수·시각은 같으며 예상 전투 시간 차이는 10% 미만이다.
- 범위에서 제외한 사항: v2 타이틀 진입, 저장·온보딩·재시도, 실제 사람 난이도·판매성 판정.

## 3. 완료한 작업

- 구현: 이야기·전술가·마왕 세 프로필과 validator, encounter 설정, 명령 자원 설정, 건설 지출, 피해 수리·승패 수입 결산을 독립 서비스로 추가했다.
- 난이도: 동시 목표 1·2·3, 예고 135%·100%·75%, 초기 건설 14·10·8, 초기 명령 4·3·2와 회복 9·12·14초로 판단 여유를 조절한다.
- 밸런스: 마왕 HP는 5%, ATK는 6%만 보정하며 spawn 수와 시각은 유지한다. DAY 5 자동 추정 전투 시간 차이는 이야기 대비 10% 미만이다.
- UI/UX: 관리 상단에 난이도명, 건설 예산, 목표 수, 명령력, 예고 비율을 한 줄로 표시한다. 첫 렌더에서 발견한 두 줄 겹침을 한 줄 요약으로 수정했다.
- 저장 및 호환성: 경제 상태는 Phase 10 저장층이 소비할 순수 Dictionary 계약이다. 공개 v1.2 자원·wave·저장 경로는 v2 gate가 꺼진 상태에서 불변이다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/economy.json` | 세 난이도 예산·명령·encounter·결산 계약 | 완료 |
| `scripts/v20/economy/V20EconomyService.gd` | validator·설정·지출·결산·판단 부하 계측 | 완료 |
| `scripts/v20/encounters/V20EncounterService.gd` | 설정된 encounter의 WaveManager adapter | 완료 |
| `scripts/game/CombatSceneController.gd` | 난이도별 encounter·명령력 runtime 연결 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 난이도·초기 자원 한 줄 요약 | 완료 |
| `scripts/core/DataRegistry.gd` | v2 economy catalog 별도 로드 | 완료 |
| `tools/tests/V20DifficultyEconomyTest.*` | 압박·시간 상한·지출·결산·HUD 검증 | 완료 |
| `tools/tests/core_verification_suite.json` | 관련 검증 scene 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 기존 v2 runtime HUD만 사용했다.
- 게임 연결 및 실제 렌더 확인 결과: `user://v20_phase9_difficulty_economy_1280x720.png`에서 마왕·건설 8·목표 3·명령 2/3·예고 75%가 상단 패널 안에 한 줄로 표시되고 하단 네 행동과 겹치지 않음을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20DifficultyEconomyTest.tscn` headless | PASS, 26 assertions | catalog·압박·시간 상한·예산·결산·runtime adapter |
| 2 | 동일 test OpenGL `--capture-v20-economy` | PASS, 27 assertions | 1280×720 수정 후 실제 렌더 |
| 3 | `V20DayOneToFiveEncountersTest.tscn` | PASS, 69 assertions | Phase 8 encounter 회귀 |
| 4 | `V20TacticalCommandsTest.tscn` | PASS, 26 assertions | Phase 7 명령 회귀 |
| 5 | `V20InformationArchitectureTest.tscn` | PASS, 33 assertions | 1280·1366·1920 PC HUD 계약 |
| 6 | `DemoSmokeTest.tscn` | PASS | 기존 부팅·controller parse 회귀 |
| 7 | JSON/suite parse, Godot editor import와 `git diff --check` | PASS | 변경 파일 |
| 8 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `6eaac768da1f82d3400fd3c87129f5a8817b58a9` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 6eaac768da1f82d3400fd3c87129f5a8817b58a9
- Review range: 655f6ad1e218ac41c54f9c671b5cd8a8075c3d1d..6eaac768da1f82d3400fd3c87129f5a8817b58a9
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: Phase 10 전에는 난이도 선택과 경제 상태가 v2 save/session에 영속되지 않는다.
- 밸런스 관찰 항목: 자동 판단 부하 점수와 시간 상한은 실제 사람이 느끼는 난이도·재미를 의미하지 않는다.
- 임시 구현 또는 대체 자산: 신규 그래픽 없음. 관리 화면은 Phase 2 전략 보드를 재사용한다.
- 외부 환경/도구 제약: 실제 난이도 이해도는 Phase 11 블라인드 플레이테스트에서만 판정한다.

## 8. 다음 작업 순서

1. Phase 10에서 v2 session과 `user://v20/` 전용 save를 만들고 1.2 저장과 완전히 분리한다.
2. 타이틀의 명시적 2.0 진입, 90초 첫 의미 있는 선택 관찰, 원인 결산과 배치 보존 재시도를 연결한다.
3. v2 저장 격리·온보딩·재시도 근거와 실제 타이틀/결과 UI를 관련 검사로 고정한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `user://v20_phase9_difficulty_economy_1280x720.png` (커밋 안 함).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트·수정 후 1280×720 렌더 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
