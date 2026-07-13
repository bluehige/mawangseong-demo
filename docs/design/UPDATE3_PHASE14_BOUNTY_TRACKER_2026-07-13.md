# 3차 업데이트 Phase 14 완료 기록 — 현상금 추적자

## 완료 범위

- `bounty_tracker` 적·캐릭터·현상금 표적 스킬을 실전 카탈로그에 연결했다.
- 기존 전투 전체 누적 기여와 별도로 발생 시각이 포함된 최근 20초 기여 이벤트를 기록한다.
- 전투 시작 5초 뒤 첫 평가하고, 표적 성공 뒤 12초마다 재평가한다.
- 생존 몬스터 중 기여 1위를 6초 표적화하며 동률일 때만 계승 몬스터를 우선한다.
- 표적 대상 위에 현상금 다이아·문구를 그리고 선택 유닛 HUD에 남은 시간을 표시한다.
- 추적자가 표적에게 주는 피해만 최대 15% 증가하며 푸딩·코코 도발은 일반 공격 대상을 바꾼다.

## 완료 조건 판정

- 최근 20초 기여 1위 정확 선택: PASS
- 전투 시작 직후 5초 대기: PASS
- 푸딩·코코 도발 대상 변경: PASS
- 표적 피해 증가 15% 상한: PASS
- 계승 정보가 없는 프로필과 계승 동률 우선 모두 정상: PASS
- 기존 누적 기여·성장 계산 회귀 없음: PASS

## 검증 결과

- `BountyTrackerPhase14Test`: 27/27 PASS
- `Update3DataContractTest`: 17/17 PASS
- `RunCoreVerification.ps1 -Mode Quick`: 27/27 PASS
- 최신 보고서: `tmp/core_verification/latest.json`, `tmp/core_verification/latest.md`
