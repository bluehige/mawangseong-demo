# Quarter Dungeon Module Sources

Final module PNGs for the socket-based quarter-view map belong here.

The first production batch is defined in:

```text
tools/imagegen/quarter_modules_gpt_image2_prompts.jsonl
```

Resource rule:

- Connected sockets in `data/dungeon_quarter/starting_layout.json` are visually open.
- Unconnected socket sides are visually closed with wall, rock, columns, or rubble.
- Navigation and collision are still driven by `data/dungeon_quarter/modules.json`, not by the image pixels.

Expected final asset names:

```text
room_entrance_01_visual.png
corridor_spike_ne_sw_01_visual.png
junction_center_01_visual.png
room_throne_01_visual.png
room_barracks_01_visual.png
room_recovery_01_visual.png
room_empty_slot_01_visual.png
room_treasure_01_visual.png
```

Generation status on 2026-07-02: GPT Image 2 prompts prepared. Live generation is blocked until `OPENAI_API_KEY` is set in the local environment.

