이 파일은 전투 스킬 이펙트 프레임의 생성 방식과 사용처를 남기기 위해 필요하다.

# 전투 스킬 이펙트 리소스

작성일: 2026-07-02

## 생성 방식

- 기본 이펙트 원본:
  - `fx_fireball_00.png`
  - `fx_hit_slash_00.png`
  - `fx_fire_impact_00.png`
  - `fx_selection_ring_00.png`
- 추가 프레임 생성:
  - `tools/generate_animation_variants.py`
- 생성형 이미지 재호출 없이 기존 PNG를 기반으로 스케일, 회전, 투명도, 색 보정, 링/스파크 드로잉을 적용했다.
- 이유:
  - 기존 데모 스타일과 캐릭터 외형을 유지하기 위해서.
  - Godot가 이미 `_00`, `_01` 형식의 프레임 파일을 자동으로 읽는 구조와 맞추기 위해서.

## 현재 프레임 구성

- `fx_fireball_00~03.png`: 임프 화염구 투사체
- `fx_hit_slash_00~03.png`: 고블린 빠른 베기/기본 근접 타격
- `fx_fire_impact_00~03.png`: 화염구 착탄, 화염 지대, 함정 피해, 용사 돌진 충격
- `fx_shield_pulse_00~03.png`: 슬라임 점액 방패
- `fx_guard_pulse_00~03.png`: 슬라임 통로 막기
- `fx_loot_spark_00~03.png`: 고블린 약탈 본능
- `fx_selection_ring_00.png`: 선택 링. 현재 다중 프레임 재생에는 연결하지 않았다.

## 코드 연결

- `scripts/game/GameRoot.gd`
  - `effect_textures`: 첫 프레임 fallback 텍스처
  - `effect_frame_sets`: `_00~_07` 프레임 시퀀스 로더
- `scripts/game/CombatSceneController.gd`
  - 화염구, 베기, 충격, 방어막, 가드, 약탈 스파크를 `AnimatedSprite2D`로 재생한다.

## 검증

```powershell
godot --headless --path . --import
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

검증 항목:

- 화염구 이펙트 다중 프레임
- 방어 스킬 이펙트 다중 프레임
- 방어 스킬 이펙트 생성
- 임프 화염구 투사체 생성
