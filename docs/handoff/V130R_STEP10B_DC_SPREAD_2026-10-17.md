# V130R Step10B — 유료 추천 건설·D/C 경유 비교 / PARTIAL · 사용자 확인 대기


## 1. 메타데이터

- 작성일: 요청 기준 2026-10-17, 실제 작업 2026-10-18 KST.
- WORKSTREAM_ID: V130R_STEP10B_DC_SPREAD
- 목표 버전: 1.3.0, 지도 개편. 0104/0106 곡선과 10/17 11:59 사용자 결정 (가), 한 건물 쏠림 방지 유지.
- 작업 브랜치: `codex/v130r-defense-layout`.
- 기준 브랜치 및 SHA: 같은 브랜치의 0113b 위 `18931a116c5562c2bddd12be08da76882e6c1921`.
- 마지막 제품·검증 커밋 SHA: `e99004132bc6753e79d9aed429d5d57d66e0e8a1`. 종료 인계는 이후 문서 전용 커밋으로 기록한다.
- 권위 제한: 로컬 `main` ref가 없다. 캐시 `origin/main`은 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`. 캐시 정책·CURRENT를 읽었지만 원격 최신 권위를 확정하지 않았다. 사용자가 제공한 정책과 현재 요청에 따라 이 브랜치만 작업했다.
- 원격 푸시 여부: 없음. fetch·push·PR·main 변경·태그·Steam 작업 없음. 영어 로컬 커밋만 사용.
- 관련 PR 또는 태그: 없음. `v1.2.5`는 읽기 확인만 했고 변경하지 않았다.

## 2. 이번 세션 목표

- 0108b의 기존 E 건물 8개 이전 상태를, 실제 비용을 지불한 D 10개 / C 12개 상태로 보정하고 네 배치를 같은 소유·예산에서 비교한다.
- 정산 보정 뒤에도 집중①이 유리한 날짜에만 적 목표·경유를 최소 조정한다. 몬스터·건물 수치, 사용자 저장 상태, DAY29 무전투를 유지한다.
- DAY20~30 추천/집중①②③의 승률·평균 옥좌HP·금고 손실·시설 무력화 표와 요청한 두 캡처를 남긴다.
- 완료 기준: 추천의 승률·평균HP가 세 집중 배치 이상이면서 0104/0106 곡선 유지. **제품 목표는 미달이며 PARTIAL이다.** 아래 표적 검증 PASS는 비교 자료의 유효성을 뜻한다.
- 전체 회귀·전체 캠페인·출시/export·별도 검수 에이전트는 미요청/미실행.

## 3. 완료한 작업

- 구현: 기존 실제 전투 시뮬레이터를 상속하는 격리 시험과 재개·분석 도구를 추가했다. 개인 세이브를 읽거나 수정하지 않는다. Godot는 한 번에 하나, 작업 종료 시 0개를 확인한다.
- 추천 건설 비교 기준: D에서 감시탑 II(금100/마나50), 미끼 보물실 II(금120), C에서 유료 D 건물 이전 후 병영 II(금100), 회복둥지 II(마나80)를 실제 `Buildings.preview` 비용으로 구매한다. 무료 건물·병력·강화 없음. 이 자동 구매는 비교 시험의 기준이다.
- 예산: DAY19의 기존 시험 상태 금1200/마나600에서 성공 전투의 실제 정산 함수·약탈 보너스·지도 전용 날짜 이동(추가 수입0)을 사용했다. D 건설 직전1794/484 → 건설 후1574/434. C 건설 직전5996/202 → 건설 후5896/122. DAY28은6688/246, DAY29·30은7480/254.
- 날짜 이동 근거: `ApprovedGradeProgression.continue_after_result`는 `Grade.advance`로 정산 잔액을 넘기고 날짜를 직접 설정한다. 일반 `GameState.advance_day`의 금32/마나18은 지급하지 않는다. 처음 이 일반 수입을 넣은 시험은 중단·폐기 보관하고 v3 기준선400회를 새로 측정했다.
- 자원 경로는 수정 전 기준 SHA의 첫 성공 시드들을 따라 산출한 **조건부 시험 기준**이다. 개인 플레이어 실제 잔액이나 HP·성장까지 이어지는 완전한 누적 캠페인은 아니다. 선택 지출·추가 보상 없음. 후보와 최종 비교에 같은 자원을 고정했다. 경유 수정 후 전체 캠페인을 다시 정산하지 않았다.
- 스토리·몬스터·건물 수치: 변경 없음. DAY29는 적 생성·전투·추가 정산 없음.
- 밸런스 채택: DAY21·26의 기존 진격병(`explorer`, 각 날짜 두 번째 웨이브 행)에 D등급 `waypoint_room_ids: [watchtower_2, ""]`만 추가했다. 첫 갈래는 감시탑 II 경유, 다른 갈래는 원래 경로다. 기존 레인1의 옥좌 공격 우선권·수치·수량·간격은 유지한다. 두 날짜 모두 **부분 결과**다.
- DAY21: 추천80%/HP53.79→80%/55.04. 집중①90%/58.75→90%/59.81, 집중②20%/11.41→20%/11.47, 집중③0%/0. 추천의 HP가 개선되고 모든 상대 격차가 확대되지 않았지만 집중① 우위는 남았다.
- DAY26: 추천90%/45.69→90%/45.43으로 곡선 안에서 HP가0.26%p 낮아진 대신, 집중①100%/37.56→90%/33.18로 **집중① 이점을 해소**했다. 집중②100%/51.68→100%/48.38은 여전히 추천보다 강하다. 이미 이긴 비교를 유지하고 남은 집중②의 HP 격차도 축소한 부분 해결을 우선했다.
- UI/UX: 실제 D 추천 유료 건설 상태와 C 서문/남문 전투를 캡처했다. 게임 추천 우선순위 자체는 변경하지 않았다.
- 저장·호환성: APPDATA/LOCALAPPDATA를 `tmp/v130r_step10b/` 아래로 격리했다. `MAWANG_DISABLE_STEAM=1`로 Steam 브리지 초기화도 차단한다. 실제 사용자 저장 경로에 접근하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/waves.json` | 채택 날짜의 D/C 경유 메타데이터만 최소 조정 | 최종 선택 기록 참조 |
| `tools/tests/V130RStep10BSpreadTest.gd` | 유료 건설·정산 기준선, 네 배치 비교, 직접 검사, 실제 캡처 | 완료 |
| `tools/tests/V130RStep10BSpreadTest.tscn` | 시험 진입점 | 완료 |
| `tools/tests/V130RStep10BFastUnit.gd` | headless에서 체력바 표시 동기화만 생략 | 완료 |
| `tools/tests/V130RStep10BSimulation.gd` | 기존 전투 구현에 위 표시 최적화 연결 | 완료 |
| `tools/run_v130r_step10b.ps1` | 실제 Godot 경로 확인, 단일 프로세스·격리 실행 | 완료 |
| `tools/tests/v130r_step10b_report.py` | 공정성·예산·곡선 검증, 후보 선별, 400행 최종 조합·표 생성 | 완료 |
| `_mockup/game_step10b_dc_spread/result_table.md` | 최종 DAY20~30 표·예산·원인·선택지 | 완료 |
| `docs/handoff/V130R_STEP10B_DC_SPREAD_2026-10-17.md` | 이 세션 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 이 로컬 브랜치의 새 진입 링크 | 완료 |

## 5. 그래픽 및 오디오 자산

- 새 그래픽·오디오·GPT 생성 없음. SOURCE.md 대상 없음.
- 기존 실제 게임 렌더 캡처만 생성했다. 로컬 캡처·대형 원자료·실험 로그는 소스 커밋에 포함하지 않는다.
- 두 PNG는1920×1080이다. C는 전투55초에 캡처했으며 지도 가림을 피하려고 캡처 순간 대사 패널의 표시만 숨겼다. 대사 타이머·전투 규칙은 그대로이며 실제 렌더2회×18필드가 최종 표와 일치한다.
- [D 유료 추천 건설](../../_mockup/game_step10b_dc_spread/d_recommended_buildings.png), [C 서문/남문 전투](../../_mockup/game_step10b_dc_spread/c_split_gates.png).

## 6. 테스트 및 검수

| 순서 | 검사 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 수입0의 유료 건설 기준선400회 | 14,288검사/실패0, 시간 초과·불법 배치0 | `paid_baseline.json`, `paid_baseline_checks.json`, `tmp/v130r_step10b/paid_baseline_v3.log` |
| 2 | 조사관 경유 후보60회(D20/21/26 추천·집중①) | 2,655검사/실패0, 목표 미충족·미채택 | `scout_trials.json`, `scout_trials_checks.json` |
| 3 | 진격병 한 갈래 후보90회(D20추천10, D21·26각40) | 재개 실행마다 검사 실패0, D21·26부분 채택 | `upper_trials.json`, `upper_trials_checks.json`, `tmp/v130r_step10b/upper_*_v3.log` |
| 4 | 새 실행의 원래 경로 대조(D20/26/27각seed0) | 3회×18필드 전부 일치 | `control_parity_summary.json` |
| 5 | 최종400행 조합 | 중복0, 실제 제품 웨이브·소유·정산 잔액·식량·레벨 일치 | `final_rows.json`, `final_rows_summary.json` |
| 6 | 경제 기준 재생성·직접 검사 | 10회 재생성·1,027검사/실패0, 매일 잔액·비용·소유 상태·정산6종 전부 일치 | `economy.json`, `direct_checks.json` |
| 7 | 실제 렌더 두 화면 및 전투 결과 일치 | 1920×1080 PNG2장 육안 확인, 497검사/실패0, D21/C27 각seed0의18필드 전부 일치 | 요청 PNG2개, `capture_rows.json` |
| 8 | 원본1751해시·수치 불변·문법·정책 | 원본1751해시 일치, 금지 수치 변경0, Python/PowerShell 문법·staged diff-check PASS. 정책 검사는 문서 커밋 뒤 실행 | `final_verification.json` |
| 9 | 전체 회귀·전체 플레이·검수 에이전트·export | NOT_REQUESTED / 미실행 | 현재 요청 범위 밖 |

주요 실행 명령:

```powershell
python -X utf8 tools/tests/v130r_step10b_report.py --prepare --route paid --name paid_baseline 
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_v130r_step10b.ps1 -Mode balance
python -X utf8 tools/tests/v130r_step10b_report.py --prepare --route scout --name scout_trials --days 20,21,26 --layouts recommended,anchor_cluster
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_v130r_step10b.ps1 -Mode balance
python -X utf8 tools/tests/v130r_step10b_report.py --prepare --route upper --name upper_trials --days 20,21,26 --layouts recommended
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_v130r_step10b.ps1 -Mode balance
python -X utf8 tools/tests/v130r_step10b_report.py --prepare --route upper --name upper_trials --days 21,26 --layouts anchor_cluster,final_line,first_line
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_v130r_step10b.ps1 -Mode balance
python -X utf8 tools/tests/v130r_step10b_report.py --select --name scout_trials
Copy-Item -LiteralPath tmp/v130r_step10b/selected_waves.json -Destination data/waves.json
python -X utf8 tools/tests/v130r_step10b_report.py --compose --name scout_trials
python -X utf8 tools/tests/v130r_step10b_report.py --name final_rows
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_v130r_step10b.ps1 -Mode direct
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_v130r_step10b.ps1 -Mode capture
```

원자료가 존재하면 같은 웨이브·예산인 행만 재개한다. 경제 기준 재생성에는 먼저 `--prepare`로 불변 기준 웨이브를 준비한다. paid 실행은 전투10일×4배치×10=400회다. 그 후 집중①이 유리한 날에만 후보를 측정하고 채택 날짜의 네 배치 결과만 대체한다. 미채택 후보를 최종 표에 섞지 않는다.

이번 직접 검사 전에는 `tmp/v130r_step10b/config.json`의 `rebuild_economy`를 true로 설정해 수정 전 불변 웨이브의 기준10회를 새로 실행했다. 체크포인트·기준SHA·매일잔액·비용·소유 상태·정산 기록이 이전 v3와 모두 일치했고 구매 기록의 가변 참조도 복사본으로 고정했다. 캡처 전에는 재생성 옵션을 제거했다.

headless는 체력바·자세·가림 등 표시만 생략하며 전투·이동·스킬·자원 규칙은 부모 구현을 사용한다. 업적 관찰 카탈로그와 저장은 시험에서 비활성화했다. 업적 자체의 검수는 이 시험 범위가 아니다. 새 실행 원래 경로3회가 기존400행과 18필드에서 정확히 일치한다. 실제 렌더 결과 일치는 종료 검사에 따로 기록한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: e99004132bc6753e79d9aed429d5d57d66e0e8a1
- Review range: 18931a116c5562c2bddd12be08da76882e6c1921..e99004132bc6753e79d9aed429d5d57d66e0e8a1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

별도 검수 에이전트 없음. TARGETED_PASS는 직접 검사·원자료 무결성·해당 화면 확인에만 적용한다. **추천 우위·곡선 전체 목표의 PASS가 아니다.** 미달 날짜는 숨기지 않고 다음 항목에 남긴다. Reviewed SHA 이후에는 인계 문서만 변경한다.

## 7. 미해결 항목과 위험

- 상세 결과: [result_table.md](../../_mockup/game_step10b_dc_spread/result_table.md), [final_rows.json](../../_mockup/game_step10b_dc_spread/final_rows.json), [선택 근거](../../_mockup/game_step10b_dc_spread/selection.json), [정산·비용](../../_mockup/game_step10b_dc_spread/economy.json).
- **추천 승률·평균HP 동시 우위 미달: DAY20·21·26.** 집중① 우위는 DAY20·21에 남고, DAY26은 집중② 우위가 남는다. DAY20은 추천80%/50.56, 집중①90%/58.92, 집중②90%/48.87이다. 최종 표의 미달을 PASS로 바꾸지 않았다.
- **곡선 미달: DAY22·23·30.** 각각 추천80%/49.53(HP하한50미달),100%/43.08(승률상한95초과·HP하한50미달),40%/27.99(목표70~90%/35~55%미달)다.
- DAY24·27은 건설·정산 기준 보정만으로 곡선과 세 집중 배치 대비 우위를 모두 충족했다. DAY22·23도 집중① 우위는 사라졌지만 곡선이 미달이므로 완전 해결로 세지 않는다.
- 건설은 수비 가능 칸을 늘리지만 추천이 모든 새 부지를 채우지는 않는다. C에서는 기존 텅텅이 결계핵→병영 II, 쉿이 금고→병영 II로 이동하고, 대기하던 파파가 결계핵에 출전한다. 같은 해금 명단에서 추천 출전 인원은 D15/C16이며 집중①9/②6/③5다. 식량 한도·실제 슬롯은 모두 지킨다.
- 이전 수입 가정(v1/v2) 결과와 마나600 대조는 income_assumption_archive/로 보관한 미채택 자료다. 현재 실제 지도 진행의 최종 비교와 섞지 않는다.
- DAY22·23·30은 새 기준선에서 집중①이 더 유리하지 않으므로 이번 조건에 따라 경로를 수정하지 않았다. 이 날짜의 곡선 복구는 다음 작업 범위를 결정해야 한다. 이전 v1/v2의 날짜별 결론은 최종 근거에서 제외했다.
- 날짜·배치당 10시드 표본이며 모든 배치의 최적성이나 실제 캠페인 누적 승률을 증명하지 않는다. 원격 최신 권위도 미확정이다.

## 8. 다음 작업 순서

1. 이 표·두 캡처·정산 기준을 사용자 확인한다. 개인 잔액을 사용할 경우 사용자가 지정한 D/C 금·마나를 기준으로 네 배치를 같이 재측정한다. 사용자 세이브를 자동 수정하지 않는다.
2. 남은 집중① 우위 날짜는 `data/waves.json`의 적 경유·목표 추가 탐색이 가능하다. 수치 변경 없이 추천 곡선·네 배치 공정성·상대 이점을 함께 검증한다.
3. 별도 선택지: `scripts/map_builder/ApprovedMonsterPlacement.gd`에서 핵심 수비를 유지하며 새 부지에 추천을 분산하는 정책을 조정한다. 이번에는 수정하지 않았다. DAY23·30 곡선 문제를 포함할지 범위를 먼저 결정한다. 한 건물 쏠림 방지와 무전투 DAY29를 유지한다.
4. 공개 배포·main·태그·Steam은 이 인계로 승인되지 않는다. **사용자 확인 대기.**

## 9. 작업 트리 상태

- 초기 혼합 작업 트리: 기존 `.import` 수정1307개 및 기존 미추적 산출물·UID 등을 보존했다. 초기 보호 파일1751개의 SHA-256 비교 결과는 종료 검증에 기록한다.
- 명시한 소스·최종 표·인계만 스테이징한다. `git add -A`, reset, stash, 브랜치 전환 없음.
- 미커밋 산출물: `_mockup/game_step10b_dc_spread/`의 두 PNG, JSON·후보·대조 자료 및 `tmp/v130r_step10b/`의 격리 데이터·로그. 원자료·캡처를 삭제하지 않는다.
- 초기 마나142 고정 C 후기 실험은 `scout_upgrade_wallet_rows.json`으로 보존한 미채택 자료다. 최종 DAY28/30에는 지도 전용 정산을 보정한246/254를 사용한다. 예산을 잘못 맞춘 과거 실험 행을 최종 표에 사용하지 않았다.
- 최종 작업 트리·의도한 커밋·Godot 프로세스 수: 종료 검증 참조.

## 10. 종료 체크리스트

- [x] 요청 범위·실제 결과·미달 날짜를 구분했다. 제품 목표 PARTIAL.
- [x] 관련 직접 검사·표 무결성·해당 화면을 확인했다.
- [x] 전체 검수·검수 에이전트·export 미요청/미실행을 기록했다.
- [x] Reviewed SHA·범위·표적 검증 결과를 기록했다.
- [x] 새 자산 생성 없음과 로컬 캡처 위치를 기록했다.
- [x] CURRENT에 로컬 인계를 연결했다.
- [x] 영어 로컬 커밋만, 원격·main·태그·Steam 조치 없음.
- [x] 개인 세이브 미접근·미수정, 기존 변경 보존, Godot 종료0개를 확인했다.
