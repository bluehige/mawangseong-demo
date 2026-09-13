# UIUX V2 — 실제 전경 벽으로 가림 수정

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 1.2.6 유지
- WORKSTREAM_ID: UIUX-V2-REAL-FOREGROUND-WALL-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 main/origin/main/실제 원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 세션 시작 SHA: 835948416fe95ddc2eae8c8cb003faf55500f492 (깨끗함)
- 마지막 구현 커밋 SHA: c2afafdbbf259507f2ec0e9ff22b7d585202e771
- main:AGENTS / main:CURRENT 기준과 실제 원격 main 일치를 재확인했다. 제품1.2.6·Godot4.6.3 유지.
- 원격 푸시·PR·새 버전·배포·main/태그 변경 없음.

## 2. 이번 세션 목표

- 사용자 지적: 앞벽이 캐릭터를 가리지 않고 몸체가 벽 위에 올라온 것처럼 보인다.
- 원인: 이전 구현은 이미 그려진 벽 위에 몸체 알파를 줄여 혼합했으며, 몸체 주변의 벽·바닥은 바뀌지 않았다. 이전943개 검사는 그 혼합식을 확인했을 뿐 사용자가 원한 실제 전경 벽 표현을 입증하지 못했다. 해당 시각 완료 판정은 이번 수정으로 대체한다.
- 완료 조건: 실제 벽 표면을 몸체 위에 그리기, 벽 윗단 유지, 주변 바닥도 비치는 반투명 영역, 이동/제거/화면 전환 시 복원, 기존 배치·건설 보존.

## 3. 완료한 작업

- 기존 masonry 최종 면과 재질을 색상 캐시에 그린다. 기존 깊이 버퍼에는 앞/뒤 구분과 윗면 표시를 추가했다.
- 앞/뒤 기본 벽 이미지에서 몸체 주변의 해당 영역을 비운 뒤 실제 전경 벽을 z108에서 그린다. 전투 몸체51~94, 관리 몸체107보다 앞이고 이름/UI110보다 뒤다.
- 벽면 불투명도42%, 윗단72%를 사용한다. 몸체 알파를 줄이던 코드는 제거했다. 가림 영역은 실제 발 깊이와 몸체 사각형 주변8px·18px 경계 완화로 결정한다. 주변 바닥이 함께 비치고 가까운 몸체 앞의 뒤벽은 전경으로 다시 덮지 않는다.
- 약한 참조로 실제 표시 몸체를 수집한다. 위치/표시 목록이 바뀔 때 기본 벽 이미지를 갱신하고, 캐릭터 제거 시 투명 영역을 비운다. 지도 이탈 시 전경 벽을 숨긴다.
- 기존 벽의 선형 밉맵 필터를 색상 캐시에도 적용했다. 그림자·바닥 링의 기존 가림, 드래그 미리보기·이름·체력 표시를 유지한다.
- 방 배치·길 찾기·AI·시설·비용·해금·성장·저장·Undo 규칙 변경 없음.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| scripts/dungeon_quarter/PreparedMazeActorDepth.gd | 벽 색상/기본 이미지 캐시, 실제 전경 레이어, 표시 몸체 영역 갱신 |
| scripts/dungeon_quarter/prepared_maze_wall_reveal.gdshader 및 .uid | 앞/뒤 기본 벽과 실제 전경 벽의 영역별 알파 |
| scripts/dungeon_quarter/prepared_maze_depth_write.gdshader | 앞/뒤 및 윗면 표시 저장 |
| scripts/dungeon_quarter/prepared_maze_actor_depth.gdshader | 잘못된 몸체 알파 혼합 제거 |
| scripts/dungeon_quarter/QuarterDungeonRenderer.gd | 기존 벽 그리기를 기본 벽 이미지와 연결 |
| scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd | 표시 몸체·위치·화면 상태 갱신 |
| scripts/map/DungeonRenderer.gd | 관리 몸체를 실제 전경 벽 뒤로 배치 |
| tools/UIUXActorWallDepthTest.gd | 실제 벽 켜기/끄기/불투명 대조군, 선형 픽셀 비교, 제거/화면 전환 복원 |
| docs/handoff/CURRENT.md 및 이 문서 | 결함 원인·수정·검증 기록 |

## 5. 그래픽 및 오디오 자산

- 신규 그래픽 생성·후처리·자산 교체·오디오 변경 없음. 기술적 렌더 캐시는 기존 masonry와 재질에서 생성하며 새 미술 원본이 아니다. 새 SOURCE.md 불필요.
- 벽 높이112·기둥120·기존 벽/아치/몬스터 그림과 승인된 돌바닥 유지.
- 돌바닥: assets/dungeon_quarter/prepared_maze/torchlit_flagstone.png
- SHA256: 8f50dfb9f466bd0aeb054e249efbde915b28da966f350f99069b9302eb847d7c (재확인).
- 같은 적 장면에서 윗단이 몸체 앞을 지나고 벽 너머 주변 바닥도 비치는 결과를 실제 게임 캡처로 확인했다.

## 6. 테스트 및 검수

Windows / Godot4.6.3 / Vulkan RTX3060Ti, 격리 APPDATA. 1920×1080·1280×720 및 글자90·100·115%.

| 검사 | 결과 | 로컬 비커밋 근거 |
|---|---|---|
| UIUXActorWallDepthTest 최종 | PASS · 973 assertions / 31장 | tmp/uiux_real_wall_overlay_final.log; tmp/uiux_real_wall_overlay_20260913/final/depth_results.json |
| UIUXMasonryTest | PASS · 31,170 assertions / 100장 | tmp/uiux_real_wall_overlay_matrix.log; 같은 산출물/matrix/results.json |
| UIUXBuildPlacementTest | PASS · 344 checks / 36장 | tmp/uiux_real_wall_overlay_build.log; 같은 산출물/build/ |
| 집중 미궁 실행 --logic-only | PASS · 24,036 assertions / 8장 | tmp/uiux_real_wall_overlay_smoke.log |
| git diff --check / 돌바닥 해시 | PASS | 세션 출력 |
| 저장소 정책 | PASS · 700 final files / 66 commits · 1bfc6eca981034dd53a442e072d1422a87913de0 | tmp/uiux_real_wall_overlay_policy.log |
| 전체 캠페인·전체 회귀·사람·검수 에이전트·Web/모바일 | NOT_REQUESTED / 미실행 | 현재 결과를 전체 검수로 확대하지 않음 |

- 실제 전경 벽을 끈 이미지와 켠 이미지, 벽면/윗단을100% 불투명하게 한 대조군을 사용했다. 독립 geometry 깊이 및 벽 색상 캐시를 기준으로42%/72% 합성과 완전 가림을 실제 framebuffer 픽셀로 확인했다. 뒤벽 앞 몸체도 보존된다.
- 움직이는 배경과 벽 경계 오차 구역은 기존 측정 기준으로 제외했다. GPU와 동일한 선형 텍스처 필터로 색상을 대조했다. 몸체를 모두 없애면 body_count0이 되고, 타이틀 이동 시 전경 레이어가 숨는 것을 검사했다. 기존 Unit 물리 이동도 포함한다.
- 미궁 검사는 성장4단계·배율·수비대/키보드 배치·샛문·저장 왕복·화면 전환을 포함한다. 건설은 카드·고스트·설치 일치, 검토/확정/취소/Undo, 후반 시설을 포함한다.
- 초기 import의 draw_texture_rect 인자 순서와 검사 변수 선언 오류를 수정했다. actor2 검사에서 불투명 대조군 색상을 최근접 픽셀로 읽어 선형 화면 필터와 불일치한 문제는 보간 샘플로 수정했다. actor3 PASS 이후 기존 벽 텍스처 필터를 맞추고 최종973개 검사를 다시 실행했다. 초기 실패 로그는 보존한다.
- 최종 final/matrix/build 로그에 SCRIPT ERROR·ERROR·FAIL 없음 확인.
- 비교: tmp/uiux_real_wall_overlay_20260913/index.html. 이전 잘못된 혼합과 실제 전경 벽 수정 후를 동일 단계/테스트 장면으로 연결했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: c2afafdbbf259507f2ec0e9ff22b7d585202e771
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..c2afafdbbf259507f2ec0e9ff22b7d585202e771
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

별도 에이전트를 사용하지 않았다. Reviewed SHA 이후에는 docs/handoff/만 변경한다.

## 7. 미해결 항목과 위험

- 시설·아치 그림 자체의 정밀 깊이 마스크는 기존 별도 보완 영역이다.
- 새 캐시3개(벽색상1·기본앞뒤2)는 기존 깊이 이미지와 같은 최대4096 해상도를 사용한다. 화면에 표시되는 최대128개 몸체 영역을 처리하며, 초과 몸체는 기존 완전 가림으로 처리한다. Web/모바일·대규모 군중·장시간 GPU 성능 검증은 하지 않았다.
- 기존 저장은 기존 지도를 유지한다. 새 미궁 확인은 새 게임에서 한다.
- 전체 DAY1~30·사람 사용성·공개 배포는 미실행.

## 8. 다음 작업 순서

1. 실제 전경 벽 비교 페이지에서 사용자 지적 장면의 가림과 투명도를 확인한다.
2. 구체적 위치별 보완 요청은 같은 좌표·카메라 장면으로 재현한다. 아치/시설 보완은 해당 범위에서 진행한다.
3. 배포·main 통합·버전·태그·전체 검수는 별도 요청 시 진행한다.

## 9. 작업 트리 상태

- 브랜치 codex/v126-uiux-u0-u3, 시작 시 깨끗함. 구현/검사9개 경로만 명시적으로 로컬 커밋했다.
- 이후 CURRENT/세션 핸드오프만 커밋한다. tmp/ 캡처·로그·비교 페이지는 비커밋.
- 정책 확인 SHA: 1bfc6eca981034dd53a442e072d1422a87913de0. 이후 변경은 핸드오프 결과 기록뿐이다.
- 원격 푸시·스태시·브랜치 전환·공개 배포 없음.

## 10. 종료 체크리스트

- [x] 사용자 지적 원인 인정 및 잘못된 몸체 혼합 제거
- [x] 실제 전경 벽·윗단·주변 바닥 투명·복원 확인
- [x] 픽셀/이동/배치/건설 검사 통과, 초기 실패 보존
- [x] 기존 높이·바닥·게임 규칙·저장 유지
- [x] 전체/사람/에이전트 검수 자동 실행하지 않음
- [x] 검증 SHA·CURRENT·미푸시 상태 기록
