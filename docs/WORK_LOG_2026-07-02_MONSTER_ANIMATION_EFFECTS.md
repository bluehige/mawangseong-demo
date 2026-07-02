이 파일이 왜 필요한지: 2026-07-02 몬스터 애니메이션과 스킬 이펙트를 점검하고 부족한 프레임/코드 연결을 보강한 내역을 핸드오프와 별도로 백업한다.

# 작업 로그: 몬스터 애니메이션과 스킬 이펙트 보강

작성일: 2026-07-02

## 요청

- 몬스터 애니메이션과 스킬 이펙트를 확인.
- 어느 정도 만들어진 것은 확인했으니, 더 해야 하는 부분이 있으면 추가 제작해서 기록.

## 확인한 상태

- 몬스터 에셋은 `idle_down`, `move_down`, `attack_down`, `skill_down`, `down` 슬롯을 갖고 있었다.
- `Unit.gd`는 `_00~_07` 프레임을 자동으로 읽을 수 있어 구조는 준비되어 있었다.
- 실제 파일은 몬스터 3종 모두 액션당 `_00` 1프레임 중심이라 움직임이 제한적이었다.
- 스킬 이펙트는 `fx_fireball_00`, `fx_hit_slash_00`, `fx_fire_impact_00` 1프레임 텍스처를 `Sprite2D` + tween으로 표시하고 있었다.
- 슬라임 점액 방패, 슬라임 통로 막기, 고블린 약탈 본능은 별도 버프 이펙트가 없었다.
- 화염구 착탄 이펙트는 기존 코드에서 투사체 도착 후가 아니라 발사 직후 생성되는 흐름이었다.

## 판단

- 새 생성형 이미지 시트를 다시 만들면 기존 캐릭터 외형이 흔들릴 가능성이 있다.
- 기존 PNG를 기반으로 스케일, 회전, 위치, 투명도, 색 보정, 링/스파크를 더하는 파생 프레임 방식이 현재 데모에는 더 안정적이다.
- 따라서 `imagegen`으로 새 이미지를 생성하지 않고, `tools/generate_animation_variants.py`로 결정론적 파생 프레임을 만들었다.

## 구현 내용

- `tools/generate_animation_variants.py`
  - 몬스터 `_00` 프레임에서 추가 프레임 생성.
  - 스킬 이펙트 추가 프레임 생성.
  - `tmp/asset_previews/monster_animation_variants.png`, `tmp/asset_previews/skill_effect_variants.png` 미리보기 시트 생성.

- 몬스터 프레임
  - 슬라임, 고블린, 임프 대상.
  - `idle_down`: 2프레임.
  - `move_down`: 4프레임.
  - `attack_down`: 4프레임.
  - `skill_down`: 4프레임.
  - `down`: 2프레임.

- 스킬 이펙트 프레임
  - `fx_fireball_00~03.png`
  - `fx_hit_slash_00~03.png`
  - `fx_fire_impact_00~03.png`
  - `fx_shield_pulse_00~03.png`
  - `fx_guard_pulse_00~03.png`
  - `fx_loot_spark_00~03.png`

- `scripts/game/GameRoot.gd`
  - `effect_frame_sets` 추가.
  - `fx_*_00~07.png`를 자동으로 읽는 `_load_effect_frames()` 추가.

- `scripts/game/CombatSceneController.gd`
  - 화염구, 베기, 충격 이펙트를 `AnimatedSprite2D`로 재생.
  - 점액 방패, 통로 막기, 약탈 본능에 버프 이펙트 연결.
  - 화염구 착탄 이펙트를 투사체 도착 후 생성하도록 수정.

- `tools/DemoSmokeTest.gd`
  - 몬스터 이동/공격/스킬 다중 프레임 검증 추가.
  - 화염구/방어 스킬 이펙트 다중 프레임 검증 추가.
  - 방어 스킬 사용 시 이펙트 노드가 생성되는지 검증 추가.

## 검증 결과

명령:

```powershell
python tools/generate_animation_variants.py
```

결과:

- 몬스터 파생 프레임과 스킬 이펙트 프레임 생성 성공.
- 미리보기 시트 생성:
  - `tmp/asset_previews/monster_animation_variants.png`
  - `tmp/asset_previews/skill_effect_variants.png`

명령:

```powershell
godot --headless --path . --import
```

결과:

- 종료 코드 0
- 신규 PNG와 `.import` 파일 생성 확인.

명령:

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

결과:

- 종료 코드 0
- `DEMO_SMOKE_TEST: PASS`
- 추가 검증 통과:
  - 몬스터 이동 애니메이션 다중 프레임
  - 몬스터 공격 애니메이션 다중 프레임
  - 몬스터 스킬 애니메이션 다중 프레임
  - 화염구 이펙트 다중 프레임
  - 방어 스킬 이펙트 다중 프레임
  - 방어 스킬 이펙트 생성

## 남은 판단 사항

- 실제 전투 화면에서 새 프레임의 흔들림이 과하지 않은지 확인해야 한다.
- 버프 이펙트가 유닛과 체력바를 너무 가리면 크기나 alpha를 낮춘다.
- 적 캐릭터는 아직 1프레임 중심이다. 다음 단계에서 적까지 같은 방식으로 확장할지 판단한다.
- `tools/generate_animation_variants.py`는 생성 규칙을 재실행할 수 있게 남겨두었다. 수치를 바꾸면 PNG를 다시 생성한 뒤 Godot import를 다시 실행해야 한다.
