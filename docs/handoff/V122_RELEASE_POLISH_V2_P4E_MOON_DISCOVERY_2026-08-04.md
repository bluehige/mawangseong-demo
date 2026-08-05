# v1.2.2 V2-P4E 루미 전투 자산 발견 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 기준 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 패킷: `V2-P4E-DISCOVER-MOON`
- 커밋/푸시: 이번 turn에서는 수행하지 않음

## 2. 목표와 완료 조건

루미(`moon_tracker`)의 현재 전투 자산과 후보를 읽기 전용으로 조사하고, 전용 자산 생성이 필요한지 판정했다. 제품 데이터·profile·자산·공통 코드는 변경하지 않았다.

## 3. 발견 결과

- `moon_tracker.sprite`는 `kobold_scout`와 같은 `monster_kobold_scout_idle_down_00.png`를 사용한다.
- 해당 PNG는 RGB 1254×1254 전체 불투명 이미지이며 `portrait_rolo.png`와 SHA가 동일하다.
- `mon_contract_lumi`와 `CHR_LUMI`의 계약·캐릭터 참조는 정상이다.
- `data/update2_contracts.json`의 `BLOCKED_WRONG_IDENTITY_SOURCE` 상태와 방어 출전 차단 테스트는 정상이다.
- `combat_visual_profiles.json`에 루미 전용 override가 없어 연결 전 상태다.
- 인간 현상금 추적자, 인간 왕실 척후, 문박쥐 지역 자산은 루미 전투 자산으로 재사용할 수 없다.
- 저장소에 루미 전용 전투 원본·시트·SOURCE.md는 없다.

## 4. 변경 파일

- `docs/qa/V122_V2_P4E_MOON_DISCOVERY_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V2_P4E_MOON_DISCOVERY_2026-08-04.md`
- `docs/handoff/CURRENT.md`

기존 제품 데이터·자산·코드 파일은 이번 패킷에서 수정하지 않았다.

## 5. 테스트

- JSON 참조·공유 자산 형식·해시·전용 파일 존재 여부 직접 검사: `V122_P4E_MOON_DISCOVERY_DIRECT_TEST: PASS`
- 루미 방어 출전 차단 Godot 검사: `V122_MOON_TRACKER_COMBAT_ASSET_GATE_TEST: PASS`
- 전체 회귀·전체 플레이·정식 빌드: 사용자 요청 범위가 아니므로 실행하지 않음

## 6. 미해결 및 다음 작업

- 루미 전용 전투 시트와 출처 기록이 아직 없다.
- 다음 패킷은 `V2-P4E-ASSET-MOON` 하나로 잠근다.
- 자산 생성 전에는 `data/monsters.json`, `data/update2_contracts.json`, `data/v122/combat_visual_profiles.json`을 수정하지 않는다.

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
