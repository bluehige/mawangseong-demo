# v1.2.2 V2-P4B `stone_sentinel` 연결 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음
- 작업 패킷: `V2-P4B-CONNECT-STONE`

## 2. 이번 세션 목표

- 요청 사항: 승인된 돌콩 전투 자산 1개만 제품 데이터와 시각 profile에 연결한다.
- 완료 조건: 데이터 sprite 경로, `unit_overrides` runtime 경로, 투명 시트 상태, 직접 계약 검사, `1280×720` 대표 화면 확인.
- 범위에서 제외한 사항: 다른 캐릭터, 공통 코드, 초상화·VFX·오디오, 최종 V3 정규화, 다음 패킷.

## 3. 완료한 작업

- `stone_sentinel`의 제품 sprite를 `res://assets/sprites/monsters/update4/monster_dolkong_sheet.png`로 연결했다.
- `combat_visual_profiles.json`에 돌콩 원본·런타임 경로와 `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, `median_art_height_px=170.5`를 기록했다.
- `large_grounded` 프로필에서 목표 높이 `97.1898px`와 배율 `0.570028`을 계산했다.
- `normalization_state`는 공통 V3 범위이므로 `NEEDS_NORMALIZATION`으로 유지했다.
- `1280×720` 실제 OpenGL 호환 화면에서 전용 시트와 grounded 기준선을 확인했다.
- 다음 제안: `V2-P4C-DISCOVER-WAR` 하나. 이번 핸드오프에서는 실행하지 않는다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/monsters.json` | 돌콩 제품 sprite 연결 | 완료 |
| `data/v122/combat_visual_profiles.json` | 돌콩 visual profile/runtime 연결 | 완료 |
| `docs/qa/V122_V2_P4B_STONE_CONNECT_2026-08-04.md` | 직접 검수 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_V2_P4B_STONE_CONNECT_2026-08-04.md` | 패킷 종료 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 패킷 잠금 갱신 | 검수 필요 |

런타임 PNG는 앞선 자산 패킷에서 생성된 승인 자산이며, 이번 연결 패킷에서는 재생성하지 않았다.

## 5. 테스트 및 UI 확인

| 검수 | 결과 |
|---|---|
| JSON 파싱·profile/runtime 경로 계약 | PASS |
| 768×768 RGBA 4×4 시트·16셀·크로마 0 | PASS |
| `170.5px` 중앙값·`0.570028` 배율·접지 앵커 | PASS |
| `V122CombatVisualProfileContractTest` | PASS |
| `1280×720` 대표 화면에서 돌콩 크기·접지 기준선 | PASS |
| 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED |

### 검수 에이전트 반복 기록

- 검수 에이전트는 요청되지 않았고 실행하지 않았다.
- 남은 P1/P2 지적: 최종 동작별 발 앵커 정규화는 V3 범위다.
- 실행하지 못한 필수 검수와 이유: 전체 회귀·전체 플레이는 이번 단일 연결 패킷의 범위가 아니므로 실행하지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A — 연결 단일 패킷 정책 필드
- Final review result: TARGETED_PASS

## 6. 미해결 항목과 다음 순서

- 공통 V3에서 모든 동작 프레임의 발 앵커와 그림자 결합을 최종 확인해야 한다.
- 현재 다음 패킷은 `V2-P4C-DISCOVER-WAR` 하나만 제안·잠금한다.
- 이 패킷에서는 커밋·푸시·빌드를 수행하지 않았다.

## 7. 작업 트리 상태

- 기존 Luna 작업과 여러 문서가 섞인 dirty worktree를 보존했다.
- 이번 패킷의 의도한 제품 변경은 `data/monsters.json`과 `data/v122/combat_visual_profiles.json`이다.
- 원격 푸시 및 PR/태그: 없음.

Related tests: JSON·profile/runtime 경로·170.5px 중앙값·RGBA/크로마 0·배율/접지 앵커·profile contract 직접 검사 PASS
UI check: `1280×720` 대표 화면에서 돌콩 전용 시트 크기와 grounded 기준선 확인 PASS
Unresolved issues: 최종 동작별 발 앵커 정규화는 V3 범위이며 다음 패킷은 `V2-P4C-DISCOVER-WAR` 하나로 잠금
