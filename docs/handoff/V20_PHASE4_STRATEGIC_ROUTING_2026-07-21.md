# 제품 2.0 Phase 4 전략 경로 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p04-strategic-routing`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `697f8b84f73dcfd54fcecde9b076da7c2725d809`
- 마지막 제품 커밋 SHA: `ff1178e492fd3dff9abebd54a1888a004916a9d8`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #48

## 2. 이번 세션 목표

- 요청 사항: 두 경로와 여러 방어선에서 배치가 적 경로·첫 교전을 바꾸게 한다.
- 완료 조건: 6개 비용 항 weighted path, 동일 seed 재현, 세 배치의 서로 다른 경로 또는 첫 교전.
- 범위에서 제외한 사항: 시설 전투 효과, 몬스터 AI, Encounter spawn, 모바일과 신규 자산.

## 3. 완료한 작업

- 구현: deterministic weighted path, 목표 선택, 세 배치 route prediction, 실제 경로 preview를 추가했다.
- 스토리 및 데이터: DAY 1~5 board를 북·남 경로, 전·중·후 방어선, 왕좌·보물·후퇴 목표로 선언했다.
- 밸런스: 경로 비용은 전략 차이 검증용 기준값이며 Phase 9에서 조정한다.
- UI/UX: 예상 경로를 회색 전체 graph와 금색 선택 경로로 즉시 구분한다.
- 저장 및 호환성: 저장 변경 없음. 기존 BFS API와 결과를 유지하고 v2 adapter만 추가했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/dungeon_layouts.json` | 두 경로·방어선·목표·node 위치 | 완료 |
| `scripts/v20/path/V20WeightedPathService.gd` | 6항 비용·goal 선택·seed tie-break | 완료 |
| `scripts/v20/path/V20RoutePreview.gd` | 예측 경로 실제 렌더 | 완료 |
| `scenes/v20/path/V20RoutePreview.tscn` | route preview scene | 완료 |
| `scripts/map/RoomGraph.gd` | legacy BFS 보존 v2 adapter | 완료 |
| `scripts/core/DataRegistry.gd` | v2 layout 별도 로드 | 완료 |
| `tools/tests/V20StrategicRoutingTest.*` | 계약·차이·재현·렌더 검증 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 기존 폰트·색만 사용한 runtime draw.
- 게임 연결 및 실제 렌더 확인 결과: `user://v20_phase4_route_1280x720.png`에서 전체 graph와 남문 선택 경로를 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20StrategicRoutingTest.tscn` | PASS, 14 assertions | catalog·6항·재현·3배치·BFS |
| 2 | 동일 test OpenGL `--capture-v20-route` | PASS, 15 assertions | 1280×720 실제 렌더 |
| 3 | `V20PlacementUxTest.tscn` | PASS, 29 assertions | Phase 3 회귀 |
| 4 | `V20DecisionContractsTest.tscn` | PASS, 21 assertions | Phase 1 회귀 |
| 5 | `DemoSmokeTest.tscn` | PASS | 기존 부팅 회귀 |
| 6 | JSON parse, `git diff --check` | PASS | 변경 파일 |
| 7 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `ff1178e492fd3dff9abebd54a1888a004916a9d8` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: ff1178e492fd3dff9abebd54a1888a004916a9d8
- Review range: 697f8b84f73dcfd54fcecde9b076da7c2725d809..ff1178e492fd3dff9abebd54a1888a004916a9d8
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: Phase 8 Encounter scheduler가 enemy contract와 route result를 실제 spawn에 연결해야 한다.
- 밸런스 관찰 항목: 문 비용 12와 목표 선호 -4는 Phase 9 관찰 대상이다.
- 임시 구현 또는 대체 자산: route preview는 vector guide이며 최종 신규 그래픽은 아직 만들지 않았다.
- 외부 환경/도구 제약: 자동 경로 차이는 재미 검증이 아니다.

## 8. 다음 작업 순서

1. Phase 5에서 바리케이드·병영·미끼 보물·감시 초소·회복 둥지 역할 data를 고정한다.
2. 각 시설의 강점·카운터·시너지·결산 지표와 path context 변환을 구현한다.
3. 시설 A/B가 경로·교전·결산 지표를 다르게 만드는 관련 검사를 통과한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `user://v20_phase4_route_1280x720.png` (커밋 안 함).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트·1280×720 렌더 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
