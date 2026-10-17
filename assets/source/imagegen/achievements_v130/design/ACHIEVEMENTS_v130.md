# 마왕성 Steam 도전과제 기획 v1 (2026-10-17)

## Steam 쪽 변경 요약 (2026-10-15 발표, 베타)
- 도전과제 세트: 본편·DLC·모드·시즌별로 묶음. 본편 100%가 업데이트 추가로 깨지지 않음. 세트 완료 시 별도 리본.
- 편집기 개편: 정의·아이콘·현지화·세트 배정 일괄 가져오기/내보내기, 잠김 아이콘(흑백) 자동 생성, 현지화 누락 경고.
- 보관(아카이브)·개발자 전용 세트·DLC 세트는 출시 전 숨김. SDK 업데이트 불필요(기존 API 이름·호출 그대로).

## 우리 게임 현재 상태
- Steam 연동 코드 없음(GodotSteam 등 미포함) → 도전과제 해제 호출을 넣으려면 연동 애드온 추가 필요.
- 게임 안 자체 기록(엔딩 12, 3차 결말 5, 의회 결말 6, 왕관 6, 도전 인장 6)은 있음 → 기존 세이브에서 소급 해제 가능.

## 목록 (100개, 숨김 8개)

### 1. 기본 캠페인
| API 이름 | 이름 | 조건 | 진행도 |
|---|---|---|---|
| `ACH_FIRST_NIGHT` | 축축한 원룸의 첫 손님 | DAY 1 방어에 성공한다. |  |
| `ACH_THIEF_DENIED` | 개업 첫 도난은 사절 | 도둑이 나오는 날 금고 손실 없이 승리한다. |  |
| `ACH_HERO_TRAINEE` | 견습 용사 돌려보내기 | DAY 3 수련생 용사를 막아낸다. |  |
| `ACH_GRADE_E` | 동굴이 아니라 마왕성 | DAY 15에 소마왕성(E등급)으로 승급한다. |  |
| `ACH_GRADE_D` | 갈림길의 요새 | DAY 20에 요새 마왕성(D등급)으로 승급한다. |  |
| `ACH_GRADE_C` | 서문과 남문 | DAY 27에 대마왕성(C등급)으로 승급한다. |  |
| `ACH_SELEN` | 성스러운 빛, 촛불로 맞서다 | 성기사 견습 셀렌을 처음 물리친다. |  |
| `ACH_ROMAN` | 감사는 끝났습니다 | 길드 조사대장 로만을 물리친다. |  |
| `ACH_LEON` | 정식 용사 레온 | DAY 30 레온을 물리치고 캠페인을 끝낸다. |  |
| `ACH_DAY29` | 싸우지 않는 밤 | DAY 29 준비일을 보낸다. |  |

### 2. 마왕성 건축 (1.3.0)
| API 이름 | 이름 | 조건 | 진행도 |
|---|---|---|---|
| `ACH_BUILD_FIRST` | 첫 삽 | 건물을 처음 지어 길을 연결한다. |  |
| `ACH_BUILD_ALL5` | 다섯 가지 방 | 병영·회복 둥지·결계핵·감시탑·미끼 보물실을 모두 짓는다. |  |
| `ACH_BUILD_MAX` | 증축 허가 | 건물 하나를 최대 레벨까지 강화한다. |  |
| `ACH_TRAPS_50` | 바닥 조심 | 함정을 누적 50개 설치한다. | STAT_TRAPS_PLACED |
| `ACH_TRAP_KILLS_100` | 발밑의 공포 | 함정으로 적을 누적 100명 쓰러뜨린다. | STAT_TRAP_KILLS |
| `ACH_STONE_BRIDGE` | 나무에서 돌로 | 다리가 돌다리로 바뀐다(D등급). |  |
| `ACH_NO_THRONE_DMG` | 옥좌는 먼지 하나 없이 | 옥좌가 피해를 받지 않고 전투에서 이긴다(DAY 10 이후). |  |
| `ACH_SPLIT_DEFENSE` | 두 갈래를 지켜라 | C등급에서 서문·남문 양쪽 최종 방어선을 모두 지켜 승리한다. |  |
| `ACH_ALL_FACILITIES_ALIVE` | 시설 무사 | D·C등급 전투에서 시설이 하나도 무력화되지 않고 승리한다. |  |

### 3. 몬스터 식구
| API 이름 | 이름 | 조건 | 진행도 |
|---|---|---|---|
| `ACH_FAMILY_10` | 식구가 늘었다 | 몬스터 10명이 합류한다. | STAT_ROSTER |
| `ACH_FAMILY_24` | 스물네 식구 | 몬스터 24명이 모두 합류한다. | STAT_ROSTER |
| `ACH_FIRST_MEMORY` | 처음 내민 젤 손 | 몬스터의 기억을 처음 해금한다. |  |
| `ACH_ALL_MEMORIES` | 기억의 서고 | 모든 몬스터의 기억을 해금한다. | STAT_MEMORIES |
| `ACH_FIRST_DUO` | 둘이 하나 | 합동기를 처음 해금한다. |  |
| `ACH_ALL_DUOS` | 열여섯 번의 하이파이브 | 합동기 16개를 모두 해금한다. | STAT_DUOS |
| `ACH_FIRST_SPEC` | 진로 결정 | 몬스터 전문화를 처음 고른다. |  |
| `ACH_SPEC_24` | 모두 제 갈 길 | 24종 모두 전문화를 고른다. | STAT_SPECS |
| `ACH_NO_HUNGER` | 배부른 마왕성 | 한 캠페인 동안 굶주림 상태 몬스터 없이 DAY 30에 도달한다. |  |
| `ACH_FULL_HOUSE` | 수비 칸 만석 | 수비 칸을 모두 채우고 식량이 모자라지 않은 채 승리한다. |  |

### 4. 몬스터 개성
| API 이름 | 이름 | 조건 | 진행도 |
|---|---|---|---|
| `ACH_M_FROG` | 혀 낚시꾼 | 퐁당이 다리 위 적을 누적 30명 묶는다. | STAT_FROG_SNAG |
| `ACH_M_SNAIL` | 늦어도 도착 | 느릿의 점액으로 적을 누적 200번 느리게 한다. | STAT_SNAIL_SLOW |
| `ACH_M_TROLL` | 통행세 징수 | 벙벙이 도둑에게서 금화 누적 500을 되찾는다. | STAT_TROLL_TOLL |
| `ACH_M_SHADOW` | 까꿍 | 쉿이 적을 누적 50번 겁준다. | STAT_SHADOW_FEAR |
| `ACH_M_ARMOR` | 옥좌 앞의 맹세 | 텅텅이 레온 전투에서 판금 재조립 후 살아남는다. |  |
| `ACH_M_WISP` | 작은 달 | 녹녹이 숨은 적을 누적 20번 드러낸다. | STAT_WISP_REVEAL |
| `ACH_M_MOLE` | 안전 제일 | 파파가 공병의 공사를 누적 30번 방해한다. | STAT_MOLE_SABOTAGE |
| `ACH_M_MAP` | 왕좌가 세 군데 | 꼬깃이 탐험가를 누적 100번 길 잃게 한다. | STAT_MAP_LOST |
| `ACH_M_RATS` | 치즈 인상 투쟁 | 찍찍단이 금화 누적 1000을 회수한다. | STAT_RAT_GOLD |
| `ACH_M_DOLL` | 대신 아파 줄게 | 누비가 보스전에서 대신 받은 피해로 동료를 살린다. |  |
| `ACH_M_PUDDING` | 말랑한 벽 | 푸딩이 한 전투에서 피해 1000을 막아낸다. |  |
| `ACH_M_GOB` | 곱은 어디? | 곱이 도둑을 누적 30명 쓰러뜨린다. | STAT_GOB_THIEF |
| `ACH_M_PYNN` | 교환 환불 불가 | 핀의 화염구로 적 누적 300명을 맞힌다. | STAT_PYNN_FIRE |
| `ACH_M_ROLO` | 부풀리지 않은 보고 | 로로가 원정을 10번 이끈다. | STAT_ROLO_RAID |

### 5. 도전·숨김
| API 이름 | 이름 | 조건 | 진행도 |
|---|---|---|---|
| `ACH_SEAL_NO_THRONE` | 철벽 인장 | 도전 인장: 옥좌 무피해 조건으로 승리한다. |  |
| `ACH_SEAL_NO_DOWN` | 아무도 쓰러지지 않게 | 도전 인장: 몬스터 전투불능 없이 승리한다. |  |
| `ACH_SEAL_LOW_MANA` | 가난한 마법사 | 도전 인장: 마나 제한 조건으로 승리한다. |  |
| `ACH_SEAL_NO_DISABLE` | 멈추지 않는 시설 | 도전 인장: 시설 무력화 없이 승리한다. |  |
| `ACH_SEAL_CONTRACT_VANGUARD` | 계약 선봉대 | 도전 인장: 계약 몬스터 선봉 조건으로 승리한다. |  |
| `ACH_SEAL_ADAPTIVE` | 숙적의 적응 | 도전 인장: 적응하는 숙적 조건으로 승리한다. |  |
| `ACH_SECRET_BUCKET` | 양동이 두 개 (숨김) | 천장 누수 대사를 끝까지 본다. |  |
| `ACH_SECRET_DIRECT_LEON` | 마왕이 직접 (숨김) | 직접 조종한 몬스터로 레온에게 마지막 일격을 넣는다. |  |
| `ACH_SECRET_ALL_IN_ONE` | 몰빵의 대가 (숨김) | 한 건물 앞에 전원 세우고 진다. |  |
| `ACH_SECRET_HUNGRY_WIN` | 배고파도 이긴다 (숨김) | 몬스터 5명 이상이 굶주린 채 승리한다. |  |
| `ACH_SECRET_37` | 연못 반환 요구서 37번 (숨김) | 퐁당 합류 대화를 본다. |  |

### 6. 본편 결말
| API 이름 | 이름 | 조건 | 진행도 |
|---|---|---|---|
| `ACH_END_TRUE_DEMON_CASTLE` | 진짜 마왕성 | 결말 "진짜 마왕성"에 도달한다. |  |
| `ACH_END_MONSTER_FAMILY_CASTLE` | 몬스터 식구들의 성 | 결말 "몬스터 식구들의 성"에 도달한다. |  |
| `ACH_END_IMPREGNABLE_DEMON_CITADEL` | 철벽의 마왕 요새 | 결말 "철벽의 마왕 요새"에 도달한다. |  |
| `ACH_END_DREAD_OVERLORD_RISES` | 공포의 대마왕 | 결말 "공포의 대마왕"에 도달한다. |  |
| `ACH_END_DEMON_HERO_RIVAL_PACT` | 마왕과 용사의 라이벌 협정 | 결말 "마왕과 용사의 라이벌 협정"에 도달한다. |  |
| `ACH_END_CONTRACT_MONSTER_ALLIANCE` | 계약 마물 연합 | 결말 "계약 마물 연합"에 도달한다. |  |
| `ACH_END_ROYAL_DOCTRINE_BROKEN` | 왕국 교리 파쇄 | 결말 "왕국 교리 파쇄"에 도달한다. |  |
| `ACH_END_CHALLENGE_SEAL_LEGEND` | 도전 인장의 전설 | 결말 "도전 인장의 전설"에 도달한다. |  |
| `ACH_END_EVELYNS_COUNTERLEDGER` | 에블린의 역산 장부 | 결말 "에블린의 역산 장부"에 도달한다. |  |
| `ACH_END_ADAPTIVE_RIVAL_MASTERY` | 적응하는 숙적의 완성 | 결말 "적응하는 숙적의 완성"에 도달한다. |  |
| `ACH_END_CASTLE_WITHOUT_RESERVES` | 예비대 없는 성 | 결말 "예비대 없는 성"에 도달한다. |  |
| `ACH_END_TWELVE_ENDINGS_CHRONICLE` | 열두 결말의 연대기 (숨김) | 결말 "열두 결말의 연대기"에 도달한다. |  |

### 7. 3차 업데이트 전선 (세트 분리)
| API 이름 | 이름 | 조건 | 진행도 |
|---|---|---|---|
| `ACH_FRONT_FRONT_HERO_OATH` | 용사의 맹세 전선 돌파 | 용사의 맹세 전선을 끝까지 막아낸다. |  |
| `ACH_FRONT_FRONT_HOLY_PURIFICATION` | 성스러운 정화 전선 돌파 | 성스러운 정화 전선을 끝까지 막아낸다. |  |
| `ACH_FRONT_FRONT_GUILD_REPOSSESSION` | 길드 압류 전선 돌파 | 길드 압류 전선을 끝까지 막아낸다. |  |
| `ACH_END3_ENDING_HOLY_OPEN_GATE` | 열린 성문 | 3차 업데이트 결말 "열린 성문"에 도달한다. |  |
| `ACH_END3_ENDING_OFF_LEDGER_INDEPENDENCE` | 장부 밖의 독립 | 3차 업데이트 결말 "장부 밖의 독립"에 도달한다. |  |
| `ACH_END3_ENDING_LIVING_CASTLE_VOICE` | 살아있는 성의 목소리 | 3차 업데이트 결말 "살아있는 성의 목소리"에 도달한다. |  |
| `ACH_END3_ENDING_LINKED_CORRIDORS` | 이어진 회랑 | 3차 업데이트 결말 "이어진 회랑"에 도달한다. |  |
| `ACH_END3_ENDING_THREE_FRONT_ARMISTICE` | 세 전선 휴전 | 3차 업데이트 결말 "세 전선 휴전"에 도달한다. |  |

### 8. 4차 업데이트 의회 (세트 분리)
| API 이름 | 이름 | 조건 | 진행도 |
|---|---|---|---|
| `ACH_END4_ENDING_COUNCIL_SEAT` | 의회의 한 자리 | 의회 결말 "의회의 한 자리"에 도달한다. |  |
| `ACH_END4_ENDING_TWO_FLOORS_ONE_THRONE` | 두 층 하나의 옥좌 | 의회 결말 "두 층 하나의 옥좌"에 도달한다. |  |
| `ACH_END4_ENDING_MINION_WEARS_THE_CROWN` | 부하가 쓴 왕관 | 의회 결말 "부하가 쓴 왕관"에 도달한다. |  |
| `ACH_END4_ENDING_OUTPOST_BECOMES_HOME` | 전초기지가 집이 되다 | 의회 결말 "전초기지가 집이 되다"에 도달한다. |  |
| `ACH_END4_ENDING_THREE_RIVALS_COSIGN` | 세 숙적의 연서 | 의회 결말 "세 숙적의 연서"에 도달한다. |  |
| `ACH_END4_ENDING_COUNCIL_DISSOLVED` | 의회 해산 | 의회 결말 "의회 해산"에 도달한다. |  |
| `ACH_CROWN_CROWN_PUDDING_ROYAL_BASTION` | 왕실 보루 푸딩 | 왕관 진화: 왕실 보루 푸딩. |  |
| `ACH_CROWN_CROWN_GOB_MIDNIGHT_MARSHAL` | 한밤의 원수 곱 | 왕관 진화: 한밤의 원수 곱. |  |
| `ACH_CROWN_CROWN_PYNN_CASTLE_FLAME_SAGE` | 성의 불꽃 현자 핀 | 왕관 진화: 성의 불꽃 현자 핀. |  |
| `ACH_CROWN_CROWN_MORI_GRAND_MYCELIAL_PRIEST` | 대균사 사제 모리 | 왕관 진화: 대균사 사제 모리. |  |
| `ACH_CROWN_CROWN_TOKTOK_ROYAL_ARMORER` | 왕실 무구장 톡톡 | 왕관 진화: 왕실 무구장 톡톡. |  |
| `ACH_CROWN_CROWN_POPO_GRAND_NIGHT_COURIER` | 대야간 전령 포포 | 왕관 진화: 대야간 전령 포포. |  |


## 추가 14개 (10/17 사용자 요청: 100개)
| 세트 | API 이름 | 이름 | 조건 |
|---|---|---|---|
| base_campaign | `ACH_MILO` | 별 세 개짜리 마왕성 | 탐험가 밀로의 조사서를 "마왕성"으로 고쳐 쓰게 만든다(DAY 5 승리). |
| base_campaign | `ACH_NIA` | 보안 평점 A | 니아의 보안 재평가(DAY 6)에서 금고 손실 없이 승리한다. |
| base_campaign | `ACH_ENGINEERS` | 부실 공사 감별 | 왕국 공병이 처음 나온 날(DAY 20) 시설 무력화 없이 승리한다. |
| base_campaign | `ACH_PERFECT_CAMPAIGN` | 패배를 모르는 성 | 한 캠페인에서 한 번도 지지 않고 DAY 30을 끝낸다. |
| castle_builder | `ACH_MOVE_BUILDING` | 이사 전문가 | 건물을 누적 20번 옮긴다. |
| castle_builder | `ACH_GATE_BRIDGE` | 관문다리 | C등급에서 관문다리를 지키며 승리한다. |
| castle_builder | `ACH_VAULT_1000` | 금고지기 | 금고에 금화 1000 이상을 모은다. |
| monster_family | `ACH_LEVEL_10` | 고참 | 몬스터 하나를 레벨 10까지 키운다. |
| monster_family | `ACH_FIRST_JOIN_SCENE` | 새 식구 환영회 | 신규 몬스터의 합류 장면을 처음 본다. |
| monster_family | `ACH_ALL_BARKS` | 수다쟁이 성 | 몬스터 24종의 전투 대사를 모두 한 번씩 듣는다. |
| challenge_and_secret | `ACH_SPEED_X3_WIN` | 빨리 감기 마왕 | 속도 x3으로만 한 전투를 끝까지 이긴다. |
| challenge_and_secret | `ACH_SECRET_ZERO_FOOD` | 빈 창고 (숨김) | 식량 0으로 정산을 맞이하고도 다음 전투에서 이긴다. |
| challenge_and_secret | `ACH_SECRET_BATI` | 바티는 건조하다 (숨김) | 바티의 대사 100줄을 본다. |
| challenge_and_secret | `ACH_100` | 마왕성 완전 정복 | 다른 도전과제 99개를 모두 달성한다. |

## 구현 계획
1. GodotSteam(Godot 4 GDExtension) 추가, App ID 5267750, Steam 없이 실행해도 크래시 없게(오프라인 큐 → 다음 실행 때 전송).
2. AchievementService: 게임 이벤트 → 조건 판정 → 해제/진행도 stat 갱신. 세이브에 자체 기록 저장(Steam 실패해도 유지).
3. 기존 세이브 소급: 이어하기 시 엔딩·왕관·인장·합류·기억 기록으로 즉시 해제.
4. 아이콘 86개: GPT image_gen(귀여운 호러, 256×256), 잠김 아이콘은 Steam 자동 생성 사용.
5. 3언어 이름·설명(ko/en/zh_cn).
6. Steamworks 일괄 가져오기 파일 생성(정의·현지화·세트 배정) → 업로드·게시는 사용자.
7. 테스트: Steam 없는 환경 모의 해제, 실제 Steam 클라이언트에서 1개 해제 확인(사용자 PC).