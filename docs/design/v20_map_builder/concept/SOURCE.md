# 마왕성 2.0 맵 기획 구상도 출처

- Generation model: GPT internal image generation
- Generated date: 2026-10-14 (Asia/Seoul)
- Target version: 2.0.0 기획 초안
- 용도: 자유 배치 맵·자동 길 연결·관전 전투의 기획 확인용 구상도(목업). 런타임 자산 아님.
- 생성 경로: GPT 내부 `image_gen` 도구. 외부 생성 서비스·API CLI를 사용하지 않음. 도구가 실제 모델 식별자를 반환하지 않아 세부 모델 이름은 추정하지 않음.
- 출력: 두 최종 PNG 모두 1536×864, 16:9, 불투명 배경.
- 참고 기획: `docs/design/v20_map_builder/V20_MAP_BUILDER_PLAN_2026-10-14.md` 2절.
- 스타일 참고 입력: `tmp/growth_support_feedback/first_protection_slime_gate_bulwark.png` (1280×720).
- 후처리: 생성 도구 원본 1672×941을 Windows System.Drawing의 고품질 bicubic 보간으로 1536×864에 크기 정규화. 별도 그림 추가·배경 제거·합성 없음. 원본은 도구 기본 캐시에 보존.
- 저장소 수정 범위: 이 폴더의 새 PNG 2개와 이 문서만. 코드·세이브·기획 원문·핸드오프 변경 및 커밋 없음.
- 기준 확인 제한: 로컬 `main` 참조가 없어 `main:AGENTS.md` 및 `main:docs/handoff/CURRENT.md`를 읽을 수 없었음. 원격 fetch·브랜치 전환을 수행하지 않았고 최신 제품 상태를 확정하지 않음. 사용자가 제공한 정책 및 지정 기획서로 이번 구상도 범위만 진행.

## 건설 모드

- Output image path: docs/design/v20_map_builder/concept/concept_build_mode.png
- Source image path: C:/Users/blueh/.codex/generated_images/01a135ef-1413-7940-a54a-1ad321edf20d/exec-77e59d19-1e6a-410f-9639-f4f5cebf7494.png
- 입력 역할: 기존 게임 화면은 스타일 참고이며 수정 대상이 아님.
- 시각 확인: 화면에 맞춘 넓은 부지, 왼쪽 입구·뒤편 왕좌, 분산된 방과 큰길·가지길, 녹색 고스트 및 점선 연결, 희미한 격자, 6개 건설 아이콘, 우상단 자원 표시. 네 귀퉁이는 동굴 지형으로 채움.

### 사용한 최종 프롬프트

```text
Use case: stylized-concept.
Create a single finished game planning mockup of dungeon BUILD MODE, landscape 16:9, exactly 1536x864 pixels or a larger exact 16:9 size. Dark fantasy cavern dungeon, faithful to the reference's grey stone blocks, violet cavern shadows, gold-trimmed furnishings, purple banners and warm orange torches; crisp 2:1 isometric pixel-art and painted texture hybrid, orthographic quarter view.

Highest priorities: fully visible room interiors, edge-to-edge filled scenery, freely placed buildings with an obvious automatically connected road network. The buildable floor is a broad SCREEN-ALIGNED RECTANGULAR footprint occupying almost the whole scene, not a floating diamond-shaped island. Keep the 2:1 isometric floor grid inside this screen-shaped rectangular plot. Surround its narrow perimeter with dense cavern rock, amethyst crystals and glowing lava fissures reaching every image edge, with no black empty corners. A tall cavern cliff frames the far/top edge only.

Entrance gate on the left plot edge; a clearly recognizable throne room at the rear/top of the plot. Scatter four distinctive roofless buildings at irregular offsets, not a fixed row or rigid room matrix: barracks with racks and bunks, healing nest with a turquoise pool, treasure chamber with gold and chests, trap room with floor spikes. Use modest full-height walls only on each room's two rear-facing edges. Its two camera-facing edges must be knee-high stone rims, so the entire interior is exposed. No roofs, no tall front walls. Broad TWO-TILE-WIDE stone roads form one continuous entrance-to-throne trunk plus short clean branching connections terminating at each building doorway. Roads have no walls, only occasional torches and purple pennants.

Show exactly one translucent green ghost building being dragged by a small mouse pointer in open space, with its entrance clearly facing a green dotted two-tile-wide preview connection to the nearest existing road. A faint isometric grid spans the buildable floor. A slim single-row construction palette of exactly six building icons occupies the bottom 6% of the frame; tiny resource icons and numbers in the upper right. Minimal text. No real-world game or brand logos, no titles, no watermarks, no large UI panels. Planning concept image, not a runtime asset.

Input images:
- first_protection_slime_gate_bulwark.png: style reference only. Preserve its stone, furnishings, violet/orange lighting and quarter-view aesthetic; replace its layout with the requested rectangular plot and cutaway walls.
```

## 전투 관전 모드

- Output image path: docs/design/v20_map_builder/concept/concept_battle_spectate.png
- Source image path: C:/Users/blueh/.codex/generated_images/01a135ef-1413-7940-a54a-1ad321edf20d/exec-255d901a-7673-4bee-b874-68bbb4457552.png
- 최초 생성 원본: C:/Users/blueh/.codex/generated_images/01a135ef-1413-7940-a54a-1ad321edf20d/exec-d1bdbdaf-fc80-4f75-9254-eee6020b16e1.png
- 입력 역할: 건설 구상도는 같은 던전의 연결성 참고, 기존 게임 화면은 스타일·유닛 크기 참고. 최초 생성 후 관전 구상도 자체를 보정 입력으로 사용함.
- 보정 내역: 길 위 방패병·푸딩 슬라임 전투를 유지하고 검사·고블린을 병영 안으로 이동. 병영 앞벽을 낮추고 미니맵에 전체 부지 경계를 추가함.
- 시각 확인: 인간 3명·몬스터 3명, 길과 병영 내부의 전투, 벽에 가리지 않는 유닛, 진입 화살표, 좌상단 왕좌 HP, 얇은 배속·명령 UI, 우하단 직사각형 미니맵 및 카메라 범위.
- 크기·길 폭·부지 형태는 기획 표현이며 실제 게임 좌표나 수치 구현의 검증 결과가 아님.

### 최초 생성 프롬프트

```text
Use case: stylized-concept.
Create a single finished game planning mockup of BATTLE SPECTATOR MODE, landscape 16:9, exactly 1536x864 pixels or a larger exact 16:9 size. Show the SAME dungeon as input image 1, with the same entrance on the left, rear throne, scattered barracks, turquoise healing pool, treasure chamber and spike-trap chamber; preserve the grey stone, purple/gold banners, violet amethyst cavern and orange torch palette. Crisp 2:1 isometric pixel-art and painted texture hybrid, orthographic quarter view.

Zoom the spectator camera into the entrance-to-throne road junction and adjacent open-front rooms so units are visibly twice the size of the original gameplay reference, approximately 80-96 pixels tall at 1536x864. This is a close view of part of the same rectangular plot, not a zoomed-out view of the entire map. Environment continues to all image edges with no black void.

At the center, depict a clearly readable battle: three HUMAN ADVENTURERS entering from the left, a steel swordsman, a broad shield bearer, and a hooded dagger rogue, against three MONSTER DEFENDERS, a glossy rounded jelly-pudding slime with a cute face, a small red winged imp, and a green goblin with a short weapon. Spread the six distinct combatants across the broad two-tile-wide stone road and the visible interior of an adjacent low-rim room. Every complete character silhouette is visible; no unit is concealed by masonry, UI, other units or large effects. Show restrained sword sparks and a small magical impact, never clutter.

All camera-facing room edges are knee-high stone rims BELOW the characters' knees. Only the two rear-facing room edges have ordinary walls; far cavern cliffs are background. No roofs and no tall foreground walls. The wide road network has no enclosing walls. A subtle sequence of glowing arrowheads on the main stone road shows the invasion route from the left entrance toward the rear throne. Keep branch roads to room doorways visible.

A small throne HP bar is at the upper left with only a crown icon and red fill. The bottom control strip is one thin horizontal row, at most 6% of frame height, containing compact speed controls and command icons; no construction palette. A small minimap sits at the bottom right above the strip: an unmistakably horizontal SCREEN-ALIGNED RECTANGULAR full-plot outline, tiny room blocks and road branches, with a contrasting smaller rectangular camera viewport box marking this zoomed-in area. Minimal text; no large panels, no real-world game or brand logos, no titles or watermarks. Planning concept image, not a runtime asset.

Input images:
- concept_build_mode.png: primary environment and layout continuity reference, showing the same dungeon before combat. Change camera zoom, units and UI for battle spectator mode.
- first_protection_slime_gate_bulwark.png: original game style reference and small-unit scale baseline; use approximately twice its character scale, with all front walls cut down.
```

### 사용한 최종 보정 프롬프트

```text
Edit this battle spectator planning mockup with a focused visibility correction. Preserve the same dungeon, isometric camera, zoom, grey/violet/orange pixel-painting style, left entrance, rear throne, road network, arrow route, throne HP bar, slim bottom controls and minimap.

Keep exactly the same six combatants, three humans and three monsters, with the same appearance and scale. Keep the shield bearer battling the jelly-pudding slime on the broad road, and the dagger rogue and red imp near the road junction. Reposition the steel swordsman and green goblin as a clearly visible dueling pair INSIDE the barracks room immediately above and left of the central road fight. Make space among the training props for both complete silhouettes; their feet must visibly stand on the barracks interior floor. No duplicated or added combatants.

Cut all camera-facing front room walls down to a single low course of stone below the combatants' knees, especially the barracks front rim. Keep ordinary walls only on the two rear room edges. No character may be concealed by walls, props, UI or another unit. Preserve the filled cavern scenery and open wall-free roads.

In the bottom-right minimap add a clearly visible thin horizontal rectangular boundary around the FULL buildable plot, while retaining tiny room/road markers and the contrasting smaller camera-view rectangle. No logos, titles or watermarks. Final landscape 16:9 planning concept, 1536x864 or larger.

Input images:
- concept_battle_spectate.png: edit target; preserve all elements except the specified unit positions, lower front rims and full-plot minimap boundary.
```

## 검증 및 다음 확인

- Pillow `Image.verify()` 및 재개방 `Image.load()`로 두 PNG의 형식·완전한 디코딩·1536×864 크기·정확한 16:9 비율을 확인 완료: PASS.
- 최종 이미지를 직접 열어 주요 구성과 유닛 가림 여부를 확인 완료. 병영 내부와 길 위의 여섯 유닛이 보이고, 방 앞면은 열린 낮은 턱으로 표현됨.
- 기획 원문의 SHA-256 작업 전후 일치 확인: PASS. `e3c1e1068db8ad5d2e2e09ebf231d9171c31669b84c50f5d68051fa8332e807a`.
- 폴더 파일 목록 검증: 요청된 PNG 2개와 SOURCE.md, 정확히 3개. Git 상태는 기존의 `docs/design/v20_map_builder/` 미추적 표시를 유지하며 추적 파일 변경 없음.
- 게임 실행·빌드·회귀 테스트는 이미지 목업 작업 범위가 아니므로 실행하지 않는다.
- 다음 단계는 두 구상도의 기획 방향 확인이다. 실제 구현·제품 버전 확정·세이브 변경·배포를 승인한 것으로 해석하지 않는다.

