# 왕관 모리 실제 우산·성찬 연결

Product/Reviewed SHA: 6869de87b9acb0684da935b9310380652282cb06. Branch: codex/royal-support-skill-recovery. Godot4.6.3, 표시1.2.11 유지. Review task ID: NOT_REQUESTED (전체제품); 독립집중읽기 `/root/skill_action_review`, Remaining P1/P2: 집중범위0/전체N/A. Final review result: TARGETED_PASS. [명세·최신승인](SKILL_COMPLETION_SPEC_2026-10-12.md).

## 변경과 새 설계 구분

royal_shared_umbrella를정상수동/자동dispatch와현재왕관외형컷신에연결했다. 실제정화, 같은층아군초당3×5tick 치유, 준비시선정한아군한명의치명피해직전HP1유지, 종료후모리회복×.85/6초. 기존마나0/CD0/전투1회/5초/HP1 계약 유지, 비어있던재생크기3/s는기존합동에서차용한NEW_DESIGN. 현재실전1F; floormetadata배제fixture는실제2F증거가아니다.

포자성찬은모리의기본치유/정화/재생/기존포자젤합동의실제발신량→수신fatigue/heart→missing초과분50%/maxHP35%cap. 별도방호TTL5초는NEW_DESIGN, 양max대체/수명refresh, 기존duo/patchshield수명불변. 실제피해직전현재왕관source활성/down/free/queued를확인한다. 치유는heal의공통계산커널, 가드는실제receive_damage의shield후·HP차감전, 방호는실제손실을흡수한다.

RoyalSupportRuntime은weak controller 참조와전투임시상태만가지며체크포인트/title/새전투에정리한다. caster/recipient삭제예약에회복·방호·구조기여0. 억제시새재생·방호·구조는중단, 조기종료후회복패널티도남는다(새정책명시). 스킬봉인만있는아군도정화auto대상, 일반retaliation기억은auto부정상태아니며그기억을보존한다. 강제도발은정화한다. 기존단일정화의정책은바꾸지않았다.

실효회복/실제방호흡수/생존횟수/HP1보존과원피해무효량을별도로기록한다. 10000overkill을9988HP지원기여라고포장하지않는다. HUD사용완료·방호TTL·후회복패널티표시. 새graphics/마나경제/해금일/적수 변경0.

## 집중 검증

| 검사 | 결과 |
|---|---|
| RoyalMoriRecoveryTest 실제GUI | PASS119/0, off/once-first/once-seen/always/actualauto 효과동일,실제왕관art,5tick/치명HP1/두번째down/과회복·cap·실흡수·fatigue/억제·queued source+target·skill-onlyseal/ordinarymemory·forcedtaunt·메뉴x3·사용표시 |
| BasicSupportRecoveryTest 회귀GUI | PASS253/0, 이전거미줄/보행중계/푸딩/모리기본치유 |
| SkillActionDuoTest 회귀GUI | PASS70/0, 기존합동atomic/두멤버·현재외형·대상효과/cost 동일 |
| PlayerContinuityTest | PASS89/0, 의도된저장실패경고포함 |
| editor / Windows private export | exit0 / exit0 |
| 새 PCK / 격리 EXE | PASS15/0 / 180frames exit0 |
| 독립 집중읽기 | TARGETED_PASS, 실제2F/정상해금·전체QA/독립engine실행NOT_RUN |

초기82/10FAIL은fixture봉인API인자누락,109/1FAIL은같은시각반복auto검사에서기존.35s판단주기를건너뛴fixture. 실패원본보존, productioncadence변경0. 최종119/0은이를수정하고실제경계를검사한결과다.

PCK/EXE최종결과와해시는task-2/evidence/royal-support-recovery/mori-development-build/development-manifest.json에기록한다. 기본지원5f8554f패키지/979adcd/aab19e4는보존하고이번왕관패키지와분리한다. 이번실제GUI6PNG는ReviewEvidence에있으며Mori왕관contact를육안확인했다. 모든사진개별평가·자연해금·인간밸런스/전체physics동시전투·실제상층은NOT_RUN.

## 남은 범위·출시 전 확인

정상Mori영입/의회reserve/mastery2생산은미완료, 이번forcedcrownfixture로무료해금했다고말하지않는다. setup고정물리스탯의왕관억제/복귀, max_mana·저항의실제의미는후속연결명세에있다. heal/passive/action현재억제검사와body-stat전체복구를혼동하지않는다.

남은5액티브(메아리/곱/핀/톡톡/포포전령),젤계승/잔여passive·정상해금/실제상층과승인된성장 작업을계속한다. Steamworks DKChrome읽기도구의Windows platform directory 오류로이번NOT_RUN; 과거parent포털보고와구분. 두PC Cloud/설치판노출/사람OS/전체캠페인NOT_RUN. Steam설정·공개배포·원격Git·홍보 변경0.
