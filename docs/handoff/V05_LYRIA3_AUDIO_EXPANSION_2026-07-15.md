# v0.5 Lyria 3 상황·스킬 오디오 확장 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5
- 작업 브랜치: `codex/v05-steam-release-readiness`
- 기준 브랜치 및 SHA: `main` / `d5a2d24457edcb919ae3ae4fe1d642552097f9c8`
- 작업 시작 SHA: `dc241bc149d5ce2a36859a12eb76ff494ec6e5e2`
- 마지막 구현·검수 SHA: `6eef61ad89730c7a3ae00e05172c873d88159570`
- 원격 푸시 여부: 미실행, upstream 없음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 선택한 BGM Take 1과 타격음 Take 2를 적용하고, 단조로운 공통 사운드 재사용을 줄여 상황별 BGM과 스킬별 고유 효과음을 만든다.
- 완료 조건: 관리·일반전·보스전 음악이 구분되고, 코어·update3 직접 전투 스킬 24개가 각자 다른 Lyria 음원을 사용하며, 원본·프롬프트·해시를 보존하고 관련 테스트가 통과한다.
- 범위에서 제외한 사항: 전체 회귀·전체 플레이·별도 검수 에이전트, 사람의 최종 지각 음량·반복 피로 청취, 매니페스트의 나머지 기존 48개 WAV 재생성.

## 3. 완료한 작업

- 선택 반영: `combat_dungeon_pressure` Take 1과 `combat_hit` Take 2를 런타임에 승격했다.
- 상황별 음악: 관리 화면용 `management_castle_bustle`, 일반 전투용 선택 BGM, 보스 전투용 `combat_boss_council`의 세 트랙을 연결했다.
- 전환 규칙: 일반 전투에서 보스가 등장하면 보스곡으로, 보스 격퇴 뒤 전투가 계속되면 일반 전투곡으로 전환한다. 경쟁 마왕처럼 데이터 `role_tags`로 정의된 보스도 판별한다.
- 스킬 팔레트: 코어·update3 몬스터의 직접 전투 스킬 24개에 `assets/audio/sfx/skills/<skill>.wav`를 하나씩 배정했다.
- 레이어링: 스킬 발동음은 각 스킬의 재질 서명·동작/마력·짧은 음조 확인의 세 레이어로 만들고, 기존 베기·화염·피격음은 실제 공격 접촉 레이어로 유지했다.
- 자동 스킬: 톡톡·코코·베베의 자동 발동 경로도 같은 스킬별 음원을 재생한다.
- 매니페스트: 런타임 WAV 76개 전체를 73 Clip + 3 Pro로 관리한다. 전체 2테이크 계획은 실행 당시 공식 단가 기준 USD 6.32다.
- API 실행: 이번 확장에서 Clip 24회와 Pro 2회를 오류·재시도 없이 생성했다. 예상 요청 비용은 USD 1.12이며 최초 후보 4회까지 포함한 누적 예상 요청 비용은 USD 1.36이다.
- 출처 보존: 승격한 28개 자산의 원본 MP3·generation JSON·`SOURCE.md`를 `assets/source/audio/lyria/v0.5/`에 기록했다. Lyria 프리뷰 응답이 Interaction ID 값을 반환하지 않은 경우 빈 값 대신 그 사실을 기록한다.
- 대용량 정책: BGM WAV와 Lyria 원본 MP3를 Git LFS로 추적한다.
- 스토리·밸런스·저장 호환성: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/CombatSceneController.gd` | 24개 스킬 음원 매핑·수동/자동 발동·보스 등장 음악 갱신 | 완료 |
| `scripts/game/GameRoot.gd` | 관리/일반전/보스전 음악 선택과 보스 등장·격퇴 전환 | 완료 |
| `assets/audio/bgm/` | 선택 BGM 교체와 관리·보스 BGM 추가 | 완료 |
| `assets/audio/sfx/combat_hit.wav` | 선택한 타격음 Take 2 적용 | 완료 |
| `assets/audio/sfx/skills/` | 직접 전투 스킬 24개 고유 WAV | 완료 |
| `assets/source/audio/lyria/v0.5/` | 28개 승격 원본·프롬프트·해시·후처리 기록 | 완료 |
| `tools/audio/lyria_v05_manifest.json` | 76개 런타임 자산 계약과 스킬·상황별 프롬프트 | 완료 |
| `tools/audio/lyria_pipeline.py` | 3레이어 SFX 지시와 미반환 Interaction ID 명시 | 완료 |
| `tools/audio/test_lyria_pipeline.py` | 매핑·형식·고유 해시·출처·키 비노출 회귀 | 12/12 PASS |
| `tools/tests/SkillAudioPaletteTest.*` | 24개 스킬 리소스의 고유 경로·재생 프레임 검사 | 74 assertions PASS |
| `tools/tests/MusicStateAudioTest.*` | 세 음악 상태와 보스 등장·격퇴 전환 검사 | 12 assertions PASS |
| `.gitattributes` | 대용량 BGM·생성 원본 Git LFS 추적 | 완료 |
| `docs/audio/LYRIA3_INTERACTIONS_WORKFLOW.md` | 76개 범위·비용·승격 상태·한계 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 생성 모델: `lyria-3-clip-preview` 24회, `lyria-3-pro-preview` 2회
- 생성 원본 경로: `assets/source/audio/lyria/v0.5/<asset-id>/source.mp3`
- `SOURCE.md` 경로: `assets/source/audio/lyria/v0.5/<asset-id>/SOURCE.md`
- 런타임 최종 자산 경로: `assets/audio/bgm/*.wav`, `assets/audio/sfx/combat_hit.wav`, `assets/audio/sfx/skills/*.wav`
- 프롬프트/후처리 요약: 스킬은 고유 재질·동작/마력·음조 확인의 3레이어 소스 릴에서 0.42~0.84초 mono 44.1kHz WAV를 추출했다. 음악은 약 114~117초 stereo 44.1kHz WAV와 2초 루프 크로스페이드를 사용한다.
- 게임 연결 및 실제 렌더 확인 결과: Godot import, 24개 스킬 프리로드, 세 음악 상태와 보스 전환이 PASS다. 사람의 최종 믹스 청취는 아직 하지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `python tools/audio/lyria_pipeline.py validate` | PASS | `assets=76`, `coverage=all-current-wav` |
| 2 | `python -m unittest tools.audio.test_lyria_pipeline -v` | PASS, 12/12 | 24 스킬·3 BGM 고유 해시, 형식, 출처 28건, 키 비노출 포함 |
| 3 | `python -m py_compile ...` | PASS | 파이프라인·테스트 구문 검사 |
| 4 | Godot 4.5.2 `--headless --path . --import` | PASS | 신규 BGM·스킬 WAV import 완료 |
| 5 | `SkillAudioPaletteTest.tscn` | PASS, 74 assertions | 24개 고유 경로와 재생 프레임 |
| 6 | `MusicStateAudioTest.tscn` | PASS, 12 assertions | 관리·일반전·보스전, 보스 등장·격퇴·데이터 태그 전환 |
| 7 | `PresentationPhase29Test.tscn` | PASS, 110 assertions | 기존 오디오·프레젠테이션 계약 유지 |
| 8 | 후보 WAV 기술 분석 | PASS | 스킬 24/24 고유 source/preview 해시, mono 44.1kHz·비무음; 음악 3/3 고유 해시, stereo 44.1kHz·약 114~117초 |
| 9 | API 키 패턴 스캔 | PASS | 관련 코드·문서·원본 메타데이터 0건 |
| 10 | `git diff --check` | PASS | 공백 오류 0건 |
| 11 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 저장소 정책에 따라 미실행 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 사용자 요청 범위의 자동 검사는 완료했다. 전체 플레이·사람의 청취 믹스 검수는 요청되지 않아 실행하지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `6eef61ad89730c7a3ae00e05172c873d88159570` 이후에는 `docs/handoff/` 문서만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 6eef61ad89730c7a3ae00e05172c873d88159570
- Review range: d5a2d24457edcb919ae3ae4fe1d642552097f9c8..6eef61ad89730c7a3ae00e05172c873d88159570
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 사용자가 채팅에 붙인 API 키는 노출된 키다. 저장소에는 없지만 즉시 폐기하고 새 키를 발급해야 한다.
- Lyria 3는 전용 Foley 모델이 아니다. 자동 검사는 무음·형식·해시·경로 차이를 검증하지만, 실제 풍성함·타격감·반복 피로는 헤드폰과 스피커 플레이 청취로 확정해야 한다.
- Lyria 프리뷰의 이번 응답은 Interaction ID 값을 반환하지 않았다. 원본 해시·프롬프트 해시·생성 시각·모델은 보존했다.
- update4의 실키·포포 스킬 정의 4개는 이미 각자 전용 기존 cue를 가리키므로 이번 24개 직접 전투 매핑에는 포함하지 않았다.
- 매니페스트의 기존 보조 cue 48개는 생성 준비가 끝났지만 이번 세션에서 Lyria로 재생성하지 않았다. 핵심 상황·직접 스킬의 단조로움 해소를 우선했다.

## 8. 다음 작업 순서

1. 실제 전투에서 스킬 24개와 세 BGM의 버스 음량·접촉 타이밍·반복 피로를 청취하고 필요한 자산만 재테이크 또는 dB 조정한다.
2. 노출된 키를 폐기한 뒤, 필요하면 새 키를 가려진 입력으로 제공해 나머지 보조 cue 48개의 후보를 단계별 생성·청취·승격한다.
3. v0.5 릴리스 통합 때 Git LFS 객체 포함 여부와 Windows/Web 빌드 오디오 재생을 확인한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v05-steam-release-readiness`
- 마지막 구현·검수 SHA: `6eef61ad89730c7a3ae00e05172c873d88159570`
- 미커밋 파일: 이 핸드오프와 `CURRENT.md`만 문서 커밋 예정
- 의도하지 않은 기존 변경: 없음. Godot import가 갱신한 기존 `.import` 138개는 검수 후 원상 복구했다.
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물: 없음. API 후보 run은 ignored `tmp/lyria_audio/`에 유지된다.
- 원격 푸시·PR·태그: 미실행

## 10. 종료 체크리스트

- [x] 선택 BGM Take 1·타격음 Take 2 적용
- [x] 관리·일반전·보스전 음악 구분과 전환
- [x] 직접 전투 스킬 24개 고유 음원·레이어 연결
- [x] 28개 원본·프롬프트·해시·후처리 기록
- [x] API 키 비노출 검사
- [x] 관련 Python·Godot 테스트 통과
- [x] 요청되지 않은 전체 회귀·검수 에이전트 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 구현 파일만 커밋
- [x] 원격 미푸시 상태 기록
