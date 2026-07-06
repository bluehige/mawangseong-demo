# UI 스킨 실제 적용 기록 (2026-07-06)

## 적용 범위

- `image_gen`으로 생성한 다크 판타지 UI 프레임/버튼 에셋을 실제 Godot HUD에 연결했다.
- 단색 `StyleBoxFlat` 중심이던 주요 패널/버튼을 `StyleBoxTexture` 기반으로 교체했다.
- 텍스트는 이미지에 박지 않고 기존 Godot `Label/Button` 텍스트를 유지했다.

## 새 에셋

위치: `assets/ui/dark_fantasy/`

- `resource_plaque_wide.png`
- `resource_plaque_small.png`
- `hp_bar_frame.png`
- `panel_inspector.png`
- `panel_log.png`
- `panel_parchment.png`
- `button_normal.png`
- `button_hover.png`
- `button_pressed.png`
- `ui_skin_atlas_imagen2_source.png`

참고: `button_menu.png`, `icon_slot.png`, `banner_title.png`는 첫 atlas 산출물에서 유지했다.

## 코드 변경

- `scripts/ui/HUDController.gd`
  - `PANEL_SKINS`, `BUTTON_SKINS` 경로 테이블 추가.
  - `panel()`은 기본적으로 이미지 패널 스킨을 사용한다.
  - `button()`은 normal/hover/pressed 이미지 버튼 스킨을 사용한다.
  - `build_top_bar()`를 레퍼런스처럼 개별 자원 플라크 + DAY 플라크 + HP 프레임으로 변경했다.
  - 신규 PNG가 아직 Godot import 되지 않아도 `Image.load()` fallback으로 로딩한다.
- `scripts/game/GameRoot.gd`
  - 온보딩 전체 배경 패널은 `flat`으로 유지한다.
  - 이름 입력/대화/예고 등 내부 패널은 이미지 프레임 스킨을 사용한다.

## 시각 확인

캡처 위치:

- `tmp/manual_verification/01_management.png`
- `tmp/manual_verification/03_combat_start.png`

확인 결과:

- 관리 화면 상단 자원바, 좌측 방 목록, 우측 인스펙터, 하단 버튼이 레퍼런스의 금장/보라/석재 톤으로 바뀌었다.
- 전투 화면도 동일 스킨이 적용됐지만, 전투 UI 배치는 아직 후속 검토 대상이다.
- 전투 로그/지침 패널은 장식 프레임이 커서 정보 밀도와 시야 가림을 별도 조정해야 한다.

## 남은 작업

- 전투 HUD는 다음 단계에서 구조를 다시 잡는다.
  - 좌측 전체 지침 패널 크기 축소 또는 접힘 처리.
  - 전투 로그는 하단 고정형/최근 3줄 오버레이형 비교.
  - 선택 유닛 패널은 우측 유지하되 스킬 슬롯 크기와 HP 표시를 재정렬.
- 현재 스킨은 1차 적용이다. 최종화 전에는 버튼/패널별 전용 크기 이미지를 추가 생성하는 편이 좋다.
