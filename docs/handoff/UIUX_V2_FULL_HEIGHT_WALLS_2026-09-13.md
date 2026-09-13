# UIUX V2 — 미궁 벽 원래 높이 복원

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 1.2.6 유지. 새 제품 버전·출시 없음.
- WORKSTREAM_ID: UIUX-V2-FULL-HEIGHT-WALLS-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 브랜치 및 SHA: main / 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 세션 시작 HEAD: 9b3f20ae827ffd32699c6b94946a126358d6d319 (깨끗한 작업트리)
- 마지막 구현 커밋 SHA: e3b9ae2bfd4aabbf0e42580209ff8f0cd639098d
- 원격 푸시 여부: 없음. PR·태그·공개 배포 없음.
- 착수 시 main/origin/main 및 `git ls-remote origin refs/heads/main` 일치 확인. 권위 main:AGENTS / main:CURRENT 재확인. AGENTS의 오래된 1.2.5 문구보다 CURRENT의 제품 1.2.6 및 최신 사용자 지시를 적용했다.

## 2. 이번 세션 목표

- 사용자는 그림이 일부 가려지더라도 앞벽을 원래 높이로 유지하고 연결 기둥과 구조를 맞추는 방향을 요청했다.
- 완료 조건: 모든 방향 벽의 높이 통일, 연결부 검증, 높아진 벽에서 캐릭터 앞뒤 가림 유지, 실제 건설과 배치 취소 유지, 같은 장면 전후 증거.
- 제외: 자동 투명화·실루엣·새 그래픽·바닥 변경·새 이동 경로·아치 스프라이트 자체의 정밀 깊이 마스크·배포.

## 3. 완료한 작업

- 앞벽(E/S) 높이 36을 기존 뒷벽(N/W) 높이 112로 복원했다. 모서리 기둥은 동일 벽 높이 위 마감 8을 더한 120을 사용한다.
- 높이와 화면 그리기 순서를 분리했다. 방향별 앞/뒤 면 구분을 별도로 보존하고, 서로 다른 그리기 순서의 면을 합치지 않도록 했다. 공유 연결부는 후면 구분을 우선한다.
- 앞뒤 벽 겹침 제거와 캐릭터 픽셀 깊이 비교를 그대로 사용한다. 높은 벽 뒤 캐릭터·시설이 더 가려지는 결과는 사용자의 최신 방향에 따른 것이다.
- 기존 상세창이 열린 상태에서 ESC가 드래그를 취소하지 않고 상세창만 닫는 문제를 직접 검사 중 발견했다. 진행 중인 몬스터 드래그 취소를 상세창 닫기보다 먼저 처리한다.
- 스토리·밸런스·시설 비용·AI·성장·방 연결·길 찾기·저장 데이터 변경 없음.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| scripts/dungeon_quarter/PreparedMazeMasonry.gd | 모든 방향 벽 높이 통일, 같은 높이 기둥, 높이와 그리기 순서 분리 | 완료 |
| scripts/game/GameRoot.gd | 상세창보다 진행 중인 몬스터 드래그의 ESC 취소 우선 | 완료 |
| tools/UIUXMasonryTest.gd | 원래 높이·봉합 단면 검사, 실제 분절 연결에 맞춘 T/십자 검사 입력 | 완료 |
| tools/UIUXPreparedMazeTest.gd | 팝업 Home/Down/Enter 및 상세창 개폐 상태별 드래그 취소 검사 | 완료 |
| tools/UIUXActorWallDepthTest.gd | 출력 경로 인자로 이전 비교 증거 보존 | 완료 |
| docs/handoff/CURRENT.md 및 이 문서 | 최신 작업·검증·제한 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- 신규 생성·후처리·자산 교체 없음. GPT 내부 이미지 생성은 필요하지 않은 코드 기반 벽 높이 수정이다.
- 벽 재질·기존 아치·조명·승인된 돌바닥 유지. 별도 생성 원본/SOURCE.md 추가 없음.
- 돌바닥: assets/dungeon_quarter/prepared_maze/torchlit_flagstone.png
- SHA256: 8f50dfb9f466bd0aeb054e249efbde915b28da966f350f99069b9302eb847d7c (실제 해시 재확인).
- 게임 건설 완료, 성/후반 성 확대, 720p 글자115%를 직접 캡처로 관찰했다. 낮은 앞벽과 높은 뒷벽 사이의 높이 단차가 사라지고 기둥 마감이 이어진다.

## 6. 테스트 및 검수

Windows / Godot 4.6.3 / Vulkan / RTX 3060 Ti. 게임 실행은 격리 APPDATA에서 진행했다.

| 검사 | 결과 | 근거 (로컬 비커밋) |
|---|---|---|
| headless editor import | PASS | tmp/uiux_full_height_import.log |
| UIUXActorWallDepthTest | PASS · 850 assertions / 30장 | tmp/uiux_full_height_actor.log; tmp/uiux_full_height_20260913/actor/depth_results.json |
| UIUXBuildPlacementTest | PASS · 344 checks / 36장 | tmp/uiux_full_height_build.log; tmp/uiux_full_height_20260913/build/ |
| UIUXMasonryTest 최종 | PASS · 31,170 assertions / 100장 | tmp/uiux_full_height_matrix3.log; tmp/uiux_full_height_20260913/final/results.json |
| 수정 입력 집중 실행 (--logic-only) | PASS · 24,036 assertions / 8장 | tmp/uiux_full_height_logic2.log |
| git diff --check 및 돌바닥 해시 | PASS | 세션 실행 출력 |
| 저장소 정책 | PASS · 695 final files / 60 commits · 1d684eb0137c74578fe331df8a86ba160c9ea310 | tmp/uiux_full_height_policy.log |
| 전체 캠페인·사람 사용성·전체 회귀·검수 에이전트·Web/모바일 | NOT_REQUESTED / 미실행 | 현재 결과를 전체 검수로 확대하지 않음 |

- 화면 검사: 1920×1080 / 1280×720, 글자 90·100·115%, 성 성장 4단계, 확대, 실제 카드 드래그·검토·확정·취소·Undo. 캐릭터 검사는 앞뒤 픽셀 비교와 기존 Unit 물리 이동을 포함한다.
- 초기 실패 기록을 보존했다. 첫 matrix(31,118 assertions)는 높이 차로 우연히 만족하던 T 연결 검사 입력과 팝업 키보드 선택이 실패했다. 실제 연결처럼 T/십자 경계선을 공유 꼭짓점에서 나누고, Home으로 팝업의 키보드 시작점을 검증한 뒤 Down/Enter를 보냈다.
- 두 번째 matrix(31,167 assertions)는 상세창이 열린 경우 ESC 취소 실패를 드러냈다. 제품 입력 우선순위를 수정하고 상세창 열림/닫힘을 각각 재검증했다. 실패 로그는 tmp/uiux_full_height_matrix.log 및 matrix2.log에 남아 있다.
- Actor/Build 검사는 최종 벽 geometry에서 수행했다. 이후 제품 변경은 위 몬스터 ESC 처리 2줄이며 최종 미궁 검사에서 재검증했다. 이전 세션의 전투 UI 210/VFX 30 검사를 이번에 다시 수행했다고 기록하지 않는다.
- 비교 페이지: tmp/uiux_full_height_20260913/index.html. 이전 세션의 동일 장면 원본과 이번 실행 PNG를 나란히 연결했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: e3b9ae2bfd4aabbf0e42580209ff8f0cd639098d
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..e3b9ae2bfd4aabbf0e42580209ff8f0cd639098d
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

별도 검수 에이전트는 사용자 지시에 따라 사용하지 않았다. Reviewed SHA 이후에는 docs/handoff/만 수정한다.

## 7. 미해결 항목과 위험

- 높은 앞벽은 몸체와 시설을 많이 가린다. 이름·체력 안내는 유지하며 자동 투명화는 하지 않았다.
- 아치는 기존 별도 스프라이트다. 높이 통일을 아치 연결·알파 깊이 처리가 모두 완료됐다는 뜻으로 기록하지 않는다. 시설·아치와 액터 사이의 정밀 가림은 별도 보완 영역이다.
- 기존 저장은 기존 지도를 보존한다. 새 미궁 확인은 새 게임에서 한다.
- Web·모바일·전체 DAY 1~30·사람 사용성·장시간 성능은 미검증.

## 8. 다음 작업 순서

1. 비교 페이지의 원래 높이 벽과 기둥, 가려지는 정도에 대한 사용자 피드백을 받는다.
2. 아치 연결 또는 시설 가림의 구체적 보완 요청이 있으면 QuarterDungeonRenderer/PreparedMazeActorDepth의 해당 경로와 실제 위치를 기준으로 처리한다.
3. 버전·배포·main 통합·태그는 별도 요청 시 진행한다. 과거 v20 참고선과 출시 태그를 유지한다.

## 9. 작업 트리 상태

- 현재 브랜치: codex/v126-uiux-u0-u3. 기존 혼합 변경 없음.
- 구현 5개 파일을 명시적으로 스테이징해 로컬 커밋. 이후 CURRENT/세션 핸드오프만 추가 커밋.
- 정책 검사 커밋: 1d684eb0137c74578fe331df8a86ba160c9ea310. 이후 변경은 핸드오프 결과 기록뿐이다.
- 원격 푸시·스태시·브랜치 전환 없음. tmp/ 캡처·로그는 비커밋.
- 산출물: tmp/uiux_full_height_20260913/; 초기 실패 증거도 보존.

## 10. 종료 체크리스트

- [x] 요청한 원래 높이 벽·기둥 적용, 승인 바닥 보존
- [x] 관련 검사·실제 게임 화면 확인 및 실패 수정
- [x] 전체 회귀·검수 에이전트 자동 실행하지 않음
- [x] Reviewed SHA와 직접 검증 근거 기록
- [x] 신규 그래픽 없음 및 기존 바닥 해시 기록
- [x] CURRENT 갱신, 의도한 파일만 로컬 커밋
- [x] 미푸시·공개 배포/태그 없음 기록
