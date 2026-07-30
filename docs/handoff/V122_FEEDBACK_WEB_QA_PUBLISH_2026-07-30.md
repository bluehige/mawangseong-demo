# v1.2.2 사용자 피드백 수정 Web QA 게시 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 제품 버전: 1.2.2
- 소스 브랜치: `codex/v122-ui-simplification`
- 소스 커밋: `5b423c9ef734c310cd5c9c688f9e6d4cf9ffd146`
- 소스 검토 PR: [bluehige/mawangseong-demo#80](https://github.com/bluehige/mawangseong-demo/pull/80), draft
- 테스트 저장소 PR: [bluehige/mawangseong-web-playtest#17](https://github.com/bluehige/mawangseong-web-playtest/pull/17), 병합 완료
- 테스트 저장소 merge commit: `f0b53852d899aeac0dd60317e5818f5f4b1f8bf6`
- Pages 실행: [30520912798](https://github.com/bluehige/mawangseong-web-playtest/actions/runs/30520912798), PASS
- 공개 테스트 주소: https://bluehige.github.io/mawangseong-web-playtest/

## 2. 게시 범위

- DAY 1~5 시각·튜토리얼 개편 누적본
- DAY 1 곱의 전열 봉쇄·후열 화력 직접 선택과 실제 전투·결산 연결
- 모든 수비 몬스터의 샛길 사용과 중간 진입 재탐색
- 금고 침입자 접근·공격과 왕좌 공격 모션
- 동적 전투 오버레이와 함정 애니메이션을 정적 던전 전체 redraw에서 분리한 성능 수정

정식 출시가 아니라 사용자 DAY 1~5 직접 테스트를 위한 데스크톱 Web 후보만 교체했다. 모바일 Web, Windows 출시 후보, 태그와 Release는 건드리지 않았다.

## 3. Web export

- Godot: `4.5.2.stable`
- preset: `Web`, single-threaded, GDExtension 비활성
- 로컬 산출물: `tmp/v122_web_qa_5b423c9/`
- export 로그: ERROR 0, WARNING 0

| 파일 | 크기 | SHA-256 |
|---|---:|---|
| `index.pck` | 242,581,944 bytes | `85c3db1a1fcd47f04ee79e5a46ed0e064ea732bdccfdaccdf4567b09f2c76765` |
| `index.wasm` | 38,047,590 bytes | `6ead2ac528d007fe9627aae650444f9187f89420d7603c22460d8f3279545240` |

- `index.html`의 PCK/WASM 크기와 배포 메타데이터가 실제 파일과 일치한다.
- PCK/WASM은 테스트 저장소의 Git LFS 계약을 유지했다.
- 공개 `playtest-build.json`은 소스 SHA `5b423c9ef734c310cd5c9c688f9e6d4cf9ffd146`을 반환한다.

## 4. 브라우저 UI 검증

실제 Godot Web 실행에서 타이틀 → 새 게임 → 이름 등록 → DAY 1 침입 정보 → 배치 → 곱 선택 → 전열·후열 선택 표식까지 조작했다.

| 화면 크기 | 모드 | 결과 |
|---|---|---|
| 1920×1080 | Full-canvas | PASS |
| 1366×768 | Compact | PASS |
| 1280×720 | Compact | PASS |

- 곱 카드, `전열 봉쇄`, `후열 화력`, 안내 패널, 선택 취소와 방어 시작 영역이 캔버스 안에 유지됐다.
- 텍스트 겹침, 패널 이탈, 버튼 잘림과 잘못된 스케일링을 발견하지 못했다.
- 로컬 실행 콘솔은 ERROR 0, WARNING 0이고 HTML/JS/PCK/WASM 요청은 모두 HTTP 200이었다.
- Pages 배포 뒤 1280×720에서 타이틀 화면을 다시 확인했다. 공개 환경도 콘솔 ERROR 0, WARNING 0이고 모든 런타임 요청이 HTTP 200이다.
- 캡처 증거는 `output/playwright/v122-web-qa-5b423c9/.playwright-cli/`에 있으며 커밋 대상이 아니다.

## 5. 자동 검증

소스 커밋 전 직접 영향 검증:

- Godot headless editor 스크립트 파싱: PASS
- `V122DefenderConnectorTest`: PASS
- `V122EnemyLaneRoutingTest`: PASS
- `V122CommandButtonIntegrationTest`: PASS
- `V122CombatVisualHierarchyTest`: PASS
- `V122CombatUISimplificationTest`: PASS
- `V122FacilityZoneCombatConsumerTest`: PASS
- `V122Day02FeedbackTest`: PASS
- `EngineerPerformanceSmokeTest`: PASS, 20 assertions
- `git diff --check`: PASS
- GitHub Pages workflow의 PCK/WASM 크기·해시·소스 SHA 검증: PASS

## 6. 검수 정책 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `5b423c9ef734c310cd5c9c688f9e6d4cf9ffd146`
- Review range: `cee86be8e9c4baed1fb99b706fab15ca2a51692a..5b423c9ef734c310cd5c9c688f9e6d4cf9ffd146`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS_AND_WEB_PUBLISHED`

## 7. 다음 작업

1. 사용자가 공개 Web 후보에서 DAY 1~5를 직접 테스트한다.
2. 샛길 선택, 금고 내부 침입자 공격, 왕좌 공격 모션과 동적 효과가 겹치는 전투 프레임을 우선 확인한다.
3. DAY 1~5가 완벽하다는 사용자 확인 뒤 같은 UI·전투 기준으로 DAY 6~30을 진행한다.
4. 실제 Windows GPU 장시간 전투와 Windows 새 QA 빌드는 필요 시 별도로 진행한다.

## 8. 아직 하지 않은 작업

- DAY 1~5 사용자 직접 최종 확인
- DAY 6~30 같은 기준 적용
- 전체 회귀와 전체 DAY 1~30 플레이
- 모바일 Web과 실제 모바일 기기 검증
- 이번 수정이 포함된 Windows QA 재빌드와 장시간 GPU 프레임 계측
- 정식 태그, Release, Steam 배포
