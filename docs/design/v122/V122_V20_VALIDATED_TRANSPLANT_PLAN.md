# 마왕성 v1.2.2 — 2.0 검증 결과 선별 통합 계획서
## 1.2.1 제품 구조 보존형 교정본

- 작성일: 2026-07-27 KST
- 대상 저장소: `bluehige/mawangseong-demo`
- 목표 제품 표시: `1.2`
- 목표 기술 버전: `1.2.2`
- 목표 태그: `v1.2.2`
- 출시 기준 브랜치: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 기존 출시 런타임: `v1.2.1@c483d135b13cf9771ee43b045ba2c3dde51573ee`
- 2.0 전투·밸런스 기준: 기능 Reviewed SHA `7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`, 통합 merge `28c6740f635e0cfffd57405879d4cdbb495d0c6b`
- 2.0 UI 기준: U5 source SHA `5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`
- 상태: 구현 전 최종 작업 계약
- 이전 계획과의 차이: **2.0을 정식 제품으로 확대하지 않고, 1.2.1에 검증 결과를 선별 이식한다.**

---

# 1. 이번 상황에 대한 정확한 해석

## 1.1 실제 개발 흐름

현재 작업은 세 개의 서로 다른 결과물을 하나로 합치는 과정이다.

### A. 정식 제품 원본 — 1.2.1

1.2.1은 다음을 이미 가진 실제 출시 제품이다.

- DAY 1~30 캠페인
- 기존 성·방·건물·시설 오브젝트
- 시설 해금·건설·업그레이드
- 몬스터 성장·특화·진화
- 적 특수 행동과 보스
- 저장·이어하기·재도전
- 원정·연대기·전선·심장·합동기
- 의회·지역·전초기지·상층
- 다중 엔딩
- Windows·Steam·PC Web·모바일 Web
- 기존 출시 검수와 사용자 저장

따라서 **1.2.1이 제품 구조와 콘텐츠의 단일 기준**이다.

### B. 전투·밸런스 검증본 — 2.0 DAY 1~5

2.0은 정식 제품을 새로 만든 것이 아니라 DAY 1~5에서 다음을 검증하기 위한 실험선이다.

- 진행을 단순하게 만들 수 있는가
- 시설·몬스터 배치가 실제 전투를 바꾸는가
- 배치·시설·몬스터 역할·명령을 포함한 전투 밸런스가 성립하는가
- DAY 1~5의 계산 방식을 이후 콘텐츠에도 확장할 수 있는가

여기서 검증한 것은 **제품 전체가 아니라 전투 규칙·인과관계·계측·밸런스 기준**이다.

### C. 별도 UI 수정본 — U1~U5

전투와 밸런스가 어느 정도 정리된 뒤 같은 2.0 검증선 위에서 UI를 별도로 수정했다.

- U1: 공통 UI·타이틀·침입 브리핑
- U2: 시설·몬스터 배치 UI
- U3: 전투 HUD
- U4: 결과 화면
- U5: UI 후보 SHA와 빌드 동결

UI 결과는 전투·밸런스 위에 올라간 **표현 계층의 참고 구현**이다.

## 1.2 최종 작업의 정의

이번 작업은 다음이 아니다.

- 2.0 브랜치를 1.2.1에 병합
- 2.0 DAY 1~5 테스트판을 DAY 30까지 단순 확장
- 1.2.1의 건물·콘텐츠를 2.0 테스트용 구조로 교체
- 1.2.1의 저장을 v20 별도 저장으로 교체
- 2.0의 임시 방·라벨·오브젝트를 제품에 그대로 복사

이번 작업은 다음이다.

> **1.2.1의 제품 구조·건물·콘텐츠·저장을 유지하면서, 2.0에서 검증한 전투 계산과 배치 인과를 일반화하고, U5 UI를 1.2.1의 실제 데이터와 기능에 맞춰 연결하여 v1.2.2를 만든다.**

---

# 2. 세 기준점의 역할

| 영역 | 기준점 | 사용 방식 |
|---|---|---|
| 스토리·DAY 1~30 | 1.2.1 | 그대로 보존 |
| 저장·이어하기 | 1.2.1 | 확장·마이그레이션 |
| 건물 ID·오브젝트 | 1.2.1 | 그대로 사용, 누락된 렌더 연결만 수정 |
| 시설 해금·업그레이드 | 1.2.1 | 그대로 사용 |
| 몬스터 성장·진화 | 1.2.1 | 그대로 사용 |
| 기존 적·보스 행동 | 1.2.1 | 그대로 보존 |
| 배치가 전투에 미치는 방식 | 2.0 전투 기준 | 계산·인과 규칙 이식 |
| 시설 효과의 실제 좌표 적용 | 2.0 전투 기준 | 일반화하여 적용 |
| 적 의도·특수 패턴 대응 | 2.0 전투 기준 | 기존 전체 적에 확대 |
| 제한 전술 명령 | 2.0 전투 기준 | 제품 공통 기능으로 이식 |
| 전투 계측 | 2.0 전투 기준 | 전체 캠페인용으로 일반화 |
| DAY 1~5 수치·시간 기준 | 2.0 밸런스 기준 | 기준 fixture로 유지 |
| DAY 6~30 수치 | 재계산 대상 | 같은 계산 체계로 새로 산출 |
| 관리·배치 UI | U5 | 1.2.1 기능 adapter를 통해 이식 |
| 전투 HUD | U5 | 기존 전체 적·보스 상태와 연결 |
| 결과 UI | U5 | 기존 성장·보상·스토리와 결합 |
| 출시·플랫폼 | 1.2.1/main | 1.2.2로 갱신 |

---

# 3. Git·브랜치 원칙

## 3.1 새 출시선

```text
main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad
└─ release/v1.2.2
```

개별 작업 브랜치:

```text
codex/v122-<topic>
```

검수 브랜치:

```text
test/v122-<topic>
```

## 3.2 금지 사항

```text
git merge release/v2.0
git cherry-pick <release/v2.0 merge commit>
git cherry-pick <release/v2.0 commit range>
git checkout release/v2.0 -- .
git checkout release/v2.0 -- scripts/game/GameRoot.gd
git checkout release/v2.0 -- scripts/game/CombatSceneController.gd
```

2.0은 **코드 공급 브랜치가 아니라 행동·수치·UI 참고 기준**이다.

## 3.3 이식 방식

각 기능마다 다음 순서를 지킨다.

1. 2.0의 사용자 행동과 완료 조건을 문서로 추출
2. 1.2.1에서 같은 책임을 가진 데이터·함수·오브젝트 확인
3. 그대로 재사용할 부분과 adapter가 필요한 부분 구분
4. 1.2.1 구조 안에 최소 hunk로 구현
5. DAY 1~5 기준 fixture와 비교
6. 1.2.1 전체 콘텐츠와 충돌 여부 확인
7. 관련 테스트만 실행
8. 최종 RC 전까지 전체 회귀는 실행하지 않음

---

# 4. 먼저 만들어야 할 통합 대응표

코드를 수정하기 전에 다음 문서를 만든다.

```text
docs/design/v122/V122_SOURCE_OF_TRUTH_MATRIX.md
docs/design/v122/V122_COMBAT_TRANSPLANT_MATRIX.md
docs/design/v122/V122_UI_TRANSPLANT_MATRIX.md
docs/design/v122/V122_BUILDING_COMPATIBILITY_MATRIX.md
docs/design/v122/V122_BALANCE_RECALCULATION_MATRIX.md
docs/design/v122/V122_SAVE_COMPATIBILITY_MATRIX.md
```

## 4.1 전투 이식 대응표 열

```text
2.0 기능
2.0 근거 SHA·함수
2.0에서 검증한 행동
1.2.1 대응 시스템
1.2.1 대응 함수·데이터
처리 방식
정식 제품 ID
추가 adapter
관련 테스트
완료 조건
```

처리 방식:

- `KEEP_121`
- `PORT_RULE`
- `ADAPT_TO_121`
- `RECALCULATE`
- `DO_NOT_PORT`
- `REMOVE_TEST_ONLY`

## 4.2 UI 이식 대응표 열

```text
U5 화면·컴포넌트
U5 source file
필요 view state
1.2.1 데이터 공급자
1.2.1 기존 기능
보존해야 할 버튼·화면
숨길 정보
신규 adapter
PC 기준
모바일 기준
실제 화면 검증
```

---

# 5. 건물·시설 통합 원칙

## 5.1 가장 중요한 결정

**2.0의 시설 이름과 효과를 이유로 1.2.1의 건물 ID·오브젝트·해금·업그레이드 구조를 교체하지 않는다.**

정식 제품에서 건물의 단일 기준은 1.2.1이다.

- 방 ID
- 시설 role
- 건물 오브젝트
- room blueprint
- prop asset
- 건설 슬롯
- 해금 조건
- 업그레이드
- 저장 데이터
- 성 단계별 외형

2.0의 시설은 정식 제품에서 별도 건물로 중복 등록하는 것이 아니라, 1.2.1 건물에 적용할 **전투 역할 계약**으로 해석한다.

## 5.2 기본 대응

| 2.0 역할 | 1.2.1 제품 기준 | 처리 |
|---|---|---|
| `v20_barracks` | `barracks` | 기존 병영 ID·오브젝트·업그레이드를 유지하고 2.0 교전 거점 계산 적용 |
| `v20_recovery_nest` | `recovery` | 기존 회복 둥지 유지, 실제 위치 기반 회복 계산 적용 |
| `v20_decoy_treasure` | `treasure` | 기존 보물 보관실 유지, 도둑 목표 유인·약탈 계산 적용 |
| `v20_watch_post` | 기존 `watch_post` facility role | 기존 해금·건설 기능 유지, reveal·후열 대응 계산 적용 |
| `v20_barricade` | 입구 문·건설 슬롯·기존 방어 시설 중 감사 후 확정 | 별도 중복 건물 생성 금지. 기존 오브젝트에 역할을 연결하거나 정말 없을 때만 신규 추가 |
| 고정 4구역 | 1.2.1 `ModuleGraph`의 실제 경로 구간 | 별도 가상 방을 만들지 않고 실제 방·통로를 논리 구간으로 묶음 |

`v20_*` ID는 내부 테스트 호환을 위해 alias로 남길 수 있지만, 제품 저장과 UI에는 1.2.1 제품 ID를 사용한다.

## 5.3 전투 맵 건물 오브젝트 문제 처리

이번 문제는 “새 건물을 전부 다시 그리는 것”이 아니다.

우선순위는 다음과 같다.

### 1순위 — 기존 1.2.1 오브젝트 연결 복구

- room blueprint의 `object_slots`
- asset manifest의 prop
- room/facility role
- 건설 결과
- combat renderer
- Y-sort
- visibility
- alpha
- scale
- anchor
- facing
- castle stage override

를 확인해 기존 오브젝트가 전투 맵에 실제로 나오게 한다.

### 2순위 — 시설 상태 연결

기존 오브젝트에 다음 상태를 연결한다.

- 기본
- 선택
- 발동
- 쿨다운
- 공병 목표
- 무력화
- 복구
- 손상
- 파괴 또는 철거

### 3순위 — 정말 없는 오브젝트만 추가

다음 조건을 모두 만족할 때만 새 그래픽을 만든다.

- 1.2.1 asset manifest에 실제 runtime asset이 없음
- 기존 prop으로 의미를 전달할 수 없음
- 해당 시설이 정식 출시 범위에 반드시 필요
- 번호가 있는 grid·anchor·facing 계약 작성 완료
- 사용자가 proof 이미지를 승인

기존 건물 전체를 새 이미지로 교체하지 않는다.

## 5.4 건물 호환 감사표

모든 정식 건물에 대해 다음을 기록한다.

```text
product_room_id
facility_role
unlock_condition
upgrade_state
room_blueprint
object_id
sprite_path
stage_override
facing
slot_anchor
management_visible
combat_visible
clickable
command_targetable
engineer_targetable
saved
result_metric
status
```

허용 상태:

- `COMPLETE`
- `INTENTIONALLY_NONVISUAL`

출시 금지 상태:

- `MISSING_OBJECT`
- `LABEL_ONLY`
- `WRONG_OBJECT`
- `WRONG_ANCHOR`
- `WRONG_FACING`
- `HIDDEN_BY_ZSORT`
- `NOT_CLICKABLE`
- `STATE_NOT_SYNCED`
- `SAVE_MISMATCH`
- `PLACEHOLDER_ONLY`

## 5.5 건물 완료 기준

- 1.2.1에서 건설 가능한 건물의 전투 오브젝트 누락 0
- 관리에서 본 건물과 전투에서 본 건물 ID 일치
- 기존 해금·업그레이드·성 단계 유지
- 공병이 목표로 삼는 건물과 실제 강조 오브젝트 일치
- 시설 발동 명령 대상이 실제 건물 오브젝트
- 무력화 중 기능 0과 시각 상태 일치
- 복구 후 기능·시각 상태 복원
- Windows·Web에서 동일
- 라벨만 있고 건물이 없는 상태 0

---

# 6. 공간·배치 시스템 이식

## 6.1 별도 2.0 지도 사용 금지

정식 제품에서는 `data/v20/dungeon_layouts.json`을 제품 맵의 단일 기준으로 사용하지 않는다.

기준은 1.2.1의:

- quarter layout
- `ModuleGraph`
- room blueprint
- 현재 성 단계
- 실제 건설 결과
- 실제 연결 socket

이다.

## 6.2 신규 제품 adapter

권장 신규 모듈:

```text
scripts/v122/spatial/V122BattlePlanAdapter.gd
scripts/v122/spatial/V122DefenseSegmentBuilder.gd
scripts/v122/spatial/V122PlacementSlotAdapter.gd
```

### `V122BattlePlanAdapter`

현재 1.2.1 성 상태에서 이번 전투용 snapshot을 만든다.

```text
layout_id
layout_fingerprint
rooms
corridors
active_route
enemy_goals
defense_segments
facility_slots
monster_slots
facility_placements
monster_placements
world_anchors
combat_bounds
```

### `V122DefenseSegmentBuilder`

실제 route를 UI용 방어 구간으로 묶는다.

DAY 1~5에서는 2.0 기준 4단계와 최대한 동일하게 구성한다.

DAY 6~30에서는 실제 성 구조와 적 목표에 따라 3~6단계로 동적 생성한다.

### `V122PlacementSlotAdapter`

기존 방·시설·몬스터 수용량을 U5 배치 UI가 이해할 수 있는 slot view model로 변환한다.

## 6.3 완료 기준

- 관리에서 배치한 room·slot이 전투 spawn과 동일
- 별도 zone translation table 최소화
- 방 이름만 바뀌고 실제 위치가 다른 경우 0
- 저장→불러오기→전투 위치 동일
- 기존 성 확장 Stage 1~4 작동
- 기존 user custom layout이 있으면 명시적으로 지원 또는 숨김 결정
- 정체 복구 유지

---

# 7. 전투 시스템 이식

## 7.1 그대로 이식할 전투 규칙

- 시설 효과는 실제 월드 위치와 범위에서만 적용
- 몬스터 배치 위치가 spawn과 home position을 결정
- 적 역할이 목표·표적·이동을 결정
- 도둑은 실제 보물 목표를 선택하고 약탈·도주
- 공병은 실제 시설을 목표로 접근하고 무력화
- 방패병과 후열이 실제 보호 관계를 형성
- 감시 초소 reveal이 후열 대응에 영향을 줌
- 비상 후퇴가 실제 위치 이동
- 제한 명령 사용 여부가 실제 전개와 결과를 변경
- event ledger에서 결과를 계산
- A/B/C/D fixture로 배치 인과를 검증

## 7.2 1.2.1에서 보존할 전투 규칙

- 기존 자동전투 기본 루프
- 몬스터 자동 스킬
- 기존 모든 적 특수 행동
- 기존 보스 페이즈
- 기존 경로 정체 복구
- 기존 성장·특화·진화 효과
- Update 2~4의 전투 기능
- 기존 스킬·피격·사망 애니메이션
- 기존 음향과 효과
- 기존 전투 결과가 성장·스토리로 이어지는 흐름

## 7.3 AI 통합 우선순위

2.0 조건문을 기존 AI 앞에 무조건 조기 반환시키지 않는다.

### 몬스터

1. 사망·생존·강제 이탈
2. 플레이어 제한 명령
3. 보스·스토리 강제 상태
4. 긴급 목표 방어
5. 기존 고유 스킬과 역할 행동
6. 2.0식 배치 역할
7. 현재 교전
8. home slot 복귀
9. 정체 복구

### 적

1. 사망·시전·강제 상태
2. 기존 보스·고유 특수 행동
3. 현재 작전 목표
4. 공병·도둑 등 역할 목표
5. 다음 방어 구간 이동
6. 교전·표적 선택
7. 돌파 행동
8. 최종 목표 공격
9. 정체 복구

## 7.4 제한 명령

제품 공통 명령:

- 집결
- 집중
- 시설 발동
- 비상 후퇴

2.0 서비스 코드를 그대로 복사하지 않고 1.2.1 actor·room·facility ID에 맞춘 adapter를 둔다.

명령에는 반드시 다음이 있다.

- 비용
- 대상
- 시작 조건
- 종료 조건
- 지속시간
- cooldown
- AI 우선권
- 이동 중 공격 충돌 해결
- 실제 대상 강조
- event ledger
- 결과 기여

## 7.5 관문 돌파

2.0의 `stop_navigation + timer + 문구`만 사용하는 돌파는 제품에 이식하지 않는다.

제품 돌파는 다음 중 실제 오브젝트와 맞는 행동으로 구현한다.

- 문 공격
- 방벽 밀기
- 봉인 해제
- 돌진
- 시설 파괴

필수 구성:

```text
breach_target
breach_animation
breach_progress
interrupt_condition
complete_event
next_route
visual_feedback
audio_feedback
```

---

# 8. DAY 1~5 기준 재현

## 8.1 목표

1.2.1 제품 구조 안에서 2.0 DAY 1~5의 전투 인과와 밸런스를 재현한다.

다만 다음은 1.2.1 제품 구조를 따른다.

- 건물 ID·오브젝트
- 몬스터 성장 데이터
- 저장
- 보상
- 스토리
- DAY 5 이후 진행

## 8.2 기준으로 사용할 수치

DAY 1~5의:

- 적 종류
- spawn 시점
- HP·ATK
- 두 유효 대응 A/B
- 오답 C
- 한 슬롯 차이 D
- 전투 시간 범위
- 도난
- 시설 무력화
- 후열 압박
- 돌파·누수
- 명령 효과

를 기준 fixture로 고정한다.

## 8.3 1.2.1과 충돌하는 테스트 전용 조건 제거

2.0 테스트에서 사용한 다음 조건은 정식 제품에 그대로 넣지 않는다.

- 몬스터 level 1 고정
- EXP 0 고정
- DAY별 성장 초기화
- 건설 점수 10의 독립 테스트 경제
- DAY 5 terminal 종료
- 별도 v20 저장
- 별도 v20 타이틀
- debug acceptance 진입점

정식판에서는 같은 전투 난이도를 재현할 수 있는 **캠페인 초기 상태 fixture**를 만들고 실제 성장·재화·보상을 사용한다.

## 8.4 완료 기준

- 2.0 기준 A/B가 1.2.2에서도 승리
- C가 같은 실패 원인으로 패배 또는 명확한 불이익
- D 한 슬롯 차이가 이동·첫 교전·피해 중 2개 이상 변경
- 전투 시간이 기준 범위에서 크게 벗어나지 않음
- DAY 5 승리 후 정상 DAY 6 진행
- 기존 스토리·성장·저장 정상

---

# 9. 밸런스 재계산 체계

## 9.1 핵심 원칙

DAY 6~30에 DAY 1~5의 HP 배율을 단순 복사하지 않는다.

같은 **계산 구조**를 사용하되 다음을 매 DAY 실제로 다시 측정한다.

- 해당 DAY의 몬스터 성장
- 특화·진화
- 보유 몬스터 수
- 시설 해금·업그레이드
- 성 단계와 경로 길이
- 명령력
- 심장·합동기·전초기지·상층 효과
- 적 역할과 보스 패턴
- 목표 수
- 예상 전투 시간

## 9.2 기준 지표

### 플레이어 전투력

```text
P_DPS = 실제 유효 배치의 몬스터 총 피해 / 실제 교전 시간
P_EHP = 시작 HP + 실제 회복 + 실제 방어막 + 실제 감소 피해
P_CONTROL = 감속 시간 + 경직 시간 + 경로 지연
P_FACILITY = 시설 추가 피해 + 감소 피해 + 회복 + 지연 가치
P_COMMAND = 명령 사용 전후의 피해·생존·목표 손실 차이
```

### 적 압력

```text
E_HP = 적 전체 실효 HP
E_DPS = 실제 공격 가능 시간 동안의 적 총 피해
E_OBJECTIVE = 왕좌·보물·시설·심장에 준 압력
E_ROLE = 도난·무력화·보호·후열·돌파·시전 등 역할 압력
E_COMPLEXITY = 동시에 판단해야 하는 새 패턴 수
```

## 9.3 계산식

초기 계산식은 2.0 DAY 1~5 event ledger로 계수를 맞춘 뒤 사용한다.

### 적 총 HP 예산

```text
WaveHPBudget
= P_DPS_median
× TargetCombatSeconds
× TargetAttackUptime
× DifficultyModifier
× ComplexityDiscount
```

### 적 총 피해 예산

```text
WaveDPSBudget
= (
    P_EHP_median × TargetMonsterLossRatio
    + ObjectiveHP × TargetObjectiveLossRatio
    + ExpectedHealing
  )
  / TargetCombatSeconds
```

### 복잡도 할인

새 패턴이 많을수록 HP·ATK를 동시에 크게 올리지 않는다.

```text
ComplexityDiscount
= clamp(
    1.00
    - 0.07 × NewHardPatternCount
    - 0.04 × ExtraSimultaneousObjectiveCount
    - 0.03 × ForcedCommandMomentCount,
    0.72,
    1.00
  )
```

이 계수는 계획상의 시작값이다. DAY 1~5 실제 기록을 재생해 전투 시간·피해 오차가 ±10% 안에 들도록 보정한 뒤 동결한다.

### 개별 적 배분

```text
UnitHP
= WaveHPBudget × RoleHPShare / UnitCount

UnitATK
= WaveDPSBudget
× AttackInterval
× RoleDamageShare
/ ExpectedActiveAttackerCount
```

## 9.4 시설 가치 계산

```text
FacilityValue
= AddedDamage
+ PreventedDamage
+ EffectiveHealing
+ DelaySeconds × P_DPS
+ ObjectiveLossPreventedValue
```

시설은 단순 설명 수치가 아니라 event ledger로 실제 기여를 계산한다.

## 9.5 명령 가치 계산

```text
CommandValue
= NoCommandOutcome - CommandOutcome
```

비교 지표:

- 왕좌 피해
- 몬스터 손실
- 시설 손실
- 도난
- 무력화 시간
- 후열 압박 시간
- 돌파 구간
- 전투 시간

명령이 언제나 필수여서는 안 된다.

DAY별 분류:

- `OPTIONAL_ADVANTAGE`
- `RECOMMENDED`
- `REQUIRED_FOR_ONE_RESPONSE`
- `REQUIRED_FOR_BOSS_INTERRUPT`

## 9.6 DAY별 밸런스 시트

각 DAY에 다음 행을 만든다.

```text
DAY
캠페인 상태 fixture
플레이어 성장 수준
보유 몬스터
사용 가능 시설
성 단계
적 편대
적 목표
새 패턴
사전 예고
유효 대응 A
유효 대응 B
오답 C
한 슬롯 인과 D
명령 분류
목표 시간
허용 왕좌 피해
허용 몬스터 손실
필수 실패 원인
3 seed 결과
판정
```

## 9.7 구간별 작업

- B1: DAY 6~10
- B2: DAY 11~15
- B3: DAY 16~20
- B4: DAY 21~25
- B5: DAY 26~30

각 구간은 앞 구간의 성장 결과 fixture를 입력으로 사용한다.

다음 구간을 먼저 조정하지 않는다.

## 9.8 보스 밸런스

보스는 일반 wave HP 공식만 사용하지 않는다.

별도로 계산한다.

```text
PhaseHPBudget
PhaseTimeTarget
TelegraphWindow
InterruptThreshold
SummonBudget
ObjectivePressureBudget
RecoveryWindow
FinalPhaseRisk
```

한 페이즈에서 새 판단을 추가하면 같은 페이즈의 raw HP·ATK 상승을 제한한다.

---

# 10. UI 이식 원칙

## 10.1 U5를 그대로 복사하지 않음

U5 UI는 다음을 참고한다.

- 정보 우선순위
- 화면 배치
- 클릭·드래그 피드백
- 전투 HUD 밀도
- 위협 예고
- 명령 targeting
- 결과 원인 표현

하지만 데이터는 1.2.1에서 공급한다.

## 10.2 정식판 UI 구조

### 타이틀

1.2.1 타이틀과 저장을 유지한다.

제거:

- `DAY 1~5 전술 방어 테스트`
- 별도 2.0 새 테스트
- 별도 2.0 이어하기
- source SHA badge

### 침입 확인

기존 DAY 스토리와 encounter data에서 다음을 표시한다.

- 적 편대
- 적 목표
- 활성 침입 경로
- 새 패턴
- 주의할 건물·몬스터 역할
- 배치 시작

### 관리·배치

U5의 중앙 맵·우측 도구함 구조를 사용하되 다음을 모두 지원한다.

- 전체 보유 몬스터
- 기존 건물
- 기존 시설 해금·업그레이드
- 기존 성 확장
- 성장·진화
- 심장·합동기
- 원정·연대기
- 의회·전초기지·상층

핵심 배치와 관계없는 기능은 상시 버튼이 아니라 context drawer 또는 별도 안전 화면으로 연결한다.

### 전투 HUD

- 현재 실제 목표
- 현재 활성 경로 구간
- 위협이 있을 때만 telegraph
- 네 명령
- 실제 시설 오브젝트 targeting
- 기존 보스 전용 상태
- 기존 심장·합동기 상태
- 속도·일시정지

### 결과

U5의 원인 중심 구조에 다음을 결합한다.

- 성장
- 특화·진화
- 보상
- 스토리
- 메타 진행
- 엔딩 조건
- 다음 DAY

## 10.3 UI 완료 기준

- 기존 기능 진입 불가 0
- 기존 기능이 UI에서 사라지는 경우 0
- dead button 0
- 빈 drawer 0
- 개발자 문구 0
- 1280×720·1366×768·1920×1080
- 모바일 844×390
- 가로·세로 안내
- 마우스·키보드·터치

---

# 11. 저장·성장·스토리 연결

## 11.1 제품 저장 기준

정식 제품은 `CampaignSaveStore`만 사용한다.

`V20SaveStore`는 테스트 도구로만 남기거나 제거한다.

## 11.2 저장에 추가할 항목

기존 저장 schema에 다음을 추가한다.

- battle plan snapshot
- 시설 slot 배치
- 몬스터 slot 배치
- 마지막 확정 배치
- retry snapshot
- 명령 설정
- UI 접기 상태 중 제품에 필요한 최소값

전투 중간 runtime transient 상태는 기본 저장 대상이 아니다.

## 11.3 호환 fixture

- v1.2.0 새 게임
- v1.2.1 DAY 1
- DAY 3 성장 전·후
- DAY 5
- DAY 12 진화
- DAY 20 전선
- DAY 25 보스
- DAY 29
- DAY 30
- 엔딩 완료
- Update 4 캠페인
- corrupt
- tmp
- bak

## 11.4 완료 기준

- 기존 저장 데이터 손실 0
- 기존 저장 자동 백업
- migration 실패 시 원복
- 성장 버튼 P1 재발 0
- 재도전 차단 재발 0
- 안전 저장 화면 불일치 0
- DAY 5→6 정상
- DAY 30→엔딩 정상

---

# 12. 구현되지 않은 기능·자잘한 버그 전수 정리

## 12.1 구현 여부 매트릭스

```text
docs/audit/v122/V122_IMPLEMENTATION_CLOSURE_MATRIX.md
docs/audit/v122/V122_IMPLEMENTATION_CLOSURE_MATRIX.json
```

각 기능은 다음을 모두 가져야 한다.

```text
요구 문서
데이터
runtime consumer
UI 진입점
입력 handler
저장
전투·결과 반영
자동 테스트
실제 실행 증거
```

## 12.2 허용 상태

- `IMPLEMENTED`
- `INTENTIONALLY_HIDDEN`
- `REMOVED`

## 12.3 출시 금지 상태

- `DOC_ONLY`
- `DATA_ONLY`
- `UI_ONLY`
- `TEST_ONLY`
- `DEAD_CLICK`
- `UNREACHABLE`
- `SAVE_MISSING`
- `VISUAL_MISSING`
- `WRONG_DESCRIPTION`
- `PENDING`
- `UNKNOWN`

## 12.4 자동 검색

- TODO
- FIXME
- PENDING
- 준비 중
- 예정
- 미구현
- 임시
- placeholder
- test only
- debug only
- 항상 빈 결과
- 연결되지 않은 signal
- handler 없는 action
- 존재하지 않는 resource
- 결과에 쓰이지 않는 metric
- UI 문구와 실제 수치 불일치

## 12.5 실제 순회

에이전트가 다음을 실제 조작한다.

- 모든 타이틀 버튼
- 모든 관리 버튼
- 모든 건설
- 모든 시설 선택
- 모든 몬스터 drag
- 모든 명령
- 모든 결과 버튼
- 모든 성장·진화
- 원정·연대기
- 심장·합동기
- 의회·전초기지·상층
- 엔딩
- 저장·이어하기·재도전

---

# 13. PR 실행 계획

| 순서 | 브랜치 | 목적 | 다음 단계 조건 |
|---:|---|---|---|
| P0 | `codex/v122-integration-contract` | 이번 교정 계획과 3개 기준점 고정 | 문서 merge |
| P1 | `codex/v122-source-audit` | 1.2.1·전투 기준·UI 기준 대응표 | UNKNOWN 0 |
| P2 | `codex/v122-building-compatibility` | 기존 건물 ID·오브젝트·기능·렌더 연결 | 건물 누락 0 |
| P3 | `codex/v122-spatial-placement-adapter` | 1.2.1 ModuleGraph 기반 배치·구간 | 관리↔전투 위치 일치 |
| P4 | `codex/v122-combat-rule-adapter` | 2.0 전투 인과·명령·계측 이식 | DAY 1 fixture 작동 |
| P5 | `codex/v122-day01-05-parity` | DAY 1~5 기준 재현 | A/B/C/D gate |
| P6 | `codex/v122-ui-management` | U5 관리·배치 UI와 전체 제품 기능 결합 | 기존 기능 진입 가능 |
| P7 | `codex/v122-ui-combat-result` | U5 전투 HUD·결과와 전체 전투 연결 | 전체 적·보스 상태 표시 |
| P8 | `codex/v122-save-progression` | 저장·성장·보상·DAY 6 연결 | 모든 fixture PASS |
| P9 | `codex/v122-balance-model` | DAY 1~5로 계산 계수 보정 | 오차 ±10% 이내 |
| P10 | `codex/v122-balance-day06-10` | DAY 6~10 재계산 | 구간 gate |
| P11 | `codex/v122-balance-day11-15` | DAY 11~15 재계산 | 구간 gate |
| P12 | `codex/v122-balance-day16-20` | DAY 16~20 재계산 | 구간 gate |
| P13 | `codex/v122-balance-day21-25` | DAY 21~25 재계산 | 구간 gate |
| P14 | `codex/v122-balance-day26-30` | DAY 26~30·보스 재계산 | 구간 gate |
| P15 | `codex/v122-content-compatibility` | Update 2~4·엔딩 전수 연결 | coverage 100% |
| P16 | `codex/v122-implementation-closure` | 미구현·dead click·자잘한 버그 폐쇄 | 금지 상태 0 |
| P17 | `codex/v122-release-readiness` | 버전·export·플랫폼 준비 | RC 준비 |
| RC0 | `release/v1.2.2` | 기능 동결·SHA 고정 | 전체 검수 시작 |
| F1 | 검수 전용 | 전체 에이전트·전체 회귀·실플레이 | P0/P1/P2/P3 0 |
| F2 | 출시 | 동일 SHA 빌드·태그·Release | `v1.2.2` |

---

# 14. 에이전트 구성

## 14.1 기준 추출

### Reference Contract Agent

- PR #69~#71에서 전투 인과와 수치 추출
- U1~U5에서 UI 행동 추출
- 코드 복사 없이 behavior contract 작성

### 1.2.1 Product Audit Agent

- 전체 DAY·건물·몬스터·적·보스·저장·엔딩 목록
- 제품 기능 기준 작성

## 14.2 구현

### Building Compatibility Agent

- 기존 building object와 facility role 연결
- 전투 렌더 누락 해결

### Spatial Integration Agent

- ModuleGraph·route·slot adapter

### Combat Integration Agent

- AI·명령·시설 효과·event ledger

### UI Integration Agent

- U5 UI를 제품 view model에 연결

### Save/Progression Agent

- 저장·성장·보상·스토리

### Balance Agent

- 계산식 보정과 DAY별 sheet

### Content Agents

- C1: DAY 6~10
- C2: DAY 11~15
- C3: DAY 16~20
- C4: DAY 21~25
- C5: DAY 26~30·보스
- C6: Update 2
- C7: Update 3
- C8: Update 4

## 14.3 검수

### Static Closure Agent

- doc/data/UI/test-only 상태 검사

### Save Review Agent

- migration·backup·corrupt 복구

### Visual QA Agent

- 건물·UI·Y-sort·해상도

### Combat QA Agent

- AI·명령·정체·x1/x3

### Campaign QA Agent

- DAY 1~30·엔딩

### Evidence Audit Agent

- SHA·hash·artifact·결과 재계산

## 14.4 충돌 방지

- `GameRoot.gd`, `CombatSceneController.gd`, `ManagementSceneController.gd`는 한 시점에 한 agent만 수정
- Content Agent는 공통 controller 수정 금지
- Balance Agent는 그래픽·UI 수정 금지
- UI Agent는 전투 수치 수정 금지
- Building Agent는 전투 계산식 수정 금지
- Reviewer는 직접 수정 금지
- Orchestrator만 release branch merge

---

# 15. 개발 중 검증

사용자의 이전 지시에 따라 전체 검수는 최종 RC에서만 한다.

각 PR에서는 다음만 실행한다.

- 관련 unit test
- 관련 integration test
- 관련 실제 화면
- 관련 전투 fixture
- `RunCoreVerification -Mode Quick`
- repository policy

실행하지 않는다.

- 전체 DAY 1~30 플레이
- 전체 회귀 Full
- 최종 초회 사용자 표본
- 전체 검수 에이전트
- 정식 release export
- 공개 URL 교체

---

# 16. 최종 RC 전체 검수

## 16.1 시작 조건

- P0~P17 전부 merge
- 기능·데이터·씬·자산 변경 예정 0
- 작업 트리 clean
- 구현 폐쇄 매트릭스 금지 상태 0
- 최종 RC full SHA 고정
- Windows·Web 후보 hash 고정

## 16.2 자동 전체 검수

- 기존 전체 core verification
- 신규 v1.2.2 테스트
- 모든 저장 migration fixture
- 모든 건물 object fixture
- 모든 적 behavior handler
- 모든 보스 phase
- 모든 엔딩 조건
- 모든 UI action

## 16.3 실제 물리 전투

### DAY 1~5

기존 기준 유지:

```text
A/B/C/D × DAY 1~5 × seed 3
+ 결정론 재실행
```

### DAY 6~30

각 DAY:

- 유효 대응 A, seed 3
- 유효 대응 B, seed 3
- 오답 C, seed 1
- x3 표본 최소 1

자동 실행 결과를 DAY별 balance sheet와 비교한다.

## 16.4 수동 QA

- 신규 게임 DAY 1~30 완주
- v1.2.1 중간 저장 이어하기→엔딩
- 시설 중심 빌드
- 몬스터 성장 중심 빌드
- 명령 최소 사용 빌드
- Update 2~4 대표 경로
- 모바일 대표 흐름

## 16.5 초회 사용자

10명:

- 새 게임
- DAY 1~5
- 시설 배치
- 몬스터 배치
- 명령 사용
- 결과 이해

자동 검수와 분리하여 기록한다.

## 16.6 최종 사용자 승인

```text
V122_OWNER_RELEASE_APPROVED
source_sha: <RC full SHA>
windows_zip_sha256: <hash>
web_pck_sha256: <hash>
decision: v1.2.2 정식 출시 승인
```

## 16.7 출시 차단 기준

- P0 0
- P1 0
- P2 0
- 사용자 노출 P3 0
- 저장 손실 0
- 건물 오브젝트 누락 0
- dead click 0
- 미구현 기능 0
- placeholder-only 정식 기능 0
- 전체 테스트 실패 0
- RC 이후 runtime 변경 0

하나라도 실패하면 새 RC를 만들고 전체 검수를 처음부터 다시 한다.

---

# 17. 출시

- `project.godot`: `1.2.2`
- Windows file/product version: `1.2.2.0`
- Windows ZIP: `MawangCastle-v1.2.2-Windows.zip`
- annotated tag: `v1.2.2`
- GitHub Release: `마왕성 v1.2.2`
- PC Web 갱신
- 모바일 Web 갱신
- Steam package
- SHA-256
- build manifest
- release notes
- provenance

`v1.2.1` 태그와 Release는 이동하거나 교체하지 않는다.

---

# 18. 코덱스 첫 작업 지시문

```text
저장소 bluehige/mawangseong-demo에서 v1.2.2 통합 계획을 시작한다.

이번 작업의 정확한 의미:
- 1.2.1은 정식 제품 원본이다.
- release/v2.0의 PR #69~#71 결과는 DAY 1~5 전투·배치·밸런스 기준이다.
- U1~U5 결과는 별도 UI 기준이다.
- 2.0 브랜치를 제품에 병합하지 않는다.
- 1.2.1의 건물 ID·오브젝트·해금·업그레이드·저장·DAY 1~30 콘텐츠를 유지한다.
- 2.0의 계산과 행동 규칙을 1.2.1 구조에 adapter 방식으로 이식한다.
- DAY 6~30은 DAY 1~5에서 보정한 같은 계산 체계로 다시 산출한다.
- 기존 건물이 전투 맵에 나오지 않는 문제는 신규 건물 전체 재제작이 아니라
  1.2.1 room blueprint·prop·renderer 연결부터 복구한다.
- UI는 U5를 그대로 복사하지 않고 1.2.1 전체 기능의 view model을 연결한다.
- 전체 검수는 최종 RC F1에서만 실행한다.

기준:
- 제품 기준: main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad
- v1.2.1 runtime: c483d135b13cf9771ee43b045ba2c3dde51573ee
- 2.0 combat reference: 7e61cc9762b5c157a52160ce7f13ad0bf0a7d358
- 2.0 UI reference: 5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1

첫 작업 P0:
1. main 기준에서 release/v1.2.2 생성
2. codex/v122-integration-contract 생성
3. 이번 ‘마왕성 v1.2.2 — 2.0 검증 결과 선별 통합 계획서’를
   docs/design/v122/V122_V20_VALIDATED_TRANSPLANT_PLAN.md로 추가
4. AGENTS.md, PRODUCT_VERSIONING, GIT_VERSIONING_WORKFLOW 갱신
5. 기존 release/v2.0-product·v2.0.0 이식 지시를 superseded 처리
6. 세 기준점의 역할을 문서에 명시
7. 다음 P1에서 만들 대응표 6종을 고정
8. runtime/data/scene/asset 변경 0 확인
9. git diff --check와 repository policy 실행
10. CURRENT와 날짜별 handoff 갱신

P0 전에는 코드를 수정하지 마라.
release/v2.0을 merge하거나 commit range를 cherry-pick하지 마라.
GameRoot.gd와 CombatSceneController.gd를 통째로 복사하지 마라.
1.2.1 건물과 저장 구조를 v20 구조로 교체하지 마라.
전체 검수를 실행하지 마라.
```
