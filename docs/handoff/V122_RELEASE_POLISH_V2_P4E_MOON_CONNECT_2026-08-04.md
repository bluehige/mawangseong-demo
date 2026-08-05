# v1.2.2 Luna V2-P4E `moon_tracker` 런타임 연결 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 기준 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 미커밋)
- 작업 패킷: `V2-P4E-CONNECT-MOON`
- 결과: `CONNECT_PASS_WITH_NORMALIZATION_PENDING`
- 커밋/푸시: 이번 turn에서는 수행하지 않음

## 2. 목표와 완료 조건

루미 전용 런타임 시트 1개를 `moon_tracker` 제품 데이터와 `combat_visual_profiles.json`에 연결하고, 임시 출전 차단 해제·데이터 경로·측정값·소형 비행 렌더 배율을 직접 검사했다.

## 3. 완료 내용

- `moon_tracker.sprite`를 `res://assets/sprites/monsters/update4/monster_moon_sheet.png`로 변경했다.
- `moon_tracker.combat_asset_state`를 `READY`로 바꿔 신규 계약 후보와 방어 출전을 다시 허용했다.
- `small_flying` profile에 전용 원본·런타임 경로, `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, `median_art_height_px=125.0`을 등록했다.
- `small_flying` 목표 높이 `59.302232px`와 렌더 배율 `0.474417853`을 기준식으로 확인했다.
- 런타임 시트의 공통 발 기준선 `y=183`, 외곽 침범 0, 크로마 잔류 0, 고유 프레임 16/16을 확인했다.
- 최종 동작별 정규화 상태는 공통 V3 범위이므로 `NEEDS_NORMALIZATION`으로 유지했다.

## 4. 변경 파일

- `data/monsters.json`
- `data/update2_contracts.json`
- `data/v122/combat_visual_profiles.json`
- `docs/qa/V122_V2_P4E_MOON_CONNECT_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V2_P4E_MOON_CONNECT_2026-08-04.md`
- `docs/handoff/CURRENT.md`

런타임 PNG와 생성 원본은 직전 `V2-P4E-ASSET-MOON` 패킷에서 완료한 자산이며 이번 패킷에서는 수정하지 않았다. 다른 캐릭터·공통 코드·씬·초상화·VFX·오디오는 변경하지 않았다.

## 5. 테스트

- 세 JSON UTF-8 파싱 및 루미 경로 연결 직접 검사: PASS
- 계약 `READY`·신규 후보·방어 출전 게이트 직접 검사: PASS
- 루미 런타임 768×768 RGBA, 16셀: PASS
- 중앙값 `125.0px`, 목표 높이 `59.302232px`, 배율 `0.474417853`: PASS
- 발 기준선 spread `0px`, 외곽 침범 `0`, 녹색 잔류 `0`, 고유 셀 `16/16`: PASS
- `V122_P4E_MOON_CONNECT_DIRECT_TEST`: PASS
- `V122_P4E_MOON_CONNECT_GATE_TEST`: PASS
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST`: PASS
- 전체 회귀·전체 플레이·정식 빌드: 사용자 요청 범위가 아니므로 실행하지 않음

## 6. 미해결 및 다음 작업

- 최종 프레임별 크기·발끝 정규화와 실제 전투 화면 확인은 공통 V3 또는 별도 화면 검수 범위에 남아 있다.
- 이번 패킷 외 다른 캐릭터·공통 코드·오디오·VFX·초상화는 변경하지 않았다.
- 다음 작업은 `CURRENT.md`에 새로 잠기는 단일 `NEXT_PACKET_ID` 하나만 따른다. 이번 turn에서는 시작하지 않았다.

## 7. 정책 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 8. 작업 트리와 인계

- 기존 Luna/사용자 변경이 섞인 dirty worktree를 보존했다.
- 기존 변경을 되돌리거나 정리하지 않았다.
- 원격 푸시: `NOT_REQUESTED`
