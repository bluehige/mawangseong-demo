# 마왕성 UI 전면 개편 — 디자인 방향 스타일 키트

Generation model: GPT internal image generation
Generated date: 2026-10-14
Target version: v1213_uiux design concept (문서 경로 식별자이며 제품 출시 버전 확정 아님)
Source image path: docs/design/v1213_uiux/kit/kit_A_ornate_gold.png
Source image path: docs/design/v1213_uiux/kit/kit_B_cute_dark.png
Source image path: docs/design/v1213_uiux/kit/screen_management_A.png
Source image path: docs/design/v1213_uiux/kit/screen_management_B.png
Runtime image path: N/A — 디자인 비교 시안이며 런타임 미연결

## 목적·작업 범위

사용자 원문: “지금 너무 덜 만든 게임 같은 UI. 제대로 만든 게임의 UI 디자인과 형태를 갖추고 싶다. 글씨가 많은 것보다 아이콘으로 처리할 수 있는 건 아이콘으로.”

A는 검은 반투명 패널·얇은 금 장식·보라 보석·세리프 계열 제목의 고급 다크 판타지, B는 둥근 형태·보라 그라데이션·귀여운 몬스터 아이콘의 친근한 다크 판타지다. 각각 스타일 키트 한 장과 관리 화면 한 장을 만들었다. B 관리 화면은 A 관리 화면을 편집 대상으로 사용해 화면 배치와 던전 구도를 비교하기 쉽게 맞췄다.

- 생성 방식: 내장 `image_gen.imagegen`, 총 4회. 외부 서비스·유료 API·CLI 생성기 사용 없음.
- 불투명 전체 화면 시안: 모든 호출에 `transparent_background: false` 지정. 패널의 반투명 효과는 배경과 합쳐진 RGB 이미지이며 분리된 알파 자산이 아니다.
- 허용된 새 파일 5개만 이 폴더에 저장. 생성기의 기본 캐시 사본은 유지했다.
- 후처리: 생성 PNG를 지정 파일명으로 바이트 그대로 복사. 리사이즈·크롭·배경 제거·로컬 합성·글자 덧쓰기 없음.
- git 명령은 사용자의 금지 지시에 따라 전혀 실행하지 않음. 브랜치·SHA·원격 최신성 미확인. 다른 작업자의 파일·CURRENT·세션 핸드오프·게임 코드·자산은 수정하지 않음.
- 출시·실제 UI 구현·커밋·배포는 이 작업 범위에 포함되지 않음.

## 레퍼런스와 입력 역할

| 파일 | 역할 |
| --- | --- |
| `docs/design/v1213_screens/v1213_title_v3.png` | 사용자 호평 톤: 어두운 보라, 금 장식, 귀여운 몬스터. A/B 키트 및 A 관리 화면의 스타일 참고 |
| `docs/design/v1213_screens/v1213_dialogue_v3.png` | 어두운 반투명 UI 및 장면을 덜 가리는 표현 참고. A/B 키트 입력 |
| `docs/design/v1213_screens/reference_dialogue_ui_user.png` | 얇고 세련된 반투명 인터페이스·작은 아이콘의 완성도 기준. A/B 키트 입력. 인물·숲 배경 이식 금지 |
| `tmp/growth_support_feedback/first_protection_slime_gate_bulwark.png` | 현재 게임 개선 대상. A 관리 화면의 주 편집 대상, B 관리 화면의 던전 보존 보조 입력 |
| `kit_A_ornate_gold.png` | A 관리 화면의 UI 스타일 입력 |
| `screen_management_A.png` | B 관리 화면의 주 편집 대상. 같은 던전 구도와 UI 배치 비교 기준 |
| `kit_B_cute_dark.png` | B 관리 화면의 UI 스타일 입력 |

위 최초 네 개 로컬 입력은 생성 전에 `view_image`로 실제 화면을 확인했다. 생성된 A/B/C/D는 내장 생성기의 반환 이미지로 시각 확인했다.

## 산출물과 검증

| 파일 | 실제 형식·크기 | 시각 확인 |
| --- | --- | --- |
| `kit_A_ornate_gold.png` | PNG / RGB / 1672×941 | 자원 4종+숫자, 버튼 3상태, 탭 4개, 아이콘 버튼 8개, 툴팁, 캐릭터 카드(레벨·경험치·HP), 적 정보 ×3, 왕좌·보물실 체력바, 확인창, 저장 토스트 확인 |
| `kit_B_cute_dark.png` | PNG / RGB / 1672×941 | A와 같은 필수 구성요소 확인. 둥근 보라 패널·귀여운 아이콘·캡슐형 적 정보 |
| `screen_management_A.png` | PNG / RGB / 1672×941 | 얇은 상단 자원 바, 좌상단 DAY 12·적 ×3, 접힌 우측 상세 핸들, 하단 건설·수비대·전술·몬스터·전투 시작, 큰 중앙 쿼터뷰 던전 |
| `screen_management_B.png` | PNG / RGB / 1672×941 | A와 같은 화면 배치에 둥근 보라 UI 적용 |

Pillow 11.1.0의 `Image.verify()` 후 다시 열어 `Image.load()`로 네 장 모두 전체 디코딩 성공. 최소 1536×864 조건은 네 장 모두 통과했다. 정확한 16:9 정수 검사 `width * 9 == height * 16`는 네 장 모두 실패했다. 실제 비율은 약 1.77683:1, 16:9 대비 상대 오차는 약 0.0531%다.

관리 화면의 던전 표시 공간은 동굴 배경을 포함하는 게임 뷰포트로 해석했다. 눈으로 확인한 UI 경계를 사각형으로 감싸고, 반투명 패널 안까지 전부 가려진 면적으로 계산했다. 아래 좌표는 왼쪽·위 포함, 오른쪽·아래 제외이며 이미지 좌상단이 (0,0)이다. 픽셀 자동 분할 검사가 아닌 수동 경계 기반 근사 검증이다.

- A UI 영역: `(0,0,1672,56), (26,65,237,114), (26,116,349,192), (396,824,1278,912), (1616,329,1672,508), (1523,845,1650,906)`
- B UI 영역: `(0,0,1672,56), (26,64,240,114), (26,116,349,193), (375,823,1308,914), (1614,329,1672,510), (1513,844,1650,906)`
- 산식: `1 - sum(UI 직사각형 면적) / (1672 * 941)`
- A: 약 **85.77%**, B: 약 **85.18%**. 수동 경계 기준 85% 통과. 외곽 발광의 모든 픽셀까지 엄밀히 계산한 비율은 아니다.

A/B 관리 화면의 UI를 제외한 공통 표본 `(355,195,1505,805)`을 `ImageChops.difference`로 비교했다. 평균 채널 차이는 0~255 기준 R 5.54 / G 5.09 / B 4.87이며 픽셀 동일성은 실패했다. 이는 두 관리 시안 사이의 비교이며, 원본 게임 그림과 동일하다는 검사가 아니다.

빌드·게임 자동 테스트·전체 검수는 실행하지 않았다. 게임 코드 변경이 없는 이미지 시안 작업이다.

## 남은 제한·판정

**STATUS: partial**

네 장과 출처·프롬프트 문서는 생성 완료했지만, 아래 엄밀한 조건을 충족했다고 주장하지 않는다.

1. 정확한 16:9: 프롬프트에는 2048×1152 및 정확한 16:9를 요구했으나, 도구가 네 장 모두 1672×941로 반환했다. 현재 도구 스키마에는 출력 너비·높이 인자가 없다. 출력 파일을 임의로 자르거나 늘리지 않았다.
2. “현재 던전 그림 유지”: 원본의 주요 방 배치·쿼터뷰·벽·왕좌·보물실·연못·동굴 분위기는 시각적으로 유지했으나, 생성 과정에서 세부 질감·선·장식이 재생성됐다. 원본 픽셀을 그대로 사용한 확정 합성본이 아니다. 실제 적용에서는 기존 게임 던전 렌더링을 유지하고 UI만 구현해야 한다.
3. A의 적 정보는 작은 칩보다 큰 표본 카드로 표현됐다. B에서는 캡슐형 칩이다. 관리 화면의 A/B 적 정보는 모두 작은 칩이다.
4. 키트의 보조 슬로건과 A의 장식용 영문은 생성기가 추가한 문구다. 필수 UI 라벨은 한국어 중심이며, 실사용 텍스트나 제품 문구로 승인된 내용이 아니다.

다음 결정: A/B 디자인 방향 선택 또는 두 방향에서 채택할 요소 결정. 정확한 규격과 원본 픽셀 보존이 필요한 최종 적용 파일은 선택한 방향에 맞춘 별도 작업이 필요하다.

## 가정

- 숫자·레벨·비용·체력은 비교용 예시이며 게임 데이터 변경이 아니다.
- `DAY`, `HP`, `Lv.` 및 배속 기호는 게임 관례에 맞는 짧은 표시로 사용했다.
- 우측 상세 패널은 접힌 기본 상태로 표시했다. 펼친 상태는 이번 네 장에 포함하지 않았다.
- 글자를 줄이면서 시안 비교가 가능하도록 키트의 아이콘에는 작은 한국어 식별 라벨을 붙였다.
- `v1213_uiux`는 지정된 문서 경로를 따른다. 제품 목표 SemVer는 추론해서 확정하지 않았다.

## 실제 생성 프롬프트

영문 프롬프트 안의 한국어 문자열은 출력 글자로 지정했다. 아래는 각 호출에 전달한 전문이다.

### A — kit_A_ornate_gold.png

```text
Use case: ui-mockup. Create ONE finished Korean game UI STYLE KIT sheet, landscape EXACT 16:9, 2048x1152 preferred, minimum 1536x864. Output a single high-resolution image. NOT a gameplay scene.
Input reference 1 title image: authoritative Mawangseong tone, dark royal purple + gold, charming monsters. Reference 2 dialogue: subtle dark translucency. Reference 3 user dialogue UI: professional thin unobtrusive translucent interfaces and small icons; copy quality only, NOT its forest or people.
Title text: "A · 고급 다크 판타지". A restrained finished PC strategy game interface system, near-black translucent panels, delicate 1px antique-gold hairlines, small ornamental corner tips, violet gemstone accent, Korean serif feeling display heading, highly legible cream Korean body typography. Elegant restrained luxury, no thick gaudy frames. Faint purple stone backdrop to reveal translucent panels. Small bat/slime portrait matching title reference. Consistent icons and spacing. Clean aligned sheet with ample breathing room.
REQUIRED layout, all components present, no omitted components:
At top below small sheet heading: one slim resource bar with 4 distinct pictorial icons and numeric values: gold coin "1,250", purple mana crystal "80", food drumstick "24", notoriety horned skull "12". Icons + numbers only, no resource words.
Middle-upper left: 3 button states in a row, captions "기본", "강조", "비활성"; button text "확인", gold-purple highlight active, dim desaturated disabled.
Below: exactly 4 tabs with icons + short Korean labels "건설", "수비대", "전술", "몬스터".
Middle-left below tabs: exactly EIGHT small icon buttons in one row or 2x4 grid: gear/settings, rolled parchment/log, floppy disk/save, open bestiary book/encyclopedia, double play chevron/speed, two vertical bars/pause, hammer/build, horned slime/monster. Tiny Korean labels beneath for sheet identification only: "설정", "로그", "저장", "도감", "배속", "일시정지", "건설", "몬스터".
Lower left: tooltip specimen with exact text title "성문 방벽", short explanation "입구의 아군을 보호합니다.", costs coin icon "120" and mana icon "10". Small dark translucent tooltip with small pointer.
Middle-right: ONE compact character card, cute blue armored slime portrait, text "방패 슬라임", level "Lv. 5", thin violet experience bar "경험치 65 / 100" and green-red HP bar "HP 800 / 1,000".
Nearby ONE enemy-info pill: adventurer hooded-face icon and "×3", caption "탐험가".
Lower middle: TWO slender structure health bars: crown/throne icon and "왕좌 1,500 / 1,500"; treasure chest icon and "보물실 800 / 1,000".
Lower right: ONE complete small confirmation dialog: title "전투를 시작할까요?", body "배치를 마치고 방어를 시작합니다.", buttons "취소" and "시작", delicate gold border and small purple gem.
Bottom: ONE compact success toast with checkmark, exact text "저장했습니다".
Ensure all Korean strings accurately rendered, no Latin placeholder text, no extra paragraphs, no giant logos, no watermark. Components should look ready for a polished real game, icon-first, concise text. This sheet is a design direction, not implementation documentation.
```

### B — kit_B_cute_dark.png

```text
Use case: ui-mockup. Create ONE finished Korean game UI STYLE KIT sheet, landscape EXACT 16:9, 2048x1152 preferred, minimum 1536x864. Output a single high-resolution image. NOT a gameplay scene.
Input reference 1 title image: authoritative Mawangseong tone, dark royal purple + gold, charming monsters. Reference 2 dialogue: subtle dark translucency. Reference 3 user dialogue UI: professional thin unobtrusive translucent interfaces and small icons; copy quality only, NOT its forest or people.
Title text: "B · 귀여운 다크 판타지". A finished friendly PC strategy game UI system, rounded corners, smooth muted plum and violet gradients in slim translucent panels, very fine lilac edges, soft restrained amber accent and small purple jewel, rounded highly legible Korean typography. Brighter and friendlier than A but still dark magical castle, never pastel white or candy mobile UI. Small cute bat/slime mascot icons matching the title reference. Faint dark purple stone backdrop, not visually busy. Consistent rounded icons and spacing. Clean aligned sheet with ample breathing room. No gold ornate angular frames.
REQUIRED layout, all components present, no omitted components:
At top below small sheet heading: one slim resource bar with 4 distinct pictorial icons and numeric values: gold coin "1,250", purple mana crystal "80", food drumstick "24", notoriety horned skull "12". Icons + numbers only, no resource words.
Middle-upper left: 3 button states in a row, captions "기본", "강조", "비활성"; button text "확인", soft luminous lavender highlight active, dim desaturated disabled.
Below: exactly 4 tabs with icons + short Korean labels "건설", "수비대", "전술", "몬스터".
Middle-left below tabs: exactly EIGHT small icon buttons in one row or 2x4 grid: gear/settings, rolled parchment/log, floppy disk/save, open bestiary book/encyclopedia, double play chevron/speed, two vertical bars/pause, hammer/build, horned slime/monster. Tiny Korean labels beneath for sheet identification only: "설정", "로그", "저장", "도감", "배속", "일시정지", "건설", "몬스터".
Lower left: tooltip specimen with exact text title "성문 방벽", short explanation "입구의 아군을 보호합니다.", costs coin icon "120" and mana icon "10". Small dark translucent tooltip with small pointer.
Middle-right: ONE compact character card, cute blue armored slime portrait, text "방패 슬라임", level "Lv. 5", thin violet experience bar "경험치 65 / 100" and green-red HP bar "HP 800 / 1,000".
Nearby ONE enemy-info pill: adventurer hooded-face icon and "×3", caption "탐험가".
Lower middle: TWO slender structure health bars: crown/throne icon and "왕좌 1,500 / 1,500"; treasure chest icon and "보물실 800 / 1,000".
Lower right: ONE complete small confirmation dialog: title "전투를 시작할까요?", body "배치를 마치고 방어를 시작합니다.", buttons "취소" and "시작", delicate rounded lilac border and small purple gem.
Bottom: ONE compact success toast with checkmark, exact text "저장했습니다".
Ensure all Korean strings accurately rendered, no Latin placeholder text, no extra paragraphs, no giant logos, no watermark. Components should look ready for a polished real game, icon-first, concise text. This sheet is a design direction, not implementation documentation.
Important: enemy-info specimen must be a SMALL horizontal pill chip, not a large portrait card. No decorative slogans, no English subtitles. Exact output pixel size request: 2048 x 1152 (16:9).
```

### C — screen_management_A.png

```text
Use case: ui-mockup / precise-object-edit. Create ONE finished Korean gameplay management/pre-combat screenshot mockup for Mawangseong, direction A.
Output landscape EXACT 16:9, 2048x1152 preferred, minimum1536x864. No sheet, no collage, no side-by-side, no mockup device, no explanatory captions.
INPUT IMAGE ROLES:
1. The current gameplay screenshot is the PRIMARY EDIT TARGET. Its isometric quarter-view dungeon image is authoritative. Preserve its EXISTING PIXEL-ART dungeon geometry, room layout, wall shapes, textures, pixel-art style, objects, throne at rear/top, treasure chest at bottom/front, torches, purple banners, slime and pool at right, cave backdrop. Keep dungeon drawing unchanged, no redesign, no new 3D assets or ornate illustration. Remove only the old GUI overlays and text; restore their covered areas consistently. Enlarge uniformly the current dungeon scene to fill the screen behind small UI overlays, preserving its orientation and room topology.
2. A gold style kit is STYLE REFERENCE ONLY for the new UI; never paste the style kit into the dungeon or use its illustrated castle backdrop.
3. Title art is COLOR/MOOD REFERENCE ONLY; NOT replacement background or new dungeon art.
Primary goal: professionally finished icon-first strategy game HUD leaving AT LEAST 85% OF SCREEN AREA as unobstructed dungeon viewport; same large central dungeon, very thin UI on perimeter. The art must remain pixel-art as input, GUI crisp modern high quality.
Precise layout:
- Top slim translucent near-black resource rail ~4% screen height, fine gold divider, tiny pictorial gold coin "1,250", purple crystal "80", food "24", horned skull "12", numbers only no labels. At far right tiny gear, save and book icons.
- Upper-left immediately below rail: small compact chip with "DAY 12" (DAY permitted exact user request), adjacent tiny adventurer icon "×3", no text paragraphs. Beneath it two tiny narrow health indicators with crown icon "1,500 / 1,500" and chest icon "800 / 1,000". This cluster occupies <2% canvas.
- Right edge: details panel COLLAPSED by default, only a slim vertical rounded rect handle at x≈96%, y≈45%, with small slime portrait icon and inward chevron, short Korean label "상세". This shows foldable panel affordance WITHOUT opening a large panel; leave almost entire dungeon visible.
- Bottom center: thin floating icon dock ~5% canvas height, airy not a full-screen-width opaque bar. Four small tabs with pictorial hammer "건설", shield "수비대", crossed swords "전술", cute horned slime "몬스터". To their right ONE emphasized larger gold-purple action button with triangle play icon and exact label "전투 시작". Large relative to icons, NOT large relative to entire screen. Bottom right tiny pause icon and "×1" speed.
Visual A: near-black translucent surfaces, very thin antique gold ornamented hairline edges only a few tiny corners, small violet gems, refined Korean heading serif feeling, cream concise UI text, dark fantasy atmosphere matching game title. No giant text, no tutorial box, no open tooltip, no chat overlay, no ornate surrounding full-screen frame, no invented characters, no sloganeering, no watermark. Prioritize preserving existing dungeon image while demonstrating improved UI forms. All UI Korean except "DAY" and numeric indicators.
```

### D — screen_management_B.png

```text
Use case: ui-mockup / precise-object-edit. Create ONE Korean gameplay management/pre-combat screenshot mockup for Mawangseong, direction B. Landscape EXACT 16:9, requested 2048x1152 or at least1536x864.
INPUT ROLES:
Reference1 screen_management_A is the PRIMARY EDIT TARGET. Preserve ALL its dungeon art, all rooms, cave, floor, wall geometry, torches, decorations, throne rear top, purple portal left, right pool, treasure chest bottom, orientation, zoom and placements EXACTLY. CHANGE ONLY the GUI STYLE. Do not redraw or reinterpret dungeon. Do not replace game art with painted castle art.
Reference2 original current-game screenshot is AUTHORITATIVE dungeon preservation support. Never revert to its old text-heavy GUI.
Reference3 kit_B_cute_dark is the UI STYLE reference ONLY; use its rounded plum translucent surfaces, soft lavender gradients, thin lavender edging, cute slime/bat icons. Do NOT paste its sheet backdrop or character illustrations into dungeon.
Keep exactly SAME management layout as Reference1 to enable fair A/B comparison. At least85% of entire screen remains unobstructed dungeon scene. Very thin resource strip at top (≤5.5% height), compact DAY+enemy chip at upper left, collapsed small detail handle on right, compact thin floating bottom dock (≤8%height). No expanded panel, tooltip, tutorial or dialog, no extra paragraphs.
GUI B: soft rounded corners, subtle plum/violet gradients, crisp pale lilac hairlines, restrained warm gold small resource icon highlights, cream rounded Korean typography, friendly but unmistakably dark magical castle atmosphere. Purple glow only on selected tab and action. Small cute monster pictograms, no thick frames.
Required displayed UI:
- Resource icons gold coin "1,250", purple mana crystal "80", food "24", notoriety horned skull "12"; no word labels. Top-right tiny settings gear, save disk, open book.
- Upper-left "DAY 12" chip and tiny explorer face icon "×3". Two micro health bars with crown icon "1,500 / 1,500" and chest icon "800 / 1,000".
- Right edge only a collapsed detail handle with cute blue slime face, inward chevron, Korean "상세". Stay as narrow as in A.
- Bottom dock pictorial hammer "건설", shield "수비대", crossed swords "전술", cute horned slime "몬스터"; one larger highlighted purple gradient play button "전투 시작". Bottom-right tiny pause and "×1".
No heading saying B, no slogan, no English except exact DAY, no watermark. Text minimum. Identical central existing dungeon art and same layout, change only interface style. Preserve image dimensions if you cannot provide exact2048x1152.
```
