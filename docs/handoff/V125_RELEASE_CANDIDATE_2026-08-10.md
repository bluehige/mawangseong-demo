# v1.2.5 정식 출시 후보 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-10
- 목표 버전: `1.2.5`
- 작업 브랜치: `codex/v125-release-candidate`
- 기준 브랜치 및 SHA: `origin/main@5082a86f5a25d098b7f1c040958bd14da703e578`
- 마지막 제품 커밋 SHA: `8bff4bd43436a31f7894b8ddbad46cfdbf5c64fd`
- 원격 푸시 여부: 문서 커밋 시점에는 아니오
- 관련 PR 또는 태그: 기존 `v1.2.4@424a2db`; `v1.2.5` PR·태그는 다음 단계

## 2. 이번 세션 목표

- 요청 사항: 그래픽 자원 검수·업데이트와 직전 최종 검수의 출시 차단 결함을 수정하고, Windows/Web 정식판과 GitHub 소스·Web 직접 플레이 배포까지 완료한다.
- 완료 조건: P1/P2/P3 수정, 1.2.5 버전 고정, 대표 Windows 렌더 확인, 최종 `main` Full 1회 PASS, 같은 태그의 Windows/Web 빌드·Release·Pages 게시.
- 현재 경계: 제품·자산·관련 검증·버전 고정까지 완료했다. 전체 Full, PR 병합, 태그, 빌드와 공개 배포는 이 핸드오프 다음 단계다.

## 3. 완료한 작업

- 구현: 패배 시 자원·보상·EXP·유대·레벨을 전투 시작 상태로 복원하고 승리 때만 성장·보상을 확정한다.
- 스토리 및 데이터: DAY 29를 공통 3장면과 선언 반응 장면으로 나누고 세 선언 및 Update 3 전선별 결전 전야를 실제 진행에 연결했다. 잘린 문장·내부 화자명·내부 축약어·백틱도 정리했다.
- 밸런스: 승리 보상 수치는 바꾸지 않고 패배 반복 획득만 차단했다.
- UI/UX: 패배 결산에 재도전 행동을 제시하고 1280×720 HUD·지침 popup·필수 성장 선택 버튼을 확대했다. 피해 숫자는 1.0배에서 시작한다.
- 그래픽: Stage 02~04 전용 배경 3개, 통로 18개와 생성 원본 9개를 추가하고 단계별 렌더·입구 배치·전면 벽 깊이를 연결했다.
- 저장 및 호환성: 기존 사용자 데이터 경로와 저장 schema를 유지한다. 패배 복원용 snapshot은 전투 런타임 상태다.
- 버전: `project.godot`, Windows Desktop/QA/Steam 리소스와 출시 계약을 `1.2.5`/`1.2.5.0`으로 맞췄다.

## 4. 주요 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | 패배 롤백, DAY 29 장면 연쇄·선언 반응 | 완료 |
| `scripts/game/CombatSceneController.gd` | 승패별 결산 확정·피해 숫자 배율 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 결과 조언·집중 성장 선택 UI | 완료 |
| `scripts/ui/HUDController.gd` | 1280×720 전투 정보·popup 가독성 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | Stage별 배경·통로·색조·입구 배치 | 완료 |
| `data/story/v122_main/day_28.json`~`day_30.json` | DAY 29 분절·선언·문구 수정 | 완료 |
| `data/dungeon_quarter/asset_manifest.json` | Stage 02~04 새 공간 자산 연결 | 완료 |
| `assets/backgrounds/v125/` | Stage 02~04 런타임 배경 | 완료 |
| `assets/tiles/stage_02/`~`stage_04/` | 단계별 통로·atlas | 완료 |
| `assets/source/imagegen/v125_stage_progression/` | 생성 원본과 출처 | 완료 |
| `tools/tests/core_verification_suite.json` | 신규 롤백·그래픽 검사 등록 | 완료 |
| `project.godot`, `export_presets.cfg` | 제품·Windows 버전 1.2.5 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 예
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/v125_stage_progression/`
- `SOURCE.md` 경로: `assets/source/imagegen/v125_stage_progression/SOURCE.md`
- 런타임 최종 자산 경로: `assets/backgrounds/v125/`, `assets/tiles/stage_02/`, `assets/tiles/stage_03/`, `assets/tiles/stage_04/`
- 프롬프트/후처리/크롭/알파 처리 요약: Stage 01 카메라와 중앙 전투 여백을 기준으로 후반 공간을 생성하고, 크로마 통로를 알파 처리한 뒤 2:1 셀과 16-mask atlas로 정규화했다.
- 게임 연결 및 실제 렌더 확인 결과: 관리 Stage 01~04와 인위적 전투 Stage 02·04 1920×1080, 전투 HUD와 성장 선택 1280×720을 실제 Windows Godot 렌더로 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 스토리 schema·DAY 06~30·DAY 29 런타임 | PASS | 19,496 / 7,768 / 64 assertions |
| 2 | 패배 자원·성장 롤백 | PASS | `V125FailedBattleProgressRollbackTest.tscn` |
| 3 | 결과 UI·재도전 행동 | PASS | `V122CombatResultUIContractTest.tscn` |
| 4 | Stage 01~04 그래픽 런타임 | PASS | `V125StageProgressionVisualRuntimeTest.tscn` |
| 5 | 출시 메타데이터 | PASS | `V122ReleaseReadinessTest.tscn`, 84 assertions |
| 6 | 실제 Stage 01~04·전투 렌더 | PASS | `tmp/castle_stage_review/`, `tmp/v125_stage_progression_combat/` |
| 7 | 실제 1280×720 HUD·성장 선택 | PASS | `tmp/v122_stage11_cascade_audit/`, 135 assertions |
| 8 | 전체 핵심 검증 | REQUESTED / PENDING | `main` merge SHA에서 1회 실행 예정 |

### 검수 에이전트 반복 기록

직전 분야별 검수 작업 `019fcf24-1f81-7d33-9978-7a13ab667184`의 P1 3 / P2 7 / P3 3을 이번 수정 범위의 출발점으로 사용했다. 결함별 수정 근거는 `docs/qa/V125_RELEASE_REMEDIATION_2026-08-10.md`에 대조했다. 이 후보 PR 자체는 관련 수정 검증 단계이며, 최종 출시 Full은 병합된 `main` SHA에서 별도로 기록한다.

- 남은 P1/P2 지적: 관련 수정 범위에서 알려진 항목 없음. 최종 판정은 `main` Full 대기.
- 실행하지 못한 필수 검수와 이유: 전체 Full은 manifest가 가리킬 최종 merge SHA에서 한 번만 실행하기 위해 대기한다.
- PASS 이후 기능·데이터·자산 변경 여부: 제품 커밋 `8bff4bd43436a31f7894b8ddbad46cfdbf5c64fd` 뒤에는 핸드오프 문서만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 8bff4bd43436a31f7894b8ddbad46cfdbf5c64fd
- Review range: 5082a86f5a25d098b7f1c040958bd14da703e578..8bff4bd43436a31f7894b8ddbad46cfdbf5c64fd
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 최종 Full 결과 전에는 정식 PASS로 확정하지 않는다.
- 밸런스 관찰 항목: 승리 수치는 유지됐으며 패배 롤백만 추가됐다.
- 임시 구현 또는 대체 자산: 기본 캠페인에서 사용하지 않는 일부 방향별 맵 편집 시설 변형은 기존 기술 부채로 남는다.
- 외부 환경/도구 제약: Windows 코드 서명과 Steam 외부 계정 gate는 이번 GitHub 정식판 범위 밖이다.

## 8. 다음 작업 순서

1. 이 문서만 별도 커밋하고 브랜치를 원격에 푸시해 `main` PR을 merge commit으로 병합한다.
2. 병합된 `main` SHA에서 Full 핵심 검증을 정확히 한 번 실행한다.
3. PASS인 같은 SHA에 `v1.2.5` 태그를 만들고 Windows/Web export와 manifest를 생성한다.
4. GitHub Release를 게시하고 Pages workflow로 Web 직접 플레이판을 교체한 뒤 공개 부팅을 확인한다.
5. 출시 SHA·검증 보고서·ZIP 해시·Release·Pages 실행을 문서 전용 후속 핸드오프에 기록한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 제품 커밋 뒤 기존 `.import` 변경과 로컬 브라우저·캡처 파일, 이번 핸드오프 문서만 남아 있다.
- 미커밋 파일: `docs/handoff/CURRENT.md`와 이번 세션 핸드오프 문서들.
- 의도하지 않은 기존 변경: 기존 오디오·Stage 01·구 자산 `.import`, `.playwright-*`, `fun-audit-*.png`, `progress.md`는 보존하고 커밋하지 않는다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/castle_stage_review/`, `tmp/v125_stage_progression_combat/`, `tmp/v122_stage11_cascade_audit/`. 정식 빌드는 다음 단계다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 대표 화면 검수 통과
- [ ] 최종 `main` Full 1회 완료
- [x] 후보 검증 대상 SHA 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 제품 변경 의도 파일만 커밋
- [ ] 원격 푸시·PR·태그·Release·Pages 완료
