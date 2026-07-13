# Web 데모 튜토리얼 하드닝 게시 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-13
- 목표 버전: v0.3 Web 데모
- 작업 브랜치: `test/web-v0.3`
- 기준 브랜치 및 SHA: `origin/test/web-v0.3` / `ba70da8411763a619de01223cef07ecb3a8b77da`
- 병합한 안정판: `origin/main` / `21f0c35c3b2a7173487216426251c3492413c764`
- 마지막 Web 산출물 커밋 SHA: `e5efa475045a3ecd8f68552f4ed71f27359b33c7`
- 원격 푸시 여부: 최종 문서 커밋과 함께 푸시 예정
- 관련 PR: 소스 PR #6

## 2. 이번 세션 목표

- 튜토리얼 포커스 재발 방지 소스가 포함된 Web export를 `test/web-v0.3`에 게시한다.
- PCK와 WASM을 모두 Git LFS로 추적한다.
- 릴리즈 ZIP과 공개 Pages가 정확한 소스·PCK를 제공하는지 검증할 식별 정보를 포함한다.

## 3. 완료한 작업

- `origin/main`과 Web 산출물을 원격 merge commit `e5efa47`로 통합했다.
- 정상 종료 코드 0으로 생성한 Godot Web release export를 `web_Demo/`에 교체했다.
- `build-version.txt`를 소스 `a216d8d`, PCK SHA-256, 수정 식별자 `tutorial_room_directive_guard`로 갱신했다.
- PCK와 WASM을 모두 Git LFS 포인터로 저장하도록 `.gitattributes`를 보강했다.
- PCK 181,259,832바이트와 `index.html`의 선언 크기가 일치함을 확인했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `.gitattributes` | Web PCK·WASM Git LFS 추적 | 완료 |
| `web_Demo/build-version.txt` | 소스·PCK·수정 식별자 고정 | 완료 |
| `web_Demo/index.html` | 새 PCK 크기 참조 | 완료 |
| `web_Demo/index.pck` | 튜토리얼 하드닝 런타임 | 완료, LFS |
| `web_Demo/index.wasm` | 기존 런타임을 정책에 맞춰 LFS 전환 | 완료, LFS |

## 5. 그래픽과 오디오 자산

- 신규 이미지 생성: 없음
- 런타임 그래픽·오디오 변경: 없음

## 6. 테스트 및 검증

| 순서 | 검증 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 소스 `TutorialFlowSmokeTest` | PASS | 실제 함정 유도 컨트롤 정렬·방 복구·폴백 제거 포함 |
| 2 | 소스 `TutorialUxCapture` | PASS | DAY 2 함정 유도 실화면 정렬 확인 |
| 3 | 소스 `OnboardingFlowSmokeTest` | PASS | 관련 온보딩 흐름 회귀 없음 |
| 4 | Godot Web release export | PASS | 종료 코드 0 |
| 5 | PCK SHA-256·바이트·HTML 선언 크기 | PASS | `e8ed913edcdd40289fdf24b765673979c0ba094594e853876ae495cf4106e56b`, 181,259,832바이트 |
| 6 | PCK·WASM LFS 포인터 | PASS | PCK `e8ed913...`, WASM `6ead2ac...` |
| 7 | 전체 게임·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 요청 범위의 관련 검증만 실행 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: e5efa475045a3ecd8f68552f4ed71f27359b33c7
- Review range: ba70da8411763a619de01223cef07ecb3a8b77da..e5efa475045a3ecd8f68552f4ed71f27359b33c7
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 이 문서 작성 시점에는 Web 브랜치 푸시, Release ZIP 교체, Pages 재배포와 실제 공개 브라우저 확인이 남아 있다.
- 전체 출시 검수는 요청되지 않아 실행하지 않았다.

## 8. 다음 작업 순서

1. `test/web-v0.3`을 푸시하고 저장소 정책 CI를 확인한다.
2. SHA-256 `987ce073189d2d933a8239dde3ff7f27f7f0e1a631b51eec6d9c430a5597c285` ZIP으로 `update3-web-20260713` Release 자산을 교체한다.
3. Pages 워크플로를 실행하고 공개 PCK SHA-256 및 실제 브라우저 로드를 확인한다.
4. 배포 주소와 실행 ID를 핸드오프에 기록한다.

## 9. 작업 트리 상태

- Web 산출물과 최신 `main` 통합은 원격 `e5efa47`에 커밋했다.
- `.gdignore`와 변경되지 않은 아이콘·PNG는 보존했다.
- 원래 작업공간의 동시 진행 변경은 건드리지 않았다.
