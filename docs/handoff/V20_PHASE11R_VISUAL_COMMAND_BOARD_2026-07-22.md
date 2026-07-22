# 제품 2.0 Phase 11R 비주얼 커맨드 보드 재설계 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-22
- 목표 버전: 제품 2.0 Phase 11R 초반 이해도·조작성 수정
- 작업 브랜치: `codex/v20-p11r-visual-redesign`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `a84cfc1aff7e1d5d5a6cd16541571e3efed2fb5e`
- 마지막 기능 커밋 SHA: `1abb2b63b03d3711bc014b9d3b081e9300f7041d`
- 원격 푸시 여부: 문서 작성 시점 미푸시
- 관련 PR 또는 태그: 문서 작성 시점 미생성

## 2. 이번 세션 목표

- 요청 사항: `참고자료/v20_p11r`의 위치·정보 우선순위만 참고하고, 상시 건물 설정과 복잡한 설치 흐름을 제거해 침략 동선·시설·몬스터·전술 명령을 설명 없이 조작할 수 있는 더 완성도 높은 UI/UX로 전체 수정한다.
- 완료 조건: 준비·전투·결과 화면 재설계, 시설·몬스터 click→click 및 drag 실동작, 선택할 때만 상세 표시, 전투 명령의 명시적 대상 지정, 1280×720·1366×768 Web 실조작 검증.
- 범위에서 제외한 사항: DAY 6~30 확장, 밸런스 수치 변경, 실제 사람 6~10명 재평가 결과, 요청되지 않은 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 구현:
  - 준비 화면을 `상단 상태 → 중앙 침략 경로 → 좌측 위협 → 하단 건설/몬스터 도구 → 방어 시작` 구조의 전쟁 탁자형 커맨드 보드로 재구성했다.
  - `건설`과 `몬스터 배치`를 두 개의 명확한 도구로 분리하고, 선택한 도구의 카드만 보여 한 위치에 한 기능만 유지한다.
  - 방 상세는 방을 선택했을 때만 오른쪽에 열리고 닫으면 경로 지도가 전체 폭으로 즉시 복귀한다.
  - 시설·몬스터 click→방 click과 직접 drag를 모두 유지하고, drag 중 유효한 방만 강조한다.
  - 시설 배치 뒤 침략 경로와 첫 교전 위치를 즉시 다시 계산하며 Undo를 같은 하단 도구함에 둔다.
  - 전투 HUD를 상단 상태·좌측 목표·중앙 전장·패턴 경고·하단 3명령으로 재구성했다.
  - 집결·집중·시설 발동을 `명령 선택 → 전장의 방/적/시설 선택 → 발동` 2단계 입력으로 연결하고 ESC 취소, 성공·실패 토스트를 추가했다.
  - 결과 화면을 핵심 원인·잘한 점·다음 주의점 3카드, 기여도 장부, 수비 방식 요약, 다음 행동으로 재구성했다.
- 실제 Web QA 중 수정:
  - 새 준비 보드 영역이 기존 월드 클릭으로도 처리되어 몬스터 도구가 건설로 되돌아가던 이중 입력을 발견했다. 2.0 관리 HUD 전체를 UI 입력 영역으로 등록하고 보드 재생성을 다음 프레임으로 미뤄 해결했다.
  - 도구 전환 뒤 늦게 도착한 반대 종류 drag payload는 배치를 변경하지 못하도록 이중 방어를 추가했다.
  - 전투 명령 발동 후 대상 선택 안내가 남던 잔상을 즉시 제거하도록 수정했다.
- 스토리 및 데이터: 기존 DAY 1~5 encounter, 시설·몬스터·난이도 데이터는 변경하지 않았다.
- 밸런스: 비용·효과·체력·웨이브 수치는 변경하지 않았다.
- 저장 및 호환성: 기존 2.0 placement/session schema를 유지한다. 결과에 수비 하이라이트와 실제 마왕 최대 체력만 추가했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/v20/placement/V20PlacementBoard.gd` | 전쟁 탁자형 준비 보드, 두 도구, 선택형 상세, drag 안전성 | 완료 |
| `scripts/v20/placement/V20PlacementRoomButton.gd` | 육각 방 노드, 경로·유효 대상·선택 강조 | 완료 |
| `scripts/v20/placement/V20MonsterDragButton.gd` | 시설·몬스터 공통 고품질 drag preview | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 관리·전투 정보 구조, 3명령, 대상 안내·토스트 | 완료 |
| `scripts/game/CombatSceneController.gd` | 전술 명령 대상 지정과 실제 전장 클릭 발동 | 완료 |
| `scripts/game/GameRoot.gd` | 관리 UI 이중 입력 차단, 전투 대상 클릭·ESC 취소 | 완료 |
| `scripts/v20/ui/V20ResultScreen.gd` | 3원인 카드·기여도·수비 방식·다음 행동 | 완료 |
| `scripts/v20/session/V20SessionService.gd` | 결과 하이라이트 계산 | 완료 |
| `tools/tests/V20PlacementUxTest.gd` | 두 도구·선택 상세·교차 drag 방어 검증 | 완료 |
| `tools/tests/V20InformationArchitectureTest.gd` | 3해상도 배치·명령 대상 안내 수명 검증 | 완료 |
| `tools/tests/V20TacticalCommandsTest.gd` | 3명령·대상 안내·live HUD 갱신 검증 | 완료 |
| `tools/tests/V20OnboardingRetrySaveTest.gd` | 실제 GameRoot 관리 입력 차단·명령 대상·결과 검증 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: 기존 던전 배경·폰트·UI 자산과 절차적 패널/경로 드로잉 재사용
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: 참고자료의 화면 위치와 정보 우선순위만 반영하고 보라색 박스 형태는 복제하지 않았다. 금색 경로, 흑자색 판, 봉인·명패 계층으로 1280×720·1366×768 실제 Web 렌더를 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V20PlacementUxTest.tscn` | PASS, 41 assertions | 두 도구·시설/몬스터 drag·경로·선택 상세·교차 입력 차단 |
| 2 | `V20InformationArchitectureTest.tscn` | PASS, 42 assertions | 1280×720·1366×768·1920×1080 관리/전투 비겹침, 3명령 |
| 3 | `V20FacilityReworkTest.tscn` | PASS, 29 assertions | 시설 경로·활성·시너지 회귀 |
| 4 | `V20StrategicRoutingTest.tscn` | PASS, 14 assertions | 북·남 경로와 weighted path 회귀 |
| 5 | `V20MonsterRoleGrowthTest.tscn` | PASS, 39 assertions | 역할·표적·시설 synergy 회귀 |
| 6 | `V20TacticalCommandsTest.tscn` | PASS, 27 assertions | 명령력·cooldown·3명령·대상 안내 |
| 7 | `V20DayOneToFiveEncountersTest.tscn` | PASS, 69 assertions | DAY 1~5 encounter·대응·HUD 회귀 |
| 8 | `V20DifficultyEconomyTest.tscn` | PASS, 26 assertions | 난이도·경제·관리 자원 회귀 |
| 9 | `V20OnboardingRetrySaveTest.tscn` | PASS, 41 assertions | 실제 GameRoot 입력·명령·결산·재도전 |
| 10 | Godot 4.5.2 `Web` release export | PASS | PCK 231,596,228 bytes, SHA-256 `6454fa55b35e14aba9ef87cd1daee1bd0eed780acb759328a7bf5dca1ee73f60` |
| 11 | Chromium 1280×720 | PASS | 시설 drag, 몬스터 click/drag, 상세 열기/닫기, 경로 전환, 방어 시작, 대상 지정 명령 |
| 12 | Chromium 1366×768 | PASS | 관리·전투·결과 실제 렌더, 집결 발동, DAY 1 x3 완료, 오류·경고 0 |
| 13 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 저장소 정책에 따라 실행하지 않음 |

- 관련 자동 테스트 합계: 9개 스위트, 328 assertions PASS.
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 요청되지 않은 전체 검수는 필수 범위가 아니다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서만 허용한다.
- Web 테스트 브랜치 검증: build commit `7e7f0df2af02f936c23943f6eceebaa132b05f88`의 PCK/WASM LFS pointer, 실제 파일 크기, SHA-256과 `playtest-build.json`을 대조했고 로컬 검수 산출물과 byte-for-byte 일치했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 7e7f0df2af02f936c23943f6eceebaa132b05f88
- Review range: 7e7f0df2af02f936c23943f6eceebaa132b05f88..7e7f0df2af02f936c23943f6eceebaa132b05f88
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동·로컬 Web에서 재현되는 필수 문제는 없다. 공개 Pages 배포 후 같은 입력 흐름을 다시 확인해야 한다.
- 밸런스 관찰 항목: 새 구조가 실제 초회 사용자의 90초 첫 의미 있는 선택과 DAY 1 이해도를 개선하는지는 새 6~10명 표본으로 측정해야 한다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 사람의 이해도·재도전 의향은 자동 테스트로 대체하지 않는다.

## 8. 다음 작업 순서

1. `codex/v20-p11r-visual-redesign`을 푸시하고 `release/v2.0` 대상 PR로 merge commit 통합한다.
2. 병합 SHA에서 전용 `test/web-*` 브랜치 Web 빌드를 만들고 공개 `/v20-p11r/` 경로에 배포한다.
3. 공개 Chromium에서 시설·몬스터 drag, 명령 대상 지정, DAY 1 결과와 콘솔 오류 0을 재확인한다.
4. 공개 빌드로 6~10명 무설명 블라인드 플레이를 다시 진행한다.

## 9. 작업 트리 상태

- 기능 커밋 직후 상태: 의도한 12개 코드·테스트 파일 커밋 완료.
- 미커밋 파일: 이 핸드오프와 `CURRENT.md` 문서 갱신.
- 의도하지 않은 기존 변경: Godot가 생성한 미추적 UID 5개는 필요한 script sidecar로 확인돼 삭제·스테이징하지 않았다.
- 스태시 또는 별도 작업공간: `tmp/v20_p11r_visual_redesign` clean worktree에서 작업.
- 빌드/캡처 산출물 위치: `%TEMP%/mawang-v20-p11r-web-qa`, `%TEMP%/mawang-v20-p11r-playwright-artifacts`; 저장소 미추적.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 1280×720·1366×768 실제 PC Web 검증 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 사실 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 기능 파일만 커밋
- [ ] 원격 푸시·PR·공개 Web 배포 기록
