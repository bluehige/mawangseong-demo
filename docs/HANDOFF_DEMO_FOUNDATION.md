# 마왕성 데모 기초 완성 핸드오프

작성일: 2026-07-01

## 1. 목표

현재 폴더의 기획서(`mawang_topview_demo_spec.md`)와 3개 UI 참고 이미지 기준으로 Godot 4.5용 탑뷰 마왕성 방어 데모의 기초를 구성했다.

이번 세션의 목표는 완성 게임이 아니라, 다음 요소가 실제 프로젝트 안에서 연결된 데모 기반을 만드는 것이다.

- Godot 프로젝트 실행 구조
- 관리 화면, 몬스터 관리 화면, 전투 화면, 결과 화면의 기본 흐름
- 3일 웨이브 루프
- 몬스터 3종, 적 3종 데이터
- RoomGraph 기반 방 이동
- 자동 전투, HP 감소, 격퇴, 보상 계산
- 전체 지침, 방 지침, 직접 조종, 기본 스킬
- 참고 이미지 분위기에 맞춘 프로젝트 내 PNG 리소스

## 2. 현재 프로젝트 구조

중요 파일:

- `project.godot`
- `scenes/main/Main.tscn`
- `scenes/game/GameRoot.tscn`
- `scripts/game/GameRoot.gd`
- `scripts/units/Unit.gd`
- `scripts/map/RoomGraph.gd`
- `scripts/combat/DamageService.gd`
- `scripts/combat/TargetingService.gd`
- `scripts/combat/DirectiveManager.gd`
- `scripts/combat/WaveManager.gd`
- `scripts/core/GameState.gd`
- `scripts/core/SignalBus.gd`
- `scripts/core/DataRegistry.gd`
- `data/rooms.json`
- `data/monsters.json`
- `data/enemies.json`
- `data/skills.json`
- `data/waves.json`
- `tools/generate_demo_assets.py`
- `assets/sprites/concept_asset_sheet.png`

`Main.tscn`은 `GameRoot.tscn`을 인스턴스하고, 실제 데모 로직은 현재 `GameRoot.gd`가 관리한다. 이후 안정화가 끝나면 기획서의 `CombatScene`, `ManagementScene`, `HUD` 등으로 분리하면 된다.

## 3. 구현된 플레이 흐름

1. 프로젝트 시작 시 관리 화면이 열린다.
2. 방을 클릭하면 선택 방 정보가 갱신된다.
3. 건설 슬롯을 선택하고 `건설`을 누르면 감시 초소로 변경된다.
4. `몬스터` 화면에서 슬라임, 고블린, 임프를 확인하고 훈련/배치할 수 있다.
5. `방어 준비`를 누르면 현재 일차 웨이브가 시작된다.
6. 전투 중 적은 입구에서 스폰되어 목표 방으로 이동한다.
7. 몬스터는 지침에 따라 적을 추적하거나 배치 방으로 복귀한다.
8. 가시 복도는 적에게 피해와 둔화를 준다.
9. 임프는 원거리 투사체 시각 효과를 낸다.
10. 적을 모두 격퇴하면 결과 화면이 열린다.
11. 3일차를 클리어하면 `데모 클리어`가 표시된다.
12. 마왕성 체력이 0이 되면 방어 실패로 종료된다.

## 4. 조작

- 좌클릭: 방 선택 또는 유닛 선택
- 우클릭: 직접 조종 중인 몬스터 이동 명령
- Space: 전투 일시정지/재개
- Tab: 다음 살아있는 몬스터 선택
- 1, 2, 3: 선택 몬스터 스킬 슬롯 사용
- 전투 UI 버튼: 전체 지침, 방 지침, 직접 조종, 속도 변경

## 5. 그래픽 리소스

생성된 리소스 수: PNG 32개

2026-07-01 추가 수정:

- 기존 절차 생성 플레이스홀더 대신 gpt-image-2 생성 경로로 핵심 리소스를 재제작했다.
- 교체 완료: 몬스터 3종, 적 3종, 주요 방 오브젝트 9종, 타일 3종, 전투 효과 4종.
- 생성 원본은 `C:\Users\LDK-6248\.codex\generated_images\019f1cd9-8aef-7913-b090-09c2aef43fcd` 아래에 남아 있다.
- 프로젝트 사용본은 크로마키 제거 및 128x128 또는 64x64 후처리 후 `assets/sprites` 아래 기존 파일명으로 덮어썼다.
- `tmp/imagegen/current_asset_preview_full.png`에서 교체된 리소스 프리뷰를 확인할 수 있다.

주요 리소스:

- 몬스터: `monster_slime_idle_down_00.png`, `monster_goblin_idle_down_00.png`, `monster_imp_idle_down_00.png`
- 적: `enemy_explorer_idle_down_00.png`, `enemy_thief_idle_down_00.png`, `enemy_trainee_hero_idle_down_00.png`
- 타일: `tile_cave_floor_01.png`, `tile_cave_wall_top_01.png`, `tile_spike_floor_01.png`
- 방 오브젝트: 왕좌, 보물, 병영, 회복 둥지, 입구, 건설 슬롯, 감시 초소
- 효과: 화염구, 타격, 화염 충돌, 선택 링
- UI 아이콘: 금화, 마력, 식량, 악명, 지침 아이콘
- AI 콘셉트 시트: `assets/sprites/concept_asset_sheet.png`

리소스는 `tools/generate_demo_assets.py`로 다시 생성할 수 있다.

AI 콘셉트 시트 생성 프롬프트 요약:

```text
Cute horror fantasy demon castle defense game, six isolated SD top-down characters:
blue slime tank, green goblin dagger fighter, red imp fire caster,
human explorer, hooded thief, trainee hero.
Clean hand-painted indie game concept art, purple rim light, warm fire highlights,
no text, no logo, no UI panels.
```

## 6. 검증 결과

완료:

- JSON 파싱 확인 완료
- `project.godot`, 메인 씬, 게임 루트 씬 존재 확인 완료
- `.gd` / `.tscn` 내부 `preload` 및 씬 참조 경로 확인 완료
- 데이터와 스크립트가 참조하는 주요 PNG 파일 생성 완료
- 참고 이미지 3개 확인 완료
- AI 콘셉트 시트 복사 완료

현재 확인:

- Godot 4.5.2 실행 파일은 `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\nanpa\tools\godot\Godot_v4.5.2-stable_win64.exe`에 있다.
- 사용자 PATH에 Godot 폴더를 추가했고, 현재 세션에서도 `godot` 명령이 동작하도록 `C:\Users\LDK-6248\AppData\Roaming\npm\godot.cmd` shim을 추가했다.
- `godot --version` 출력: `4.5.2.stable.official.6ce3de25a`
- 아직 프로젝트 자체를 Godot로 열어 씬 실행 검증은 하지 않았다.

다음 세션의 첫 작업은 Godot 4.5에서 `project.godot`를 열고 import가 끝난 뒤 실행하는 것이다.

## 7. 다음 세션 우선순위

1. Godot 4.5로 프로젝트 열기
2. 에셋 import 완료 대기
3. `Main.tscn` 실행
4. 파서/런타임 오류가 있으면 먼저 수정
5. 관리 화면에서 `방어 준비`까지 클릭 흐름 확인
6. 전투에서 적 스폰, 몬스터 이동, 공격, 결과 화면 확인
7. 직접 조종과 스킬 1/2 입력 확인
8. UI가 겹치거나 텍스트가 넘치는 부분 조정
9. `GameRoot.gd`를 `ManagementScene`, `CombatScene`, `HUD` 단위로 분리
10. 캐릭터를 단일 idle 이미지에서 SpriteFrames 애니메이션으로 확장

## 8. 현재 리스크

- Godot 실행 파일은 확인됐지만, 프로젝트 씬 실행 검증은 아직 하지 않았으므로 API 세부 차이로 인한 문법/런타임 오류가 남아 있을 수 있다.
- 지금은 데모 안정성 우선으로 `GameRoot.gd`에 많은 흐름이 들어 있다. 기능 검증 후 씬/스크립트 분리가 필요하다.
- 절차 생성 PNG는 데모 연결용 리소스다. 최종 아트 품질은 `concept_asset_sheet.png` 스타일을 기준으로 개별 스프라이트를 다시 제작하는 편이 좋다.
- 전투 AI는 기획서의 체감 검증용 최소 구현이다. 개별 지능/충성도, 레벨업 후보 선택, 자유 건설은 다음 단계다.
- `.import` 파일은 아직 생성되지 않았다. Godot에서 프로젝트를 열면 자동 생성된다.

## 9. 이어받기 명령

Godot가 PATH에 잡힌 환경이라면:

```powershell
godot --path "C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성"
```

에디터에서 열 경우:

1. Godot 4.5 실행
2. Import 선택
3. `C:\Users\LDK-6248\Desktop\AI개발\어시스트프로젝트\마왕성\project.godot` 선택
4. 에셋 import 완료 후 Run

정적 재검증:

```powershell
python tools/generate_demo_assets.py
```

이 명령은 프로젝트 PNG 리소스를 다시 생성한다.
