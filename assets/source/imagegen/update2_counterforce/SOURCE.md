# 2차 대응군·에블린 그래픽 SOURCE

- 생성일: 2026-07-13 (KST)
- 생성 경로: Codex 기본 built-in `imagegen` (`gpt-image-2`)
- 용도: 2차 재구성 R3의 일반 적 6종과 왕실 전략가 에블린
- 원본 배치: 4열×2행, 마지막 셀 비움
- 셀 순서: `royal_scout`, `monster_binder`, `ward_breaker`, `supply_raider`, `anti_magic_archer`, `royal_field_medic`, `royal_strategist_evelyn`
- 크로마키: 단색 `#ff00ff`; 설치된 `remove_chroma_key.py`의 border 자동 추출, soft matte, despill로 제거
- 런타임 준비: `tools/prepare_update2_counterforce_assets.py`
- 프레임 계약: 각 유닛 `idle 2 / move 4 / attack 4 / skill 4 / down 2`

## 원본 파일

- `counterforce_design_sheet_4x2_chroma.png`: 최초 디자인/대기 기준
- `counterforce_move_sheet_4x2_chroma.png`: 이동 포즈
- `counterforce_attack_sheet_4x2_chroma.png`: 공격 포즈
- `counterforce_skill_sheet_4x2_chroma.png`: 역할별 스킬 포즈
- `counterforce_down_sheet_4x2_chroma.png`: 비고어 전투 불능 포즈
- `counterforce_idle_sheet_4x2_alpha.png`: 디자인/대기 시트의 크로마키 제거 원본
- 이동·공격·스킬·전투 불능 시트의 대응 `*_alpha.png`: 각 크로마키 제거 원본

런타임 파일은 생성 원본을 다시 그리지 않고 셀 분할, 투명 여백 정규화, 크기 조정, 프레임별 미세 위치·크기 변형만 적용한다.
