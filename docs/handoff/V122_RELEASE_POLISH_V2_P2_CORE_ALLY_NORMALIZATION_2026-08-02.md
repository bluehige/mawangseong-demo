# v1.2.2 V2-P2 핵심 아군·DAY12 1차 승급 정규화 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-02
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 작업 미커밋)
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 계획표 순서에 따라 V2-P2의 핵심 아군 및 첫 승급 visual profile을 연결한다.
- 완료 조건: 6개 profile의 경로·중앙값·배율·동작 모드가 런타임과 계약 테스트에 연결되고, `1280×720` 실제 화면에서 비교된다.
- 범위에서 제외한 사항: 새 이미지 생성·재저장, 일반 적·도둑, V3 접지, V4 벽/UI, 오디오·VFX, 전체 회귀, 빌드·커밋·푸시.

## 3. 완료한 작업

- 구현: DAY1~5 핵심 아군 `slime·goblin·imp`와 DAY12 첫 승급 `slime_gate_bulwark·goblin_ambush_captain·imp_flame_adept`를 `combat_visual_profiles.json`에 등록했다. 등록된 종족만 정확한 승급 sprite path 매칭을 사용하도록 `DataRegistry`를 보강했다.
- 스토리 및 데이터: DAY1~5 parity fixture와 DAY12 첫 승급 규칙에 맞춰 대상 6개를 고정했다. 기존 source/runtime 이미지와 192×192 프레임은 변경하지 않았다.
- 밸런스: 전투 수치·웨이브·승급 조건은 변경하지 않았다. 화면 크기만 F0 중앙값·size class 비율로 계산했다.
- UI/UX: 6개 비교용 비헤드리스 contact sheet를 추가하고 profile·동작·상태·측정값을 셀에 표시했다.
- 저장 및 호환성: 저장 형식과 저장 마이그레이션은 변경하지 않았다. 미등록 roster가 기본 sprite를 재사용하는 fallback을 별도 계약으로 보호했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v122/combat_visual_profiles.json` | 핵심 아군·승급 6개 profile과 측정값 등록 | 완료/검수 통과 |
| `scripts/core/DataRegistry.gd` | 등록 종족 한정 sprite path 승급 선택 및 inventory 상태 전달 | 완료/검수 통과 |
| `scripts/units/Unit.gd` | stats sprite 경로를 profile lookup에 전달 | 완료/검수 통과 |
| `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd` | 6개 아군·6개 적·fallback 런타임 계약 | 완료/검수 통과 |
| `tools/V122CombatAllyPacketCapture.gd` | 6개 비교 화면 생성 도구 | 완료/검수 통과 |
| `tools/V122CombatAllyPacketCapture.tscn` | 비교 화면 장면 | 완료/검수 통과 |
| `docs/qa/V122_V2_P2_CORE_ALLY_NORMALIZATION_2026-08-02.md` | QA 근거와 미해결 범위 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오. 기존 승인·기록 자산만 연결했다.
- 생성 모델: 해당 없음
- 생성 원본 경로: 기존 승급 source 경로 3개를 profile에 연결 (`assets/source/imagegen/evolutions/`)
- `SOURCE.md` 경로: 기존 승급 원본 문서 3개를 그대로 사용
- 런타임 최종 자산 경로: 기존 `assets/sprites/monsters/monster_*_idle_down_00.png` 6개
- 프롬프트/후처리/크롭/알파 처리 요약: 이번 세션에는 재생성·재저장·크롭을 하지 않고 프레임별 알파 bbox 중앙값만 측정·기록했다.
- 게임 연결 및 실제 렌더 확인 결과: 비헤드리스 OpenGL `1280×720` 6개 contact sheet PASS

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122CombatVisualProfileContractTest.tscn` | PASS | Godot headless 로그 |
| 2 | `V122CombatVisualRuntimeProfileContractTest.tscn` | PASS | Godot headless 로그 |
| 3 | `V122CombatAllyPacketCapture.tscn` 비헤드리스 OpenGL | PASS, 6 records, 1280×720 | `tmp/v122_release_polish/v2_p2/` |
| 4 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 밖 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|---|
| 1 | 기본 작업 검수 | `N/A` | `N/A` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 관련 계약 테스트 | NOT_REQUESTED |

- 남은 P1/P2 지적: 없음(이번 패킷 범위)
- 실행하지 못한 필수 검수와 이유: 전체 회귀·전체 플레이·빌드는 요청되지 않아 실행하지 않음
- PASS 이후 기능·데이터·자산 변경 여부: 문서 기록 전까지 없음

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 기본 아군 3종은 `NEEDS_NORMALIZATION` 상태를 운반할 뿐 최종 `NORMALIZED_PASS`로 확정하지 않았다.
- V3에서 발·그림자·down 앵커를 검증하기 전까지 승급과 기본 종족의 실제 접지감은 출시 승인 대상이 아니다.
- 전체 활성 roster 누락 0은 V2-P3 이후에 판정한다.
- 혼합 작업 트리의 기존 미커밋 변경은 건드리지 않았다.

## 8. 다음 작업 순서

1. V2-P3에서 DAY1~5 일반 적과 도둑 6개만 동일한 측정·runtime 계약으로 연결한다.
2. V2-P3 관련 테스트와 `1280×720` 비교판을 실행하고 이 핸드오프의 범위 밖 문제를 섞지 않는다.
3. V2 전체 roster가 끝난 뒤 V3 공통 ground root·body·발 앵커를 시작한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`, 기존 변경 다수와 이번 패킷 변경이 함께 존재
- 미커밋 파일: 위 변경 파일 및 사용자 기존 변경
- 의도하지 않은 기존 변경: 복구·삭제하지 않음
- 스태시 또는 별도 작업공간: 사용하지 않음
- 빌드/캡처 산출물 위치: 캡처는 `tmp/v122_release_polish/v2_p2/`에만 생성되며 소스 브랜치 커밋 대상이 아님

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [ ] `docs/handoff/CURRENT.md` 갱신 (다음 문서 패치에서 완료)
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록

## Related tests

`V122CombatVisualProfileContractTest.tscn`, `V122CombatVisualRuntimeProfileContractTest.tscn` 모두 PASS.

## UI check

비헤드리스 OpenGL `V122CombatAllyPacketCapture.tscn`가 6개 기록과 `1280×720` PNG를 PASS했다.

## Unresolved issues

V2-P3 일반 적·도둑, V3 접지, V4 가림·UI anchor, 전체 회귀·빌드는 남아 있다.
