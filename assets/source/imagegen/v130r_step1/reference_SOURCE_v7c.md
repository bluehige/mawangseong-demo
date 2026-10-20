# v7c 생성 기록
Generation model: GPT internal image generation
Generated date: 2026-10-16
Target version: external mockup assets_v7c
Source image path: source/door_arch_down.png
Runtime image path: final/building/door_arch_down.png
Runtime image path: final/building/door_arch_up.png
Runtime image path: final/building/door_arch.png
Source image path: source/entrance_gate.png
Runtime image path: final/interiors/entrance.png

GPT image_gen 두 번 호출, 모두 transparent_background=true. 실제 알파 검사 통과.
문틀 프롬프트: 기존 보라 석재와 촛불 스타일, 발이 ↘ +0.5 벽선에 놓이는 2:1 아이소 열린 아치. 배경·바닥·문짝 없이 구멍도 투명.
입구 프롬프트: 기존 전체 미리보기 스타일, 탑 대신 낮고 넓은 열린 관문. 키스톤 위 작은 뿔 해골, ↘ 벽과 ↗ 관통 길, 바깥 짧은 포장 접근로, 3×3 부지, 배경과 구멍 네이티브 투명.
사각 여백 크롭 후 원본 알파 보존. 문틀 양발 간격 (128,64) 기하 크기 조절 및 좌우 반전. 입구 균등 0.36배. 바깥 길은 기존 GPT 도로 재질과 영역 마스크 조립.
로컬 배경 제거·재채색·코드 그림 없음. 게임 코드·Godot·커밋 없음.
v7b 보존 후 복제. 현재 결과 기준은 assemble_v7c.py, door_direction_table.json, assembly_config.json, checks/v7c_validation.json. 복제된 다른 스크립트와 이전 증거는 역사 자료.
