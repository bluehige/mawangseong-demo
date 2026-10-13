# 스타일 B — UI 아이콘32종 후보

- Generation model: GPT internal image generation
- Generated date: 2026-10-14
- Target version: 1.2.13 (v1213 UI/UX candidate; 사용자 폴더 이름에 따른 가정)

## 기준과 제작

`docs/design/v1213_uiux/kit/kit_B_cute_dark.png`의 귀여운 다크 판타지 아이콘 톤을 사용했다. 금색 베벨·짙은 자주 외곽·보라색 포인트를 유지했다. 내부 imagegen을 transparent_background:true로 호출해 네이티브 RGBA 원본 시트2장에 각각16종을 생성했다. 두 번째 시트는 첫 번째 시트도 참조해 톤을 맞췄다. generation_prompts.json에 실제 프롬프트를 보존했다. 외부 이미지 서비스 또는 유료 API를 사용하지 않았다.

도구에는 전용 크기 인자가 없으므로 프롬프트에2048×2048을 요청했으나 실제 생성 원본은1254×1254다. 4×4 시트를 분리해 각 기호의 실제 알파 영역을 감싼 뒤 비율을 유지하여 최대 길이208픽셀로 축소하고256×256 투명 캔버스 중앙에 넣었다. 배경 제거·알파 임계값 보정은 하지 않았다. 모든 개별 PNG의 최소 여백은24픽셀이고 도형 중심은 반 픽셀 이내로 맞췄다. 가로로 긴 체크 등의 모양에는 반대 축 여백이 더 크며 형태 비율은 보존한다.

prepare_and_check.py에 실제 분할 위치·리사이즈·미리보기·수치 검증을 보존했다. 이 스크립트는 새 파일을 만들 때 기존 파일이 있으면 중단한다. 전체 제작을 다시 실행할 필요 없이 결과 PNG/JSON을 검토할 수 있다.

## 아이콘 목록 및 알파 검사

| 용도 | 파일 | 크기 | 알파0 비율 % | 반투명 비율 % | 여백 좌/상/우/하 px | 외곽 비투명 픽셀 |
|---|---|---|---:|---:|---|---:|
| 설정 | icon_settings.png | 256×256 | 65.4236 | 34.1492 | 40/24/36/24 | 0 |
| 로그 | icon_log.png | 256×256 | 73.7976 | 25.9064 | 32/24/32/24 | 0 |
| 저장 | icon_save.png | 256×256 | 64.3417 | 35.3439 | 40/24/41/24 | 0 |
| 불러오기 | icon_load.png | 256×256 | 61.6318 | 37.8601 | 24/28/24/28 | 0 |
| 도감 | icon_encyclopedia.png | 256×256 | 60.1669 | 39.4623 | 24/28/24/28 | 0 |
| 배속 | icon_speed.png | 256×256 | 75.5463 | 24.2035 | 24/28/24/28 | 0 |
| 일시정지 | icon_pause.png | 256×256 | 67.0929 | 32.4005 | 28/24/28/24 | 0 |
| 재생 | icon_play.png | 256×256 | 79.8843 | 19.9326 | 57/24/58/24 | 0 |
| 넘기기 | icon_skip.png | 256×256 | 80.0079 | 19.6915 | 47/24/48/24 | 0 |
| 자동재생 | icon_auto_play.png | 256×256 | 66.1789 | 33.4625 | 41/24/42/24 | 0 |
| 건설 | icon_build.png | 256×256 | 76.4618 | 23.2025 | 35/24/36/24 | 0 |
| 수비대 | icon_garrison.png | 256×256 | 71.8979 | 27.8595 | 38/24/38/24 | 0 |
| 전술 | icon_tactics.png | 256×256 | 59.5123 | 40.0452 | 24/29/24/29 | 0 |
| 몬스터 | icon_monster.png | 256×256 | 57.4524 | 42.1951 | 29/24/30/24 | 0 |
| 전투시작 | icon_battle_start.png | 256×256 | 70.0821 | 29.6539 | 24/30/24/31 | 0 |
| 되돌리기 | icon_undo.png | 256×256 | 68.1305 | 31.4346 | 24/25/24/26 | 0 |
| 닫기 | icon_close.png | 256×256 | 54.2908 | 45.2942 | 24/28/24/28 | 0 |
| 정보 | icon_info.png | 256×256 | 52.9373 | 46.6461 | 24/25/24/25 | 0 |
| 경고 | icon_warning.png | 256×256 | 65.2405 | 34.5261 | 24/27/24/27 | 0 |
| 잠금 | icon_lock.png | 256×256 | 63.9847 | 35.7452 | 44/24/44/24 | 0 |
| 체크 | icon_check.png | 256×256 | 79.8660 | 19.8791 | 24/44/24/44 | 0 |
| 금화 | icon_gold.png | 256×256 | 59.1064 | 40.5823 | 24/25/24/26 | 0 |
| 마력 | icon_mana.png | 256×256 | 75.3723 | 24.3149 | 41/24/41/24 | 0 |
| 식량 | icon_food.png | 256×256 | 70.5719 | 29.0878 | 24/28/24/28 | 0 |
| 악명 | icon_infamy.png | 256×256 | 61.1801 | 38.3728 | 24/31/24/32 | 0 |
| 왕좌 | icon_throne.png | 256×256 | 57.8796 | 41.7053 | 24/24/25/24 | 0 |
| 보물실 | icon_treasury.png | 256×256 | 55.4184 | 44.1833 | 24/28/24/28 | 0 |
| 탐험가(적) | icon_explorer_enemy.png | 256×256 | 59.3613 | 40.2420 | 24/24/25/24 | 0 |
| 감시초소 범위 | icon_watch_post_range.png | 256×256 | 71.9116 | 27.8641 | 24/37/24/37 | 0 |
| 경험치 | icon_experience.png | 256×256 | 70.6589 | 28.9169 | 30/24/31/26 | 0 |
| HP | icon_hp.png | 256×256 | 69.5999 | 30.0476 | 27/24/27/24 | 0 |
| 언어(지구본) | icon_language.png | 256×256 | 56.1569 | 43.4921 | 24/28/24/29 | 0 |

## 고정 경로 필드

- Source image path: assets/source/imagegen/v1213_ui_icons/icon_auto_play.png
- Runtime image path: assets/ui/kit/icons/icon_auto_play_64.png
- Runtime image path: assets/ui/kit/icons/icon_auto_play_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_battle_start.png
- Runtime image path: assets/ui/kit/icons/icon_battle_start_64.png
- Runtime image path: assets/ui/kit/icons/icon_battle_start_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_build.png
- Runtime image path: assets/ui/kit/icons/icon_build_64.png
- Runtime image path: assets/ui/kit/icons/icon_build_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_check.png
- Runtime image path: assets/ui/kit/icons/icon_check_64.png
- Runtime image path: assets/ui/kit/icons/icon_check_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_close.png
- Runtime image path: assets/ui/kit/icons/icon_close_64.png
- Runtime image path: assets/ui/kit/icons/icon_close_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_encyclopedia.png
- Runtime image path: assets/ui/kit/icons/icon_encyclopedia_64.png
- Runtime image path: assets/ui/kit/icons/icon_encyclopedia_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_experience.png
- Runtime image path: assets/ui/kit/icons/icon_experience_64.png
- Runtime image path: assets/ui/kit/icons/icon_experience_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_explorer_enemy.png
- Runtime image path: assets/ui/kit/icons/icon_explorer_enemy_64.png
- Runtime image path: assets/ui/kit/icons/icon_explorer_enemy_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_food.png
- Runtime image path: assets/ui/kit/icons/icon_food_64.png
- Runtime image path: assets/ui/kit/icons/icon_food_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_garrison.png
- Runtime image path: assets/ui/kit/icons/icon_garrison_64.png
- Runtime image path: assets/ui/kit/icons/icon_garrison_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_gold.png
- Runtime image path: assets/ui/kit/icons/icon_gold_64.png
- Runtime image path: assets/ui/kit/icons/icon_gold_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_hp.png
- Runtime image path: assets/ui/kit/icons/icon_hp_64.png
- Runtime image path: assets/ui/kit/icons/icon_hp_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_infamy.png
- Runtime image path: assets/ui/kit/icons/icon_infamy_64.png
- Runtime image path: assets/ui/kit/icons/icon_infamy_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_info.png
- Runtime image path: assets/ui/kit/icons/icon_info_64.png
- Runtime image path: assets/ui/kit/icons/icon_info_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_language.png
- Runtime image path: assets/ui/kit/icons/icon_language_64.png
- Runtime image path: assets/ui/kit/icons/icon_language_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_load.png
- Runtime image path: assets/ui/kit/icons/icon_load_64.png
- Runtime image path: assets/ui/kit/icons/icon_load_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_lock.png
- Runtime image path: assets/ui/kit/icons/icon_lock_64.png
- Runtime image path: assets/ui/kit/icons/icon_lock_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_log.png
- Runtime image path: assets/ui/kit/icons/icon_log_64.png
- Runtime image path: assets/ui/kit/icons/icon_log_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_mana.png
- Runtime image path: assets/ui/kit/icons/icon_mana_64.png
- Runtime image path: assets/ui/kit/icons/icon_mana_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_monster.png
- Runtime image path: assets/ui/kit/icons/icon_monster_64.png
- Runtime image path: assets/ui/kit/icons/icon_monster_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_pause.png
- Runtime image path: assets/ui/kit/icons/icon_pause_64.png
- Runtime image path: assets/ui/kit/icons/icon_pause_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_play.png
- Runtime image path: assets/ui/kit/icons/icon_play_64.png
- Runtime image path: assets/ui/kit/icons/icon_play_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_save.png
- Runtime image path: assets/ui/kit/icons/icon_save_64.png
- Runtime image path: assets/ui/kit/icons/icon_save_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_settings.png
- Runtime image path: assets/ui/kit/icons/icon_settings_64.png
- Runtime image path: assets/ui/kit/icons/icon_settings_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_skip.png
- Runtime image path: assets/ui/kit/icons/icon_skip_64.png
- Runtime image path: assets/ui/kit/icons/icon_skip_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_speed.png
- Runtime image path: assets/ui/kit/icons/icon_speed_64.png
- Runtime image path: assets/ui/kit/icons/icon_speed_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_tactics.png
- Runtime image path: assets/ui/kit/icons/icon_tactics_64.png
- Runtime image path: assets/ui/kit/icons/icon_tactics_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_throne.png
- Runtime image path: assets/ui/kit/icons/icon_throne_64.png
- Runtime image path: assets/ui/kit/icons/icon_throne_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_treasury.png
- Runtime image path: assets/ui/kit/icons/icon_treasury_64.png
- Runtime image path: assets/ui/kit/icons/icon_treasury_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_undo.png
- Runtime image path: assets/ui/kit/icons/icon_undo_64.png
- Runtime image path: assets/ui/kit/icons/icon_undo_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_warning.png
- Runtime image path: assets/ui/kit/icons/icon_warning_64.png
- Runtime image path: assets/ui/kit/icons/icon_warning_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icon_watch_post_range.png
- Runtime image path: assets/ui/kit/icons/icon_watch_post_range_64.png
- Runtime image path: assets/ui/kit/icons/icon_watch_post_range_128.png
- Source image path: assets/source/imagegen/v1213_ui_icons/icons_preview.png
- Source image path: assets/source/imagegen/v1213_ui_icons/originals/icons_sheet_01.png
- Source image path: assets/source/imagegen/v1213_ui_icons/originals/icons_sheet_02.png

원본 시트와 icons_preview.png는 출처/검토용이다. 미리보기는 의도적으로 어두운 RGB 배경 위에32종을 나열했다. 개별 icon_*.png만 실제 투명 자산 후보다. 2026-10-14 U4 fidelity에서 각 PNG를 Lanczos로64/128px로 축소했다. 알파를 그대로 보존했고 배경 제거 없이 총64개636452bytes를 assets/ui/kit/icons/에 연결했다. tools/ui_kit/prepare_icons.py가 재현 도구이며 알파 검사는 tmp/v1213_u4/fidelity/icon_checks.json에 있다.

## 검증과 한계

Pillow로PNG/RGBA를 디코딩하고 numpy/scipy로 알파0·반투명 비율·외곽·도형범위를 계산했다. 32개 모두256×256이며 알파0 비율52.9373~80.0079%, 외곽 비투명 픽셀0, 최소 여백24px다. 두 시트의 기호가 분할 경계에서 잘리지 않았는지 확인했고 최종 icons_preview.png를 직접 열어 모든 용도를 확인했다. 저장/불러오기, 재생/넘기기/자동재생의 기호는 서로 다르다. 감시초소의 보라색 범위 링은 요청한 의미 표현이며 기호 안의 의도적 반투명 요소다.

게임 연결·실행 검수·빌드·전체 회귀는 하지 않았다. git 명령/커밋/푸시도 실행하지 않았다. 기준 브랜치와원격 권위 확인 및 실제 연결은 헤드 작업자가 수행한다. docs/handoff 수정 권한이 없어 이SOURCE.md가 통합 출처·핸드오프를 대신한다.

- Review task ID: NOT_REQUESTED
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS (생성 후보의 크기·알파·분할·미리보기 검사에 한정)
- Runtime wiring: UIKitIcons.gd / assets/ui/kit/icons/ (2026-10-14 U4 fidelity)

## U4 런타임 채택 (2026-10-14)

제품 버전은1.2.12를 유지한다. 위 Target version의1.2.13은 원 제작자가 폴더 이름에서 가정한 후보 식별값이며 출시 SemVer가 아니다. 런타임64/128px를32종 모두 중앙 매핑에 연결했다. 기존 개인 저장과 기존 화면 atlas는 분리 보존했다. 새 이미지 생성 호출0.
