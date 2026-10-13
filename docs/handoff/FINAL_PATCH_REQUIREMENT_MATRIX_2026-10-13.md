# 최종 패치 요구사항 판정과 Steam 출시 경계 · 2026-10-13

## 1. 메타데이터

- 목표: 승인된 스킬/성장/배치/저장 패치의 증거 대조, 실제 빠진 경계만 보완, 최신 사용자 승인에 따른 Steam app5267750 업데이트/패치노트 준비.
- branch: `codex/fresh-v5-result-save-fix`; 문서 시작 SHA `6431ed1fffdbc187ff8368bec5f41f17d9838992`.
- 최종 제품: `2dfbaeea2e28b4d8d04631689eee24c9ef7b0800`, 로컬 표시/manifest1.2.11·Godot4.6.3. 새 패치 SemVer는 **현재 공개 default를 확인하기 전 미확정**. 실제 릴리스 SHA로 표시하지 않는다.
- main부재, origin/main0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b/v1.2.5f757ffa9f9e962158f2123856c8568a3163ecb6c; origin문서쌍 재독, 원격최신성 미확정/fetch0. branch-local인계이며 권위CURRENT 승격0.
- 원문 승인: 사용자2026-10-13 02:17UTC Sentinel_f0018c368fcc81919dbb64a6b4b3525c “아니 여기에 올리지말고 검수 제대로 해서 패치 수정 다했으면 패치 수정 내역까지 해서 스팀에 업데이트해”. 공개 업데이트/패치노트 승인은 유효하며 재승인 요청0. 새자격증명/OTP/계정보안변경 승인은 포함하지 않는다.

## 2. 완료 판정 원칙

아래 **완료**는 적힌 제품SHA의 자동/표적 검증을 최종 파일·함수 영향범위로 재사용하는 뜻이다. assertions는 고유 시나리오 수가 아니며 표의 숫자를 합산하지 않는다. 8개 효과를2df에서 모두 재실행한 전체QA/PASS가 아니다. 이번 실제 추가 실행은 새 실패Quit의 오류 해결 후 재저장 성공 경계만이다. fullcampaign/사람재미/사용자DAY30/2PCCloud는 별도 미검증이다.

증거루트 `B=C:/Users/blueh/Documents/Codex/2026-10-11/task-2/evidence/basic-support-recovery/development-build/ReviewEvidence`, `R=C:/Users/blueh/Documents/Codex/2026-10-11/task-2/evidence/royal-support-recovery`, `F=C:/Users/blueh/Documents/Codex/2026-10-13/task/final-review`, `N=C:/Users/blueh/Documents/Codex/2026-10-13/task/release-readiness`. 기존 로그 존재/결과는 읽기전용 두 에이전트가 대조했다.

## 3. 스킬8개 효과·컷씬·모드

| 요구사항/판정 | 검증 제품 SHA | 실제 표적검사·근거 | 최종까지 영향·한계 |
|---|---|---|---|
| 완료: stitch_stairway 실제 문턱교차·둔화·화염제거/현재외형 | 5f8554f3df4e63dc413f2f24de311041d4aa2102 | BasicSupportRecoveryTest253/0, B/support-trajectory-final.log; packed12/0 | 같은suite는밤길중계·패시브포함. 수동off/once최초/once기확인/always 및actualauto always. 실제다층 아님 |
| 완료: night_relay 실제 다른 위험방 보행→도착 후 양쪽5초 강화 | 같은5f8554f | 같은253/0·packed12/0, 메뉴/취소/이동·도착·현재actor프레임 | efc7aa1에서 도착 숙련기록1줄 추가, earned검사로확인. 위suite를 두번 더하지 않음 |
| 완료: royal_shared_umbrella 정화·재생·HP1일회구조·종료패널티 | 6869de87b9acb0684da935b9310380652282cb06 | RoyalMoriRecoveryTest119/0, R/mori-development-build/ReviewEvidence/mori-release.log; packed15/0 | manual4표시정책/auto always·억제/queued원자성. 이후 실효치유숙련기록1줄. guard명목량9988을 실제HP기여로 주장0 |
| 완료: royal_emergency_plating 실제1F시설 maxHP30%수리cap·8초30%방호 | 15d5efb67a6cc6c5229e2eadc734d9b710debd32 | CrownFacilityRecoveryTest120/0, R/facility-development-build/ReviewEvidence/facility-final.log; packed14/0 | manual4/auto always·실제시설renderer/HP컷씬·억제/무효. 이후 실효수리숙련기록1줄. 실제2F없음 |
| 완료: royal_urgent_courier 실제위험방 .20초이동→도착후6초지원·첫방CD회복 | a83460df54c7b2fddf66c68616abc2c72ee496d1 | CrownMobilityRecoveryTest202/0, R/mobility-development-build/ReviewEvidence/mobility-final-gui.log; packed18/0 | manual4/auto always·도착전효과0·동료독립수명·억제. 이후 도착숙련기록1줄. 젤계승도같은suite |
| 완료: tricolor_demonfire 단일/광역/피해0저주·실제가격·마나효율 | dc22af2dfd47be0e5c1f968a5b8e34e8dd7c9e1e | CrownPynnRecoveryTest220/0, R/pynn-development-build/ReviewEvidence/pynn-second-gui.log; desktop/touch8각, packed18 | 2계승×3모드×manual4, actualauto3모드(off)별도. Echo후기 은신타깃변경은 R/echo-pynn-frozen.log220/0에서확인 |
| 완료: royal_no_second_cut 실제접근/주·보조타격/복귀·사용·부채·DEF | 8b15d27211dfcd18cb56444bc00c6b06f817e6ac; 자동보완80335024f813bf0b5052251714185d000fa76932 | CrownGobRecoveryTest112/0, R/gob-development-build/ReviewEvidence/gob-final-gui.log; native컷씬13/CD0재사용6. CrownGobAutomaticBoundaryTest24/0, R/gob-auto-tooltip-boundary.log | 후기 nativechannel/표적변경은 echo-gob-frozen.log112/0. 803실제manual/auto always 동일;24에는툴팁6포함 |
| 완료: echo_alarm 8초공개·실제채널지연 일반2/boss.7·실제소비기여 | bdf886a6def2067ea96844cc3450c4ad96e07744 | EchoObjectiveRecoveryTest190/0, R/echo-final-runtime-gui2.log; desktop/touch9각, 수정PCKtouch5/0 | manual4/actualauto off·기존일반/왕관억제fixture·Skip/정보창복원. 이후 소비지연숙련기록1줄. 초기PCK+하네스실패를통합29PASS로표시0 |

공통모드는 `UISettings.should_show(policy,key)`와 `SkillActionPresentation.request/_commit/skip`의 동일Callable/committed guard를 사용한다. manual/AI는같은 `skill:<id>` 준비packet→같은commit을쓴다. R/echo-action-lifecycle.log34/0(실제자동frame 메뉴/스토리/백로그·무효·중복Skip·설정), echo-action-duo-gui.log70/0도기존검증. **automatic×4표시정책 전체 Cartesian matrix는 NOT_RUN**, 자동전용policy게임플레이분기없음/공통경계동일하여 필수누락으로판정하지 않는다. 전체조합을실행했다는주장0.

추가공통요구: royal_jelly_bastion의 두계승실제중앙DEF3/안전구조44는mobility202/packed18, crown_room_embrace의40%HP/15%방호는Basic253, spore_sacrament실초과치유50%/35%cap/TTL5·흡수는Mori119/packed15, moving_forge 실제시설HP손실cap1–6은facility120, messenger_bag 실제손실보류/도착환급은Echo190으로확인. livebody현재외형·왕관억제/복구는d9de8a78333b1c28001ca5e903ba1e65fbb551e3의 R/livebody-development-build/ReviewEvidence/livebody-finalui.log1051/0·desktop/touch8각·packed15. 실제상층/heart자연파괴·자연왕관획득 증거아님.

## 4. 성장·배치·저장·불러오기·종료

| 요구사항/판정 | 제품 SHA·검사 | 근거·한계 |
|---|---|---|
| 완료: 정상지원숙련/보유편성/다음회차 | efc7aa12e58f5064016edd0ba67dc2f7c94ca8d9, earned-new-boundaries9/0·earned-save-targeted10/0·ownedUI4/0·continuity89·packed8 | R/earned-development-build/ReviewEvidence. actual기여producer·정상계약/reserve/빈편성가드. 강제fixture를자연DAY1–30해금으로표시0 |
| 완료: 푸딩두승급역할·성장표시/실제지원기여·다음선택 | d7f662b845399f4946bc3f7d0d4e7dc69864f8b4, baseline9/0·clockdesktop/touch8각·existingSave7/0·packed15/0 | R/growth-development-build/ReviewEvidence의growth-*.log. 자기vs부상동료방패·목표경로·heal/absorb/protection/duo/actualredirectHP비용. 실제자연두번째전투·사람재미아님 |
| 완료: 현재1F툴팁KO/EN/ZH | 8033502, Gob자동24의툴팁6항목 | night_relay/royal_emergency_plating 현재실제1F 계약과일치. 생산효과변경0 |
| 완료: 초반전열/후열 선택전·후피드백/현재카드 | runtime9138368aa837c585143fd5e8b4edf5a923fef339→최종2df동일, FinalPatchBoundaryTest.placement_ui | F/ReviewEvidence-remaining/final-boundary-results.json의evidence.placement; 실제NewGame/card/map room·zone·선택완료·카드일치. 전체실행FAIL44/20은유지, 해당성공경계만재사용 |
| 완료: 시설결산 기존측정값·0/누락/알림동시표시 | 동일runtime9138368→2df; recorded병영17/회복0·3locale 화면 | F/ReviewEvidence-final 및remaining PNG/JSON. watch0/탈취11은표시용합성. Label이름조회오류FAIL은targetregistry/픽셀로확인. 시설계산counter를실제총HP피해/승리인과로승격0, 함정새계측0 |
| 완료: 첫정상승리저장·별도Continue | b1a9e502cafc8a18d6161c4757fec9bdc1ebf96f, FirstVictorySaveBoundaryTest15/7/12 | task-2/evidence/fresh-save-p1/{fresh,restart,legacy}-final.log. LEGACY의Council자료삽입수정. earnedprofile보존기존legacy경계. 반복0 |
| 완료: 정상Quit→별도Continue | b1a9e50의부모실제Linux nativeCUA | task-2/evidence/fresh-save-p1/parent-native-cua-followup.json; 정상첫승리자동저장/정상Quit/새프로세스Continue/메뉴Save, 자원EXP/bond동일·보상중복0. 최신Windows새자연Quit로표시0 |
| 완료: 정상14종 통제DAY30 v1~v5/Continue | runtime9138368→2df동일; 이미쓴필드의의미비교14종/불일치0 | F/recorded-day30-field-comparison.json, ReviewEvidence-remaining JSON. 실제로컬DAY2복사본+실제15/20/27진화전제로구성한통제fixture. **사용자실제DAY30복구아님** |
| 완료: 저장실패 취소/재실패/명시무저장Quit | runtime9138368, FINAL_PATCH_BOUNDARY13/0·exit0; 최종2df rollbacknotice4 | F/quit-boundary-console.log, ReviewEvidence-quit/final-boundary-results.json, final-notice-locale-results.json. primary5bytes/roster보존; 실제productionpressed callback이며OS마우스아님 |
| 완료(이번추가): 실패원인제거→동일창Retry성공→정상Quit→새checkpointContinue | **최종2df 실제추가1경계**, N/retry-recover-recorded.json 및 retry-validate-restart.json PASS/errors0·exit0 | unknown sentinel로실패창준비→원인제거→현재Retry의productioncallback. 실제gold1475→1492(+17), roster동일/5저장valid, 별도Continue자원동일/KokoEXP13bond44. 원래recover후처리inspect인자오류는INVALID보존; 성공Save/Quit를반복하지않고이미작성된출력검증+새checkpointContinue만수행. Headless자동이며자연/OS입력아님 |
| 완료: 독립Windows패키징 | 제품2df, WindowsEXE/PCK/launcher/고지. 새EXE1920×1080 Main부팅·exit0 | task/standalone-review/standalone-boot.json; 전체PCK3421·기존fullbyte동일. **타이틀부팅PASS를전체최종QA로표시0** |

## 5. 변경 영향과 재사용 근거

- 8033502→2df에서스킬정의·효과runtime·CombatSceneController·Unit·HUD·SkillActionPresentation·UISettings 변경0. combat관련유일diff는NativeObjectiveRuntime.before_result의nonCouncil결산직렬화guard3줄(b1a9e50), firstsave/legacy로검증.
- 원래스킬SHA부터803까지livebody/표적/nativechannel/숙련계측변경은해당후기검사를재사용: echo-basic-frozen253, echo-pynn-frozen220, echo-gob-frozen112, echo-livebody1051 및earned9/10/4/packed8. 원래runtime이바이트그대로라고표시하지않음.
- 성장runtime는d7→2df blob `570a4f9b7aa08a5d49da960e3a3a838b6b098c4b`동일. 성장pane/next_choice동일. ResultWorkspace의facilityblock22–31만추가되어해당화면근거확인.
- runtime9138368 이후생산코드는동일;2df는기존rollbacknotice두줄EN/ZH만. F/final-runtime-impact.json에서최종overlay와Quit13runtime의code12리소스동일, 달라진리소스는ui_en/ui_zh_cn/uidcache뿐. notice4최종번역확인.
- 제품2df→문서6431ed1은handoff2파일만. 이번작업도제품/자산/데이터수정0, source/tools추가0(진단script는workspace만).
- 초기종합harness INVALID/FAIL10/6/FAIL44/20/이번후처리인자오류모두보존. assertion합산/fullcatalogPASS/literal single-processPASS0.

## 6. 저장 호환성과 출시 필수 위험

`N/save-compatibility-source-impact.json`: 역사1.2.11검수후보2786be4dff4fea5d21797f33311042e096f781c6와비교해 project.godot(고정customuserdata경로), release_config(6파일Cloud계약), SaveStorev1–v5, v2→v3/v3→v4/v4→v5migrators 모두blob동일. v1→v2만등록5종canonicalmap추가. 새schema/version/slot/Cloud설정변경0. 현재공개실제SHA/Build과비교완료라는뜻은아니다.

기존upgrade/localCloud26·합성이전1.2.10compat11은V1211_VERSION_REVIEW의과거대상/범위로만재사용. 실제개인698원본은이번추가경계후도read/hash698→698 mismatch0(standalone-review/personal-preservation-standalone.json); 원본inspect/쓰기0. 실제DAY30원본·실행SHA미수신. coherent v1–v5를먼저묶음backup하고버전이섞이지않게해야한다. 구실행파일로내리면이미수정한Council/누락매핑저장실패가다시발생할수있으므로**downgrade무위험/실제Steamrollback검증완료주장0**. 실제현재공개default를확인한후그정확한기준과compatibility/risk를다시판정하는릴리스gate가남아있다.

## 7. 완료·미검증·차단

- **완료:** 승인8효과·공통컷씬/모드·승급역할/기여·초반안내·시설표시·저장/Continue/정상및실패Quit의표적증거대조, 새Retry성공경계보완, 개인698보존. 최종제품코드영향의추가필수검사누락은찾지못함.
- **미검증:** 자동×모든표시조합전수(공유경로충분판정), 자연왕관해금/전체DAY1–30/자연두번째전투/사람재미·밸런스/실제상층, 사용자실제DAY30, Steam설치판검증·2PCCloud·offline/conflict·실제downgrade. 전체QA로승격0.
- **차단:** 현재Steamdefault BuildID/제품version 직접조회, 높은새patchSemVer확정, releasecandidate고정/업로드/default공개/패치노트게시. Cua초기화실패 `node_repl kernel exited unexpectedly`; diagnostics `MXC launcher: cannot locate required Windows platform directory: HRESULT 0x80070003`. SDK/SteamCMD PATH/표준위치/문서runtime없음; Steam라이브러리2곳 appmanifest5267750없음; 기존Chrome/Edge프로세스20, 재사용remote-debugging-port없음. 인증비밀읽기/출력/새로그인/OTP요청0.
- 공식SteamNews GET은HTTP200/app5267750/latest1item **1.2.10 Post-Launch Hotfixes**(gid1846018067930533, date1791478396)확인. [공식공개뉴스](https://steamstore-a.akamaihd.net/news/externalpost/steam_community_announcements/1846018067930533); N/steam-public-news.json. 이는currentdefault BuildID/version증명이아님. 역사Build25808943/Manifest7359545829337152740도현재로간주0.
- 업로드/default/패치노트상태 **NOT_RUN/BLOCKED**, 새SteamBuildID/공개패치URL없음. Valve공식절차상default는SteamworksAppAdmin에서설정해야하며기존UploadSteamBuild.ps1도SetLive default를거절. [공식SteamPipe지침](https://partner.steamgames.com/doc/sdk/uploading).
- **Library 중단:** exposed `mcp__codex_apps__library_prepare_uploads`, helper connector_openai_library `prepare_uploads`. 이전오류정확히 `Library prepare_uploads is not available`; hostedtools/list에서실패하여prepare tools/call전, 전송/finalize0/새fileID0. 우회/분할/재시도0. 최신사용자지시뒤Library호출0.

## 8. 준비한 패치노트 초안과 다음 작업

아래는**미게시초안**이며제목의버전/BuildID는포털확인뒤확정한다. 검증한기능만적었고실제자연밸런스/Cloud완료를약속하지않는다. 부모가접근가능한기존Steamworks인증환경을확보하면이번승인그대로진행한다: canonicalBuildsdefault와서버version검증→그보다높은SemVer→version/notes영향만검수→공식SteamPipe/WebUpload→서버파일hash/설치후관련경계→정확한BuildID defaultSetLive→재조회livehistory→SmallUpdate/PatchNotes공개→실제URL확인. Cloud설정변경0, 불필요한원격소스업로드/pushmerge0.

### 한국어 게시 초안 (버전·BuildID 확인 대기)

스킬 동작과 성장 피드백, 저장·종료 흐름을 개선했습니다.

- 실키의 문턱 설치, 포포의 방간 보행 지원·메아리 경보와 왕관 긴급전령, 모리의 왕관 정화·재생·보호, 톡톡의 실제 시설 수리·방호, 핀의 삼색 모드와 실제 마나 비용, 곱의 연쇄 타격·복귀를 연결했습니다. 현재 외형 컷씬과 수동/자동 경로에 같은 효과를 적용합니다. 설명은 현재1층 실행 범위에 맞췄습니다.
- 승급 역할, 실제 회복·흡수·보호 등 지원 결과와 다음 회차 선택을 표시합니다. 첫 배치의 전열/후열 합류 위치와 선택 완료 안내를 명료하게 했습니다.
- 결산에는 기존 시설 기록의 추가 피해·방호·회복과 알림을 함께 표시합니다.
- 첫 승리 저장에 의회 전용 정보가 섞이던 오류와 코코 등 등록 몬스터의 저장 변환 누락을 수정했습니다. 저장 실패 시 취소·다시 저장하고 종료·저장 없이 종료를 명시적으로 선택할 수 있습니다. 관련 안내를 한국어·영어·간체 중국어로 보완했습니다.

검증 범위는 위 변경의 표적 검사입니다. 특정 사용자DAY30 저장 복구와 실제 두PC SteamCloud 동기화는 확인하지 못했습니다. Cloud 설정은 변경하지 않았습니다. 이전 실행 파일로 내릴 때는 서로 맞는5개 캠페인 저장을 함께 보존하세요.

### English draft

This patch connects the remaining skill effects and improves progression feedback, opening placement guidance, and save/quit controls. Physical threshold traps, room-to-room support and alarm/courier actions, royal cleansing/regeneration/protection, facility repair, tricolor modes with actual mana costs, and Gob's contact chain/return now use their production action paths and current-form cutscenes. Tooltips describe the current first-floor scope. Results show recorded support and facility contributions. First-victory Council-data contamination and missing registered-monster save mappings are fixed. Save failures offer cancel, retry-and-quit, or explicit quit without saving, with Korean/English/Simplified-Chinese guidance.

Verification covers these affected boundaries. The particular user's DAY30 save recovery and real two-PC SteamCloud synchronization are unverified. Cloud settings are unchanged; preserve a coherent five-file campaign backup before downgrading. Version/BuildID/title are pending actual Steam default verification; this text is not published.

### 简体中文草稿

本次补丁连接剩余技能的实际效果，并改善成长反馈、开局布阵提示和存档/退出流程。技能使用实际门槛陷阱、跨房间支援、警报与信使移动、王冠净化/再生/保护、设施修复、三色模式及实际魔力费用、连续命中与返回等路径，并显示当前形态的演出。说明与当前一层范围一致。结算显示已有的支援与设施记录。修复首胜存档混入议会专用数据及已注册怪物转换遗漏；保存失败时可取消、重试保存并退出或明确选择不保存退出。

验证仅覆盖上述变更。尚未确认特定用户的DAY30存档恢复或真实两台电脑的SteamCloud同步。Cloud设置未改动；降级前请保留一致的五个战役存档。版本和BuildID需核对当前公开默认版本后确定，本草稿未发布。

## 9. 작업 트리와 증거

이번 생산 파일/그래픽/오디오/데이터 변경0. 본 핸드오프와 CURRENT만 Git에 기록하며 진단script/JSON/로그는N에 둔다. 제품2df를 유지하고 문서 두 경로만 명시staging/로컬commit한다. pushmerge/태그/Release0. read-only agents `/root/final_review_plan`, `/root/deployment_copy_audit`, `/root/steam_release_route`는 각각8스킬, 성장·저장, 출시경로를 조사했으며 새 전체QA를 실행하지 않았다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 2dfbaeea2e28b4d8d04631689eee24c9ef7b0800
- Review range: 05a126169096ae35c7579e876a1a891f97e1a40f..2dfbaeea2e28b4d8d04631689eee24c9ef7b0800
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

위 필드는 해당 표적 변경 경계에만 유효하다. 전체catalog/전체campaign은NOT_RUN, Steam 공개출시는BLOCKED다.

## 10. 종료 체크리스트

- [x] 요구사항/원래SHA/실제영향범위 대조, 변경없는통과검사반복0
- [x] 새Retry성공 필수경계 보완, 후처리harness오류 원본보존
- [x] EXE부팅과전체QA구분, 실제사용자DAY30/Steam2PCCloud미검증 유지
- [x] 개인698보존, Cloud설정/인증비밀 변경0
- [x] Library중단, 정확한오류 및쓰기전실패 기록
- [ ] 현재공개default버전/높은새patchSemVer 확정 (포털제어환경차단)
- [ ] Steam업로드/공개default/패치노트URL 확인 (미실행/완료주장0)
