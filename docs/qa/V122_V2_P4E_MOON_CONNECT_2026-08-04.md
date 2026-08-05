# v1.2.2 V2-P4E `moon_tracker` 런타임 연결 검수

## 패킷 카드

- `PACKET_ID`: `V2-P4E-CONNECT-MOON`
- `GOAL`: 루미 전용 런타임 시트 1개를 제품 몬스터 데이터와 전투 시각 프로필에 연결하고 임시 출전 차단을 해제
- `ALLOWED_WRITE_PATHS`: `data/monsters.json`, `data/update2_contracts.json`, `data/v122/combat_visual_profiles.json`, 이 QA 문서, 패킷 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 다른 캐릭터·공통 코드·씬·초상화·VFX·오디오·V3 정규화·다음 패킷
- `DIRECT_TEST`: 루미 몬스터/profile/runtime 경로, `READY` 차단 게이트 해제, 125.0px 중앙값, RGBA 시트, 접지 기준선과 소형 비행 렌더 배율
- `UI_OR_AUDIO_CHECK`: 없음(현재 잠금의 직접 검수 범위에 포함되지 않음)
- `STOP_AFTER`: 루미 연결과 직접 검수 문서화 후 중단

## 결과

`CONNECT_PASS_WITH_NORMALIZATION_PENDING`.

루미(`moon_tracker`)가 더 이상 로로·코볼트 공유 원본을 사용하지 않고 전용 4×4 런타임 시트를 사용하도록 연결했다. 계약 상태를 `READY`로 바꿔 신규 계약 후보와 방어 출전을 다시 허용했으며, 전투 시각 프로필에는 `small_flying`과 전용 원본·런타임 경로를 등록했다. 최종 프레임별 크기·발끝 정규화는 공통 V3 범위이므로 `NEEDS_NORMALIZATION`을 유지한다.

## 변경 경로

| 경로 | 변경 내용 |
|---|---|
| `data/monsters.json` | `moon_tracker.sprite`를 `res://assets/sprites/monsters/update4/monster_moon_sheet.png`로 연결 |
| `data/update2_contracts.json` | `moon_tracker.combat_asset_state`를 `READY`로 변경해 임시 차단 해제 |
| `data/v122/combat_visual_profiles.json` | `small_flying`, `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, 125.0px 중앙값, 원본·런타임 경로 등록 |
| `docs/qa/V122_V2_P4E_MOON_CONNECT_2026-08-04.md` | 이번 패킷 직접 검수 기록 |
| `docs/handoff/V122_RELEASE_POLISH_V2_P4E_MOON_CONNECT_2026-08-04.md` | 패킷 인계 기록 |
| `docs/handoff/CURRENT.md` | 다음 패킷 잠금 갱신 |

런타임 PNG와 생성 원본은 이전 `V2-P4E-ASSET-MOON` 패킷에서 완료한 자산이며 이번 연결 패킷에서는 수정하지 않았다.

## 직접 검수

- 세 JSON UTF-8 파싱 및 `moon_tracker` sprite/profile/runtime 경로 일치: PASS
- 계약 상태 `READY`, 신규 후보 포함, 방어 출전 가능, `combat_asset_pending` 미설정: PASS
- 루미 런타임 시트: `768×768`, RGBA, `192×192` 셀 16개: PASS
- 셀별 알파 경계 침범: `0개`
- 셀별 그림 높이 중앙값: `125.0px`, profile 선언값과 일치: PASS
- 순수 크로마 및 녹색 잔류 픽셀: `0개`: PASS
- 공통 발 기준선: 모든 셀 `bottom=183`, spread `0px`: PASS
- `small_flying` 목표 높이: `68.04 × 1.15 × (0.72 / 0.95) = 59.302232px`
- 렌더 배율: `59.302232 / 125.0 = 0.474417853`: PASS
- 고유 프레임 수: `16/16`: PASS
- 런타임 SHA-256 prefix: `cc3f18b342c0c934`
- `V122_P4E_MOON_CONNECT_DIRECT_TEST`: PASS
- `V122_P4E_MOON_CONNECT_GATE_TEST`: PASS
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST`: PASS

실행한 Godot 직접 계약 검사:

```text
godot.cmd --headless --path . --scene tools/tests/V122CombatVisualProfileContractTest.tscn --quit-after 30
V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS

godot.cmd --headless --path . --scene tmp/v122_release_polish/moon_connect_gate_check.tscn --quit-after 30
V122_P4E_MOON_CONNECT_GATE_TEST: PASS
```

게이트 검사용 임시 파일은 검사 직후 삭제했으며 제품 경로에는 남기지 않았다.

## 미해결 및 다음 패킷

- 최종 프레임별 크기·발끝 정규화와 실제 전투 화면 확인은 공통 V3 또는 별도 화면 검수 범위에 남아 있다.
- 다른 계약 몬스터·공통 코드·오디오·VFX·초상화는 변경하지 않았다.
- 다음 작업은 `CURRENT.md`에 새로 잠기는 단일 `NEXT_PACKET_ID`만 따른다. 현재 turn에서는 다음 패킷을 실행하지 않는다.

## 검수 상태

- 전체 회귀·전체 플레이·정식 빌드: `NOT_REQUESTED`
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
