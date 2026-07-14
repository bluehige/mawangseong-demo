# 「마왕님, 마왕성은 누가 지켜요?」
# 몬스터 애착·분기 진화·다중 엔딩·다회차 확장 개발 기획서

- 작성일: 2026-07-12
- 검토 저장소: `bluehige/mawangseong-demo`
- 기준 브랜치: `main`
- 기준 최신 커밋: `ab2d445da35ee087dc29bd01e1e740ff4a5769a3` (`Add campaign save and continue support`)
- 엔진/언어: Godot 4.5 / GDScript
- 기준 해상도: 1920×1080, PC 16:9
- 문서 용도: 이 파일 전체를 Codex에 제공하되, **한 번에 전부 구현시키지 않고 아래 작업 순서대로 한 기능 묶음씩 진행**한다.

---

## 검토 근거 파일

이 기획은 다음 현재 저장소 파일을 우선 근거로 작성했다. 실제 구현 시작 시 `main`이 기준 커밋보다 앞서 있다면 Phase 0에서 다시 비교하고, 새 구현을 무시하지 말고 이 문서의 결정 로그에 차이를 기록한다.

```text
README.md
project.godot
docs/DEMO_COMPLETION_STATUS.md
docs/GAMEPLAY_CORE_AUDIT_2026-07-10.md
docs/STORY_PLAN_AFTER_TUTORIAL_2026-07-08.md
docs/design/README.md
docs/design/EVOLUTION_SYSTEM_REFERENCE_OPTIONS_2026-07-07.md
docs/regular_version/REGULAR_VERSION_TARGET_SUMMARY.md
docs/regular_version/FOLDER_STRUCTURE.md
docs/HANDOFF_DAY12_FIRST_PROMOTION_2026-07-09.md
docs/HANDOFF_DAY28_30_FINALE_2026-07-12.md
docs/HANDOFF_CAMPAIGN_SAVE_CONTINUE_2026-07-12.md
data/monsters.json
data/characters.json
data/skills.json
data/specializations.json
data/evolution_rules.json
data/campaign_days.json
data/raid_missions.json
scripts/core/GameState.gd
scripts/core/DataRegistry.gd
scripts/core/CampaignSaveStore.gd
scripts/game/GameRoot.gd
scripts/game/CombatSceneController.gd
scripts/game/ManagementSceneController.gd
scripts/units/Unit.gd
tools/DemoSmokeTest.gd
tools/BalanceSimulation.gd
tools/UIRegressionVisualReview.gd
tools/tests/core_verification_suite.json
```

## 0. Codex가 가장 먼저 지켜야 할 실행 명령

이 문서는 아이디어 모음이 아니라 구현 순서가 고정된 개발 계약이다.

1. **DAY 30은 계속 정규 캠페인의 최종일이다. DAY 31~40을 만들지 않는다.** 다회차는 DAY 30 엔딩 뒤 새 회차를 시작하는 구조다.
2. 기존 `main`의 DAY 1~30 캠페인, 4단계 성 진화, 저장·이어하기, 자동 검사 결과를 기준선으로 보존한다.
3. 한 세션/한 PR에는 이 문서의 한 작업 묶음만 다룬다.
4. 먼저 데이터 계약과 테스트를 만든 뒤 런타임을 연결한다. 그래픽은 ID·동작·파일 계약이 확정된 뒤 제작한다.
5. `GameRoot.gd`에 새 상태와 조건문을 계속 직접 추가하지 않는다. 새 기능은 일반 `RefCounted` 또는 `Node` 서비스로 만들고 테스트한 뒤 연결한다.
6. 기존 콘텐츠 ID는 삭제하거나 재사용하지 않는다. 마이그레이션 없이 `slime`, `goblin`, `imp`, 기존 승급 ID를 바꾸지 않는다.
7. 저장 v1을 손상시키거나 즉시 삭제하지 않는다. v2 마이그레이션 성공 뒤에도 최초 릴리스에서는 v1 백업을 남긴다.
8. 기존 전체 검증이 실패하면 다음 단계로 넘어가지 않는다. 신규 기능을 얹어 실패를 가리는 수치 조정도 금지한다.
9. 푸딩 수직 구현이 끝나기 전에 곱·핀·로로·신규 몬스터를 동시에 작업하지 않는다.
10. 이 범위에서 융합, 장비 세트, 다층 성, 완전 자유건설, 진화 2~3단계, 12종 몬스터 일괄 제작은 구현하지 않는다.

### 최초 실행 단위

Codex가 이 문서를 받은 직후 수행할 작업은 **19장 Phase 0만**이다. Phase 0 결과를 기록하고 검증한 뒤 Phase 1로 넘어간다. 전체 계획을 한 번에 코드로 만들지 않는다.

---

## 1. 저장소 확인 결과와 현재 상태

### 1.1 현재 게임은 이미 3일 데모가 아니다

현재 저장소에는 다음이 구현되어 있다.

- DAY 1~3 온보딩과 DAY 4~30 정규 캠페인
- 관리 → 원정/준비 → 전투 → 결산 → 다음 날 루프
- Stage 01 동굴부터 Stage 04 대마왕성까지 4단계 성 진화
- 11개 구역과 병영·감시초소·회복 시설·수호핵 등 시설 역할
- 슬라임 푸딩, 고블린 곱, 임프 핀, 원정 지원 코볼트 로로
- 몬스터 레벨/EXP, DAY 2 전술 특화, DAY 12/23 승급
- 전체 지침, 방 지침, 자동 전투, 한 마리 직접 조종, 스킬
- DAY 28 최종 원정 선택, DAY 29 결전 전야, DAY 30 3단계 최종 공성전
- 승리 엔딩, DAY 30 패배 재도전, 후일담, 새 게임
- 저장 v1, 자동 저장, 이어하기, 손상 파일 판정, 안전 교체, 복원 검사
- 광범위한 스모크·밸런스·UI 회귀 검사

따라서 이 확장은 기존 캠페인을 다시 만드는 작업이 아니다. **현재 완성된 30일 캠페인 위에 개별 몬스터 기록, 관계, 분기 진화, 엔딩 평가, 영구 프로필, 새 회차를 얹는 작업**이다.

### 1.2 현재 성장 구조

현재 몬스터 성장에는 이미 두 층이 있다.

- `data/specializations.json`: 푸딩/곱/핀마다 2개 전술 특화가 있으며 AI 행동과 스킬 보정을 바꾼다.
- `data/evolution_rules.json`: 푸딩/곱/핀마다 DAY 12 이후 사용할 수 있는 고정 승급이 1개씩 있다.

현재 승급은 다음 세 가지다.

| 몬스터 | 현재 승급 ID | 현재 표시 이름 | 역할 |
|---|---|---|---|
| 푸딩 | `slime_gate_bulwark` | 성문 방벽 푸딩 | 전열 방벽 |
| 곱 | `goblin_ambush_captain` | 매복대장 고브 | 추격 |
| 핀 | `imp_flame_adept` | 화염 숙련자 핀 | 원거리 화력 |

문제는 전술 특화는 2갈래인데, 시각적·서사적 보상인 승급은 1갈래라는 점이다. 또한 승급 그래픽은 배지와 이름 변화가 중심이며, 완전한 진화 형태의 전투 프레임은 아직 없다.

### 1.3 현재 엔딩 구조

DAY 30 데이터에는 다음 두 결과가 있다.

- 승리: `true_demon_castle`
- 패배: `named_rivals_retry`

패배는 수집형 엔딩이 아니라 DAY 30 재도전 흐름이다. 승리 엔딩은 현재 사실상 하나이며 `post_campaign_mode`는 Stage 04 후일담 유지다. 다중 엔딩을 위해서는 DAY 30 코드에 `if`를 계속 붙이는 것이 아니라 **일반화된 엔딩 조건 평가기**가 필요하다.

### 1.4 현재 저장·상태 구조의 위험

- `GameState.gd`는 날짜, 자원, 왕좌 체력, 승패, 플레이어 이름 등 최소 전역값만 보관한다.
- 로스터, 진화, 특화, 원정, 캠페인 플래그, 결산 성장, 전투 지표, 저장 페이로드 대부분은 `GameRoot.gd`에 집중되어 있다.
- 저장 v1은 `world.monster_roster`를 종족 ID 키의 Dictionary로 저장한다.
- 로스터 기본값은 사실상 `slime`, `goblin`, `imp` 각각의 `level`, `exp`, `room`이다.

이 상태에서 유대, 추억, 개별 이름, 다회차 계승, 5~7개 엔딩 조건을 추가하면 `GameRoot.gd`가 더 거대해지고 저장 검증도 취약해진다. **새 콘텐츠보다 먼저 상태 모델을 분리해야 한다.**

### 1.5 즉시 정리할 데이터 불일치

`CHR_GOB`의 캐릭터 표시 이름은 `곱`인데, 현재 승급 표시 이름은 `매복대장 고브`다.

결정:

- 캐릭터의 고유 이름은 **곱**으로 통일한다.
- 기존 승급 ID `goblin_ambush_captain`은 유지한다.
- 표시 문자열만 `매복대장 곱`으로 수정한다.
- 저장 데이터에는 표시 문자열을 저장하지 않고 ID만 저장한다.
- 기존 대사/이미지 파일명을 대규모로 바꾸지 않는다.

---

## 2. 확장 목표

### 2.1 플레이어가 느껴야 할 핵심 감정

1. **이 몬스터는 내 부하다.** 전투 수치가 아니라 이름, 활약, 선택, 추억으로 기억한다.
2. **같은 종족이라도 내가 고른 방식으로 성장했다.** 진화가 단순 상위호환이 아니라 역할과 행동을 바꾼다.
3. **이번 마왕성은 지난 마왕성과 달랐다.** 시설·지침·원정·관계·진화 선택이 엔딩에 남는다.
4. **다음 회차에는 다른 부하와 다른 기풍을 만들고 싶다.** 엔딩 보상과 계승 선택이 다음 빌드를 열어 준다.
5. **조건을 몰라서 실패한 것이 아니다.** 엔딩 방향은 완전히 숨기지 않고, 플레이 중 정성적 힌트를 준다.

### 2.2 제품 설계 축

| 축 | 구현 의미 |
|---|---|
| 개별성 | 종족 ID와 별도로 `instance_id`, 고유 이름, 유대, 전투 기록, 추억을 보유 |
| 선택성 | 전술 특화 2개 × 진화 2개 × 스킬 장착으로 몬스터별 여러 빌드 제공 |
| 가시성 | 진화 외형, 초상, 배지, VFX, 결산 활약 문구가 실제로 달라짐 |
| 서사성 | 몬스터 이벤트와 관계 수치가 엔딩 조건과 후일담에 연결 |
| 반복성 | DAY 30 뒤 새 회차, 엔딩 도감, 계승 추억, 새 교리/계약 해금 |
| 안정성 | 데이터 기반 조건식, 저장 v2 마이그레이션, 자동 도달성 검사 |

### 2.3 하지 않을 설계

- 수치가 무한히 누적되는 환생 시스템
- 매 회차 레벨·장비·자원을 전부 유지해 난이도를 무력화하는 방식
- 몬스터 영구 사망
- 호감도를 올리기 위한 반복 선물 클릭
- 마지막 선택 한 번으로 30일의 플레이를 전부 무효화하는 엔딩
- 숨겨진 단일 “진 엔딩”을 다른 엔딩보다 우월하게 취급하는 구조
- 엔딩마다 완전히 별도인 DAY 26~30 캠페인을 제작하는 구조
- 모든 스킬 행동을 JSON 문자열로 임의 실행하는 위험한 구조

---

## 3. 범위 분류

### 3.1 이번 확장의 데모 핵심

다음은 이번 확장의 필수 범위다.

1. 종족과 분리된 개별 몬스터 `instance_id`
2. 저장 v2와 v1→v2 무손실 마이그레이션
3. 전투·원정·선택 누적 지표를 기록하는 `RunMetricLedger`
4. 데이터 기반 엔딩 조건 평가기
5. 현재 엔딩을 포함한 수집형 승리 엔딩 5개
6. 푸딩·곱·핀의 2갈래 진화 1단계
7. 몬스터별 유대와 추억 이벤트
8. 3칸 스킬 장착과 데이터 기반 스킬 정의 확장
9. 엔딩 도감
10. DAY 30 뒤 새 회차 시작
11. 한 마리의 계승 몬스터와 한 개의 추억 능력 선택
12. 재회차 편의 기능: 본 튜토리얼 생략, 본 대사 건너뛰기, 해금된 전투 배속

### 3.2 데모 보조

- 로로의 원정 전용 유대와 2갈래 성장
- 엔딩 예상 방향 UI
- 개별 몬스터 전투 통계와 활약 문구
- 엔딩별 전용 일러스트/문장/문양
- 새 회차의 왕국 교리 3종
- 엔딩별 신규 몬스터 계약서 해금 표시
- 몬스터 추억 앨범

### 3.3 확장판 후보

이번 작업에서 데이터 자리만 준비하고 구현하지 않는다.

- 일반 몬스터 12종, 희귀 몬스터 4종 완성
- 진화 2~3단계
- 융합
- 장비와 세트 효과
- 몬스터 영지/생활 시뮬레이션
- 다층 마왕성
- 온라인 도감/공유
- 무한 회차 수치 상승
- 엔딩별 완전한 별도 챕터

---

## 4. 전체 게임 루프 수정안

### 4.1 1회차

기존 30일 루프를 유지한다.

```text
관리
→ 방어/원정 준비
→ 전투 또는 관리 전용 DAY
→ 결산
→ 몬스터 활약·유대·추억 확인
→ 다음 날
→ DAY 30 승리
→ 엔딩 평가
→ 엔딩 화면
→ 후일담 또는 새 회차
```

### 4.2 2회차 이후

```text
엔딩 화면
→ 새 회차 준비
→ 계승 몬스터 1마리 선택
→ 계승 추억 1개 선택
→ 왕국 교리 1개 선택
→ 일반 시작 또는 DAY 4 압축 시작
→ 기존 30일 캠페인 + 회차 변형 이벤트/웨이브
→ 다른 진화·관계·엔딩 목표
```

### 4.3 회차 길이 완화

30일 전체를 여러 번 플레이하는 부담을 줄이기 위해 첫 클리어 뒤 다음을 해금한다.

- 본 대사 즉시 건너뛰기
- 이미 본 대화 자동 넘김
- 전투 3배속 또는 4배속
- `DAY 4 압축 시작`
  - DAY 1~3의 검증된 기본 완료 상태를 데이터 스냅샷으로 적용
  - 이름·기본 배치·초기 특화 선택은 새 회차 준비 화면에서 처리
  - DAY 1~3 전용 엔딩 지표는 중립값으로 기록
- 이전 회차 관리 배치를 “참고 배치”로 불러오되, 자동 확정하지 않음

전투 자동 판정이나 하루 전체 건너뛰기는 이번 범위에서 제외한다. 반복 플레이가 전투를 하지 않는 메뉴 작업으로 변하는 것을 막기 위해서다.

---

## 5. 개별 몬스터 데이터 모델

### 5.1 핵심 원칙

현재 `monster_roster`는 종족 ID가 곧 한 마리의 정체성이다. 이를 다음처럼 분리한다.

- `species_id`: 전투 기본 데이터. 예: `slime`
- `instance_id`: 저장과 관계가 붙는 한 마리. 예: `mon_pudding`
- `character_id`: 초상과 대사. 예: `CHR_PUDDING`
- `nickname`: 화면 표시 이름. 예: `푸딩`

현재는 종족당 한 마리만 있어도 `instance_id`를 먼저 도입한다. 이후 같은 종족의 다른 개체가 들어와도 저장 구조를 다시 바꾸지 않기 위해서다.

### 5.2 개별 몬스터 런타임 레코드

```json
{
  "instance_id": "mon_pudding",
  "species_id": "slime",
  "character_id": "CHR_PUDDING",
  "nickname": "푸딩",
  "core_member": true,
  "level": 1,
  "exp": 0,
  "room_id": "entrance",
  "defense_enabled": true,
  "raid_support": false,
  "specialization_id": "",
  "evolution_id": "",
  "equipped_skill_ids": ["slime_shield", "hold_corridor", ""],
  "bond": 25,
  "bond_rank": "trusted",
  "unlocked_memory_ids": [],
  "active_legacy_memory_id": "",
  "battle_record": {
    "deployments": 0,
    "wins": 0,
    "downs": 0,
    "damage_dealt": 0,
    "damage_taken": 0,
    "damage_blocked": 0,
    "healing_done": 0,
    "kills": 0,
    "rescues": 0,
    "manual_control_seconds": 0.0
  }
}
```

### 5.3 고정 instance ID

| 캐릭터 | instance ID | species ID | character ID |
|---|---|---|---|
| 푸딩 | `mon_pudding` | `slime` | `CHR_PUDDING` |
| 곱 | `mon_gob` | `goblin` | `CHR_GOB` |
| 핀 | `mon_pynn` | `imp` | `CHR_PYNN` |
| 로로 | `mon_rolo` | `kobold_scout` | `CHR_ROLO` |

ID는 영문 소문자 snake_case로 고정한다. 표시 이름을 수정해도 ID는 바꾸지 않는다.

### 5.4 전투 유닛에 필요한 필드

`Unit.gd`가 최소한 다음 두 값을 구분해 보유해야 한다.

```gdscript
var species_id: String
var monster_instance_id: String
```

- 스탯/기본 스프라이트 조회: `species_id`
- 유대/추억/장착 스킬/전투 기록 반영: `monster_instance_id`

적 유닛은 `monster_instance_id`가 빈 문자열이어도 된다.

### 5.5 영구 사망 정책

- 전투 불능은 사망이 아니다.
- 일반 전투 불능으로 유대를 잃지 않는다.
- 전투 불능은 결산 대사, 추억 이벤트, 흉터 문양 같은 서사 재료로만 사용한다.
- 다음 날 자동 회복 규칙은 현재 게임을 유지한다.
- 영구 이탈/희생은 이번 범위에서 금지한다.

---

## 6. 성장 구조 재설계

### 6.1 성장 층의 역할을 분명히 분리한다

| 성장 층 | 시점 | 되돌리기 | 플레이 영향 | 회차 계승 |
|---|---|---|---|---|
| 레벨 | 전투/훈련 | 불가 | 기초 능력치 | 초기화 |
| 전술 특화 | DAY 2 이후 | 관리 단계에서 비용을 내고 변경 가능 | AI 행동과 배치 역할 | 해금 정보만 유지 |
| 스킬 장착 | DAY 2 이후 | 관리 단계에서 자유 변경 | 수동/자동 기술 조합 | 해금 정보만 유지 |
| 진화 1단계 | DAY 12/23 | 해당 회차에서는 불가 | 외형·핵심 스킬·역할 변화 | 형태는 초기화, 도감은 유지 |
| 유대 | 전체 캠페인 | 감소를 최소화 | 이벤트·대사·추억 해금 | 관계 기록 유지, 수치는 일부 초기화 |
| 계승 추억 | 새 회차 시작 | 회차 시작 때 1개 선택 | 작은 수평 효과 | 영구 해금 |

### 6.2 전술 특화와 진화의 관계

전술 특화와 진화를 같은 선택으로 합치지 않는다.

예:

- `slime_gate_keeper` 특화 + `slime_gate_bulwark` 진화: 입구 고정 극대화
- `slime_rescue_guard` 특화 + `slime_gate_bulwark` 진화: 튼튼한 구조대
- `slime_gate_keeper` 특화 + `slime_rescue_alchemist` 진화: 전열 제어형 지원
- `slime_rescue_guard` 특화 + `slime_rescue_alchemist` 진화: 아군 구조 극대화

이 구조는 몬스터 1종당 4개 조합을 만들면서도 UI에서는 “행동 방식”과 “몸의 진화”로 이해할 수 있다.

### 6.3 전술 특화 변경 규칙

현재 세션 동안 유지되는 선택을 다음처럼 정리한다.

- DAY 2 첫 선택은 무료이며 필수다.
- DAY 4 이후 관리 화면에서 하루 한 번 재훈련 가능하다.
- 재훈련 비용은 금화/마력의 소액이며 레벨이나 유대는 잃지 않는다.
- 전투 중에는 변경할 수 없다.
- 결과 화면에서 “이 특화가 어떤 행동을 했는지” 통계를 보여 준다.

이 규칙은 초반 선택을 시험해 볼 수 있게 하면서, 진화 선택만 회차 내 영구 결정으로 남긴다.

### 6.4 능력치 적용 순서

모든 수치 보정은 다음 순서를 단일 서비스에서 적용한다.

```text
종족 기본값
→ 레벨 성장
→ 전술 특화
→ 진화
→ 장착 패시브/계승 추억
→ 방/시설 상시 효과
→ 전체·방 지침
→ 전투 중 임시 버프/디버프
```

동일 단계 안에서는 `multiplier`를 먼저 곱하고 `flat bonus`를 더한다. 예외 규칙을 `GameRoot.gd`나 `CombatSceneController.gd`에 개별 `if promotion_id == ...`로 추가하지 않는다.

---

## 7. 핵심 몬스터 진화 설계

### 7.1 공통 규칙

- 진화 단계는 1단계만 구현한다.
- DAY 12에는 총 1마리, DAY 23부터 총 2마리까지 진화할 수 있는 현재 제한을 유지한다.
- 따라서 한 회차에서는 푸딩·곱·핀 중 한 마리가 진화하지 않을 수 있다. 이것이 다음 회차의 선택 동기가 된다.
- 진화는 능력치 전체 상승이 아니라 핵심 역할 강화다.
- 각 가지는 하나의 명확한 강점과 하나의 대가를 가진다.
- 일반 아이템 인벤토리를 새로 만들지 않는다.
- DAY 12/23의 `evolution_token`과 기존 자원 비용만 사용한다.
- 기존 승급 ID는 첫 번째 가지로 그대로 유지한다.

### 7.2 푸딩

#### A. 성문 방벽 푸딩 — 기존 확장

- ID: `slime_gate_bulwark`
- 역할: 고정 전열, 왕좌 돌진 차단
- 추천 특화: `slime_gate_keeper`
- 시각 키워드: 넓고 낮은 실루엣, 작은 성문 문양 방패, 돌 테두리, 보라색 점액 광택
- 강점: 최대 HP, 방어, 넉백 저항, 입구/왕좌 방 고정
- 대가: 이동 속도 감소, 부상 아군 구조 반응이 느림
- 기존 `slime_shield` 강화 유지
- 신규 패시브: `fortress_anchor`
  - 같은 방에서 2초 이상 정지 시 방어·저지력 상승
  - 방을 떠나면 즉시 해제

#### B. 구조 연금젤 푸딩 — 신규

- ID: `slime_rescue_alchemist`
- 표시 이름: `구조 연금젤 푸딩`
- 역할: 부상 아군 구조, 보호막 공유, 회복 시설 연계
- 추천 특화: `slime_rescue_guard`
- 시각 키워드: 반투명 몸 안의 작은 회복 룬, 부드러운 띠 장식, 탄력 있는 길쭉한 실루엣
- 강점: 이동, 아군 보호, 회복 둥지 연계
- 대가: 순수 최대 HP와 고정 저지력은 방벽 가지보다 낮음
- 신규 액티브: `gel_rescue`
  - HP 비율이 가장 낮은 아군에게 짧게 도약
  - 도착 시 푸딩과 대상에게 짧은 보호막
  - AI는 아군 HP 40% 이하일 때 사용
- 신규 패시브: `shared_shell`
  - 푸딩의 보호막이 깨질 때 인접 아군 피해를 일부 흡수

### 7.3 곱

#### A. 매복대장 곱 — 기존 확장

- ID: `goblin_ambush_captain`
- 기존 표시 이름을 `매복대장 곱`으로 정리
- 역할: 위험한 후열과 공병 추격, 빠른 마무리
- 추천 특화: `goblin_finisher`
- 시각 키워드: 낮은 후드, 짧은 곡도, 매복 표식, 가벼운 가죽 장비
- 강점: 돌진, 단일 대상 폭딜, 공병/조사관 우선
- 대가: 보물 방에 오래 머무르는 수비에는 약함
- 기존 `quick_slash` 강화 유지
- 신규 액티브: `shadow_pounce`
  - 지정 대상 뒤로 짧게 파고들며 일격
  - 보스에게는 이동 거리만 줄고 피해는 정상 적용

#### B. 금고지기 곱 — 신규

- ID: `goblin_vault_warden`
- 표시 이름: `금고지기 곱`
- 역할: 도둑 봉쇄, 보물실 경보, 제어
- 추천 특화: `goblin_treasure_hunter`
- 시각 키워드: 큰 열쇠 꾸러미, 작은 경보종, 짧은 강화 외투, 민첩한 체형 유지
- 강점: 도둑 탐지, 이동 차단, 보물 손실 감소
- 대가: 일반 적과 보스에 대한 순수 화력은 매복대장보다 낮음
- 신규 액티브: `alarm_snare`
  - 보물 방 또는 인접 방의 가장 빠른 적에게 덫
  - 도둑에게 지속시간 증가
- 신규 패시브: `treasure_oath`
  - 보물 방이 공격받거나 도둑이 도달하면 잠시 이동/공격 속도 상승

### 7.4 핀

#### A. 화염 숙련자 핀 — 기존 확장

- ID: `imp_flame_adept`
- 역할: 장거리 단일/광역 화력
- 추천 특화: `imp_artillery`
- 시각 키워드: 커진 불씨 뿔, 주황 화염 고리, 날개 끝의 불꽃, 작은 체형 유지
- 강점: 화염구 사거리, 피해, 밀집 적 처리
- 대가: 제어와 생존 지원이 약함
- 기존 `fireball` 강화 유지
- 신규 패시브: `overheat_focus`
  - 같은 대상을 연속 공격하면 피해가 소폭 상승
  - 대상 변경 시 초기화

#### B. 잿불 주술사 핀 — 신규

- ID: `imp_cinder_hexer`
- 표시 이름: `잿불 주술사 핀`
- 역할: 둔화, 약화, 함정·감시초소 연계
- 추천 특화: `imp_trap_weaver`
- 시각 키워드: 보라색 잿불 실, 작은 룬 고리, 자홍/보라 불꽃, 지나치게 사악하지 않은 표정
- 강점: 적 이동·공격 약화, 함정 구역 유지력
- 대가: 즉시 폭발 피해는 화염 숙련자보다 낮음
- 신규 액티브: `binding_cinder`
  - 작은 범위에 잿불 매듭을 생성해 둔화와 공격 간격 증가
- 신규 패시브: `hex_echo`
  - 함정 또는 감시초소에 영향받은 적에게 약화 지속시간 증가

### 7.5 로로 성장

로로는 현재 전투 애니메이션 계약이 부족하고 원정/정찰 지원 역할이 명확하다. 핵심 3종이 끝난 뒤 별도 작업한다.

| 가지 | ID | 역할 |
|---|---|---|
| 길잡이 대장 로로 | `kobold_pathfinder_captain` | 안전 정찰, 적 도착 지연, 위험 감소 |
| 소문상 로로 | `kobold_rumor_broker` | 높은 악명·보상, 추가 침입 위험 |

로로는 전투 배치 없이도 원정 횟수, 위험 선택, 보고서 선택으로 유대가 오른다. 전투형으로 전환하지 않는다.

---

## 8. 스킬 시스템 설계

### 8.1 현재 문제

현재 `skills.json`은 이름, 마나, 재사용 대기시간, 설명 중심이고 실제 행동은 전투 코드에 강하게 결합되어 있다. 분기 진화 스킬을 같은 방식으로 추가하면 몬스터·진화 ID별 조건문이 늘어난다.

### 8.2 목표 구조

- 단순 효과는 데이터로 정의한다.
- 복잡한 기존 기술은 등록된 `handler_id`로 실행한다.
- JSON에서 임의 GDScript나 표현식을 실행하지 않는다.
- 모든 `handler_id`는 코드 레지스트리에 명시적으로 등록한다.

### 8.3 스킬 데이터 예시

```json
{
  "gel_rescue": {
    "display_name": "점액 구조 도약",
    "kind": "active",
    "manual_usable": true,
    "cost_mana": 15,
    "cooldown": 9.0,
    "tags": ["rescue", "barrier", "mobility"],
    "targeting": {
      "side": "ally",
      "rule": "lowest_hp_ratio",
      "range": 360.0
    },
    "ai_use": {
      "ally_hp_ratio_lte": 0.4,
      "min_targets": 1
    },
    "effects": [
      {"type": "dash_to_target", "distance_cap": 180.0, "duration": 0.22},
      {"type": "barrier", "target": "self", "value": 42, "duration": 4.0},
      {"type": "barrier", "target": "selected", "value": 42, "duration": 4.0}
    ],
    "icon": "res://assets/sprites/ui/skills/skill_gel_rescue.png",
    "vfx_id": "fx_gel_rescue",
    "sfx_id": "sfx_gel_rescue"
  }
}
```

### 8.4 공통 효과 타입

MVP에서 지원할 효과 타입만 먼저 만든다.

- `damage`
- `heal`
- `barrier`
- `stat_buff`
- `stat_debuff`
- `dash_to_target`
- `taunt`
- `apply_status`
- `create_zone`
- `modify_reward`는 전투 스킬 실행기 밖의 결산 훅으로 처리

### 8.5 장착 슬롯

몬스터마다 3칸을 사용한다.

| 슬롯 | 규칙 |
|---|---|
| 1 | 주 액티브. 직접 조종 패널에 표시 |
| 2 | 전술 액티브 또는 자동 액티브 |
| 3 | 패시브 또는 계승 추억 |

- 액티브와 패시브를 UI에서 명확히 구분한다.
- 패시브는 직접 조종 버튼으로 노출하지 않는다.
- 진화 시 새 기술을 “자동 장착”하되, 확인 화면에서 기존 기술과 비교 후 확정한다.
- 장착 변경은 관리 화면에서만 가능하다.

### 8.6 기존 스킬 이관 순서

1. 기존 스킬 데이터를 확장하되 행동은 그대로 둔다.
2. 기존 기술에 `handler_id`를 붙인다.
3. 푸딩 신규 기술 하나만 공통 실행기로 구현한다.
4. 공통 실행기가 검증된 뒤 다른 신규 기술에 재사용한다.
5. 기존 모든 기술을 한 번에 재작성하지 않는다.

### 8.7 밸런스 기준

- 두 진화 가지의 전체 평균 전투력 차이는 목표 시나리오 전체에서 ±15% 이내다.
- 대신 각 가지가 유리한 목표 지표에서는 20% 이상 차이가 나야 한다.
- 예:
  - 방벽 푸딩: 최종 왕좌 피해와 자기 생존에서 우위
  - 구조 푸딩: 아군 전투 불능 수와 잔여 전력에서 우위
  - 매복 곱: 공병 처치 시간에서 우위
  - 금고 곱: 도둑 도달/도난에서 우위
  - 화염 핀: 적 전멸 시간에서 우위
  - 주술 핀: 시설 무력화 횟수와 적 행동 지연에서 우위

---

## 9. 유대와 추억 시스템

### 9.1 명칭

UI 명칭은 `호감도`가 아니라 **유대**를 사용한다. 몬스터가 연애 대상처럼 보이기보다 부하, 동료, 가족으로 성장하는 방향이다.

### 9.2 유대 범위와 등급

- 범위: 0~100
- 핵심 3종 시작값: 25
- 로로 합류 시작값: 20

| 수치 | 등급 | 의미 |
|---:|---|---|
| 0~24 | 낯선 부하 | 기능적 관계 |
| 25~49 | 믿을 만한 부하 | 기본 개인 대사 |
| 50~74 | 전우 | 두 번째 추억과 분기 대사 |
| 75~89 | 식구 | 가족 엔딩 기여, 계승 후보 |
| 90~100 | 전설의 부하 | 최종 추억과 특수 후일담 |

### 9.3 유대 획득

반복 배치만으로 무한 파밍되지 않도록 하루 획득 상한을 둔다.

#### 전투/원정 자동 획득 — 하루 최대 2

- 실제 배치/원정 참여: +1
- 해당 역할의 의미 있는 활약 달성: +1
  - 푸딩: 일정 피해 흡수 또는 아군 구조
  - 곱: 위험 적 마무리 또는 도둑 차단
  - 핀: 위험 적 피해/제어 또는 시설 연계
  - 로로: 원정 위험 감소 또는 추가 보상

#### 이벤트 획득

- 추억 이벤트 선택: +5~10
- DAY 25/29 관계 회수: +3~5
- 특정 진화 선택 후 전용 대화: +3

#### 획득하지 않는 경우

- 메뉴에서 반복 클릭
- 금화 선물 반복
- 전투를 시작만 하고 즉시 종료
- 쓰러진 적 수만으로 모든 몬스터에게 동일한 큰 보너스

### 9.4 유대 감소

MVP에서는 일반적인 유대 감소를 넣지 않는다.

- 전투 불능: 감소 없음
- 미배치: 감소 없음
- 진화하지 못함: 감소 없음
- 스토리에서 명시적인 배신/희생 선택만 별도 플래그로 처리

유대 손실보다 “누구와 시간을 보냈는가”를 선택하게 하는 편이 애착 형성에 적합하다.

### 9.5 추억 이벤트 구조

각 핵심 몬스터에 3개씩, 로로에 2개를 우선 제작한다.

| 몬스터 | 이벤트 1 | 이벤트 2 | 이벤트 3 |
|---|---|---|---|
| 푸딩 | 첫날 왕좌 앞에 선 이유 | 쓰러진 아군을 지킬지 입구를 지킬지 | DAY 29 혼자가 아니라는 약속 |
| 곱 | 보물에 관심이 많은 진짜 이유 | 놓친 도둑을 인정하는 방식 | 자기 몫보다 성의 보물을 택하는 약속 |
| 핀 | 불꽃을 제어하지 못했던 기억 | 강한 불과 정교한 불 사이의 선택 | 마지막 밤 성의 불을 맡는 약속 |
| 로로 | 소문을 과장하는 이유 | 지도를 집이라고 부르는 순간 | 추후 확장 |

### 9.6 추억 이벤트 조건

- 이벤트 1: 유대 35 이상, 지정 DAY 범위
- 이벤트 2: 유대 60 이상, 관련 전투 기록 또는 진화 이후
- 이벤트 3: 유대 85 이상, DAY 26~29
- 같은 이벤트는 회차당 한 번
- 본 적 있는 이벤트는 다음 회차에서 즉시 넘길 수 있음
- 선택 결과는 정답/오답이 아니라 서로 다른 성의 기풍을 올림

### 9.7 추억 이벤트 데이터 예시

```json
{
  "memory_pudding_02_rescue_or_gate": {
    "monster_instance_id": "mon_pudding",
    "day_min": 13,
    "day_max": 24,
    "bond_required": 60,
    "requirements": {
      "any": [
        {"metric": "monster.mon_pudding.rescues", "op": "gte", "value": 1},
        {"metric": "monster.mon_pudding.damage_blocked", "op": "gte", "value": 350}
      ]
    },
    "dialogue_id": "D_MEMORY_PUDDING_02",
    "choices": [
      {
        "id": "protect_the_line",
        "label": "네가 버티는 동안 모두가 싸울 수 있어.",
        "bond_delta": 7,
        "axis_delta": {"order": 6, "kinship": 2},
        "unlocks_memory_id": "memory_pudding_gate_promise"
      },
      {
        "id": "protect_each_other",
        "label": "성보다 먼저 서로를 놓치지 말자.",
        "bond_delta": 7,
        "axis_delta": {"kinship": 7},
        "unlocks_memory_id": "memory_pudding_rescue_promise"
      }
    ]
  }
}
```

### 9.8 계승 추억

유대 75 이상이고 관련 추억 이벤트를 본 몬스터는 새 회차의 계승 후보가 된다.

- 새 회차에 한 마리만 계승 몬스터로 선택
- 그 몬스터의 해금된 추억 중 하나만 활성화
- 효과는 5~8% 이내의 수평 보정 또는 행동 조건 변화
- 중첩되지 않음
- 이전 추억은 앨범에 남지만 동시에 장착할 수 없음

예:

| 추억 | 효과 예시 |
|---|---|
| 푸딩의 문 앞 약속 | 전투 시작 5초 동안 받는 피해 6% 감소 |
| 푸딩의 구조 약속 | 첫 아군 HP 40% 이하 시 이동 속도 8% 증가 |
| 곱의 금고 열쇠 | 첫 도둑 등장 시 3초간 이동 속도 8% 증가 |
| 핀의 마지막 불씨 | 첫 스킬 마나 비용 5 감소 |

레벨, 진화 형태, 전체 능력치, 자원은 계승하지 않는다.

---

## 10. 성의 기풍과 관계 지표

### 10.1 엔딩용 다섯 기풍

엔딩을 한 수치로 결정하지 않는다. 플레이 방식의 방향을 다섯 축으로 기록한다.

| ID | 표시 이름 | 의미 |
|---|---|---|
| `kinship` | 식구 | 몬스터 보호, 유대, 구조, 함께 성장 |
| `order` | 철벽 | 시설, 보안, 왕좌 보존, 안정적 지휘 |
| `dominion` | 위압 | 악명, 대담한 원정, 공격적 대응 |
| `honor` | 명예 | 레온과의 정정당당한 라이벌 관계, 약속 준수 |
| `cunning` | 계략 | 정찰, 기만, 보물 운용, 니아·로로와의 책략 |

- 범위: 0~100
- UI에서는 처음부터 정확한 숫자를 크게 보여 주지 않는다.
- 관리 화면의 `성의 기풍` 패널에서 5단계 문구로 표시한다.
- 엔딩 도감에서는 획득한 엔딩의 실제 결정 항목을 보여 준다.

### 10.2 관계 지표

다음 NPC 관계는 0~100으로 별도 기록한다.

- `relation_leon`
- `relation_nia`
- `relation_bati`
- `relation_rolo`

핵심 몬스터는 별도의 `bond`를 사용한다. NPC 관계와 몬스터 유대를 같은 수치로 합치지 않는다.

### 10.3 결정 기록

모든 중요한 선택은 수치만 더하지 않고 기록을 남긴다.

```json
{
  "day": 25,
  "source_id": "event_day25_leon_rematch_result",
  "choice_id": "acknowledge_rival",
  "axis_delta": {"honor": 12},
  "relation_delta": {"leon": 10},
  "tags": ["honorable_rival", "leon_respected"],
  "summary": "레온의 성장을 인정하고 정식 재도전을 받아들였다."
}
```

엔딩 화면은 이 기록 중 해당 엔딩에 가장 크게 기여한 3개를 보여 준다.

---

## 11. 다중 엔딩 설계

### 11.1 원칙

- 모든 수집형 엔딩은 DAY 30 승리를 요구한다.
- DAY 30 패배는 현재처럼 재도전 장면이며 엔딩 도감에 등록하지 않는다.
- 특별 엔딩 조건을 충족하지 못해도 현재 엔딩 `true_demon_castle`을 반드시 얻는다.
- 어떤 엔딩도 “나쁜 엔딩”으로 취급하지 않는다.
- `true_demon_castle` ID는 호환성을 위해 유지하되, UI에서 다른 엔딩보다 우월한 “진 엔딩”으로 표시하지 않는다.
- 한 회차에서 여러 조건을 만족하면 점수와 안정적인 타이브레이커로 하나를 선택한다.
- 엔딩의 핵심 조건은 DAY 29에 정성적 힌트를 제공한다.

### 11.2 MVP 엔딩 5개

#### E00. 진짜 마왕과 진짜 용사 — 현재 엔딩/균형 엔딩

- ID: `true_demon_castle`
- 역할: 항상 도달 가능한 기본 결말
- 핵심: 초보 마왕과 레온이 서로의 성장을 인정
- 조건: DAY 30 승리, 다른 특별 엔딩 미선정
- 현재 문패 문구 `여기서부터 진짜 마왕성.` 유지
- 보상: 엔딩 도감, 새 회차, 기본 박쥐 정찰 계약서 후보

#### E01. 마왕성은 우리 집입니다 — 식구 엔딩

- ID: `monster_family_castle`
- 핵심: 마왕성이 시설이 아니라 함께 자란 몬스터의 집으로 인정됨
- 주요 인물: 푸딩, 곱, 핀, 로로, 바티
- 연출: 결전 뒤 부상한 몬스터들이 왕좌 앞이 아니라 식탁/휴게실에 모임
- 보상 후보: 회복·지원형 신규 몬스터 계약서 또는 식구 계승 추억

#### E02. 철벽 대마왕성 등록 완료 — 요새 엔딩

- ID: `impregnable_demon_citadel`
- 핵심: 왕국이 침공 비용을 감당하지 못해 마왕성을 공식 불가침 요새로 기록
- 주요 인물: 바티, 골딘, 셀렌
- 연출: 11개 구역과 네 시설이 정상 작동하는 전경, 깨끗한 왕좌 방
- 보상 후보: 가고일 새끼 계약서 또는 시설 계승 설계도

#### E03. 왕국이 먼저 문을 잠갔다 — 위압 엔딩

- ID: `dread_overlord_rises`
- 핵심: 공격적 원정과 높은 악명으로 왕국이 주변 길을 스스로 봉쇄
- 주요 인물: 로로, 셀렌, 레온
- 연출: 마왕성 깃발이 지도 곳곳에 표시되지만 직접적 고어는 없음
- 보상 후보: 해골 고수/전열 몬스터 계약서 또는 위압 계승 추억

#### E04. 마왕과 용사의 정식 협정 — 라이벌 엔딩

- ID: `demon_hero_rival_pact`
- 핵심: 마왕과 레온이 서로를 쓰러뜨릴 대상이 아니라 지역의 질서를 지키는 정식 라이벌로 인정
- 주요 인물: 레온, 셀렌, 바티
- 연출: 악수보다 서로 무기를 세우고 예를 갖추는 장면이 톤에 맞음
- 보상 후보: 명예 도전 이벤트, 왕국 전령 몬스터/불빛 정령 계약서

### 11.3 2차 엔딩 2개

MVP 5개와 새 회차가 안정된 뒤 추가한다.

#### E05. 보물방은 오늘도 영업 중 — 계략/경제 엔딩

- ID: `shadow_market_demon_castle`
- 니아·골딘 관계, 원정 순이익, 보안과 위험 관리가 핵심
- 보상 후보: 미믹 계약서

#### E06. 마왕님은 결재만 하세요 — 바티 비밀 엔딩

- ID: `bati_runs_the_castle`
- 높은 바티 신뢰, 낮은 직접 조종 의존, 재시도 없는 안정 운영이 핵심
- 웃음 엔딩이지만 플레이어를 무능하게 조롱하지 않는다.
- “지휘를 위임하는 것도 마왕의 능력”으로 마무리한다.

### 11.4 엔딩 초기 조건표

아래 수치는 첫 구현값이다. 밸런스 시뮬레이션과 실제 플레이 로그로 조정하되, 조건의 종류는 임의로 늘리지 않는다.

| 엔딩 | 필수 조건 | 점수 중심 |
|---|---|---|
| 식구 | 승리, `kinship >= 60`, 핵심 3종 평균 유대 ≥72, 최저 유대 ≥50, 핵심 추억 5개 이상, 강제 희생 0 | 평균 유대 45%, 식구 기풍 25%, 생존/구조 30% |
| 철벽 | 승리, `order >= 60`, Stage 04, 최종 왕좌 HP ≥75%, 보안 A 횟수 ≥5, 누적 보물 손실 ≤150, 시설 무력화 ≤5 | 왕좌 30%, 보안 25%, 시설 기여 25%, 질서 20% |
| 위압 | 승리, `dominion >= 60`, 최종 악명 ≥1400, 위험 원정 성공 ≥2, 총공격 사용 비율 ≥35% | 악명 35%, 위압 30%, 위험 원정 20%, 공격 성과 15% |
| 라이벌 | 승리, `honor >= 60`, 레온 관계 ≥70, DAY 25 성장 인정, DAY 29 정식 결투 수락 | 레온 관계 40%, 명예 30%, 결투 기록 20%, 최종전 수행 10% |
| 균형 | 승리, 다른 특별 엔딩이 선택되지 않음 | 점수 계산 없음, 보장 fallback |
| 계략(2차) | 승리, `cunning >= 60`, 니아 관계 ≥70, 원정 순이익 ≥450, 최종 금화 ≥900 | 계략·관계·순이익 |
| 바티(2차) | 승리, 바티 관계 ≥85, 총 직접 조종 60초 이하, 캠페인 재시도 0 | 위임 운영·안정성 |

주의:

- 위압 엔딩은 몬스터 유대가 낮아야 하는 엔딩이 아니다. 부하를 아끼면서도 외부에는 무서운 마왕이 될 수 있다.
- 식구 엔딩은 세 몬스터를 모두 진화시키라고 요구하지 않는다. 현재 한 회차 진화 한도가 2마리이기 때문이다.
- 철벽 엔딩을 위해 모든 DAY를 무피해로 만들지 않는다.
- 라이벌 엔딩은 최종전 직전 선택 하나만으로 열리지 않는다.

### 11.5 조건 평가 순서

1. DAY 30 승리 뒤 `EndingMetricProvider`가 최종 지표 스냅샷을 만든다.
2. 각 특별 엔딩의 `requirements`를 평가한다.
3. 자격이 있는 엔딩의 `score_terms`를 0~100으로 계산한다.
4. 최고 점수 엔딩을 선택한다.
5. 동점이면 `priority`가 높은 엔딩을 선택한다.
6. 다시 동점이면 엔딩 ID 오름차순으로 고정한다.
7. 특별 엔딩이 없으면 `true_demon_castle`을 선택한다.
8. 선택 결과와 지표 스냅샷을 저장한 뒤 엔딩 화면을 연다.

엔딩 결과는 엔딩 화면을 다시 열 때 재계산하지 않는다. 최초 확정된 `resolved_ending_id`를 사용한다.

### 11.6 조건식 DSL

임의 코드 실행 없이 다음 노드만 지원한다.

- `all`
- `any`
- `not`
- 리프: `metric`, `op`, `value`

지원 연산자:

- `eq`, `ne`
- `gt`, `gte`, `lt`, `lte`
- `in`
- `contains`

예시:

```json
{
  "requirements": {
    "all": [
      {"metric": "campaign.victory", "op": "eq", "value": true},
      {"metric": "story.axis.kinship", "op": "gte", "value": 60},
      {"metric": "roster.core_average_bond", "op": "gte", "value": 72},
      {"metric": "roster.core_minimum_bond", "op": "gte", "value": 50},
      {"metric": "story.forced_sacrifice_count", "op": "eq", "value": 0}
    ]
  }
}
```

`metric`은 저장 Dictionary 경로를 직접 읽지 않는다. `EndingMetricRegistry`에 등록된 ID만 사용할 수 있다. 저장 구조가 바뀌어도 엔딩 JSON을 보호하기 위해서다.

### 11.7 엔딩 데이터 예시

```json
{
  "monster_family_castle": {
    "resolution_group": "day30_victory",
    "fallback": false,
    "priority": 50,
    "display_name": "마왕성은 우리 집입니다",
    "short_hint": "부하들을 누구도 뒤에 두지 않은 마왕의 결말",
    "requirements": {
      "all": [
        {"metric": "campaign.victory", "op": "eq", "value": true},
        {"metric": "story.axis.kinship", "op": "gte", "value": 60},
        {"metric": "roster.core_average_bond", "op": "gte", "value": 72},
        {"metric": "roster.core_minimum_bond", "op": "gte", "value": 50},
        {"metric": "memory.core_unlocked_count", "op": "gte", "value": 5}
      ]
    },
    "score_terms": [
      {"metric": "roster.core_average_bond", "weight": 0.45, "normalize_min": 50, "normalize_max": 100},
      {"metric": "story.axis.kinship", "weight": 0.25, "normalize_min": 40, "normalize_max": 100},
      {"metric": "combat.core_survival_ratio", "weight": 0.15, "normalize_min": 0.4, "normalize_max": 1.0},
      {"metric": "combat.total_rescues", "weight": 0.15, "normalize_min": 0, "normalize_max": 12}
    ],
    "presentation": {
      "title": "엔딩 · 마왕성은 우리 집입니다",
      "illustration": "res://assets/ui/endings/ending_monster_family_castle.png",
      "emblem": "res://assets/sprites/ui/endings/emblem_monster_family_castle.png",
      "dialogue_id": "ENDING_MONSTER_FAMILY_CASTLE"
    },
    "unlock_rewards": ["legacy_memory_family_table", "contract_mushroom_nurse"]
  }
}
```

---

## 12. 엔딩 지표 스냅샷

### 12.1 필요한 누적 지표

현재 `last_security_grade`처럼 마지막 값만 저장하는 항목은 엔딩에 부족하다. 다음을 회차 단위로 누적한다.

#### 캠페인

- `cycle_index`
- `difficulty_id`
- `victory`
- `retry_count`
- `play_time_seconds`

#### 전투

- 총 전투 수
- 전체/몬스터별 출전 수
- 몬스터별 피해, 흡수, 회복, 처치, 구조, 전투 불능
- 누적 왕좌 피해
- 최종 왕좌 HP 비율
- 누적 보물 손실
- 도둑 도달/도난/탈출 횟수
- 시설 무력화 횟수
- 보안 등급 이력과 A 횟수
- 시설별 기여량
- 지침별 사용 시간/비율
- 직접 조종 시간
- 수동 스킬 성공 횟수

#### 원정

- 성공 수
- 안전/위험 선택 수
- 순이익 금화/식량/악명
- 선택한 원정 ID 이력
- 로로 대장 횟수

#### 관계/성장

- 몬스터별 유대
- 핵심 3종 평균/최저 유대
- 해금 추억 수
- 진화한 몬스터 수와 가지
- NPC 관계
- 5개 기풍
- 결정 태그

### 12.2 저장 크기 제한

- 현재 회차는 상세 지표를 저장한다.
- 완료된 과거 회차는 요약만 `run_history`에 저장한다.
- 과거 전투 로그 전체는 보존하지 않는다.
- `run_history`는 기본 50개까지 보존하고 초과 시 가장 오래된 상세 요약부터 제거한다.
- 엔딩 도감과 몬스터 추억 해금 기록은 제거하지 않는다.

---

## 13. 다회차/영구 프로필 설계

### 13.1 논리적 두 층, 물리적 한 파일

영구 프로필과 현재 회차를 논리적으로 분리하되, 서로 다른 두 파일로 따로 저장하지 않는다. 독립 파일 두 개는 한쪽만 갱신될 때 불일치가 생길 수 있다.

새 저장 파일 예시:

```text
user://mawang_profile_v2.json
```

하나의 원자적 저장 봉투 안에 다음을 둔다.

```json
{
  "version": 2,
  "schema_id": "mawang_profile",
  "profile": {},
  "active_run": {},
  "summary": {}
}
```

### 13.2 영구 프로필

```json
{
  "profile_id": "profile_default",
  "created_at_unix": 0,
  "total_cycles_started": 1,
  "total_cycles_cleared": 0,
  "highest_cycle": 1,
  "unlocked_ending_ids": [],
  "ending_history": [],
  "unlocked_content_ids": [],
  "unlocked_memory_ids": [],
  "monster_legacy_records": {},
  "seen_dialogue_ids": [],
  "seen_event_ids": [],
  "run_history": []
}
```

### 13.3 현재 회차

기존 저장 페이로드를 `active_run` 아래로 옮기고 다음을 추가한다.

```json
{
  "run_id": "run_0001",
  "cycle_index": 1,
  "difficulty_id": "normal",
  "kingdom_doctrine_id": "",
  "start_mode": "full_tutorial",
  "game_state": {},
  "world": {},
  "roster": {},
  "raid": {},
  "campaign": {},
  "relationships": {},
  "metric_ledger": {},
  "decision_log": [],
  "result": {},
  "onboarding": {},
  "resolved_ending_id": "",
  "resolved_ending_snapshot": {}
}
```

### 13.4 새 회차 계승 범위

#### 유지

- 획득 엔딩
- 본 대화/이벤트
- 몬스터 추억 해금
- 몬스터별 누적 회차 기록
- 콘텐츠/계약서 해금
- 엔딩 도감
- 계승 추억 선택 가능 여부
- 편의 기능 해금

#### 초기화

- 레벨/EXP
- 진화 형태
- 전술 특화 장착
- 스킬 장착 상태
- 방/시설 배치
- 자원
- DAY
- 왕좌 HP
- 원정 결과
- 회차 관계 수치 대부분
- 엔딩 기풍

#### 부분 유지

- 계승 몬스터 1마리의 유대는 이전 수치 전부가 아니라 시작 보정으로 변환
  - 이전 75~89: 다음 회차 시작 35
  - 이전 90~100: 다음 회차 시작 40
- 다른 핵심 몬스터는 기본 시작 25
- 선택한 계승 추억 1개만 활성화

### 13.5 왕국 교리

2회차부터 왕국이 이전 전투를 학습했다는 설정으로 한 가지 교리를 선택한다.

| ID | 이름 | 행동 변화 |
|---|---|---|
| `doctrine_route_analysis` | 경로 분석 | 조사관이 늘고 일부 웨이브의 목표 경로가 달라짐 |
| `doctrine_engineer_siege` | 공병 공성 | 시설 교란 빈도가 늘고 공병 등장 시간이 달라짐 |
| `doctrine_treasure_blockade` | 보물 봉쇄 | 도둑/보급 압박과 원정 비용이 달라짐 |

- 단순 HP/공격력 대폭 증가가 아니다.
- 기본 수치 보정은 5% 이내로 제한한다.
- 플레이어가 교리를 보고 빌드를 선택하게 한다.
- 한 회차에 하나만 활성화한다.

### 13.6 엔딩 보상과 신규 몬스터

엔딩 보상은 즉시 큰 능력치를 주지 않는다.

- 우선: 추억, 다음 회차 시작 계약서, 새 이벤트, 새 교리
- 후순위: 신규 몬스터 모집

신규 몬스터는 시스템이 안정된 뒤 한 마리씩 추가한다.

| 연결 엔딩 | 신규 몬스터 후보 | 역할 |
|---|---|---|
| 식구 | 버섯 간호사 | 회복/상태 정화 |
| 철벽 | 가고일 새끼 | 고정 포탑/수호핵 연계 |
| 위압 | 해골 고수 | 전열 버프/사기 저하 |
| 라이벌 | 등불 도깨비 | 시야/표식/감시초소 연계 |
| 계략 | 미믹 | 보물 방 방어/기습 |

MVP 엔딩 구현과 동시에 이 몬스터들을 만들지 않는다. 엔딩 데이터에는 잠긴 보상 ID만 준비하고, 실제 계약서는 해당 몬스터 작업이 끝난 버전에서 활성화한다.

---

## 14. 캠페인에 삽입할 변경 지점

기존 DAY 1~30 스토리를 전면 재작성하지 않는다. 아래 지점만 확장한다.

| DAY | 기존 기능 | 추가할 내용 |
|---:|---|---|
| 2 | 첫 전술 특화 | 개별 몬스터 ID, 첫 유대 안내, 장착 스킬 3칸 소개 |
| 4 | 로로 원정 | 로로 유대 시작, 첫 기풍 기록 |
| 5~7 | 원정 영향/시설 | 첫 몬스터 추억 이벤트 후보, `order/cunning` 선택 기록 |
| 8 | 성장 예고 | 2갈래 진화 실루엣과 역할 차이 예고 |
| 12 | 첫 승급 | 한 종을 고른 뒤 해당 종의 두 진화 가지 중 하나 선택 |
| 13~17 | 카운터 적/원정 | 선택한 진화의 실제 강점과 약점을 시험 |
| 18 | 역할 특화 | 두 번째 추억 및 스킬 장착 확장 |
| 20 | 로만 | 시설/장기전 지표 기록 강화 |
| 23 | 두 번째 승급 | 두 번째 몬스터의 두 진화 가지 선택 |
| 25 | 레온 재도전 | 레온 관계와 `honor` 결정 선택 |
| 28 | 마지막 원정 | `order`, `dominion`, `cunning` 방향을 크게 바꾸는 기존 선택 기록 |
| 29 | 결전 전야 | 몬스터 최종 추억, 엔딩 방향 힌트, 마지막 서약 선택 |
| 30 | 최종전 | 지표 동결 → 엔딩 평가 → 전용 엔딩 화면 |

### 14.1 DAY 29 마지막 서약

DAY 29에 5개 버튼을 주어 엔딩을 직접 고르게 하면 안 된다. 대신 현재 가장 가까운 두 기풍을 바티가 설명하고, 플레이어가 하나의 서약으로 최대 +10을 보정한다.

예:

- `누구도 뒤에 두지 않는다.` → `kinship +10`
- `한 발짝도 왕좌에 들이지 않는다.` → `order +10`
- `왕국이 다시는 이 길을 보지 못하게 한다.` → `dominion +10`
- `레온과 약속한 결투를 끝낸다.` → `honor +10`
- `상대가 준비한 길부터 틀어 버린다.` → `cunning +10`

이 선택은 30일 플레이를 뒤집는 스위치가 아니라 경계선에 있는 방향을 보정하는 역할이다.

---

## 15. UI/UX 설계

### 15.1 몬스터 관리 화면

현재 코드 생성 UI를 전부 한 번에 씬으로 옮기지 않는다. 새로 복잡해지는 영역부터 씬으로 만든다.

권장 구조:

```text
scenes/ui/screens/MonsterDetailScreen.tscn
scenes/ui/screens/EvolutionChoiceScreen.tscn
scenes/ui/screens/EndingGalleryScreen.tscn
scenes/ui/screens/NewCycleSetupScreen.tscn
scenes/ui/components/MonsterRosterCard.tscn
scenes/ui/components/SkillSlotCard.tscn
scenes/ui/components/BondTrack.tscn
scenes/ui/components/EndingHintCard.tscn
scenes/ui/components/LegacyMemoryCard.tscn
scenes/ui/popups/MemoryEventPopup.tscn
scenes/ui/popups/EvolutionConfirmPopup.tscn
```

몬스터 상세 탭:

1. `정보`: 레벨, 역할, 특화, 진화, 추천 방, 전투 기록
2. `기술`: 3칸 장착, 액티브/패시브, AI 사용 조건
3. `진화`: 두 가지 비교, 강점/대가, 미리보기
4. `추억`: 유대 등급, 본 이벤트, 계승 가능 여부

### 15.2 진화 비교 화면

1920×1080 기준 좌우 두 카드 비교를 사용한다.

각 카드에 반드시 표시:

- 진화 이름과 큰 초상
- 역할 태그
- 추천 방/지침
- 바뀌는 AI 행동
- 새 액티브/패시브
- 강점 2개
- 대가 1개
- 현재 특화와의 시너지
- 실제 전투 미리보기 GIF는 구현하지 않음
- `이 회차에서는 되돌릴 수 없습니다` 경고

수치만 나열하지 말고 행동 문장을 우선한다.

### 15.3 전투 HUD

선택 유닛 패널에 추가:

- 고유 이름
- 진화 문양
- 특화 아이콘
- 2개 액티브 쿨다운
- 현재 AI 행동 한 줄
- 직접 조종 상태

유대 수치는 전투 중 크게 보여 주지 않는다. 전투 집중을 해치지 않도록 결산/관리에서만 상세 표시한다.

### 15.4 결산 화면

몬스터별 카드에서 다음을 보여 준다.

- 피해/흡수/회복/처치/구조 중 해당 역할에 중요한 2~3개
- 이번 전투 유대 변화와 이유
- 진화/특화가 만든 기여
- 다음 추억까지의 정성적 힌트

예:

```text
푸딩 · 성문 방벽
피해 흡수 312 · 돌진 차단 2회
유대 +2: 전열 유지, 전원 귀환
“이번에는 왕좌 앞을 혼자 지키지 않았다.”
```

### 15.5 성의 기풍 패널

관리 화면에서 5개 숫자를 상시 크게 노출하지 않는다.

- `약함 / 싹틈 / 뚜렷함 / 강함 / 지배적` 5단계
- 마우스 오버 시 최근 기여 선택 2개 표시
- 첫 클리어 전에는 엔딩이라는 단어를 직접 쓰지 않음
- 첫 클리어 뒤에는 `엔딩 방향` 도움말 해금

### 15.6 엔딩 도감

각 엔딩 카드 상태:

1. 완전 미발견: 문양 실루엣만
2. 힌트 발견: 제목 일부와 방향 문구
3. 획득: 전체 일러스트, 대사, 달성 이유, 회차 기록

도감에서 보여 줄 정보:

- 엔딩 제목
- 획득 회차/날짜
- 선택한 진화 2개
- 계승 몬스터
- 결정적 기록 3개
- 해금 보상
- 다음에 다른 엔딩을 노릴 수 있는 정성적 힌트

### 15.7 새 회차 준비 화면

필수 순서:

1. 새 회차 설명
2. 시작 방식 선택: 전체 / DAY 4 압축
3. 계승 몬스터 1마리
4. 계승 추억 1개
5. 왕국 교리 1개
6. 난이도 확인
7. 시작

한 화면에 모든 항목을 펼치지 말고 단계형으로 구성한다.

---

## 16. 기술 구조

### 16.1 새 서비스

```text
scripts/systems/progression/MonsterRosterService.gd
scripts/systems/progression/MonsterGrowthService.gd
scripts/systems/progression/BondService.gd
scripts/systems/progression/LegacyService.gd
scripts/systems/skills/SkillDefinitionService.gd
scripts/systems/skills/SkillExecutor.gd
scripts/systems/skills/SkillHandlerRegistry.gd
scripts/systems/endings/EndingMetricRegistry.gd
scripts/systems/endings/EndingMetricProvider.gd
scripts/systems/endings/ConditionEvaluator.gd
scripts/systems/endings/EndingResolver.gd
scripts/systems/campaign/RunMetricLedger.gd
scripts/systems/campaign/CycleService.gd
scripts/systems/save/AtomicJsonStore.gd
scripts/systems/save/ProfileSaveStore.gd
scripts/systems/save/SaveMigrationV1ToV2.gd
scripts/data/RegularContentValidator.gd
```

새 폴더 `scripts/systems/endings/`와 `scripts/systems/skills/`를 추가한다.

### 16.2 책임

#### `MonsterRosterService`

- instance ID 생성/조회
- 종족/캐릭터 연결
- 기존 종족 키 로스터 마이그레이션
- 장착·배치 상태 검증
- 전투 유닛에 instance ID 전달

#### `MonsterGrowthService`

- 레벨/특화/진화/스킬 슬롯 계산
- 능력치 적용 순서
- 진화 가능 여부와 비용
- 진화 그룹의 상호 배타성

#### `BondService`

- 하루 유대 획득 상한
- 전투 결과 기반 획득 사유
- 이벤트 조건
- 유대 등급
- 계승 가능 판정

#### `RunMetricLedger`

- 전투·원정·선택 누적
- 현재 회차 지표 저장/복원
- 엔딩용 평탄화 스냅샷 생성에 필요한 원본 제공

#### `ConditionEvaluator`

- 허용된 조건 DSL만 평가
- 타입 오류를 실패로 반환
- 알 수 없는 metric/op를 경고가 아니라 데이터 검증 실패로 처리

#### `EndingResolver`

- 자격 평가
- 점수 계산
- 안정적 타이브레이크
- fallback 보장
- 결과 설명용 기여 항목 반환

#### `CycleService`

- 새 회차 초기화
- 계승 선택 적용
- 압축 시작 스냅샷 적용
- 왕국 교리 적용
- 완료 회차 요약을 프로필에 기록

### 16.3 Autoload 정책

새 서비스는 처음부터 Autoload로 등록하지 않는다.

1. `RefCounted` 또는 일반 Node로 작성
2. 독립 테스트 씬에서 검증
3. `GameRoot`가 소유/주입
4. 여러 씬에서 실제로 공통 수명이 필요하다는 것이 확인된 서비스만 추후 Autoload 후보로 검토

기존 `GameState`, `SignalBus`, `DataRegistry`는 유지한다.

### 16.4 SignalBus 추가 후보

```gdscript
signal monster_bond_changed(instance_id: String, old_value: int, new_value: int, reason: String)
signal monster_evolved(instance_id: String, evolution_id: String)
signal monster_skill_loadout_changed(instance_id: String, equipped_skill_ids: Array)
signal memory_unlocked(instance_id: String, memory_id: String)
signal ending_resolved(ending_id: String, snapshot: Dictionary)
signal ending_unlocked(ending_id: String)
signal cycle_started(cycle_index: int, start_mode: String)
```

UI는 서비스 내부 Dictionary를 직접 변경하지 않고 신호와 공개 API를 사용한다.

### 16.5 DataRegistry 추가

```gdscript
var monster_instance_seeds: Dictionary = {}
var monster_bond_events: Dictionary = {}
var legacy_memories: Dictionary = {}
var endings: Dictionary = {}
var cycle_modifiers: Dictionary = {}
var meta_unlocks: Dictionary = {}
```

권장 파일:

```text
data/regular_version/monsters/monster_instances_seed.json
data/regular_version/events/monster_bond_events.json
data/regular_version/progression/legacy_memories.json
data/regular_version/progression/endings.json
data/regular_version/progression/cycle_modifiers.json
data/regular_version/progression/meta_unlocks.json
```

기존 `data/evolution_rules.json`, `data/specializations.json`, `data/skills.json`은 당장 복제하지 않고 확장한다. 같은 콘텐츠의 원본이 두 군데 생기면 안 된다.

### 16.6 GameRoot 축소 방향

한 번에 대규모 리팩터링하지 않는다.

- `GameRoot`는 화면 전환과 서비스 조정만 담당
- 성장 계산은 `MonsterGrowthService`
- 유대 계산은 `BondService`
- 엔딩 조건은 `EndingResolver`
- 누적 지표는 `RunMetricLedger`
- 저장 봉투는 `ProfileSaveStore`

기존 함수를 옮길 때는 원래 함수명에 얇은 어댑터를 남겨 기존 테스트를 먼저 통과시킨다.

---

## 17. 저장 v2 마이그레이션

### 17.1 마이그레이션 순서

1. v2 파일 검사
2. v2가 없으면 기존 `user://campaign_save_v1.json` 검사
3. v1이 유효하면 원본을 `.pre_v2.bak`으로 복사
4. 기본 `profile` 생성
5. 기존 페이로드를 `active_run`으로 변환
6. 종족 키 로스터를 instance ID 키로 변환
7. 기존 엔딩/완료 상태를 프로필에 반영
8. v2 전체 검증
9. 임시 파일 쓰기 → 재검증 → 안전 교체
10. v2를 실제로 다시 불러와 복원 테스트
11. 성공한 경우에도 첫 릴리스에서는 v1 원본 또는 백업을 삭제하지 않음

### 17.2 로스터 변환

```text
slime        → mon_pudding
goblin       → mon_gob
 imp          → mon_pynn
 kobold_scout → mon_rolo
```

각 기존 레코드의 다음 필드는 그대로 보존한다.

- level
- exp
- room
- defense_enabled
- raid_support
- growth_preparation 관련 값
- specialization_id
- promotion_id → evolution_id로 의미를 확장하되 값 유지
- role_tag

새 필드는 기본값을 채운다.

- bond: 25, 로로 20
- equipped_skill_ids: 기존 종족 `skill_slots` 복사
- memory: 빈 배열
- battle_record: 0

### 17.3 기존 엔딩 변환

- `campaign_completed == true`
- `campaign_final_battle_outcome == "victory"`

인 v1 저장은 다음을 적용한다.

```text
profile.unlocked_ending_ids += true_demon_castle
active_run.resolved_ending_id = true_demon_castle
profile.total_cycles_cleared = 최소 1
```

패배 재도전 상태는 엔딩 해금으로 처리하지 않는다.

### 17.4 새 게임 의미 변경

현재 제목 화면의 새 게임은 기존 진행을 완전히 지우는 의미가 강하다. v2 이후 분리한다.

- `새 회차`: 프로필 유지, active_run만 새로 생성
- `현재 회차 포기`: 확인창 뒤 active_run 초기화, 프로필 유지
- `프로필 초기화`: 설정/데이터 관리 안쪽의 별도 위험 작업

엔딩 화면의 `새 게임` 버튼 명칭은 `새 회차 시작`으로 바꾼다.

### 17.5 마이그레이션 완료 조건

- DAY 1, DAY 12, DAY 23, DAY 28 선택 대기, DAY 30 재도전, DAY 30 승리 후일담 v1 샘플 모두 v2로 복원
- 승급/특화/맵/시설/원정 선택 손실 없음
- 변환 전후 핵심 수치 일치
- 마이그레이션을 두 번 실행해도 결과가 중복되지 않음
- v2 쓰기 실패 시 v1로 계속 시작 가능
- 손상 v1은 기존처럼 격리하고 임의 보정하지 않음

---

## 18. 그래픽 리소스 계획

### 18.1 제작 원칙

- 큐트 호러 판타지 유지
- 어두운 동굴/성, 보라색 마력 조명, 귀여운 몬스터, 작은 해골 장식
- 진화해도 원래 캐릭터의 얼굴·실루엣·색상 정체성이 남아야 함
- 텍스트를 이미지에 굽지 않음
- 직접적 고어 금지
- 기존 게임 캐릭터/장비 실루엣 복제 금지
- 모든 생성 원본과 프롬프트를 `SOURCE.md`에 기록
- 한 포즈를 회전/이동만 해서 공격·스킬 프레임으로 대체하지 않음

### 18.2 진화 전투 프레임 계약

현재 프로젝트의 완전 애니메이션 계약을 따른다.

| 동작 | 프레임 수 | 크기 |
|---|---:|---:|
| `idle_down` | 2 | 192×192 RGBA |
| `move_down` | 4 | 192×192 RGBA |
| `attack_down` | 4 | 192×192 RGBA |
| `skill_down` | 4 | 192×192 RGBA |
| `down` | 2 | 192×192 RGBA |

진화 형태 1개당 총 16프레임이다.

푸딩 2가지 + 곱 2가지 + 핀 2가지 = 6형태, 총 96개 전투 PNG가 필요하다.

파일 예시:

```text
assets/sprites/monsters/evolved/slime_gate_bulwark/
  monster_slime_gate_bulwark_idle_down_00.png
  monster_slime_gate_bulwark_idle_down_01.png
  ...
  monster_slime_gate_bulwark_down_01.png
```

### 18.3 초상 리소스

진화 형태마다 최소:

- 기본 초상 1
- 자신감/기쁨 1
- 부상/걱정 또는 결의 1

6형태 × 3 = 18개 초상 PNG.

MVP에서 메모리 이벤트마다 별도 전신 일러스트를 만들지 않는다. 초상과 공용 배경을 조합한다.

파일 예시:

```text
assets/sprites/portraits/monsters/mon_pudding/slime_gate_bulwark/
  CHR_PUDDING_gate_bulwark_portrait_base.png
  CHR_PUDDING_gate_bulwark_portrait_proud.png
  CHR_PUDDING_gate_bulwark_portrait_soft.png
```

### 18.4 진화 배지

- 6개 진화 배지, 256×256 원본/128×128 런타임
- 기존 3개 배지는 개선 또는 유지
- 신규 3개 배지 제작
- 가지별 문양이 작은 UI에서도 구분되어야 함

### 18.5 스킬 아이콘

우선 18개를 계획한다.

- 기존 핵심 스킬 6개
- 진화 가지 신규 액티브/패시브 12개

권장 크기:

- 원본 256×256
- 런타임 96×96 또는 128×128
- 투명 배경
- 아이콘 안에 글자/숫자 없음

### 18.6 신규 VFX

최소 6세트:

| VFX | 목적 |
|---|---|
| `fx_fortress_anchor` | 방벽 푸딩 고정 룬 |
| `fx_gel_rescue` | 구조 도약/보호막 |
| `fx_shadow_pounce` | 곱의 매복 이동/베기 |
| `fx_alarm_snare` | 금고 경보 덫 |
| `fx_overheat_focus` | 핀 연속 화염 표식 |
| `fx_binding_cinder` | 잿불 매듭/둔화 |

각 4프레임을 기본으로 하며 필요할 때만 6~8프레임으로 늘린다.

### 18.7 유대/추억 UI 리소스

- 유대 문양 5단계 또는 한 개 문양의 5상태
- 잠긴 추억 카드 프레임
- 해금 추억 인장 12개
- 계승 몬스터 왕관/문양 1세트
- 기풍 아이콘 5개
- 최근 선택 표시 화살표/광택

하트 아이콘을 주 테마로 사용하지 않는다. 박쥐 날개, 작은 뿔, 마력 인장, 성 문양을 사용한다.

### 18.8 엔딩 리소스

MVP 5개 기준:

- 1920×1080 엔딩 일러스트 5개
- 엔딩 문양 5개
- 잠금 실루엣 5개 또는 공용 1개
- 도감 썸네일 5개
- 엔딩 화면 공용 프레임 1세트

권장 원본은 2560×1440 이상으로 제작하고 1920×1080 안전 영역을 확인한다.

#### 구도 지침

- 균형: 마왕, 레온, 바티와 성 문패
- 식구: 핵심 몬스터들이 함께 쉬는 성 내부
- 철벽: 네 시설과 11구역이 작동하는 대마왕성 전경
- 위압: 왕국 지도와 마왕성 깃발, 공포는 표정/거리감으로 표현
- 라이벌: 마왕과 레온이 서로 무기를 세워 예를 갖추는 장면
- 계략(2차): 니아·골딘·로로가 보물방 장부를 두고 협상
- 바티(2차): 바티가 결재판을 들고 마왕에게 휴가 명령서를 내미는 장면

### 18.9 공용 배경

추억 이벤트용으로 전용 캐릭터 일러스트를 양산하지 않고 다음 3개 배경을 재사용한다.

- 보라 조명이 비치는 몬스터 휴게실
- 회복 둥지의 조용한 밤
- DAY 29 왕좌 앞 결전 전야

### 18.10 리소스 제작 순서

1. 진화 ID와 이름 확정
2. 흑백 실루엣 시안
3. 캐릭터 디자인 시트
4. 초상 1장
5. 전투 기본/공격/스킬 키포즈
6. 16프레임 완전 계약
7. VFX
8. 배지/스킬 아이콘
9. Godot import
10. 프레임 수·투명 모서리·중복 해시 검사
11. 1920×1080/1366×768 실제 캡처
12. 승인 뒤 다음 진화 형태 제작

푸딩 두 형태를 먼저 완성하기 전 곱과 핀의 전체 애니메이션을 동시에 생성하지 않는다.

### 18.11 오디오 보조 리소스

그래픽 요청의 직접 범위는 아니지만 완성도에 필요한 최소 오디오다.

- 진화 확정 짧은 스팅어 1
- 유대/추억 해금 1
- 신규 액티브 스킬 SFX 6
- 엔딩 공용 BGM 1 + 엔딩별 짧은 변주 5개 후보
- 새 회차 시작 스팅어 1

엔딩별 풀 BGM 5곡을 첫 범위로 잡지 않는다.

---

## 19. 상세 작업 순서

각 Phase는 독립 PR 또는 독립 작업 세션이다. 이전 Phase의 완료 조건을 통과하지 못하면 다음 Phase를 시작하지 않는다.

### Phase 0. 기준선 동결과 문서 등록

#### 목적

현재 정상 동작을 새 시스템의 회귀 기준으로 고정한다.

#### 작업

1. 이 문서를 `docs/design/MONSTER_LEGACY_MULTI_ENDING_EXPANSION_PLAN_2026-07-12.md`로 복사
2. 기준 커밋, Godot 버전, 테스트 목록 기록
3. 기존 Full/Quick 검증 실행
4. DAY 2 특화, DAY 12 첫 승급, DAY 23 두 번째 승급, DAY 30 승패/후일담 캡처 보관
5. `docs/DECISION_LOG_MONSTER_LEGACY_ENDINGS.md` 생성

#### 변경 허용

- 문서
- 테스트 실행 결과
- 코드/데이터 동작 변경 금지

#### 완료 조건

- 현재 전체 검증 PASS
- 기준 캡처/결과 경로 기록
- 작업 트리 깨끗함

#### 다음 단계 금지 조건

- 기존 검증 실패 원인을 모른 채 Phase 1 시작 금지

---

### Phase 1. 데이터 계약과 콘텐츠 검증기

#### 목적

런타임 연결 없이 새 ID와 JSON 구조를 먼저 확정한다.

#### 추가 파일

```text
data/regular_version/monsters/monster_instances_seed.json
data/regular_version/events/monster_bond_events.json
data/regular_version/progression/legacy_memories.json
data/regular_version/progression/endings.json
data/regular_version/progression/cycle_modifiers.json
data/regular_version/progression/meta_unlocks.json
scripts/data/RegularContentValidator.gd
tools/tests/RegularContentValidationTest.gd
tools/tests/RegularContentValidationTest.tscn
```

#### 수정 파일

- `scripts/core/DataRegistry.gd`
- `tools/tests/core_verification_suite.json`

#### 세부 순서

1. 푸딩/곱/핀/로로 instance seed만 작성
2. 엔딩은 fallback `true_demon_castle`과 테스트용 비활성 샘플만 작성
3. 조건 DSL 스키마 검증
4. 진화 그룹 검증 필드 추가
5. 스킬 참조 무결성 검사
6. 리소스 경로는 placeholder 허용 여부를 명시적으로 필드에 기록
7. 테스트를 core suite에 등록

#### 검증 항목

- ID 중복 없음
- 정확히 하나의 fallback
- 알 수 없는 metric/op 거부
- 모든 character/species/skill 참조 존재
- 진화 가지 그룹마다 같은 species
- 표시 이름 빈 문자열 금지
- JSON 파싱 오류 위치 출력

#### 완료 조건

- 런타임 게임 화면 변화 없음
- 새 검증 테스트 PASS
- 기존 전체 검증 PASS

#### 하지 않을 것

- 엔딩 UI
- 유대 계산
- 저장 v2
- 그래픽 생성

---

### Phase 2. 저장 v2와 개별 몬스터 마이그레이션

#### 목적

향후 모든 시스템이 사용할 안정적인 프로필/회차/instance 구조를 만든다.

#### 추가 파일

```text
scripts/systems/save/AtomicJsonStore.gd
scripts/systems/save/ProfileSaveStore.gd
scripts/systems/save/SaveMigrationV1ToV2.gd
scripts/systems/progression/MonsterRosterService.gd
tools/tests/ProfileSaveMigrationTest.gd
tools/tests/ProfileSaveMigrationTest.tscn
```

#### 수정 파일

- `GameRoot.gd`: 저장 어댑터만
- `CampaignSaveStore.gd`: v1 읽기 호환 유지, 대규모 재작성 금지
- 제목/이어하기 UI 최소 문구

#### 세부 순서

1. v2 envelope validator 구현
2. v1 샘플 fixture 작성
3. roster 키 변환 함수 구현
4. v1→v2 pure function 테스트
5. 파일 쓰기 없는 메모리 마이그레이션 테스트
6. AtomicJsonStore 적용
7. 실제 v1 파일 발견 시 마이그레이션 연결
8. v2 이어하기 연결
9. v1 백업 정책 검증

#### 완료 조건

- 기존 v1 DAY 1/12/23/28/30 상태 복원
- v2 새 게임/이어하기 동작
- 마이그레이션 2회 실행 시 중복 없음
- 실패 시 v1 보존
- 기존 전체 검증 PASS

#### 하지 않을 것

- 유대 수치 표시
- 엔딩 추가
- 진화 가지 추가
- 새 회차 UI

---

### Phase 3. RunMetricLedger

#### 목적

엔딩과 유대가 읽을 수 있는 누적 기록을 만든다.

#### 추가 파일

```text
scripts/systems/campaign/RunMetricLedger.gd
tools/tests/RunMetricLedgerTest.gd
tools/tests/RunMetricLedgerTest.tscn
```

#### 연결 지점

- 전투 시작/종료
- 몬스터 피해/흡수/회복/처치/구조
- 도둑/시설/왕좌 결과
- 지침 사용 시간
- 직접 조종 시간
- 원정 완료
- 선택 이벤트

#### 세부 순서

1. 지표 이름/타입 표 작성
2. 전투 1회 기록 API
3. 누적 API
4. export/import
5. 기존 결산 값과 ledger 값 비교 테스트
6. v2 저장 연결
7. 디버그 JSON 덤프 도구

#### 완료 조건

- 같은 전투를 두 번 결산해도 중복 누적되지 않음
- 저장/복원 전후 누적 일치
- 기존 결과 화면 수치와 핵심 지표 일치
- 성능 저하 없음

#### 하지 않을 것

- 엔딩 판정
- 유대 증가
- UI 확장

---

### Phase 4. 엔딩 조건 평가기 수직 구현

#### 목적

현재 엔딩 하나를 일반화된 평가기로 통과시킨다.

#### 추가 파일

```text
scripts/systems/endings/EndingMetricRegistry.gd
scripts/systems/endings/EndingMetricProvider.gd
scripts/systems/endings/ConditionEvaluator.gd
scripts/systems/endings/EndingResolver.gd
tools/tests/EndingResolverSmokeTest.gd
tools/tests/EndingResolverSmokeTest.tscn
tools/tests/EndingReachabilityMatrix.gd
tools/tests/EndingReachabilityMatrix.tscn
```

#### 세부 순서

1. metric registry 구현
2. 조건 노드 타입 검증
3. fallback 하나만 있는 데이터로 resolver 구현
4. 합성 스냅샷 테스트
5. 중첩 `all/any/not` 테스트
6. 점수 정규화와 동점 테스트
7. DAY 30 승리 시 resolver 호출
8. 결과는 여전히 현재 `true_demon_castle`만 표시

#### 완료 조건

- 현재 DAY 30 엔딩 내용/후일담 변화 없음
- 엔딩 ID가 데이터 평가기로 결정됨
- 알 수 없는 metric이 런타임에서 조용히 false가 되지 않고 검증 실패
- fallback 누락 시 테스트 실패

#### 하지 않을 것

- 특별 엔딩 콘텐츠
- 엔딩 도감
- 새 회차

---

### Phase 5. 엔딩 화면/도감 껍데기

#### 목적

콘텐츠를 늘리기 전에 표시·저장·재열람 흐름을 완성한다.

#### 추가 씬

```text
scenes/ui/screens/EndingGalleryScreen.tscn
scenes/ui/components/EndingHintCard.tscn
```

#### 작업

- 현재 엔딩 카드 1개
- 잠긴 카드 4개 placeholder
- 프로필 `unlocked_ending_ids`
- 엔딩 획득 시 프로필 기록
- 제목 화면 또는 후일담에서 도감 진입
- 엔딩 화면에 결정적 기록 3개 영역 준비

#### 완료 조건

- 기존 엔딩 획득/저장/재실행 후 도감 유지
- 잠긴 엔딩의 실제 조건 수치 노출 없음
- 1920×1080/1366×768 비겹침

---

### Phase 6. 푸딩 유대 수직 구현

#### 목적

한 마리의 유대가 전투→결산→이벤트→저장까지 완전히 흐르는지 검증한다.

#### 범위

- 푸딩만
- 유대 0~100
- 하루 자동 획득 최대 2
- 추억 이벤트 1개
- 추억 인장 1개
- 계승은 아직 연결하지 않음

#### 추가 파일

```text
scripts/systems/progression/BondService.gd
scenes/ui/components/BondTrack.tscn
scenes/ui/popups/MemoryEventPopup.tscn
tools/tests/PuddingBondVerticalSliceTest.gd
tools/tests/PuddingBondVerticalSliceTest.tscn
```

#### 완료 조건

- 참여하지 않은 전투에서 유대 획득 없음
- 전투 결산 중복 획득 없음
- 쓰러져도 유대 감소 없음
- 저장/복원 유지
- 이벤트 1회만 발생
- 결산 이유 문구 표시

#### 하지 않을 것

- 곱/핀 복제
- 계승
- 진화 아트

---

### Phase 7. 푸딩 스킬 실행기 수직 구현

#### 목적

신규 스킬 하나를 공통 데이터 실행기로 구현한다.

#### 범위

- 기존 푸딩 스킬은 handler adapter
- 신규 `gel_rescue`만 generic effects 사용
- AI/직접 조종 모두 검증

#### 완료 조건

- 대상 없음 시 자원/쿨다운 미소모
- AI 조건에 맞을 때만 사용
- 직접 조종 사용 가능
- 보호막/이동/애니메이션/VFX 실제 적용
- 기존 `slime_shield` 동작 회귀 없음

---

### Phase 8. 푸딩 2갈래 진화 완성

#### 목적

기획 전체의 첫 완전한 수직 슬라이스를 만든다.

#### 순서

1. 데이터 두 가지
2. 선택 UI placeholder
3. 전투 행동
4. 자동 A/B 테스트
5. 디자인 시트
6. 초상
7. 16프레임 ×2
8. VFX/배지/아이콘
9. UI 캡처
10. DAY 12 실제 연결

#### 필수 A/B 시나리오

- 왕좌 돌진 중심 웨이브
- 아군이 분산 피해를 받는 웨이브
- 시설 없는 기준 웨이브

#### 완료 조건

- 두 가지 모두 승리 가능
- 방벽 가지가 왕좌/자기 생존 우위
- 구조 가지가 아군 생존/구조 우위
- 전체 평균 파워 ±15%
- 그래픽 계약/중복 프레임 검사 PASS
- DAY 12 저장/복원 PASS

#### 이 단계 통과 전 금지

- 곱/핀 진화 제작
- 특별 엔딩 조건 추가
- 신규 몬스터 제작

---

### Phase 9. 곱 확장

푸딩 구조를 재사용한다. 새로운 프레임워크를 만들지 않는다.

#### 세션 9A

- 데이터/스킬/테스트 placeholder

#### 세션 9B

- 매복대장 곱 전투/그래픽

#### 세션 9C

- 금고지기 곱 전투/그래픽

#### 완료 조건

- 공병 처치 시간 vs 도난 방지 지표가 명확히 분리
- `곱` 이름 통일
- 기존 도둑 AI/보물 손실 회귀 없음

---

### Phase 10. 핀 확장

#### 세션 10A

- 데이터/스킬/테스트 placeholder

#### 세션 10B

- 화염 숙련자 핀 전투/그래픽

#### 세션 10C

- 잿불 주술사 핀 전투/그래픽

#### 완료 조건

- 전멸 시간 vs 제어/시설 보호 지표 분리
- 화염구 기존 타격감 유지
- 저주 VFX가 큐트 호러 톤을 벗어나지 않음

---

### Phase 11. 곱·핀 유대/추억 복제

#### 목적

검증된 푸딩 구조를 데이터 중심으로 확장한다.

- 곱 이벤트 3개
- 핀 이벤트 3개
- 공용 UI 재사용
- 몬스터별 역할 지표로 유대 이유 계산

#### 완료 조건

- 서비스 코드에 몬스터 이름별 분기 최소화
- 이벤트 JSON 추가만으로 대부분 동작
- 추억 조건 도달성 테스트 PASS

---

### Phase 12. 특별 엔딩 4개

#### 순서

1. 식구 엔딩 데이터/합성 도달성
2. 철벽 엔딩 데이터/합성 도달성
3. 위압 엔딩 데이터/합성 도달성
4. 라이벌 엔딩 데이터/합성 도달성
5. 실제 DAY 이벤트에 기풍/관계 기록 연결
6. DAY 29 방향 힌트
7. 엔딩 대사
8. placeholder 일러스트로 전체 흐름
9. 실제 엔딩 일러스트 4개
10. 도감/저장/재실행 검증

#### 완료 조건

- 5개 엔딩 모두 합성 스냅샷으로 도달
- 자동 플레이 프로필 5종이 의도한 서로 다른 엔딩 도달
- 한 엔딩이 모든 프로필을 독점하지 않음
- 조건 겹침 타이브레이크 고정
- 기본 엔딩 항상 도달 가능

---

### Phase 13. 새 회차

#### 추가 파일

```text
scripts/systems/progression/LegacyService.gd
scripts/systems/campaign/CycleService.gd
scenes/ui/screens/NewCycleSetupScreen.tscn
tools/tests/NewCycleFlowSmokeTest.gd
tools/tests/NewCycleFlowSmokeTest.tscn
```

#### 세부 순서

1. 완료 회차 요약 기록
2. 새 회차 active_run 생성
3. 계승 후보 판정
4. 추억 1개 적용
5. 전체 시작
6. DAY 4 압축 시작
7. 왕국 교리 1종
8. 본 대사 건너뛰기
9. 나머지 교리 2종
10. 2회차 DAY 30까지 스모크

#### 완료 조건

- 프로필/엔딩 도감 유지
- 자원/레벨/진화/방 배치 초기화
- 선택한 추억만 적용
- DAY 31 없음
- 2회차 저장/이어하기
- 1회차 저장과 구분되는 run ID

---

### Phase 14. 로로 유대와 성장

- 원정 전용 관계
- 안전 정찰/소문상 2갈래
- 원정 결과/엔딩 계략 지표 연계
- 전투 유닛 구현 금지

---

### Phase 15. 2차 엔딩과 신규 몬스터 1종

순서:

1. 계략 엔딩
2. 바티 비밀 엔딩
3. 엔딩 보상 계약서 시스템
4. 신규 몬스터 한 마리 선정
5. 한 마리만 완전 구현
6. 플레이 테스트 후 다음 몬스터 결정

5종을 한꺼번에 만들지 않는다.

---

### Phase 16. 최종 통합 검수

- 저장 v1→v2
- 1회차 5엔딩
- 2회차 전체/압축 시작
- 6가지 핵심 진화
- 계승 추억
- 3개 왕국 교리
- 1920×1080/1366×768
- 성능/메모리/웹 내보내기
- `assets/source/imagegen` 배포 제외 확인

---

## 20. 자동 검사 계획

### 20.1 데이터 검사

- 모든 ID 유일
- 모든 참조 존재
- 엔딩 fallback 정확히 1개
- 조건 metric/op 타입 유효
- score weight 합계 1.0 ± 허용 오차
- 진화 그룹 2개 가지
- 같은 가지 중복 선택 금지
- skill handler 등록
- 리소스 파일 존재
- 추억 이벤트 임계값/날짜가 모순되지 않음

### 20.2 엔딩 도달성 검사

각 엔딩마다 최소 한 개의 합성 지표 스냅샷을 둔다.

```text
ENDING_REACHABILITY_FAMILY
ENDING_REACHABILITY_CITADEL
ENDING_REACHABILITY_DREAD
ENDING_REACHABILITY_RIVAL
ENDING_REACHABILITY_DEFAULT
```

추가 검사:

- 모든 특별 엔딩 자격 실패 시 fallback
- 두 엔딩 동점
- priority 동점
- 알 수 없는 metric
- 잘못된 타입
- 점수 정규화 min=max
- 저장된 resolved ID 재열람 시 재계산하지 않음

### 20.3 진화 A/B 검사

각 가지마다 최소 3개 시나리오:

- 유리한 시나리오
- 불리한 시나리오
- 중립 시나리오

기록:

- 전투 시간
- 왕좌 피해
- 생존 전력
- 전투 불능
- 보물 손실
- 시설 무력화
- 가지 고유 지표

### 20.4 유대 검사

- 하루 상한
- 중복 결산
- 미참여
- 전투 불능
- 직접 조종 유무
- 저장/복원
- 이벤트 1회성
- threshold 건너뛰기
- 압축 시작 기본값

### 20.5 저장 검사

- v1 정상 샘플 6종
- v1 손상
- v1 지원하지 않는 범위
- v2 임시 쓰기 실패
- 백업 복구
- migration idempotence
- profile 유지/active run 초기화
- 엔딩 도감 유지
- run history 제한

### 20.6 실제 회차 자동 프로필

| 프로필 | 핵심 행동 | 목표 엔딩 |
|---|---|---|
| 식구형 | 생존/구조, 유대 이벤트, 안정 지침 | 식구 |
| 요새형 | 시설/보안, 왕좌 HP 보존 | 철벽 |
| 위압형 | 위험 원정, 악명, 총공격 | 위압 |
| 라이벌형 | 레온 존중, 결투 약속 | 라이벌 |
| 혼합형 | 특별 축을 과도하게 올리지 않음 | 균형 |

자동 프로필은 사람의 재미를 증명하지 않는다. 기능 도달성과 조건 분리를 검사하는 용도라고 결과 문서에 명시한다.

---

## 21. 수동 플레이 테스트

### 21.1 첫 수직 슬라이스

외부 플레이어 3~5명에게 DAY 8~13 구간을 플레이시킨다.

확인 질문:

1. 푸딩 두 진화의 차이를 설명할 수 있는가?
2. 어느 쪽을 선택했고 이유가 무엇인가?
3. 선택 뒤 전투에서 차이를 느꼈는가?
4. 푸딩을 캐릭터 이름으로 기억하는가?
5. 다른 가지를 다음 회차에 시험하고 싶은가?

### 21.2 엔딩/다회차 테스트

첫 클리어 뒤 확인:

- 획득 엔딩의 이유를 납득하는가?
- 다음에 노릴 엔딩 방향을 한 문장으로 설명할 수 있는가?
- 새 회차 계승 선택을 이해하는가?
- 레벨이 초기화돼도 추억이 남는 것을 손해로만 느끼지 않는가?
- 본 대사 건너뛰기와 압축 시작으로 재플레이 부담이 줄었는가?

### 21.3 정성 목표

- 플레이어가 핵심 몬스터 최소 2마리를 이름으로 부름
- 진화 가지를 “공격력 높은 쪽”이 아니라 행동 차이로 설명
- 엔딩을 우연한 마지막 선택이 아니라 전체 플레이 결과로 인식
- 다음 회차에 바꿀 몬스터/시설/엔딩을 하나 이상 언급

---

## 22. 밸런스 원칙

1. 메인 스토리 적은 플레이어 레벨에 직접 무한 스케일하지 않는다.
2. 회차 난이도는 교리와 역할 조합으로 바꾼다.
3. 진화는 모든 수치 30~50% 상승이 아니라 한 역할의 15~25% 강화가 기준이다.
4. 계승 추억은 최대 5~8% 또는 조건형 행동 보정이다.
5. 특별 엔딩은 완벽 플레이를 요구하지 않는다.
6. 관계 엔딩을 위해 직접 조종을 강제하지 않는다.
7. 자동 전투 중심 플레이와 직접 조종 중심 플레이 모두 엔딩에 도달할 수 있어야 한다.
8. 위압 플레이가 몬스터 학대를 요구하지 않는다.
9. 진화하지 못한 한 마리도 서사와 유대에서 소외되지 않는다.
10. 새 몬스터는 기존 몬스터의 완전 상위호환이 아니라 다른 문제를 푼다.

---

## 23. Codex 삽질 방지 규칙

### 23.1 작업 시작 전

매 세션 시작 시 다음을 출력한다.

```text
이번 세션의 Phase:
수정할 파일:
수정하지 않을 파일:
완료 조건:
기존 회귀 검사:
새 검사:
```

### 23.2 한 세션 한 기능 묶음

허용 예:

- `ConditionEvaluator + 단위 테스트`
- `푸딩 gel_rescue + 데이터 + 테스트 + placeholder VFX`
- `푸딩 방벽 형태 16프레임 + import 검사`

금지 예:

- 저장 v2를 만들면서 엔딩 UI와 신규 몬스터까지 추가
- 푸딩 진화를 만들다가 곱 스킬을 같이 리팩터링
- 그래픽 생성 중 전투 AI를 임의 조정
- 테스트가 실패하자 웨이브 전체 HP를 낮춤

### 23.3 파일 책임 지키기

- 콘텐츠 수치/조건: JSON
- 범용 계산: 서비스
- 전투 실제 실행: 전투/스킬 서비스
- 화면: UI 씬/컨트롤러
- 저장: save 시스템
- ID/참조 검증: data validator
- `GameRoot.gd`: 조정과 연결

### 23.4 멈춤 조건

다음 중 하나면 즉시 현재 Phase에서 멈추고 원인을 기록한다.

- 기존 Full/Quick 검사 실패
- v1 저장 복원 실패
- 새 데이터의 참조 무결성 실패
- placeholder 구현과 실제 아트 구현의 히트박스/타이밍 차이
- 1920×1080 또는 1366×768 UI 겹침
- 두 진화 가지 중 하나가 모든 핵심 지표에서 우위
- 엔딩 하나가 합성 프로필 5개 중 3개 이상을 의도치 않게 독점

### 23.5 그래픽 생성 금지 조건

- ID 미확정
- 스킬 동작 미확정
- 프레임 수 미확정
- placeholder로 전투 밸런스 미검증
- SOURCE 기록 위치 미확정

### 23.6 리팩터링 금지 조건

현재 Phase 완료에 필요하지 않은 파일 이동, 전체 UI 씬화, 전역 네이밍 변경은 하지 않는다.

---

## 24. 산출물 규격

각 Phase 종료 시 다음 형식으로 핸드오프 문서를 남긴다.

```text
# Phase 이름

## 목적
## 구현 대상
## 변경 파일
## 데이터 구조
## UI에 표시한 정보
## 테스트와 결과
## 수동 확인
## 남은 위험
## 다음 Phase 진입 조건
## 의도적으로 하지 않은 일
## 결정 로그 추가
```

각 중요 변경은 `docs/DECISION_LOG_MONSTER_LEGACY_ENDINGS.md`에 날짜, 결정, 이유, 대안, 영향 범위로 기록한다.

---

## 25. 완료 조건

### 25.1 시스템 완료

- v1 저장을 v2로 무손실 마이그레이션
- 프로필과 active run 논리 분리
- 몬스터 instance ID 적용
- 푸딩/곱/핀 각각 2가지 진화
- 스킬 3칸 장착
- 유대/추억 이벤트
- 5개 승리 엔딩
- 엔딩 도감
- DAY 30 뒤 새 회차
- 계승 몬스터/추억
- 왕국 교리
- 전체/압축 시작

### 25.2 콘텐츠 완료

- 핵심 몬스터 추억 이벤트 9개
- 로로 이벤트 최소 2개는 보조 완료 조건
- 6개 진화 형태의 전투/초상/배지
- 신규 스킬 아이콘/VFX
- MVP 엔딩 일러스트 5개
- 엔딩 대사와 결정 이유

### 25.3 검증 완료

- 기존 코어 검증 전체 PASS
- 신규 데이터/저장/엔딩/유대/진화/회차 테스트 PASS
- 5개 엔딩 도달성 PASS
- 2회차 DAY 30 완주 스모크 PASS
- 1920×1080/1366×768 UI PASS
- 웹 내보내기 PASS
- source 이미지 배포 제외 확인

### 25.4 재미 검증 완료

- 플레이어가 진화 가지 차이를 행동으로 설명
- 획득 엔딩 이유를 이해
- 다음 회차 목표를 스스로 정함
- 몬스터 이름과 추억을 기억
- 다른 진화 또는 다른 엔딩을 보고 싶다는 동기가 확인됨

---

## 26. 확장 로드맵

### 26.1 이 문서 완료 직후

1. 계략 엔딩
2. 바티 비밀 엔딩
3. 로로 성장
4. 엔딩 보상 계약서
5. 신규 몬스터 1종

### 26.2 1.0 목표로 확대

- 기존 4종 + 신규 일반 몬스터를 단계적으로 8~12종까지 확대
- 희귀 몬스터 2~4종
- 엔딩별 후일담 변형
- 몬스터 도감
- 아이템/재료 정식 시스템
- 진화 촉매 정식화

### 26.3 그 이후

- 진화 2단계
- 융합 연구소
- 다층 성
- 대규모 침공

이 순서는 현재 핵심 시스템과 실제 플레이 데이터가 검증된 뒤 다시 결정한다.

---

## 27. 결정 로그 초안

| ID | 결정 | 이유 |
|---|---|---|
| D-001 | DAY 30을 최종일로 유지 | 기존 캠페인·저장·최종장 계약 보존 |
| D-002 | 다회차는 DAY 30 뒤 새 run | DAY 31~40 확장보다 구조 충돌이 적음 |
| D-003 | 영구 프로필과 현재 회차를 한 v2 파일에 저장 | 두 파일 원자성 불일치 방지 |
| D-004 | 종족 ID와 instance ID 분리 | 개별 애착·추억·향후 동종 개체 지원 |
| D-005 | 전술 특화와 진화를 별도 층으로 유지 | 행동 선택과 시각적 영구 선택을 모두 살림 |
| D-006 | 기존 승급 ID를 첫 번째 진화 가지로 유지 | 저장 호환성과 기존 데이터 보호 |
| D-007 | 진화 1단계만 구현 | 아트·밸런스 범위 통제 |
| D-008 | 한 회차 진화 한도 2마리 유지 | 다음 회차 선택 동기 보존 |
| D-009 | 유대는 일반 전투 실패로 감소하지 않음 | 애착 시스템이 처벌/파밍으로 변하는 것 방지 |
| D-010 | 영구 사망 없음 | 장기 애착 방향과 충돌 방지 |
| D-011 | 수집형 엔딩은 모두 승리 엔딩 | 패배 파밍과 좌절 방지 |
| D-012 | 현재 엔딩을 fallback으로 유지 | 어떤 정상 승리도 무엔딩 상태가 되지 않음 |
| D-013 | 엔딩 조건은 registry metric DSL | 저장 구조 직접 의존과 임의 코드 실행 방지 |
| D-014 | 계승은 한 몬스터·한 추억 | 무한 수치 누적 방지, 선택 가치 확보 |
| D-015 | 회차 난이도는 왕국 교리 중심 | 단순 HP 스펀지 방지 |
| D-016 | 신규 몬스터는 시스템 안정 후 한 종씩 | Codex의 범위 폭주 방지 |
| D-017 | `곱`을 고유 이름 표준으로 사용 | 캐릭터 데이터/대사와 승급 이름 불일치 해소 |
| D-018 | 복잡해지는 신규 UI만 씬으로 제작 | 현재 코드 UI 전체 리팩터링 위험 회피 |
| D-019 | 그래픽은 placeholder 밸런스 뒤 제작 | 동작 변경으로 인한 재제작 방지 |
| D-020 | 특별 엔딩 사이에 우열 없음 | 다양한 플레이 스타일을 보상하기 위함 |

---

## 28. Codex에 전달할 첫 작업 요청문

아래 문장을 이 문서와 함께 Codex에 전달한다.

```text
첨부한 기획서 전체를 기준으로 작업하되, 지금은 Phase 0만 수행하라.
현재 main 기준 동작을 변경하지 말고, 문서를 docs/design에 등록하고 기존 전체 검증과 기준 캡처를 실행해 결과를 핸드오프 문서와 결정 로그에 남겨라.
Phase 1 이상의 코드·데이터·그래픽 구현은 시작하지 마라.
완료 전 수정 파일, 수행한 검사, 실패/경고, 다음 Phase 진입 가능 여부를 명확히 보고하라.
```

Phase 0이 승인된 뒤 다음 요청은 Phase 1만 지정한다.

---

## 29. 구현 대상

- 개별 몬스터 로스터
- 분기 진화 1단계
- 스킬 장착/정의 확장
- 유대/추억
- 성의 기풍/관계
- 데이터 기반 다중 엔딩
- 엔딩 도감
- 저장 v2
- 새 회차/계승/왕국 교리
- 관련 UI·그래픽·테스트

## 30. 데이터 구조

핵심 신규 구조:

- `profile`
- `active_run`
- instance 기반 `roster`
- `metric_ledger`
- `decision_log`
- `relationships`
- `endings`
- `bond_events`
- `legacy_memories`
- `cycle_modifiers`

## 31. UI에 표시할 정보

- 몬스터 고유 이름/진화/특화/스킬/유대/추억
- 결산 활약과 유대 변화 이유
- 성의 기풍 정성 단계
- DAY 29 엔딩 방향 힌트
- 엔딩 획득 이유와 도감
- 새 회차 계승 선택

## 32. Codex에 넘길 JSON 예시

이 문서 5장, 8장, 9장, 11장, 13장의 JSON 예시를 기준으로 한다. 실제 구현 전 `RegularContentValidator`의 스키마 계약을 먼저 확정한다.

## 33. 최종 완료 조건

25장의 시스템·콘텐츠·검증·재미 완료 조건을 모두 만족해야 이 확장을 완료로 판정한다.

## 34. 확장판 후보

3.3장과 26장에 명시한 범위만 후보로 둔다. 이번 작업 중 즉흥적으로 구현하지 않는다.

## 35. 결정 로그

27장의 D-001~D-020을 초기 결정으로 등록한다. 변경 시 기존 결정을 삭제하지 말고 `대체 결정`과 이유를 추가한다.
