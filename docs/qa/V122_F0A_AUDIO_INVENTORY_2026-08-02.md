# V1.2.2 릴리스 폴리시 F0-A 오디오 인벤토리

작성일: 2026-08-02
대상 버전: 제품 `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 목적과 범위

이번 단계는 소리를 고치는 단계가 아니라, 현재 오디오를 빠짐없이 목록화하고 다음 Luna 패킷에서 판단할 기준을 고정하는 단계다. `assets/audio/**/*.wav` 76개와 각 `.import`, 원본 출처 기록, Lyria manifest, 런타임·데이터·테스트의 참조를 읽기 전용으로 대조했다. 오디오 파일, 런타임 코드, 데이터, import 설정은 수정하지 않았다.

기계 판정 원본은 [F0-A JSON 인벤토리](../../tmp/v122_release_polish/f0_a/f0_a_inventory.json)와 [F0-A TSV 인벤토리](../../tmp/v122_release_polish/f0_a/f0_a_inventory.tsv)다. TSV에는 모든 파일의 길이, 채널, 샘플레이트, 바이트 크기, SHA-256, 루프 설정, 출처, 버스, 참조 파일과 청취 상태가 한 행씩 들어 있다.

## 전체 판정

| 항목 | 결과 |
|---|---:|
| WAV 총수 | 76 |
| 실제 런타임 재생 경로 확인 | 54 |
| 데이터에만 연결되고 런타임 호출 미확인 | 12 |
| 코드·데이터 호출을 찾지 못함 | 10 |
| Lyria 원본 기록 | 28 |
| 로컬 결정적 합성(절차적) | 48 |
| manifest 등재 | 76/76 |
| 사람 청취 상태 | 76/76 `pending` |

## 순서 재시작 재검증

위 표의 `54 actual_runtime / 12 data_only / 10 unconnected`는 A1 변경 전 F0 기준선이다. 작업 트리를 보존한 채 `tmp/v122_release_polish/f0_a/build_inventory.py`를 다시 실행한 현재 결과는 `53 actual_runtime / 23 data_only / 0 unconnected`였다. WAV 76개, Lyria 28개, procedural 48개, listening pending 76개는 같지만 연결 분류가 달라졌다.

따라서 이 문서의 최초 표는 원래 F0 기준선으로 보존하고, 현재 혼합 트리의 수치는 재시작 감사 결과로만 사용한다. V1~V4 기준선 정리가 끝나기 전에는 이 재생성 수치를 A1 완료 근거로 사용하지 않는다.

`actual_runtime`는 `scripts/` 또는 `scenes/`에서 실제 재생 함수·preload·동적 cue 조립을 확인한 경우다. `data_only`는 JSON에 경로가 있지만 실제 재생 호출을 찾지 못한 경우이며, `unconnected`는 현재 코드와 데이터 어디에서도 소비되지 않는 파일이다. 파일이 존재하거나 manifest에만 있다는 이유로 런타임 연결로 세지 않았다.

## 그룹·형식 분포

| 그룹 | 수 | 실제 길이 범위 | 채널/샘플레이트 | 기본 버스 |
|---|---:|---:|---|---|
| `assets/audio/bgm` | 3 | 114.140~116.909초 | stereo, 44.1kHz | Music |
| `assets/audio/sfx` | 5 | 0.140~0.360초 | mono, 44.1kHz | SFX |
| `assets/audio/sfx/skills` | 24 | 0.420~0.840초 | mono, 44.1kHz | SFX |
| `assets/audio/update3` | 31 | 0.520~2.400초 | mono, 44.1kHz | SFX |
| `assets/audio/music/update4/rivals` | 3 | 1.580초 | mono, 22.05kHz | Music 의도 |
| `assets/audio/sfx/update4/contract_monsters` | 4 | 0.420초 | mono, 22.05kHz | SFX |
| `assets/audio/sfx/update4/crowns` | 6 | 0.420초 | mono, 22.05kHz | SFX |

모든 파일은 16-bit WAV다. Update 4에서 생성된 13개 파일은 22.05kHz이고, 기존 Lyria·Update 3·기본 전투음은 44.1kHz다. 이 차이는 아직 오류로 단정하지 않지만, 최종 믹스와 청취 비교 때 반드시 확인할 항목이다.

## 실제 재생 경로

| 영역 | 확인된 수 | 연결 근거 |
|---|---:|---|
| 관리/일반 전투/보스 BGM | 3 | `scripts/game/GameRoot.gd`의 `COMBAT_MUSIC`, `COMBAT_BOSS_MUSIC`, `MANAGEMENT_MUSIC` |
| 기본 전투음 | 5 | `scripts/game/CombatSceneController.gd`의 기본 SFX preload |
| 직접 전투 스킬음 | 24 | `CombatSceneController.gd`의 `SKILL_SFX`와 `_play_skill_sfx` |
| Update 3 보스·합동기·경고·심장음 | 21 | `GameRoot.gd`의 `_play_update3_sfx`, 동적 `enemy_%s` 경고 cue, 심장 loop override |
| Update 4 계약 알림 | 1 | `scenes/ui/hud/MultiFloorHUD.gd`의 `sfx_popo_alarm` |

Update 3 경고음 6개는 코드에 파일명을 그대로 쓰지 않고 `enemy_%s`로 조립하므로 정적 인벤토리에서 이 동적 호출을 별도로 판정했다. 심장 loop 3개는 `.import`가 루프가 아니어도 `GameRoot.gd`가 실행 중 `AudioStreamWAV.LOOP_FORWARD`로 덮어쓴다.

## 데이터만 연결된 12개

다음 파일은 Update 4 JSON에서 경로를 선언하지만, 현재 런타임에서 실제 재생하는 소비자를 찾지 못했다.

```text
assets/audio/music/update4/rivals/boss_brassa_motif.wav
assets/audio/music/update4/rivals/boss_mirella_motif.wav
assets/audio/music/update4/rivals/boss_vesper_motif.wav
assets/audio/sfx/update4/contract_monsters/sfx_popo_relay.wav
assets/audio/sfx/update4/contract_monsters/sfx_silky_rescue.wav
assets/audio/sfx/update4/contract_monsters/sfx_silky_stitch.wav
assets/audio/sfx/update4/crowns/sfx_crown_gob_ascend.wav
assets/audio/sfx/update4/crowns/sfx_crown_mori_ascend.wav
assets/audio/sfx/update4/crowns/sfx_crown_popo_ascend.wav
assets/audio/sfx/update4/crowns/sfx_crown_pudding_ascend.wav
assets/audio/sfx/update4/crowns/sfx_crown_pynn_ascend.wav
assets/audio/sfx/update4/crowns/sfx_crown_toktok_ascend.wav
```

이것은 “파일이 깨졌다”는 뜻이 아니라, 데이터 계약과 실제 이벤트 소비자가 아직 이어지지 않았다는 뜻이다. 다음 A1 패킷에서 이벤트별 호출 위치를 정하고, 호출을 추가하기 전에는 임의의 전역 재생으로 우회하지 않는다.

## 호출을 찾지 못한 10개

```text
assets/audio/update3/heart_ready.wav
assets/audio/update3/monster_signature_01.wav ... monster_signature_09.wav
```

현재 Update 3 코드에는 심장 `active`, `loop`, `disabled` 호출은 있지만 `heart_ready` 호출은 없다. `monster_signature_01~09`도 현재 런타임·데이터 참조가 없다. 다음 패킷에서 실제 이벤트가 필요한지 먼저 결정하고, 필요 없으면 보존·폐기 후보로 분리한다.

## 루프와 BGM 공백

| 스트림 | 현재 상태 |
|---|---|
| `combat_dungeon_pressure.wav` | `.import` `edit/loop_mode=2`; 실제 런타임 루프 확인 |
| `management_castle_bustle.wav` | 약 115.081초, `.import` 루프 없음, 종료 콜백 없음 |
| `combat_boss_council.wav` | 약 114.140초, `.import` 루프 없음, 종료 콜백 없음 |
| Update 3 심장 loop 3개 | 코드에서 `LOOP_FORWARD`를 런타임 적용 |
| Update 4 rival motif 3개 | 데이터만 연결된 1.58초 단발 cue |

현재 화면 상태는 관리/일반 전투/보스의 3종 BGM만 가진다. 계획에서 요구한 타이틀, 늦은 전투, 최종전 전용 상태는 아직 별도 곡·연결이 없다. 관리·보스 BGM은 114~115초 뒤 다시 재생하는 경로가 코드상 보이지 않으므로 A1에서 “루프를 고칠지, 상태별 짧은 곡으로 교체할지”를 먼저 결정한다.

## 버스와 동시 재생 정책

- `scripts/core/AudioSettings.gd`는 현재 `Master`, `Music`, `SFX` 세 버스와 기본 음량(`0.85 / 0.55 / 0.90`)만 만든다.
- UI·환경음 전용 버스, Master limiter, 전역 동시 재생 상한은 아직 없다.
- `CombatSceneController.gd`는 기본 전투음과 스킬음에 cue별 최소 간격을 적용한다.
- `GameRoot.gd`의 Update 3 one-shot은 같은 cue 중복을 막고 최대 4개까지, 심장 loop는 1개만 재생한다.
- 심장 loop도 현재는 SFX 버스를 사용한다. 음악성 loop를 별도 Music/Environment 버스로 옮길지는 A2에서 결정한다.

## 출처와 문서 충돌

- 28개는 `assets/source/audio/lyria/v0.5/**/SOURCE.md`와 `generation.json`이 연결된 Lyria 자산이다.
- 기본 전투음 4개, Update 3 31개, Update 4 13개는 로컬 결정적 합성 도구와 GPT 내부 이미지 생성 원본 기록을 기준으로 `procedural`로 분류했다.
- `assets/audio/bgm/SOURCE.md`는 `combat_dungeon_pressure.wav`를 “procedural 30초”라고 적지만, 실제 WAV는 약 116.909초이고 Lyria SOURCE/manifest는 Lyria 3 pro·120초 렌더로 기록한다. 이 충돌은 수정하지 않고 A0 정정 목록으로 넘겼다.
- Lyria 28개와 절차적 48개 모두 사람이 직접 들어 승인한 상태가 아니므로 현재 청취 열은 전부 `pending`이다. F0-A에서는 유료 생성 호출이나 파일 교체를 하지 않았다.

## 다음 패킷

1. `F0-R`: 코드·데이터·자산의 출시 공백을 읽기 전용으로 정리한다.
2. F0가 끝나면 계획 순서대로 `V1-A → V1-B → V1-C/V1-D → V2 → V3 → V4`를 먼저 닫는다.
3. 그 뒤 `A0`: Lyria manifest·승격 출처·오디오 연결 계약과 위 문서 충돌을 정정한다.
4. 이후 `A1-A~E`: 타격음, BGM 상태, 환경음, 믹스 정책을 각각 작은 Luna 패킷으로 진행한다.

전체 회귀·전체 플레이·빌드는 요청 범위에 없어서 실행하지 않았다. F0-A 완료 후에도 커밋·푸시는 하지 않는다.
