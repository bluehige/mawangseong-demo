# U4 공통 UI 부품 — 스타일 B

2026-10-14 · WORKSTREAM_ID `V1213-U4-CODEX` · `codex/v1213-fix-plan` · 제품 **1.2.12 유지**. v1213은 작업 이름이다.

사용자 확정 B 시안 `kit_B_cute_dark.png`·`screen_management_B.png`의 어두운 보라 패널, 둥근 모서리, 보라 강조, 금색 초점, 은은한 외곽 빛을 공통 부품으로 구현했다. 이번 단계는 **부품과 검증 갤러리**이며 실제 화면 교체는 U5다. 게임 로직·밸런스·저장 형식·기존 화면 레이아웃은 변경하지 않았다.

## 토큰과 호환 경계

`scripts/ui/kit/UIKitTokens.gd`가 색·수치의 단일 정의다. `assets/ui/kit/StyleB.tres`와 그라데이션 SVG는 토큰에서 생성되는 산출물이다. 일반 표면은 StyleBoxFlat, 강조 버튼만 작은 그라데이션 StyleBoxTexture 한 개를 공유한다. 셰이더는 필요하지 않다.

| 색 토큰 | 값 | 의미 |
|---|---|---|
| BACKGROUND | `#100c19` | 배경·바 트랙 |
| PANEL / PANEL_RAISED | `#21182d` / `#30223e` | 패널·버튼 표면 |
| BORDER | `#9373ab` | 보통 테두리 |
| GRADIENT_TOP / BOTTOM | `#a35aeb` / `#482078` | 강조 버튼 그라데이션 |
| ACCENT / HIGHLIGHT | `#cc8dff` / `#ffe4a0` | 보라 강조 / 금색 초점·강조 패널 |
| DANGER / DISABLED | `#e36b89` / `#282331` | 위험 / 비활성 표면 |
| TEXT / TEXT_SECONDARY / TEXT_MUTED | `#fff4e8` / `#d0bddc` / `#a696b4` | 본문 / 보조 / 비활성·덜 중요한 글자 |
| GOLD / MANA / FOOD / INFAMY | `#ffd064` / `#b876ff` / `#f8a46b` / `#dfb4f7` | 금화·마력·식량·악명 |
| HP / EXP | `#6ddf80` / `#ac68ef` | 체력·경험치 |
| SHADOW / GLOW | `#05030999` / `#b56bff66` | 그림자·보라 외곽 빛 |

| 크기 토큰 | 논리 px / 배율 | 규칙 |
|---|---|---|
| RADIUS_SMALL / RADIUS / RADIUS_LARGE | 8 / 14 / 22 | 바 / 버튼 / 패널·칩 |
| SPACE_UNIT / SPACE_SMALL / SPACE / SPACE_LARGE | 4 / 8 / 12 / 20 | 간격 단위·컨테이너 간격·패널 여백·안전 여백 |
| PADDING | 좌우12 / 상하8 | 버튼 내용 여백 |
| SHADOW_SIZE / SHADOW_OFFSET / GLOW_SIZE | 6 / `(0,3)` / 8 | 그림자·빛 |
| TITLE_SIZE / BODY_SIZE / SUPPORT_SIZE / NUMBER_SIZE | 32 / 20 / 18 / 22 | 제목 / 본문 / 보조 / 숫자 |
| BUTTON_SIZE / BUTTON_HEIGHT | 22 / 최소44 | 폰트+여백이 더 크면 자동 증가 |
| ICON_SIZE / ICON_SMALL / ICON_BUTTON_SIZE | 32 / 24 / 최소48 | 내용 아이콘 / 비용·칩 / 터치 대상 |
| PORTRAIT_SIZE | 최소96 | 비율을 유지하는 초상 |
| TOOLTIP_SIZE / TOOLTIP_WIDTH | 22 / 최대560 | 본문 줄바꿈과 가용 폭 |
| TOUCH_SCALE | 1.35 | 글자·간격·터치 대상 확대 |

글자 배율은 기존 설정 범위 0.9~1.15를 받고 **논리 18px 하한**을 지킨다. 간격·모서리·아이콘과 최소 조작 영역은 `max(1, text_scale) × touch_scale`, 글자 크기는 요청 크기×글자 배율×터치 배율이다. 높이는 실제 폰트와 줄바꿈·내용 여백을 바탕으로 Container가 결정한다. 컴포넌트에 고정 Rect 높이는 없다. ProgressBar의 최소 높이도 폰트 높이로 계산한다.

- `UIStandard`의 기존 상수·함수 이름은 유지하고 크기 상수와 공통 atlas 조회만 새 중앙 정의에 위임했다. 알 수 없는 기존 아이콘 ID의 조용한 `null` 반환도 유지한다.
- `UIUXTheme`의 기존 팔레트는 `LEGACY_*` 별칭으로 토큰 파일에 모았다. 기존 표면·무테 마스크 생성·`apply_tree()` 동작은 그대로다.
- `UIFont`는 기존 MapleStory Light/Bold·Noto CJK의 유일한 파일/역할/언어 선택 계층이다. 새로운 폰트 파일이나 별도 선택 로직을 만들지 않았다.
- `HUDController.panel/button` 등 기존 화면 생성기는 이번에 새 Theme으로 연결하지 않았다. `project.godot`의 전역 Theme도 바꾸지 않았다.

## 기본 사용법

씬의 루트나 부품의 부모는 가용 폭을 정하는 Container로 만든다. 텍스트와 상태를 설정한 뒤 루트에서 한 번 배율을 적용한다. `apply_scale()`은 원본 Theme을 복제하므로 반복 호출해도 배율이 누적되지 않는다. 새로 만든 하위 부품을 붙인 뒤에는 해당 가지에 다시 적용한다. 탭 재구성과 툴팁의 비용 행 재구성은 부모 Theme의 배율을 자체 유지한다.

```gdscript
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const Panel = preload("res://scripts/ui/kit/KitPanel.gd")
const Button = preload("res://scripts/ui/kit/KitButton.gd")

var panel := Panel.new()
$VBoxContainer.add_child(panel)
panel.content.add_child(Kit.label("제목", "title", true))
var apply := Button.new().configure("적용", Button.VariantStyle.PRIMARY,
    "check", "설정 적용\n변경한 설정을 저장합니다.")
panel.content.add_child(apply)
apply.pressed.connect(_on_apply)
Kit.apply_scale(panel, UISettings.text_scale, UISettings.is_touch_ui())
```

문구는 호출자가 현재 언어로 제공한다. 기존 번역이 있으면 `LanguageSettings.ui_text()`, 새 짧은 문자열이면 기존 `UIStandard.localized()`를 사용한다. 언어 전환 후 부품의 문구를 다시 설정하고 `apply_scale()`을 호출하면 `UIFont`의 해당 언어 폰트가 적용된다. 갤러리의 ko/en/zh_CN 문구는 검증 도구에만 있다. U5의 새 제품 문구를 자동 번역하거나 확정한 것은 아니다.

## 컴포넌트 API

모든 부품 파일은 `scripts/ui/kit/`에 있다. Panel 계열은 `content` VBoxContainer에 내용을 추가한다. 각 부품의 `set_ui_scale(text_scale, touch)` 또는 공통 `Kit.apply_scale(root, ...)`로 확대한다.

| 부품 | 생성·갱신 | 내용·입력 계약 |
|---|---|---|
| KitPanel | `new()`, `set_emphasis(bool)` | 기본 / 금색 강조·빛. `content.add_child()`로 조립 |
| KitButton | `configure(caption, variant, icon_id, help)`; `set_variant()` | BASIC/PRIMARY/DANGER/DISABLED. 기본 Button의 `pressed`, 초점, 비활성 입력 차단을 사용. `.disabled = true`로 강조/위험 종류를 보존하며 잠글 수도 있음 |
| KitIconButton | `configure_icon(icon_id, help)` | 텍스트 없는 아이콘 버튼. 툴팁이 비면 `_ready()` 경고 로그. 최소48 대상과 키보드 초점 |
| KitTabs | `set_tabs(entries, active_id)`, `select_tab(id)` | 항목 `{id,label,icon,tooltip,disabled}`. HFlow로 줄바꿈. `tab_selected(id)`는 새 유효 선택 때만 발생 |
| KitResourceBar | `set_resources(amounts, descriptions)` | `gold/mana/food/infamy` 아이콘·숫자·자원색. 이름·설명은 툴팁 |
| KitStatBar | `configure("HP" 또는 "EXP", value, max, before=-1)`; `set_value()` | 0/최대, 전→후 및 증감값. 상승 녹색·하락 위험색. 순수 표시이며 수치 지급 없음 |
| KitChip | `configure(icon_id, amount, max=-1, title="")`; `set_amount()` | 아이콘×수량 또는 현재/최대. 비용·정원·적 수 등 표시 |
| KitCard | `configure(name, level, portrait, hp, hp_max, exp, exp_max)` | 비율 유지 초상·이름·Lv·HP/EXP. 임의 게임 규칙·선택 ID를 포함하지 않음 |
| KitTooltip | `configure(title, explanation, costs={}, max_width=560)` | 제목+줄바꿈 본문+비용 칩. 갤러리 같은 가용 폭 Container에서는 `max_width=0` |
| KitModal | `configure(title, body, confirm_text, cancel_text)`; `present(parent, text_scale, touch)` | `confirmed`/`cancelled` 중 1회. 안전한 취소 초점, 내부 Tab 순환, Escape 취소, 기존 초점 복귀. 게임의 pause/저장 함수는 호출자가 담당 |
| KitToast | `configure(message, close_help)`; `present(parent, seconds=3, text_scale, touch)`; `dismiss()` | 하단 우측 비모달 알림, 닫기·자동 종료, `dismissed` 1회 |
| KitDock | `configure(entries, selected)`; `mount_bottom(parent)` | 하단 자동 크기 틀+아이콘/짧은 이름. `action_selected(id)`로 새 탭 선택 전달 |
| KitSideDrawer | `configure(title, help)`; `set_expanded(bool)`; `mount_right(parent)` | 접힌 손잡이 / 펼친 상세 패널. `panel.content`에 내용 추가. `expanded_changed(bool)` |

Tab/Dock의 비활성 사유는 항목 `tooltip`에 전달한다. 게임 조건·유효 대상·튜토리얼 target ID는 U5 호출자가 기존 함수를 연결해야 한다. 현재 활성 탭을 다시 누른 것은 선택 변경이 아니다. 전투 시작 같은 일회 행동은 U5에서 별도 KitButton으로 붙여 기존 확정 함수를 호출한다.

`KitButton.tooltip_costs = {"gold":120,"mana":10}`이면 커스텀 툴팁에 비용 행이 붙는다. 첫 줄은 제목, 다음 줄부터 설명이다. 엔진의 기본 툴팁 Popup에는 Theme의 TooltipPanel/TooltipLabel이 적용된다. 수동 툴팁은 `KitTooltip.present_at(parent, anchor, text_scale, touch)`로 최상단 CanvasLayer에 표시하며 콘텐츠 크기 계산 후 화면 경계에 맞춘다. `dismiss()`로 닫는다.

독·드로어를 지도 위에 mount할 때 부모는 전체 가용 영역을 제공하고, 지도/상세의 예약 공간은 부품의 **실제 `get_combined_minimum_size()`**를 기준으로 계산한다. 긴 상세 본문은 호출자가 ScrollContainer에 넣고 머리글/닫기/주요 행동을 바깥에 둔다. U4만으로 지도80%·화면 통합·클릭 감소를 완료했다고 판단하지 않는다.

## 레이어와 컷신

`UIKitLayers.gd`의 CanvasLayer 번호:

| 순서 | 상수 | 번호 |
|---|---|---:|
| 배경·지도 | BACKGROUND_MAP | 0 |
| 지도 표식 | MAP_MARKERS | 5 |
| HUD | HUD | 10 |
| 상세 패널 | DETAILS | 20 |
| 모달 | MODAL | 30 |
| 컷신 무대 | CUTSCENE | 40 |
| 토스트·수동 툴팁 | TOAST_TOOLTIP | 50 |

```gdscript
const Layers = preload("res://scripts/ui/kit/UIKitLayers.gd")
var visibility_policy := Layers.new()
visibility_policy.set_cutscene_active(true, [resource_bar, dock, speed, drawer])
# 컷신 도중 새 HUD/지원 알림이 생긴 경우:
visibility_policy.track_hud(new_hud)
# 종료·스킵·중단은 모두 같은 복구 함수로 연결:
visibility_policy.set_cutscene_active(false, [])
```

반복 숨김으로 원래 가시성을 덮어쓰지 않는다. 시작부터 숨겨진 HUD는 종료 뒤에도 숨겨져 있다. 이 정책은 새 부품용이며 기존 `SkillActionPresentation`의 D06/D07 숨김·복구 코드는 그대로 유지했다. U5에서 최상단 토스트가 컷신을 덮지 않아야 하는 상황이라면 해당 전투 알림도 HUD 숨김 목록에 등록한다. 게임 효과 commit·스킵 기록·일시정지는 이 함수가 다루지 않는다.

## Theme과 아이콘 교체

Theme은 Button/Label/PanelContainer/TabBar/ProgressBar/TooltipPanel/TooltipLabel/ScrollContainer/OptionButton/CheckBox/HSlider, PopupMenu·스크롤바와 Kit 변형을 포함한다. 일반 Control도 새 UI 가지의 Theme을 상속하면 같은 B 스타일을 사용한다.

아이콘 경로·기존 atlas 셀은 `UIKitIcons.gd` 한 곳에 있다. 기존 PNG와 푸딩 초상·12칸 atlas를 재사용하고 없는 건설/체크/접기/체크박스 빈 상태/슬라이더 손잡이만 단순 SVG로 작성했다. 최종 아이콘 승인본이 아니며 다른 자산 작업자의 결과를 덮어쓰거나 임의 채택하지 않았다.

토큰 또는 아이콘 매핑 수정 뒤, 격리 APPDATA를 사용해 다음을 실행한다. Theme 생성기는 토큰에서 그라데이션 SVG를 작성하고 직접 디코드하므로 그라데이션 수정에 전역 editor import가 필요하지 않다. 새로운 외부 아이콘은 해당 자산의 Godot import가 먼저 필요하다.

```powershell
$env:APPDATA = Join-Path $PWD 'tmp/v1213_u4/theme/profile'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
godot --headless --path . --script res://tools/ui_kit/BuildTheme.gd
powershell -ExecutionPolicy Bypass -File tools/ui_kit/RunGallery.ps1 -Profile final
```

## 검증과 캡처

- `tools/ui_kit/KitGallery.tscn`이 실제 Godot 4.6.3 그래픽 렌더를 수행한다. **1920×1080·1280×720 × 기본/1.35 터치 배율 × ko/en/zh_CN = 12조합**이다. 각 조합은 행동/자원/독, 카드/바/칩, 툴팁/모달/토스트, 드로어/기본 Control의 4페이지를 가진다.
- 기본·강조·위험 버튼 각각 normal/hover/pressed/focus/disabled를 실제 Theme 리소스로 보여준다. hover/pressed/focus는 정적 상태 미리보기이며 실제 입력은 계약 검사에서 별도로 확인한다.
- 좁은 화면·큰 글자에서 내용은 갤러리의 ScrollContainer로 이어진다. 화면 밖 항목은 가려진 상태만으로 완료 처리하지 않고, 중간/하단 스크롤 캡처에서 각 내용이 한 번 이상 온전히 보이는지 검사한다. 스크롤 시 경계에서 일부 보이는 항목은 정상 스크롤이며 원본 JSON에 남는다.
- 감사 도구 `Audit.collect()`를 재사용하고 `effective_rect()`만 현재 해상도에 맞춘다. `scan.py --kit-gallery`는 기존 기하 검사와 별도로 12×4 조합, 부품 내용, 렌더 요소 전체 표시를 검증한다. 기존 Sweep의 29화면 기준은 완화하지 않았다.
- `RunGallery.ps1`은 렌더 exit code·오류 로그·스캐너 결과를 확인하고 비교 이미지를 생성한다. PNG/JSON/scan.json/비교 이미지/격리 프로필은 `tmp/v1213_u4/<Profile>/`에만 남는다.
- `compare.py`의 비교 이미지는 **원본 B 기준을 그대로** 왼쪽에, 실제 갤러리의 내용 영역을 잘라 오른쪽 4칸에 놓은 한 장이다. 전체 원본 캡처는 별도로 보존한다. 이미지 생성 모델로 실행 증거를 재현하지 않았다.
- `KitContractTest.tscn`: 실제 마우스/키보드/터치 입력, 비활성 차단, 글자 증가에 따른 높이, 0.9 및 1.15+터치 배율·세 언어 폰트, 탭 재구성, 구조화 툴팁·레이어·경계, 드로어, 확인 1회·Escape·초점 복귀, 컷신 HUD 원상 복구, 토스트 만료를 검증한다. `--kit-empty-tooltip`은 경고 1회를 의도적으로 유발한다.
- 기존 V1213StageOne/S1Followup/StageTwo 표적 검사와 데스크톱/터치 Sweep을 재실행한다. S1 후속 headless의 기존 `can_process: !is_inside_tree()` 로그7회는 이전 인계와 동일한 알려진 제한이다.

최종 숫자·커밋 SHA·로그·비교 경로는 [U4 세션 인계](../../handoff/V1213_U4_UI_KIT_2026-10-14.md)에 기록한다. 개인 세이브·전체 회귀·전체 플레이·물리 터치 기기·새 export·공개 배포는 이번 범위가 아니다.

구현 근거는 [Godot Theme](https://docs.godotengine.org/en/stable/classes/class_theme.html), [StyleBoxFlat](https://docs.godotengine.org/en/stable/classes/class_styleboxflat.html), [Container](https://docs.godotengine.org/en/stable/classes/class_container.html), [GDScript 생성자](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#class-constructor)의 공식 문서를 확인했고, 제공된 엔진에서 직접 실행해 검증했다.
