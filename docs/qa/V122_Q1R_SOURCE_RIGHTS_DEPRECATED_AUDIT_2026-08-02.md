# V1.2.2 Q1-R 권리·출처·deprecated 감사

- 감사일: 2026-08-02
- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 범위: 활성 그래픽·오디오의 런타임 경로, 출처 문서, manifest 연결, 권리 표식, deprecated 격리 정책
- 변경 원칙: 읽기 전용 감사. 런타임 코드·데이터·그래픽·오디오·빌드는 수정하지 않음

## 결론

상태는 `SOURCE_AUDIT_PARTIAL_WITH_RELEASE_GATE`이다. 활성 파일과 연결된 출처 문서의 실제 파일 누락은 찾지 못했고, 이전 벽 리소스와 proof-only 자료가 런타임으로 다시 들어온 흔적도 없었다. 다만 제품 `1.2.2`에 사용할 오디오 이벤트 카탈로그와 전용 Lyria manifest가 아직 없고, `combat_dungeon_pressure`의 공용 BGM 출처 문서가 실제 활성 원본과 충돌한다. 따라서 권리·출처 감사는 완료로 닫지 않고, 아래 P2 검토 항목을 별도 Luna 수정 패킷으로 남긴다.

중요한 점은 이번 감사에서 저작권 침해나 권리 위반을 증명한 것이 아니라는 것이다. 현재 구조에 통합된 권리 승인 필드가 없어서, 소유자 확인 없이는 “출시 권리 확인 완료”라고 말할 수 없다는 의미다.

## 확인한 범위와 결과

| 영역 | 확인 내용 | 결과 |
| --- | --- | --- |
| 활성 그래픽 | F0-V 고유 전투 스프라이트 37개 | 실제 파일 누락 0 |
| Update4 manifest | 20개 항목, 런타임 그래픽·초상화·VFX·SFX 경로 138개 | 실제 파일 누락 0, source record 15개 모두 존재 |
| 던전 벽 카탈로그 | `cave_v2` 구조 벽 runtime 14개 | 실제 파일 누락 0, 공통 `v122_structural_wall_kit_v3/SOURCE.md` 존재 |
| 오디오 | WAV 76개, 실제 런타임 54·data-only 12·호출 미확인 10 | 파일 누락 0, source record 고유 41개 모두 존재 |
| 기존 Lyria manifest | `tools/audio/lyria_v05_manifest.json` 76개 | 활성 WAV 76/76 연결, 단 target `v0.5` |
| 출처 문서 | 활성 연결 SOURCE.md 45개 | 누락 0, AGENTS 고정 필드 완비 16개·미완비 29개 |
| 전체 source 문서 | `assets/source/**/SOURCE.md` 72개 | 고정 필드 완비 31개·미완비 41개 |
| deprecated 격리 | legacy wall 5그룹·12경로, proof-only 정책 | 활성 런타임 참조 적중 0 |

기계 판독 원본은 [`q1_r_inventory.json`](../../tmp/v122_release_polish/q1_r/q1_r_inventory.json)과 [`q1_r_inventory.tsv`](../../tmp/v122_release_polish/q1_r/q1_r_inventory.tsv)에 있다.

## 발견 사항

### Q1-R-P2-01 — 1.2.2 오디오 manifest·이벤트 카탈로그 부재

- 계획에서 요구한 `tools/audio/lyria_v122_manifest.json`이 없다.
- 계획에서 요구한 `data/audio/audio_event_catalog.json`도 없다.
- 현재 유일한 오디오 manifest는 `tools/audio/lyria_v05_manifest.json`이며 `target_version`은 `v0.5`다.
- 따라서 활성 오디오 76개가 어떤 1.2.2 이벤트·버스·승격 상태에 속하는지 한 파일에서 재현할 수 없다.
- 권장 후속 순서: A0에서 새 manifest·이벤트 카탈로그의 스키마를 먼저 확정하고, 기존 WAV를 임의 교체하지 않은 채 76개를 일대일로 매핑한다.

### Q1-R-P2-02 — `combat_dungeon_pressure` 출처 설명 충돌

- 실제 활성 source record: `assets/source/audio/lyria/v0.5/combat_dungeon_pressure/SOURCE.md`
- F0-A가 읽은 실제 WAV 길이: 약 `116.909388`초
- 현재 공용 문서 [`assets/audio/bgm/SOURCE.md`](../../assets/audio/bgm/SOURCE.md)는 절차적 합성·30초 곡이라고 설명한다.
- 이 문서는 활성 Lyria 원본을 가리키지 않으므로, 출처 문서 하나를 선택해 사실을 일치시켜야 한다. 이번 패킷에서는 문서나 오디오를 고치지 않았다.

### Q1-R-P3-01 — 출처 문서 형식과 권리 표식의 비표준화

- 전체 SOURCE.md 72개 중 41개가 `AGENTS.md`의 고정 필드(`Generation model`, `Generated date`, `Target version`, `Source image path`, `Runtime image path`)를 모두 갖추지 않았다.
- 현재 활성 연결 문서만 보아도 45개 중 29개가 그 형식을 완전히 충족하지 않는다.
- 문서 안에 권리·상업 이용·승인 표식이 있는 경우와 없는 경우가 섞여 있다. 이 결과만으로 권리 위반을 판정하지는 않으며, 표준 필드와 소유자 승인 기록을 별도 패킷에서 정리해야 한다.

### Q1-R-OWNER-01 — 소유자 청취·권리·승격 검수 대기

- 활성 오디오 76개 모두 `listening_state=pending`이다.
- Windows 실제 재생, 최종 믹스, 권리 승인, 1.2.2 승격 여부는 자동 검사만으로 확정할 수 없다.

### Q1-R-PASS-01 — deprecated/proof-only 격리 유지

- `wall_asset_catalog.json`의 legacy quarantine 5그룹·12경로는 활성 구조 벽 catalog에서 사용되지 않는다.
- `tile_variant_manifest.json`은 legacy wall을 `legacy_quarantined`·`structural_allowed=false`로 표시한다.
- `asset_manifest.json`의 rejected/proof-only 정책도 활성 상태이며, proof 경로와 격리 경로가 활성 런타임 자산에 연결된 적중은 각각 0개다.

## 실행한 검수

- `python tmp/v122_release_polish/q1_r/build_inventory.py` — source/manifest/deprecated 교차 감사 PASS
- `python -m unittest tools.audio.test_lyria_pipeline` — 12 tests PASS ([로그](../../tmp/v122_release_polish/q1_r/lyria_pipeline.log))
- `godot --headless --path . --scene res://tools/tests/V122WallAssetCatalogTest.tscn --quit-after 120` — PASS ([로그](../../tmp/v122_release_polish/q1_r/wall_asset_catalog_test.log))

이번 패킷은 출처와 정책을 읽는 감사이므로 새 화면을 만들거나 캡처하지 않았다.

Related tests: `tools.audio.test_lyria_pipeline` 12 tests PASS; `V122WallAssetCatalogTest` PASS; Q1-R 교차 인벤토리 PASS.

UI check: UI·런타임 화면 변경 없음. 시각 검수는 실행하지 않음.

Unresolved issues: `lyria_v122_manifest.json`·`audio_event_catalog.json` 부재, `combat_dungeon_pressure` SOURCE.md 충돌, 활성 오디오 76개 청취·권리·승격 OWNER 검수, 활성 출처 문서 29개 고정 필드 미완비.
