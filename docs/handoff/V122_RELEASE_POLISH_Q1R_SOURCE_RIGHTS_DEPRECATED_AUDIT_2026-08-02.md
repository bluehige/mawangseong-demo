# V1.2.2 출시 마무리 Q1-R 핸드오프 — 권리·출처·deprecated 감사

- 목표 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 커밋하지 않음)
- 감사 상태: `SOURCE_AUDIT_PARTIAL_WITH_RELEASE_GATE`

## 완료한 내용

- F0-V/F0-A 인벤토리와 Update4·던전·벽 manifest를 읽어 활성 그래픽·오디오 경로의 실제 파일 존재를 대조했다.
- 활성 연결 source record 46개(문서 45개)의 파일 존재를 확인했다. 누락은 0개다.
- F0-A의 오디오 76개가 기존 `lyria_v05_manifest.json`에 76/76 연결되는지 확인했다. 다만 manifest target은 `v0.5`다.
- `combat_dungeon_pressure`의 실제 Lyria source record·재생 길이와 공용 BGM `SOURCE.md`의 절차적 30초 설명이 충돌하는 것을 재현했다.
- legacy wall/proof-only 자료가 활성 런타임에 참조되는지 확인했고, 적중 0개였다.
- 이번 감사에서는 런타임 코드·데이터·그래픽·오디오·빌드를 수정하지 않았다.

## 변경 파일

- 추가: `docs/qa/V122_Q1R_SOURCE_RIGHTS_DEPRECATED_AUDIT_2026-08-02.md`
- 추가: `docs/handoff/V122_RELEASE_POLISH_Q1R_SOURCE_RIGHTS_DEPRECATED_AUDIT_2026-08-02.md`
- 임시·무추적: `tmp/v122_release_polish/q1_r/build_inventory.py`, `q1_r_inventory.json`, `q1_r_inventory.tsv`, 실행 로그

## 다음 작업

1. A0/Luna 패킷에서 `tools/audio/lyria_v122_manifest.json`과 `data/audio/audio_event_catalog.json`의 스키마·일대일 매핑을 확정한다.
2. `combat_dungeon_pressure`의 실제 활성 원본에 맞춰 `assets/audio/bgm/SOURCE.md`를 정정할지, 활성 원본을 바꿀지 소유자 승인 후 결정한다.
3. 활성 오디오 76개의 청취·권리·승격 상태를 소유자가 확인한다.
4. AGENTS 고정 필드를 갖추지 못한 활성 출처 문서를 일괄 수정하기 전에, Luna 작업량 상한과 실제 필요한 문서 목록을 다시 확정한다.
5. Q1-R release gate가 정리되기 전에는 출시 후보 빌드·태그·Release를 진행하지 않는다.

## 검수와 미해결

Related tests: `python -m unittest tools.audio.test_lyria_pipeline` 12 tests PASS; `V122WallAssetCatalogTest` PASS; Q1-R 교차 인벤토리 PASS.

UI check: UI·런타임 변경 없음. 화면 확인 없음.

Unresolved issues: 제품 1.2.2 오디오 manifest·이벤트 카탈로그 없음, `combat_dungeon_pressure` 출처 문서 충돌, 권리 승인 필드 비표준화, 활성 오디오 76개 OWNER 청취·권리·승격 검수 대기.

## 작업 트리와 원격

- 작업 트리에는 이번 세션 전부터 있던 `.import` 수정 6개와 `.uid` 7개가 있다. 이 파일들은 Q1-R에서 건드리거나 스테이징하지 않는다.
- Q1-R 감사 문서와 계획/CURRENT 갱신은 아직 커밋하지 않았다.
- 원격 푸시는 하지 않았다.
