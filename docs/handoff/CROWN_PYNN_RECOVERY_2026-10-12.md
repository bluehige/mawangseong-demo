# 핀 마나 효율·삼색 마왕화 구현과 검증

제품 `dc22af2dfd47be0e5c1f968a5b8e34e8dd7c9e1e`, branch `codex/crown-pynn-mana-tricolor`, Godot4.6.3. 사용자 답 ‘마나 효율로 변경하고 비용도 재설계’를 [사전계약](CROWN_PYNN_SPEC_2026-10-12.md)에 고정하고 구현했다. 버전1.2.11/세이브 기본경로/단일체크포인트/원격Git/공개Steam 설정은 변경하지 않았다. 로컬main 부재·origin/main의 원격 최신성 미검증은 기존과 같다.

## 변화

핀의 작동하지 않는최대마나1.06 항목을 실제자기스킬 **마나효율1.06**으로 바꿨다. 일반화염구/화염지대20/40은 활성왕관핀만19/38, 다른시전자·선택된캐릭터없는기본quote·합동공용비용은 유지한다. 억제시원래가격, 준비뒤가격/봉쇄/왕관상태변화는 차감전에실패한다. 마나상한/새재화는만들지않았다.

삼색 단일은 실제magic투사체 발사→나중도착에서피해, 광역은기존실제대상범위/피해·둔화/firehit커널, 저주는피해0의독립DEF약화/둔화다. 저장계승으로기존화염숙련damage×1.10·잿불duration×1.20을 적용한다. 저주 NEW: normalDEF2/5초,bossDEF1/4초·slow.70/2.5초에왕관duration1.30, 기존적대상태보정과첫heart둔화token1회. 기존armor_break/slow/heart상태를 덮어쓰지않고 원본왕관source억제/다운·수명종료시자기key만폐기한다.

| global1/활성왕관 실제소모 NEW_DESIGN | 단일 | 광역 | 저주 |
|---|---:|---:|---:|
| 기본 |23|26|15|
| 같은불씨 반복 |27|32|18|
| 세종순환 다음 |16|19|10|

modebase24/28/16→기존repeat20%/cycle30% round→기존global회차 multiplier ceil→효율division/roundnearest(min1 positive),0원은0. 실제기존마력배급칙령.80과합성검증. 수동HUD/auto reserve/prepare/commit/실제차감은동일quote다. 일반fireball의single·flamezone의area·실제왕관mode가commit뒤이력을최신3개로기록한다. 일반두종+왕관저주로세종을완성해 **왕관2회제한 안에서 두번째할인이 실제로가능**하다. 실패·보기만/중복skip은이력/사용횟수/비용0.

실제desktop/touch전투inspector에세mode선택·일반2스킬/선택Royal실행을 연결했다. 수동선택과auto유용성선택은분리하며가격/남은횟수/현재효율을표시한다. 메뉴·스토리·백로그·presentation중버튼callback은시전하지않는다. 실제확장Control크기/canvas변환으로pointer소유권을판정해새버튼클릭이world클릭으로선택을파괴하던문제를수정했다. 현재native왕관sheet·기존VFX/실제target컷씬과발사/접촉/저주·실지출문구를구분한다.

변경13파일: 새 `scripts/combat/CrownFlameRuntime.gd/.uid`, Root/CombatSceneController/HUDController/Unit, CrownEvolutionService, update4skills/crown_evolutions, 새CrownPynnRecoveryTest.gd/.uid/.tscn, 사전계약문서. 기존몸체ATK배율/스킬flat원본에추가일괄공격상향은없다.

## 결과

| 검사 | 결과 | 의미/한계 |
|---|---|---|
| CrownPynnRecoveryTest 실제GUI |PASS220/0|세mode×두계승×off/once처음/seen/always, 실제투사체/영역/저주, 실제일반→세종이력→두번째할인/2회제한, globaldecree·다른caster/zero/min가격, stalehistory/mode/source/대상/mana/봉쇄, 기존상태공존·actualbossactor·firstheart1회·auto효용0회피 |
| 실제desktop/touch입력 |PASS8/0 각각|nativepointer→mode가격15→menu보호callback→실제cursepay15→다음repeat18, controls実bounds. 실제사람OS손입력은NOT_RUN |
| CrownLiveStatRecoveryTest |PASS1051/0|기존왕관현재능력치·억제/복구/절대HP·nativebody/기존기대값유지 |
| BasicSupportRecoveryTest |PASS253/0|기존지원·젤·합동 회귀 |
| PlayerContinuityTest |PASS89/0|메뉴/저장실패/체크포인트/백로그. synthetic실패경고는의도한검사 |
| CrownGobPynnPhase27Test |PASS22|기존순수계약유지. 곱실전/상대매트릭스·기여율/승률의실제검증으로해석하지않는다 |
| editor/export |exit0/error0|새분리패키지 |
| 실제PCK |PASS18/0|actualmana19/38→15→16·세종이력·피해/독립저주·uses2·source억제·실제UIbounds/productionexit |
| 독립읽기/실제PCK |TARGETED_PASS·18/0·exit0|제품13hash/ReviewedSHA확인·열린확정P1/P2 0, 별도TempAPPDATA/LOCALAPPDATA, 같은불변PCKhash |
| WindowsEXE시작 |180frame exit0/error0|패키지내부userdata만 |
| 개인/이전패키지보존 |PASS|698mismatch0, 이전5패키지×3해시15변경0, 원본17capture/기존5artifact보존 |

최종GUI/desktop/touch/livebody/basic/editor/export/PCK/EXE 로그SCRIPT ERROR/ERROR/ParseError0. 최초205/1 FAIL+invalidcontrols SCRIPTERROR는보존했고, 원인은실제확장inspector 클릭의world소유권누수→선택/UI파괴였다. 사전읽기의auto효용0저주·ordinarycontact봉쇄P2두건도수정하고재검증했다. 주관적컷씬질·재미/자연진행밸런스평가는하지않았다.

## 검토본/복구점

`evidence/royal-support-recovery/pynn-development-build/LaunchPrototype.ps1` 실행은패키지내부userdata를사용한다. `ReviewEvidence`에현재8PNG/결과JSON/로그·최초실패·검수보고서를모았다. 현재8PNG는직접열어nativeactor·단일발사vs피해시점·광역50/46·피해숫자없는저주·desktop/touch가격상태를확인했다. 공개배포/새바로가기/Steam설치없음.

| 파일 | 크기 / SHA256 |
|---|---|
| MawangCastle.exe |104699392 / DD562A07855D0CCED116F58E1E727250F45A0D3BF0822B96A17635240DB09845|
| MawangCastle.pck |584486072 / 18A6EE7EE9D36989F37AA73A4BE6DE6A37B8C3B0DA94439D7E4A7DC80B2DAF11|
| LaunchPrototype.ps1 |647 / D31BB2686C72DC74DD1B0F6EBA5B8B36E485DFC3EE4A57344F911B64118F24A5|

NOT_RUN/잔여: 자연영입·mastery·왕관해금, 곱실제연쇄/왕명·메아리공개/실제objective채널, 실제상층·사람재미/정상밸런스·전체캠페인/저사양/nativeOS손입력·최신Steamworks읽기·설치Steam·두PCCloud. 현재브라우저runtime장애와과거Steam게시기록은구분,설정write0. 승인성장은스킬잔여연결뒤진행한다. 전체스킬완료아님.

복구점제품dc22af2·불변패키지·8PNG·최종로그, 이후source는다른로컬branch에서진행하고이패키지는덮어쓰지않는다. 두사용자답처리완료/재질문없음, 추가필수결정은부모대화로보고한다. Review task ID: scoped `/root/skill_action_review`; Reviewed SHA:dc22af2dfd47be0e5c1f968a5b8e34e8dd7c9e1e; Remaining confirmed P1/P2:0; Final review result:TARGETED_PASS. External `pynn-independent-review.md` SHA941E2637CBA3E738C3DEA52357F17A8847EF698DDE41A2AB03B42CC1A1F77A66,독립PCK로그는`pynn-independent-packed.log`. 전체QA NOT_REQUESTED.
