# V130R Step8B 합법 집중 배치와 적 경로 분산

## 1. 메타데이터

- 작성일: 2026-10-17 KST. WORKSTREAM_ID: V130R_STEP8B_SPREAD.
- 목표 버전: 1.3.0. 버전·manifest 변경 없음.
- 작업 브랜치: `codex/v130r-defense-layout`.
- 기준 브랜치 및 SHA: 사용자 지정 0105 `414c8881b7f7664563e8843f29e8c4adc8286602`.
- 마지막 구현 커밋 SHA / Reviewed SHA: `cb6841452e315d25831959f600ea9ff0d0f8b4d0`. 이후에는 `docs/handoff/`만 변경한다. 최종 문서 커밋 SHA는 Git 이력으로 확인한다.
- 원격 푸시 여부: 없음. PR·main·태그·Steam 조치 없음.
- 권위 제한: 로컬 main 없음. 캐시 origin/main `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 AGENTS/CURRENT를 읽었다. 원격 최신성 미확인. 원격 조회/fetch 미실행.

## 2. 이번 세션 목표

사용자 10/17 11:59 결정(가)에 따라 실제 정원·고유 수비 칸으로 집중3종을 재현하고, 추천에 유리한 곡선을 유지하면서 쏠림을 줄인다. DAY20·24·27·30 각 배치10회 재현 후 필요한 적 목표·경로 분산(a)부터 적용했다. 최종 DAY15~30 추천/합법 집중3종/정원초과 참고를 비교한다. DAY29 준비일·전투 없음은 유지한다.

0104와 같은 E 지도·시설 Lv1 조건이다. 강화·이동·증설 이후의 최대 정원은 포함하지 않는다. 강화 포함 여부를 사용자에게 질문했으나 응답이 없어 동일 기준으로 진행했다. 전체 회귀·전체 플레이·export·출시는 범위 밖이다.

## 3. 완료한 작업

- 구현: 조사관·정찰병에만 선택적 `waypoint_room_id`를 허용하고 옆길 도착 후 원래 목표로 복귀한다. 미설정 시 기존 경로와 난수 소비를 유지한다. 공병·도둑의 전문 목표와 도발 개입을 보존한다.
- 합법 배치: 실제 `Members.put`/`sanitize`와 식량 한도를 검증했다. 병영4+결계핵1+옥좌4=9명, 최종선 옥좌4+금고2=6명, 1차선 감시탑3+미끼2=5명. 남는 병력은 대기하며 칸·정원 중복 없음. 정원초과는0104와 같은 불법 참고 시험으로만 분리했다.
- 최초160회: DAY27 집중 평균HP43.013% > 추천41.08%, DAY30 집중41.707% > 추천38.68%를 재현했다. 집중 승률은 낮아도 평균HP 역전이 있어 분산을 적용했다. 나머지 날짜의 추가 역전도 함께 수정했다.
- 최종 데이터: DAY17 investigator 행4: waypoint_room_id=bait_treasure; DAY19 investigator 행3: waypoint_room_id=watchtower; DAY21 investigator 행6: waypoint_room_id=recovery_nest; DAY26 engineer 행5: target_room_id=barracks; DAY27 engineer 행6: target_room_id=recovery_nest; DAY28 investigator 행3: waypoint_room_id=watchtower; DAY28 engineer 행5: target_room_id=ward_core; DAY30 engineer 행7: target_room_id=watchtower.
- 최종750회: 모든 전투일의 추천 승률·평균HP가 합법3종 이상이며0104 목표 곡선 이탈0건. 미변경 날짜의0104 추천/정원초과 핵심 필드 160행 일치. 후보는 tmp에 보존하고 최종 웨이브와 일치하는 행만 표에 채택했다.
- 스토리/UI: DAY29·스토리·버전 변경 없음. 과밀 페널티(b)·아이콘·새 범위 공격(c) 미적용. 시험용 검수 캡션 외 제품 UI 변경 없음.
- 저장: 형식·사용자 세이브 변경 없음. 격리 APPDATA/LOCALAPPDATA 사용, 캠페인 정산·저장 미실행.
- 시설 손실은 기존 공병의 약10초 일시 무력화이며 영구 건물 파괴가 아니다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/waves.json` | 적 목표·경유 분산 | 완료 |
| `scripts/game/ApprovedBattleController.gd` | 조사관·정찰병의 경유 후 원래 목표 복귀 | 완료 |
| `tools/run_v130r_step8b.ps1` | Godot 한 개, 격리 저장 경로와 종료 관리 | 완료 |
| `tools/tests/V130RStep8BSpreadTest.gd` | 합법 배치·60Hz 전투·직접 경로·DAY29·캡처 시험 | 완료 |
| `tools/tests/V130RStep8BSpreadTest.tscn` | 전용 시험 씬 | 완료 |
| `tools/tests/V130RStep8BSpreadSimulation.gd` | 실제 길·시설 무력화 관찰 | 완료 |
| `tools/tests/v130r_step8b_report.py` | 원시 증거 병합·목표 판정·UTF-8 보고서 | 완료 |
| `_mockup/game_step8b_spread/result_table.md` | DAY15~30 다섯 배치 비교표 | 완료 |
| `docs/handoff/V130R_STEP8B_SPREAD_2026-10-17.md` | 세션 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 현재 상태 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

신규 생성 자산·image_gen·외부 서비스 호출 없음. PNG2장은 실제 렌더이며 `_mockup/game_step8b_spread/split_route_day24.png`, `crowded_fail_day27.png`에 저장했다.1920×1080 원본과1000×563 축소본을 보존하고 한 장씩 확인했다. b 미적용으로 `overcrowd_icon.png`는 만들지 않았다. PNG·원시 JSON·로그는 로컬 산출물로 소스 커밋에서 제외한다. 바탕화면의 한글 `_mockup` 폴더가 존재하면 Python UTF-8로 복사한다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 0105 네 날짜×네 배치×10회 | 160회, 추천40회0104 일치 | `tmp/v130r_step8b/reproduction.json` |
| 2 | 화면 효과 생략 경로 대응16회 | 실제 계산15필드 일치 | `fast_parity_summary.json` |
| 3 | 새 옵션 미설정 경로 대응16회 | 0105 계산15필드 일치 | `kernel_parity_summary.json` |
| 4 | 실제 옆길12종 도착·복귀/잘못된 목표/도발 | 직접78검사 실패0 | `spread_route_checks.json` |
| 5 | 최종15전투일×5배치×10회,60Hz | 750회, 우위 역전0·곡선 이탈0·시간초과0 | `_mockup/game_step8b_spread/trial_rows.json`, `result_table.md` |
| 6 | 75개Lv1 배치와 DAY29 시작 차단 | 2078검사 실패0, DAY29 관련7항목 포함 | `fixture_audit_checks.json`, `day29_preparation_checks.json` |
| 7 | 실제 렌더와 상태 증거 | DAY24 옆길 분기, DAY27 회복 둥지 무력화 | PNG2장과 `_state.json` |
| 8 | 시험 종료 리소스 정리 수정 재실행 | 20행 전부 동일, 종료 오류0 | `cleanup_summary.json` |
| 9 | 기존 혼합 변경 SHA256 보존 | 1414파일 바이트 일치 | `tmp/v130r_step8b/preservation.json` |
| 10 | Python 컴파일·PowerShell 파싱·JSON·스테이징 diff | 통과 | 세션 명령 결과 |
| 11 | Godot 실행 수 | 동시 최대1, 종료 시0 | 실행 전/후 프로세스 확인 |
| 12 | 전체 회귀·전체 플레이·성능·export·검수 에이전트 | NOT_REQUESTED / 미실행 | 요청 범위 밖 |

실행: `powershell -NoProfile -File tools/run_v130r_step8b.ps1`, 캡처는 `-Capture`. 설정/로그는 `tmp/v130r_step8b/*_config.json`, `*.log`, `*.err.log`에 보존했다. 보고서 재현: `python -X utf8 tools/tests/v130r_step8b_report.py --merge reproduction.json matrix_candidates.json watchtower_trials.json waypoint_watch.json mixed_routes.json defense_objectives.json day28_flank_core.json completion.json --name final_rows`, 이후 `python -X utf8 tools/tests/v130r_step8b_report.py final_rows.json`.

시험은 실제 전투 경로를1/60초씩 계산한다. 빠른 경로는 피해 숫자 Label과 접촉 장식만 생략하며 투사체 도착·피해 콜백·길·스킬은 유지한다. 캡처에는 모든 효과를 표시했다. 폐기 후보의 종료 리소스 잔존은 시험 종료 정리로 해결하고20회 결과 불변을 확인했다. 검수 에이전트 회차 없음. 요청 범위의 미실행 필수 검사는 없다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: cb6841452e315d25831959f600ea9ff0d0f8b4d0
- Review range: 414c8881b7f7664563e8843f29e8c4adc8286602..cb6841452e315d25831959f600ea9ff0d0f8b4d0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

시설 강화 시 정원이 증가하므로9/6/5명은 기본Lv1에서만 최대다. 강화 이후는 별도 조건 합의와 시험이 필요하다. 각10회는 고정 대응 표본이며 실제 캠페인 확률로 일반화하지 않는다. 성장·소유·경제는0104와 동일: Lv=1+floor((DAY−합류DAY)/3), 기본4종과 모리/돌콩 계약DAY1, 신규join_day, 전문화·기억·승급·수동스킬·이월부상 없음, 옥좌1500/금1200/마나600. 원격 최신성과 main 권위 미확정.

## 8. 다음 작업 순서

1. 두 캡처와 결과 표의 **사용자 확인 대기**.
2. 강화 조건까지 요청하면 같은 강화·예산으로 추천/집중을 추가 비교한다. 이번 결과를 강화 상태에 자동 적용하지 않는다.
3. 별도 지시 전 push·main 병합·태그·Steam 조치 없음.

## 9. 작업 트리 상태

브랜치 `codex/v130r-defense-layout`. 기존 혼합 변경 1414개와 다른 작업의 미추적 파일을 보존한다. 소스/표8경로와 인계2경로만 명시적으로 커밋한다. `git add -A`·스태시·reset·브랜치 전환 없음. 원격 조치0건. 로컬 산출물: `_mockup/game_step8b_spread/`, `tmp/v130r_step8b/`.

## 10. 종료 체크리스트

- [x] Lv1 시험 범위와 요구사항 대조
- [x] 관련 시험 통과와 전체 검수 미요청 구분
- [x] 최종 검수 SHA·정책 필드 기록
- [x] 신규 자산 없음·실제 렌더 두 장 확인
- [x] CURRENT 갱신·의도한 파일만 로컬 커밋
- [x] 사용자 세이브 보존·Godot 종료·원격 조치 없음
