# UIUX V2 성장 구간별 경로·초기 수비대 안내

- WORKSTREAM_ID: UIUX-V2-PREPARATION-ROUTES-20260913
- 시작 HEAD: a6f5ce6019d0d3f9c7f4958345921958f0f9b194
- 작업 브랜치: codex/v126-uiux-u0-u3
- 권위 main/origin/main/확인한 원격 main:69a75970b1f8c030aa3a6956e5ca0f5bf15b2112.
- 제품1.2.6 유지. 권위 main AGENTS의 구 버전 문구와 CURRENT를 대조, 새 버전·태그·배포 없음.
- 사용자 순서대로 주 에이전트 혼자 구현 후 마지막 관련 검사. frontend-skill의 지도 중심 정보 배치 원칙 적용. 신규 이미지 생성·외부자료 사용 없음.

## 구현

1. 선택한 예상 경로의 실제 graph.path_between 방 목록과 combat_topology.defense_zones를 대조하고, 현재 maze_deployments에서 해당 구역의 출전 동료만 표시한다.
2. 실제 이름·현재 레벨, 경로상 방어 구역 수를 표시. 요약은 두 명+추가 인원, tooltip에는 전체 동료/구역을 넣는다. 출전 가능/배치 필터는 기존 _refresh_maze_route_forecasts 경로를 재사용한다.
3. 배치0명은 ‘초기 배치 없음’, 경로/연결 정보가 없으면 ‘확인할 수 없음’으로 구분한다. 전투 중 이동·사거리·합류·승패를 예측하지 않는다.
4. 수비대 열기 버튼은 기존 도구함 탭만 전환한다. 자동 배치·훈련·비용 지출·새 시작 차단은 없다. 수비대 카드에도 현재 레벨을 표시한다.
5. 캠페인 공지 존재 시 ManagementWorkspaceUI.build가 return하여 중후반의 경로 선택 UI 전체가 없어지던 결함을 수정했다. 기존 공지는 그대로 두고 경로 영역을 아래로 배치했다.

## 변경 경로

| 파일 | 역할 |
|---|---|
| scripts/ui/DefensePreparationSummary.gd, .gd.uid | 현재 경로의 초기 수비대·구역 설명 |
| scripts/ui/ManagementWorkspaceUI.gd | 공지/경로 공존, 요약과 바로가기 |
| scripts/game/GameRoot.gd | 경로 선택 시 설명 갱신 |
| scripts/game/ManagementSceneController.gd | 수비대 카드 레벨 |
| tools/UIUXPreparationRouteTest.gd, .gd.uid, .tscn | 네 성장 구간 실제 UI 검사 |

데이터·비용·해금·보상·AI·성장 계산·저장 형식·스토리·게임 그래픽은 변경하지 않았다.

## 마지막 관련 검사

Godot4.6.3 Windows Forward+ RTX3060Ti. 로그·캡처는 tmp/uiux_preparation_20260913/.

| 검사 | 결과 | 증거 |
|---|---|---|
| editor import | 구문 오류 없음 | import.log |
| UIUXPreparationRouteTest | PASS128 | direct.log |
| 기존 UIUXBuildPlacementTest | PASS344 | build.log |
| git diff --check | PASS | 실행 출력 |
| 동일 장면 이전/수정 UI 렌더 | 완료 | before.png / after.png / compare.log |

- 첫 검사 DAY12에서 요약Label이 없어 assertion과 null 접근이 실패했다. 캠페인 공지의 기존 조기 return이 원인이었고 제품 코드를 고친 뒤 전체 직접 검사를 재실행해128항목 PASS.
- 초기 실패 로그는 userdata/Godot/app_userdata/마왕님, 마왕성 지켜주세요! Demo/logs/godot2026-09-13T23.21.27.log에도 남아 있다. 최종 direct.log/build.log/compare.log에는 ERROR/SCRIPT ERROR/WARNING 없음.
- 성장 구간 DAY2/12/22/30 × Windows1920×1080 100% /1280×720 115% =8조합. 실제 game 준비 UI, 경로 선택 후 즉시 갱신, 현재 레벨·초기3명·출전 불가 제외·빈 경로 안내·알 수 없음 구분·Enter 바로가기 확인.
- 경로 조회 전후 roster/resources/update2 seed/start_state 동일. 바로가기 후 배치와 자원 동일. 수비대 카드의 실제 레벨 확인.
- 기존 건설 검사는 --evidence-dir=res://tmp/uiux_preparation_20260913/build로 실행하여 이전 캡처 보존. 기존 유효 슬롯·고스트·확정·취소·Undo와 후반 시설까지344항목 확인.
- 비교 도구는 직전 HEAD의 ManagementWorkspaceUI.gd만 tmp/PreviousWorkspace.gd로 읽어, 같은 GameRoot 관리 상태에서 이전/새 workspace를 차례로 렌더했다. 제품 파일을 되돌리거나 저장을 바꾸지 않았다.
- 대표 DAY12 전후1920, DAY30 배치없음1280, DAY12 수비대1280 화면을 직접 열어 확인했다. 모든 화면의 사람 사용성·미술 취향 판정을 주장하지 않는다.

## 한계·다음

- 레벨과 배치는 검사용 성장 fixture다. DAY1~30 연속 플레이·전력 비교·난이도 판정은 수행하지 않았다. 전투 밸런스 수치는 조정하지 않았다.
- 전술 탭에서만 경로 요약을 표시해 지도 중심 구성을 유지한다. 수비대 탭으로 전환하면 기존 규칙대로 경로선이 숨겨진다.
- 새 명령 확인창/시작 차단 없음. 예비·지원 동료는 현재 출전 배치가 아니면 초기 방어 인원에 포함하지 않는다.
- ASSET_BLOCKED_NATIVE_ALPHA 방향 미술은 이전 상태 유지. 같은 실패 경로의 재생성은 하지 않았다.
- 실제 성장 전력·밸런스, 방향/적 미술, 전체 캠페인·사람·Web·저사양·장시간 검증은 남음. 최종 출시 HOLD.
- 공개 배포·태그·Release·원격 푸시 없음. tmp 캡처/비교 도구/로그는 커밋 제외.
