# U4 공통 UI 부품 — 스타일 B

2026-10-14 · WORKSTREAM_ID `V1213-U4-FIDELITY` · `codex/v1213-fix-plan` · 제품 **1.2.12 유지**. v1213은 작업 이름이다. 이전51b54be의 축소 비교/임시 아이콘/평면 표면 판정을 아래 측정·실제 전체 프레임 비교로 대체한다.

사용자 확정 B 시안 `kit_B_cute_dark.png`·`screen_management_B.png`의 어두운 보라 패널, 둥근 모서리, 보라 강조, 금색 초점, 은은한 외곽 빛을 공통 부품으로 구현했다. 이번 단계는 **부품과 검증 갤러리**이며 실제 화면 교체는 U5다. 게임 로직·밸런스·저장 형식·기존 화면 레이아웃은 변경하지 않았다.

## 토큰과 호환 경계

`scripts/ui/kit/UIKitTokens.gd`가 크기·본문 색의 단일 정의다. `assets/ui/kit/StyleB.tres`는 토큰에서 생성된다. 키트 표면은 `KitSurface.gd` + `surface.gdshader`의 단일 패스로 그린다. 일반/강조/위험의 기본·호버·눌림·비활성, 선택 탭을 지원하며 금색 초점은 Theme으로 덧그린다. 세로 보라 그라데이션·12px 유한 외곽 빛·밝은 외곽선과3px 안쪽 어두운 선·상단 하이라이트가 존재한다. Container 크기와 상태가 바뀔 때만 uniform을 갱신하고 `_process`/TIME/화면 샘플/블러/다중 패스가 없다. 바는 작은 둥근 그라데이션 StyleBoxTexture로 만든다. 확대 시 모서리를9-slice로 보존한다.

| 색 토큰 | 값 | 의미 |
|---|---|---|
| BACKGROUND | `#100c19` | 배경·바 트랙 |
| PANEL / PANEL_RAISED | `#21182d` / `#241a31` | 패널·버튼 표면 |
| BORDER | `#9373ab` | 보통 테두리 |
| GRADIENT_TOP / BOTTOM | `#9e50df` / `#3a1763` | 강조 버튼 그라데이션 |
| ACCENT / HIGHLIGHT | `#cc8dff` / `#ffe4a0` | 보라 강조 / 금색 초점·강조 패널 |
| DANGER / DISABLED | `#e36b89` / `#282331` | 위험 / 비활성 표면 |
| TEXT / TEXT_SECONDARY / TEXT_MUTED | `#fff4e8` / `#d0bddc` / `#a696b4` | 본문 / 보조 / 비활성·덜 중요한 글자 |
| GOLD / MANA / FOOD / INFAMY | `#ffd064` / `#b876ff` / `#f8a46b` / `#dfb4f7` | 금화·마력·식량·악명 |
| HP / EXP | `#6ddf80` / `#ac68ef` | 체력·경험치 |
| SHADOW / GLOW | `#05030999` / `#b56bff66` | 그림자·보라 외곽 빛 |

| 크기 토큰 | 논리 px / 배율 | 규칙 |
|---|---|---|
| RADIUS_SMALL / RADIUS / RADIUS_LARGE | 12 / 16 / 26 | 바 / 버튼 / 패널. 적 칩 반경48 |
| RADIUS_COMPACT / RADIUS_TAB / RADIUS_DOCK | 21 / 14 / 20 | 툴팁·토스트·왕좌 바 / 탭 / 독 버튼. 관리 자원 바22 |
| SPACE_UNIT / SPACE_SMALL / SPACE / SPACE_LARGE | 4 / 12 / 24 / 32 | 간격 단위·컨테이너 간격·패널 여백·안전 여백 |
| PADDING | 좌우24 / 상하12 | 기본 버튼. 아이콘 버튼 좌우12, 탭 좌우18/상하11 |
| SHADOW_SIZE / SHADOW_OFFSET / GLOW_SIZE | 6 / `(0,3)` / 8 | 그림자·빛 |
| TITLE_SIZE / BODY_SIZE / SUPPORT_SIZE / NUMBER_SIZE | 36 / 26 / 24 / 28 | 제목 / 본문 / 보조·바 숫자 / 자원·Lv. 숫자는 Light 폰트 |
| BUTTON_SIZE / BUTTON_HEIGHT | 28 / 최소70 | 폰트+여백이 더 크면 자동 증가 |
| TAB_HEIGHT / DOCK_HEIGHT / BATTLE_HEIGHT | 78 / 96 / 100 | 키트 탭 / 관리 독 / 전투 시작. 실제 u3 독90px에 대해96px(+6.7%) |
| RESOURCE_HEIGHT / BAR_HEIGHT | 84 / 24 | kit_B 자원84~86px / HP·EXP24px. 관리 자원 바58px는48px 아이콘·5px 상하 여백의 밀집 변형 |
| ICON_SIZE / ICON_SMALL / ICON_BUTTON_SIZE | 56 / 40 / 최소84 | 실제 도형은 PNG의 여백을 포함해 약45 / 32px. 고해상도용128px 조회 가능 |
| PORTRAIT_SIZE | 너비240, 카드 영역240×176 | 기존 푸딩 초상의 실제 도형 영역을 AtlasTexture로 참조, 픽셀/알파 수정 없음 |
| TOOLTIP_SIZE / TOOLTIP_WIDTH | 26 / 최대560 | 본문 줄바꿈과 가용 폭. 비교 fixture는612px로 지정 |
| TOUCH_SCALE | 1.35 | 글자·간격·터치 대상 확대 |

새 키트 글자 배율은0.9~1.15, **논리24px 하한**이다. 기존 UIStandard 화면의18px 하한·44px 버튼·기존atlas는 그대로 보존한다. 새 키트의 간격·아이콘·최소 조작 영역은 `max(1, text_scale) × touch_scale`이다. 높이는 최소 토큰+실제 폰트·줄바꿈·내용 여백으로 Container가 결정한다. 바의 시각 두께는24px이고 숫자 영역을 예약해 채색 막대와 수치가 겹치지 않는다. 갤러리의 고정 Rect는 시안 측정용 fixture이며 제품 컴포넌트의 고정 화면 좌표가 아니다.

## 1920 기준 측정 원장

원장: `tools/ui_kit/reference_measurements.json`. kit_B는1672×941이므로 x는1920/1672=1.148325, y는1080/941=1.147715로 환산했다. u3 세 장은 원래1920×1080이다. 아래는 빛을 제외한 보이는 테두리/도형의 수동 측정이며 경계 오차는 원본±2px다. 글자 크기는 래스터 글자 높이에서 추정한 값이며 생성 시안의 실제 폰트 파일/원래 point size를 알 수는 없다. 따라서 정확한 폰트 일치로 주장하지 않는다.

| 기준·부품 | 원본 높이 →1920 높이 | 패딩 좌우/상하(1920) | 반경 | 글자 추정 | 아이콘 도형/영역 | 바 두께 |
|---|---:|---:|---:|---:|---:|---:|
| kit_B 기본/강조/비활성 버튼 | 61→70 | 23/12 | 16 | 28 | — | — |
| kit_B 자원 | 75→86 | 28/16 | 25 | 25 | 51 | — |
| kit_B 탭 | 68→78 | 23/14 | 14 | 25 | 41 | — |
| kit_B 아이콘 버튼 | 73→84 | 12/12 | 16 | 이름21 | 48 | — |
| kit_B 카드 | 289→332 | 25/25 | 25 | 이름34·Lv25·바22~24 | 초상 약241×145 | 21→24 |
| kit_B 적 칩 | 103→118 | 23/12 | 53 | 28 | 101 | — |
| kit_B 왕좌/보물실 | 83~86→95~99 | 18/12 | 21 | 25 | 64 | 20→23 |
| kit_B 툴팁 | 178→204 | 25/21 | 21 | 제목28·본문25 | 건물172 | — |
| kit_B 모달 | 239→274 | 25/28 | 25 | 28 | — | — |
| kit_B 토스트 | 82→94 | 28/16 | 21 | 25 | 48 | — |
| u3/03 자원 | 58→58 | 26/8 | 22 | 24 | 40 | — |
| u3/03 시설 카드 | 128→128 | 16/12 | 16 | 이름26·비용22~24 | 104 | — |
| u3/03 독/전투 시작 | 90→90 | 28~30/14 | 20 | 30 | 56 | — |
| u3/07 자원/탭 | 78/89→78/89 | 26/14~16 | 24/16 | 26/32 | 48 | — |
| u3/07 동료 카드 | 117→117 | 16/12 | 16 | 이름30·Lv26 | 96 | — |
| u3/07 EXP 미리보기 | 38→38 | 8/4 | 19 | 26 | — | 28 |
| u3/07 비활성 행동 | 118→118 | 30/20 | 26 | 36 | — | — |
| u3/10 보상 | 132→132 | 24/14 | 18 | 30 | 64 | — |
| u3/10 선택 행/일반 행 | 86/71→86/71 | 18/10~8 | 16/14 | 28/26 | 112/88 | — |
| u3/10 보조/주요 행동 | 95/127→95/127 | 26~32/18~22 | 22/24 | 32/42 | 주요48 | — |

u3/07의 큰 성장 미리보기 바28px, u3/10의127px 주요 행동은 화면별 큰 변형으로 남기고 키트 기본값을 무조건 키우지 않는다. 사용자 예시의 자원64px보다 u3/03은 실제58px였다. 측정값을 우선하며 키트 기본84px와 관리 밀집58px를 구분한다.

- `UIStandard`의 기존 상수·함수 이름과 원래 크기를 유지하고 공통 atlas 조회는 `get_legacy_icon()`으로 분리했다. 알 수 없는 기존 아이콘 ID의 조용한 `null` 반환도 유지한다. 새 키트의 치수/32종 PNG가 기존 화면에 전파되지 않는다.
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
| KitIconButton | `configure_icon(icon_id, help)` | 텍스트 없는 아이콘 버튼. 툴팁이 비면 `_ready()` 경고 로그. 최소84 대상과 키보드 초점 |
| KitTabs | `set_tabs(entries, active_id)`, `select_tab(id)` | 항목 `{id,label,icon,tooltip,disabled}`. HFlow로 줄바꿈. `tab_selected(id)`는 새 유효 선택 때만 발생 |
| KitResourceBar | `set_resources(amounts, descriptions)` | `gold/mana/food/infamy` 아이콘·숫자·자원색. 이름·설명은 툴팁 |
| KitStatBar | `configure("HP" 또는 "EXP", value, max, before=-1)`; `set_value()` | 0/최대, 전→후 및 증감값. 상승 녹색·하락 위험색. 순수 표시이며 수치 지급 없음 |
| KitChip | `configure(icon_id, amount, max=-1, title="")`; `set_amount()` | 아이콘×수량 또는 현재/최대. 비용·정원·적 수 등 표시 |
| KitCard | `configure(name, level, portrait, hp, hp_max, exp, exp_max)` | 비율 유지 초상·이름·Lv·HP/EXP. 임의 게임 규칙·선택 ID를 포함하지 않음 |
| KitTooltip | `configure(title, explanation, costs={}, max_width=560)`; `set_illustration(texture)` | 제목+줄바꿈 본문+아이콘/숫자 비용 행. 선택 건물 그림. 갤러리 같은 가용 폭 Container에서는 `max_width=0` |
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

아이콘 경로·별칭·기존 atlas 셀은 `UIKitIcons.gd` 한 곳에 있다. 사용자 지시대로 `assets/source/imagegen/v1213_ui_icons/`의32종을64/128px로 최적화해 `assets/ui/kit/icons/`에 채택했고 SOURCE.md의 Runtime image path64개를 실제 파일과 연결했다. 네이티브 알파를 보존하며 배경 제거/재생성은 없다. 임시 SVG5개와 import를 제거했다. `shield→garrison`, `attack→tactics`, `auto→auto_play`, `resume→play` 등을 별칭으로 유지한다. native Control의 `chevron→undo`, `unchecked→lock`, `slider_grip→mana`는 새32종 안에서 기능 의미가 가까운 호환 표현이며 전용 기호와 동일하지 않은 차이를 기록한다. 기존 화면 atlas는 별도 유지한다.

토큰 또는 아이콘 매핑 수정 뒤, 격리 APPDATA를 사용해 다음을 실행한다. Theme 생성기는 토큰에서 그라데이션 SVG를 작성하고 직접 디코드하므로 그라데이션 수정에 전역 editor import가 필요하지 않다. 새로운 외부 아이콘은 해당 자산의 Godot import가 먼저 필요하다.

```powershell
$env:APPDATA = Join-Path $PWD 'tmp/v1213_u4/theme/profile'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
godot --headless --path . --script res://tools/ui_kit/BuildTheme.gd
powershell -ExecutionPolicy Bypass -File tools/ui_kit/RunGallery.ps1 -Profile final
```

## 검증과 캡처

- 이번 fidelity의 주 갤러리는 `FidelityGallery.tscn`이다. 원본 시안과 같은 배치의1920×1080 전체 프레임2장(kit/관리 strip)과 상태별 전체 프레임1장을 실제 Godot에서 렌더한다. 기존 성 홀 그림 `docs/design/v1213_screens/dialogue_bg_throne_report.png`를 배경으로 사용하며 시안 UI 픽셀을 가져다 붙이지 않는다.
- `RunFidelity.ps1 -Profile fidelity`는45초 상한·60FPS 제한·기존 Godot 프로세스 차단·종료 보장·GPU 표본 기록·오류 로그/치수 검사를 수행한다. 실제 설치 경로가 다르면 `-GodotPath`로 확인된 실행 파일을 전달한다. 캡처/프로필은 tmp에만 둔다.
- `fidelity.py`는 원본 전체를1920×1080으로 환산한 왼쪽과1920×1080 원본 framebuffer 오른쪽을 그대로 놓아3840×1080 비교를 만든다. **크롭/페이지 짜깁기/오른쪽 렌더 축소 없음**. 경로: `tmp/v1213_u4/fidelity/compare_kit.png`, `compare_management_strip.png`. 관리 비교는 요청한 자원·시설 카드 줄·독만 재현하며 지도/툴팁을 재현한 전체 관리 화면으로 주장하지 않는다.
- 30개 기본 fixture와 개별 탭·독 버튼의 실제 크기를 측정 원장의 좌표/가용 슬롯과 대조한다. 시각 요소의 픽셀 수준 동일성까지 이 기하 통과로 주장하지 않는다. 보정0→1→2 및 최종 캡처/실패 로그는 tmp에 보존한다.
- 최종 **38개/실패0, 최대 크기 오차6.38%**. 부품 계약은 기존72개+바 숫자의 한국어/간체/터치 확대3개를 추가해 **75개/실패0**다. S1 41/S1후속131/S2 907 통과, Sweep29화면×2의49/50캡처 스캐너0을 유지했다. 최종 갤러리 엔진 FPS는3화면 모두60이며120프레임 짧은 구간 계산은약61.02로 경계 오차를 포함한다. 장치 전체 GPU32표본은0~22%, 중앙값13%; Godot 전용 사용률은 아니다.
- 아래12조합/102캡처는 이전 U4의 사용성 갤러리 기록이다. 이번 변경의 새로운 결과와 혼동하지 않는다. `KitGallery.tscn`과 `RunGallery.ps1`은 추가 배율/언어 검증 도구로 보존하며 실제 shader 상태 미리보기와60FPS 상한으로 갱신했다.

- `tools/ui_kit/KitGallery.tscn`이 실제 Godot 4.6.3 그래픽 렌더를 수행한다. **1920×1080·1280×720 × 기본/1.35 터치 배율 × ko/en/zh_CN = 12조합**이다. 각 조합은 행동/자원/독, 카드/바/칩, 툴팁/모달/토스트, 드로어/기본 Control의 4페이지를 가진다.
- 기본·강조·위험 버튼 각각 normal/hover/pressed/focus/disabled를 실제 Theme 리소스로 보여준다. hover/pressed/focus는 정적 상태 미리보기이며 실제 입력은 계약 검사에서 별도로 확인한다.
- 좁은 화면·큰 글자에서 내용은 갤러리의 ScrollContainer로 이어진다. 화면 밖 항목은 가려진 상태만으로 완료 처리하지 않고, 중간/하단 스크롤 캡처에서 각 내용이 한 번 이상 온전히 보이는지 검사한다. 스크롤 시 경계에서 일부 보이는 항목은 정상 스크롤이며 원본 JSON에 남는다.
- 감사 도구 `Audit.collect()`를 재사용하고 `effective_rect()`만 현재 해상도에 맞춘다. `scan.py --kit-gallery`는 기존 기하 검사와 별도로 12×4 조합, 부품 내용, 렌더 요소 전체 표시를 검증한다. 기존 Sweep의 29화면 기준은 완화하지 않았다.
- `RunGallery.ps1`은 렌더 exit code·오류 로그·스캐너 결과를 확인하고 비교 이미지를 생성한다. PNG/JSON/scan.json/비교 이미지/격리 프로필은 `tmp/v1213_u4/<Profile>/`에만 남는다.
- 과거 `compare.py`의 오른쪽4칸 축소 비교는 fidelity 판정 근거로 사용하지 않는다. 새 `fidelity.py`의 전체 프레임 비교로 대체했다. 이미지 생성 모델로 실행 증거를 재현하지 않았다.
- `KitContractTest.tscn`: 실제 마우스/키보드/터치 입력, 비활성 차단, 글자 증가에 따른 높이, 0.9 및 1.15+터치 배율·세 언어 폰트, 탭 재구성, 구조화 툴팁·레이어·경계, 드로어, 확인 1회·Escape·초점 복귀, 컷신 HUD 원상 복구, 토스트 만료를 검증한다. `--kit-empty-tooltip`은 경고 1회를 의도적으로 유발한다.
- 기존 V1213StageOne/S1Followup/StageTwo 표적 검사와 데스크톱/터치 Sweep을 재실행한다. S1 후속 headless의 기존 `can_process: !is_inside_tree()` 로그7회는 이전 인계와 동일한 알려진 제한이다.

최종 숫자·커밋 SHA·로그·비교 경로는 [U4 fidelity 인계](../../handoff/V1213_U4_FIDELITY_2026-10-14.md)에 기록한다. 개인 세이브·전체 회귀·전체 플레이·물리 터치 기기·새 export·공개 배포는 이번 범위가 아니다.

## 직접 비교·보정 기록

| 회차 | 직접 본 차이 | 적용한 보정 | 근거 |
|---|---|---|---|
| 0→1 | 최초 카드441px·모달/툴팁/토스트의 초기 줄바꿈 최소 높이가 큰 상태로 남음. 아이콘 버튼96px. | 가용 폭이 확정된 뒤 실제 최소 높이를 다시 계산하는 fixture 배치. 자동 크기 계약은 그대로 유지. | fidelity/round0/, round1/ 전체 렌더 |
| 1→2 | 내부 아이콘이 작음, 카드 초상의 큰 투명 여백, 수치 굵기/막대 겹침, 자원/토스트/적 칩 높이, 툴팁 비용 pill이 시안과 다름 | 아이콘56px·타일84px, 기존 초상 도형영역 Atlas 참조, Light 숫자, 수치 폭 예약, 표면 여백 분리, 툴팁 그림/비용 아이콘 행 | fidelity/round2_fixed/ |
| 2→최종 | 키운 아이콘 때문에 탭4개가 두 줄, 흰 glow·위험 대비·툴팁/모달 보석 위치, 독 버튼 비율 | 탭 여백18/11·78px 높이, 별도 보라 glow, 모달 상단 보석·툴팁 포인터, 독224/198/178/198px | fidelity/kit_render.png, management_render.png, states_render.png |

남는 차이: 시안의 미세한 모서리 식물/문양·금 장식·배경/마스코트/타이틀 그림, 시안의 독특한 폰트 외곽선은 동일하지 않다. 실제 생성된32종의 금색/보라색 배색과 탐험가 도형도 시안과 다르다. HP 미충족분의 빨간색은 현재 키트에서 검은 트랙이며 데이터 수치 의미는 유지한다. 관리 strip의 시설 그림은 기존 게임 자산으로 u3의 새 시설 그림과 다르다. 이런 차이를 크기 측정 통과나 기존 기능 검사만으로 시안 완전 일치라고 평가하지 않는다.

구현 근거는 [Godot Theme](https://docs.godotengine.org/en/stable/classes/class_theme.html), [StyleBoxFlat](https://docs.godotengine.org/en/stable/classes/class_styleboxflat.html), [Container](https://docs.godotengine.org/en/stable/classes/class_container.html), [GDScript 생성자](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#class-constructor)의 공식 문서를 확인했고, 제공된 엔진에서 직접 실행해 검증했다.
