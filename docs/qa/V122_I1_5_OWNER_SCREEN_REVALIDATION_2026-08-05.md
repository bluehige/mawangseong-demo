# v1.2.2 I1-5 소유자 화면 재검수

검수일: 2026-08-05
대상 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
패킷: `I1-5-OWNER-SCREEN-REVALIDATION`

## 목적

앞선 `V4-A-03-FRONT-OCCLUDER-SCOPE`, `V5-DEPTH-OCCLUSION-SCREEN-REVALIDATION`, `V4-B-03-UI-ANCHOR-SCREEN-REVALIDATION` 뒤에 I1-5 보스 대표 화면을 다시 실행해 캐릭터·VFX·UI의 앞뒤 관계를 읽기 전용으로 확인했다. 이전 `I1_5_OWNER_SCREEN_BLOCKED` 화면에서 보였던 벽 가림과 VFX 분리 현상이 더 이상 재현되지 않는지 판정하는 패킷이다.

## 직접 실행

실행 환경은 Godot `4.5.2`, Vulkan, NVIDIA GeForce RTX 3060 Ti, `1280×720`이다.

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
```

실행 결과:

```text
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
```

상태 단언 11개와 대표 캡처 4개가 모두 통과했다.

- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_ready_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_inspection_telegraph_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_consecrated_floor_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_mercy_barrier_1280x720.png`

## 화면 판정

- 캐릭터 몸체가 바닥 위에 보이며 전체 구조 벽 본체에 삼켜지지 않는다. 의도된 낮은 E/S `front_occluder`만 전면 가림으로 남는다.
- 축성 바닥과 일반 지면 VFX가 바닥에 붙어 있고, 캐릭터 몸체와 잘못된 앞뒤 관계를 만들지 않는다.
- 검수 예고 링과 자비의 방벽 링은 의도한 전면 계층에 표시되며 벽에 잘려 나가거나 캐릭터와 분리되지 않는다.
- 보스 이름·HP 패널과 하단 명령 rail/readout이 읽히며 캐릭터 몸체와 겹치지 않는다.
- 이전 `I1_5_OWNER_SCREEN_BLOCKED`의 캐릭터 벽 삼킴·VFX 분리 현상은 이번 캡처에서 재현되지 않았다.

## 결과

`I1_5_OWNER_SCREEN_REVALIDATION_PASS`

이번 패킷에서는 코드·데이터·자산·오디오를 수정하지 않았다. 전체 회귀 검수, 빌드, 커밋, 푸시는 실행하지 않았다. 실제 소유자의 Windows 후보 조작과 헤드폰·스피커 청취 승인은 별도 gate로 남긴다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`
