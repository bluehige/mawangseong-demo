# 캐릭터와 미궁 벽의 앞뒤 가림

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 기존 1.2.6 작업선. 새 제품 버전·출시 확정 없음.
- WORKSTREAM_ID: UIUX-V2-ACTOR-WALL-DEPTH-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 브랜치 및 SHA: main / 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 착수 HEAD: 976aeb07bbd72903ec46c570a79ea63afb632177 (clean)
- 마지막 구현 커밋 SHA: 96466221d09f7427dd523b6f6dc5cb9d058b9442
- 원격 푸시 여부: 없음. main/origin/main/실제 원격 main은 착수 시 위 SHA로 일치.
- 관련 PR 또는 태그: 생성·이동·배포 없음. 과거 v20 참고선과 출시 태그 유지.
- 권위: main:AGENTS.md와 main:docs/handoff/CURRENT.md. 최신 CURRENT의 1.2.6을 적용하며 과거 1.2.5 문구로 제품 버전을 변경하지 않음.

## 2. 이번 세션 목표

- 요청 사항: 승인한 빛 받는 돌바닥을 유지하고, 캐릭터가 앞벽에는 가려지고 뒤벽은 가리도록 실제 게임에 적용.
- 완료 조건: 배치된 몬스터·전투 아군·적의 몸체가 발 위치와 벽 표면 깊이를 따르고, 카메라 및 UI 배율에서도 가림이 일치. 기존 조작과 저장 규칙 유지.
- 제외: 새 그래픽, 미궁 재설계, 게임 규칙 변경, 전체 캠페인·사람·서브에이전트 검수, 공개 배포.

## 3. 완료한 작업

- 기존 벽은 N/W 높은 벽을 뒤쪽, E/S 낮은 벽을 앞쪽에 고정 배치했고 관리 화면 몸체는 모든 벽 위에 그렸다. 이를 준비된 미궁의 실제 벽 표면 깊이와 캐릭터 발 위치를 비교하는 방식으로 변경했다.
- `PreparedMazeMasonry`의 이미 가림 처리된 면들을 기술용 깊이 버퍼로 한 번 그린다. 16비트 깊이를 RG 두 채널에 저장하며 카메라 이동 때 다시 만들지 않는다. 가장 긴 변은 최대 4096픽셀, 기본 월드 1픽셀당 2샘플이다. 게임 그림을 새로 생성하거나 편집한 파일이 아니다.
- 몸체 셰이더는 월드 좌표의 벽 깊이가 발보다 앞일 때 해당 픽셀을 제외한다. AtlasTexture 프레임, 기존 알파·크로마키, 몸체 색/포즈를 유지한다. 좌표 변환과 COLOR 처리 근거: [Godot 4.6 CanvasItem 셰이더 문서](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/canvas_item_shader.html).
- 전투 Unit과 배치된 몬스터에 같은 버퍼를 적용한다. 물리적 바닥 그림자·선택 링도 마스킹하며 이름·체력·상태 안내는 읽을 수 있게 둔다. 조작 중인 카드·몬스터 드래그는 기존 안내 층에 유지한다.
- 기존 벽/바닥/시설 그리기 코드는 유지하고, 준비된 미궁의 액터 합성 슬롯을 51~94로 배치했다. 월드 안내는 110, 전면 전투 효과 기준은 108로 분리하여 공중 효과가 몸체 아래로 떨어지지 않게 했다. 기존 지도는 1~44 및 기존 전면 벽 방식을 유지한다.
- 스토리·데이터·밸런스·AI·경로·저장 스키마·비용·해금·건설 실행·Undo 변경 없음.
- 테스트의 경로 선택 팝업 입력은 실제 임베디드 팝업으로 전달되는 루트 Viewport 입력으로 정정했다. 초기 선택에서 Down→Enter를 누르고 실제 포커스 및 경로 변경을 검사한다. PopupMenu 입력 경로 근거: [Godot 4.6 구현](https://github.com/godotengine/godot/blob/4.6/scene/gui/popup_menu.cpp). 게임 메뉴 로직 변경은 없다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| scripts/dungeon_quarter/PreparedMazeActorDepth.gd, prepared_maze_depth_write.gdshader | 벽 표면 깊이 캐시·인코딩 | 완료 |
| scripts/dungeon_quarter/prepared_maze_actor_depth.gdshader | 발 위치에 따른 몸체 픽셀 가림 | 완료 |
| scripts/dungeon_quarter/PreparedMazeRosterActor.gd, scripts/map/DungeonRenderer.gd | 배치 몸체·그림자·선택 링 연결 | 완료 |
| scripts/dungeon_quarter/QuarterDungeonRenderer.gd | 레이아웃별 깊이 계약과 버퍼 연결 | 완료 |
| scripts/units/Unit.gd, UnitGroundVisual.gd | 전투 몸체·그림자·선택 및 생성 직후/이동 갱신 | 완료 |
| scripts/game/GameRoot.gd | 화면 전환·드래그 시 배치 몸체 표시 동기화 | 완료 |
| scripts/game/CombatSceneController.gd | 공중/전면 효과 깊이 경계 연동 | 완료 |
| tools/UIUXActorWallDepthTest.gd, .tscn | 실제 픽셀·해상도·배율·이동 검사 | 완료 |
| tools/UIUXMasonryTest.gd, UIUXPreparedMazeTest.gd | 변경된 가림 계약·실제 팝업 입력 검사 | 완료 |
| tools/tests/V122CombatVfxDepthLiveContractTest.gd, V122V4ADepthSlotContractTest.gd | 새 미궁/기존 지도 깊이 계약 검사 갱신 | 완료 |
| 위 신규 스크립트·셰이더의 .uid | Godot 리소스 식별자 | 완료 |
| docs/handoff/CURRENT.md, 본 문서 | 검증·범위·다음 진입점 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 작업에는 신규 그림이 없어 사용하지 않음.
- 생성 모델/원본/후처리: 신규 해당 없음. 래스터 편집·리사이즈 없음.
- 승인한 런타임 바닥: assets/dungeon_quarter/prepared_maze/torchlit_flagstone.png
- 바닥 SHA256 유지: 8f50dfb9f466bd0aeb054e249efbde915b28da966f350f99069b9302eb847d7c
- 기존 출처: assets/source/imagegen/prepared_maze_flagstone_20260913/SOURCE.md
- 검은 벽 재질·면 구성, 바닥 명암·횃불 반사색·시설 받침대·오디오 자산 변경 없음.
- 실제 게임 연결: 관리 화면 배치 몸체, 아군/적 전투 몸체와 기존 Unit 물리 이동으로 확인.

## 6. 테스트 및 검수

Windows, Godot 4.6.3, NVIDIA RTX 3060 Ti / Vulkan Forward+. 각 실행은 별도의 임시 APPDATA를 사용했다.

| 검사 | 결과 | 근거 |
|---|---|---|
| 에디터 headless import | PASS, 파싱·리소스 오류 없음 | tmp/uiux_actor_depth_final_import.log |
| UIUXActorWallDepthTest | PASS, 850 assertions / 30 캡처 | tmp/uiux_actor_depth_verified.log, tmp/uiux_actor_depth_20260913/after/depth_results.json |
| UIUXMasonryTest | PASS, 30,178 assertions / 100 캡처 | tmp/uiux_actor_depth_matrix3.log, tmp/uiux_actor_depth_20260913/matrix/results.json |
| UIUXBuildPlacementTest | PASS, 344 checks / 36 캡처 | tmp/uiux_actor_depth_build.log, tmp/uiux_actor_depth_20260913/build/ |
| UIUXCombatInteractionTest | PASS, 210 assertions / 24 캡처 | tmp/uiux_actor_depth_combat.log, tmp/uiux_actor_depth_20260913/combat/results.json |
| V122CombatVfxDepthLiveContractTest | PASS, 30 assertions | tmp/uiux_actor_depth_vfx.log |
| V122V4ADepthSlotContractTest | PASS | tmp/uiux_actor_depth_contract.log |
| git diff --check | PASS | 로컬 실행 |
| 저장소 정책 | PASS, 694 final files / 57 commits, 437ea5a6c5c0425ab9a6a086625dffc2425a4d06 기준 | tmp/uiux_actor_depth_policy.log |
| 전체 회귀·DAY 1~30·사람 사용성·검수 에이전트 | NOT_REQUESTED / 미실행 | 현재 요청 범위 밖 |

- 1920×1080 / 1280×720, 글자90/100/115%에서 확인. 실제 지도 확대 버튼, 고정 확대/이동 카메라, 성장 4단계, 기존/새 지도 저장 왕복, 건설/드롭/검토/확정/취소/Undo, 몬스터 배치·전투 진입·명령 입력을 포함한다.
- 벽 깊이 2,695개 샘플의 최대 인코딩 오차는 월드 0.00548픽셀 미만이었다. 실제 몸체 비교에서는 앞벽 뒤 픽셀 10,445/10,445개가 제외됐고, 열린 공간/뒤벽 앞 픽셀 29,936/30,010개가 유지됐다. 경계 1.2월드픽셀과 움직이는 배경을 제외하고 사례별 97% 이상을 통과 기준으로 사용했다. 모든 화면 픽셀이 완전히 동일하다고 주장하지 않는다.
- 기존 Unit 물리 이동으로 시작 (942.9759, 607.5839) → 종료 (926.9011, 658.5786), 남은 경유점 0. 이동 중 몸체 발 깊이가 실제 위치로 갱신됨을 검사했다. 직접 위치 설정을 이용한 앞뒤 비교와 실제 물리 이동 검사를 구분한다.
- 초기 픽셀 검사는 축소된 네이티브 창의 화면 배율을 누락해 실패했다. 검증 좌표에 Viewport stretch 변환을 포함하고 실제 해상도를 고정해 재검증했다. 초기 미궁 검사 2회는 팝업 자동 키 입력 전달에서 실패했으며, 실제 루트 입력 경로로 수정 후 최종 전항목 PASS. 초기 실패 로그를 삭제하거나 PASS로 바꾸지 않았다.
- 최종 로그의 SCRIPT ERROR / ERROR / ASSERT_FAIL도 별도로 확인해 없음을 검사했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 96466221d09f7427dd523b6f6dc5cb9d058b9442
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..96466221d09f7427dd523b6f6dc5cb9d058b9442
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

Reviewed SHA 이후에는 docs/handoff 문서만 변경한다.

## 7. 미해결 항목과 위험

- 벽 표면을 대상으로 한 가림 처리다. 시설과 문 아치 스프라이트의 알파 형태는 이 깊이 버퍼에 포함하지 않았다. 준비된 미궁의 액터 합성 층 변경으로 해당 소품과의 기존 단순 z 순서가 달라질 수 있으며, 시설/아치의 정밀 앞뒤 표현은 별도 후속 범위다.
- 새 미술 대체물이나 미완료 생성 자산 없음. 승인한 바닥·벽은 유지했다.
- Web·모바일·다른 GPU·장시간 성능·전체 캠페인·사람 사용성은 미검증. Windows 결과를 이 범위로 확대하지 않는다.
- 이번 결과는 로컬 작업본이다. 공개 안정판이나 사용자 배포 빌드를 갱신하지 않았다.

## 8. 다음 작업 순서

1. tmp/uiux_actor_depth_20260913/index.html에서 벽 앞뒤, 실제 이동, 관리 화면 전후를 확인한다.
2. 후속 피드백은 실제 위치·겹친 대상을 기준으로 대응한다. 시설/아치의 정밀 가림을 확장한다면 기존 Sprite 연결과 해당 면의 깊이를 별도 검토한다.
3. 제품 통합·테스트 빌드·공개 배포·새 버전·태그는 해당 요청이 있을 때 진행한다. 서브에이전트·전체 캠페인·8인 검수를 자동 실행하지 않는다.

## 9. 작업 트리 상태

- 구현 96466221d09f7427dd523b6f6dc5cb9d058b9442 로컬 커밋 완료. 기존 혼합 변경 없음.
- 종료 문서는 본 문서와 CURRENT만 수정 후 별도 커밋한다. 정책 결과 기록도 docs/handoff에만 추가한다.
- 원격 푸시·스태시·브랜치 전환 없음.
- 캡처/결과/갤러리: tmp/uiux_actor_depth_20260913/ (비추적).
- 전체 증거 목록: tmp/uiux_actor_depth_20260913/verification.json.

## 10. 종료 체크리스트

- [x] 사용자 요청의 벽 가림을 실제 게임에 연결
- [x] 승인한 바닥·벽 자산 보존
- [x] 관련 직접 검사·해상도·글자 배율 확인
- [x] 실제 실행한 검증과 미검증 범위 구분
- [x] 구현 Reviewed SHA 및 로컬 커밋 기록
- [x] 그래픽 생성·편집 없음 및 기존 출처 기록
- [x] CURRENT 갱신
- [x] 요청하지 않은 배포·태그·서브에이전트 실행 없음

정책 검증 뒤에는 본 문서와 CURRENT에 결과만 추가했다. 구현 Reviewed SHA 이후 제품 코드·데이터·자산 변경 없음. 최종 작업 트리는 clean, 원격 푸시 없음.
