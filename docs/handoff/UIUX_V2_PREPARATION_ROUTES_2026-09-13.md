# UIUX V2 경로별 방어 준비 핸드오프

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 공개1.2.6 기반 UIUX 개선, 새 버전 미확정
- WORKSTREAM_ID: UIUX-V2-PREPARATION-ROUTES-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 main/origin/main/확인한 원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD: a6f5ce6019d0d3f9c7f4958345921958f0f9b194
- 마지막 구현·QA SHA: 1f1adc0232fc9f176c0093e3b8a619b28e2cfb27
- 이후 변경: 이 핸드오프와 CURRENT만
- 원격 푸시/새 PR/태그/Release/공개 배포: 없음
- 버전 근거: main AGENTS 구 버전 문구와 CURRENT를 대조, 현재 공개판1.2.6 유지.

## 2. 목표

사용자 ‘진행해’에 따라 성장 구간별 준비·배치 안내를 구현했다. 주 에이전트 혼자 작업하고 마지막에 관련 검사를 실행. 기존 게임 규칙을 유지하며 실제 초기 수비대와 레벨을 선택한 경로와 연결하는 것이 이번 완료 조건이다. 전력/밸런스 판정은 이번 UI fixture 검사에서 제외한다.

## 3. 완료 내용

- 현재 graph 경로와 실제 방어구역, 출전 배치를 대조해 초기 동료·실제 레벨 표시.
- 요약 두 명+추가 인원, tooltip에 전체 동료·구역. 비출전 동료 제외. 배치0명과 경로 연결 정보없음을 구분.
- 수비대 열기 → 기존 도구함. 자동배치·비용·훈련 없이 접근. 카드에 실제 레벨 추가.
- 캠페인 공지가 존재하면 경로 선택 UI 전체를 생성하지 않던 조기 return 결함 수정. 공지 아래에 경로 UI를 함께 표시.
- 규칙·비용·해금·AI·성장/보상 계산·저장 형식·스토리·자산 변경 없음.

## 4. 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| scripts/ui/DefensePreparationSummary.gd/.gd.uid | 실제 초기 배치 설명 | 완료 |
| scripts/ui/ManagementWorkspaceUI.gd | 공지/경로 공존·안내·바로가기 | 완료 |
| scripts/game/GameRoot.gd | 경로 변경 시 설명 갱신 | 완료 |
| scripts/game/ManagementSceneController.gd | 카드 레벨 | 완료 |
| tools/UIUXPreparationRouteTest.gd/.gd.uid/.tscn | 네 구간 직접 검사 | 완료 |
| docs/qa/UIUX_V2_PREPARATION_ROUTES_2026-09-13.md | 상세 근거 | 완료 |

## 5. 그래픽/오디오

신규 생성·편집·연결 없음. frontend-skill의 지도 중심·필요할 때만 정보 표시 원칙을 적용. 검은 전체 높이벽·앞벽 반투명·돌바닥·현재 캐릭터·오디오 유지. 실패한 방향 생성은 재시도하지 않음.

## 6. 마지막 관련 검사

| 검사 | 결과 | 증거 (tmp/uiux_preparation_20260913/) |
|---|---|---|
| Godot4.6.3 import | 구문 오류 없음 | import.log |
| UIUXPreparationRouteTest | PASS128 | direct.log |
| UIUXBuildPlacementTest | PASS344 | build.log |
| Windows1920×1080 100% /1280×720 115% × DAY2/12/22/30 | 실제 관리UI8조합 | direct/*.png |
| 동일 장면 직전/수정 UI 렌더 | 완료 | before.png/after.png/compare.log |
| git diff --cached --check | PASS | 실행 출력 |
| 전체 회귀/전체 플레이/검수 에이전트 | NOT_REQUESTED | 미실행 |

- 첫 검사에서 DAY12 경로 설명이 없어 실패, 캠페인 공지 조기 return을 수정하고 직접 검사 재실행128항목 PASS. 최종 direct/build/compare 로그 오류·경고0. 최초 실패 로그는 격리 userdata에 보존.
- 경로 조회의 roster/resources/seed/start_state 보존, 비출전 제외, 미확인 구분, 현재레벨, Enter 바로가기와 자원보존 확인.
- 건설 검사는 기존 드래그·고스트·검토·확정·취소·Undo·후반 슬롯까지344항목. --evidence-dir로 이전 캡처 보존.
- 전후 캡처는 같은 GameRoot 관리 상태에서 직전 HEAD의 Workspace와 새 Workspace를 차례로 렌더. 제품 파일을 되돌리거나 저장을 바꾸지 않았음.
- 대표 DAY12 전후1920, DAY30 배치없음1280, DAY12 수비대1280을 직접 열어 확인. 사람 사용성·모든 플랫폼 검증 아님.

### 정책 CI 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 1f1adc0232fc9f176c0093e3b8a619b28e2cfb27
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..1f1adc0232fc9f176c0093e3b8a619b28e2cfb27
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

Reviewed SHA 이후 기능·데이터·자산 변경 없음. 위 판정은 관련 UI/건설 검사에 한정.

## 7. 미해결

- 이번 레벨/배치는 성장 fixture. 실제 DAY1~30 진행이나 전투 승률·전력 비교·밸런스 검증은 하지 않음.
- 초기 배치만 표시하므로 실제 사거리·지원 합류·승패에 대한 보장 없음. 수비대 탭에서는 기존 규칙대로 경로선이 숨겨짐.
- ASSET_BLOCKED_NATIVE_ALPHA 지속. 조건 변화 없는 동일 이미지 생성 재시도 금지.
- 방향/적 미술·실제 성장 전력과 밸런스·전체캠페인/사람/Web/저사양/장시간 검증은 남음. 최종 출시 HOLD.

## 8. 다음 작업

1. UI 수정 반복 대신 초·중·후반 실제 전력/성장 근거 비교를 다음 작업으로 진행. 임의 fixture 레벨을 실제 캠페인 성장으로 주장하지 말고 기존 성장·비용·훈련/보상 경로에서 도달 가능한 상태를 대조한다.
2. 필요한 변경의 근거를 확보하기 전에는 전투 수치·비용·보상을 임의 조정하지 않는다. 사용자가 제외한 전체DAY1~30/8인검수/공개배포를 자동 실행하지 않는다.
3. native alpha 출력 조건이 달라지면 방향/적 미술을 재개. 마지막 관련 검증 후 별도 출시 승인 절차.

## 9. 작업 트리

현재 구현·QA 커밋 완료. 문서 커밋에는 본 핸드오프와 CURRENT만 포함. 기존 변경·스태시 없음, 원격 미푸시. tmp 캡처·비교용 이전 코드·실행 도구·로그는 커밋 제외.

## 10. 종료 확인

- [x] 초기 배치·실제레벨·바로가기 구현
- [x] 캠페인 공지의 경로 UI 차단 수정
- [x] 관련472항목·실제 전후 화면
- [x] Reviewed SHA·CURRENT 기록
- [ ] 실제 전력·밸런스·방향미술·최종출시
