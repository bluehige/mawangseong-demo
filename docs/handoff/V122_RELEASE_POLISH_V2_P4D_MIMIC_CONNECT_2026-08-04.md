# v1.2.2 V2-P4D 미미 런타임 연결 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 기준 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 미커밋)
- 작업 패킷: `V2-P4D-CONNECT-MIMIC`
- 커밋/푸시: 이번 turn에서는 수행하지 않음

## 2. 목표와 완료 조건

미미 전용 런타임 시트 1개를 `mimic_porter` 제품 데이터와 `combat_visual_profiles.json`에 연결하고, 데이터 경로·측정값·렌더 배율·접지 기준선을 직접 검사했다.

## 3. 완료 내용

- `mimic_porter.sprite`를 미미 전용 4×4 런타임 시트로 변경했다.
- 미미 visual profile에 전용 원본·런타임 경로, `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, `median_art_height_px=146.5`를 연결했다.
- `normal_grounded` 목표 높이 `78.246px`에 따라 렌더 배율 `0.534102`를 계산했다.
- 런타임 시트의 공통 발 기준선 `y=183`, 외곽 침범 0, 크로마 잔류 0을 확인했다.
- 최종 동작별 정규화 상태는 공통 V3 범위이므로 `NEEDS_NORMALIZATION`으로 유지했다.

## 4. 변경 파일

- `data/monsters.json`
- `data/v122/combat_visual_profiles.json`
- `docs/qa/V122_V2_P4D_MIMIC_CONNECT_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V2_P4D_MIMIC_CONNECT_2026-08-04.md`
- `docs/handoff/CURRENT.md`

런타임 PNG와 생성 원본은 직전 `V2-P4D-ASSET-MIMIC` 패킷에서 완료한 자산이며 이번 패킷에서는 수정하지 않았다.

## 5. 테스트

- JSON UTF-8 파싱 및 미미 경로 연결 직접 검사: PASS
- 미미 런타임 768×768 RGBA, 16셀: PASS
- 중앙값 `146.5px`, 목표 높이 `78.246px`, 배율 `0.534102`: PASS
- 발 기준선 spread `0px`, 외곽 침범 `0`, 녹색 잔류 `0`, 고유 셀 `16/16`: PASS
- `V122_P4D_MIMIC_CONNECT_DIRECT_TEST`: PASS
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST`: PASS
- 전체 회귀·전체 플레이·정식 빌드: 사용자 요청 범위가 아니므로 실행하지 않음

## 6. 미해결 및 다음 작업

- 최종 프레임별 크기·발끝 정규화와 실제 전투 화면 확인은 공통 V3 또는 별도 화면 검수 범위에 남아 있다.
- 이번 패킷 외 다른 캐릭터·공통 코드·오디오·VFX·초상화는 변경하지 않았다.
- 다음 작업은 `CURRENT.md`에 새로 잠기는 `NEXT_PACKET_ID` 하나만 따른다. 이번 turn에서는 시작하지 않았다.

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
