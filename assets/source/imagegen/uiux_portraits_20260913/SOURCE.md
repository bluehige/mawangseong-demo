# UIUX V2 동료 큰 초상 원본

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6

푸딩·고브·핀·모리의 기존 uiux3d 전투 외형에 맞춘 전용 큰 초상 4장과 고브 eager 감정 1장이다. 제품 기준선은 1.2.6이며 새 출시 버전은 확정하지 않았다. 실제 3D 모델이 아니라 입체 재질을 가진 PNG 초상이다.

내부 imagegen 도구의 prompt/referenced_image_paths를 사용했다. 인터페이스에 별도 background 인수가 없으므로 실제 프롬프트에 투명 PNG 요구를 전달했다. 푸딩 RGB 체크무늬 후보 두 장은 탈락시켰다. 최종 5장은 RGBA와 모서리 alpha 0을 검사했다. 로컬 배경 제거·크롭·축소·색상 변환 없이 생성 원본을 그대로 복사했다. 원본/런타임 SHA-256은 동일하다. Godot 손실 없는 import와 mipmap을 사용하며 크기 제한은 0이다.

## gob_base

- Source image path: assets/source/imagegen/uiux_portraits_20260913/gob_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/gob_base.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-91fd8d2e-6e06-4b1e-a7b1-966197a9dfef.png
- SHA-256: da2e69af7e551838e873198473325a8706a83537e853eed8addf60047242e905
- Size: [1216, 1293]; 1894942 bytes
- Reference: assets/sprites/uiux3d/goblin_sheet.png

### Prompt

투명 배경 이미지로 만들어줘. 첨부 시트의 첫 번째 녹색 고블린 고브 한 명을 큰 게임 초상으로. 갈색 모히칸, 긴 뾰족 귀, 주황 눈, 붉은 목도리, 갈색 가죽 갑옷, 작은 곡도 그대로. 허벅지 위 구도, 두 귀와 머리와 손이 잘리지 않게 8% 여백. 차분하고 자신 있는 미소. 단 하나의 캐릭터, 부드러운 고급 3D 렌더 느낌. 네이티브 투명 PNG, 글자 없음.

## pynn_base

- Source image path: assets/source/imagegen/uiux_portraits_20260913/pynn_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/pynn_base.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-a09e71e1-0351-42c1-8b1c-a139622f73df.png
- SHA-256: 0d21c059126ce03e23d7d0ad200c6666f16d5d79d2b70a6a96041340000b6b57
- Size: [1254, 1254]; 1469366 bytes
- Reference: assets/sprites/uiux3d/imp_sheet.png

### Prompt

투명 배경 이미지로 만들어줘. 첨부 시트의 첫 번째 빨간 임프 핀 한 명을 큰 게임 초상으로. 붉은 피부, 검은 뿔 두 개, 작은 박쥐 날개, 노란 눈, 검보라 로브와 금색 마름모 장식, 작은 불꽃 지팡이 그대로. 허벅지 위 구도, 뿔과 날개와 지팡이가 잘리지 않게 8% 여백. 자신 있는 장난스러운 미소. 단 하나의 캐릭터, 부드러운 고급 3D 렌더 느낌. 네이티브 투명 PNG, 글자 없음.

## mori_base

- Source image path: assets/source/imagegen/uiux_portraits_20260913/mori_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/mori_base.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-a5a608e6-2e22-47c8-b3b0-c8680e91f13f.png
- SHA-256: dd9c5eaf5ff9c77d9759e95c5b731ffe683c37f302ad866367642278f61c96aa
- Size: [1254, 1254]; 1183911 bytes
- Reference: assets/sprites/uiux3d/spore_healer_sheet.png

### Prompt

투명 배경 이미지로 만들어줘. 첨부 시트의 첫 번째 버섯 치유사 모리 한 명을 큰 게임 초상으로. 빨간 버섯 갓과 흰 점, 크림색 몸체, 검은 둥근 눈, 이끼색 망토, 갈색 가방, 작은 금빛 등불 지팡이 그대로. 전신에 가까운 구도, 갓과 지팡이가 잘리지 않게 8% 여백. 친근하고 평온한 표정. 단 하나의 캐릭터, 부드러운 고급 3D 렌더 느낌. 네이티브 투명 PNG, 글자 없음.

## gob_eager

- Source image path: assets/source/imagegen/uiux_portraits_20260913/gob_eager.png
- Runtime image path: assets/sprites/portraits/uiux3d/gob_eager.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-ce9beeaa-e046-432f-9781-a544734323b1.png
- SHA-256: 6bf6b776672cb323647fb46d3f0b4eb4f66ae7d2c2a7db17f2de945248d2b2c3
- Size: [1216, 1294]; 1927691 bytes
- Reference: assets/sprites/portraits/uiux3d/gob_base.png

### Prompt

투명 배경 이미지로 만들어줘. 첨부 고브 초상의 감정 변형 한 장. 같은 녹색 피부, 갈색 모히칸과 긴 귀, 붉은 목도리, 갈색 가죽 장비, 곡도, 카메라 각도와 크기 그대로. 변화는 기대에 찬 활기찬 표정: 눈썹을 살짝 올리고 눈을 반짝이며 작은 송곳니가 보이게 웃는다. 고급 3D 렌더 재질 유지, 네이티브 투명 PNG.

## pudding_base

- Source image path: assets/source/imagegen/uiux_portraits_20260913/pudding_base.png
- Runtime image path: assets/sprites/portraits/uiux3d/pudding_base.png
- Generation output: C:\Users\blueh\.codex\generated_images\01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3\exec-9fc5c416-de75-4465-8341-3ce997b85ff9.png
- SHA-256: e15114caca1da1dc088b6f24338b57892fc7bd35e88138bc63854b86c70b9894
- Size: [1254, 1254]; 1018126 bytes
- Reference: assets/sprites/uiux3d/slime_sheet.png

### Prompt

투명 배경 이미지로 만들어줘. 첨부 캐릭터 시트에서 첫 번째 파란 슬라임과 방패를 한 개만 크게 그린 게임 캐릭터 초상. 네이티브 투명 PNG, 3D 렌더 느낌과 기존 파란 젤리 모습 유지.

## 미채택 투명도 재시도

초기 요청: 참고 이미지에 있는 파란 젤리 슬라임 푸딩 하나의 고해상도 게임 초상을 만들어줘. 참고는 캐릭터 정체성과 3D 재질 기준이다. 애니메이션 시트가 아니라 단 하나의 캐릭터 초상, 정사각형 1024x1024. 파란 반투명 젤리 몸체, 작은 둥근 나무 방패와 금속 테두리, 선명한 눈과 의젓하고 다정한 표정. 기존 형태·색·장비 그대로, 팔다리 추가 금지. 전체 몸체와 방패를 캔버스 중앙에 크게, 사방 약 8% 여백. 부드러운 3D 렌더 재질, 넓고 정돈된 하이라이트, 과도한 반짝임 입자 없이. 실제 RGBA 투명 배경 PNG로 생성해. 바닥·배경·체크무늬·문자·테두리는 그리지 마. 어두운 게임 UI에 직접 합성할 초상이다.

첫 재편집 요청: 첨부 그림의 푸딩 캐릭터 형태와 색을 그대로 유지하고, 체크무늬 배경을 없애 실제 투명 배경 PNG로 만들어줘. 반드시 알파 채널이 있는 투명이미지. 캐릭터와 방패만 남겨줘.

두 결과 모두 불투명 RGB라 게임에 연결하지 않았다. 최종 푸딩은 원래 투명 전투 시트를 다시 참조해 생성했다.
