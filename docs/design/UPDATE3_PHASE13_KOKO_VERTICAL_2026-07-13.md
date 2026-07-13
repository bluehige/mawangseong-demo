# 3차 업데이트 Phase 13 완료 기록 — 코코 전투 수직 구현

## 완료 범위

- `graveyard_hound` 코코의 캐릭터·개체·스킬·특화·유대 placeholder를 실전 카탈로그에 연결했다.
- 냄새 고정은 7초 동안 대상 우선 공격, 추적 이동 +25%, 해당 대상 기본 공격 피해 +10%를 적용한다.
- 집 지키는 짖음은 반경 145 일반 적 최대 2명 도발, 보스 1.5초 공격 우선도, 보호막 18을 적용한다.
- 표식 종료·대상 처치·이탈 뒤 최대 4초 동안 배치 방 복귀 이동 +35%, 받는 피해 -8%를 적용한다.
- AI 우선순위는 훔친 도둑, 배치 방 침입, 왕좌 침입, 기존 표식, 공병·위험 후열 순으로 동작한다.
- 새 AI는 종족 ID 직접 분기 대신 몬스터 데이터의 `behavior_handler`로 연결했다.

## 완료 조건 판정

- 공병 표적 기준 처치 시간 18% 이상 단축: PASS
- 방어력 12 전열의 추적 이득 8% 미만 제한: PASS
- 반복 복귀 갱신 시 경로 증식·루프 없음: PASS
- 도둑 처리 후 배치 방 복귀 및 일반 적 재탐색: PASS
- 멀리 추격하면 배치 방이 실제로 비는 전술 대가 유지: PASS

## 검증 결과

- `KokoPhase13Test`: 33/33 PASS
- `Update3DataContractTest`: 17/17 PASS
- `RunCoreVerification.ps1 -Mode Quick`: 26/26 PASS
- 최신 보고서: `tmp/core_verification/latest.json`, `tmp/core_verification/latest.md`
