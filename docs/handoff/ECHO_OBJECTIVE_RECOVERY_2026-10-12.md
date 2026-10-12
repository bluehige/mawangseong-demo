# 메아리·전령 가방·실제 1층 목표 복구 — 2026-10-12

## 1. 메타데이터

- 목표 버전:1.2.11 유지 / Godot4.6.3.stable.official.7d41c59c4.
- 브랜치:codex/echo-native-objectives. 기준fc6bb2106aab4de4adfa2e59bc0b0a8574690b4c.
- 제품 SHA:bdf886a6def2067ea96844cc3450c4ad96e07744. 최초 구현40b2f526은 터치 가림 P2 때문에 중간 패키지로 보존.
- 원격 push/merge/PR/Steam 게시/개발자 전용 설정 변경:0. 로컬 main 없음, origin/main0ac9fdc7은 기존 원격 추적 기준이며 원격 최신 재조회 아님.
- 사용량 중단 후21:36 UTC 디스크 상태를 확인해40b2 소스/PCK부터 복구했다. 전령a834·핀dc22·곱8b15를 재구현하지 않았다.

## 2. 목표와 실제 완료 범위

일반 포포의 메아리 경보와 전령 가방이 실제 적·수거 시간·차감된 자원에 작용하도록 연결했다. 신규 실제2층과 Vesper 전체 기술 묶음은 구현하지 않았다. 기존 실제1층 보물 방과 의회 자원에 연결하는 NEW_RUNTIME adapter이며 강제 장면을 자연 획득/플레이 완료로 부르지 않는다.

## 3. 구현

- 실제 spawn한 Dusk는 기존 안전 경로를 걸어 금고 중심12 이내에 도착해4초 수거한다. 실제 HP 손실이면1초 재시도 후 새4초; 보호막만 소모한 HP0피해는 재시도0. Vesper 실제5초 수거 중만 받는 피해1.25. 채널 중 일반 공격/다른 이동 소유권을 차단한다.
- Echo 비용12/CD12, 경보8초. 준비된 actor/channel-generation을 고정하고 같은 세대 누적 지연2초/boss.7초를 한 번만 예약한다. 실제 채널에서 소비한 시간만 float초·정수ms로 기여를 기록한다. 재시전 재충전·명목 지연 기여·.7절삭0. 기존 금화 도둑의 contest/5초/sentinel-999/탈출은 유지한다.
- 의회 실제 표5(표 부족 시 인장1)를 기존 정산 서비스로 차감한다. 실제 positive before/after만 한 전투 max1 손실을 확정한다. 일반 포포가 첫 손실을5초(Express4/SealGuard7) 회수 대기로 잡고, 살아 있는 절도범이나 실제 사망 위치에 물리 도달해야 정확한 차감액만 CURRENT 자원에 되돌린다. 시간 초과/탈출/전투 종료는 추가 차감 없이 확정한다. 큰 delta 기한은 실제 채널 완료 시각부터 시작한다.
- Shadow 실제 최근 기여 추적·같은 방 안전한 뒤90 급습·2초 ATK1.20/DEF.75를 표준 피해/방어 소비기에 연결했다. NEW conceal2초는 일반 직접 표적을 제한하고 실제 공격/HP손실에 끝난다. Echo/watch/Koko 실제 source scent 탐지는 별개다. 실제 물리 AoE·이미 발사한 투사체/돌진 충돌은 유지한다.
- 준비/커밋/자동 특화/합동기/왕명/집중 공격/화면 선택에 관측자별 직접 표적 검사를 연결했다. Native 컷씬·기존 SFX/VFX·실제 inspector의 수거/경보 상태를 표시한다.
- 정보창은 컷씬 동안만 원래 가시성을 기록해 숨기고 종료/중단 시 복원한다. 메뉴·배속은 유지한다. 터치 Skip을 우측 상단/큰 영역으로 옮겨 정보창과 배속 패널에 가리지 않게 했다. 렌더링은 삭제 대기 actor/없는 프레임을 안전하게 건너뛴다.
- 저장 경로/세이브 파일 가족/버전 우선 로드는 그대로다. actorRef·채널·임시 이동은 저장하지 않는다. 종료 정산 전에 회수 대기를 확정하고 plain loss/metric만 기존 campaign에 기록한다.

## 4. 파일 변경

| 파일 | 변경 |
|---|---|
| scripts/combat/NativeObjectiveRuntime.gd(+uid) | 실제1층 채널·자원·가방·잠행/급습·정산 |
| scripts/combat/EchoAlarmRuntime.gd(+uid) | actor별 경보·세대별 지연 예산·실제 소비 기여 |
| CombatSceneController.gd / GameRoot.gd / Unit.gd | spawn/tick/원장/실제HP/표적/종료·manual 흐름 |
| CrownCommandRuntime.gd / CrownFlameRuntime.gd / DamageService.gd / TargetingService.gd | 표준 피해·직접 인지·물리 영역 효과 분리 |
| HUDController.gd / SkillActionPresentation.gd / PreparedMazeActorDepth.gd | 실제 상태·컷씬 가림/터치Skip·actor 프레임 수명 |
| tools/tests/EchoObjectiveRecoveryTest.gd(+uid/tscn) / ECHO_OBJECTIVE_SPEC | 안전한 강제 장면/구체 계약 |

fc6bb21..bdf886a의18 경로만 독립 고정 해시 검수했다. 새 그래픽/음원 생성0; 현재 actor SpriteFrames와 기존 자산을 실제 사용했다.

## 5. PASS / FAIL / NOT_RUN

| 검증 | 결과 | 근거(evidence/royal-support-recovery) |
|---|---|---|
| 최종 Echo 실제 GUI | PASS190/0, 실행 오류0 | echo-final-runtime-gui2.log |
| 실제 desktop/touch 버튼→준비→contact→Skip→정보창 복귀 | PASS9/0씩 | echo-desktop-ui-final.log / echo-touch-ui-final.log |
| 변경된 공통 컷씬 생명주기 / 실제 합동기 GUI | PASS34/0(의도된 config쓰기 경고) / PASS70/0 | echo-action-lifecycle.log / echo-action-duo-gui.log |
| 변경 전40b2 공통 효과 회귀(범위/SHA 재사용) | Basic253/Gob112/Pynn220, bodyGUI1051, continuity89; 모두 오류0, continuity 의도된 저장실패 경고 | *-frozen.log / echo-livebody.log / echo-continuity.log |
| 최종 editor/export/자체 EXE180frame | exit0, 오류0 | echo-editor-final.log / echo-export-final.log / echo-exe.log |
| PCK 핵심 효과 | 40b2 전체24/0 재사용. 최종PCK24 predicate는 실행PASS; 이후 외부 GUI 시험이 실패해 통합29 PASS가 아님 | 기존 echo-packed.log / IntermediateNotFinalPASS/echo-packed-final.log |
| 수정 PCK의 실제 터치 구간만 독립 실행 | PASS5/0, exit0, 오류0, PCK before/after 동일 | echo-independent-ui-corrected.log |
| 고정 소스/6PNG/패키지 독립 검수 | TARGETED_PASS bdf886a, 범위 내 P1/P2=0/0 | echo-final-independent-review.md |

초기 fixture FAIL130/2·131/1(배치 전 급습/정수 공격 기대값), 잘못된 시험 메서드의158/0+SCRIPT ERROR, 무효 beetle fixture 프레임의188/0+SCRIPT ERROR, inspector만 숨긴 touch8/1, 화면 그리기를 기다리는 Duo의 headless timeout, 외부 packed GUI의 Nil/좌표 전송 실패는 역사 FAIL/INVALID이며 최종 PASS에 합산하지 않았다. 실제 armored_beetle fixture와 GUI/viewport-local 입력으로 교정했다. 제품 source를 바꾸지 않은 packed 시험 장치 수정 후 UI5만 다시 실행했다.

개인 저장698개+백업 mismatch0, 이전7 구현 패키지21 파일 해시 동일, 기존5 산출물과17 캡처 보존. 40b2 중간 패키지는 echo-draft40b2f52에 보존했다.

## 6. 검수와 개발 빌드

- 초기 /root/echo_frozen_review:40b2 scoped P1=0/P2=1 터치 가림, CHANGES_REQUESTED. bdf886a 수정 뒤 source18해시/6PNG/compiledUI5로 재검수,0/0.
- 개발용:evidence/royal-support-recovery/echo-development-build/LaunchPrototype.ps1. 패키지 내 격리 userdata 사용.
- PCK584530580 bytes SHA256 2F8FE046C74271E67DC157FF52264A0007344B51F1E7981142095C8407111A1A.
- EXE104699392 bytes SHA256 DD562A07855D0CCED116F58E1E727250F45A0D3BF0822B96A17635240DB09845. launcher647 bytes SHA256 D31BB2686C72DC74DD1B0F6EBA5B8B36E485DFC3EE4A57344F911B64118F24A5.
- 최종 독립 보고서 SHA256 BE1F45B92D81AD549ED8C1961ED2E7F493F5F98003A1A55E0827235AF603DF37.
- 6개의 현재 PNG는 ReviewEvidence의 echo_objective_recovery{,_desktop,_touch}_*.png. actual 수거/경보 상태와 터치 결과/Skip 표시를 직접 확인했다.

Review task ID: NOT_REQUESTED
Reviewed SHA: bdf886a6def2067ea96844cc3450c4ad96e07744
Review range: 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b..bdf886a6def2067ea96844cc3450c4ad96e07744
Remaining P1/P2: N/A
Final review result: TARGETED_PASS

위 CI 필드는 전체 QA 미요청을 뜻한다. 실제 독립 표적 범위는 fc6bb21..bdf886a와 P1/P2=0/0이며 전체 캠페인 승인 아님. 이후 제품 source 수정0; handoff 문서만 추가한다.

## 7. 미실행/위험

정상 획득·역할 숙련도·자연 왕관 해금·승인 성장 작업은 다음 묶음으로 미완료다. 실제2층/다른 boss 전체 kit/outpost/wholecampaign/사람 OS입력·재미·밸런스는 NOT_RUN. 강제 높은HP/배치/세이브 시험을 개인 진행이나 자연 해금으로 부르지 않는다.

Steamworks 최신 읽기는21:53 이후 fresh CUA inventory에서도 MXC Windows platform directory HRESULT0x80070003으로 막혔다(steamworks-browser-resume-blocked.json 실제시각 참조). 현재 포털 설정 읽기0/쓰기0/두PC 동기화 NOT_RUN. 과거 게시/developer-only0 부모 기록과 구분한다. Steam 공개 배포/SDK계약/원격Git/보안 변경0.

## 8. 다음

이미 획득한 모리·톡톡의 의회 owned/reserve 복원, 정상 편성 UI, 실제 지원/위험 생존/유대 milestone을 승리 정산과 기존 v5에 연결한다. 기존 왕관 Lv6/유대80/특화/비용 조건을 낮추지 않는다. 이어 승인된 DAY12 승급 행동 설명·실제 기여 가시성·기존 다음 회차 선택의 성장 흐름을 진행한다. 신규 필수 결정만 부모에 보고하며 이전 PASS를 반복하지 않는다.
