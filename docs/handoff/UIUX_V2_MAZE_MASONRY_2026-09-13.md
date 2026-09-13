# UIUX V2 미궁 석조 벽과 접합부 — 2026-09-13

## 1. 메타데이터

- 작성일: 2026-09-13
- WORKSTREAM_ID: UIUX-V2-MAZE-MASONRY-20260913
- 목표 버전: 공개 안정판 1.2.6 기반의 미출시 UI/UX 개선. 새 제품 버전 확정 없음.
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 main / origin/main / 실제 원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112. 종료 시 git ls-remote로 일치 확인.
- 세션 시작 SHA: 231628159c61479bcc007e058acd590b7b711c47
- 마지막 구현 커밋 SHA: 08b0e875246e4d407379d6a7b09f61b6304ab861
- 원격 푸시 여부: 미푸시, 로컬 커밋만 수행
- PR / 태그 / 배포: 없음. main·기존 출시 태그·과거 v20 브랜치 불변.
- 버전 충돌: 오래된 AGENTS의 1.2.5 문구보다 권위 main:CURRENT의 1.2.6과 최신 사용자 지시를 적용.

## 2. 이번 세션 목표

사용자가 좋아한 방 중심의 미궁 공간은 유지하고, 벽에 미궁의 석조 질감을 더하며 꺾인 면의 빈틈·겹침을 수정한다.
시작 전 제안한 접합부 → 입체 석조 → 방 입구 구별 → 절제된 조명 순서를 사용자가 승인했다.
완료 조건은 실제 게임에 연결된 벽과 동일 장면 전후 캡처, 확대 및 건설·전투 조작 확인이다.
새 이동 경로·밸런스·저장 시스템·전체 DAY 1~30·사람/8인 검수·출시는 이번 범위가 아니다.

## 3. 완료한 작업

- 실제 닫힌 wall_edges를 하나의 두께 있는 높이 구조로 합쳐서 안/바깥 꺾임, T 접합, 벽 끝과 높은 벽/낮은 앞벽 단차를 채웠다.
- 면적 검사에서 발견한 오목한 모서리의 중복 측면은 정렬된 셀 순회와 방문 확인으로 수정했다.
- GPT 석재 재질을 위·옆면에 연결하고 위쪽 모서리 밝기를 통일했다.
- 높은 뒷벽과 낮은 불투명 앞벽을 분리했다. 앞벽은 기존 전면 깊이에서 발 부분을 가린다.
- 아치는 실제 시설 방 입구에만 배치한다. 통과 복도는 열어 두고 선택한 실제 뒷벽에만 따뜻한 횃불을 단다.
- 그래픽 구조는 지도 갱신 때 계산하고 확대·반복 redraw에서는 캐시를 재사용한다.
- 스토리·데이터·밸런스·시설 규칙·적 목표 및 경로·샛문 비용/해금·저장 형식은 변경하지 않았다.
- 새 미궁에만 적용하며 기존 저장 지도는 기존 벽 자산과 반투명 가림을 유지한다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/dungeon_quarter/PreparedMazeMasonry.gd (+uid) | 공유 모서리·단차·측면·상단 생성과 캐시 |
| scripts/dungeon_quarter/QuarterDungeonRenderer.gd | 새 미궁 렌더 연결, 방 입구 아치, 횃불, 실제 깊이 계약 |
| assets/dungeon_quarter/prepared_maze/{masonry_material,warm_sconce}.png (+import) | 실제 런타임 석재·횃불, 밉맵 |
| assets/source/imagegen/prepared_maze_masonry_20260913/* | 두 원본·프롬프트·출처 |
| tools/UIUXMasonryTest.gd (+uid/tscn) | 모서리 회귀, 실제 미궁 화면·확대·캐시 직접 검증 |
| tools/tests/V122FrontWallActorVisibilityTest.gd | 기존 지도 분기 검사 및 Windows 줄바꿈 정규화 |
| tools/tests/V122V4ADepthSlotContractTest.gd | 기존 지도 깊이 계약의 분기 확인 |
| docs/design/UIUX_MAZE_MASONRY_2026-09-13.md | 승인 범위·구현 방식·검증 범위 |

제품 및 검사 변경은 위 구현 SHA의 16개 경로다. 이후에는 이 문서와 CURRENT만 변경한다.

## 5. 그래픽 및 오디오

- Generation model: GPT internal image generation
- 생성 2회. 다른 이미지 생성 서비스 및 로컬 배경 제거 사용 없음.
- 출처: assets/source/imagegen/prepared_maze_masonry_20260913/SOURCE.md
- 석재: 1254×1254 RGB. SHA256 948230fa23804a96331e4aea9c263224a1074d576ff44aa6e8cba7723ee30108
- 횃불: 1536×1024 RGBA. 실제 alpha 0..254. SHA256 bb47e9650e767046c1666a057a05ea9bbcdda9226d2e25cf6a9c2e5053b8d4ff
- 두 런타임 PNG와 원본은 각각 바이트 동일. 크롭·리사이즈·알파 제거 등 로컬 픽셀 편집 없음.
- Godot 밉맵 및 게임 내부 크기 변환 사용. 관리·전투 실제 렌더 확인.
- 오디오 변경 없음.

## 6. 테스트 및 검수

Godot 4.6.3 stable / Windows / NVIDIA GeForce RTX 3060 Ti. 네이티브 테스트 창은 순차 실행했고 세이브는 테스트별 임시 APPDATA를 사용했다.

| 검사 | 실제 결과 | 근거 |
|---|---|---|
| UIUXMasonryTest.tscn | PASS, 26,643 assertions, 고유 캡처 100장 | tmp/uiux_masonry_matrix_final.log, tmp/uiux_masonry_20260913/after/results.json |
| 기존 UIUXBuildPlacementTest.tscn | PASS, 344 checks, 캡처 36장 | tmp/uiux_masonry_build.log, tmp/uiux_masonry_20260913/build/ |
| 기존 UIUXCombatInteractionTest.tscn | PASS, 210 assertions, 캡처 24장 | tmp/uiux_masonry_combat.log, tmp/uiux_masonry_20260913/combat/results.json |
| V122CorridorWallTopologyTest.tscn | PASS, 기존 지도 직접 검사 | tmp/uiux_masonry_legacy.log |
| V122FrontWallActorVisibilityTest.gd | PASS, 33 assertions, 소스 계약 검사 | tmp/uiux_masonry_legacy_visibility_final.log |
| V122V4ADepthSlotContractTest.gd | PASS, 소스 계약 검사 | tmp/uiux_masonry_legacy_depth.log |
| PNG 실제 크기·알파·원본 동일성 | PASS, 위 수치 확인 | 런타임/원본 직접 PIL·SHA256 읽기 |
| git diff --cached --check | PASS | 구현 커밋 직전 확인 |
| 저장소 정책 | 아래 최종 정책 기록 참조 | tmp/uiux_masonry_policy.log |
| 전체 캠페인·사람 검수·다른 플랫폼 | NOT_REQUESTED / NOT_RUN | 결과를 PASS로 확대하지 않음 |

- 10개 구성: 직선/끝, 높은 안·바깥 L, 낮은 L, T, 사거리, 양방향 높이 전환, 음수 좌표, 열린 문.
- 각 공유 윗면 셀은 정확히 한 면에 덮이고, 보이는 측면의 면적이 실제 노출 면적과 일치한다. 열린 문 중심·기존 통행 셀 중심은 비운다.
- 4개 성장 단계 × 1920×1080/1280×720 × 글자 90/100/115%의 관리·실제 예상 경로를 캡처했다. 성/최종 단계 확대 2장 포함.
- 기존 미궁 테스트의 저장 왕복·샛문 복구/Undo·수비대 배치·실제 전투 생성 확인도 함께 수행했다.
- 건물 드래그·유효/불가 고스트·위치 검토·확정/취소·기존 Undo·키보드·UI 위 드롭·줌/이동·후반 슬롯 검사를 기존 테스트로 실행했다.
- 전투 명령·시설 가동·일시정지·결과의 기존 직접 조작도 통과했다.
- 대표 시각 확인: 1920 성/최종 단계, 확대, 1280×720 글자115%, 실제 전투. 새 벽과 캐릭터/시설이 함께 보이는지 확인했다.
- 초기 실패: 테스트 클래스명 Projection의 Godot 내장명 충돌; 안쪽 모서리 측면 중복; 카메라 뒤쪽 단차까지 렌더를 요구하던 검사 오해; 기존 소스 검사에서 CRLF 줄바꿈 오탐. 각각 수정하고 해당 최종 로그에서 통과했다.
- 최종 검사 이후 실행 동작 변경 없음. 파일 끝 빈 줄만 정리했다.
- 검수 에이전트: 사용자 지시에 따라 사용하지 않음.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 08b0e875246e4d407379d6a7b09f61b6304ab861
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..08b0e875246e4d407379d6a7b09f61b6304ab861
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 석재 문양은 성장 단계 공통이다. 기존 절벽 배경·바닥·시설 자산을 이번에 재제작하지 않았다.
- 전체 캠페인 난도, 사람의 취향/사용성, Web·모바일 렌더와 장시간 성능은 미검증이다.
- 이번 요구 범위의 직접 검사에서 남은 실패 없음. 새 미궁 시각 확인에는 새 게임 또는 해당 미궁 저장을 사용한다.

## 8. 다음 작업 순서

1. tmp/uiux_masonry_20260913/index.html의 동일 장면 전후 6쌍과 확대 화면을 사용자에게 제출한다.
2. 추가 미술 피드백이 있으면 현재 장면과 실제 배율을 기준으로 범위를 정해 보완한다.
3. 제품 통합·빌드 게시·새 버전·출시는 해당 명시적 요청이 있을 때 진행한다.

## 9. 작업 트리 상태

- 시작 시 2316281 기준 깨끗한 작업트리. 기존 변경을 되돌리지 않음.
- 구현 08b0e87 로컬 커밋, 이 핸드오프 및 CURRENT는 별도 문서 커밋으로 기록.
- 캡처·로그는 tmp/에만 저장하며 소스 커밋에 포함하지 않음.
- 원격 푸시·PR·태그·배포 없음. 과거 브랜치와 출시본 불변.

## 10. 종료 체크리스트

- [x] 승인한 벽·접합·문·조명 범위 구현
- [x] 관련 직접 검사 및 대표 시각 확인
- [x] 생성 원본·프롬프트·실제 알파·런타임 기록
- [x] 검수 대상 SHA와 NOT_REQUESTED 범위 기록
- [x] CURRENT 갱신 및 의도한 파일만 커밋
- [x] 미수행 플랫폼·전체 캠페인·사람 검수 명시

## 최종 정책 기록

- REPOSITORY_POLICY: PASS (667 final files, 42 commits inspected).
- 검사 HEAD: c3c2a720d3d4091f0baf8d8bd77fd3f4729352ea. 기준 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112.
- 근거: tmp/uiux_masonry_policy.log. 이후 이 정책 결과와 CURRENT 기록만 추가했다.
- 종료 시 작업트리 깨끗함. 구현·문서 모두 로컬 커밋, 원격 푸시 없음.
