# v1.2.5 정식 출시 검증 게이트 정합화 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-10
- 목표 버전: `1.2.5`
- 작업 브랜치: `codex/v125-release-gate-fix`
- 기준 브랜치 및 SHA: `origin/main@1e4b86c1c9082693fd63424dd7a3190a09a15438`
- 마지막 제품·검증 커밋 SHA: `9deece7501fa11def2f9bbb0c9e256f747042953`
- 원격 푸시 여부: 이 문서 커밋 후 푸시 예정
- 관련 PR 또는 태그: 게이트 수정 PR 생성 예정, `v1.2.5`는 최종 Full PASS 뒤 생성

## 2. 이번 세션 목표

- 요청 사항: v1.2.5 수정본을 정식 Windows/Web 빌드로 만들고 소스와 직접 플레이 Web판을 GitHub에 게시한다.
- 완료 조건: 병합된 동일 SHA의 Full PASS, Windows/Web 빌드, `v1.2.5` Release, Pages 공개 부팅 완료.
- 범위에서 제외한 사항: 제품 런타임의 추가 기능·밸런스·그래픽 변경.

## 3. 완료한 작업

- 첫 `main` Full에서 158개 중 4개가 실패한 원인을 확인했다.
- Stage 02~04가 새 `stage_atlas`를 사용하도록 바뀐 사실을 통로 레이아웃 검사가 반영하도록 수정했다.
- UI 문구 `집중 +`가 `집중 성장 +`로 바뀐 사실을 데모·튜토리얼 검사가 반영하도록 수정했다.
- DAY 3 보조 밸런스의 경계값에 물리 시뮬레이션 한 틱(`0.0666667초`)의 수치 오차를 허용했다.
- 제품 코드·데이터·자산은 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/tests/V122CorridorTopologyLayoutMatrixTest.gd` | Stage 02~04의 실제 바닥 모드와 검사 기대값 정합화 | 완료 |
| `tools/DemoSmokeTest.gd` | 현재 집중 성장 버튼 문구 반영 | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 현재 튜토리얼 성장 문구 반영 | 완료 |
| `tools/BalanceSimulation.gd` | 고정 스텝 한 틱의 경계 오차 허용 | 완료 |

## 5. 그래픽 및 오디오 자산

- 신규 생성·변경 없음.
- 기존 v1.2.5 Stage 02~04 그래픽 자산과 런타임 연결은 그대로 유지했다.

## 6. 테스트 및 검수

| 순서 | 검사 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 첫 `RunCoreVerification.ps1 -Mode Full` | 154/158 PASS | `tmp/core_verification/runs/20260810_120600/` |
| 2 | `V122CorridorTopologyLayoutMatrixTest.tscn` | PASS | 새 `stage_atlas` 기대값 확인 |
| 3 | `DemoSmokeTest.tscn` | PASS | `집중 성장 +` 탐색 확인 |
| 4 | `TutorialFlowSmokeTest.tscn` | PASS | `집중 성장 +8` 흐름 확인 |
| 5 | `BalanceSimulation.tscn --assert-tutorial-balance` | PASS | DAY3_ASSISTED 승리·HP·다운·스킬·시간 허용범위 통과 |

첫 Full의 4건은 모두 현재 제품 사양을 따라가지 못한 검증 계약 문제였다. 제품 런타임 결함은 발견되지 않았다. 최종 Full은 이 커밋을 `main`에 병합한 뒤 생성된 merge SHA에서 한 번 실행한다.

### 검수 에이전트 반복 기록

- 잔여 P1/P2 지적: 관련 수정 범위에서 알려진 항목 없음. 최종 판정은 병합 SHA Full 대기.
- 실행하지 못한 필수 검사와 이유: 최종 Full은 원격 PR 병합 SHA가 아직 생성되지 않아 대기.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 아래 Reviewed SHA 이후에는 핸드오프 문서만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 9deece7501fa11def2f9bbb0c9e256f747042953
- Review range: 1e4b86c1c9082693fd63424dd7a3190a09a15438..9deece7501fa11def2f9bbb0c9e256f747042953
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 제품 미해결 결함은 없다.
- 병합 SHA에서 최종 Full, 빌드, Release, Pages 게시가 남아 있다.

## 8. 다음 작업 순서

1. 게이트 수정 PR을 merge commit으로 `main`에 병합한다.
2. 최종 `main` SHA에서 Full을 정확히 한 번 실행한다.
3. 같은 SHA에서 Windows/Web 정식 빌드를 만들고 부팅 확인한다.
4. `v1.2.5` 태그·GitHub Release·Pages를 게시하고 공개 URL을 확인한다.
5. 최종 출시 핸드오프를 문서 전용 PR로 기록한다.

## 9. 작업 트리 상태

- 격리 작업공간: `tmp/v125_release_main`
- 사용자 기본 작업 트리의 기존 `.import`, 캡처, 브라우저 산출물, `progress.md`는 수정·스테이징하지 않았다.
- 빌드 산출물은 소스 브랜치에 커밋하지 않고 GitHub Release에서 보관할 예정이다.

## 10. 종료 체크리스트

- [x] 검증 계약 원인 분석 및 수정
- [x] 실패 4종 직접 재검증 PASS
- [x] 검증 기준 SHA 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 원격 푸시 및 PR 병합
- [ ] 최종 Full PASS
- [ ] Windows/Web 빌드와 GitHub 배포
