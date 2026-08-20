# 현재 작업 핸드오프

최종 갱신: 2026-08-20

이 문서는 **최신 `main`에서 지금 필요한 사실·활성 작업·다음 진입점만** 제공한다. 과거 진행 기록은 `docs/handoff/archive/current/README.md`에서 날짜와 버전 순서로 찾는다.

## 1. 권위 기준

- 작업 정책의 권위는 `main:AGENTS.md`, 제품 현재 상태의 권위는 `main:docs/handoff/CURRENT.md`다.
- 현재 작업트리가 `main`이 아니면 작업트리의 `CURRENT.md`를 제품 현재 상태로 사용하지 않는다.
- 비-`main` 작업트리에서는 아래를 먼저 확인한다.

```powershell
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
git show main:AGENTS.md
git show main:docs/handoff/CURRENT.md
```

- `main`과 `origin/main`이 다르거나 원격 최신성을 확인하지 못했으면 현재 권위를 확정하지 말고 보고한다.
- 과거 브랜치의 `CURRENT.md`에 적힌 `현재`, `다음 작업`, `최신 안정판`은 그 브랜치가 작성된 당시의 기록일 뿐이다.
- 작업트리가 더럽다면 브랜치를 전환하지 말고 `git show main:...` 또는 `git worktree list`로 확인한 깨끗한 `main` 작업트리를 사용한다.
- 현재 지시 검색에서는 `docs/handoff/archive/**`, `tmp/**`, `output/**`, `builds/**`, `web_Demo/**`를 제외한다.

## 2. 현재 제품 기준선

- 현재 공개 안정판: `1.2.5`
- 불변 출시 태그와 제품 SHA: `v1.2.5` / `f757ffa9f9e962158f2123856c8568a3163ecb6c`
- 이 문서 정리를 시작할 때의 `main` SHA: `ce601b81b8f283543a04867e11632d0e87beea3c`
- 위 기준 SHA까지 태그 이후 변경은 v1.2.5 출시 완료 기록을 추가한 문서 전용 마감이다. 현재 `main` SHA는 `git rev-parse main`으로 확인한다.
- GitHub Release: <https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.5>
- 공개 Web: <https://bluehige.github.io/mawangseong-demo/web_Demo/>
- 출시 완료 근거: `docs/handoff/V125_RELEASE_COMPLETE_2026-08-10.md`

출시 시점에는 Full 158/158과 당시 P1/P2/P3 0건이 기록됐다. 이는 **2026-08-13에 새로 접수된 플레이 감각·AI·UI·대사·그래픽 품질 피드백이 해결됐다는 뜻이 아니다.** 자동 검증과 부팅 성공은 대중적 체감 품질의 증거로 승계하지 않는다.

## 3. 현재 활성 작업

- 작업명: v1.2.6 전투 지휘·AI·관리 UX 정식 출시 후보
- 작업 단계: `GODOT_4_6_3 / MINIMAL_TARGETED_RELEASE`
- 피드백 상태: `FDB-20260820-001`~`004 FIXED → RETESTED`
- 공개 기준: `v1.2.5@f757ffa9f9e962158f2123856c8568a3163ecb6c`
- 출시 후보 브랜치: `codex/v126-release-candidate`
- Reviewed product SHA: `2c2d46ca339cb9d298d0ab3051b22fa649c41c73`
- 최신 출시 후보 핸드오프: [V126_RELEASE_CANDIDATE_2026-08-20.md](V126_RELEASE_CANDIDATE_2026-08-20.md)
- 사용자 피드백 수정 핸드오프: [V126_USER_FEEDBACK_AI_UX_FIX_2026-08-20.md](V126_USER_FEEDBACK_AI_UX_FIX_2026-08-20.md)
- 확정 실행 계획: [V126_PRODUCT_QUALITY_AUDIT_PLAN_2026-08-13.md](V126_PRODUCT_QUALITY_AUDIT_PLAN_2026-08-13.md)
- CURRENT 교정 기록: [CURRENT_REORGANIZATION_2026-08-13.md](CURRENT_REORGANIZATION_2026-08-13.md)
- 최신 사용자 지시에 따라 정식 엔진 기준을 Godot `4.6.3`으로 전환하고 Full·8인 역할 검수 대신 핵심 명령·AI·지침·건설·이름표·버전 표적 검수만 수행한다.
- 기존 4.6.3 QA ZIP은 기능 확인용으로만 남기고 최종 `main` merge SHA에서 Windows 정식 프리셋으로 다시 생성한다.

## 4. 사용자 확정 방향

1. 제품 매력 우선순위: `전술 지휘 쾌감 → 몬스터 애착 → 행정·상황 코미디`
2. 유효 명령은 최대 0.3초 안에 반응하고 지속시간 동안 평상시 AI보다 우선한다.
3. 수행 불가 시 대상 근처 이펙트와 비모달 소형 알림으로 `거부 이유 + 가능한 해결 행동`을 표시한다.
4. AI는 역할에 맞게 영리하되 독단적이지 않은 `예측 가능한 유능함`을 지향한다.
5. 기준 사용자는 전략게임 초보자이며 숙련 깊이는 별도 보조 기준으로 본다.
6. 한 화면 한 목적, 상시 핵심 행동 최대 3개, 중요 행동 2단계 이내를 지향한다.
7. 핵심 몬스터는 짧고 자주 반응하는 공동 주연이며 시스템 설명은 UI와 바티가 담당한다.
8. 마왕은 가벼운 허당미를 유지하되 후반 결정적 순간에는 신뢰받는 지휘관으로 성숙한다.
9. 기본 분위기는 계속 가볍게 유지하며, 마왕의 후반 성숙 장면만 진지함을 강화한다.
10. 미술은 실제 게임 크기에서 깨끗한 스타일라이즈드 2D를 우선하고 자글거림·계단·이동 중 shimmer를 결함으로 본다.
11. Windows PC가 품질 합격 기준이며 Web·모바일 등은 테스트 범위다.
12. 검수 대상은 타이틀부터 DAY 30까지의 전체 출시본이며, 실행 순서는 `핵심 전투·UI → 대사·그래픽 → 전체 캠페인`으로 나눈다.
13. 블라인드 검수단은 전략게임 초보 3명, 디자인 관심 게이머 2명, 스토리 관심 게이머 2명, 전략게임 숙련자 1명으로 구성한다.
14. 오디오·효과음·믹스를 검수 범위에 포함한다.
15. 검수 뒤 수정본의 목표 버전은 `v1.2.6`이며 기존 `v1.2.5` 태그는 보존한다.
16. 각 단계는 `검수 → 수정 → 재검수 통과`를 완료한 뒤에만 다음 단계로 넘어간다.
17. 역할별 AI 에이전트 8명의 단계별 검수·수정·재검수를 근거로 Codex가 `v1.2.6` 완성 판정을 내리고 완성품을 사용자에게 전달한다. 사용자와 지인의 테스트는 그 이후 진행하며, 새 피드백이 오면 별도 후속 개선 주기로 접수한다. 인간 테스트는 이번 완성 판정의 선행 게이트가 아니다.
18. 단계 게이트는 재현 가능한 P1/P2 0건, 독립 검수 8명 중 6명 이상 통과, 디자인 또는 스토리 담당 2명의 동일 핵심 결함 지적 시 보류로 한다. P3는 기록 후 다음 단계 진행이 가능하다.
19. 현재 수정 사항을 공통 런타임과 전체 캠페인 회귀에 적용해 `v1.2.6` 정식판으로 승격하고 `main`에 반영한다.
20. 정식 엔진은 Godot `4.6.3`으로 고정하고, 이번 출시는 Full·8인 역할 검수 대신 핵심 기능 표적 검수만 거쳐 `main`·`v1.2.6` 태그·Release로 등록한다. 이 최신 지시는 이번 출시의 4.5.2·Full 선행 요구를 대체한다.

## 5. 범위 경계와 교정 사항

- 이번 버전 오인의 직접 원인은 루트 안내가 `게임소스/`를 현재 구현 진입점으로 고정하고, 그 폴더의 과거 v20 브랜치 `CURRENT.md`가 자신을 단일 진입점으로 표시한 데 있다. 폴더명 대신 Git branch·HEAD·`main`·`origin/main`과 권위 문서 쌍을 확인하도록 루트·main·과거 작업트리 안내를 교정했다.
- 기존 `release/v2.0`과 `codex/v20-*`는 과거 DAY 1~5 실험·검증 참고선이다.
- 해당 브랜치의 UI·명령·AI 구현이나 `CURRENT.md`를 현재 제품으로 간주하지 않으며, 커밋 범위를 1.2.6에 그대로 이식하지 않는다.
- 이번 검수는 2.0 제품 개발 계획이 아니다. v20에서 얻은 아이디어는 비교 근거로만 사용하고 v1.2.5 기반의 1.2.6 런타임에서 다시 구현·확인했다.
- 목표 버전은 `1.2.6`으로 확정됐고 기존 `v1.2.5` 태그와 Release는 불변으로 보존한다.
- `INT-20260820-020`: Godot 4.6.3 정식 기준과 최소 표적 검수 출시가 `USER_CONFIRMED`됐으며, 이번 출시에 한해 과거 4.5.2 고정과 Full·8인 선행 게이트는 `SUPERSEDED`다.

## 6. 다음 작업 순서

1. Godot 4.6.3 엔진·workflow·Steam·manifest 계약을 정렬한다.
2. 명령·AI·지침·건설·이름표·버전 핵심 표적 검수를 실행한다.
3. 후보 브랜치를 원격에 푸시하고 `main` PR을 merge commit으로 병합한다.
4. 병합된 `main` SHA로 Godot 4.6.3 Windows 정식 빌드·manifest·부팅을 검증한다.
5. `v1.2.6` 태그와 GitHub Release를 등록하고 출시 완료 핸드오프로 마감한다.

## 7. 아직 필요한 사용자 결정

- 현재 출시 범위의 추가 결정 없음. 새 제품 방향이나 범위 확대가 발견될 때만 별도로 확인한다.

## 8. 과거 기록 찾기

- v1.2.6 출시 후보: [V126_RELEASE_CANDIDATE_2026-08-20.md](V126_RELEASE_CANDIDATE_2026-08-20.md)
- v1.2.6 릴리스 노트: [V1_2_6_RELEASE_NOTES_2026-08-20.md](../release/V1_2_6_RELEASE_NOTES_2026-08-20.md)
- CURRENT 분할 전 전체 원문과 버전별 탐색표: [역사 백업 인덱스](archive/current/README.md)
- v1.2.5 출시 완료: [V125_RELEASE_COMPLETE_2026-08-10.md](V125_RELEASE_COMPLETE_2026-08-10.md)
- v1.2.5 후보 수정: [V125_RELEASE_CANDIDATE_2026-08-10.md](V125_RELEASE_CANDIDATE_2026-08-10.md)
- v1.2.5 그래픽 감사: [V125_GRAPHICS_RESOURCE_AUDIT_2026-08-10.md](../qa/V125_GRAPHICS_RESOURCE_AUDIT_2026-08-10.md)
- v1.2.5 결함 대조: [V125_RELEASE_REMEDIATION_2026-08-10.md](../qa/V125_RELEASE_REMEDIATION_2026-08-10.md)

## 9. 검수 정책 상태

- Review task ID: `NOT_REQUESTED`
- Baseline SHA: `f757ffa9f9e962158f2123856c8568a3163ecb6c`
- Reviewed product SHA: `2c2d46ca339cb9d298d0ab3051b22fa649c41c73`
- Feedback state: `FIXED → RETESTED`
- Cause confirmed: `YES`
- Fix approved: `YES`
- Remaining P1/P2: `0 / 0`
- Final review result: `TARGETED_PENDING`
