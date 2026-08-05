# V1.2.2 release polish handoff — A4 Stage 01 Lyria prerequisite gate

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: v1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` / 변경 없음
- 패킷 ID: `A4-STAGE-01-LYRIA-PREREQUISITE-GATE`
- 결과: `A4_STAGE01_LYRIA_PREREQUISITE_GATE_BLOCKED`

## 2. 이번 패킷 목표

Stage 01 loop 생성 전에 전용 Lyria 실행 환경과 보안 키 준비 상태를 읽기 전용으로 확인한다. 생성, 비용 호출, runtime 자산 변경은 이번 패킷 범위가 아니다.

## 3. 실제 변경 경로

| 경로 | 변경 내용 | 상태 |
|---|---|---|
| `docs/qa/V122_A4_STAGE01_LYRIA_PREREQUISITE_GATE_2026-08-05.md` | prerequisite 점검 결과 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LYRIA_PREREQUISITE_GATE_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 패킷과 차단 사유 갱신 | 진행 중 |

## 4. 직접 실행한 테스트

```text
python tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json doctor
```

결과:

```text
python=3.11.9
google.genai=MISSING
miniaudio=MISSING
manifest=OK assets=76
GEMINI_API_KEY=NOT_SET
No network request was made.
```

## 5. 미해결 및 보안 경계

- Lyria 전용 venv, `google.genai`, `miniaudio`가 없다.
- `GEMINI_API_KEY`가 준비되지 않았다.
- 채팅으로 노출된 키는 사용하거나 저장하지 않았다. 해당 키는 폐기·교체해야 한다.
- 외부 생성, 네트워크 요청, 결제, 오디오 runtime 덮어쓰기, manifest 변경은 하지 않았다.

## 6. 다음 작업 순서

1. 사용자가 노출된 키를 폐기하고 새 키를 발급한다.
2. 사용자가 로컬에서 `tools/audio/setup_lyria.ps1`로 전용 환경을 준비한다.
3. 준비 완료 후 동일 prerequisite gate를 다시 실행한다.
4. gate가 통과한 뒤에만 `A4-STAGE-01-LOOP-GENERATION`을 새 단일 패킷으로 제안한다.

## 7. 검수 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_BLOCKED`
- 전체 회귀/빌드: 사용자 요청 범위가 아니므로 실행하지 않음

## 8. 작업 트리 및 푸시

- 기존 혼합 작업 트리는 보존했다.
- 이번 패킷에서 제품 코드·자산·manifest는 변경하지 않았다.
- 커밋·푸시는 하지 않았다.
