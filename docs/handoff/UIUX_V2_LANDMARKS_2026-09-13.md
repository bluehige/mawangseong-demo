# UIUX V2 성문·왕좌·빈 구역과 지도 접근 개선

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 공개 기준 v1.2.6, 새 제품 버전 미확정
- WORKSTREAM_ID: UIUX-V2-LANDMARKS-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 브랜치 및 SHA: main / origin/main / 원격 main 모두 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD: 42fc299cdf0b152fb6bdbc24e1c0c26b0f6c2587
- 마지막 구현 커밋 SHA: 5f20e889559c5e17392ab962d526590aa8e5abcc
- 원격 푸시 여부: 미푸시, PR·Release·태그·공개 배포 없음
- 권위 확인: 선택 작업트리의 초기 clean 상태·브랜치·HEAD·main·origin/main, main:AGENTS.md/main:docs/handoff/CURRENT.md 및 원격 main 동일 SHA 확인.
- 버전 충돌: AGENTS의 과거 1.2.5 문구보다 최신 사용자 지시와 main:CURRENT의 1.2.6을 기준으로 기록. 과거 v20·출시 태그·루트 혼합 작업트리는 변경하지 않음.

## 2. 이번 세션 목표

사용자의 “더 진행해”에 따라 이전 시설 작업에서 남은 실제 성문·왕좌·빈 건설 구역을 단계/방향에 맞춰 재제작하고 게임에 연결한다. 기존 건설 안전 계약과 클릭 접근을 확인하며, 발견한 후반 슬롯 접근 결함을 수정한다.

지정 참고는 앞선 세션에서 확인한 Curse of the Dead Gods 설정·전리품 화면이다. REFERENCE_VERIFIED (2026-09-12 Chrome). 이번 공통 UI는 앞서 연결한 판석 자산을 재사용했다. 전체 미술·캠페인·8인 검수·공개 배포는 이번 완료 범위가 아니다.

## 3. 완료한 작업

- 성문: 실제 주 입구 SE 단계 1~4와 보조 입구 NE 공통 1장.
- 왕좌: 실제 SW 단계 1~4. 단계 2는 새 그림에 계단 전체가 포함되므로 해당 단계 front 선택만 제거. _complete_override와 stack_layers 및 다른 방향은 유지하여 기존 앞 계단 중복/옛 그림 fallback을 방지.
- 빈 건설 구역: NE 단계 1~4, NW/SE 공통 2장. SE는 기존 병영 철거로 실제 확인.
- 총 15장 네이티브 투명 원본을 기존 방향/투영/바닥 기준점/렌더 경로에 연결. manifest 의미 변화는 이미지 경로 19개와 단계 2 왕좌 front 선택 제거 1개뿐.
- 기존 실제 마우스 검사에서 후반 NW 슬롯이 하단 도구함에 가려지는 결함 재현. 관리 진입/단계 변경 시 전체 방과 지붕·계단 경계를 도구함 위 공간에 맞추고, 공통 판석 “지도 전체” 버튼으로 다시 맞출 수 있게 함.
- 지도 맞춤은 화면 표시만 변경. 배치/드래그 중 맞춤을 차단하고 관리 화면을 떠나면 이전 화면 변환을 복원. 화면→월드 좌표 변환은 기존 함수를 그대로 재사용.
- 고정 방·비용·해금·AI·경로·수용량·성장·보상·스토리·저장 구조 변경 없음. 드롭은 후보 선택, 확정은 기존 실행 경로 1회, Undo 재사용.
- 기존 depth 소스 계약 검사가 Windows CRLF 줄바꿈을 LF 문자열과 직접 비교하여 실패하던 문제를 읽기 정규화로 수정. Unit의 실제 depth 갱신 동작은 변경하지 않음.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/game/BuildingPlacementController.gd | 전체 지도 맞춤·배치 중 이동 차단·이전 뷰 복원 |
| scripts/ui/ManagementWorkspaceUI.gd | 관리 진입 맞춤·키보드 포커스 가능한 지도 전체 버튼 |
| data/dungeon_quarter/asset_manifest.json | 실제 단계/방향 이미지 선택 19개와 중복 front 제거 |
| assets/props/uiux/{entrance,throne,foundation}_*.png 및 .import 중 신규 15쌍 | 네이티브 원본과 밉맵 가져오기 |
| assets/source/imagegen/uiux_landmarks_20260913/ | 원본 15장과 SOURCE.md |
| tools/UIUXLandmarkTest.gd/.gd.uid/.tscn | 단계/해상도/글자별 실제 입력, 그림 연결, 지도 접근, 전후 캡처 |
| tools/tests/V122Stage01SpatialVisualRuntimeTest.gd | 활성 stage01 왕좌 경로 검사 갱신 |
| tools/tests/V122V4ADepthSlotContractTest.gd | Windows 줄바꿈을 정규화하여 기존 동작 계약 비교 |

구현 커밋 54개 파일. tmp 증거는 로컬 전용으로 커밋하지 않음.

## 5. 그래픽 및 오디오 자산

- Generation model: GPT internal image generation
- 실제 프롬프트·원본 경로·최종 출력·SHA-256: [SOURCE.md](../../assets/source/imagegen/uiux_landmarks_20260913/SOURCE.md)
- 15장 모두 실제 RGBA, 모서리 alpha 0, 투명/불투명 픽셀 존재, 고유 해시, 원본=런타임 확인.
- RGB 체크무늬 8개 후보는 실패로 제외하고 동일 내부 이미지 생성기로 투명 출력을 재요청. 모델이 투명 출력을 지원하지 않는다고 일반화하지 않음.
- 로컬 배경 제거·축소 저장·크롭·회전·반전 없음. mipmaps/generate=true, process/size_limit=0. 신규 런타임 PNG 20.83 MiB, 원본 별도 보존.
- 실제 3D 모델이 아닌 입체 음영의 2D 스프라이트. 미술의 최종 취향 및 모든 방향 세부 일관성은 전체 미술 완료 판정과 구분.
- 새 오디오 없음. 기존 효과음과 배치 반응 유지.

## 6. 테스트 및 검수

Windows / Godot 4.6.3.stable.official.7d41c59c4 / Vulkan Forward+ / RTX 3060 Ti. APPDATA는 tmp의 별도 테스트 경로 사용.

| 검사 | 결과 | 근거 |
|---|---|---|
| 변경 전 UIUXLandmarkTest -- before | FAIL 재현: 1,332개 중 후반 NW 입력 36개 실패 | tmp/uiux_landmarks_before2.stdout |
| 변경 후 UIUXLandmarkTest -- after | PASS 2,014개, 관리 표시 24조건 | tmp/uiux_landmarks_after.stdout, tmp/uiux_landmarks_20260913/after/results.json |
| 전투 상세창을 닫은 최종 겹침 검사 -- after combat_only | PASS 274개, 실제 전투 진입 8사례 | tmp/uiux_landmarks_overlap.stdout, after/combat_results.json |
| UIUXBuildPlacementTest | PASS 343개 | tmp/uiux_landmarks_build_safety.stdout |
| V122Stage01SpatialVisualRuntimeTest | PASS | tmp/uiux_landmarks_V122Stage01SpatialVisualRuntimeTest.stdout |
| V122VisualTextureConsistencyTest | PASS | tmp/uiux_landmarks_V122VisualTextureConsistencyTest.stdout |
| V125StageProgressionVisualRuntimeTest | PASS | tmp/uiux_landmarks_V125StageProgressionVisualRuntimeTest.stdout |
| V122V4ADepthSlotContractTest | 초기 CRLF 비교 FAIL → 읽기 정규화 후 PASS | tmp/uiux_landmarks_depth.stdout, tmp/uiux_landmarks_depth2.stdout |
| Godot import 및 밉맵 재import | exit 0, 오류 없음 | tmp/uiux_landmark_import.stdout, tmp/uiux_landmark_import2.stdout |
| 전후 비교 HTML 파일/JS 검사 | 503개 고유 링크 존재, node --check PASS | tmp/uiux_landmarks_20260913/index.html |
| git diff --check | PASS | 구현 커밋 전 실행 |
| ValidateRepositoryPolicy.ps1 -BaseRef main | PASS (329 final files, 16 commits inspected) | tmp/uiux_landmarks_policy.stdout |
| 전체 캠페인·8인·사람 사용성·다른 플랫폼 | NOT_REQUESTED / 미실시 | 전체 PASS로 확대하지 않음 |

두 해상도(1920×1080 / 1280×720) × 세 글자 배율(90/100/115%) × 성 4단계 = 24관리 표시 조건. 실제 빈 구역 NE/NW 36사례에 마우스 클릭·카드 드래그·드롭·하단 확정 입력을 보내고 비용 1회·설치·Undo·ESC를 확인했다. SE 철거와 몬스터/자원 복구 24사례도 확인했다. 고정 입구·보조 입구·왕좌는 건설 대상으로 거부되며 상태가 바뀌지 않는다.

자동 지도 맞춤, 모든 현재 변경 가능 방 중심의 실제 마우스 접근, 버튼 클릭 후 맞춤 복구, 키보드 focus, 드래그 중 이동 차단, 관리 종료 시 이전 뷰 및 게임 상태 보존을 검사했다. 343개 기존 건설 안전 검사는 UI 위/지도 밖/잘못된 드롭, 중복 입력, 포커스 상실, 화면 전환, 클릭 대안/키보드, 카메라 좌표 및 기존 Undo를 포함한다.

전투 8사례는 실제 방어 시작 후 60프레임 실행하여 일시정지했다. 왕좌 겹침은 그 상태에서 몬스터 하나의 표시 위치만 왕좌 중앙으로 옮긴 fixture로, 실제 AI가 그곳까지 이동했다는 증거는 아니다. 최종 캡처는 상세창을 닫아 겹침을 직접 확인했으며 관리 24조건은 앞선 동일 제품 코드/자산 검사 결과를 유지한다.

변경 전 232장 / 변경 후 256장, 합계 488장. 차이 24장은 후반 NW 건설이 변경 전에 막혀 설치/Undo에 도달하지 못했기 때문이다. 서로 대응되는 지도·검토 장면과 변경 후 전투/겹침을 직접 시각 확인했다. 새 그림·기존 앞벽·바닥 기준점과 하단 검토 버튼/문구를 6개 표시 조건 대표 화면에서 확인했다.

단계 순회 종료 시 텍스처 메모리 약 614.59 MiB 관측(겹침 전용 재실행 611.34 MiB). 최대 메모리나 저사양 성능 판정이 아니다. 최종 관련 실행 로그에 ERROR/WARNING/FAIL 없음. 초기 before 실패와 depth 테스트 오탐은 위에 별도 기록했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 5f20e889559c5e17392ab962d526590aa8e5abcc
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..5f20e889559c5e17392ab962d526590aa8e5abcc
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

별도 전체 검수 에이전트는 요청받지 않아 실행하지 않았다. building_visual_audit는 활성 방향·단계와 렌더 선택 경로의 읽기 전용 조사 보조였으며 구현 writer는 root 한 명이다. Reviewed SHA 뒤에는 docs/handoff 문서만 변경한다.

## 7. 미해결 항목과 위험

- 보물고·회복 둥지·감시초소·병영의 남은 단계 전용 원본, 오래된 배경/조명과 새 그림의 조화.
- 대표 8종 외 후반 적·동료·진화/왕관·큰 초상과 프레임별 자세/효과.
- 전체 지도 맞춤은 현재 유효 구역의 접근을 우선한다. 작은 화면에서 지도 이름과 세부 그림의 최종 가독성, 사용자 줌/이동 경험은 추가 개선 대상.
- 이름 입력·일부 기록/회상·상층·전초기지 전투의 정보 구조/키보드 접근.
- 모든 분기·전체 캠페인·다른 플랫폼·사람 취향/사용성은 이번 검사로 확정하지 않는다.

## 8. 다음 작업 순서

1. 남은 단계 전용 시설 그림과 지도 세부 가독성을 이어서 개선.
2. 후반 캐릭터·큰 초상·프레임별 자세를 기존 실제 연결 기준으로 확장.
3. 공통 테마 적용에 머무른 보조 메뉴의 정보 구조와 키보드 접근 보완.

## 9. 작업 트리와 제출

선택 작업트리: tmp/uiux_v2. 구현은 로컬 커밋 완료, 핸드오프/CURRENT/잔여 문서는 별도 문서 커밋으로 기록했다. 종료 시 선택 작업트리는 clean이며 Reviewed SHA 이후 변경은 docs/handoff 3개뿐이다. 무관한 루트 혼합 작업트리와 공개 브랜치/태그는 보존한다. 비교 화면: tmp/uiux_landmarks_20260913/index.html. 원격 푸시 없음.
