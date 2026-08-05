# v1.2.2 I1-5-OWNER-01 전투 VFX 대표 화면 검수

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

Windows Vulkan `1280×720` 대표 전투 장면에서 전투 VFX의 전면 벽 가림·anchor·강도 체감을 한 번 확인했다. DAY 30 정식 셀렌, 탐험가, 슬라임이 있는 `spike_corridor` 장면을 사용했으며 코드·데이터·자산은 수정하지 않았다.

## 실행

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
```

실행 환경은 Godot `4.5.2`, Vulkan, NVIDIA GeForce RTX 3060 Ti였다. 테스트 스크립트의 11개 상태 단언과 4개 `1280×720` 캡처 생성은 모두 통과했다.

```text
I1_5_BOSS_FINAL_REPRESENTATIVE: {"assertions":11,"failures":0,"boss_id":"official_paladin_selen","boss_music":"combat_boss_council.wav","consecrated_floor_count":1,"barrier_activated":true}
```

캡처:

- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_ready_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_inspection_telegraph_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_consecrated_floor_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_mercy_barrier_1280x720.png`

## 화면 판정

### 확인된 사항

- 1280×720 해상도에서 상단 DAY/HP, 우측 적 정보, 하단 명령 rail은 읽을 수 있다.
- 보스 BGM gate, 검수 예고, 축성 바닥, 자비의 방벽 상태가 상태 단언과 화면 효과로 생성됐다.
- 회흑색 통로·벽 구조 자체는 화면 전체에 유지된다.

### 출시 승인으로 닫을 수 없는 사항

- 중앙 전투 위치에서 셀렌·탐험가·슬라임의 몸체가 벽에 대부분 가려져, 캐릭터와 VFX의 anchor 관계를 눈으로 확인할 수 없다.
- 보라색 검수/방벽 ring은 전면 벽 위에 통째로 표시되지만 대상 몸체는 벽 아래로 밀려 있어, 지면·몸 VFX의 `wall_front` 가림 관계가 맞다고 승인할 수 없다.
- 축성 바닥과 방벽의 강도는 보이지만 캐릭터와의 상대 크기·부착 위치는 검증 불가다.

읽기 전용 코드 확인상 `CombatSceneController._apply_vfx_profile()`은 VFX depth를 `unit_fx=-30`, `front_fx=3000`, `aerial_fx=100`의 고정 z 값으로 적용하고, `Unit`은 renderer의 `-40..44` 슬롯을 사용한다. 이 둘을 실제 `wall_front` 가림 슬롯으로 변환하는 연결이 없어 화면에서 보인 단절을 설명한다. 이번 패킷에서는 수정하지 않았다.

## 결과

`I1_5_OWNER_SCREEN_BLOCKED` — 기술 캡처와 상태 단언은 통과했지만, 캐릭터가 벽에 묻히고 VFX가 벽 위에 분리되어 보이는 화면 때문에 전면 벽·anchor·강도 시각 gate를 통과시키지 않는다. 소유자 승인도 보류한다.

실행 종료 시 다음 Godot teardown 경고도 기록됐다. 기능 단언 실패는 아니지만 후속 수정 패킷에서 함께 확인해야 한다.

```text
WARNING: 1 RID of type "CanvasItem" was leaked.
WARNING: ObjectDB instances leaked at exit.
```

## 범위 밖 및 다음 조치

- 새 VFX·오디오 생성, 자산 승격, 전체 회귀, 빌드, 커밋·푸시는 하지 않았다.
- 다음 잠금 후보는 `V5-DEPTH-OCCLUSION-LIVE-CONTRACT`다. renderer depth 슬롯과 VFX depth를 실제 전면 벽 계층에 연결하고 대표 캡처로 재검증해야 한다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_BLOCKED`
