# 2차 업데이트 완료 재감사

- 감사일: 2026-07-13 (KST)
- 완료 기준: `UPDATE3_LIVING_CASTLE_THREE_FRONTS_PLAN_2026-07-12.md` 1.1
- 재구성 계약: `docs/design/UPDATE2_RECONSTRUCTION_CONTRACT_2026-07-13.md`
- 기준 커밋: `11769401b9237a4f7f928aa5365729c77b81133b`
- 전체 판정: **PASS**
- 차단 목록: **0건**

## 1. 1.1 선행 조건별 판정

| 선행 조건 | 구현 증거 | 자동 검사 | 판정 |
|---|---|---|---|
| 저장 v3와 v2→v3 무손실 변환 | `CampaignSaveMigratorV2ToV3.gd`, `CampaignSaveV3Store.gd` | `update2_save_v3` | PASS |
| 회차당 계약 몬스터 2종 선택 | `ContractRosterService.gd`, `update2_contracts.json` | `update2_contract_roster` | PASS |
| 출전/예비와 Stage별 출전 한도 | `ContractRosterService.gd`, 관리·전투 연결 | `update2_contract_roster` | PASS |
| 계약 5종의 역할·유대·해금·저장 | `monster_instances.json`, `monsters.json`, 계약 서비스 | `update2_contract_roster`, `update2_save_v3` | PASS |
| 일반 적 6종과 에블린의 데이터·행동·그래픽 | `update2_counterforce.json`, 전투 컨트롤러, 전용 이미지 | `update2_counterforce`, `update2_release_contract` | PASS |
| 교리·칙령·도전 인장 각 6종 | `cycle_doctrines.json`, `cycle_decrees.json`, `challenge_seals.json` | `update2_cycle_choices` | PASS |
| seed 기반 사건 덱과 웨이브 변형 | `Update2SeededCampaignService.gd`, `update2_seeded_campaign.json` | `update2_seeded_campaign` | PASS |
| 레온 적응 자세 4종의 DAY 24 예고·DAY 30 적용 | `LeonAdaptationService.gd`, `leon_adaptive_stances.json` | `update2_leon_adaptation` | PASS |
| E00~E11 도달성과 도감 기록 | `ending_rules.json`, `EndingConditionEvaluator.gd`, `NewCycleService.gd` | `update2_ending_catalog` | PASS |
| 30일 자동 저장·이어하기·새 회차 | 기존 DAY 28~30 저장 흐름과 v1/v2/v3 다음 회차 체크포인트 | `campaign_save_load`, `update2_release_contract` | PASS |
| 신규 그래픽 SOURCE와 프레임 계약 | `assets/source/imagegen/update2_counterforce/SOURCE.md`, 7종×16프레임 | `update2_counterforce`, `update2_release_contract` 383개 단언 | PASS |
| 전체 핵심 통합 검증 | `tools/tests/RunCoreVerification.ps1` Full | 21/21 | PASS |

## 2. R8에서 발견하고 닫은 결함

1. 계약 게시판·교리·칙령·인장 선택 화면이 기존 저장 허용 화면 목록에 없어 다음 회차 자동 저장이 거부되던 문제를 수정했다.
2. 다음 회차 v2 보조 저장에 profile v2를 그대로 넣어 v2 검증이 실패하던 문제를 v2 호환 프로필로 기록한 뒤 v3에서 profile v2를 보존하도록 수정했다.
3. JSON에서 읽은 `completed_cycles`가 숫자 표현 차이로 0으로 초기화되던 문제를 숫자형 정규화로 수정했다.
4. 대응군 SOURCE 문서의 디자인/대기 알파 원본 이름을 실제 파일과 일치시켰다.

## 3. 전체 통합 검증 기록

- 실행 명령: `tools/tests/RunCoreVerification.ps1 -Mode Full`
- 생성 시각: 2026-07-13 02:09:32 KST
- 총 소요: 765.06초
- 결과: 21개 통과, 0개 실패
- 보고서: `tmp/core_verification/latest.json`, `tmp/core_verification/latest.md`
- 포함 범위: 프로젝트 불러오기, 핵심 게임, 정규 저장, R1~R8, 튜토리얼, 온보딩, 전체 밸런스, 다중 seed, 1920×1080·1366×768 UI 캡처, 전투 난전 캡처

## 4. 차단 목록

없음. 3차 업데이트 Phase 0 재감사를 시작할 수 있다.
