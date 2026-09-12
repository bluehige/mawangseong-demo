# UIUX V2 시설 3종·지도 건설 표식 개선

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 공개 기준 v1.2.6, 새 제품 버전 미확정
- WORKSTREAM_ID: UIUX-V2-FACILITIES-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 브랜치 및 SHA: main / origin/main / 원격 main 모두 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD: bab1a3be93ec3e2260622e824895f3e7ea646df5
- 마지막 구현 커밋 SHA: 9a46ad8d01722cca6f58da648abbe81c1456b223
- 원격 푸시 여부: 미푸시. PR·태그·Release·공개 배포 없음.
- 권위 확인: 선택 작업트리 상태·브랜치·HEAD·main·origin/main 및 main:AGENTS.md/main:docs/handoff/CURRENT.md 확인. 초기 제한 네트워크 조회 실패 뒤 읽기 전용 git ls-remote로 원격 main 동일 SHA 확인.
- 버전 충돌: AGENTS의 과거 1.2.5 문구보다 최신 사용자 지시와 main:CURRENT의 공개 1.2.6을 기준으로 기록. 과거 v20·출시 태그·루트 혼합 작업트리는 변경하지 않았다.

## 2. 이번 세션 목표

사용자의 “개선 작업 계속 진행해”에 따라 지정 참고 기반 공통 UI를 지도 위 표식까지 연결하고, 작은 원본에서 거칠게 보이던 보물 보관실·회복 둥지·감시 초소 3종을 네 방향으로 재제작한다. 실제 카드·고스트·설치·취소·Undo를 검사한다.

지정 참고는 앞선 세션에서 확인한 Curse of the Dead Gods의 설정·전리품 화면이다. REFERENCE_VERIFIED (2026-09-12 Chrome). 다른 게임을 같은 원본으로 취급하지 않았다. 이번에는 기존 공통 판석 자산을 재사용했다.

전체 캠페인, 사람 사용성 시험, 8인 검수, 새 버전·출시, 남은 모든 미술 완성을 이번 결과로 주장하지 않는다.

## 3. 완료한 작업

- 세 시설 × NW/NE/SE/SW = 네이티브 RGBA PNG 12장. 기존 방향·보라색/금속/돌 재질을 유지하면서 큰 형태와 부드러운 입체 음영으로 재제작.
- 원본과 런타임을 바이트 동일하게 보존. 보물고/회복 둥지 1448×1086, 감시초소 1145×1374. 로컬 배경 제거·축소 저장·반전·회전·크롭 없음.
- 기본 방향 선택 12경로와 성 2단계 NW 보물고/회복 둥지 2경로를 교체. manifest의 실제 차이는 이미지 경로 14개뿐이다.
- 성 1·3·4 NW 전용 그림, 기존 병영과 수호핵 자산은 보존.
- 지도 위 선택 방 이름, 유효 건설 구역, 검토 안내, 지도 밖 오류 표식의 네모 배경을 기존 공통 판석/각진 윤곽으로 변경. 유효·불가·선택 색 구분과 글자·위치·입력 영역 보존. 스타일을 색별로 캐시하여 매 프레임 새 리소스를 만들지 않는다.
- 드롭은 후보 선택, 현장 검토 후 확정 시 기존 실행 경로 1회 반영. 고유 시설 이동과 기존 Undo가 자원·시설·몬스터·연결 경로·튜토리얼 상태를 복구하는지 직접 확인.
- 스토리·AI·비용·해금·수용량·성장·저장 구조 변경 없음.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/game/GameRoot.gd | 실제 지도 건설 표식 연결 |
| scripts/ui/UIUXTheme.gd | 공통 지도 표식 캐시 |
| scripts/ui/ObsidianStyleBox.gd | 작은 표식의 의미 색 윤곽 |
| data/dungeon_quarter/asset_manifest.json | 시설 방향/단계 이미지 경로 14개 |
| assets/props/uiux/{treasure,recovery,watch_post}_{NW,NE,SE,SW}.png 및 .import | 실제 게임 자산 12장과 밉맵 설정 |
| assets/source/imagegen/uiux_facilities_20260913/ | 생성 원본 12장과 SOURCE.md |
| tools/UIUXFacilityArtTest.gd/.gd.uid/.tscn | 실제 배치 54사례와 전후 캡처 직접 검사 |

구현 커밋은 명시한 44개 파일만 포함한다. tmp 산출물은 커밋하지 않았다.

## 5. 그래픽 및 오디오 자산

- 생성 모델: GPT internal image generation
- 출처·실제 프롬프트·출력 경로·SHA-256: [SOURCE.md](../../assets/source/imagegen/uiux_facilities_20260913/SOURCE.md)
- 런타임 최종 PNG 총량: 17.39 MiB (생성 원본 별도 보존).
- 도구가 노출하는 prompt에 네이티브 투명 출력을 요청했다. 존재하지 않는 background 인자를 전달했다고 기록하지 않는다.
- 실제 RGBA, 바깥 네 모서리 alpha 0, 투명 영역 43.9~60.3%, 건물 픽셀 존재, 12장 고유 해시, 원본=런타임 바이트 확인.
- RGB 체크무늬 후보는 실패로 제외하고 내부 도구로 다시 생성했다. 일부 이미지 참조 읽기 helper_unknown_error 이후 요청을 순차 재실행했다. 로컬 투명화나 외부 API를 쓰지 않았다.
- mipmaps/generate=true, process/size_limit=0. 기존 렌더러의 원본 비율과 바닥 기준점 선택을 그대로 사용한다.
- 실제 지도 크기에서 카드·고스트·설치의 형태와 바닥 위치, 검토 바의 큰 그림, 앞벽보다 앞에 표시되는 고스트를 확인했다.
- 새 음원 없음. 3D처럼 보이는 2D 그림이며 실제 3D 모델/회전 애니메이션은 아니다. 방향별 소품 세부 일관성과 최종 취향 평가는 남는다.

## 6. 테스트 및 검수

Windows / Godot 4.6.3.stable.official.7d41c59c4 / Vulkan Forward+ / RTX 3060 Ti. APPDATA를 tmp의 별도 테스트 경로로 지정하여 사용자 저장과 분리했다.

| 검사 | 결과 | 근거 |
|---|---|---|
| 변경 전 실제 시설 경로/입력 캡처 | PASS 1,281개, 배치 54사례 | tmp/uiux_facilities_before2.stdout |
| 변경 후 UIUXFacilityArtTest.tscn -- after | PASS 1,365개, 배치 54사례 | tmp/uiux_facilities_after.stdout, after/results.json |
| 지도 표식 변경 후 UIUXBuildPlacementTest.tscn | PASS 343개 | tmp/uiux_facilities_badges.stdout |
| V122VisualTextureConsistencyTest.tscn | PASS | tmp/uiux_facilities_texture_contract.stdout |
| V125StageProgressionVisualRuntimeTest.tscn | PASS | tmp/uiux_facilities_stage_contract.stdout |
| 최종 Godot import | exit 0, 오류 없음 | tmp/uiux_facilities_import3.stdout |
| manifest 의미 차이 | 이미지 경로 14개만 변경 | git diff 및 JSON 구조 대조 |
| 비교 화면 스크립트·파일 경로 | PASS 369개 고유 이미지 링크 | tmp/uiux_facilities_20260913/index.html |
| 전체 DAY 1~30·8인·사람 사용성·다른 플랫폼 | NOT_REQUESTED / 미실시 | 전체 PASS로 확대하지 않음 |

54사례는 두 해상도(1920×1080 / 1280×720) × 세 글자 배율(90/100/115%) × 세 시설 × 실제 NW/NE/SE 슬롯이다. 카드에 눌림·이동·놓기 입력을 보내고 현장 확정 버튼을 실제 클릭했다. 드래그/드롭 무변경, 고스트 실제 픽셀, 동일 구성·텍스처, 비용 1회, 중복 확정 차단, 고유 시설 1개, Undo 원상복구, ESC 무료 취소를 검사했다.

343개 기존 건설 검사는 잘못된 드롭, UI 위, 화면 밖, 포커스 상실, 화면 전환, 중복 입력, 클릭 대안·키보드, 카메라 및 후반 슬롯 등 기존 안전 계약을 포함한다. 이 검사는 표식 코드를 변경한 뒤 실행했으며 세 시설 그림 교체 후에는 위 54사례 검사를 실행했다.

현재 기본 지도에는 SW 변경 가능 슬롯이 없다. SW 3장은 리소스/알파/해시와 방향 등록 검사만 수행했으며 실제 SW 맵 설치 PASS가 아니다. 성 1·3·4는 해당 단계/방향 선택 경로와 대표 실제 화면을 확인했다.

전후 캡처 각 189장, 합계 378장. 6개 표시 조건의 대표 화면을 직접 시각 확인했다. 자동 조작 fixture이며 사람 사용성 시험은 아니다. 텍스처 메모리는 단계 순회 종료 시 약 531.43 MiB를 관측했으며 최대치/저사양 성능 판정이 아니다. 최종 관련 로그에 ERROR/WARNING/FAIL 없음. 초기 테스트의 타입 추론 구문 오류는 명시적 타입으로 수정한 뒤 before/after 모두 다시 실행했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 9a46ad8d01722cca6f58da648abbe81c1456b223
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..9a46ad8d01722cca6f58da648abbe81c1456b223
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

별도 전체 검수 에이전트는 요청받지 않아 실행하지 않았다. building_visual_audit는 활성 자산·방향 경로의 읽기 전용 조사 보조였다. 이 SHA 뒤에는 docs/handoff 문서만 변경한다.

## 7. 미해결 항목과 위험

- 입구·왕좌·빈 기반 등 나머지 시설과 단계 전용 원본, 새 자산과 오래된 배경의 재질 통일.
- 후반 적·동료·진화/왕관·큰 초상, 프레임별 자세와 효과. 대표 8종은 앞선 세션 완료 상태를 유지했다.
- 이름 입력·일부 기록/회상·상층·전초기지 전투의 정보 구조/키보드 접근.
- 실제 3D 회전 생성물이 아니므로 방향별 세부 소품은 완전히 동일하지 않다.
- 메모리/패키지 용량 증가와 저사양/다른 플랫폼 성능은 별도 관측 필요. 이번 결과를 전체 미술 완료로 기록하지 않는다.

## 8. 다음 작업 순서

1. assets/props 및 manifest의 남은 활성 입구·왕좌·빈 기반/성 단계 원본부터 조사하여 같은 장면 전후와 실제 크기 기준으로 개선한다. 완료한 병영·수호핵·이번 시설 12장은 다시 생성하지 않는다.
2. 후반 캐릭터/적 및 큰 초상을 기존 정체성과 진화 차이를 보존해 확장한다.
3. 남은 보조 메뉴는 실제 활성 호출과 키보드 입력을 확인한 뒤 구조를 개선하고 관련 검사만 수행한다. 새 버전·공개 배포·전체 캠페인은 자동 실행하지 않는다.

## 9. 작업 트리 상태

- 선택 worktree: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2
- 구현 커밋 이후 남은 의도한 수정은 이 핸드오프·CURRENT·ART_GAPS 문서다. 문서 커밋 후 clean 상태를 확인한다.
- 기존 루트 혼합 작업트리, v20 실험 브랜치, 출시 태그는 보존.
- 빌드/로그/캡처/대화형 비교: tmp/uiux_facilities_20260913/ 및 tmp/uiux_facilities_*.stdout/.log
- [로컬 전후 비교](../../tmp/uiux_facilities_20260913/index.html) — 소스 커밋에 캡처/빌드 미포함.
- 원격 푸시·PR·출시 없음.

## 10. 종료 체크리스트

- [x] 요청과 실제 변경 대조, 관련 직접 검사, 6개 표시 조건 시각 확인
- [x] 검수 대상 SHA 및 미실시 범위 기록
- [x] 생성 출처·실제 알파·게임 연결 기록
- [x] CURRENT와 잔여 미술 목록 갱신
- [x] 의도한 구현 44개 파일만 로컬 커밋
- [x] 공개 버전·원격·태그 불변
