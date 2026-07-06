# 07. 참고 자료 요약

이 문서는 프로젝트 내부 기준을 위한 참고 요약이다.

## 1. 엔진/툴 문서에서 확인한 점

- Godot 4.5의 TileMapLayer는 TileSet을 사용하는 2D 타일 기반 맵 노드이며, 여러 TileMapLayer를 나눠 기존 TileMap처럼 여러 레이어를 구성할 수 있다.
- Godot TileSet은 atlas source, scene source, physics layer 등 타일 속성 레이어를 지원한다.
- Godot AStarGrid2D는 diamond cell shape을 제공하므로 isometric look의 그리드 경로 탐색에 사용할 수 있다.
- Godot CanvasItem은 y_sort_enabled와 z_index를 제공하므로 쿼터뷰 유닛/오브젝트 앞뒤 정렬에 사용할 수 있다.
- Tiled는 orthogonal, isometric, hexagonal 등 여러 projection의 타일맵을 지원하고, Terrain Brush는 Terrain Set 정보를 기반으로 지형 전환을 칠한다.
- Unity 2D Tilemap도 isometric tilemap과 tile palette 워크플로우를 제공한다.
- Unity 공식 블로그는 isometric/hexagonal grid layout 기반 2D 환경 제작 방식을 Diablo, Fallout, Civilization, Age of Empires 같은 고전 사례와 연결해 설명한다.
- MDN도 isometric tilemap이 2D simulation, strategy, RPG에서 널리 쓰이며 SimCity 2000, Pharaoh, Final Fantasy Tactics 같은 예시를 든다.

## 2. 이 프로젝트에 적용한 결론

1. 쿼터뷰 방을 통짜 이미지로 만들지 않는다.
2. 논리 그리드 위에 타일과 오브젝트를 얹는다.
3. 바닥 연결은 최소 4방향 16마스크가 필요하다.
4. 자연스러운 연결은 terrain/wang/autotile 계열 규칙으로 해결한다.
5. 마왕성 규모 확장은 새 이미지 생성이 아니라 같은 타일 반복 배치와 소켓/그리드 확장으로 해결한다.
6. 등급 상승은 테마 교체와 오버레이로 해결한다.
7. 이동 가능 영역은 이미지 모양이 아니라 walkable cell 데이터로 관리한다.

## 3. 참조 URL

- Godot TileMapLayer: https://docs.godotengine.org/en/4.5/classes/class_tilemaplayer.html
- Godot TileSet: https://docs.godotengine.org/en/4.5/classes/class_tileset.html
- Godot AStarGrid2D: https://docs.godotengine.org/en/4.4/classes/class_astargrid2d.html
- Godot CanvasItem: https://docs.godotengine.org/en/stable/classes/class_canvasitem.html
- Tiled Terrain: https://doc.mapeditor.org/en/stable/manual/terrain/
- Tiled editor overview: https://thorbjorn.itch.io/tiled
- Unity Isometric Tilemap: https://docs.unity3d.com/6000.1/Documentation/Manual/tilemaps/work-with-tilemaps/isometric-tilemaps/create-tile-palette-isometric-tilemap.html
- Unity Isometric Tilemap blog: https://unity.com/blog/engine-platform/isometric-2d-environments-with-tilemap
- MDN Tilemaps overview: https://developer.mozilla.org/en-US/docs/Games/Techniques/Tilemaps
