# 제품 2.0 최종 UI U5 사용자 테스트 후보 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-candidate`
- 기준 브랜치와 SHA: `release/v2.0@380b8ad6c931739b8424ac05cca1384f5719f22e`
- source full SHA: `5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`
- Reviewed SHA: `5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`
- 후보 상태: `G1_OWNER_PLAY_PENDING`
- 매니페스트: `docs/handoff/V20_FINAL_UI_CANDIDATE_MANIFEST_2026-07-27.json`

## 2. 이번 세션 목표와 범위

- U1~U4가 병합된 UI 후보에서 제품 기능·데이터·밸런스를 바꾸지 않고 사용자 직접 테스트용 source SHA를 동결한다.
- 직접 관련 UI 테스트와 UI flow smoke만 실행한다.
- 같은 source SHA에서 Windows/Web debug acceptance 산출물을 만들고 SHA-256을 고정한다.
- 1280×720 관리·전투·결과와 1366×768 관리·전투 실제 화면을 기록한다.
- 사용자 명시 승인 전에는 P0 정식 출시선 이식을 시작하지 않는다.
- 전체 회귀, 전체 플레이, 실제 물리 70전, 숙련 QA 24전, 초회 사용자 10명 전체 표본, 별도 검수 에이전트, 정식 release export와 기존 공개 Pages 교체는 수행하지 않는다.

## 3. U5 변경

U5의 제품 runtime 기능·데이터·scene·asset 변경은 0건이다. 고정 UI 후보의 실제 signal wiring을 한 경로에서 확인하기 위한 test tooling만 Reviewed SHA에 추가했다.

| 경로 | 목적 | 제품 runtime 영향 |
|---|---|---|
| `tools/tests/V20FinalUIFlowSmokeTest.gd` | 제목 → 침입 → 배치 → countdown → 전투 HUD → 승패 결과의 실제 UI 연결 검사 | 없음 |
| `tools/tests/V20FinalUIFlowSmokeTest.tscn` | flow smoke 진입 scene | 없음 |
| `docs/handoff/V20_FINAL_UI_CANDIDATE_MANIFEST_2026-07-27.json` | 후보 source·artifact·capture hash 기계 판독 기록 | 없음 |
| `docs/handoff/V20_FINAL_UI_CANDIDATE_2026-07-27.md` | U5 증거와 G1 사용자 게이트 기록 | 없음 |
| `docs/handoff/CURRENT.md` | 다음 세션 단일 진입점 갱신 | 없음 |

## 4. 수정 전/후 핵심 차이

| 구분 | 수정 전 | U5 고정 후보 |
|---|---|---|
| 제목 | 기존 메뉴와 v2.0 진입 행동의 위계가 불명확 | `새 테스트 시작`을 단일 주 행동으로 고정하고 유효 저장만 이어하기 표시 |
| 침입 확인 | 배치 전에 목표·경로·DAY 주의점을 따로 찾아야 함 | 적 목표, 고정 침입 순서, DAY 주의점과 `배치 시작`을 한 화면에 표시 |
| 배치 | 시설·몬스터·경로·상태·주 행동이 분산 | 고정 성 루트 위에 시설과 몬스터를 직접 배치하고 invalid drop·Undo·방어 시작을 명확히 표시 |
| 전투 | 적 진행과 명령 대상·남은 사용 횟수의 연결이 약함 | 4단계 전선, 현재 적 예고, 명령별 대상 안내·사용 횟수·취소 경로를 한 HUD에 표시 |
| 결과 | 승패 뒤 원인과 다음 행동을 다시 해석해야 함 | 핵심 원인, 잘한 점, 다음 변경점, 3개 지표와 패배 `배치 수정` 주 행동을 우선 표시 |

## 5. 고정 산출물과 SHA-256

로컬 산출물 루트:

`tmp/v20-ui-candidate-5ed1d5f0/`

| 산출물 | bytes | SHA-256 |
|---|---:|---|
| Windows debug ZIP | 261,860,112 | `437a27a391a9fe883da99889157199151b874a9498f02548f63f147bd4d6d8a0` |
| Windows EXE | 94,340,608 | `971ee5813e43225d6c414e404c33d257dba51bea7a3dfb0fa104d1b5cdea2b13` |
| Windows PCK | 231,754,052 | `2def8a3f314ef816bc47d74d33fe18c9868ff1f972e3905aa8704706fc05db4c` |
| Web debug ZIP | 239,757,071 | `cd98af40337bfa2d78c9f5b90837c2af57d1daf14b2f946e49e4450c471be0f9` |
| Web PCK | 231,754,052 | `2def8a3f314ef816bc47d74d33fe18c9868ff1f972e3905aa8704706fc05db4c` |
| Web WASM | 36,157,734 | `e5fdeacf9706dce4252c5e144ae07ed66e9ca65645852a1880bd8af51fb09d8d` |

- Windows ZIP은 `Start-V20-UI-Candidate.cmd`, EXE, PCK, README를 포함한다.
- Web ZIP은 `Start-V20-Web-Candidate.cmd`, HTML/JS/PCK/WASM, 아이콘·worklet, README를 포함한다.
- Windows 실행 파일은 source/build 환경 변수를 적용한 상태로 8초간 정상 유지되어 부팅 PASS로 판정한 뒤 테스트 프로세스만 종료했다.
- Web 후보는 고정 acceptance URL로 실제 실행했고 source SHA와 `web-debug-acceptance` badge를 우측 상단에 표시했다.

## 6. 실제 화면 캡처

| 화면 | 해상도 | 파일 |
|---|---:|---|
| 관리·배치 | 1280×720 | `captures/management-1280x720.jpg` |
| 전투 | 1280×720 | `captures/combat-1280x720.jpg` |
| 패배 결과 | 1280×720 | `captures/result-loss-1280x720.jpg` |
| 관리·배치 | 1366×768 | `captures/management-1366x768.jpg` |
| 전투 | 1366×768 | `captures/combat-1366x768.jpg` |

모든 파일은 매니페스트에 bytes와 SHA-256을 기록했다. Web 실제 실행에서 제목 → 침입 브리핑 → 배치 → countdown → 실전 전투 → 패배 결과를 통과했고 브라우저 console error·warning은 각각 0건이었다.

## 7. 직접 관련 검증

| 검사 | 결과 |
|---|---|
| `V20InformationArchitectureTest` | PASS, 115 assertions |
| `V20PlacementUxTest` | PASS, 42 assertions |
| `V20TacticalCommandsTest` | PASS, 29 assertions |
| `V20ResultScreenTest` | PASS, 41 assertions |
| `V20OnboardingRetrySaveTest` | PASS, 60 assertions |
| `V20FinalUIFlowSmokeTest` | PASS, 22 assertions |
| Windows debug 부팅 | PASS, 8초 process alive |
| Web 1280×720 실제 흐름 | PASS, 제목·침입·배치·전투·결과 |
| Web 1366×768 실제 흐름 | PASS, 배치·전투 |
| Web console | PASS, error 0 / warning 0 |
| 전체 검수 | NOT_REQUESTED, F1 전 실행 금지 |

`V20FinalUIFlowSmokeTest`는 제목 주 행동, 실제 GameRoot 침입·배치, 시설 설치, invalid drop fingerprint, 몬스터 이동, Undo, countdown 취소·재시작, 전투 명령 대상 안내·취소, 패배 배치 수정, 승리 결과를 22개 단언으로 검사한다. 이는 UI 연결 증거이며 재미·밸런스·실제 물리 70전 PASS가 아니다.

### 정책 CI와 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1
- Review range: 380b8ad6c931739b8424ac05cca1384f5719f22e..5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 8. 알려진 제한 사항

- 이 후보는 로컬 debug acceptance 빌드다. 코드 서명된 정식 release export가 아니다.
- Windows export preset의 기존 제품 메타데이터는 아직 v1.2.1이다. 버전·출시 설정 통합은 사용자 승인 뒤 P4 범위다.
- Web badge는 산출물 HTML에만 더한 overlay이며 PCK는 export 원본 그대로다.
- Windows badge는 ZIP 안의 `Start-V20-UI-Candidate.cmd`로 실행할 때 source/build 환경 변수가 표시된다.
- 일부 headless 스위트는 PASS와 exit code 0 뒤 기존 audio resource cleanup 경고를 출력한다.
- 모바일 전면 개편, 장시간 성능, 실제 재미·밸런스, F1 전체 수용 매트릭스는 이 후보 검증 범위가 아니다.

## 9. G1 사용자 테스트 순서

1. 새 테스트 시작
2. 침입 목표 확인
3. 시설 1개 설치
4. 몬스터 3종 배치 또는 이동
5. 잘못된 슬롯에 한 번 drop
6. Undo 한 번
7. 방어 시작
8. 전투에서 적 예고 확인
9. 명령 1회 사용
10. 승리 또는 패배 결과 확인
11. 패배 시 배치 수정
12. DAY 진행 또는 재도전

### 사용자 판정 질문

- 첫 행동을 바로 알 수 있었는가
- 시설과 몬스터를 어디에 놓아야 하는지 알 수 있었는가
- 중요한 정보가 너무 작거나 가려지지 않았는가
- 전투 중 적의 행동과 명령 대상을 알 수 있었는가
- 패배 원인과 다음 수정 행동을 알 수 있었는가
- 불필요하거나 의미를 알 수 없는 버튼이 남아 있는가
- 이 UI를 정식판 기준으로 사용해도 되는가

## 10. 승인 게이트

자동·수동 targeted PASS만으로 승인 처리하지 않는다. 사용자가 고정 후보를 직접 플레이한 뒤 아래 문구를 명시해야 한다.

```text
V20_UI_OWNER_ACCEPTED
source_sha: 5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1
build_hash: 437a27a391a9fe883da99889157199151b874a9498f02548f63f147bd4d6d8a0
decision: 정식 출시본 이식 승인
```

Web 기준으로 승인할 경우 `build_hash`에는 Web PCK SHA-256 `2def8a3f314ef816bc47d74d33fe18c9868ff1f972e3905aa8704706fc05db4c`를 사용할 수 있다.

새 기능·데이터·자산 수정으로 source SHA 또는 고정 build hash가 바뀌면 이전 승인은 무효다. 승인 전까지 P0, `release/v2.0-product`, 정식 출시선 이식은 시작하지 않는다.

## 11. 다음 작업

1. U5 문서 커밋과 PR을 `release/v2.0`에 병합한다.
2. G1에서 사용자가 위 고정 후보를 직접 플레이한다.
3. 수정 요청이면 U1~U4 해당 화면 범위로 돌아가 새 source와 build hash를 만든다.
4. 명시적 `V20_UI_OWNER_ACCEPTED`이면 그때만 `origin/main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`에서 P0를 시작한다.
