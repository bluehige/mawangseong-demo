# 의회 시즌 — 1층 부지 확장 서사 수정 제안서

## 1. 요약

**권장 방향: 성이 높아지는 이야기 대신, 함께 지킬 땅이 넓어지는 이야기로 바꾼다.** 성 등급 상승으로 동굴 암반을 파내 1층 새 구역을 열고, 그곳의 인장 금고·왕관실을 기존 왕좌실과 함께 지킨다. 의회는 안전 규정·공사 예산·인장 감사로 확장을 감시하고 압박한다. 세 경쟁 마왕은 기존 성격과 관계에 따라 공사를 지원하거나 시험한다. 지역 선택, 전초기지 두 차례 방어, 세 차례 표결, DAY23 왕관 진화, DAY25·30 결투의 순서는 유지한다.

- 상태: **사용자 확인용 제안, 제품 미적용**. 출시 목표 **1.3.0**, 내부 작업 이름은 **맵 2.0**.
- 적용 시점: 맵 계획 **M3(자유 배치 UI·첫날 튜토리얼) 이후**. 부지 해금과 저장 변환은 M6와 함께 완성하며 1.3.0 출시 전에 반영한다.
- 확정 배경: [맵 계획 8절](V20_MAP_BUILDER_PLAN_2026-10-14.md#8-사용자-확정-사항-2026-10-14)의 1층 전용, 시작 30×20·성 등급마다 가로 +6칸, 길 폭 2칸, 기존 배치 자동 변환. 이 값은 새 결정 대상이 아니다.
- 이번 세션은 이 문서만 변경한다. 코드·데이터·대사·CURRENT·별도 핸드오프는 수정하지 않는다. Godot 실행, 이미지 생성, 빌드, 푸시는 하지 않는다.

### 조사 기준과 한계

작성일 2026-10-14. 선택 작업트리 `mawangseong-action`, 브랜치 `codex/v1213-fix-plan`, 조사 기준 HEAD `71587de4f6d238a68190a22be5a7a22b6461f0f5`. 저장된 `origin/main`은 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`, 불변 `v1.2.5`는 `f757ffa9f9e962158f2123856c8568a3163ecb6c`이다. 로컬 `main`은 없어 `git show main:...`가 실패했다. 대신 `origin/main:AGENTS.md`·`origin/main:docs/handoff/CURRENT.md`를 읽었으며, 이번 원격 조회·fetch는 하지 않아 최신 권위를 확정하지 않는다. 최신 로컬 작업 기록인 `docs/handoff/CURRENT.md` 첫 항목과 `V1213_U5F_SETTINGS_2026-10-14.md`는 진행 경위 참고로만 읽었다. 활성 범위는 이번 사용자 지시와 맵 계획 8절에 따른다.

`council_campaign_days.json` **30항목 전체**, `council_endings.json` **6엔딩 전체**를 읽었다. 날짜 데이터에는 제목·이야기 비트(그날의 핵심 사건)·전투 종류·기능 플래그만 있고, **날짜별 의회 대화 본문은 없다**. 따라서 아래 ‘기존 대사 요지’는 실제 편지·왕관 사건이 있으면 그 키를 표시하고, 없으면 비트만 있는 원문이라고 명시한다. 새 대사는 전부 제안 초안이며 기존 대사를 인용한 것으로 취급하지 않는다. `data/story/v122_main/`의 기본 캠페인 대사를 의회 시즌 원문으로 옮겨 해석하지 않는다.

검색은 선택 작업트리 안에서 `rg -n -i '상층|2층|upper|floor|두 층'`를 기본으로 수행하고, `층간|층 전|층 이동|계단|1F|2F` 및 중국어 `上层|二层|两层|楼层|楼梯|2层`를 추가했다. `tmp/`, `output/`, `builds/`, `web_Demo/`, `docs/handoff/archive/`와 다른 연결 작업트리는 제외했다. 출처·키의 상세 목록은 4절에 둔다. 바닥 타일·수학적 내림 함수 등 검색 오탐은 서사 수정 대상에서 구분한다.

### 30일 전체 줄거리와 상층의 원래 역할

| 구간 | 원문 흐름 | 상층과의 관계 및 1층 대체 방향 |
|---|---|---|
| DAY1–3 | 의회 초청·회차 규칙, 계승 전력·심장 점검, 브라사·베스퍼·미렐라 소개 | 경쟁과 심사의 출발. 아직 새 구역을 열지 않는다. |
| DAY4–10 | 첫 지역·전초기지 선택, 환경·사건 해결, 파견·안건·습격 예고, 첫 방어 결산 | 성 밖 책임을 학습한다. 공사 정찰·암반 조사 정도만 연결하며 새 공사 전투를 추가하지 않는다. |
| DAY11–14 | 두 번째 지역, 전초기지 Lv.2, 첫 표결, 라이벌 지원/방해 | DAY13 예산 상한·안전 규정이 이후 공사에 영향을 주는 정치적 연결점이다. DAY14 개입의 우호/적대 분기를 유지한다. |
| DAY15–18 | 상층 공사와 왕관 진화 예고 → 상층 배치 선택 → 인장 금고 방어 → 왕관실·층 전환 학습 | 왕좌 외 보조 목표가 생겨 위협이 분산되고 지원 이동을 배운다. 같은 기능을 1층 기존 구역↔확장 구역의 이동·연결 방어로 대체한다. |
| DAY19–23 | 두 번째 습격 예고·대리인 결투, 세 번째 지역, 두 번째 표결, 왕관 진화 또는 인장 대체 | 외부 책임과 내부 성장의 교차. 확장 구역을 왕관 준비 공간으로 쓰되 진화 선택을 강제하지 않는다. |
| DAY24–28 | 최종 대표·지원 세력 공개, 대표 첫 형태 결투, 마지막 표결, 상층 종합 시험, 마지막 지역 작전 | 최종 시설을 지키며 누적 선택이 최종전에 연결된다. 감사와 시설 방어를 확장 구역에 옮긴다. |
| DAY29–30 | 관계·지역·전초기지·상층 회수, 최종 선언과 준비, 의회 왕관 심사·최종전·엔딩 | 두 전선의 협력을 회수한다. 두 층의 통합 지휘 대신 넓어진 한 성의 공동 방어를 결말로 삼는다. |

원문에서 상층의 역할은 **① 중반 위협 고조 ② 의회 인장과 예산 압박 ③ 왕관 성장의 시설 기반 ④ 분산 방어·구조·지원 학습 ⑤ E18의 공동 승리 증명**이다. 이것은 데이터와 서비스 연결에서 읽은 해석이며, ‘의회가 공사를 직접 방해한다’는 구체적인 대사는 이번 제안에서 새로 보강한다. 모든 적대 행위를 의회 음모로 단정하지 않고, 합법적 심사·라이벌의 경쟁·인장 절도를 구분한다.

### 개연성 규칙

1. 성 등급 상승이 부지 확장의 원인이다. DAY15는 다음 등급 확장 계획과 시설 사용 예고, DAY16은 공사 검수·왕관실/금고 사용 개시다. DAY16 자체가 등급과 무관하게 땅을 무료로 주는 사건이 되지 않게 한다.
2. DAY16 전에 등급을 달성했다면 이미 열린 부지에 시설만 개방한다. 등급이 부족하면 기존 1층의 가용 부지에 보조 목표를 임시 설치하여 날짜 진행을 막지 않는 방식을 권장한다. 부지 부족 시 안전 배치 정책은 **결정 필요**이며, 새 등급 요구치나 추가 면적을 임의로 정하지 않는다.
3. DAY5 편지의 ‘이미 있는 상층 주소/계단’은 ‘현재 본성 통로/앞으로 조사할 암반 가장자리’로 고친다. DAY16 확장 완료를 DAY5로 앞당기지 않는다.
4. 왕관실은 왕관을 준비·보관하는 공간이다. DAY23 진화 또는 인장 대체 선택은 유지한다. 왕관실 손상·인장 절도는 보조 목표 실패이며 왕좌 패배로 자동 승격하지 않는다.
5. 자유 배치를 유지한다. 기존 구역과 확장 구역은 부지 해금 이력으로 구분하고 통로는 자동 연결한다. 상층 배치 3종을 선택·영구 잠금하는 절차는 없앤다. 필요하면 3종은 선택 사항인 추천 배치 설명으로만 재활용한다.

## 2. 날짜별 수정안

**공통 번역 상태: 모든 신규·수정 대사, 제목, 비트는 ko 초안이며 en/zh_CN 번역 필요.** 원문 그대로 유지하는 날짜는 번역을 새로 쓰지 않는다. 표의 등장인물 대사는 새 연결 설명의 후보이며 실제 화자 등록·대화 연결 방식은 구현 단계에서 확인한다. 우호/적대 관계 수치와 선택지를 추가하거나 바꾸지 않는다.

| DAY/원문 키 | 기존 제목·이야기 비트 | 기존 대사 요지·출처 | 수정 제목·비트·ko 대사 초안 |
|---|---|---|---|
| 01 / `council_day_01` | **마계 의회 초청장**<br>회차 규칙 확인 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **마계 의회 초청장**<br>회차 규칙 확인<br>마왕: “초청에 응하겠다. 우리 성을 지키는 약속까지 넘기지는 않겠어.” |
| 02 / `council_day_02` | **계약 로스터와 심장 확인**<br>기존 계승 전력 확인 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **계약 로스터와 심장 확인**<br>기존 계승 전력 확인<br>마왕: “심장과 동료부터 확인하자. 넓힐 성도 이 전력으로 지킨다.” |
| 03 / `council_day_03` | **세 경쟁 마왕**<br>브라사·베스퍼·미렐라 첫 소개 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **세 경쟁 마왕**<br>브라사·베스퍼·미렐라 첫 소개<br>브라사: “규격부터 보지.” 베스퍼: “배송 경로도요.” 미렐라: “사는 아이들을 먼저 볼게요.” |
| 04 / `council_day_04` | **첫 지역과 전초기지**<br>첫 지역·전초기지 유형 확정 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **첫 지역과 전초기지**<br>첫 지역·전초기지 유형 확정<br>마왕: “밖에 세울 보루와 안에 지킬 성을 함께 생각하자.” |
| 05 / `council_day_05` | **첫 지역 환경 학습**<br>선택 지역 규칙 소개 | 비트만 있음; 날짜별 의회 대사 본문 없음. 보조 편지 `letter_brassa_day05`(계단 검사), `letter_vesper_day05`(상층 주소), `letter_mirella_day05`(계단 이끼)의 `body`. | **첫 지역 환경 학습**<br>선택 지역 규칙 소개; 본성 통로와 암반 조사 예고<br>베스퍼 편지는 본성 동쪽 통로 주소로, 미렐라 편지는 나중에 넓힐 암반 가장자리로 수정(아래 원문 키 참조). |
| 06 / `council_day_06` | **첫 지역 사건**<br>지역 사건 첫 해결 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **첫 지역 사건**<br>지역 사건 첫 해결<br>마왕: “선택한 지역의 규칙부터 익힌다. 새 공사 계획은 그 다음이다.” |
| 07 / `council_day_07` | **전초기지 파견**<br>파견 몬스터 선택 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **전초기지 파견**<br>파견 몬스터 선택<br>마왕: “밖의 경비와 본성의 경비가 서로 빈자리를 알아야 한다.” |
| 08 / `council_day_08` | **첫 의회 안건 예고**<br>안건 효과와 표결일 공개 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **첫 의회 안건 예고**<br>안건 효과와 표결일 공개; 공사 예산·안전 규정 연결<br>브라사: “성의 등급이 오르면 바위를 깰 수 있다. 하지만 버팀목 규격은 먼저 공개해라.” |
| 09 / `council_day_09` | **전초기지 습격 예고**<br>첫 습격 정찰 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **전초기지 습격 예고**<br>첫 습격 정찰<br>마왕: “먼저 오는 습격부터 막는다. 공사 계획 때문에 파견을 흔들지 말자.” |
| 10 / `council_day_10` | **전초기지 방어전 1**<br>첫 전초기지 결산 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **전초기지 방어전 1**<br>첫 전초기지 결산<br>마왕: “성 밖에서도 버텼다. 이 기록을 의회에 제출하자.” |
| 11 / `council_day_11` | **두 번째 지역**<br>두 번째 지역 선택 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **두 번째 지역**<br>두 번째 지역 선택<br>마왕: “다음 지역을 고른다. 공사 자재를 핑계로 선택을 바꾸지는 않겠다.” |
| 12 / `council_day_12` | **전초기지 Lv.2**<br>전초기지 강화 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **전초기지 Lv.2**<br>전초기지 강화; 본성 목표 진입 정찰 준비<br>마왕: “감시 둥지의 보고는 본성의 새 구역을 지킬 때도 쓰겠다.” 해당 유형 선택 시에만 노출. |
| 13 / `council_day_13` | **제1차 의회 표결**<br>첫 공개 표결 | 비트만 있음; 날짜별 의회 대사 본문 없음. `rival_letters.json / letter_brassa_day13.body`: 표결 뒤 시설 하중 공개 요구. | **제1차 의회 표결**<br>첫 공개 표결; 확장 공사에 적용될 규정 선택<br>브라사: “예산과 안전 규정은 넓힐 구역에도 적용된다.” 마왕: “규정은 논의하되 우리 등급의 성장을 허가제로 만들지는 않겠다.” |
| 14 / `council_day_14` | **경쟁 마왕 첫 개입**<br>라이벌 지원 또는 방해 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **경쟁 마왕 첫 개입**<br>라이벌 지원 또는 방해; 공사 점검/간섭으로 연결<br>우호: 마왕 “보강 의견은 받겠다.” 적대: 마왕 “검사 명목으로 길을 막아도 경비를 비우지는 않는다.” 실제 선택된 라이벌만 연결. |
| 15 / `council_day_15` | **상층 공사 예고**<br>2층과 왕관 진화 예고 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **부지 확장 공사 예고**<br>성 등급 확장으로 암반을 파낼 계획; 왕관실·금고·왕관 진화 예고<br>톡톡: “성 등급에 맞는 버팀목을 세우고 이 암반을 걷어 내겠다.” 마왕: “새 땅에 인장 금고와 왕관실을 마련한다. 왕관을 맡길지는 나중에 정한다.” |
| 16 / `council_day_16` | **2층 개방**<br>상층 레이아웃 선택 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **새 구역 시설 개방**<br>성 등급으로 열린 1층 구역 검수; 왕관실·금고 자유 배치와 자동 길 학습<br>톡톡: “넓어진 터의 길은 입구와 왕좌에 이어진다.” 마왕: “금고와 왕관실로 가는 길도 확인하자.” 미달/선달성 분기는 1절 정책대로 표현. |
| 17 / `council_day_17` | **인장 금고 압박**<br>상층 목표 첫 방어 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **인장 금고 압박**<br>확장 구역 보조 목표 첫 방어; 의회 기록을 노리는 절도<br>포포: “금고 쪽 봉인이 흔들려요!” 마왕: “왕좌 경비는 남기고 금고로 지원한다. 공사 기록과 인장을 지켜라.” 의회 직접 범행이라고 단정하지 않음. |
| 18 / `council_day_18` | **왕관실 압박**<br>층 전환 학습 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **왕관실 압박**<br>같은 1층의 본성·확장 구역 사이 지원 이동 학습<br>실키: “문턱은 제가 붙잡을게요. 다친 아이는 이 길로 돌아와요.” 마왕: “왕관실을 지키되 왕좌로 이어지는 길도 비우지 마라.” |
| 19 / `council_day_19` | **두 번째 습격 예고**<br>전초기지 2차 습격 예고 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **두 번째 습격 예고**<br>전초기지 2차 습격 예고; 내부 시설과 외부 경비 책임 병존<br>마왕: “새 구역이 생겼다고 성 밖의 동료를 잊지 않는다. 두 번째 습격에 대비하자.” |
| 20 / `council_day_20` | **전초기지 방어전 2**<br>경쟁 마왕 대리인 결투 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **전초기지 방어전 2**<br>경쟁 마왕 대리인 결투<br>마왕: “대표의 시험은 성 밖까지 왔다. 파견 동료가 지킨 약속부터 끝내자.” |
| 21 / `council_day_21` | **세 번째 지역**<br>마지막 지역 선택 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **세 번째 지역**<br>마지막 지역 선택<br>마왕: “마지막 지역을 고른다. 돌아오면 왕관과 최종 심사가 기다린다.” |
| 22 / `council_day_22` | **제2차 의회 표결**<br>두 번째 공개 표결 | 비트만 있음; 날짜별 의회 대사 본문 없음. `rival_letters.json / letter_vesper_day22.body`: 상층 창문 우회 요청. | **제2차 의회 표결**<br>두 번째 공개 표결; 배송·공방·검역의 확장 구역 적용<br>베스퍼: “새 구역 환기 통로로 표결 서신을 보낼 예정입니다.” 마왕: “배송 경로는 확인한다. 금고 봉인과 출입 기록은 따로 지켜라.” |
| 23 / `council_day_23` | **왕관 진화**<br>진화 또는 인장 대체 | 비트만 있음; 날짜별 의회 대사 본문 없음. `crown_events.json / crown_event_popo_grand_night_courier.scenes[0..2].text`: 정시 배송·위험한 층 지원·망토/환기구 농담. | **왕관 진화**<br>왕관 진화 또는 인장 대체; 확장 왕관실의 성장 회수<br>포포 선택 시: “성이 넓어져도 제시간에 닿게 할래요.” 마왕: “가장 위험한 방에 지원을 전해라.” 다른5형태 사건·진화 거절은 기존 흐름 유지. |
| 24 / `council_day_24` | **최종 대표 공개**<br>DAY 30 상대와 지원 세력 공개 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **최종 대표 공개**<br>DAY30 상대와 지원 세력 공개<br>마왕: “누가 시험하고 누가 돕는지 정해졌다. 새 구역까지 포함해 방어 준비를 맞춘다.” |
| 25 / `council_day_25` | **경쟁 마왕 정식 결투**<br>대표의 첫 형태 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **경쟁 마왕 정식 결투**<br>대표의 첫 형태<br>선택 대표의 기존 결투 편지 유지. 마왕: “검사표가 아니라 직접 부딪쳐 증명할 차례군.” |
| 26 / `council_day_26` | **최종 의회 안건**<br>마지막 공개 표결 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **최종 의회 안건**<br>마지막 공개 표결; 인장 감사·왕관 권리·자치·독립 선택 연결<br>마왕: “확장 구역의 인장과 왕관도 마지막 안건의 대상이다. 어느 약속을 지킬지 결정하겠다.” 의회 선택별 기존 효과 유지. |
| 27 / `council_day_27` | **상층 최종 시설**<br>Stage 04 상층 종합 시험 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **확장 구역 최종 시설**<br>Stage04 확장 구역 시설 종합 시험<br>톡톡: “마지막 보강은 끝났다. 왕관실과 금고, 연결 통로를 함께 확인해라.” 마왕: “시설 하나에 모든 경비를 몰지 않는다. 한 성 전체를 지켜라.” |
| 28 / `council_day_28` | **마지막 지역 작전**<br>최종전 선택 효과 예약 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **마지막 지역 작전**<br>최종전 선택 효과 예약<br>마왕: “지역 작전의 성과를 내일 준비에 반영한다. 새 공사 임무를 더하지는 않는다.” |
| 29 / `council_day_29` | **의회 전야**<br>관계·지역·전초기지·상층 회수 | 비트만 있음; 날짜별 의회 대사 본문 없음. `rival_letters.json / letter_{brassa,vesper,mirella}_day29.body`: 하중·특급 경로·왕관 주변 준비. | **의회 전야**<br>관계·지역·전초기지·확장 구역 회수와 최종 준비<br>마왕: “밖의 보루도 새로 연 터도 우리가 지켰다. 내일 왕관의 이름과 의회에 할 말을 정하자.” 기존 위임/전초 유지/독립 등 선언 분기 유지. |
| 30 / `council_day_30` | **마계 의회 왕관 심사**<br>경쟁 마왕 최종전과 엔딩 | 비트만 있음; 날짜별 의회 대사 본문 없음. | **마계 의회 왕관 심사**<br>경쟁 마왕 최종전과 1층 공동 방어 엔딩<br>마왕: “왕좌와 새 구역은 같은 길로 이어져 있다. 오늘의 승리는 함께 지킨 성의 이름으로 남긴다.” 선택 대표·지원 세력은 기존 분기 유지. |

### 핵심 날짜의 게임플레이 목표 대체

아래 새 식별자는 **제안 이름**이다. 현재 파일에 존재하거나 구현됐다는 뜻이 아니다. `encounter_kind`는 전투 종류, 기능 플래그는 그날 개방할 기능의 표시, 지표는 엔딩을 판정할 기록값이다. endpoint는 경로의 연결 지점을 뜻한다. `management_only`·`empty_wave`는 기존 값을 유지한다. 현재 `empty_wave: true`는 ‘전투 없음’으로 읽지 않는다. 서비스는 지역 템플릿으로 웨이브를 구성하며 날짜별 `encounter_kind`만 바꿔서는 실제 목표 공격이 연결되지 않는다.

| 날짜/키 | 기존 | 1층 대체안 | 유지 수치·구현 조건 |
|---|---|---|---|
| `council_day_15` | `stage_transition`; `upper_floor_preview`, `crown_preview` | 전투 종류 유지; `plot_expansion_preview`, `crown_preview` | 신규 웨이브·비용·공사 대기시간 추가 없음. 등급별 부지 확장 사실과 시설 준비 예고만 연결. |
| `council_day_16` | `upper_split`; `upper_floor_unlock`, `upper_layout_selection` | `expansion_opening`; `expansion_objective_unlock`, `expansion_placement_guidance` | 레이아웃 선택 대신 왕관실·인장 금고 자유 배치/자동 길 확인. 병영·감시·회복 역할 재사용. 계단 전이 최대2명은 부지 출전 제한으로 옮기지 않음. |
| `council_day_17` | `upper_objective`; `seal_vault_pressure` | `expansion_objective`; 인장 금고 접근·절도 중단 | 금고 경고3초·채널4초·전투당 손실 최대1회, 표5 우선 손실/부족 시 인장1 유지. 보조 실패이며 왕좌는 계속 방어. |
| `council_day_18` | `upper_transition`; `crown_sanctum_pressure` | `expansion_relay`; 왕관실 방어와 구역 간 지원 | 왕관실 기본HP600·Stage03 이후 단계당10% 증가·복구금화24 유지. 손상 시 해당 전투 왕관 기능 억제·다음 날 복구의 계약 유지. 층 탭 학습 대신 같은 화면에서 목표 확인→길로 지원. |
| `council_day_27` | `upper_final`; `upper_final_facility` | `expansion_final`; `expansion_final_facility` | Stage04 종합 시험. 왕관실·금고·활성 시설의 기존 압박을 같은 1층 길망에 연결. 적 수·체력·공격·보상 배율 유지. |
| `council_day_29` | `none`; 관계·지역·전초기지·상층 회수 | `none`; 관계·지역·전초기지·확장 구역 회수 | 관리 전용 유지. `relationship_recap`, `final_preparation` 및 기존 최종 선언 선택 유지. |
| `council_day_30` | `council_final`; 층별 결산 | 전투 종류 유지; 왕좌와 확장 시설의 공동 방어 결산 | 최종 대표/지원 선택 유지. E18 지표만 3절 기준으로 이동. |

난도 보존은 수치 복사만으로 완료되지 않는다. 1층 자동 길은 계단 대기·전환이 없어 도달 시간이 달라진다. 기존 적 수·지역 장별 위협 예산3.4/4.5/6.0, 모든 지역 템플릿의 `actual_threat`, 지역 배율, DAY25 보스 HP0.75·공격0.90·등장8초와 DAY30 HP1.0·공격1.0·등장6초는 그대로 시작한다. 부지별 거리·지원 도달 시간·목표 공격 타이밍을 나중에 표적 검증한다. 보정이 필요하면 **경로/등장 지점 우선, 새 이동·사거리·시간 수치는 결정 필요**로 분리한다. 미완료 다층 이동을 실제 제공했던 난도로 단정하지 않는다.

### 관련 편지·사건·설명의 ko 초안

| 출처 파일/키 | 원문 요지 | 수정 초안 또는 처리 |
|---|---|---|
| `rival_letters.json / letter_brassa_day05.body` | 계단 폭 합격, 난간 이음새 지적 | “네 성의 주 통로 폭은 합격이다. 다만 암반 가장자리 세 번째 버팀목은 전투 두 번을 버티기 어렵다. 도면에 붉은 선을 그어 두었으니 고쳐라.” |
| `rival_letters.json / letter_vesper_day05.body` | 상층 주소, 밤2시 이후 동쪽 계단 | “귀 성의 본성 주소를 확인했습니다. 밤 2시 이후에는 동쪽 통로가 가장 빠릅니다. 답장은 같은 봉인으로 보내 주세요.” |
| `rival_letters.json / letter_mirella_day05.subject, body, tone_keywords[0]` | 계단 이끼 관리법 | 제목 “암반 가장자리 이끼 관리법”. “나중에 넓힐 암반 가장자리의 이끼는 모두 걷지 않아도 괜찮아요. 통로 밖에 조금 남기면 발소리를 부드럽게 품어 줄 거예요.” 키워드 “통로”. |
| `rival_letters.json / letter_vesper_day22.body` | 북쪽 안개, 상층 창문 우회 | “안개로 북쪽 항로가 늦어집니다. 표결 서신은 확장 구역의 환기 통로를 경유하겠습니다. 거부 시 자정 전까지 회신 바랍니다.” |
| `bond_events.json / silky_crown_cover.text` | 상층 왕관 덮개·귀 치수 농담 | “실키는 새 왕관실의 왕관 덮개를 만들겠다며 후보들의 머리 둘레를 재기 시작했다. 포포는 귀까지 포함하면 반칙이라고 주장했다.” 유대80 유지. |
| `crown_events.json / crown_event_popo_grand_night_courier.scenes[0].text` | 어느 층이든 정시 배송 | 포포: “왕관은 무거워도 편지는 가벼워요. 성이 넓어져도 제시간에 닿게 할래요.” |
| 같은 사건 `scenes[1].text` | 위험한 층에 지원과 인장 반환 | 마왕: “네 역할은 가장 위험한 방에 지원을 제때 전하는 것이다.” 이미 승인된 다른 방 지원 구현과 일치시킨다. 인장 회수는 별도 기존 능력에서 설명. 실키의 망토/환기구 농담은 유지. |
| `council_agendas.json / agenda_budget_cap.cost` | 상층 시설 최대 레벨 제한 | “확장 구역 시설 최대 레벨 제한”. 같은 modifier가 부지 면적·등급 상승까지 막지 않게 함. 기존 수치 확인 후 유지. |
| `outpost_types.json / outpost_watch_nest.level_2_text` | 상층 목표 적 진입 위치 공개 | “확장 구역 목표를 노리는 적의 진입 위치 공개”. 본성 정찰 연결의 의미 유지. |
| `crown_evolutions.json / crown_toktok_royal_armorer.role` | 시설·상층 목표 응급 보강 | “시설·확장 구역 목표 응급 보강”. 기존 1층 수리 설명·수치 유지. |
| `monster_codex.json / codex_bat_courier.weaknesses[2]` | 혼자 남은 상층 | “지원 없이 홀로 남은 먼 방”. 낮은 체력·봉인/포획 약점 유지. |
| `monsters.json`, `monster_codex.json`, `specializations.json`의 층간/계단 역할 | 실키 제어·구조, 포포 중계 | “문턱·연결 통로 제어”, “구역 간 기동·위험 예고·인장 회수”, “구역 간 중계”. 전문화 제목 “계단 파수 재봉”→“통로 파수 재봉”. 강화·페널티 값 유지. |
| `enemies.json`, `regions.json`의 층 이동·계단 점유 | 기습·절도·길목 압박·뿌리 | “환기 통로 우회·인장 절도”, “시설 압박·연결 통로 점유”, “최근 기여 몬스터 추적·다른 방 기습”, “문턱·연결 통로 뿌리 장벽”. |
| `skills.json / stitch_stairway.display_name, description` | 계단 꿰매기, 4명/4초/35% 둔화 | “통로 꿰매기”; “문턱 또는 연결 통로에 거미실을 설치해 처음 지나가는 적 4명을 4초 동안 35% 느리게 합니다.” |
| `skills.json / ceiling_path.description` | 층 전이40% 가속·계단 큐 아군 충돌 무시 | 제안: “안전한 연결 통로의 중계 이동이 40% 빨라지고, 좁은 길목에서 아군에 막히지 않습니다.” **결정 필요**: 기존0.60 전이 배율을 실제 이동속도40% 증가로 오역하지 말 것. 지원 이동에만 같은 시간 배율을 적용할지, 기능 폐기/대체할지 확인. |
| `skills.json / air_shortcut.description, deadline_dive.description` | 환기구/계단 endpoint로 다른 층 진입 | “연결된 환기 통로로 다른 방에 우회 진입하며 왕좌로 직접 순간이동하지 않습니다.” / “연결 통로의 진입점을 거쳐 다른 방으로 급강하하고 도착 지점에 짧은 침묵을 남깁니다.” 우회 경로 검증 필요. |
| `skills.json / root_threshold.description` | 계단 또는 문턱6초 장벽 | “문턱이나 연결 통로에 6초 뿌리 장벽을 하나 만들며 피해 또는 정화로 제거할 수 있습니다.” |
| `skills.json / shadow_promise.description, royal_shared_umbrella.description` | 같은 층 대상 | 대상 범위는 실제 1층 런타임을 확인한 뒤 “1층의 유효 아군/목표”로 명시. 전투당1회·2초 및 모리5초/초당HP3/HP1 방지/6초 회복-15% 유지. 구역 경계로 효과 범위를 임의로 줄이지 않는다. |
| `skills.json / night_relay.description, royal_emergency_plating.description, royal_urgent_courier.description` | 이미 1층/다른 위험 방 설계 | 현재 ko 설명과 수치 유지. 번역 카탈로그의 구 ‘다른 층’ 설명을 새 원문과 대조·정리한다. |

## 3. E18 엔딩 대체안

### 원문 확인

출처: `data/regular_version/update4/council_endings.json / ending_two_floors_one_throne`.

- 이름 **두 층, 하나의 왕좌**, 코드 **E18**, priority **180**, base_score **18000**, fallback **false**, score_weights **{}**.
- 표지 문구: “계단은 전선이 아니라 서로를 살린 기록이 되었다.”
- 본문: “왕관실과 왕좌실의 경보가 동시에 꺼지자 두 층의 몬스터들이 계단 한가운데서 만났다.” / “누가 더 오래 버텼는지 다투던 기록표에는 결국 한 성의 승리라고 적혔다.” / “마왕성은 높아졌지만 지휘는 갈라지지 않았다.”
- 일러스트·썸네일 모두 `res://assets/ui/endings/update4/ending_two_floors_one_throne.png`.
- 보상 `cosmetic_upper_floor_epilogue_layout`, `chronicle_floor_detail`.

| 기존 필수 조건(모두 충족) | 값 | 대체안 A: 넓어진 땅, 하나의 왕좌 | 대체안 B: 바위를 넘어, 함께 지킨 성 |
|---|---|---|---|
| `update4.final_battle_won` | `== true` | 유지 | 유지 |
| `update4.upper_floor_integrity` | `>= 80` | `update4.expansion_facility_integrity >= 80` | 같은 조건 |
| `update4.crown_room_disable_count_since_day16` | `== 0` | 이름·DAY16 기준 유지, 1층 왕관실 기록에서 산출 | 같은 조건 |
| `update4.seal_theft_completed` | `== 0` | 유지, 1층 금고 절도 기록에서 산출 | 같은 조건 |
| `update4.day30_upper_floor_contribution_ratio` | `>= 0.25` | `update4.day30_expansion_survivor_ratio >= 0.25` | `update4.day30_expansion_contribution_ratio >= 0.25` |
| `update4.day30_lower_survivor_count` | `>= 1` | `update4.day30_original_zone_survivor_count >= 1` | 같은 조건 |
| `update4.day30_upper_survivor_count` | `>= 1` | `update4.day30_expansion_zone_survivor_count >= 1` | 같은 조건 |

**권장안 A**는 원래의 생존자 분산 판정을 보존한다. 실제 `_finalize_update4_council_ending()`은 이름과 달리 상층 기여율을 `상층 생존자 / max(1, 양층 생존자 합)`으로 계산한다. A는 이를 **확장 구역 담당 생존자 비율**로 명확히 이름 붙인다. DAY30 출전 시 담당 구역을 기록하고 이후 지원 이동과 무관하게 그 기준으로 결산하는 방식을 권장한다. 마지막 위치만 세면 승리 직전 이동으로 조건이 달라지므로 담당 기준은 사용자 결정 후 고정한다. 분모0은0으로 처리한다.

`expansion_facility_integrity`는 이름은 시설 보전 지표지만 **기존 계산과 같이 왕관실 잔여HP/최대HP×100**으로 우선 정의할 것을 권장한다. 금고는 별도 절도0 조건으로 보전 여부를 판정한다. 시설 평균·최솟값을 새로 쓰면 같은80이라도 난도가 바뀌므로 결정 필요다. ‘부지 확장만 완료하면80’처럼 자동 점수를 주지 않는다. 왕관실/금고가 실제 확장 부지에 없던 임시 배치 회차는 E18 확장 방어 실적으로 계산하지 않는 방식을 권장하되, 다른 엔딩·날짜 진행은 막지 않는다.

**대체안 B**는 실제 확장 구역 담당자의 피해·피해 흡수·시설 기여 합을 전체 유효 기여 합으로 나눈 지표를 새로 만든다. 0.25는 기존 문턱을 유지한 후보 값일 뿐, 생존비와 실제 기여율이 동등한 난도라는 근거는 없다. 현재 기여 기록은 종별로 합쳐지는 부분이 있어, 개체/담당 구역별 중복 없는 집계가 먼저 필요하다. 새로운 가중치가 필요하면 **결정 필요**. 넓어진 성의 협력은 더 직접 보여 주지만 1.3.0 작업량과 밸런스 검증 부담이 증가한다.

### 문구와 그림 비교

| 항목 | A — 넓어진 땅, 하나의 왕좌 **(권장)** | B — 바위를 넘어, 함께 지킨 성 |
|---|---|---|
| 표지 문구 | “새로 낸 길은 서로를 살린 기록이 되었다.” | “깨어낸 바위보다 단단했던 것은 서로를 믿는 마음이었다.” |
| 본문1 | “왕관실과 왕좌실의 경보가 함께 꺼지자, 새 구역과 본성의 몬스터들이 연결 통로에서 만났다.” | “공사 도면에 남은 붉은 선마다 누군가 버텼고, 누군가 제때 달려왔다.” |
| 본문2 | “누가 더 오래 버텼는지 다투던 기록표에는 결국 한 성의 승리라고 적혔다.” | “의회가 요구한 마지막 검사표에는 시설의 이름 옆으로 동료들의 이름이 이어졌다.” |
| 본문3 | “마왕성의 터는 넓어졌고, 그 위의 명령은 하나로 이어졌다.” | “몬스터들은 더 넓어진 동굴에 집을 지었고, 하나의 왕좌 아래 서로의 자리를 지켰다.” |
| 그림 재사용 | **원본 그대로는 비권장** | **원본 그대로는 비권장** |
| 이유 | 기존 PNG를 직접 열어 확인: 왕좌가 있는 하단과 왕관·금고가 있는 상단을 중앙 긴 계단으로 나눈 명확한 두 층 구도다. 1층 확장 설명과 충돌한다. | 동일. 단순 제목 변경으로 공간 구도가 바뀌지 않는다. |
| 가능한 후속 처리 | 같은 PNG의 하단 왕좌·몬스터만 자른 부분 재사용 후보는 있으나, 왕관실/금고·통로 협력 의미가 빠지고 썸네일도 재검토해야 한다. **미승인·미편집**. 최종 권장: 1층 공동 방어 구도로 별도 그림 제작 승인 후 교체. | 공사 도면/버팀목/함께 복구하는 동료의 새 그림이 더 적합. 비용·제작은 별도 승인 범위. |

양안 모두 E18·priority180·base_score18000·다른 엔딩과의 우선순위를 유지한다. 저장 호환을 위해 내부 `ending_two_floors_one_throne` ID를 당분간 남기고 **표시 이름·조건·본문·보상 기능을 변경**하는 방식을 권장한다. 내부 ID의 역사적 이름은 플레이어 문구에 노출하지 않는다. 새 ID로 바꾸려면 구 ID→새 ID 및 E18 도감 기록의 변환이 필요하다.

보상은 2층 후일담 배치 대신 **확장 구역 후일담 장식/추천 배치**와 **구역별 공동 방어 연대기 상세**로 바꾼다. 후보 ID `cosmetic_expansion_epilogue_layout`, `chronicle_zone_detail`. 기존 보상 보유자는 동등한 새 해금을 받도록 변환하되, 옛 상층 런타임·큐·층 위치를 새 구역 실적으로 그대로 재사용하지 않는다. 과거 E18 해금/날짜/프로필 기록은 보존한다.

## 4. 영향 받는 파일·키와 구현 순서

### 처리 범위

아래는 **나중에 구현할 영향 목록**이다. 이번 변경 파일은 이 제안서 하나뿐이다. 데이터 JSON 경로는 객체 키를 점으로, 배열을 `[번호]`로 표시한다. 번역 JSON은 한국어 원문 자체가 사전 키이므로 원문 전체를 적는다. 코드는 함수·상수와 검색 일치 행을 표시하여 추적 가능하게 한다.

| 묶음 | 구현 시 처리 |
|---|---|
| 30일 일정 | 날짜/필수 필드/관리 전용일 유지. DAY15–18·27·29 중심으로 문구·전투 종류·플래그 교체. DAY13·14·22·23·26·30 연결 설명 보강. |
| 편지·유대·왕관 사건 | 위 초안 반영. 편지 개방일·유대 문턱·사건 기억ID·관계 변화 유지. `rival_events.json`은 현재 `{}`이므로 기존 대화가 있다고 가정하지 않는다. |
| 엔딩·지표·보상·연대기 | E18 조건 생산자와 소비자를 함께 수정. 과거 해금 보존, 새 회차의 층별 기록→담당 구역 기록. 접근성 층 키/숨은 층 요약 제거 또는 구역 경보로 명시적 이전. |
| 레이아웃·모듈·세이브 | `upper_floor_layouts.json`과 다층 화면/그래프 연결 제거. `upper_floor_modules.json`의 왕관실·금고·허용시설 역할/수치를 1층 카탈로그로 이관한 뒤 층 전용 모듈 폐기. 파일부터 삭제하여 보조 목표 자체가 없어지지 않게 함. |
| 웨이브·지역·적·전초기지 | `floor_pattern`을 같은 1층 목표 패턴으로 옮김. `lower_focus`→왕좌 집중, `facility_then_stair`→시설 후 연결 통로, `delayed_upper`→지연 확장 진입, `alternating_floors`→구역 교대, `cross_floor_objectives`→구역 분산 목표, `two_floor_garden`→분산 정원, `cross_floor_exchange`→금고/왕좌 교차 압박. 기존 지역/적 구성·장별 수치는 유지. |
| 스킬·도감·전문화 | 계단/층 전이→같은 1층 연결 통로/다른 방. 이미 승인된 포포·톡톡의 1층 런타임을 역행시키지 않음. 삭제되는 큐/전이 기능은 단어만 바꾸지 말고 대체 기능 확인. |
| 번역·UI·튜토리얼 | ko 원문 변경과 en/zh_CN 새 키·번역 동시 준비. 삭제된 상층 탭/선택/설정 문구 제거. DAY16 학습을 목표 확인·자유 배치·자동 길·지원 이동으로 대체. M3 첫날 안내는 고정 위치 대신 실제 건물/연결 상태를 참조. |
| 자산·오디오 | 왕관 받침·금고 상태 그림의 1층 재사용 후보와 계단/층전환 아이콘 폐기 대상을 분리. 원본 출처는 보존. `update4.floor_intrusion.alarm`·`hud.floor.alert`는 구역 목표 경보 재사용 후보, 음원 신규 생성 불필요. E18 그림 교체는 별도 승인. |

### 전체 출처 색인

색인 집계: **73개 출처 파일**(데이터·번역 29개, 코드·씬 43개, 카탈로그 설명 문서1개). JSON 129개를 파싱하여 검색했으며, 해당 파일만 아래에 나열했다. 추가 조사 기준은 맵 계획·정책·CURRENT·최근 U5-F 인계와 E18 PNG 직접 확인이다. 이 숫자는 고유 파일 수이며 언어별 동일 문구를 별도 파일로 센다. 색인은 검색 오탐도 추적용으로 포함하며, 실제 변경 범위는 위 처리표와 아래 제외 설명으로 구분한다.

#### 4-A. 데이터와 ko/en/zh_CN 원문 키

<details>

<summary>data/audio/audio_event_catalog.json — 6개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `assets[35].events[0]` | update4.floor_intrusion.alarm |
| `assets[38].events[0]` | update4.skill.stitch_stairway |
| `events[63].id` | update4.floor_intrusion.alarm |
| `events[63].owner` | scenes/ui/hud/MultiFloorHUD.gd |
| `events[63].locator` | push_hidden_floor_alert |
| `events[64].id` | update4.skill.stitch_stairway |

</details>

<details>

<summary>data/ending_rules.json — 1개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `impregnable_demon_citadel.lines[0]` | 수없이 두드린 성문과 왕좌는 끝내 무너지지 않았다. 침입 기록에는 실패 도장만 층층이 쌓였다. |

</details>

<details>

<summary>data/localization/ui_en.json — 107개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `messages.조합 threat %.2f가 상한 %.2f 초과` | Lineup threat %.2f exceeds the cap of %.2f |
| `messages.전투 속도 x%.1f.` | Battle speed x%.1f. |
| `messages.상층 레이아웃을 확정하지 못했습니다.` | Failed to confirm the upper-floor layout. |
| `messages.상층 레이아웃 확정: %s` | Upper-floor layout confirmed: %s |
| `messages.DAY %d 전투 전에 상층 레이아웃을 확정하세요.` | Confirm the upper-floor layout before the DAY %d battle. |
| `messages.체력 %d / 몬스터 %d명 배치. 내부 초당 %.1f, 배치 아군이 인접 방에서 싸울 때 초당 %.1f 회복합니다.` | HP %d / %d monster slots. Heals %.1f per second inside, or %.1f per second when assigned allies fight in adjacent rooms. |
| `messages.회복 +%.1f/초` | Healing +%.1f/s |
| `messages.%s: 내부 초당 %.1f·인접 방 초당 %.1f 회복` | %s: Heals %.1f/s inside and %.1f/s in adjacent rooms |
| `messages.상층 왕성` | Upper Royal Castle |
| `messages.부채 표식 때문에 심장 액티브가 %.1f초 잠겼습니다.` | Debt Mark has locked the heart's active ability for %.1f seconds. |
| `messages.거미실을 설치할 계단·문턱·퇴각 통로가 없습니다.` | No stairs, thresholds, or retreat passages available for spider silk. |
| `messages.상층 계단참` | Upper Landing |
| `messages.상층 목표 fixture` | Upper-Floor Objective fixture |
| `messages.계단 endpoint 방이 없습니다.` | No stair endpoint room. |
| `messages.유닛이 계단 endpoint에 있지 않습니다.` | The unit is not at a stair endpoint. |
| `messages.같은 방향 계단 전이 큐는 최대 2명입니다.` | The stair transfer queue allows up to 2 units in the same direction. |
| `messages.상층이 아직 해금되지 않았습니다.` | The upper floor is not unlocked yet. |
| `messages.이번 회차의 상층 레이아웃은 이미 확정되었습니다.` | The upper-floor layout for this run is already confirmed. |
| `messages.등록되지 않은 상층 레이아웃입니다.` | Unregistered upper-floor layout. |
| `messages.상층에는 병영·감시초소·회복 시설만 설치할 수 있습니다.` | Only Barracks, Watch Posts, and healing facilities can be built on the upper floor. |
| `messages.층 경보 소리 크기는 0~1이어야 합니다.` | Floor alert volume must be 0~1. |
| `messages.층 전환 키 설정이 올바르지 않습니다.` | Invalid floor-switching key setting. |
| `messages.상층 상태 형식이 올바르지 않습니다.` | Invalid upper-floor state format. |
| `messages.DAY 16 이전에는 상층을 해금할 수 없습니다.` | The upper floor cannot be unlocked before DAY 16. |
| `messages.상층 목표 HP는 0 이상이어야 합니다.` | Upper-floor objective HP must be 0 or greater. |
| `messages.초당 %.1f 회복` | Heal %.1f per second |
| `messages.표시 층` | Displayed Floor |
| `messages.현재 활성화된 심장·합동기·상층 전력이 없습니다.` | No active Heart, combos, or upper-floor forces. |
| `messages.부채 표식 %.1f` | Debt Mark %.1f |
| `messages.정화 성가 %.1f` | Purifying Hymn %.1f |
| `messages.상층 배치·시설·왕관 목표를 관리합니다.` | Manage upper-floor placements, facilities, and crown objectives. |
| `messages.실키는 상층 왕관 덮개를 만들겠다며 후보들의 머리 둘레를 재기 시작했다. 포포는 귀까지 포함하면 반칙이라고 주장했다.` | Silky began measuring the candidates' heads to make a cover for the upper-floor crown. Popo insisted counting ears was cheating. |
| `messages.상층 시설 최대 레벨 제한` | Upper-floor facility level cap |
| `messages.상층 공사 예고` | Upper-Floor Construction Preview |
| `messages.2층과 왕관 진화 예고` | Preview the 2nd Floor and Crown Evolution |
| `messages.2층 개방` | 2nd Floor Unlocked |
| `messages.상층 레이아웃 선택` | Choose an Upper-Floor Layout |
| `messages.상층 목표 첫 방어` | First Upper-Floor Objective Defense |
| `messages.층 전환 학습` | Learn Floor Switching |
| `messages.상층 최종 시설` | Final Upper-Floor Facility |
| `messages.Stage 04 상층 종합 시험` | Stage 04 Upper-Floor Comprehensive Test |
| `messages.관계·지역·전초기지·상층 회수` | Revisit Relationships, Regions, Outpost, and Upper Floor |
| `messages.두 층, 하나의 왕좌` | Two Floors, One Throne |
| `messages.계단은 전선이 아니라 서로를 살린 기록이 되었다.` | The stairs became a record of saving one another, not a battlefront. |
| `messages.왕관실과 왕좌실의 경보가 동시에 꺼지자 두 층의 몬스터들이 계단 한가운데서 만났다.` | When the Crown Chamber and Throne Room alarms fell silent together, the monsters from both floors met halfway up the stairs. |
| `messages.왕관은 무거워도 편지는 가벼워요. 어느 층이든 제시간에 닿게 할래요.` | A crown may be heavy, but letters are light. I want to reach every floor on time. |
| `messages.네 역할은 가장 위험한 층에 지원과 인장을 함께 되돌려 놓는 것이다.` | Your role is to bring both support and the seal back to the floor in greatest danger. |
| `messages.시설·상층 목표 응급 보강` | Emergency Reinforcement for Facilities and Upper-Floor Objectives |
| `messages.층간 긴급 지원·인장 보호` | Emergency Support Between Floors · Seal Protection |
| `messages.공중 층 전이·인장 절도` | Aerial Floor Transfer · Seal Theft |
| `messages.시설 압박·계단 전이 큐 점유` | Facility Pressure · Occupies Stair Transfer Queue |
| `messages.최근 기여 몬스터 추적·층간 기습` | Tracks Recent Contributors · Ambushes Between Floors |
| `messages.문턱·계단 뿌리 장벽` | Root Barriers at Doorways and Stairs |
| `messages.계단·문턱 제어, 아군 구조 보조` | Stair and Doorway Control, Ally Rescue Support |
| `messages.층간 기동, 위험 예고, 인장 회수` | Mobility Between Floors, Threat Warnings, Seal Recovery |
| `messages.계단·문턱 제어와 저체력 아군 구조` | Stair and Doorway Control and Low-HP Ally Rescue |
| `messages.계단 전이 가속` | Faster Stair Transfers |
| `messages.넓은 단일층 방` | Large Single-Floor Rooms |
| `messages.층간 기동·위험 예고·인장 회수` | Mobility Between Floors · Threat Warnings · Seal Recovery |
| `messages.빠른 층 이동` | Fast Floor Movement |
| `messages.혼자 남은 상층` | Alone on the Upper Floor |
| `messages.상층 목표 적 진입 위치 공개` | Reveals entry points of enemies targeting upper-floor objectives |
| `messages.빠른 목표 전환 · 인장 절도 · 층 이동` | Fast Target Switching · Seal Theft · Floor Movement |
| `messages.네 성의 계단 폭은 합격이다. 다만 난간 세 번째 이음새는 전투 두 번을 버티기 어렵다. 도면에 붉은 선을 그어 두었으니 고쳐라.` | Your castle's stair width passes. The third railing joint, however, will struggle to survive two battles. I've marked it in red on the plans. Fix it. |
| `messages.귀 성의 상층 주소를 확인했습니다. 밤 2시 이후에는 동쪽 계단이 가장 빠릅니다. 답장은 같은 봉인으로 보내 주세요.` | We have confirmed your castle's upper-floor address. After 2 a.m., the eastern stairs are the fastest route. Please reply under the same seal. |
| `messages.안개로 북쪽 항로가 늦어집니다. 표결 서신은 상층 창문을 경유하겠습니다. 거부 시 자정 전까지 회신 바랍니다.` | Fog is delaying the northern air route. Voting correspondence will be routed through the upper-floor window. Please reply before midnight if you object. |
| `messages.계단 이끼 관리법` | How to Care for Stair Moss |
| `messages.상층 계단의 이끼는 모두 걷지 않아도 괜찮아요. 가장자리만 남기면 발소리를 부드럽게 품어 줄 거예요.` | You don't need to remove all the moss from the upper stairs. Leave some along the edges, and it will gently soften your footsteps. |
| `messages.계단` | Stairs |
| `messages.계단 꿰매기` | Stair Stitching |
| `messages.계단 또는 문턱에 거미실을 설치해 처음 지나가는 적 4명을 4초 동안 35% 느리게 합니다.` | Place webs on stairs or a doorway to slow the first 4 enemies passing through by 35% for 4 seconds. |
| `messages.층 전이가 40% 빨라지고 계단 전이 큐에서 아군 충돌을 무시합니다.` | Floor transfers are 40% faster, and allied collisions are ignored in the stair transfer queue. |
| `messages.1층의 다른 위험 방에 있는 아군에게 걸어가, 도착하면 둘 모두 5초 동안 빠르게 움직이고 공격합니다.` | Walk to an ally in another threatened room on the first floor. On arrival, both move and attack faster for 5 seconds. |
| `messages.환기 통로 endpoint로 층을 이동하지만 왕좌로 직접 순간이동하지 않습니다.` | Move between floors through a vent endpoint, without teleporting directly to the Throne. |
| `messages.전투당 한 번 같은 층의 최근 기여 대상 뒤로 이동해 2초 동안 공격이 강해지고 방어가 낮아집니다.` | Once per battle, move behind a recent contributor on the same floor, gaining attack but losing defense for 2 seconds. |
| `messages.문턱이나 계단에 6초 뿌리 장벽을 하나 만들며 피해 또는 정화로 제거할 수 있습니다.` | Create one root barrier at a doorway or stairway for 6 seconds. Damage or cleansing can remove it. |
| `messages.계단 endpoint를 거쳐 다른 층으로 급강하하고 도착 지점에 짧은 침묵을 남깁니다.` | Dive to another floor through a stair endpoint, leaving a brief silence effect at the landing point. |
| `messages.같은 층 아군 전체를 정화하고 5초 재생하며 한 명의 전투 불능을 HP 1로 막습니다.` | Cleanse all allies on the same floor, grant regeneration for 5 seconds, and prevent one ally's incapacitation at 1 HP. |
| `messages.1층에서 같은 방 또는 닿을 수 있는 가까운 손상 시설 중 HP 비율이 가장 낮은 시설을 최대 HP 30% 수리하고, 8초 동안 받는 피해를 30% 줄입니다.` | Among damaged first-floor facilities in the same room or within nearby reachable range, repair the one with the lowest HP ratio by up to 30% of max HP and reduce its incoming damage by 30% for 8 seconds. |
| `messages.다른 층 아군에게 0.20초 만에 이동해 6초 공격·이동·상태 저항을 지원합니다.` | Reach an ally on another floor in 0.20 seconds and boost attack, movement, and status resistance for 6 seconds. |
| `messages.계단 파수 재봉` | Stairwatch Stitching |
| `messages.계단 제어` | Stair Control |
| `messages.층간 중계` | Cross-Floor Relay |
| `messages.계단·왕관실·금고 사이 대응이 빠름` | Fast responses between stairs, Crown Chamber, and vault |
| `messages.상층 시설 슬롯` | Upper-Floor Facility Slot |
| `messages.수없이 두드린 성문과 왕좌는 끝내 무너지지 않았다. 침입 기록에는 실패 도장만 층층이 쌓였다.` | The gates and Throne endured countless blows and never fell. The invasion records filled with stamp after stamp of failure. |
| `messages.%04.1f / %04.1f초` | %04.1f / %04.1f sec |
| `messages.전투 시간  %.1f초   ·   깃발 HP  %d / %d` | Battle Time  %.1f sec   ·   Flag HP  %d / %d |
| `messages.%s · %.1f초` | %s · %.1f sec |
| `messages.⚠ 숨은 층 침입` | ⚠ Offscreen Floor Breached |
| `messages.직접 조종 계단 이동 시 자동 전환` | Auto-switch floors when using stairs in direct control |
| `messages.같은 층 시설 효과` | Facility effects on the same floor |
| `messages.단일 계단 endpoint` | Single staircase endpoint |
| `messages.전초기지·상층·왕관` | Outposts, Upper Floor, and Crowns |
| `messages.• %d회차 · %s %s<br>  지역 %s · 전초 %s/%s · 상층 %s<br>  대표 %s · 관계 %s<br>  왕관 %s · 인장 %d · 표 %d · 독립 %d<br>  DAY30 %.1f초 · 생존 1F %d/2F %d · 층 피해 %s` | • Run %d · %s %s<br>  Regions %s · Outpost %s/%s · Upper Floor %s<br>  Representative %s · Relations %s<br>  Crown %s · Seals %d · Votes %d · Independence %d<br>  DAY30 %.1f sec · Survivors 1F %d/2F %d · Floor Damage %s |
| `messages.숨은 층 전투 요약` | Offscreen Floor Battle Summary |
| `messages.층 경보 소리` | Floor Alarm Sounds |
| `messages.1층 전환` | Switch to Floor 1 |
| `messages.2층 전환` | Switch to Floor 2 |
| `messages.1층` | Floor 1 |
| `messages.2층` | Floor 2 |
| `messages.상층 방어 배치` | Upper Floor Defense Layout |
| `messages.1층과 2층이 출전 인원을 나눕니다. 배치와 실제 연결을 살펴본 뒤 확정하세요.` | Floors 1 and 2 share the available units. Review the layout and room connections before confirming. |
| `messages.고정 모듈 4개<br>계단 연결 1곳` | Fixed Modules: 4<br>Stair Connections: 1 |
| `messages.선은 실제 방 연결입니다.<br>1층 가시 복도에서 계단으로 진입합니다.` | Lines show actual room connections.<br>Enter the stairs from the Spike Corridor on Floor 1. |
| `messages.확정 전에는 배치가 바뀌지 않습니다. 확정한 상층 배치는 이번 회차 동안 유지됩니다.` | The layout will not change until you confirm. Your confirmed upper floor layout stays in place for this Run. |
| `supplemental_messages.내부 초당 %.1f, 배치 아군이 인접 방에서 싸울 때 초당 %.1f 회복합니다.` | Heals %.1f per second inside, or %.1f per second when assigned allies fight in adjacent rooms. |

</details>

<details>

<summary>data/localization/ui_zh_cn.json — 116개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `messages.조합 threat %.2f가 상한 %.2f 초과` | 组合威胁值 %.2f 超出上限 %.2f |
| `messages.셀렌 지휘: 진군 강화 %.1f초 · 지휘 %d회 · %s` | 瑟伦指挥：进军强化 %.1f 秒 · 指挥 %d 次 · %s |
| `messages.레온 기술: 용기의 외침 %d회 · 누적 %d명 강화 · %.1f초 유지` | 里昂技能：勇气呐喊 %d 次 · 累计强化 %d 名单位 · 持续 %.1f 秒 |
| `messages.%s이 %s에게 봉인 사슬을 예고합니다. %.1f초 안에 끊으세요!` | %s 准备对 %s 施放封印锁链。请在 %.1f 秒内打断！ |
| `messages.%s 부채 3중첩 폭주: 방 피해 %d · %.1f초 무력화%s.` | %s 债务叠至 3 层并失控：房间伤害 %d · 失效 %.1f 秒%s。 |
| `messages.레온 기술: 최후의 맹세 %d회 · 회복 %d · 방어막 %.1f초` | 里昂技能：最后的誓言 %d 次 · 恢复 %d · 屏障 %.1f 秒 |
| `messages.전투 시간: %.1f초 / 생존 몬스터: %d/%d` | 战斗时间：%.1f 秒 / 存活魔物：%d/%d |
| `messages.봉인 사슬 때문에 액티브 스킬을 사용할 수 없습니다. %.1f초 남았습니다.` | 封印锁链阻止了主动技能的使用。剩余 %.1f 秒。 |
| `messages.%s가 %s의 냄새를 %.1f초 동안 고정했습니다.` | %s 锁定了 %s 的气味，持续 %.1f 秒。 |
| `messages.톡톡의 갑각 돌진: %s에게 %d 피해, 방어력 -%d(%.1f초).` | 托克托克的甲壳冲锋：对 %s 造成 %d 点伤害，防御力 -%d（%.1f 秒）。 |
| `messages.전투 속도 x%.1f.` | 战斗速度 x%.1f。 |
| `messages.상층 레이아웃을 확정하지 못했습니다.` | 无法确定上层布局。 |
| `messages.상층 레이아웃 확정: %s` | 上层布局已确定：%s |
| `messages.전투 시간 %.1f초` | 战斗时间 %.1f 秒 |
| `messages.DAY %d 전투 전에 상층 레이아웃을 확정하세요.` | 请在 第%d天 战斗前确定上层布局。 |
| `messages.첫 등장 %+.1f초` | 首次出现 %+.1f 秒 |
| `messages.체력 %d / 몬스터 %d명 배치. 내부 초당 %.1f, 배치 아군이 인접 방에서 싸울 때 초당 %.1f 회복합니다.` | HP %d / 可部署 %d 名魔物。内部每秒恢复 %.1f，部署友军在相邻房间作战时每秒恢复 %.1f。 |
| `messages.무력화 %.1f초` | 失效 %.1f 秒 |
| `messages.회복 +%.1f/초` | 恢复 +%.1f/秒 |
| `messages.%s: 내부 초당 %.1f·인접 방 초당 %.1f 회복` | %s：内部每秒恢复%.1f，相邻房间每秒恢复%.1f |
| `messages.상층 왕성` | 上层王城 |
| `messages.거미실을 설치할 계단·문턱·퇴각 통로가 없습니다.` | 没有可布置蛛丝的楼梯、门槛或撤退通道。 |
| `messages.상층 계단참` | 上层楼梯平台 |
| `messages.상층 목표 fixture` | 上层目标fixture |
| `messages.계단 endpoint 방이 없습니다.` | 缺少楼梯endpoint房间。 |
| `messages.유닛이 계단 endpoint에 있지 않습니다.` | 单位不在楼梯endpoint。 |
| `messages.같은 방향 계단 전이 큐는 최대 2명입니다.` | 同方向楼梯转移队列最多容纳2名。 |
| `messages.상층이 아직 해금되지 않았습니다.` | 上层尚未解锁。 |
| `messages.이번 회차의 상층 레이아웃은 이미 확정되었습니다.` | 本周目的上层布局已确认。 |
| `messages.등록되지 않은 상층 레이아웃입니다.` | 未登记的上层布局。 |
| `messages.상층에는 병영·감시초소·회복 시설만 설치할 수 있습니다.` | 上层仅可设置兵营、瞭望哨与恢复设施。 |
| `messages.층 경보 소리 크기는 0~1이어야 합니다.` | 楼层警报音量必须处于0~1。 |
| `messages.층 전환 키 설정이 올바르지 않습니다.` | 楼层切换键设置无效。 |
| `messages.상층 상태 형식이 올바르지 않습니다.` | 上层状态格式无效。 |
| `messages.DAY 16 이전에는 상층을 해금할 수 없습니다.` | 第16天之前无法解锁上层。 |
| `messages.상층 목표 HP는 0 이상이어야 합니다.` | 上层目标HP必须至少为0。 |
| `messages.초당 %.1f 회복` | 每秒恢复%.1f |
| `messages.표시 층` | 显示楼层 |
| `messages.현재 활성화된 심장·합동기·상층 전력이 없습니다.` | 当前没有已激活的心脏、合击技或上层战力。 |
| `messages.부채 표식 %.1f` | 债务标记%.1f |
| `messages.정화 성가 %.1f` | 净化圣歌%.1f |
| `messages.상층 배치·시설·왕관 목표를 관리합니다.` | 管理上层部署、设施与王冠目标。 |
| `messages.%04.1f / %04.1f초` | %04.1f / %04.1f秒 |
| `messages.⚠ 숨은 층 침입` | ⚠ 未显示楼层遭到入侵 |
| `messages.직접 조종 계단 이동 시 자동 전환` | 直接操控单位使用楼梯时自动切换楼层 |
| `messages.같은 층 시설 효과` | 同楼层设施效果 |
| `messages.단일 계단 endpoint` | 单一楼梯endpoint |
| `messages.전초기지·상층·왕관` | 前哨站·上层·王冠 |
| `messages.• %d회차 · %s %s<br>  지역 %s · 전초 %s/%s · 상층 %s<br>  대표 %s · 관계 %s<br>  왕관 %s · 인장 %d · 표 %d · 독립 %d<br>  DAY30 %.1f초 · 생존 1F %d/2F %d · 층 피해 %s` | • 第%d周目 · %s %s<br>  地区%s · 前哨站%s/%s · 上层%s<br>  代表%s · 关系%s<br>  王冠%s · 印章%d · 票数%d · 独立度%d<br>  第30天 %.1f秒 · 存活1F %d/2F %d · 楼层伤害%s |
| `messages.숨은 층 전투 요약` | 未显示楼层战斗摘要 |
| `messages.층 경보 소리` | 楼层警报音 |
| `messages.1층 전환` | 切换至1层 |
| `messages.2층 전환` | 切换至2层 |
| `messages.1층` | 1层 |
| `messages.2층` | 2层 |
| `messages.상층 방어 배치` | 上层防御布局 |
| `messages.1층과 2층이 출전 인원을 나눕니다. 배치와 실제 연결을 살펴본 뒤 확정하세요.` | 1层与2层共用出战人数。请查看布局及实际连接后确认。 |
| `messages.고정 모듈 4개<br>계단 연결 1곳` | 固定模块4个<br>楼梯连接1处 |
| `messages.선은 실제 방 연결입니다.<br>1층 가시 복도에서 계단으로 진입합니다.` | 连线表示房间的实际连接。<br>从1层的尖刺走廊进入楼梯。 |
| `messages.확정 전에는 배치가 바뀌지 않습니다. 확정한 상층 배치는 이번 회차 동안 유지됩니다.` | 确认前布局不会改变。确认的上层布局将在本周目内保持不变。 |
| `messages.수없이 두드린 성문과 왕좌는 끝내 무너지지 않았다. 침입 기록에는 실패 도장만 층층이 쌓였다.` | 被无数次冲击的城门与王座，最终仍未倒下。入侵记录上，一层层堆满了失败印章。 |
| `messages.실키는 상층 왕관 덮개를 만들겠다며 후보들의 머리 둘레를 재기 시작했다. 포포는 귀까지 포함하면 반칙이라고 주장했다.` | 丝琪说要做上层王冠罩，开始测量候选者们的头围。波波坚称，把耳朵也算进去就是犯规。 |
| `messages.상층 시설 최대 레벨 제한` | 限制上层设施最高等级 |
| `messages.상층 공사 예고` | 上层施工预告 |
| `messages.2층과 왕관 진화 예고` | 预告2层与王冠进化 |
| `messages.2층 개방` | 开放2层 |
| `messages.상층 레이아웃 선택` | 选择上层布局 |
| `messages.상층 목표 첫 방어` | 首次守卫上层目标 |
| `messages.층 전환 학습` | 学习楼层切换 |
| `messages.상층 최종 시설` | 上层最终设施 |
| `messages.Stage 04 상층 종합 시험` | 第04阶段 上层综合测试 |
| `messages.관계·지역·전초기지·상층 회수` | 回顾关系·地区·前哨站·上层 |
| `messages.두 층, 하나의 왕좌` | 两层楼，一座王座 |
| `messages.계단은 전선이 아니라 서로를 살린 기록이 되었다.` | 楼梯成为互相救助的记录，而不再是战线。 |
| `messages.왕관실과 왕좌실의 경보가 동시에 꺼지자 두 층의 몬스터들이 계단 한가운데서 만났다.` | 王冠室与王座室的警报同时停下，两层楼的魔物们在楼梯中间相遇。 |
| `messages.왕관은 무거워도 편지는 가벼워요. 어느 층이든 제시간에 닿게 할래요.` | 王冠再重，信件也是轻的。我想不管哪一层，都能按时送到。 |
| `messages.네 역할은 가장 위험한 층에 지원과 인장을 함께 되돌려 놓는 것이다.` | 你的职责是把支援和印章一起送回最危险的楼层。 |
| `messages.시설·상층 목표 응급 보강` | 设施·上层目标紧急加固 |
| `messages.층간 긴급 지원·인장 보호` | 楼层间紧急支援·印章保护 |
| `messages.공중 층 전이·인장 절도` | 空中楼层转移·印章盗窃 |
| `messages.시설 압박·계단 전이 큐 점유` | 设施压制·占据楼梯转移队列 |
| `messages.최근 기여 몬스터 추적·층간 기습` | 追踪近期贡献魔物·跨层突袭 |
| `messages.문턱·계단 뿌리 장벽` | 门槛·楼梯树根屏障 |
| `messages.계단·문턱 제어와 저체력 아군 구조` | 控制楼梯·门槛，救援低 HP 伙伴 |
| `messages.계단 전이 가속` | 加速楼梯转移 |
| `messages.넓은 단일층 방` | 宽阔的单层房间 |
| `messages.층간 기동·위험 예고·인장 회수` | 跨层机动·危险预警·印章追回 |
| `messages.빠른 층 이동` | 快速跨层移动 |
| `messages.혼자 남은 상층` | 独自留在上层 |
| `messages.계단·문턱 제어, 아군 구조 보조` | 控制楼梯·门槛，辅助救援伙伴 |
| `messages.층간 기동, 위험 예고, 인장 회수` | 跨层机动、危险预警、印章追回 |
| `messages.상층 목표 적 진입 위치 공개` | 公开针对上层目标的敌人进入位置 |
| `messages.빠른 목표 전환 · 인장 절도 · 층 이동` | 快速切换目标·印章盗窃·楼层移动 |
| `messages.네 성의 계단 폭은 합격이다. 다만 난간 세 번째 이음새는 전투 두 번을 버티기 어렵다. 도면에 붉은 선을 그어 두었으니 고쳐라.` | 你城堡的楼梯宽度合格。不过栏杆第三处接头撑不住两场战斗。我在图纸上画了红线，修好它。 |
| `messages.귀 성의 상층 주소를 확인했습니다. 밤 2시 이후에는 동쪽 계단이 가장 빠릅니다. 답장은 같은 봉인으로 보내 주세요.` | 已确认贵城的上层地址。凌晨 2 点后，东侧楼梯是最快路线。回信请使用相同封印。 |
| `messages.안개로 북쪽 항로가 늦어집니다. 표결 서신은 상층 창문을 경유하겠습니다. 거부 시 자정 전까지 회신 바랍니다.` | 雾气导致北方航线延误。表决信件将经由上层窗户送达。若拒绝，请于午夜前回复。 |
| `messages.계단 이끼 관리법` | 楼梯苔藓养护法 |
| `messages.상층 계단의 이끼는 모두 걷지 않아도 괜찮아요. 가장자리만 남기면 발소리를 부드럽게 품어 줄 거예요.` | 上层楼梯的苔藓不用全部清除。只留边缘一些，它们就会温柔地缓和脚步声。 |
| `messages.계단` | 楼梯 |
| `messages.계단 꿰매기` | 缝补楼梯 |
| `messages.계단 또는 문턱에 거미실을 설치해 처음 지나가는 적 4명을 4초 동안 35% 느리게 합니다.` | 在楼梯或门槛布下蛛丝，使最先经过的 4 名敌人在 4 秒内减速 35%。 |
| `messages.층 전이가 40% 빨라지고 계단 전이 큐에서 아군 충돌을 무시합니다.` | 楼层转移速度提高 40%，在楼梯转移队列中忽略伙伴碰撞。 |
| `messages.1층의 다른 위험 방에 있는 아군에게 걸어가, 도착하면 둘 모두 5초 동안 빠르게 움직이고 공격합니다.` | 步行前往一楼另一处危险房间的伙伴身旁。到达后，两人在 5 秒内加速移动与攻击。 |
| `messages.환기 통로 endpoint로 층을 이동하지만 왕좌로 직접 순간이동하지 않습니다.` | 通过通风通道 endpoint 跨层移动，不会直接传送到王座。 |
| `messages.전투당 한 번 같은 층의 최근 기여 대상 뒤로 이동해 2초 동안 공격이 강해지고 방어가 낮아집니다.` | 每场战斗一次，移动到同层近期贡献目标的身后，2 秒内攻击增强、防御降低。 |
| `messages.문턱이나 계단에 6초 뿌리 장벽을 하나 만들며 피해 또는 정화로 제거할 수 있습니다.` | 在门槛或楼梯制造一道持续 6 秒的树根屏障，可用伤害或净化移除。 |
| `messages.계단 endpoint를 거쳐 다른 층으로 급강하하고 도착 지점에 짧은 침묵을 남깁니다.` | 经楼梯 endpoint 俯冲到另一楼层，在落点留下短暂沉默。 |
| `messages.같은 층 아군 전체를 정화하고 5초 재생하며 한 명의 전투 불능을 HP 1로 막습니다.` | 净化同层所有伙伴，使其再生 5 秒，并以 1 HP 阻止一名伙伴失去战斗能力。 |
| `messages.1층에서 같은 방 또는 닿을 수 있는 가까운 손상 시설 중 HP 비율이 가장 낮은 시설을 최대 HP 30% 수리하고, 8초 동안 받는 피해를 30% 줄입니다.` | 在同一房间或附近可达的一楼受损设施中，选择 HP 比例最低的设施，最多修复其最大 HP 的 30%，并在 8 秒内使其受到的伤害减少 30%。 |
| `messages.다른 층 아군에게 0.20초 만에 이동해 6초 공격·이동·상태 저항을 지원합니다.` | 在 0.20 秒内到达另一层伙伴身旁，提供 6 秒攻击·移动·状态抗性支援。 |
| `messages.계단 파수 재봉` | 楼梯守卫缝补 |
| `messages.계단 제어` | 楼梯控制 |
| `messages.층간 중계` | 跨层接力 |
| `messages.계단·왕관실·금고 사이 대응이 빠름` | 楼梯·王冠室·金库之间应对迅速 |
| `messages.상층 시설 슬롯` | 上层设施槽位 |
| `supplemental_messages.내부 초당 %.1f, 배치 아군이 인접 방에서 싸울 때 초당 %.1f 회복합니다.` | 内部每秒恢复%.1f，部署友军在相邻房间作战时每秒恢复%.1f。 |

</details>

<details>

<summary>data/regular_version/update4/asset_manifest.json — 18개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `asset_spider_tailor.capture_contexts[1]` | upper_floor |
| `asset_bat_courier.capture_contexts[1]` | upper_floor |
| `asset_update4_world_upper_floor.tiles[0]` | res://assets/tiles/update4/upper/upper_floor_tile.png |
| `asset_update4_world_upper_floor.tiles[1]` | res://assets/tiles/update4/upper/upper_wall_tile.png |
| `asset_update4_world_upper_floor.tiles[2]` | res://assets/tiles/update4/upper/upper_stair_landing.png |
| `asset_update4_world_upper_floor.tiles[3]` | res://assets/tiles/update4/upper/upper_threshold.png |
| `asset_update4_world_upper_floor.props[0]` | res://assets/props/update4/upper/crown_pedestal_empty.png |
| `asset_update4_world_upper_floor.props[1]` | res://assets/props/update4/upper/crown_pedestal_active.png |
| `asset_update4_world_upper_floor.props[2]` | res://assets/props/update4/upper/crown_pedestal_damaged.png |
| `asset_update4_world_upper_floor.props[3]` | res://assets/props/update4/upper/upper_facility_slot.png |
| `asset_update4_world_upper_floor.props[4]` | res://assets/props/update4/upper/seal_vault_normal.png |
| `asset_update4_world_upper_floor.props[5]` | res://assets/props/update4/upper/seal_vault_alarm.png |
| `asset_update4_world_upper_floor.props[6]` | res://assets/props/update4/upper/seal_vault_stolen.png |
| `asset_update4_world_upper_floor.floor_icon` | res://assets/ui/icons/update4/floor_switch.png |
| `asset_update4_world_upper_floor.layout_previews[0]` | res://assets/ui/upper_floor/update4/layout_upper_compact_guard.png |
| `asset_update4_world_upper_floor.layout_previews[1]` | res://assets/ui/upper_floor/update4/layout_upper_split_vault.png |
| `asset_update4_world_upper_floor.layout_previews[2]` | res://assets/ui/upper_floor/update4/layout_upper_long_gallery.png |
| `asset_update4_world_upper_floor.source_record` | res://assets/source/imagegen/update4_world_phase34/upper_floor/SOURCE.md |

</details>

<details>

<summary>data/regular_version/update4/bond_events.json — 1개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `silky_crown_cover.text` | 실키는 상층 왕관 덮개를 만들겠다며 후보들의 머리 둘레를 재기 시작했다. 포포는 귀까지 포함하면 반칙이라고 주장했다. |

</details>

<details>

<summary>data/regular_version/update4/campaign_modes.json — 1개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `council_season.supported_systems[3]` | upper_floor |

</details>

<details>

<summary>data/regular_version/update4/council_agendas.json — 1개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `agenda_budget_cap.cost` | 상층 시설 최대 레벨 제한 |

</details>

<details>

<summary>data/regular_version/update4/council_campaign_days.json — 17개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `council_day_15.title` | 상층 공사 예고 |
| `council_day_15.story_beat` | 2층과 왕관 진화 예고 |
| `council_day_15.feature_flags[0]` | upper_floor_preview |
| `council_day_16.title` | 2층 개방 |
| `council_day_16.story_beat` | 상층 레이아웃 선택 |
| `council_day_16.encounter_kind` | upper_split |
| `council_day_16.feature_flags[0]` | upper_floor_unlock |
| `council_day_16.feature_flags[1]` | upper_layout_selection |
| `council_day_17.story_beat` | 상층 목표 첫 방어 |
| `council_day_17.encounter_kind` | upper_objective |
| `council_day_18.story_beat` | 층 전환 학습 |
| `council_day_18.encounter_kind` | upper_transition |
| `council_day_27.title` | 상층 최종 시설 |
| `council_day_27.story_beat` | Stage 04 상층 종합 시험 |
| `council_day_27.encounter_kind` | upper_final |
| `council_day_27.feature_flags[0]` | upper_final_facility |
| `council_day_29.story_beat` | 관계·지역·전초기지·상층 회수 |

</details>

<details>

<summary>data/regular_version/update4/council_endings.json — 35개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `ending_two_floors_one_throne.id` | ending_two_floors_one_throne |
| `ending_two_floors_one_throne.catalog_code` | E18 |
| `ending_two_floors_one_throne.display_name` | 두 층, 하나의 왕좌 |
| `ending_two_floors_one_throne.priority` | 180 |
| `ending_two_floors_one_throne.base_score` | 18000 |
| `ending_two_floors_one_throne.fallback` | false |
| `ending_two_floors_one_throne.illustration` | res://assets/ui/endings/update4/ending_two_floors_one_throne.png |
| `ending_two_floors_one_throne.thumbnail` | res://assets/ui/endings/update4/ending_two_floors_one_throne.png |
| `ending_two_floors_one_throne.sign_text` | 계단은 전선이 아니라 서로를 살린 기록이 되었다. |
| `ending_two_floors_one_throne.lines[0]` | 왕관실과 왕좌실의 경보가 동시에 꺼지자 두 층의 몬스터들이 계단 한가운데서 만났다. |
| `ending_two_floors_one_throne.lines[1]` | 누가 더 오래 버텼는지 다투던 기록표에는 결국 한 성의 승리라고 적혔다. |
| `ending_two_floors_one_throne.lines[2]` | 마왕성은 높아졌지만 지휘는 갈라지지 않았다. |
| `ending_two_floors_one_throne.condition.all[0].metric` | update4.final_battle_won |
| `ending_two_floors_one_throne.condition.all[0].op` | == |
| `ending_two_floors_one_throne.condition.all[0].value` | true |
| `ending_two_floors_one_throne.condition.all[1].metric` | update4.upper_floor_integrity |
| `ending_two_floors_one_throne.condition.all[1].op` | >= |
| `ending_two_floors_one_throne.condition.all[1].value` | 80 |
| `ending_two_floors_one_throne.condition.all[2].metric` | update4.crown_room_disable_count_since_day16 |
| `ending_two_floors_one_throne.condition.all[2].op` | == |
| `ending_two_floors_one_throne.condition.all[2].value` | 0 |
| `ending_two_floors_one_throne.condition.all[3].metric` | update4.seal_theft_completed |
| `ending_two_floors_one_throne.condition.all[3].op` | == |
| `ending_two_floors_one_throne.condition.all[3].value` | 0 |
| `ending_two_floors_one_throne.condition.all[4].metric` | update4.day30_upper_floor_contribution_ratio |
| `ending_two_floors_one_throne.condition.all[4].op` | >= |
| `ending_two_floors_one_throne.condition.all[4].value` | 0.25 |
| `ending_two_floors_one_throne.condition.all[5].metric` | update4.day30_lower_survivor_count |
| `ending_two_floors_one_throne.condition.all[5].op` | >= |
| `ending_two_floors_one_throne.condition.all[5].value` | 1 |
| `ending_two_floors_one_throne.condition.all[6].metric` | update4.day30_upper_survivor_count |
| `ending_two_floors_one_throne.condition.all[6].op` | >= |
| `ending_two_floors_one_throne.condition.all[6].value` | 1 |
| `ending_two_floors_one_throne.reward_ids[0]` | cosmetic_upper_floor_epilogue_layout |
| `ending_two_floors_one_throne.reward_ids[1]` | chronicle_floor_detail |

</details>

<details>

<summary>data/regular_version/update4/council_wave_templates.json — 15개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `wave_ironbell_chapter_1.floor_pattern` | lower_focus |
| `wave_ironbell_chapter_2.floor_pattern` | facility_then_stair |
| `wave_ironbell_chapter_3.floor_pattern` | split_facility_pressure |
| `wave_moonbat_chapter_1.floor_pattern` | delayed_upper |
| `wave_moonbat_chapter_2.floor_pattern` | alternating_floors |
| `wave_moonbat_chapter_3.floor_pattern` | cross_floor_objectives |
| `wave_mistcap_chapter_1.floor_pattern` | support_advance |
| `wave_mistcap_chapter_2.floor_pattern` | threshold_support |
| `wave_mistcap_chapter_3.floor_pattern` | two_floor_garden |
| `wave_bone_lantern_chapter_1.floor_pattern` | morale_feint |
| `wave_bone_lantern_chapter_2.floor_pattern` | rear_guard_feint |
| `wave_bone_lantern_chapter_3.floor_pattern` | split_morale_pressure |
| `wave_blackwater_chapter_1.floor_pattern` | treasure_probe |
| `wave_blackwater_chapter_2.floor_pattern` | vault_and_supply |
| `wave_blackwater_chapter_3.floor_pattern` | cross_floor_exchange |

</details>

<details>

<summary>data/regular_version/update4/crown_events.json — 2개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `crown_event_popo_grand_night_courier.scenes[0].text` | 왕관은 무거워도 편지는 가벼워요. 어느 층이든 제시간에 닿게 할래요. |
| `crown_event_popo_grand_night_courier.scenes[1].text` | 네 역할은 가장 위험한 층에 지원과 인장을 함께 되돌려 놓는 것이다. |

</details>

<details>

<summary>data/regular_version/update4/crown_evolutions.json — 2개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `crown_toktok_royal_armorer.role` | 시설·상층 목표 응급 보강 |
| `crown_popo_grand_night_courier.mobility_design` | USER_AUTHORIZED_REDESIGN: actual safe-route transition to an ally in a different enemy-occupied room in 0.20 simulated seconds; recipient-only six-second support starts on arrival. First actual different-room entry once per battle recovers 30% of first base skill's remaining cooldown. No implemented upper floor or seal protection claim. |

</details>

<details>

<summary>data/regular_version/update4/enemies.json — 10개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `dusk_courier.role` | 공중 층 전이·인장 절도 |
| `bronze_automaton.goal_type` | facility_or_stair |
| `bronze_automaton.role` | 시설 압박·계단 전이 큐 점유 |
| `bronze_automaton.role_tags[2]` | stair_blocker |
| `bronze_automaton.behavior_handler` | bronze_automaton_facility_or_stair |
| `bronze_automaton.max_stair_transitioning` | 1 |
| `shadow_duelist.role` | 최근 기여 몬스터 추적·층간 기습 |
| `root_tender.goal_type` | stair_or_room_entry |
| `root_tender.role` | 문턱·계단 뿌리 장벽 |
| `root_tender.role_tags[2]` | stair_blocker |

</details>

<details>

<summary>data/regular_version/update4/monster_codex.json — 8개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `codex_spider_tailor.role` | 계단·문턱 제어와 저체력 아군 구조 |
| `codex_spider_tailor.strengths[0]` | 계단 전이 가속 |
| `codex_spider_tailor.weaknesses[2]` | 넓은 단일층 방 |
| `codex_spider_tailor.skill_ids[0]` | stitch_stairway |
| `codex_spider_tailor.specialization_ids[0]` | silky_stair_warden |
| `codex_bat_courier.role` | 층간 기동·위험 예고·인장 회수 |
| `codex_bat_courier.strengths[0]` | 빠른 층 이동 |
| `codex_bat_courier.weaknesses[2]` | 혼자 남은 상층 |

</details>

<details>

<summary>data/regular_version/update4/monster_instances.json — 1개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `MON_SILKY.equipped_skill_ids[0]` | stitch_stairway |

</details>

<details>

<summary>data/regular_version/update4/monsters.json — 8개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `spider_tailor.role` | 계단·문턱 제어, 아군 구조 보조 |
| `spider_tailor.role_tags[2]` | floor_transition |
| `spider_tailor.skills[0]` | stitch_stairway |
| `spider_tailor.skill_slots[0]` | stitch_stairway |
| `spider_tailor.specialization_ids[0]` | silky_stair_warden |
| `bat_courier.role` | 층간 기동, 위험 예고, 인장 회수 |
| `bat_courier.role_tags[0]` | floor_mobility |
| `bat_courier.behavior_handler` | popo_floor_courier |

</details>

<details>

<summary>data/regular_version/update4/outpost_types.json — 2개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `outpost_watch_nest.upgrade_handler_id` | outpost_watch_preview_upper_entry |
| `outpost_watch_nest.level_2_text` | 상층 목표 적 진입 위치 공개 |

</details>

<details>

<summary>data/regular_version/update4/region_day_overlays.json — 13개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `ironbell_facility_pressure_a.day_types[1]` | upper_objective |
| `ironbell_facility_pressure_b.day_types[1]` | floor_transition |
| `ironbell_facility_pressure_b.primary_goal` | stair |
| `moonbat_cross_floor_pressure.region_id` | region_moonbat_aerie |
| `moonbat_cross_floor_pressure.variant` | cross_floor_delivery |
| `moonbat_cross_floor_pressure.first_entry_delay_seconds` | 3.0 |
| `moonbat_cross_floor_pressure.reinforcement_interval_multiplier` | 0.9 |
| `moonbat_cross_floor_pressure.wave_modifier` | moonbat_split_delivery |
| `blackwater_cross_floor_pressure.region_id` | region_blackwater_exchange |
| `blackwater_cross_floor_pressure.variant` | cross_floor_exchange |
| `blackwater_cross_floor_pressure.battle_gold_multiplier` | 1.15 |
| `blackwater_cross_floor_pressure.treasure_loss_multiplier` | 1.2 |
| `blackwater_cross_floor_pressure.wave_modifier` | blackwater_split_exchange |

</details>

<details>

<summary>data/regular_version/update4/regions.json — 1개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `region_moonbat_aerie.pressure_summary` | 빠른 목표 전환 · 인장 절도 · 층 이동 |

</details>

<details>

<summary>data/regular_version/update4/rival_bosses.json — 1개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `rival_vesper_council_champion.role_tags[2]` | floor_transition |

</details>

<details>

<summary>data/regular_version/update4/rival_letters.json — 6개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `letter_brassa_day05.body` | 네 성의 계단 폭은 합격이다. 다만 난간 세 번째 이음새는 전투 두 번을 버티기 어렵다. 도면에 붉은 선을 그어 두었으니 고쳐라. |
| `letter_vesper_day05.body` | 귀 성의 상층 주소를 확인했습니다. 밤 2시 이후에는 동쪽 계단이 가장 빠릅니다. 답장은 같은 봉인으로 보내 주세요. |
| `letter_vesper_day22.body` | 안개로 북쪽 항로가 늦어집니다. 표결 서신은 상층 창문을 경유하겠습니다. 거부 시 자정 전까지 회신 바랍니다. |
| `letter_mirella_day05.subject` | 계단 이끼 관리법 |
| `letter_mirella_day05.body` | 상층 계단의 이끼는 모두 걷지 않아도 괜찮아요. 가장자리만 남기면 발소리를 부드럽게 품어 줄 거예요. |
| `letter_mirella_day05.tone_keywords[0]` | 계단 |

</details>

<details>

<summary>data/regular_version/update4/run_metric_definitions.json — 16개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `update4.upper_floor_integrity.type` | number |
| `update4.upper_floor_integrity.default` | 0 |
| `update4.upper_floor_integrity.min` | 0 |
| `update4.upper_floor_integrity.max` | 100 |
| `update4.day30_upper_floor_contribution_ratio.type` | number |
| `update4.day30_upper_floor_contribution_ratio.default` | 0 |
| `update4.day30_upper_floor_contribution_ratio.min` | 0 |
| `update4.day30_upper_floor_contribution_ratio.max` | 1 |
| `update4.day30_lower_survivor_count.type` | number |
| `update4.day30_lower_survivor_count.default` | 0 |
| `update4.day30_lower_survivor_count.min` | 0 |
| `update4.day30_lower_survivor_count.max` | 99 |
| `update4.day30_upper_survivor_count.type` | number |
| `update4.day30_upper_survivor_count.default` | 0 |
| `update4.day30_upper_survivor_count.min` | 0 |
| `update4.day30_upper_survivor_count.max` | 99 |

</details>

<details>

<summary>data/regular_version/update4/skills.json — 24개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `stitch_stairway.display_name` | 계단 꿰매기 |
| `stitch_stairway.icon` | res://assets/sprites/ui/skills/skill_false_footprints.png |
| `stitch_stairway.cost_mana` | 12 |
| `stitch_stairway.cooldown` | 11.0 |
| `stitch_stairway.max_active` | 1 |
| `stitch_stairway.max_slow_targets` | 4 |
| `stitch_stairway.slow_multiplier` | 0.65 |
| `stitch_stairway.slow_seconds` | 4.0 |
| `stitch_stairway.fire_hits_to_remove` | 2 |
| `stitch_stairway.vfx_id` | fx_silky_thread |
| `stitch_stairway.sfx` | res://assets/audio/sfx/update4/contract_monsters/sfx_silky_stitch.wav |
| `stitch_stairway.description` | 계단 또는 문턱에 거미실을 설치해 처음 지나가는 적 4명을 4초 동안 35% 느리게 합니다. |
| `ceiling_path.hidden_floor_alert_move_multiplier` | 1.2 |
| `ceiling_path.description` | 층 전이가 40% 빨라지고 계단 전이 큐에서 아군 충돌을 무시합니다. |
| `night_relay.description` | 1층의 다른 위험 방에 있는 아군에게 걸어가, 도착하면 둘 모두 5초 동안 빠르게 움직이고 공격합니다. |
| `air_shortcut.description` | 환기 통로 endpoint로 층을 이동하지만 왕좌로 직접 순간이동하지 않습니다. |
| `shadow_promise.same_floor_only` | true |
| `shadow_promise.description` | 전투당 한 번 같은 층의 최근 기여 대상 뒤로 이동해 2초 동안 공격이 강해지고 방어가 낮아집니다. |
| `root_threshold.description` | 문턱이나 계단에 6초 뿌리 장벽을 하나 만들며 피해 또는 정화로 제거할 수 있습니다. |
| `deadline_dive.description` | 계단 endpoint를 거쳐 다른 층으로 급강하하고 도착 지점에 짧은 침묵을 남깁니다. |
| `royal_shared_umbrella.description` | 같은 층 아군 전체를 정화하고 5초 동안 초당 HP 3 재생하며 가장 낮은 체력비 아군의 전투 불능을 HP 1로 한 번 막습니다. 종료 후 모리 회복량은 6초 동안 15% 감소합니다. |
| `royal_emergency_plating.runtime_design` | NEW_DESIGN: protection0.30 from royalgel; finalrepaircap floor(maxHP*.30), unchanged ordinary repair boost |
| `royal_emergency_plating.description` | 1층에서 같은 방 또는 닿을 수 있는 가까운 손상 시설 중 HP 비율이 가장 낮은 시설을 최대 HP 30% 수리하고, 8초 동안 받는 피해를 30% 줄입니다. |
| `royal_urgent_courier.runtime_design` | USER_AUTHORIZED_REDESIGN: current different-room support replaces unsupported upperfloor travel. Actual arrival then recipient-only6s; source-owned effects cancel on down/suppression. CD30% recovery once at first actual room entry, capture weakness preserved. |

</details>

<details>

<summary>data/regular_version/update4/specializations.json — 12개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `silky_stair_warden.display_name` | 계단 파수 재봉 |
| `silky_stair_warden.monster_id` | spider_tailor |
| `silky_stair_warden.role_tag` | 계단 제어 |
| `silky_stair_warden.short_effect` | 거미실 둔화 40%·내구 +1 / 구조 보호막 -3%p |
| `silky_stair_warden.ai_behavior` | silky_threshold_rescue |
| `silky_stair_warden.rescue_shield_ratio_penalty` | 0.03 |
| `silky_stair_warden.skill_upgrade.skill_id` | stitch_stairway |
| `silky_stair_warden.skill_upgrade.slow_multiplier` | 0.6 |
| `silky_stair_warden.skill_upgrade.fire_hits_to_remove_bonus` | 1 |
| `popo_royal_express.role_tag` | 층간 중계 |
| `popo_royal_express.ai_behavior` | popo_floor_courier |
| `popo_seal_guard.ai_behavior` | popo_floor_courier |

</details>

<details>

<summary>data/regular_version/update4/upper_floor_layouts.json — 86개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `upper_compact_guard.display_name` | 밀집 수비 |
| `upper_compact_guard.floor_id` | 2F |
| `upper_compact_guard.advantage` | 계단·왕관실·금고 사이 대응이 빠름 |
| `upper_compact_guard.weakness` | 광역 공격에 목표가 함께 노출됨 |
| `upper_compact_guard.preview` | res://assets/ui/upper_floor/update4/layout_upper_compact_guard.png |
| `upper_compact_guard.base_stair_room` | spike_corridor |
| `upper_compact_guard.placed_modules[0].instance_id` | upper_stair |
| `upper_compact_guard.placed_modules[0].module_id` | upper_stair_landing |
| `upper_compact_guard.placed_modules[0].grid_origin[0]` | 0 |
| `upper_compact_guard.placed_modules[0].grid_origin[1]` | 1 |
| `upper_compact_guard.placed_modules[1].instance_id` | upper_crown |
| `upper_compact_guard.placed_modules[1].module_id` | crown_sanctum |
| `upper_compact_guard.placed_modules[1].grid_origin[0]` | 1 |
| `upper_compact_guard.placed_modules[1].grid_origin[1]` | 0 |
| `upper_compact_guard.placed_modules[2].instance_id` | upper_vault |
| `upper_compact_guard.placed_modules[2].module_id` | seal_vault |
| `upper_compact_guard.placed_modules[2].grid_origin[0]` | 1 |
| `upper_compact_guard.placed_modules[2].grid_origin[1]` | 2 |
| `upper_compact_guard.placed_modules[3].instance_id` | upper_facility |
| `upper_compact_guard.placed_modules[3].module_id` | upper_facility_slot |
| `upper_compact_guard.placed_modules[3].grid_origin[0]` | 2 |
| `upper_compact_guard.placed_modules[3].grid_origin[1]` | 1 |
| `upper_compact_guard.connections[0][0]` | upper_stair |
| `upper_compact_guard.connections[0][1]` | upper_crown |
| `upper_compact_guard.connections[1][0]` | upper_stair |
| `upper_compact_guard.connections[1][1]` | upper_vault |
| `upper_compact_guard.connections[2][0]` | upper_crown |
| `upper_compact_guard.connections[2][1]` | upper_facility |
| `upper_compact_guard.connections[3][0]` | upper_vault |
| `upper_compact_guard.connections[3][1]` | upper_facility |
| `upper_split_vault.display_name` | 분기 금고 |
| `upper_split_vault.floor_id` | 2F |
| `upper_split_vault.advantage` | 왕관실과 금고 목표를 양쪽으로 분산 |
| `upper_split_vault.weakness` | 수비 몬스터도 양쪽으로 나뉨 |
| `upper_split_vault.preview` | res://assets/ui/upper_floor/update4/layout_upper_split_vault.png |
| `upper_split_vault.base_stair_room` | spike_corridor |
| `upper_split_vault.placed_modules[0].instance_id` | upper_stair |
| `upper_split_vault.placed_modules[0].module_id` | upper_stair_landing |
| `upper_split_vault.placed_modules[0].grid_origin[0]` | 1 |
| `upper_split_vault.placed_modules[0].grid_origin[1]` | 2 |
| `upper_split_vault.placed_modules[1].instance_id` | upper_crown |
| `upper_split_vault.placed_modules[1].module_id` | crown_sanctum |
| `upper_split_vault.placed_modules[1].grid_origin[0]` | 0 |
| `upper_split_vault.placed_modules[1].grid_origin[1]` | 0 |
| `upper_split_vault.placed_modules[2].instance_id` | upper_vault |
| `upper_split_vault.placed_modules[2].module_id` | seal_vault |
| `upper_split_vault.placed_modules[2].grid_origin[0]` | 2 |
| `upper_split_vault.placed_modules[2].grid_origin[1]` | 0 |
| `upper_split_vault.placed_modules[3].instance_id` | upper_facility |
| `upper_split_vault.placed_modules[3].module_id` | upper_facility_slot |
| `upper_split_vault.placed_modules[3].grid_origin[0]` | 1 |
| `upper_split_vault.placed_modules[3].grid_origin[1]` | 1 |
| `upper_split_vault.connections[0][0]` | upper_stair |
| `upper_split_vault.connections[0][1]` | upper_facility |
| `upper_split_vault.connections[1][0]` | upper_facility |
| `upper_split_vault.connections[1][1]` | upper_crown |
| `upper_split_vault.connections[2][0]` | upper_facility |
| `upper_split_vault.connections[2][1]` | upper_vault |
| `upper_long_gallery.display_name` | 긴 회랑 |
| `upper_long_gallery.floor_id` | 2F |
| `upper_long_gallery.advantage` | 긴 이동 경로로 왕관실 진입 지연 |
| `upper_long_gallery.weakness` | 느린 몬스터의 대응이 늦음 |
| `upper_long_gallery.preview` | res://assets/ui/upper_floor/update4/layout_upper_long_gallery.png |
| `upper_long_gallery.base_stair_room` | spike_corridor |
| `upper_long_gallery.placed_modules[0].instance_id` | upper_stair |
| `upper_long_gallery.placed_modules[0].module_id` | upper_stair_landing |
| `upper_long_gallery.placed_modules[0].grid_origin[0]` | 0 |
| `upper_long_gallery.placed_modules[0].grid_origin[1]` | 1 |
| `upper_long_gallery.placed_modules[1].instance_id` | upper_facility |
| `upper_long_gallery.placed_modules[1].module_id` | upper_facility_slot |
| `upper_long_gallery.placed_modules[1].grid_origin[0]` | 1 |
| `upper_long_gallery.placed_modules[1].grid_origin[1]` | 1 |
| `upper_long_gallery.placed_modules[2].instance_id` | upper_vault |
| `upper_long_gallery.placed_modules[2].module_id` | seal_vault |
| `upper_long_gallery.placed_modules[2].grid_origin[0]` | 2 |
| `upper_long_gallery.placed_modules[2].grid_origin[1]` | 1 |
| `upper_long_gallery.placed_modules[3].instance_id` | upper_crown |
| `upper_long_gallery.placed_modules[3].module_id` | crown_sanctum |
| `upper_long_gallery.placed_modules[3].grid_origin[0]` | 3 |
| `upper_long_gallery.placed_modules[3].grid_origin[1]` | 1 |
| `upper_long_gallery.connections[0][0]` | upper_stair |
| `upper_long_gallery.connections[0][1]` | upper_facility |
| `upper_long_gallery.connections[1][0]` | upper_facility |
| `upper_long_gallery.connections[1][1]` | upper_vault |
| `upper_long_gallery.connections[2][0]` | upper_vault |
| `upper_long_gallery.connections[2][1]` | upper_crown |

</details>

<details>

<summary>data/regular_version/update4/upper_floor_modules.json — 17개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `upper_stair_landing.display_name` | 상층 계단참 |
| `upper_stair_landing.role` | transition |
| `upper_stair_landing.max_deployed` | 2 |
| `upper_stair_landing.art_states.normal` | res://assets/tiles/update4/upper/upper_stair_landing.png |
| `crown_sanctum.art_states.empty` | res://assets/props/update4/upper/crown_pedestal_empty.png |
| `crown_sanctum.art_states.active` | res://assets/props/update4/upper/crown_pedestal_active.png |
| `crown_sanctum.art_states.damaged` | res://assets/props/update4/upper/crown_pedestal_damaged.png |
| `seal_vault.art_states.normal` | res://assets/props/update4/upper/seal_vault_normal.png |
| `seal_vault.art_states.alarm` | res://assets/props/update4/upper/seal_vault_alarm.png |
| `seal_vault.art_states.stolen` | res://assets/props/update4/upper/seal_vault_stolen.png |
| `upper_facility_slot.display_name` | 상층 시설 슬롯 |
| `upper_facility_slot.role` | facility_slot |
| `upper_facility_slot.allowed_facility_roles[0]` | barracks |
| `upper_facility_slot.allowed_facility_roles[1]` | watch |
| `upper_facility_slot.allowed_facility_roles[2]` | recovery |
| `upper_facility_slot.same_floor_only` | true |
| `upper_facility_slot.art_states.normal` | res://assets/props/update4/upper/upper_facility_slot.png |

</details>

<details>

<summary>data/v122/combat_vfx_catalog.json — 1개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `references.update4_skills.stitch_stairway` | fx_silky_thread |

</details>

<details>

<summary>data/v122/content_compatibility.json — 4개 필드/문구</summary>

| 정확한 객체/번역 키 | 조사 당시 값 |
|---|---|
| `updates.update4.catalog_counts.res://data/regular_version/update4/upper_floor_layouts.json` | 3 |
| `updates.update4.catalog_counts.res://data/regular_version/update4/upper_floor_modules.json` | 4 |
| `updates.update4.quick_and_full_checks[9]` | update4_multifloor_graph_phase10 |
| `updates.update4.quick_and_full_checks[11]` | update4_multifloor_hud_phase12 |

</details>

#### 4-B. 코드·씬의 연결 지점과 직접 UI 문구

행 번호는 조사 기준 HEAD의 현재 작업 파일 기준이다. 파일별 의미 검색 일치 지점을 함수/선언으로 모았다. 같은 함수 안의 문자열은 정확한 원문/설정 키를 유지했다. `층`이 UI 레이어를 의미하는 선언은 제품 상층 제거와 무관하여 수정 전에 분류한다. 이 목록은 직접 검색 지점이며, 호출 관계로 연결되는 추가 함수는 구현 시 함께 추적한다.

<details>

<summary>scripts/combat/CrownFacilityRuntime.gd — 3개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `eligible` | 24 | `runtime_floor_id`<br>`1F` |
| `cast` | 46 | `floor_id`<br>`runtime_floor_id`<br>`1F` |
| `damage_scale` | 62 | `runtime_floor_id`<br>`1F` |

</details>

<details>

<summary>scripts/combat/NativeObjectiveRuntime.gd — 7개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const Upper` | 6 | `res://scripts/systems/multifloor/UpperFloorObjectiveService.gd` |
| `stock_available` | 28 | 내부 상태/연결 참조; 원문 없음 |
| `spawn` | 39 | `1층 의회 금고 접근` |
| `_start` | 91, 92 | `1층 의회 자원 수거`<br>`%s · 실제1층 의회 금고 수거 %.1f초 시작.` |
| `behavior` | 130 | `1층 의회 금고 접근` |
| `_settle` | 180, 187, 194 | `1f:%d:%d:%d`<br>`1층 의회 금고 · %s %d 손실%s.` |
| `status` | 334 | `1층 의회 수거`<br>`1F council collection` |

</details>

<details>

<summary>scripts/combat/RoyalSupportRuntime.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `floor_of` | 11 | `runtime_floor_id`<br>`1F` |

</details>

<details>

<summary>scripts/combat/SingleFloorSupportRuntime.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `relay_target` | 121, 122 | `floor_id`<br>`1F` |

</details>

<details>

<summary>scripts/core/CampaignSaveStore.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const SAFE_SCREENS` | 27 | `upper_floor` |

</details>

<details>

<summary>scripts/core/Constants.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const SCREEN_UPPER_FLOOR` | 22 | `upper_floor` |

</details>

<details>

<summary>scripts/core/DataRegistry.gd — 3개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `var update4_upper_floor_modules` | 61 | 내부 상태/연결 참조; 원문 없음 |
| `var update4_upper_floor_layouts` | 62 | 내부 상태/연결 참조; 원문 없음 |
| `load_all` | 173, 174 | `upper_floor_modules`<br>`upper_floor_layouts` |

</details>

<details>

<summary>scripts/data/update4/Update4CatalogLoader.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const CATALOG_FILES` | 17, 23 | `upper_floor_layouts`<br>`upper_floor_layouts.json`<br>`upper_floor_modules`<br>`upper_floor_modules.json` |

</details>

<details>

<summary>scripts/dungeon_quarter/QuarterDungeonRenderer.gd — 3개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const CORRIDOR_AUTOTILE_VARIANTS` | 34 | 내부 상태/연결 참조; 원문 없음 |
| `_draw_wall_edge_front_occluder` | 3037 | 내부 상태/연결 참조; 원문 없음 |
| `_draw_wall_vertex_front_occluder_layer` | 3091 | 내부 상태/연결 참조; 원문 없음 |

</details>

<details>

<summary>scripts/game/CombatSceneController.gd — 8개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const AUTO_SKILL_CONTROL` | 119 | `stitch_stairway` |
| `start_combat` | 664, 665 | `_prepare_update4_multifloor_battle` |
| `evaluate_update3_counter_combo` | 2442 | `조합 threat %.2f가 상한 %.2f 초과` |
| `_auto_skill_condition` | 3890 | `stitch_stairway` |
| `_prepare_selected_skill` | 6407 | `stitch_stairway` |
| `_commit_prepared_skill` | 6488, 6490, 6525 | `stitch_stairway` |
| `_active_crown_id` | 6831 | `upper_floor` |
| `set_speed` | 7427 | `전투 속도 x%.1f.` |

</details>

<details>

<summary>scripts/game/GameRoot.gd — 32개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const MultiFloorGraphServiceScript` | 63 | `res://scripts/systems/multifloor/MultiFloorGraphService.gd` |
| `const UpperFloorObjectiveServiceScript` | 64 | `res://scripts/systems/multifloor/UpperFloorObjectiveService.gd` |
| `const UpperFloorScreenScene` | 75 | `res://scenes/ui/screens/UpperFloorScreen.tscn` |
| `const MultiFloorHUDScene` | 81 | `res://scenes/ui/hud/MultiFloorHUD.tscn` |
| `const UPDATE4_SKILL_EVENT_BY_ID` | 106 | `stitch_stairway`<br>`update4.skill.stitch_stairway` |
| `const MANAGEMENT_MUSIC_SCREENS` | 135 | 내부 상태/연결 참조; 원문 없음 |
| `_draw_world_overlay` | 1596 | 내부 상태/연결 참조; 원문 없음 |
| `_set_screen` | 4242, 4304, 4326, 4327 | 내부 상태/연결 참조; 원문 없음 |
| `_build_chronicle_ui` | 5132 | `upper_floor_layouts` |
| `_build_settings_accessibility_category` | 5284, 5292, 5293, 5297 | `숨은 층 전투 요약`<br>`隐藏楼层战斗摘要`<br>`hidden_floor_summary`<br>`floor_one_key`<br>`floor_two_key`<br>`%d층 전환 키` |
| `_build_settings_audio_category` | 5349 | `층 경보 소리`<br>`楼层警报音量`<br>`floor_alert_volume` |
| `_build_audio_setting_row` | 5374 | `floor_alert_volume` |
| `_on_audio_slider_changed` | 5381 | `floor_alert_volume` |
| `_reset_settings_category` | 5565, 5572 | `hidden_floor_summary`<br>`floor_one_key`<br>`floor_two_key` |
| `_open_update4_upper_floor` | 6098, 6099, 6100 | `upper_floor` |
| `_build_upper_floor_ui` | 6103, 6104, 6105, 6107 | `UpperFloorScreen`<br>`upper_floor` |
| `_select_update4_upper_layout` | 6113, 6115, 6119, 6120 | `상층 레이아웃을 확정하지 못했습니다.`<br>`상층 레이아웃 확정: %s` |
| `_build_update4_multifloor_hud` | 6124, 6125, 6127, 6128, 6131, 6132, 6133, 6138 | `upper_floor`<br>`MultiFloorHUD` |
| `_prepare_update4_multifloor_battle` | 6142, 6143, 6145, 6146, 6147, 6158, 6159, 6160, 6162 | `upper_floor` |
| `_select_update4_visible_floor` | 6165, 6166, 6168, 6170, 6174, 6176, 6178 | `upper_floor`<br>`floor_id`<br>`1F`<br>`MultiFloorHUD` |
| `_set_update4_auto_camera` | 6185, 6187 | `upper_floor` |
| `_update4_upper_layout_pending` | 8117 | `upper_floor` |
| `_begin_update4_council_combat` | 8326, 8327 | `DAY %d 전투 전에 상층 레이아웃을 확정하세요.` |
| `_apply_update4_campaign_result_flags` | 9075, 9076 | `upper_floor`<br>`floor_transitions` |
| `_finalize_update4_council_ending` | 9097, 9118, 9119, 9129, 9130, 9132, 9136, 9137, 9148, 9149, 9150, 9151 | `upper_floor`<br>`floor_id`<br>`1F`<br>`2F`<br>`upper_floor_integrity`<br>`day30_upper_floor_contribution_ratio`<br>`day30_lower_survivor_count`<br>`day30_upper_survivor_count` |
| `_record_update4_battle_metrics` | 9278 | `upper_floor` |
| `_enter_campaign_management_day` | 9299, 9300 | 내부 상태/연결 참조; 원문 없음 |
| `_apply_update4_crown_stats` | 12666 | `upper_floor` |
| `_facility_base_definition` | 14426 | `체력 %d / 몬스터 %d명 배치. 내부 초당 %.1f, 배치 아군이 인접 방에서 싸울 때 초당 %.1f 회복합니다.` |
| `_facility_combat_overlay_text` | 15772 | `회복 +%.1f/초` |
| `_facility_effect_status_lines` | 16052 | `%s: 내부 초당 %.1f·인접 방 초당 %.1f 회복` |
| `_log` | 16119 | `[%05.1f] ` |

</details>

<details>

<summary>scripts/game/ManagementSceneController.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `_build_legacy_management_ui` | 804, 805 | `상층 왕성`<br>`_open_update4_upper_floor`<br>`UpperFloorButton`<br>`upper_floor` |

</details>

<details>

<summary>scripts/systems/bosses/VesperBossBattleService.gd — 3개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `deadline_dive` | 24 | `hidden_floor_alert` |
| `airmail_exchange` | 43, 48, 51, 53, 55 | `floor_id` |
| `resolve_battle` | 78 | `floor_transitions` |

</details>

<details>

<summary>scripts/systems/campaign/CampaignModeService.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `default_active_run` | 31 | `upper_floor` |
| `select_mode` | 101 | `upper_floor` |

</details>

<details>

<summary>scripts/systems/campaign/Update4CampaignRuntimeService.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `required_choice_id` | 29 | `upper_floor` |
| `_wave_entries` | 169 | `update4_floor_pattern`<br>`floor_pattern` |

</details>

<details>

<summary>scripts/systems/chronicle/CouncilChronicleService.gd — 5개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const FLOOR_ONE_KEYS` | 21 | 내부 상태/연결 참조; 원문 없음 |
| `const FLOOR_TWO_KEYS` | 22 | 내부 상태/연결 참조; 원문 없음 |
| `default_accessibility` | 27, 28, 33, 34 | `floor_alert_volume`<br>`hidden_floor_summary`<br>`floor_one_key`<br>`floor_two_key` |
| `normalize_accessibility` | 45, 48, 50, 51, 52, 53, 54, 55, 56, 57 | `hidden_floor_summary`<br>`floor_alert_volume`<br>`floor_one_key`<br>`floor_two_key` |
| `_run_summary` | 246, 265, 266, 267 | `upper_floor`<br>`lower_survivors`<br>`day30_lower_survivor_count`<br>`upper_survivors`<br>`day30_upper_survivor_count`<br>`damage_by_floor`<br>`day30_damage_by_floor` |

</details>

<details>

<summary>scripts/systems/crown/CrownEvolutionService.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `mori_shared_umbrella` | 296, 303 | `floor_id` |
| `popo_urgent_courier` | 348, 350, 351 | `floor_id`<br>`target_same_floor`<br>`target_floor_id` |

</details>

<details>

<summary>scripts/systems/endings/CouncilEndingService.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `build_metrics` | 15, 40, 43, 44, 45 | `upper_floor`<br>`update4.upper_floor_integrity`<br>`upper_floor_integrity`<br>`update4.day30_upper_floor_contribution_ratio`<br>`day30_upper_floor_contribution_ratio`<br>`update4.day30_lower_survivor_count`<br>`day30_lower_survivor_count`<br>`update4.day30_upper_survivor_count`<br>`day30_upper_survivor_count` |
| `apply_rewards` | 107, 109, 112 | `ending_two_floors_one_throne`<br>`upper_floor_epilogue_layout`<br>`floor_detail_unlocked` |

</details>

<details>

<summary>scripts/systems/enemies/BronzeAutomatonPressureService.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `choose_goal` | 5, 18 | `upper_stair` |
| `can_enter_stair` | 33, 34 | `max_stair_transitioning` |

</details>

<details>

<summary>scripts/systems/enemies/CoalSparkCounterService.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `choose_objective` | 5, 6 | 내부 상태/연결 참조; 원문 없음 |
| `silky_efficiency_trial` | 34 | `silky_stair_warden` |

</details>

<details>

<summary>scripts/systems/enemies/DuskCourierCounterService.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `air_shortcut_path` | 10, 11, 12 | `1F`<br>`2F`<br>`floor_id` |

</details>

<details>

<summary>scripts/systems/enemies/MirellaEnemyPressureService.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `place_root_barrier` | 39 | `stair` |

</details>

<details>

<summary>scripts/systems/enemies/ShadowDuelistPressureService.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `shadow_promise` | 20 | `floor_id` |
| `cross_floor_wave` | 36, 42, 45 | `floor_id` |

</details>

<details>

<summary>scripts/systems/monsters/PopoCombatService.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `choose_relay_target` | 9, 18, 21, 27 | `floor_id`<br>`1F` |
| `choose_floor_transition` | 106, 107, 109 | `1F`<br>`2F` |

</details>

<details>

<summary>scripts/systems/monsters/SilkyCombatService.gd — 4개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const SPEC_WARDEN` | 4 | `silky_stair_warden` |
| `place_thread` | 16, 21 | `stair`<br>`거미실을 설치할 계단·문턱·퇴각 통로가 없습니다.` |
| `ceiling_path_transition` | 78, 82 | `hidden_floor_alert_move_multiplier` |
| `choose_ai_action` | 93, 95 | `stair`<br>`stitch_stairway` |

</details>

<details>

<summary>scripts/systems/multifloor/MultiFloorGraphService.gd — 18개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `파일 최상위 선언` | 2 | 내부 상태/연결 참조; 원문 없음 |
| `const FLOOR_1` | 4 | `1F` |
| `const FLOOR_2` | 5 | `2F` |
| `fixture_upper_rooms` | 14, 15 | `upper_stair_landing`<br>`상층 계단참`<br>`상층 목표 fixture` |
| `build_graph` | 19, 22, 23, 29, 30, 31 | `upper_stair_landing`<br>`계단 endpoint 방이 없습니다.`<br>`stairs`<br>`castle_stair_01` |
| `objective_path` | 54, 60, 63 | 내부 상태/연결 참조; 원문 없음 |
| `new_runtime` | 70 | 내부 상태/연결 참조; 원문 없음 |
| `unlock_if_due` | 77, 81 | `upper_floor` |
| `register_entity` | 85, 87, 90 | `floor_id` |
| `request_transition` | 100, 101, 103, 108 | `floor_id`<br>`유닛이 계단 endpoint에 있지 않습니다.`<br>`같은 방향 계단 전이 큐는 최대 2명입니다.` |
| `tick` | 146 | `floor_id` |
| `restore_runtime` | 178, 182 | `floor_id` |
| `auto_camera_floor` | 200, 201 | `floor_id` |
| `_neighbors` | 206, 209, 211, 212, 213, 214, 215, 216, 217 | `stairs` |
| `_stair_endpoint` | 221, 222, 223, 224, 225, 226 | `stairs` |
| `_has_room` | 230, 231 | 내부 상태/연결 참조; 원문 없음 |
| `_node_key` | 234, 235 | 내부 상태/연결 참조; 원문 없음 |
| `_parse_key` | 240 | `floor_id` |

</details>

<details>

<summary>scripts/systems/multifloor/UpperFloorObjectiveService.gd — 9개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `파일 최상위 선언` | 2 | 내부 상태/연결 참조; 원문 없음 |
| `initialize_if_unlocked` | 12, 23 | `upper_floor` |
| `select_layout` | 29, 31, 33, 35, 39, 40 | `upper_floor`<br>`상층이 아직 해금되지 않았습니다.`<br>`이번 회차의 상층 레이아웃은 이미 확정되었습니다.`<br>`등록되지 않은 상층 레이아웃입니다.`<br>`1F`<br>`1F>2F`<br>`2F>1F` |
| `damage_crown_sanctum` | 52, 58 | `upper_floor` |
| `repair_next_day` | 64, 72 | `upper_floor` |
| `new_battle_objectives` | 78 | `upper_floor` |
| `settle_seal_theft` | 149, 151 | `upper_floor` |
| `install_facility` | 162, 163, 165 | `상층에는 병영·감시초소·회복 시설만 설치할 수 있습니다.`<br>`upper_floor` |
| `same_floor_targets` | 169, 173 | `floor_id` |

</details>

<details>

<summary>scripts/systems/save/SaveV4ToV5Migrator.gd — 6개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `fresh_update4_active_run` | 89 | `upper_floor` |
| `default_upper_floor` | 115 | 내부 상태/연결 참조; 원문 없음 |
| `_migrate_active_run` | 147 | `upper_floor` |
| `_validate_profile` | 204, 207, 209, 210, 211 | `hidden_floor_summary`<br>`floor_alert_volume`<br>`층 경보 소리 크기는 0~1이어야 합니다.`<br>`floor_one_key`<br>`floor_two_key`<br>`층 전환 키 설정이 올바르지 않습니다.` |
| `_validate_active_run` | 221, 282, 284, 291, 294 | `upper_floor`<br>`상층 상태 형식이 올바르지 않습니다.`<br>`DAY 16 이전에는 상층을 해금할 수 없습니다.`<br>`상층 목표 HP는 0 이상이어야 합니다.` |
| `_validate_catalog_references` | 321 | `upper_floor_layouts`<br>`upper_floor` |

</details>

<details>

<summary>scripts/ui/CombatWorkspaceUI.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `build_special_actions` | 210, 213, 216 | `upper_floor`<br>`1F`<br>`2F` |

</details>

<details>

<summary>scripts/ui/FacilityEffectText.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `for_topology` | 20 | `초당 %.1f 회복` |

</details>

<details>

<summary>scripts/ui/HUDController.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `_combat_unit_status_text` | 831, 832, 833, 837, 841 | ` %.1f`<br>` %d / %.1f` |
| `_build_combat_detail_drawer` | 1058, 1059, 1060, 1061, 1073 | `upper_floor`<br>`표시 층`<br>`1F`<br>`2F`<br>`현재 활성화된 심장·합동기·상층 전력이 없습니다.` |

</details>

<details>

<summary>scripts/ui/kit/KitStatBar.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `number_text` | 81 | `%.2f` |

</details>

<details>

<summary>scripts/ui/kit/UIKitIcons.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const ACTION_IDS` | 9 | `stitch_stairway` |

</details>

<details>

<summary>scripts/ui/SkillActionPresentation.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `_hide_inspectors` | 336 | `MultiFloorHUD` |

</details>

<details>

<summary>scripts/units/Unit.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `_draw` | 1421, 1425 | `부채 표식 %.1f`<br>`정화 성가 %.1f` |

</details>

<details>

<summary>scripts/v122/ui/V122ManagementViewModel.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `const ACTIONS` | 68, 69, 70, 72 | `upper_floor`<br>`상층 왕성`<br>`_open_update4_upper_floor`<br>`상층 배치·시설·왕관 목표를 관리합니다.` |
| `build` | 94, 96 | `upper_floor` |

</details>

<details>

<summary>scenes/outpost/OutpostBattleRoot.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `_refresh_battle_view` | 188 | `%04.1f / %04.1f초` |

</details>

<details>

<summary>scenes/ui/hud/MultiFloorHUD.gd — 16개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `파일 최상위 선언` | 2 | 내부 상태/연결 참조; 원문 없음 |
| `signal floor_selected(floor_id` | 4 | 내부 상태/연결 참조; 원문 없음 |
| `var upper_floor` | 15 | 내부 상태/연결 참조; 원문 없음 |
| `var visible_floor` | 20 | `1F` |
| `var floor_1_button` | 28 | 내부 상태/연결 참조; 원문 없음 |
| `var floor_2_button` | 29 | 내부 상태/연결 참조; 원문 없음 |
| `setup` | 57, 63, 64, 65, 66, 72 | `1F`<br>`2F` |
| `push_hidden_floor_alert` | 85, 88, 89, 92, 97, 101 | `숨은 층 침입`<br>`隐藏楼层入侵`<br>`hidden_floor_summary`<br>`floor_alert_volume`<br>`update4.floor_intrusion.alarm` |
| `hidden_enemy_count` | 108, 111 | `2F`<br>`1F`<br>`floor_id` |
| `select_floor` | 116, 117, 119, 123 | `1F`<br>`2F` |
| `_unhandled_input` | 139, 140, 141, 142 | `floor_one_key`<br>`1F`<br>`floor_two_key`<br>`2F` |
| `_build` | 148, 149, 157, 172, 173, 174, 175, 176, 177, 178, 190, 191, 213 | `UpperFloorSchematic`<br>`1F  %s`<br>`floor_one_key`<br>`1F`<br>`2F  %s`<br>`floor_two_key`<br>`2F`<br>`res://assets/ui/icons/update4/floor_switch.png`<br>`계단 이동 시 자동 전환`<br>`Auto camera on stairs`<br>`楼梯移动时自动切换`<br>`⚠ 숨은 층 침입`<br>`⚠ 隐藏楼层入侵` |
| `_build_upper_schematic` | 228, 231, 242 | `UpperFloorBackdrop`<br>`2F · %s` |
| `_module_status` | 275, 277, 278 | `같은 층 시설 효과`<br>`단일 계단 endpoint` |
| `_module_art_path` | 285, 287, 291 | 내부 상태/연결 참조; 원문 없음 |
| `_refresh` | 312, 313, 314, 315, 316 | `2F`<br>`1F` |

</details>

<details>

<summary>scenes/ui/hud/MultiFloorHUD.tscn — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `파일 최상위 선언` | 3, 5 | `res://scenes/ui/hud/MultiFloorHUD.gd`<br>`MultiFloorHUD` |

</details>

<details>

<summary>scenes/ui/screens/CampaignModeSelectionScreen.gd — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `_build` | 80 | `전초기지·상층·왕관` |

</details>

<details>

<summary>scenes/ui/screens/ChronicleScreen.gd — 2개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `_run_epilogue_text` | 297, 299, 301 | `• %d회차 · %s %s\n  지역 %s · 전초 %s/%s · 상층 %s\n  대표 %s · 관계 %s\n  왕관 %s · 인장 %d · 표 %d · 독립 %d\n  DAY30 %.1f초 · 생존 1F %d/2F %d · 층 피해 %s`<br>`upper_floor_layouts`<br>`lower_survivors`<br>`upper_survivors`<br>`damage_by_floor` |
| `_floor_damage_text` | 383, 384 | `1F`<br>`2F`<br>`1층`<br>`2층` |

</details>

<details>

<summary>scenes/ui/screens/UpperFloorScreen.gd — 5개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `파일 최상위 선언` | 2 | 내부 상태/연결 참조; 원문 없음 |
| `var upper_floor` | 10 | 내부 상태/연결 참조; 원문 없음 |
| `setup` | 23, 26 | 내부 상태/연결 참조; 원문 없음 |
| `_build` | 53, 54, 55, 59, 63, 78, 79, 82 | `상층 방어 배치`<br>`1층과 2층이 출전 인원을 나눕니다. 배치와 실제 연결을 살펴본 뒤 확정하세요.`<br>`고정 모듈 4개\n계단 연결 1곳`<br>`선은 실제 방 연결입니다.\n1층 가시 복도에서 계단으로 진입합니다.`<br>`확정 전에는 배치가 바뀌지 않습니다. 확정한 상층 배치는 이번 회차 동안 유지됩니다.`<br>`UpperFloorCloseButton` |
| `_confirm` | 127 | 내부 상태/연결 참조; 원문 없음 |

</details>

<details>

<summary>scenes/ui/screens/UpperFloorScreen.tscn — 1개 함수/선언</summary>

| 함수·선언 | 검색 일치 행 | 관련 원문·키(존재할 때) |
|---|---|---|
| `파일 최상위 선언` | 3, 5 | `res://scenes/ui/screens/UpperFloorScreen.gd`<br>`UpperFloorScreen` |

</details>

#### 4-C. 카탈로그 설명 문서

<details>

<summary>data/regular_version/update4/README.md — 설명 문구1개</summary>

| 위치 | 원문 요지 | 후속 처리 |
|---|---|---|
| 11행 마지막 문단 | 캠페인·의회·지역·경쟁 마왕·전초기지·상층·왕관·엔딩 카탈로그 설명 | 실제 1층 카탈로그 이관 후 ‘상층’→‘확장 구역’으로 문서 설명 갱신. Phase1의 과거 fixture 기록은 현재 구현 상태로 해석하지 않음. |

</details>

### 검색 오탐·미발견 항목

- `data/localization/story_en.json`의 `STORY_D08_MANAGEMENT_005`, `STORY_D14_RESULT_WIN_010`, `STORY_D15_RESULT_WIN_009`, `STORY_D27_RESULT_WIN_010`, `STORY_D30_ENDING_003`에서 `floor(s)`는 그릇이 떨어질 바닥·벽/바닥·축축한 바닥을 뜻한다. `story_zh_cn.json` 대응 키와 `data/story/v122_main/`는 기본 캠페인으로서 이번 층 삭제에 따른 수정 대상이 아니다.
- 기본 `data/skills.json`의 `floor_seconds`, `floor_interval`, `floor_radius`, `max_floors`와 `data/rooms.json`의 `spike_floor`는 바닥 효과/함정이다. 수학의 `floor()`/`floori()`, `.to_upper()`, `floor_cells`, 타일 `floor_*`, 바닥 마스크와 상단 UI 배치의 영어 upper는 변경하지 않는다.
- 색인의 `data/ending_rules.json / impregnable_demon_citadel.lines[0]`의 ‘실패 도장만 층층이 쌓였다’와 UI 표시 레이어는 실제 2층 구조를 요구하는 문구가 아니다. 층 삭제만을 이유로 바꾸지 않는다. `data/regular_version/update4/monster_instances.json / MON_SILKY.equipped_skill_ids[0]`의 `stitch_stairway`는 장착 스킬ID다. 표시 이름·기능은 이관하되 내부ID를 유지하면 이 장착 참조는 변경할 필요가 없다.
- `scripts/systems/tutorial/`, `scripts/core/TutorialGuidanceHistory.gd`, `data/onboarding_flow_dialogue_v0.4.json`, `data/story/v122_main/`에서 상층/2층 서사 지시는 발견되지 않았다. DAY16 상층 배치 화면의 도움 문구와 게임 진입 전 확정 안내는 발견됐다(색인 참조). M3 첫날 자유 배치 튜토리얼 재작업은 기존 맵 계획의 별도 승인 범위다.
- `data/regular_version/update4/localization_ko.json`는 `{}`. 현재 ko 원문은 각 카탈로그와 코드, en/zh_CN은 `ui_en.json`·`ui_zh_cn.json`에서 관리된다. 번역만 남은 층간 왕관 설명도 색인에 포함하고 활성 원문과 대조하여 폐기/이전한다.
- 자산의 `SOURCE.md`, 과거 디자인 문서, 기록 브랜치의 ‘상층’은 역사적 출처다. 제품 문구 검색과 구분하며 일괄 치환하지 않는다.

### M3 이후 구현 순서와 완료 조건

| 순서 | 적용 내용 | 주요 경로·완료 조건 |
|---|---|---|
| 1 | 사용자 결정 확정, M3 자유 배치·자동 길 연결 상태 인수 | 이 문서와 맵 계획. 1.3.0 적용 범위/엔딩안/등급 미달 처리/지원 기능을 먼저 고정. |
| 2 | 1층 목표와 구역 식별 이관; 등급 확장 해금과 배치 안전정책 연결 | `data/map_builder/plot_grades.json`(계획 경로), 새 1층 목표 카탈로그·서비스(경로 결정 필요), 기존 모듈 수치 재사용. 확장 전후 왕좌·왕관실·금고 모두 실제 길로 접근 가능. M6와 통합. |
| 3 | 다층 요구 선택·화면·그래프·세이브 제거 및 변환 | `GameRoot.gd`, `Update4CampaignRuntimeService.gd`, `CampaignModeService.gd`, `DataRegistry.gd`, `Update4CatalogLoader.gd`, multifloor/HUD/UpperFloorScreen, `SaveV4ToV5Migrator.gd`, `CampaignSaveStore.gd`. 구 세이브 복사본으로 층 필드 안전 폐기, 진행일·자원·E18/보상 기록 보존. |
| 4 | 일정·편지·사건·안건·목표 적 연결 | update4의 날짜/이벤트/편지/지역/웨이브/적/스킬 데이터와 관련 서비스. DAY15 예고→16 시설 사용→17 절도→18 왕관실 지원→27 종합→29 회수→30 결산이 끊기지 않음. |
| 5 | E18 지표·보상·연대기·3언어 문구 반영 | `CouncilEndingService.gd`, `CouncilChronicleService.gd`, `ChronicleScreen.gd`, GameRoot 설정, 엔딩/지표/번역 카탈로그. 80·0·0.25·각1 경계값과 생산자/소비자 일치. 과거 기록을 새 회차 실적으로 합산하지 않음. |
| 6 | 그림 처리 후 표적 검증·출시 인계 | 별도 승인된 그림 경로/manifest, 테스트와 날짜별 핸드오프. 대표 화면은 구현 승인 후 실제 실행하여 확인. 1.3.0 출시 전에 완료. |

후속 표적 테스트 후보는 기존 `tools/tests/Update4DataContractTest.gd`, `CampaignModePhase3Test.gd`, `UpperFloorObjectivesPhase11Test.gd`, `MultiFloorGraphPhase10Test.gd`, `MultiFloorHudPhase12Test.gd`, `Update4EndingsPhase32Test.gd`, `Update4EndingsPhase33Test.gd`, `Update4ChronicleAccessibilityPhase35Test.gd`, `SaveV5MigrationTest.gd`, `OutpostTypesPhase9Test.gd`, `PopoCombatPhase15Test.gd`, `CrownMobilityRecoveryTest.gd`, `CrownFacilityRecoveryTest.gd`, `VesperBossPhase23Test.gd`, `V1213U5BTest.gd`, `V1213U5CTest.gd`, `V1213U5FTest.gd`이다. 이름이 다층인 검사는 목적을 1층 목표/구역 지원으로 바꾸거나 폐기 여부를 판단한다. 원문 계약이 제거됐는데 이름만 바꿔 통과시키지 않는다. 맵 M2·M3 검사는 해당 맵 작업에서 수행하며 이 문서 세션에서는 실행하지 않았다.

### 이번 세션 인계

- 목표/브랜치/기준 SHA: 1.3.0용 문서 제안 / `codex/v1213-fix-plan` / `71587de4f6d238a68190a22be5a7a22b6461f0f5`.
- 완료: 30일 원문 조사, 1층 연결 초안, 목표 대체표, E18 양안, 출처 색인·구현 순서. 실제 제품 스토리·코드·데이터·밸런스·자산·저장 변경0.
- 변경 파일: `docs/design/v20_map_builder/COUNCIL_1F_STORY_REWRITE_PROPOSAL.md`만.
- 검증: JSON129개 원문 파싱, 30일/원문 제목·비트 대조, 출처73파일·JSON키532개·코드 함수/선언162개 존재/행 범위 확인, 번역 원문/값 대조, PNG 직접 확인, 결정 질문5개·표 열 수·접기 태그 확인. 기존 코드/데이터/씬/도구/맵 문서1539파일의 합성 해시가 조사 전후 동일함을 확인했다. 지정 파일의 공백·단일 파일 커밋 확인을 수행한다. Godot/빌드/게임 테스트/전체 회귀/플레이/검수 에이전트 미실행.
- Review task ID: NOT_REQUESTED
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS (문서의 원문 대조·범위 확인에 한함, 게임 동작 승인 아님).
- 마지막 커밋 SHA: 이 파일 단독 영어 커밋 후 최종 보고에서 제공(자기 참조 SHA를 문서에 고정하지 않음). 원격 푸시 없음.
- 기존 미커밋 `.import`·`.uid` 등은 보존하고 커밋에서 제외. 추가 핸드오프/CURRENT 변경은 ‘이 파일만’이라는 이번 사용자 제한에 따라 수행하지 않음.
- 미해결: 아래 결정 및 en/zh_CN 번역·제품 적용·그림 처리·후속 표적 검증. 기존 E18 지표의 생존자 비율과 시설 보전 정의를 문서에서 밝혔으며 실제 구현 검증은 후속 범위다.

## 5. 사용자 결정 질문

1. **E18은 어떤 결말로 바꿀까요?** 권장: **A ‘넓어진 땅, 하나의 왕좌’**. 기존 생존비0.25·시설 보전80·각 구역 생존1 조건을 보존해 변경 범위를 줄입니다. B는 실제 기여 집계와 별도 난도 확인이 필요합니다.
2. **DAY16 전에 확장 등급을 못 달성한 회차는 어떻게 이어갈까요?** 권장: 기존 부지의 왕관실/금고 임시 배치로 날짜를 이어가고, 실제 등급 달성 뒤 확장 구역으로 이전합니다. 확장 전에는 E18 확장 방어 실적을 적립하지 않습니다. 부지 부족 시 기존 배치를 보존하는 안전 배치안을 구현 단계에서 먼저 검증합니다.
3. **E18의 구역 담당·시설 보전 기준을 어떻게 정할까요?** 권장: DAY30 출전 시 담당 구역을 고정하고 생존자를 세며, 보전 지표는 기존처럼 왕관실 잔여HP 비율로 둡니다. 자유 이동/건물 재배치 중 구역이 바뀌어도 중복 집계하지 않습니다. 전체 시설 평균을 쓰려면 별도 난도 결정이 필요합니다.
4. **계단 전이 전용 기능을 1층에서 어떻게 처리할까요?** 권장: 실키·베스퍼의 길목 제어/우회 기능을 실제 연결 통로에 이관하고, 포포는 이미 승인된 다른 위험 방 지원을 유지합니다. `ceiling_path`의 시간 배율0.60은 지원 이동에만 적용하는 후보로 검토하며 새 이동속도 수치를 자동 도입하지 않습니다.
5. **E18 그림과 내부 ID는 어떻게 처리할까요?** 권장: 표시 이름은 A로 변경하고 내부 ID/E18 기록은 호환용으로 보존합니다. 명확한 두 층 그림은 최종본에 그대로 쓰지 않고, 1층 공동 방어 그림의 후속 제작을 별도 승인합니다. 이번 문서에서는 생성·편집하지 않았습니다.

## 6. 사용자 확정 (2026-10-15 00:43 KST)

5절 결정 질문 1~5 모두 **권장안 승인**.
1. E18 → A안 "넓어진 땅, 하나의 왕좌"(기존 생존비0.25·시설 보전80·각 구역 생존1 조건 보존).
2. DAY16 전 등급 미달 → 기존 부지에 왕관실·금고 임시 배치로 날짜 진행, 등급 달성 후 확장 구역으로 이전. 확장 전 E18 실적 미적립.
3. E18 판정 → DAY30 출전 시 담당 구역 고정 생존자 기준, 보전 지표 = 왕관실 잔여HP 비율.
4. 계단 전용 기능 → 실키·베스퍼 길목 제어/우회를 연결 통로로 이관, 포포는 기존 다른 위험 방 지원 유지, 새 이동속도 수치 도입 없음(ceiling_path 0.60 배율은 지원 이동 한정 후보로 검토).
5. E18 그림·ID → 표시 이름 A로 변경, 내부 ID·E18 기록 보존, 1층 공동 방어 그림은 후속 제작.
제품 버전: 1.3.0(맵 개편과 함께 적용). 이 문서를 적용 작업의 기준으로 사용한다.
