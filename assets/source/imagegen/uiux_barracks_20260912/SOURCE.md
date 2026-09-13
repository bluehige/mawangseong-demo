# UIUX V2 병영 원본 재제작

- Generation model: GPT internal image generation
- Generated date: 2026-09-12
- Target version: v1.2.6

출시선 기준이며 새 버전은 미확정이다. 각 방향의 기존 250×195 수준 v3 원본을 참고하여 GPT 내부 이미지 생성으로 입체적인 목재·금속·보라색 천을 다시 그렸다. 신규 시설·등급·비용·경로는 추가하지 않았다. 기계적인 3D 회전 추출물이 아니므로 각 방향별 소품 세부 묘사에는 차이가 있다. 카드·고스트·설치에는 동일한 manifest 선택 결과를 사용한다.

네 장은 native RGBA, 바깥 alpha 0을 확인했다. 생성 원본을 복사한 동일 바이트 PNG를 런타임에 사용한다. 로컬 배경 제거·반전·회전·이미지 크롭·재샘플링 없음. mipmap만 Godot 가져오기에서 생성한다. 최초 NE 불투명 체크무늬 후보는 사용하지 않았다.

## NW

- Source image path: assets/source/imagegen/uiux_barracks_20260912/barracks_NW.png
- Runtime image path: assets/props/uiux/barracks_NW.png
- Reference: assets/props/v3/prop_weapon_rack_v3_NW_back.png

## NE

- Source image path: assets/source/imagegen/uiux_barracks_20260912/barracks_NE.png
- Runtime image path: assets/props/uiux/barracks_NE.png
- Reference: assets/props/v3/prop_weapon_rack_v3_NE_back.png

## SE

- Source image path: assets/source/imagegen/uiux_barracks_20260912/barracks_SE.png
- Runtime image path: assets/props/uiux/barracks_SE.png
- Reference: assets/props/v3/prop_weapon_rack_v3_SE_back.png

## SW

- Source image path: assets/source/imagegen/uiux_barracks_20260912/barracks_SW.png
- Runtime image path: assets/props/uiux/barracks_SW.png
- Reference: assets/props/v3/prop_weapon_rack_v3_SW_back.png

## 실제 프롬프트

Remaster this exact isometric dungeon barracks prop as a clean high-quality stylized 3D game render. Preserve the exact camera angle, orientation, footprint, positions and count of the weapon rack, weapons, purple bedroll, hanging purple banner, crates, barrels, torch and stone base. This is the same existing building, no upgrade, no added room walls, no roof, no new objects. Replace the tiny jagged source image with smooth sculpted volume, broad clean materials, readable warm wood and dark iron, soft warm light from upper left, crisp silhouette, restrained details with no tiny etched scratches or dense grain. Improve the object at its actual 200 pixel displayed size, not just high-resolution decoration. Native transparent PNG output with an alpha channel. No background, no checkerboard, no ground beyond the exact diamond stone footprint. Entire prop visible, centered, safe transparent space around edges. Single building, no text.

NE 후속 편집: 같은 내장 도구에 네이티브 투명 PNG 출력과 병영 외형 보존을 요청했다. 바깥 실제 alpha 0과 원본/런타임 해시를 검사했다.
