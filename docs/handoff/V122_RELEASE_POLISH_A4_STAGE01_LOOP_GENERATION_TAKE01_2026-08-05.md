# V1.2.2 release polish handoff — A4 Stage 01 loop generation take 01

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: v1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 기준 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 패킷 ID: `A4-STAGE-01-LOOP-GENERATION-TAKE01`
- 결과: `A4_STAGE01_LOOP_GENERATION_TAKE01_PASS_PENDING_LISTENING`

## 2. 이번 패킷 목표

- 요청 사항: 계획된 `ambience_stage01_cave`만 Lyria 3 Pro로 take 1개 생성한다.
- 완료 조건: 실제 유료 요청 1회 성공, 후보 MP3·미리듣기 WAV 검증, API 키 미저장 확인, runtime 승격 없이 청취 단계로 넘긴다.
- 범위에서 제외: 추가 take·추가 자산·자동 재호출·`promote --confirm`·runtime WAV·`SOURCE.md`·event catalog·게임 연결.

## 3. 완료한 작업

- Chrome AI Studio에서 올바른 Ultra 계정 표시와 API 키 복사 버튼 1개를 확인했다.
- API 키는 값 자체를 출력하거나 저장하지 않고 현재 생성 프로세스의 환경 변수로만 전달했다.
- `ambience_stage01_cave`를 `lyria-3-pro-preview`로 1회 생성했다.
- 실제 요청은 1회이며 manifest 기준 예상 비용은 `$0.08`이다.
- 후보 미리듣기 WAV를 생성하고 WAV 구조·길이·해시를 확인했다.
- 생성 뒤 클립보드를 일반 문구로 덮어썼다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tmp/lyria_audio_v122/20260805_stage01_loop_take01/ambience_stage01_cave/take-01/source.mp3` | Lyria 생성 원본 후보, Git 무시 | 청취 필요 |
| `tmp/lyria_audio_v122/20260805_stage01_loop_take01/ambience_stage01_cave/take-01/preview.wav` | 44.1kHz 미리듣기 후보, Git 무시 | 청취 필요 |
| `tmp/lyria_audio_v122/20260805_stage01_loop_take01/ambience_stage01_cave/take-01/generation.json` | 생성 메타데이터, Git 무시 | 확인 완료 |
| `tmp/lyria_audio_v122/20260805_stage01_loop_take01/ambience_stage01_cave/take-01/preview.json` | 렌더 메타데이터, Git 무시 | 확인 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_GENERATION_TAKE01_2026-08-05.md` | 패킷 결과와 청취 단계 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 단일 패킷 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음
- 생성 모델: Google `lyria-3-pro-preview`
- 생성 원본 경로: `tmp/lyria_audio_v122/20260805_stage01_loop_take01/ambience_stage01_cave/take-01/source.mp3`
- `SOURCE.md` 경로: 없음. 사람 승인 전 후보이므로 작성하지 않음
- 런타임 최종 자산 경로: 없음. `assets/audio/ambience/stage01_cave.wav`는 아직 생성하지 않음
- 프롬프트 요약: 좁은 보라빛 동굴의 지속적인 바람, 먼 물방울, 석재 반향. 멜로디·리듬·음성 없이 전투 타격과 경고음을 위한 여백을 유지하도록 요청
- 게임 연결 및 실제 렌더 확인 결과: 게임에는 연결하지 않음. 사람 청취·loop seam·믹스 검수 대기

후보 디렉터리:

`tmp/lyria_audio_v122/20260805_stage01_loop_take01/ambience_stage01_cave/take-01/`

| 파일 | 크기 | SHA-256 | 결과 |
|---|---:|---|---|
| `source.mp3` | 2,763,352 bytes | `499540007347C5454D53A4D7868446D423B1B9CB3BD6FC5BCEAC4952F2077711` | PASS |
| `preview.wav` | 19,913,228 bytes | `DDC51C7944BE024CFCB9576C8B712B4595D6ABEA2CE4D41A31F8D4C15449EA85` | PASS |

`preview.wav`는 2채널, 44.1kHz, 16bit, 112.887초로 정상 판독됐다. 후보 폴더의 Google API 키 형식 문자열은 0건이다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `generate --asset ambience_stage01_cave --takes 1 --run-id 20260805_stage01_loop_take01` | PASS — 유료 호출 없음, 예상 `$0.08` | 터미널 실행 결과 |
| 2 | 같은 명령의 `--execute` | PASS — Lyria 3 Pro 실제 요청 1회 | 후보 `generation.json` |
| 3 | WAV 메타데이터·MP3/WAV SHA-256·키 패턴 검사 | PASS | 후보 디렉터리 |
| 4 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |
| 5 | 사람 청취·실플레이 | NOT_REQUESTED | 다음 승인 gate |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않음
- PASS 이후 기능·데이터·자산 변경 여부: runtime·출처·catalog 변경 없음

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 이 후보는 생성 성공 상태일 뿐 최종 승인 상태가 아니다.
- 사용자가 직접 들어보고 바람·물방울·석재 반향의 분위기와 112초 loop 이음새를 판단해야 한다.
- 전투 타격·경고음과 겹칠 때 거슬리지 않는지, x3 재생에서 밀도가 과하지 않은지 확인해야 한다.
- 사람 승인 전 `promote --confirm`과 runtime 복사는 금지한다.
- 후보는 `tmp/` 아래에 있어 정리 작업으로 사라질 수 있다. 승인 전에는 제품 원본이 아니다.

## 8. 다음 작업 순서

1. `A4-STAGE-01-LOOP-LISTENING-GATE`: 사용자가 위 `preview.wav`를 직접 청취하고 `approve`, `regenerate`, `reject` 중 하나를 결정한다. 자동 재생성하지 않는다.
2. 승인일 때만 `A4-STAGE-01-LOOP-PROMOTE`에서 `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/`의 `SOURCE.md`·원본·생성 기록과 runtime WAV를 만든다.
3. 승격 뒤 event catalog와 Stage 01 runtime 연결을 별도 패킷으로 처리한다.

## 9. 작업 트리 상태

- `git status --short --branch`: 기존부터 다수의 수정·미추적 파일이 있는 혼합 작업 트리
- 이번 패킷의 추적 대상 변경: 이 핸드오프와 `CURRENT.md`
- 후보 산출물: `tmp/lyria_audio_v122/20260805_stage01_loop_take01/`
- 의도하지 않은 기존 변경: 보존했고 되돌리거나 스테이징하지 않음
- 원격 푸시: 하지 않음

## 10. 종료 체크리스트

- [x] Lyria 3 Pro 요청 1회 완료
- [x] 후보 MP3·WAV 구조와 해시 확인
- [x] API 키 미저장 및 후보 폴더 키 패턴 0건 확인
- [x] runtime·출처·catalog 미변경
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 사람 청취 승인
- [ ] runtime 승격 및 게임 연결
- [ ] 의도한 파일만 커밋·원격 푸시
