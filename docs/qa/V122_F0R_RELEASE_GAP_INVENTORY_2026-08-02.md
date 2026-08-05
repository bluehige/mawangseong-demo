# V1.2.2 릴리스 폴리시 F0-R 출시 공백 인벤토리

작성일: 2026-08-02
대상 버전: 제품 `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 목적과 범위

F0-R은 문제를 고치는 단계가 아니라, 이미 작성된 권위 문서와 아직 사용자가 확인하지 않은 출시 공백을 다섯 소유 페이즈로 나누는 단계다. 저장·복구, 입력·IME, UI·현지화, 성능, 권리·출처를 다시 구현하거나 전체 회귀하지 않고, 각 항목의 현재 증거·재현 입구·다음 담당 패킷만 고정했다.

기계 목록은 [F0-R JSON 인벤토리](../../tmp/v122_release_polish/f0_r/f0_r_inventory.json)와 [F0-R TSV 인벤토리](../../tmp/v122_release_polish/f0_r/f0_r_inventory.tsv)다. 다섯 행 모두 `Q1`의 상세 감사가 필요한 입력이며, 여기서 `PASS`라고 쓰지 않고 현재 증거와 사용자 검수 대기 상태를 분리했다.

## 현재 출시 경계

`V122_P17_RELEASE_READINESS_2026-07-27.md`의 자동 검사는 targeted PASS지만 상태는 `READY_FOR_OWNER_FINAL_QA`다. 따라서 아래 다섯 영역의 실제 사용자·Windows 검수가 끝나기 전에는 출시 후보 빌드, 태그, Release를 만들 수 없다. F0-R에서도 코드·데이터·자산·빌드·태그는 변경하지 않았다.

## 다섯 공백과 담당 패킷

| ID | 영역 | 현재 상태 | 현재 근거 | 다음 재현 입구 |
|---|---|---|---|---|
| `Q1-S` | 저장·복구 | `OWNER_QA_PENDING` | P8 자동 저장/migration/corrupt·`.tmp/.bak` targeted PASS | `V122SaveProgressionTest.tscn` + OWNER 체크리스트 실제 저장 파일 |
| `Q1-I` | 입력·IME | `OWNER_QA_PENDING` | Stage 10 touch·landscape 계약 PASS, 물리 Windows IME 미검수 | OWNER 체크리스트의 한/영 조합·Backspace·화면 전환 |
| `Q1-L` | UI·현지화·placeholder | `OWNER_QA_PENDING` | Stage 10/12 자동 검사는 PASS, S09의 `trap` 내부 ID P3와 전체 버튼 검수 잔여 | Stage 10 계약 + 모든 버튼·최대 글꼴·dead click 절차 |
| `Q1-P` | 성능 | `OWNER_QA_PENDING` | 오버레이 headless 계측 PASS, 실제 Windows GPU 장시간 전투 미검수 | `EngineerPerformanceSmokeTest.gd` + 혼잡 전투 사용자 환경 |
| `Q1-R` | 권리·출처·deprecated | `SOURCE_AUDIT_PARTIAL` | P1 대응표 6종 PASS, F0-A 오디오 76개 대조 PASS | Lyria pipeline, `asset_manifest`, 전체 활성 `SOURCE.md` 대조 |

`OWNER_QA_PENDING`은 자동 검사가 실패했다는 뜻이 아니다. 자동 계약은 통과했지만 물리 장치·실제 파일·사용자 화면에서 아직 확인하지 않았다는 뜻이다. `SOURCE_AUDIT_PARTIAL`은 일부 목록은 닫혔지만 모든 활성 그래픽·오디오의 권리·deprecated 상태를 하나의 표로 닫지 않았다는 뜻이다.

## 영역별 확인 내용

### Q1-S 저장·복구

- P8에서 v1.2.0/v1.2.1 호환, v1~v5 migration, 원자 저장, corrupt·`.tmp/.bak` 원복, 일반전·DAY 30 retry가 targeted PASS였다.
- P17과 OWNER 체크리스트는 기존 1.2.1 저장을 복사한 뒤 hash·수정 시각을 비교하고 실제 이어하기·손상 안내를 수행하도록 요구한다.
- F0-R에서는 저장 포맷을 다시 열거나 파일을 덮어쓰지 않았다. 다음 Q1-S는 실제 Windows 파일과 저장 원본 보존을 확인한다.

### Q1-I 입력·IME

- `GameRoot.gd`에는 키보드 이벤트 소유권, `InputSettings`, touch orientation 차단과 landscape 안내 경로가 있다.
- Stage 10 현지화·터치·landscape 계약은 자동 PASS였지만 P17은 물리 Windows 한/영 조합과 Backspace를 아직 미완료로 분류한다.
- Q1-I는 새 입력 기능을 만드는 패킷이 아니라, Windows 후보와 모바일 대표 흐름에서 실제 조합·전환·터치 대상을 재현하는 패킷이다.

### Q1-L UI·현지화·placeholder

- Stage 10은 `ko/en` 카탈로그 누락, 설정 적용·취소, 이름 등록, DAY 1~3 안내를 자동·캡처로 PASS했다. Stage 12 통합도 관리→침입→전투→결산→튜토리얼·저장 흐름을 targeted PASS로 기록한다.
- S09 통합 보고에는 `trap` 내부 ID 노출 P3가 남아 있고, OWNER 체크리스트의 전체 버튼·최대 글꼴·긴 문구·dead click은 아직 사용자 검수다.
- P16에서 금지된 일반 `placeholder` 상태는 0으로 닫혔지만, 화면에서 보이는 임시 문구·내부 ID와 데이터의 정상 `placeholder` 속성을 Q1-L에서 다시 혼동하지 않도록 분리한다.

### Q1-P 성능

- 전투 오버레이 성능 수정은 동적 표식에서 정적 전체 redraw 0회, headless p95 16.132ms를 기록했다.
- 같은 문서가 실제 Windows GPU, 저사양 메모리, 장시간 전투, 혼잡한 타격·함정·시설 효과를 아직 하지 않았다고 명시한다.
- 기존 `QuarterModuleSmokeTest`의 Stage 01 왕좌 투영 기대값 불일치는 이번 인벤토리에서 임의 수정하지 않고 별도 기존 이슈로 남긴다.

### Q1-R 권리·출처·deprecated

- P1은 제품·전투·UI·저장·밸런스·건물 기준표 6종과 `UNKNOWN=0`을 닫았지만, 이번 릴리스 폴리시에서 추가·누적된 모든 활성 그래픽과 오디오를 한 표로 재감사한 것은 아니다.
- F0-V는 전투 유닛 44개와 그래픽 경로를, F0-A는 오디오 76개와 Lyria/procedural·manifest·SHA를 고정했다.
- F0-A에서 `assets/audio/bgm/SOURCE.md`와 실제 `combat_dungeon_pressure`/Lyria 기록이 30초 procedural 대 116.9초 WAV·120초 Lyria로 충돌하는 것을 확인했다. 문서는 A0에서 정정한다.
- `data/dungeon_quarter/asset_manifest.json`의 proof-only·runtime 구분과 `AGENTS.md`의 `SOURCE.md` 필드를 유지하며, deprecated 후보는 런타임에서 제거된 뒤에만 퇴역시킨다.

## 다음 작업 순서

정식 Luna 실행 순서에서 F0-R 다음은 Q1이 아니라 V1이다. 이 인벤토리의 Q1 항목은 출시 공백 입력으로 보존하고, 실제 상세 감사는 계획표의 A5 이후 Q1 페이즈에서 수행한다.

1. `V1-A` 맵 비례 스케일 계약·registry
2. `V1-B` capture·감사 도구
3. `V1-C`·`V1-D` Update 4 시트 전처리
4. `V2` 전체 roster 크기 정규화
5. `V3` 접지 렌더 구조·발 앵커
6. `V4` 전면 벽·UI 앵커
7. 이후 계획 순서대로 `A0 → A1 → C1 → V5 → V6 → A2 → A3 → A4 → A5`
8. 그 다음에야 이 문서의 Q1-S/I/L/P/R을 상세 감사하고, 발견된 P0/P1/P2만 결함 하나당 별도 Luna 수정 패킷으로 분리한다.

F0-R에서는 전체 회귀, 전체 플레이, 실제 후보 export, 빌드, 커밋, 푸시를 실행하지 않았다.
