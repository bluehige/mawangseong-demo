# v1.2.2 V2-P4D `mimic_porter` 원본 발견 패킷 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-04
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 기준 SHA: `codex/v122-ui-simplification@efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 미커밋)
- 작업 패킷: `V2-P4D-DISCOVER-MIMIC`

## 2. 목표와 완료 조건

미미의 현재 공유 전투 그림, 계약·캐릭터 참조, 저장소의 전용 원본 후보와 파일 형식을 읽기 전용으로 교차 검사한다. 미미 역할과 소유권이 충돌하는 기존 자산은 다음 생성 후보에서 제외하고, 생성 패킷의 정확한 경로를 제안한다.

## 3. 발견 결과

- `mimic_porter.sprite`와 `unit_overrides.mimic_porter.source_path/runtime_path`는 일반 고블린 단일 프레임을 가리킨다.
- `goblin`과의 공유는 확인됐지만, 직전 두둠 연결로 미미·두둠·고블린의 3-way 공유는 해소됐다.
- `mon_contract_mimi`, `CHR_MIMI`, `mimic_porter` 참조와 가짜 보물·유인 역할은 정상이다.
- `assets/source/imagegen/mimi/SOURCE.md`, `monster_mimi_idle_down_00.png`, Update 4 미미 원본 디렉터리는 존재하지 않는다.
- 고블린 금고지기 진화, 적 마물 구속병, 보물실 소품·환경 원본은 이름이 비슷해도 미미 전투 자산으로 쓸 수 없다.
- 결과: `DISCOVERY_PASS_WITH_ASSET_REQUIRED`.

## 4. 변경 파일

- `docs/qa/V122_V2_P4D_MIMIC_DISCOVERY_2026-08-04.md`
- `docs/handoff/V122_RELEASE_POLISH_V2_P4D_MIMIC_DISCOVERY_2026-08-04.md`
- `docs/handoff/CURRENT.md`

제품 데이터·visual profile·런타임 자산·공통 코드는 변경하지 않았다.

## 5. 검수

- JSON 및 미미 계약/캐릭터 참조 교차 검사: PASS
- 현재 공유 PNG `192×192 RGBA`, 63,399바이트, SHA-256 앞 16자 `e5ee8576e82644eb`: PASS
- 미미 전용 파일명·출처 부재 확인: PASS
- 고블린 진화·적 자산·환경 소품 소유권 분류: PASS
- UI·오디오·전체 회귀·빌드: 발견 전용 패킷이므로 실행하지 않음

## 6. 정책 및 다음 순서

- Review task ID: NOT_REQUESTED
- Reviewed SHA: N/A
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
- 다음은 `V2-P4D-ASSET-MIMIC` 하나만 제안한다.
- 제안 경로는 `assets/source/imagegen/update4_contract_monsters/mimi/`와 `assets/sprites/monsters/update4/monster_mimi_sheet.png`이며, 이번 패킷에서는 만들지 않았다.

## 7. 작업 트리와 게시 상태

- 기존 Luna 작업과 사용자 변경이 섞인 dirty worktree를 보존했다.
- 이번 패킷은 문서 3개만 추가·갱신했다.
- 커밋·푸시·PR·릴리스 빌드는 수행하지 않았다.
