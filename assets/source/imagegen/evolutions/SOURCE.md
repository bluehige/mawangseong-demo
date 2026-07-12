# 진화 형태 초상화 ImageGen 원본 기록

- 생성일: 2026-07-12
- 생성 방식: Codex 내장 ImageGen
- 런타임 경로: `res://assets/sprites/portraits/evolution/`
- 원본 보관 경로: `res://assets/source/imagegen/evolutions/`
- 참고 이미지: 각 몬스터의 기존 온보딩 초상화와 대응 진화 배지
- 공통 규칙: 정사각형 UI 초상화, 기존 종족·얼굴 특징 유지, 작은 화면에서도 역할이 보이는 실루엣, 글자·로고·워터마크 금지

## 형태별 프롬프트 요약

1. `portrait_slime_gate_bulwark.png`: 푸딩의 디저트 외형을 유지하면서 청록 수정 성벽 갑주와 방패형 젤 팔을 더한 전열 방벽형.
2. `portrait_slime_rescue_alchemy_gel.png`: 연금액이 흐르는 투명 젤 몸, 길게 늘어나는 구조 팔, 보호 방울과 약초 장식의 동료 구조형.
3. `portrait_goblin_ambush_captain.png`: 가벼운 가죽 갑옷, 후드, 갈고리 창, 덫 장비와 전방으로 기운 자세의 추격형.
4. `portrait_goblin_vault_keeper.png`: 중장 철갑, 자물쇠 방패, 굵은 창과 금고 열쇠 묶음을 든 고정 수호형.
5. `portrait_imp_flame_adept.png`: 백열하는 자홍 화염구, 날카로운 지팡이와 공격적 주문 문양을 강조한 순간 화력형.
6. `portrait_imp_ember_shaman.png`: 잿빛 의복, 매달린 화로 지팡이, 보호 원형으로 떠도는 잿불을 강조한 구역 지원형.

## 진화 전투 시트

- `sheet_slime_gate_bulwark_4x4_chroma.png`: 성문 방벽 푸딩 16프레임 생성 원본
- `sheet_slime_rescue_alchemy_gel_4x4_chroma.png`: 구조 연금 젤 푸딩 16프레임 생성 원본
- `sheet_goblin_ambush_captain_4x4_chroma.png`: 매복대장 곱 16프레임 생성 원본
- `sheet_goblin_vault_keeper_4x4_chroma.png`: 금고지기 곱 16프레임 생성 원본
- `sheet_imp_flame_adept_4x4_chroma.png`: 화염 숙련자 핀 16프레임 생성 원본
- `sheet_imp_ember_shaman_4x4_chroma.png`: 잿불 주술사 핀 16프레임 생성 원본
- `*_alpha.png`: 공용 `remove_chroma_key.py`로 녹색 배경을 제거한 알파 원본
- 셀 순서: `idle 2 → move 4 → attack 4 → skill 4 → down 2`
- 런타임 변환: `tools/prepare_evolution_combat_assets.py`
- 출력: `res://assets/sprites/monsters/monster_<evolution_id>_<animation>_<frame>.png`

여섯 시트 모두 동일한 4×4 셀, 동일한 내려다보는 전투 카메라, 동일한 크기·바닥선, 단색 `#00ff00` 배경, 셀당 캐릭터 1개, 글자·격자선·로고 금지 조건으로 생성했다.

## 진화 전용 VFX

- `vfx_slime_gate_bulwark_2x2_chroma.png`: 룬 조립 → 반쪽 성벽 → 완성 성문 → 수정 파편 해체
- `vfx_slime_rescue_alchemy_2x2_chroma.png`: 연금 물방울 고리 → 젤 방울 성장 → 구조 보호막 완성 → 물방울·잎 소멸
- `vfx_goblin_ambush_captain_2x2_chroma.png`: 속도 흔적 → 교차 참격 → 최대 X 참격 → 보랏빛 잔상 소멸
- `vfx_goblin_vault_keeper_2x2_chroma.png`: 열쇠 룬 → 반쪽 금고 방벽 → 완성 금고문 → 자물쇠 봉인
- `vfx_imp_flame_adept_2x2_chroma.png`: 불씨 핵 → 성장 화염구 → 최대 마법진 → 발사 꼬리
- `vfx_imp_ember_shaman_2x2_chroma.png`: 잿불 고리 → 성장 지대 → 최대 화염 지대 → 식은 재
- `*_alpha.png`: 공용 크로마키 제거 도구로 투명 배경 변환
- 런타임 출력: `res://assets/sprites/effects/fx_<evolution_id>_00~03.png`
- `slime_shield`, `quick_slash`, `fireball`, `flame_zone` 사용 시 현재 진화 ID에 따라 서로 다른 4프레임 효과를 재생한다.

## 스킬과 계승 UI 아이콘

- `skill_icons_4x2_chroma.png`, `skill_icons_4x2_alpha.png`: `skills.json` 등록 스킬 8개의 생성·투명화 원본
- 런타임 스킬 아이콘: `res://assets/sprites/ui/skills/skill_<skill_id>.png`
- `legacy_ui_icons_3x1_chroma.png`, `legacy_ui_icons_3x1_alpha.png`: 유대, 기억, 플레이스타일 순서의 UI 원본
- 런타임 계승 UI 아이콘: `res://assets/sprites/ui/legacy/ui_icon_<bond|memory|style>.png`

## 진화 감정 초상

- `expressions_<evolution_id>_2x1.png`: 왼쪽 승리, 오른쪽 부상 상태로 구성한 진화 6종 원본
- 런타임 출력: `portrait_<evolution_id>_victory.png`, `portrait_<evolution_id>_wounded.png`
- 변환 도구: `tools/prepare_evolution_expression_portraits.py`
