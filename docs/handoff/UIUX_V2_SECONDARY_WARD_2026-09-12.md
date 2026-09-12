# UIUX V2 보조 메뉴·수호핵 방향별 미술 핸드오프

## 1. 메타데이터

- 작성일: 2026-09-12
- WORKSTREAM_ID: UIUX-V2-SECONDARY-WARD-20260912
- 목표 버전: 공개 안정판 1.2.6 기준 UIUX V2 개선. 새 제품 버전 미확정.
- 작업 브랜치: codex/v126-uiux-u0-u3
- 작업트리: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2
- 기준 main / origin/main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD / 이전 캡처 기준: faa1e9bd975609fa1c3e3c83fdbeb22421427e22
- 구현 커밋: a22927ddc252a7b3ea9271ed5535e066385b39bd
- 마지막 구현 커밋 / Reviewed SHA: d728f1ff062c59a3d4e3b7ad352cc66d009b16d8
- 원격 푸시 여부: 없음. 로컬 커밋만 생성.
- 관련 PR / 새 태그 / Release: 없음.
- 종료 전 원격 재확인: main 69a7597, v1.2.6 태그 객체 2a66ebf5f4a2f51c4b5913daf8980aecd9dad6f1, 실제 제품 커밋 1f36c8a775b471c4dbc7c7714f85f33efb00876d 유지.
- 권위 main:AGENTS의 유지보수 1.2.5 문구와 main:CURRENT의 공개 1.2.6이 충돌한다. 최신 사용자 V2 지시와 CURRENT/불변 태그의 1.2.6을 비교 근거로 삼았으며 제품 버전·과거 v20 브랜치·출시 태그를 변경하지 않았다.
- 기존 루트 혼합 작업트리는 보존했다. 위 격리 작업트리만 구현 writer 한 명이 수정했다.

## 2. 이번 목표와 완료 범위

사용자의 “다음작업 진행해”에 따라 직전 CURRENT의 수호핵 방향별 6개 자산과 보조 메뉴 재배치를 진행했다. 중간 사용자 수정 지시는 “내부 투명 이미지 생성 규칙 자체를 현재 기능에 맞게 바꾸고 바로 투명으로 생성”이었다. 로컬 배경 제거는 승인된 방법으로 간주하지 않았다.

대표 구현은 게임 안에서 동작한다. 교리·칙령·도전 인장, 계약 후보·출전/예비 편성, 엔딩 도감, 전초기지 건설·관리 8개 화면 상태를 개선했다. 전체 V2 미술·모든 메뉴·전체 캠페인 완주까지 완료했다고 판정하지 않는다.

## 3. 구현 및 실제 호출

- 교리·칙령·인장: 목록 → 실제 효과 상세 → 선택 확정. 초기 첫 상세는 미리보기이며 새 단계의 항목을 직접 선택해야 확정이 활성화된다. ESC는 선택만 지운다. 연속 확인 클릭이 다음 단계를 확정하지 않는다.
- GameRoot의 세 활성 builder → CampaignWorkspaceUI.build_cycle/select/confirm → 기존 _select_cycle_doctrine / _select_cycle_decree / _select_challenge_seal. 비용·즉시 보상·효과·이력 코드는 기존 경로를 사용한다.
- 계약: 5개 후보의 실제 동료 외형·이름·역할·설명 → 후보 토글 → 정확히 2개 확정. 출전 편성은 보유 전체 목록으로 확장하고 실제 즉시 적용 의미를 “편성 완료”로 표시한다. 출전 0명은 확인·ESC 모두 차단한다.
- GameRoot._build_contract_board_ui → CampaignWorkspaceUI → 기존 _toggle_contract_candidate / _confirm_contract_selection / _toggle_contract_deployment / _confirm_contract_roster. 이전 고정 패널 builder 두 개를 제거했다.
- 엔딩: E00~E22 총 23개를 스크롤/Tab으로 접근한다. 발견한 결말은 실제 그림·기록 상세, 미발견은 제목·그림 비공개. 원래 타이틀 복귀 유지.
- 전초기지: 유형 비교 / 선택 상세 / 전체 동료 목록 / 고정 하단 행동으로 분리했다. 기존 7명 절단 때문에 불가능했던 8번째 이후 동료 배치·해제가 가능하다. 유형 클릭은 검토만, 하단 건설에서 기존 OutpostService.build를 한 번 호출한다.
- 수비대 배치 → assignment_changed → GameRoot._set_update4_outpost_assignment → OutpostService.assign_monsters. 3명 정원 유지. 변경한 동료로 포커스·스크롤을 복원한다. DAY 12 강화·최대 Lv.2·원래 자원 차감 없음 계약 유지.
- 전초기지 현재 HP와 지역 보너스를 포함한 강화 예상 HP를 표시한다. 실제 상시 효과·위험·다음 습격·방어 통계·엔딩 지표 설명을 유지한다.
- 후반 동료의 잘못된 대리 초상 연결을 새 메뉴에서 피했다. 전용 기본 초상이 없는 동료는 실제 전투 시트의 첫 idle 프레임을 사용하며, 진화형은 해당 진화 초상을 사용한다. 모리에게 푸딩 초상을 표시하지 않는다.
- 관련 상태 변경 callback은 현재 화면을 확인한다. Tab의 전투 몬스터 선택은 전투 중에만 수행한다. 지연 포커스 요청도 현재 화면의 살아 있는 Control만 대상으로 한다.
- 수호핵: ModuleGraph._object_facing_for_instance → _slots_with_facing → QuarterDungeonRenderer의 단계/방향 키 → FacilityPreview 카드·고스트 및 실제 지도 렌더. ward_core만 NW로 강제하던 예외를 제거했다. 기존 확인·재검증·실행·Undo 경로를 유지한다.
- 스토리/콘텐츠/밸런스/AI/성장/보상/저장 스키마 변경: 없음. UI 전용 선택 ID는 저장 필드로 추가하지 않았다.

## 4. 변경 파일

구현 커밋 a22927d의 41개 파일과 후속 d728f1f의 4개 파일이 이번 실제 변경 범위다. 경로 전체 목록은 `git diff --name-only faa1e9bd975609fa1c3e3c83fdbeb22421427e22..d728f1ff062c59a3d4e3b7ad352cc66d009b16d8`로 재현한다.

| 경로 | 변경 목적 |
|---|---|
| AGENTS.md | 현재 내장 도구의 네이티브 투명도·실제 알파 검증 규칙 |
| scripts/ui/CampaignWorkspaceUI.gd | 회차 선택·계약·엔딩 목록/상세/확정 공통 구현 |
| scenes/ui/screens/OutpostManagementScreen.gd | 전초기지 전체 목록과 검토/실행 분리 |
| scripts/game/GameRoot.gd | 실제 builder 연결, 중복 경로 제거, 화면/키보드 가드 |
| scripts/game/ManagementSceneController.gd | 현재 동료 실제 외형 텍스처 |
| scripts/dungeon_quarter/ModuleGraph.gd | 수호핵 현재 방 방향 사용 |
| data/dungeon_quarter/asset_manifest.json | 단계 3/4 × NE/SE/SW 6장 연결 |
| assets/props/uiux/ward_core_stage03_*.png 및 stage04_*.png | 최종 투명 자산 6장과 import 설정 |
| assets/source/imagegen/uiux_ward_core_directions_20260912/ | 생성 원본 6장 및 SOURCE.md |
| tools/UIUXSecondaryFixture.gd | 기존 데이터로 만든 재현용 준비 상태 |
| tools/UIUXSecondaryInteractionTest.gd/.tscn | 실제 메뉴 입력 및 화면 전환 검사 |
| tools/UIUXSecondaryScreensCapture.gd/.tscn | 8개 화면 × 6개 조건 전후 캡처 |
| tools/UIUXWardDirectionalTest.gd/.tscn | 원본 알파·실제 카드/드래그/설치/취소/Undo |
| tools/Update2CycleChoicesSmokeTest.gd, Update2ContractRosterSmokeTest.gd | 실제 활성 화면에서 기존 callback 검사 |
| tools/Update2EndingCatalogSmokeTest.gd | 새 발견 수 표기 및 지연 UI 해제 후 종료 |
| tools/tests/OutpostPhase7Test.gd | 전체 보유 동료 접근·새 행동 위치 검증 |

새 스크립트 일부의 .gd.uid도 함께 기록했다. 엔진 실행으로 생긴 무관 UID는 제외했다. tmp/ 캡처·로그·엔진·HTML 갤러리는 소스 커밋에 넣지 않았다.

## 5. 그래픽 및 전역 규칙 수정

- Generation model: GPT internal image generation
- 실제 원본/런타임/프롬프트: [SOURCE.md](../../assets/source/imagegen/uiux_ward_core_directions_20260912/SOURCE.md)
- 선택한 6장 모두 실제 RGBA. 바깥 알파 0 및 충분한 불투명 건물 픽셀 검사 통과.
- 생성 원본과 런타임 PNG의 SHA-256 일치. 배경 제거·색상 키·좌우 반전·로컬 회전·크롭·리샘플링 없음.
- 기존 NW 2장은 그대로 유지했다. 새 그림은 기존 자산을 참고한 방향별 그림이며, 3D 모델에서 정확한 기계 회전을 추출한 것으로 표현하지 않는다.
- 체크무늬가 픽셀에 들어간 RGB 후보는 실패 후보로 제외했다. 실패가 모델의 투명 생성 미지원이라는 규칙으로 남지 않게 수정했다. 최종 6장에는 이 문제가 없다.
- 사용자 지시로 다음 전역 파일도 수정했다. 이 파일들은 저장소 Git 커밋에 포함되지 않는다.
  - C:/Users/blueh/.codex/skills/.system/imagegen/SKILL.md
  - C:/Users/blueh/.codex/skills/.system/imagegen/references/prompting.md
  - C:/Users/blueh/.codex/skills/.system/imagegen/references/sample-prompts.md
- 현재 도구 schema에 노출된 prompt/referenced_image_paths를 실제 호출에 사용했다. 존재하지 않는 background 인자를 전달했다고 주장하지 않는다. 투명 제어가 노출될 때 실제 인자로 설정하고, 노출되지 않으면 생성기 prompt에 요구를 전달하며 실제 알파를 검사하도록 규칙을 정리했다.
- 공식 기능 근거: [Images in ChatGPT](https://help.openai.com/en/articles/11084440-chatgpt-image-library). 과거 CLI/모델 제약을 현재 내장 도구 전체에 일반화하지 않는다.
- 전역 스킬 frontmatter의 이름·설명 및 수정 구문을 확인했다. skill-creator 표준 quick_validate는 번들 Python의 PyYAML 부재로 실행하지 못했다. 이를 PASS로 기록하지 않는다.
- 오디오: 기존 UI 버튼/완료 효과음 연결을 사용. 새 음원·사람 청취 평가 없음.

## 6. 실행 검증과 증거

Windows / Godot 4.6.3 / Vulkan Forward+ / RTX 3060 Ti. 실제 Viewport 입력을 보냈으며 단순 함수 호출만으로 UI 조작 PASS를 만들지 않았다. 일부 규칙·저장 호환 검사는 기존 headless 테스트를 병행했다.

| 검사 | 결과 | 로그 |
|---|---|---|
| UIUXSecondaryInteractionTest.tscn | PASS · 3,260개 assertion | tmp/uiux_secondary_interaction.log |
| UIUXWardDirectionalTest.tscn | PASS · 612개 check | tmp/uiux_ward_directional.log |
| UIUXBuildPlacementTest.tscn | PASS · 343개 check | tmp/uiux_build_final.log |
| Update2CycleChoicesSmokeTest.tscn | PASS · 72개 | tmp/uiux_secondary_related_0.stdout |
| Update2ContractRosterSmokeTest.tscn | PASS · 68개 | tmp/uiux_secondary_related_1.stdout |
| Update2EndingCatalogSmokeTest.tscn | PASS · 41개 | tmp/uiux_secondary_related_2.stdout |
| OutpostPhase7Test.tscn | PASS · 23개 | tmp/uiux_secondary_related_3.stdout |
| OutpostTypesPhase9Test.tscn | PASS · 26개 | tmp/uiux_secondary_related_4.stdout |
| UIUXSecondaryScreensCapture.tscn | 실제 전후 48쌍 | tmp/uiux_secondary/before 및 after |
| git diff --check | PASS | 로컬 명령 결과 |

네이티브 직접 검사는 합계 4,215개이며 글자 경계 assertion도 포함한다. 기존 5개 검사는 합계 230개다. 개수를 사람 사용성 검수 인원이나 전체 캠페인 범위로 해석하지 않는다.

- 해상도/글자: 1920×1080, 1280×720 각각 90%, 100%, 115%. 최종 관련 로그에서 SCRIPT ERROR/ERROR 없음.
- 실제 목록 끝 도달, 모리 외형, 후보 취소, 출전 정원/0명 차단, 전초기지 8번째 이후 배치·해제, 빠른 연속 확정, 같은 프레임 화면 전환을 확인했다.
- 수호핵 실제 현재 지도 검사 방향: SE(병영), NW(회복), NE(slot_01). 두 성 단계·6개 표시 조건에서 드래그/검토/설치/ESC/Undo를 수행했다. SW 2장은 리소스·알파 검사 범위이며 이 준비 지도의 SW 직접 설치를 수행했다고 쓰지 않는다.
- 건설 안전 343개에는 UI 위/지도 밖/잘못된 위치/ESC/포커스 상실/화면 전환/줌·이동·창 크기 변경/중복 확정/기존 Undo가 포함된다.
- 초기 실패: 클래스명 Theme 충돌, 테스트 준비의 미완료 지역 선택 및 단계 역행 상태, 오래된 UI 경로 기대값을 수정했다. 빠른 화면 전환의 실제 지연 포커스 오류를 수정하고 재검사했다. 테스트 종료 시 지연 해제 대기 부족도 수정했다. 최종 PASS는 수정 후 로그만 근거로 한다.
- 전체 회귀/전체 DAY 1~30/8인 검수/사람 사용성/Web/모바일/새 export·배포: NOT_REQUESTED / 미실시.
- 별도 검수 에이전트 PASS: 없음. /root/result_flow_audit는 목록 잘림·현재 자산·효과/입력 계약을 읽기 조사했으며 실행 검수·파일 수정은 하지 않았다.

### 로컬 제출물

- 갤러리: tmp/uiux_secondary/index.html
- 증거 목록: tmp/uiux_secondary/manifest.json
- 이전/현재: 같은 8개 상태 × 6조건, 48쌍
- 메뉴 입력: tmp/uiux_secondary/interaction/ · 36장 및 results.json
- 수호핵 입력: tmp/uiux_secondary/ward/ · 최종 통과 실행의 드래그/검토/설치 108장, 고스트 픽셀 비교 및 results.json
- 기존 건설 취소/Undo: tmp/uiux_evidence/06_undo.png, 07_cancel.png 등. 이번 건설 검사에서 갱신한 파일.
- 준비 상태의 엔딩 23종·전체 동료는 실제 기존 데이터로 채운 테스트 fixture다. 사용자가 실제로 모든 엔딩을 발견했다고 주장하지 않는다.
- 실패 실행의 오래된 SW 캡처 파일은 현재 증거 manifest에서 제외했다. 전체 폴더의 모든 파일을 최신 PASS 증거로 취급하지 않는다.

### 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: d728f1ff062c59a3d4e3b7ad352cc66d009b16d8
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..d728f1ff062c59a3d4e3b7ad352cc66d009b16d8
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

검사한 제품 코드·자산 이후에는 docs/handoff 문서만 변경했다. 저장소 정책 검사는 문서 포함 최종 변경 범위에서 별도로 기록한다.

## 7. 미해결 범위와 다음 순서

1. 이름 입력, 기록/회상, 상층 고정 모듈과 전초기지 전투처럼 직전 화면 적용표에서 공통 테마 수준에 머무른 화면의 실제 활성 경로를 확인하고 정보 구조·키보드 접근을 이어서 개선한다. 이번 8개 보조 상태를 모든 화면 재배치 완료로 확대하지 않는다.
2. 일부 동료의 전용 큰 기본 초상은 여전히 없다. 현재는 다른 동료 초상으로 대체하지 않고 실제 전투 외형을 사용한다. 기존 전체 배경·빛·이동 중 자글거림의 최종 미술 판정은 남아 있다.
3. 사용자 지정 참고 URL gameuidatabase.com/gameData.php?id=729는 계속 REFERENCE_UNVERIFIED다. 다른 작품을 원본으로 대체하지 않았다.
4. 사람 사용성·전체 캠페인·플랫폼 확대·새 제품 버전·출시/태그/공개 배포는 별도 범위로 남긴다. 이번 작업만으로 자동 실행하지 않는다.

## 8. 종료 상태

- 구현 소스·자산은 위 두 로컬 커밋으로 보존했다.
- CURRENT와 ART_GAPS를 이번 결과로 갱신했다.
- 원격 푸시/PR/배포 없음.
- 최종 작업트리 상태와 문서 커밋은 종료 명령 결과로 확인한다. 원래 루트의 혼합 변경은 작업 범위 밖으로 유지했다.
