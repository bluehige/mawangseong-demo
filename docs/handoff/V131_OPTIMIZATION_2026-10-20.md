# V131 최적화 점검 — 사용자 확인 대기

## 1. 메타데이터

- 작성일: 2026-10-20 KST
- 목표 버전/작업: v1.3.1-4 / 0134, 보류0066의 A.1~3 대체 수행
- 브랜치: `codex/v131-patch`
- 작업트리: `C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-v131-patch`
- 기준 SHA: `f3a0c617288f83758db83cc4974fb280569f7fbe`
- 마지막 제품·검증 SHA: `7f1a4d224587bc6fa7fef1ea74fd143b1d7b03b1`. 이후에는 인계·CSV·CURRENT만 변경한다.
- 원격 푸시/PR/태그: 없음. 영어 로컬 커밋만.
- 권위 제한: 로컬 main 부재. `origin/main=0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`. 원격 최신성은 확정하지 않았다. 제공 AGENTS·사용자 지정 브랜치·계획의 최신0134 항목을 적용했다.
- 계획: `C:/Users/blueh/Desktop/진행중인프로젝트/_orchestra/plans/V131_NEXT_PATCH_PLAN.md`의 05:39 갱신. `tasks/hold/0066-optimization-audit.md`는 읽기만 했고 보류·대체 상태를 유지한다.

## 2. 결과와 적용 범위

숨긴 전투 화면의 버튼 위치·체력표 배치·상태 갱신을 중단했다. 설정 창4초의 호출 수는 **240/240/34→0/0/0**이다. 화면 복귀 첫 표시 프레임에 갱신하며 비시각 알림·자동 대화 타이밍을 담당하는 `_suspended_interface_tick` 호출 순서는 유지한다.

제품 수정은 `ApprovedBattleUI.gd`의 가시성 조건3행뿐이다. 0133 대화 코드·게임 수치·스토리·저장 형식·글꼴 변경0. DAY29 무전투 유지. 이미지·import·export 설정 변경0. 대규모 리팩터링·죽은 코드 삭제·미사용 파일 제외는 미실행이다.

FPS는 수직 동기화 아래 약60으로 비슷하며 **메모리·PCK·시작 시간 개선은 확인하지 못했다**. 입증한 효과는 숨긴 UI 계산 제거다. 전투 p95가 악화한 단일 표본도 있어 전체 전투 성능 향상이나 모든 하드웨어의 무회귀를 주장하지 않는다.

## 3. 이미지 점검

### 범위·추적 방법

PCK 디렉터리를 파싱해 실제 포함된 `.import→.ctex`를 확인했다. PNG1,878개, 원본785.91MiB, PCK 텍스처671.13MiB다. `assets/source/`는 PCK에 없다. 원본 PNG SHA256으로 중복을 비교했다.

[전체1,878개 이미지 CSV](V131_OPTIMIZATION_IMAGES_2026-10-20.csv)에 해상도·PCK 크기·압축·mipmaps·size_limit·해시·참조·관측 표시 배율을 기록했다. 스크립트·씬·JSON의 전체 경로/파일명 사용처를 추적하고 실제 보이는 Sprite2D/TextureRect의 변환 배율을 반영했다. AtlasTexture는 한 프레임과 전체 시트를 혼동하지 않도록 region 대비 표시 배율을 전체 원본에 환산했다. 마진 포함 영역은 보수적인 상한 추정이다.

**118개 이미지의 표시 크기를 관측했고 그중23개가 관측 크기의2배보다 크다.** 나머지1,760개는 해당 장면에서 관측하지 못했다. 모든 화면·확대·언어·장비 해상도의 전역 최대를 확정한 것은 아니다. CSV의 `SAMPLED_*`는 표본 최대, `DYNAMIC_OR_UNSAMPLED`는 미사용 판정이 아니다. StyleBoxTexture/직접 그리기는 노드 표본에서 빠질 수 있어 관련 코드도 대조했다.

### 관측상2배 초과 후보 전체

절감량은 관측 최대2배까지 같은 비율·알파로 줄인다고 가정한 **비압축 RGBA 메모리 추정**이다. 실제 PNG/PCK 절감량이 아니며 전역 최대 미확정 때문에 미채택이다. Atlas는 region/frame_size와 확대 상한을 함께 확인해야 한다.

| 이미지 | 원본px | 관측 환산 최대px | RGBA 절감추정MiB | 미적용 이유 |
|---|---|---|---|---|
| `assets/sprites/v130r/portraits_contract/mimi_determined.png` | 1402×1122 | 100.0×112.0 | 5.76 | 다른 화면·스타일 상한 필요 |
| `assets/ui/uiux/obsidian_button.png` | 2172×724 | 240.0×96.0 | 5.58 | 다른 화면·스타일 상한 필요 |
| `assets/sprites/portraits/uiux3d/pynn_base.png` | 1254×1254 | 192.8×190.6 | 5.43 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/graveyard_hound/graveyard_hound_sheet.png` | 1254×1254 | 415.4×415.4 | 3.37 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/imp/imp_sheet.png` | 1254×1254 | 435.5×435.5 | 3.10 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/war_drummer/war_drummer_sheet.png` | 1254×1254 | 446.3×446.3 | 2.96 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/spore_healer/spore_healer_sheet.png` | 1254×1254 | 459.9×459.9 | 2.77 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_sheet.png` | 1254×1254 | 441.9×478.6 | 2.50 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/bat_courier/bat_courier_sheet.png` | 1254×1254 | 521.1×521.1 | 1.86 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/moon_tracker/moon_tracker_sheet_ne.png` | 1254×1254 | 536.6×500.6 | 1.61 | 아틀라스·확대 상한 필요 |
| `assets/sprites/uiux3d/engineer_sheet.png` | 1244×1264 | 540.8×431.5 | 1.46 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_sheet.png` | 1254×1254 | 546.3×546.3 | 1.44 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/bridge_troll/bridge_troll_sheet.png` | 1254×1254 | 566.5×566.5 | 1.10 | 아틀라스·확대 상한 필요 |
| `assets/sprites/v130r/quarter_final/mimic_porter/mimic_porter_sheet_ne.png` | 1254×1254 | 570.5×570.5 | 1.03 | 아틀라스·확대 상한 필요 |
| `assets/ui/v130r/hpbar/C/portrait_frame.png` | 292×277 | 27.7×29.9 | 0.29 | 다른 화면·스타일 상한 필요 |
| `assets/ui/v130r/hpbar/C/level_badge.png` | 156×154 | 11.7×11.7 | 0.09 | 다른 화면·스타일 상한 필요 |
| `assets/ui/v130r/hpbar/C/status_socket.png` | 118×122 | 10.0×10.0 | 0.05 | 다른 화면·스타일 상한 필요 |
| `assets/ui/kit/icons/icon_speed_64.png` | 64×64 | 4.4×4.4 | 0.02 | 다른 화면·스타일 상한 필요 |
| `assets/ui/kit/icons/icon_garrison_64.png` | 64×64 | 5.0×5.0 | 0.02 | 다른 화면·스타일 상한 필요 |
| `assets/ui/kit/icons/icon_language_128.png` | 128×128 | 56.0×56.0 | 0.01 | 다른 화면·스타일 상한 필요 |
| `assets/ui/kit/icons/icon_food_64.png` | 64×64 | 24.0×24.0 | 0.01 | 다른 화면·스타일 상한 필요 |
| `assets/ui/kit/icons/icon_gold_64.png` | 64×64 | 24.0×24.0 | 0.01 | 다른 화면·스타일 상한 필요 |
| `assets/ui/kit/icons/icon_mana_64.png` | 64×64 | 24.0×24.0 | 0.01 | 다른 화면·스타일 상한 필요 |

`obsidian_button.png` 표본은240×96이지만 392×56 팝업 StyleBox·업적·테마에도 쓰이며 고정18px 소스 마진 경로가 있다. 표본만으로480px까지 줄이면 안 된다. mimi_determined·pynn_base는 카드 외 초상 사용처도 있어 0133 재측정 범위를 지켰다. quarter_final 시트는 몸체 배율과 최대 카메라1.5×ui_unit 때문에 표본 크기가 전역 상한이 아니다.

추가 소형 후보는 `PortraitHealthBar.gd:103~115`의 portrait_frame(26×28), level_badge(11×11), status_socket(8×8)이다. 실제 표시에는 `ui_scale=96/66×크기군`, 카메라, viewport/ui_unit, 군중 축소가 곱해진다. 절감이 작고 고해상도·최대 확대 확인이 남아 이번의 효과 큰 항목으로 채택하지 않았다.

1640×399 resource_plaque 계열은 터치 HUD에서250×62, 날짜판185×62, HP판486×62 논리px다(`HUDController.gd:135~141`). desktop rail은 해당 스킨을 쓰지 않아 데스크톱 검증만으로 축소하지 않았다.

### import·필터

Lossless(mode0)1,878개, mipmaps 없음1,544개/있음334개다. size_limit0은1,866개이고 나머지12개는 기존 제한을 유지했다. 프로젝트 기본은 nearest, Approved 맵/유닛은 linear를 명시하지만 기존 Unit·월드·카드에는 linear_with_mipmaps도 있다. mipmaps 일괄 제거는 다른 경로의 축소 품질을 바꿀 수 있다. VRAM/Lossy 전환도 알파·글자·윤곽 확인이 필요해 미적용했다. 명백한 오류로 확정한 import 설정은 없다.

### 중복·참조 미발견

동일 해시22묶음·여분68파일이다. 모든 경로를 하나로 연결할 경우 이론상 PCK5.42MiB 절감 후보다. 전체 구성원은 CSV의 sha256으로 확인한다. 자동 삭제·대체하지 않았다.

| 대표 경로 | 동일 파일 수 | 여분 PCK 추정MiB |
|---|---|---|
| `assets/maps/v130r_step1/assembled/road_10_10_11_10.png` | 5 | 0.010 |
| `assets/maps/v130r_step1/assembled/road_10_8_10_10.png` | 17 | 0.078 |
| `assets/maps/v130r_step1/assembled/road_11_12_13_12.png` | 7 | 0.030 |
| `assets/maps/v130r_step1/assembled/road_13_10_16_10.png` | 4 | 0.022 |
| `assets/maps/v130r_step1/assembled/road_16_14_24_14.png` | 2 | 0.020 |
| `assets/maps/v130r_step1/assembled/road_18_12_24_12.png` | 2 | 0.015 |
| `assets/maps/v130r_step1/assembled/road_18_7_18_8.png` | 2 | 0.002 |
| `assets/maps/v130r_step1/assembled/road_26_5_30_5.png` | 2 | 0.010 |
| `assets/maps/v130r_step1/assembled/water_10_0_10_18.png` | 3 | 0.076 |
| `assets/maps/v130r_step1/assembled/water_24_0_26_0.png` | 5 | 0.017 |
| `assets/maps/v130r_step1/assembled/water_26_0_26_8.png` | 2 | 0.017 |
| `assets/maps/v130r_step1/assembled/water_26_10_32_10.png` | 2 | 0.013 |
| `assets/maps/v130r_step1/assembled/water_32_8_32_10.png` | 2 | 0.004 |
| `assets/maps/v130r_step1/building/door_arch.png` | 2 | 0.037 |
| `assets/sprites/enemies/enemy_investigator_attack_down_00.png` | 3 | 0.046 |
| `assets/sprites/enemies/enemy_investigator_skill_down_00.png` | 2 | 0.032 |
| `assets/sprites/monsters/monster_kobold_scout_idle_down_00.png` | 2 | 1.580 |
| `assets/sprites/room_markers/marker_recovery_nest_gpt2.png` | 2 | 0.055 |
| `assets/tiles/cave_v2/wall/wall_cave_v2_mask_00.png` | 9 | 0.305 |
| `assets/tiles/cave_v2/wall/wall_cave_v2_mask_01.png` | 9 | 0.212 |
| `assets/ui/dark_fantasy/hp_bar_frame.png` | 3 | 1.146 |
| `assets/ui/dark_fantasy/panel_inspector.png` | 3 | 1.696 |

전체 경로/파일명 리터럴 참조가 없는853개를 추렸다. floor_%s_cells·방향별 도로·애니메이션 등 조합 경로가 있어853개를 미사용이라고 단정하거나 exclude하지 않았다. 아래3개는 경로·파일명·스템 참조를 찾지 못했고 런타임 폴더 열거로 읽는 코드도 발견하지 못한 강한 미사용 후보다. 별도 제외 검토를 추천하되 원본과 설정은 보존했다.

| 포함된 미사용 후보 | PCK MiB | 위험·추천 |
|---|---|---|
| `assets/sprites/concept_asset_sheet.png` | 1.433 | 낮음~중간: 조합 경로 확인 뒤 삭제 없이 제외 검토 |
| `assets/sprites/animation_gpt2/gpt2_character_animation_sheet.png` | 1.377 | 낮음~중간: 조합 경로 확인 뒤 삭제 없이 제외 검토 |
| `assets/ui/dark_fantasy/ui_skin_atlas_imagen2_source.png` | 1.393 | 낮음~중간: 조합 경로 확인 뒤 삭제 없이 제외 검토 |

### PCK 파일 상위30

가능한 항목은 .ctex를 원본 경로로 역추적했다. PCK 안 데이터 크기이며 원본 PNG 크기가 아니다. 폰트·음원도 포함한다.

| 순위 | 파일 | PCK MiB |
|---|---|---|
| 1 | `assets/fonts/NotoSansCJKkr-Regular.otf` | 13.771 |
| 2 | `assets/maps/v130r_step10/floor_c_cells.png` | 11.466 |
| 3 | `assets/maps/v130r_step10/floor_d_cells.png` | 8.533 |
| 4 | `assets/maps/v130r_step2/road_cells.png` | 6.943 |
| 5 | `assets/maps/v130r_step2/floor_cells.png` | 6.417 |
| 6 | `assets/maps/v130r_step2/water_cells.png` | 5.405 |
| 7 | `assets/maps/v130r_step1/terrain/ground_unique_field.png` | 4.818 |
| 8 | `assets/audio/bgm/v130/combat_02_wardstone_relay.ogg` | 3.530 |
| 9 | `assets/audio/bgm/v130/final_ending_01_one_throne_many_paths.ogg` | 3.485 |
| 10 | `assets/sprites/uiux3d/slime_gate_bulwark_sheet.png` | 3.115 |
| 11 | `assets/audio/bgm/v130/management_01_blueprint_shuffle.ogg` | 3.097 |
| 12 | `assets/audio/bgm/v130/title_02_crooked_banner.ogg` | 3.053 |
| 13 | `assets/audio/bgm/v130/final_ending_04_last_candle_dawn.ogg` | 3.049 |
| 14 | `assets/audio/bgm/v130/combat_01_corridor_counterattack.ogg` | 3.010 |
| 15 | `assets/audio/bgm/v130/final_ending_02_home_after_siege.ogg` | 3.006 |
| 16 | `assets/ui/v1213/title_monster_court.png` | 2.981 |
| 17 | `assets/sprites/portraits/uiux_evolution/wounded.png` | 2.973 |
| 18 | `assets/sprites/portraits/uiux_evolution/portraits.png` | 2.971 |
| 19 | `assets/audio/bgm/v130/management_03_market_receipts.ogg` | 2.956 |
| 20 | `assets/sprites/portraits/uiux_evolution/victory.png` | 2.915 |
| 21 | `assets/audio/bgm/combat_late_siege_pressure.ogg` | 2.885 |
| 22 | `assets/audio/bgm/v130/final_ending_03_truce_lanterns.ogg` | 2.881 |
| 23 | `assets/audio/bgm/v130/title_01_lantern_gate.ogg` | 2.839 |
| 24 | `assets/sprites/uiux3d/crown_pudding_royal_bastion_sheet.png` | 2.814 |
| 25 | `assets/audio/bgm/combat_dungeon_pressure.ogg` | 2.737 |
| 26 | `assets/sprites/uiux3d/imp_ember_shaman_sheet.png` | 2.705 |
| 27 | `assets/sprites/portraits/uiux_crowns/core.png` | 2.704 |
| 28 | `assets/audio/bgm/v130/result_02_mended_flags.ogg` | 2.685 |
| 29 | `assets/audio/bgm/final_ending_crown_of_ashes.ogg` | 2.683 |
| 30 | `assets/audio/bgm/v130/title_03_moon_clock.ogg` | 2.664 |

### PCK 폴더 상위30

전체 PCK 파일을 같은 원본 대응 폴더에 합산했다. 대응 없는 엔진 생성 리소스는 PCK 폴더로 남겼다. 부모·자식 누적 중복 없이 직접 포함 파일 기준이다.

| 순위 | 폴더 | PCK MiB |
|---|---|---|
| 1 | `assets/sprites/uiux3d` | 113.750 |
| 2 | `assets/props/uiux` | 74.743 |
| 3 | `assets/sprites/portraits/uiux3d` | 46.664 |
| 4 | `assets/audio/bgm/v130` | 44.139 |
| 5 | `assets/sprites/portraits/onboarding` | 39.027 |
| 6 | `assets/sprites/portraits/evolution` | 23.308 |
| 7 | `assets/maps/v130r_step10` | 21.165 |
| 8 | `assets/maps/v130r_step2` | 18.807 |
| 9 | `assets/ui/endings` | 18.033 |
| 10 | `assets/audio/bgm` | 16.082 |
| 11 | `assets/sprites/portraits/uiux_evolution` | 15.801 |
| 12 | `assets/fonts` | 14.551 |
| 13 | `assets/ui/endings/update4` | 13.864 |
| 14 | `assets/props/stage_04` | 13.683 |
| 15 | `assets/achievements/v130/icons_jpg` | 12.828 |
| 16 | `assets/achievements/v130/icons` | 11.971 |
| 17 | `assets/sprites/v130r/portraits_contract` | 11.941 |
| 18 | `assets/audio/ambience` | 10.330 |
| 19 | `assets/sprites/enemies` | 9.537 |
| 20 | `assets/sprites/portraits/uiux_crowns` | 9.461 |
| 21 | `assets/ui/dark_fantasy` | 9.407 |
| 22 | `assets/sprites/enemies/update4/region` | 9.276 |
| 23 | `assets/dungeon_quarter/prepared_maze` | 8.865 |
| 24 | `assets/sprites/monsters` | 8.645 |
| 25 | `assets/props/stage_03` | 8.527 |
| 26 | `assets/sprites/dungeon_quarter/modules` | 8.352 |
| 27 | `assets/props/stage_01` | 7.215 |
| 28 | `assets/maps/v130r_step1/terrain` | 6.628 |
| 29 | `assets/sprites/enemies/update3_atlas` | 6.386 |
| 30 | `assets/sprites/portraits/campaign` | 6.089 |

NotoSansCJKkr는 중국어 대체 글꼴로 실제 사용하므로 제거하지 않았다. 기본·대화 글꼴은 NEXON MapleStory Light/Bold 그대로다.

## 4. 코드 점검·위험도·추천

246개 GDScript에서 _process11개, _physics_process4개, _draw 선언18개, queue_redraw83곳을 조사했다. 선언/호출 지점 수가 실제 프레임 실행 횟수는 아니다. _draw에는 일반 보조 함수도 포함한다. 읽기 전용 조사 보조1명은 코드만 읽었으며 Godot·이미지·파일 수정은 하지 않았다. 전체 검수 에이전트가 아니다.

| 항목·근거 | 판정·변경 위험 | 처리·추천 |
|---|---|---|
| ApprovedBattleUI:153 숨긴 view의 위치/체력표/상태 갱신 | 확정/낮음 | 적용. 비시각 tick 뒤 실제 가시성 검사 |
| SpectatorCameraDirector:65~104 유닛 배열·Dictionary·점수·redraw | 실행 확정, 불필요성 조건부/중간 | 미적용. Approved 카메라 소유권·구 전투 복귀·수동 입력부터 검증 |
| ApprovedPlacementView:107,213,361 숨긴 resize 재구성·미니맵 읽기 | 확정/중간 | dirty 표시 후 복귀 직전 최종 크기로 한 번 구성 추천 |
| FacilityPreview:13 비월드 카드 폴링·문자열 키 | 숨긴 존속 조건부/낮음~중간 | 가시성·선택·그래프 변경 때 갱신 추천 |
| ApprovedBattleUI:102, ApprovedPlacementView:325 find_child·문자열·지갑10Hz | 확정/낮음 | 라벨 캐시·값 변경 갱신, locale/배율/재구성 무효화 필요 |
| ApprovedBattleUnit:246와 전투 UI의 실루엣 갱신 | 경로 확정, 중복 필요성 추정/중간 | 물리·시각 프레임 차이를 보존하고 표시 갱신 소유자 정리 |
| Unit:459 queue_redraw, ApprovedBattleUnit._draw는 pass | 확정/낮음~중간 | 새 맵 사용자 정의 그리기 여부로 분기 검토 |
| CombatSceneController:331 스냅샷, ApprovedBattleController:219 배열 결합, Unit:398 keys | 확정/중간~높음 | 유닛 생성/제거·재진입 순회 안전성을 보존하는 별도 작업 |
| DataRegistry:90와 GameRoot:540 load_all 두 번 | 확정/낮음~중간 | 일반 ensure_loaded와 명시적 재로딩 분리. 이번 허용 종류 밖이라 유지 |
| DataRegistry:633~634 skills_new JSON 두 번 파싱 | 확정/낮음 | 파싱 결과 재사용 추천, 이번 유지 |
| DataRegistry:139~181 전체/개별 카탈로그 깊은 복사 | 확정/중간 | 읽기 전용/가변 소유권 확정 뒤 복사 축소 |
| GameRoot:4204~4307 구 맵·효과 프레임 선행 로드 | 로드 확정, 불필요 범위 미확정/중간 | renderer별 준비 분리. preload를 매 프레임 디스크 읽기로 오인하지 않음 |
| QuarterDungeonWallCanvas→PreparedMazeActorDepth:157 | 조기 종료 확인 | 숨긴 월드는 배열 생성 전 종료. 깊이/컬러/미니맵 UPDATE_ONCE 유지 |

음악 Timer는 한 개이며 종료 때 정지한다. combat Tween은 정리·finished 제거 경로가 있다. TutorialButtonGlow는 중복 부착 방지·dismiss kill이 있고 숨긴 부모의 맥동은 조건부 낭비 후보다. 지원/특화/합동기 역참조에는 WeakRef가 있다. Steam 초기화 재호출은 중복 연결 위험이 있으나 정상 경로 반복 호출은 찾지 못했다. Steam 콜백·업적 저장을 가시성으로 중단하지 않는다.

**무한 이벤트/메모리 누수는 확정하지 못했다.** ObjectDB 종료 경고는 수정 전 탐색run2·수정 후 최종run1·0133 재측정에서 관측했다. 최종 수정 전run3·직접10검사·수동 전후·기존 UI/대화 검사는 경고0이었다. 원인 미확정이며 해결됐다고 기록하지 않는다. 장시간 반복 진입의 누수 검사는 미실행이다.

GameRoot는16,656행/1,078함수, CombatSceneController는8,163행/393함수다. 저장/복원·맵 편집·성장/시설·화면 전환, 전투 공통 단계/공간 탐색/표시 어댑터 분리를 추천한다. 변경 위험이 높고 AI0.12초 간격·호출 순서·구 저장 호환성을 보존해야 하므로 이번에는 분리하지 않았다.

외부 참조 미발견 후보는 GameRoot의 _clear_ui(11625), _build_management_ui(11628), _spawn_monsters(12375), 13685/13688와16350~16381의 전달 함수, CombatSceneController:7972/7975 피해 숫자 전달이다. _rebuild_combat_ui_light(11664)는 효과 없는 본문이다. Callable(root,callback_name)·데이터 action.callback·root.call이 있어 고정 참조0회가 삭제 안전을 뜻하지 않는다. 모두 유지했다.

## 5. Windows 전후 실측

Godot4.6.3 Windows release EXE, Vulkan/Forward+, RTX3060Ti, 실제 창/렌더1920×1080, VSync·기존 max_fps120 유지. 전후 QA autoload·호출 계수기는 바이트 동일하다. 제품 차이는 가시성 조건뿐이다.

최종은 before run3/after run1 각 독립1기동이다. 타이틀4초→관리4초→DAY27 전투18초→설정4초→복귀 전투4초→의회 DAY2 관리4초→전투14초. 탐색run1은1280×720이라 제외했고 run2도 요약에 합치지 않았다. frame_post_draw 간격·nearest-rank p95이며 GPU 단독 시간이나 입력 지연이 아니다.

수치는 그대로인 QA 신규 프로필/해금 fixture, seed131004다. DAY27 실제13명 예정 웨이브 중 관측 최대9명, 의회 cycle3/DAY2 실제 최대4명이다. QA는 진행 잠금·준비 UI를 건너뛰고 기존 ApprovedBattleController와 정상 physics를 실행한다. 실제30일 세이브나 모든 적 동시 생존의 최악 조건으로 일반화하지 않는다. council mode/day_state도 확인했다.

### 장면별 FPS·프레임·메모리·draw call

메모리는 renderer video memory 평균이며 아래 프로세스 Working Set/Private peak와 별개다. draw call은 프레임 평균이다.

| 장면 | FPS 전→후 | 평균ms 전→후 | p95ms 전→후 | 최대ms 전→후 | GPU MiB 전→후 | draw call 전→후 |
|---|---|---|---|---|---|---|
| 타이틀 | 60.00→59.93 | 16.667→16.686 | 22.745→24.104 | 26.280→26.883 | 634.7→634.7 | 12.0→12.0 |
| DAY27 관리 | 60.07→59.97 | 16.646→16.674 | 20.071→20.267 | 20.673→24.157 | 1006.0→1006.0 | 2561.0→2561.0 |
| DAY27 전투 | 59.77→59.89 | 16.732→16.698 | 33.110→36.960 | 106.602→94.062 | 1189.8→1189.8 | 2723.0→2723.3 |
| 숨긴 전투·설정 | 59.99→59.98 | 16.669→16.672 | 22.226→23.074 | 24.540→27.562 | 1195.4→1195.4 | 105.0→105.0 |
| 같은 전투 복귀 | 59.74→60.02 | 16.738→16.661 | 40.384→38.873 | 55.691→55.032 | 1186.8→1186.8 | 792.7→795.9 |
| 의회 DAY2 관리 | 60.07→59.98 | 16.646→16.674 | 20.412→20.132 | 24.145→22.509 | 1125.8→1125.8 | 2375.0→2375.0 |
| 의회 DAY2 전투 | 60.03→60.10 | 16.657→16.638 | 20.452→20.516 | 55.123→48.893 | 1148.0→1148.0 | 2484.9→2484.9 |

### 시작·프로세스 메모리·PCK

| 지표 | 전 | 후 | 해석 |
|---|---|---|---|
| 첫 타이틀 draw / ms | 5637.000 | 5662.000 | 엔진 tick 기준·GPU/OS 초기화 포함 |
| DataRegistry 두 번 합계 / ms | 61.321 | 62.333 | autoload와 GameRoot 각각 약31ms |
| 초기 _load_textures / ms | 208.915 | 203.457 | 이미지·프레임 선행 준비 |
| Working Set peak / MiB | 872.785 | 909.113 | psutil100ms 간격 전체 실행 최고 |
| Private committed peak / MiB | 2318.273 | 2345.488 | 물리 RAM 상주량과 다름 |
| QA PCK / bytes | 819351896.000 | 819352200.000 | +304bytes. Steam 배포 패키지 아님 |

이미지/import가 같아 텍스처671.13MiB·GPU 평균·draw call은 실질적으로 같다. Working Set 최고는약36.33MiB 늘었다. 단일 기동·OS/driver/할당/수집 상태가 섞인 결과여서 가시성 조건의 메모리 효과로 해석하지 않는다. DAY27 p95는33.110→36.960ms로 개선하지 못했고 최대 지연은106.602→94.062ms다. 별도 장기 성능 목표 통과를 선언하지 않는다.

숨긴 UI4초에서 position_skills240→0, layout_vitals240→0, refresh34→0이다. 복귀 뒤에는241/241/35회로 정상 재개했다.

### 0133은 재측정만

GameRoot·StoryDialoguePresenter가0133 제품SHA `4ef749ba`와 동일함을 Git으로 확인했다. 기존0133 QA release EXE를 새 프로필로 재실행했으며 새 최적화 QA EXE와 구분한다. 대화 제품 코드는 수정하지 않았다.

넘김121회 정지 평균0.571ms/p951.083ms/최대2.240ms, 관측 최대 프레임24.505ms다. 첫 진입176.179ms·로그 열기68.805ms는 별도 비용으로 유지한다. 기능70검사·본문 재사용 통과. 기존0133 독립2회 표와 표본 수가 달라 추가 최적화 효과로 비교하지 않는다.

## 6. 검증·변경 파일·그래픽

| 검증 | 결과 | 근거(ignored tmp) |
|---|---|---|
| Windows release export 전후 | exit0·오류0·경고0 | v131_optimization/export-before.json·export-after.json |
| 새 EXE 직접 회귀 | 10검사 실패0·경고0 | checks-after-1.log: 숨김/시각 갱신0/정지/동일 전투 복귀/알림/DAY29 |
| 기존 UI 회귀 | 1,917검사 실패0·경고0 | test-V131UIFeedbackTest.log |
| 기존 대화 재사용 | 237검사 실패0·경고0 | test-V131DialogueReuseTest.log |
| 0133 대화 재측정 | 143표본/넘김121회, 기능70검사 실패0 | v131_dialogue_perf/bench-after-opt-20261020.log·프로필 benchmark.json |
| 전후7장면 | 각1기동 실패0·1920×1080 | comparison.json·profiles/run-before-3·run-after-1 |
| 실제 EXE Computer Use | 관리→배치 탭 실제 클릭→전투, 전후 정상 종료0 | manual-before-1.json·manual-after-1.json. fixture 진입QA F6, 기준판 pause 실제 클릭도 확인 |
| 이미지/PCK | 1,878개 고유 실제 경로 확인 | 전체CSV·inventory/audit/pck JSON |
| Python·Git | py_compile·diff --check 통과 | 로컬 실행 |
| 보호 경로 | waves/UIFont/fonts/project/export 설정 Git 동일 | diff --exit-code 통과 |
| 전체 회귀·전체 플레이·전체 검수 | NOT_REQUESTED | 미실행 |
| Android APK 재빌드 | 이번 A.1~3 범위 밖, 미실행 | 기존 APK 유지 |

직접 이미지 열람7/15장, Computer Use 창 캡처902px 이하. 전체 캡처20장 이내(QA 비교/탐색12+Computer Use7+대화QA1), 모두960px 이하. 원본 게임 이미지 직접 열람·새 image_gen·절차적 그림/필터 생성0. 이미지·오디오·SOURCE.md 변경0. 기존 GPT 자산을 사용하며 NEXON MapleStory를 유지했다.

| 변경 파일 | 목적 |
|---|---|
| scripts/ui/ApprovedBattleUI.gd | 숨긴 전투 view 시각 갱신만 차단 |
| tools/run_v131_optimization.py | 격리 사본·직렬 실행·PCK/PNG 전수 목록·메모리·요약 |
| tools/tests/V131OptimizationProbe.gd | QA 사본 전용7장면·10 직접 검사·수동 fixture |
| docs/handoff/V131_OPTIMIZATION_IMAGES_2026-10-20.csv | 이미지 전체 근거 |
| 이 문서·docs/handoff/CURRENT.md | 결과·제한·다음 진입점 |

### 정책 CI용 최종 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 7f1a4d224587bc6fa7fef1ea74fd143b1d7b03b1
- Review range: f3a0c617288f83758db83cc4974fb280569f7fbe..7f1a4d224587bc6fa7fef1ea74fd143b1d7b03b1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 작업트리·제한·다음 순서

기존 mawangseong-action 혼합 변경은 보존하고 이미 존재한 별도 패치 작업트리에서만 작업했다. Steam-1.3.0-Ready·사용자 저장 원본 수정/조회0. 새 APPDATA/LOCALAPPDATA만 사용하고 MAWANG_DISABLE_STEAM=1을 적용했다. Steam 로그인/업로드/Steamworks·push/fetch/PR/태그/main0. 빌드/PCK/로그/캡처는 ignored tmp에만 있으며 커밋하지 않았다. Godot/게임 직렬 최대1, 종료0을 확인했다.

최종 제품·검증 SHA 이후에는 인계·CSV·CURRENT만 커밋한다. 원격 최신성·종료 ObjectDB 경고 원인·이미지 전역 표시 상한은 미확정이고 장기 성능은 미검증이다. 공개 출시나 전체 성능 보증이 아니다.

**사용자 확인 대기.** 후속 추천은 (1) 참조 미발견 생성시트3개 export 제외 검토, (2) DataRegistry 초기화 소유권 정리, (3) Approved/구 관전 카메라 소유권 검증, (4) 최대 확대·다른 화면을 포함한 이미지 상한 확정 순이다. 각각 별도 범위에서 관련 검사·실제 표시 확인 후 결정한다. 0135 밸런스·난이도·출시 패키지는 자동 진행하지 않는다.
