# Stage 04 대마왕성 그래픽 생성 기록

- 생성일: 2026-07-12
- 생성 도구: Codex 내장 `image_gen`
- 생성 방식: 기존 방향별 런타임 소품을 참조 이미지로 넣은 이미지 편집
- 목적: `stage_04_citadel`의 11개 방에 필요한 9종 방향별 소품 완성
- 배경 처리: 단색 크로마키 배경을 공식 `remove_chroma_key.py`로 제거한 RGBA PNG

## 공통 프롬프트 계약

모든 생성 요청은 다음 조건을 공통으로 사용했다.

- 기존 등각 시점, 방위, 1칸 발자국, 바닥 접점을 유지한다.
- 최종 진화 단계답게 흑요석, 금빛 청동 장식, 보랏빛 마력 구조를 사용한다.
- 한 방에 하나의 완성된 건물만 배치하며 캐릭터, 글자, UI, 워터마크를 넣지 않는다.
- 배경은 완전히 균일한 RGB `#00FF00`으로 생성한다.
- 게임 화면에서 겹쳐 보이지 않도록 외곽선을 또렷하게 하고 바닥 접점을 아래 중앙에 둔다.

## 자산별 프롬프트 차이와 생성 원본

| 런타임 자산 | 방향/레이어 | 자산별 요청 | 내장 생성 원본 |
|---|---|---|---|
| `prop_entrance_gate_stage04_SE_back.png` | SE/back | 요새 성문을 최종 흑요석 성문과 보랏빛 봉인 장치로 진화 | `exec-72a51593-8d0f-4747-b018-42a5d4d24346.png` |
| `prop_throne_stage04_SW_back.png` | SW/back | 지휘용 대마왕 옥좌, 금빛 골조와 보랏빛 마력 고리 | `exec-6fde5709-3cef-4b1d-9911-86bc2fd77d14.png` |
| `prop_armory_stage04_SE_back.png` | SE/back | 기존 병영을 최종 단계 무기고와 중장비 보급소로 진화 | `exec-6a91fdf9-2f00-4292-899c-d0333ffc715d.png` |
| `prop_elite_garrison_stage04_NW_back.png` | NW/back | 별도 정예 주둔지, 중갑 장비와 보랏빛 강화 설비 | `exec-c3f433db-e13d-46f2-a04a-c213c82112bd.png` |
| `prop_recovery_sanctuary_stage04_NW_front.png` | NW/front | 최종 비상 회복 성소, 보랏빛 회복 수조와 보호 골조 | `exec-a28fe4fb-af98-454f-b170-621f754335d7.png` |
| `prop_treasure_vault_stage04_NW_front.png` | NW/front | 최종 왕실 보물고, 강화 금고와 마력 봉인 장치 | `exec-54203387-0294-4b35-85e3-616bf2d661b3.png` |
| `prop_construction_platform_stage04_NE_back.png` | NE/back | 빈 상태가 분명한 저상형 고급 건설 플랫폼 | `exec-e16a6c19-ffd9-415f-9933-5b6dfca1d6fc.png` |
| `prop_ward_core_stage04_NW_back.png` | NW/back | 거대한 보랏빛 수정과 동심원 룬 골조를 가진 성채 방호 핵 | `exec-e5b79f27-ef94-4903-b0d6-55d9a1bed6e5.png` |
| `prop_watch_tower_stage04_NW_front.png` | NW/front | 보랏빛 봉화와 지휘 발코니를 가진 최종 감시 지휘탑 | `exec-32987e69-f466-49c3-a16d-55bf14d66a16.png` |

크로마키가 남아 있는 보존 원본은 `assets/source/imagegen/castle_stage04/`에 함께 저장했다.

## Stage 03 방위 누락 보정

Stage 03의 `ward_core_01`은 실제 배치 방향이 NW인데 기존에는 NE 전용 이미지밖에 없어 일반 건설 바닥으로 대체되고 있었다. 같은 내장 생성 방식으로 한 단계 낮은 요새형 방호 핵을 추가했다.

- 런타임 자산: `assets/props/stage_03/prop_ward_core_stage03_NW_back.png`
- 프롬프트 차이: Stage 04보다 장식과 수정 규모를 낮추되 중앙 수정과 네 갈래 마력 연결선이 분명한 검은 석재 방호 플랫폼, NW 방향 유지
- 1차 생성 원본: `exec-52133326-e270-4048-9948-5e7aa8b5b4b2.png`
- 육안 검사 후 보정한 최종 생성 원본: `exec-3e2bf030-60e1-4f0a-a43f-8f9325394328.png`

## 후처리와 검증 기준

`--auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill` 옵션으로 배경을 제거했다. 최종 파일은 모두 알파 채널이 있는 PNG이며, 투명 픽셀과 반투명 외곽 픽셀이 실제로 존재하는지 자동 검사한다.
