# v1.2.2 V2-P4C `war_drummer` 런타임 연결 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 기준 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 미커밋)
- 작업 패킷: `V2-P4C-CONNECT-WAR`

## 2. 목표와 완료 조건

두둠 전용 런타임 시트 하나를 `war_drummer` 제품 데이터와 `combat_visual_profiles.json`에 연결하고, 데이터 경로·측정값·렌더 배율·접지 앵커를 직접 검사한다. `1280×720` 대표 화면에서 시트가 기준선에 접지되어 보이는 것을 확인한다.

## 3. 완료 내용

- `war_drummer.sprite`를 두둠 전용 시트로 연결했다.
- `war_drummer` visual profile에 전용 원본·런타임 경로, `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, `median_art_height_px=140.0`을 연결했다.
- `normal_grounded`의 목표 높이 `78.246px`과 측정값으로 렌더 배율 `0.5589`를 계산하고, Unit 발 앵커 위치를 확인했다.
- 공통 최종 정규화는 V3 범위이므로 `NEEDS_NORMALIZATION`으로 유지했다.

## 4. 변경 파일

- `data/monsters.json`
- `data/v122/combat_visual_profiles.json`
- `docs/qa/V122_V2_P4C_WAR_CONNECT_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V2_P4C_WAR_CONNECT_2026-08-04.md`
- `docs/handoff/CURRENT.md`

런타임 PNG와 생성 원본은 직전 `V2-P4C-ASSET-WAR` 패킷에서 완료된 자산이며 이번 패킷에서는 수정하지 않았다.

## 5. 테스트와 화면 확인

- JSON UTF-8 파싱 및 `git diff --check`: PASS
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST`: PASS
- 두둠 전용 Godot 직접 계약 검사: PASS
- 768×768 RGBA 4×4 시트, 외곽 침범 0, 중앙값 140.0px, 발 바닥선 편차 0px: PASS
- OpenGL 호환 `1280×720` 대표 화면에서 두둠 접지 확인: PASS
- 캡처: `C:/Users/blueh/AppData/Local/Temp/v122_p4c_war_connect_1280x720.png`
- 전체 회귀·전체 플레이·정식 빌드: 사용자 요청 범위가 아니므로 실행하지 않음

## 6. 정책 및 미해결

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
- 최종 프레임별 정규화와 동작별 접지 흔들림 판정은 V3에서 처리한다.
- 다음 순서는 `V2-P4D-DISCOVER-MIMIC` 하나만 제안하며 이 패킷에서 시작하지 않는다.

## 7. 작업 트리와 게시 상태

- 기존 Luna 작업과 사용자 변경이 섞인 dirty worktree를 보존했다.
- 이번 패킷의 의도한 제품 변경은 `data/monsters.json` 및 `data/v122/combat_visual_profiles.json`이다.
- 커밋·푸시·PR·릴리스 빌드는 수행하지 않았다.
