# UIUX V2 돌콩·두둠·루미·미미 초상과 전투 원본

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6

기존 동료 정체성과 장비를 보존한 입체 재질 PNG다. 3D 모델 교체나 새 버전 확정은 아니다. 실제 imagegen 프롬프트에 투명 배경을 요청했다. 루미·미미 초상 첫 RGB 체크무늬 후보는 미채택하고 내부 생성으로 다시 만들었다. 최종 8장 모두 RGBA이며 원본과 런타임 파일은 바이트가 동일하다. 로컬 배경 제거·크롭·축소·색 변환은 하지 않았다. Godot 손실 없는 import와 mipmap을 사용한다. 전투 16프레임은 data/uiux_actor_art.json의 AtlasTexture 영역과 논리 여백으로 연결하며 PNG 픽셀을 변경하지 않는다.

## dolkong_portrait

- Source image path: assets/source/imagegen/uiux_contract_art_20260913/dolkong_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/dolkong_base.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-caa55c26-4f97-4db2-a862-f56126d1c37e.png
- SHA-256: 883cda84aad0b19050e015a5283b0167b298ac29be8a383060c7fb06bbb2061e
- Size: (1223, 1286); 2583824 bytes
- References: assets/sprites/monsters/update4/monster_dolkong_sheet.png

### Prompt

투명 배경 이미지로 만들어줘. 첨부 전투 시트의 첫 번째 캐릭터 한 명을 큰 전용 게임 초상으로 그려줘. 돌콩은 작고 단단한 숯빛 회색 현무암 가고일 수호자. 짧은 돌뿔 두 개, 뒤로 접힌 돌날개, 굵은 돌 팔과 다리, 절제된 호박색 눈, 가슴의 작은 철제 성문 문양. 든든하고 과묵한 표정. 기존 형태·색·장비를 유지하면서 매끈하고 선명한 고급 3D 렌더 같은 입체 재질. 한 캐릭터 전신만 중앙에 크게, 주요 소품과 머리와 발이 잘리지 않게 여백 8%. 네이티브 투명 PNG. 글자·격자·바닥·배경 없음.

## dolkong_sheet

- Source image path: assets/source/imagegen/uiux_contract_art_20260913/stone_sentinel_sheet.png
- Runtime image path: assets/sprites/uiux3d/stone_sentinel_sheet.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-e5bf0414-9fc1-4381-948b-d725bd82984f.png
- SHA-256: f8f8c200452230462d827b690509442fe0563ac23b806ef1c10814fb9343bf55
- Size: (1254, 1254); 2531311 bytes
- References: assets/sprites/monsters/update4/monster_dolkong_sheet.png, assets/sprites/portraits/uiux3d/dolkong_base.png

### Prompt

투명 배경 PNG 스프라이트 시트를 만들어줘. 첫 이미지의 캐릭터와 16개 동작을 유지하되 두 번째 초상처럼 선명한 3D 입체 재질로 그려줘. 돌콩은 작고 단단한 숯빛 회색 현무암 가고일 수호자. 짧은 돌뿔 두 개, 뒤로 접힌 돌날개, 굵은 돌 팔과 다리, 절제된 호박색 눈, 가슴의 작은 철제 성문 문양. 든든하고 과묵한 표정. 정확히 4열×4행, 총 16개 독립된 전신 포즈. 첫 행은 대기 2프레임 다음 쓰러짐 2프레임, 둘째 행은 이동 4프레임, 셋째 행은 공격 4프레임, 넷째 행은 기술 4프레임. 같은 크기와 방향, 칸마다 전체 몸과 장비가 들어가도록 충분한 투명 여백, 칸 사이 간격. 문자·선·바닥 그림자 없음. 실제 투명 배경으로 생성해줘.

## dudum_portrait

- Source image path: assets/source/imagegen/uiux_contract_art_20260913/dudum_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/dudum_base.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-27f11801-4672-4eb8-a3e8-ff14a81364c0.png
- SHA-256: 5eee2411e73f5046d2f302db311e33aea5258952149b1374d9ea14333add4695
- Size: (1254, 1254); 1612964 bytes
- References: assets/sprites/monsters/update4/monster_dudum_sheet.png

### Prompt

투명 배경 이미지로 만들어줘. 첨부 전투 시트의 첫 번째 캐릭터 한 명을 큰 전용 게임 초상으로 그려줘. 두둠은 작고 귀여운 해골 북 연주자. 둥근 해골 얼굴과 검은 눈구멍, 붉은 머리 두건과 금색 둥근 배지, 검은 깃털 하나, 갈색 가죽 어깨 보호구와 붉은 천, 배 앞의 갈색 나무 북, 양손의 둥근 북채. 밝고 씩씩한 표정. 기존 형태·색·장비를 유지하면서 매끈하고 선명한 고급 3D 렌더 같은 입체 재질. 한 캐릭터 전신만 중앙에 크게, 주요 소품과 머리와 발이 잘리지 않게 여백 8%. 네이티브 투명 PNG. 글자·격자·바닥·배경 없음.

## dudum_sheet

- Source image path: assets/source/imagegen/uiux_contract_art_20260913/war_drummer_sheet.png
- Runtime image path: assets/sprites/uiux3d/war_drummer_sheet.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-3c6c29d2-427e-4923-a3a8-e9c7b5097846.png
- SHA-256: 20d890f9920f470fe3e88b84fb46806c2a8a75998e6320918e0a2a282c5dd5ac
- Size: (1254, 1254); 1850226 bytes
- References: assets/sprites/monsters/update4/monster_dudum_sheet.png, assets/sprites/portraits/uiux3d/dudum_base.png

### Prompt

투명 배경 PNG 스프라이트 시트를 만들어줘. 첫 이미지의 캐릭터와 16개 동작을 유지하되 두 번째 초상처럼 선명한 3D 입체 재질로 그려줘. 두둠은 작고 귀여운 해골 북 연주자. 둥근 해골 얼굴과 검은 눈구멍, 붉은 머리 두건과 금색 둥근 배지, 검은 깃털 하나, 갈색 가죽 어깨 보호구와 붉은 천, 배 앞의 갈색 나무 북, 양손의 둥근 북채. 밝고 씩씩한 표정. 정확히 4열×4행, 총 16개 독립된 전신 포즈. 첫 행은 대기 2프레임 다음 쓰러짐 2프레임, 둘째 행은 이동 4프레임, 셋째 행은 공격 4프레임, 넷째 행은 기술 4프레임. 같은 크기와 방향, 칸마다 전체 몸과 장비가 들어가도록 충분한 투명 여백, 칸 사이 간격. 문자·선·바닥 그림자 없음. 실제 투명 배경으로 생성해줘.

## moon_portrait

- Source image path: assets/source/imagegen/uiux_contract_art_20260913/moon_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/moon_base.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-273c8f45-7df3-46b7-a675-186adbce542d.png
- SHA-256: e6cd06114b4d502eba7342dce607c2fcfddbbdf26f845462c4cb47232f10c977
- Size: (1254, 1254); 2046856 bytes
- References: assets/sprites/monsters/update4/monster_moon_sheet.png

### Prompt

투명 배경 PNG로 만들어줘. 첨부 캐릭터 한 명의 전신을 크게 그려줘. 루미는 작고 보라색인 달빛 추적자. 매우 긴 뾰족 귀, 보라색 눈, 진청색 후드와 짧은 망토, 후드의 흰 초승달 장식, 화살통, 작은 초승달 곡선 활. 경계하며 영리한 표정. 선명하고 귀여운 3D 게임 렌더. 캐릭터만 있고 배경은 실제로 투명한 이미지로 생성해줘.

## moon_sheet

- Source image path: assets/source/imagegen/uiux_contract_art_20260913/moon_tracker_sheet.png
- Runtime image path: assets/sprites/uiux3d/moon_tracker_sheet.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-25642525-0919-4cd0-95f9-8310bd55b489.png
- SHA-256: 9571a218d091d305e1c75a092931d0b9286fa17f1ea03814503152a0adbec751
- Size: (1254, 1254); 1928404 bytes
- References: assets/sprites/monsters/update4/monster_moon_sheet.png, assets/sprites/portraits/uiux3d/moon_base.png

### Prompt

투명 배경 PNG 스프라이트 시트를 만들어줘. 첫 이미지의 캐릭터와 16개 동작을 유지하되 두 번째 초상처럼 선명한 3D 입체 재질로 그려줘. 루미는 작고 보라색인 달빛 추적자. 매우 긴 뾰족 귀, 보라색 눈, 진청색 후드와 짧은 망토, 후드의 흰 초승달 장식, 화살통, 작은 초승달 곡선 활. 경계하며 영리한 표정. 정확히 4열×4행, 총 16개 독립된 전신 포즈. 첫 행은 대기 2프레임 다음 쓰러짐 2프레임, 둘째 행은 이동 4프레임, 셋째 행은 공격 4프레임, 넷째 행은 기술 4프레임. 같은 크기와 방향, 칸마다 전체 몸과 장비가 들어가도록 충분한 투명 여백, 칸 사이 간격. 문자·선·바닥 그림자 없음. 실제 투명 배경으로 생성해줘.

## mimi_portrait

- Source image path: assets/source/imagegen/uiux_contract_art_20260913/mimi_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/mimi_base.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-ff418e90-c37c-4ef1-a55b-07d8ea3009b2.png
- SHA-256: bf4748f9c84a3f333ff006e0ee99953df239436c132ee19275ebc32079c4d450
- Size: (1402, 1122); 2052008 bytes
- References: assets/sprites/monsters/update4/monster_mimi_sheet.png

### Prompt

투명 배경 PNG로 만들어줘. 첨부 캐릭터 한 명의 전신을 크게 그려줘. 미미는 갈색 나무 보물상자 몸체를 가진 작은 미믹. 금동색 띠와 리벳, 앞의 열쇠구멍, 금색 화살 모양 문양이 있는 붉은 천, 짧은 나무 팔과 발, 열린 뚜껑 안의 이빨. 별도의 눈이나 인간 얼굴은 추가하지 않음. 짓궂고 귀여운 분위기. 선명하고 귀여운 3D 게임 렌더. 캐릭터만 있고 배경은 실제로 투명한 이미지로 생성해줘.

## mimi_sheet

- Source image path: assets/source/imagegen/uiux_contract_art_20260913/mimic_porter_sheet.png
- Runtime image path: assets/sprites/uiux3d/mimic_porter_sheet.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-f672b3f1-4bf4-4014-ad6a-82e674f82fd7.png
- SHA-256: 28d9da0f50ee86269c13f4d6f82fd6a6c2217a1075907bc50ddf14da20dd1fe9
- Size: (1254, 1254); 2175435 bytes
- References: assets/sprites/monsters/update4/monster_mimi_sheet.png, assets/sprites/portraits/uiux3d/mimi_base.png

### Prompt

투명 배경 PNG 스프라이트 시트를 만들어줘. 첫 이미지의 캐릭터와 16개 동작을 유지하되 두 번째 초상처럼 선명한 3D 입체 재질로 그려줘. 미미는 갈색 나무 보물상자 몸체를 가진 작은 미믹. 금동색 띠와 리벳, 앞의 열쇠구멍, 금색 화살 모양 문양이 있는 붉은 천, 짧은 나무 팔과 발, 열린 뚜껑 안의 이빨. 별도의 눈이나 인간 얼굴은 추가하지 않음. 짓궂고 귀여운 분위기. 정확히 4열×4행, 총 16개 독립된 전신 포즈. 첫 행은 대기 2프레임 다음 쓰러짐 2프레임, 둘째 행은 이동 4프레임, 셋째 행은 공격 4프레임, 넷째 행은 기술 4프레임. 같은 크기와 방향, 칸마다 전체 몸과 장비가 들어가도록 충분한 투명 여백, 칸 사이 간격. 문자·선·바닥 그림자 없음. 실제 투명 배경으로 생성해줘.
