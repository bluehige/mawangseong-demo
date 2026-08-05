# v1.2.2 A0 오디오 생성·승격 계약

검수일: 2026-08-02
대상 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

기존 v0.5 Lyria manifest와 출처 기록을 보존한 채 v1.2.2용 manifest를 분리했다. 실제 생성 API 호출, 후보 승격, 런타임 WAV 덮어쓰기는 하지 않았다.

## 변경 내용

- 신규 manifest: `tools/audio/lyria_v122_manifest.json`
- target version: `v1.2.2`
- 현재 런타임 WAV 76개를 기존 경로 그대로 일대일 선언
- 이전 manifest: `tools/audio/lyria_v05_manifest.json`
- 신규 source root: `assets/source/audio/lyria/v1.2.2/`
- 기본 작업 폴더: `tmp/lyria_audio_v122`
- 생성 정책: `plan-only-until-owner-approval`
- 기존 v0.5 manifest SHA-256: `B3D17C58746448439F92886C81D01DCAC129E059FEA663AA02024F77D04C47F3`

`assets/audio/bgm/SOURCE.md`는 `combat_dungeon_pressure.wav`의 낡은 procedural 30초 설명을 deprecated로 명시하고, 실제 v0.5 Lyria source record와 116.909초 runtime·120초 render contract 불일치를 A1 loop 검증 항목으로 분리했다.

## 검증 결과

- `python tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate`: PASS, 76 assets와 현재 WAV coverage 일치
- `python tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json plan`: PASS, 2 takes 기준 예상 비용 `$6.32` 출력
- `python -m json.tool tools/audio/lyria_v122_manifest.json`: PASS
- 네트워크 요청 및 `generate --execute`는 실행하지 않았다.

Related tests: v1.2.2 manifest validate PASS(76 assets); plan PASS(146 clip + 6 pro requests, estimated `$6.32`); JSON syntax PASS.
UI check: UI·게임 화면 변경 없음. manifest와 BGM source 문서만 읽기·계약 검증했다.
Unresolved issues: 사용자 비용·생성·청취 승인 전에는 새 source/runtime이 없다. A1 loop·bus·catalog 기반과 A4 Stage 환경음·발소리 자산이 남아 있다.
