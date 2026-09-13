# UIUX V2 — 몬스터를 가리는 앞벽 반투명 합성

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 1.2.6 유지. 새 버전·출시 없음.
- WORKSTREAM_ID: UIUX-V2-WALL-TRANSPARENCY-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 브랜치 및 SHA: main / 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 세션 시작 SHA: d008ac58d7cf12e0eebf4057759c86ecfe5347a5 (깨끗한 작업트리)
- 마지막 구현 커밋 SHA: c81bd94ce2e17db0cff85d86846b441e1caeefc7
- 원격 푸시 여부: 없음. PR·태그·main·공개 배포 변경 없음.
- main/origin/main/실제 원격 main 일치를 `git ls-remote`로 재확인했다. main:AGENTS와 main:CURRENT를 읽었으며, 오래된 버전 문구보다 CURRENT의 제품 1.2.6과 최신 사용자 지시를 적용했다.

## 2. 이번 세션 목표

- 사용자 요청: 몬스터보다 앞에 있어 몸체를 가리는 벽을 반투명하게 만들어 몬스터를 보이게 한다. 앞벽·뒤벽 레이어 분리를 제안했다.
- 기존 전체 높이 벽·기둥·승인 돌바닥은 유지한다. 앞선 핸드오프의 자동 반투명 제외는 이번 명시적 요청으로 대체한다.
- 완료 조건: 실제 몸체 겹침에서 앞벽 30%/몸체70% 합성, 뒤벽 앞 몸체 유지, 이동·관리/전투 연결, 기존 배치·건설 보존 및 캡처.

## 3. 완료한 작업

- 기존 앞/뒤 그리기 순서와 픽셀 깊이 버퍼를 재사용했다. 발 위치보다 앞에 있는 벽 표면에 가린 몸체 픽셀을 버리던 대신 반투명 합성한다.
- 구현은 역순 알파 합성이다. 벽이 이미 그려진 화면 위에 가려진 몸체를 70%로 그려 최종 `벽30% + 몸체70%`를 만든다. 몸체와 벽이 겹치는 범위에 적용하며, 전체 앞벽 조각이나 주변 바닥까지 투명하게 바꾸는 구현은 아니다.
- 관리 수비대와 실제 전투 아군·적에 연결했다. 벽 앞 또는 열린 바닥의 몸체는 기존 색·알파로 유지한다. 카메라·UI 배율과 현재 발 위치를 기존 변환으로 반영한다.
- 관리 몸체를 기존 노드의 Sprite2D 자식으로 분리했다. 기존 텍스처·미리보기 사각형 크기·위치를 사용하며 부모의 그림자와 바닥 선택 링은 완전 가림을 유지한다. 전투 바닥 표시도 기존 가림을 유지한다.
- 이름·체력 안내 및 조작 중 드래그 미리보기의 표시 경로는 유지한다.
- 스토리·콘텐츠·비용·해금·AI·경로·성장·저장·Undo 규칙 변경 없음.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| scripts/dungeon_quarter/PreparedMazeActorDepth.gd | 몸체 표시 선택 및 앞벽 불투명도30% 연결 | 완료 |
| scripts/dungeon_quarter/prepared_maze_actor_depth.gdshader | 실제 가림 영역의 역순 반투명 합성 | 완료 |
| scripts/dungeon_quarter/QuarterDungeonRenderer.gd | 전투 몸체의 반투명 가림 활성화 | 완료 |
| scripts/dungeon_quarter/PreparedMazeRosterActor.gd | 몸체와 그림자·선택 링 분리 | 완료 |
| scripts/map/DungeonRenderer.gd | 관리 몸체 갱신·반투명 바인딩 | 완료 |
| tools/UIUXActorWallDepthTest.gd | 실제 합성 비율·원래 불투명 대조군·뒤벽 보존 검증 | 완료 |
| docs/handoff/CURRENT.md 및 이 문서 | 최신 작업과 검증·제한 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- 신규 이미지 생성·후처리·오디오·자산 교체 없음. 기존 몸체 텍스처와 벽 소재를 사용한 코드 합성 변경이다.
- 새 생성 원본·SOURCE.md는 필요하지 않다.
- 유지한 돌바닥: assets/dungeon_quarter/prepared_maze/torchlit_flagstone.png
- SHA256 재확인: 8f50dfb9f466bd0aeb054e249efbde915b28da966f350f99069b9302eb847d7c
- 전체 벽112·기둥120·벽 소재·아치·조명·돌바닥 변경 없음.
- 실제 관리 확대, 전투 벽 뒤 몸체, 720p 글자115% 화면을 캡처로 관찰했다.

## 6. 테스트 및 검수

Windows / Godot 4.6.3 / Vulkan / RTX 3060 Ti, 격리 APPDATA. 1920×1080 및 1280×720, 글자90·100·115%.

| 검사 | 결과 | 근거 (로컬 비커밋) |
|---|---|---|
| headless editor import | PASS | tmp/uiux_wall_transparency_import.log |
| UIUXActorWallDepthTest | PASS · 943 assertions / 30장 | tmp/uiux_wall_transparency_actor2.log; tmp/uiux_wall_transparency_20260913/verified/depth_results.json |
| UIUXMasonryTest | PASS · 31,170 assertions / 100장 | tmp/uiux_wall_transparency_matrix.log; tmp/uiux_wall_transparency_20260913/matrix/results.json |
| UIUXBuildPlacementTest | PASS · 344 checks / 36장 | tmp/uiux_wall_transparency_build.log; tmp/uiux_wall_transparency_20260913/build/ |
| git diff --check / 바닥 해시 | PASS | 세션 실행 출력 |
| 저장소 정책 | PASS · 696 final files / 63 commits · 0a0e898af54a29c7760936c4c92975b05d9b79b4 | tmp/uiux_wall_transparency_policy.log |
| 전체 캠페인·사람·전체 회귀·검수 에이전트·Web/모바일 | NOT_REQUESTED / 미실행 | 현재 결과를 전체 검수로 확대하지 않음 |

- 실제 native framebuffer에서 몸체를 숨긴 배경, 가림을 끈 몸체, 반투명 합성, 원래 완전 가림 대조군을 비교했다. 독립 벽 geometry query와 각 몸체 발 위치로 앞뒤를 판정한다. 그림자/링에 몸체 표시 플래그가 꺼져 있는지도 확인한다.
- 움직이는 배경 픽셀과 벽 모서리 오차 구역은 기존 측정 기준대로 제외한다. 실제 물리 이동 경로와 프레임별 발 깊이 갱신도 확인했다.
- 초기 actor.log는 셰이더 기본값 조회가 null인 테스트 오류를 포함한다. 도구가 끝에 PASS(808)를 출력했어도 유효한 통과로 인정하지 않았다. 실제 불투명도를 재질에 명시적으로 연결하고 오류 없이 943개 검사를 다시 수행했다. 초기 로그는 보존했다.
- 최종 actor2/matrix/build 로그에 SCRIPT ERROR·ERROR·FAIL 없음 확인.
- 미궁 검사는 성장4단계·지도/글자배율·관리/전투 전환·수비대 드래그·키보드·샛문·저장 왕복을 포함한다. 건설 검사는 카드/고스트/확정 일치, 검토·취소·Undo와 후반 시설을 포함한다.
- 전후 비교: tmp/uiux_wall_transparency_20260913/index.html. 이전 전체 높이 벽 실행과 이번 동일 단계/테스트 장면을 연결했다. 대기 동작·불꽃 프레임은 다를 수 있다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: c81bd94ce2e17db0cff85d86846b441e1caeefc7
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..c81bd94ce2e17db0cff85d86846b441e1caeefc7
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

별도 에이전트는 사용하지 않았다. Reviewed SHA 이후에는 docs/handoff/만 수정한다.

## 7. 미해결 항목과 위험

- 적용 범위는 몸체와 벽이 겹치는 픽셀이다. 여러 액터의 겹침은 기존 액터 그리기 순서를 따르며, 새로운 전체 벽 렌더 시스템을 만들지 않았다.
- 시설·아치 그림 자체의 정밀 깊이 판정은 기존 별도 보완 영역으로 남는다.
- 기존 저장은 기존 지도를 유지한다. 새 미궁 확인에는 새 게임을 사용한다.
- 전체 DAY 1~30·사람 사용성·Web·모바일·장시간 성능은 미검증.

## 8. 다음 작업 순서

1. 비교 페이지에서 몸체가 비치는 정도와 앞뒤 구분에 대한 사용자 피드백을 확인한다.
2. 불투명도 조정은 PreparedMazeActorDepth의 상수와 해당 실제 픽셀 검사를 함께 수정한다. 전체 벽 조각 단위 또는 주변 바닥이 비치는 연출 요청은 별도 범위로 처리한다.
3. 아치·시설 보완이나 배포·버전·main 통합·태그는 해당 요청이 있을 때 진행한다.

## 9. 작업 트리 상태

- 브랜치: codex/v126-uiux-u0-u3. 시작 시 깨끗했고 기존 변경 없음.
- 구현/검사 6개 파일을 명시적으로 로컬 커밋했다. 이어서 CURRENT/핸드오프만 커밋한다.
- 정책 확인 SHA: 0a0e898af54a29c7760936c4c92975b05d9b79b4. 이후 수정은 핸드오프의 정책 결과 기록뿐이다.
- 원격 푸시·스태시·브랜치 전환·공개 배포 없음.
- tmp/ 로그·캡처·비교 HTML은 비커밋으로 보존한다.

## 10. 종료 체크리스트

- [x] 실제 앞벽과 몸체 겹침 반투명 적용
- [x] 높이·기둥·바닥·기존 게임 규칙 보존
- [x] 직접 픽셀·이동·배치·건설 검사 통과 및 초기 실패 기록
- [x] 전체/사람/에이전트 검수 자동 실행하지 않음
- [x] 검증 SHA·자산 변경 없음 기록
- [x] CURRENT 갱신, 의도한 파일만 로컬 커밋
- [x] 미푸시·공개 배포/태그 없음 기록
