# UIUX V2 단계별 시설·지도 확대·가독성 개선

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 공개 기준 v1.2.6, 새 제품 버전 미확정
- WORKSTREAM_ID: UIUX-V2-STAGE-ART-NAVIGATION-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 main / origin/main / 원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD: cc57d9047f65d3173514e6c3117e9f7d1f50d6dc
- 마지막 구현 커밋 SHA: 8cde57752afeeaa679f927b11de171bef356204c
- 원격 푸시 여부: 미푸시. PR·태그·Release·공개 배포 없음.
- 권위 확인: 초기 clean 작업트리, 브랜치·HEAD·main·origin/main과 main:AGENTS.md / main:docs/handoff/CURRENT.md를 읽고 git ls-remote로 원격 main 일치를 확인했다.
- AGENTS의 과거 1.2.5 문구는 최신 사용자 지시와 권위 CURRENT의 1.2.6에 대조해 기록했다. 과거 v20·기존 태그·루트 혼합 작업트리는 보존했다.

## 2. 이번 세션 목표

사용자의 계속 지시에 따라 남은 단계 전용 시설 11종을 게임 크기에서 읽히는 입체 음영으로 재제작하고, 지도 확대·이동과 이름표 가독성을 개선한다. 이전 실제 건설 경로와 게임 규칙을 유지하면서 같은 장면의 전후·조작 증거를 남긴다.

지정 참고는 이전 확인된 Curse of the Dead Gods 설정/전리품 화면이다(REFERENCE_VERIFIED, 2026-09-12 Chrome). 공통 UI는 이미 연결한 판석 자산을 재사용했다. 전체 미술, 전체 캠페인, 사람 사용성, 8인 검수, 다른 플랫폼과 출시는 이번 완료 범위가 아니다.

## 3. 완료한 작업

- 단계 전용 병영 SE 1/3/4단계, 정예 병영 NW 4단계, 보물고·회복 둥지 NW 각 1/3/4단계, 감시초소 NW 4단계: 총 11장.
- manifest 의미 비교 결과 정확히 PNG 경로 11개만 교체했다. 단계·방향·층·바닥 기준점·실제 건설 구역은 보존했다.
- 휠 확대/축소, 휠 버튼을 누른 채 지도 이동, 포커스 가능한 +/−와 지도 전체 버튼을 연결했다. 포인터의 월드 지점을 중심으로 확대하고 맵 경계 안에서 이동한다.
- 도구함·팝업 위에서는 지도 조작을 시작하지 않는다. 건설 카드 드래그/클릭 배치/검토와 수비대·지도 몬스터 드래그/클릭 배치 중에는 지도 이동·확대·맞춤을 잠근다.
- 이동 제스처는 UI 위 버튼 해제, 동시 왼쪽 입력, ESC, 포커스 상실, 화면 전환까지 소유한다. ESC는 진행 중 이동만 끝내고 관리 종료 시 이전 뷰를 복원한다.
- 지도 이름·유효/불가 안내·몬스터 이름은 화면 좌표로 그려 확대 배율과 독립적으로 유지하고 기존 글자 배율을 반영한다. 긴 안내는 단어 단위로 줄바꿈한다.
- 실제 캡처에서 철거 후 같은 입구에 모인 몬스터 이름표 겹침을 발견해, 겹친 이름표를 아래로 간격 배치하고 원래 몬스터 위치까지 연결선을 표시했다. 이름이나 실제 클릭 영역을 없애지 않았다.
- 카드·고스트·설치는 같은 현재 단계/방향/구성을 사용한다. 드롭은 상태를 바꾸지 않으며 확정은 기존 실행 경로 1회, 취소는 무비용, Undo는 기존 기능이다.
- 비용·해금·고정/고유 시설·AI·경로·수용량·성장·보상·스토리·저장 구조와 제품 버전은 변경하지 않았다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/game/BuildingPlacementController.gd | 지도 확대·이동·경계·입력 소유·조작 잠금 |
| scripts/ui/ManagementWorkspaceUI.gd | 공통 판석 지도 버튼과 조작 안내 |
| scripts/game/GameRoot.gd | 화면 기준 이름표·줄바꿈·겹침 회피·포커스 상실 처리 |
| scripts/map/DungeonRenderer.gd | 실제 활성 몬스터 미리보기 이름표 연결 |
| data/dungeon_quarter/asset_manifest.json | 기존 단계/방향 PNG 11곳 교체 |
| assets/props/uiux/{barracks,recovery,treasure,watch_post}_stage*.png 중 신규 11쌍 | 실제 RGBA와 무손실·밉맵 import |
| assets/source/imagegen/uiux_stage_facilities_20260913/ | 생성 원본 11장과 SOURCE.md |
| tools/UIUXStageFacilityArtTest.gd/.gd.uid/.tscn | 실제 단계 시설 66사례·투명 자산·이름표 검사 |
| tools/UIUXBuildPlacementTest.gd | 기존 테스트의 로컬 증거 경로 인수 추가 |
| tools/UIUXMapNavigationTest.gd/.gd.uid/.tscn | 확대/이동/버튼/잠금/변환 후 건설 24조건 |

구현 커밋은 46개 파일. tmp의 테스트 실행용 래퍼, 로그와 캡처는 로컬 전용이다.

## 5. 그래픽 및 오디오 자산

- Generation model: GPT internal image generation
- [SOURCE.md](../../assets/source/imagegen/uiux_stage_facilities_20260913/SOURCE.md)에 참조 원본·생성 출력·프롬프트·날짜·목표 버전·원본/런타임 경로·SHA-256을 기록했다.
- 11장 모두 실제 RGBA, 모서리 alpha 0, 투명/불투명 픽셀과 서로 다른 해시를 확인했다. 원본과 런타임 PNG 바이트가 같다.
- 처음 RGB로 나온 보물고 2장과 회복 1장, 회복의 추가 불투명 후보 2장은 미채택했다. 보물고는 같은 GPT 내부 도구로 투명 편집, 회복은 원래 투명 시설을 참조해 다시 생성하여 실제 알파 결과를 채택했다.
- 로컬 배경 제거·리사이즈·크롭·반전·회전 없음. 런타임은 원본 크기, 무손실 import, mipmaps/generate=true, process/size_limit=0을 사용한다.
- 새 런타임 PNG 합계 18.99 MiB. 실제 3D 모델이 아닌 입체 음영의 2D 스프라이트다.
- 새 오디오는 없으며 기존 건설 효과음과 배치 반응을 유지했다.

## 6. 테스트 및 검수

Windows / Godot 4.6.3.stable.official.7d41c59c4 / Vulkan Forward+ / RTX 3060 Ti. APPDATA는 tmp의 격리 테스트 경로를 사용했다.

| 검사 | 결과 | 증거 |
|---|---|---|
| 변경 전 UIUXStageFacilityArtTest -- before | PASS 1,546개, 실제 66배치 | tmp/uiux_stage_art_before.stdout |
| 최종 UIUXStageFacilityArtTest -- after | PASS 1,887개, 실제 66배치 | tmp/uiux_stage_art_after_final.stdout, after/results.json |
| 최종 UIUXMapNavigationTest | PASS 1,062개, 관리 24조건 | tmp/uiux_stage_navigation_final.stdout, navigation/results.json |
| 기존 UIUXBuildPlacementTest | PASS 343개 | tmp/uiux_stage_build_safety_final.stdout |
| V122Stage01SpatialVisualRuntimeTest | PASS | tmp/uiux_stage_V122Stage01SpatialVisualRuntimeTest.stdout |
| V122VisualTextureConsistencyTest | PASS | tmp/uiux_stage_V122VisualTextureConsistencyTest.stdout |
| V125StageProgressionVisualRuntimeTest | PASS | tmp/uiux_stage_V125StageProgressionVisualRuntimeTest.stdout |
| Godot import / 밉맵 reimport | exit 0 | tmp/uiux_stage_import.stdout, tmp/uiux_stage_mipmap_import.stdout |
| manifest 의미 비교 | PNG 경로 11개만 변경 | 기존 HEAD와 JSON 구조 재귀 비교 |
| 전후 HTML 링크·JS 문법 | 588개 링크 존재, node --check PASS | tmp/uiux_stage_art_20260913/index.html |
| git diff --check | PASS | 구현 커밋 전 |
| ValidateRepositoryPolicy.ps1 -BaseRef main | PASS (370개 최종 파일, 19개 커밋 검사; 이후 핸드오프 문서만 변경) | tmp/uiux_stage_policy.stdout |
| 전체 캠페인·8인·사람 사용성·다른 플랫폼 | NOT_REQUESTED / 미실시 | 전체 PASS로 확대하지 않음 |

시설 검사는 1920×1080 / 1280×720 × 글자 90/100/115% × 실제 단계 1/3/4의 11개 그림을 66회 설치했다. 병영 SE는 기존 철거 처리로 빈 구역을 만들고 재건설했다. 카드/고스트/설치의 동일 자산·구성과 실제 고스트 픽셀, 드롭의 무변경 상태, 비용 1회, 고유 시설, 중복 확정 거부, Undo와 ESC를 검사했다. 3종 몬스터의 이름 유지와 이름표 쌍별 비겹침을 모든 사례에서 추가 확인했다.

지도 검사는 같은 6개 표시 조건 × 성 4단계 = 24조건이다. 휠/중간 버튼/실제 UI 버튼/키보드 포커스에 입력을 보내고, 확대·이동 후 실제 건설과 기존 Undo까지 실행했다. 기존 343개 검사는 잘못된 위치·UI/지도 밖 드롭·중복 입력·포커스 상실·화면 전환·클릭 대안·키보드·Undo의 안전 계약을 포함한다. 기존 검사의 검증 본문은 유지하고 --evidence-dir=res://tmp/... 인수로 캡처 경로만 분리했다.

초기 지도 검사에는 자동 입력 결함이 있었다. 비동기 Input.parse_input_event와 동기 push_input을 섞은 순서, 잘못된 버튼 마스크, 휠 해제 누락을 수정했다. Godot 4.6.3의 [Viewport 입력 소스](https://github.com/godotengine/godot/blob/4.6.3-stable/scene/main/viewport.cpp)를 확인했으며 누름/해제 쌍을 정상 재현한 최종 네이티브 실행은 모두 통과했다. 초기 임시 headless 추적은 고스트 픽셀 readback이 불가능해 오류가 있었으므로 렌더 검수 결과로 사용하지 않는다.

1차 시설 after 1,623개 PASS 뒤 실제 캡처에서 이름표 겹침을 발견했다. 수정과 비겹침 검사를 추가한 최종 1,887개 결과로 대체했다. 초기 tmp 안전 검사 래퍼는 tools 씬용 저장 격리를 벗어나 수동 DAY 변경 fixture의 자동 저장 검증 경고를 냈다. 제품 코드를 바꾸지 않고 원래 tools 씬으로 실행하며 증거 경로 인수를 추가해 해결했다. 최종 시설/지도/안전/관련 계약 로그에 FAIL·SCRIPT ERROR·ERROR·WARNING이 없다.

변경 전 238장 / 최종 변경 후 238장 / 새 지도 조작 96장 = 572장. 기존 건설 안전 캡처 36장은 safety/에 별도 보존했다. 같은 이름의 전후 장면을 비교 페이지에 연결했으며, 신규 지도 조작을 가짜 변경 전 캡처와 연결하지 않았다. 6개 표시 조건의 대표 드래그/검토/설치, 모인 몬스터 이름, 새 시설과 기존 바닥·앞벽의 결합을 직접 시각 확인했다. 단계 순회 종료 텍스처 메모리 약 607.26 MiB 관측이며 최대 메모리·저사양 성능 판정이 아니다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 8cde57752afeeaa679f927b11de171bef356204c
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..8cde57752afeeaa679f927b11de171bef356204c
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

게임 코드·PNG·검사 본문은 ff886ed57dd18cac5be5e21a3a8a831f7e585811에서 검증한 내용과 동일하다. 초기 정책 검사가 SOURCE.md의 목록 접두사와 v 버전 형식을 지적해 출처 문서 형식만 수정했고, 그 커밋까지 포함해 Reviewed SHA를 갱신했다.

map_readability_audit는 활성 호출·기존 이름표·좌표/입력 위험을 조사한 읽기 전용 보조다. 전체 검수 에이전트를 실행한 것이 아니며 구현 writer는 root 한 명이다. Reviewed SHA 이후에는 docs/handoff 문서만 변경한다.

## 7. 미해결 항목과 위험

- 대표 8종 외 후반 적·동료·진화/왕관·큰 초상과 프레임별 자세/효과의 미술 확장.
- 기존 배경·조명·벽/바닥과 새 그림의 전체 조화. 모든 방향의 주관적 미술 평가와 이동 중 장시간 관찰은 미완료다.
- 몬스터 다수가 같은 위치에 모이면 이름표는 아래로 벌어진다. 매우 많은 후반 동료가 한 방에 모이는 화면의 최종 밀도는 추가 확인 대상이다.
- 이름 입력·일부 기록/회상·상층·전초기지 전투의 정보 구조와 키보드 접근.
- 전체 DAY 1~30·모든 분기·사람 취향/사용성·다른 플랫폼·8인 검수·배포는 미실시다.

## 8. 다음 작업 순서

1. 실제 연결된 후반 캐릭터·진화/왕관·큰 초상 경로를 조사하고 대표 8종과 같은 입체 재질로 확장한다. actors/portraits 연결과 프레임·발 기준점을 실제 게임에서 확인한다.
2. 이름 입력·기록/회상·상층·전초기지 전투의 활성 UI에서 작업 흐름과 키보드 접근을 보완한다.
3. 관련 직접 검사와 대표 화면을 남긴다. 이미 완료한 단계별 시설 11종·성문/왕좌/빈 기반 15종 등은 재생성하지 않는다.

## 9. 작업 트리 상태와 제출

선택 작업트리: tmp/uiux_v2. 구현과 문서는 로컬 커밋했다. 종료 시 선택 작업트리는 clean이며 Reviewed SHA 뒤 변경은 docs/handoff 문서뿐이다. 원격 푸시 없음. 루트의 기존 혼합 작업트리와 과거 브랜치·태그를 보존했다.

전후·조작 증거: tmp/uiux_stage_art_20260913/index.html. 세부 로그·PNG는 같은 작업트리의 tmp 경로에만 존재한다. CURRENT와 잔여 미술 문서를 갱신했다.
