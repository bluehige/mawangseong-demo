# v0.3 튜토리얼 적 우클릭 및 Web 갱신 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-14
- 목표 버전: v0.3 Web 데모 핫픽스
- 작업 브랜치: `codex/v03-tutorial-enemy-click`
- 기준 브랜치 및 SHA: `origin/main` / `0eac1d28f8a1c7274c9a0e499ba05c35f5000526`
- 마지막 구현·워크플로 커밋 SHA: `d546bb85717e6a9188ba62f2b961ca553e135528`
- 원격 푸시 여부: 완료
- 관련 PR 또는 태그: PR #8 / Release `update3-web-20260713` / Pages run `29295761853`

## 2. 이번 세션 목표

- 요청 사항: 튜토리얼 탐험가 우클릭 판정 수정본을 `main`에 병합하고 현재 Web 데모와 Release 자산을 갱신한다.
- 완료 조건: 수정이 merge commit으로 `main`에 포함되고, 새 Web PCK가 `test/web-v0.3`, Release 및 공개 Pages에 동일 해시로 게시된다.
- 범위에서 제외한 사항: 전체 게임 회귀, 전체 플레이, 정식 `v0.3.0` 태그 생성, 별도 검수 에이전트.

## 3. 완료한 작업

- 구현: 적 선택 판정을 발 위치 중심 36px 원형에서 튜토리얼 강조와 같은 104×118px 캐릭터 영역으로 맞췄다.
- 회귀 검사: 실제 `InputEventMouseButton` 우클릭으로 강조된 적의 보이는 상단이 직접 공격 대상이 되는지 확인한다.
- Web export: 구현 SHA `91acdec6ec00c65a438cba9f6cf88e0cfa829744`에서 Godot 4.5.2 Web release export를 생성했다.
- 배포 정책: Release ZIP, 소스 SHA, PCK SHA-256·크기와 수정 식별자를 새 빌드로 고정했다.
- 스토리·데이터·밸런스·저장·그래픽·오디오: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | 보이는 적 캐릭터 영역의 우클릭 판정 | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 실제 우클릭 이벤트 회귀 검사 | 완료 |
| `.github/workflows/deploy-web-demo.yml` | 새 Release ZIP 및 PCK provenance 고정 | 완료 |
| `docs/handoff/V03_TUTORIAL_ENEMY_CLICK_WEB_2026-07-14.md` | 구현·Web 배포 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 생성 모델·원본·`SOURCE.md`·런타임 자산: N/A
- 게임 연결 및 실제 렌더 확인 결과: 그래픽과 오디오 변경 없음

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `TutorialFlowSmokeTest.tscn` | PASS | 신규 상단 우클릭 검사와 `TUTORIAL_FLOW_SMOKE_TEST: PASS` |
| 2 | `DemoSmokeTest.tscn` | PASS | `DEMO_SMOKE_TEST: PASS` |
| 3 | Godot 4.5.2 `--export-release Web` | PASS | 임시 export 디렉터리의 10개 파일 |
| 4 | ZIP 엔트리, PCK 크기·HTML 표기 및 SHA-256 | PASS | 아래 Web 산출물 표 |
| 5 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

### Web 산출물

| 항목 | 값 |
|---|---|
| 소스 SHA | `91acdec6ec00c65a438cba9f6cf88e0cfa829744` |
| PCK 크기 | 181,259,112바이트 |
| PCK SHA-256 | `af5fe8a49d1e9441f30a8cc6b1e0647c1ef723002eaaf63aeba4f01a1150f65a` |
| WASM SHA-256 | `6ead2ac528d007fe9627aae650444f9187f89420d7603c22460d8f3279545240` |
| Release ZIP 크기 | 189,470,675바이트 |
| Release ZIP SHA-256 | `81606b31128e50ffad34a4a5cc9618c6f8f606ddc2077c71f395653d52a4f05f` |
| 수정 식별자 | `tutorial_enemy_click_target` |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `d546bb8` 이후에는 이 핸드오프와 `CURRENT.md`만 변경했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: d546bb85717e6a9188ba62f2b961ca553e135528
- Review range: 0eac1d28f8a1c7274c9a0e499ba05c35f5000526..d546bb85717e6a9188ba62f2b961ca553e135528
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 요청 범위의 `main`, Web 브랜치, Release와 Pages 갱신은 완료됐다.
- 적이 밀집한 경우 넓어진 판정 영역 안에서 클릭점에 가장 가까운 적을 선택한다.
- Actions가 Node.js 20 대상 action을 Node.js 24로 강제 실행한다는 경고를 표시했지만 이번 배포 결과에는 영향이 없었다.
- 전체 출시 검수와 정식 `v0.3.0` 태그는 이번 요청 범위가 아니다.

## 8. 다음 작업 순서

1. 공개 데모에서 추가 사용자 피드백을 관찰한다.
2. 정식 `v0.3.0` 출시를 요청받으면 전체 출시 검수와 SemVer 태그 절차를 진행한다.

## 9. 작업 트리 상태

- 미커밋 파일: 이 문서와 `docs/handoff/CURRENT.md`만 문서 커밋 예정
- 의도하지 않은 기존 변경: 원래 작업공간의 혼합 변경은 `pre-main-tutorial-click-fix-20260714` 스태시에 보존
- 빌드 산출물: `C:/Users/LDK-6248/AppData/Local/Temp/mawangseong-web-click-fix/`
- Release ZIP: `C:/Users/LDK-6248/AppData/Local/Temp/mawangseong-update3-web-20260714-click-fix.zip`

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 검수 대상 최종 SHA 기록
- [x] Web export와 해시 검증
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] PR merge commit으로 `main` 반영
- [x] Web 브랜치·Release·Pages 갱신

## 11. 원격 게시 결과

- `main` merge commit: `ded2e7f705c3f8227eacae1474a6965bcd572f7d`
- `test/web-v0.3` 최종 문서 SHA: `ec9deb18fa4160685d1b7ae80447b3f54ab70bbc`
- Web 정책 CI: `https://github.com/bluehige/mawangseong-demo/actions/runs/29295844563`
- Release: `https://github.com/bluehige/mawangseong-demo/releases/tag/update3-web-20260713`
- Release asset digest: `sha256:81606b31128e50ffad34a4a5cc9618c6f8f606ddc2077c71f395653d52a4f05f`
- Pages run: `https://github.com/bluehige/mawangseong-demo/actions/runs/29295761853`
- 공개 데모: `https://bluehige.github.io/mawangseong-demo/web_Demo/`
