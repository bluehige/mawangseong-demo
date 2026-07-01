# 마왕성 데모 1차 완성 핸드오프

작성일: 2026-07-01

## 1. 목표

현재 폴더의 기획서(`mawang_topview_demo_spec.md`)와 3개 UI 참고 이미지 기준으로 Godot 4.5용 탑뷰 마왕성 방어 데모의 1차 플레이 루프를 구성했다.

이번 기준의 목표는 상용 완성 게임이 아니라, 다음 요소가 실제 프로젝트 안에서 끝까지 연결된 1차 데모를 만드는 것이다.

- Godot 프로젝트 실행 구조
- 관리 화면, 몬스터 관리 화면, 전투 화면, 결과 화면의 기본 흐름
- 3일 웨이브 루프
- 몬스터 3종, 적 3종 데이터
- RoomGraph 기반 방 이동
- 자동 전투, HP 감소, 격퇴, 보상 계산
- 전체 지침, 방 지침, 직접 조종, 기본 스킬
- 참고 이미지 분위기에 맞춘 프로젝트 내 PNG 리소스
- Godot import 완료 및 자동 스모크 테스트 통과

## 2. 현재 프로젝트 구조

중요 파일:

- `project.godot`
- `scenes/main/Main.tscn`
- `scenes/game/GameRoot.tscn`
- `scripts/game/GameRoot.gd`
- `scripts/game/ManagementSceneController.gd`
- `scripts/game/CombatSceneController.gd`
- `scripts/ui/HUDController.gd`
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
- `tools/DemoSmokeTest.tscn`
- `tools/ManualVerificationCapture.tscn`

`Main.tscn`은 `GameRoot.tscn`을 인스턴스한다. `GameRoot.gd`는 전체 상태와 씬 전환의 중심만 맡고, 관리 화면은 `ManagementSceneController.gd`, 전투 진행과 전투 HUD는 `CombatSceneController.gd`, 공통 UI 부품은 `HUDController.gd`가 맡는다.

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

2026-07-01 던전 맵 보강:

- 참고 이미지의 탑뷰 타일 던전 느낌을 기준으로 방 사각형 UI처럼 보이던 기존 맵 표현을 수정했다.
- 방 좌표를 64px 타일 배수로 다시 배치했다.
- `scripts/map/DungeonRenderer.gd`를 추가해 배경, 암벽 테두리, 복도, 방 바닥 타일, 소품, 방 이름 표지를 전담하게 했다.
- 관리 화면에서도 몬스터가 배치된 방 안에 대기하는 모습을 그린다.
- 전투 시작 시 적 스폰 위치를 새 입구 방 구조에 맞춰 보정했다.

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
- Godot 4.5.2 에셋 import 완료
- `Main.tscn` headless 실행 확인 완료
- `tools/DemoSmokeTest.tscn` 자동 체크 통과 완료
- PNG 텍스처를 Godot import 리소스로 읽도록 수정 완료
- 키보드 1/2 스킬 입력, 우클릭 직접 조종 입력 검증 완료
- `tools/ManualVerificationCapture.tscn`으로 실제 렌더링 화면 캡처 완료
- UI 겹침/텍스트 넘침 방지를 위한 HUD 글자 크기, 말줄임, 간격 조정 완료
- `GameRoot.gd`를 관리/전투/HUD 컨트롤러 단위로 분리 완료
- 캐릭터를 `AnimatedSprite2D` + `SpriteFrames` 구조로 확장 완료

현재 확인:

- Godot 4.5.2 실행 파일은 `C:\Users\blueh\Desktop\진행중인프로젝트\codex\난파\tools\godot\Godot_v4.5.2-stable_win64.exe`에 있다.
- 한글 경로 배치 파일 문제를 피하려고 `C:\Users\blueh\AppData\Local\Godot45` junction을 만들었다.
- 사용자 PATH에 이미 포함된 `C:\Users\blueh\AppData\Roaming\npm` 아래에 `godot.cmd`, `godot-gui.cmd` shim을 추가했다.
- `godot --version` 출력: `4.5.2.stable.official.6ce3de25a`
- 자동 체크 명령:

```powershell
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
```

자동 체크 결과:

```text
DEMO_SMOKE_TEST: PASS
```

시각 검수 캡처 명령:

```powershell
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

캡처 결과는 `tmp/manual_verification/` 아래에 생성된다.

## 7. 다음 세션 우선순위

1. 실제 사람 플레이 기준으로 새 던전 동선의 전투 템포와 난이도 체감 확인
2. 방별 소품 밀도, 암벽 외곽, 빈 배경 타일의 미술 품질 추가 보정
3. 밸런스 검수: 1~3일차 난이도, 보상량, 왕좌 HP 손실량 확인
4. 실제 애니메이션 프레임 추가 제작 및 SpriteFrames에 삽입
5. 미니맵, 사운드 이펙트, 튜토리얼 대사 같은 후순위 연출 추가
6. 레벨업 스킬 후보 선택 UI 확장
7. 자유 건설 시스템 확장

## 8. 현재 리스크

- 자동 체크와 렌더링 캡처는 통과했지만, 사람이 오래 플레이하며 느끼는 클릭감과 전투 체감은 별도 검수가 필요하다.
- `GameRoot.gd`는 컨트롤러로 분리됐지만, 아직 Godot 씬 노드 자체를 `ManagementScene`, `CombatScene`, `HUD` 하위 씬으로 완전히 나눈 단계는 아니다.
- 던전은 참고 이미지 방향을 반영한 1차 타일형 구조로 바꿨지만, 최종 아트 품질의 타일셋/벽 코너/방 장식 세트까지 완성한 단계는 아니다.
- 절차 생성 PNG는 데모 연결용 리소스다. 최종 아트 품질은 `concept_asset_sheet.png` 스타일을 기준으로 개별 스프라이트를 다시 제작하는 편이 좋다.
- 전투 AI는 기획서의 체감 검증용 최소 구현이다. 개별 지능/충성도, 레벨업 후보 선택, 자유 건설은 다음 단계다.
- 애니메이션 구조는 준비됐지만 현재는 단일 이미지를 각 애니메이션 슬롯에 넣은 상태다. 실제 움직임을 보려면 프레임 추가가 필요하다.
- `.import` 파일과 `.gd.uid` 파일은 Godot import 과정에서 생성되었고, 프로젝트 재현성을 위해 커밋 대상에 포함한다.

## 9. 이어받기 명령

Godot가 PATH에 잡힌 환경이라면:

```powershell
godot --path "C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성"
```

에디터에서 열 경우:

1. Godot 4.5 실행
2. Import 선택
3. `C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성\project.godot` 선택
4. 에셋 import 완료 후 Run

정적 재검증:

```powershell
python tools/generate_demo_assets.py
```

이 명령은 프로젝트 PNG 리소스를 다시 생성한다.
