# 메아리·1층 실제 목표채널·전령가방 실행 계약 — 구현 전 고정

기준 제품8b15d27/문서fc6bb21, 별도 codex/echo-native-objectives. 사용자 승인한 이름뿐인 플레이어 스킬/컷신 실제 연결의 마지막 경보 묶음이다. 새캠페인/층/맵/적수/재화/SDK/RemoteStorage는 추가하지 않는다. 실제1F 보물방을 의회자원 상호작용 장소로 쓰는 NEW_RUNTIME이며 실제2F·seal_vault geometry·Vesper전체kit·outpostcache 완성이라 하지 않는다. 구현완료/PASS·사람밸런스 증거가 아니다.

## 실제 채널과 손실

현재 살아있는 실제 dusk_courier/Vesper를 정상DataRegistry/spawn의기존1F graph로보행시킨다. 의회모드/실제활성보물방/합법경로/의회자원/공유손실cap검증 후에만해당방을목표로선택한다. 실제방·중앙12거리 도착 후actorID+generation+channel-generation 소유채널 시작. 없는경로/목표/자원은기존왕좌공격fallback이며태그뿐인경우진행채널/지연을주장하지않는다. 각기존방/계단/배치/적수유지.

Dusk native4초,실제양수HP손실 때채널중단→retry1초→새4초. fullyshielded HP0은damage interrupt0. Vesper native5초/CD14,채널중실제받는피해×1.25; 종료/취소/이탈/down시이승수만해제. 채널/재시도중일반공격·navigation경합금지,이동중일반교전은기존대로허용. 시작/재도착frame의delta를새기한에중복소모하지않고 retry-residual은분리소모한다. pause/cutscene는진행/지연/가방clock모두정지,배속은simdelta1회적용.

한 전투 공유실제손실게이트 max1. native완료는UpperFloorObjectiveService의기존settlement우선순위(표>=5면표5,아니면실제인장최대1)·cap를재사용해Root.update4_active_run.council_season을실제변경한다. actual before/after/resource kind/amount/owner/channel-generation/loss-ID를별도원장에고정한다. 자원0 손실은기여/회수/추가카운터로조작하지않는다. 다른actor동시완료·중복tick·skip에재차감0. 회수해도공유cap소모유지해반복농사0. Dusk완료는기존실제exit로보행/탈출(처치보상0),Vesper는기존왕좌교전복귀. 정상낮은층adapter metrics는명시적으로1F라표시하고옛pure2F검증과분리한다.

Gob금고계승의공통 interrupt는실제미완료 native채널에도연결한다. 일반Dusk양수피해가이미retry를시작했으면Royal추가중단기여0. Vesper기본피해는원기획상자동중단하지않으며특별왕명은양수미완료진행을실제로초기화하는 NEW_RESET; 이미0/완료는효과0. 이공유경계는기존gold2→0/완료-999불변도보존한다.

## 메아리 경보

마나12/CD12/경보8초·일반목표지연2·실제boss태그.7 유지. 현재alive/유효1F actor의기존stealth/ambush/seal_thief태그와별도legacy-gold thief adapter만후보. cast시현재실제목록/소유ID를고정,contact에재검증,빈/사라진목록은차감0. 이미보이는태그는경보/표시이며실제hidden→reveal과구분한다. 미래spawn전부/가짜층/평타cooldown/일반stun/이동감속으로대체하지않는다.

현재진행중채널만실제delay debt에최대2/.7 credit(한channel-generation의남은credit은max로갱신,무한합산0). credit을먼저소모한뒤channel진행하며elapsed진행을0/음수로만들지않는다. Dusk4→6, Vesper5→5.7,legacygold5→7를현재unopposed종료시각으로검증. 아직이동/재시도/이미완료는actualdelay0·경보8만. contest는기존gold진행과credit소모를모두멈추고,채널재시작/이탈/삭제는oldgenerationcredit폐기. 배분credit와실제소모지연을구분하고actual consumed만지원기여로계산한다. 같은cast/skip/actor duplicate로재차감/재배분없음. 자동은실제숨은적해제 또는현재채널에새delay가능할때만경보마나를쓴다. 수동의경보만가능한선택은actualdelay0으로정확히표시한다.

컷신현재포포native/crownframes와경보VFX/SFX/실제대상을재사용. 준비는유실될hidden/목표상태를변경하지않고contact후8초경보·실제숨김해제수·이번배분/진짜채널지연을구분한다. 화면genericmanualUI에Echo를현재slot로연결,메뉴/스토리/백로그/presentation중callback봉쇄. 기존Royals.20도착지원/일반밤길중계와경보는각기다른효과/기여/사용횟수다.

## 실제 잠행 생산과 인지 NEW_RUNTIME

nativeShadow의기존 recent-contribution-hunt/그림자약속을최소1F로연결한다. 실제최근12초기여 몬스터를선정·실제방에보행접근 후같은실제방/안전경로/안전한target뒤90위치일때전투1회기존behind이동과2초ATK1.20/DEF.75. 기존왕관Body/globalatk/다른actor를변경하지않고실효공격/방어kernel에이actor의source/timer를연결한다. 강제도발/실제방이탈/down/queued/위치불가와수동focus기존규칙을보존한다.

NEW conceal: 이실제Shadow급습동작동안최대기존duration2초(수치차용이며옛은신기획완료아님),첫실제공격 또는실제양수피해에잠행종료. 지도는희미한잠행실루엣·직접조준불가로표시한다. 일반적전부의영구은신/위험공격일괄상향없음. 경보8/현재watch-post reveal/해당Koko의실제scent 추적예외는독립소유자로인지한다. root visibility/floor설정/사망alpha를덮어쓰지않고잠행alpha만현재source에적용/복구한다. watch/경보만료가상대source를지우거나expired기저잠행을부활시키지않는다.

중앙Targeting.nearest/monster_priority 및강제/수동focus/preferred/direct실행·CrownGob mark/chain·표적스킬contact에서observer-targetability를일관되게검사한다. 이미발사된투사체와실제물리AoE/함정은피할수있는새면역을만들지않는다. Koko실제scent_lock는잠행추적예외를생산하는전용대응;일반자동표적은숨어있는배열원소를텔레파시조준하지않는다.

## 전령가방 실제 원장·도달

현재살아있는배치포포가있을때전투첫의회손실1회만held. 원기획5초,Express4/SealGuard7. NEW accounting: 실제의회표/인장손실을즉시1회차감해정확kind/amount/loss-ID로환불가능escrow를보관하고UI에‘회수대기’로표시한다. 시간초과는추가차감없이확정loss로전환한다. 골드절도는가방회수로확장하지않는다. 실제포포가정상안전경로로해당절도범/contact anchor12이내에기한내도달할때만정확차감액1회복원,다른절도범/원격click/중복arrival/refund불가. 회수후공유손실cap/held1소모유지.

살아있는절도범이움직이면추적목적지를갱신한다. 실제죽음시마지막실제위치의떨어진의회봉투anchor로기한을그대로유지하는 NEW_DROP(자동회수0),그위치에걸어도달해야한다. escape/증명되지않은actor교체/포포down/queued/전투이탈은held를추가debit없이최종손실로닫는다. 수동이동은bag자동길소유를취소하되기한/실제접촉으로인한회수는유지한다. 밤길중계/왕관이동은별도이동소유권을따르고기한/실제회수조건을회피하지않는다. 임시actorRef/채널/escrow는새세이브파일/전투중간세이브에기록하지않고최종실제의회자원은기존campaign모델에보존한다.

## 예정 검증 / 현재NOT_RUN

실제DataRegistry/spawn nativeActor→물리1F보행→채널화면/4·5native지속→alarm2/.7후정확완료→실제표5/인장1 before-after와한battlecap. 두동시owner/중복commit/재시도residual/전체HP방호/실제damage/Vesper1.25/시작·종료해제/이탈/down/pause/x3/large delta/완료불변/없는목표자원. Gold원본contest/진행/완료/escape비용보존. 실제Shadow1회준비/기여target/safebehind90/2초실효ATKDEF/잠행조준불가→Echo 실제reveal/watch/Koko예외/firststrike/damage 종료·소스independence. 실제원장손실→봉투5/4/7초→살아있는이동Actor 또는actualdropanchor걸어도달→정확환불1/timeout추가debit0/전투교체cleanup. nativecutscene와desktop/touch버튼,기존Gob/PoPo/Mori/Pynn/continuity 회귀와privatePCK/EXE/독립검토. Forced fixtures와정상획득·사람재미·wholecampaign·실제2F·다른보스kit·두PC/Steam은분리해NOT_RUN.
사전검토 보강: per-channel-generation allocated/consumed/remaining 누적budget2/.7,최초grant가budget예약·다시casting으로소모분재충전0. 경보8s와이미활성채널credit생명은분리,기존goldcontest시credit소모멈춤/실제이탈generation폐기. 실제delay초float와Root지원원장의밀리초정수(단위명시)를축적,standardfacility_value는누적whole초만이전해.7telemetry0절삭/700배위협score를피한다. 수동리스트/actor와준비channel-ID를고정해freshretry로소리없이credit이동0,자동접촉시효용사라짐은비용0. actualpositive자원차감때만sharedcap/held,환불은현재stock에정확차감액add하고오래된snapshot전체복원0. finish_combat의정산/save/cleanup전에미회수escrow확정. ordinary가방은Crownactive조건없음.

Implementation refinement: hold deadlines start at the actual channel completion time, including overshoot after retry and consumed Echo credit; a large frame cannot create a fresh expired recovery window. Recovery/expiry stop only an actual bag-owned pursuit path, preserving ordinary relay, royal transit and manual movement owners. Duo and specialist direct targets are checked both at preparation and contact; incidental physical AoE/ram collisions remain physical. Koko scent acquisition may explicitly find a concealed intruder in its assigned room or core, but navigation/attacks require its actual live source mark. Rendering skips queued bodies/unavailable SpriteFrames without changing unit visibility, tint or floor ownership. Initial tests and intermediate error logs are historical; final evidence belongs to the separate recovery handoff and its fixed reviewed SHA.
