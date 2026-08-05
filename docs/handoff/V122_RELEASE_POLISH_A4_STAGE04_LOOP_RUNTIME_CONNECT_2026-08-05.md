# V1.2.2 릴리스 폴리시 핸드오프 — A4 Stage 04 runtime 연결

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 패킷 ID: `A4-STAGE-04-LOOP-RUNTIME-CONNECT`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 작업 결과: `TARGETED_PASS`

## 2. 이번 세션 목표

- 요청 사항: Stage 04 환경음 catalog event를 GameRoot runtime owner에 연결한다.
- 완료 조건: Stage 04 event가 catalog와 GameRoot에서 연결되고, Stage 01~04 stream 전환·버스·중복 방지 직접 테스트를 통과한다.
- 범위에서 제외한 사항: 추가 음원 생성, source/runtime·manifest·AudioDirector 변경, 대표 화면과 실제 청취, 전체 회귀 검수.

## 3. 완료한 작업

- 구현: `GameRoot.gd`에 Stage 04 ambience asset/event 상수와 `CASTLE_STAGE_FOUR_ID` 분기를 추가했다.
- 스토리 및 데이터: `ambience.stage04.citadel`을 실제 runtime event로 catalog에 등록하고 Stage 04 asset을 `actual_runtime`으로 전환했다.
- 밸런스: 변경 없음.
- UI/UX: 변경 없음.
- 저장 및 호환성: 기존 Stage 01~03 단계별 ambience 흐름을 유지하면서 Stage 04를 네 번째 단계로 추가했다.

연결된 이벤트의 owner는 `scripts/game/GameRoot.gd`, locator는 `_update_stage_ambience`, 재생 버스는 `AudioSettings.AMBIENCE_BUS`다. 실제 runtime 자산 경로는 `assets/audio/ambience/stage04_citadel.wav`다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | Stage 04 ambience 상수와 단계 분기 연결 | 완료 |
| `data/audio/audio_event_catalog.json` | Stage 04 asset/event actual runtime 정렬 | 완료 |
| `tools/audio/test_audio_event_catalog.py` | snapshot·Stage 04 connected 계약 단언 갱신 | 완료 |
| `tools/tests/MusicStateAudioTest.gd` | Stage 04 event·stream·버스·중복 방지 테스트 추가 | 완료 |
| `docs/qa/V122_A4_STAGE04_LOOP_RUNTIME_CONNECT_2026-08-05.md` | 직접 검증 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE04_LOOP_RUNTIME_CONNECT_2026-08-05.md` | 세션 인수인계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 대표 화면·청취 패킷 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음.
- 생성 모델: 이번 패킷에서 생성하지 않음. 기존 Lyria 승인·승격 자산을 runtime에 연결함.
- 생성 원본 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/source.mp3`
- `SOURCE.md` 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/SOURCE.md`
- 런타임 최종 자산 경로: `assets/audio/ambience/stage04_citadel.wav`
- 프롬프트/후처리/크롭/알파 처리 요약: 이번 패킷에서는 변경 없음.
- 게임 연결 및 실제 렌더 확인 결과: GameRoot runtime 연결과 headless 직접 단언은 완료. 대표 화면·실제 청취는 다음 패킷.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | PASS — 10/10 | `docs/qa/V122_A4_STAGE04_LOOP_RUNTIME_CONNECT_2026-08-05.md` |
| 2 | catalog JSON 파싱 및 summary 확인 | PASS — 80/72/70/10 | `docs/qa/V122_A4_STAGE04_LOOP_RUNTIME_CONNECT_2026-08-05.md` |
| 3 | `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` | PASS — 54 assertions | `docs/qa/V122_A4_STAGE04_LOOP_RUNTIME_CONNECT_2026-08-05.md` |
| 4 | 전체 회귀·전체 플레이 | `NOT_REQUESTED` | 사용자 요청 범위 아님 |
| 5 | 시각·실제 청취 검수 | `NOT_REQUESTED` | 대표 화면·청취 후속 패킷 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `NOT_REQUESTED` | `N/A` | `N/A` | 없음 | 없음 | QA 문서 | `NOT_REQUESTED` |

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 전체 회귀·전체 플레이·검수 에이전트는 이번 사용자 요청 범위가 아님
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이번 패킷의 runtime 연결·catalog·직접 테스트·문서만 반영

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- Stage 04 대표 1280×720 화면에서 ambience가 실제 화면과 함께 재생되는지 아직 확인하지 않았다.
- 사용자의 실제 청취 및 승인 전이다.
- 전체 출시 검수와 최종 커밋·푸시는 별도 범위다.

## 8. 다음 작업 순서

다음 단일 패킷만 제안한다.

`A4-STAGE-04-LOOP-REPRESENTATIVE-CHECK`

1. `tools/V122StructuralWallCapture.tscn`으로 Stage 04 `stage_04_citadel` DAY 30 관리 화면을 1280×720에서 캡처한다.
2. `MusicStateAudioTest`를 재실행해 runtime 연결 상태를 재확인한다.
3. Stage 04 ambience를 실제 청취하고 무음·끊김·반복 seam·화면 분위기 적합성을 기록한다. 완료 후 다음 패킷은 자동 실행하지 않는다.

허용 경로는 해당 QA/핸드오프 문서와 `docs/handoff/CURRENT.md`뿐이다. 코드·데이터·자산·manifest·source/runtime·GameRoot·AudioDirector·Stage 01/02/03·발소리·다음 패킷은 건드리지 않는다.

## 9. 작업 트리 상태

- 혼합 작업 트리이며 기존 사용자 변경을 보존했다.
- 이번 패킷은 커밋·스테이징·푸시하지 않았다.
- 이번 패킷의 직접 변경은 GameRoot 단계 분기, catalog event, 두 직접 테스트, QA/핸드오프, `CURRENT.md`다.
- 다음 세션은 `docs/handoff/CURRENT.md`의 `A4-STAGE-04-LOOP-REPRESENTATIVE-CHECK`에서 시작한다.

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
