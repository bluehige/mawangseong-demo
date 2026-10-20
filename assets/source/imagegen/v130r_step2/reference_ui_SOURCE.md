# UI icons v1 — 사용자 확인 대기

Generation model: GPT internal image generation
Generated date: 2026-10-16
Target version: UI icons v1 / standalone mockup (게임 미적용)

## 결과
- 사용자 OK 2026-10-16 06:27 기준. 기능 26개 + 원형 프레임 3종.
- icons_128/ 29개, icons_64/ 29개, 통합 및 크기별 시트.
- 건설/전투/배치 보조 와이어프레임 적용 미리보기 3장, 각 1920×1080.
- 요청 산출물 미달 없음. 사용자 확인 대기.

## 기준과 규격
- 스타일: ../assets_v1/A_style/style_reference.png, ../assets_v1/preview_full.png (0071 결과).
- 구조: ../plan/ui2_1_build.png, ../plan/ui2_2_place.png, ../plan/ui2_3_battle.png.
- ../assets_v1/assemble_preview.py와 ../plan/plan_E_cells.txt는 구조 참고로 열람만 함. 기존 조립 코드를 실행하거나 재사용해 그림을 만들지 않음.
- 아이콘은 정사각 128×128 기준본, 투명 배경, 64×64 축소본. 맵용 2:1/128×64/하단 피벗 대신 사용자 지정 UI 규격 적용.
- 젖은 청회색 동굴 석재·목재·낡은 금속·청록빛. 두꺼운 외곽선과 왼쪽 위 빛. 초보 마왕의 큐트호러 코미디.
- 용암/지옥/피/글자/숫자/로고 없음. 배속은 삼각형 개수 1/2/3. 프레임은 기본/밝은 이중 테두리/자물쇠로 구분.

## 생성과 후처리
- GPT 내부 image_gen만 사용. 매 호출 transparent_background=true. 외부 API/생성기/로컬 배경 제거 사용 안 함.
- 30회 생성: 채택 29개 + 전부 해제 미채택 1개. 모든 생성 원본 보존.
- 도구 반환 원래 해상도는 source/에 보존. 납품 기준본은 icons_128, 64px 파일은 해당 기준본에서 축소.
- 조립은 전체 캔버스 리사이즈·생성 프레임/상징 알파 합성·시트 배열·기존 와이어프레임 위 배치만 수행.
- 코드 드로잉, SVG/도형 대체, 코드 마스크, 크롭, 알파 덮어쓰기, 재투영, 배경 제거 없음.
- 기능 26개는 정확히 동일한 생성 기본 프레임을 재사용. 미리보기 선택 상태에는 생성 선택 프레임 적용.
- 와이어프레임의 기존 이름/비용/안내 문구는 보존. 이 문구는 새 아이콘 내부의 글자가 아님.
- 실제 프롬프트·참조 파일·도구 원본 위치: prompts/*.json. 중간 진행 기록: checks/progress_log.txt.

## 검수
- 채택 29개 네이티브 투명 알파, 납품 58개 정확한 크기/바깥 테두리 전체 알파 0/중복 없음 PASS.
- 원본 가장자리의 보이지 않는 알파 1/255는 그대로 보존. 알파 픽셀을 지우는 로컬 처리는 하지 않음.
- 전부 해제 첫 후보의 경계 접촉은 내부 재생성으로 해결. 상세: checks/visual_review.md.
- 64px 형태 구분·요청 기호·무문자·혼동쌍·프레임 통일·맵 톤을 직접 이미지로 확인. TARGETED_PASS.
- 실사용자 인지 실험, 별도 검수 에이전트, 게임/빌드/전체 회귀 검사는 미실행.
- index.html 로컬 이미지/링크 누락 0. 기준 입력 파일 7개 해시 일치.

## 저장소 경계
- 브랜치 codex/v130r-defense-layout / HEAD acc7f048d3bd9141c6511d7f99561ec3efeb277c 유지.
- 로컬 main 없음. origin/main 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b는 참고만 열람. 최신 권위 확정 안 함. fetch/브랜치 전환 없음.
- 작업 전/후 git status --porcelain=v1 차이 0행. 기존 혼합 변경 보존.
- 게임 코드·씬·세이브·저장소 문서 수정 없음. Godot/커밋/푸시 실행 없음. 모든 결과는 지정된 ui_icons_v1 안에 저장.

## 채택 이미지별 출처

### 병영 — build_barracks
Source image path: source/build_barracks.png
Runtime image path: icons_128/build_barracks.png
Runtime image path: icons_64/build_barracks.png
Prompt record: prompts/build_barracks.json
Selection: ACCEPTED

### 회복 둥지 — build_recovery_nest
Source image path: source/build_recovery_nest.png
Runtime image path: icons_128/build_recovery_nest.png
Runtime image path: icons_64/build_recovery_nest.png
Prompt record: prompts/build_recovery_nest.json
Selection: ACCEPTED

### 결계핵 — build_ward_core
Source image path: source/build_ward_core.png
Runtime image path: icons_128/build_ward_core.png
Runtime image path: icons_64/build_ward_core.png
Prompt record: prompts/build_ward_core.json
Selection: ACCEPTED

### 감시탑 — build_watchtower
Source image path: source/build_watchtower.png
Runtime image path: icons_128/build_watchtower.png
Runtime image path: icons_64/build_watchtower.png
Prompt record: prompts/build_watchtower.json
Selection: ACCEPTED

### 미끼 보물실 — build_decoy_treasure
Source image path: source/build_decoy_treasure.png
Runtime image path: icons_128/build_decoy_treasure.png
Runtime image path: icons_64/build_decoy_treasure.png
Prompt record: prompts/build_decoy_treasure.json
Selection: ACCEPTED

### 가시 함정 — build_spike_trap
Source image path: source/build_spike_trap.png
Runtime image path: icons_128/build_spike_trap.png
Runtime image path: icons_64/build_spike_trap.png
Prompt record: prompts/build_spike_trap.json
Selection: ACCEPTED

### 끈끈이 함정 — build_sticky_trap
Source image path: source/build_sticky_trap.png
Runtime image path: icons_128/build_sticky_trap.png
Runtime image path: icons_64/build_sticky_trap.png
Prompt record: prompts/build_sticky_trap.json
Selection: ACCEPTED

### 정보 — menu_info
Source image path: source/menu_info.png
Runtime image path: icons_128/menu_info.png
Runtime image path: icons_64/menu_info.png
Prompt record: prompts/menu_info.json
Selection: ACCEPTED

### 강화 — menu_upgrade
Source image path: source/menu_upgrade.png
Runtime image path: icons_128/menu_upgrade.png
Runtime image path: icons_64/menu_upgrade.png
Prompt record: prompts/menu_upgrade.json
Selection: ACCEPTED

### 이동 — menu_move
Source image path: source/menu_move.png
Runtime image path: icons_128/menu_move.png
Runtime image path: icons_64/menu_move.png
Prompt record: prompts/menu_move.json
Selection: ACCEPTED

### 해체(환불) — menu_dismantle_refund
Source image path: source/menu_dismantle_refund.png
Runtime image path: icons_128/menu_dismantle_refund.png
Runtime image path: icons_64/menu_dismantle_refund.png
Prompt record: prompts/menu_dismantle_refund.json
Selection: ACCEPTED

### 수비 배치 — menu_assign_defenders
Source image path: source/menu_assign_defenders.png
Runtime image path: icons_128/menu_assign_defenders.png
Runtime image path: icons_64/menu_assign_defenders.png
Prompt record: prompts/menu_assign_defenders.json
Selection: ACCEPTED

### 집결 — tactic_rally
Source image path: source/tactic_rally.png
Runtime image path: icons_128/tactic_rally.png
Runtime image path: icons_64/tactic_rally.png
Prompt record: prompts/tactic_rally.json
Selection: ACCEPTED

### 집중 공격 — tactic_focus_attack
Source image path: source/tactic_focus_attack.png
Runtime image path: icons_128/tactic_focus_attack.png
Runtime image path: icons_64/tactic_focus_attack.png
Prompt record: prompts/tactic_focus_attack.json
Selection: ACCEPTED

### 비상 후퇴 — tactic_emergency_retreat
Source image path: source/tactic_emergency_retreat.png
Runtime image path: icons_128/tactic_emergency_retreat.png
Runtime image path: icons_64/tactic_emergency_retreat.png
Prompt record: prompts/tactic_emergency_retreat.json
Selection: ACCEPTED

### 사수 — tactic_hold_ground
Source image path: source/tactic_hold_ground.png
Runtime image path: icons_128/tactic_hold_ground.png
Runtime image path: icons_64/tactic_hold_ground.png
Prompt record: prompts/tactic_hold_ground.json
Selection: ACCEPTED

### 후퇴 유도 — tactic_lure_retreat
Source image path: source/tactic_lure_retreat.png
Runtime image path: icons_128/tactic_lure_retreat.png
Runtime image path: icons_64/tactic_lure_retreat.png
Prompt record: prompts/tactic_lure_retreat.json
Selection: ACCEPTED

### 일시정지 — speed_pause
Source image path: source/speed_pause.png
Runtime image path: icons_128/speed_pause.png
Runtime image path: icons_64/speed_pause.png
Prompt record: prompts/speed_pause.json
Selection: ACCEPTED

### x1 (화살표 1) — speed_1
Source image path: source/speed_1.png
Runtime image path: icons_128/speed_1.png
Runtime image path: icons_64/speed_1.png
Prompt record: prompts/speed_1.json
Selection: ACCEPTED

### x2 (화살표 2) — speed_2
Source image path: source/speed_2.png
Runtime image path: icons_128/speed_2.png
Runtime image path: icons_64/speed_2.png
Prompt record: prompts/speed_2.json
Selection: ACCEPTED

### x3 (화살표 3) — speed_3
Source image path: source/speed_3.png
Runtime image path: icons_128/speed_3.png
Runtime image path: icons_64/speed_3.png
Prompt record: prompts/speed_3.json
Selection: ACCEPTED

### 자동 배치 — place_auto
Source image path: source/place_auto.png
Runtime image path: icons_128/place_auto.png
Runtime image path: icons_64/place_auto.png
Prompt record: prompts/place_auto.json
Selection: ACCEPTED

### 전부 해제 — place_clear_all
Source image path: source/place_clear_all.png
Runtime image path: icons_128/place_clear_all.png
Runtime image path: icons_64/place_clear_all.png
Prompt record: prompts/place_clear_all.json
Selection: ACCEPTED / attempt 2

### 막기 — skill_block
Source image path: source/skill_block.png
Runtime image path: icons_128/skill_block.png
Runtime image path: icons_64/skill_block.png
Prompt record: prompts/skill_block.json
Selection: ACCEPTED

### 반격 — skill_counter
Source image path: source/skill_counter.png
Runtime image path: icons_128/skill_counter.png
Runtime image path: icons_64/skill_counter.png
Prompt record: prompts/skill_counter.json
Selection: ACCEPTED

### 직접 조종 — skill_direct_control
Source image path: source/skill_direct_control.png
Runtime image path: icons_128/skill_direct_control.png
Runtime image path: icons_64/skill_direct_control.png
Prompt record: prompts/skill_direct_control.json
Selection: ACCEPTED

### 원형 기본 — frame_normal
Source image path: source/frame_normal.png
Runtime image path: icons_128/frame_normal.png
Runtime image path: icons_64/frame_normal.png
Prompt record: prompts/frame_normal.json
Selection: ACCEPTED

### 선택됨 — frame_selected
Source image path: source/frame_selected.png
Runtime image path: icons_128/frame_selected.png
Runtime image path: icons_64/frame_selected.png
Prompt record: prompts/frame_selected.json
Selection: ACCEPTED

### 사용 불가 — frame_disabled
Source image path: source/frame_disabled.png
Runtime image path: icons_128/frame_disabled.png
Runtime image path: icons_64/frame_disabled.png
Prompt record: prompts/frame_disabled.json
Selection: ACCEPTED

## 미채택 원본
Source image path: source/rejected/place_clear_all_attempt01.png
Prompt record: prompts/rejected/place_clear_all_attempt01.json
Selection: REJECTED — 오른쪽 경계 접촉. 내부 재생성본으로 교체, 런타임 연결 없음.

## 조립 산출물
- icons_sheet.png: 1024×800. 128px 구역 원점 (0,0), 64px 구역 원점 (0,544).
- icons_sheet_128.png: 1024×512, 8열×4행.
- icons_sheet_64.png: 512×256, 8열×4행.
- 시트 셀 좌표/이름: sheet_layout.json.
- 미리보기 배치 좌표/크기/상태: preview_placements.json.
- 검토 페이지: index.html. 밝은/어두운 배경 전환 가능.
- 파일 목록 및 SHA256: delivery_manifest.json.

## 다음 단계
사용자 확인 대기. 미달 항목 없음. 취향 피드백은 이 폴더 안의 아트 수정으로 반영한다.
