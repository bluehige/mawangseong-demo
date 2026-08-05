# v1.2.2 V2-P4A `spore_healer` 연결 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음
- 작업 패킷: `V2-P4A-CONNECT-SPORE`

## 2. 이번 세션 목표

- 요청 사항: 승인된 모리 전투 자산 1개만 제품 데이터와 시각 profile에 연결한다.
- 완료 조건: 데이터 sprite 경로, `unit_overrides` runtime 경로, 투명 시트 상태, 직접 계약 검사, `1280×720` 대표 화면 확인.
- 범위에서 제외한 사항: 다른 캐릭터, 공통 코드, 초상화·VFX·오디오, 최종 V3 정규화, 다음 패킷.

## 3. 완료한 작업

- `spore_healer`의 제품 sprite를 `res://assets/sprites/monsters/update4/monster_mori_sheet.png`로 연결했다.
- `combat_visual_profiles.json`에 모리 원본·런타임 경로와 `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, `median_art_height_px=161.0`을 기록했다.
- `normal_grounded`와 기존 발 앵커 계약을 사용해 배율 `0.486`과 접지 위치를 계산했다.
- 최종 발끝·동작별 정규화는 공통 V3 범위이므로 상태를 `NEEDS_NORMALIZATION`으로 유지했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/monsters.json` | 모리 제품 sprite 연결 | 완료 |
| `data/v122/combat_visual_profiles.json` | 모리 visual profile/runtime 연결 | 완료 |
| `docs/qa/V122_V2_P4A_SPORE_CONNECT_2026-08-02.md` | 직접 검수 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_V2_P4A_SPORE_CONNECT_2026-08-02.md` | 패킷 종료 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 패킷 잠금 갱신 | 완료 |

런타임 PNG와 Godot import sidecar는 앞선 자산 패킷에서 생성된 승인 자산이며, 이번 연결 패킷에서는 재생성하지 않았다.

## 5. 테스트 및 UI 확인

| 검수 | 결과 |
|---|---|
| JSON 파싱·profile/runtime 경로 계약 | PASS |
| 768×768 RGBA 4×4 시트·16셀·크로마 잔류 0 | PASS |
| Godot 직접 연결 검사 | PASS |
| `1280×720` 대표 화면에서 모리 크기·접지 기준선 | PASS |
| 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED |

## 6. 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A — 연결 단일 패킷 정책 필드
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 다음 순서

- 공통 V3에서 모든 동작 프레임의 발 앵커와 그림자 결합을 최종 확인해야 한다.
- 현재 다음 패킷은 `V2-P4B-DISCOVER-STONE` 하나만 제안·잠금한다.
- 이 패킷에서는 커밋·푸시·빌드를 수행하지 않았다.

## 8. 작업 트리 상태

- 기존 Luna 작업과 여러 문서가 섞인 dirty worktree를 보존했다.
- 이번 패킷의 의도한 제품 변경은 `data/monsters.json`과 `data/v122/combat_visual_profiles.json`이다.
- 원격 푸시 및 PR/태그: 없음.

Related tests: JSON·profile/runtime 경로·161px 중앙값·RGBA/크로마 0·배율/접지 앵커 직접 검사 PASS
UI check: `1280×720` 대표 화면에서 모리 시트 크기와 grounded 기준선 확인 PASS
Unresolved issues: 최종 동작별 발 앵커 정규화는 V3 범위이며 다음 패킷은 `V2-P4B-DISCOVER-STONE` 하나로 잠금
