# 기본 계약 전투 모리 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-08-02
- Target version: v1.2.2
- Source image path: `assets/source/imagegen/update4_contract_monsters/mori/mori_combat_sheet_chroma_2026-08-02.png`
- Runtime image path: `assets/sprites/monsters/update4/monster_mori_sheet.png`

## 목적

기존 `spore_healer`가 슬라임 그림을 공유하던 문제를 해결하기 위한 기본 계약 전투 자산이다. 모리의 기본 정체성을 왕관 진화형과 분리해 유지하면서, `Unit.gd`의 4×4 시트 계약에 맞춘다.

## 최종 생성 사양

- 4열×4행, 총 16셀, 셀당 1캐릭터
- 행 순서: 1행 `idle_down` 2프레임 + `down` 2프레임, 2행 `move_down` 4프레임, 3행 `attack_down` 4프레임, 4행 `skill_down` 4프레임
- 작은 비인간 버섯 치유사: 버건디 버섯갓, 크림색 몸, 이끼색 짧은 망토, 포자 등불 지팡이, 갈색 작은 가방
- 동일한 쿼터뷰 전투 카메라, 동일한 발 기준선, 어두운 회흑색·이끼색 중심 팔레트와 절제된 금색 회복 광원
- 원본 배경: 크로마 그린 `#00ff00`; 글자·라벨·격자선·왕관 장식·워터마크 없음

## 프롬프트 및 반복 기록

최종 프롬프트는 정확한 4×4 배치와 `idle/down/move/attack/skill` 행 계약을 하드 제약으로 지정했다. 첫 번째 생성은 4×4가 아닌 불규칙 배치라 폐기했고, 두 번째 생성은 4×4였지만 행별 런타임 의미가 어긋나 폐기했다. 세 번째 생성만 배치·행 계약을 통과해 이 원본으로 채택했다.

## 후처리

- `tools.prepare_update4_crown_assets.remove_chroma`를 기준으로 크로마 그린을 제거했다.
- 1254×1254 원본의 셀 경계 `[0, 314, 627, 941, 1254]`를 사용해 16개 셀을 추출했다.
- 각 셀을 투명 192×192로 맞추고, 동일한 4×4 768×768 RGBA 런타임 시트로 조립했다.
- 후처리 단계에서 크로마 색 번짐을 제거하고, 순수 크로마 잔류 픽셀 0개를 직접 검사했다.
- 초상화·VFX·오디오·제품 데이터 연결은 이 패킷에서 생성하지 않았다.
