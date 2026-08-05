# V1.2.2 릴리스 폴리시 F0-A 오디오 인벤토리 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-02
- 목표 버전: V1.2.2 release polish
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `origin/main` merge-base `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 기준 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- PR/태그: 없음 (사용자 요청 전 커밋·푸시하지 않음)

## 2. 이번 세션 목표

- 요청 사항: Luna 순차 실행 계획의 다음 패킷인 `F0-A`를 읽기 전용으로 완료한다.
- 완료 조건: 현재 WAV 76개의 경로·길이·포맷·SHA-256·import loop·버스·출처·실제 런타임/데이터/미연결 상태와 사람 청취 상태를 고정하고, 다음 A0/A1에서 처리할 BGM 루프·연결 공백·문서 충돌을 근거와 함께 남긴다.
- 제외 범위: 오디오 파일 교체/재생성, 런타임·데이터·import 설정 수정, 유료 Lyria 호출, 전체 회귀, 전체 플레이, 빌드, 커밋 및 푸시.

## 3. 완료 내용

- `assets/audio/**/*.wav` 76개를 Python `wave`·SHA-256으로 읽어 인벤토리 JSON/TSV를 생성했다.
- 런타임 호출 54개, 데이터만 연결 12개, 호출 미확인 10개로 구분했다. Update 3의 `enemy_%s` 동적 경고 cue와 심장 loop override를 코드 계약으로 따로 확인했다.
- 출처를 Lyria 28개와 로컬 결정적 합성 48개로 구분했다. 모든 파일은 Lyria manifest 76개 항목에 대응하지만, 사람 청취 승인은 전부 `pending`이다.
- BGM은 관리/일반 전투/보스 3종만 실제 코드에 연결되어 있고, 일반 전투만 import loop가 켜져 있음을 확인했다. 관리·보스 BGM의 종료 후 재시작 경로 부재를 출시 공백으로 기록했다.
- `assets/audio/bgm/SOURCE.md`의 procedural 30초 표기와 실제 WAV/Lyria SOURCE·manifest 기록의 충돌을 정정하지 않고 A0 대상으로 남겼다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_F0A_AUDIO_INVENTORY_2026-08-02.md` | 76개 오디오의 연결·출처·루프·버스·공백 요약 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_F0A_AUDIO_INVENTORY_2026-08-02.md` | 이번 패킷의 근거·검증·다음 작업 인계 | 완료 |
| `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md` | F0-A 완료 및 F0-R 대기 상태 반영 | 완료 |
| `docs/handoff/CURRENT.md` | F0-A 핸드오프 링크와 다음 작업 갱신 | 완료 |

임시 기계 산출물은 `tmp/v122_release_polish/f0_a/`에만 두었다.

## 5. 그래픽·오디오 자산과 실제 렌더 확인

- 신규 그래픽·오디오 생성 및 자산 교체: 없음.
- 오디오 원본·manifest: 읽기 전용으로 대조했다.
- 실제 화면 캡처: F0-A 범위에는 없음. 오디오 파일을 변경하지 않았으므로 별도 화면 렌더는 실행하지 않았다.
- 사람 청취: 수행하지 않음. 76개 모두 `pending`이며 승인으로 간주하지 않는다.

## 6. 테스트 및 검증

| 순서 | 검증 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `python -m unittest tools.audio.test_lyria_pipeline` | PASS (12 tests) | 콘솔 `Ran 12 tests ... OK` |
| 2 | F0-A 인벤토리 생성 | PASS | `tmp/v122_release_polish/f0_a/f0_a_inventory.json` 요약 76/54/12/10 |
| 3 | JSON 고정 assertion (manifest 76개, Lyria 28개, procedural 48개, 청취 pending 76개) | PASS | 콘솔 `F0A_INVENTORY_ASSERTS_OK` |
| 4 | 전체 회귀/전체 플레이/전체 출시 검수 | NOT_REQUESTED | 이번 요청은 F0-A 읽기 전용 인벤토리 범위 |

### 정책 CI용 고정 필드

- Related tests: `python -m unittest tools.audio.test_lyria_pipeline` — PASS (12개)
- UI check: 해당 없음 — 오디오·코드 변경 없이 읽기 전용 인벤토리만 수행
- Unresolved issues: 관리·보스 BGM 루프 없음, Update 4 오디오 12개 데이터-only, Update 3 미연결 10개, `combat_dungeon_pressure` SOURCE.md 충돌, 사람 청취 승인 0개

## 7. 미해결 문제와 위험

- 관리/보스 BGM은 114~115초 뒤 종료할 수 있다. 루프를 켜거나 상태별 새 곡으로 교체하기 전에는 출시 완료로 볼 수 없다.
- Update 4 rival motif 3개와 계약/왕관 SFX 9개는 JSON에만 연결되어 실제 이벤트에서 재생되는지 확인되지 않았다.
- `heart_ready`와 `monster_signature_01~09`는 현재 소비자가 없다. 삭제·보존·연결을 임의로 결정하지 않는다.
- `AudioSettings.gd`에는 Master/Music/SFX만 있고 limiter·UI/환경 분리·전역 동시 재생 상한이 없다.
- `combat_dungeon_pressure.wav`의 소스 문서가 실제 파일·Lyria 기록과 다르다.

## 8. 다음 작업 순서

1. `F0-R` 출시 공백 인벤토리
2. `A0` 출처·manifest·연결 계약 정정
3. `A1-A~E` 타격음·BGM·환경음·믹스 정책 패킷

F0-A에서 런타임 코드를 수정하지 않았으므로 다음 패킷은 이 핸드오프와 JSON/TSV를 입력으로 사용한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification` (origin보다 2커밋 앞섬)
- F0-A에서 새로 만든 문서: QA 보고서와 본 핸드오프
- 임시 산출물: `tmp/v122_release_polish/f0_a/` (커밋 대상 아님)
- 기존 사용자 변경: 6개 `.png.import` 수정, 7개 `.uid` 미추적, 기존 Luna 계획 문서와 CURRENT 변경을 보존
- 커밋/푸시: 수행하지 않음

## 10. 종료 체크리스트

- [x] 76개 WAV 인벤토리와 SHA-256 생성
- [x] 실제 런타임/데이터-only/미연결 구분
- [x] Lyria/procedural 출처 구분 및 청취 상태 기록
- [x] BGM 루프·버스·동시 재생 정책의 현재 상태 기록
- [x] 관련 테스트 실행
- [x] QA 문서와 CURRENT/계획 갱신
- [ ] 오디오 자산·런타임 수정 (다음 패킷)
- [ ] 커밋·푸시 (사용자 요청 전 보류)
