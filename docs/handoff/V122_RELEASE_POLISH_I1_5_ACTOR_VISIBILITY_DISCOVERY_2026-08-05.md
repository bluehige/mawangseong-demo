# v1.2.2 I1-5 캐릭터 표시 원인 발견 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (문서 변경은 아직 미커밋)
- 패킷 ID: `I1-5-ACTOR-VISIBILITY-DISCOVERY`
- 결과: `I1_5_ACTOR_VISIBILITY_DISCOVERY_PASS`
- QA: `docs/qa/V122_I1_5_ACTOR_VISIBILITY_DISCOVERY_2026-08-05.md`

## 2. 완료 내용

- 기존 I1-5 보스 대표 장면을 Vulkan 1280×720으로 1회 실행했다.
- 상태 단언 11개와 캡처 4개가 모두 통과했다.
- Unit 초기화·프레임 연결·전투 화면 가시성·UnitYSort 깊이 슬롯·FrontWallLayer 앞가림 경계를 읽기 전용으로 대조했다.
- 캐릭터 몸체가 사라지는 주원인이 스프라이트 로딩이 아니라, GameRoot 부모 draw(z=0)에 그려지는 전체 벽 본체와 UnitYSort 음수 깊이 슬롯의 계층 불일치임을 확인했다.

## 3. 변경 파일

이번 패킷의 실제 변경은 다음 문서 2개와 `docs/handoff/CURRENT.md` 갱신뿐이다.

- `docs/qa/V122_I1_5_ACTOR_VISIBILITY_DISCOVERY_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_I1_5_ACTOR_VISIBILITY_DISCOVERY_2026-08-05.md`
- `docs/handoff/CURRENT.md`

제품 코드, 데이터, 그래픽·오디오 자산은 수정하지 않았다.

## 4. 직접 테스트와 화면 확인

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
```

캡처 4개는 1280×720으로 저장됐다. 화면에서는 UI·전투 표식·VFX 고리는 보이지만 중앙 캐릭터 몸체가 벽 뒤로 과도하게 가려진다. 실행 종료 시 CanvasItem/ObjectDB 누수 경고가 남았다.

## 5. 미해결 문제와 다음 순서

- 벽 본체를 선언된 `BackWallLayer` 소유로 이동하거나 동등한 z 경계를 확보하는 구현이 아직 없다.
- E/S `front_occluder`는 낮은 국소 앞가림으로 유지하되, 전체 벽 본체와 유닛의 부모·자식 CanvasItem 순서를 함께 검증해야 한다.
- 다음 잠금 패킷은 `V4-A-03-FRONT-OCCLUDER-SCOPE`다. 제안만 기록하고 이 turn에서는 실행하지 않는다.

## 6. 핸드오프 상태

- 작업 트리: 기존 Luna·사용자 미커밋 변경이 섞여 있다. 되돌리거나 정리하지 않았다.
- 원격 푸시: 하지 않았다.
- 전체 회귀·전체 플레이 검수·빌드: 요청 범위가 아니므로 실행하지 않았다.
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
