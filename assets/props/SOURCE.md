이 파일이 왜 필요한지: 쿼터뷰 던전의 object slot prop/trap PNG가 어떤 생성 이미지에서 나왔고 어떻게 잘려 들어갔는지 남겨, 이후 같은 기준으로 재생성하거나 교체할 수 있게 한다.

# Quarter-View Prop Source

## 생성 원본

GPT 이미지 생성으로 제작한 4x4 prop atlas를 사용했다.

```text
C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_06d858dced7de545016a4654ac26d48191b798d3155a492f9e.png
```

프로젝트에 보존한 원본 atlas:

```text
assets/props/gpt2_dungeon_props_source_atlas.png
```

## 후처리 규칙

- 초록 배경을 투명 alpha로 변환했다.
- 4x4 atlas를 셀 단위로 자르고, 실제 prop 픽셀만 trim했다.
- 왕좌와 입구문처럼 큰 구조물은 렌더러에서 화면 비율에 맞게 축소한다.
- 바닥 함정과 건설 룬은 바닥에 낮게 깔리도록 `floor_center` 성격으로 맞췄다.

## 최종 파일

```text
assets/props/gate/prop_entrance_gate_f_back.png
assets/props/decor/prop_small_brazier_back.png
assets/props/throne/prop_throne_f_back.png
assets/props/throne/prop_throne_f_front.png
assets/props/treasure/prop_treasure_pile_large_front.png
assets/props/barracks/prop_weapon_rack_cave_f_back.png
assets/props/recovery/prop_recovery_nest_f_front.png
assets/props/build/prop_foundation_marks_back.png
assets/props/traps/trap_spike_idle_00.png
assets/props/traps/trap_spike_trigger_00.png
assets/props/traps/trap_spike_trigger_01.png
assets/props/traps/trap_spike_trigger_02.png
assets/props/traps/trap_spike_trigger_03.png
```

## 렌더러 연결

- `asset_manifest.json`에 `entrance_gate_f`, `small_brazier`, `foundation_marks`를 추가했다.
- 기존 `throne_f`, `treasure_pile_large`, `weapon_rack`, `recovery_nest_f`, `spike_floor`도 실제 PNG 경로로 연결했다.
- `QuarterDungeonRenderer.gd`가 prop/trap 텍스처를 로드하고 `object_slots` 위치에 그린다.
- 누락 파일은 `debug_missing_object_sprites()`로 확인한다.
- `QuarterModuleSmokeTest.gd`가 prop/trap 텍스처 로딩을 검증한다.
