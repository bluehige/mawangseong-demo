# Update 4 Phase 33 Ending Illustrations

Generation model: GPT internal image generation
Generated date: 2026-07-14
Target version: v0.4
Source image path: assets/source/imagegen/update4_endings_phase33/ending_e20_outpost_home_source_2026-07-14.png
Runtime image path: assets/ui/endings/update4/ending_outpost_becomes_home.png
Source image path: assets/source/imagegen/update4_endings_phase33/ending_e21_three_rivals_source_2026-07-14.png
Runtime image path: assets/ui/endings/update4/ending_three_rivals_cosign.png
Source image path: assets/source/imagegen/update4_endings_phase33/ending_e22_council_dissolved_source_2026-07-14.png
Runtime image path: assets/ui/endings/update4/ending_council_dissolved.png

## Prompt intent

- E20: 전투 두 번을 버틴 보라색 전초기지가 침대·빈 간판·간식 창고를 갖춘 따뜻한 공동체가 된 해질녘 풍경.
- E21: 기존 경쟁 마왕 3인의 원본 초상을 참조해 한 협정서에 공동 인장을 찍으면서 종이·배송·습도를 두고 논쟁하는 의회 장면.
- E22: 기존 경쟁 마왕 3인의 원본 초상을 참조해 공식 연단은 치우고 간식과 지도를 둔 원탁에서 비공식 모임을 여는 해산 후 장면.
- 모든 원본은 16:9 엔딩 카드 구도이며 화면 안 문자는 생성하지 않았다.

## Reference image roles

E21과 E22는 `assets/source/imagegen/update4_rivals/{brassa,vesper,mirella}/*portraits_chroma_2026-07-14.png`를 각 경쟁 마왕의 얼굴·실루엣·복장·색상 정체성 참조로 사용했다. E20은 신규 장면 생성이다.

## Post-processing

`tools/prepare_update4_ending_assets.py`가 중앙 기준으로 16:9를 맞춘 뒤 1920×1080 PNG로 리샘플링한다. 색상·인물·배경 요소는 별도로 합성하거나 재생성하지 않는다.
