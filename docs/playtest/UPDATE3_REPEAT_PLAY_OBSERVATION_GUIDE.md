# Update 3 반복 플레이 자유 선택 관찰 가이드

## 목적과 증거 범위

이 절차는 같은 Update 3 빌드를 여러 사람이 반복 플레이하면서 전선, 성 심장, 연계기를 **자유롭게 선택한 이유와 결과**를 모으기 위한 것이다. 결과는 `human_update3_repeat_observation` 증거로만 저장한다.

Day 30 조합을 강제 배정하는 54회 자동 proxy는 전투 조합의 이상 신호를 찾는 자료다. 강제 배정이므로 플레이어 선택률을 측정하지 않으며, 이 문서의 사람 자유 선택 자료와 합산하지 않는다. 또한 이 관찰은 원 계획의 전체 캠페인 proxy 15회를 대체하지 않는다.

자동 proxy는 18개 pairwise-balanced fractional assignment를 seed 3개로 반복한다. 따라서 전선×심장×연계기의 triple interaction은 해석할 수 없다. 전선마다 실제 도달 가능한 DAY 28 작전 하나도 고정 적용하고, 선택된 modifier가 실제 DAY 30 schedule을 바꿨는지 hard gate로 확인한다. 전선과 고정 작전은 함께 움직이므로 두 효과는 confounded되어 있다.

## 관찰 전 고정 사항

1. 관찰 대상 커밋의 전체 40자 SHA를 확인한다.
2. 모든 참여자가 같은 SHA와 같은 데이터 스키마를 사용한다.
3. 각 세션에서 전선 3개, 심장 3개, 연계기 6개를 모두 선택 가능하게 제공한다.
4. 관찰자 ID에는 이름, 이메일 등 개인정보 대신 고정된 익명 ID를 쓴다.
5. 한 관찰자는 최대 3세션까지만 readiness 표본에 참여한다.

현재 고정 ID는 다음과 같다.

- 전선: `front_hero_oath`, `front_holy_purification`, `front_guild_repossession`
- 심장: `heart_stonebone`, `heart_hungry_maw`, `heart_dream_lantern`
- 연계기: `link_spore_jelly_shelter`, `link_ghostly_evacuate`, `link_moon_scent_hunt`, `link_molten_carapace`, `link_stone_march`, `link_false_beacon_vault`

## 세션 기록

`docs/playtest/templates/UPDATE3_REPEAT_OBSERVATION_TEMPLATE.json`을 복사해 입력 디렉터리에 `session_<고유값>.json`으로 저장한다. 요약기는 입력 디렉터리 바로 아래의 `session_*.json`만 읽는다.

- `session_id`: 모든 파일에서 고유한 세션 ID
- `observer_id`: 같은 사람에게 매번 같은 익명 ID
- `run_number_for_observer`: 해당 관찰자의 1부터 시작하는 실행 번호
- `commit_sha`: 관찰한 빌드의 전체 SHA
- `available`: 그 세션에서 실제로 보인 모든 선택지. readiness 표본은 3/3/6 전체 목록이어야 한다.
- `choices`: 실제 선택한 전선, 심장, 장착·사용 연계기, 출전 인스턴스와 심장 액티브 사용 여부
- `outcome.result`: `win`, `loss`, `abandoned` 중 하나
- `outcome.completed_day`: 마지막으로 도달한 Day, 0~30
- `outcome.ending_catalog_code`: 내부 ending ID가 아니라 v0.3에 등록된 `E01`~`E16` 도감 코드. 엔딩을 보지 못했다면 빈 문자열
- `outcome.day30_combat_time_seconds`: Day 30 전투를 하지 않았다면 `null`, 했다면 0보다 큰 실제 초
- `reason_tags`: 선택 이유를 짧고 일관된 태그로 기록한다. 자유 서술은 `notes`에 둔다.

`win`은 DAY 30 완료, 엔딩 도감 코드, DAY 30 전투 시간이 모두 있어야 한다. DAY 30 전에 끝난 관찰에는 엔딩 코드와 DAY 30 전투 시간을 기록할 수 없고, `abandoned`에는 엔딩 코드를 기록할 수 없다. 이 교차 조건을 위반한 파일은 표본에서 제외된다.

장착 연계기는 최대 2개, 출전 인스턴스는 알려진 인스턴스 1~5개만 기록한다. `used_duo_link_ids`는 `equipped_duo_link_ids`의 부분집합이어야 하며, 사용한 연계기의 두 멤버가 모두 출전 목록에 있어야 한다. 선택하지 않은 항목을 추정해 채우지 않는다.

## 요약 실행

입력과 출력 디렉터리는 분리한다.

```powershell
python tools/ci/update3_repeat_observations.py `
  --input-dir tmp/update3_repeat_observations/sessions `
  --output-dir tmp/update3_repeat_observations/summary `
  --expected-sha <40자-커밋-SHA>
```

결과는 `latest.json`과 한국어 `latest.md`로 생성된다. 자료가 부족해도 요약 파일은 생성되며 CLI 출력이 `NOT_READY`로 표시된다. 스크립트 자체 계약은 다음으로 확인한다.

```powershell
python tools/ci/update3_repeat_observations.py --self-test
```

## Readiness 기준

다음을 모두 만족해야 `READY`다.

- 유효 세션 18개 이상
- 서로 다른 관찰자 6명 이상
- 관찰자별 세션 최대 3개
- 모든 유효 세션에서 전선 3개, 심장 3개, 연계기 6개가 모두 선택 가능
- 각 연계기의 선택 기회 10회 이상
- 스키마 v1 및 대상 SHA 일치

중복 `session_id`와 같은 관찰자의 같은 실행 번호는 한 번만 집계한다. 형식 오류 파일은 제외하고 오류 목록에 남긴다. SHA 또는 스키마가 다른 `session_*.json`이 섞이면 readiness를 통과하지 않는다.

전선·심장·연계기 그룹별 승률은 `win`/`loss` 완료 관찰이 5건 이상일 때만 계산한다. 5건 미만은 `표본 부족`으로 표시한다. 선택 횟수는 플레이어의 자유 선택 분포이고, 자동 proxy의 강제 배정 횟수와 비교하거나 합산해서는 안 된다.
