# Web 데모 튜토리얼 적 우클릭 게시 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-14
- 목표 버전: v0.3 Web 데모 핫픽스
- 작업 브랜치: `test/web-v0.3`
- 기준 브랜치 및 SHA: `origin/test/web-v0.3` / `eae05e5ce01d3042de590f328e8b7fc74307568b`
- 병합된 `main`: `ded2e7f705c3f8227eacae1474a6965bcd572f7d`
- 소스 구현 SHA: `91acdec6ec00c65a438cba9f6cf88e0cfa829744`
- Web 산출물 검토 SHA: `7adbbbe90cdfb5d66ef38d80857f6ca46fbcf014`
- 원격 푸시 여부: 문서 작성 시점 미푸시
- 관련 PR 또는 태그: PR #8 / Release `update3-web-20260713`

## 2. 이번 세션 목표

- 요청 사항: 적 우클릭 판정 수정이 포함된 현재 Web 데모와 Release 버전을 게시한다.
- 완료 조건: `test/web-v0.3`, Release ZIP, Pages 공개 PCK가 동일한 새 해시를 제공한다.
- 범위에서 제외한 사항: 전체 게임 회귀, 전체 플레이, 정식 `v0.3.0` 태그, 별도 검수 에이전트.

## 3. 완료한 작업

- `main`에 병합된 적 클릭 판정 구현을 Web 브랜치에 적용했다.
- Godot 4.5.2 Web release export의 PCK와 HTML 크기 표기, `build-version.txt`를 갱신했다.
- 기존과 동일한 WASM 및 JavaScript 파일은 새 커밋에 중복 포함하지 않았다.
- PCK는 Git LFS pointer로 스테이징하고 원격 push 대상으로 준비했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | 보이는 적 영역 우클릭 판정 | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 실제 우클릭 회귀 검사 | 완료 |
| `web_Demo/build-version.txt` | 새 소스·PCK·수정 식별자 | 완료 |
| `web_Demo/index.html` | 새 PCK 바이트 크기 | 완료 |
| `web_Demo/index.pck` | 수정 코드가 포함된 Web 런타임 | 완료 |
| `docs/handoff/WEB_DEMO_TUTORIAL_ENEMY_CLICK_PUBLISH_2026-07-14.md` | Web 게시 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 현재 배포 상태 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 신규 또는 변경 그래픽·오디오: 없음
- `SOURCE.md`: N/A

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `TutorialFlowSmokeTest.tscn` | PASS | 신규 상단 우클릭 회귀 검사 포함 |
| 2 | `DemoSmokeTest.tscn` | PASS | `DEMO_SMOKE_TEST: PASS` |
| 3 | Godot 4.5.2 Web release export | PASS | 정상 종료 코드 0 |
| 4 | PCK SHA-256·크기와 HTML 표기 | PASS | 아래 산출물 표 |
| 5 | PCK Git LFS pointer | PASS | `git lfs status` |
| 6 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

### Web 산출물

| 항목 | 값 |
|---|---|
| PCK 크기 | 181,259,112바이트 |
| PCK SHA-256 | `af5fe8a49d1e9441f30a8cc6b1e0647c1ef723002eaaf63aeba4f01a1150f65a` |
| WASM SHA-256 | `6ead2ac528d007fe9627aae650444f9187f89420d7603c22460d8f3279545240` |
| Release ZIP 크기 | 189,470,675바이트 |
| Release ZIP SHA-256 | `81606b31128e50ffad34a4a5cc9618c6f8f606ddc2077c71f395653d52a4f05f` |
| 수정 식별자 | `tutorial_enemy_click_target` |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 7adbbbe90cdfb5d66ef38d80857f6ca46fbcf014
- Review range: eae05e5ce01d3042de590f328e8b7fc74307568b..7adbbbe90cdfb5d66ef38d80857f6ca46fbcf014
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 문서 작성 시점에는 Web 브랜치 push, Release ZIP 교체와 Pages 배포가 남아 있다.
- CDN 또는 브라우저 캐시가 배포 직후 잠시 이전 파일을 제공할 수 있다.

## 8. 다음 작업 순서

1. `test/web-v0.3`에 직접 push하고 정책 CI와 LFS 객체 업로드를 확인한다.
2. Release ZIP을 새 고정 ZIP으로 교체한다.
3. Pages 워크플로를 실행해 공개 마커·HTML·PCK 크기와 SHA-256을 확인한다.

## 9. 작업 트리 상태

- 의도하지 않은 기존 변경: 없음
- 로컬 Web 작업공간: `C:/Users/LDK-6248/AppData/Local/Temp/mawangseong-web-branch-20260714`
- Release ZIP: `C:/Users/LDK-6248/AppData/Local/Temp/mawangseong-update3-web-20260714-click-fix.zip`

## 10. 종료 체크리스트

- [x] 구현·관련 테스트·Web export 완료
- [x] 검수 대상 SHA와 산출물 해시 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] Web 브랜치 및 LFS push
- [ ] Release 자산 교체
- [ ] Pages 배포와 공개 해시 확인
