# UIUX V2 — 공통 판석 UI·병영·입체 캐릭터 1차 연결

## 1. 메타데이터

- 작업 시작일: 2026-09-12
- 최종 기록일: 2026-09-13 (KST 날짜 경계 이후 문서 마무리)
- WORKSTREAM_ID: UIUX-V2-ART-DIRECTION-20260912
- 목표 버전: 공개 기준 제품 1.2.6의 UIUX 작업. 새 제품 버전·출시일 미확정.
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 브랜치 및 SHA: main / origin/main / 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD: e9a566311d22c40d228b142e439b784b2fb824ec
- 마지막 구현 커밋 SHA: 2b4514ea036637997d7bd668a5466efa70a677a2
- 원격 푸시 여부: 미푸시. 이후 로컬 핸드오프 문서 커밋만 추가.
- 관련 PR 또는 태그: 이번 작업 없음. 기존 v1.2.6 및 과거 v20 브랜치/태그 불변.

선택 작업트리 C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2는 시작 때 깨끗했다. 루트의 기존 혼합 작업트리는 보존했다. main:AGENTS.md의 1.2.5 문구와 main:CURRENT.md의 공개 1.2.6이 충돌한다. 최신 사용자 요청·CURRENT·기존 v1.2.6을 대조해 1.2.6을 기준으로 삼았고 새 버전을 정하지 않았다. 원격 main 최신성은 git ls-remote로 확인했다. Godot 4.6.3을 실제 실행했다.

## 2. 이번 세션 목표

사용자가 정한 순서는 ① 네모 UI를 지정 참고와 비슷한 그래픽으로 개선 ② 강제 축소로 깨진 건물 외형 개선 ③ 현재 캐릭터·적을 입체감 있는 그림으로 수정이다. 기존 V2 직접 배치와 게임 규칙을 보존하면서 대표 자산을 실제 화면에 연결했다.

사용자 지정 원본은 [Curse of the Dead Gods](https://www.gameuidatabase.com/gameData.php?id=729)로 확인했다. **REFERENCE_VERIFIED — 2026-09-12 Chrome, 설정·전리품 선택 화면.** 어두운 판석, 잘린 모서리, 얇은 금빛 테두리와 선택 강조를 참고했다. 스크린샷을 다운로드하거나 생성 입력으로 복제하지 않았고 다른 게임을 같은 원본으로 취급하지 않았다. 앞선 핸드오프의 REFERENCE_UNVERIFIED는 그때의 상태다.

이번 결과는 공통 UI 2장, 병영 4방향, 대표 캐릭터 8종이다. 모든 시설·후반 배우·대형 초상·모든 화면 정보 구조의 완성을 뜻하지 않는다. 전체 DAY 1~30·8인 검수·공개 배포·태그는 범위 밖이다.

## 3. 완료한 작업

- 공통 버튼·패널을 GPT 판석 텍스처 기반으로 바꿨다. 9개 영역으로 나누어 그리되 모서리의 화면 크기는 유지한다. 높이가 큰 카드는 패널 그림을 사용한다. hover/pressed/disabled/selected/focus를 구별하고 선택 테두리와 키보드 포커스를 유지했다.
- 실제 활성 시설 가져오기 설정 60개에서 mipmap(축소 단계별 표본)을 켜거나 후반 고해상도 자산의 size_limit 768 제한을 해제했다. 카드도 지도와 같은 축소 필터를 쓴다. 비활성 full_grid·옛 대체 시설 등 23개는 변경 대상에서 제외했다.
- 병영 NW/NE/SE/SW를 각 기존 방향 원본에 맞춰 다시 생성했다. manifest의 공통 4방향과 stage 2 SE 선택을 연결했다. 비용·해금·고유 시설·유효 슬롯·구성 선택은 기존 경로를 재사용한다.
- 푸딩(slime), 고브(goblin), 핀(imp), 모리(spore_healer), 탐험가, 도둑, 수습 용사, 방패병에 부드러운 빛·둥근 형태·입체 재질의 새 스프라이트를 연결했다. 실제 3D 모델을 추가한 것은 아니다.
- 기존 대기 2/쓰러짐 2/이동 4/공격 4/스킬 4프레임과 재생 속도를 유지했다. 투명 여백과 몸체 크기를 분리해 지도·드래그·전투·성장 화면에서 캐릭터가 작아지거나 발이 어긋나지 않게 했다. 프레임별 효과의 과도한 잘림은 GPT 간격 보완과 런타임 표시 여백으로 수정했다.
- 지도와 동료 화면은 현재 진화·왕관 형태의 실제 전투 그림을 선택한다. 기본 8종을 새로 그렸다는 이유로 기존 진화 그림을 기본형으로 덮지 않는다. 기존 라이벌 보스 3종의 sprite_sheet 필드도 Unit에 연결했다.
- 스토리·비용·능력치·AI·보상·저장 형식 변경 없음. monsters/enemies JSON은 sprite 경로를 제외한 구조적 값이 시작 커밋과 같다. 배열 줄바꿈 서식 차이는 남아 있다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/ui/ObsidianStyleBox.gd, UIUXTheme.gd, HUDController.gd | 공통 판석 표면·버튼 상태·포커스 |
| scenes/ui/screens의 CampaignModeSelection, Chronicle, DuoLinkLoadout, FrontSelection, HeartSelection, RegionSelection, UpperFloor; scenes/outpost/OutpostBattleRoot.gd | 공통 StyleBox 연결 및 반환형 호환 |
| scripts/ui/FacilityPreview.gd, assets/props의 활성 .png.import 60개 | 지도/카드 축소 품질 |
| data/dungeon_quarter/asset_manifest.json, assets/props/uiux/barracks_*.png | 병영 4방향 연결 |
| scripts/ui/UIUXActorArt.gd, data/uiux_actor_art.json, tools/measure_uiux_actor_art.py | 몸체 경계·UV·발 위치와 효과 여백 |
| scripts/units/Unit.gd, scripts/core/DataRegistry.gd, data/v122/combat_visual_profiles.json | 실제 프레임·크기·머리 위 UI 기준점 |
| scripts/game/GameRoot.gd, ManagementSceneController.gd, scripts/map/DungeonRenderer.gd, scripts/ui/MonsterWorkspaceUI.gd | 현재 외형 지도/드래그/동료 화면 |
| data/monsters.json, data/enemies.json, assets/sprites/uiux3d/* | 대표 8종 런타임 경로 |
| tools/UIUXActorArtTest.*, UIUXBarracksArtTest.*, UIUXArtDirectionCapture.*, fixtures/uiux_actor_legacy_profiles.json | 새 자산 직접 검사·전후 비교 |
| tools/UIUXSecondaryInteractionTest.gd, tools/tests/V122CombatVisualHierarchyTest.gd | 현재 Mori 경로와 네이티브 프레임 계약 반영 |
| assets/source/imagegen/uiux_*_20260912/SOURCE.md 및 원본 PNG | 출처·프롬프트·실제 알파 처리 기록 |

이번 구현 커밋의 정확한 155개 경로는 git show --name-only 2b4514ea036637997d7bd668a5466efa70a677a2에서 확인한다. 관련 Godot 스크립트의 새 UID도 포함했다. tmp·캡처·실행 파일은 커밋하지 않았다.

## 5. 그래픽 및 오디오 자산

- Generation model: GPT internal image generation
- UI 원본/출처: [uiux_obsidian_20260912/SOURCE.md](../../assets/source/imagegen/uiux_obsidian_20260912/SOURCE.md)
- 병영 원본/출처: [uiux_barracks_20260912/SOURCE.md](../../assets/source/imagegen/uiux_barracks_20260912/SOURCE.md)
- 캐릭터 원본/출처: [uiux_actors3d_20260912/SOURCE.md](../../assets/source/imagegen/uiux_actors3d_20260912/SOURCE.md)
- 런타임: assets/ui/uiux, assets/props/uiux/barracks_*, assets/sprites/uiux3d.
- 새 런타임 14장의 PNG 합계: 18.69 MiB. 원본 14장은 같은 바이트를 별도 보관한다.
- 알파: 최종 14장 실제 RGBA/바깥 alpha 0. 소스와 런타임 SHA-256 일치. 불투명 체크무늬 후보는 제외했다.
- 도구의 실제 prompt/referenced_image_paths만 사용했다. 제공되지 않은 background 파라미터를 전달했다고 기록하지 않는다. 로컬 배경 제거·리사이즈·픽셀 편집 없이 GPT 내부 도구에서 투명 PNG를 받았다.
- 후처리: PNG를 읽어 JSON의 런타임 UV·margin·몸체 경계만 작성했다. 원본 픽셀 변경 없음. 몸체 경계와 10px 반투명 효과 여유를 분리했다.
- 오디오 변경 없음.

## 6. 테스트 및 검수

Windows / Godot 4.6.3 / Vulkan Forward+ / RTX 3060 Ti. 실제 렌더링을 사용하는 테스트 씬에서 마우스·키 입력을 주입했다. 자동 픽스처 검사이며 사람의 자연 플레이를 수행했다고 쓰지 않는다. APPDATA를 tmp의 별도 경로로 격리했다. 네이티브 창은 포커스 간섭을 피하도록 순서대로 실행했다.

| 검사 | 결과 | 근거 |
|---|---|---|
| UIUXBuildPlacementTest | PASS 343 | tmp/uiux_art_final_UIUXBuildPlacementTest.stdout |
| UIUXSecondaryInteractionTest | PASS 3,260 | tmp/uiux_art_verified_UIUXSecondaryInteractionTest.stdout |
| UIUXCombatInteractionTest | PASS 210 | tmp/uiux_art_verified_UIUXCombatInteractionTest.stdout |
| UIUXBarracksArtTest | PASS 214 | tmp/uiux_barracks_art3.stdout |
| UIUXActorArtTest | PASS 406 | tmp/uiux_art_actor_halo.stdout |
| UIUXArtDirectionCapture -- after_final | PASS 54장 + 촬영 편성 확인 6개 | tmp/uiux_art_capture_final.stdout |
| V122CombatVisualHierarchyTest | PASS | tmp/uiux_art_hierarchy_halo.stdout |
| V122CombatVisualProfileContractTest | PASS | tmp/uiux_art_verified_V122CombatVisualProfileContractTest.stdout |
| V122CombatVisualRuntimeProfileContractTest | PASS | tmp/uiux_art_verified_V122CombatVisualRuntimeProfileContractTest.stdout |
| V122VisualTextureConsistencyTest | PASS | tmp/uiux_art_V122VisualTextureConsistencyTest.stdout |
| V125StageProgressionVisualRuntimeTest | PASS | tmp/uiux_art_V125StageProgressionVisualRuntimeTest.stdout |
| 14쌍 소스/런타임 해시·게임 수치 비교 | PASS | tmp/uiux_art_direction/asset_audit.json |
| 비교 HTML의 142개 이미지 참조·JS 문법 | PASS | tmp/uiux_art_direction/index.html |
| git diff --check | PASS | 구현 커밋 전 실행 |
| tools/ci/ValidateRepositoryPolicy.ps1 -BaseRef main | PASS (236 final files, 10 commits inspected) | 핸드오프 커밋 563ba15 기준 실행 |
| 전체 회귀·전체 플레이·8인 검수 | NOT_REQUESTED | 실행하지 않음 |
| 사람 사용성·Web/모바일·저사양 성능 | NOT_RUN | PASS 아님 |

직접 동작/자산 검사 5종의 합계는 **4,433개**다. 기존 계약 검사 5종과 캡처 검사는 이 수에 합치지 않았다. 기존 핸드오프의 과거 검사 수를 더해 이번 결과를 부풀리지 않는다.

1920×1080 / 1280×720, 글자 90/100/115%에서 관련 화면을 캡처했다. 새 병영은 현재 맵의 유효 NW·NE 후보에서 드래그→검토→확정→중복 차단→Undo→ESC를 6가지 표시 조건으로 검사했다. 새 SE 자산은 기존 설치 병영에서 렌더링되며 SW 신규 설치를 실제 지도에서 수행한 것은 아니다. 일반 건설 검사는 UI 위·지도 밖·고정 방·잘못된 위치·화면 전환·포커스 상실·취소·Undo를 포함한다. 전투 상시 3명령에 새 확인창 없음.

8종의 모든 동작 프레임, 기존 라이벌 3종, 진화/왕관 12형태의 그림 경로와 공격 프레임을 확인했다. 마지막 몸체·효과 여백 변경 뒤 Actor/Hierarchy/화면 캡처를 재실행했다. 게임 규칙이 변하지 않은 일반 건설·보조 화면 검사는 같은 작업흐름의 최종 관련 실행 결과다.

### 실제 시각 증거

- [로컬 전후 비교](../../tmp/uiux_art_direction/index.html): UI 42쌍, 병영 36장, 캐릭터 동작표 전후 16장, 실제 전투 전후 4장, 동료 화면.
- tmp/uiux_art_direction/after_final: 54장. stage 1/2/3/4, 동료, 타이틀, 설정, 교리, 전초기지 × 6조건.
- tmp/uiux_evidence/03_drag_valid.png → 04_review.png → 05_built.png → 06_undo.png / 07_cancel.png: 이번 스타일로 일반 건설 실행.
- 전 캡처의 stage 2는 잘못된 단계 ID를 써서 비교에서 제외했다. 수정 후 올바른 stage_02_castle을 찍었다.
- 후반 촬영 픽스처의 출전 편성이 다음 동료 촬영에 남아 한 명만 보이던 문제는 테스트 상태를 분리해 수정했다. 기본 3명이 보이는지 별도 확인했다.
- 도구 씬이 만든 DAY 16·후반 상태는 자연 캠페인 진행 증거가 아니다.
- 화면 순회 중 텍스처 메모리 관측: 493,732,352~503,891,968 bytes(최대 약 480.55 MiB). 기존과 동일 조건의 메모리 비교·저사양 성능 합격을 주장하지 않는다.

### 검증 중 수정

선언 순서/타입 추론 파서 오류, 실제 유효 병영 방향 수와 테스트 가정 불일치, 기존 Mori 파일명 하드코딩, 192px 레거시 프레임 가정, 부동소수점 배열 비교를 수정하고 해당 검사를 재실행했다. 실패 로그도 tmp에 남겼으며 위 표는 마지막 통과 로그만 가리킨다. 읽기 전용 보조 조사에서 가져오기 범위·버튼 상태·런타임 경로·표시 크기를 확인했지만 별도 전체 검수의 PASS로 취급하지 않는다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 2b4514ea036637997d7bd668a5466efa70a677a2
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..2b4514ea036637997d7bd668a5466efa70a677a2
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

이 판정은 이번 변경의 표적 검사에 한한다. Reviewed SHA 뒤에는 docs/handoff 파일만 변경한다.

## 7. 미해결 항목과 위험

- 병영 외 저해상도 시설은 가져오기 품질을 개선했지만 원본 형태·색·밀도를 모두 다시 그린 것은 아니다. 나머지 시설과 단계/방향 간 미술 일관성은 남아 있다.
- 후반 적·계약 동료·진화·왕관 외형은 아직 기존 그림이다. 타이틀/대화/회상/승급용 큰 초상도 새 기본 전투 그림과 미술 차이가 남는다.
- 새 16프레임은 실제 동작하지만 수작업 3D 리깅 결과가 아니다. 일부 자세·효과·방향별 소품의 세부 일관성과 미술 취향 평가는 남는다.
- 공통 테마가 적용된 모든 화면을 개별 재배치한 것은 아니다. 이름 입력, 기록/회상, 상층 고정 모듈, 전초기지 전투의 정보 구조와 키보드 접근을 계속 확인해야 한다.
- 전체 조명·배경·이동 중 자글거림·저사양 텍스처 메모리와 사람 사용성 미검증.
- 선택적 JSON 서식 정리를 위해 기준 커밋에서 파일을 재구성하려던 작업이 자동 승인 검토에서 거절됐다. 기존/사용자 변경을 덮을 수 있다는 사유였다. 실행·재시도하지 않고 현재 JSON을 보존했다. 실제 기능 변경·검증은 차단되지 않았다.

## 8. 다음 작업 순서

1. 실제 게임에 남은 시설을 manifest 기준으로 선정해 병영과 같은 원본 재제작·방향 일치·카드/고스트/설치 검사로 확장한다. 변경 경로: assets/props, assets/source/imagegen, data/dungeon_quarter/asset_manifest.json.
2. 나머지 캐릭터/적과 진화·왕관, 큰 초상을 현재 8종의 입체 재질에 맞춘다. 기존 정체성과 장비·동작 계약을 보존하고 작은 실제 표시 크기에서 비교한다. 변경 경로: assets/sprites, assets/portraits, 관련 데이터/visual profile.
3. 공통 테마만 적용된 보조 화면의 활성 호출과 정보 구조를 개선하고 해당 입력/해상도만 직접 검사한다.
4. 사람 사용성·전체 DAY 1~30·8인 검수·새 버전·공개 배포는 이번 요청에서 자동 실행하지 않는다.

## 9. 작업 트리 상태

- 구현 2b4514ea036637997d7bd668a5466efa70a677a2와 핸드오프 563ba15를 로컬 커밋했다. 해당 시점 git status는 깨끗했고 저장소 정책 검사도 PASS였다. 이 결과 기록만 핸드오프 전용 커밋으로 추가한다.
- 원래 루트 혼합 작업트리와 다른 브랜치는 수정하지 않았다.
- 미푸시, PR 없음, 출시/태그 변경 없음.
- 로컬 로그·캡처·비교 HTML·Godot 실행 파일은 tmp 아래이며 소스에 추가하지 않는다.

## 10. 종료 체크리스트

- [x] 이번 변경과 요구사항 대조, 잔여 범위 분리
- [x] 변경 기능의 관련 직접 검사
- [x] Windows 두 해상도·세 글자 배율 확인
- [x] 검수 SHA와 범위 기록
- [x] 원본·프롬프트·네이티브 알파·런타임 출처 기록
- [x] CURRENT 갱신
- [x] 구현 경로 명시 스테이징·로컬 커밋
- [x] 원격 푸시/PR/태그 없음 기록
- [ ] 전체 미술·모든 메뉴 완료 — 아직 아님
