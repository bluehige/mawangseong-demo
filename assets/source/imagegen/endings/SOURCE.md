# 엔딩 일러스트 ImageGen 원본 기록

- 생성일: 2026-07-12
- 생성 방식: Codex 내장 ImageGen
- 런타임 경로: `res://assets/ui/endings/`
- 원본 보관 경로: `res://assets/source/imagegen/endings/`
- 공통 규칙: 16:9 가로 구도, 기존 마왕성/캐릭터 초상화를 스타일·캐릭터 참고 이미지로 사용, 화면 내 글자·로고·워터마크 금지

## 프롬프트 요약

1. `ending_true_demon_castle.png`: 전투가 끝난 마왕성 알현실에서 마왕과 레온이 서로 경계하면서도 무기를 내린 균형 승리. 새벽빛과 횃불, 엄숙하고 모호한 희망.
2. `ending_monster_family_castle.png`: 푸딩·곱·핀·로로가 복구 중인 성에서 식탁을 함께하는 가족 엔딩. 따뜻한 난롯불과 고딕 분위기.
3. `ending_impregnable_demon_citadel.png`: 검은 성벽·망루·쇠뇌로 증축된 난공불락 요새를 곱과 마왕이 내려다보는 장면. 후퇴하는 인간군과 폭풍 전야.
4. `ending_dread_overlord_rises.png`: 붉은 일식 아래 마왕과 핀이 거대한 보랏빛 마법진을 펼치고 몬스터 군단이 도열한 공포의 대마왕 엔딩.
5. `ending_demon_hero_rival_pact.png`: 무너진 다리를 임시로 이어 마왕과 레온이 동등한 전사로 팔을 맞잡는 불안정한 라이벌 협정. 양 진영은 무기를 내린 채 대치.

각 프롬프트에는 기존 참고 이미지의 화풍·색상·캐릭터 특징 유지, 오른쪽 UI용 어두운 여백, 잔혹한 유혈 표현 제외 조건을 함께 지정했다.

## 엔딩 문양과 도감 썸네일

- `ending_emblems_5x1_chroma.png`: 진짜 마왕성, 몬스터 가족, 철벽 요새, 공포의 대마왕, 라이벌 협정을 순서대로 배치한 5칸 생성 원본
- `ending_emblems_5x1_alpha.png`: 녹색 배경 제거 원본
- 런타임 문양: `emblem_<ending_id>.png` 5개
- 도감 썸네일: 각 엔딩 일러스트를 16:9로 축소한 `thumbnail_<ending_id>.png` 5개
- 변환 도구: `tools/prepare_legacy_ui_assets.py`
