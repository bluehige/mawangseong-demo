# 왕관 능력치·현재 외형의 안전한 억제/복구

Product/Reviewed SHA `d9de8a78333b1c28001ca5e903ba1e65fbb551e3`, branch `codex/crown-live-stat-recovery`, Godot4.6.3. 표시1.2.11 유지. 독립 집중 읽기 `/root/skill_action_review`: TARGETED_PASS, 열린 확정 P1/P2 0. 전체제품 검수 task NOT_REQUESTED. [승인과 명세](SKILL_COMPLETION_SPEC_2026-10-12.md).

왕관6종의 HP/ATK/DEF/이동은 기존 setup에 굳어 있어 억제 뒤에도 남거나, 억제 상태에서 태어난 actor가 복구 뒤 보너스를 얻지 못했다. 정확한 성장·레벨·승급·특화·회차·계약 계산과 rounding **이후**, 왕관 배율 **이전** snapshot을 저장하고 실제 읽기/피해/치유/physics에서 왕관 한 층만 현재 상태로 갱신한다. 이전 값 나눗셈이나 중복 곱셈 없음. guard/heart/갑옷감소/산성/보행/중계·후패널티는 별도 기존 층으로 보존한다.

HP 전환 NEW_POLICY: 살아 있으면 절대HP를 유지하되 낮아진 maxHP까지만 clip하고 HP1을 유지한다. cap 증가만으로 회복하지 않는다. down0은 그대로0/down, 부활0. 전환은 피해/치유/기여 사건이 아니며 기존 HPsignal/root Pudding 지원 재진입에는 source flag를 먼저 갱신해 무한 emit을 막는다. 원래 HP40% 이하 처음15% 방호의 정상 Root callback은1회 발생하며 반복 왕관 전환으로 중복 지급하지 않는다.

기존 외형 규칙 **억제→정확한 pre-crown 외형, 복구→현재 crown native 외형**을 유지했다. ‘형성된 외형 항상 유지’ 초안은 미채택이며 기존 NativeContract/PromotionDialogue 기대값 수정0. Setup과 전환은 동일한 원래 native frame/profile/chroma kernel을 사용하고, 전환 즉시 기존 wall-depth/foot/chroma를 재bind한다. 캐시된 SpriteFrames는 복구 때 동일 자원으로 돌아온다. inspector의 이름/역할/공격·방어는 원래 정적 Label이라 전환 후 stale이었고 desktop/touch 동적 갱신을 연결했다. HP를 읽기 전에 body를 동기화해 첫 frame의 HP325/max280 같은 모순도 막는다.

모리 healing1.08은 억제 출생에서도 복구해46→50/24→26, 별도 outgoing.85패널티와1회 곱한다. 포포의 status_resistance1.06은 **NEW_DESIGN: 적용 순간 지속시간÷1.06**. 이미 걸린 타이머는 왕관 토글로 재조정하지 않는다. 원래capture_duration1.15는 실제 seal_chain의 적대 이동/스킬 lock에만1회, 아군 immunity는 그대로. relic/consecrated 및 heart 첫control1회는 기존 커널을 보존한다. 실제상태5초→4.71698초, native seal5초→5.42453초(heart 추가 전).

## 집중 검증과 실행 오류 구분

| 검사 | 결과 |
|---|---|
| CrownLiveStatRecoveryTest 실제GUI | PASS1051/0,6폼·active/suppressed 출생·20토글·HP1/down0·실제기본피해·independent층·root callback·native frames/material·타이머·현재HUD/메뉴/체크포인트 |
| 현재 화면만 재검증 | desktop8/0 + touch8/0, 각각actual active→suppressed→restored3PNG, 실제label/월드frames/HP 유지; mobile flag renderer이며 사람touch 입력 검증 아님 |
| Mori / 시설 / 기본지원 | GUI119/0 / GUI120/0 / headless253/0 |
| 기존 native profile / 대화 portrait | GUI140/0 / headless373/0, 기존 억제 외형 기대값 수정0 |
| continuity / editor / export | PASS89/0 / exit0 / exit0 |
| 실제 새 PCK | PASS15/0, 현재그림·재질·HUD·HP·모리·저항·immunity·공유마나 불변 |
| 독립 읽기 | TARGETED_PASS, 독립 engine/PCK/EXE NOT_RUN |

최종1051/8/8 및 native/facility/PCK의 ERROR/SCRIPT ERROR0. initial headless764은 능력치 연결의 중간 결과.783은 미채택 외형 초안.1024 assertion은 통과했지만24개의 depth material null SCRIPT ERROR로 **최종 실행PASS가 아니다**. 즉시refresh_depth_slot 재bind를 고쳤다. 다음1042/6은 실제 위치로 옮긴 뒤 physics를 끄고 depth를 갱신하지 않은 fixture의 첫 sample6폼 실패; fixture 실제위치refresh로 고쳐1048/0을 확인했다. stale사진에서 추가 inspector 정적label 결함을 발견해 source 수정→1051과 visual8/8로 실제텍스트·그림 검증. 시설119/1은 예전cachedcrownDEF가 남아있음을 기대한 assertion을 정확한pre-crownDEF+forge0으로 정렬; 시설효과 변경0. 실패/미채택원본은 IntermediateNotFinalPASS로 보존한다.

## 패키지·경계·최신 결정

`task-2/evidence/royal-support-recovery/livebody-development-build/development-manifest.json`에 실제 EXE180frames exit/파일해시·이전 패키지3종 각3해시·개인698/백업/기존5artifact 보존 결과를 기록한다. 이전15d시설·6869모리·5f기본·979/aab 패키지를 덮어쓰지 않는다. ReviewEvidence에 이번6GPU그림과검사/독립보고서.

이번 왕관 상태는 forced fixture, 정상영입/mastery·실제상층목표파괴/다음날복구·전체캠페인·사람OS/밸런스·두PCCloud·현재DKSteamworks는 NOT_RUN. 모두왕관패시브/스킬완성이라고확대하지 않는다. 전투임시body snapshot은 세이브체크포인트에직렬화하지 않고 복원 시 현재상태로 재생성한다.

최신 사용자 답 ‘긴급전령의 상층 구현을 다른 밸런스로 수정해봐’, ‘마나 효율로 변경하고 비용도 재설계’를 승인원문으로 명세에 추가했다. 다음은 현재전투의 실제방간 긴급지원 재설계와 핀 최대마나→개인스킬효율/실제비용재설계. 이번d9de제품의 max_mana는 여전히 미구현 표시이며 **마나효율 완료로 보고하지 않는다**. 이전24/29/17·다른층.20 계약은 역사적 기준이고 사용자 답에 따른 새설계가 이를 대체한다. 두사항 재질문0, 추가 결정은 부모대화에 질문/권장안/영향을 전달한다. 잔여4액티브/계승·정상영입/mastery·승인성장 작업은 계속, 성장순서는 스킬 뒤. 공개Steam/원격Git/홍보/서비스·보안 변경0.
