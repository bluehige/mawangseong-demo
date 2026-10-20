# 곱 왕명·연속 공격 실제 연결과 검증

제품 `8b15d27211dfcd18cb56444bc00c6b06f817e6ac`, branch `codex/crown-gob-chain`, Godot4.6.3. [구현 전 계약](CROWN_GOB_SPEC_2026-10-12.md)에 따라 이름뿐이던 왕명 표식/두 번 베지 않는 명령을 실제 전투에 연결했다. 기존 왕관 ATK1.16/이동1.06, 비용0/CD0/전투2회, 종료후DEF.85/4초를 보존했다. 버전1.2.11·단일체크포인트·세이브 기본경로·원격Git·Steam공개 설정은 변경하지 않았다. 로컬main 부재/원격 최신성 미검증도 이전과 같다.

실제 살아있는 적의 완료약탈 탈출·현재진행중 unopposed약탈·실제왕좌/심장/시설 압박·물리방/거리에 기반한 NEW 왕명 adapter를 분리했다. 코코 scent/bounty와 수동focus/강제도발을 덮어쓰지 않는다. 동일종의 단순goal 태그를 진행채널로 간주하지 않는다. 제시한 점수500/400+/300/200/100은 NEW_DESIGN이며 실제DPS/사람위협측정값 아님.

연쇄는 실제보행 접근→표적 기본타격1→기존공격간격→인접 support/healing/aura 보조적 최대1 기본타격→출발점으로 실제보행 복귀다. 상대ID/출발좌표/물리방/saved계승/focus는준비시고정, 실제접촉때alive/room/adjacency/경로/봉쇄/도발을재검증한다. 기존기본공격의directive/시설/명령/body/피해감소/실제HP/기여/down/반격/tail을그대로추출재사용했고 quick_slash1.9·순간이동·지도전체2타·추가보상으로대체하지않았다.

실제첫타격 전달때만 사용1과표식방 skill부채1, 두번째타격은부채추가0. 준비·컷씬·접근실패는비용/사용/부채0. 보호막으로HP손실0인전달타격과실제HP기여를구분한다. 동기HP callback·부채시설억제·레온반격 전에contactcallback으로기록을확정하고, in-flight취소와battle-generation변경은다음타격/이전연쇄부활을막는다. 수동이동·focus변경·sourcedown/억제·방이탈·정체·경로실패는남은타격을취소하며첫명중은환불하지않는다. 단일pending_atomic_tail을덮어쓰지않는다.

마지막 실제명중 연쇄 종료/취소 시독립DEF.85/4초를최종DEF에적용한다. 다른base/guard/heart/forge/curse원본을수정하지않는다. 약화중에도CD0에따라남은두번째접근이가능하고, 가장최근종료현재시각+4로기한갱신하며.85하나만유지한다. 최초4206849에있던불필요한4초재시전금지는독립P2검토후최종8b15에서제거했다.

매복계승은첫명중뒤4초 frozen primary에실제가시함정1회×1.20(14→17,유인30→36), 실제총HP와원시추가요청값을분리기록한다. 보호막/피해감소가있는실제추가HP를추정해성공이라고하지않는다. 금고계승은실제미완료 unopposed금화채널의양수진행을0으로중단한다. 이미0/contest/완료-999에는효과0·금화환불0이다. 실제vault_guard승급 actor의정상명중으로2초취소기여를검증했다.

현재왕관sprite/target과off/once/always공통commit컷씬은‘연쇄접근시작·실제타격후사용’으로표시해시전시없는HP피해를보이지않는다. 실제명중/복귀상태/DEF기한/남은사용을HUD에표시한다. 핀전용모드는보존하고다른아군inspector에이미연결된일반·왕관버튼을현재슬롯으로추가했다. desktop/touch실제높이526/780,최종홀수Royal버튼fullwidth,Group6 actualControlpointer소유권/메뉴·스토리·백로그·봉쇄·연쇄보호를재사용했다. 내부phase문자열은플레이용한글/영문/중문으로표시한다.

변경10파일: 새CrownCommandRuntime.gd/.uid,Controller/Unit/HUD/update4skills,새CrownGobRecoveryTest.gd/.uid/.tscn,사전계약. 로컬4206849에기본연결,최종8b15에CD0보존수정. 이후이문서/CURRENT는별도문서커밋이다.

## 집중 결과

| 검증 | 결과 | 한계 |
|---|---|---|
| CrownGobRecoveryTest 실제GUI | PASS112/0·런타임오류0 | 왕관/대상/레벨강제fixture,정상획득아님 |
| CD0약화중두번째실제사용 | PASS6/0 | 동일.85갱신/정확2회,사람밸런스아님 |
| 최종실제마우스/터치버튼 | 각PASS9/0 | viewport MouseInput,물리OS손입력아님 |
| 현재native컷씬/실제복귀시각 | PASS13/0·현재4PNG직접확인 | 순수서비스출력/완전새art아님 |
| 기존지원/핀회귀 | PASS253/0·220/0 | 집중범위 |
| PlayerFeedback / PlayerContinuity | PASS136/0·89/0 | continuity의합성저장실패경고는의도된fixture |
| Editor / 최종Windows export | exit0·확인오류0 | 첫safe-save오류exit0은중간실패로보존,설정보안변경없음 |
| 실제최종PCK / 독립PCK | 각PASS19/0·exit0·오류0 | 소스밖격리cwd/독립freshTempAPPDATA+LOCALAPPDATA |
| 추가실제PCK contest비교 | PASS22/0 | 기본19+실제진행2/보물방hunter/대체왕좌압박3;독립보고서의추가fixturegap은이후root증거로보강 |
| 자기EXE기동 | 180프레임exit0·오류0 | 전체캠페인/사람입력아님 |
| 보존 | 개인698 mismatch0·이전6패키지18hash동일 | 원본5산출물/17캡처도동일 |

독립보고서 `../evidence/basic-support-recovery/gob-independent-review.md`: Product/Reviewed8b15,10파일hash,발견P2세건수정,확정열린P1/P2=0/TARGETED_PASS. SHA256 **C06DD044BE7F489D290357A94D2A889371BBBDAEDFCE59CEDFDD95363F630BE2**. 전체스킬/캠페인QA·자연왕관획득·실제사람재미/밸런스PASS는아니다. 독립검토후추가rootcontest22시험으로단순목표태그/멈춘채널의위협오판정회귀도보강했다.

개발패키지 `../evidence/royal-support-recovery/gob-development-build`, LaunchPrototype.ps1로package-local userdata. 현재4PNG/최종로그/중간실패로그/manifest보존. 새desktopshortcut없음. 이전4206849 PCK/EXE는 `gob-draft4206849` 중간본으로보존하며최종배포본으로간주하지않는다.

| 파일 | bytes | SHA256 |
|---|---:|---|
| MawangCastle.exe |104699392|DD562A07855D0CCED116F58E1E727250F45A0D3BF0822B96A17635240DB09845|
| MawangCastle.pck |584502140|E602D706FFFE6F5FD49C8C0C14CDEC916A8F9FEBADEA2D0AC45513142367A1A5|
| LaunchPrototype.ps1 |647|D31BB2686C72DC74DD1B0F6EBA5B8B36E485DFC3EE4A57344F911B64118F24A5|

## 남은 승인 작업

메아리의실제reveal/목표채널/인장회수·정상계약영입/예비배치/숙련도획득·승인성장흐름은이후단계다. 현재전체기능완료주장없음. 실제상층맵/다른native보스전체kit/아웃포스트는이번곱복구결과와별개다. 자연플레이/사람밸런스/wholecampaign/실제Steam설치/새DKSteamworks읽기(환경blocked)/두PCCloud는NOT_RUN. 모든공개Steam/settings/Developer-onlytoggle/원격pushmerge/SDK계약/보안변경0,추가필수판단은부모에게보고한다.
