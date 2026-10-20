# U3 이미지 생성 출처

Generation model: GPT internal image generation
Generated date: 2026-10-14
Target version: v1213 UI/UX U3 작업 흐름 (제품 SemVer 변경 없음)
Runtime image path: N/A — 검토용 문서 시안이며 런타임 자산으로 연결하지 않음

## 방식·보존 범위

- 사용 도구: GPT 내부 `image_gen.imagegen`. 외부 유료 API·CLI·외부 생성 서비스를 사용하지 않았다.
- 대상: 한국어 스타일 B 화면 12종. 각 파일은 별도 생성 호출로 만들고, 아래 보정 호출도 같은 내부 생성기를 사용했다.
- 입력 역할: B kit는 색·패널·버튼 스타일 참고이며 kit의 예시 수치·기능은 제품 정보로 취급하지 않았다. 타이틀 v3·대화 v4는 구도와 참여자 참고, 실제 초상은 외형 참고, 실제 게임 캡처는 정보·상태 참고다.
- 사용자 지정 `tmp/v1213_uiux_audit/`가 현재 작업본에 없어 `docs/design/v1213_uiux/audit/`의 보존된 실제 JPG를 사용했다.
- 내부 생성기는 원본을 Codex 기본 생성 디렉터리에 저장한다. 아래 원본 경로를 기록하고 최종 납품본은 허용된 `docs/design/v1213_uiux/u3/`에만 저장했다. 참고 파일·코드·기존 문서는 수정하지 않았다. git 명령은 사용하지 않았다.
- 후처리: 최종 원본 약1671~1672×941을 PowerShell의 System.Drawing 고품질 Bicubic 보간으로 **1920×1080 PNG**로 내보냈다. 원본과 최종본은 구분한다. 로컬 후처리는 해상도·PNG 인코딩 정규화만 수행했으며 UI 문구·그림·기능 수정은 아래 내부 생성 보정 호출로 수행했다. 출력은 전체 화면이므로 투명 배경은 요청하지 않았다(`transparent_background=false`).
- 원본의 세로 가로 비율과 정확한16:9 사이 차이는 약0.05~0.11%다. 1920×1080은 내보내기 해상도이며 내부 생성기가 네이티브1920×1080을 반환했다고 주장하지 않는다.
- 최종 선택본의 디코딩·크기·파일 링크 검증은 README.md와 작업 보고에 남긴다. 게임 실행·회귀 검수·사용자 시안 승인은 이 산출물 작업에 포함하지 않았다.

## 구조·실제 수치 근거

- [확정 사항 §4](../UIUX_OVERHAUL_PLAN_2026-10-14.md#4-사용자-결정-2026-10-14-확정)
- [IA 문서](../UIUX_IA_FLOW_2026-10-14.md): §1 화면 틀·도감·설정, §2 화면별 목적·우선순위, §3 건설/배치/강화/지침, §4 훈련/전직/합동기/결과, §5 자동 재생, §7 전투 HUD.
- [GameRoot.gd](../../../../scripts/game/GameRoot.gd): `_facility_base_definition`, `_facility_upgrade_cost`, `_facility_upgrade_block_reason`, `_upgrade_selected_facility`, `_monster_exp_to_next`, `_promotion_block_reason`, `_contract_roster_available`, `_build_tutorial_history_setting_row`, `_continue_from_result`. 읽기 전용 확인.
- [종족 기본 능력치](../../../../data/monsters.json), [실제 동료 이름](../../../../data/monster_instances.json), [기본 방 정원](../../../../data/rooms.json)
- [전직 후보·조건·효과](../../../../data/evolution_rules.json), [훈련·강화 날짜](../../../../data/campaign_days.json)
- [합동기](../../../../data/regular_version/update3/duo_links.json), [기존 계약 동료 역할](../../../../data/update2_contracts.json)
- [설정의 실제 한국어 문구](../../../../data/localization/v122_stage10_ui.json)

## 개별 생성 기록

아래 최초 프롬프트는 실제 전달 문자열이다. 보정이 있는 파일은 **최초 후보를 최종 채택하지 않고 마지막 보정 결과를 채택**했다. 각 입력의 역할은 프롬프트 안에 명시했다. 확인되지 않은 설치 상한·승급 인원·성과는 임의 값 대신 미정·미확인으로 남겼다.

### 01_title.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-750be600-5bd5-47ed-81f5-fa57b5166028.png
Deliverable image path: docs/design/v1213_uiux/u3/01_title.png

최초 입력 레퍼런스:

- [docs/design/v1213_screens/v1213_title_v3.png](../../../../docs/design/v1213_screens/v1213_title_v3.png)
- [docs/design/v1213_uiux/kit/kit_B_cute_dark.png](../../../../docs/design/v1213_uiux/kit/kit_B_cute_dark.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. Create ONE finished Korean game screen mockup, 1920x1080 exact 16:9 landscape, flat full-bleed screenshot without device or outside frame, for 마왕성 U3 01_title.png.
Input images by order: 1 is the approved title illustration and composition; 2 is ONLY approved style B UI design system. Keep image 1's ensemble, castle throne hall, central title, central menu, cute monster groups at both sides, black-haired horned dark lord seated high on central throne, blue shield slime, green goblins with red scarves, red imps, mushroom lantern mascot, purple ghost maid, skeleton, cute short-bodied charcoal bat mascot with pink ears, red vest, clipboard and quill. Do not replace these with generic characters. Keep title exactly "마왕님, 마왕성은 누가 지켜요?".
Change menu chrome to style B: rounded dark aubergine translucent panels, delicate lilac outlines, small gold edge accents, violet gem details, soft purple active glow, creamy white readable Korean typography. Keep illustrations warmly candle-lit with violet shadows, premium cute dark fantasy. Central vertical buttons with compact icons and exact labels "새 게임", "이어하기", "설정", "도감", "종료". Active 새 게임 is violet, other buttons quiet. Bottom-right globe and three compact buttons exact text "한국어", "English", "简体中文", 한국어 active. Minimal other text; NO resource numbers, invented version, currencies, banner explaining concept, mockup annotations or new features. Render crisp lettering. Single screen at least 1536x864, preferably requested 1920x1080.
```

### 02_dialogue.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-a081b3aa-a61e-4bd3-b7ed-3a96629a2ba2.png
Deliverable image path: docs/design/v1213_uiux/u3/02_dialogue.png

최초 입력 레퍼런스:

- [docs/design/v1213_screens/v1213_dialogue_v4.png](../../../../docs/design/v1213_screens/v1213_dialogue_v4.png)
- [docs/design/v1213_screens/bati_cute_standing_candidate.png](../../../../docs/design/v1213_screens/bati_cute_standing_candidate.png)
- [docs/design/v1213_uiux/kit/kit_B_cute_dark.png](../../../../docs/design/v1213_uiux/kit/kit_B_cute_dark.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Input 1 is exact composition/participants/background and dialogue copy; input 2 is approved Bati identity: adorable short rounded bat body, charcoal fur, HUGE pink ears, violet eyes, tiny fangs, red vest and white cravat, black jacket, clipboard and feather. Input3 style only. Preserve the horned black-haired dark lord on left in black-red coat, keep bat on right brightly emphasized as active speaker; palace background softly dim. Lower ~22% wide dialogue band restyled B with slim lilac top edge and subtle gem corners, not bulky box. Name "바티" and exact dialogue "마왕님, 먼저 동료들을 배치해 주세요." / "오늘의 목표는 이 성을 무너지지 않게 지키는 겁니다." Top-right three small icon buttons book "로그", play "자동 켜짐" lit violet with visible running indicator, double-chevron "넘기기" grey disabled with tiny lock indicating unread skip restriction. Bottom-right small next arrow. No dialogue number, no other copy. Automatic playback visibly ON.
```

### 03_management_build.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-6a40be1a-80e8-43ea-851c-65e468dd948f.png
Deliverable image path: docs/design/v1213_uiux/u3/03_management_build.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/screen_management_B.png](../../../../docs/design/v1213_uiux/kit/screen_management_B.png)
- [docs/design/v1213_uiux/audit/26_build_review_day1.jpg](../../../../docs/design/v1213_uiux/audit/26_build_review_day1.jpg)
- [docs/design/v1213_uiux/kit/kit_B_cute_dark.png](../../../../docs/design/v1213_uiux/kit/kit_B_cute_dark.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Input1 style and wide dungeon emphasis; input2 actual dungeon topology/facility watch tower and factual costs. Render recognizable real connected isometric dungeon: left entrance, central corridors, upper-left throne, upper-right turquoise recovery room, lower-left build slot, lower-right treasure chest room; do NOT invent new castle rooms. Map enlarged occupying dominant screen, never giant black unused rectangle. Ultra-thin top resources from actual DAY1 screenshot only: coin1245, violet mana320, food18/30, infamy620; small settings/save/book icons right. Top-left DAY1, hooded explorer icon ×3, crown HP1500/1500, treasure HP bar WITHOUT a number since undocumented. Do NOT show invented treasure HP. Bottom floating dock exact labels "건설","수비대","전술","몬스터","전투 시작", 건설 active. Compact build card strip just above dock: selected gold-violet actual watchtower icon label "감시 초소", coin100 mana50. Other cards can be icon silhouettes WITHOUT invented costs. Selected card highlights valid build sites teal thin diamonds, unavailable positions dim. Lower-left build slot under white pointer contains a ghosted semi-transparent watchtower showing mouse-placement preview. Nearby small tooltip exact "감시 초소", coin100 mana50, "적 이동 -18% · 받는 피해 +12%", "배치 0/3" which is actual tower garrison capacity, and "클릭·놓기 즉시 설치". Show total installation count label "설치 현재/최대" with no speculative numerical limit. Undo rounded arrow button "되돌리기" at lower-left. No separate confirmation/install button.
```

보정 1 입력: `C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-3421681a-94a4-412b-86b3-35808b9d1c0d.png`

보정 1 프롬프트:

```text
Use case: precise-object-edit. Correct this already-generated game mockup. Change ONLY bottom build-card strip and installation counter. Keep whole dungeon, other chrome, pointer tower preview, tooltip, costs, identities. REPLACE unsupported wall/catapult/spike/banner cards with ONLY these actual facilities and EXACT costs: "감시 초소" coin100 violetmana50 selected; "병영" barracks icon coin100 food2; "보물 보관실" treasure chest icon coin120; "회복 둥지" turquoise pool icon violetmana80. Use these 4 cards only. Replace bottom-left fabricated installation "0/3" with "0/—", label "설치 현재/최대" and small "상한 확인 필요". It is unknown installation maximum, NOT tower garrison3. Keep tooltip "배치 0/3" which IS actual garrison capacity. Do not invent any other number. No full-screen concept title. All Korean text crisp. Exact16:9 requested1920x1080. Output a single complete Korean game screen. Preserve style B and all unmentioned pixels/composition.
```

### 04_management_garrison.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-53d1d72f-0ea8-446a-a47e-0d750da88add.png
Deliverable image path: docs/design/v1213_uiux/u3/04_management_garrison.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/screen_management_B.png](../../../../docs/design/v1213_uiux/kit/screen_management_B.png)
- [docs/design/v1213_uiux/audit/18_day1_roster.jpg](../../../../docs/design/v1213_uiux/audit/18_day1_roster.jpg)
- [assets/sprites/portraits/uiux3d/pudding_base.png](../../../../assets/sprites/portraits/uiux3d/pudding_base.png)
- [assets/sprites/portraits/uiux3d/gob_base.png](../../../../assets/sprites/portraits/uiux3d/gob_base.png)
- [assets/sprites/portraits/uiux3d/pynn_base.png](../../../../assets/sprites/portraits/uiux3d/pynn_base.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
References:1 style B dungeon,2 actual DAY1 map/roster arrangement,3-5 exact Pudding blue shield slime, Gob green red-scarf brown-mohawk goblin, Pynn red horned staff imp. Preserve real dungeon silhouette and linked rooms from input2 while enlarging map. Top thin coin1245 mana320 food18/30 infamy620, DAY1 explorer×3, crown1500/1500, treasure plain HP bar without number. Bottom dock "건설","수비대","전술","몬스터","전투 시작" with 수비대 active. Directly above dock narrow three portrait cards "푸딩 Lv.1" HP180/180, "곱 Lv.1" HP140/140, "핀 Lv.1" HP120/120; each HP thin green bar. 푸딩 fixed entrance, 핀 fixed recovery; show small lock on these cards as DAY1 actual constraints. 곱 card selected; visible pointer drags small semi-transparent exact Gob sprite toward rear room, thin dotted path and bright target outline, tooltip "곱 · 배치 미리보기". On map compact occupancy chips entrance "1/3", central trap corridor "0/2", barracks "0/4", recovery "1/2", treasure "0/2", throne "0/4". Near Gob target ghost show projected chip "0→1/4" distinguishing before-after. Clearly a preview BEFORE drop. Lower-left undo "되돌리기". Map dominates, no roster modal or invented extra units/HP.
```

보정 1 입력: `C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-b55902c9-51dc-4475-8087-166198f5cc62.png`

보정 1 프롬프트:

```text
Use case: precise-object-edit. Correct this already-generated game mockup. Change ONLY map chips, Gob drag target, and duplicate Gob ghost. Preserve chrome and all portraits, HP, resources, dock. The portal/barracks room at upper-left below throne is the BARRACKS: place chip "병영 0/4" there and project dragged Gob ghost/pointer there with tooltip "곱 · 배치 미리보기 0→1/4"; only ONE ghost and one dotted drag line from Gob card. Lower-left unbuilt slot must be "건설 슬롯" with small lock, NO entrance1/3 on that empty wooden platform. Actual entrance is left horned gate: place BLUE PUDDING with shield there, chip "입구 1/3". Rear turquoise room with PIN is "회복 둥지 1/2". Treasure chest room at bottom-right is "보물 보관실 0/2", NOT barracks. Upper-right spiked stone room IS "가시 복도 0/2", NOT treasure; throne at top "왕좌 0/4". All labels small compact, HP same180/180140/140120/120. Gob stays in drag preview not committed. Remove additional misleading yellow humanoid occupancy icons if cramped; use simple person outline. No new room or numeric changes. Output a single complete Korean game screen. Preserve style B and all unmentioned pixels/composition.
```

### 05_management_tactics.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-7df1e9c7-c569-46d9-a1ae-8ed44630f8fc.png
Deliverable image path: docs/design/v1213_uiux/u3/05_management_tactics.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/screen_management_B.png](../../../../docs/design/v1213_uiux/kit/screen_management_B.png)
- [docs/design/v1213_uiux/audit/78_management_tactics_day12.jpg](../../../../docs/design/v1213_uiux/audit/78_management_tactics_day12.jpg)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Reference1 approved chrome only; reference2 actual DAY12 map, route, operating policy. Show enlarged connected real isometric dungeon and watchtower at lower-left. Thin top resources coin5000 mana5000 food24/30 infamy650, DAY12, enemy group icon×6 (known TOTAL only; don't subdivide imaginary enemy counts), crown1500/1500, treasure plain bar without speculative HP. Bottom dock "건설","수비대","전술","몬스터","전투 시작", 전술 active. Above dock a compact horizontal TWO scope policy tool: global icon/castle header "성 전체 · 상시 정책" active chip "사수" and one-line plain explanation exactly "배치한 방을 지키고 저체력 방어막을 복구합니다." Separate small ROOM tool header "이 방 · 지침", selected watchtower chip "함정 유도"; one-line "적을 가시 복도로 유도합니다." Never make global and room rules look like immediate attack commands. Draw coherent turquoise chevron route along REAL corridors from entrance toward trap corridor, repeated directional arrowheads/dashed motion cues to imply animated path in static image; do not promise actual animation. Watchtower faint translucent lavender radius disc over nearby rooms, small eye badge "감시 범위". Keep disc unobtrusive and transparent. No large text paragraphs, modal, attack confirmation or extra button features.
```

보정 1 입력: `C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-86b5c19f-e70e-4469-8023-59c0eb6537bc.png`

보정 1 프롬프트:

```text
Use case: precise-object-edit. Correct this already-generated game mockup. Single precise edit: top-left enemy chip must represent the TOTAL MIXED invasion force, NOT all6 explorers. Replace portrait of lone hooded explorer with neutral enemy-group icon showing small sword+hood+shield cluster and exact count "×6". Keep DAY12, policies, one-line descriptions, watch range, dungeon, map chevron arrows, rest unchanged. No invented breakdown of6 by type. Do not add more units. Output a single complete Korean game screen. Preserve style B and all unmentioned pixels/composition.
```

### 06_room_detail.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-72100fb3-f0fd-4214-8c18-37742f848aba.png
Deliverable image path: docs/design/v1213_uiux/u3/06_room_detail.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/screen_management_B.png](../../../../docs/design/v1213_uiux/kit/screen_management_B.png)
- [docs/design/v1213_uiux/audit/26_build_review_day1.jpg](../../../../docs/design/v1213_uiux/audit/26_build_review_day1.jpg)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Style B management screen, actual DAY1 dungeon with watchtower installed at lower-left. Top resources coin1145 mana270 food18/30 infamy620 (actual prebuild1245/320 less watchtower100/50), DAY1 explorer×3 crown1500/1500, plain treasure HP bar. Bottom 5 dock labels "건설","수비대","전술","몬스터","전투 시작". Right edge OPEN collapsible inspector only ~24% wide, map still most screen. Handle chevron with "접기". Panel small exact watchtower thumbnail, heading "감시 초소", level "Lv.1 → Lv.2". Two icon rows current→next values from real upgrade: heart "체력 380 → 460", unit "정원 3 → 4". Cost coin90 mana30. Show prominent DISABLED muted button "강화" and clear inline lock reason "DAY 07부터 강화 가능". Grey cost/preview not purchased. Tiny explanatory line "적 이동 -18% · 받는 피해 +12%" from real tower. Selection thin violet outline on map watchtower. DO NOT give upgrade undo, don't invent experience for facilities. Inspector visual is restrained and clearly foldable, no full-screen modal.
```

### 07_monster_growth.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-8f8c0b05-fc78-4103-8860-656537cac4ae.png
Deliverable image path: docs/design/v1213_uiux/u3/07_monster_growth.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/kit_B_cute_dark.png](../../../../docs/design/v1213_uiux/kit/kit_B_cute_dark.png)
- [docs/design/v1213_uiux/audit/70_growth_day12_top.jpg](../../../../docs/design/v1213_uiux/audit/70_growth_day12_top.jpg)
- [assets/sprites/portraits/uiux3d/pudding_base.png](../../../../assets/sprites/portraits/uiux3d/pudding_base.png)
- [assets/sprites/portraits/uiux3d/gob_base.png](../../../../assets/sprites/portraits/uiux3d/gob_base.png)
- [assets/sprites/portraits/uiux3d/pynn_base.png](../../../../assets/sprites/portraits/uiux3d/pynn_base.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Image1 style only; image2 exact known DAY12 monster snapshot; images3-5 portraits identity. Use monster workspace with fixed LEFT narrow list~22% screen "동료": Gob card "곱 Lv.2", Pynn "핀 Lv.1", Pudding selected "푸딩 Lv.5". Top light resources coin5000 mana5000 food24/30 infamy650 DAY12. Right main area85%? keep list22%, content78%. Header medium Pudding portrait, "푸딩 · 근접 탱커", "Lv.5", bond "유대 80/100". Five tabs exact "훈련","스킬","전직","합동기","기억" icons, 훈련 active. Training content readable sparse, prominent comparative EXP bars exact "현재 20/170" and "훈련 후 40/170", "Lv.5 → Lv.5". These are PREVIEW only, label "훈련 미리보기". Cost coin30, "EXP +20", "하루 2회". No invented today-use count. Small comparison rows heart "260 → 260 (+0)", sword "20 → 20 (+0)", shield "12 → 12 (+0)", precisely values from image2. A compact paired meaning legend with infinity/seed icon "영구 성장 · EXP +20" and small battle/clock icon "다음 전투 준비 · 별도 효과" with one-line "훈련은 경험치를 키웁니다." No invented temporary buffs. Clearly display cap "현재 장 훈련 상한 Lv.5"; disabled training button "훈련" and readable reason "훈련 상한 도달". Do not falsely show actionable training at cap. Bottom-left back "관리로". Background subdued castle hall, generous spacing, no long stats wall.
```

보정 1 입력: `C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-c457f29b-4b41-419a-b70a-abe09e642363.png`

보정 1 프롬프트:

```text
Use case: precise-object-edit. Correct this already-generated game mockup. Single precise edit: remove decorative top-left "마왕성 U3" logo (U3 is internal workstream, NOT game branding); leave that small area understated castle background. Everything else identical: roster, tabs, numbers, EXP20/170→40/170, actual +0 stats, cap and disabled training. No extra slogans or features. Exact16:9 requested1920x1080. Output a single complete Korean game screen. Preserve style B and all unmentioned pixels/composition.
```

### 08_monster_promotion.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-9f03cd33-3636-4612-9a61-78ed248de279.png
Deliverable image path: docs/design/v1213_uiux/u3/08_monster_promotion.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/kit_B_cute_dark.png](../../../../docs/design/v1213_uiux/kit/kit_B_cute_dark.png)
- [assets/sprites/portraits/uiux3d/pudding_base.png](../../../../assets/sprites/portraits/uiux3d/pudding_base.png)
- [assets/sprites/portraits/evolution/portrait_slime_gate_bulwark.png](../../../../assets/sprites/portraits/evolution/portrait_slime_gate_bulwark.png)
- [assets/sprites/portraits/uiux3d/mori_base.png](../../../../assets/sprites/portraits/uiux3d/mori_base.png)
- [docs/design/v1213_uiux/audit/70_growth_day12_top.jpg](../../../../docs/design/v1213_uiux/audit/70_growth_day12_top.jpg)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Same monster layout as requested: left fixed roster short list 곱Lv.2, 핀Lv.1, 푸딩Lv.5 selected. Right FIVE tabs "훈련","스킬","전직","합동기","기억", 전직 active, thin top DAY12 coin5000 mana5000 food24/30 infamy650. Image2 current blue shield Pudding, image3 MUST exact evolved Pudding appearance (purple pudding slime, translucent teal castle-wall armor, golden gate emblem, chocolate head topped whipped cream and cherry), image4 exact Mori red-spotted mushroom with green cape and lantern. Show current smaller portrait → evolved larger portrait, exact title "성문 방벽 푸딩", role badge "전열 방벽", one-line "입구와 병영에서 오래 버팁니다." Known effect chips heart"+18%" shield"+10%" sword"+1", upgrade skill "방어막 강화". Clear condition column "필요 조건": "Lv.3 이상" checked with currentLv.5, "DAY12" checked, "2장 시작" checked, cost coin120 mana60 infamy20 checked because resources5000/5000/650. Do not invent universal bond requirement since this candidate has none. Cumulative limit row "승급 인원 · 확인 필요" with pending amber indicator (no speculative current count). Button "전직" disabled until cumulative limit checked; short reason "승급 인원 확인 필요". Bottom right small companion combo preview "합동기 · 별도 해금" with Pudding+Mori paired icons, exact "포자 젤리 피난처", "광역 보호 · 회복", "유대·기억·함께 출전 조건 확인". Do not imply promotion automatically unlocks combo. Not a crown evolution. Bottom "관리로".
```

보정 1 입력: `C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-530b6d10-0f3c-4176-8e31-9863f63fca31.png`

보정 1 프롬프트:

```text
Use case: precise-object-edit. Correct this already-generated game mockup. Change only two small things: remove top-left invented "마왕성 U3" logo AND slogan "어둠도, 함께라면 더 귀엽다" leaving quiet background; change Pynn roster status from "대기 중" to "출전" to match real DAY12 screenshot. Preserve all actual portraits, current/evolved appearance, five tabs, exact costs/conditions/stat multipliers, pending cumulative promotion count, separate combo preview. No new words, number or functionality. Output a single complete Korean game screen. Preserve style B and all unmentioned pixels/composition.
```

### 09_combat_hud.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-9d247ab9-c298-47f4-b54c-20b2c5a91786.png
Deliverable image path: docs/design/v1213_uiux/u3/09_combat_hud.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/screen_management_B.png](../../../../docs/design/v1213_uiux/kit/screen_management_B.png)
- [docs/design/v1213_uiux/audit/99_skill_action.jpg](../../../../docs/design/v1213_uiux/audit/99_skill_action.jpg)
- [assets/sprites/portraits/uiux3d/pudding_base.png](../../../../assets/sprites/portraits/uiux3d/pudding_base.png)
- [assets/sprites/portraits/uiux3d/gob_base.png](../../../../assets/sprites/portraits/uiux3d/gob_base.png)
- [assets/sprites/portraits/uiux3d/pynn_base.png](../../../../assets/sprites/portraits/uiux3d/pynn_base.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Render battle screenshot HUD, same real connected dungeon silhouette in input1, recognizable trio units from inputs3-5 with SMALL map sprites. Input2 known combat command bar costs and speed settings ONLY, do not recreate its cutscene overlay. DUNGEON very large~80% usable area, not a tiny picture inside frame. Thin top state "DAY 07", crown "1500/1500", battle command resource "명령 3/3". No invented unit damage or enemy count. Orange-red arrow at REAL left entrance points inward showing enemy incursion; hooded explorers small actual type rather than generic skeleton foes. Bottom single thin immediate action bar icon chips "집결 CP1","집중 CP1","비상 후퇴 CP2", separated small selected Pudding ability shield "방어막", hold corridor icon, small combo icon with lock "합동기". Policy small chips just above bar "성 전체 · 사수", "이 방 · 함정 유도", not large policy panel. Fixed bottom-right pause and speeds "×1","×1.5","×2","×3"; ×1 active, no new speed. Compact right small selection inspector ~16% width only "푸딩", blue shield portrait, simple HP bar without unverified numbers, "선택 유닛", shield skill icon; no giant panel. All controls remain accessible with inspector open. No cutscene, dialogue, resource shop, invented cooldown numbers, scores or new commands.
```

### 10_result.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-e2d4e5e8-2ce0-4fdf-96d6-0dc3bf9f2358.png
Deliverable image path: docs/design/v1213_uiux/u3/10_result.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/kit_B_cute_dark.png](../../../../docs/design/v1213_uiux/kit/kit_B_cute_dark.png)
- [docs/design/v1213_uiux/audit/46_monster_day1.jpg](../../../../docs/design/v1213_uiux/audit/46_monster_day1.jpg)
- [assets/sprites/portraits/uiux3d/pudding_base.png](../../../../assets/sprites/portraits/uiux3d/pudding_base.png)
- [assets/sprites/portraits/uiux3d/gob_base.png](../../../../assets/sprites/portraits/uiux3d/gob_base.png)
- [assets/sprites/portraits/uiux3d/pynn_base.png](../../../../assets/sprites/portraits/uiux3d/pynn_base.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
DAY1 defense success screen. Reference2 is REAL result snapshot and ONLY source of performance numbers. References3-5 exact cute trio bodies. Top center "방어 성공" with small DAY1 badge. Upper half cheerful victory illustration: blue wooden-shield slime Pudding smiles/bounces, green mohawk red-scarf Gob raises axe, red-horned purple-robed staff Pynn cheers inside existing candlelit castle, no new monsters or treasure currency rain. Beneath headline small actual verified outcome "왕좌 피해 0 · 생존 3/3". Actual earned rewards icon row coin"+198", mana"+60", infamy"+15", no invented rewards.
Lower half compact per-character performance table with portraits, names "푸딩","곱","핀", column headings ICONS + small "피해","회복","보호","합동기". Populate ONLY observed data: Gob damage133, Pudding protection"3회". ALL remaining unobserved cells show em dash "—" (NOT zero). Don't invent a score, MVP rank or imaginary heal amount. Pudding chosen violet outline badge "집중성장 선택됨". Its EXP compare "22/50 → 30/50", caption "영구 EXP +8"; separate NEXT battle benefit "다음 DAY · 최대 HP +24 · 방어 +1", verified in screenshot. Gob small EXP "20/50"; Pynn no invented EXP. Focus already applied, no duplicate purchase implied.
Bottom small selected-companion bridge "푸딩 · 훈련 미리보기" with cost coin30 and "EXP +20", clear "다음 DAY 준비에서 실행" (no train-buy button on result). Separate button "성장 확인", main next button "다음 DAY". Next DAY is explicit action and NOT automatic training. Keep joy art big, text short, readable and clear.
```

### 11_codex.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-ad24e527-41a2-4730-9aa7-5eac2372cdfc.png
Deliverable image path: docs/design/v1213_uiux/u3/11_codex.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/kit_B_cute_dark.png](../../../../docs/design/v1213_uiux/kit/kit_B_cute_dark.png)
- [assets/sprites/portraits/uiux3d/pudding_base.png](../../../../assets/sprites/portraits/uiux3d/pudding_base.png)
- [assets/sprites/portraits/uiux3d/gob_base.png](../../../../assets/sprites/portraits/uiux3d/gob_base.png)
- [assets/sprites/portraits/uiux3d/pynn_base.png](../../../../assets/sprites/portraits/uiux3d/pynn_base.png)
- [assets/sprites/portraits/uiux3d/mori_base.png](../../../../assets/sprites/portraits/uiux3d/mori_base.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Companion codex within A04 monster workspace, same subdued palace background and fixed LEFT companion list, scope strip "보유","도감","계약" with 도감 active. Top heading "동료 도감". Three known companion entries using actual portraits exact blue Pudding shield slime, green Gob red scarf mohawk axe, red Pynn staff imp, badges "만남". Main codex open-book spacious grid, known cards "푸딩" role"근접 탱커", "곱" role"근접 딜러", "핀" role"원거리 마법". Below, LOCKED companions entirely dark silhouettes ONLY (no portrait color, face, identity/name spoilers): one actual Mori mushroom silhouette from final ref, role"회복·정화", visible existing condition text "다음 회차 계약"; another generic catalog-accurate small stone sentinel silhouette role"고정 방어", condition"다음 회차 계약". These are known contract categories from actual game, don't invent days, currencies, quests or extra monster species. Locked name is "???" not Mori. Selected locked mushroom right small detail shows silhouette, "아직 만나지 않은 동료", "역할 · 회복·정화", "만나는 조건 · 다음 회차 계약". Gentle bottom one-line "다음 회차에서 새로운 동료를 만나 보세요." Small back arrow "몬스터로". No training/purchase/deploy controls for locked companions, no made-up codex completion count, no unrevealed memories or ending titles. Show only 5 entries, not random additional silhouettes.
```

보정 1 입력: `C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-83f3e1b0-cee0-4843-8ded-0bb8d15eb390.png`

보정 1 프롬프트:

```text
Use case: precise-object-edit. Correct this already-generated game mockup. Remove ONLY invented slogan beneath header "함께하는 작은 어둠이, 더 큰 이야기를 만든다". Keep title "동료 도감", actual portraits, roles,5entries, actual mushroom/stone sentinel locked silhouettes, scope tabs, next-cycle contract conditions, back and next-cycle expectation line unchanged. No new features or numbers. Output a single complete Korean game screen. Preserve style B and all unmentioned pixels/composition.
```

### 12_settings.png

Source image path: C:/Users/blueh/.codex/generated_images/01a1372f-c91c-7f23-932c-c1bd6168ed27/exec-a86b1cee-449b-48e1-a5bc-1829b9fbfc05.png
Deliverable image path: docs/design/v1213_uiux/u3/12_settings.png

최초 입력 레퍼런스:

- [docs/design/v1213_uiux/kit/kit_B_cute_dark.png](../../../../docs/design/v1213_uiux/kit/kit_B_cute_dark.png)

최초 생성 프롬프트:

```text
Use case: ui-mockup. ONE finished full-bleed Korean game screenshot concept for 마왕성 U3, landscape EXACT 16:9 1920x1080 (minimum1536x864). No device, no outer frame, no multi-screen collage, no design annotations. Approved style B cute dark fantasy: rounded translucent charcoal-aubergine UI, restrained lilac edges, fine gold accents, violet active glow, cream readable Korean, icon first with short labels, polished painterly 3D cute monsters, candle amber against violet shadows. Input kit is STYLE ONLY, its example resource counts and feature names are NOT game facts. Never copy made-up kit numbers. Text must be spelled exactly and not cropped. Do not invent new features, values, items or characters.
Settings game screen, subdued blurred candlelit violet throne hall, restrained main panel with rounded lilac outline. Title "설정". EXACT FOUR horizontal icon tabs "화면" monitor, "일반" gear, "오디오" speaker, "전투" crossed swords; 일반 active. Current shown general pane must contain only known general settings, not mix all tabs. Rows: globe icon "언어" with 3 beautiful segmented chips exact "한국어","English","简体中文", Korean lit selected. Next row book icon "튜토리얼 안내" current choice "기본" (do not invent a new preset list). Next row practice icon "조작 연습" modest button "연습 시작". Next history icon "안내 이력" modest button "이력 보기". Keep settings generous spacing and small icons dominant, sparse Korean short labels. Bottom paired buttons "취소", violet primary "적용". No auto-save text since apply/cancel required. No made-up HDR/FPS/keybind settings, graphics presets, connectivity or account features; no invented numerical sliders in general tab. This visual groups IA control/accessibility and dialogue/guidance into the user's requested 일반 tab, full plan not written on screen. No numeric volume values or new tutorial functionality.
```
