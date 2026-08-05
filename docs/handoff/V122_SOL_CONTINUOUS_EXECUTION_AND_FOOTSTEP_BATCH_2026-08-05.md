# v1.2.2 SOL 연속 실행 전환·발소리 묶음 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 상태: upstream보다 2커밋 앞섬
- 커밋·푸시·PR: 실행하지 않음
- 작업흐름: `SOL-V122-FOOTSTEPS-BATCH`
- 결과: `TARGETED_PASS` — 후속 runtime·scheduler 핸드오프로 완료

## 2. 이번 세션 목표

- Luna의 컨텍스트 한계를 위해 만든 소형 패킷 강제 규칙을 Luna에게만 적용하도록 고친다.
- SOL은 연속 작업흐름으로 여러 관련 단계와 자산을 처리하고 실제 사용자 판단 지점에서만 멈추도록 한다.
- 발소리 세 표면 × 세 변형을 묶어서 생성·기계 검증하고 한 번의 청취 gate로 전달한다.

## 3. 완료한 작업

- `AGENTS.md`의 실행 규모 규칙을 SOL 연속 실행과 Luna 소형 패킷으로 분리했다.
- SOL 명령의 연속 승인, 공개된 비용 상한 안의 묶음 호출, 사람 청취·화면 승인 묶음, 작업흐름 단위 QA·핸드오프를 명시했다.
- v1.2.2 Lyria manifest를 89개로 확장하고 발소리 9개에 surface·variation·source reel·anchor 계약을 등록했다.
- 파이프라인 단위 테스트를 18개로 확장해 세 표면 × 세 변형, 경로, render, source mapping, `$0.36` 최대 계획을 검증했다.
- Lyria Clip 성공 요청 4회로 고유 source reel 4개를 만들고, 2·7·12초 앵커에서 고유 preview 9개를 추출했다.
- 세 번째 동굴 cue의 일반 필터 차단 2회 후 같은 요청을 반복하지 않고 성공 reel 추출로 전환했다.
- 표면별 review WAV 3개와 통합 `verification.json`을 생성했다.
- API 키는 Chrome의 현재 AI Studio 세션에서 복사해 생성 프로세스에만 전달했고, 실행 뒤 환경 변수와 클립보드를 정리했다. 키 값은 출력·저장·문서화하지 않았다.

## 4. 변경 파일과 산출물

| 경로 | 목적 | 상태 |
|---|---|---|
| `AGENTS.md` | SOL 연속 실행·Luna 소형 패킷 분리 | 완료 |
| `tools/audio/lyria_v122_manifest.json` | 발소리 9개와 source reel 앵커 계약 | 완료 |
| `tools/audio/test_lyria_pipeline.py` | 89개 snapshot·9개 발소리 계약 검증 | 완료 |
| `docs/qa/V122_SOL_FOOTSTEP_BATCH_LISTENING_GATE_2026-08-05.md` | 생성·검증·청취 gate 증빙 | 완료 |
| `docs/handoff/V122_SOL_CONTINUOUS_EXECUTION_AND_FOOTSTEP_BATCH_2026-08-05.md` | 이번 인계 | 완료 |
| `docs/handoff/CURRENT.md` | SOL 작업흐름과 다음 승인 gate | 완료 |
| `tmp/lyria_audio_v122/20260805_footsteps_batch_listening/` | 후보 9개·review 3개·검증 JSON, Git 무시 | 전체 승인 완료 |

## 5. 그래픽·오디오·데이터 변경

- 그래픽·스토리·밸런스·저장: 변경 없음.
- 후속 승격·catalog·scheduler 결과는 `docs/handoff/V122_SOL_FOOTSTEP_RUNTIME_AND_SCHEDULER_2026-08-05.md`에 기록했다.
- 생성 후보: mono 44.1kHz·16bit·약 0.26~0.32초, preview 해시 9개 모두 고유.

## 6. 테스트 및 검수

| 순서 | 검사 | 결과 |
|---:|---|---|
| 1 | `python tools/audio/test_lyria_pipeline.py` | PASS, 18 tests |
| 2 | v1.2.2 manifest `validate` | PASS, 89 assets/coverage 일치 |
| 3 | 발소리 9개 plan | PASS, 최대 9회/`$0.36` |
| 4 | Lyria 실제 생성 | 성공 4회/예상 `$0.16`, 필터 차단 2회/출력 없음 |
| 5 | 후보 메타데이터·SHA-256·무음·민감정보 | PASS, 9개 고유 preview·키 패턴 0건 |
| 6 | review WAV 3개 생성·해시 | PASS |
| 7 | 사람 청취 | PASS — 사용자 `전체 승인` |
| 8 | 전체 회귀·정식 후보 빌드 | 아직 실행 전 — 최종 출시 단계에서 수행 |

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 다음 순서

1. 사용자가 세 review WAV를 한 번에 청취하고 전체 또는 표면별 판정을 한다.
2. 승인된 9개 후보를 source/runtime로 승격하고 manifest active·catalog 89개를 정렬한다.
3. `normal`·`heavy` 재생 프로필, 정지 무음, 보이는 주요 유닛, 동시 voice 3개, x3 밀도 감소 scheduler를 구현한다.
4. 대표 전투 청취와 오디오 장시간·mix gate를 닫는다.
5. CURRENT의 그래픽·UI·IME·성능·OWNER QA 미해결을 SOL 연속 작업흐름으로 처리한다.
6. 최종 기능 SHA를 선별 통합하고 전체 검수 뒤 Windows 정식 후보를 export·실행·해시한다.

## 8. 작업 트리 상태

- 기존 사용자·Luna 변경이 대량으로 섞인 미커밋 작업 트리를 그대로 보존했다.
- 관련 파일만 수정했고 기존 변경을 되돌리거나 정리하지 않았다.
- `tmp/` 후보는 `.gitignore` 대상이며 소스 브랜치 커밋 대상이 아니다.
- 커밋·푸시·PR·태그·Release는 실행하지 않았다.

## 9. 종료 체크리스트

- [x] SOL 연속 실행 규칙 반영
- [x] 발소리 9개 manifest 계약
- [x] 테스트 18개·manifest 89개 검증
- [x] 성공 source reel 4개·고유 preview 9개
- [x] 키 잔존 0건
- [x] 표면별 review WAV 3개
- [x] QA·핸드오프 작성
- [x] 사용자 묶음 청취 승인
- [x] runtime·source·catalog·scheduler 승격
- [ ] 전체 검수·Windows 정식 후보
