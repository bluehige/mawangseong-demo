# v1.2.2 구현 폐쇄 행렬

- 기준일: 2026-07-27
- 대상: P0~P15에서 제품 경로에 반영한 기능과 Update 2~4 전체
- 기계 판독본: `docs/audit/v122/V122_IMPLEMENTATION_CLOSURE_MATRIX.json`
- 자동 검사: `tools/tests/V122ImplementationClosureTest.tscn`
- 허용 상태: `IMPLEMENTED`, `INTENTIONALLY_HIDDEN`, `REMOVED`
- 금지 상태: `DOC_ONLY`, `DATA_ONLY`, `UI_ONLY`, `TEST_ONLY`, `DEAD_CLICK`, `UNREACHABLE`, `SAVE_MISSING`, `VISUAL_MISSING`, `WRONG_DESCRIPTION`, `PENDING`, `UNKNOWN`

## 폐쇄 결과

| 제품 기능군 | 상태 | 제품 진입·결과 근거 |
|---|---|---|
| 건물 호환·시설 대상 | IMPLEMENTED | 실제 방·시설 데이터, 건설 handler, 전투 시설 adapter |
| 공간·배치 | IMPLEMENTED | ModuleGraph snapshot, 지도 편집·드래그 handler, 저장 snapshot |
| 전투 명령·시설 | IMPLEMENTED | 명령 UI, 제품 command service, battle ledger |
| DAY 1~5 기준 재현 | IMPLEMENTED | 제품 fixture, 진행 handler, 결과 view model |
| 관리·배치 UI | IMPLEMENTED | 관리·몬스터 화면, 선택·배치 handler |
| 전투·결과 UI | IMPLEMENTED | HUD·결과 진입점, 종료·계속 handler |
| 저장·진행·재도전 | IMPLEMENTED | 저장 adapter, 이어하기·retry handler |
| DAY 1~30 밸런스 | IMPLEMENTED | 동결 계산 모델, B1~B5 sheet, 제품 전투 결과 |
| Update 2 계약·회차·엔딩 | IMPLEMENTED | DataRegistry 병합, 계약·회차 UI, 제품 저장 |
| Update 3 전선·심장·합동기·연대기 | IMPLEMENTED | 제품 카탈로그, UI handler, v4 저장 |
| Update 4 의회·지역·전초기지·상층 | IMPLEMENTED | 제품 카탈로그, 세 화면의 선택 handler, v5 저장 |
| 성장·승급·왕관 진화 | IMPLEMENTED | 성장 데이터, 몬스터 UI, 전투 능력치 반영 |
| E00~E22 엔딩 | IMPLEMENTED | 연속 카탈로그, 판정기, 결과·보관함 UI |
| Update 4 지역 적 6종 시각 자산 | IMPLEMENTED | 4×4 실전투 sheet, asset manifest, 런타임 loader |
| 타이틀·온보딩·캠페인 진입 | IMPLEMENTED | 타이틀·대화 UI, 캠페인 선택 handler, 저장 |

각 행의 `요구 문서`, `데이터`, `runtime consumer`, `UI 진입점`, `입력 handler`, `저장`, `전투·결과 반영`, `자동 테스트`, `실제 실행 증거`는 JSON 행렬에 제품 경로로 기록했다. 자동 검사는 누락 필드, 존재하지 않는 경로, 존재하지 않는 handler, 금지 상태를 실패로 처리한다.

## P16에서 닫은 실제 누락

| 발견 상태 | 조치 | 최종 상태 |
|---|---|---|
| Update 4 지역 일반 적 6종 `placeholder_art=true` | 내장 이미지 생성으로 4×4 전투 sheet 6종 제작, enemy catalog·asset manifest·source 기록 연결 | IMPLEMENTED |
| 전초기지 DAY 10 `placeholder_wave`·`run_placeholder_trial` | 제품 명칭 `day10_wave`·`run_trial`로 교체하고 소비자·테스트 동시 갱신 | IMPLEMENTED |
| 온보딩 노출 문구 `정규판 TODO` | 실제 설명 `작전 보상과 위험도`로 교체 | IMPLEMENTED |
| 전투 fallback의 `다음 장 준비 중` | 제품 안내 `방어 일정이 없습니다`로 교체 | IMPLEMENTED |

## 자동 검색 분류

`scripts/`, `scenes/`, `data/`, `project.godot`에서 `TODO`, `FIXME`, 준비 중, 미구현, `test only`, `debug only`, `placeholder_art=true`, `placeholder_wave`, `run_placeholder_trial`을 출시 차단 literal로 검사한다.

다음 용어는 문자열만으로 미구현을 뜻하지 않으므로 기계 판독 행렬의 `semantic_exceptions`에서 의미와 노출 범위를 고정했다.

- `open_placeholder`: 던전 편집기의 미연결 socket 상태
- `debug_placeholder`: 디버그 배치 fixture
- `placeholder_text`: Godot 입력란 API 속성
- `placeholder_art=false`: 실자산 연결 완료 sentinel
- `pending` 상태 변수: 실행 중 상태 전이
- `임시 파일`: 원자 저장 복구 경로

## 판정

- 기능군: 15
- `IMPLEMENTED`: 15
- `INTENTIONALLY_HIDDEN` 기능군: 0
- `REMOVED` 기능군: 0
- 금지 상태: **0**
- 출시 차단 literal: **0**
- P16 판정: **PASS**
