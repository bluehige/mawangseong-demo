# 기본 계약 전투 돌콩 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-08-04
- Target version: v1.2.2
- Source image path: `assets/source/imagegen/update4_contract_monsters/dolkong/dolkong_combat_sheet_chroma_2026-08-04.png`
- Runtime image path: `assets/sprites/monsters/update4/monster_dolkong_sheet.png`

## 목적

기존 `stone_sentinel`이 슬라임 idle 그림을 공유하던 문제를 해결하기 위한 돌콩 전용 기본 계약 전투 자산이다. 작은 석상 파수꾼의 무게감 있는 실루엣과 회색 석재 재질을 유지하면서 `Unit.gd`의 4×4 전투 시트 계약에 맞춘다.

## 최종 생성 사양

- 4열×4행, 총 16셀, 셀당 캐릭터 1개
- 행 순서: 1행 `idle_down` 2프레임 + `down` 2프레임, 2행 `move_down` 4프레임, 3행 `attack_down` 4프레임, 4행 `skill_down` 4프레임
- 작은 석상 파수꾼: 숯빛 회색 현무암 몸체, 짧은 뿔, 접힌 돌날개, 가슴의 작은 성문 문양, 절제된 호박색 눈빛
- 동일한 쿼터뷰 전투 카메라, 동일한 발 기준선, 어두운 회색·슬레이트 중심 팔레트와 절제된 호박색 스킬 광원
- 원본 배경: 크로마 그린 `#00ff00`; 글자·라벨·격자선·워터마크·추가 캐릭터 없음

## 프롬프트 및 검수 기록

최종 프롬프트는 돌콩을 슬라임·푸딩·버섯·고블린과 구분되는 작은 회색 석상 가고일 수호자로 지정하고, 4×4 배치·행별 동작 의미·공통 발 기준선을 하드 제약으로 지정했다. 생성 결과를 원본으로 확인한 뒤 16셀 모두 캐릭터가 있고 각 프레임의 실루엣이 동일한 결과를 채택했다.

## 후처리

- 크로마 그린과 녹색 가장자리 픽셀을 제거하고, 투명 영역의 RGB를 검정으로 중화해 축소 시 녹색 번짐을 막았다.
- 1254×1254 원본의 셀 경계 `[0, 314, 627, 941, 1254]`를 사용해 16개 셀을 추출했다.
- 각 셀을 투명 192×192로 맞추고, 동일한 4×4 768×768 RGBA 런타임 시트로 조립했다.
- 프레임별 visible pixel·중복 해시·투명 모서리·순수 크로마 잔류를 직접 검사했다.
- 초상화·VFX·오디오·제품 데이터 연결은 이 패킷에서 생성하지 않았다.
