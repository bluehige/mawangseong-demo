# V1.2.2 Q1-P 성능·메모리 상세 감사

## 감사 범위

이번 문서는 정식 출시 전 Q1-P 패킷의 읽기 전용 감사 결과다. 대표 전투에서 동적 표식·타격 효과·함정 애니메이션·시설 무력화 카운트다운이 정적 던전 전체를 다시 그리는지 확인하고, headless 환경에서 프레임 시간과 Godot 내부 메모리 추이를 기록했다. 실제 Windows GPU와 저사양 장시간 검수는 이 패킷의 실행 환경 밖이다.

- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 렌더 프로필: Windows `full`
- 샘플: 시나리오당 120프레임
- 화면 기준 예산: 60fps의 한 프레임 `16.667ms`
- 기계 결과: `tmp/v122_release_polish/q1_p/q1_p_inventory.{json,tsv}`

## 실행한 검사

| 검사 | 결과 | 근거 |
|---|---|---|
| `EngineerPerformanceSmokeTest.tscn` | PASS, 20 assertions | `tmp/v122_release_polish/q1_p/engineer_performance_smoke.log` |
| `V122CombatVisualHierarchyTest.tscn` | PASS | `tmp/v122_release_polish/q1_p/v122_combat_visual_hierarchy.log` |
| `Q1PPerformanceRepro.tscn` | PASS, 5 assertions | `tmp/v122_release_polish/q1_p/q1_p_performance_repro.log` |

`EngineerPerformanceSmokeTest`는 타이틀에서 숨겨진 던전 draw 차단, 관리 화면 복구, idle 전투, 공병 `SpriteFrames` 공유, 동적 overlay·함정·시설 redraw 분리를 확인했다. 합성 재현기는 20개 전투 표식, 타격 효과 24개, 실제 함정 슬롯, 시설 카운트다운, 네 효과의 복합 상태를 각각 120프레임 계측했다.

## 측정 결과

| 시나리오 | wall p95 / 최대 ms | Godot process p95 ms | 정적 맵 전체 redraw | overlay draw | memory_static peak |
|---|---:|---:|---:|---:|---:|
| idle | 16.468 / 23.218 | 0.455 | 0 | 0 | 325,828,751 B |
| 동적 표식 20개 | 15.034 / 16.425 | 1.992 | 0 | 120 | 325,895,631 B |
| 타격 효과 24개 | 15.955 / 22.437 | 1.992 | 0 | 0 | 326,025,479 B |
| 함정 애니메이션 1개 | 15.954 / 19.026 | 1.493 | 0 | 0 | 326,030,987 B |
| 시설 카운트다운 | 15.926 / 19.884 | 0.659 | 0 | 20 | 326,089,399 B |
| 복합 표식·타격·함정·시설 | 15.129 / 16.629 | 0.659 | 0 | 120 | 326,248,559 B |

headless 합성의 idle peak에서 복합 시나리오 peak까지 `memory_static` 증가는 약 419,808바이트(약 0.40MiB)였다. 이는 효과 자원 생성과 테스트 순서가 포함된 Godot 내부 정적 메모리 수치이며, Windows 작업 관리자 RSS·VRAM·장시간 누수의 판정값이 아니다. headless 더미 렌더러에서는 `RENDER_TOTAL_DRAW_CALLS_IN_FRAME=0`으로 보고되므로 GPU draw-call 품질을 이 수치로 승인하지 않았다.

## 판정

- 정적 던전 전체 redraw: PASS. 동적 표식·타격·함정·시설과 복합 상태에서 모두 0회다.
- headless 프레임 시간: TARGETED PASS. 여섯 시나리오 wall p95는 모두 60fps 예산 이하였고, 일부 최대값은 19~23ms로 순간 초과했다.
- 내부 메모리: 합성 범위에서 급격한 증가는 관찰되지 않았지만, 정적 메모리만 측정했으므로 출시 승인 근거로 사용하지 않는다.
- 런타임·데이터·그래픽·오디오: 수정하지 않았다.

## 미해결과 소유자 검수

`Q1-P-OWNER-01`은 출시 게이트로 남긴다. 새 Windows QA 후보에서 실제 GPU를 사용하는 1280×720 대표 전투를 최소 10분 실행해 시작·최저·p95 FPS, 최대 frame time, 작업 관리자 메모리 시작/최대/종료, 혼잡 타격·함정·시설 효과의 순간 급락을 기록해야 한다. 이 검수 전에는 Q1-P를 `OWNER_QA_PENDING` 상태로 유지한다.

직접 전투 시작 합성 때문에 autosave 요약 불일치 경고와 종료 시 ObjectDB/RID cleanup 경고가 있었지만, 세 테스트는 모두 정상 종료·PASS했다. 이는 테스트 harness 정리 경계로 기록하며 제품 성능 결함으로 분류하지 않는다.

Related tests: `EngineerPerformanceSmokeTest` PASS(20), `V122CombatVisualHierarchyTest` PASS, `Q1PPerformanceRepro` PASS(5)
UI check: headless Windows full 프로필에서 동적 overlay·함정·시설·복합 효과 정적 맵 redraw 0회와 120프레임 wall p95를 확인했으며 실제 GPU 화면은 미검수
Unresolved issues: `Q1-P-OWNER-01` 실제 Windows GPU·저사양 RSS·장시간 전투 검수, headless autosave/ObjectDB/RID cleanup 경고는 harness noise

## 범위 경계

- 새 코드·데이터·그래픽·오디오·빌드 산출물: 없음
- 전체 회귀·전체 플레이·검수 에이전트: 실행하지 않음
- 커밋·푸시: 실행하지 않음
