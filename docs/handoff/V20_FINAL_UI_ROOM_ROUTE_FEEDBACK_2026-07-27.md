# 제품 2.0 최종 UI G1 배치 동선·몬스터 가독성 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-room-route`
- 기준 브랜치와 SHA: `release/v2.0@9e96a0901070694d784f6196d01a74b661775f3f`
- source full SHA: `7b68d8cb450d26838cc8a2af822ca555ec660d87`
- Reviewed SHA: `7b68d8cb450d26838cc8a2af822ca555ec660d87`
- 후보 상태: `G1_OWNER_REPLAY_PENDING`
- 매니페스트: `docs/handoff/V20_FINAL_UI_CANDIDATE_R1_MANIFEST_2026-07-27.json`

## 2. 사용자 피드백과 완료 조건

사용자가 기존 U5 후보를 직접 확인한 뒤 다음 두 문제를 수정 요청했다.

1. 배치 화면의 흐름선이 실제 성의 방과 통로를 거쳐 왕좌로 진행하는 것으로 보이지 않는다.
2. 각 건물·방에 어떤 몬스터가 배치돼 있는지 한눈에 알아보기 어렵다.

완료 조건은 하단 침입구부터 왕좌까지 실제 배경의 바닥 통로를 따라가는 시각 동선, 방 카드의 몬스터 초상·한글 이름·빈 슬롯·현재/정원 동시 표시, 1280×720과 1366×768 실제 렌더의 겹침 없는 가독성이다.

기존 U5 후보 SHA와 빌드 해시는 이 수정 요청으로 승인 대상에서 제외된다. 사용자 승인 게이트는 아래 R1 source와 build hash로 다시 고정한다.

## 3. 변경 내용

| 경로 | 변경 |
|---|---|
| `data/v20/dungeon_layouts.json` | 배치 화면 전용 `placement_view` 동선·stage·카드 anchor 추가 |
| `scripts/v20/placement/V20PlacementBoard.gd` | 실제 바닥 통로형 흐름선, 구간 화살표, 단일 이동 bead, stage와 카드 연결선 적용 |
| `scripts/v20/placement/V20PlacementBoard.gd` | 방 정보 카드를 확대하고 카드 위치를 실제 방과 겹치지 않는 전용 anchor로 분리 |
| `scripts/v20/placement/V20PlacementRoomButton.gd` | 방마다 정원 수만큼 슬롯을 항상 표시하고 초상·한글 이름·빈 슬롯을 구분 |
| `tools/tests/V20PlacementUxTest.gd` | 동선·anchor·카드 정보 계약과 두 해상도 GPU 캡처 검증 추가 |

`route_waypoints`, `zones`, `world_anchor`, `combat_bounds`, 시설·몬스터 효과, spawn, HP, ATK, AI와 전투 판정은 변경하지 않았다. `placement_view`는 배치 화면의 설명용 시각 좌표만 제공한다.

## 4. 수정 전/후

| 구분 | 수정 전 | R1 |
|---|---|---|
| 흐름선 | 논리 node anchor를 직선으로 연결해 벽과 방을 가로지르는 것처럼 보임 | 침입구 → 성문 전초 → 하부 복도 → 가시 회랑 → 중앙 전투실 → 왕좌 전실 → 왕좌의 바닥 통로를 따라감 |
| 진행 표시 | 모든 구간에 화살표와 이동점이 반복돼 시선이 분산됨 | 주요 구간 화살표와 경로 전체를 이동하는 bead 하나로 단순화 |
| 방 카드 | 작은 카드의 점 표기로 배치 수만 확인 가능 | 큰 카드에서 `배치 몬스터 1/2`, 초상, `슬라임` 같은 한글 이름, `빈 슬롯`을 동시에 확인 |
| 배치 후 갱신 | 도구 목록의 현재 위치와 작은 초상 위주 | 도구 위치와 대상 방 카드의 초상·이름·빈 슬롯이 함께 즉시 갱신 |

## 5. 직접 관련 검증

| 검사 | 결과 |
|---|---|
| `V20PlacementUxTest` GPU | PASS, 57 assertions |
| `V20InformationArchitectureTest` | PASS, 115 assertions |
| `V20UnifiedSpatialModelTest` | PASS, 68 assertions |
| `V20DecisionContractsTest` | PASS, 24 assertions |
| `V20FinalUIFlowSmokeTest` | PASS, 22 assertions |
| Windows debug 부팅 | PASS, 8초 process alive |
| Web HTTP smoke | PASS, HTML 200·PCK 200·source badge 일치 |
| 1280×720 GPU 실제 렌더 | PASS, 초기·drag·거부·적용 |
| 1366×768 GPU 실제 렌더 | PASS, 초기·drag·거부·적용 |
| 전체 검수 | NOT_REQUESTED, F1 전 실행 금지 |

1280×720과 1366×768의 초기·적용 화면을 직접 확인했다. 흐름선은 성 내부 바닥과 중앙 복도를 따라 왕좌에 도달하고, 네 방 카드와 우측 배치 도구가 겹치지 않으며 몬스터 이름과 빈 슬롯이 판독 가능하다.

### 정책 CI와 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: `7b68d8cb450d26838cc8a2af822ca555ec660d87`
- Review range: `9e96a0901070694d784f6196d01a74b661775f3f..7b68d8cb450d26838cc8a2af822ca555ec660d87`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 고정 산출물과 SHA-256

로컬 산출물 루트:

`tmp/v20-ui-candidate-7b68d8cb-room-route/`

| 산출물 | bytes | SHA-256 |
|---|---:|---|
| Windows debug ZIP | 261,863,081 | `4bd2521b2392f373984a88aebfe4b85a510d9b54b6ab9e5da28f8d3d28a6753e` |
| Windows EXE | 94,340,608 | `971ee5813e43225d6c414e404c33d257dba51bea7a3dfb0fa104d1b5cdea2b13` |
| Windows PCK | 231,758,164 | `c18376fc29a249a7207c520804d3b142e4ca41e5f7286de4cb65c4071cd37336` |
| Web debug ZIP | 239,760,030 | `506e0c2d8c3b95b424ceb09e73ca7ea1453671d8501276cc4e86ce934b2fc6b4` |
| Web PCK | 231,758,164 | `6eefe074ed3b6733ddb2a5472735a0385f551b1b18d65118cb33aeaaf9a9d6ce` |
| Web WASM | 36,157,734 | `e5fdeacf9706dce4252c5e144ae07ed66e9ca65645852a1880bd8af51fb09d8d` |

Windows ZIP은 `Start-V20-UI-Candidate.cmd`, EXE, PCK, README를 포함한다. Web ZIP은 `Start-V20-Web-Candidate.cmd`, HTML/JS/PCK/WASM, 아이콘·worklet, README를 포함한다.

## 7. 실제 화면 캡처

| 화면 | 파일 | SHA-256 |
|---|---|---|
| 초기 배치 1280×720 | `captures/placement-initial-1280x720.png` | `eed237a2c9ad0c4fcce87069896e7bd18e5487e8f742ad343c89cbc597afc9ae` |
| 몬스터 이동 후 1280×720 | `captures/placement-applied-1280x720.png` | `17e00488f37e0b28ad48a7ce3fb5554504cd3d51c4ce20c1a9f318fd836366f5` |
| 초기 배치 1366×768 | `captures/placement-initial-1366x768.png` | `da46428690643bf1ca7b827799682c3bab2420a6407b5a7e4f52b6c978a2c3f2` |
| 몬스터 이동 후 1366×768 | `captures/placement-applied-1366x768.png` | `1e8551fb5fff3c0f828401d16338e45818b8c9777c7b9358bec8886602b2fd2c` |

## 8. 알려진 제한

- 이 후보는 로컬 debug acceptance 빌드이며 코드 서명된 정식 release export가 아니다.
- Windows export preset의 기존 v1.2.1 제품 메타데이터는 그대로다. 버전·출시 설정 통합은 사용자 승인 뒤 P4 범위다.
- Web source badge는 산출물 HTML overlay이고 PCK는 export 원본이다.
- 전체 회귀, 실제 물리 70전, 숙련 QA 24전, 초회 사용자 10명 표본과 재미·밸런스 판정은 F1 전 실행하지 않는다.

## 9. G1 재확인과 승인 게이트

사용자는 R1에서 다음을 다시 확인한다.

1. 흐름선이 실제 바닥 통로와 방을 거쳐 왕좌로 이어지는지
2. 각 방의 몬스터 초상·이름·빈 슬롯·정원을 바로 구분할 수 있는지
3. 몬스터를 다른 방으로 옮겼을 때 두 방 카드가 즉시 갱신되는지
4. 카드가 배경의 핵심 통로와 우측 배치 도구를 과도하게 가리지 않는지

승인할 경우 아래 고정 문구를 사용한다.

```text
V20_UI_OWNER_ACCEPTED
source_sha: 7b68d8cb450d26838cc8a2af822ca555ec660d87
build_hash: 4bd2521b2392f373984a88aebfe4b85a510d9b54b6ab9e5da28f8d3d28a6753e
decision: 정식 출시본 이식 승인
```

Web 기준 승인에는 Web PCK SHA-256 `6eefe074ed3b6733ddb2a5472735a0385f551b1b18d65118cb33aeaaf9a9d6ce`를 사용할 수 있다.

승인 전까지 P0, `release/v2.0-product`, 정식 출시선 이식은 시작하지 않는다.
