# Web 데모 튜토리얼 하드닝 게시 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-13
- 목표 버전: v0.3 Web 데모
- 작업 브랜치: `test/web-v0.3`
- 기준 SHA: `ba70da8411763a619de01223cef07ecb3a8b77da`
- 병합한 안정판: `21f0c35c3b2a7173487216426251c3492413c764`
- Web 산출물 검토 SHA: `e5efa475045a3ecd8f68552f4ed71f27359b33c7`
- Web 브랜치 최종 SHA: `eae05e5ce01d3042de590f328e8b7fc74307568b`
- 원격 푸시 여부: 완료

## 2. 완료한 작업

- `main`의 튜토리얼 포커스 하드닝과 정상 종료 코드 0으로 생성한 Web export를 merge commit으로 통합했다.
- `build-version.txt`에 소스 `a216d8d`, PCK SHA-256과 `tutorial_room_directive_guard` 수정 식별자를 기록했다.
- PCK와 WASM을 모두 Git LFS로 추적했다.
- 고정 ZIP으로 Release 자산을 교체하고 Pages를 재배포했다.
- 배포 워크플로가 공개 PCK를 다시 내려받아 SHA-256까지 일치함을 확인했다.

## 3. Web 산출물

| 항목 | 값 | 결과 |
|---|---|---|
| PCK 크기 | 181,259,832바이트 | PASS |
| PCK SHA-256 | `e8ed913edcdd40289fdf24b765673979c0ba094594e853876ae495cf4106e56b` | PASS |
| WASM SHA-256 | `6ead2ac528d007fe9627aae650444f9187f89420d7603c22460d8f3279545240` | PASS |
| Release ZIP SHA-256 | `987ce073189d2d933a8239dde3ff7f27f7f0e1a631b51eec6d9c430a5597c285` | PASS |
| PCK·WASM Git LFS | 두 파일 모두 LFS pointer 및 원격 객체 확인 | PASS |

## 4. 테스트 및 검증

| 검증 | 결과 | 근거 |
|---|---|---|
| 저장소 정책 로컬 검사 | PASS | 14 final files, 15 commits |
| Web 브랜치 정책 CI | PASS | run `29246011409` |
| Release asset digest | PASS | GitHub digest가 고정 ZIP SHA-256과 일치 |
| Pages provenance 검증 | PASS | run `29246085475` |
| 공개 마커·HTML·PCK 크기 | PASS | 소스·수정 식별자·181,259,832바이트 일치 |
| 공개 PCK SHA-256 | PASS | 워크플로가 공개 PCK 전체 다운로드 후 검증 |
| 실제 브라우저 로드 | PASS | 1920×1080 Godot 캔버스, 타이틀 화면, 콘솔 오류 0건 |
| 전체 게임·전체 플레이 출시 검수 | NOT_REQUESTED | 관련 버그 수정과 재배포 범위만 검증 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: e5efa475045a3ecd8f68552f4ed71f27359b33c7
- Review range: ba70da8411763a619de01223cef07ecb3a8b77da..e5efa475045a3ecd8f68552f4ed71f27359b33c7
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 5. 원격 주소

- Web branch: `https://github.com/bluehige/mawangseong-demo/tree/test/web-v0.3`
- Release: `https://github.com/bluehige/mawangseong-demo/releases/tag/update3-web-20260713`
- Pages run: `https://github.com/bluehige/mawangseong-demo/actions/runs/29246085475`
- 공개 데모: `https://bluehige.github.io/mawangseong-demo/web_Demo/`

## 6. 미해결 항목

- 이번 요청 범위의 미해결 필수 항목은 없다.
- 정식 `v0.3.0` 태그와 전체 출시 검수는 사용자가 별도로 요청할 때 진행한다.
