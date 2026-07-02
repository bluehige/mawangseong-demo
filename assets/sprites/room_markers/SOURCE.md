이 파일이 왜 필요한지: 방의 물리적 위치와 방의 용도 표시 이미지를 분리해, 같은 방이라도 보관실/병영/회복둥지 같은 기능 표시를 나중에 쉽게 바꿀 수 있게 기록한다.

# GPT Room Marker Assets

- Source model/path: GPT image generation through Codex image tool, per user request for GPT-generated graphics.
- Generated source kept by Codex:
  `C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_0f8e0a9ce186c6cb016a4533e4852c819192fb8a1b61f733d2.png`
- Project copy:
  `assets/sprites/room_markers/gpt2_room_marker_sheet.png`

The sheet was cropped into individual room-purpose marker images:

- `marker_gate_gpt2.png`
- `marker_spike_corridor_gpt2.png`
- `marker_brazier_passage_gpt2.png`
- `marker_throne_gpt2.png`
- `marker_barracks_gpt2.png`
- `marker_treasure_gpt2.png`
- `marker_recovery_nest_gpt2.png`
- `marker_recovery_room_gpt2.png`
- `marker_build_slot_gpt2.png`

## 2026-07-02 회복 시설 분리 아이콘

- 생성 원본 위치: `C:\Users\LDK-6248\.codex\generated_images\019f200d-8e32-7233-a6f3-72a76f65ec97\ig_05ba4aac5f7ade84016a45c445d7008199b5fdafb6a29ec33a.png`
- 프로젝트 복사본: `assets/sprites/room_markers/marker_recovery_room_gpt2.png`
- 처리 방식: 자홍색 크로마키 배경으로 생성한 뒤 로컬 투명 처리와 256x256 리사이즈를 적용했다.
- 생성 이유: 회복실 소품을 던전 배경에 고정하지 않고, 방 용도 변경에 따라 별도 오버레이 아이콘으로 표시하기 위해 추가했다.
- 호환 처리: 기존 참조가 남아도 깨지지 않도록 `marker_recovery_nest_gpt2.png`도 같은 새 아이콘으로 갱신했다. 현재 코드와 데이터는 `marker_recovery_room_gpt2.png`를 사용한다.
