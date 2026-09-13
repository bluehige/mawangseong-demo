# 원정 비용·예약 효과·편성 예고 핸드오프

## 1. 메타데이터
- 작성일: 2026-09-14
- 목표 버전: 공개1.2.6 보존, UIUX V2 개선 작업. 새 버전 미정.
- WORKSTREAM_ID: UIUX-V2-RAID-CHOICE-20260914
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 main/origin/main/조회 원격main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 세션 시작 HEAD: 33e983cd5de38ee5291505b87759d4e7e511d95b
- 마지막 구현·QA 커밋 SHA: 317bee9cdce1393c38a3bdf8577bca010e8aab07
- 원격 푸시: 없음. PR·릴리스·태그 없음.
- main 권위 CURRENT의1.2.6이 과거 AGENTS1.2.5보다 최신. 사용자 지시 대조, 버전 임의 확정 없음.

## 2. 목표와 완료 조건
사용자의 나머지 완성도 개선 계속. 현재 진입점의 원정·필수 선택·투자 대가 가독성에서 실제 원정 12개의 비용과 효과를 연결한다. 혼자 구현하고 마지막 관련 검사. 전체 회귀·출시 제외.

## 3. 완료한 작업
- 원정 비용/총보상/순보상을 함께 표시. 실제 출발 전후 잔고와 delta를 last_raid_result.resource_balance에 추가.
- DAY28의DAY30 예약 효과를 선택 상세·하단·완료 보고에 명시. 실제 전선/예약 효과가 포함된 WaveManager 전후 편성에서 종류별 적 수·첫 등장 지연 예고.
- 출발 가능 판정과 브리핑 뒤 확정의 날짜·필수 그룹·인원·완료·양자택일·자원 검증 통합. 결제 시 다른 임무 자동 대체 제거.
- 긴 카드 보상·위험 두 줄 잘림 수정. 별도 modifier 설명이 없는 성광/길드 작전에 실제 설명 사용.
- 비용/보상/AI/스토리 데이터/미술/저장 버전 변경 없음. 기존 원정 딕셔너리에 선택 필드 추가.

## 4. 변경 파일
| 경로 | 변경 |
|---|---|
| scripts/game/GameRoot.gd | 실제 원정 결산/검증/날짜별 효과 조회/예고 |
| scripts/ui/RaidWorkspaceUI.gd | 순보상·적 수·시점·긴 문구 |
| tools/UIUXRaidChoiceTest.gd, .gd.uid, .tscn | 12개 실제 처리/거부/예약/화면 직접 검사 |
| tools/tests/V122SaveProgressionTest.gd | 종료 UI 타이머 정리 |
| docs/qa/UIUX_V2_RAID_CHOICE_2026-09-14.md | 수치/증거/제한 |

## 5. 그래픽 및 오디오
신규 생성·편집 없음. 승인된 미술 유지. 방향별 스프라이트 ASSET_BLOCKED_NATIVE_ALPHA 유지; 동일 생성 반복 금지.

## 6. 마지막 관련 검사
| 검사 | 결과 |
|---|---|
| UIUXRaidChoiceTest | PASS 320 |
| FinaleEveHardeningTest | PASS 64 |
| HolyPurificationPhase19Test | PASS 49 |
| GuildRepossessionPhase21Test | PASS 37 |
| V122SaveProgressionTest | PASS |
| Windows 1920×1080 100% /1280×720 115% | 네이티브 원정4종×2, 핵심 효과·줄바꿈 확인 |
| git diff --check | PASS |

증거 `tmp/uiux_raid_choice_20260914/index.html`, `results.json`, `direct.log`, `*Test_final.log`, PNG9장. before는 이전 RaidWorkspaceUI를 현재GameRoot와 실행한 레이아웃 비교이며 하단 문구는 현재 코드다. 비교파일 부재 시 before만생략.

첫 검사 타입 선언/전선fixture 심장 선택을 보완했다. 초기 성광/저장 검사 종료 자원 정리 진단 발생; 성광 최종 단독실행 깨끗함. 저장 검사는 UI 타이머0.3초 정리 추가 후 최종 예상 손상JSON3건 외 오류 없음. 최종 기능 변경 뒤 직접 검사 재실행. 이후변경은 테스트 비교파일 존재guard 및 종료정리, 해당검사 재실행.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 317bee9cdce1393c38a3bdf8577bca010e8aab07
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..317bee9cdce1393c38a3bdf8577bca010e8aab07
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

이 판정은 이번 관련 변경에 한한다. 누적브랜치 전체 검수 판정이 아니다. ReviewedSHA 이후 docs/handoff만 변경.

## 7. 미해결 항목과 제한
- 모든 자원1000으로 개별 원정을 실행했다. 연속 성장·투자·전투 소비까지 합친 경제 완주/승률 미검증. 임의 재조정 없음.
- 예고 수치는 현재 알고 있는 전선/예약 설정 기준. 이후 사건 선택으로 바뀔 수 있으며 전체 보스 메커니즘·승률 예측 아님.
- UI 단축조작 전체 회귀·사람 사용성·Web·저사양·장시간·전체DAY1~30 미실행.
- 새 방향별 그래픽 alpha 문제 유지. 최종 출시 HOLD.

## 8. 다음 작업
1. 준비 화면의 투자·원정·전투 결산을 이어 읽는 자원 안내/막힘 해소 흐름을 실제 기존 기록으로 연결. 예상 경로 scripts/game/GameRoot.gd, scripts/ui/ManagementWorkspaceUI.gd; 비용 변경보다 정보 정확성을 먼저 개선.
2. 남은 기능/UI 구현을 묶어서 마무리한 뒤 마지막 관련 검사. 전체/사람 검수는 별도 사용자 지시 범위에만 실행.
3. 그래픽 투명 생성 도구 조건이 바뀌기 전 동일 시도 반복하지 않음. 출시/태그 임의 실행 금지.

## 9. 작업 트리
시작은 깨끗한 기존 작업트리. 이번7개 구현/QA 파일만 명시적 커밋. 사용자 변경 없음. 핸드오프/현재문서 별도 로컬 커밋 예정. tmp 빌드·캡처 미추적/커밋 제외. main·과거실험·출시태그 그대로.

## 10. 종료 확인
구현·관련 검사·증거·버전 보존·검수SHA 기록 완료. CURRENT 갱신. 전체 검수·공개배포 없음.
