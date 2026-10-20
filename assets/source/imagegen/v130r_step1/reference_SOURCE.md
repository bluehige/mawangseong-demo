# assets_v7 — 게임 반영용 최종 후보

**사용자 확인 대기.** 직접 화면 검수와 외부 산출물 검증은 TARGETED_PASS. 게임에 반영하거나 사용자 승인으로 기록하지 않았다.

Generation model: GPT internal image generation
Generated date: 2026-10-16 (KST)
Target version: assets_v7 (외부 목업 최종 후보, 게임 미반영)

사용자 2026-10-16 10:50 피드백에 따라 v6의 붉은 기 범위와 조립·실내·입구를 기준으로 판석 크기와 바닥 거울 반복만 보정했다. 신규 그림은 내장 GPT image_gen으로 만들었으며 외부 API나 다른 생성기는 사용하지 않았다. 정확한 프롬프트·생성 원본 위치는 [generation_receipts.json](prompts/generation_receipts.json)에 있다.

## 요청 출력

| 파일 | 크기 | 내용 |
|---|---|---|
| [preview_full.png](preview_full.png) | 1920×1080 | 전체, v6와 동일한 카메라 |
| [preview_zoom2x.png](preview_zoom2x.png) | 1920×1080 | 전체 대비 2배 카메라 |
| [road_close.png](road_close.png) | 1920×1080 | 길 경계 4곳, 2×2 조립 |
| [grayscale_check.png](grayscale_check.png) | 1920×1080 | 전체 화면의 BT.601 흑백 |
| [compare_v6_v7.png](compare_v6_v7.png) | 3840×1080 | 왼쪽 v6 / 오른쪽 v7 |
| [final/asset_table.csv](final/asset_table.csv) | 49행 | 게임용 PNG 49개, 이름·크기·피벗·앵커·출처·해시 |

## 판석 크기와 색

Source image path: source/road_texture.png
Runtime image path: textures/road_material.png
Runtime image path: final/terrain/road_material.png

새 생성 원본은 **1774×887 RGB**. 같은 재질을 더 작은 사각·직사각 판석으로 다시 그렸다. 원본을 **512×256**으로 축소해 전역 화면 좌표에 배치했다. 바닥과 달리 정돈된 길 포장 패턴은 같은 방향으로 반복하며 뒤집지 않는다. 128×64 한 칸에 512×256 전체 이미지를 늘려 넣지 않는다.

| 측정 | v6 | v7 |
|---|---:|---:|
| 길 원본의 월드 축소율 | 768/1774 = 0.432920 | 512/1774 = 0.288613 |
| 완전히 잡힌 판석 면 수 | 35 | 102 |
| 판석 외접 크기 중앙값, 월드 픽셀 | 111.26×80.52 | **41.99×29.44** |
| v6 대비 가로/세로 크기 | 1 | **0.3774 / 0.3656** |
| 2칸 폭 표본에서 보이는 판석 구간 수 중앙값 | 3 | **5** |
| 전체 화면 길 평균 밝기 | 108.0951 | **109.1455 / 255** |

판석의 선형 크기는 v6의 약 **37%**, 약 1/2.7이다. 목표 1/2~1/3 범위다. 외접 크기는 그림 속 개별 판석의 화면상 가로·세로 경계이며, 돌의 실제 정사각형 변 길이와 다르다.

측정 방법과 개별 판석 경계·표본은 [paving_size.json](checks/paving_size.json)에 있다. 어두운 줄눈의 국소 골을 찾아 돌 면을 구분한 기술 통계이며, 예술적 품질 판정을 대신하지 않는다. 폭 2칸의 벡터 (128,64)를 12번 표본 추출했다. 중앙값 5개, 11/12 표본은 4~6개였고 한 표본은 미세 균열·부분 판석까지 잡혀 8개였다. 직접 화면에서도 대표 길 폭에 약 4~6개가 보이는지 확인했다.

길은 v6와 같은 낮은 채도의 붉은 회갈색이다. 생성 모델의 재해석으로 RGB가 완전히 같지는 않다. 최종 화면 길 RGB는 v6 **(127.6782, 100.8079, 94.2553)** → v7 **(133.4944, 100.1056, 91.8311)**, 밝기 변화는 **+1.0504/255**다. 이를 숨기거나 로컬 색 보정을 하지 않았다. 직접 좌우 비교 후 같은 재질 범위의 최종 후보로 채택했으며 최종 취향 판단은 사용자 확인 대기다.

## 거울 반복 제거와 원본 해상도

v6 바닥 한 장과 새 바닥 3장을 **각각 한 번**, **원본 픽셀 1:1**, **뒤집기·회전·타일 반복 없이** 놓았다. 네 원본의 SHA-256은 모두 다르다. 큰 영역이 만나는 64px 경계에는 조립용 투명도 마스크만 사용했다. 질감 그림·줄눈·균열·색·밝기를 코드로 그리거나 보정하지 않았다.

Source image path: source/cave_floor.png
Source image path: source/cave_floor_b.png
Source image path: source/cave_floor_c.png
Source image path: source/cave_floor_d.png
Runtime image path: textures/cave_floor_continuous.png
Runtime image path: layers/ground_continuous_fill.png
Runtime image path: final/terrain/ground_unique_field.png

| 원본 | 크기 | 월드 왼쪽 위 | 배치 횟수/배율 |
|---|---|---|---|
| cave_floor.png — v6 보존 | 1536×1024 | (254,1024) | 1회 / 1.0 |
| cave_floor_b.png — 새 그림 | 1448×1086 | (1050,510) | 1회 / 1.0 |
| cave_floor_c.png — 새 그림 | 1448×1086 | (2011,510) | 1회 / 1.0 |
| cave_floor_d.png — 새 그림 | 1536×1024 | (1150,1091) | 1회 / 1.0 |

자세한 조립 좌표는 [floor_assembly.json](checks/floor_assembly.json)에 기록했다. 바닥 미덮임은 0픽셀이다. 전체 카메라 배율은 0.48, 2배·길 확대는 0.96이므로 바닥 원본 해상도를 확대하지 않았다. 길 확대의 원본 대비 배율도 0.2771이다.

v6의 정확한 거울 이음선 두 곳에서 양쪽 그림의 대칭 상관도를 확인했다. v6는 X/Y 모두 **1.0000**, v7은 **0.0349 / 0.0304**다. 해당 이음선의 대칭 픽셀 차이는 v6 0에서 v7 16.1263 / 14.4249로 바뀌었다. 반복 복사 배치 0회라는 조립 기록과 함께, 전체·확대 화면에서 눈에 띄는 대칭이나 복사된 암반 무늬가 없는지도 직접 확인했다. [repetition.json](checks/repetition.json)

## 밝기와 흑백

최종 1920×1080 화면에서 오브젝트·물·연석·접촉 경계를 제외한 실제 길 40,883픽셀, 바닥 179,715픽셀을 사용했다. 밝기는 흑백과 같은 BT.601 **Y=0.299R+0.587G+0.114B**, 0~255 기준이다.

| 항목 | 결과 |
|---|---:|
| 길 평균 RGB | 133.4944, 100.1056, 91.8311 |
| 바닥 평균 RGB | 57.6679, 49.7948, 57.4427 |
| 길 평균 밝기 | **109.1455 / 255** |
| 바닥 평균 밝기 | **53.0207 / 255** |
| 길 − 바닥 | **56.1248 / 255** |
| 저장된 흑백 PNG에서의 차 | **56.1364 / 255** |
| 최소 기준 | 25 / 255 — 통과 |

[brightness.json](checks/brightness.json)에 수치와 샘플 수를 남겼고, 샘플 마스크도 checks 안에 보존했다.

## final 반영 지침과 피벗

final에는 **런타임 PNG 49개와 asset_table.csv만** 있다. 미리보기, 생성 시트, 미채택 그림과 검사 마스크는 들어 있지 않다. 표의 name은 모두 고유하다. width/height와 pivot_x/pivot_y는 PNG 왼쪽 위 기준의 픽셀 좌표이며, 정규화 좌표·앵커·출처·SHA-256도 기록했다.

- terrain/ground_unique_field.png는 이 32×18 목업 부지용 **3205×1605 통합 바닥 조각**이다. 타일 한 칸이 아니다. 피벗 **(2,1026)**을 월드 P(0,0)에 맞추면 왼쪽 위가 (254,510)이 된다. 반복·미러를 켜지 않는다. 더 큰 맵으로 단순 확대하면 해상도와 비반복 조건이 달라지므로 새 조립이 필요하다.
- terrain/road_material.png는 **512×256**의 전역 포장 재질이다. 128×64 셀 단위로 질감 좌표를 초기화하지 않는다. 연석은 연결된 길 영역 바깥에만 놓는다.
- road/와 water/는 방향별 직선 2개와 안/바깥 코너 각 4방향이다. 코너 방향 변환은 v6의 기하 조립을 그대로 저장한 것이며 새 그림을 코드로 만들지 않았다.
- cliff/는 v6의 네이티브 투명 절벽 레일이다. 경사·길이·깊이 조립 조건을 표 notes에 기록했다.
- interiors/의 8종 그림 픽셀과 입구 피벗 **(290,185)**·앵커 **P(3,9)**는 v6와 같다. 입구 PNG는 340×321이다.
- 기존 물·다리·건물 벽·외곽·함정·배경·목업 캐릭터 조각도 기존 배치를 재현할 수 있게 모았다. 기존 캐릭터는 v6에서 쓰던 게임 원본의 동일 자르기·축소 결과이며 신규 생성물이 아니다.

생성 원본과 재사용 자산의 과거 출처는 [../assets_v6/SOURCE.md](../assets_v6/SOURCE.md), v6가 참조하는 이전 버전의 SOURCE.md를 계승한다. 새 바닥과 길 이외 그림은 새 생성으로 주장하지 않는다. source 안의 과거 미채택 후보는 v6에서 복사한 역사 자료이며 final에는 포함하지 않았다.

## 직접 검수와 보존

전체, 2배, 길 4곳 확대, 흑백, v6/v7 좌우 비교를 직접 보고 통과로 기록했다.

1. 작은 사각·직사각 판석이 정돈된 포장길로 보이며, 커다란 돌덩이나 자갈길처럼 보이지 않는다.
2. 바닥의 이전 거울 대칭·복사 무늬가 보이지 않는다.
3. 흑백에서 길의 분기·합류가 바닥과 구별된다.
4. v6의 입구·실내·연석·그림자·건물·물·다리 배치는 유지됐다.

[visual_review.json](checks/visual_review.json)에 실제 검수 이미지 해시와 관찰을 기록했다. **image_gen 총 4회, 재생성 0회**, 미달 시 최대 2회라는 한도를 넘지 않았다.

v1~v6의 **805개 파일 SHA-256 보존**, 원본 assemble.py·입구 설정·실내 8종·함정 보존, 오브젝트 가림 마스크·길/물 외곽선 및 그림자 픽셀·배치 정보 동일성을 확인했다. final 49개 PNG와 표의 이름·크기·해시 일치, 투명 이미지 알파와 최종 바닥·실내 픽셀도 검사했다. [verify.json](verify.json), [final_manifest.json](checks/final_manifest.json), [final_alpha.json](checks/final_alpha.json)

저장소 브랜치 codex/v130r-defense-layout, 시작/종료 HEAD **acc7f048d3bd9141c6511d7f99561ec3efeb277c**. 기존 혼합 작업 트리 상태가 시작 전과 동일하다. 로컬 main 참조가 없어 최신 정책/CURRENT 권위를 확정하지 않았으며 이번 외부 목업 작업의 제품 상태를 임의 변경하지 않았다.

게임 코드·저장소 문서 수정, Godot 실행, 빌드, 게임 전체 검수, 커밋·푸시는 하지 않았다. 게임 반영과 엔진 안에서의 연결 확인은 이번 범위에 포함되지 않는다.

## 재현

이미 보존한 원본으로 아래 순서대로 실행하면 된다. 이미지 생성기를 다시 호출하지 않는다. prepare_v7.py는 최초 보존 기준을 기록하는 준비용이며 최종 재현 시 다시 실행하지 않는다.

1. python assemble_v7.py — 원본 assemble.py는 변경하지 않고 바닥/길 재질과 검사 카메라만 메모리에서 치환
2. python measure_paving.py
3. python pack_final.py
4. 직접 화면 확인 후 record_review.py
5. python verify_v7.py

WORKSTREAM_ID: ASSETS_V7_FINAL_CORRECTION_20261016
Review task ID: NOT_REQUESTED
Remaining P1/P2: N/A
Final review result: TARGETED_PASS
Next: 사용자 확인 대기. 승인 뒤 별도 요청으로 게임 반영.
