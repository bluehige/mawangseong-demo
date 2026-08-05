# v1.2.2 V2-P4 반복 노출 자산 범위 게이트 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-02
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 작업 미커밋)
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표와 판정

- 요청 사항: 계획표 순서에 따라 V2-P4 DAY6~30 반복 노출 아군·적 자산을 확인하고 정규화한다.
- 판정: `PARTIAL_PASS` / P4 4개 연결 완료, 전체 `SCOPE_BLOCKED`
- 완료 조건 미충족 사유: 후보에 들어온 `kobold_scout`가 방어 전투가 아닌 원정·정찰 지원 전용이며, 원본이 전체 불투명 `1254×1254` 이미지다. 이를 전투 profile로 연결하면 화면에 정사각형 배경이 나타난다.
- 다음 단계: 네 후보의 공유 원본 정체성 문제와 `moon_tracker` 전투 원본 결정을 고정한 뒤 P4를 재개한다.

## 3. 확인한 작업과 제거한 작업

- 확인: `data/monsters.json`, `data/campaign_days.json`, `data/waves.json`, F0-V inventory와 원본 PNG 알파를 교차 대조했다.
- 확인: `kobold_scout`와 같은 원본을 쓰는 `moon_tracker`도 전투 profile에 연결하면 같은 자산 문제가 재현된다.
- 분류: `spore_healer`, `stone_sentinel`, `war_drummer`, `mimic_porter`는 투명한 기존 192×192 전투 원본을 가진 등록 가능 후보다. `moon_tracker`는 전용 전투 원본 결정 전 보류하고, `kobold_scout`는 지원 전용으로 전투 profile에서 제외한다.
- 제거: 이번 세션에서 임시로 추가했던 P4 6개 profile override, 런타임 계약 기대값, 잘못된 recurring ally 비교 도구를 제거했다.
- 부분 구현: `spore_healer`, `stone_sentinel`, `war_drummer`, `mimic_porter`를 투명한 기존 192×192 원본 기반 profile로 등록하고 계약 테스트에 추가했다.
- 비교판: `tools/V122CombatRecurringTransparentAllyPacketCapture.gd/.tscn`에서 네 기록의 `1280×720` 크기·알파 연결을 확인했다. 모리/돌콩은 같은 slime, 두둠/미미는 같은 goblin 원본을 공유하므로 정체성 승인은 하지 않았다.
- 보존: V1-A~D와 V2-P1~P3의 변경, 기존 사용자 변경, 진단용 `tmp/v122_release_polish/v2_p4/` 산출물은 건드리지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd` | 잘못된 P4 후보 기대값 제거 | 완료 |
| `data/v122/combat_visual_profiles.json` | 임시 P4 후보 override 제거 | 완료 |
| `tools/V122CombatRecurringAllyPacketCapture.gd` | 임시 비교 도구 제거 | 완료 |
| `tools/V122CombatRecurringAllyPacketCapture.tscn` | 임시 비교 장면 제거 | 완료 |
| `tools/V122CombatRecurringTransparentAllyPacketCapture.gd` | 투명 계약 아군 4개 비교판 | 완료 |
| `tools/V122CombatRecurringTransparentAllyPacketCapture.tscn` | 투명 계약 아군 비교 장면 | 완료 |
| `data/v122/combat_visual_profiles.json` | 투명 계약 아군 4개 profile 등록 | 완료 |
| `docs/qa/V122_V2_P4_RECURRING_ASSET_SCOPE_GATE_2026-08-02.md` | 범위 충돌과 재발 방지 규칙 기록 | 완료 |

## 5. 그래픽·데이터·스토리 변경

- 새 그래픽 생성: 없음
- 런타임 그래픽 연결: 투명 원본 4개만 profile과 맵 비례 배율을 연결했다. 코볼트·문 트래커는 연결하지 않았다.
- 데이터·밸런스: wave, 적 수치, roster, 원정 규칙을 변경하지 않았다.
- 핵심 원인: 지원 전용 `kobold_scout`를 전투 roster 후보로 취급한 선택 오류와, opaque 원본의 알파 검사를 연결 전에 하지 않은 절차 누락이다.
- 남은 시각 문제: 서로 다른 계약 아군 4개가 slime/goblin 원본을 공유한다. 새 원본 생성·대체는 이번 크기 패킷 밖이다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | PNG 알파·크기 검사 | `kobold_scout` 전체 불투명 `1254×1254` 확인 | 원본 PNG |
| 2 | `V122CombatVisualRuntimeProfileContractTest.tscn` | PASS | 직접 계약 테스트 |
| 3 | `V122CombatVisualProfileContractTest.tscn` | PASS | schema·registry 계약 |
| 4 | P4 scope 검사 | `P4_SCOPE_SAFE: PASS` | opaque 후보 profile 부재·투명 4개 profile·비교 도구 |
| 5 | `V122CombatRecurringTransparentAllyPacketCapture.tscn` 비헤드리스 OpenGL | PASS, 4 records, `1280×720` | `tmp/v122_release_polish/v2_p4/` |
| 6 | P4 전체 후보 비교판 | 기술적 PASS였으나 opaque 지원 자산 때문에 시각 판정 거부 | `tmp/v122_release_polish/v2_p4/` |
| 7 | 전체 회귀·전체 플레이·빌드 | `NOT_REQUESTED` | 사용자 요청 범위 밖 |

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS` (범위 게이트 문서화와 잘못된 연결 제거만 판정)

## Related tests

P4 후보 정리 후 P1~P3와 네 투명 계약 아군의 runtime profile 계약, schema 계약, `1280×720` 비교판을 PASS했다. 이 PASS는 크기·알파 연결만 뜻하며 공유 원본 정체성 승인은 아니다.

## UI check

부분 P4 비교판 `tmp/v122_release_polish/v2_p4/v2_p4_transparent_contract_ally_contact_sheet_1280x720.png`은 4개 기록·크기·알파 계약을 보여준다. 모리/돌콩, 두둠/미미의 공유 실루엣과 opaque 코볼트·문 트래커 전체 후보판은 승인하지 않는다.

## Unresolved issues

P4는 부분 완료(4/6 후보)다. 공유 원본 정체성 결정과 `moon_tracker` 전투 원본 결정 전에는 V2-P5로 넘어가지 않는다.

## 7. 작업 트리 상태

- 미커밋 파일: 기존 사용자 변경, V1-A~D/V2-P1~P3 변경, 이번 범위 게이트 문서와 정리 변경
- 스테이징: 하지 않음
- 커밋·푸시: 하지 않음
- 빌드 산출물: 생성하지 않음
