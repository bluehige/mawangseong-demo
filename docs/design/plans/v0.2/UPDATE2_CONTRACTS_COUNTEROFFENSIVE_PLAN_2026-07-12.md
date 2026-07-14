# 「마왕님, 마왕성은 누가 지켜요?」
# 2차 대형 업데이트 개발 기획서
## 부제: 계약과 역습 — 신규 몬스터·왕국 대응군·추가 엔딩·다회차 변형

- 작성일: 2026-07-12
- 대상 프로젝트: `bluehige/mawangseong-demo`
- 엔진/언어: Godot 4.5 / GDScript
- 기준 해상도: PC 16:9, 1920×1080
- 선행 문서: `MONSTER_LEGACY_MULTI_ENDING_EXPANSION_PLAN_2026-07-12.md`
- 전제: 선행 문서의 1차 개발 범위가 완료되고 저장 v2, 개별 몬스터, 유대·추억, 분기 진화, 엔딩 E00~E06, 새 회차가 안정화된 뒤 착수한다.
- 문서 용도: 이 파일 전체를 Codex에 전달하되, **한 번에 전부 구현하지 않고 22장의 Phase 순서대로 한 기능 묶음씩 구현**한다.

---

## 0. Codex 실행 계약

이 문서는 아이디어 후보 목록이 아니라 2차 업데이트의 구현 계약이다. 아래 규칙은 다른 모든 세부 항목보다 우선한다.

1. **DAY 30은 계속 캠페인의 최종일이다. DAY 31~40을 추가하지 않는다.** 2차 업데이트는 같은 30일 안의 회차 변형을 늘린다.
2. 1차 개발의 저장 v2, 엔딩 도감, 새 회차, 핵심 3종 분기 진화, 유대·추억을 다시 만들지 않는다. 재사용하거나 확장한다.
3. 1차 개발에서 추가된 신규 몬스터가 무엇인지 Phase 0에서 먼저 확인한다. 같은 종을 새 ID로 중복 제작하지 않는다.
4. 2차 업데이트 완료 시 목표 전투 몬스터는 **기존 핵심 3종 + 계약 몬스터 5종**이다. 1차 개발에서 별도 종이 이미 추가됐다면 계약 몬스터 총수 상한은 6종으로 제한한다.
5. 신규 일반 적은 정확히 6종, 신규 네임드 보스는 정확히 1명만 구현한다. 적 수를 더 늘려 문제를 해결하지 않는다.
6. 신규 수집형 엔딩은 일반 회차 엔딩 3개와 메타 엔딩 2개만 추가한다. 기존 엔딩 ID와 조건을 삭제하지 않는다.
7. 신규 몬스터는 역할과 약점이 확정되고 자동 A/B 검사가 통과하기 전까지 최종 그래픽을 제작하지 않는다.
8. 신규 적은 대응할 몬스터가 실제 플레이 가능해진 뒤에만 구현한다. 카운터 적부터 만들어 기존 빌드를 일방적으로 약화하지 않는다.
9. 한 Phase에서 몬스터, 적, 엔딩, 저장, UI를 동시에 건드리지 않는다. Phase의 완료 조건이 통과해야 다음 Phase로 이동한다.
10. `GameRoot.gd`와 `CombatSceneController.gd`에 종별 조건문을 계속 추가하지 않는다. 1차 개발의 서비스·레지스트리 구조를 확장한다.
11. 같은 효과의 배율은 합산 한도를 둔다. 회복, 보호막, 표식, 공격 속도, 군중 제어를 무한 중첩시키지 않는다.
12. 1차 개발의 v2 저장을 직접 덮어쓰지 않는다. 2차 업데이트 저장은 v3 마이그레이션으로 처리한다.
13. 새 회차의 난이도는 적 HP·공격력 대폭 증가가 아니라 적 조합, 교리, 이벤트, 레온 대응형으로 만든다.
14. 신규 엔딩은 마지막 선택 한 번만으로 열리지 않는다. 30일 동안의 지표가 자격을 만들고 DAY 29 선호 선택은 동점 보정만 한다.
15. 기존 1920×1080과 1366×768 UI 회귀 검사를 모두 유지한다.
16. 이 업데이트에서 진화 2단계, 융합, 장비 세트, 다층 성, 새 성 단계, 완전 자유건설은 구현하지 않는다.

### 최초 실행 단위

Codex가 이 문서를 받은 직후에는 **Phase 0만 수행**한다. Phase 0에서 1차 개발의 실제 완료 상태와 추가된 몬스터 ID를 기록하기 전에는 신규 데이터 파일도 만들지 않는다.

---

## 1. 선행 조건과 시작점

### 1.1 1차 개발 완료를 인정하는 조건

아래가 모두 충족되어야 2차 업데이트를 시작한다.

- 저장 v2로 1회차와 새 회차를 구분해 저장·복원할 수 있다.
- v1→v2 마이그레이션이 무손실로 통과한다.
- 푸딩·곱·핀에 개별 `instance_id`, 유대, 추억, 스킬 장착이 있다.
- 푸딩·곱·핀은 각각 2갈래 진화 중 하나를 선택할 수 있다.
- 엔딩 E00~E06이 데이터 기반 조건 평가기로 결정된다.
- 엔딩 도감과 새 회차 준비 화면이 있다.
- 왕국 교리 3종과 계승 추억 1칸이 실제 새 회차에 적용된다.
- 로로의 원정 전용 성장과 유대가 저장된다.
- 1차 개발에서 선택한 신규 몬스터 1종이 있다면, 전투·저장·그래픽·테스트가 완결돼 있다.
- 기존 전체 핵심 검증이 모두 PASS다.

하나라도 없으면 해당 항목은 2차 업데이트로 끌고 오지 말고 1차 개발의 미완료 항목으로 먼저 닫는다.

### 1.2 1차 개발 신규 몬스터 불확정 대응

선행 문서는 마지막에 신규 몬스터 1종만 완전 구현하도록 했고 종을 고정하지 않았다. 따라서 Phase 0에서 다음 표를 반드시 작성한다.

| 점검 항목 | 기록 값 |
|---|---|
| 1차 신규 종 ID | 실제 ID 또는 `none` |
| 캐릭터 ID | 실제 ID |
| 전투 가능 여부 | true/false |
| 유대 이벤트 수 | 숫자 |
| 전술 특화 수 | 숫자 |
| 엔딩 보상 연결 | 엔딩 ID |
| 최종 그래픽 계약 | PASS/FAIL |

결정 규칙:

- 1차 신규 종이 이 문서의 계약 몬스터 5종 중 하나라면 해당 종은 `Wave 0 완료`로 간주하고 재제작하지 않는다.
- 1차 신규 종이 다른 종이라면 삭제하지 않는다. 다만 이 문서의 5종 중 우선순위가 가장 낮은 종 하나를 2.1 후보로 미뤄 총 계약 종 수를 6 이하로 유지한다.
- 기존 ID를 이 문서의 ID로 강제 변경하지 않는다. 필요하면 `content_aliases.json`으로 의미만 연결한다.

### 1.3 2차 업데이트가 해결할 문제

1차 개발이 끝나면 핵심 3종의 애착과 여러 엔딩은 생기지만, 회차마다 실제 전투 편성이 크게 달라지는 폭은 아직 좁다. 2차 업데이트는 다음 공백을 해결한다.

- 새 회차에 데려갈 신규 몬스터 선택이 부족함
- 핵심 3종 중심 조합이 모든 회차의 기본 해답이 될 위험
- 기존 적 역할에 정화, 후열 압박, 이동 봉쇄, 사기 보호, 미믹 판별이 없음
- 같은 DAY의 적 구성이 회차마다 충분히 바뀌지 않음
- 엔딩 조건은 늘었지만 여러 종을 골고루 키우는 목표가 부족함
- 왕국 교리 3종만으로 장기 반복 시 패턴이 빨리 소진될 수 있음
- 최종 레온전이 플레이어 빌드를 충분히 읽고 반응하지 않음

---

## 2. 업데이트 정체성과 목표

### 2.1 업데이트 명칭

**2차 대형 업데이트: 계약과 역습**

- `계약`: 엔딩에서 만난 결과가 다음 회차의 신규 몬스터 계약으로 돌아온다.
- `역습`: 왕국도 이전 회차의 전술을 학습해 새로운 대응군과 교리를 들고 온다.
- 핵심 문장: **“다른 부하를 고르면 다른 왕국군이 오고, 다른 성을 만들면 다른 결말이 열린다.”**

### 2.2 플레이어 감정 목표

1. 이번 회차에는 누구와 살 것인지 시작 전에 고민한다.
2. 새 몬스터가 기존 몬스터를 대체하는 상위호환이 아니라 새 해법을 제공한다.
3. 왕국의 카운터 적이 억지 패널티가 아니라 읽고 대응할 수 있는 문제로 보인다.
4. 같은 DAY 30까지 가더라도 중간 사건과 적 조합이 지난 회차와 다르다.
5. 특정 엔딩을 보기 위해 한 종만 몰아 키우는 것이 아니라 여러 종의 역할을 섞어 보고 싶어진다.
6. 새 엔딩 보상은 수치 폭증이 아니라 다음 회차의 새로운 선택지를 연다.

### 2.3 제품 설계 축

| 축 | 2차 업데이트의 구현 의미 |
|---|---|
| 계약 편성 | 핵심 3종에 계약 몬스터 2종을 더해 회차별 5종 로스터 구성 |
| 역할 교환 | 출전 한도 때문에 모든 몬스터를 동시에 쓰지 못하고 전투별 편성을 바꿈 |
| 상호 카운터 | 신규 몬스터마다 이를 압박하는 적과 그 적을 다시 잡는 기존 몬스터가 존재 |
| 회차 변형 | 교리, 칙령, 도전 인장, 이벤트 덱, 웨이브 변형이 같은 DAY를 바꿈 |
| 적응형 최종전 | 레온이 플레이어의 우세 전략을 읽되 약점도 함께 노출 |
| 메타 목표 | 계약 수집, 종별 추억, 교리 격파, 도전 인장이 메타 엔딩으로 연결 |
| 비수치 보상 | 계약권, 교리 선택권, 교대권, 추억 슬롯, 외형과 이벤트 해금 중심 |

---

## 3. 고정 범위

### 3.1 2차 업데이트 핵심 범위

1. 계약 게시판
2. 회차 시작 계약 몬스터 2종 선택
3. 전투 출전 한도와 예비 로스터
4. 계약 몬스터 목표 카탈로그 5종
5. 신규 일반 적 6종
6. 신규 네임드 보스 `왕국 전술감 에블린`
7. 왕국 교리 3종 추가, 총 6종
8. 마왕 칙령 6종
9. 선택형 도전 인장 6종
10. 회차 전용 이벤트 15개
11. 핵심 DAY 웨이브 변형 12개
12. 레온 적응형 최종전 4형
13. 일반 회차 엔딩 3개 추가
14. 메타 엔딩 2개 추가
15. 엔딩/계약/교리/도전 이력 저장 v3
16. 신규 몬스터·적·엔딩 그래픽과 오디오

### 3.2 보조 범위

- 종별 숙련 목표와 장식 보상
- 적 정보 도감과 카운터 설명
- 회차 결과 비교 화면
- DAY 29 엔딩 선호 선택
- 교리별 대사 변형
- 최종 편성 프리셋 저장 1개

### 3.3 명시적 제외

- DAY 31 이후 신규 날짜
- 새 성 단계 Stage 05
- 신규 방 전체 세트
- 신규 자원 통화
- 가챠형 계약
- 몬스터 영구 사망
- 몬스터 중복 개체 파밍
- 진화 2단계
- 융합
- 장비/아이템 인벤토리 전면 구현
- PvP·온라인·랭킹
- 무한 적 수 증가
- 종족별 전용 캠페인 30일 재작성

---

## 4. 2차 업데이트 전체 루프

### 4.1 새 회차 시작

```text
엔딩/후일담
→ 새 회차 준비
→ 계승 몬스터·추억 선택
→ 왕국 교리 후보 3개 중 1개 확인
→ 마왕 칙령 1개 선택
→ 도전 인장 0~1개 선택
→ 계약 게시판에서 계약 몬스터 2종 선택
→ 전체 시작 또는 DAY 4 압축 시작
→ 30일 캠페인
→ 회차 변형 이벤트/웨이브
→ DAY 29 레온 대응형 및 엔딩 방향 확인
→ DAY 30 최종전
→ 기존 또는 신규 엔딩
→ 계약·교리·인장·추억 해금
```

### 4.2 계약 몬스터 합류 시점

- 전체 시작: DAY 1~3은 기존 핵심 3종만 사용한다.
- DAY 4 관리 시작에 첫 번째 계약 몬스터가 합류한다.
- DAY 16 관리 시작에 두 번째 계약 몬스터가 합류한다.
- DAY 4 압축 시작: 첫 계약 몬스터는 즉시 합류하고, 두 번째는 DAY 16에 합류한다.
- 계약 몬스터를 DAY 1부터 주면 온보딩과 기존 밸런스가 무너지므로 금지한다.

### 4.3 출전 한도

| 성 단계 | 전투 출전 한도 | 회차 로스터 최대 |
|---|---:|---:|
| Stage 01 | 3 | 핵심 3 + 합류 계약 최대 1 |
| Stage 02 | 4 | 핵심 3 + 계약 1 |
| Stage 03 | 5 | 핵심 3 + 계약 2 |
| Stage 04 | 5 | 핵심 3 + 계약 2 |

- 로스터에 있어도 출전 체크가 꺼진 몬스터는 맵에 생성하지 않는다.
- 예비 몬스터는 기본 EXP의 40%만 받으며 활약 EXP와 유대는 받지 않는다.
- 전투 시작 전 최소 1마리, 최대 출전 한도만큼 선택한다.
- 기본 추천 편성은 자동 제공하되 자동 확정하지 않는다.
- 모든 종을 동시에 투입하는 방식으로 난도를 무력화하지 않는다.

### 4.4 중간 교대

- 일반 전투 중 즉시 교대는 없다.
- 관리 화면에서 다음 전투 출전 명단을 바꾼다.
- `다섯 목소리, 하나의 성` 엔딩 보상으로 해금되는 `연합 교대권`은 DAY 15 결산 뒤 계약 몬스터 1종을 다른 해금 종으로 한 번 교체하게 한다.
- 교대된 종은 해당 회차의 레벨을 이어받지 않고 `회차 평균 레벨 -1`로 합류한다.

---

## 5. 계약 게시판과 해금 구조

### 5.1 기본 규칙

- 계약 게시판은 첫 DAY 30 승리 뒤 해금한다.
- 계약은 가챠가 아니다. 해금된 종 중 플레이어가 직접 선택한다.
- 회차당 2종만 서명한다.
- 같은 종을 두 번 선택할 수 없다.
- 계약 해금은 프로필 영구 기록이다.
- 계약 종의 레벨, 진화, 특화는 회차마다 초기화한다.
- 유대의 영구 계승은 1차 개발 규칙을 따른다.

### 5.2 기존 엔딩과 계약 보상

| 기존 엔딩 | 계약/메타 보상 |
|---|---|
| E00 `true_demon_castle` | 계약 게시판 해금 + 아래 일반 계약 후보 3개 중 1개 선택권 |
| E01 `monster_family_castle` | `mushroom_nurse` 즉시 해금 |
| E02 `impregnable_demon_citadel` | `gargoyle_hatchling` 즉시 해금 |
| E03 `dread_overlord_rises` | `skeleton_drummer` 즉시 해금 |
| E04 `demon_hero_rival_pact` | `lantern_wisp` 즉시 해금 |
| E05 `shadow_market_demon_castle` | `treasure_mimic` 즉시 해금 |
| E06 `bati_runs_the_castle` | 계약 후보 새로고침 +1, 예비 EXP +10% 해금 |

E00 선택 후보:

- `mushroom_nurse`
- `gargoyle_hatchling`
- `lantern_wisp`

E00으로 첫 클리어한 플레이어도 다음 회차에 반드시 새 몬스터 하나를 경험할 수 있다.

### 5.3 계약 종 목표 카탈로그

| ID | 이름 | 핵심 역할 | 주 연결 엔딩 |
|---|---|---|---|
| `mushroom_nurse` | 버섯 간호사 모리 | 회복·정화·지속 지원 | 식구 |
| `gargoyle_hatchling` | 가고일 새끼 돌콩 | 고정 감시·시설 수호 | 철벽 |
| `skeleton_drummer` | 해골 고수 두둠 | 아군 박자 버프·적 동요 | 위압 |
| `lantern_wisp` | 등불 도깨비 루미 | 표식·시야·후열 지원 | 라이벌 |
| `treasure_mimic` | 보물 미믹 미미 | 보물 유인·기습·금고 수비 | 계략 |

---

## 6. 신규 몬스터 상세 설계

### 6.1 공통 설계 규칙

- 각 계약 몬스터는 기본 형태 1개만 구현한다. 진화 2단계는 하지 않는다.
- 대신 전술 특화 2개, 액티브 2개, 패시브 1개, 유대 이벤트 3개를 제공한다.
- 기본 전투 프레임 계약은 `idle 2 / move 4 / attack 4 / skill 4 / down 2` 총 16프레임이다.
- 신규 종은 핵심 3종의 진화 형태보다 평균 전투력이 높아서는 안 된다.
- 한 종은 하나의 문제를 강하게 해결하고, 다른 문제에는 분명한 약점을 가진다.
- 스킬은 1차 개발의 `SkillExecutor`와 등록된 effect/handler만 사용한다.
- 신규 종 전용 조건문을 `CombatSceneController.gd`에 직접 작성하지 않는다.

### 6.2 기준 능력치 비교

현재 기본형 비교 기준:

| 종 | HP | ATK | DEF | 이동 | 사거리 | 공격 간격 | 기본 역할 |
|---|---:|---:|---:|---:|---:|---:|---|
| 슬라임 | 180 | 8 | 8 | 90 | 50 | 1.40 | 탱커 |
| 고블린 | 140 | 16 | 4 | 130 | 46 | 0.90 | 근접 딜러 |
| 임프 | 120 | 18 | 3 | 115 | 180 | 1.20 | 원거리 딜러 |

계약 몬스터는 이 셋의 빈 역할을 채운다.

---

### 6.3 버섯 간호사 모리

#### 기본 정보

- species ID: `mushroom_nurse`
- character ID: `CHR_MORI`
- instance seed: `monster_mori`
- 표시 이름: `모리`
- 역할: 회복·상태 정화·회복 둥지 연계
- 추천 방: 회복 둥지
- 해금: E01 또는 E00 선택권

#### 기본 능력치

| 항목 | 값 |
|---|---:|
| max_hp | 118 |
| atk | 6 |
| def | 3 |
| move_speed | 102 |
| attack_range | 150 |
| attack_interval | 1.45 |
| int | 34 |
| loyalty | 82 |

기본 공격 DPS는 낮다. 모리가 있는 조합은 전투 시간이 조금 늘어도 전투 불능과 잔여 HP에서 이득을 보게 한다.

#### 스킬

1. `spore_mend` / 포자 응급치료
   - 가장 낮은 HP 비율 아군 1명 회복
   - 기본 회복 32
   - 사거리 220
   - 마나 18
   - 재사용 8초
   - 이동·공격 약화 상태 1개 정화
   - 같은 대상이 5초 내 다시 직접 회복을 받으면 `healing_fatigue` 1중첩 적용

2. `clean_cap` / 맑은 갓
   - 반경 105, 5초 지속 포자 구역
   - 초당 회복 2
   - 아군 상태 이상 지속시간 30% 감소
   - 적에게 피해를 주지 않음
   - 마나 28, 재사용 14초

3. `mycelium_link` / 균사 연결
   - 패시브
   - 회복 둥지 또는 인접 방에서 초과 회복의 30%를 보호막으로 변환
   - 보호막은 대상 최대 HP의 12%를 넘지 않음

#### 전술 특화

A. `mori_triage_mycologist` / 응급 균사사

- 직접 회복량 +20%
- HP 45% 이하 아군 우선도 상승
- `clean_cap` 지속시간 -1초
- 추천: 구조 푸딩, 생존 우선 지침

B. `mori_sleep_spore_keeper` / 졸음 포자지기

- `clean_cap`이 적 이동 속도 -18%, 사기 피해 12 부여
- 직접 회복량 -18%
- 추천: 잿불 주술사 핀, 가시 복도

#### AI 규칙

1. 아군 HP 35% 이하: `spore_mend` 최우선
2. 아군 2명 이상이 상태 이상: `clean_cap`
3. 직접 조종 중에는 자동 회복을 잠시 중지하되 패시브는 유지
4. 왕좌 공격 중에는 회복 대상이 없어도 왕좌 방으로 이동하지 않고 지정 방을 유지

#### 약점

- 낮은 기본 화력
- 장거리 적에게 노출되면 빠르게 쓰러짐
- 정화 수습사제가 포자 구역을 억제함
- 회복 피로 때문에 구조 푸딩·회복 둥지와 무한 회복 불가

#### 유대 이벤트

1. `mori_bitter_medicine` / 쓴 약도 약입니다
2. `mori_enemy_bandage` / 침입자도 붕대는 감습니다
3. `mori_full_table_recipe` / 전원 귀환 수프

#### 그래픽 키워드

- 작은 보라·청록 버섯 갓
- 허리에 약초 주머니
- 무섭지 않은 해골 모양 붕대 핀
- 치료 시 갓 아래에서 별 모양 포자
- 인간 간호사 복장으로 만들지 않음

---

### 6.4 가고일 새끼 돌콩

#### 기본 정보

- species ID: `gargoyle_hatchling`
- character ID: `CHR_DOLKONG`
- instance seed: `monster_dolkong`
- 표시 이름: `돌콩`
- 역할: 고정 감시·시설 수호·원거리 저지
- 추천 방: 수호핵, 입구
- 해금: E02 또는 E00 선택권

#### 기본 능력치

| 항목 | 값 |
|---|---:|
| max_hp | 205 |
| atk | 12 |
| def | 8 |
| move_speed | 68 |
| attack_range | 135 |
| attack_interval | 1.45 |
| int | 14 |
| loyalty | 74 |

슬라임보다 느리고 고정 위치에서 강하다. 이동 중에는 공격 효율이 낮다.

#### 스킬

1. `stone_watch` / 석상 감시
   - 6초 동안 이동 불가
   - 사거리 +60
   - 방어 +3
   - 기본 공격 피해 +18%
   - 재사용 10초
   - 적이 없는 방에서는 AI가 사용하지 않음

2. `ward_screech` / 수호의 끼익
   - 반경 180 내 시설 목표 적 최대 2명 도발
   - 자신에게 보호막 34
   - 재사용 12초
   - 보스 도발 불가, 대신 2초간 돌콩 공격 우선도만 증가

3. `living_masonry` / 살아 있는 석재
   - 패시브
   - 입구·수호핵·왕좌 방에서 받는 피해 12% 감소
   - 방을 떠난 뒤 1초 후 해제

#### 전술 특화

A. `dolkong_ward_turret` / 수호 포대

- `stone_watch` 사거리 추가 +25
- 공격 피해 추가 +8%
- 이동 속도 -10%

B. `dolkong_intercept_guard` / 날개 요격수

- 시설 목표 적이 인접 방에 들어오면 120px 짧은 요격 이동
- `stone_watch` 지속시간 -2초
- 기본 사거리 -15

#### AI 규칙

- 시설 목표 적이 있으면 일반 왕좌 목표보다 우선
- `stone_watch` 사용 중에는 직접 이동 명령을 받으면 스킬을 취소
- 수호핵이 무력화되면 가장 가까운 활성 시설로 이동
- 전투 시작 시 적이 오기 전 미리 고정하지 않음

#### 약점

- 느린 재배치
- 공성 파쇄병의 방벽/고정 추가 피해
- 원거리 석궁병에게 일방적으로 맞을 수 있음
- 도둑 추격 능력 부족

#### 유대 이벤트

1. `dolkong_statue_prank` / 진짜 석상은 누구인가
2. `dolkong_cracked_wing` / 금 간 날개 수리
3. `dolkong_watch_oath` / 눈을 감아도 지키는 자리

#### 그래픽 키워드

- 작은 돌날개와 둥근 뿔
- 보라 마력 균열
- 평소에는 웅크린 석상 실루엣
- 공격은 입에서 작은 돌탄 또는 마력 파편
- 성인형 석상이나 거대한 악마상 금지

---

### 6.5 해골 고수 두둠

#### 기본 정보

- species ID: `skeleton_drummer`
- character ID: `CHR_DUDUM`
- instance seed: `monster_dudum`
- 표시 이름: `두둠`
- 역할: 아군 박자 버프·적 동요·전열 보조
- 추천 방: 병영, 중앙 통로
- 해금: E03

#### 기본 능력치

| 항목 | 값 |
|---|---:|
| max_hp | 150 |
| atk | 9 |
| def | 5 |
| move_speed | 105 |
| attack_range | 80 |
| attack_interval | 1.15 |
| int | 18 |
| loyalty | 77 |

#### 스킬

1. `warbeat` / 전진 박자
   - 반경 220 아군 이동 속도 +8%
   - 공격 간격 -10%
   - 5초 지속
   - 재사용 12초
   - 전체 공격 간격 감소 상한 25% 적용

2. `rattle_fright` / 달그락 겁주기
   - 전방 부채꼴 사기 피해 35
   - 사기 임계치가 찬 일반 적은 2.5초 `shaken`
   - 보스는 1.2초 약한 공격력 감소만 적용
   - 재사용 10초

3. `second_measure` / 두 번째 마디
   - 패시브
   - 세 번째 기본 공격마다 주변 아군 스킬 쿨다운 0.25초 감소
   - 한 아군당 2초에 한 번만 적용

#### 전술 특화

A. `dudum_march_conductor` / 행진 지휘자

- `warbeat` 공격 간격 -14%
- `rattle_fright` 사기 피해 -10

B. `dudum_dirge_keeper` / 장송곡 지기

- `rattle_fright` 사기 피해 +18
- `warbeat` 이동 보너스 제거

#### 사기 시스템

- 기존 적 `morale` 값을 저항 임계치로 사용한다.
- 사기 피해는 별도 누적치이며 HP 피해가 아니다.
- 누적치가 morale에 도달하면 일반 적은 `shaken` 상태가 되고 누적치가 0으로 초기화된다.
- `shaken`: 이동 -25%, 공격력 -15%, 2.5초.
- 보스는 임계치 2배, 이동 제어 없이 공격력 -8%, 1.2초.
- 왕국 기수의 오라 안에서는 사기 피해 50% 감소.
- 사기 때문에 적이 맵 밖으로 도망치거나 웨이브 종료가 꼬이지 않게 한다.

#### 약점

- 혼자서는 낮은 피해
- 왕국 기수가 사기 피해를 크게 줄임
- 아군이 분산되면 버프 효율 낮음
- 원거리 집중 공격에 취약

#### 유대 이벤트

1. `dudum_midnight_rehearsal` / 자정의 두둠두둠
2. `dudum_missing_beat` / 잃어버린 북채
3. `dudum_everyone_marches` / 각자 다른 발걸음

#### 그래픽 키워드

- 작은 해골, 큰 북이 아니라 배에 맨 소형 북
- 뼈가 흩어지는 고어 표현 금지
- 북채 끝에 보라 불꽃
- 공격·스킬 동작이 박자로 명확히 구분

---

### 6.6 등불 도깨비 루미

#### 기본 정보

- species ID: `lantern_wisp`
- character ID: `CHR_LUMI`
- instance seed: `monster_lumi`
- 표시 이름: `루미`
- 역할: 위험 대상 표식·시야·원거리 지원
- 추천 방: 감시초소
- 해금: E04 또는 E00 선택권

#### 기본 능력치

| 항목 | 값 |
|---|---:|
| max_hp | 100 |
| atk | 13 |
| def | 2 |
| move_speed | 140 |
| attack_range | 205 |
| attack_interval | 1.25 |
| int | 30 |
| loyalty | 80 |

#### 스킬

1. `guiding_mark` / 길잡이 표식
   - 적 1명 6초 표식
   - 아군 AI 우선도 상승
   - 대상이 받는 모든 피해 +8%
   - 마나 12, 재사용 6초
   - 전체 표식 피해 증폭 상한 15%

2. `flicker_step` / 깜빡 이동
   - 가장 가까운 적 반대 방향으로 최대 120px 순간 이동
   - 직접 조종 시 마우스 지정 위치로 이동
   - 벽·비보행 셀 통과 금지
   - 재사용 9초

3. `watchlight_link` / 감시불 연결
   - 패시브
   - 감시초소 범위의 표식 대상 이동 속도 -10%
   - 은신·가짜 목표 태그가 있는 적을 드러냄

#### 전술 특화

A. `lumi_watch_beacon` / 감시 봉화

- 표식 2개까지 유지
- 각 표식 피해 증폭 5%
- 감시초소 둔화 +5%

B. `lumi_duel_lantern` / 결투 등불

- 표식 1개만 유지
- 피해 증폭 12%
- 표식 사거리 +50

#### AI 규칙

- 공병, 정화사제, 기수, 보스를 우선 표식
- 이미 다른 루미 표식이 있으면 중복 사용 금지
- HP 35% 이하에서 `flicker_step`
- 직접 조종 표식은 AI 표식보다 우선

#### 약점

- 매우 낮은 생존력
- 석궁병의 후열 우선 사격
- 포획꾼의 이동 봉쇄
- 표식 증폭은 상한 때문에 화염 핀과 조합해도 폭증하지 않음

#### 유대 이벤트

1. `lumi_afraid_of_dark` / 어둠이 무서운 도깨비불
2. `lumi_leons_lantern` / 용사의 등불과 마왕의 등불
3. `lumi_last_watch` / 마지막 불을 끄는 순서

#### 그래픽 키워드

- 작은 등불 몸체와 둥근 도깨비불 꼬리
- 노랑·보라 불빛 혼합
- 인간형 요정 실루엣 금지
- 표식은 UI 가독성이 높은 고리와 작은 화살표

---

### 6.7 보물 미믹 미미

#### 기본 정보

- species ID: `treasure_mimic`
- character ID: `CHR_MIMI`
- instance seed: `monster_mimi`
- 표시 이름: `미미`
- 역할: 보물 유인·기습·금고 수비
- 추천 방: 보물 보관실
- 해금: E05

#### 기본 능력치

| 항목 | 값 |
|---|---:|
| max_hp | 175 |
| atk | 15 |
| def | 6 |
| move_speed | 78 |
| attack_range | 48 |
| attack_interval | 1.05 |
| int | 16 |
| loyalty | 68 |

#### 스킬

1. `false_treasure` / 가짜 보물상자
   - 보물 방 또는 인접 방에 가짜 목표 1개 설치
   - 도둑은 실제 보물보다 가짜 목표를 먼저 확인
   - 첫 접촉 적에게 기습 피해 22와 1초 도발
   - 8초 지속, 재사용 14초
   - 보스와 왕실 감정사는 속지 않음

2. `vault_bite` / 금고 깨물기
   - 근접 적 1명에게 기본 공격력 1.6배
   - `goal_type = treasure` 대상은 1.2초 속박
   - 재사용 7초

3. `golden_shell` / 금빛 껍데기
   - 패시브
   - 보물 방이 공격받거나 금화가 실제로 도난당하면 최대 HP 18% 보호막
   - 5초 지속, 전투당 최대 3회

#### 전술 특화

A. `mimi_bait_chest` / 미끼 상자

- 가짜 보물 지속 +3초
- 기습 피해 +25%
- 기본 방어 -1

B. `mimi_vault_guard` / 금고 수문장

- `golden_shell` 22%
- 보물 방에서 받는 피해 -8%
- 가짜 보물 지속 -2초

#### AI 규칙

- 보물 방이 존재할 때만 `false_treasure` 사용
- 도둑이 아직 등장하지 않았어도 웨이브 예고에 도둑이 있으면 미리 배치 가능
- 실제 보물에서 2방 이상 멀어지지 않음
- 왕좌 긴급 방어는 보물 방에 적이 없을 때만 수행

#### 약점

- 낮은 이동 속도
- 왕실 감정사가 가짜 목표를 무시하고 미미를 노출
- 왕좌 방 순수 탱커로는 슬라임보다 약함
- 보물 없는 시나리오에서 효율 낮음

#### 유대 이벤트

1. `mimi_ate_own_coin` / 자기 금화를 먹었습니다
2. `mimi_real_or_fake` / 진짜 상자의 자존심
3. `mimi_castle_over_gold` / 금화보다 남는 것

#### 그래픽 키워드

- 작은 보물상자, 큰 혀 대신 짧은 보라 점액 혀
- 이빨은 둥글고 과장되게 귀여움
- 다리 대신 작은 그림자 발
- 직접적 포식·고어 금지

---

## 7. 신규 적 상세 설계

### 7.1 신규 적 설계 원칙

- 신규 적은 신규 몬스터를 완전히 봉쇄하지 않고 효율을 20~35% 낮추는 수준이다.
- 카운터 적에게도 기존 몬스터로 대응 가능한 약점이 있다.
- 첫 등장 DAY에는 한 명만 나오고 5초 이상 사전 경고를 준다.
- 한 웨이브에 강한 카운터 역할은 최대 2종까지만 조합한다.
- 일반 적에게 종족 특공을 넣지 않는다. 행동·상태·목표를 카운터한다.
- 모든 신규 적은 `idle 2 / move 4 / attack 4 / skill 4 / down 2` 계약을 갖는다.

### 7.2 카운터 순환표

| 신규 몬스터 | 압박 적 | 압박 방식 | 다시 대응하는 아군 |
|---|---|---|---|
| 모리 | 정화 수습사제 | 포자 구역·약화 정화 | 곱의 후열 추격, 루미 표식 |
| 돌콩 | 공성 파쇄병 | 보호막·고정·시설 추가 피해 | 핀 원거리 화력, 모리 유지력 |
| 두둠 | 왕국 기수 | 사기 피해 저항·아군 버프 | 곱 암살, 루미 표식 |
| 루미 | 석궁병·포획꾼 | 후열 사격·이동 봉쇄 | 푸딩 보호, 곱 추격 |
| 미미 | 왕실 감정사 | 가짜 보물 판별·미믹 노출 | 금고 곱, 루미 표식 |

---

### 7.3 왕국 석궁병

- ID: `royal_crossbowman`
- 표시 이름: `왕국 석궁병`
- goal_type: `throne`

| 항목 | 값 |
|---|---:|
| max_hp | 82 |
| atk | 17 |
| def | 2 |
| move_speed | 88 |
| attack_range | 240 |
| attack_interval | 1.60 |
| morale | 62 |
| exp | 34 |
| infamy | 12 |
| threat | 1.35 |

행동:

- 사거리 안의 `support`, `ranged`, `marked_caster` 태그 아군을 우선한다.
- 벽과 비보행 셀을 관통해 사격하지 않는다.
- 같은 대상을 3회 연속 맞히면 `pinning_bolt`: 이동 -20%, 2.5초.
- 근접 적이 70 안으로 오면 왕좌 방향으로 짧게 후퇴한다.

약점:

- 낮은 HP·방어
- 곱의 추격과 루미 표식에 취약
- 푸딩이 접근을 막으면 후퇴 공간을 잃음

---

### 7.4 왕국 포획꾼

- ID: `royal_trapper`
- 표시 이름: `왕국 포획꾼`
- goal_type: `throne`

| 항목 | 값 |
|---|---:|
| max_hp | 105 |
| atk | 9 |
| def | 3 |
| move_speed | 118 |
| attack_range | 125 |
| attack_interval | 1.25 |
| morale | 72 |
| exp | 38 |
| infamy | 13 |
| threat | 1.40 |

스킬 `snare_net`:

- 반경 180 내 이동 속도가 가장 빠른 아군 또는 직접 조종 중인 아군을 선택
- 1.8초 이동 봉쇄, 공격 가능
- 같은 대상은 8초 동안 재포획 면역
- 재사용 10초
- 보스용이 아닌 일반 제어 규칙 적용

약점:

- 순수 화력 낮음
- 핀·루미에게 원거리에서 쉽게 제거
- 고정형 돌콩에게 그물 효율 낮음

---

### 7.5 정화 수습사제

- ID: `purification_acolyte`
- 표시 이름: `정화 수습사제`
- goal_type: `throne`

| 항목 | 값 |
|---|---:|
| max_hp | 95 |
| atk | 7 |
| def | 2 |
| move_speed | 100 |
| attack_range | 165 |
| attack_interval | 1.45 |
| morale | 78 |
| exp | 40 |
| infamy | 14 |
| threat | 1.35 |

스킬 `purge_field`:

- 반경 180 내 아군 적 1명에게 걸린 가장 강한 약화 1개 제거
- 가장 가까운 적대 구역 1개를 4초간 억제
- 억제는 구역을 삭제하지 않고 효과만 중지
- 재사용 10초
- 방 함정 자체는 제거하지 않음

약점:

- 낮은 생존력
- 곱이 우선 추격할 수 있음
- 정화 대상이 없으면 위협도가 낮음
- 루미 표식으로 집중 제거 가능

---

### 7.6 공성 파쇄병

- ID: `siege_breaker`
- 표시 이름: `공성 파쇄병`
- goal_type: `facility`, 활성 시설이 없으면 `throne`

| 항목 | 값 |
|---|---:|
| max_hp | 165 |
| atk | 14 |
| def | 5 |
| move_speed | 76 |
| attack_range | 50 |
| attack_interval | 1.50 |
| morale | 95 |
| exp | 48 |
| infamy | 17 |
| threat | 1.80 |

스킬 `shatter_strike`:

- 0.45초 붉은 경고 원과 망치 들기
- 보호막 대상 피해 +40%
- `anchored`, `stone_watch`, 시설 오브젝트 피해 +35%
- 일반 몬스터에게는 기본 피해만 적용
- 재사용 7초

약점:

- 느림
- 임프 화력과 둔화에 취약
- 모리 회복으로 장기전에서 무력화 가능
- 고블린이 후방 지원을 제거하면 혼자 남음

---

### 7.7 왕국 기수

- ID: `royal_banner_bearer`
- 표시 이름: `왕국 기수`
- goal_type: `throne`

| 항목 | 값 |
|---|---:|
| max_hp | 125 |
| atk | 7 |
| def | 4 |
| move_speed | 90 |
| attack_range | 50 |
| attack_interval | 1.35 |
| morale | 105 |
| exp | 44 |
| infamy | 15 |
| threat | 1.50 |

패시브 `rally_banner`:

- 반경 230 아군 사기 피해 50% 감소
- 공격 간격 -6%
- 기수가 쓰러지면 즉시 해제
- 여러 기수 오라는 중첩하지 않음

스킬 `plant_banner`:

- 6초 동안 이동을 멈추고 오라 범위 +50
- 받는 피해 +10%
- 재사용 12초

약점:

- 오라 때문에 우선 표적이 됨
- 곱·루미에게 취약
- 스스로의 공격 위협 낮음

---

### 7.8 왕실 감정사

- ID: `royal_appraiser`
- 표시 이름: `왕실 감정사`
- goal_type: `treasure`

| 항목 | 값 |
|---|---:|
| max_hp | 110 |
| atk | 9 |
| def | 3 |
| move_speed | 112 |
| attack_range | 48 |
| attack_interval | 1.05 |
| morale | 85 |
| exp | 42 |
| infamy | 15 |
| threat | 1.45 |

행동:

- `false_treasure`를 무시한다.
- 보물 방 진입 시 `true_value`를 사용해 미미의 은폐를 해제하고 5초간 받는 피해 +8% 표식을 건다.
- 직접 금화를 훔치는 속도는 도둑의 70%다.
- 도둑이 함께 있으면 감정사가 먼저 진입하고 도둑이 뒤따른다.

약점:

- 도둑보다 느림
- 금고 곱과 루미 표식에 취약
- 보물 방이 없으면 기본 탐험가 수준의 위협

---

### 7.9 왕국 전술감 에블린

#### 기본 정보

- enemy ID: `royal_tactician_evelyn`
- character ID: `CHR_EVELYN`
- 표시 이름: `왕국 전술감 에블린`
- 등장: 2회차 이상 DAY 21 회차 전용 네임드
- 역할: 선택된 왕국 교리를 전투에서 직접 보여 주는 지휘 보스
- goal_type: `throne`

#### 기본 능력치

| 항목 | 값 |
|---|---:|
| max_hp | 390 |
| atk | 15 |
| def | 7 |
| move_speed | 98 |
| attack_range | 150 |
| attack_interval | 1.20 |
| morale | 125 |
| exp | 110 |
| infamy | 40 |
| threat | 4.60 |

#### 공통 스킬

1. `counter_order`
   - 생존 중인 카운터 적 1명에게 보호막 45
   - 4초 동안 공격 간격 -12%
   - 재사용 9초

2. `contingency_call`
   - HP 50% 이하 1회
   - 현재 교리의 일반 적 1명 소환
   - 소환 적 threat 1.5 이하

3. `tactical_fallback`
   - HP 30% 이하에서 4초 동안 받는 피해 -22%
   - 이동 속도 -15%
   - 회복 없음

#### 교리별 추가 행동

- 경로 분석: 가장 비어 있는 방 경로로 1회 재지정
- 공병 공성: 공병/파쇄병 시설 피해 +10%, 에블린 생존 중만
- 보물 봉쇄: 감정사/도둑 이동 속도 +8%
- 정화 성전: 정화사제 첫 `purge_field` 쿨다운 0초
- 원거리 포위: 석궁병 첫 사격 사거리 +20
- 사기 단속: 기수 오라 범위 +30

#### 약점

- 직접 화력은 레온·셀렌보다 낮음
- 카운터 부하를 먼저 제거하면 지휘 효율 급감
- 교리별 추가 행동은 DAY 21 관리 화면에서 전부 예고

#### 서사 톤

- 에블린은 천재 악역이 아니라 이전 패배 보고서를 지나치게 성실히 읽는 전술 행정관이다.
- 바티와 보고서 양식으로 신경전을 벌인다.
- 레온의 성장을 빼앗지 않으며 DAY 30 최종 라이벌은 계속 레온이다.

---

## 8. 밸런스 프레임워크

### 8.1 위협도 예산

적 수가 아니라 `threat` 합으로 웨이브를 비교한다.

| 적 | threat |
|---|---:|
| 탐험가 | 1.00 |
| 도둑 | 1.15 |
| 조사관 | 1.25 |
| 석궁병 | 1.35 |
| 정화 수습사제 | 1.35 |
| 포획꾼 | 1.40 |
| 공병 | 1.45 |
| 왕실 감정사 | 1.45 |
| 왕국 기수 | 1.50 |
| 방패병 | 1.55 |
| 공성 파쇄병 | 1.80 |
| 셀렌 | 4.20 |
| 로만 | 4.00 |
| 에블린 | 4.60 |
| 정식 레온 | 6.50 |

위협도는 자동 승패 계산식이 아니라 웨이브 편성 검토 기준이다.

### 8.2 조합 추가 비용

| 조합 | 추가 threat |
|---|---:|
| 공병 + 파쇄병 | +0.60 |
| 도둑 + 감정사 | +0.50 |
| 석궁병 + 포획꾼 | +0.40 |
| 정화사제 + 상태 버프 보스 | +0.35 |
| 기수 + 일반 적 3명 이상 | +0.30 |
| 에블린 + 교리 카운터 2종 | +0.50 |

웨이브 변형은 기존 같은 DAY 예산 대비 ±8% 안에서 구성한다.

### 8.3 출전 슬롯 증가 보정

- Stage 01은 기존 3마리이므로 추가 보정 없음.
- Stage 02에서 출전 4마리일 때 기존 웨이브에 평균 threat +1.2.
- Stage 03~04에서 출전 5마리일 때 기존 웨이브에 평균 threat +2.0~2.4.
- 모든 DAY에 일괄 추가하지 않고 변형 웨이브가 있는 핵심 DAY에만 반영한다.
- 지원 몬스터가 추가됐다고 적 HP를 바로 올리지 않는다.

### 8.4 회차 수치 보정

```text
cycle 1~2: 1.00
cycle 3: 1.025
cycle 4: 1.05
cycle 5: 1.075
cycle 6+: 1.10 cap
```

- HP와 ATK에만 적용한다.
- DEF, 이동, 사거리, 스킬 지속시간은 회차로 증가하지 않는다.
- 교리의 행동 변화가 주 난도이고 수치는 보조다.

### 8.5 중첩 상한

| 효과 | 상한 |
|---|---|
| 공격 간격 감소 | 총 25% |
| 이동 속도 증가 | 총 30% |
| 받는 피해 증가 표식 | 총 15% |
| 받는 피해 감소 | 총 55% |
| 단일 보호막 | 대상 최대 HP 35% |
| 직접 회복 피로 | 5초, 최대 2중첩, 중첩당 회복 -20% |
| 일반 적 속박/기절 연속 | 해제 뒤 3초 같은 강제 제어 면역 |
| 보스 강제 제어 | 지속시간 50%, 이동 완전 정지 금지 |
| 사기 피해 | 일반 임계치 100%, 보스 임계치 200% |

### 8.6 신규 몬스터 A/B 목표

| 몬스터 | 우위 시나리오 | 목표 차이 | 대가 확인 |
|---|---|---|---|
| 모리 | 분산 피해·상태 이상 | 전투 불능 1명 감소 또는 잔여 HP +20% | 전투 시간 +5~15% |
| 돌콩 | 시설 공성 | 시설 무력화/피해 -25% | 추격전 시간 +10% 이상 |
| 두둠 | 다수 일반 적 | 전투 시간 -8~12% 또는 적 행동 지연 +15% | 기수 포함 시 효율 절반 |
| 루미 | 위험 후열 1~2명 | 우선 대상 처치 시간 -20% | 석궁/포획 조합 생존 압박 |
| 미미 | 도둑 웨이브 | 도둑 실제 보물 도달 -60% | 감정사 포함 시 이득 20~35%로 감소 |

### 8.7 카운터 적 허용 범위

- 카운터 없는 웨이브 대비 대상 몬스터의 핵심 지표를 20~35% 낮춘다.
- 50% 이상 낮아지면 하드 카운터로 판정하고 수정한다.
- 카운터 적 한 명 때문에 특정 몬스터를 빼지 않으면 패배하는 구조는 금지한다.
- 카운터 적이 나온 날에는 관리 화면에 대응 힌트를 표시한다.

### 8.8 자동 프로필 목표

5개 자동 플레이 프로필 × 5개 seed 기준:

| 프로필 | 목표 결과 |
|---|---|
| 핵심 3종만 사용 | 2회차 보통 교리에서 60% 이상 승리 |
| 회복 중심 | 안정적 승리, 평균 시간이 가장 느림 |
| 시설 중심 | 시설 피해 최소, 포획/보물 대응은 약함 |
| 제어 중심 | 일반 웨이브 우위, 기수/정화 조합에서 고전 |
| 공격 중심 | 가장 빠르나 최종 잔여 HP가 가장 낮음 |
| 균형 계약 | 전체 평균 승률 70~85% |

한 프로필이 모든 교리와 seed에서 100% 승리하면 지나치게 범용적인 조합으로 본다.

---

## 9. 다회차 변형 요소

### 9.1 왕국 교리 총 6종

1차 개발의 3종을 유지하고 3종을 추가한다.

| ID | 이름 | 주요 적 | 변화 |
|---|---|---|---|
| `doctrine_route_analysis` | 경로 분석 | 조사관·석궁병 | 경로 예고가 바뀌고 후열 정찰이 늘어남 |
| `doctrine_engineer_siege` | 공병 공성 | 공병·파쇄병 | 시설 압박과 분산 진입 증가 |
| `doctrine_treasure_blockade` | 보물 봉쇄 | 도둑·감정사 | 보물 목표 적과 원정 비용 압박 |
| `doctrine_sanctified_purge` | 정화 성전 | 정화사제·셀렌 | 둔화·약화·포자 억제 |
| `doctrine_ranged_encirclement` | 원거리 포위 | 석궁병·포획꾼 | 후열과 직접 조종 몬스터 압박 |
| `doctrine_morale_crackdown` | 사기 단속 | 기수·방패병 | 사기 피해 저항과 밀집 전열 |

선택 규칙:

- 회차 시작 시 해금된 교리 중 3개 후보를 보여 준다.
- 최소 1개는 이전 회차와 다른 교리다.
- E11 보상 전에는 직접 전체 목록에서 고를 수 없다.
- 같은 교리를 연속 2회 넘게 후보에 강제하지 않는다.

### 9.2 마왕 칙령 6종

칙령은 플레이어가 선택하는 이득+대가다.

| ID | 이름 | 이득 | 대가 |
|---|---|---|---|
| `decree_household_first` | 식구 우선 | 유대 획득 +25% | 원정 금화 보상 -10% |
| `decree_iron_architecture` | 철골 예산 | 시설 강화 비용 -15% | 몬스터 직접 회복 -10% |
| `decree_smoke_and_mirrors` | 연막 행정 | 이벤트 선택지 새로고침 1회 | 왕좌 최대 HP -8% |
| `decree_arcane_overclock` | 마력 과부하 | 스킬 마나 비용 -15% | 시설이 받는 피해 +10% |
| `decree_personal_command` | 친정 지휘 | 직접 조종 스킬 쿨다운 -10% | AI 지침 보정 -5% |
| `decree_full_delegation` | 전권 위임 | AI 대상 재평가 속도 +20%, 지침 효과 +8% | 직접 조종 쿨다운 +25% |

- 칙령은 엔딩 자격을 단독으로 만들지 않는다.
- 칙령 ID와 사용 결과는 회차 이력에 저장한다.

### 9.3 도전 인장 6종

도전 인장은 선택하지 않아도 된다. 수치 보상 대신 프로필 도장, 장식, 메타 엔딩 조건을 준다.

| ID | 이름 | 조건 |
|---|---|---|
| `seal_no_retry` | 한 번의 문패 | 캠페인 재시도 0회 |
| `seal_fragile_throne` | 얇은 왕좌 | 왕좌 최대 HP -20% |
| `seal_scarce_supplies` | 빠듯한 장부 | 일일 자원 수입 -15% |
| `seal_shifting_rooms` | 흔들리는 복도 | 챕터 전환마다 시설 1곳 재배치 요구 |
| `seal_no_direct_control` | 완전 위임 | 직접 조종 사용 불가 |
| `seal_single_contract` | 작은 식구 | 계약 몬스터 1종만 서명 가능 |

- 한 회차에 최대 1개.
- 첫 2회차에는 UI에서 추천하지 않는다.
- 도전 인장 때문에 일반 엔딩이 잠기지 않게 한다.

### 9.4 이벤트 덱

한 회차에 3개만 발생한다.

- DAY 7~10: 몬스터 또는 성 사건 1개
- DAY 16~20: 교리 사건 1개
- DAY 22~27: 몬스터 또는 왕국 사건 1개
- 같은 프로필에서 모든 이벤트를 보기 전에는 중복 가중치 0.25
- 이벤트 선택은 다음 전투 1회 또는 작은 영구 기록만 바꾼다.

#### 몬스터 사건 5개

1. 모리: `쓴 약 시식회`
2. 돌콩: `석상인 척 경연대회`
3. 두둠: `자정 연습 민원`
4. 루미: `꺼진 등불 찾기`
5. 미미: `진짜 금화 감별 대회`

#### 교리 사건 6개

1. 경로 분석: `빈 지도 상자`
2. 공병 공성: `규격이 다른 망치`
3. 보물 봉쇄: `왕실 압류 딱지`
4. 정화 성전: `성수 배관 누수`
5. 원거리 포위: `횃불을 끌 것인가`
6. 사기 단속: `왕국 선전 벽보`

#### 성 사건 4개

1. `마력 배관 누수`
2. `왕좌 삐걱거림`
3. `작은 해골 행진`
4. `골딘의 사라진 간식비`

### 9.5 핵심 DAY 웨이브 변형 12개

| 변형 ID | 적용 DAY | 중심 교리/역할 |
|---|---:|---|
| `v05_crossbow_scouts` | 5 | 석궁병 첫 예고 |
| `v09_route_pin` | 9 | 조사관+석궁병 |
| `v13_first_purge` | 13 | 정화사제 1명 교육 |
| `v16_treasure_audit` | 16 | 감정사+도둑 |
| `v17_net_and_arrow` | 17 | 포획꾼+석궁병 |
| `v18_breaker_entry` | 18 | 파쇄병 첫 시설 압박 |
| `v20_banner_supply` | 20 | 기수+로만 보급 |
| `v21_evelyn_doctrine` | 21 | 에블린 보스 |
| `v22_purge_watchtower` | 22 | 정화사제+감시초소 시험 |
| `v24_trapper_map` | 24 | 포획꾼+레온 지도 |
| `v28_doctrine_exam` | 28 | 선택 교리 최종 시험 |
| `v30_adaptive_siege` | 30 | 레온 대응형+교리 적 1종 |

선택 규칙:

- 해당 DAY 기본 웨이브를 삭제하지 않고 `variant_group`에서 교체한다.
- 교리와 직전 3일 등장 적을 고려한다.
- 같은 변형을 연속 회차에서 다시 뽑을 확률을 25%로 낮춘다.
- `run_seed`로 결정하고 저장·복원 후 동일하게 유지한다.

### 9.6 회차 seed

`active_run.run_seed`를 저장한다.

- 이벤트 덱 순서
- 웨이브 변형
- 교리 후보
- DAY 29 엔딩 카드 정렬

전투 내부 명중·AI를 모두 고정 난수로 만들 필요는 없다. 콘텐츠 선택만 재현 가능하게 한다.

### 9.7 종별 숙련 목표

각 계약 종은 3개 목표를 갖는다.

- 역할 목표 1개
- 약점 극복 목표 1개
- 유대 목표 1개

보상:

- 초상 표정
- 방 장식
- 추억 문장
- 엔딩 도감 장식

직접 능력치 상승 보상은 주지 않는다.

---

## 10. 레온 적응형 최종전

### 10.1 목적

레온은 플레이어를 몰래 카운터하는 치트 보스가 아니라 DAY 24~29 동안 관찰하고 공개적으로 대응 준비를 하는 라이벌이다.

### 10.2 분석 기간

DAY 21~28 지표로 네 점수를 계산한다.

| 점수 | 주요 지표 |
|---|---|
| `fortress_score` | 보호막, 고정 시간, 시설 기여, 왕좌 무피해 |
| `support_score` | 회복, 정화, 구조, 전투 불능 방지 |
| `control_score` | 둔화, 속박, 사기 피해, 표식 지원 |
| `aggression_score` | 직접 피해, 총공격 시간, 위험 원정, 빠른 처치 |

최고 점수가 55 미만이면 기존 균형형 레온을 사용한다.

### 10.3 대응형 4종

#### A. `leon_breaker_stance` / 파성 자세

- 대상: fortress_score 우세
- 보호막 피해 +25%
- 돌진 시설 피해 +15%
- 이동 속도 -8%
- 외침 범위 -10%

#### B. `leon_pursuit_stance` / 추격 자세

- 대상: support_score 우세
- HP 50% 이하 지원형 몬스터 우선도 상승
- 돌진 거리 +20
- 방어 -10%

#### C. `leon_resolve_stance` / 결의 자세

- 대상: control_score 우세
- 상태 이상 지속시간 -35%
- 사기 피해 저항 +50%
- 공격력 -8%

#### D. `leon_guard_stance` / 방어 결투 자세

- 대상: aggression_score 우세
- 5초마다 첫 큰 피해 20% 감소
- 최후의 맹세 회복량 -5%p
- 기본 이동 속도 -5%

### 10.4 공정성 규칙

- DAY 24에 레온이 무엇을 연구 중인지 예고한다.
- DAY 29에 확정 자세와 약점을 명시한다.
- 플레이어는 DAY 29 관리에서 출전, 스킬, 시설, 지침을 수정할 수 있다.
- 대응형은 대상 전략 효율을 15~25% 낮추되 무효화하지 않는다.
- 동일 자세가 2회 연속 선택되면 다음 회차 계산에서 다른 점수에 +5 탐색 보정한다.

---

## 11. 신규 엔딩

### 11.1 기존 엔딩 호환

- E00~E06 ID와 해금 기록 유지
- 기존 fallback `true_demon_castle` 유지
- 신규 일반 엔딩은 2회차 이상에서만 평가
- 신규 메타 엔딩은 `legacy_goal_id`를 회차 시작 때 명시적으로 선택한 경우만 평가
- DAY 29 선호 선택은 자격을 만들지 않고 해당 엔딩 점수 +3만 제공

### 11.2 E07. 다섯 목소리, 하나의 성

- ID: `many_voices_one_castle`
- 유형: 일반 회차 엔딩
- 핵심: 서로 다른 종이 한 역할에 몰리지 않고 각자 기여한 연합 마왕성
- 연출: 왕좌 앞 점호에서 목소리와 울음이 전부 달라 바티가 출석부를 포기함

필수 조건:

- DAY 30 승리
- cycle_index >= 2
- DAY 30 출전 종 5개
- 계약 종 출전 2개 이상
- 각 종 전투 기여 비율 8% 이상
- 최고 기여 종 비율 42% 이하
- 최종 출전 5종 평균 유대 62 이상
- DAY 30 전투 불능 1명 이하

점수:

- 기여 균형 35%
- 종 다양성 25%
- 평균 유대 25%
- 생존 15%

보상:

- `coalition_charter`
- DAY 15 계약 몬스터 1회 교대권
- 엔딩 일러스트와 연합 문패 장식

### 11.3 E08. 마왕성이 먼저 물었다

- ID: `the_castle_bites_back`
- 유형: 일반 회차 엔딩
- 핵심: 몬스터와 시설이 합쳐져 마왕성 자체가 살아 있는 수비대처럼 작동
- 연출: 미미가 상자인 척하고 돌콩이 석상인 척하는 사이 왕국 보고서에 “건물도 공격함”이라고 기록됨

필수 조건:

- DAY 30 승리
- 시설·함정·구조물 피해 비율 33% 이상
- 시설 평균 가동률 68% 이상
- 돌콩 요격 + 미미 기습 합계 8회 이상
- 총 직접 조종 120초 이하
- 최종장 시설 무력화 4회 이하
- `order >= 55`, `cunning >= 45`

점수:

- 구조물 기여 40%
- 시설 가동 25%
- 자동 운용 20%
- 질서/계략 15%

보상:

- `living_castle_skin`
- 성 사건 이벤트 팩 4개 영구 해금
- 움직이는 문패 장식

### 11.4 E09. 전원 귀환, 식탁은 만석

- ID: `everyone_returns_to_the_table`
- 유형: 일반 회차 엔딩
- 핵심: 강한 성보다 아무도 버리지 않는 지휘가 결말이 됨
- 연출: 결산보다 먼저 식탁 좌석 수를 확인하는 골딘과 모리

필수 조건:

- DAY 30 승리
- DAY 30 전투 불능 0
- DAY 25~30 누적 전투 불능 1 이하
- 유효 회복 + 보호막 방지 피해 650 이상
- 구조 행동 6회 이상
- 최종 출전 종 최저 유대 50 이상
- `kinship >= 58`, `honor >= 45`
- 모리 또는 구조 연금젤 푸딩 출전

점수:

- 생존 35%
- 회복/보호 30%
- 구조 20%
- 유대 15%

보상:

- 계승 추억 2칸 해금
- 단, 전투형 추억은 1개만 장착 가능하고 두 번째는 서사/편의형으로 제한
- 만석 식탁 후일담

### 11.5 E10. 마왕성 거주자 총회

- ID: `demon_castle_residents_assembly`
- 유형: 메타 엔딩
- 회차 시작 `legacy_goal_id = residents_assembly` 필요
- 어떤 엔딩보다 우월한 진 엔딩으로 표시하지 않는다.

필수 프로필 조건:

- 계약 종 5개 전부 해금
- 각 계약 종 추억 1개 이상 해금
- 서로 다른 엔딩 5개 이상 획득
- cycle_index >= 3

현재 회차 조건:

- DAY 30 승리
- 계약 종 2개 출전
- 핵심 3종 중 2개 이상 출전
- 평균 유대 65 이상
- DAY 29 총회 선언 선택

연출:

- 왕좌가 아니라 회의용 긴 탁자
- 각 몬스터가 문패 문구를 제안
- 최종 문구는 “여기 사는 모두가 마왕성.”

보상:

- 계약 로스터 서명 슬롯 3개
- 전투 출전 한도는 그대로 5
- 계약 게시판 즐겨찾기 프리셋 2개

### 11.6 E11. 왕국 교리서는 반납되었습니다

- ID: `kingdom_playbook_returned`
- 유형: 메타 도전 엔딩
- 회차 시작 `legacy_goal_id = return_the_playbook` 필요

필수 프로필 조건:

- 서로 다른 왕국 교리 3종 이상 클리어
- 도전 인장 2종 이상 클리어

현재 회차 조건:

- 도전 인장 1개 활성
- 에블린 격퇴
- 캠페인 재시도 0
- DAY 30 승리
- DAY 29 레온 대응형 확인 후 출전·스킬·지침 중 2개 이상 실제 변경
- `honor >= 50`, `cunning >= 55`

연출:

- 에블린이 두꺼운 교리서를 돌려받고 모든 여백에 마왕성 측 수정 메모가 적혀 있음
- 레온은 다음 판에는 새 공책을 가져오겠다고 선언

보상:

- 새 회차에서 왕국 교리 전체 목록 직접 선택 가능
- 흑요석 검수 도장 장식
- 수치 보너스 없음

### 11.7 신규 엔딩 우선순위

1. 명시적으로 무장한 메타 엔딩 E10/E11
2. E09 전원 귀환
3. E07 다섯 목소리
4. E08 살아 있는 성
5. 기존 E01~E06
6. E00 fallback

동일 등급 안에서는 기존 `EndingResolver` 점수와 안정적 타이브레이크를 사용한다.

---

## 12. 스토리 삽입 지점

기존 DAY 1~30 본편을 재작성하지 않는다.

| DAY | 추가 내용 |
|---:|---|
| 4 | 첫 계약 몬스터 합류 대화, 계약 게시판 설명 |
| 7~10 | 첫 회차 이벤트 덱 사건 |
| 9 | 신규 적 교육형 첫 등장 가능 |
| 13 | 정화/카운터 적 1종 예고 |
| 16 | 두 번째 계약 몬스터 합류, 계약 조합 안내 |
| 16~20 | 교리 사건 1개 |
| 18 | 파쇄병 또는 감정사 교육형 등장 |
| 21 | 에블린 보스와 교리 시험 |
| 22~27 | 후기 이벤트 1개 |
| 24 | 레온이 플레이어 우세 전략을 연구 중임을 알림 |
| 28 | 교리 최종 시험 변형 |
| 29 | 레온 대응형, 엔딩 선호, 메타 목표 상태 표시 |
| 30 | 교리 적 1종과 적응형 레온, 신규 엔딩 평가 |

대사 원칙:

- 신규 몬스터 합류는 종당 5~7줄 이내
- 신규 적 첫 등장 설명은 바티 2줄, 해당 몬스터 반응 1줄 이내
- 반복 회차에서 본 대사는 요약 카드 1개로 축약
- 에블린은 보고서 코미디를 담당하고 레온의 감정선을 침범하지 않음

---

## 13. UI/UX 설계

### 13.1 계약 게시판 화면

필수 영역:

1. 해금된 계약 카드
2. 잠긴 계약과 연결 엔딩 힌트
3. 이번 회차 서명 슬롯 2개
4. 종 역할·강점·약점
5. 합류 DAY
6. 계승 유대 시작값
7. 현재 선택 조합의 역할 경고

경고 예:

- 전열 없음
- 원거리 화력 없음
- 보물 대응 없음
- 회복/보호 없음
- 카운터 적 정화 대응 부족

경고는 선택을 막지 않는다.

### 13.2 출전 명단 화면

- 로스터 최대 5~6개 카드
- 출전/예비 토글
- 현재 한도 `3/4/5`
- 방 배치와 별도로 전투 생성 여부 표시
- 예비 EXP 40% 설명
- 역할 필터: 전열/추격/화력/지원/제어/시설/보물

### 13.3 회차 준비 화면

표시 순서:

1. 계승 몬스터·추억
2. 왕국 교리 후보
3. 마왕 칙령
4. 도전 인장
5. 계약 몬스터
6. 시작 방식
7. 최종 요약

한 화면에 모두 펼치지 말고 단계형 스텝 UI로 만든다.

### 13.4 전투 HUD

- 선택 몬스터 역할 아이콘
- 회복 피로, 표식, 고정, 사기 피해 상태 아이콘
- 신규 카운터 적 등장 경고
- 현재 기수 오라/정화 구역 표시
- 레온 대응 자세 아이콘
- 표식 피해 증폭 상한 도달 시 별도 경고는 하지 않고 툴팁에만 표시

### 13.5 결산 화면

추가 지표:

- 종별 기여 비율
- 회복·보호막 방지 피해
- 구조 행동
- 표식 지원 피해
- 사기 동요 횟수
- 시설 요격·미끼 기습
- 카운터 적별 성공/실패
- 출전/예비 EXP
- 엔딩 방향 변화 1줄

### 13.6 적 정보 도감

각 적 카드:

- 목표 방
- 가장 위험한 행동
- 어떤 몬스터를 압박하는지
- 어떤 기존 몬스터로 대응할 수 있는지
- 첫 조우 전에는 실루엣과 한 줄 힌트만 표시

### 13.7 엔딩 도감 확장

- 기존 7개 + 신규 5개, 총 12개 카드
- 일반/메타 배지 구분
- 잠긴 메타 엔딩은 필요 프로필 진행도 일부 표시
- 정확한 수치 조건은 첫 획득 전 숨김
- 획득 후 당시 지표 스냅샷과 편성 표시

### 13.8 회차 결과 비교

최근 5회차만 비교한다.

- 엔딩
- 계약 몬스터
- 교리·칙령·인장
- 최종 편성
- 왕좌 잔여 HP
- 전투 불능
- 가장 많이 기여한 종
- 레온 대응형

전체 전투 로그는 저장하지 않는다.

---

## 14. 기술 구조

### 14.1 1차 개발 서비스 재사용

재사용 대상:

```text
MonsterRosterService
MonsterGrowthService
BondService
LegacyService
SkillDefinitionService
SkillExecutor
SkillHandlerRegistry
EndingMetricRegistry
EndingMetricProvider
ConditionEvaluator
EndingResolver
RunMetricLedger
CycleService
AtomicJsonStore
ProfileSaveStore
RegularContentValidator
```

### 14.2 신규 서비스

```text
scripts/systems/contracts/ContractBoardService.gd
scripts/systems/progression/SquadSelectionService.gd
scripts/systems/campaign/RunModifierService.gd
scripts/systems/campaign/EventDeckService.gd
scripts/systems/campaign/EncounterVariantResolver.gd
scripts/systems/combat/ThreatBudgetService.gd
scripts/systems/combat/StatusStackPolicy.gd
scripts/systems/combat/MoraleService.gd
scripts/systems/enemies/EnemyBehaviorRegistry.gd
scripts/systems/enemies/DoctrinePackageService.gd
scripts/systems/bosses/LeonAdaptationResolver.gd
scripts/systems/endings/MetaEndingGoalService.gd
scripts/systems/save/SaveMigrationV2ToV3.gd
```

### 14.3 책임

#### `ContractBoardService`

- 계약 해금 판정
- 회차 서명 2종 검증
- E00 선택권 처리
- 중복 계약 방지
- 합류 DAY 관리

#### `SquadSelectionService`

- 성 단계별 출전 한도
- 출전/예비 목록
- 최소 1명 검증
- 전투 생성 대상 제공
- 예비 EXP 계산

#### `RunModifierService`

- 교리, 칙령, 인장 조합 검증
- 보정 적용 순서
- 상호 배타 규칙
- UI 요약

#### `EventDeckService`

- run seed 기반 덱 셔플
- 카테고리별 1개 선택
- 중복 가중치 감소
- 저장/복원

#### `EncounterVariantResolver`

- DAY, 교리, 최근 등장, run seed로 변형 선택
- threat 예산 검증
- 선택 결과 고정 저장

#### `ThreatBudgetService`

- 적 threat 합산
- 조합 추가 비용
- 기준 웨이브 대비 편차 계산
- 자동 테스트용 보고서

#### `StatusStackPolicy`

- 회복 피로
- 피해 증폭 상한
- 공격 간격 상한
- 보호막 상한
- 제어 면역 시간

#### `MoraleService`

- 사기 피해 누적
- 임계치와 shaken 적용
- 기수 저항
- 보스 규칙

#### `EnemyBehaviorRegistry`

- 후열 우선
- 그물
- 정화
- 시설 파쇄
- 기수 오라
- 감정 판별

#### `LeonAdaptationResolver`

- DAY 21~28 지표 계산
- 자세 선택
- 반복 자세 탐색 보정
- DAY 24/29 설명용 근거 반환

### 14.4 Autoload 정책

신규 서비스는 처음부터 Autoload로 등록하지 않는다. `GameRoot` 또는 전투 세션 컨텍스트가 생성·주입한다. 전역 수명이 정말 필요한 저장·프로필 접근은 기존 `ProfileSaveStore`를 통해 처리한다.

### 14.5 신호 후보

```gdscript
signal contract_unlocked(species_id: String, source_ending_id: String)
signal contract_signed(species_id: String, join_day: int)
signal squad_changed(active_instance_ids: Array[String], reserve_instance_ids: Array[String])
signal doctrine_selected(doctrine_id: String)
signal decree_selected(decree_id: String)
signal challenge_seal_selected(seal_id: String)
signal encounter_variant_resolved(day: int, variant_id: String)
signal morale_broken(unit_id: String, source_instance_id: String)
signal leon_adaptation_resolved(adaptation_id: String, scores: Dictionary)
signal meta_ending_goal_selected(goal_id: String)
```

---

## 15. 저장 v3

### 15.1 파일 정책

- 물리 파일은 기존 원자적 프로필 파일 경로를 유지하거나 `mawang_profile_v3.json`으로 안전 전환한다.
- v2 원본을 `.pre_v3.bak`으로 남긴다.
- 마이그레이션 체인은 `v1 → v2 → v3`이며 v1에서 곧바로 v3로 건너뛰는 별도 로직을 만들지 않는다.

### 15.2 profile 추가 필드

```json
{
  "unlocked_contract_species_ids": [],
  "contract_choice_tokens": 0,
  "contract_mastery": {},
  "doctrine_clear_history": {},
  "challenge_seal_clear_history": {},
  "unlocked_decree_ids": [],
  "unlocked_legacy_goal_ids": [],
  "enemy_intel": {},
  "event_seen_counts": {},
  "ending_preference_history": [],
  "contract_loadout_presets": []
}
```

### 15.3 active_run 추가 필드

```json
{
  "run_seed": 0,
  "signed_contract_species_ids": [],
  "contract_join_days": {},
  "active_squad_instance_ids": [],
  "reserve_instance_ids": [],
  "kingdom_doctrine_id": "",
  "demon_decree_id": "",
  "challenge_seal_id": "",
  "event_deck_state": {},
  "resolved_event_ids": [],
  "encounter_variant_history": {},
  "leon_adaptation_id": "",
  "leon_adaptation_scores": {},
  "ending_preference_id": "",
  "legacy_goal_id": ""
}
```

### 15.4 진행 중 v2 저장 마이그레이션

- DAY 1~30 진행 중인 v2 저장은 그대로 이어간다.
- 진행 중 회차에 계약 몬스터, 교리 추가, 이벤트 덱을 강제로 삽입하지 않는다.
- 해당 회차를 클리어하거나 새 회차를 시작할 때 2차 콘텐츠가 활성화된다.
- 엔딩/후일담 상태의 v2 저장은 계약 게시판 해금 안내를 바로 받을 수 있다.
- 신규 필드는 안전 기본값으로 추가한다.

### 15.5 검증

- signed contract는 해금 목록에 있어야 함
- 중복 species 금지
- active+reserve 합은 해당 회차 로스터와 일치
- 출전 수는 성 단계 한도 이하
- doctrine/decree/seal ID 유효
- event deck cursor 범위 유효
- encounter variant의 DAY와 저장 키 일치
- leon adaptation은 DAY 29 이후에만 비어 있지 않을 수 있음
- meta ending goal은 해금된 목표만 허용

---

## 16. 데이터 파일 계획

### 16.1 신규 데이터

```text
data/regular_version/monsters/contract_monsters.json
data/regular_version/monsters/contract_specializations.json
data/regular_version/events/contract_monster_events.json
data/regular_version/enemies/counter_enemies.json
data/regular_version/enemies/enemy_behaviors.json
data/regular_version/progression/contract_unlocks.json
data/regular_version/progression/kingdom_doctrines_v2.json
data/regular_version/progression/demon_decrees.json
data/regular_version/progression/challenge_seals.json
data/regular_version/progression/meta_ending_goals.json
data/regular_version/campaign/cycle_events_v2.json
data/regular_version/campaign/encounter_variants_v2.json
data/regular_version/campaign/leon_adaptation_rules.json
data/regular_version/progression/endings_update2.json
data/regular_version/balance/update2_threat_budget.json
```

### 16.2 기존 데이터 수정

- `data/monsters.json`: 신규 종 런타임 기본 정의를 이 파일이 원본이라면 여기에 추가
- `data/skills.json`: 신규 스킬 정의
- `data/characters.json`: 신규 캐릭터 ID와 초상
- `data/enemies.json`: 신규 적 기본 능력치
- `data/campaign_days.json`: 변형 그룹과 대사 훅만 추가
- `data/waves.json`: 기본 웨이브 유지, 변형 참조 추가

같은 데이터의 원본을 두 군데 만들지 않는다. Phase 0에서 1차 개발이 데이터를 어디로 이관했는지 확인하고 한쪽만 사용한다.

### 16.3 몬스터 JSON 예시

```json
{
  "mushroom_nurse": {
    "display_name": "버섯 간호사",
    "character_id": "CHR_MORI",
    "role": "회복·정화 지원",
    "max_hp": 118,
    "atk": 6,
    "def": 3,
    "move_speed": 102,
    "attack_range": 150,
    "attack_interval": 1.45,
    "int": 34,
    "loyalty": 82,
    "skill_slots": ["spore_mend", "clean_cap", "mycelium_link"],
    "specialization_ids": [
      "mori_triage_mycologist",
      "mori_sleep_spore_keeper"
    ],
    "recommended_room": "recovery",
    "contract": {
      "join_day_first": 4,
      "join_day_second": 16,
      "unlock_id": "contract_mushroom_nurse"
    }
  }
}
```

### 16.4 적 JSON 예시

```json
{
  "purification_acolyte": {
    "display_name": "정화 수습사제",
    "goal_type": "throne",
    "max_hp": 95,
    "atk": 7,
    "def": 2,
    "move_speed": 100,
    "attack_range": 165,
    "attack_interval": 1.45,
    "morale": 78,
    "behavior_ids": ["support_backline", "purge_field"],
    "skill_ids": ["enemy_purge_field"],
    "threat": 1.35,
    "counter_tags": ["zone", "debuff", "spore"],
    "weak_to_role_tags": ["chaser", "mark_focus"]
  }
}
```

### 16.5 웨이브 변형 예시

```json
{
  "v17_net_and_arrow": {
    "day": 17,
    "eligible_doctrines": ["doctrine_ranged_encirclement"],
    "replace_group": "day17_midwave",
    "enemy_entries": [
      {"enemy_id": "royal_trapper", "count": 1, "spawn_delay": 18.0},
      {"enemy_id": "royal_crossbowman", "count": 1, "spawn_delay": 23.0}
    ],
    "target_threat_delta": 1.75,
    "intro_line_id": "D_V17_NET_ARROW_001",
    "first_seen_intel_ids": ["royal_trapper", "royal_crossbowman"]
  }
}
```

### 16.6 신규 엔딩 예시

```json
{
  "many_voices_one_castle": {
    "category": "run_ending",
    "priority": 70,
    "requirements": {
      "all": [
        {"metric": "campaign.victory", "op": "eq", "value": true},
        {"metric": "run.cycle_index", "op": "gte", "value": 2},
        {"metric": "roster.final_species_count", "op": "gte", "value": 5},
        {"metric": "roster.final_min_contribution_share", "op": "gte", "value": 0.08},
        {"metric": "roster.final_max_contribution_share", "op": "lte", "value": 0.42},
        {"metric": "roster.final_average_bond", "op": "gte", "value": 62},
        {"metric": "combat.day30_down_count", "op": "lte", "value": 1}
      ]
    },
    "reward_ids": ["coalition_charter"],
    "illustration": "res://assets/sprites/endings/ending_many_voices_one_castle.png"
  }
}
```

---

## 17. 그래픽 리소스 계획

### 17.1 최대 제작량

1차 개발에서 어떤 계약 종이 이미 완료됐는지에 따라 실제 수량은 줄어든다. 최대 기준:

#### 신규 몬스터 5종

- 전투 프레임: 5 × 16 = 80장
- 기본 초상: 5장
- 감정 초상: 종당 2개 추가 = 10장
- 스킬 아이콘: 종당 3개 = 15개
- 전술 특화 배지: 종당 2개 = 10개
- 전용 VFX: 종당 2세트 = 10세트

#### 신규 일반 적 6종 + 에블린

- 일반 적 전투 프레임: 6 × 16 = 96장
- 에블린 전투 프레임: 16장
- 에블린 초상: 기본 + 감정 3개 = 4장
- 적 스킬 VFX: 7세트
- 적 정보 도감 아이콘: 7개

#### 엔딩·UI

- 신규 엔딩 일러스트 5장
- 엔딩 문양 5개
- 계약 카드 배경 5개
- 교리 아이콘 6개, 신규 제작은 3개 이상
- 칙령 아이콘 6개
- 도전 인장 6개
- 상태 아이콘: 회복 피로, 표식, 고정, 그물, 정화 억제, 동요, 기수 오라 총 7개

### 17.2 파일명

몬스터:

```text
assets/sprites/monsters/monster_mushroom_nurse_idle_down_00.png
assets/sprites/monsters/monster_gargoyle_hatchling_skill_down_03.png
assets/sprites/monsters/monster_skeleton_drummer_down_01.png
```

적:

```text
assets/sprites/enemies/enemy_royal_crossbowman_attack_down_00.png
assets/sprites/enemies/enemy_royal_tactician_evelyn_skill_down_03.png
```

초상:

```text
assets/sprites/portraits/monsters/CHR_MORI_portrait_worried.png
assets/sprites/portraits/campaign/CHR_EVELYN_portrait_procedural.png
```

원본:

```text
assets/source/imagegen/mori/SOURCE.md
assets/source/imagegen/dolkong/SOURCE.md
assets/source/imagegen/dudum/SOURCE.md
assets/source/imagegen/lumi/SOURCE.md
assets/source/imagegen/mimi/SOURCE.md
assets/source/imagegen/evelyn/SOURCE.md
```

### 17.3 제작 순서

각 종마다 다음 순서를 지킨다.

1. placeholder 실루엣
2. 실제 전투 기능
3. A/B 밸런스
4. 디자인 시트
5. 기본 초상
6. 16프레임 전투 시트
7. 투명화·분할·중복 해시 검사
8. 스킬 VFX
9. 전술 특화 배지
10. 1920×1080/1366×768 실제 캡처

### 17.4 리소스 검수

- 192×192 RGBA
- 네 모서리 투명
- 프레임 픽셀 해시 중복 금지
- 공격·스킬 4프레임이 실제 재생 시간 안에 모두 보임
- 실루엣이 기본 줌에서 구분됨
- 기존 캐릭터를 색만 바꾼 대체 금지
- 텍스트·워터마크 금지
- 큐트 호러 판타지 유지
- 직접적 고어와 성인 요소 금지

### 17.5 방 장식

신규 방 종류는 만들지 않는다. 기존 방에 소품 슬롯으로만 추가한다.

- 모리: 작은 포자 약장
- 돌콩: 가고일 횃대
- 두둠: 북 보관대
- 루미: 등불 걸이
- 미미: 가짜 보물 표식
- 계약 게시판: 관리 화면 소품

---

## 18. 오디오 계획

### 18.1 신규 SFX

몬스터:

- 모리: 포자 분사, 회복, 정화
- 돌콩: 돌탄, 석상 고정, 끼익 도발
- 두둠: 기본 북, 전진 박자, 겁주기
- 루미: 표식, 깜빡 이동, 불빛 타격
- 미미: 상자 닫힘, 기습 깨물기, 금빛 보호막

적:

- 석궁 발사
- 그물 투척
- 정화 파동
- 파쇄 망치
- 기수 깃발 설치
- 감정 도장
- 에블린 지휘 신호

### 18.2 BGM

- 신규 전투 BGM 1곡: `왕국의 대응 작전`
- 에블린 등장 시 20~30초 지휘 변주
- 신규 엔딩은 공용 후일담 BGM을 사용하되 엔딩별 2~3초 스팅어만 다르게 한다.

### 18.3 중첩 제한

- 두둠 북소리는 동일 샘플 0.10초 내 중복 재생 금지
- 석궁 다수 사격은 음높이·볼륨 소폭 변화
- 회복·보호막 소리는 전투 로그보다 우선하지 않게 음량 제한

---

## 19. 상세 구현 Phase

각 Phase는 독립 PR 또는 독립 세션이다. 완료 조건을 통과하지 못하면 다음 Phase로 가지 않는다.

### Phase 0. 1차 개발 완료 감사와 기준선 동결

산출물:

- `docs/design/UPDATE2_CONTRACTS_COUNTEROFFENSIVE_PLAN_2026-07-12.md`
- `docs/HANDOFF_UPDATE2_BASELINE.md`
- 1차 신규 몬스터 감사표
- 기존 Full/Quick 결과

작업:

1. 1차 개발 모든 완료 조건 확인
2. 실제 저장 schema/version 확인
3. 실제 엔딩 ID 목록 확인
4. 실제 계약/신규 몬스터 확인
5. 서비스 경로 확인
6. 기준 캡처 보관

완료 조건:

- 기존 전체 검증 PASS
- 신규 몬스터 중복 위험 없음
- 수정 없는 기준 커밋 기록

금지:

- 코드·데이터·그래픽 변경

---

### Phase 1. 데이터 계약과 저장 v3 마이그레이션

추가:

```text
SaveMigrationV2ToV3.gd
Update2ContentValidator.gd
Update2SaveMigrationTest.gd/.tscn
```

작업:

1. v3 필드 계약
2. v2 fixture 5종
3. 순수 함수 마이그레이션
4. 진행 중 회차 비활성 정책
5. 원자적 저장 연결
6. validator 등록

완료 조건:

- v2 DAY 4/16/21/29/30 저장 복원
- 진행 중 회차에 신규 콘텐츠 미삽입
- 후일담에서 계약 게시판 해금 가능
- v2 백업 보존

금지:

- 계약 UI
- 신규 몬스터

---

### Phase 2. 계약 게시판 껍데기

범위:

- 계약 카드 placeholder 5개
- 해금/잠금
- E00 선택권
- 회차 서명 2칸
- 실제 전투 합류 없음

추가 씬:

```text
ContractBoardScreen.tscn
ContractCard.tscn
ContractChoicePopup.tscn
```

완료 조건:

- 프로필 해금 저장
- 중복 선택 차단
- 잠긴 카드 조건 힌트
- 1920/1366 UI PASS

---

### Phase 3. 출전/예비 로스터

범위:

- 기존 핵심 3종만으로 출전 한도 구조 검증
- Stage 01=3, Stage 02=4, Stage 03/04=5
- 예비 EXP 40%

완료 조건:

- 출전 체크가 꺼진 유닛 미생성
- 저장/복원
- 기존 DAY 1~30 기본 편성 회귀 없음
- 최소 1명/최대 한도 검증

금지:

- 신규 종 생성

---

### Phase 4. 위협도와 웨이브 변형 기반

범위:

- ThreatBudgetService
- EncounterVariantResolver
- 기존 적만 사용한 테스트 변형 1개
- run seed 저장

완료 조건:

- 같은 seed 저장/복원 결과 동일
- 기준 웨이브 ±8% 검사
- 변형이 없으면 기존 웨이브 그대로

---

### Phase 5. 모리 전투 수직 구현

순서:

1. 데이터
2. placeholder
3. 회복 피로 정책
4. `spore_mend`
5. `clean_cap`
6. 전술 특화 2개
7. AI/직접 조종
8. A/B 테스트
9. 최종 그래픽·오디오
10. 유대 이벤트 1개

완료 조건:

- 분산 피해 시 잔여 HP 우위
- 기본 화력 조합보다 전투 시간 증가
- 무한 회복 없음
- 회복 둥지와 보호막 상한 준수

---

### Phase 6. 정화 수습사제

순서:

1. enemy behavior registry 정화 훅
2. 구역 억제
3. 교육형 DAY 13 변형
4. 모리/주술 핀/가시 복도 A/B
5. 그래픽·오디오

완료 조건:

- 모리 핵심 효율 20~35% 감소
- 포자/함정 전체 삭제 금지
- 곱 추격으로 대응 가능

---

### Phase 7. 돌콩 전투 구현

- `stone_watch`
- `ward_screech`
- 특화 2개
- 수호핵·입구·왕좌 연계
- 고정 취소와 직접 이동
- 그래픽·오디오

완료 조건:

- 시설 피해 -25% 목표
- 추격전에서 명확히 느림
- 슬라임보다 모든 전열 지표가 우월하지 않음

---

### Phase 8. 공성 파쇄병

- 시설 목표 fallback
- `shatter_strike` 경고
- 보호막/고정 추가 피해
- DAY 18 교육형 변형
- 그래픽·오디오

완료 조건:

- 돌콩 효율 감소 20~35%
- 파쇄병이 일반 몬스터를 8초 내 삭제하지 않음
- 임프·둔화 조합으로 대응 가능

---

### Phase 9. 미미 전투 구현

- 가짜 목표 오브젝트
- 도둑 목표 우선순위
- `vault_bite`
- `golden_shell`
- 특화 2개
- 그래픽·오디오

완료 조건:

- 도둑 보물 도달 -60%
- 보물 없는 전투에서 효율 제한
- 왕좌 긴급 방어 회귀 없음

---

### Phase 10. 왕실 감정사

- 가짜 목표 무시
- 미미 노출 표식
- 도둑과 협동 진입
- DAY 16 변형
- 그래픽·오디오

완료 조건:

- 미미를 무효화하지 않음
- 금고 곱/루미로 대응 가능
- 보물 손실 계산 중복 없음

---

### Phase 11. 루미 전투 구현

- 표식 상한
- AI 우선도
- `flicker_step` 보행 검증
- 감시초소 연계
- 특화 2개
- 그래픽·오디오

완료 조건:

- 위험 적 처치 시간 -20%
- 표식 중첩 15% 상한
- 벽 통과 없음

---

### Phase 12. 석궁병과 포획꾼

세션 12A: 석궁병

- 후열 우선
- 사선 검사
- 연속 사격 둔화

세션 12B: 포획꾼

- 이동 빠른 대상/직접 조종 대상 그물
- 재포획 면역

완료 조건:

- 루미/모리에게 위협이 되지만 보호·추격으로 대응 가능
- 맵 밖 후퇴·벽 관통 없음
- 직접 조종을 완전히 봉쇄하지 않음

---

### Phase 13. 두둠과 사기 시스템

순서:

1. MoraleService 독립 테스트
2. 두둠 placeholder
3. `warbeat`
4. `rattle_fright`
5. 보스 규칙
6. 특화 2개
7. 그래픽·오디오

완료 조건:

- 적 도주로 웨이브 종료 꼬임 없음
- 일반 웨이브 우위 8~15%
- 보스 하드 제어 없음

---

### Phase 14. 왕국 기수

- 오라
- 깃발 설치
- 중첩 방지
- 기수 우선 표식
- DAY 20/22 변형
- 그래픽·오디오

완료 조건:

- 두둠 사기 효율 약 절반
- 기수 제거 후 즉시 정상 회복
- 기수 2명 중첩 없음

---

### Phase 15. 에블린과 교리 6종

순서:

1. 기존 교리 3종 데이터 이관
2. 신규 교리 3종
3. DoctrinePackageService
4. 에블린 공통 행동
5. 교리별 추가 행동
6. DAY 21 전투
7. 초상·16프레임·오디오
8. 교리별 A/B

완료 조건:

- 모든 교리에서 에블린 승리 가능
- 교리별 지표가 실제로 다름
- 레온 최종전 역할 침범 없음

---

### Phase 16. 마왕 칙령과 도전 인장

범위:

- 칙령 6개
- 인장 6개
- 회차 준비 단계형 UI
- 저장/결산
- 인장 클리어 프로필 기록

완료 조건:

- 이득과 대가 실제 적용
- 칙령 하나가 엔딩을 자동 확정하지 않음
- 인장 미선택 가능

---

### Phase 17. 이벤트 덱 15개

순서:

1. EventDeckService
2. placeholder 텍스트로 3개 수직 구현
3. 중복 가중치
4. 저장/복원
5. 나머지 12개 데이터
6. 초상/소품 연결

완료 조건:

- 회차당 정확히 3개
- 같은 save에서 재로드해 결과 변경 없음
- 이벤트 하나의 전투 보정이 ±10%를 넘지 않음

---

### Phase 18. 웨이브 변형 12개

- 각 변형 threat 보고서
- 신규 적 첫 등장 순서
- 최근 3일 중복 제한
- 교리별 최소 2개 변형
- DAY 28 최종 시험

완료 조건:

- 기본 웨이브 경로 유지
- 모든 변형 시간 초과 없음
- 한 웨이브 강한 카운터 2종 이하

---

### Phase 19. 레온 적응형 최종전

순서:

1. 점수 계산 pure function
2. 합성 스냅샷 4종
3. 반복 자세 탐색 보정
4. DAY 24 예고
5. DAY 29 확정 UI
6. DAY 30 실제 보정
7. 기존 균형형 fallback

완료 조건:

- 4자세 모두 도달
- 대상 빌드 효율 15~25% 감소
- 약점도 함께 존재
- 저장/복원 후 자세 고정

---

### Phase 20. 일반 신규 엔딩 E07~E09

순서:

1. metric registry 확장
2. 합성 도달성
3. 자동 프로필
4. DAY 29 선호 +3
5. 대사
6. placeholder 일러스트
7. 실제 일러스트·스팅어
8. 도감

완료 조건:

- E07~E09 각각 최소 2개 서로 다른 빌드로 도달 가능
- 기존 E01 식구 엔딩과 무조건 충돌하지 않음
- fallback 유지

---

### Phase 21. 메타 엔딩 E10~E11

- MetaEndingGoalService
- 회차 시작 목표 선택
- 프로필 조건
- 총회 장면
- 교리서 반납 장면
- 보상 적용

완료 조건:

- 목표를 무장하지 않으면 메타 엔딩 미평가
- 프로필 변조 검증
- 보상이 출전 한도/수치를 직접 올리지 않음

---

### Phase 22. 최종 통합 검수

검수 묶음:

- v2→v3
- 계약 게시판
- 출전/예비
- 계약 종 5개
- 신규 적 6개
- 에블린
- 교리 6개
- 칙령 6개
- 인장 6개
- 이벤트 15개
- 웨이브 변형 12개
- 레온 4자세
- 신규 엔딩 5개
- 기존 엔딩 7개
- 1920×1080/1366×768
- 웹 내보내기
- 메모리·프레임 시간

완료 조건:

- 전체 core suite PASS
- 5 seed × 6 프로필 자동 회차 PASS
- 저장 손상·마이그레이션 검사 PASS
- 엔딩 12개 도달성 검사 PASS
- 그래픽 프레임 계약 PASS
- 실제 외부 플레이 테스트 완료

---

## 20. 자동 검사 계획

### 20.1 데이터 검사

- ID 중복
- 존재하지 않는 skill/behavior/portrait
- 계약 해금 엔딩 참조
- threat 음수/누락
- 교리 패키지 빈 배열
- 이벤트 카테고리 수
- 엔딩 fallback 정확히 하나
- 메타 목표 참조

### 20.2 계약/로스터 검사

- 잠긴 계약 선택 거부
- 동일 종 중복 거부
- 2종 초과 거부
- 합류 DAY 전 생성 금지
- 출전 한도
- 예비 EXP 40%
- 저장/복원

### 20.3 상태 상한 검사

- 회복 피로
- 보호막 35%
- 표식 15%
- 공격 간격 25%
- 기수 오라 중첩 금지
- 제어 면역

### 20.4 신규 적 검사

- 석궁 벽 관통 없음
- 그물 재포획 면역
- 정화가 구역을 삭제하지 않음
- 파쇄 경고 시간
- 감정사 가짜 보물 무시
- 기수 사망 후 오라 제거

### 20.5 엔딩 도달성

- 합성 스냅샷 12개
- 기존 엔딩 회귀
- E07 기여 비율 경계값
- E08 직접 조종 경계값
- E09 전투 불능 경계값
- E10 계약/추억 프로필 조건
- E11 교리/인장/재시도 조건

### 20.6 자동 회차 프로필

1. 핵심 3종 only
2. 모리+돌콩 안정형
3. 루미+두둠 제어형
4. 미미+곱 보물형
5. 핀+루미 공격형
6. 랜덤 계약 균형형

각 프로필을 최소 seed 5개로 실행한다.

### 20.7 성능

- 동시 유닛 증가에도 1920×1080 기준 목표 프레임 유지
- 상태 아이콘 업데이트를 매 물리 프레임 전체 재생성하지 않음
- EventDeck/EndingResolver는 전투 프레임 루프에서 실행하지 않음
- run history 최근 50개 제한 유지

---

## 21. 수동 플레이 테스트

### 21.1 첫 계약 체감

외부 플레이어가 다음을 설명할 수 있어야 한다.

- 왜 모리를 데려갔는지
- 왜 다른 계약 종을 포기했는지
- 출전과 예비의 차이
- 신규 적이 무엇을 압박했는지
- 다음 회차에 다른 종을 고를 이유

### 21.2 카운터 공정성

질문:

- 적 첫 등장 전에 경고를 봤는가
- 어떤 몬스터가 압박받는지 이해했는가
- 편성/방/지침 중 하나를 바꿔 대응할 수 있었는가
- 적이 “내 선택을 금지한다”고 느끼지 않았는가

### 21.3 반복 동기

최소 2회차 플레이 뒤 다음 중 3개 이상이 자발적으로 언급돼야 한다.

- 다른 계약 몬스터
- 다른 교리
- 다른 칙령
- 다른 엔딩
- 종별 추억
- 레온 다른 자세
- 도전 인장

---

## 22. 완료 조건

### 22.1 시스템 완료

- 계약 게시판과 회차 서명
- 출전/예비 로스터
- 저장 v3
- threat/변형/event seed
- 교리/칙령/인장
- 적응형 레온
- 일반/메타 엔딩

### 22.2 콘텐츠 완료

- 목표 계약 몬스터 5종 카탈로그
- 신규 일반 적 6종
- 에블린 1명
- 이벤트 15개
- 변형 12개
- 신규 엔딩 5개
- 모든 필수 그래픽·오디오

### 22.3 밸런스 완료

- 신규 몬스터가 기존 핵심 3종의 상위호환이 아님
- 카운터 적 효율 감소 20~35%
- 5종 편성의 평균 파워가 웨이브 예산과 맞음
- 한 조합이 모든 교리에서 독점하지 않음
- 전투 시간 목표 범위 유지

### 22.4 다회차 완료

- 같은 DAY에서 회차별 적·사건이 실제로 달라짐
- 계약 선택이 전투와 엔딩에 반영됨
- 최소 3회차 동안 새로운 해금 또는 목표가 남음
- 수치 무한 누적 없이 선택지가 증가함

---

## 23. Codex 삽질 방지 규칙

1. 한 Phase를 끝내기 전 다음 종의 그래픽을 만들지 않는다.
2. 신규 몬스터 하나를 만든 뒤 바로 그 몬스터의 카운터 적까지 검증한다.
3. A/B가 실패하면 적 수를 추가하지 말고 역할 수치와 행동을 먼저 고친다.
4. UI가 복잡하면 새 탭을 계속 늘리지 말고 단계형 화면과 툴팁을 사용한다.
5. 엔딩 조건은 코드 `if`로 추가하지 않는다.
6. 신규 적 행동은 `EnemyBehaviorRegistry`를 통한다.
7. 이벤트 효과는 다음 전투 ±10%를 넘기지 않는다.
8. 레온 대응형은 DAY 29에 반드시 공개한다.
9. 1차 개발 신규 몬스터를 발견하면 재제작하지 않는다.
10. 전체 검증 실패 시 신규 콘텐츠를 더 얹지 않는다.
11. 최종 그래픽 전에 placeholder 캡처로 크기와 실루엣을 검증한다.
12. 리팩터링은 현재 Phase에 필요한 경계만 수정한다.

---

## 24. 결정 로그 초안

| ID | 결정 |
|---|---|
| U2-D001 | DAY 30 최종일 유지, 회차 변형으로 확장 |
| U2-D002 | 계약 몬스터 목표 5종, 회차당 2종 서명 |
| U2-D003 | Stage별 출전 한도 3/4/5/5 |
| U2-D004 | 예비 EXP 40%, 유대·활약 EXP 없음 |
| U2-D005 | 신규 일반 적 6종, 네임드 1명 상한 |
| U2-D006 | 신규 종마다 대응 적과 기존 대응 수단을 함께 설계 |
| U2-D007 | threat 예산과 조합 추가 비용 사용 |
| U2-D008 | 회차 수치 증가 10% cap |
| U2-D009 | 왕국 교리 총 6종 |
| U2-D010 | 마왕 칙령 6종은 이득+대가 |
| U2-D011 | 도전 인장은 선택형·비수치 보상 |
| U2-D012 | 이벤트는 회차당 3개, 총 15개 |
| U2-D013 | 레온 대응형 4개, DAY 29 공개 |
| U2-D014 | 일반 엔딩 3개, 메타 엔딩 2개 추가 |
| U2-D015 | 메타 엔딩은 회차 시작 목표 무장 필요 |
| U2-D016 | 저장 v3, 진행 중 v2 회차에는 신규 콘텐츠 강제 삽입 금지 |
| U2-D017 | 신규 종은 기본 형태만, 진화 2단계는 차기 업데이트 |
| U2-D018 | 계약·엔딩 보상은 선택지와 편의 중심, 큰 능력치 보너스 금지 |

---

## 25. Codex에 전달할 첫 작업 요청문

아래 문장을 문서와 함께 첫 작업으로 전달한다.

> `UPDATE2_CONTRACTS_COUNTEROFFENSIVE_PLAN_2026-07-12.md`를 읽고 Phase 0만 수행하라. 1차 개발 완료 조건, 실제 저장 버전, 실제 엔딩 ID, 실제 신규 몬스터 ID와 구현 수준을 감사하고 `docs/HANDOFF_UPDATE2_BASELINE.md`에 기록하라. 기존 코드·데이터·그래픽 동작은 변경하지 말고 전체 검증과 기준 캡처만 남겨라. Phase 1 이상의 구현은 시작하지 말라.

---

## 26. 구현 대상

- 계약 게시판과 계약 몬스터 2종 선택
- 출전/예비 로스터
- 계약 몬스터 목표 카탈로그 5종
- 신규 일반 적 6종
- 에블린 보스
- 왕국 교리 총 6종
- 칙령 6종, 인장 6종
- 이벤트 15개, 웨이브 변형 12개
- 레온 적응 자세 4개
- 신규 엔딩 E07~E11
- 저장 v3와 전체 자동 검증

## 27. 데이터 구조

- 프로필 영구 해금과 현재 회차 선택을 분리한다.
- 모든 신규 콘텐츠는 ID 참조 기반 JSON으로 정의한다.
- 적 행동은 등록된 behavior ID만 사용한다.
- 엔딩은 기존 DSL과 metric registry를 확장한다.
- run seed로 콘텐츠 선택을 재현한다.
- threat는 편성 검증 지표이며 전투 중 자동 스케일 공식으로 사용하지 않는다.

## 28. UI에 표시할 정보

- 계약 해금 출처와 역할
- 출전/예비 상태
- 교리·칙령·인장 요약
- 신규 적 카운터 정보
- 상태 상한 관련 툴팁
- 종별 기여와 구조/지원 지표
- 레온 대응형과 약점
- 신규 엔딩 방향과 획득 당시 편성

## 29. Codex에 넘길 JSON 예시

- 16.3 몬스터 예시
- 16.4 적 예시
- 16.5 웨이브 변형 예시
- 16.6 엔딩 예시

실제 구현에서는 스키마 validator를 먼저 만든 뒤 전체 데이터를 작성한다.

## 30. 최종 완료 조건

이 업데이트가 끝났다고 판단하려면 플레이어가 최소 세 번의 새 회차에서 서로 다른 계약 몬스터, 왕국 교리, 사건, 레온 자세, 엔딩을 경험할 수 있어야 한다. 단순히 적 HP가 높아진 같은 캠페인이면 완료가 아니다.

## 31. 확장판 후보

2차 업데이트 안정화 뒤에만 검토한다.

- 계약 몬스터의 2갈래 진화
- 희귀 몬스터 2종
- 신규 방 2~3종
- 진화 촉매 정식화
- 적 네임드 2명 추가
- 진화 2단계
- 몬스터 생활 장면
- 융합 연구소

## 32. 결정 로그

구현 중 변경되는 모든 수치·ID·범위는 `docs/DECISION_LOG_UPDATE2_CONTRACTS_COUNTEROFFENSIVE.md`에 날짜, 근거, 테스트 결과와 함께 기록한다. 한 번 통과한 범위를 이유 없이 확대하지 않는다.
