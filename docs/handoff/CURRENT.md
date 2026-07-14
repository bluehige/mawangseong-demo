# 현재 작업 핸드오프

최종 갱신: 2026-07-14

이 파일은 다음 세션의 단일 진입점이다.

- Web 튜토리얼 적 우클릭 게시: `docs/handoff/WEB_DEMO_TUTORIAL_ENEMY_CLICK_PUBLISH_2026-07-14.md`
- v0.3 소스 통합: `docs/handoff/V03_MAIN_INTEGRATION_2026-07-13.md`
- v0.3 Web 데모: `docs/handoff/WEB_DEMO_V03_2026-07-13.md`
- Web 브랜치 최종 동기화: `docs/handoff/WEB_DEMO_V03_SYNC_2026-07-13.md`
- Web 튜토리얼 포커스 재배포: `docs/handoff/WEB_DEMO_TUTORIAL_TARGET_FIX_2026-07-13.md`
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
| `origin/main` | `ded2e7f705c3f8227eacae1474a6965bcd572f7d` | 적 우클릭 판정과 새 Web 배포 핀이 병합된 안정 기준 |
| `release/v0.3` | `af34cad42634759088114043760abafad5c3e94a` | v0.3 통합 PR 원격 계보 |
| `test/web-v0.3` | `e5efa475045a3ecd8f68552f4ed71f27359b33c7` | 181,259,832바이트 하드닝 PCK와 PCK·WASM LFS 기준 |
| `v.02` | `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69` | v0.2 완성 계보 |
| `v.03` | `199d2d0347e78f9c62b1c15e9369231384235900` | 기존 v0.3 완성 계보 |

## 완료 상태

- DAY 01 적 우클릭 판정을 강조 영역과 일치시키고 새 Web PCK 181,259,112바이트를 생성했다. Release와 Pages 게시를 진행 중이다.
- 미커밋 소스 수정은 튜토리얼 포커스 버그 수정으로 확인해 `7112961`로 보존하고 `main`에 통합했다.
- v0.3 소스 계보는 PR #2와 merge commit `c8eded5`로 `main`에 병합했다.
- `test/web-v0.3`에 181,257,848바이트 PCK를 Git LFS로 업로드했다.
- Web 데모 전용 push 허용과 소스 PR 차단 정책의 자체 검사는 9/9 PASS다.
- Linux 정책 셸의 성공 종료 코드 표시 수정 `377900c`도 PR #3으로 `main`과 Web 브랜치에 반영했다.
- `test/web-v0.3` 원격 정책 CI `29238842740`은 최종 PASS했다.
- 중복 Web export stash는 원격 브랜치와 LFS 객체 확인 후 제거했다. `pre-v02-switch-20260713` stash만 보존 중이다.
- 공개 Pages가 이전 206,275,120바이트 PCK를 제공하던 상태를 확인하고, 181,257,848바이트 수정 PCK 재배포를 준비했다.
- 고정 좌표 폴백 제거와 실제 컨트롤 기준 회귀 검사를 `a216d8d`, 배포 핀 검증을 원격 `994855b`까지 완료했고 소스 PR·Web 재배포를 준비했다.
- `test/web-v0.3`에 하드닝 PCK를 교체하고 PCK·WASM을 모두 Git LFS로 전환했다.

## 관련 테스트

- 튜토리얼 전체 흐름 및 강조된 적 상단 우클릭: PASS
- 데모 스모크: PASS
- 새 Web export·PCK·ZIP 해시 검증: PASS
- Update 3 데이터 계약: 17/17 PASS
- 저장 v4 마이그레이션: 42/42 PASS
- 저장소 정책 자체 검사: 9/9 PASS
- Web PCK 크기·LFS 무결성: PASS
- 전체 게임 검수·검수 에이전트: NOT_REQUESTED

## 다음 작업 순서

1. `test/web-v0.3` push와 LFS·정책 CI 확인
2. Release `update3-web-20260713` ZIP 교체와 Pages 공개 해시 확인
3. 사용자가 정식 출시 검증을 요청한 경우에만 RC1 확정과 전체 게임·Web·브라우저 검수 실행
4. 검수된 최종 `main`에 `v0.3.0` 태그를 만들고 같은 태그의 Release에 정식 빌드 보관

## 아직 하지 않은 작업

- 정식 `v0.2.0`, `v0.3.0` 태그 생성
- 전체 게임·Web·브라우저 출시 검수
