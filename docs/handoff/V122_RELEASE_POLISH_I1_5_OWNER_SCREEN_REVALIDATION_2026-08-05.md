# v1.2.2 I1-5 소유자 화면 재검수 핸드오프

## 1. 메타데이터

- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (문서 변경은 미커밋)
- 패킷: `I1-5-OWNER-SCREEN-REVALIDATION`
- 결과: `I1_5_OWNER_SCREEN_REVALIDATION_PASS`
- QA: `docs/qa/V122_I1_5_OWNER_SCREEN_REVALIDATION_2026-08-05.md`

## 2. 완료 내용

앞선 A03·V5·V4-B 보정 뒤 I1-5 보스 대표 장면을 `1280×720`으로 한 번 실행했다. Godot `4.5.2` Vulkan 환경에서 상태 단언 11개와 캡처 4개가 모두 통과했다. 캐릭터 몸체, 지면·몸·공중 VFX, 검수 예고·자비의 방벽, 보스 UI의 앞뒤 관계를 화면으로 확인했으며 이전 벽 가림·VFX 분리 차단 상태는 해소됐다.

## 3. 실제 변경 경로

- `docs/qa/V122_I1_5_OWNER_SCREEN_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_I1_5_OWNER_SCREEN_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

코드·데이터·스토리·밸런스·그래픽 자산·오디오는 변경하지 않았다.

## 4. 실행한 직접 테스트와 UI 확인

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
```

대표 해상도 `1280×720`에서 캐릭터가 벽에 묻히지 않고, VFX가 의도한 계층에 붙으며, 보스 이름·HP·하단 명령 rail이 가독성을 유지하는 것을 확인했다.

## 5. 미해결 및 다음 순서

- 실제 소유자의 Windows 후보 조작과 헤드폰·일반 스피커 청취 승인은 남아 있다.
- `I1-5-OWNER-SCREEN-REVALIDATION` 다음은 `A4-STAGE-01-LOOP-READINESS-AUDIT` 단일 패킷으로 제안한다. Stage 01 환경 loop 한 개의 출처·승격 전제와 현재 Ambience 연결 준비만 읽기 전용으로 확인하며, 사용자 음원 생성·비용·청취 승인 전에는 자산이나 런타임을 수정하지 않는다.

## 6. 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
- 커밋·푸시·빌드: 수행하지 않음
- 작업 트리: 기존 사용자·Luna 미커밋 변경을 보존함
