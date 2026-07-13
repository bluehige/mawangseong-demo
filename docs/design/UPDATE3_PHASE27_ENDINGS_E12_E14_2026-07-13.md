# 3차 Phase 27 완료 기록 · 엔딩 E12~E14

## 완료 범위

- E12 `ending_holy_open_gate`: 성광 정화 전선 제한, 관계·명예/공포 성향·봉인 중단·자비 선택 조건
- E13 `ending_off_ledger_independence`: 길드 회수 전선 제한, 관계·평균 보안 등급·보물 손실·시설 무력화·부채 정화·최종 금화 조건
- E14 `ending_living_castle_voice`: 심장 공통 기여 조건과 석골·포식·몽등별 추가 조건
- 기존 E00~E11을 보존한 런타임 병합 및 E12/E13 > E14 > 기존 엔딩 우선순위
- 캠페인 DAY별 누적 지표, 선택 전 심장 숙련도, 왕좌 피해, 셀렌 방벽, 로만 최종 단계 예산, 톡톡 수리 기록
- 엔딩별 비수치 보상 해금과 중복 지급 방지
- E12~E14 일러스트 원본·출처 기록, 엔딩 화면 1920×1080·1366×768 확인

## 보상 원칙

- E12: 베베 계약 보장, 성광 문양 ID, 공동 경계 사건 2개
- E13: 톡톡 계약 보장, 길드 문양 ID, 계약 게시판 무료 새로고침 1회
- E14: 선택 심장 숙련 외형, 연대기 음성 기록, 다음 회차 선택 연출
- 공격력·체력·게이지 등 전투 능력치 보상은 없다.

## 자동 검증

- `EndingPhase27Test`: 42/42 PASS
- `Update2EndingCatalogSmokeTest`: 38/38 PASS
- `Update3DataContractTest`: 17/17 PASS
- `SaveV4MigrationTest`: 42/42 PASS
- `MonsterLegacySystemsSmokeTest`: 31/31 PASS
- `EndingPhase27VisualReview`: PASS

## 화면 자료

- `tmp/update3_phase27/ending_e12_1920x1080.png`
- `tmp/update3_phase27/ending_e13_1366x768.png`
- `tmp/update3_phase27/ending_e14_1920x1080.png`
