# v1.2.2 I1-5-OWNER-01 전투 VFX 대표 화면 검수 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: 변경 사항 미커밋
- 패킷: `I1-5-OWNER-01`
- 결과: `I1_5_OWNER_SCREEN_BLOCKED`
- QA: `docs/qa/V122_I1_5_OWNER_VFX_SCREEN_REVIEW_2026-08-05.md`
- 원격 푸시: 실행하지 않음

## 2. 검수 결과

Windows Vulkan `1280×720` 대표 장면을 현재 런타임에서 1회 실행했다. 11개 상태 단언과 4개 캡처 생성은 통과했지만, 화면에서 중앙 캐릭터가 전면 벽에 대부분 가려지고 `front_fx` ring이 벽 위에 분리되어 보여 VFX anchor·depth 관계를 승인할 수 없었다. 소유자 시각 승인도 보류한다.

## 3. 실제 변경 경로

- `docs/qa/V122_I1_5_OWNER_VFX_SCREEN_REVIEW_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_I1_5_OWNER_VFX_SCREEN_REVIEW_2026-08-05.md`
- `docs/handoff/CURRENT.md`

제품 코드·데이터·그래픽·오디오 자산은 변경하지 않았다. 실행 캡처와 로그는 기존 `tmp/v122_release_polish/i1_5_boss_final/` 검수 경로에 갱신됐다.

## 4. 직접 검수

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
```

해상도 1280×720과 Vulkan 실행은 확인했다. 종료 시 `CanvasItem` RID 1건과 `ObjectDB instances` leak 경고가 있었다.

## 5. 미해결 문제와 다음 순서

- VFX depth가 renderer의 유닛 슬롯·`wall_front` 계층과 연결되지 않아 실제 화면에서 캐릭터와 효과의 앞뒤 관계가 끊어진다.
- 캐릭터가 충분히 보이지 않아 anchor·상대 크기·강도 체감의 소유자 승인을 진행할 수 없다.
- 다음 잠금 후보: `V5-DEPTH-OCCLUSION-LIVE-CONTRACT` — VFX depth를 실제 renderer/전면 벽 계층에 연결하고 전용 화면 테스트로 재검증.
- 이번 핸드오프에서는 다음 패킷을 실행하지 않는다.

## 6. 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_BLOCKED`
- 커밋·푸시·빌드: 실행하지 않음
