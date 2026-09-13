# 경제 흐름·DAY15 자금 재확인

## 1. 메타데이터
- 작성일: 2026-09-14 (실행 시작 9월13일)
- WORKSTREAM_ID: UIUX-V2-ECONOMY-FLOW-20260914
- 목표 버전: 공개1.2.6 유지, 새 버전 미확정
- 브랜치: codex/v126-uiux-u0-u3
- 기준 main/origin/main/조회한 원격main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 세션 시작 HEAD: 2efb8ceb96ebbde7e48c2be49a6d92315eb79f75
- 마지막 구현·QA SHA: 098c99011fc4855935bc8b9d4839cb1f5739d278
- 이후 변경은 docs/handoff만. 원격 푸시/PR/태그 없음.

## 2. 목표
사용자 '진행해'에 따라 실제 자금·지출·해금 흐름을 연결하고 진행 차단 결함을 수정한다. 혼자 구현 후 마지막 관련 검사. 전체 완주·출시와 서브에이전트는 제외한다.

## 3. 완료한 작업
- DAY14 자금 부족 기록이 남아 DAY15 날짜 수입으로 충분해져도 심사를 못 통과하던 오류 수정.
- 2장 진입+자금 심사 일정이면 현재 잔고로 재확인. 조회는 무부작용, 승리 결산에서 funded/unlock 함께 기록. 원래 비용720gold/720infamy 및 다른 시작 조건 유지.
- 실제 훈련/샛문/시설강화·이전/승급 차감, 일일수입, 조건부 격퇴 보상·성장·결산을 DAY1~15 기록으로 연결.
- 선택 지출 합계 gold1400/mana240/infamy20. DAY15 전 gold5393/mana2032/infamy1435. 전투 소비·도난·원정/필수 선택 절차 제외한 조건부 계산이며 실전 잔고나 경제 전체 PASS가 아니다.
- 가격·수입·스탯·저장 형식·스토리·UI/아트/오디오 변경 없음.

## 4. 변경 파일
| 경로 | 목적 |
|---|---|
| scripts/game/GameRoot.gd | 자금 재확인·결산 플래그 일관성 |
| tools/UIUXEconomyFlowTest.gd/.gd.uid/.tscn | 경제 API 기록·회귀 |
| docs/qa/UIUX_V2_ECONOMY_FLOW_2026-09-14.md | 범위·수치·근거·제한 |

## 5. 자산
신규 이미지 생성 없음. 승인된 검은 벽·돌바닥·가림·초상화 유지. ASSET_BLOCKED_NATIVE_ALPHA 유지, 같은 실패 요청 반복 금지.

## 6. 관련 검증
- Godot4.6.3 Windows console headless, APPDATA 시험별 분리.
- UIUXEconomyFlowTest: PASS109 checks.
- V122PrecombatFlowTest: PASS40 assertions.
- V122SaveProgressionTest: PASS. 손상저장 `{broken` 복구 fixture의 예상 JSON parse ERROR3건 확인. SCRIPT ERROR없음.
- 직접/방어준비 로그 ERROR없음. git diff --check PASS.
- 화면 변경 없으므로 다중 해상도/캡처 미실행.
- 전체캠페인/8인/사람/Web/장시간/공개출시 미실행.

### 정책 필드
- Review task ID: NOT_REQUESTED
- Reviewed SHA: 098c99011fc4855935bc8b9d4839cb1f5739d278
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..098c99011fc4855935bc8b9d4839cb1f5739d278
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 남은 제한
기본 적 전멸·승리를 가정한 계산이다. 전투 마력·도난/도주·실패·원정·필수 선택 절차·추가 지출은 제외. 실제 완주/승률 근거가 아니다. 자금이 실제로 부족한 경우는 계속 차단한다. DAY15 전투 중 손실 후 결산 기준과 과소 자금의 회복 경로는 추가 확인 대상. 전체 출시 HOLD.

## 8. 다음 작업
1. 실제 대표 전투에서 마력 소비·도난·목표 방어 손실을 경제 계산에 연결하고, 결과 기록으로 다음 배치/투자를 판단하게 한다.
2. 원정·필수 선택·후반 투자를 포함한 전력 범위를 비교한다. 임의로 자금을 지급한 시험을 실전 근거로 쓰지 않는다.
3. 비용·보상 조정은 위 근거가 있을 때만. UI 문구 개선만 반복하지 않는다. 전체통합/출시는 별도 실행 경계.

## 9. 작업 트리
구현·QA는 명시적 경로만 로컬 커밋. 이 핸드오프와 CURRENT를 문서 커밋하고 종료한다. 기존 변경 되돌림/새 브랜치/강제 작업 없음. 로컬 근거 tmp/uiux_economy_20260913/economy.json, direct.log, precombat.log, save.log는 소스 커밋 제외.

[상세 보고서](../qa/UIUX_V2_ECONOMY_FLOW_2026-09-14.md)
