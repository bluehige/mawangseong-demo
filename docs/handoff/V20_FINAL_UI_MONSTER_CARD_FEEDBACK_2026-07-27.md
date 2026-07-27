# 제품 2.0 최종 UI G1 몬스터 카드 가독성 R2 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v20-final-ui-room-route`
- 기준 브랜치와 SHA: `release/v2.0@9e96a0901070694d784f6196d01a74b661775f3f`
- source full SHA: `2349299be955a02b0fddb00b045cf71207ad4e7b`
- Reviewed SHA: `2349299be955a02b0fddb00b045cf71207ad4e7b`
- 후보 상태: `G1_OWNER_REPLAY_PENDING`
- 매니페스트: `docs/handoff/V20_FINAL_UI_CANDIDATE_R2_MANIFEST_2026-07-27.json`

## 2. 사용자 피드백

R1의 방 카드가 이전보다 명확해졌지만 사용자는 몬스터를 더 크게 보여 주는 참고 구성을 제시했다. 방·시설·정원 텍스트는 왼쪽에 유지하고, 몬스터 초상과 이름은 오른쪽에서 더 크게 보이도록 재배치하며 정원 3명인 경우도 카드 안에 맞춰야 한다.

R1 source와 build hash는 이 추가 수정으로 승인 대상에서 제외된다. 현재 승인 대상은 R2다.

## 3. 변경

- 방 카드 크기를 1280×720에서 최소 218×110으로 확대했다.
- 왼쪽 정보는 `방 이름 / 시설 / 수비대 현재·정원` 세 줄로 축약했다.
- 오른쪽에 정원 수만큼 세로 슬롯을 만들었다.
- 정원 2명은 약 40px 초상과 10px 이름을 사용한다.
- 정원 3명은 슬롯 간격·초상·이름을 자동 축소해 세 줄을 모두 카드 안에 유지한다.
- 빈 자리도 같은 열에서 `빈 슬롯`으로 표시한다.
- 확대된 네 방 카드가 1280×720에서 겹치지 않도록 배치 화면 전용 카드 anchor를 조정했다.

현재 제품의 canonical 방 정원은 2명 그대로다. 3인 표시는 컴포넌트의 대응 능력만 검증했으며 방 정원, 전투 좌표, spawn, AI, HP/ATK, 시설 효과와 밸런스는 변경하지 않았다.

## 4. 검증

| 검사 | 결과 |
|---|---|
| `V20PlacementUxTest` GPU | PASS, 62 assertions |
| 정원 2명 카드 | PASS, 큰 초상·이름·빈 슬롯·왼쪽 정보 비겹침 |
| 정원 3명 fixture | PASS, 초상·이름 3개·왼쪽 정보 비겹침 |
| 1280×720 GPU 렌더 | PASS, 카드 4개 비겹침 |
| 1366×768 GPU 렌더 | PASS |
| `V20InformationArchitectureTest` | PASS, 115 assertions |
| `V20UnifiedSpatialModelTest` | PASS, 68 assertions |
| `V20DecisionContractsTest` | PASS, 24 assertions |
| `V20FinalUIFlowSmokeTest` | PASS, 22 assertions |
| Windows debug 부팅 | PASS, 8초 process alive |
| Web HTTP smoke | PASS, HTML 200·PCK 200·source badge 일치 |
| 전체 검수 | NOT_REQUESTED, F1 전 실행 금지 |

### 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: `2349299be955a02b0fddb00b045cf71207ad4e7b`
- Review range: `9e96a0901070694d784f6196d01a74b661775f3f..2349299be955a02b0fddb00b045cf71207ad4e7b`
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 5. R2 산출물

로컬 루트:

`tmp/v20-ui-candidate-2349299b-monster-cards/`

| 산출물 | bytes | SHA-256 |
|---|---:|---|
| Windows debug ZIP | 261,863,385 | `7b86b0554f423f5f276396ca87e53d3a791ccf7d6311fe71cad008837d5fa793` |
| Windows EXE | 94,340,608 | `971ee5813e43225d6c414e404c33d257dba51bea7a3dfb0fa104d1b5cdea2b13` |
| Windows PCK | 231,758,980 | `de26ab137854801b7f37d7870d69cd1fc94ee830cca1fa9d84bcfc939424241f` |
| Web debug ZIP | 239,760,279 | `d4a7ec0420ab1a98fa801fa1bad5494ab8f9587a245aa62cc2b49e5994ca3ddf` |
| Web PCK | 231,758,980 | `b3ac451afe990519b2a0c768b3b177dae95b0cbaa53ccc22429c61ce1a701cb9` |
| Web WASM | 36,157,734 | `e5fdeacf9706dce4252c5e144ae07ed66e9ca65645852a1880bd8af51fb09d8d` |

## 6. 캡처

| 화면 | 파일 |
|---|---|
| 초기 배치 1280×720 | `captures/placement-initial-1280x720.png` |
| 이동 후 배치 1280×720 | `captures/placement-applied-1280x720.png` |
| 초기 배치 1366×768 | `captures/placement-initial-1366x768.png` |
| 이동 후 배치 1366×768 | `captures/placement-applied-1366x768.png` |
| 정원 3명 카드 | `captures/monster-card-three-slots-280x160.png` |

## 7. 승인 게이트

```text
V20_UI_OWNER_ACCEPTED
source_sha: 2349299be955a02b0fddb00b045cf71207ad4e7b
build_hash: 7b86b0554f423f5f276396ca87e53d3a791ccf7d6311fe71cad008837d5fa793
decision: 정식 출시본 이식 승인
```

Web 기준 승인에는 Web PCK SHA-256 `b3ac451afe990519b2a0c768b3b177dae95b0cbaa53ccc22429c61ce1a701cb9`를 사용할 수 있다. 승인 전까지 P0와 `release/v2.0-product`를 시작하지 않는다.
