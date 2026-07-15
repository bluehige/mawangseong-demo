# v0.5 모바일 터치 UI 개선 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5 공개 Web·모바일 플레이테스트
- 작업 브랜치: `codex/v05-mobile-touch-ui`, `codex/v05-mobile-text-readability`, `codex/v05-mobile-tutorial-touch-targets`
- 기준 브랜치 및 SHA: `main` / `0390ebe1866101a65db97fe18fd22321a08523ea`
- 마지막 기능 커밋 SHA: `f0c984b680b27c12c8bbf8586afa8c2f743b17ad`
- 최종 소스 `main` 병합 SHA: `c2400102ce3e1a88760bb944d50c28307419bb66`
- 원격 푸시 여부: 소스와 Web·모바일 공개 빌드 모두 푸시·병합·Pages 배포 완료
- 관련 PR 또는 태그: [소스 PR #27](https://github.com/bluehige/mawangseong-demo/pull/27), [소스 PR #28](https://github.com/bluehige/mawangseong-demo/pull/28), [소스 PR #29](https://github.com/bluehige/mawangseong-demo/pull/29) merge commit 병합 완료 / 신규 태그 없음

## 2. 이번 세션 목표

- 요청 사항: 모바일 버튼 크기·가시성 개선, 우클릭 없는 터치 전용 전투 조작, 선택하기 어려운 지침 UI 개선, 이름 입력 가상 키보드 반복 호출 제거.
- 완료 조건: 모바일 가로 화면에서 큰 핵심 터치 대상이 표시되고, 적을 한 번 탭해 공격 지정할 수 있으며, 이름 화면은 사용자가 입력창을 누르기 전 키보드를 열지 않는다.
- 범위에서 제외한 사항: 네이티브 Android/iOS 패키지, 전체 화면별 재설계, 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 구현: 터치스크린·`--mobile-touch-ui` 인수 기반 모바일 레이아웃 감지와 터치 입력 경로를 추가했다.
- 스토리 및 데이터: 직접 공격 튜토리얼 원문을 탭·우클릭 공용 문구로 바꿨고 모바일 런타임 안내는 모두 `탭`으로 표시한다.
- 밸런스: 변경 없음.
- UI/UX:
  - 모바일 타이틀·이름·대화 버튼과 이름 입력창을 큰 터치 영역으로 재배치했다.
  - 관리 화면에 `사수·총공격·생존` 및 현재 방 지침을 큰 개별 버튼으로 제공하고 건설·몬스터·전투 시작 버튼을 키웠다.
  - 전투 화면 하단에 직접 조종·AI 복귀·스킬 2개·지침·속도·일시정지를 모은 2단 모바일 액션 바를 추가했다.
  - 선택된 몬스터가 있을 때 적 탭은 공격 지정, 직접 조종 중 바닥 탭은 이동 명령으로 처리한다. 데스크톱 우클릭은 유지한다.
  - 모바일 버튼은 고대비 금색 테두리와 더 큰 글꼴을 사용한다.
  - 모바일 공통 텍스트를 1.35배 확대하고 작은 본문은 22, 버튼은 24의 입력 최소값을 적용했다. 버튼 글꼴의 기존 21 상한은 터치 환경에서 제거하고 실제 폭에 맞춰 축소한다.
  - 모바일 튜토리얼은 단계별 필수 몬스터·방을 미리 선택하고 잘못 남은 선택을 자동 교정한다. 강조 링의 외곽 24px과 `여기를 탭` 배지 전체를 실제 액션 영역으로 연결했다.
  - 일반 모바일 유닛·적·관리 몬스터 판정 반경을 각각 96·최대 110·104로 넓히고, 첫 적 강조 링은 184×196 크기로 확대했다.
- 저장 및 호환성: 저장 형식 변경 없음. 데스크톱 레이아웃과 우클릭 조작은 비모바일 환경에서 기존대로 유지한다.
- 키보드: 모바일 이름 화면의 자동 `grab_focus`를 제거하고, 무작위 이름/이름 확정 시 포커스 해제와 가상 키보드 닫기를 수행한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/core/UISettings.gd` | 터치 UI 감지, 모바일 1.35배 텍스트 배율과 글꼴 최소값 | 완료 |
| `scripts/game/GameRoot.gd` | 터치 공격·이동, 모바일 온보딩 레이아웃, 키보드 제어, 튜토리얼 사전 선택·강조 영역 액션 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 모바일 관리 하단 버튼·빠른 지침 바 | 완료 |
| `scripts/game/CombatSceneController.gd` | 모바일 전투 UI 분기와 탭 안내 로그 | 완료 |
| `scripts/ui/HUDController.gd` | 모바일 전투 액션 바, 고대비 스타일, 본문·버튼 글꼴 확대와 폭 맞춤 | 완료 |
| `data/onboarding_flow_dialogue_v0.4.json` | 직접 공격 안내를 탭·우클릭 공용으로 수정 | 완료 |
| `tools/MobileTouchUISmokeTest.gd` | 모바일 터치·키보드·레이아웃 자동 검증 | 완료 |
| `tools/MobileTouchUISmokeTest.tscn` | 모바일 스모크 테스트 실행 씬 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 기존 UI·오디오 자산 재사용
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 844×390 Web 모바일 가로 화면에서 타이틀, 이름, 관리, 전투 UI가 정상 렌더됐고 확대된 텍스트가 이름 안내 화면에서 겹치지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `Godot --headless --path . res://tools/MobileTouchUISmokeTest.tscn -- --mobile-touch-ui` | PASS | `tools/MobileTouchUISmokeTest.gd` 23개 핵심 단언, 사전 선택·배지 탭·다음 화면 복귀·적 강조 링 공격 포함 |
| 2 | `Godot --headless --path . res://tools/TutorialFlowSmokeTest.tscn` | PASS | 데스크톱 튜토리얼·우클릭 호환 |
| 3 | `Godot --headless --path . res://tools/OnboardingFlowSmokeTest.tscn` | PASS | 이름 입력부터 DAY 05 저장 흐름 |
| 4 | Web export 및 844×390 실제 브라우저 확인 | PASS | 타이틀·이름 화면을 키보드 없이 진행하고 첫 관리 튜토리얼 배지 탭으로 슬라임 자동 선택·다음 단계 전환 확인 |
| 5 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청에 따라 직접 영향만 최소 확인 |

- 실제 브라우저에서 모바일 이름 화면이 자동으로 포커스를 얻지 않았고, 무작위 이름만으로 키보드 없이 진행됐다.
- 로컬 브라우저의 과거 저장 데이터로 `회차 seed가 올바르지 않습니다` 자동 저장 경고가 있었으나 신규 모바일 UI·입력 경로와 무관하며 새 테스트 저장소의 자동 검증은 PASS다.

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `f0c984b` 이후 변경은 `docs/handoff/` 문서만 허용한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: f0c984b680b27c12c8bbf8586afa8c2f743b17ad
- Review range: 9236fe1e69cc6cb8ca4db614166184efafa15a2b..f0c984b680b27c12c8bbf8586afa8c2f743b17ad
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 후반부 복합 선택 화면은 기존 고정 레이아웃을 유지하며 버튼 대비·글꼴만 모바일 보정된다. 이번 세션은 초반 온보딩·관리·전투의 핵심 조작을 우선했다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 모바일 공개판은 네이티브 앱이 아닌 가로형 모바일 브라우저 빌드다.

## 8. 배포 결과와 다음 작업

- 소스 PR #29를 merge commit으로 병합했고 최종 소스 `main`은 `c2400102ce3e1a88760bb944d50c28307419bb66`이다.
- [Web 공개 PR #3](https://github.com/bluehige/mawangseong-web-playtest/pull/3)은 `18a6fe1b4d125e19055d07211a4d9954b95c6b70`에 병합했고 [Pages 배포](https://github.com/bluehige/mawangseong-web-playtest/actions/runs/29388737033)가 성공했다. 플레이 URL은 https://bluehige.github.io/mawangseong-web-playtest/ 이다.
- [모바일 공개 PR #3](https://github.com/bluehige/mawangseong-mobile-playtest/pull/3)은 `4bf82851c6f24a1e12ad8a4b68b47066a66392d3`에 병합했고 [Pages 배포](https://github.com/bluehige/mawangseong-mobile-playtest/actions/runs/29388739327)가 성공했다. 플레이 URL은 https://bluehige.github.io/mawangseong-mobile-playtest/ 이다.
- 두 공개 빌드는 동일한 `index.pck` 231,477,848바이트, SHA-256 `673F678B330636BE604BCF35DBB54907B66FD5E382CACFA638357156A7D48FD9`를 사용한다. Pages 검증은 PCK/WASM 크기와 핵심 오디오 포함 여부를 통과했다.
- 모바일 HTML은 `--mobile-touch-ui`를 유지하고 첫 포인터 입력에 전체화면과 가로 잠금을 요청한다. 브라우저가 이를 허용하지 않으면 회전 안내와 수동 가로 전체화면 버튼을 유지한다.
- 다음 작업은 실제 플레이에서 오디오 믹스를 청취하고 필요한 자산만 조정하는 것이다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 최종 소스 `main`과 공개 Web·모바일 `main` 모두 원격과 동기화됐고, 이 핸드오프 문서 커밋 후 작업 트리는 깨끗함
- 미커밋 파일: 없음
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물 위치: 로컬 `tmp/mobile-ui-preview/`, `tmp/mobile-font-preview/`만 사용, Git 미추적

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처 대상 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 소스 PR #29 merge commit 병합
- [x] 공개 Web·모바일 PR #3 병합 및 Pages 재배포 성공
- [x] 최종 핸드오프 문서 커밋과 원격 푸시
