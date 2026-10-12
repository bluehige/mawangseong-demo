# 정상 소유·의회 편성·지원 숙련도 실행 계약

기준 productbdf886a/docs4e11172, 별도 codex/earned-support-progression. 사용자 승인된 실제 스킬·해금·저장 연결의 다음 단계다. 이전 묶음 PASS는 고정 SHA/범위로 재사용하고, 새 producer/정산/편성/save필드만 검증한다. 구현 전 계약이며 현재 실행 결과는 NOT_RUN.

## 정상 획득과 편성

- Mori는 기존 두 계약 선택 확정 producer가 campaign_profile.unlocked_contract_ids에 기록한 유효 ID만 기존 idempotent add API로 의회 owned/reserve에 복원한다. TokTok은 기존 전선 클리어/E13/guaranteed_contract_instance_ids producer와 reward sync를 재사용한다. 새 DAY13 자동 영입/무료 캐릭터·레벨·특화·왕관을 지급하지 않는다.
- 기존 owned entry의 level/EXP/bond/memory/specialization/promotion/room/defense_enabled는 보존한다. 반복 setup은 유효한 사용자의 현재 deployed 선택을 초기화하지 않는다. 새 복원은 reserve이며 기본 초기 의회5인(기존Core3+Silky+Popo) 정책을 유지한다.
- 의회 owned 편성 화면은 ordinary selected_contract_ids==2 선택완료 guard와 분리한다. 계약 후보/재선택 화면으로 잘못 들어가지 않고 실제 owned를 보여준다. ordinary 전선 계약 선택 규칙과3/4/4/5 stage cap은 유지한다.
- 의회 기존5인 초기 정책과 stage cap의 충돌을 명시적으로 다룬다: 의회 편성 한도는 기존 실제5인 이상인 현재 유효 배치 정책을 유지하며, stage/기존 perk가 그 이상을 허용하면 기존 값만 사용한다. 새 증원 perk나 전투 unit 수의 추가 지급은 없다. 이미 잘못된 IDs/중복은 정규화하고 자동으로 모든 reserve를 배치하지 않는다.

## NEW_DESIGN — 실제 역할 milestone만 최대3

update4_profile.crown_evolution.species_milestones[species]={support,survive,bond80}, species_mastery가 저장 경로다. 대상은 기존 required_species_mastery==2인 Mori/TokTok/Popo. 세 고유 milestone은 반복 횟수/새 재화/일일 노가다가 아니며 새 획득 값은 최대3이다. 기존 저장의 더 높은 mastery와 crown_evolution 내부 모르는 키는 낮추거나 지우지 않는다. 최상위 profile은 기존 저장 스키마 정책을 유지한다.

- support: Mori 실제 effective_healing>0; TokTok 실제 effective_facility_repair>0 또는 살아있는 적의 effective_DEF가 실제 낮아진 파쇄; Popo 실제 중계 도착 후 buff 적용, 실제 Echo 지연 ms>0, 실제 봉투 자원 회수>0. 준비·시청·버튼 클릭·명목 회복/수리·보호막 제공만으로 인정하지 않는다.
- survive: 그 전투에 실제 출전한 같은 actor가 위 역할 기여를 하고 실제 positive HP 손실을 받은 후 승리 시 살아 있다. shield-only HP0 손실/down/미출전 reserve/다른 actor의 같은 species 실적은 생존 milestone을 만들지 않는다. 실제 지원과 위험을 경험한 생존으로 bounded producer를 만든다.
- bond80: 기존 정상 roster 유대80을 인정한다. 실제 유대 증가로80에 도달하면 기록하며, 이미80을 획득한 패치 전 출전 멤버는 승리 정산에서 인정해 추가 선물 노가다를 요구하지 않는다. 화면 조회만으로 새 기록을 만들지 않는다.
- 전투 중은 임시 pending만 기록하고 공통 승리 growth 정산 후 한 번 병합한다. 패배/포기/새 전투는 pending을 폐기한다. 지원 후 down된 actor의 support 실적은 승리 시 support만 인정할 수 있으나 survive는0. generic source HP/current roster/deployment를 확인한다.
- 기존 후보/confirm의 Lv6·유대80·특화·growth/evolution·인장 비용·회차1왕관 cap은 그대로 검사한다. milestone2를 얻었다고 나머지 조건을 우회하지 않는다.

## 저장·표시·새 검증

임시 actorRef/HP/role events는 세이브하지 않는다. 기존 v5/profile crown dictionary에 plain bounded milestone만 저장하고 기존 세이브 가족/경로/Cloud6파일을 유지한다. malformed milestone은 안전하게 정규화하되 정상 기존 진행/알 수 없는 crown 내부 키를 보존한다. 편성/monster 또는 정산 화면에 실제 숙련도와 부족한 항목을 짧게 표시한다. 의회 출전 목록이 비면 전원 출전으로 해석하지 않으며, 초기/잘못된 기록은 기존Core+Silky+Popo로만 안전하게 복원한다. 편성 중 빈 목록은 확인/전투 시작을 허용하지 않고 예비를 자동 출전시키지 않는다.

새 검증: 해금 없는 명단 불변; 실제 기존 계약 확정/전선 보상 producer→복원/반복 idempotence/기존 성장·선택 보존; 실제 owned 편성 UI/한도/미출전 제외; 실제 회복·수리/파쇄·도착/지연/회수 producer; 실제 HP0/positiveHP·승리/패배/down·중복 정산/새 전투; Lv/유대/특화/비용 게이트; v5 roundtrip/이전 profile/다음 회차 보존. 강제 경계 조건과 실제 producer 연결을 자연 전체 캠페인 클리어로 부르지 않는다. 사람 재미/전체 플레이/Cloud/새DAY13 producer는 NOT_RUN.
