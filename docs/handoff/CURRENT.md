# 현재 작업 핸드오프

최종 갱신: 2026-07-14

이 파일은 다음 세션의 단일 진입점이다.

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
| `codex/v03-sequential-finalize` 검수 SHA | `0dae916a5354f3df119bae6115c754fc12e1b094` | 전야 마감과 최신 튜토리얼 버그픽스를 함께 검증한 v0.3 소스 |
| `origin/main` 기준 | `8cddba6cdf522024131970fcf0909751ebd17adb` | 최신 튜토리얼 배포 기록까지 포함한 안정 기준 |
| 최신 튜토리얼 구현 | `91acdec6ec00c65a438cba9f6cf88e0cfa829744` | 적 우클릭 판정 버그픽스, 위 검수 SHA에 포함 |
| `release/v0.3` | `af34cad42634759088114043760abafad5c3e94a` | 기존 v0.3 통합 계보 |
| `v.02` | `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69` | v0.2 완성 계보 |

## v0.3 완료 상태

- 세 전선 결전 전야, DAY 28 작전 연결, DAY 29 라이벌 선언과 구저장 정리를 완료했다.
- 최신 `main`의 튜토리얼 적 우클릭 버그픽스와 배포 기록을 merge commit으로 포함했다.
- v0.3 Phase 1~30, 데모, 엔딩과 레거시 시스템 자동 회귀 38/38 PASS다.
- 최신 튜토리얼 직접 흐름 1/1 PASS다.
- 54회 반복 관측과 추가 밸런스 실험은 사용자 지시에 따라 실행하지 않았다.
- 신규 그래픽·오디오·빌드 산출물은 없다.

## 검수 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 0dae916a5354f3df119bae6115c754fc12e1b094
- Review range: 8cddba6cdf522024131970fcf0909751ebd17adb..0dae916a5354f3df119bae6115c754fc12e1b094
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 다음 작업 순서

1. v0.3 마감 브랜치를 원격에 푸시하고 PR의 필수 정책 통과 후 merge commit으로 `main`에 통합한다.
2. 최신 `main`에서 v0.4 전용 브랜치를 만들고 Phase 0→Phase 36 순서로 개발한다.
3. v0.4 완료 후 v0.5, 그다음 v0.6을 같은 방식으로 순차 진행한다.

## 아직 하지 않은 작업

- v0.3 마감 브랜치 원격 푸시·PR·`main` 병합
- 정식 `v0.2.0`, `v0.3.0` SemVer 태그 생성
- v0.4 실제 구현
