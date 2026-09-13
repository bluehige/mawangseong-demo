# UIUX V2 후반 캐릭터 원본

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6

실제 imagegen 프롬프트로 투명 PNG를 요청했다. 채택 파일의 네이티브 알파를 검사하며 원본과 런타임 바이트는 동일하다. 로컬 배경 제거·축소·크롭·색 변환은 하지 않았다. AtlasTexture 영역·여백과 Godot lossless import 및 mipmap만 사용한다. 일부 첫 생성과 투명화 편집이 RGB 체크무늬로 반환되어 미채택했다. GPT 내부 생성기로 다시 제작하여 실제 RGBA인 최종 59장만 채택했다. 이 실패를 내부 생성 모델의 투명 PNG 지원 불가로 해석하지 않는다. 프레임 구획은 원본의 투명 간격을 측정했고, 비대칭 여백에서 이웃 동작 또는 몸체가 잘리지 않도록 표시 영역과 논리 여백만 조정했다. 새 제품 버전 확정이 아니다.


## kobold_scout

- Source image path: assets/source/imagegen/uiux_completion_20260913/kobold_scout_sheet.png
- Runtime image path: assets/sprites/uiux3d/kobold_scout_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-1f25ac1f-7f1a-4208-bce4-3a4d26aeb681.png
- SHA-256: 445951459621ada7dd2d4ab72c21e02c8b22ae053ead48a28525993c492daf6d
- Size: (1247, 1261); 2136585 bytes
- References: assets/source/imagegen/uiux_completion_20260913/rolo_base.png

### Prompt

투명 배경 PNG 게임 스프라이트 시트를 만들어줘. 첨부의 로로 한 명을 작고 귀여운 3D 게임 캐릭터로 그려줘. 올리브색 비늘, 호박색 눈, 짧은 뿔과 큰 귀, 녹색 망토와 가죽 정찰 장비, 말린 지도와 작은 횃불 깃대. 정확히 4열×4행, 총 16개의 독립된 전신 포즈. 첫 행은 대기 2개와 쓰러짐 2개, 둘째 행 이동 4개, 셋째 행 공격 4개, 넷째 행 기술 4개. 각 칸 전체 몸과 장비, 같은 체격과 정면 3/4 방향, 칸마다 15% 빈 여백과 충분한 간격. 부드럽고 또렷한 입체 재질, 큰 형태 위주. 배경은 실제로 투명하게. 문구·격자·바닥·배경·체크무늬 없음.


## ghost_housemaid

- Source image path: assets/source/imagegen/uiux_completion_20260913/ghost_housemaid_sheet.png
- Runtime image path: assets/sprites/uiux3d/ghost_housemaid_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-469d640a-f67e-430e-9671-86156d3a87ed.png
- SHA-256: aa8b20bb19dbf5558c61d52f0f1658fa9f7933d4e264e3e521b4a5cc9ce08978
- Size: (1273, 1236); 1902565 bytes
- References: res://assets/sprites/monsters/monster_ghost_housemaid_idle_down_00.png

### Prompt

투명 배경 PNG 게임 스프라이트 시트. 첨부의 베베 정체성 유지: 라벤더색 작은 유령 메이드, 흰 레이스 머리띠, 보라색 단발머리, 검정·크림 메이드복, 빗자루, 아래 몸은 떠다니는 유령 꼬리. 귀엽고 세련된 3D 게임 렌더, 매끈한 큰 형태와 부드러운 조명. 정확히 4열×4행 총16전신포즈: 첫행 대기2 쓰러짐2, 둘째행 이동4, 셋째행 빗자루공격4, 넷째행 청소마법4. 같은 체격과 시점, 각칸에 몸과 빗자루가 완전히 들어가며 15%빈여백. 배경 실제 투명 알파 PNG, 바닥·문구·격자·체크무늬 없음.


## graveyard_hound

- Source image path: assets/source/imagegen/uiux_completion_20260913/graveyard_hound_sheet.png
- Runtime image path: assets/sprites/uiux3d/graveyard_hound_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-c3360daf-f25f-4892-9b10-840e504a253e.png
- SHA-256: 58c900a0a07c24fd2daa03e7126b60a86f9d3c20e72676c31cd564043f2f3fd0
- Size: (1402, 1122); 1786124 bytes
- References: res://assets/sprites/monsters/monster_graveyard_hound_idle_down_00.png

### Prompt

투명 배경 PNG 게임 스프라이트 시트. 첨부 코코 정체성 유지: 작고 귀여운 검은 늑대 강아지, 보랏빛 검은 털, 커다란 뾰족귀, 밝은 파란 눈, 뼈 목걸이, 말린 꼬리 위 청색 유령불 랜턴. 세련된 3D 게임 렌더, 풍성하지만 단순하고 깨끗한 털과 부드러운 조명. 정확히4열×4행 총16전신포즈. 첫행 대기2 쓰러짐2, 둘째행 달리기4, 셋째행 물기공격4, 넷째행 유령불기술4. 같은체격과3/4시점. 각칸 몸·귀·꼬리·랜턴이 완전히 들어가고 15%빈여백. 이펙트는 몸근처 작게. 배경 실제 투명 알파 PNG. 바닥·문구·격자·체크무늬 없음.


## armored_beetle

- Source image path: assets/source/imagegen/uiux_completion_20260913/armored_beetle_sheet.png
- Runtime image path: assets/sprites/uiux3d/armored_beetle_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-cf0e8a19-cb3b-4667-8244-7802bc80abfc.png
- SHA-256: 927f06a5cc1904124245665126b51f6b705a54eec65e8d7d77f15ee5399c39a4
- Size: (1235, 1274); 2046599 bytes
- References: res://assets/sprites/monsters/monster_armored_beetle_idle_down_00.png

### Prompt

투명 배경 PNG 게임 스프라이트 시트. 첨부 톡톡 정체성 유지: 육중하지만 귀여운 작은 갑옷 딱정벌레, 둥근 청동 판금 등껍질, 보라색 보석과 반짝이는 눈, 짧은 여섯 다리와 뿔. 매끈한 고급 3D 게임 렌더처럼 입체 금속 재질, 큰 형태, 부드러운 조명. 정확히4열×4행 총16전신포즈: 첫행 대기2 쓰러짐2, 둘째행 이동4, 셋째행 몸통돌진4, 넷째행 방어자세4. 같은체격과정면3/4시점. 각칸 몸전체가 완전히 들어가고 18%빈여백. 부드러운 네이티브 투명 알파 배경. 글씨·격자·바닥·체크무늬 없음.


## spider_tailor

- Source image path: assets/source/imagegen/uiux_completion_20260913/spider_tailor_sheet.png
- Runtime image path: assets/sprites/uiux3d/spider_tailor_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-7dfc16c0-4b71-47a9-8054-96df335899f0.png
- SHA-256: 467f864617c86b6016d1bba6060fe4a891c2ca2cfe96580c67c369b1d1432e3c
- Size: (1254, 1254); 1599666 bytes
- References: res://assets/sprites/monsters/update4/monster_spider_tailor_sheet.png

### Prompt

투명 배경 PNG 게임 스프라이트 시트. 첨부 실키 정체성과 장비 유지: 귀여운 연보라 거미 재단사, 큰 보라눈과 작은 이마눈, 흰 은색 앞머리, 보라색 작업모, 은색 바늘과 보라실, 갈색 벨트에 실타래와 골무. 세련된 3D 게임 렌더의 매끈하고 풍성한 재질과 부드러운 조명. 정확히4열×4행 총16전신포즈. 첫행 대기2 쓰러짐2, 둘째행 이동4, 셋째행 바늘공격4, 넷째행 실을 엮는 기술4. 각포즈 독립된 한캐릭터. 같은체격·시점. 전체 다리·바늘·실이 각칸 안에 완전히 들어가고 18%빈여백. 효과 작게, 이웃칸 침범없음. 네이티브 투명 PNG, 문구·격자·바닥·체크무늬 없음.


## bat_courier

- Source image path: assets/source/imagegen/uiux_completion_20260913/bat_courier_sheet.png
- Runtime image path: assets/sprites/uiux3d/bat_courier_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-c55f6e27-24be-4a0d-8818-1c326fd63da1.png
- SHA-256: 1cb509ccc2eaab3aedec15d924cfc243c058c87b88e38f84e87096080a301619
- Size: (1254, 1254); 1723901 bytes
- References: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-21644691-48f4-4c17-acd2-9b7522517d0e.png

### Prompt

이 시트의 회색 체크무늬 배경을 지워서 실제 투명 배경 PNG로 만들어줘. 16개 포포 캐릭터와 소품을 그대로 유지하고 캐릭터 사이와 주변을 투명하게 만들어줘. 투명한 배경.


## investigator

- Source image path: assets/source/imagegen/uiux_completion_20260913/investigator_sheet.png
- Runtime image path: assets/sprites/uiux3d/investigator_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-9dd2ce90-ddc1-4134-a261-34ae889303de.png
- SHA-256: a98e3a405a001cb6b152945b71e6ce957094a4384709198608b5a8d6d4eb2f51
- Size: (1230, 1278); 1781304 bytes
- References: res://assets/sprites/enemies/enemy_investigator_idle_down_00.png

### Prompt

투명 배경 게임 스프라이트 시트. 첨부 조사관의 정체성 유지: 갈색머리의 젊은 남성 탐정, 갈색 제복과 외투, 황동 배지 모자, 돋보기와 수첩, 가죽 벨트. 조사와 경계하는 똑똑한 표정. 정확히 4열×4행 총16전신포즈: 첫행 대기2 쓰러짐2, 둘째행 이동4, 셋째행 공격4, 넷째행 기술4. 같은 체격과3/4시점. 각칸 전체몸·장비가 완전히 들어가고 18%빈여백, 효과는 작게. 고급 3D 게임 렌더처럼 매끈하고 입체적인 재질, 명확한 큰 형태. 배경은 실제 투명 PNG로 생성해줘. 문구·격자·체크무늬·바닥 없음.


## engineer

- Source image path: assets/source/imagegen/uiux_completion_20260913/engineer_sheet.png
- Runtime image path: assets/sprites/uiux3d/engineer_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-94337503-0cc0-405d-9a50-cf7db53b0147.png
- SHA-256: 6a5bdc308ca8abcb8c6423ae0fad43c0dbc1ddbc83583b604232ed21a9250b38
- Size: (1244, 1264); 1708693 bytes
- References: res://assets/sprites/enemies/enemy_engineer_idle_down_00.png

### Prompt

투명 배경 게임 스프라이트 시트. 첨부 공병의 정체성 유지: 갈색머리의 젊은 남성 공병, 둥근 철제 헬멧과 작업 고글, 붉은 목도리, 갈색 가죽 작업복과 공구 벨트, 작은 망치와 렌치, 장비 가방. 정확히 4열×4행 총16전신포즈: 첫행 대기2 쓰러짐2, 둘째행 이동4, 셋째행 공격4, 넷째행 기술4. 같은 체격과3/4시점. 각칸 전체몸·장비가 완전히 들어가고 18%빈여백, 효과는 작게. 고급 3D 게임 렌더처럼 매끈하고 입체적인 재질, 명확한 큰 형태. 배경은 실제 투명 PNG로 생성해줘. 문구·격자·체크무늬·바닥 없음.


## rolo

- Source image path: assets/source/imagegen/uiux_completion_20260913/rolo_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/rolo_base.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-fca56d88-33d2-4f95-99f1-a719170f8639.png
- SHA-256: a48db6d341ea373b2195c1e909790dc1ed133c0b6edace8a9f5a5c976e748957
- Size: (1024, 1536); 2489957 bytes
- References: assets/sprites/portraits/onboarding/portrait_rolo.png

### Prompt

투명 배경 PNG로 만들어줘. 첨부 인물 로로의 정체성·얼굴·색·소품을 유지해서 큰 전용 게임 초상으로 다시 그려줘. 작은 올리브색 코볼트 정찰대장, 호박색 눈, 짧은 코와 작은 송곳니, 뒤로 솟은 갈색 뿔, 큰 뾰족 귀, 녹색 짧은 후드 망토, 갈색 가죽 정찰 장비, 한 손에 말린 지도와 다른 손에 작고 안전하게 빛나는 횃불 겸 깃대. 영리하고 당당한 표정. 한 명의 전신이 화면 중앙에 완전히 들어가고 발·머리·장비 주위 여백 8%. 선명하고 매끈한 고급 3D 게임 렌더처럼 입체감 있는 재질과 부드러운 조명, 또렷한 큰 형태. 배경은 실제 알파가 있는 네이티브 투명 이미지. 배경·바닥·격자·체크무늬·문자 없음.


## selen_trainee_paladin

- Source image path: assets/source/imagegen/uiux_completion_20260913/selen_trainee_paladin_sheet.png
- Runtime image path: assets/sprites/uiux3d/selen_trainee_paladin_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-59a99efd-9926-4038-89a5-dd32e44a7018.png
- SHA-256: 95c1cdf7a51fc4bfbf2233ae6fe02486ea502c07f23a83aaf628a66479a0a870
- Size: (1296, 1213); 1790143 bytes
- References: assets/sprites/enemies/enemy_selen_paladin_idle_down_00.png, assets/sprites/portraits/onboarding/CHR_SELEN_portrait_checklist.png

### Prompt

첨부 셀렌의 정체성 보존한 투명배경 게임스프라이트 시트. 신참 성기사 검사관, 흰색과 금색 작은 투구 및 갑옷, 남색 검은 바이저에 네모난 작은 눈구멍, 푸른색 문장천, 금색 별이 있는 청색 방패와 작은 검. 중립적이고 절차에 충실한 표정, 복잡하지 않은 신참 장비. 셀렌의 기존 모양을 매끈한 입체 캐릭터로. 고급 3D 게임 렌더처럼 매끈하고 입체적인 재질, 큰 형태, 부드러운 조명. 정확히4열×4행 총16전신포즈: 첫행 대기2 쓰러짐2, 둘째행 이동4, 셋째행 공격4, 넷째행 기술4. 같은체격과정면3/4시점. 각칸 전체몸·소품이 들어가고18%빈여백. 효과작게. 실제 투명배경 PNG, 글자·바닥·격자·체크무늬 없음.


## official_hero_leon

- Source image path: assets/source/imagegen/uiux_completion_20260913/official_hero_leon_sheet.png
- Runtime image path: assets/sprites/uiux3d/official_hero_leon_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-1489aa77-0690-4c81-a8a6-9ad186180628.png
- SHA-256: c8b50d4b5f0022f824d133afaaed13ab434409eda0eb6765708d4454c0b4b6d4
- Size: (1263, 1246); 2276320 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_official_hero_leon_idle_down_00.png

### Prompt

투명배경 게임 스프라이트 시트. 첨부 정식 용사 레온 정체성 유지: 금발과 푸른 눈의 어린 남성 기사, 은색 판금과 금테두리, 남색 망토와 남색 태양 문장 방패, 큰 검. 씩씩하고 진지한 젊은 영웅. 정확히4열×4행 총16전신포즈: 첫행 대기2 쓰러짐2, 둘째행 이동4, 셋째행 공격4, 넷째행 기술4. 각칸 전체몸·장비가 완전히 들어가고18%빈여백. 같은체격과3/4시점. 고급3D게임렌더처럼 매끈한 입체재질, 큰 형태와 부드러운조명. 배경은 실제로 투명하게 생성해줘. PNG. 글씨·바닥·격자·체크무늬 없음.


## royal_scout

- Source image path: assets/source/imagegen/uiux_completion_20260913/royal_scout_sheet.png
- Runtime image path: assets/sprites/uiux3d/royal_scout_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-999b0e67-149f-456b-912b-90f06129b2ff.png
- SHA-256: ff01b0cde80704233759088225d07df9a1aed2d9d5f7889a572b5c4fc32acdf0
- Size: (1230, 1278); 1986005 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_royal_scout_idle_down_00.png

### Prompt

투명배경 게임 스프라이트 시트. 첨부 왕실 정찰병 정체성 유지: 남색머리와 푸른 후드, 하얀 상의와 가죽 갑옷, 갈색가죽·청색 망토, 황동 망원경 두 개, 민첩한 젊은 남성 척후. 고급 3D 캐릭터로. 정확히4열×4행 총16전신포즈: 첫행 대기2 쓰러짐2, 둘째행 이동4, 셋째행 공격4, 넷째행 기술4. 각칸 전체몸·장비가 완전히 들어가고18%빈여백. 같은체격과3/4시점. 고급3D게임렌더처럼 매끈한 입체재질, 큰 형태와 부드러운조명. 배경은 실제로 투명하게 생성해줘. PNG. 글씨·바닥·격자·체크무늬 없음.


## bati_dry

- Source image path: assets/source/imagegen/uiux_completion_20260913/bati_dry.png
- Runtime image path: assets/sprites/portraits/uiux3d/bati_dry.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-3486c5c8-5cf7-4ef9-a99d-6bff9e422488.png
- SHA-256: e69aa4a57ad70fb31e619e2999b1bccd9936b54f016e8946ba3c535371d3b350
- Size: (1199, 1312); 1924605 bytes
- References: assets/sprites/portraits/onboarding/CHR_BATI_portrait_dry.png

### Prompt

첨부 바티를 전용 투명배경 PNG 초상으로 다시 그려줘. 검은 박쥐 비서, 큰 귀, 반쯤 뜬 보라빛 눈과 작은 송곳니, 검정 정장과 흰 프릴 셔츠, 붉은 보석 브로치. 한손에 흰 깃펜 다른손에 갈색 장부. 절제되고 건조한 표정과 동일한 얼굴·의복·소품 유지. 고급 3D 애니메이션 게임 캐릭터의 매끈하고 입체적인 검은 털·천 재질, 과하지 않은 부드러운 조명. 허벅지 위 상반신 전체, 양귀·날개·책·손이 화면안에 완전히 들어가며8%여백. 실제 투명PNG 배경. 바닥·테두리·문구·체크무늬 없음.


## ward_breaker

- Source image path: assets/source/imagegen/uiux_completion_20260913/ward_breaker_sheet.png
- Runtime image path: assets/sprites/uiux3d/ward_breaker_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-f1ee59cd-c0ac-45b7-b802-59021d2b2cd9.png
- SHA-256: 013f72bba130d6bba2b7c292f6c653d058a122f2f70c320e33fc1d623c8f826d
- Size: (1289, 1221); 2167709 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_ward_breaker_idle_down_00.png

### Prompt

Create a native RGBA transparent-background PNG sprite sheet, a polished soft 3D game miniature render matching the attached character. Exactly 4 columns x 4 rows of separate full-body poses. Row1 idle, idle, defeated lying down, defeated lying down; row2 four walking poses; row3 four physical attack poses; row4 four ability poses. Consistent body size and front three-quarter camera. Keep EACH body and all equipment fully inside its cell, 18 percent empty margins, no overlap across cells. Soft volumetric lighting, clear broad shapes, detailed materials, smooth edges. NO text, grid, checkerboard, background, floor or shadow plane. Background must actually be transparent alpha, not painted white or checked. Preserve character identity and existing equipment. Brown spiky-haired male knight, royal navy blue cape and silver-gold armor, enormous dark rectangular metal hammer and faceted icy blue shield.


## anti_magic_archer

- Source image path: assets/source/imagegen/uiux_completion_20260913/anti_magic_archer_sheet.png
- Runtime image path: assets/sprites/uiux3d/anti_magic_archer_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-a1f2ca2c-2503-4e2d-b0ff-52ab42a48b98.png
- SHA-256: 9e29389540c84c589f448eb12a2e9f7ec782f893d5ae8bc1394cdb65c95159ae
- Size: (1268, 1241); 2004913 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_anti_magic_archer_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 은백색 머리 포니테일의 여성 궁수, 청록색 목도리와 망토, 은금 판금, 청록 보석의 큰 활, 화살통.


## royal_field_medic

- Source image path: assets/source/imagegen/uiux_completion_20260913/royal_field_medic_sheet.png
- Runtime image path: assets/sprites/uiux3d/royal_field_medic_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-7c38ae27-7a9e-4c43-9663-4168dfd10672.png
- SHA-256: 5a772788aec66c9cf021f6f3391bf8c31e388065bb8670088abdd7e79cdadecb
- Size: (1312, 1199); 1982939 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_royal_field_medic_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 갈색 단발의 온화한 여성 의무관. 백색과 녹색 모자·긴 코트, 금장 녹색 보석 지팡이, 의료 가방.


## royal_strategist_evelyn

- Source image path: assets/source/imagegen/uiux_completion_20260913/royal_strategist_evelyn_sheet.png
- Runtime image path: assets/sprites/uiux3d/royal_strategist_evelyn_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-9bad8adb-54ad-4d6c-9b4f-f5fdca21bcf8.png
- SHA-256: 97ea7d39d3bb5a3695553ec3b89800880e7b2d409320b80ce1d0d999e3736474
- Size: (1230, 1278); 1857886 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_royal_strategist_evelyn_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 백은색 턱선 단발의 여성 전략가. 남색 금장 제복 코트, 한 손 펼친 책, 다른 손 금색 지휘봉, 차분한 지성.


## roman

- Source image path: assets/source/imagegen/uiux_completion_20260913/roman_sheet.png
- Runtime image path: assets/sprites/uiux3d/roman_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-2ba60eba-c179-43bb-b05c-81ab0a67c5dd.png
- SHA-256: d2c39e88c5faa0d8fd0080971c45705da91e06eff5e58a4f6ac208a1017f19ac
- Size: (1225, 1284); 1574491 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_roman_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 검은 챙모자·검은 머리·날카로운 눈썹의 남성 조사대장. 남색 금장 긴 코트, 갈색 장부와 깃펜, 서류 두루마리 가방. 장부와 펜의 행동.


## seal_chainbearer

- Source image path: assets/source/imagegen/uiux_completion_20260913/seal_chainbearer_sheet.png
- Runtime image path: assets/sprites/uiux3d/seal_chainbearer_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-790cc44f-e6dc-4d9a-83d3-0ef50409e247.png
- SHA-256: 57a75394b91fc2b869e82d6565818725b1ae6bcdb1c6e1cc32327394c6c557e7
- Size: (1254, 1254); 2162179 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update3_atlas/enemy_seal_chainbearer_sheet.png

### Prompt

undefined흰 머리·검은 복면, 백은·금 장식의 길쭉한 기사 갑옷과 흰 코트. 등 뒤 작은 금색 가시 고리, 금 고리가 달린 사슬을 든 봉인 사슬병. 원본 자홍 배경은 버리고 실제 투명으로 생성.


## reliquary_guard

- Source image path: assets/source/imagegen/uiux_completion_20260913/reliquary_guard_sheet.png
- Runtime image path: assets/sprites/uiux3d/reliquary_guard_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-8028f58a-aa0a-453b-b4ef-d449e17cbec5.png
- SHA-256: 545e40873dadcf3a580ccffba04ba804e2e3308f0310d268c582bb5630e620d0
- Size: (1254, 1254); 2108644 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update3_atlas/enemy_reliquary_guard_sheet.png

### Prompt

undefined얼굴이 가려진 육중한 금색 중갑 기사. 투구 위 하얀 수정 장식, 남색 천, 성물함 모양의 커다란 금 방패와 철퇴. 원본 자홍 배경은 버리고 실제 투명으로 생성.


## choir_exorcist

- Source image path: assets/source/imagegen/uiux_completion_20260913/choir_exorcist_sheet.png
- Runtime image path: assets/sprites/uiux3d/choir_exorcist_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-dc5cf0c6-33eb-4788-9f35-aa8f7832d833.png
- SHA-256: 873839e2cf8bb79fe1a91c11ddb61a9fbf3611c7ffcf5b1215a5c20a4cb791bb
- Size: (1230, 1278); 1737252 bytes
- References: res://assets/sprites/enemies/update3_atlas/enemy_choir_exorcist_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 갈색 머리의 남성 성가대 마법사, 흰색과 금색 긴 성직복, 작은 황금지팡이와 남색 성가집. 매끈하고 부드러운 3D 게임 캐릭터 재질. 정확히 4열×4행 총16개 독립된 전신 자세. 첫행 대기2 쓰러짐2, 둘째행 걷기4, 셋째행 지팡이 공격4, 넷째행 작은 음표마법4. 각칸 중앙60%영역 안에 몸과 무기와 효과가 모두 들어가고 사방20% 빈 여백을 둔다. 같은 체격·3/4 시점. 이펙트는 몸 옆의 작은 음표 두세개만. 배경은 실제로 투명하게. 바닥·격자·글자 없음.


## bounty_tracker

- Source image path: assets/source/imagegen/uiux_completion_20260913/bounty_tracker_sheet.png
- Runtime image path: assets/sprites/uiux3d/bounty_tracker_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-09a3e90d-4309-42a6-962f-2c54d0b03f3d.png
- SHA-256: 0849c7257efdfe556e544a2699b1ae6771aa0a3f2e5c322f92bf0a20648ce30b
- Size: (1254, 1254); 1847882 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update3_atlas/enemy_bounty_tracker_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 검은 머리를 뒤로 묶은 수염난 남성 추적자, 갈색 가죽 중갑과 헤진 갈색 망토, 길고 어두운 갈고리 창, 허리에 작은 서류 부적. 원본 자홍 배경은 버리고 실제 투명으로 생성.


## combat_alchemist

- Source image path: assets/source/imagegen/uiux_completion_20260913/combat_alchemist_sheet.png
- Runtime image path: assets/sprites/uiux3d/combat_alchemist_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-84b26b11-bba7-451a-85ad-0e697e18473e.png
- SHA-256: 58307e5f895f7f27ce9c2762f9882c799a542c3039c6637e7b8a3439daf327be
- Size: (1254, 1254); 1640761 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update3_atlas/enemy_combat_alchemist_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 갈색 짧은 머리와 짧은 수염의 남성 연금술사. 어두운 녹색 옷과 황동 어깨갑옷·베이지 앞치마, 가방에 초록 물약병들, 물약을 던지는 행동. 원본 자홍 배경은 버리고 실제 투명으로 생성.


## ledger_binder

- Source image path: assets/source/imagegen/uiux_completion_20260913/ledger_binder_sheet.png
- Runtime image path: assets/sprites/uiux3d/ledger_binder_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-2fa0496a-b652-4496-8771-f3427a329bc5.png
- SHA-256: 4fe2f6c2d7fcf262e8129fe1aefbe8d1a82a9fb6c4b6e86f261ea40eb1b66f6b
- Size: (1254, 1254); 2074274 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update3_atlas/enemy_ledger_binder_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 얼굴 대신 세워진 낡은 갈색 장부 책머리를 가진 마법사. 갈색 금장 후드로브, 봉인장식 지팡이와 사슬로 연결된 책, 작은 종이 부적. 원본 자홍 배경은 버리고 실제 투명으로 생성.


## coal_spark

- Source image path: assets/source/imagegen/uiux_completion_20260913/coal_spark_sheet.png
- Runtime image path: assets/sprites/uiux3d/coal_spark_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-6f0fe697-06e2-448e-a4f3-aec75fcd293e.png
- SHA-256: 706795d27cf41cd73041a388e7f2d4710a419927a7704b4b75af6a37bc8e97ca
- Size: (1254, 1254); 1714900 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update4/region/enemy_coal_spark_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 짧고 통통한 검은 숯바위 정령, 뾰족한 검은 돌갑각과 주황색 발광 눈·틈새, 머리 위 밝은 주황 불길, 작은 손발. 원본 자홍 배경 제거하고 실제 투명으로 생성.


## dusk_courier

- Source image path: assets/source/imagegen/uiux_completion_20260913/dusk_courier_sheet.png
- Runtime image path: assets/sprites/uiux3d/dusk_courier_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-e406bdb0-2935-4d57-ac63-530e6dd0f640.png
- SHA-256: 5a5f252e3360a6403783fff1ab3bc96602ff97da0b15dd472d251e568926fe81
- Size: (1254, 1254); 1745960 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update4/region/enemy_dusk_courier_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 어두운 보라 후드를 쓴 신비로운 인간형 전령, 눈만 보이는 어두운 얼굴, 등 뒤 큰 박쥐 날개, 갈색 우편가방과 봉투, 은색 짧은 단검. 이동행은 날개로 부유하는 네 자세. 원본 자홍 배경 제거하고 실제 투명으로 생성.


## bronze_automaton

- Source image path: assets/source/imagegen/uiux_completion_20260913/bronze_automaton_sheet.png
- Runtime image path: assets/sprites/uiux3d/bronze_automaton_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-5bcc97f5-a6bc-41de-b302-5eb2cb96722f.png
- SHA-256: 774fdefd1d163f931f8b45c195ebfbbab0bfa88bb9122149854374a530bb7368
- Size: (1254, 1254); 2090899 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update4/region/enemy_bronze_automaton_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 육중하고 둥근 청동 증기 로봇, 원통형 투구머리의 주황색 눈 틈, 커다란 주먹과 두꺼운 다리, 가슴의 주황 화로와 등 뒤 태엽·증기배관. 원본 자홍 배경 제거하고 실제 투명으로 생성.


## spore_doll

- Source image path: assets/source/imagegen/uiux_completion_20260913/spore_doll_sheet.png
- Runtime image path: assets/sprites/uiux3d/spore_doll_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-939baa4c-5d18-4c26-98e5-1f5a91d7e8c6.png
- SHA-256: b5bf11698fd5f157868177a782bd1f5f6567237dc75e8e98f468e5984082135d
- Size: (1254, 1254); 1943989 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update4/region/enemy_spore_doll_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 통통한 나무·천 인형, 빛나는 작은 하늘색 눈, 커다란 푸른 회색 버섯 갓, 이끼 머리카락과 낡은 갈색 옷, 울퉁불퉁한 나뭇가지 지팡이와 파란 포자주머니. 원본 자홍 배경 대신 실제 투명으로 생성.


## root_tender

- Source image path: assets/source/imagegen/uiux_completion_20260913/root_tender_sheet.png
- Runtime image path: assets/sprites/uiux3d/root_tender_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-fbd54ca1-b4e2-46b9-97ba-f48184af9ae5.png
- SHA-256: 76644eb43ba648f46e50417ed7f4914b171c523ab009c6fe6ac42019a616284f
- Size: (1254, 1254); 2389112 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update4/region/enemy_root_tender_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 이끼 후드를 쓴 굵고 큰 나무껍질 인간형 정원사, 빛나는 금색 눈, 뿌리 갑옷과 잎사귀, 긴 가지자루의 두갈래 갈고리 낫. 원본 자홍 배경 대신 실제 투명으로 생성.


## rolo_briefing

- Source image path: assets/source/imagegen/uiux_completion_20260913/rolo_briefing.png
- Runtime image path: assets/sprites/portraits/uiux3d/rolo_briefing.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-c3b3203b-d582-47a3-99b7-0fb57bc82588.png
- SHA-256: b37129eea34614d685b4ed018ada51175e635b0597dea155a2f811b60f860a67
- Size: (1024, 1536); 2507254 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/uiux3d/rolo_base.png

### Prompt

실제 투명 배경 PNG로 만들어줘. 첨부 로로와 같은 올리브색 작은 코볼트 정찰병의 큰 게임 대화 초상 한 장. 머리·귀·뿔·얼굴·의상·녹색 망토·가죽 장구·말린 지도·등의 깃발을 동일하게 유지. 진지하고 자신있게 작은 지도를 펼쳐 보고하는 표정과 자세. 고급 3D 게임 렌더처럼 부드럽고 입체적인 재질, 또렷한 눈과 표정. 전신이 중앙에 완전히 들어가며 사방 빈 여백. 단일 캐릭터 한 명, 글자나 배경 장면 없이 진짜 투명 PNG.


## rolo_mischief

- Source image path: assets/source/imagegen/uiux_completion_20260913/rolo_mischief.png
- Runtime image path: assets/sprites/portraits/uiux3d/rolo_mischief.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-5ded6610-76fe-43ec-ba07-a09963704dc4.png
- SHA-256: e966fc0b30a8fff1811ab8fb9f90e9376e34cbff2cc9f43b3ff46463dddc186f
- Size: (1024, 1536); 2493368 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/uiux3d/rolo_base.png

### Prompt

실제 투명 배경 PNG로 만들어줘. 첨부 로로와 같은 올리브색 작은 코볼트 정찰병의 큰 게임 대화 초상 한 장. 머리·귀·뿔·얼굴·의상·녹색 망토·가죽 장구·말린 지도·등의 깃발을 동일하게 유지. 한쪽 눈을 살짝 감고 능청스럽게 웃으며 작은 주머니를 들어 보여주는 장난꾸러기 표정과 자세. 고급 3D 게임 렌더처럼 부드럽고 입체적인 재질, 또렷한 눈과 표정. 전신이 중앙에 완전히 들어가며 사방 빈 여백. 단일 캐릭터 한 명, 글자나 배경 장면 없이 진짜 투명 PNG.


## rolo_flustered

- Source image path: assets/source/imagegen/uiux_completion_20260913/rolo_flustered.png
- Runtime image path: assets/sprites/portraits/uiux3d/rolo_flustered.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-46992c63-3a54-4e01-98ad-11ae0184fcc7.png
- SHA-256: f6eca01b15b40a7a5f343ac856f1818fd7a9b2d370ea25b8af4fdd4f7384e428
- Size: (1024, 1536); 2432433 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/uiux3d/rolo_base.png

### Prompt

실제 투명 배경 PNG로 만들어줘. 첨부 로로와 같은 올리브색 작은 코볼트 정찰병의 큰 게임 대화 초상 한 장. 머리·귀·뿔·얼굴·의상·녹색 망토·가죽 장구·말린 지도·등의 깃발을 동일하게 유지. 눈을 동그랗게 뜨고 당황해 움찔하며 지도를 꽉 붙드는 표정과 자세. 고급 3D 게임 렌더처럼 부드럽고 입체적인 재질, 또렷한 눈과 표정. 전신이 중앙에 완전히 들어가며 사방 빈 여백. 단일 캐릭터 한 명, 글자나 배경 장면 없이 진짜 투명 PNG.


## bati_tutorial

- Source image path: assets/source/imagegen/uiux_completion_20260913/bati_tutorial.png
- Runtime image path: assets/sprites/portraits/uiux3d/bati_tutorial.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-1dc3071c-b978-4400-9392-92e991403363.png
- SHA-256: 27ec1ea4336a6d97c857570443f7aad8e33d9d677374776120d689bac2b405b8
- Size: (1199, 1312); 2055151 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/uiux3d/bati_dry.png, C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/onboarding/CHR_BATI_portrait_tutorial.png

### Prompt

실제 투명 배경 PNG 게임 대화 초상 한 장으로 생성해줘. 매끈한 고급 3D 게임 렌더처럼 입체적인 형태·재질·부드러운 스튜디오 조명, 또렷한 얼굴. 단일 인물이 중앙에 완전히 들어가며 사방 10% 빈 여백. 배경 장면·바닥·글자 없이 진짜 투명 알파. 첫 이미지 바티와 같은 검은 박쥐 비서. 보라 눈·큰 귀·작은 날개·검은 정장과 흰 주름 셔츠·붉은 브로치·클립보드·깃펜을 유지. 설명하듯 입을 열고 깃펜을 약간 들어 차분히 알려주는 자세. 두 번째 이미지의 설명 표정 참고.


## bati_stern

- Source image path: assets/source/imagegen/uiux_completion_20260913/bati_stern.png
- Runtime image path: assets/sprites/portraits/uiux3d/bati_stern.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-25283b69-b4aa-4502-bd3c-85ea9c632799.png
- SHA-256: c0b89d4834fef4b77c605f576d1cb6a86d95dbb36d51ce479aa5492f8a76e771
- Size: (1199, 1312); 1916690 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/uiux3d/bati_dry.png, C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/onboarding/CHR_BATI_portrait_stern.png

### Prompt

실제 투명 배경 PNG 게임 대화 초상 한 장으로 생성해줘. 매끈한 고급 3D 게임 렌더처럼 입체적인 형태·재질·부드러운 스튜디오 조명, 또렷한 얼굴. 단일 인물이 중앙에 완전히 들어가며 사방 10% 빈 여백. 배경 장면·바닥·글자 없이 진짜 투명 알파. 첫 이미지 바티와 동일한 검은 박쥐 비서, 모든 의상·장비·귀·눈 유지. 눈썹을 찌푸리고 작은 입을 다문 엄격한 경고 표정, 깃펜을 들어 단호하게 가리키기. 두 번째 이미지의 엄격한 표정 참고.


## bati_dry_happy

- Source image path: assets/source/imagegen/uiux_completion_20260913/bati_dry_happy.png
- Runtime image path: assets/sprites/portraits/uiux3d/bati_dry_happy.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-64731631-dd42-4df5-99eb-f3a9fc99f673.png
- SHA-256: 31204fd1c00ee4690f2ec809ceae2de14121e4fd36bce117c6c8125ed19da8da
- Size: (1199, 1312); 1909076 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/uiux3d/bati_dry.png, C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/onboarding/CHR_BATI_portrait_dry_happy.png

### Prompt

실제 투명 배경 PNG 게임 대화 초상 한 장으로 생성해줘. 매끈한 고급 3D 게임 렌더처럼 입체적인 형태·재질·부드러운 스튜디오 조명, 또렷한 얼굴. 단일 인물이 중앙에 완전히 들어가며 사방 10% 빈 여백. 배경 장면·바닥·글자 없이 진짜 투명 알파. 첫 이미지 바티와 동일한 검은 박쥐 비서, 의상·장비·얼굴 유지. 반쯤 뜬 보라 눈에 입꼬리가 살짝 올라간 절제된 만족의 미소, 클립보드와 깃펜을 든 여유 있는 자세. 두 번째 이미지 표정 참고.


## darklord_base

- Source image path: assets/source/imagegen/uiux_completion_20260913/darklord_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/darklord_base.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-b659a11a-0a29-4fe7-ab95-b682cf3ff858.png
- SHA-256: ed26ccef0635d55f8494c1a51c418f032b8db044de5d8c1a82493c597c747e65
- Size: (1024, 1536); 2683297 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/portraits/onboarding/portrait_darklord_player.png

### Prompt

실제 투명 배경 PNG 게임 대화 초상 한 장으로 생성해줘. 매끈한 고급 3D 게임 렌더처럼 입체적인 형태·재질·부드러운 스튜디오 조명, 또렷한 얼굴. 단일 인물이 중앙에 완전히 들어가며 사방 10% 빈 여백. 배경 장면·바닥·글자 없이 진짜 투명 알파. 첨부 신입 마왕의 정체성 그대로: 검은 헝클어진 머리, 머리 양쪽 검은 뿔, 붉은 눈, 젊은 성인 남성, 검붉은 금장 귀족 코트, 검은 깃털 어깨와 금빛 갑주, 붉은 보석. 자신만만하지만 친근한 살짝 미소. 머리부터 허리까지 대화 초상 한 명, 뿔과 팔이 잘리지 않게.


## rival_vesper_council_champion

- Source image path: assets/source/imagegen/uiux_completion_20260913/rival_vesper_council_champion_sheet.png
- Runtime image path: assets/sprites/uiux3d/rival_vesper_council_champion_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-f61d166b-aed8-48a8-8f7c-f2a7daf7dda1.png
- SHA-256: 36a9f9b01aa5d05c5f9c9e5234575a0f01ac5bb2364130ddaeec9dca9ed8a528
- Size: (1254, 1254); 1936960 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/update4/rivals/enemy_rival_vesper_council_champion_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 베스퍼: 키 큰 귀의 짙은 남보라 박쥐 마왕. 은색 눈, 작은 날개, 고급 남색 은장 망토와 초승달 목장식, 회중시계와 우편봉투. 우편 모자 없음. 포포보다 날카롭고 성숙한 얼굴.


## slime_gate_bulwark

- Source image path: assets/source/imagegen/uiux_completion_20260913/slime_gate_bulwark_sheet.png
- Runtime image path: assets/sprites/uiux3d/slime_gate_bulwark_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-4945edf4-5e54-4bee-acee-11ce5c9064c4.png
- SHA-256: 3dfc78ccd2af51b7a78b47a33a5c3d80a565ed7c581ae1d03a729c50081a4cac
- Size: (1536, 1024); 2886642 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/monsters/monster_slime_gate_bulwark_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 보라색 둥근 푸딩 슬라임. 머리 위 초콜릿·크림·빨간 체리, 양쪽 커다란 청록 수정 방벽 갑옷과 금색 문장. 웃는 검은 동그란 눈. 두꺼운 젤과 유리처럼 빛나는 보호 갑주.


## goblin_ambush_captain

- Source image path: assets/source/imagegen/uiux_completion_20260913/goblin_ambush_captain_sheet.png
- Runtime image path: assets/sprites/uiux3d/goblin_ambush_captain_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-1ccb54ad-7c4b-4f33-848f-a63f9f883db6.png
- SHA-256: 439b74315f98a154361067d4a2187a8ed4d43e8eaee0905e915df15288124ca9
- Size: (1242, 1266); 1644308 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/monsters/monster_goblin_ambush_captain_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 매복대장 곱. 성숙한 녹색 고블린 얼굴과 길고 뾰족한 귀, 검은 가죽 두건·갈색 가죽 중갑·붉은 목도리, 긴 은날의 창, 벨트에 작은 도구. 마른 장난꾸러기 전사 체격.


## goblin_vault_keeper

- Source image path: assets/source/imagegen/uiux_completion_20260913/goblin_vault_keeper_sheet.png
- Runtime image path: assets/sprites/uiux3d/goblin_vault_keeper_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-60db9dda-c5f1-4e85-9721-22a20d7e4fde.png
- SHA-256: 677a037c06ee770a8d1b3b575d8fdf75ff949f17d34d109841cef985a74663ed
- Size: (1363, 1154); 1793620 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/monsters/monster_goblin_vault_keeper_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 금고지기 곱. 성숙한 녹색 고블린 긴 귀와 노란 눈, 금테 검은 철갑 투구와 중갑, 붉은 목도리, 커다란 잠금장치 문장의 직사각 방패와 긴 창, 허리에 황금 열쇠꾸러미.


## imp_ember_shaman

- Source image path: assets/source/imagegen/uiux_completion_20260913/imp_ember_shaman_sheet.png
- Runtime image path: assets/sprites/uiux3d/imp_ember_shaman_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-45d102d1-705d-4a99-8663-f0f2272fe6a4.png
- SHA-256: ed143f03d7b15bd86c0b7033a1a644720da32c13a6a71f7014e4d67493d951dd
- Size: (1266, 1242); 2503566 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/monsters/monster_imp_ember_shaman_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 잿불 주술사 핀. 밝은 분홍 머리·분홍 붉은 피부·검은 두 뿔·황금 눈. 검보라 깃털 망토, 황동 보석장식, 휘어진 나무 지팡이에 초록 등불, 손 위 푸른-자홍 작은 도깨비불. 부유하는 작은 악마.


## monster_binder

- Source image path: assets/source/imagegen/uiux_completion_20260913/monster_binder_sheet.png
- Runtime image path: assets/sprites/uiux3d/monster_binder_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-c1f935d1-58ce-4bd3-969a-f33a96be2134.png
- SHA-256: 6a7b75e2a2ca6f6d6f5ae0c9f1ddcf10a5e9dea37e47d0db5fe954fab2e32e10
- Size: (1278, 1230); 2106130 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_monster_binder_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 금빛 갈색 머리의 여성 마물 구속병. 높은 포니테일, 은금색 갑옷과 남색 망토, 한 손 무거운 금속 사슬, 다른 손 둥근 밧줄 그물. 장비와 머리가 모든 칸에 완전히 들어가게. 원본의 불투명 배경이나 체크무늬를 따라그리지 말고 배경 영역은 진짜 투명 PNG 알파 0으로 만들어줘.


## supply_raider

- Source image path: assets/source/imagegen/uiux_completion_20260913/supply_raider_sheet.png
- Runtime image path: assets/sprites/uiux3d/supply_raider_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-e7ec688f-0444-47a1-80e7-3fbb9b70c6a0.png
- SHA-256: 3e0efafd49db1c0955d854cdbd659a4a87277dbd43489fb0dd87068e03b58acc
- Size: (1312, 1199); 1647310 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/enemies/enemy_supply_raider_idle_down_00.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 보급 약탈병. 남색 두건과 복면, 크림색 소매와 갈색 가죽 갑옷, 초록 허리끈. 긴 갈고리 장대와 직사각 작은 목재 상자. 두 무기를 모든 칸 안에 온전히 담아. 원본의 불투명 배경이나 체크무늬를 따라그리지 말고 배경 영역은 진짜 투명 PNG 알파 0으로 만들어줘.


## crown_toktok_royal_armorer

- Source image path: assets/source/imagegen/uiux_completion_20260913/crown_toktok_royal_armorer_sheet.png
- Runtime image path: assets/sprites/uiux3d/crown_toktok_royal_armorer_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-73b9295b-3e1e-4d8a-a451-982f1d8e7c48.png
- SHA-256: db1db4f35cd568881d3547a0603a2b587e4f2e5e2a2570c5a549717ac4507c30
- Size: (1254, 1254); 2098462 bytes
- References: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/assets/sprites/monsters/update4/crowns/monster_toktok_crown_armorer_sheet.png

### Prompt

실제 투명 배경 PNG로 생성해줘. 첨부 캐릭터를 부드러운 조명과 선명한 입체 재질의 고급 3D 게임 캐릭터로 개선해. 정체성·의상·장비 유지. 게임 애니메이션용 정확히 4열×4행의 16개 독립된 전신 자세. 첫행 대기2·쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 같은 체격·3/4 시점. 각각의 칸에 몸과 장비가 완전히 들어가고 가장자리에 18% 빈 여백을 남겨. 각 자세끼리 완전히 떨어져 있어야 해. 그림자 바닥 없이 배경은 투명 알파로 생성. 글자와 선 없음. 톡톡: 짧고 둥근 여섯다리 갑주 딱정벌레, 청동·검정 판금, 보라눈과 보석, 황금왕관 등성이와 큰 보라수정. 참조의 자홍색 바탕은 유지하지 말고 실제 투명 배경으로 생성.


## darklord_proud

- Source image path: assets/source/imagegen/uiux_completion_20260913/darklord_proud.png
- Runtime image path: assets/sprites/portraits/uiux3d/darklord_proud.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-5bb0954f-e263-461a-9477-9480c7c5234a.png
- SHA-256: 57d32c29c3d5317005b925d92588dbdbf1e60cec8bc1969f334467faa96804ab
- Size: (1024, 1536); 2722079 bytes
- References: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-b659a11a-0a29-4fe7-ab95-b682cf3ff858.png

### Prompt

실제 투명 배경 PNG로 생성. 첨부와 동일한 젊은 성인 남성 마왕, 동일한 얼굴과 뿔, 검정 머리·붉은 눈, 검정·붉은색·금색 의상과 검은 깃털 어깨망토·붉은 보석. 같은 고급 3D 게임 캐릭터 재질과 조명. 허벅지 위까지의 대화용 초상 한 명. 뿔과 손·어깨가 잘리지 않고 가장자리 8% 빈 여백. 자신만만하고 우쭐한 미소, 턱을 살짝 들고 가슴에 손. 단색 배경 없이 네이티브 투명 알파 배경, 글자 없음.


## darklord_offended

- Source image path: assets/source/imagegen/uiux_completion_20260913/darklord_offended.png
- Runtime image path: assets/sprites/portraits/uiux3d/darklord_offended.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-5fed9f84-0c6d-41fd-af3c-7dcf3aed00b7.png
- SHA-256: 175f4ac798b456433ef55d4737a6bb419343bea2c3945951b36ee06d0d6d0dce
- Size: (1024, 1536); 2685127 bytes
- References: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-b659a11a-0a29-4fe7-ab95-b682cf3ff858.png

### Prompt

실제 투명 배경 PNG로 생성. 첨부와 동일한 젊은 성인 남성 마왕, 동일한 얼굴과 뿔, 검정 머리·붉은 눈, 검정·붉은색·금색 의상과 검은 깃털 어깨망토·붉은 보석. 같은 고급 3D 게임 캐릭터 재질과 조명. 허벅지 위까지의 대화용 초상 한 명. 뿔과 손·어깨가 잘리지 않고 가장자리 8% 빈 여백. 자존심이 상해 입을 다문 불만스러운 표정, 팔짱. 단색 배경 없이 네이티브 투명 알파 배경, 글자 없음.


## darklord_flustered

- Source image path: assets/source/imagegen/uiux_completion_20260913/darklord_flustered.png
- Runtime image path: assets/sprites/portraits/uiux3d/darklord_flustered.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-30de9e17-c992-44d9-afd7-957c757d619f.png
- SHA-256: ca24ec02ba0b9b9217804a8369465c6aa5140c3e406717a46645e8be070fedbc
- Size: (1024, 1536); 2701935 bytes
- References: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-b659a11a-0a29-4fe7-ab95-b682cf3ff858.png

### Prompt

실제 투명 배경 PNG로 생성. 첨부와 동일한 젊은 성인 남성 마왕, 동일한 얼굴과 뿔, 검정 머리·붉은 눈, 검정·붉은색·금색 의상과 검은 깃털 어깨망토·붉은 보석. 같은 고급 3D 게임 캐릭터 재질과 조명. 허벅지 위까지의 대화용 초상 한 명. 뿔과 손·어깨가 잘리지 않고 가장자리 8% 빈 여백. 예상 밖 상황에 당황한 표정, 눈을 크게 뜨고 손을 조금 들어 멈칫. 단색 배경 없이 네이티브 투명 알파 배경, 글자 없음.


## darklord_serious

- Source image path: assets/source/imagegen/uiux_completion_20260913/darklord_serious.png
- Runtime image path: assets/sprites/portraits/uiux3d/darklord_serious.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-284e1e1f-73d2-4f18-9109-9cf466e98e36.png
- SHA-256: 87dd85c179c84bfd70989ca7587c155589b93a56bd7901c4432d8c16140c6245
- Size: (1024, 1536); 2700230 bytes
- References: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-b659a11a-0a29-4fe7-ab95-b682cf3ff858.png

### Prompt

실제 투명 배경 PNG로 생성. 첨부와 동일한 젊은 성인 남성 마왕, 동일한 얼굴과 뿔, 검정 머리·붉은 눈, 검정·붉은색·금색 의상과 검은 깃털 어깨망토·붉은 보석. 같은 고급 3D 게임 캐릭터 재질과 조명. 허벅지 위까지의 대화용 초상 한 명. 뿔과 손·어깨가 잘리지 않고 가장자리 8% 빈 여백. 집중하고 진지한 표정, 입 다물고 눈썹 약간 모음. 단색 배경 없이 네이티브 투명 알파 배경, 글자 없음.


## darklord_command

- Source image path: assets/source/imagegen/uiux_completion_20260913/darklord_command.png
- Runtime image path: assets/sprites/portraits/uiux3d/darklord_command.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-8cedb1c5-bd55-4bf3-b8ce-5a60d47216ec.png
- SHA-256: 891c1bb3ed48a029e62dbf60da45cd20498e80e91c2260e4d1d1685b20c173b1
- Size: (1024, 1536); 2741533 bytes
- References: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-b659a11a-0a29-4fe7-ab95-b682cf3ff858.png

### Prompt

실제 투명 배경 PNG로 생성. 첨부와 동일한 젊은 성인 남성 마왕, 동일한 얼굴과 뿔, 검정 머리·붉은 눈, 검정·붉은색·금색 의상과 검은 깃털 어깨망토·붉은 보석. 같은 고급 3D 게임 캐릭터 재질과 조명. 허벅지 위까지의 대화용 초상 한 명. 뿔과 손·어깨가 잘리지 않고 가장자리 8% 빈 여백. 결연한 지휘 표정, 손을 앞으로 뻗어 명령하는 자세. 단색 배경 없이 네이티브 투명 알파 배경, 글자 없음.


## crown_pudding_royal_bastion

- Source image path: assets/source/imagegen/uiux_completion_20260913/crown_pudding_royal_bastion_sheet.png
- Runtime image path: assets/sprites/uiux3d/crown_pudding_royal_bastion_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-c764adb3-7ea8-4d73-b5dc-cc1f68bef89f.png
- SHA-256: 89a10764d572e8666c81d9ce308024490bdd11b7fc23beeb521dc6a00721895d
- Size: (1536, 1024); 2554140 bytes
- References: res://assets/sprites/monsters/update4/crowns/monster_slime_crown_bastion_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 푸딩: 초콜릿과 생크림과 체리가 얹힌 보라색 젤리 슬라임, 커다란 황금 왕관 장식, 청록색 수정 성벽 갑옷과 양쪽 방패. 귀엽고 둥근 형태. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## crown_gob_midnight_marshal

- Source image path: assets/source/imagegen/uiux_completion_20260913/crown_gob_midnight_marshal_sheet.png
- Runtime image path: assets/sprites/uiux3d/crown_gob_midnight_marshal_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-ca3f8d70-782e-49f5-89ce-c48f155c6fa0.png
- SHA-256: 30940b771d9f7ee9902c880a538bc06f21fef7c157ca50c6a3ddf2124c9c3443
- Size: (1287, 1222); 1687397 bytes
- References: res://assets/sprites/monsters/update4/crowns/monster_goblin_crown_marshal_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 곱: 성숙한 녹색 고블린, 검정 후드와 검정·금색 갑옷, 황금 왕관과 빨강 목도리, 금색 창날의 긴 창, 황금 열쇠와 체인. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## crown_pynn_castle_flame_sage

- Source image path: assets/source/imagegen/uiux_completion_20260913/crown_pynn_castle_flame_sage_sheet.png
- Runtime image path: assets/sprites/uiux3d/crown_pynn_castle_flame_sage_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-d8e7b86d-9a1c-4495-ac23-bd9a394d5941.png
- SHA-256: 234a799ce681c410d85c90bbe76f744770d7fef475d1576021aa28253550409f
- Size: (1287, 1222); 1995304 bytes
- References: res://assets/sprites/monsters/update4/crowns/monster_imp_crown_flame_sage_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 핀: 분홍 머리와 분홍 피부, 검은 뿔, 황금 보석 왕관, 검정·보라색 깃털 마법 의상, 자홍빛 불꽃 지팡이. 불꽃은 작은 범위. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## crown_mori_grand_mycelial_priest

- Source image path: assets/source/imagegen/uiux_completion_20260913/crown_mori_grand_mycelial_priest_sheet.png
- Runtime image path: assets/sprites/uiux3d/crown_mori_grand_mycelial_priest_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-ed359dd3-58ad-410b-b752-5e1c7e4e9a19.png
- SHA-256: 1cf7fa64c84b89449c7670cb647fe8a94766f2384dedbaa337cde4d83991a0b1
- Size: (1272, 1236); 1951825 bytes
- References: res://assets/sprites/monsters/update4/crowns/monster_mori_crown_priest_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 모리: 동그란 크림색 얼굴의 버섯, 크림색 점무늬 자주색 큰 버섯갓에 황금장식과 흰보석, 흰 로브와 금색 스톨, 녹색잎 망토, 녹색빛 구슬 나무 지팡이. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## crown_popo_grand_night_courier

- Source image path: assets/source/imagegen/uiux_completion_20260913/crown_popo_grand_night_courier_sheet.png
- Runtime image path: assets/sprites/uiux3d/crown_popo_grand_night_courier_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-b5eecd80-0c09-4c26-8e7e-80f380f6a61c.png
- SHA-256: 60aedc4ba66b3f360516d432e754d9c45a8321c426e0d601244c2d7700ccc372
- Size: (1237, 1271); 1908863 bytes
- References: res://assets/sprites/monsters/update4/crowns/monster_popo_crown_courier_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 포포: 청흑색 털의 귀여운 작은 박쥐, 커다란 보라눈과 귀, 남색·보라 전령 모자 위 금관, 금망토 잠금장치·달 펜던트, 편지가 든 갈색 우편가방. 날개를 포함한 전신. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## rival_brassa_council_champion

- Source image path: assets/source/imagegen/uiux_completion_20260913/rival_brassa_council_champion_sheet.png
- Runtime image path: assets/sprites/uiux3d/rival_brassa_council_champion_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-5ead2f3d-86d2-447c-b4fe-7c429454e227.png
- SHA-256: 25ca583a167f5b0a99720994bf0e5448750db3afa19f2ef421ca1983cadb580d
- Size: (1335, 1178); 1952567 bytes
- References: res://assets/sprites/enemies/update4/rivals/enemy_rival_brassa_council_champion_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 브라사: 검은 회색 피부의 작고 강인한 여성 악마 공방마왕. 머리 뒤 검은 번, 두 뿔, 주황 눈, 검은 금장 작업복·가죽 앞치마, 큰 황동 종과 스패너. 뾰족 큰 눈과 얼굴 정체성 보존. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## rival_mirella_council_champion

- Source image path: assets/source/imagegen/uiux_completion_20260913/rival_mirella_council_champion_sheet.png
- Runtime image path: assets/sprites/uiux3d/rival_mirella_council_champion_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-b099368c-c816-491c-b077-12859b0f768b.png
- SHA-256: 101f11060e36d919b0f4c882ca4c2a1e5e994d3acc69f77fca5dadb5db01966f
- Size: (1312, 1199); 2168183 bytes
- References: res://assets/sprites/enemies/update4/rivals/enemy_rival_mirella_council_champion_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 미렐라: 은백색 단발과 보라 눈의 작은 요정 여성 마왕, 커다란 연보라 버섯 우산모자와 흰 꽃, 모자에서 늘어진 녹색 덩굴과 작은 등, 보라 회색 식물 드레스. 정원 가위와 꽃 담긴 작은 석함. 사랑스럽고 차분한 표정. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## imp_flame_adept

- Source image path: assets/source/imagegen/uiux_completion_20260913/imp_flame_adept_sheet.png
- Runtime image path: assets/sprites/uiux3d/imp_flame_adept_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-95d85a7b-7de4-4d12-b749-b76d5b213385.png
- SHA-256: a08df749a1ef3a23db282dc7641f919869adcc48dabd2debace9788e93f1b304
- Size: (1227, 1282); 2096161 bytes
- References: res://assets/sprites/monsters/monster_imp_flame_adept_idle_down_00.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 화염 숙련자 핀. 밝은 분홍색 짧은 머리, 붉은 분홍 피부, 검은 뿔 두 개, 황금 눈, 검보라·진분홍 불꽃 형태 날개/망토와 금장 악마옷, 자홍 불꽃 지팡이. 부유하는 작은 악마. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## slime_rescue_alchemy_gel

- Source image path: assets/source/imagegen/uiux_completion_20260913/slime_rescue_alchemy_gel_sheet.png
- Runtime image path: assets/sprites/uiux3d/slime_rescue_alchemy_gel_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-81676191-9de6-48a4-8048-ea67446a4df7.png
- SHA-256: 75a96a0fcc25afba00ea4bffe63be49e50ebc55597719c854ab9fcdc0fc7edbe
- Size: (1284, 1225); 2062108 bytes
- References: res://assets/sprites/monsters/monster_slime_rescue_alchemy_gel_idle_down_00.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 구조 연금 젤 푸딩. 큰 보라색 푸딩 슬라임과 머리 위 초콜릿·크림·빨간 체리. 옅은 연보라 구급천 망토, 녹색 십자가 금메달과 허리의 작은 푸른 물약 두 병, 입체적 젤리 재질. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.


## shadow_duelist

- Source image path: assets/source/imagegen/uiux_completion_20260913/shadow_duelist_sheet.png
- Runtime image path: assets/sprites/uiux3d/shadow_duelist_sheet.png
- Generation output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-3e0f4582-e610-4a33-b3b1-1373ffe54024.png
- SHA-256: d4fd8e1bb2fbf343071ecb8f878e7b056a35027445e48837cad872e8928f57b6
- Size: (1241, 1268); 1676804 bytes
- References: res://assets/sprites/enemies/update4/region/enemy_shadow_duelist_sheet.png

### Prompt

투명 배경 PNG 게임 캐릭터 스프라이트 시트를 새로 생성해줘. 검은 머리를 뒤로 묶고 어두운 복면을 쓴 그림자 검객. 선명한 보라 눈, 남색 갑옷과 헤진 망토, 얇은 은색 곡검. 밝은 테두리 조명으로 어두운 옷 형태가 읽히게. 매끈한 고급 3D 게임 렌더처럼 큰 형태와 부드러운 입체 조명. 정확히 4열×4행, 총16개 독립적인 전신자세: 첫행 대기2와 쓰러짐2, 둘째행 걷기4, 셋째행 공격4, 넷째행 기술4. 각칸 정중앙에 같은 체격의 한 캐릭터. 몸과 모든 장비·효과가 각칸 중앙60% 안에 완전히 들어가며 사방20% 빈공간. 배경은 실제로 투명하게 생성. 바닥, 격자, 글자 없음.
