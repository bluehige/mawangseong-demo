# 제품 2.0 Phase 11 직관형 배치 보드 UX 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 Phase 11 블라인드 플레이 피드백 수정
- 작업 브랜치: `codex/v20-p11-intuitive-board`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `4b687aeea80b487f237e6c153dce8600989ec81b`
- 마지막 기능 커밋 SHA: `68a47475b228f81ff929f8e4e167ee08638f0ad2`
- 원격 푸시 여부: 문서 작성 시점 미푸시
- 관련 PR 또는 태그: 문서 작성 시점 미생성

## 2. 이번 세션 목표

- 요청 사항: 초반 체험자가 침략 동선, 시설 설치, 몬스터 배치를 설명 없이 이해할 수 있도록 관리 UI/UX를 다시 설계한다.
- 완료 조건: 상시 건물 설정 패널 제거, 현재 침략로 시각화, 시설·몬스터 직접 drag와 click→click 입력, 배치 직후 경로·자원·인원 즉시 갱신, 실제 PC Web 검증.
- 범위에서 제외한 사항: 실제 사람 6~10명 재검수 결과와 Go/No-Go 판정, DAY 6~30 확장, 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 구현:
  - 관리 화면 전체 폭을 단일 `RouteMap` 보드로 사용하고 상시 `ContextDrawer`를 제거했다.
  - 상단에 `1 침략로 확인 → 2 시설·몬스터 배치 → 3 방어 시작`만 고정했다.
  - 시설과 몬스터를 모드 전환 없이 같은 하단 도구함에 항상 노출했다.
  - 시설 drag 1동작, 시설 click→위치 click 2동작, 몬스터 drag 1동작, 몬스터 click→위치 click 2동작을 연결했다.
  - 교체 확인과 Undo는 보드 안에서만 일시적으로 표시한다.
  - 배치 완료 때 관리 화면 전체를 재생성하던 동작을 제거해 drag 종료 입력과 포커스를 보존했다.
  - 배치된 시설의 `slot_id`와 `edge_id`를 실제 전투 상태까지 보존해 예상 침략로와 전투 침략로를 일치시켰다.
- 스토리 및 데이터:
  - 첫 안내를 `바리케이드를 북문으로 드래그`하는 한 문장으로 바꾸고, 30초에는 click 대체 입력, 60초에는 금색 경로 갱신을 안내한다.
  - `placement_rules.json`을 schema 2로 갱신해 시설 drag와 접근성 입력의 동작 수를 명시했다.
- 밸런스: 시설 비용·효과·방 정원·적 구성은 변경하지 않았다.
- UI/UX:
  - 금색 굵은 화살표는 현재 침략로, 보라색 강조는 몬스터·방어 배치로 통일했다.
  - 시설 설치 시 첫 교전 위치가 바뀌면 보드 상단에 즉시 한 줄로 알린다.
  - Web 기본 툴팁 한글 깨짐을 실제 브라우저에서 발견해 중복 툴팁을 제거했다.
- 저장 및 호환성: placement 저장 schema는 1을 유지해 기존 2.0 세션과 호환된다. 입력 규칙 catalog만 schema 2다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/v20/placement/V20PlacementBoard.gd` | 단일 경로 보드·동시 도구함·즉시 피드백 | 완료 |
| `scripts/v20/placement/V20PlacementService.gd` | 시설 drag/click 직접 배치 계약 | 완료 |
| `scripts/v20/placement/V20PlacementRoomButton.gd` | 시설·몬스터 공통 drop target | 완료 |
| `scripts/v20/placement/V20MonsterDragButton.gd` | 시설·몬스터 공통 drag payload | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 전체 폭 보드·주 행동 1개·자원 부분 갱신 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 상시 drawer와 전체 화면 재생성 제거 | 완료 |
| `scripts/game/CombatSceneController.gd` | 시설 slot·edge 실제 전투 보존 | 완료 |
| `data/v20/onboarding.json` | 첫 행동과 대체 입력 안내 단순화 | 완료 |
| `data/v20/placement_rules.json` | 직접 배치 동작 수 계약 | 완료 |
| `tools/tests/V20PlacementUxTest.gd` | 단일 보드·두 drag·즉시 경로 검증 | 완료 |
| `tools/tests/V20InformationArchitectureTest.gd` | 전체 폭·drawer 미노출·주 행동 1개 검증 | 완료 |
| `tools/tests/V20FacilityReworkTest.gd` | 실제 전투 slot·edge 경로 효과 검증 | 완료 |
| `tools/tests/V20OnboardingRetrySaveTest.gd` | 새 30초 안내 계약 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: 기존 던전 배경과 UI 자산 재사용
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: 1280×720 Godot 렌더와 PC Web에서 기존 던전 위 경로·노드·도구함 합성을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V20PlacementUxTest.tscn` | PASS, 37 assertions | 시설·몬스터 직접 drag, click 대체, 경로 갱신, 상시 palette·mode 제거 |
| 2 | `V20InformationArchitectureTest.tscn` | PASS, 33 assertions | 1280×720·1366×768·1920×1080 전체 폭 관리 보드 |
| 3 | `V20FacilityReworkTest.tscn` | PASS, 29 assertions | 실제 전투 `entry_north` 비용 +12 보존 |
| 4 | `V20StrategicRoutingTest.tscn` | PASS, 14 assertions | 두 경로·weighted path 회귀 |
| 5 | `V20OnboardingRetrySaveTest.tscn` | PASS, 35 assertions | 새 안내·저장·재도전·실제 GameRoot 흐름 |
| 6 | Godot 비헤드리스 1280×720 배치 보드 렌더 | PASS | `user://v20_phase11_intuitive_board_1280x720.png`, 저장소 미추적 |
| 7 | Godot 4.5.2 `Web` release export | PASS | 로컬 PCK 231,757,264 bytes, SHA-256 `6e422c0ddb8a41eaf90518fffc397914d08dcdaa402665c6012032ffc3791e57` |
| 8 | Chromium 1280×720 타이틀→2.0→시설 drag→몬스터 drag→방어 시작 | PASS | 건설 10→7, 북문→남문 경로 전환, 북문 0/2·남문 1/2, 오류·경고 0 |
| 9 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 저장소 정책에 따라 실행하지 않음 |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 요청되지 않은 전체 검수는 필수 범위가 아니다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서만 허용한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 68a47475b228f81ff929f8e4e167ee08638f0ad2
- Review range: 4b687aeea80b487f237e6c153dce8600989ec81b..68a47475b228f81ff929f8e4e167ee08638f0ad2
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동·로컬 Web 기준 재현 이슈는 없다. 공개 Pages 갱신 후 같은 drag 흐름을 다시 확인해야 한다.
- 밸런스 관찰 항목: UI가 단순해진 뒤 실제 초회 사용자가 90초 안에 첫 의미 있는 선택을 하는지는 새 블라인드 표본으로 다시 측정한다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 사람 판매성 평가는 자동 검증으로 대체하지 않는다.

## 8. 다음 작업 순서

1. 기능 브랜치를 `release/v2.0`에 PR로 병합한다.
2. 병합 SHA에서 `test/web-*` Web 빌드를 갱신하고 공개 `/v20-p11/` 주소를 재배포한다.
3. 새 빌드로 6~10명 무설명 블라인드 플레이를 다시 받아 첫 선택 90초·DAY 1 완료·이해도·재도전 의향을 판정한다.

## 9. 작업 트리 상태

- 기능 커밋 직후 상태: 의도한 파일은 커밋 완료.
- 미커밋 파일: 이 핸드오프와 `CURRENT.md` 문서 갱신.
- 의도하지 않은 기존 변경: Godot가 생성한 기존 미추적 UID 5개는 필요 sidecar로 확인돼 삭제·스테이징하지 않았다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/v20_p11_intuitive_web_20260721/`, `user://v20_phase11_intuitive_board_1280x720.png`; 모두 저장소 미추적.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 실제 PC Web 검증 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 사실 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 기능 파일만 커밋
- [ ] 원격 푸시·PR·공개 Web 갱신
