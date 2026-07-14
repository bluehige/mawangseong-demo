# 현재 작업 핸드오프

최종 갱신: 2026-07-14

이 파일은 다음 세션의 단일 진입점이다.

- v0.3 튜토리얼 적 우클릭·Web 갱신: `docs/handoff/V03_TUTORIAL_ENEMY_CLICK_WEB_2026-07-14.md`
- v0.3 소스 통합: `docs/handoff/V03_MAIN_INTEGRATION_2026-07-13.md`
- v0.3 Web 데모: `docs/handoff/WEB_DEMO_V03_2026-07-13.md`
- Web 브랜치 최종 동기화: `docs/handoff/WEB_DEMO_V03_SYNC_2026-07-13.md`
- Web 튜토리얼 포커스 Pages 재배포: `docs/handoff/WEB_DEMO_TUTORIAL_DEPLOY_2026-07-13.md`
- Web 튜토리얼 포커스 재발 방지: `docs/handoff/WEB_DEMO_TUTORIAL_HARDENING_2026-07-13.md`
- Web 튜토리얼 하드닝 게시: `docs/handoff/WEB_DEMO_TUTORIAL_HARDENED_PUBLISH_2026-07-13.md`

## 현재 실행 원칙

- 기본 작업은 변경 범위 관련 테스트만 실행한다.
- 전체 회귀, 전체 플레이와 별도 검수 에이전트는 사용자가 현재 작업에서 명시적으로 요청한 경우에만 실행한다.
- Web export는 `test/web-*`에 커밋·푸시할 수 있지만 `main`, `release/*`, `codex/*`로 병합하지 않는다.

## 현재 계보

| 브랜치·커밋 | SHA | 의미 |
|---|---|---|
| `origin/main` | `21f0c35c3b2a7173487216426251c3492413c764` | 튜토리얼 포커스 하드닝과 배포 핀 검증이 병합된 안정 기준 |
| `release/v0.3` | `af34cad42634759088114043760abafad5c3e94a` | v0.3 통합 PR 원격 계보 |
| `test/web-v0.3` | `eae05e5ce01d3042de590f328e8b7fc74307568b` | 하드닝 PCK와 PCK·WASM LFS가 게시된 Web 기준 |
| `v.02` | `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69` | v0.2 완성 계보 |
| `v.03` | `199d2d0347e78f9c62b1c15e9369231384235900` | 기존 v0.3 완성 계보 |

## 완료 상태

- DAY 01 직접 공격 튜토리얼의 적 판정을 강조 영역과 같은 캐릭터 영역으로 넓히고 실제 우클릭 이벤트 회귀 검사를 추가했다. 새 Web PCK와 Release ZIP 해시를 생성해 배포 정책에 고정했다.
- 미커밋 소스 수정은 튜토리얼 포커스 버그 수정으로 확인해 `7112961`로 보존하고 `main`에 통합했다.
- v0.3 소스 계보는 PR #2와 merge commit `c8eded5`로 `main`에 병합했다.
- `test/web-v0.3`에 181,259,832바이트 하드닝 PCK와 WASM을 Git LFS로 업로드했다.
- Web 데모 전용 push 허용과 소스 PR 차단 정책의 자체 검사는 9/9 PASS다.
- Linux 정책 셸의 성공 종료 코드 표시 수정 `377900c`도 PR #3으로 `main`과 Web 브랜치에 반영했다.
- `test/web-v0.3` 원격 정책 CI `29238842740`은 최종 PASS했다.
- 중복 Web export stash는 원격 브랜치와 LFS 객체 확인 후 제거했다. `pre-v02-switch-20260713` stash만 보존 중이다.
- 고정 좌표 폴백 제거와 실제 컨트롤 기준 회귀 검사를 `a216d8d`, 배포 핀 검증을 `994855b`에 완료하고 PR #6으로 `main`에 병합했다.
- Release ZIP digest, 공개 마커·PCK 크기와 공개 PCK SHA-256을 Pages run `29246085475`에서 모두 검증했다.
- 공개 데모를 실제 브라우저로 열어 1920×1080 Godot 캔버스, 타이틀 화면과 콘솔 오류 0건을 확인했다.

## 관련 테스트

- 튜토리얼 전체 흐름 및 강조된 적 상단 우클릭: PASS
- 데모 스모크: PASS
- 새 Web export·PCK·ZIP 해시 검증: PASS
- Update 3 데이터 계약: 17/17 PASS
- 저장 v4 마이그레이션: 42/42 PASS
- 저장소 정책 자체 검사: 9/9 PASS
- Web PCK 크기·LFS 무결성: PASS
- Release·공개 Pages PCK SHA-256: PASS
- 공개 Web 브라우저 로드: PASS
- 전체 게임 검수·검수 에이전트: NOT_REQUESTED

## 다음 작업 순서

1. 우클릭 수정 PR을 merge commit으로 `main`에 병합
2. `test/web-v0.3`, Release `update3-web-20260713`와 Pages를 새 PCK로 갱신하고 공개 해시 확인
3. 사용자가 정식 출시 검증을 요청한 경우에만 RC1 확정과 전체 게임·Web·브라우저 검수 실행
4. 검수된 최종 `main`에 `v0.3.0` 태그를 만들고 같은 태그의 Release에 정식 빌드 보관

## 아직 하지 않은 작업

- 정식 `v0.2.0`, `v0.3.0` 태그 생성
- 전체 게임·Web·브라우저 출시 검수
