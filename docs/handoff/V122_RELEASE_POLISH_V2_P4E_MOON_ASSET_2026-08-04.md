# v1.2.2 Luna V2-P4E `moon_tracker` 기본 전투 자산 핸드오프

- 목표 버전: v1.2.2
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 현재 패킷: `V2-P4E-ASSET-MOON`
- 결과: `ASSET_PASS_WITH_CONNECT_PENDING`
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 이번 패킷에서 완료한 내용

루미(`moon_tracker`)의 잘못된 공유 원본을 재사용하지 않고, GPT 내부 이미지 생성으로 달박쥐 추적자 전용 4×4 전투 시트를 만들었다. 크로마키 배경을 투명화하고 16개 프레임을 192×192 셀에 맞춘 뒤 발 기준선을 y=183으로 통일했다. 활 공격과 보랏빛 추적 문양은 캐릭터 가까이에만 배치해 셀 경계 침범을 제거했다.

## 변경 파일

- `assets/source/imagegen/update4_contract_monsters/moon/moon_combat_sheet_chroma_2026-08-04.png`
- `assets/source/imagegen/update4_contract_monsters/moon/SOURCE.md`
- `assets/sprites/monsters/update4/monster_moon_sheet.png`
- `docs/qa/V122_V2_P4E_MOON_ASSET_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V2_P4E_MOON_ASSET_2026-08-04.md`
- `docs/handoff/CURRENT.md`

제품 데이터(`data/monsters.json`, `data/update2_contracts.json`, `data/v122/combat_visual_profiles.json`), 씬, 공통 렌더러는 이번 패킷에서 건드리지 않았다. 실제 제품 연결은 별도 `V2-P4E-CONNECT-MOON` 패킷으로 남겼다.

## 실행한 직접 테스트

- 원본 1254×1254 RGB와 런타임 768×768 RGBA 확인
- 4×4 16프레임 존재·고유 셀 16/16 확인
- 셀 경계 밖 알파 0, 초록 잔류 0 확인
- 아트 높이 중앙값 125.0px, 모든 발 기준선 y=183, spread 0px 확인
- 런타임 SHA-256 prefix: `cc3f18b342c0c934`
- 결과: `MOON_ASSET_DIRECT_TEST: PASS`

전체 회귀·전체 플레이·정식 빌드 검수는 사용자 요청 범위가 아니어서 실행하지 않았다.

## 미해결 및 다음 순서

- 미해결: 제품 데이터/profile이 아직 새 시트를 참조하지 않으며 출전 차단 게이트가 유지된다.
- 다음 패킷: `V2-P4E-CONNECT-MOON` — 새 런타임 경로를 루미 제품 데이터와 전투 시각 profile에 연결하고 직접 계약 검사를 수행한다.

작업 트리에는 본 패킷 파일 외 기존 사용자·Luna 변경이 섞여 있으며, 이를 되돌리거나 정리하지 않았다. 이번 패킷에서는 커밋·푸시하지 않았다.
