# 실제 전투 자원 결산

## 1. 메타데이터
- 작성: 2026-09-14
- WORKSTREAM_ID: UIUX-V2-RESOURCE-RESULT-20260914
- 목표 버전: 공개1.2.6 유지, 새 버전 없음.
- 브랜치: codex/v126-uiux-u0-u3
- 기준 main/origin/main/조회 원격main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 세션 시작: 44eab95ee106fcedde8044721165a4615b65af5a
- 마지막 구현·QA SHA: 4c1234464fcc5c1491a285e63a5e4a52bda09a83
- 이후 docs/handoff만 수정. 미푸시, PR/태그 없음.

## 2. 목표
사용자 '진행해'에 따라 실제 전투 마력/도난/보상과 결과를 연결한다. 혼자 구현 후 마지막 관련 검사. 전체완주·공개출시 제외.

## 3. 완료
전투 시작/결산 직전/결산 후 잔고를 기록하고 보상 아래 최종 순변동을 표시한다. 패배 복구 후 순변동과 전투 중 변화는 구분한다. 이전 결과에 기록이 없으면 생략한다. 툴팁은4종 자원 잔고를 제공한다. 잔고 차이를 총 소비량으로 잘못 명명하지 않는다. 실제 DAY15 대표 전투 결과에도 기록 연결.

## 4. 변경 파일
- scripts/game/CombatSceneController.gd: 실제 자원 기록.
- scripts/v122/ui/V122CombatResultViewModel.gd: 전달.
- scripts/ui/ResultWorkspaceUI.gd: 보상/순변동 UI.
- tools/BalanceSimulation.gd: 대표 전투 출력.
- tools/UIUXResourceResultTest.gd/.gd.uid/.tscn: 통제 재현·UI 검사.
- tools/tests/V122ResultUISimplificationTest.gd: 종료 전 지연 정리0.3초.
- docs/qa/UIUX_V2_RESOURCE_RESULT_2026-09-14.md: 증거·검증.

## 5. 규칙·자산
비용/보상/AI/성장/원정/스토리/미술 변경 없음. 저장 버전 유지, 결과 summary에 선택 필드만 추가. 새 생성 없음. native alpha 차단 및 기존 미술 유지.

## 6. 관련 검사
- 새 직접65 +기존 결과37 checks PASS.
- Windows Godot4.6.3 Forward+ RTX3060Ti, 1920×1080 100% /1280×720 115%, 승패4조합.
- 기존 저장진행 PASS. 손상JSON 예상 parse ERROR3건, SCRIPT ERROR없음.
- 실제 DAY15 전투53.1초WIN, 적6/6, 다운0, 왕좌피해0, Stage02. 마력210→10→130(전투 중-200/최종-80), 금화830→1226. 시험 설정을 사용했으며 연속 캠페인/경제완주 증명이 아니다.
- 최종 직접/결과계약/대표 전투 로그 오류없음. 결과 검사 종료 잔류 오류는 지연 정리 대기 후 해소. 저장 단독 최종은 예상JSON진단만.
- 첫 무료 스킬 재현은 소비근거로 폐기. 유료 스킬의 잘못된 대상 방도 수정 후 재검증. 실제 스킬 유효 방 규칙 유지.
- git diff --check PASS. 전체DAY1~30/8인/사람/Web/저사양/장시간/공개출시 미실행.

### 정책 필드
- Review task ID: NOT_REQUESTED
- Reviewed SHA: 4c1234464fcc5c1491a285e63a5e4a52bda09a83
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..4c1234464fcc5c1491a285e63a5e4a52bda09a83
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 한계
UI 재현 승패는 시험에서 지정, 스킬40마력/도난100금화/격퇴보상 실제 API 처리. 실제 플레이 승률 증거가 아니다. 별도 DAY15 시나리오는 실제 전투로 승리했으나 시설/승급/자금은 시험 설정. 기본DAY15 도둑1명 최대100 약탈은 다른 적5명 보상300보다 작다는 조건부 비교만 가능. 변형 모드/선택/후반까지 일반화 금지. 최종 출시 HOLD.

## 8. 다음 작업
후반 원정·필수 선택·투자의 대가를 실전 resource_balance 기록과 비교한다. 시험 자금/총보상만으로 전력·경제를 확정하지 않는다. 근거가 있을 때만 데이터 조정. UI 문구 작업만 반복하지 않는다. 전체 통합/출시는 별도 경계.

## 9. 작업 트리와 증거
관련 파일만 로컬 커밋, 원격 미푸시. 기존 변경 되돌림 없음. 문서 커밋 후 깨끗한 상태로 종료.
로컬 tmp/uiux_resource_result_20260914/index.html 및 results.json, direct.log, result_contract_final.log, save_final.log, day15.log, 승패/전후PNG. 모두 소스 커밋 제외.
[상세 QA](../qa/UIUX_V2_RESOURCE_RESULT_2026-09-14.md)
