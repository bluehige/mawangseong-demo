# v1.2.2 이중 전선 Phase C-2a DAY 1~5 웨이브 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-29
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 다음 순서인 후보 전용 DAY 1~5 양면 웨이브를 구현한다.
- 완료 조건: DAY 1 A 단독, DAY 2 B 전선 도둑 경고와 8~10초 양면 압력, DAY 3~5 점진 압박을 후보 레이아웃에서만 사용하고 기존 제품 웨이브는 유지한다.
- 범위에서 제외한 사항: DAY 3 방어자 전용 연결로 건설·저장, 후보의 제품 기본값 활성화, 전체 QA·실플레이·밸런스 확정, 빌드·배포.

## 3. 완료한 작업

- 구현:
  - `DataRegistry`가 후보 전용 웨이브를 별도 카탈로그로 읽는다.
  - `wave_catalog_for_layout`은 `stage01_dual_front_candidate_01`의 DAY 1~5 요청에만 해당 DAY를 덮어쓴다.
  - 실제 전투의 `_active_wave_catalog`이 현재 레이아웃 ID와 DAY를 사용해 후보 카탈로그를 선택한다.
  - 기존 레이아웃과 후보 DAY 6 이후는 기존 `data/waves.json`을 그대로 사용한다.
- 스토리 및 데이터:
  - DAY 1: A 전선 탐험가 3명.
  - DAY 2: 0초 A 전선, 14초 B 전선 도둑, 22초와 30초에 A/B 동시 증원. 6초 사전 예고 기준 도둑의 B 전선 경고는 8초에 시작한다.
  - DAY 3: A/B 소규모 동시 압박, 총 5명.
  - DAY 4: 연결로 없이 사전 배치와 명령으로 대응할 기준 압박, 총 6명.
  - DAY 5: A/B 교차 출현과 후반 수련생 용사·도둑, 총 8명.
- 밸런스:
  - DAY 3→4→5 출현 수를 5→6→8로 늘려 점진 압박을 데이터 계약으로 고정했다.
  - DAY 2는 22~30초의 8초 동안 두 전선의 출현 흐름이 겹친다.
  - 모든 DAY는 연결로 보유를 전투 시작 조건으로 검사하지 않는다.
  - DAY 5의 실제 체감 난이도와 연결로 필요성은 실플레이 피드백 전까지 확정하지 않는다.
- UI/UX: 새 UI는 추가하지 않았다. Phase C-1의 6초 전선·진입점·목표 예고가 새 웨이브를 그대로 소비한다.
- 저장 및 호환성: 저장 형식은 변경하지 않았다. 후보 레이아웃이 아니면 제품 웨이브 참조와 결과가 바뀌지 않는다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v122/dual_front_day01_05_waves.json` | 후보 전용 DAY 1~5 전선·시간·배율 | 완료 |
| `scripts/core/DataRegistry.gd` | 후보 웨이브 로드와 레이아웃별 단일 DAY overlay | 완료 |
| `scripts/game/GameRoot.gd` | 실제 전투 카탈로그 선택에 레이아웃 overlay 연결 | 완료 |
| `tools/tests/V122DualFrontDay01To05WaveTest.gd` | 학습 순서·8초 겹침·점진 압박·런타임 진입점 검증 | 완료 |
| `tools/tests/V122DualFrontDay01To05WaveTest.tscn` | 전용 headless 테스트 scene | 완료 |
| `docs/handoff/V122_DUAL_FRONT_PHASEC2A_DAY01_05_WAVES_2026-07-29.md` | 세션 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 시각·실플레이 검수는 이번 범위에서 요청되지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122DualFrontDay01To05WaveTest.tscn` | PASS | `.godot/V122DualFrontDay01To05WaveTest-phasec2a-final.log` |
| 2 | `V122EnemyLaneRoutingTest.tscn` | PASS | `.godot/V122EnemyLaneRoutingTest-phasec2a.log` |
| 3 | `V122DualFrontLayoutContractTest.tscn` | PASS | `.godot/V122DualFrontLayoutContractTest-phasec2a.log` |
| 4 | `V122Day01To05ParityTest.tscn` | PASS | `.godot/V122Day01To05ParityTest-phasec2a.log` |
| 5 | `V122Day02FeedbackTest.tscn` | PASS | `.godot/V122Day02FeedbackTest-phasec2a.log` |
| 6 | `V122FacilityZoneCombatConsumerTest.tscn` | PASS | `.godot/V122FacilityZoneCombatConsumerTest-phasec2a.log` |
| 7 | 직접 영향 파일 `git diff --check` | PASS | 줄 끝 변환 경고만 존재 |
| 8 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 지시에 따라 보류 |
| 9 | 시각/실플레이 검수 | NOT_REQUESTED | 사용자 최종 테스트 전까지 보류 |

Windows root certificate store 읽기 경고는 기존 headless 환경 경고이며 위 전용 테스트의 종료 코드와 단언 결과에는 영향을 주지 않았다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | 미커밋 작업 트리 | 전체 검수 미요청 | 직접 영향 계약 테스트만 수행 | 위 테스트 로그 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 회귀·실플레이는 이번 작업의 필수 범위가 아니다.
- PASS 이후 기능·데이터·자산 변경 여부: 핸드오프 문서와 `CURRENT.md`만 변경.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 후보 레이아웃은 아직 제품 기본값이 아니므로 일반 플레이에서는 새 웨이브가 활성화되지 않는다.
- 밸런스 관찰 항목: DAY 2의 22~30초 양면 압박, DAY 4 무연결 승리 가능성, DAY 5 연결로 필요 체감은 실제 플레이로 조정해야 한다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 전체 플레이·렌더·빌드는 실행하지 않았다.

## 8. 다음 작업 순서

1. `scripts/v122/spatial/`, `scripts/game/`, 저장 adapter에 DAY 3 금화 1000·마나 100 방어자 전용 연결로의 건설 상태와 traversal을 구현한다. 완료 조건은 미건설 시 양 전선 분리, 건설 시 방어자만 최단 이동에 사용, 적 경로는 불변이다.
2. 연결로 상태와 후보 room descriptor를 구저장·retry·Stage 2~4에 결정적으로 이식한다. 완료 조건은 누락 필드 기본값 `false`와 재생성 결과 일치다.
3. 구조·저장 집중 테스트 후에만 후보의 제품 기본값 활성화를 검토한다. 실제 밸런스와 재미는 사용자 플레이 피드백으로 확정한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`에 미커밋 변경이 존재한다.
- 미커밋 파일: 이번 Phase C-2a 5개 구현·테스트 파일과 핸드오프 2개 외에 Phase A/B/C-1 및 이전 UI·설정 변경이 함께 남아 있다.
- 의도하지 않은 기존 변경: 다수 `.import`와 이전 UI·오디오·설정 변경을 보존했으며 정리하거나 되돌리지 않았다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 없음. 전용 테스트 로그만 `.godot/`에 있다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
