# Update 4 Phase 32 Ending Illustrations

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: assets/source/imagegen/update4_endings_phase32/ending_e17_council_seat_source_2026-07-14.png
- Runtime image path: assets/ui/endings/update4/ending_council_seat.png
- Source image path: assets/source/imagegen/update4_endings_phase32/ending_e18_two_floors_source_2026-07-14.png
- Runtime image path: assets/ui/endings/update4/ending_two_floors_one_throne.png
- Source image path: assets/source/imagegen/update4_endings_phase32/ending_e19_minion_crown_source_2026-07-14.png
- Runtime image path: assets/ui/endings/update4/ending_minion_wears_the_crown.png

## Prompt intent

- E17: 마계 의회의 정식 의석과 명패를 받은 마왕성 대표단, 전투가 아닌 정치적 승리의 분위기.
- E18: 상층 왕관실과 하층 왕좌실이 한 계단으로 연결되고 양쪽 생존자들이 함께 승리를 확인하는 장면.
- E19: 왕관을 쓴 보라색 슬라임을 중심으로 마왕과 여러 종의 동료가 공로를 나누는 유쾌한 단체 초상.
- 모든 원본은 기존 v0.4의 짙은 보라·금색 동화풍 판타지 톤과 16:9 엔딩 카드 구도를 사용하며 화면 안 문자는 생성하지 않았다.

## Post-processing

`tools/prepare_update4_ending_assets.py`가 중앙 기준으로 16:9를 맞춘 뒤 1920×1080 PNG로 리샘플링한다. 색상·인물·배경 요소는 별도로 합성하거나 재생성하지 않는다.
