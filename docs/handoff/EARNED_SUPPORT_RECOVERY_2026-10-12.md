# 지원 숙련과 의회 보유 편성 연결

제품 SHA `efc7aa12e58f5064016edd0ba67dc2f7c94ca8d9`, 브랜치 `codex/earned-support-progression`, 기준 문서 SHA `4e11172`. 버전1.2.11 / Godot4.6.3 유지. 19개 파일 변경. [설계 계약](EARNED_SUPPORT_SPEC_2026-10-12.md).

기존 계약 확인에서 얻은 모리와 기존 전선 완료/E13 보상으로 얻은 톡톡을 의회에서도 보유 예비로 복원한다. 새 무료 해금·레벨·왕관을 지급하지 않는다. 의회 편성은 기존 초기5명과 최소5명 한도를 유지하고, 보유 화면·전환 버튼·확인·실제 출전 판정에 같은 한도를 쓴다. 기존 선택은 보존하며 의도적으로 빈 편성은 빈 상태로 유지한다. 잘못된 예전 ID만 원래5명으로 복구한다. 빈 편성으로 전투를 시작하면 편성 화면에서 먼저 선택하게 한다.

모리/톡톡/포포의 실제 회복, 살아 있는 적의 실제 DEF 감소, 실제 방 HP 수리, 중계/왕관 전령 도착, 소비된 Echo 지연, 실제 가방 자원 회수에 actor 소유 기록을 연결했다. 새 숙련은 지원·같은 actor의 실제 HP 부상 후 생존 승리·기존 정상 유대80의 서로 다른 3개 성과다. 전투 성과는 승리 결산에서만 기존 crown profile로 합쳐지고 패배·포기·새 전투는 미확정 기록을 폐기한다. 예비·보호막만 받은 피해·다른 actor/전투의 부상은 생존 증거로 합치지 않는다. 기존 숙련 숫자가 더 크면 보존하며 알려지지 않은 crown 내부 키도 유지한다.

기존 왕관 숙련2/LV6/유대80/특화/인장2/회차당1회 조건은 유지했다. v5에 plain 자료만 저장하며 저장 파일·Cloud 등록 경로를 추가하지 않는다. 실제 보유/몬스터/결과 화면에서 필요한 성과를 보여주고 결과 재열람은 현재 언어로 표시한다.

| 검증 | 결과 | 범위 |
|---|---|---|
| Earned new boundaries | PASS9/0 | 같은 종 actor 분리, 왕관 실제 수리/도착, 기존 Front/E13 producer, 빈 편성, 실제 포인터 |
| Earned save targeted | PASS10/0 | 실제 v1~v5 저장, 정상 왕관 조건/비용, 불러오기, 다음 회차 |
| Earned owned touch | PASS4/0 | 실제 터치 레이아웃과 viewport 버튼 입력/새 성과 안내 |
| PlayerContinuityTest | PASS89/0 | 변경된 저장 경로 영향 확인; 의도적 실패 경고 포함 |
| PackedEarnedSupport | PASS8/0 | 새 PCK의 실제 지원/부상/승리, locale 갱신, 중복·빈 편성 |
| Packed UI capture only | PASS3/0 | 결과 scroll로 성과를 노출한 영어/중국어 GPU 캡처 |
| editor/export/EXE180 | PASS, exit0/error0 | 격리 userdata와 새 비공개 패키지 |
| 독립 고정 소스 검수 | SOURCE_TARGETED_PASS P1/P2=0/0 | 19 Git blob SHA256; 엔진 실행 없음 |
| 초기 전체 fixture | FAIL39/1 및 script error | 테스트 해금 자료 오류; 후속 저장 검사로 수정 경로 검증. 전체 PASS로 승격하지 않음 |
| 자연 캠페인 전체 획득/재미/밸런스 | NOT_RUN | 실제 producer 경계 검사는 자연 전체 플레이와 구분 |
| 현재 Steamworks/two-PC Cloud | BLOCKED / NOT_RUN | 기존 MXC Windows platform HRESULT0x80070003; 설정 읽기·쓰기0 |

비공개 패키지: `../evidence/royal-support-recovery/earned-development-build` (작업공간 evidence 아래 실제 경로). PCK584539096 bytes, SHA256 `BDBD66E09834D10A8EBCB2BEBC4FDCE3E15AA8E0CC3409C783FB8F90E013783F`. EXE104699392 bytes, 기존 DD562A...9845. 독립 보고서 `evidence/basic-support-recovery/earned-final-independent-review.md`; 실행 로그·GPU 캡처·이전 실패는 패키지 ReviewEvidence에 구분 보존했다.

개인698파일/백업 mismatch0, 기존8개 구현 패키지24개 파일 hash 불변. 원격 push/merge, Steam 공개 배포/설정 게시, 새 SDK 계약, 계정 보안 변경 없음. 기존 통과 검사는 원래 SHA/범위로 재사용하고 새로운 영향 경로만 확인했다. 다음 승인 작업은 푸딩 기존 DAY12 두 분기 행동 측정 → 실제 지원 기여 표시 → 기존 다음 회차 선택 연결이다. 전체 기능 완료나 출시 PASS를 주장하지 않는다.

Review task ID: NOT_REQUESTED (whole QA). Reviewed SHA: efc7aa12e58f5064016edd0ba67dc2f7c94ca8d9. Remaining P1/P2: N/A for whole QA; independent source scope0/0. Final review result: TARGETED_PASS.
