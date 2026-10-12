# 남은 스킬 결정 자료 및 DAY2 선택 수정

## 1. 기준·요청

- 2026-10-12 UTC, 제품 Who Guards the Demon Castle / bluehige/mawangseong-demo / Steam5267750.
- 목표 버전1.2.11 비공개 검토. 작업 브랜치 codex/day2-room-selection, 분리 작업본 task-2/mawangseong-action.
- 기준5a30d774c189d86149ea700e10abaac5d3325d14, 새 제품979adcd44be41cc3583ff28a9ed597bafb4d94ba.
- 이전 스킬 제품aab19e40edc77b5b9baa52e47cdd360232e578a4와 이전 검토 빌드·바로가기 보존. 새 제품은 GameRoot 입력·안내 좌표 및 관련 테스트만 변경한다.
- 로컬 main ref 없음; origin/main0ac9fdc7는 과거 관측이며 현재 원격 최신성 미확정. 원격/Steam 설정/공개 배포/외부 홍보 없음.
- 요청: 남은8·젤 계승·왕관의 정확한 상태와 이번 완성/DLC 판단을 밸런스 근거로 제공. 미정8 효과를 전부 구현하거나 수치를 창작하는 승인이 아님. DAY2 반복 입력 문제는 원인에 따른 최소 수정/회귀. 성장 새 행동은 아직 개발하지 않는다.

## 2. 결론과 권고 — 효과 구현 완료와 구분

**기본 실키·포포 기술은 왕관 없이 쓰는 기존 역할이다.** 실키/포포는 첫 설치 DAY1이 아니라 전선30일 완주/ending 기록 뒤 다음 의회 회차 선택 시 DAY1에 Lv1로 합류한다. 그 합류 경로는 코드에 있으나 자연 전선 완주→의회 영입 전체 플레이는 NOT_RUN.

8개를 묶어서 DLC로 넘기기보다는 기존 기본 역할 복구를 이번 유지보수 후보로 하고, 실제 다층·새 은신/인장 목표 전투 콘텐츠를 확장 후보로 분리할 것을 권한다. 아래 판정은 설계/현 역할 기반의 제안이다. 미구현 기술의 완성 강도나 DLC 판매 정당성을 실제 승률로 증명한 것은 아니다.

| 스킬 / ID | 권고 | 기존 근거·결정해야 할 점 |
|---|---|---|
| 계단 꿰매기 / stitch_stairway | **이번 패치 복구 우선** | 문턱 fallback, mana12/CD11, 첫 고유4적 ×.65/4초·화염2회. 실제 anchor·통과/중복방지·화염 사건 hook 필요. 새 감속 반경으로 바꾸지 않음 |
| 밤길 중계 / night_relay | **이번 패치 단층 복구 우선** | 먼 위험방 fallback, mana10/CD8, 두 유닛5초 이동×1.15/공격간격×.90. 실제 이동·도착 확인·독립 버프 수명 필요 |
| 메아리 경보 / echo_alarm | **근거 부족 보류** | mana12/CD12, 노출8초·채널지연2초/보스.7초. 실제 은신/급습/인장절도·상호작용 채널 없음. 임의 도발/감속은 대체 아님. 새 적 콘텐츠만 확장 후보 |
| 두 번 베지 않는 명령 / royal_no_second_cut | **계약 결정 전 보류, 이후 기존 왕관 복구** | mana0/CD0/전투2회, 표식·인접 지원 순차공격·원방복귀·DEF×.85/4초. 공격 커널/인접 기준/표식 및 절도 중단을 확정해야 함 |
| 삼색 마왕화 / tricolor_demonfire | **근거 부족 보류, 기존2모드 부분 복구 후보** | 전투2회, 직격/장판 계약 일부 있음. 잿불 저주 강도/시간·모드UI 필요. 2회 제한과 history>=3 할인 충돌: 기본 화염 기술도 이력에 넣는지/저장하는지 등을 결정. 횟수 임의 변경 안 함 |
| 모두 같은 우산 아래 / royal_shared_umbrella | **해금·효과 정의 전 보류** | 전투1회·정화/재생5초/치명 피해1명 HP1보호/이후회복×.85 6초. 재생량·치명 guard 수명/소모순서 없음, 실제 floor와 mastery producer 없음 |
| 왕성 긴급 판금 / royal_emergency_plating | **방호 정의 전 보류, 시설 부분 복구 후보** | 전투1회·maxHP30%수리/8초방호/이동×.75 5초. 방호 강도/성격 없음, mastery producer·왕관실 실제 피해·인장금고HP 없음 |
| 왕관 긴급전령 / royal_urgent_courier | **실제 다층 기반은 DLC 후보; 현재 왕관 노출·해금은 별도 보류** | 전투2회/층간.20초/6초이동×1.20·공격간격×.85·저항+.20. 실제 층/전이AI/저항 계약/mastery 없음. 단층 밤길 이름 바꿔 대체하면 역할 유실 |

정확한 특화/왕관 계승 수치·다른 캐릭터 대체·합동/승급 상호작용·구현 상대비용·저장·노출/발표 근거는 [전체8개 결정 감사표](REMAINING_SKILL_DECISION_AUDIT_2026-10-12.md)에 있다. 실제 전투에서 미정8 효과를 구현하거나 가상 효과를 주입하지 않았다.

## 3. 왕관 질문의 완결과 새 해금 막힘

왕관 전체가 없는 것도, 액티브만 미완인 것도 아니다. DAY23 평의회 후보/비용2·한 회차1종·저장·해당 캐릭터 자동 외형/기본 HP/ATK/DEF/이동 배율 적용이 있다. 별도 장비 슬롯 장착 조작이 아니라 선택한 form 자동 적용이다. 일반 DAY12 첫 승급과 왕관 DAY23 선택은 다르다. DAY23 전 전체 일반 승급 선택1명 제한, 그 뒤 제한 해제와 개인 이미승급 차단을 ‘모두 두 단계 승급’으로 설명하면 부정확하다.

푸딩·곱·핀은 Lv6/유대80/특화/첫승급/의회인장2 또는 대체2가 조건이다. 모리·톡톡·포포는 공통 조건과 종 숙련2가 조건인데 정상 profile의 숙련 생산 코드가 없다(없으면0). 해당3왕관 자연 해금은 현재 코드상 BLOCKED이며 gate삭제/숙련+2 주입으로 몰래 해결하지 않았다. 모리·톡톡 의회 roster취득도 자연 확인이 필요하다.

왕관 푸딩 액티브 기본만 현재 연결. 다른5액티브·패시브6·일부 healing/max_mana/status_resistance 사전 배율의 Unit 소비·실제 왕관실 파괴→억제·왕관3장면 이벤트 UX는 별도 미완/미검증이다. 억제 상태 검사는 있으나 목표 실전 피해 producer가 없고, seen 기록만으로 사용자 장면 시청을 증명할 수 없다.

젤 성문 계승은 강화량/고정 규칙 부족으로 보류. 젤 구조 계승은 기존 안전 이동 커널로 복구 후보지만 ‘푸딩 뒤’ 위치/동률/벽·방/이동 잠금 규칙을 명시해야 한다. 두 계승 모두 여전히 미지원이다.

공개 노출 근거: 공개 후보로 지목된 로컬2786be4 소스에 의회 합류/왕관 데이터가 있음. 공식 Steam 상점 본문은30일·성장·역할 등을 말하지만8개 개별 기술이나2층/DLC 약속을 확인하지 못했다. 현재 Steamworks default BuildID와 실제 설치 바이너리는 NOT_RUN. 의도적 유료DLC 보류의 승인 이력을 읽은 문서/이력에서 찾지 못했으며 절대 없다고 단정하지 않는다.

## 4. 제한 실제 밸런스 비교

기준은 불변aab19e4 PCK(SHA2569CC1499464EE0EC889E881542715F1843414500BBAC240A3A82B43E7DCEA1205), **새979adcd 빌드 결과와 별개**다. 실제GPU Godot4.6.3/RTX3060Ti. 8전투/비교동일성40/40 PASS. 각 그룹 실제 적 스케줄/스탯·시설·초기 배치 slot·3명 같음, 시드20261012. 훈련구매0/동일 지정레벨이다. 레벨을 실제 같은EXP로 키운 것도, 영입·승급·왕관 비용까지 맞춘 것도 아니다. DAY30은 자연30일 성이 아니라 고정 첫방어 성과 실제DAY30 적을 사용했다.

| 그룹 | 기본3 | 곱자리→실키 | 곱자리→포포 |
|---|---|---|---|
| DAY1/Lv1, 시간·남은HP | 24.35초·403/440 | 20.55초·397/428 | 17.25초·353/410 |
| DAY30/Lv6, 시간·남은HP | 62.65초·625/814 | 63.15초·656/802 | 63.00초·626/784 |

8개 모두 승리·3명 생존·왕좌1500·보물손실0. 일반3구성의DAY30시간 차이≤.5초. 구조/왕관방호 발동0으로 지원 효과 강약은 NOT_MEASURED. 피해량은 실제 적HP감소, damage_absorbed는HP손실+막은압박 혼합이므로 시전자 보호량이라고 쓰지 않는다. 시설회복0, 스킬 실효회복/출처별 보호는 NOT_MEASURED.

왕관2비교는 강제 상태 fixture이다. 실제후보 검사에서 푸딩은 specialization/seal_cost, 포포는 추가mastery도 막힌다. 별도 조건채운 데이터 fixture candidate/confirm PASS(인장2 차감)는 합법 자연 왕관 전투 성공이 아니다. 단일맵/시드·역할별 다른 기초 kit이므로 전반적 동등/우수/유료화 판정 근거로 과장하지 않는다. 초기 roster순서가 달랐던pilot과 약한DAY23실험은 보존·제외했다. [제한 전투 상세](LIMITED_ROLE_BALANCE_PROBE_2026-10-12.md) 참조.

## 5. DAY2 원인·제품 수정

기존6618 자기 자연 DAY2 체크포인트/같은1920 논리 viewport에서 Viewport 클릭을 진단했다. update확인 후 modal=false/pause=false/input_enabled=true/실제방spike였음. 중앙은 _management_monster_at=slime이라 _start_management_monster_drag가 먼저 처리하고 짧은 release는 원래배치방entrance선택만 한다. room_selected가 발생하지 않아TUT110유지. 빈 방 위치는 즉시TUT120진행. 직접 _input진단도 같은 차이였다. 잘못된 raw강조 중심 클릭은 다른 path_a_entry_front에 해당했고, 화면강조 world→canvas변환이 빠져 있었다.

최소17추가2삭제(GameRoot): 관리 필수room_selected 단계·목표방·다른배치/build/mapeditor모드없음에만 방 선택을 드래그보다 우선. 관리 튜토리얼 방 rect에 canvas변환. 실제 worldmarker그리기는 그대로. 일반 드래그·다른방 선택·전투입력/스킬수치 변경 없음.

실제 GUI 회귀는 naturally reached자기DAY2 체크포인트로 실행했다. 최초 직접 구성 fixture는 배치/완료단계가 부정확했고14실패, 실제fixture로수정 뒤DAY3 stage오타1실패, 정확한stage로 최종61/0. 실패로그를 보존했고 제품버그로 잘못 세지 않았다. 네이티브 PopupMenu 입력을 root/별도Viewport/Window신호로 보내는 테스트는 선택 전달이 안 됐다. 실제 팝업항목을 열어 확인하고 production id_pressed callback으로 trap_lure를 선택했더니TUT120→130진행. **방선택은실제ViewportGUI,함정선택은메뉴콜백,사람/네이티브팝업입력NOT_RUN**이다. 이 구분을 지우지 않는다. fullDAY2battle완료도 NOT_RUN.

## 6. 수정·검증·자산

| 파일 | 변경 |
|---|---|
| scripts/game/GameRoot.gd | occupied required room selection/management focus transform |
| tools/tests/Day2RoomSelectionTest.gd/.uid/.tscn | 자기DAY2 fixture요구, 실제GUI pan/zoom/Full-Core-Off/menu/title-restore/일반drag/DAY3recovery61checks |

| 검사 | 결과 | 근거(task-2/evidence) |
|---|---|---|
| Day2RoomSelection 실제GUI | PASS61/0 | day2-room-selection-gui-final.log |
| 안내설정 | PASS | day2-V122TutorialGuidanceLevelTest.log |
| 튜토리얼 연습 | PASS22 | day2-V122TutorialPracticeTest.log |
| 저장·실패·취소·타이틀·백로그 | PASS89/0; 의도적실패주입진단포함 | day2-PlayerContinuityTest.log |
| editor/source | PASSexit0 | day2-editor-final.log |
| 새979adcdexport | PASSexit0 | day2-export-final.log |
| 새 실제PCK 스킬유지 | PASS14/0 | day2-packed-skills-smoke.log |
| 새 실제PCK 방선택/함정콜백 | 110→120/120→130,exit0 | day2-packed-progression.log; first-defense-review-6618c09/day2-packed-final/probe.json |
| 새 실제EXE격리180frame | PASSexit0 | day2-progression/development-build/development-manifest.json |
| 개인698+backup698/기존5산출물 | 해시 보존검사 | skill-action-preservation-final.json |
| 제한balance8/비교조건40 | PASS,8효과강도NOT_MEASURED | runtime-connection/balance-role-probe-summary.json |

새이미지/음악/외부SDK 없음. 실제 PCK 수정 전/후·방선택후 캡처와 별도balance3GPU캡처. 작성자는 새 실제 강조전/후 대표를 직접 열어 확인; 모든이미지 전수육안PASS 아님. 기존aab독립검수는그범위에서만유효, 새DAY2은직접표적검수이며새전체검수/검수에이전트를수행했다고주장하지않는다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 979adcd44be41cc3583ff28a9ed597bafb4d94ba
- Review range: 5a30d774c189d86149ea700e10abaac5d3325d14..979adcd44be41cc3583ff28a9ed597bafb4d94ba
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 출시·후속 결정·성장 계획

확인된 클릭 우선순위/강조 문제는 수정했다. 네이티브 사람 입력·전체DAY2진행·자연왕관해금·mastery생산부재·현재미지원노출·실제Steam/twoPC는별도게이트다. 자동8승을 출시·사람재도전의향PASS로세지않는다. 홍보일정때문에게이트를생략하지않되기술8확장을끝없이이패치에끼워넣지도않는다.

부모가 결정할 구체안: 기본문턱/단층중계이번복구우선, 메아리필수전투기반을이번에만들지명시보류할지, 기존왕관5/젤계승의누락계약·숙련도성장규칙·부분노출정책. DLC는새다층/새전투목표콘텐츠후보로분리한다. 이번에미정수치·전투당횟수·해금조건은바꾸지않았다.

승인된 성장 초안은 기존 [GROWTH_APPEAL_NEXT_PLAN](GROWTH_APPEAL_NEXT_PLAN_2026-10-12.md): 푸딩DAY12 두분기(entry_anchor길목/ally_guard부상아군)와푸딩+모리합동하나→실제회복/출처가있는보호발동·합동커밋기여→다음회차기존승급/조합/알려진엔딩선택한개. 해금/공격력일괄변경·새보상화폐·반복숙제·새엔딩없음. **이8개처리방침과진행게이트가정리된뒤성장구현**으로순서를조정하며이번턴성장코드는없다.

## 8. 복구·전달·보존

새제품979adcd+문서후속commit, 새개발패키지task-2/evidence/day2-progression/development-build. 바탕화면 새 마왕성_DAY2선택_검토_979adcd만추가, 개인/기존실행/이전shortcut보존. 런처만사용하면 APPDATA는패키지prototype_userdata. 이전skillruntimeaab14/126/1030검사는기존제품범위이고 새PCK14로연결유지확인.

새EXESHA256 DD562A07855D0CCED116F58E1E727250F45A0D3BF0822B96A17635240DB09845, 새PCKSHA256 F5681C061D4D62CA9C7760124BCE7D48BCAAF5874577931FDDE5D70F07BBA57F. 이전aab19e4EXE/PCK/런처3파일은원manifest해시와현재해시일치도추가확인했다. 개인698+백업698 불일치0, 기존5산출물해시보존/17원캡처유지. 같은자료를새검증으로중복승격하지않는다.

허브기존mawangseong/session cutscene-policy-decision-20261012에결정자료·신규진행수정·미완료·다음순서체크포인트. siblingbaseline562f0d1/권한/기존automation그대로. 중앙기준/evidenceID승격은부모담당, 효율·시간·토큰측정null/NOT_MEASURED. 공개Steam/원격Git/외부홍보없음.
