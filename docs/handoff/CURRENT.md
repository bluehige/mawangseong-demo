# 현재 작업 핸드오프

최종 갱신: 2026-07-14

이 파일은 다음 세션의 단일 진입점이다.

- v0.4 UI 입력 레이어 방어 작업: `docs/handoff/V04_INPUT_LAYER_GUARD_2026-07-14.md`
- v0.4 순차 개발 마감: `docs/handoff/V04_SEQUENTIAL_FINALIZATION_2026-07-14.md`
- v0.3 순차 개발 마감: `docs/handoff/V03_SEQUENTIAL_FINALIZATION_2026-07-14.md`
- v0.3 최신 튜토리얼 버그픽스·Web 갱신: `docs/handoff/V03_TUTORIAL_ENEMY_CLICK_WEB_2026-07-14.md`
- v0.3 소스 통합: `docs/handoff/V03_MAIN_INTEGRATION_2026-07-13.md`
- 버전별 원문 계획: `docs/design/plans/README.md`

## 현재 실행 원칙

- 과도한 반복 관측은 실행하지 않는다.
- 변경 범위와 직접 관련된 테스트만 실행한다.
- 버전 마감에서는 자동 버그 회귀를 꼼꼼히 실행하고, 전체 플레이·시각 재검수·별도 검수 에이전트는 사용자가 그 작업에서 요청한 경우에만 실행한다.
- 신규 그래픽은 GPT 내부 이미지 생성 도구만 사용하고 `assets/source/imagegen/<version>/` 원본과 `assets/` 런타임 자산을 분리한다.

## 현재 계보

| 브랜치·커밋 | SHA | 의미 |
|---|---|---|
| UI 입력 레이어 `main` 병합 | `592b3a434fde5196d22ee1269e9009d667517264` | PR [#14](https://github.com/bluehige/mawangseong-demo/pull/14)를 merge commit 방식으로 통합 |
| `codex/v04-input-layer-guard` 구현 | `af361d5c64b24e94896a6d31845d0e9fa6e4bda0` | UI 입력 레이어 방어 구현과 직접 영향 테스트 기준 |
| `origin/main` v0.4 병합 | `a8b29e6ee176b96b0f910beb2d5cbf07dc2c4767` | PR #13으로 v0.4 개발본을 merge commit 방식으로 통합한 최신 안정 기준 |
| `codex/v04-sequential-development` 검수 SHA | `51b401fad9d16584a00674e48afdc83bb6219473` | v0.4 Phase 0~36 기능·데이터·자산, 이미지 출처 정책과 최종 버그 테스트 기준 |
| `origin/release/v0.4` | `c0b9534` | PR #12로 v0.4 개발본을 통합한 릴리스 브랜치 기준 |
| `v0.3.0` / PR #10 merge | `ba661015e4bc5be6fec1aa470c5f48d565422597` | v0.3 최종 소스와 최신 튜토리얼 버그픽스를 고정한 정식 태그 |
| `codex/v03-sequential-finalize` 검수 SHA | `0dae916a5354f3df119bae6115c754fc12e1b094` | 전야 마감과 최신 튜토리얼 버그픽스를 함께 검증한 v0.3 소스 |
| `origin/main` v0.3 병합 | `ba661015e4bc5be6fec1aa470c5f48d565422597` | PR #10을 merge commit 방식으로 통합한 안정 기준 |
| 최신 튜토리얼 구현 | `91acdec6ec00c65a438cba9f6cf88e0cfa829744` | 적 우클릭 판정 버그픽스, 위 검수 SHA에 포함 |
| `release/v0.3` | `af34cad42634759088114043760abafad5c3e94a` | 기존 v0.3 통합 계보 |
| `v.02` | `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69` | v0.2 완성 계보 |

## v0.4 개발 완료 상태

- v0.4 Phase 0~36을 계획 순서대로 구현하고 의회 회차 DAY 1~30 실제 진행 경로를 완성했다.
- 최신 `main`의 v0.3 튜토리얼 적 클릭 버그픽스 `91acdec6`를 포함한다.
- Phase별 관련 자동 테스트 36종, Phase 36 통합 285 assertions, 튜토리얼과 데모 스모크가 PASS다.
- 의결·왕관·최종 선언 UI는 1920×1080과 1366×768에서 확인했다.
- 그래픽은 GPT 내부 생성 도구로 만들고 `assets/source/imagegen/` 원본과 런타임 자산을 분리했다.
- PR #12와 #13으로 `release/v0.4` 및 `main` 통합을 완료했으며 정식 `v0.4.0` 태그는 후속 버그픽스 이후 만든다.
- PR #14로 표시 전용 UI 레이어의 클릭 차단을 방지하고 35개 입력 계약 단언을 추가했다.

## 검수 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: af361d5c64b24e94896a6d31845d0e9fa6e4bda0
- Review range: a8b29e6ee176b96b0f910beb2d5cbf07dc2c4767..af361d5c64b24e94896a6d31845d0e9fa6e4bda0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 다음 작업 순서

1. Web 갱신 요청이 이어지면 최신 `main` 태그 기준으로 Web 빌드·배포를 진행한다.
2. 후속 v0.4 버그픽스·출시 검증 뒤 `v0.4.0` 태그를 만든다.
3. 최신 `main`에서 v0.5를 시작한다.

## 아직 하지 않은 작업

- Web 배포 갱신
- 정식 `v0.2.0` SemVer 태그 생성
- 정식 `v0.4.0` 태그와 출시 빌드
- v0.5 및 v0.6 순차 개발
