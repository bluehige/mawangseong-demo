# GPT Image 2 던전 리소스 출처

이 파일이 왜 필요한지: 던전 그래픽을 코드로 임시로 그린 것이 아니라, GPT Image 2로 생성한 실제 PNG 리소스를 사용했다는 근거와 재작업 기준을 남기기 위해 필요하다.

- 생성 원본 위치: `C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_0d8bd3bd4b9cdd09016a451aa2fd74819a9abe67f7a939b5f2.png`
- 프로젝트 복사본: `assets/sprites/dungeon_gpt2/gpt2_dungeon_asset_sheet.png`
- 사용 방식: 원본 시트에서 바닥, 벽, 문, 기둥, 횃불, 암벽 리소스를 잘라 개별 PNG로 저장한 뒤 Godot 렌더러에서 사용한다.
- 생성 방향: `topview_battle_ui_reference.png`처럼 탑뷰이지만 벽 높이와 앞뒤 거리감이 느껴지는 2.5D 던전 내부 타일셋.

생성 프롬프트 요지:

```text
Create a production-ready 2D game asset sheet for a cute dark fantasy demon castle defense game dungeon interior.
Top-view but with 2.5D depth, hand-painted indie game art, chunky stone blocks, purple rim light, warm torch highlights.
Include seamless stone floor, cave floor, wall top cap, front wall face, side wall face, arched doorway, pillar, rock border chunks, torch, brazier, shadow overlay.
No text, no UI, no labels, no watermark.
```
