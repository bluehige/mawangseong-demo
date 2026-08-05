# v1.2.2 A4 Stage 01 환경 loop 승격 검증

검수일: 2026-08-05
대상 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
패킷: `A4-STAGE-01-LOOP-PROMOTE`

## 목적

사용자 승인을 받은 `ambience_stage01_cave` take 1개를 제품 source/runtime 경로로 승격하고, v1.2.2 manifest에서 `active` 상태와 현재 WAV coverage를 확인했다. event catalog와 게임 연결은 이번 범위에서 제외했다.

## 직접 실행 결과

1. 첫 `promote --confirm`은 runtime 상위 폴더 `assets/audio/ambience/`가 없어 중단됐다. source MP3가 먼저 복사된 부분 상태가 남았다.
2. 정확한 runtime 상위 폴더를 만든 뒤 같은 승인 후보에 `--force`를 사용해 재실행했다.
3. 승격 결과:
   - runtime: `assets/audio/ambience/stage01_cave.wav`
   - source: `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/source.mp3`
   - 출처 기록: `SOURCE.md`, `generation.json`
4. `tools/audio/lyria_v122_manifest.json`의 상태를 `planned`에서 `active`로 전환했다.
5. v1.2.2 manifest 검증:

```text
manifest=OK assets=77 coverage=all-current-wav
```

## 자산 무결성

| 파일 | SHA-256 | 결과 |
|---|---|---|
| `assets/audio/ambience/stage01_cave.wav` | `DDC51C7944BE024CFCB9576C8B712B4595D6ABEA2CE4D41A31F8D4C15449EA85` | 후보 preview와 일치 |
| `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/source.mp3` | `499540007347C5454D53A4D7868446D423B1B9CB3BD6FC5BCEAC4952F2077711` | 후보 source와 일치 |

`SOURCE.md`에는 Lyria 3 Pro 모델, 생성일, v1.2.2, source/runtime 경로, SHA-256, `store=false`, SynthID 워터마크와 명시적 승인 승격 문구가 기록됐다. source 기록과 generation JSON의 Google API 키 패턴은 0건이다.

## 테스트 상태

| 검수 | 결과 | 비고 |
|---|---|---|
| v1.2.2 manifest validate | PASS | 77개 coverage |
| 기존 `python -m unittest tools.audio.test_lyria_pipeline -q` | BLOCKED | 기본 v0.5 manifest가 새 runtime 1개를 누락으로 판정해 `setUpClass`에서 0개 테스트 실행 |

실패 원인:

```text
Manifest coverage mismatch. missing=['assets/audio/ambience/stage01_cave.wav'], stale=[]
```

현재 패킷 허용 경로에는 기본 v0.5 manifest와 해당 테스트 파일이 없으므로 임의로 수정하지 않았다. 다음 `A4-STAGE-01-POST-PROMOTE-MANIFEST-ALIGNMENT` 패킷에서 현재 v1.2.2 manifest를 테스트 fixture로 정렬하고 전체 단위 테스트를 다시 실행해야 한다.

## 범위 경계

- 추가 음원 생성 없음
- 다른 자산 승격 없음
- event catalog·AudioDirector·Stage runtime 재생 연결 없음
- 사람 청취 승인은 이전 패킷에서 완료
- 전체 회귀·빌드·커밋·푸시는 요청되지 않아 실행하지 않음

## 판정

`A4_STAGE01_LOOP_PROMOTE_PASS_WITH_LEGACY_MANIFEST_TEST_ALIGNMENT_BLOCKED`

승인된 Stage 01 환경 loop의 제품 source/runtime 승격과 v1.2.2 coverage는 성공했다. 그러나 기존 단위 테스트의 기본 manifest 정렬이 남아 있으므로 전체 관련 테스트 기준으로는 완료 처리하지 않는다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_BLOCKED`
