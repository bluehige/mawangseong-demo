# 정식 용사 레온 이미지 출처

- 제작일: 2026-07-12
- 제작 도구: Codex 내장 `image_gen`
- 정체성 기준: 기존 `CHR_HERO_LEON` 초상과 `enemy_trainee_hero` 전투 프레임
- 목적: DAY 30에서 견습 장비를 벗은 동일 인물의 정식 용사 승급 표현

## 생성 원본

- `CHR_HERO_LEON_OFFICIAL_design_sheet_imagegen.png`: 정식 갑옷과 여섯 핵심 자세 기준 원화
- `CHR_HERO_LEON_OFFICIAL_portrait_imagegen.png`: 최종전 대화 초상
- `CHR_HERO_LEON_OFFICIAL_{idle,move,attack,skill,down}_sheet_imagegen.png`: 상태별 독립 키프레임 시트
- 같은 이름의 `_alpha.png`: 공용 크로마키 제거 도구로 만든 투명 중간 산출물

## 내장 생성기 원본 매핑

- 디자인 기준: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-111648b5-7584-4a31-b00a-10897457654a.png`
- 대화 초상: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-7c9665d9-547a-4c81-8532-6fb02a3d9fde.png`
- 대기 시트: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-cfc55eef-3e23-4ce4-9f05-37e1d0ccadee.png`
- 이동 시트: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-3924c81b-7e0d-41de-8765-4ddbfb6fd795.png`
- 공격 시트: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-7409cf95-dfc3-4de7-892e-716e9f148640.png`
- 기술 시트: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-8b5e12f6-4635-4188-b68b-5a9492f5f2f5.png`
- 쓰러짐 시트: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-c9b22be0-2852-4baf-8534-f345993fc4f4.png`

위 7개와 워크스페이스의 같은 용도 `_imagegen.png` 파일은 SHA-256 해시가 각각 일치한다.

모든 시트는 평면 녹색 배경으로 내장 생성한 뒤
`C:/Users/blueh/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py`의
`--auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill`
설정으로 투명화했다.

## 런타임 가공

`tools/prepare_official_leon_assets.py`가 상태별 셀을 시간 순서로 잘라 192×192 투명 프레임에 발 위치를 맞춘다.
각 상태는 `idle 2 / move 4 / attack 4 / skill 4 / down 2` 프레임이며, 인접 프레임 차이가 1% 미만이면 실패하도록 검사한다.
또한 16개 런타임 프레임의 `192×192 RGBA` 형식, 투명 모서리, 완전 투명·불투명 알파 범위, 전체 픽셀 해시 중복을 검사한다. 피사체 크기와 위치를 정규화한 뒤 반전·90도 회전 변형까지 비교해 단순 복제에 가까우면 실패한다.
정지 포즈 한 장을 이동·회전해 만든 대체 애니메이션이 아니라, 각 상태별로 내장 생성한 서로 다른 동작 키프레임을 사용한다.
