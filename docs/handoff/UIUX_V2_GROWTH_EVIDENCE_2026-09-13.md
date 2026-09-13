# 성장 전력 근거·피해 경계 핸드오프

## 1. 메타데이터

- 작성일: 2026-09-13
- WORKSTREAM_ID: UIUX-V2-GROWTH-EVIDENCE-20260913
- 목표 버전: 공개1.2.6 유지, 새 버전 미확정
- 브랜치: codex/v126-uiux-u0-u3
- 기준 main/origin/main/원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112 (ls-remote 일치)
- 세션 시작 HEAD: 605df8b1f840bc5e15e36df9f224a6f344c42681
- 마지막 구현·QA 커밋: ca544f6dcae38d9566f907b7b52df965dbb30057
- 이 SHA 뒤 변경: docs/handoff 문서만
- 원격 푸시 / PR / 태그: 없음
- main:AGENTS.md의 구 1.2.5 문구보다 main:CURRENT의 공개1.2.6 및 최신 사용자 지시를 따른다.

## 2. 목표와 완료 조건

사용자 '나머지 진행해'에 따라 UI만 반복하지 않고 실제 성장·훈련·전력 근거를 연결한다. 혼자 구현 후 마지막 관련 검사를 수행한다. 전체 캠페인·공개 출시·서브에이전트는 범위 밖이다.

## 3. 완료 내용

- 0 이하 물리 피해와 0으로 반올림된 마법 피해가 HP·보호막을 소모하지 않도록 수정. 양수 최소 피해 규칙 유지.
- 실제 웨이브·보상·레벨업·집중 선택 API로 조건부 성장 기록 생성. DAY30 전 Lv.10 vs 기존 최종 시험 Lv.7 차이를 발견.
- BalanceSimulation은 선택한 성장 기록의 레벨·EXP만 가져오고 시설·승급·경제·해금이 여전히 시험 설정임을 출력한다. 한 개 시나리오를 지정해야 한다.
- 경험치·훈련 비용·적 능력치·저장 구조·스토리·UI/그래픽/오디오 변경 없음.
- 전체 밸런스/출시 HOLD. 근거 없이 난이도 수치를 바꾸지 않음.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/units/Unit.gd | 0 이하 피해 무효 처리 |
| tools/BalanceSimulation.gd | 성장 근거 선택 연결·실험 조건 출력 |
| tools/UIUXGrowthEvidenceTest.gd / .gd.uid / .tscn | 성장 기록과 경계 직접 검사 |
| docs/qa/UIUX_V2_GROWTH_EVIDENCE_2026-09-13.md | 가정·수치·실행 결과·제한 |

## 5. 자산

신규 생성·후처리 없음. 승인된 벽·바닥·가림·초상화 유지. ASSET_BLOCKED_NATIVE_ALPHA 계속, 조건 변화 없는 생성 재시도 금지.

## 6. 마지막 관련 검사

Godot4.6.3 Windows console headless, APPDATA 격리. UI 변경 없어 새 다중 해상도/캡처 미실행.

- UIUXGrowthEvidenceTest: PASS 601 assertions.
- ReliquaryGuardPhase17ATest: PASS 27 assertions.
- DAY12_FIRST_PROMOTION_SLIME + rotating_focus 기록: 52.1초 WIN, 적8/8, 왕좌피해0, 아군다운0. 레벨5→6. **자금·시설·승급·해금은 시험 설정**.
- 최종 3개 로그 SCRIPT ERROR/ERROR 없음. git diff --check PASS.
- 최초 도구의 빈 gold 사전 접근 오류는 수정 후 재실행. 최초 PASS 문자열은 무효이며 최종 로그만 유효.
- 전체DAY1~30/8인/사람/Web/저사양/장시간/공개출시 미실행.

### 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: ca544f6dcae38d9566f907b7b52df965dbb30057
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..ca544f6dcae38d9566f907b7b52df965dbb30057
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 한계와 위험

성장 기록은 기본 적을 전부 격퇴하고 승리했다는 가정이며 실제 연속 플레이 증명이 아니다. 활약 EXP·훈련·원정 변형·도주 적은 제외했다. 총 격퇴 금화는 지출 후 잔고가 아니다. 실제 전투 1건으로 전체 난이도를 확정하지 않는다. 피해0 경계는 수정했지만 양수 방어 계산의 최소1 규칙은 보존한다.

## 8. 다음 작업

1. GameRoot의 실제 건설/강화/승급/복구/장별 투자 비용과 자금·해금 흐름을 연결해 경제 근거를 만든다. 기존 fixture 지급 자금이 실전 수입을 대체하지 않게 한다.
2. 그 근거로 중·후반 대표 배치 및 적 목표 대응을 비교하고 수치 변경은 관찰 근거가 있을 때 제안/적용한다.
3. 전체 통합·출시 검수는 별도 실행 경계. 현재 목표를 테마나 UI 문구 개선만으로 되돌리지 않는다.

## 9. 작업 트리

- 구현·QA 커밋 후 깨끗한 상태 확인. 이 핸드오프와 CURRENT만 뒤에 기록하여 문서 커밋한다.
- 의도하지 않은 기존 변경, stash, 원격 push 없음.
- 로컬 근거: tmp/uiux_growth_20260913/growth_evidence.json / direct.log / relic.log / day12.log (소스 커밋 제외).
- 상세: [QA 보고서](../qa/UIUX_V2_GROWTH_EVIDENCE_2026-09-13.md)
