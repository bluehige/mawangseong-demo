# v1.2.2 V2-P4C `war_drummer` 원본 발견 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음
- 작업 패킷: `V2-P4C-DISCOVER-WAR`

## 2. 이번 세션 목표

- 요청 사항: 두둠(`war_drummer`)의 현재 공유 전투 그림과 전용 원본 후보 충돌을 읽기 전용으로 조사한다.
- 완료 조건: 세 데이터셋·visual profile의 참조 일치, 현재 파일 형식·해시, 전용 후보 존재 여부, 옛 계획 경로와 진화 후보의 소유권 판정.
- 범위에서 제외한 사항: 제품 코드·데이터·씬·전투 연결, 이미지 생성·후처리, 초상화·VFX·오디오, UI·실플레이, 다음 패킷 실행.

## 3. 완료한 작업

- `war_drummer.sprite`, `unit_overrides.war_drummer.source_path/runtime_path`가 고블린 idle 하나를 공유함을 확인했다.
- `CHR_DUDUM`의 초상화는 `portrait_gob.png` fallback일 뿐 전투 자산이 아님을 분리했다.
- 옛 설계 경로 `monster_skeleton_drummer_down_01.png`와 `assets/source/imagegen/dudum/SOURCE.md`가 현재 파일로 존재하지 않음을 확인했다.
- 매복대장·금고지기 고블린 진화 시트는 각각 곱 진화 전용 출처 기록이 있어 두둠 후보에서 제외했다.
- 결과를 `DISCOVERY_PASS_WITH_ASSET_REQUIRED`로 닫고 다음 패킷을 `V2-P4C-ASSET-WAR` 하나로 제안했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_V2_P4C_WAR_DISCOVERY_2026-08-04.md` | 두둠 원본·후보·형식 교차 검사 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_V2_P4C_WAR_DISCOVERY_2026-08-04.md` | 패킷 종료 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 패킷 잠금 갱신 | 완료 |

제품 데이터와 자산은 이번 발견 패킷에서 변경하지 않았다.

## 5. 테스트 및 UI 확인

| 검수 | 결과 |
|---|---|
| JSON 파싱·`war_drummer`/계약/초상 fallback 경로 교차 | PASS |
| 공유 고블린 파일 존재·192×192 RGBA·SHA-256·알파 bbox | PASS |
| 옛 두둠 계획 경로 및 `dudum`/`drummer` 전용 토큰 검색 | PASS — 전용 파일 0개 |
| 고블린 진화 후보의 출처·런타임 소유권 분류 | PASS — 두둠 후보에서 제외 |
| 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED |
| UI/오디오 확인 | NOT_REQUESTED — 읽기 전용 발견 패킷 |

### 검수 에이전트 반복 기록

- 검수 에이전트는 요청되지 않았고 실행하지 않았다.
- 남은 P1/P2 지적: 두둠 전용 기본 전투 자산 부재는 다음 자산 패킷의 해결 대상이다.
- 실행하지 못한 필수 검수와 이유: 제품·런타임 변경이 없는 발견 패킷이므로 전체 회귀·실제 화면을 실행하지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 미해결 항목과 다음 순서

- 공유 고블린 그림은 두둠의 전투 정체성으로 승인하지 않는다.
- 현재 다음 패킷은 `V2-P4C-ASSET-WAR` 하나만 제안·잠금한다. 생성 원본·출처 기록·16프레임 런타임 시트만 다루며 연결은 그 다음 별도 패킷으로 둔다.
- 이 패킷에서는 커밋·푸시·빌드를 수행하지 않았다.

## 7. 작업 트리 상태

- 기존 Luna 작업과 여러 문서가 섞인 dirty worktree를 보존했다.
- 이번 패킷의 의도한 변경은 QA·핸드오프·`CURRENT.md` 세 문서뿐이다.
- 원격 푸시 및 PR/태그: 없음.

Related tests: JSON·계약/초상 fallback·공유 파일 SHA/형식·옛 계획 경로·전용 토큰 검색 PASS
UI check: 읽기 전용 발견 패킷이라 실행하지 않음
Unresolved issues: 두둠 전용 기본 전투 원본이 없어 `V2-P4C-ASSET-WAR` 전에는 전투 정체성을 승인할 수 없음
