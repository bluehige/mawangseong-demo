# 다음 세션 핸드오프: 쿼터뷰 방향 Variant부터 바로잡기

작성일: 2026-07-02

## 다음 세션 시작 문장

현재 목표는 마왕성 데모의 던전 배경을 “쿼터뷰 타일/오브젝트 variant 시스템” 기준으로 완성하는 것이다.

반드시 먼저 아래 문서를 읽고 진행해라.

- `mawang_guideline_pack/docs/08_CURRENT_QUARTERVIEW_GUIDELINES.md`
- `mawang_guideline_pack/docs/03_ASSET_GENERATION_GUIDE_GPT_IMAGE_2.md`
- `docs/WORK_LOG_2026-07-02_TILEGRID_CONVERSION.md`
- `data/dungeon_quarter/tile_variant_manifest.json`
- `scripts/dungeon_quarter/AutoTileMask.gd`
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`

이번 작업은 “소품을 많이 추가하는 일”이 아니다. 같은 타일/오브젝트가 위치와 연결 방향에 따라 다르게 보이도록 `NW/NE/SE/SW` 방향 variant를 만들고, renderer가 올바른 variant를 선택하게 하는 일이다.

## 현재 상태

- Godot 엔진: `C:\Users\blueh\AppData\Local\Godot45\Godot_v4.5.2-stable_win64.exe`
- 브랜치: `main`
- 원격 대비 상태: `origin/main`보다 5커밋 앞섬
- 최신 커밋: `c39f249 Animate spike traps during combat`
- 현재 작업트리는 이 핸드오프 작성 전 기준으로 깨끗했다.
- 이번 세션에서 잘못 만든 임의 장식 리소스 `assets/props/dressing/`는 제거했다. 프로젝트에 남기지 말 것.
- 잘못 생성된 원본 이미지는 `.codex/generated_images`에는 남아 있을 수 있지만, 프로젝트 리소스로 사용하지 말 것.

## 쿼터뷰 이해 기준

쿼터뷰는 단순히 위에서 내려다본 네모 타일이 아니다.

- 화면은 2D지만, 바닥의 네 방향이 `NW`, `NE`, `SE`, `SW`로 읽혀야 한다.
- 바닥, 벽, 문, 장식은 어느 방향이 열려 있고 어느 방향이 막혔는지에 따라 형태가 달라져야 한다.
- 앞쪽 벽/소품은 유닛을 가릴 수 있으므로 `back`, `front`, `UnitYSortLayer` 분리가 중요하다.
- 이미지를 무작정 회전시키면 쿼터뷰 조명, 원근, 앞뒤 관계가 깨질 수 있다. 회전/반전은 variant 규칙과 QA 기준이 있을 때만 사용한다.

현재 방향 bit 규칙:

```text
NW = 1
NE = 2
SE = 4
SW = 8
```

따라서 4방향 연결 상태는 0~15의 16개 mask로 표현된다.

예:

```text
0  = 아무 방향도 연결되지 않음
1  = NW만 연결
2  = NE만 연결
3  = NW + NE 연결
4  = SE만 연결
8  = SW만 연결
15 = NW + NE + SE + SW 모두 연결
```

## 절대 하지 말 것

- “16개가 필요하다”는 말을 “서로 다른 장식 16개를 만들라”로 해석하지 말 것.
- 랜덤 기둥, 바위, 횃불, 뼈무더기 같은 소품 atlas를 먼저 만들지 말 것.
- 방 전체 통짜 이미지를 다시 쓰지 말 것.
- 기존 `object_slots`에 임의 장식을 끼워 넣어 배경 완성처럼 보이게 하지 말 것.
- 방향 variant 선택 로직 없이 GPT Image 2 리소스만 만들지 말 것.
- 쿼터뷰 방향을 모르는 상태에서 이미지 회전으로 때우지 말 것.

## 실제로 해야 할 일

1. 현재 renderer가 어떤 variant를 이미 고르고 있는지 확인한다.
   - `AutoTileMask.gd`는 floor mask 0~15 계산을 이미 제공한다.
   - `QuarterDungeonRenderer.gd`는 현재 floor 16 mask를 로드하고 그린다.
   - edge/corner/wall/door는 일부 방향만 있고, 아직 완전한 16 variant 체계가 아니다.

2. `tile_variant_manifest.json`를 “방향 variant manifest”로 확장할 설계를 먼저 만든다.
   - 단일 오브젝트 정체성 하나당 mask 0~15 variant를 둔다.
   - 예: `wall_cave_f_mask_00.png`부터 `wall_cave_f_mask_15.png`
   - 예: `door_socket_cave_f_mask_00.png`부터 `door_socket_cave_f_mask_15.png`
   - 예: 위치 의존 장식도 필요하면 `prop_<id>_mask_00.png`부터 `15.png`

3. renderer 선택 기준을 명확히 한다.
   - 바닥: 주변 floor cell 기준 mask
   - 벽/가장자리: 주변 floor 부재와 socket open 여부 기준 mask
   - 문/소켓: `starting_layout.connections`와 socket side 기준 mask
   - 오브젝트: `object_slots`의 cell과 주변 막힘/열림 상태 기준 mask가 필요한 경우에만 variant 적용

4. GPT Image 2 리소스 제작은 이 설계가 끝난 뒤에 한다.
   - 내부 이미지 생성 도구를 사용한다.
   - API/CLI fallback이나 `OPENAI_API_KEY` 확인으로 우회하지 않는다.
   - 절차 생성 도형, SVG, 코드 드로잉, placeholder PNG로 대체하지 않는다.
   - 프롬프트는 “서로 다른 16개 오브젝트”가 아니라 “같은 오브젝트/타일의 16개 방향 연결 상태”로 써야 한다.
   - 같은 스타일, 같은 크기, 같은 앵커, 같은 조명이어야 한다.

5. 생성 후 반드시 테스트한다.
   - `QuarterModuleSmokeTest.tscn`
   - `DemoSmokeTest.tscn`
   - `ManualVerificationCapture.tscn`
   - F4 floor mask, F5 socket, F7 blocked overlay로 실제 방향과 이미지 방향이 맞는지 확인

## 첫 작업 추천

바로 이미지를 만들지 말고, 먼저 아래 산출물을 만들어라.

1. `docs/PLAN_2026-07-02_QUARTERVIEW_VARIANT_RENDERING.md`
   - 어떤 asset group에 16 variant가 필요한지
   - mask 계산 기준
   - 파일명 규칙
   - renderer 변경 지점

2. `data/dungeon_quarter/tile_variant_manifest.json` 확장 초안
   - 아직 PNG가 없어도 placeholder `file_hint`를 정의한다.

3. `QuarterDungeonRenderer.gd`에 debug 함수 추가
   - 특정 cell의 floor/wall/object mask를 확인할 수 있어야 한다.
   - 테스트에서 mask 0~15가 의도대로 선택되는지 검증해야 한다.

## 참고: 현재 구현된 것과 부족한 것

이미 구현됨:

- `room_blueprints.json` 기반 방/복도 정의
- `starting_layout.json` 기반 8x8 타일 그리드 배치
- `AutoTileMask.gd`의 4방향 16 mask
- floor 16 PNG 로드 및 렌더
- 일부 edge, corner overlay, wall, door PNG 로드 및 렌더
- object_slots 기반 prop/trap 렌더
- 가시 함정 trigger 애니메이션 전투 이벤트 연결

부족한 것:

- wall/door/object의 완전한 16방향 variant 체계
- 위치 의존 오브젝트의 mask 선택 로직
- front/back/Y-sort와 방향 variant를 함께 고려한 최종 배경 조립
- 실제 플레이 화면에서 방향이 맞는지 검증한 최종 캡처

## 다음 세션에 전달할 핵심 경고

사용자가 요구한 것은 “배경을 장식으로 채우라”가 아니다.

요구사항은 다음과 같다.

> 쿼터뷰에서 오브젝트는 위치와 연결 방향에 따라 보이는 면이 달라져야 한다. 따라서 같은 오브젝트라도 네 방향 조합에 맞는 16개 variant가 필요하고, renderer가 그중 맞는 이미지를 선택해야 한다.

이 기준을 구현하지 않으면 아무리 예쁜 오브젝트를 많이 넣어도 “쿼터뷰 던전 배경 완성”이 아니다.
