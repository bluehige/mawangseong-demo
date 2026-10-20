# 성장 대표·지원 기여 검토 결과

제품 `d7f662b845399f4946bc3f7d0d4e7dc69864f8b4`, branch `codex/growth-support-feedback`, 기준 문서 `2f69f2a`, 버전1.2.11/Godot4.6.3 유지. 11개 변경 파일. [구현 계약](GROWTH_SUPPORT_SPEC_2026-10-12.md), [이전 지원 숙련 결과](EARNED_SUPPORT_RECOVERY_2026-10-12.md).

기존 푸딩 DAY12 두 분기는 실제 방패 대상과 AI 경로 목표가 이미 달랐다. 같은 그래프·실제 explorer·부상 아군 조건에서 성문 방벽은 자기 방패6초/감소48%/incoming100→HP52 및 입구 방어선 목표, 구조형은 부상 고블린 방패5.5초/45%/100→55 및 부상 아군 회복실 목표였다. 이는 통제한 DAY12/LV3/유대25 경계 검사다. AI 경로 **목표**를 확인했으며 실제 도착·자연 승급 획득·승률·사람 재미를 측정한 것으로 표시하지 않는다.

선택·완료 설명을 이 실제 역할과 우선 명령 조건에 맞췄다. 실제 shield timer/reduction을 늘린 commit에만 보호 적용1회와 첫 유효 안내를 기록한다. 안내는 actor당 전투 첫 적용, 전투 시계5초이며 입력을 가로채지 않는다. x3 및 메뉴 정지·복귀에서 수명이 맞는다. 이미 더 강하고 오래 남은 방패나 무효 준비는0. 기존 메뉴 중단은 유효한 accepted action을 한 번 확정한다는 기존 규칙을 유지한다.

결산에는 실제 출처가 있는 회복 HP, 방어막 흡수, 보호 적용, 공유 합동기 사용 중 최대3개를 표시한다. redirect는 보호자가 실제 잃은 HP 비용이며 막은 피해로 부풀리지 않는다(검사에서 nominal35 대신 actual1). 합동기 성공은 두 참여 actor가 공유1회로 표시하고 중복은0. 기존 성장 Dictionary 행에 bounded plain int snapshot으로 보존하며 오래된 행은 기록 없음이다. 실제 v5에는 기존 canonical instance ID를 사용하고 불러오면 species ID로 복원한다.

최종 승리 결과의 정적 안내는 현재와 반대인 기존 푸딩 분기 하나, 모리 보유/기존 계약, 실제 합동기 해금 조건45/1/3/5를 읽는다. 이미 해금했다면 반복 조건을 요구하지 않는다. 이미 본 일반 엔딩만 기존 requirements/현재 metrics로 확인하고, 전체 엔딩 판정과 구분해 보장하지 않는다. 새 팝업·보상·화폐·엔딩·자동 새 회차 없음. 해금일·공격력·적 수·기본 AI는 바꾸지 않았다.

| 검증 | 결과 | 정확한 범위 |
|---|---|---|
| 변경 전 분기 baseline2 | PASS9/0 | 실제 방패 대상/효과와 서로 다른 경로 목표 |
| GrowthClockUI desktop/touch | PASS8/0 각각 | 실제 x3 physics .1→time.3, 남은4.7; 메뉴 정지, x1 복귀 만료; 새 설명 GPU 캡처 |
| Growth existing save read | PASS7/0 | 이전 실제 작성 v5 읽기, heal6/shared1, canonical ID 복원, title→continue 보상/EXP/유대 중복 없음, 과거/잘못된 자료 |
| PackedGrowthSupport | PASS15/0 | 새 PCK의 보호 commit·준비·x3/메뉴/배속3, 실제 합동기/중복, 실제 HP 비용, snapshot, 현재 영어/중국어·최종 안내 |
| editor/export/EXE180 | PASS exit0/error0 | 새 비공개 패키지·격리 userdata |
| 독립 고정 소스 | SOURCE_TARGETED_PASS P1/P2=0/0 | 11 Git blob SHA256. 독립 엔진 실행 없음 |
| 초기 runtime/후속 fixture | FAIL72/6, FAIL14/2, FAIL16/2 | 잘못된 charge key/유효 heart 없는 자료/저장 canonical ID 예상 오류. 실패 경로를 분리 수정·검증; 전체 PASS로 승격 안 함 |
| 첫 baseline | INVALID apparent9/0 | 존재하지 않는 Unit property script error; 후속 baseline2만 PASS |
| 자연 전체 캠페인·재미·승률 | NOT_RUN | 실제 사람 평가 필요 |
| 기본 곱 AI 차별화/대기 압축 | NOT_RUN | 기존 실험 flag 유지, 기본 밸런스 변경 없음 |
| 현재 Steamworks / 두 PC Cloud | BLOCKED / NOT_RUN | 기존 MXC HRESULT0x80070003, 이번 설정 읽기/쓰기0 |

검토 패키지 `C:\Users\blueh\Documents\Codex\2026-10-11\task-2\evidence\royal-support-recovery\growth-development-build`. PCK584547588 bytes, SHA256 `56C8FC89A7C966872306357C35859490801F7FEDD4FD993E015D008F45BFB35E`. EXE104699392 bytes DD562A...9845, launcher647 D31BB...24A5. ReviewEvidence에 source/새 PCK GPU 캡처14개와 로그, 별도 IntermediateNotFinalPASS 실패 이력, 독립 보고서가 있다. Root는 첫 안내·지원 결과·최종 안내 등의 대표 캡처를 직접 확인했으며14장 모두 독립 시각 검수한 것으로 주장하지 않는다.

개인698/백업 mismatch0, 기존9개 구현 패키지27개 파일 hash 불변, 원래5개 자료/17캡처 보존. 최신 패키지는 이전 스킬·긴급전령·마나효율·숙련 변경을 포함한다. 실제1F 긴급전령 대체와 핀 효율1.06/왕관 base24·28·16 재설계는 이전 승인 답변대로 유지된다. 실제2F·전체 보스/전초 확장이나 인간 밸런스 PASS와 구분한다. 이전 검증은 원래 SHA/범위로 재사용했으며 이미 통과한 큰 묶음을 반복하지 않았다. 시간·토큰 절감의 비교 수치는 NOT_MEASURED다.

실행은 LaunchPrototype.ps1로 패키지 userdata를 분리한다. 현재 승인된 대표 성장 구현과 검토 빌드까지 완료했으며 출시 전체 PASS를 주장하지 않는다. 다음 판단은 실제 플레이 평가와 접근 가능한 Steamworks/두 PC 결과, 출시 전 검토다. Steam 공개 배포·developer-only 해제/게시·원격 push/merge·SDK 계약·계정 보안 변경 없음. Cloud 게시 변경은 실제 결과를 부모에게 전달하고 별도 승인 후만 진행한다.

Review task ID: NOT_REQUESTED (whole QA). Reviewed SHA: d7f662b845399f4946bc3f7d0d4e7dc69864f8b4. Remaining P1/P2: N/A for whole QA; source scope0/0. Final review result: TARGETED_PASS.
