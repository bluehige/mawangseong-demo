# V130R Step8 — 꼬깃 시트 교체·DAY 1~30 난이도 재조정

> 최신 정정: 2026-10-17 09:08 사용자 지시에 따라 DAY 29 전투 추가를 되돌렸다. 현재 DAY 29는 준비일(전투 없음)이며, 아래 0104 결과 중 DAY 29 전투 수치는 역사 기록이다. 최종 근거는 문서 끝의 §11을 따른다.

## 1. 메타데이터

- 작성일: 2026-10-17 KST. WORKSTREAM_ID: V130R_STEP8_BALANCE.
- 목표 버전: 1.3.0. 버전/manifest 변경 없음.
- 작업 브랜치: `codex/v130r-defense-layout`.
- 기준 브랜치 및 SHA: 사용자 지정 0102 `35de2147fb75e097abefa5abf5d5436e627b8771`.
- 마지막 구현 커밋 SHA / Reviewed SHA: `acc253c8a4908a3803652db2e74d7f97c14738d7`. 이후 변경은 `docs/handoff/`만 허용한다.
- 꼬깃 채택 출처: `codex/v130r-monsters`, 0103 `a34444eb342d5525a8dca22637d5524690d47d33`.
- 원격 푸시 여부: 없음. push·main·태그·Steam·PR·공개 배포 작업 없음.
- 권위 한계: 로컬 main 부재. 캐시 origin/main=`0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`; 원격 최신성 미확정. 조회/fetch 없이 사용자 지정 기준에서 진행했다.

## 2. 이번 세션 목표

0103 꼬깃 채택 시트를 정확히 교체하고 실제 4방향·몸 높이·이름표를 확인한다. 새 지도·수비 칸·24종 카탈로그에서 예상 성장 레벨의 추천/몰빵 배치를 각각 10시드, DAY 1~30 비교하고 요청 곡선·금고 손실·대표 전투 화면을 제공한다. 개인 세이브와 공개 배포, 전체 회귀/전체 플레이/성능/export/별도 검수 에이전트는 범위 밖이다.

## 3. 완료한 작업

- 요청한 `git checkout codex/v130r-monsters -- assets/sprites/v130r/quarter_final/crumpled_map`을 적용했다. 런타임 6파일과 PNG 4개는 0103 채택본 그대로다.
- 웨이브 HP·공격 배율·병력·생성 간격을 조정하고, 교전 담당 전열과 목표 전진 병력을 분리했다. 일반 접촉을 지나 목표로 진격하는 병력도 강제 도발에는 막힌다. 일부 전열의 목표 전진 확률: DAY17 5%, DAY22 5%.
- 생성 시각 ±0.35초와 입구 갈림길을 시드로 분산했다. 도둑은 50% 확률로 실제 금고 쪽을 택하고, 조사관은 50% 확률로 결계 핵을 경유한 뒤 원래 옥좌 목표로 복귀한다.
- 추천 배치는 임프와 꼬깃의 옥좌 수비 우선순위를 높였다. 기존 방어·공격·지원 역할 및 몬스터 기본/스킬 수치는 변경하지 않았다.
- 원본 DAY29는 빈 웨이브였다. 사용자가 27~30 전일 곡선을 요청한 뜻으로 해석해 DAY28 기반 DAY29 전투를 추가했다. 승인 지도에서는 전투 시작 가능하며 구 지도/기존 캠페인의 준비일 게이트·스토리는 변경하지 않았다.
- 이전/이후 각 600행(30일×2배치×10시드)을 보존했다. 모든 최종 행의 실제 웨이브가 `data/waves.json`과 일치하며 시간 초과는 0이다. 원본 DAY29 20행은 무전투 종료다.
- 추천 30/30일이 요청 승률·평균 옥좌 HP 범위다. F구간 몰빵 패배는 10/10일. 추천에서 실제 금고 순손실이 발생하며 도둑 등장일 평균은 0~100금이다.
- 저장 형식·스토리·보상·몬스터 기본 수치·스킬 수치·버전 변경 없음. 개인 세이브 접근/수정 없음. 모든 실행은 격리 APPDATA/LOCALAPPDATA와 시험 복사본을 사용했다.

### 시뮬레이션 가정 표

| 항목 | 가정 / 적용 범위 |
|---|---|
| 성장 | Lv=1+floor(max(DAY−합류DAY,0)/3). 실제 누적 캠페인 경험치를 재현하지 않는 독립 스냅샷이며, 성장 자동 지급 기능을 추가한 것이 아니다. |
| 레벨별 수치 | 기존 공식 HP+20 / 공격+3 / 방어+1. 기본 이동·공격 간격·사거리와 역할 유지. |
| 기본/계약 | 기본4종과 모리·돌콩 계약은 DAY1 합류. 신규종은 데이터 join_day/FALLBACK 적용. |
| 소유/해금 | 전선·의회 미완료. 카탈로그24종 전원 동시 소유·출전 조건은 아니다. 실제 선정 인원과 유지비는 비교표에 이전→이후로 공개했다. |
| 보너스 | 전문화·기억·진급·유대 보너스·굶주림·원정·수동 지휘/스킬 미적용. 기본 자동 스킬/패시브는 활성. |
| 초기 자원 | 옥좌1500, 금1200, 마나600. 식량은 당일 창고 한도, 추천 유지비는 당일 수입 이내. |
| 수입/창고 | DAY1~14:15/30, 15~19:23/45, 20~26:30/60, 27~30:34/75. |
| 지도 | DAY1~14 F, DAY15~30 E. D/C 도면 미확정으로 후반도 E다. |
| 추천 | 실제 제품 auto_place의 합법적·중복 없는 수비 칸. 이전은 원본0102의 웨이브와 추천 알고리즘, 이후는 최종 웨이브와 추천 알고리즘. |
| 몰빵 | 같은 추천 병력을 병영 앞 동일 수비 칸에 강제로 겹친 스트레스 배치. 일반 UI 정원 초과 조건이며 합법적인 수동 배치 모집단의 승률과 동일시할 수 없다. |
| 반복/간격 | seed130800~130809, 날짜마다 독립 초기화, 프로젝트 기본 물리 갱신과 같은 고정 1/60초. 초기15Hz 후보는30Hz 점검에서 차이가 확인돼 폐기했다. |
| 평균/승률 | 패배의 HP0을 평균에 포함. 금고 손실은 회수를 반영한 순손실. 승률은 10회 표본 비율이며 실제 캠페인 모집단 추정이나 신뢰구간을 뜻하지 않는다. |

### DAY별 예상 Lv

| DAY | 기본4종·계약 Lv | 신규종 Lv |
|---:|---:|---|
| 1 | 1 | — |
| 2 | 1 | — |
| 3 | 1 | — |
| 4 | 2 | rat_union:1 |
| 5 | 2 | crumpled_map:1, rat_union:1 |
| 6 | 2 | crumpled_map:1, rat_union:1, river_frog:1 |
| 7 | 3 | crumpled_map:1, rat_union:2, river_frog:1 |
| 8 | 3 | crumpled_map:2, glue_snail:1, rat_union:2, river_frog:1 |
| 9 | 3 | crumpled_map:2, glue_snail:1, rat_union:2, river_frog:2 |
| 10 | 4 | crumpled_map:2, glue_snail:1, river_frog:2, under_bed_shadow:1 |
| 11 | 4 | crumpled_map:3, glue_snail:2, river_frog:2, under_bed_shadow:1 |
| 12 | 4 | crumpled_map:3, glue_snail:2, river_frog:3, under_bed_shadow:1 |
| 13 | 5 | bridge_troll:1, glue_snail:2, river_frog:3 |
| 14 | 5 | bridge_troll:1, glue_snail:3, river_frog:3 |
| 15 | 5 | bridge_troll:1, candle_wisp:1, crumpled_map:4, glue_snail:3, rat_union:4, river_frog:4, under_bed_shadow:2 |
| 16 | 6 | bridge_troll:2, candle_wisp:1, crumpled_map:4, glue_snail:3, rat_union:5, river_frog:4, under_bed_shadow:3 |
| 17 | 6 | bridge_troll:2, candle_wisp:1, crumpled_map:5, glue_snail:4, rat_union:5, river_frog:4, under_bed_shadow:3 |
| 18 | 6 | bridge_troll:2, candle_wisp:2, crumpled_map:5, curse_doll:1, glue_snail:4, rat_union:5, river_frog:5, under_bed_shadow:3 |
| 19 | 7 | bridge_troll:3, candle_wisp:2, crumpled_map:5, curse_doll:1, glue_snail:4, rat_union:6, river_frog:5, under_bed_shadow:4 |
| 20 | 7 | bridge_troll:3, candle_wisp:2, crumpled_map:6, curse_doll:1, glue_snail:5, mole_digger:1, rat_union:6, river_frog:5, under_bed_shadow:4 |
| 21 | 7 | bridge_troll:3, candle_wisp:3, crumpled_map:6, curse_doll:2, glue_snail:5, mole_digger:1, rat_union:6, river_frog:6, under_bed_shadow:4 |
| 22 | 8 | bridge_troll:4, candle_wisp:3, crumpled_map:6, curse_doll:2, glue_snail:5, mole_digger:1, rat_union:7, river_frog:6, under_bed_shadow:5 |
| 23 | 8 | bridge_troll:4, candle_wisp:3, crumpled_map:7, curse_doll:2, glue_snail:6, mole_digger:2, rat_union:7, river_frog:6, under_bed_shadow:5 |
| 24 | 8 | bridge_troll:4, candle_wisp:4, crumpled_map:7, curse_doll:3, glue_snail:6, mole_digger:2, rat_union:7, river_frog:7, under_bed_shadow:5 |
| 25 | 9 | bridge_troll:5, candle_wisp:4, crumpled_map:7, glue_snail:6, hollow_armor:1, mole_digger:2, rat_union:8, river_frog:7, under_bed_shadow:6 |
| 26 | 9 | bridge_troll:5, candle_wisp:4, crumpled_map:8, glue_snail:7, hollow_armor:1, mole_digger:3, rat_union:8, river_frog:7, under_bed_shadow:6 |
| 27 | 9 | bridge_troll:5, candle_wisp:5, crumpled_map:8, glue_snail:7, hollow_armor:1, mole_digger:3, rat_union:8, river_frog:8, under_bed_shadow:6 |
| 28 | 10 | bridge_troll:6, candle_wisp:5, crumpled_map:8, glue_snail:7, hollow_armor:2, mole_digger:3, rat_union:9, river_frog:8, under_bed_shadow:7 |
| 29 | 10 | bridge_troll:6, candle_wisp:5, crumpled_map:9, glue_snail:8, hollow_armor:2, mole_digger:4, rat_union:9, river_frog:8, under_bed_shadow:7 |
| 30 | 10 | bridge_troll:6, candle_wisp:6, crumpled_map:9, glue_snail:8, hollow_armor:2, mole_digger:4, rat_union:9, river_frog:9, under_bed_shadow:7 |

### DAY 1~30 결과

| DAY | 기본/계약 Lv | 이전 추천 승률/HP | 이후 추천 승률/HP | 이후 몰빵 승률/HP | 금고 손실 평균 |
|---:|---:|---|---|---|---|
| 1 | 1 | 100%/100.0% | 100%/87.0% | 0%/0.0% | 0금 |
| 2 | 1 | 100%/100.0% | 100%/94.7% | 0%/0.0% | 100금 |
| 3 | 1 | 100%/100.0% | 100%/91.6% | 0%/0.0% | 100금 |
| 4 | 2 | 100%/100.0% | 100%/86.6% | 0%/0.0% | 0금 |
| 5 | 2 | 100%/100.0% | 100%/71.0% | 0%/0.0% | 0금 |
| 6 | 2 | 100%/100.0% | 100%/70.7% | 0%/0.0% | 0금 |
| 7 | 3 | 100%/100.0% | 100%/81.8% | 0%/0.0% | 0금 |
| 8 | 3 | 100%/100.0% | 100%/80.1% | 0%/0.0% | 0금 |
| 9 | 3 | 100%/100.0% | 100%/80.6% | 0%/0.0% | 0금 |
| 10 | 4 | 100%/100.0% | 100%/76.7% | 0%/0.0% | 0금 |
| 11 | 4 | 100%/100.0% | 90%/83.6% | 0%/0.0% | 0금 |
| 12 | 4 | 100%/100.0% | 100%/60.9% | 0%/0.0% | 0금 |
| 13 | 5 | 100%/100.0% | 100%/78.0% | 0%/0.0% | 100금 |
| 14 | 5 | 100%/100.0% | 100%/82.8% | 0%/0.0% | 100금 |
| 15 | 5 | 100%/100.0% | 90%/47.0% | 0%/0.0% | 0금 |
| 16 | 6 | 100%/100.0% | 90%/74.9% | 0%/0.0% | 0금 |
| 17 | 6 | 100%/100.0% | 90%/58.9% | 0%/0.0% | 0금 |
| 18 | 6 | 100%/100.0% | 90%/50.6% | 0%/0.0% | 0금 |
| 19 | 7 | 100%/100.0% | 80%/53.7% | 10%/10.0% | 0금 |
| 20 | 7 | 100%/100.0% | 90%/62.4% | 70%/67.0% | 0금 |
| 21 | 7 | 100%/100.0% | 80%/59.2% | 30%/29.4% | 0금 |
| 22 | 8 | 100%/100.0% | 90%/67.1% | 0%/0.0% | 0금 |
| 23 | 8 | 100%/100.0% | 80%/73.1% | 0%/0.0% | 0금 |
| 24 | 8 | 100%/100.0% | 80%/57.1% | 70%/68.6% | 0금 |
| 25 | 9 | 100%/100.0% | 90%/54.1% | 90%/78.9% | 0금 |
| 26 | 9 | 100%/100.0% | 80%/54.6% | 90%/87.1% | 0금 |
| 27 | 9 | 100%/100.0% | 90%/41.1% | 90%/80.1% | 0금 |
| 28 | 10 | 100%/100.0% | 90%/42.7% | 100%/86.0% | 0금 |
| 29 | 10 | 100%/100.0% | 90%/43.1% | 100%/87.1% | 0금 |
| 30 | 10 | 100%/100.0% | 80%/38.7% | 100%/96.2% | 0금 |

원본 Step7의 Lv1·6일 검수와 달리 위 표는 양쪽 모두 같은 DAY별 성장 가정을 적용했다. 최소~최대 HP와 이전/이후 몰빵·금 손실·선정 인원/유지비는 [전체 비교표](../../_mockup/game_step8_balance/balance_before_after.md), 행별 HP·공격·병력·간격·지연·진격 확률은 [변경 수치 표](../../_mockup/game_step8_balance/changed_values.md)에 있다. 스킬 수치 변경은 0이므로 별도의 스킬 변경 표는 없다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/imagegen/v130r_step7_crumpled_map/HISTORICAL_SOURCE.md` | 이전0102 원본 출처를 역사 기록으로 보존 | 완료 |
| `assets/source/imagegen/v130r_step8_crumpled_map/APPROVED_SOURCE_0103.txt` | 0103 원본·프롬프트·조립 근거·활성 출처 보존 | 완료 |
| `assets/source/imagegen/v130r_step8_crumpled_map/SOURCE.md` | 0103 원본·프롬프트·조립 근거·활성 출처 보존 | 완료 |
| `assets/source/imagegen/v130r_step8_crumpled_map/assemble_0103.py` | 0103 원본·프롬프트·조립 근거·활성 출처 보존 | 완료 |
| `assets/source/imagegen/v130r_step8_crumpled_map/generated_attempt_2.png` | 0103 원본·프롬프트·조립 근거·활성 출처 보존 | 완료 |
| `assets/source/imagegen/v130r_step8_crumpled_map/generated_attempt_3.png` | 0103 원본·프롬프트·조립 근거·활성 출처 보존 | 완료 |
| `assets/source/imagegen/v130r_step8_crumpled_map/generated_attempt_4.png` | 0103 원본·프롬프트·조립 근거·활성 출처 보존 | 완료 |
| `assets/source/imagegen/v130r_step8_crumpled_map/prompts.md` | 0103 원본·프롬프트·조립 근거·활성 출처 보존 | 완료 |
| `assets/sprites/v130r/quarter_final/crumpled_map/REJECTED.md` | 0103 채택 시트·승인 메타데이터 교체 | 완료 |
| `assets/sprites/v130r/quarter_final/crumpled_map/art_review.json` | 0103 채택 시트·승인 메타데이터 교체 | 완료 |
| `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_ne.png` | 0103 채택 시트·승인 메타데이터 교체 | 완료 |
| `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_hurt_sw.png` | 0103 채택 시트·승인 메타데이터 교체 | 완료 |
| `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet.png` | 0103 채택 시트·승인 메타데이터 교체 | 완료 |
| `assets/sprites/v130r/quarter_final/crumpled_map/crumpled_map_sheet_ne.png` | 0103 채택 시트·승인 메타데이터 교체 | 완료 |
| `data/waves.json` | DAY1~30 병력·HP·공격·생성·진격 확률 조정 | 완료 |
| `scripts/game/ApprovedBattleController.gd` | 생성 시각·갈림길 분산과 목표 전진·강제 도발 연결 | 완료 |
| `scripts/map_builder/ApprovedMonsterPlacement.gd` | 임프·꼬깃의 추천 옥좌 수비 우선순위 | 완료 |
| `tools/art/assemble_v130r_step7_map.py` | 옛 조립기가0103 채택본을 덮어쓰지 못하도록 거부 | 완료 |
| `tools/run_v130r_step8.ps1` | 격리 데이터·단일 Godot·결과 백업 실행기 | 완료 |
| `tools/tests/V130RStep8BalanceTest.gd` | 60Hz 독립 일별 전투·목표/도발 직접 검사·실화면 캡처 | 완료 |
| `tools/tests/V130RStep8BalanceTest.tscn` | 60Hz 독립 일별 전투·목표/도발 직접 검사·실화면 캡처 | 완료 |
| `tools/tests/V130RStep8FastUnit.gd` | 60Hz 독립 일별 전투·목표/도발 직접 검사·실화면 캡처 | 완료 |
| `tools/tests/V130RStep8Simulation.gd` | 60Hz 독립 일별 전투·목표/도발 직접 검사·실화면 캡처 | 완료 |
| `tools/tests/v130r_step8_report.py` | 60Hz 전후 표·변경 수치·원자료·축소본 생성 및 검증 | 완료 |
| `docs/handoff/V130R_STEP8_BALANCE_2026-10-17.md` | 이번 인계·가정·최종 수치·제한 | 완료 |
| `docs/handoff/CURRENT.md` | 브랜치의 최신 상태 진입점 | 완료 |

캡처·전투 JSON·보고서는 소스 커밋에서 제외했다. 요청 산출물은 `C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step8_balance/`와 작업트리 `_mockup/game_step8_balance/`에 동일하게 둔다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 승인된0103 원본 재사용. 이 세션 신규 생성·외부 API·비용0.
- 생성 모델: GPT internal image generation.
- 생성 원본: `assets/source/imagegen/v130r_step8_crumpled_map/generated_attempt_2.png`, `_3.png`, `_4.png`.
- 활성 출처: `assets/source/imagegen/v130r_step8_crumpled_map/SOURCE.md`. 정확한 프롬프트·역사적 조립기·승인 기록도 같은 폴더에 보존했다.
- 런타임: `assets/sprites/v130r/quarter_final/crumpled_map/`. PNG4개와 원본3개의 채택 SHA 일치. 실제 RGBA alpha0..255 확인.
- 후처리:0103의 기존 크롭·균일 크기 정규화·이동·알파 합성만 재사용. Step8 추가 픽셀 처리·배경 제거 없음. SW/NE와 기존 좌우 반전으로4방향.
- 이전0102 출처는 `HISTORICAL_SOURCE.md`로 이동했고 옛 Step7 조립기가 채택본을 덮어쓰지 못하게 실행을 거부하도록 했다. 거부 전후 런타임 PNG SHA 불변을 확인했다.
- 실제 이름표 `꼬깃`과4방향 몸 높이96월드px, 슬라임/임프96 기준을 확인했다. `kkogit_battle.png`는 실제 유닛 일시정지 비교 fixture이고 나머지3장은 자연 전투다.1920×1080 원본과 최대1000×600 축소본을 개별 확인했다. 오디오 변경0.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `python -X utf8 tools/content/validate_v130r_monsters.py` | PASS 2402, 오류0 | 세션 명령 출력 |
| 2 | 원본600 / 최종600, 2배치×30일×10시드 | 목표30/30·시간초과0·최종 웨이브 일치 | `_mockup/game_step8_balance/before_rows.json`, `after_rows.json`, `summary.json` |
| 3 | `powershell -File tools/run_v130r_step7.ps1 -Mode direct` | 1821 직접 런타임 체크, 실패0 | `tmp/v130r_step7/direct_result.json`, `direct.log`, `direct.err.log` |
| 4 | `powershell -File tools/run_v130r_step8.ps1 -Capture`, direct 포함 | 27 직접 체크, 실패0. 실화면4장 | `tmp/v130r_step8/objective_checks.json`, `captures.log`, `captures.err.log` |
| 5 | `python -X utf8 tools/tests/v130r_step8_report.py --require-targets` | PASS: 미달0, 몰빵 패배·실제 도둑 손실 확인 | `_mockup/game_step8_balance/` |
| 6 | PNG/원본 SHA·알파/이전 조립기 거부 | PASS | `tmp/v130r_step8/asset_checks.json` |
| 7 | Python compile·PowerShell 구문·범위 diff check | PASS | 세션 명령 출력 |
| 8 | 기존1397파일 체크포인트 보존 / Godot 동시수 | 해시 불변 / 동시최대1·종료0 | `tmp/v130r_step8/preservation.json`, 프로세스 확인 |
| 9 | 전체 회귀·전체 플레이·성능·export·검수 에이전트 | NOT_REQUESTED / 미실행 | 이번 범위 밖 |

머리 없는 실행에서는 래스터 자세·깊이 갱신만 생략한다. 초기 대표10전투의 일반 유닛과 이 최적화 유닛을 비교해 승패·옥좌·시간·손실·생성·스킬 결과가 일치했다. UI·이미지 검수는 생략 없는 실제 유닛을 사용했다. 전체 래스터/모든 프레임률 동등성을 검증한 것은 아니다.

### 대표 전투 캡처

| DAY | seed | 촬영 전투시각 | 전투 종료 HP | 원본 |
|---:|---:|---:|---:|---|
| 7 | 130805 | 33.92초 | 69.2% | [battle_day7.png](../../_mockup/game_step8_balance/battle_day7.png) |
| 15 | 130808 | 68.45초 | 47.5% | [battle_day15.png](../../_mockup/game_step8_balance/battle_day15.png) |
| 30 | 130802 | 66.02초 | 45.0% | [battle_day30.png](../../_mockup/game_step8_balance/battle_day30.png) |

DAY15는60초, DAY30은66초 이후(보스 등장 후)에 실제 살아 있는 적이 옥좌150월드px 안에 있고 옥좌 피해가 발생한 장면을 촬영했다. 이는 보스 자체가 반드시 옥좌에 도착한 장면을 뜻하지 않는다.

### 계산 간격 민감도

초기15Hz 후보를30Hz로 대조했을 때 DAY7 같은3시드의 옥좌 평균이 약69.4%→100%로 달라졌다. 초기 후보를 폐기하고 최종 이전/이후 양쪽 모두 프로젝트 기본60Hz로 다시 측정했다. 폐기 후보와 진단 원자료는 `tmp/v130r_step8/model15_archive/`에 보존하며 최종 곡선 판정에는 포함하지 않는다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: acc253c8a4908a3803652db2e74d7f97c14738d7
- Review range: 35de2147fb75e097abefa5abf5d5436e627b8771..acc253c8a4908a3803652db2e74d7f97c14738d7
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

필수 표적 검증의 실패/시간초과 없음. 이 SHA 이후 제품 코드·데이터·자산은 바꾸지 않고 인계/CURRENT만 기록한다. 전체 검수 PASS나 출시 승인을 뜻하지 않는다.

## 7. 미해결 항목과 위험

- 성장/계약/지도 가정과 10개 시드에 따른 모델 결과다. 실제 누적 캠페인·서로 다른 계약/전문화/기억/직접 조작 조합의 승률은 검증하지 않았다. 레벨 가정과 합류 시점은 사용자 확인 대기.
- 10회 표본의 각 결과 폭은 넓다(일부 날짜0~100%). 평균 곡선 충족을 모든 개별 전투가 비슷한 난이도라는 뜻으로 해석하면 안 된다. 계산 간격 비교도 전체 실플레이 검수의 대체물이 아니다.
- DAY29 전투 추가 및 임프/꼬깃 추천 우선순위 변경은 사용자 확인 대기. 구 지도 캠페인의 공유 waves 호환성은 이번 범위 밖이다.
- 후반 몰빵은 DAY28~30 승률100%로 추천보다 유리했다. F구간의 나쁜 배치 패배 조건은 충족하지만 모든 날짜에서 추천이 최적이라는 뜻은 아니다.
- 로컬 main 부재와 원격 최신성 미확정은 계속된다. 공개 배포·Steam/태그/main 조치는 승인받지 않았고 수행하지 않았다.

## 8. 다음 작업 순서

1. 사용자가 4장 화면, [30일 비교표](../../_mockup/game_step8_balance/balance_before_after.md), [변경 수치](../../_mockup/game_step8_balance/changed_values.md)와 이 가정 표를 확인한다. 사용자 확인 대기.
2. 다른 성장/계약/지도 가정을 선택하면 `tools/tests/V130RStep8BalanceTest.gd`의 조건부터 변경하고 영향 날짜의 두 배치를 다시 측정한다.
3. 별도 배포/검수 지시 전에는 push·main·태그·Steam 작업을 하지 않는다.

## 9. 작업 트리 상태

- 사용자 지정 브랜치에 영어 로컬 구현 커밋과 문서 커밋만 만든다. 기존1398상태 항목(파일1397+미추적 `docs/design/v131_layout/`)은 스테이징/수정/삭제하지 않았다.
- 초기 목록과 작업 경로 겹침 없음. 최초 해시 scratch 파일은 실험 출력 이름 충돌로 사라져 중간 시점에 별도 `preservation.json`으로 다시 기록했다. 기존1397파일은 그 체크포인트와 최종 해시가 일치하며 최초 해시를 복구했다고 주장하지 않는다.
- 원본 재측정 초기에 잘못된 검증 조건이 몰빵 패배까지 실패로 판단해 중복 실행했다. 이후 재측정600행을 완료·보존했고, 실행기는 기존 결과/로그를 실행 전에 백업한다. 초기 폐기 실험은 최종 표에 섞지 않았다.
- 별도 stash·브랜치 이동·이력 재작성·원격 동작 없음. 산출물·격리 데이터·조정 실험·로컬 캡처는 tmp 및 _mockup에만 유지한다.

## 10. 종료 체크리스트

- [x] 구현·요구사항 대조, 관련 표적 테스트·대표 화면4장 확인.
- [x] 30일 전후·2배치·각10시드, 성장 가정·손실·수치 표 기록.
- [x] 그래픽 원본·프롬프트·알파·런타임 연결·최종 검증 SHA 기록.
- [x] CURRENT 갱신, 의도한 파일만 영어 로컬 커밋.
- [x] 개인 세이브 미접근·Godot 최종0·원격/태그/Steam/main 작업0.
- [x] 전체 회귀·전체 플레이·별도 검수는 미요청·미실행으로 명시.

사용자 확인 대기.

## 11. DAY 29 준비일 복원 — 2026-10-17 후속 작업

### 메타데이터와 범위

- WORKSTREAM_ID: V130R_STEP8_DAY29_REVERT. 목표 버전 1.3.0, 버전 변경 없음.
- 사용자 지시: 2026-10-17 09:08, DAY 29는 원래 적 없는 준비일 유지. 다른 날짜 수치 변경 금지.
- 브랜치: `codex/v130r-defense-layout`.
- 기준 SHA: 0104 `8ee2908c54b01e86750fa3a0a1df17459c08efce`.
- 마지막 제품/직접 테스트/보고서 커밋: `db507a8686e6019c32b1385f218e5ce38f5b77b3` (`Restore DAY 29 as a preparation-only day`). 이후 변경은 이 인계와 CURRENT 문서뿐이다.
- 원격 최신성 한계 유지: 로컬 main 부재, 캐시 origin/main `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`. fetch·원격 조회·push·태그·Steam·main 변경·PR 없음.

### 변경 내용과 파일

- `data/waves.json`: `day_29 = []`. 0104가 추가한 8개 웨이브 항목만 제거했다. 원본 0102 `35de2147fb75e097abefa5abf5d5436e627b8771`의 DAY 29와 동일하다. 다른 모든 키/날짜의 데이터는 0104와 동일함을 JSON 대조로 확인했다.
- `tools/tests/V130RStep8BalanceTest.gd`: `preparation_day` 설정으로 실제 DAY 29 관리일 진입과 기존 전투 시작 차단을 검사하는 직접 테스트 1개(확인 항목 7개)를 추가했다. 기존 시뮬레이션 계산은 변경하지 않았다.
- `_mockup/game_step8_balance/balance_before_after.md`: DAY 29 결과 행을 **준비일(전투 없음)**으로 정정하고 전투 통계에서 제외했다. 다른 날짜 수치 유지.
- `_mockup/game_step8_balance/changed_values.md`: DAY 29의 8개 변경 항목을 삭제했다. 위 두 문서는 이전에 미추적 상태였으며 이번에는 요청된 두 파일만 명시적으로 커밋했다.
- 데스크톱 `C:/Users/blueh/Desktop/진행중인프로젝트/_mockup/game_step8_balance/`의 같은 두 문서도 동기화했다. 기존 전후 원자료 JSON은 0104 당시 기록으로 보존했다.
- `docs/handoff/CURRENT.md`: 이 후속 결과로 진입할 수 있도록 갱신했다.
- 스토리·준비일 조건·보상·세이브 형식·몬스터 수치·스킬·그래픽·오디오 변경 없음. 개인 세이브 접근/수정 없음.

### 검증 결과

| 검증 | 결과 | 근거 |
|---|---|---|
| DAY 29 준비일 진입 직접 테스트 1개 | PASS, 7확인/실패0. 관리일 유지·빈 웨이브·방어 웨이브 부재·management_only 일정/시작 차단·적 미생성·날짜/옥좌 HP 유지 | `tmp/v130r_step8/day29_preparation_checks.json`, `day29_preparation_final.log`, `day29_preparation_final.err.log` |
| DAY 28 추천 배치 10회 | 0104와 일치: 승률90%, 평균 옥좌HP42.7% | `tmp/v130r_step8/day29_revert_regression.json` |
| DAY 30 추천 배치 10회 | 0104와 일치: 승률80%, 평균 옥좌HP38.7% | 같은 회귀 원자료 |
| 시드별 기존 원자료 대조 | PASS. 승패·HP·시간·생성 수·금 손실·도둑/탈출/절도·시간초과·웨이브·배치·레벨 일치, 시간초과0 | `tmp/v130r_step8/check_day29_revert.py`, `day29_revert_summary.json` |
| 다른 날짜 데이터/기존 파일 보존 | PASS. 변경 웨이브 키는 day_29 하나, 기존1397파일 SHA256 불변 | 같은 요약 및 `day29_preservation.json` |
| 관련 변경 `git diff --check` / 스테이징 검사 | PASS | 세션 명령 출력 |
| Godot 동시 실행/종료 | 최대1, 최종0. 격리 APPDATA/LOCALAPPDATA 사용 | 실행기 및 프로세스 확인 |
| 전체 회귀·전체 플레이·빌드/export·별도 검수 에이전트 | NOT_REQUESTED / 미실행 | 이번 요청 범위 밖 |

명령: `powershell -NoProfile -File tools/run_v130r_step8.ps1`. 회귀 설정은 `days=[28,30], layouts=[recommended], trials=10, hz=60`, seed130800~130809로 0104와 동일하다. 최종 직접 확인은 `days=[], preparation_day=true, name=day29_preparation_final`로 실행했다. 요약 대조 명령은 `python -X utf8 tmp/v130r_step8/check_day29_revert.py`이다.

초기 직접 시험은 화면 진입 시 해제된 화면 참조 때문에 중단됐다. 이후 회귀20회는 완료했으나 이전 전투의 누적 생성 수를 0과 비교한 시험 조건이 실패했다. 화면 참조 의존을 제거하고 진입 전후 생성 수 불변으로 고친 최종 직접 시험은 7/7 통과했다. 회귀20회의 전투 계산은 수정하지 않았으며 0104와의 시드별 대조도 통과했다. 실패 로그는 실행기 백업에 보존했고 최종 직접 시험으로 이전 실패를 대체한다.

### 최종 판정과 남은 작업

- Review task ID: NOT_REQUESTED
- Reviewed SHA: db507a8686e6019c32b1385f218e5ce38f5b77b3
- Review range: 8ee2908c54b01e86750fa3a0a1df17459c08efce..db507a8686e6019c32b1385f218e5ce38f5b77b3
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

DAY 29 복원 요청의 미해결 항목 없음. 위 §3/§7과 기존 CURRENT에 있던 'DAY29 전투 추가 사용자 확인 대기'는 이번 복원 지시로 종료했다. 그 밖의 꼬깃 화면·성장/계약 가정 확인은 기존 범위로 남는다. 기존 혼합 작업트리와 미추적 자산·UID·설계 자료는 보존했으며 이번 대상 파일만 로컬 커밋했다. 공개 배포를 진행하지 않는다.
