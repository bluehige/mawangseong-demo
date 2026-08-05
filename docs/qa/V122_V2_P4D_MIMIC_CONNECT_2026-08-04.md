# v1.2.2 V2-P4D `mimic_porter` 런타임 연결 검수

## 패킷 카드

- `PACKET_ID`: `V2-P4D-CONNECT-MIMIC`
- `GOAL`: 미미 전용 런타임 시트 1개를 제품 데이터와 전투 시각 프로필에 연결
- `ALLOWED_WRITE_PATHS`: `data/monsters.json`, `data/v122/combat_visual_profiles.json`, 이 QA 문서, 패킷 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 다른 캐릭터·공통 코드·씬·초상화·VFX·오디오·V3 정규화·다음 패킷
- `DIRECT_TEST`: 미미 데이터/profile/runtime 경로, 146.5px 중앙값, RGBA 시트, 크로마 잔류, 접지 기준선과 렌더 배율
- `UI_OR_AUDIO_CHECK`: 없음(현재 잠금의 직접 검수 범위에 포함되지 않음)
- `STOP_AFTER`: 미미 연결과 직접 검수 문서화 후 중단

## 결과

`CONNECT_PASS_WITH_NORMALIZATION_PENDING`.

미미(`mimic_porter`)가 더 이상 고블린 공유 그림을 사용하지 않고 전용 4×4 런타임 시트를 사용하도록 연결했다. 원본·런타임 경로와 `RUNTIME_PREP_PASS`, 투명 시트 설정을 전투 시각 프로필에 기록했다. 최종 동작별 크기·발끝 정규화는 공통 V3 범위이므로 `NEEDS_NORMALIZATION`을 유지한다.

## 변경 경로

| 경로 | 변경 내용 |
|---|---|
| `data/monsters.json` | `mimic_porter.sprite`를 `res://assets/sprites/monsters/update4/monster_mimi_sheet.png`로 연결 |
| `data/v122/combat_visual_profiles.json` | 미미 원본·런타임 경로, `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, `146.5px` 중앙값 연결 |
| `docs/qa/V122_V2_P4D_MIMIC_CONNECT_2026-08-04.md` | 이번 패킷 직접 검수 기록 |
| `docs/handoff/V122_RELEASE_POLISH_V2_P4D_MIMIC_CONNECT_2026-08-04.md` | 패킷 인계 기록 |
| `docs/handoff/CURRENT.md` | 다음 패킷 잠금 갱신 |

런타임 PNG와 생성 원본은 이전 `V2-P4D-ASSET-MIMIC` 패킷에서 완료한 자산이며 이번 연결 패킷에서는 수정하지 않았다.

## 직접 검수

- 두 JSON UTF-8 파싱 및 미미 sprite/profile/runtime 경로 일치: PASS
- 미미 런타임 시트: `768×768`, RGBA, `192×192` 셀 16개: PASS
- 셀별 알파 경계 침범: `0개`
- 셀별 그림 높이 중앙값: `146.5px`, profile 선언값과 일치: PASS
- 순수 크로마 및 녹색 우세 잔류 픽셀: `0개`: PASS
- 공통 발 기준선: 모든 셀 `bottom=183`, spread `0px`: PASS
- `normal_grounded` 목표 높이: `68.04 × 1.15 = 78.246px`
- 렌더 배율: `78.246 / 146.5 = 0.534102`: PASS
- 고유 프레임 수: `16/16`: PASS
- `V122_P4D_MIMIC_CONNECT_DIRECT_TEST`: PASS
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST`: PASS

실행한 Godot 직접 계약 검사:

```text
godot.cmd --headless --path . --scene tools/tests/V122CombatVisualProfileContractTest.tscn --quit-after 30
V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS
```

## 미해결 및 다음 패킷

- 최종 프레임별 크기·발끝 정규화와 실제 전투 화면 검수는 공통 V3 또는 별도 화면 검수 범위로 남긴다.
- 다른 계약 몬스터·공통 코드·오디오·VFX·초상화는 변경하지 않았다.
- 다음 작업은 `CURRENT.md`에 새로 잠기는 단일 `NEXT_PACKET_ID`만 따른다. 현재 turn에서는 다음 패킷을 실행하지 않는다.

## 검수 상태

- 전체 회귀·전체 플레이·정식 빌드: `NOT_REQUESTED`
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
