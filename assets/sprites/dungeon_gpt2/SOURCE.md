# GPT Image 2 던전 리소스 출처

이 파일이 왜 필요한지: 던전 그래픽을 코드로 임시로 그린 것이 아니라, GPT Image 2로 생성한 실제 PNG 리소스를 사용했다는 근거와 재작업 기준을 남기기 위해 필요하다.

- 생성 원본 위치: `C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_0d8bd3bd4b9cdd09016a451aa2fd74819a9abe67f7a939b5f2.png`
- 프로젝트 복사본: `assets/sprites/dungeon_gpt2/gpt2_dungeon_asset_sheet.png`
- 사용 방식: 원본 시트에서 바닥, 벽, 문, 기둥, 횃불, 암벽 리소스를 잘라 개별 PNG로 저장한 뒤 Godot 렌더러에서 사용한다.
- 생성 방향: `topview_battle_ui_reference.png`처럼 탑뷰이지만 벽 높이와 앞뒤 거리감이 느껴지는 2.5D 던전 내부 타일셋.

## 연결형 던전 배경

- 생성 원본 위치: `C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_0d413fda5ab5f57c016a4523222340819187d8e8362593dc24.png`
- 프로젝트 복사본: `assets/sprites/dungeon_gpt2/gpt2_dungeon_connected_map.png`
- 사용 방식: 기존 네모 타일 렌더링 대신, 방과 복도가 실제로 이어진 던전 내부 전체 배경으로 사용한다. Godot에서는 방 선택 영역, 방 이름표, 캐릭터, 전투 UI만 이 이미지 위에 얹는다.
- 생성 방향: 하단 연결 벽/통로를 더 위로 올려 입구, 가시 복도, 보물 보관실이 같은 던전 구조 안에서 이어져 보이게 하고, 입구 -> 가시 복도 -> 중앙 통로 -> 왕좌의 방으로 이어지는 주 경로가 끊기지 않게 만든다.

### 2026-07-02 중립 방 배경 편집

- 편집 원본 위치: `C:\Users\LDK-6248\.codex\generated_images\019f200d-8e32-7233-a6f3-72a76f65ec97\ig_0f4686e884b06966016a45c0794e148191b9c1d3992e058b56.png`
- 프로젝트 복사본: `assets/sprites/dungeon_gpt2/gpt2_dungeon_connected_map.png`
- 편집 이유: 방 용도 변경 시스템 도입 후 우하단 방이 배경 이미지 자체에서 계속 보물방처럼 보이는 문제를 줄이기 위해 보물더미와 상자를 제거했다.
- 편집 방향: 전체 던전 구조, 벽, 통로, 조명, 다른 방은 유지하고 우하단 방 내부만 중립적인 빈 방/보관 공간으로 바꿨다.

생성 프롬프트 요지:

```text
Create a production-ready 2D game asset sheet for a cute dark fantasy demon castle defense game dungeon interior.
Top-view but with 2.5D depth, hand-painted indie game art, chunky stone blocks, purple rim light, warm torch highlights.
Include seamless stone floor, cave floor, wall top cap, front wall face, side wall face, arched doorway, pillar, rock border chunks, torch, brazier, shadow overlay.
No text, no UI, no labels, no watermark.
```
