# 4차 업데이트 Phase 0 기준 감사

## 감사 기준

- 감사일: 2026-07-14
- 목표 버전: v0.4.0
- 작업 브랜치: `codex/v04-sequential-development`
- 기준 브랜치 및 SHA: `origin/main` / `af9ff09cd47fce181e9457b32b9409fa54b9a816`
- v0.3 출시 소스 태그 및 SHA: `v0.3.0` / `ba661015e4bc5be6fec1aa470c5f48d565422597`
- 제품 버전: `0.3.0`
- 저장 포맷: v4
- 4차 계획 원문 SHA-256: `63adc0c12fffd9a1272ecf025b262ba4a104806c0ebfe93b7f1ba2070dbf7904`

이 감사는 Phase 0에 따라 문서만 변경한다. 런타임, JSON, 씬, 그래픽과 밸런스 수치는 변경하지 않는다.

## v0.3 완료 기준선

- PR #10 merge commit `ba661015`에 결전 전야, DAY 28 작전 연결, DAY 29 라이벌 선언과 최신 튜토리얼 적 우클릭 버그픽스가 포함됐다.
- 같은 커밋을 이동하지 않는 `v0.3.0` 태그로 고정했다.
- v0.3 Phase 1~30, 데모, E00~E16과 레거시 시스템 자동 회귀는 38/38 PASS다.
- 최신 튜토리얼 직접 흐름은 1/1 PASS다.
- 저장소의 `data/**/*.json` 45개를 다시 파싱했고 오류는 0건이다.
- 전체 반복 관측과 시각 재검수는 사용자 지시에 따라 실행하지 않았다. 이 항목은 v0.4 착수 차단 조건으로 취급하지 않는다.

## Update 3 동결 ID

### 전선

- `front_hero_oath`
- `front_holy_purification`
- `front_guild_repossession`

### 심장

- `heart_stonebone`
- `heart_hungry_maw`
- `heart_dream_lantern`

### 합동기

- `link_spore_jelly_shelter`
- `link_ghostly_evacuate`
- `link_moon_scent_hunt`
- `link_molten_carapace`
- `link_stone_march`
- `link_false_beacon_vault`

### Update 3 엔딩

| 코드 | ID |
|---|---|
| E12 | `ending_holy_open_gate` |
| E13 | `ending_off_ledger_independence` |
| E14 | `ending_living_castle_voice` |
| E15 | `ending_linked_corridors` |
| E16 | `ending_three_front_armistice` |

## 책임 위치와 확장 경계

- 기존 데이터: `data/`와 `data/regular_version/update3/`
- 전선·심장·합동기·연대기: `scripts/systems/fronts/`, `hearts/`, `duo_links/`, `chronicle/`
- 저장 v1~v4: `scripts/systems/save/`
- 화면: `scenes/ui/screens/`, `scenes/ui/hud/`
- 통합 계층: `scripts/game/GameRoot.gd`, `scripts/game/CombatSceneController.gd`
- 자동 검사: `tools/tests/`, `tools/ci/`
- 생성 원본: `assets/source/imagegen/`

`GameRoot.gd`는 10,726줄, `CombatSceneController.gd`는 4,701줄이다. v0.4의 의회, 지역, 전초기지, 다층, 왕관 책임은 새 서비스로 분리하고 두 통합 파일에는 화면 전환과 이벤트 연결만 둔다.

## 반복 관측 해석

- `heart_auto_profiles.json`의 수치는 정적 예상치이며 플레이어 선택률이 아니다.
- Phase 30에는 18개 배치 × 3개 시드 관측 계약이 존재하지만 이번 Phase 0에서 54회 실행하지 않았다.
- 사용자 지시인 과도한 관측 금지를 우선하며, v0.4에서는 각 Phase 직접 테스트와 Phase 36 최종 버그 회귀만 수행한다.
- 선택률·재미·장기 피로도는 자동 승률로 표현하지 않고 향후 명시적으로 요청된 사람 관측과 분리한다.

## v0.4 선결 결정

1. 신규 데이터는 저장소 관례에 맞춰 `data/regular_version/update4/`에 둔다.
2. `rival_brassa`, `rival_vesper`, `rival_mirella`를 카탈로그 ID와 관계 키에 함께 사용한다.
3. 몬스터 instance ID는 기존 소문자 관례를 유지한다.
4. 계획 예시의 `slime_rescue_alchemist` 대신 실제 ID `slime_rescue_alchemy_gel`을 사용한다.
5. 저장 v5는 v4 옆의 추가 sidecar가 아니라 이어하기·검증·복구의 권위 있는 envelope로 승격한다.
6. 진행 중 v4 회차는 `front_chronicle_legacy_v4`로 완주시키고 의회 기능을 중간 삽입하지 않는다.
7. 의회 모드 Stage 03 출전 한도 5명은 기존 전선 모드의 4명을 전역 변경하지 않고 모드 전용 규칙으로 구현한다.

## Phase 0 결론

- v0.3 출시 소스와 저장 v4 기준선: 동결 완료
- 직접 관련 자동 회귀: PASS
- 미완료 v0.3 런타임·스토리 필수 항목: 없음
- 반복 관측: 사용자 지시에 따라 제외
- v0.4 Phase 1 착수 판정: **GO**

