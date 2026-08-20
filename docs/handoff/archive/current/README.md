# CURRENT 역사 백업 인덱스

이 폴더는 `docs/handoff/CURRENT.md`에서 제거한 과거 진행 기록을 보존한다. 여기의 문서에 적힌 `현재`, `최우선`, `다음 작업` 표현은 **작성 당시의 역사적 상태**이며 제품의 현재 권위가 아니다.

제품 현재 상태는 항상 `main:docs/handoff/CURRENT.md`를 사용한다.

분할 이유와 오인 원인 교정은 [CURRENT_REORGANIZATION_2026-08-13.md](../../CURRENT_REORGANIZATION_2026-08-13.md)에서 확인한다.

## 원문 스냅샷

| 순서 | 스냅샷 | 범위 | SHA-256 |
|---:|---|---|---|
| 1 | [HISTORICAL_ONLY_CURRENT_2026-08-10_PRE_SPLIT.snapshot.txt](HISTORICAL_ONLY_CURRENT_2026-08-10_PRE_SPLIT.snapshot.txt) | v1.2.5 출시 완료부터 v1.2.2 세부 패킷, v1.2.1·v20·구 버전·Steam·오디오 기록까지 포함한 분할 전 807줄 원문 | `3AC54A53190A756DF354EE41D93BD44DB17D17456166F48A893BEE7042180564` |

스냅샷은 원문과 바이트 단위 SHA-256이 일치하도록 복사했다. 내용을 교정하지 않은 이유는 당시 기록을 훼손하지 않기 위해서다. 파일명과 확장자는 현재 Markdown 지시 검색에 섞이지 않도록 `HISTORICAL_ONLY`·`.snapshot.txt`로 격리했다.

## 버전 순서로 찾기

### v1.2.5 — 2026-08-10

1. [그래픽 리소스 갱신](../../V125_GRAPHICS_RESOURCE_UPDATE_2026-08-10.md)
2. [출시 후보](../../V125_RELEASE_CANDIDATE_2026-08-10.md)
3. [출시 게이트 수정](../../V125_RELEASE_GATE_FIX_2026-08-10.md)
4. [출시 완료](../../V125_RELEASE_COMPLETE_2026-08-10.md)
5. [그래픽 리소스 감사](../../../qa/V125_GRAPHICS_RESOURCE_AUDIT_2026-08-10.md)
6. [출시 결함 대조](../../../qa/V125_RELEASE_REMEDIATION_2026-08-10.md)

### v1.2.4 — 2026-08-06~10

1. [도둑 고블린 추격 수정](../../V124_GOBLIN_THIEF_PURSUIT_FIX_2026-08-06.md)
2. [관리 화면 몬스터 미리보기 수정](../../V124_MANAGEMENT_MONSTER_PREVIEW_FOREGROUND_FIX_2026-08-06.md)
3. [명령 버튼 입력 수정](../../V124_COMMAND_BUTTON_INPUT_FIX_2026-08-06.md)
4. [출시 후보 빌드](../../V124_RELEASE_CANDIDATE_BUILD_2026-08-06.md)
5. [Windows 최종 완료 검수](../../V124_WINDOWS_FINAL_COMPLETION_REVIEW_2026-08-10.md)

### v1.2.3 — 2026-08-06

1. [핫픽스 덮어쓰기](../../V123_HOTFIX_OVERWRITE_2026-08-06.md)
2. [카탈로그 provenance 수정](../../V123_CATALOG_PROVENANCE_FIX_2026-08-06.md)
3. [출시 완료](../../V123_RELEASE_COMPLETE_2026-08-06.md)

### v1.2.2 — 2026-07-27~08-06

- 통합·출시 계보: [최종 통합 검수](../../V122_FINAL_INTEGRATION_REVIEW_2026-08-06.md), [최종 검수](../../V122_FINAL_REVIEW_2026-08-06.md), [출시 마감 검수](../../V122_RELEASE_CLOSEOUT_REVIEW_2026-08-06.md)
- UI·전투·저장·밸런스 단계: `../../V122_P0_INTEGRATION_CONTRACT_2026-07-27.md`부터 `../../V122_P17_RELEASE_READINESS_2026-07-27.md`
- 대사: [원천 게이트](../../V122_STORY_DIALOGUE_PHASE0_SOURCE_GATE_2026-07-30.md), [DAY 1~5 런타임](../../V122_STORY_DIALOGUE_PHASE2_DAY01_05_RUNTIME_2026-07-30.md), [DAY 6~30 런타임](../../V122_STORY_DIALOGUE_PHASE3_DAY06_30_RUNTIME_2026-08-01.md)
- 시각·오디오 세부 패킷: 파일명이 `V122_VISUAL_*`, `V122_RELEASE_POLISH_*`인 개별 핸드오프와 대응 `docs/qa/` 문서
- 전체 세부 진행 순서는 위 원문 스냅샷에서 확인한다.

### v1.2.1 이하와 v20 참고선 — 2026-07

- v1.2.1: [공개 출시](../../V12_1_PUBLIC_RELEASE_2026-07-20.md)
- v1.2 실제 사용자 검수: [사용자 플레이테스트 QA](../../V12_USER_PLAYTEST_QA_2026-07-20.md)
- v20 DAY 1~5 실험선: 파일명이 `V20_PHASE*`인 핸드오프와 `docs/design/V20_*` 문서
- v20은 현재 제품 브랜치가 아니라 참고선이다. 현재 작업 대상으로 승계하지 않는다.

## 사용 규칙

1. 현재 상태를 알고 싶으면 이 폴더가 아니라 `main:docs/handoff/CURRENT.md`를 읽는다.
2. 특정 버전의 결정 근거가 필요할 때만 위 순서와 개별 핸드오프를 따라간다.
3. 원문 스냅샷의 오래된 `현재` 표시는 수정하거나 다시 제품 결정으로 승격하지 않는다.
