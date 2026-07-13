# 현재 작업 핸드오프

최종 갱신: 2026-07-13

이 파일은 다음 세션의 단일 진입점이다. 최신 상세 기록은 `docs/handoff/V03_MAIN_INTEGRATION_2026-07-13.md`다.

## 현재 실행 원칙

- 기본 작업은 변경 범위 관련 테스트만 실행한다.
- 전체 회귀, 전체 플레이와 별도 검수 에이전트는 사용자가 현재 작업에서 명시적으로 요청한 경우에만 실행한다.
- 테스트용 Web export는 `test/web-*`에 커밋·푸시할 수 있지만 `main`이나 `release/*`로 병합하지 않는다.

## 현재 계보

| 브랜치·커밋 | SHA | 의미 |
|---|---|---|
| `origin/main` | `dc6fad5f2b7fd1bcbad6dd30d652c3ed7f4e453e` | 저장소 운영 정책까지 병합된 현재 안정 기준 |
| `release/v0.3` | `af83c7feca8909c392489590d28e969d1fde9df0` | `main`과 v0.3 게임 계보를 통합한 로컬 merge commit |
| `v.02` | `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69` | v0.2 완성 계보 |
| `v.03` | `199d2d0347e78f9c62b1c15e9369231384235900` | 기존 v0.3 완성 계보 |
| 튜토리얼 패치 | `71129612db771f8cdd4085f5d2b41c1efb1ffe5e` | 미커밋 소스 수정 보존 |

## 이번 통합 결과

- 미커밋 4개 중 두 소스 파일은 실제 튜토리얼 포커스 버그 수정으로 확인해 `7112961`로 커밋했다.
- `web_Demo/index.html`, `web_Demo/index.pck`는 Web 재내보내기 산출물로 확인해 `stash@{0}`에 보존했다.
- `release/v0.3` merge commit `af83c7f`가 최신 `main`, `v.02`, `v.03`, 튜토리얼 패치를 모두 포함한다.
- 소스 통합 트리의 `web_Demo`는 현재 `main` 버전을 유지한다.
- `test/web-*` 직접 push에서만 Web export와 LFS PCK/WASM을 허용하도록 정책을 수정했다.

## 확인된 관련 테스트

- 튜토리얼 전체 흐름: PASS
- Update 3 데이터 계약: 17/17 PASS
- 저장 v4 마이그레이션: 42/42 PASS
- 저장소 정책 자체 검사: 9/9 PASS
- 전체 게임 검수·검수 에이전트: NOT_REQUESTED

## 보존한 Web export

- stash: `stash@{0}` / `v0.3 web export before main integration (sha256 2b6d72f9)`
- PCK SHA-256: `2b6d72f9e9f4606b0b92e571c32ba35e49c85c71420ea3b29dd959d672478731`
- PCK 크기: 181,257,848바이트
- 복원 대상 브랜치: `test/web-v0.3`

## 다음 작업 순서

1. `release/v0.3` 푸시, PR 정책 CI 확인, merge commit으로 `main` 병합
2. 새 `main`에서 `test/web-v0.3` 생성
3. v.03 Web 기준 파일과 `stash@{0}` 복원, LFS 확인, 커밋·푸시
4. 정식 출시 검증을 사용자가 요청한 경우에만 전체 검수, RC1 확정, `v0.3.0` 태그 생성

## 아직 하지 않은 작업

- `release/v0.3` 원격 푸시 및 PR
- `test/web-v0.3` Web export 푸시
- 정식 `v0.2.0`, `v0.3.0` 태그 생성
- 전체 게임·Web·브라우저 출시 검수

