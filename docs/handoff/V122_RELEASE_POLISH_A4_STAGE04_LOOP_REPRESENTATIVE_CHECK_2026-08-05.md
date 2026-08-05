# V1.2.2 릴리스 폴리시 핸드오프 — A4 Stage 04 대표 화면·청취 확인

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 패킷 ID: `A4-STAGE-04-LOOP-REPRESENTATIVE-CHECK`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 사용자 승인 여부: 대표 화면·ambience 청취 확인 완료
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 작업 결과: `A4_STAGE04_LOOP_REPRESENTATIVE_CHECK_PASS`

## 2. 이번 세션 목표

- 요청 사항: Stage 04 ambience runtime 연결을 1280×720 대표 화면에서 확인하고 실제 청취 승인을 기록한다.
- 완료 조건: 대표 화면 캡처 PASS, runtime 직접 테스트 PASS, 사용자 청취 승인.
- 범위에서 제외한 사항: 코드·catalog·manifest·source/runtime·오디오 자산·AudioDirector 변경, 전체 회귀 검수.

## 3. 완료한 확인

- Stage 04 `stage_04_citadel` DAY 30 관리 화면을 1280×720으로 렌더링했다.
- 성채 맵, 상단 자원·DAY·HP HUD, 우측 방 지침, 하단 수비대·명령 영역이 정상 표시됐다.
- Stage 04 ambience event·stream·Ambience 버스·반복 갱신 중복 방지를 `MusicStateAudioTest` 54 assertions로 재확인했다.
- 사용자가 `assets/audio/ambience/stage04_citadel.wav`를 직접 청취하고 `승인 완료`를 전달했다.
- 무음·끊김·과도한 반복 seam·화면 분위기 불일치에 대한 수정 요청은 없었다.

## 4. 실제 변경 경로

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_A4_STAGE04_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md` | 대표 화면·runtime·청취 결과 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE04_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | PASS 결과와 다음 패킷 갱신 | 완료 |

코드·데이터·스토리·밸런스·그래픽 자산·오디오 runtime은 이번 패킷에서 변경하지 않았다. 대표 캡처는 `tmp/v122_structural_wall_review/stage_04_citadel_1280x720.png`에 남겼다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음.
- 생성 모델: 이번 패킷에서 생성하지 않음. 기존 Lyria 승인·승격·runtime 연결 자산을 확인함.
- 생성 원본 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/source.mp3` — 변경 없음
- `SOURCE.md` 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/SOURCE.md` — 변경 없음
- 런타임 최종 자산 경로: `assets/audio/ambience/stage04_citadel.wav` — 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 변경 없음.
- 게임 연결 및 실제 렌더 확인 결과: 1280×720 Stage 04 대표 화면 PASS, 실제 ambience 청취 승인 PASS.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `godot.cmd --path . --scene tools/V122StructuralWallCapture.tscn --quit-after 3000` | PASS — `V122_STRUCTURAL_WALL_CAPTURE: PASS` | QA 문서 및 캡처 |
| 2 | `godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 1800` | PASS — 54 assertions | QA 문서 |
| 3 | Stage 04 ambience 실제 청취 | PASS — 사용자 `승인 완료` | 사용자 확인 |
| 4 | 전체 회귀·전체 플레이·검수 에이전트 | `NOT_REQUESTED` | 사용자 요청 범위 아님 |

Godot headless 종료에서 ObjectDB/resource teardown 경고가 관찰됐지만 기능 단언 54개와 대표 캡처는 통과했다. 이 경고는 기존 관찰 항목으로 보존한다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `NOT_REQUESTED` | `N/A` | `N/A` | 없음 | 없음 | QA 문서 | `NOT_REQUESTED` |

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 전체 회귀·전체 플레이·검수 에이전트는 이번 사용자 요청 범위가 아님
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 문서만 추가·갱신

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 기존 Godot teardown resource 경고는 남아 있다. 기능 단언 실패는 아니며 별도 정리 패킷에서 다룬다.
- Stage 02 대표 화면·runtime 단언은 통과했지만 실제 ambience 청취·사용자 승인이 아직 남아 있다.
- 전체 출시 검수, 최종 커밋·푸시·배포는 별도 범위다.

## 8. 다음 작업 순서

다음 단일 패킷만 제안한다.

`A4-STAGE-02-LOOP-REPRESENTATIVE-CHECK`

1. 기존 Stage 02 대표 캡처와 `MusicStateAudioTest` 42 assertions를 기준으로 현재 작업 트리에서 runtime 상태를 재확인한다.
2. `assets/audio/ambience/stage02_indoor.wav`를 실제 청취하고 사용자 승인을 기록한다.
3. 승인 후 이 패킷을 `TARGETED_PASS`로 닫고, 다음 오디오 패킷은 새로 제안한다. Stage 02 승인 전에는 다음 패킷을 자동 실행하지 않는다.

허용 경로는 `docs/qa/V122_A4_STAGE02_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`, `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_REPRESENTATIVE_CHECK_2026-08-05.md`, `docs/handoff/CURRENT.md`다. 코드·데이터·자산·manifest·source/runtime·AudioDirector·Stage 01·03·04·발소리·다음 packet은 건드리지 않는다.

## 9. 작업 트리 상태

- 혼합 작업 트리이며 기존 사용자·Luna 변경을 보존했다.
- 이번 패킷은 커밋·스테이징·푸시하지 않았다.
- 이번 패킷의 저장소 변경은 QA/핸드오프와 `CURRENT.md` 문서뿐이다.
- 다음 세션은 `docs/handoff/CURRENT.md`의 `A4-STAGE-02-LOOP-REPRESENTATIVE-CHECK`에서 시작한다.

## 10. 종료 체크리스트

- [x] 대표 화면 부팅 및 Stage 04 화면 확인
- [x] 관련 Godot 직접 테스트 통과
- [x] 소유자 실제 청취 확인
- [x] 전체 회귀·검수 에이전트는 요청되지 않아 실행하지 않음
- [x] 오디오 출처와 런타임 연결 상태 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 커밋·푸시·PR/태그
