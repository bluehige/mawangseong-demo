# v1.2.6 정식 출시 후보 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-20
- 목표 버전: `1.2.6`
- 출시 후보 브랜치: `codex/v126-release-candidate`
- 원격 기준: `origin/main@ce601b81b8f283543a04867e11632d0e87beea3c`
- 제품 기준 체인: `10817c5c37f49763e086e75eac4e90d67a4ee45b → e8aca24c435fc64d3ec6a6079623185ed0232010 → 608a3da47dcfdb0e1bb259a96130e214d9c55e4a → 75a4115b8337569a83db5544076f9c2ca9d55941`
- 원격 푸시·PR·태그·Release: 아직 수행하지 않음

## 2. 사용자 지시와 범위

- 현재 v1.2.6 수정 사항을 공통 런타임에 적용하고 정식 버전으로 승격한 뒤 `main`에 merge commit으로 반영한다.
- Windows PC가 품질 기준이며 Web·모바일은 호환성 검증 범위다.
- 기존 `v1.2.5` 태그와 Release는 보존한다.
- 정식 승격 전 P1/P2 0건, 전체 자동 검증, 정식 Windows 빌드·manifest·부팅을 확인한다.

## 3. 제품 변경 요약

- 명령 수락·거부를 대상 근처 효과, 비모달 알림과 구분 효과음으로 표시했다.
- 강제 명령의 0.3초 반응 계약과 명령 충돌 전환 안내를 연결했다.
- 도둑 사냥꾼·금고 수호자·역할 AI의 위협 우선순위를 보강했다.
- 방별 지침을 자율 역할 AI보다 먼저 처리하고 반대 전선으로 전역 확산되지 않게 했다.
- 입구 봉쇄의 단일 applicability 판정을 행동과 HUD가 공유하게 해 슬라임·곱·임프·후반 동료의 표시/행동을 일치시켰다.
- 건설 슬롯 발견, 시설 효과·추천, 미리보기·취소·확정 흐름을 공통화했다.
- 방 이름표·지침 배지를 전면 소품보다 높은 월드 오버레이로 이동했다.
- 모바일 회귀를 확정된 핵심 명령 3개 정책에 맞췄다.

## 4. 사용자 피드백 상태

| ID | 관찰 | 상태 | 근거 |
|---|---|---|---|
| `FDB-20260820-001` | 몬스터 지능이 이상함 | `FIXED → RETESTED` | 역할 AI·위협 우선순위 및 방 지침 선행 처리 |
| `FDB-20260820-002` | 방별 지침 적용 여부를 알 수 없음 | `FIXED → RETESTED` | 공통 applicability, HUD 적용 지침·현재 행동, 로컬/원격 행렬 |
| `FDB-20260820-003` | 보물실 옆 건설이 어렵고 불편함 | `FIXED → RETESTED` | 빈 슬롯 배지, 문맥 시설 목록, 전역 미리보기·확정 흐름 |
| `FDB-20260820-004` | 보물실 등 방 이름이 그림에 가림 | `FIXED → RETESTED` | z=60 월드 오버레이 이름표·지침 배지 |

사용자와 지인의 새 플레이테스트는 완성품 전달 뒤 별도 피드백 주기로 접수한다.

## 5. 검증 현황

| 검증 | SHA | 결과 |
|---|---|---|
| 방 지침 핵심 4종·원격 전선·HUD 행동 일치 | `75a4115b8337569a83db5544076f9c2ca9d55941` | PASS |
| Stage 03 `slot_02`·Stage 04 `slot_03` 미리보기/취소 | `75a4115b8337569a83db5544076f9c2ca9d55941` | PASS |
| 모바일 핵심 명령 3개 터치 흐름 | `75a4115b8337569a83db5544076f9c2ca9d55941` | PASS, 84 assertions |
| Core Verification Quick | `75a4115b8337569a83db5544076f9c2ca9d55941` | 143/143 PASS, `source_tree_clean=true`, Godot 4.5.2 |
| Core Verification Full | 최종 후보 SHA | PENDING |
| Windows Steam 정식 export·manifest·부팅 | 최종 `main` merge SHA | PENDING |
| Web release manifest·부팅 | 최종 `main` merge SHA | PENDING |

Godot root certificate store 경고는 반복되지만 대상 테스트 결과와 파일 출력에는 영향을 주지 않았다. 테스트 AppData는 제품 저장과 분리된 작업공간 경로에 격리했다.

## 6. 현재 판정과 다음 순서

- P1: 0
- P2: 0
- P3: 정식 Full·빌드 증빙이 아직 남음
- Review task ID: `V126-RELEASE-CANDIDATE-GATE`
- Reviewed product SHA: `75a4115b8337569a83db5544076f9c2ca9d55941`
- Final review result: `QUICK_PASS / FULL_PENDING`

다음 순서:

1. 릴리스 문서·CURRENT를 커밋한다.
2. 후보 최종 SHA에서 Full 전체 검증과 Stage 01~04 대표 화면을 확인한다.
3. 후보를 원격에 푸시하고 `main` PR을 merge commit으로 병합한다.
4. 병합된 `main` SHA에서 Full을 재확인한다.
5. 같은 SHA로 Windows Steam 정식 빌드·manifest·10초 부팅을 검증한다.
6. 태그·Web·GitHub Release·Pages는 사용자 지시와 저장소 출시 절차에 따라 진행한다.
