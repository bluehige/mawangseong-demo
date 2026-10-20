# 핀 마나 효율·삼색 실행 계약 — 구현 전 고정

제품a83460d/문서70f750e에서 별도 `codex/crown-pynn-mana-tricolor`로 진행. 사용자 답 ‘마나 효율로 변경하고 비용도 재설계’가 이전24/29/17최종유지 제약을 대체한다. 현재 최대마나 모델/공용상한/새재화는 만들지 않는다. 이 문서는 구현완료나 사람 밸런스 PASS가 아니다.

## 실제 가격 NEW_DESIGN

왕관핀의 기존 `max_mana:1.06`은 `mana_efficiency:1.06`으로 대체한다. 활성·살아있는 현재 **해당 핀**이 시전하는 일반/왕관 스킬만 source효율을 적용한다. 다른캐릭터/합동스킬팀/공용마나최대치는 변경하지 않는다. 억제 시1.0, 억제전후 가격은 준비와커밋에서 재검증한다. body없는0마나능력치를 만들지 않는다.

삼색 base mode가격 NEW: 단일24/광역28/저주16. 같은불씨 연속20%가산, 직전세개의서로다른불씨 순환뒤30%할인은 기존순수커널의 의미/우선순위를 유지하되 mode별base를 사용한다. 가격순서: modebase→repeat/cycle roundnearest→기존global회차마나 multiplier ceil→현재 source효율1.06으로 나눈 roundnearest. 양수가격은최소1, 원래0은0. 기존global회차마나효과는 없애지 않는다.

| 상황(global1.0/왕관활성) | 단일 | 광역 | 저주 |
|---|---:|---:|---:|
| 기본 |23|26|15|
| 같은불씨 반복 |27|32|18|
| 세종순환 다음 |16|19|10|

가격은 HUD/수동모드/auto마나reserve/prepare/commit/실제차감/기여에 동일 quote를 사용한다. 준비 중source왕관상태·saved계승·battlehistory·필수타깃·고정모드가 바뀌면효과/비용/이력0으로실패. 더비싼효과로조용히재선정하지않는다. 기존왕관2회/CD0, 일반스킬 기존CD유지. 최초quote와나중mode선택을혼합하지않는다.

## 실제 세모드

- 단일: 기존fireball 실제대상320+기존rangebonus, 실제투사체. 커밋은발사이며 contactHP즉시차감0, 실제arrival 기존magic/방어/시설/focus/기여/hitfeedback커널1회. 기존52+기존damagebonus×왕관1.45, 화염숙련계승×1.10. 실제타깃경계·projectilecleanup 유지.
- 광역: 기존flame_zone의실제범위선정/기존damage34+bonus×1.35, 화염숙련×1.10. 실제동일피해커널/slow2.5·.70과기존특화보너스·거미실firehit재사용. 빈영역비용0, 준비목록을소리없이전체맵적목록으로바꾸지않는다. 삼색광역은별도Royal1회hit, 일반승급의잔열지속을자동중복발동시키지않는다.
- 저주 NEW: 화염구실제사거리 대상1명, damage0. 기존Tok DEF약화에서빌린 normalDEF−2/5초, boss−1/4초; 기존flame slow .70/2.5초를 독립Royal상태로연결한다. 왕관duration×1.30, 잿불주술계승×1.20. 실제적대status효율은적용순간sample1회. 별도armor/slow소유key/deadline이라기존armor_break/slow/heart timer를덮어쓰지않는다. 같은종재적용은강한값/긴기한,무한합산없음. Royal원본이down/queued/억제되면자기상태만폐기; 기존상태는보존.

saved `crown_source_evolution_id`를사용하고legacy없는경우기존Group5호환정책을재사용한다. 평범fireball의single, flame_zone의area, Royal선택mode는 **활성왕관의실제commit 후만** battlehistory에append한다. 실패preview/준비/skip중복/컷씬뷰만으로이력없음. 투사체는commit발사기록으로카운트하며나중miss도발사였다는사실을바꾸지않고실제damage기여0. 일반single+area+Royalcurse로3종순환을정상적으로만들어Royal2회제한과모순을해결한다. 이력은최신3개만; 저장/다음전투/타이틀에임시이력/사용횟수/저주key를재생하지않는다.

## 모드·자동·컷씬·검증

수동은현재선택모드/가격을표시하고세모드를선택할수있게연결한다. 자동은실제enemy/range/area/현재저주 필요와불씨이력을평가해유효mode를고정하며다른모드의quote를사용하지않는다. 준비조건을충족하지않는일반자동스킬정책은기존대로다음스킬을평가한다. 전투지원없는적에게마나공회전없음.

native현재왕관sheet/기존실제공격·스킬animation과fireball/flame/curse관련기존VFX를사용한다. 약1초컷씬/once·always·off·skip는effect1조건동일; mode/실제가격·발사vs도착·실제저주를문구로구분하고damage0저주를피해숫자로연출하지않는다. passive가격효율마다별도컷씬을띄우지않는다. actualcast/mana실지출·savings·actualHPdamage·curse실기여를허위합산하지않는다.

수동·actualauto/세mode/두계승/가격행렬·globalcycle·다른caster/억제·source변경/준비후마나·두회/이력producer·projectile실제arrival·별도상태timer/legacy상태공존·boss·메뉴·x3·중복skip·현재native/HUD·새PCK를집중검증한다. 캐릭터일괄공격력/해금일/적수/새층/RemoteStorage/새재화0. 사람재미/자연해금·balance·실제Steam·Cloud는별도NOT_RUN. 추가필수선택은부모에질문/권장안/영향보고한다.
