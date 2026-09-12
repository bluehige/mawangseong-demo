# UI·UX V2 미술 미완료 및 자산 요청서

작성일: 2026-09-12. 대상: 공개 안정판 1.2.6 기반 UI·UX V2. 새 제품/출시 버전 미확정.
구현 기준 SHA: bc52628a4659259daff64949019b159ccbd5381c.
관련 기록: [구현과 직접 검증](UIUX_V2_U4_U5_2026-09-12.md).

## 현재 실제 게임 연결

- 수호핵은 빈 바닥 표시와 분리했다. 단계 3은 `assets/props/stage_03/prop_ward_core_stage03_NW_back.png`, 단계 4는 `assets/props/stage_04/prop_ward_core_stage04_NW_back.png`를 사용한다.
- `data/dungeon_quarter/asset_manifest.json`의 ward_core는 현재 존재하는 NW 방향으로 고정한다. `missing_art_facings`에 NE/SE/SW를 명시했다.
- 카드·고스트·설치물은 같은 자산/단계/방향/바닥 기준점으로 렌더된다. 다른 방향을 복사·뒤집기로 완성했다고 등록하지 않았다.
- 관련 건설·배치 규칙은 유지했다. 새 그림 없이도 실제 기존 자산으로 조작할 수 있다.

## 필요한 이미지: 수호핵 6개

| 성 단계 | 방향 | 제안 런타임 경로 |
|---|---|---|
| stage_03_keep | NE | assets/props/uiux/ward_core_stage03_NE.png |
| stage_03_keep | SE | assets/props/uiux/ward_core_stage03_SE.png |
| stage_03_keep | SW | assets/props/uiux/ward_core_stage03_SW.png |
| stage_04_citadel | NE | assets/props/uiux/ward_core_stage04_NE.png |
| stage_04_citadel | SE | assets/props/uiux/ward_core_stage04_SE.png |
| stage_04_citadel | SW | assets/props/uiux/ward_core_stage04_SW.png |

위 경로는 제작 요청이며 아직 존재하는 자산이 아니다.

요청 조건:

1. GPT 내부 이미지 생성 모델로 기존 NW 수호핵과 같은 시설의 각 방향을 만든다. stage 3과 4의 기존 색·재질·구조 차이를 보존한다. 기존 수호핵과 해당 성 단계의 방을 함께 참고한다.
2. 원본 1024×1024, 실제 RGBA 투명 배경을 목표로 한다. 바깥 알파 0, 구조물 내부 알파 유효. 흰색·체크무늬·바닥판을 투명 배경처럼 그려 넣지 않는다.
3. 기존 5×5 방 구성의 등각 투영과 floor_center 접점을 맞춘다. 그림 자체에 좌표 이동을 임의로 넣지 않고 manifest 및 QuarterDungeonRenderer의 현재 배치 기준에서 검증한다.
4. 실제 게임에서 약 269×182픽셀로 보이는 크기에서도 수호핵으로 구분되어야 한다. 과도한 작은 무늬·빛 입자·외곽 자글거림을 줄인다.
5. 방향마다 구조에 맞는 시점을 사용한다. 동일 파일 복사나 단순 좌우 반전으로 방향별 완료 처리하지 않는다.
6. 앞벽 가림·바닥 접점·클릭 영역을 현재 지도에서 확인한다. 카드만 보기 좋거나 지도와 다른 그림인 후보는 채택하지 않는다.

채택 검사:

- 실제 이미지 모드와 알파 범위, 네 모서리 알파 0, 불필요한 배경/체크무늬와 잘린 외곽 여부.
- 단계·방향 식별 및 바닥 기준점, 실제 맵의 앞벽·조명과 결합한 모습.
- 동일 조건의 카드→유효/불가 고스트→검토→설치 결과 일치.
- 1920×1080 / 1280×720, 글자 90/100/115%에서 시설 식별.
- 기존 비용·규칙·저장 의미 변경 없음. 관련 시설 직접 검사와 실제 렌더 픽셀 확인.

## 이번에 채택하지 않은 생성 후보

모델: GPT internal image generation. 생성일: 2026-09-12.
다음 문장은 요청 요약이며, 도구에 전달한 프롬프트의 정확한 원문 인용이 아니다.

| 후보 | 요청 요약 | 실제 확인 | 판정 |
|---|---|---|---|
| 1 | 기존 NW 수호핵과 어울리는 보랏빛 핵/석조 시설을 투명 배경 컷아웃으로 제작 | 1254×1254, Format24bppRgb, 모서리 alpha 255, 불투명 체크무늬 배경 | 미채택 |
| 2 | 후보의 체크무늬를 제거하고 실제 투명 알파로 수정 | 1254×1254, Format24bppRgb, 모서리 alpha 255, 불투명 체크무늬 잔존 | 미채택 |

원본은 아래 로컬 경로에 남아 있다.

- C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-58f66a41-ab00-4f33-8091-ed6a75937aa0.png
- C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-11e310fd-c735-4bd8-8b7e-8ea86cd3ff34.png

신규 런타임 이미지로 연결하지 않았으며, 새 자산의 SOURCE.md 채택 기록은 만들지 않았다. 외부 이미지 생성 서비스는 사용하지 않았다.

## 추후 채택 시 출처 기록

`assets/source/imagegen/<asset>/SOURCE.md`에 실제 원본·런타임 경로를 한 이미지당 정확히 한 번 연결한다. 아래 고정 필드를 모두 채우고 프롬프트, 날짜, 후처리, 크롭·알파 검사와 게임 연결 결과를 기록한다.

- Generation model: GPT internal image generation
- Generated date: 실제 생성일
- Target version: 1.2.6 baseline UIUX V2; new release unconfirmed
- Source image path: 실제 존재하는 원본 경로
- Runtime image path: 실제 채택한 런타임 경로

미채택 후보를 런타임 최종본으로 기록하거나 제안 경로를 존재하는 파일처럼 기록하지 않는다.

## 그 밖의 미완료

- 사용자 참고 URL `https://www.gameuidatabase.com/gameData.php?id=729`: **REFERENCE_UNVERIFIED**. 조회 실패로 원본을 확인하지 못했다. 다른 게임을 같은 출처로 대체하지 않았다.
- 일부 회차·계약·엔딩/도감·전초기지 메뉴는 공통 테마와 글자 적용까지다. 모든 화면의 정보 구조를 다시 완성한 것은 아니다.
- 기존 배경·조명·가림과 이동 중 자글거림에 대한 전체 미술 판정, 사람의 취향·가독성·사용성 시험은 남아 있다.
- 새 미술 채택 시 구현 SHA가 바뀌므로 해당 화면/시설 검사를 다시 하고 새로운 검수 기준을 기록한다.
