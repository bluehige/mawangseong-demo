# 3차 Phase 19 완료 기록 — 성광 정화 전선 DAY 5~29

## 완료 범위

- 전선 해금: 셀렌 관계 45, 정화 성전 교리, E04/E09, 성광 초대장
- 선택한 대체 전선 1회 클리어 후 나머지 대체 전선 자동 해금
- DAY 1~3 공통 내용 유지
- DAY 5 징후, DAY 10 첫 사슬 순찰대, DAY 11 본격 성광 적 진입
- DAY 15 심장방 첫 점검, DAY 20 성물 호송대, DAY 25 셀렌 예비 결투
- 전선 사건 2개와 선택한 심장 사건 1개 실제 선택 UI
- 사건 선택의 셀렌 관계·E12 지표·자원 반영과 중복 방지
- DAY 28 성광 전용 작전 2개를 기존 원정 화면에 연결
- DAY 28 작전 효과를 회차에 저장하고 DAY 30에만 적용
- DAY 29 심장·합동기·작전·셀렌 관계를 받는 전야 placeholder
- 정식 성기사 셀렌 최종전은 Phase 20 전까지 placeholder 유지

## 웨이브 예산

| DAY | 기존 인원 | 성광 전선 인원 | 결과 |
|---:|---:|---:|---|
| 10 | 6 | 6 | 동일 |
| 11 | 7 | 7 | 동일 |
| 15 | 6 | 6 | 동일 |
| 20 | 7 | 7 | 동일 |
| 25 | 6 | 6 | 동일 |

## 핵심 파일

- `data/regular_version/update3/fronts.json`
- `data/regular_version/update3/front_day_overlays.json`
- `data/regular_version/update3/front_operations.json`
- `data/regular_version/update3/events.json`
- `scripts/systems/fronts/FrontCampaignService.gd`
- `scripts/core/DataRegistry.gd`
- `scripts/game/GameRoot.gd`
- `tools/content/ValidateUpdate3Content.gd`
- `tools/tests/HolyPurificationPhase19Test.gd`

## 검증 결과

- Phase 19 전용 검증: 49/49 PASS
- 3차 데이터 계약: 17/17 PASS
- 빠른 핵심 검증: 33/33 PASS, 148.8초
- 레온 전선 DAY 10/15/20/25 오버레이 미적용과 기존 DAY 15 웨이브 보존 확인
