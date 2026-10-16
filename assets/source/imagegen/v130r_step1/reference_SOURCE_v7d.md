# v7d 입구 다리

Generation model: GPT internal image generation
Generated date: 2026-10-16
Target version: external mockup assets_v7d
Source image path: source/entrance_bridge.png
Runtime image path: final/bridge/entrance_bridge.png

GPT image_gen 내장 도구, transparent_background=true. 프롬프트: prompts/entrance_bridge.txt.
v7c를 보존하여 복제. 새 그림은 GPT 생성, 코드는 알파 보존 기하 변환과 조립만 수행.
판자·로프와 일부 돌 보강, 2칸 폭, 관문 길과 같은 2:1 아이소 방향. 관문 앞 포장과 다리 끝을 겹쳐 연결하고 화면 왼쪽 아래 동굴 바닥까지 연장. 긴 지지대와 석재 받침 포함.
전체·입구 확대를 직접 열어 연결, 진행 방향, 지지대, 검은 여백 해소 확인.
검증: checks/v7d_validation.json. v7c 164파일 해시 보존, 최종 조각 53개 해시 확인, PNG 읽기 확인.
실제 알파 범위 0~255, 완전 투명 픽셀 약 62%. 배경 제거 없음.
게임 코드 변경·Godot 실행·커밋 없음. 저장소 외부 목업 작업.
재조립: python assemble_v7d.py (v7c 읽기, v7d 출력).
