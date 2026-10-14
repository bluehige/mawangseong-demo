## 2026-10-15 V130 M4 꾸미기·맵 가독성 보정 완료

[M4 인계·A1~A6 전후·기대값 이전·검증·삭제 목록](V130_MAP_M4_2026-10-15.md). `codex/v130-map-overhaul`, 의회 1층 0047 구현391c543/인계4c34d7e를 확인하고 시작했다. 구현·검증 **e2f86062be700f4c0763b6d6188e18411c23bd6a TARGETED_PASS**, 프로젝트/manifest 1.2.12 유지. 코드 SHA 이후 인계/CURRENT만 문서 커밋한다.

밝은 돌 포장길·하나의 석조 바닥/부지 경계·미해금 잠금·부지 폭 뒷벽·확장 후 전체 맞춤·3언어 성 이름/내부 결과 태그 정리·첫날 병영 이름표 회피를 완료했다. 기존 타일/화로·절차적 그리기만 사용, 이미지/음원 생성0. 전투 길·수치·자원·승급 조건·부지 해금 변경0.

6종 장식 팔레트·빈칸 클릭/네이티브 터치·가능/불가 미리보기·취소/제거/되돌리기·위압감·F~S 화면 평가, v6 배치/Continue·승급 좌표 보존을 연결했다. 성장 기본0/20/40/60 + 꾸밈 최대10의 표시 평가만 추가했고 실제 graph 등급/전투/해금에는 쓰지 않는다. 필수 승급의 새 방/길과 충돌하는 장식은 장식만 빈칸으로 옮긴다. 선행 의회 전환의 구 저장 현재/복원 스냅샷 지표 누락도 수정하여 실제 개인 v1~v5 복사본 Continue와 원본 보존을 회복했다.

표적 PASS: StageOne41/S1Followup131/StageTwo1091/U5-A280/B3259/C996/D11613/E19400/F5384/Perf9/M0 200회105137/M1 481/M2 DAY1 14928·DAY12 28041/M3 GUI 마우스111·터치116/M6 212/의회302/v5이관37/영어API16/M4 직접502·최종GUI506. M2의 폐기된 ‘의회 구 맵’ 기대값 1개를 실제 1층 그래프/경로 검사로 이전했으며 약화0·다른 기대값/원본 복사본 변경0이다. 전체 회귀·자연30일·별도 검수 에이전트 NOT_REQUESTED.

`tmp/v130_m4/` GUI 누적20/20, 실제 전후 비교 대표4장만 유지·원본/초안20장 삭제 목록/원장 기록. Godot 최대1·매 실행 전후0·종료0. 기존 import1423/무관UID31 보존·커밋 제외. push/fetch/PR/태그/배포/Sweep·갤러리0, 서버 main 읽기 조회1. 로컬 main 부재, origin/main 서버·캐시 일치만 확인했다.

다음: 헤드가 로컬 커밋·대표4장 검토/통합. M5 관전/미니맵·E18 그림·제품 버전 적용·정식 출시 검수/배포는 별도 범위다. 아래 의회/M6 및 이전 내용은 완료된 역사 기록이다.

## 2026-10-15 V130 의회 1층 서사·상층 제거 완료

[의회 1층 적용·검색 표·기대값 이전·검증·다음 작업 인계](V130_COUNCIL_1F_2026-10-15.md). `codex/v130-map-overhaul`, M6 `4be55fa`/`deb6d94` 확인 후 사용자 제안6절을 그대로 먼저 `4df43c1`로 커밋했다. 구현·검증 **391c5435e6eb1d0fb71bc3444acad661a2757bbe TARGETED_PASS**, 프로젝트/manifest 1.2.12 유지.

의회를 M6 자유 배치·폭2 자동 길에 연결했다. DAY16 보조 목표 개방, 등급 미달/포화 부지 임시 배치·진행 유지, 기존 등급 자격에 따른 +6칸 확장·실제 해금 날짜·확장 구역 이전을 적용했다. 상층3배치·계단 큐·층 탭/전환 키는 제거했다. 왕관실 실제 HP/억제/복구, 금고3초 경고/4초 수거와 기존 손실/회수, 베스퍼 실제 연결 경로를 검증했다. 새 속도/게임 수치/그림0.

E18 “넓어진 땅, 하나의 왕좌”: 개체별 출전 담당 구역 고정, 왕관실HP비율80·확장 생존비0.25·각1·실패0 유지. 내부 ID/E18/기존 보상·그림 보존. v6 구 층 큐/위치 폐기·HP/보상 이관·과거 실적 미환산·원본 보존·실제 DAY18 저장/Continue PASS. ko/en/zh_CN 연결 서사·목표 UI/경보·기록 이전 완료. 사용자 노출 잔존0, ID/경로64·숫자형식 오탐4.

의회 최종GUI **302 PASS**, 기존 30일 선택 서비스286, E17~E19 48/E20~E22 53, 데이터14/모드20/목표18/저장v5 37/전초26/포포19/베스퍼20/U5-B3145/C996/F5372/시설120/왕관이동202/기본지원253/절도190/연대기24/오디오9/그림60/관리행동·StageOne41 PASS. 통과한 기존 결과는 재사용하고 새로운 연결/실패/화면만 확인했다. 전체 회귀·자연30일전투완주·검수 에이전트 NOT_REQUESTED.

대표4장 `tmp/v130_council/`, 누적8/20·초안4장 삭제 목록. 최종포커스 재검사 추가캡처0. Godot 최대1·매실행 전후0·종료0. 기존 import/무관UID 보존·제외. **push/fetch/원격조회/PR/태그/배포/이미지생성/Sweep·갤러리0**. 로컬 main 부재·원격 최신 권위 미확정.

다음: 헤드 검토/통합, E18 새 1층 그림은 별도 후속 제작. M4·M5·정식 출시 검수는 별도 지시 범위다. 아래 M6 및 이전 내용은 완료된 역사 기록이다.

## 2026-10-15 V130 M6 저장 v6·부지 확장 완료

[M6 구현·개인 세이브 원본 보존·검증·길이별 측정·다음 작업 인계](V130_MAP_M6_2026-10-15.md). 사용자 지정 `codex/v130-map-overhaul`, M3 이력/인계 확인 후 `dbeb8c8`에서 시작. 코드·검증 SHA `4be55fac177e52d2dbd38e90a40c0dedff7554f0` **TARGETED_PASS**. 프로젝트/manifest 1.2.12 유지.

v6 우선 Continue, v1~v5 자동 변환, 부지 크기·자유 좌표/회전·해금 이력 저장, 자동 폭 2 길 재생성 완료. 손상 좌표/누락 왕좌는 원본 아카이브 후 안전 배치로 복원하며 정상 해금 날짜를 유지한다. 반복 실패마다 원본을 보존하고 v6 쓰기 실패/중단 복구·설정 프로필 전용 편집·새 게임 삭제를 연결했다. 기존 성 진화/요구치로 30×20→36×20→42×20→48×20, 기존 배치 보존·신규 구역 판정과 ko/en/zh_CN 안내를 제공한다.

실제 개인 v1~v5 5개는 tmp 복사본에서 Continue PASS, 사용자 원본 SHA256 변경0. M6 direct212/GUI209, StageOne41/S1Followup131/StageTwo1061/U5-A280/B3145/C997/D11613/E19400/F5480/Perf9, M0 200회105137/M1 481/M2 DAY1 14789·DAY12 27966/M3 마우스111·터치116 PASS. 기존 테스트 기대값 변경0. 전체 회귀·전체 플레이·별도 검수 에이전트 NOT_REQUESTED.

DAY1 동일 시드/수치/웨이브로 경로 991.74/1051.85/1111.95px 측정: 모두 25.57초 방어 성공(첫 교전2.03초, 왕좌 도달 전 격퇴). 게임 수치·밸런스 변경0, 후반 밸런스 결론으로 확대하지 않는다. 대표 캡처 `tmp/v130_m6/` 4장, 누적8/20·초안4장 삭제 목록 기록. Godot 단일/매 실행 전후0, 종료0. 기존 import1423/uid31/의회 제안 변경 보존·커밋 제외. **push/fetch/원격 조회/PR/태그/배포/이미지 생성/Sweep·갤러리0**. 로컬 main 부재·원격 최신 권위 미확정.

다음: 헤드 검토/통합 및 확정 의회 1층 서사 적용. M6는 상층/의회 상태를 보존하고 기존 의회 그래프를 선행 변경하지 않았다. 의회 적용에서 v6 해금 구역·등급 미달 임시 시설·상층 제거·E18 보상 기록을 연결/검증한다. M4 꾸미기·M5 관전 및 출시 검수/배포는 별도 범위다. 아래는 이전 작업의 역사 기록이다.

## 2026-10-15 V130 M3 배치 UI·첫날 튜토리얼 완료

[M3 구현·검증·캡처·다음 작업 인계](V130_MAP_M3_2026-10-15.md). 사용자 지정 `codex/v130-map-overhaul`, 기준 `be39d0a`; M0/M1/M2 포함 확인 후 작업. 코드·검증 SHA `f85510dab7a81872ae83e5420d5fbff3c475ecbb` **TARGETED_PASS**.

U5-B 카드/상세 재사용, 자유 좌표 고스트·실시간 자동 길의 녹색/불가 빨강, 즉시 설치+취소+1회 되돌리기, 이동·2방향 회전·철거 완료. S3-03 후보 위치 강조와 S3-04 실제 전투 탐지 구역 표시 흡수. 단계/필수 행동 13개를 보존하고 ko/en/zh_CN 안내를 현재 배치에 연결했다. 빈 건설 구역을 자유 위치로 옮겨 설치하며 기존 시설 제한·비용·HP/강화/정원/효과는 유지한다.

최종 실제 GUI 마우스111/터치116, 이동한 첫날 대상→첫 방어 시작 3언어×2입력 PASS. StageOne41/S1Followup131/StageTwo1061/U5-A280/B3145/C997/D11613/E19400/F5480/Perf9, M0 200회105137/M1 481/M2 DAY1 14823·DAY12 27974 PASS. S1Followup 기존 엔진 진단7건은 별도 기록. 전체 회귀/전체 플레이/별도 검수 에이전트 NOT_REQUESTED.

단일 Godot·매 실행 전후0·60FPS·격리 APPDATA. 캡처 누적 **7/20**, `tmp/v130_m3/` 대표4장만 유지·초안3장 삭제 목록 기록. 기존 import1423/uid31/의회 스토리 제안 변경 보존·커밋 제외. **push/fetch/PR/태그/배포/이미지 생성/Sweep·갤러리0**. 로컬 main 부재; origin/main의 정책/CURRENT 대체 조회와 원격 main SHA 일치를 확인했으며 이 CURRENT는 지정 브랜치의 상태 기록이다.

다음: 헤드 검토·통합, 별도 의회 상층→1층 전환, M4~M6. 배치는 런타임 source만 유지하며 Continue/v6 이관·재시작 복원·편집 부지의 등급 확장 연결은 M6 범위다. 아래는 이전 작업의 역사 기록이다.

## 2026-10-15 V130 ? ?? M0?M2 ??

[V130 ????????? ?????? ?? ??](V130_MAP_M0_M2_2026-10-15.md). ??? ?? `600f936`?? `codex/v130-map-overhaul` ??. M0 ?2 ?? ??200/200?105137 checks, M1 1920/1280 ?485, M2 DAY1/DAY12 ?? ????? ?? ? ??10? **TARGETED_PASS**. ??? ?? SHA `4038067586916b7c4ad95f63b35500bbe136ed2f`; ?? ?? ??? ????. ??4??/??17?, Godot ??0. **push ??**.

??: M3 ?? ?? UI?????, ??? ?? ??? ??? ?? ? ?? ??, M4~M6. ?? ????? ?????? ?????? ?????? ?? ??0. ?? ?? Continue/?????? ?? ???. ?? main ??/?? ??? ???. ?? ?? ?? ??28??/3???? PASS. origin/main ?? ??? ?? ?? ?? ?? ??3??? ?? FAIL(??7?), ?? main PR ? ?? ??. ??? ?? ??? ?? ??.

## 2026-10-14 V1213 U5-F · 설정·기록 + S5-05 BGM 순환 완료

[상세 인계·테스트 표·대표5장·삭제14목록](V1213_U5F_SETTINGS_2026-10-14.md). `codex/v1213-fix-plan` / 시작 `437a83803790bd94cd707ccf465c9e49da1048de` → 구현·검증 **41bb5c5c03d45711483f53a9f81b1621c199d17b TARGETED_PASS**. 제품1.2.12 유지. 이후 인계/CURRENT만 영어 로컬 문서 커밋한다. 문서 포함 최종 SHA는 git log/대화에서 확인한다. **push 금지 유지**.

B 설정5분야·기존 왕좌 배경/반투명 카드/기존 그림, 연대기 접근성 편집 제거→같은 설정 바로가기. 일반 설정은 settings.cfg, 접근성은 기존 캠페인 프로필의 draft→적용/취소·실패 재시도·재실행/원래 메뉴 복귀. 타이틀은 저장된 v5 프로필의 접근성만 바꾸고 active_run/다른 프로필/기록은 보존한다. 저장 없는 첫 실행은 기존 캠페인 접근 조건을 유지하고 새 게임 후 조절 안내; 일반 설정은 바로 적용. 읽기 전용 엔딩/연대기 기록실·동료 기억/도감/선택 위치 복귀, 미해금 기록/엔딩 이름·본문·그림 비노출, 반복 로그/기록 읽기 이벤트 재실행0. 게임 메뉴는 기존 행동의 이름 있는 B 버튼이다.

S5-05: data/audio 후보 데이터 + 기존 장곡만 타이틀2/관리2/전투3/일반 결과2/최종 엔딩1곡, 5곡 대비 부족3/3/2/3/4. 같은 파일 연속 선택 방지·종료 전0.65초 크로스페이드·재구성/전투 갱신 유지·정지 복귀/종료 정리. 최종 단곡 native loop. 신규 음원/이미지 생성·상층 화면·게임 규칙·저장 스키마·버전 변경0.

지정 headless **10종 PASS**: StageOne41 / S1Followup131 / StageTwo1053 / U5-A280 / U5-B3115 / U5-C997 / U5-D11613 / U5-E19400 / PerfFreeze8 / 신규 U5-F5480. 기존 can_process 진단7건과 의도한 저장 실패 WARNING 구분. U5-A 종료 자원 오류는 오디오 정리·효과음 차단·짧은 종료 유예 후 일반 실행2회 오류0으로 해결했다. 기록실 복귀 컨텍스트의 마지막2줄 보정은 신규 U5-F/최종 GUI로 검증했다. 최종 GUI **5399 PASS**, ko/en/zh_CN ×1920/1280 변경 화면·본문/목록 tail·메뉴·첫 실행 안내 확인. 오디오는 headless 순서/전환 로그만, 실제 소리 측정 미실행.

단일 Godot·각 실행 전후0·max-fps60·격리 APPDATA. GUI 누적 **19/20장**, 대표 **5장 유지/14장 삭제**(`tmp/v1213_u5f/`). 로그/JSON/PNG 미추적. 기존 import1423/uid31 보존·커밋 제외. 로컬 main 부재; origin/main 정책·CURRENT 및 서버 main 일치를 읽기 확인했으며 지정 HEAD에서 작업. Sweep/갤러리/전체 플레이·추가 전체 회귀/Q·별도 검수 에이전트/export/Steam/푸시0. 읽기 전용 곡 조사 보조만 실행했다.

다음: 헤드가 구현16경로+인계2경로/대표5장/검증 SHA 검토·통합. push 금지 유지. S5-03/04·Q·상층 제거·음원 추가/출시는 별도 범위다. 아래 U5-E/D 등은 완료된 과거 기록이다.

## 2026-10-14 V1213 U5-E · 결과 화면 시안 대비 시각 보정 완료

[보정4항목·지정9종·대표4장·삭제8경로](V1213_U5E_RESULT_2026-10-14.md#u5e-polish). 사용자 지정 HEAD `e1d798ea148e1e95bdfa79aed14a84f12a98e204`(U5-E 구현33656cd/인계06f7b46 및 U5-D 보정 포함)에서 시작, `codex/v1213-fix-plan` / 제품1.2.12 유지. 최종 구현·검증 **81685384e820c9f5d696c5a99aed2a06f41cb847 TARGETED_PASS** (`Polish combat result visuals to match the approved mockup`). 이후에는 인계/CURRENT2파일만 영어 로컬 문서 커밋한다. 최종 문서 SHA는 git log/대화에서 확인한다.

기존 U5-D 왕좌 배경·반투명 패널/패배 어두운 톤, 중앙 큰 DAY/결과 제목·왕좌 피해/생존 한 줄, 기존 최대 해상도 입상3종·금화/마력/악명 아이콘 숫자 카드. 성과를 동료/피해/회복/보호/합동기/EXP/비고7열로 바꾸고 0은—·영구 EXP 전후/증가량·선택됨 칩/예약 DAY효과를 표시한다. 방어막/대신 받은 피해/시설/공유·활약 EXP/지원 숙련/Lv/돌파 구간은 툴팁·상세 기록에 보존한다. 하단은 같은 동료 훈련의 금화30/EXP+20/다음 DAY 실행 카드·성장 확인·큰 다음 DAY/엔딩 버튼, 최종/패배와 기록 없는 준비 성공의 안내를 유지한다. **보상·EXP·집중성장·훈련/저장·대화/날짜/엔딩/재도전 흐름·게임 수치·스토리·자산 바이트·이미지 생성 변경0**.

지정 headless9종 S1 **41** / S1Followup **131** / S2 **1041** / U5-A **280** / U5-B **3115** / U5-C **997** / U5-D **11613** / U5-E **19400** / PerfFreeze **8** 전부 PASS. S1Followup 기존 can_process 진단7건 구분. S1/S1Followup은 버튼 여백·빈 기록 안내 보정 전 결과 재사용, 그 뒤 S2/U5-E를 재검사했다. 최종 GUI **12891 PASS**, ko/en/zh_CN ×1920×1080·1280×720의 승리/선택/확인/패배/최종·상세/목록 끝 라벨 잘림·조작 요소 겹침·번역잔여0. 첫 영어 최종 제목 경계3건 및 S2 간체 상세 버튼 여백1건은 수정·재검사하고 실패 로그를 보존했다. 자연 전체 플레이·추가 전체 회귀·검수 에이전트/export/Steam은 미실행.

단일 Godot/각 실행 전후0·max-fps60·격리 APPDATA. `tmp/v1213_u5e_polish/` GUI 누적 **12/12장**, 대표 **4장만 유지 / 8장 삭제**. 한국어 확인 완료 대표1장은 마지막 상세 버튼8px 여백 보정 전이며 나머지3장은 최종 코드 캡처; 현재 코드의 여백/경계는 최종 GUI에서 모두 확인했다. 보상 고정 fixture와 캡처 시점 차이는 인계에 명시했다. 기존 캡처·import1423/uid31 보존·커밋 제외, 로그/JSON/PNG 추적0. 로컬 main 없음/원격 최신 권위 미확정 유지, 캐시 origin/main 문서를 읽고 지정 HEAD에서 진행. **push/원격 조회/fetch/PR/tag/새 이미지/Sweep·갤러리/배포0**.

다음: 헤드가 이번 보정5경로·검증 SHA·대표4장을 검토/통합. push 금지 유지. 다른 U5·기본형 새 승리 그림·출시는 별도 지시 범위다. 아래 U5-D 및 최초 U5-E 기록은 역사로 보존한다.

## 2026-10-14 V1213 U5-D · 시안 대비 시각 보정 완료

[보정5항목·지정9종·대표5장·삭제10경로](V1213_U5D_MONSTER_2026-10-14.md#u5d-polish). `codex/v1213-fix-plan` / 시작 HEAD06f7b46816e3c290609ea36e756d853e94b5ea12 → 최종 구현·검증 **7aecca00c3c2622d78c1dc88518e501c7ba08a14 TARGETED_PASS**. 영어 로컬 구현 커밋 뒤 인계/CURRENT2파일만 후속 영어 로컬 커밋한다. 제품1.2.12 유지. git log로 사용자0036 U5-E 구현33656cd/인계06f7b46 이후임을 확인했으며 결과 화면과 U5-E 파일은 보존했다.

기존 대화용 왕좌 배경·반투명 표면, 큰 현재형 초상/받침과 이름·역할·Lv·유대 블록, EXP 전후/능력치3행/금화·EXP·횟수 카드와 성장/준비효과 칩·불가 사유 부제의 큰 고정 훈련 버튼. 전직 후보별 미리보기와2열 충족/미충족 조건 칩·요구유대0 숨김·항상 보이는 확정 버튼, 스킬·합동기·기억·도감 카드/칩 문법을 보정했다. 기존 실행 콜백·게임 기능/수치/해금/저장·스토리/데이터/자산 픽셀·버전·이미지 생성 변경0. 축약 상세는 접근 가능한 툴팁으로 보존한다.

최종 headless9종 S1 **41** / S1Followup **131** / S2 **1041** / U5-A **280** / U5-B **3115** / U5-C **997** / U5-D **11613** / U5-E **11697** / PerfFreeze **8** 전부 PASS. S1Followup 기존 can_process 진단7건 구분. 실제 최종 GUI **7017 PASS**; ko/en/zh_CN ×1920×1080·1280×720 변경6화면의 라벨/고정 버튼/탭·본문/큰 초상 경계 및 기본 전직 조건 전체 표시·번역잔여/대체문자 문제0. 정상 장문/목록 스크롤은 구분. 자연 전체 플레이/추가 전체 회귀/검수 에이전트/실기 터치/장시간 성능/export/Steam 미요청·미실행.

단일 Godot/각 실행 전후0·max-fps60·격리 APPDATA. `tmp/v1213_u5d_polish/` GUI 누적 **15/16장**, 최종 대표 **5장만 유지 / 초안10장 삭제**; 재검사 캡처0. 기존 U5-D 캡처 및 `.import`1423·`.uid`31 보존·커밋 제외. 추가 초상 검사 대상 오류60건과 전직완료 fixture의 중복 안내에 따른 조건 공간9건은 수정·최종 재검증했으며 실패 이력을 인계/로컬 로그에 보존했다. 로컬 main 없음/원격 최신 권위 미확정, 현재 지정 HEAD에서 진행. **push/원격 조회/fetch/PR/tag/이미지 생성/Sweep·갤러리/배포0**.

다음: 헤드가 대표5장·관련7경로·검증 SHA를 검토/통합. U5-E 결과→같은 동료 훈련은 아래 기록대로 완료 상태이며 별도 지시 시 U5-7 설정·기록. 아래 U5-E 및 이전 U5-D 기록은 완료된 과거 작업으로 보존한다.

## 2026-10-14 V1213 U5-E · 결과 연결 화면 교체 완료

사용자 지정 `codex/v1213-fix-plan` 기준37a30ea에서 IA U5-6/D-U2-06/S5-01/02 완료. [상세 인계](V1213_U5E_RESULT_2026-10-14.md). 제품1.2.12/버전 태그 보존. 구현·검증 SHA `33656cd1c6f2aa350c9e9e2d8afdbe6305adc167` (영어 로컬 커밋); 이후 인계/CURRENT만 후속 커밋한다.

기존 승리/초상과 Style B 동료 성과·공격/회복/보호/방어막/대신 받은 피해/합동기·EXP 전후 바 → 집중성장+8 → 수동 성장 확인 → 기존 다음 DAY 대화·관리 → 같은 동료 훈련 탭1클릭 연결. 결과에서는 금화30/EXP+20·준비 DAY의 미리보기만 제공하고 실제 훈련은 원래 몬스터 관리 상태에서 실행한다. 새 계산·보상/EXP/비용/저장 구조/이미지 생성 변경0. 기본형 푸딩/곱/핀 승리 전용 variant 없음은 기존 초상으로 대체해 인계에 목록 기록. 최종전 집중성장/다음 DAY 훈련 약속 없음, 패배 재도전 경로 보존.

지정 headless9종 S1 41/S1후속131/S2 1041/U5-A280/U5-B3115/U5-C997/U5-D3740/Perf8/신규 U5-E11697 PASS. S1후속 기존 can_process 진단7건 구분. 최종 변경 GUI11656 PASS; ko/en/zh_CN ×1920/1280/2560 결과·선택/확인/상세/패배/최종 및 스크롤 아래 동료의 줄/글자·버튼·주요 패널 겹침·외국어 한글 잔여/깨짐0. 실제 날짜 대화와 엔딩·훈련30/+20/당일 횟수·준비 DAY 직접 확인. 자연 전체30일/전체 회귀/Q/검수 에이전트/export/Steam은 미요청·미실행.

모든 Godot 실행 단일1개/전후0·max-fps60·격리 APPDATA. GUI 총10/20장 후 `tmp/v1213_u5e/final/capture/` 대표4장만 유지, 앞선6장 삭제 목록은 인계 및 `tmp/v1213_u5e/deleted_capture_files.txt`. 관련7경로 영어 로컬 구현 커밋 후 문서2경로만 후속 커밋, **push 금지**. 기존 import1423/uid31 보존·커밋 제외. 로컬 main 없음; origin/main 정책/CURRENT를 읽고 `git ls-remote`로 서버 main=캐시0ac9fdc 확인, 요청 브랜치 서버 ref 없음. fetch/PR/태그/배포0. 이 CURRENT는 지정 브랜치의 상태 기록이다.

다음은 헤드 U5-E 대표4장/관련9경로 검토·통합, 별도 지시 시 IA U5-7 설정·기록. S5-03/04/05 및 Q는 별도 범위. 아래 U5-D 이후 기록은 과거 진행 기록으로 보존한다.

## 2026-10-14 V1213 U5-D · 몬스터·동료 Workspace 교체 완료

[구현·지정 검사·대표6장·삭제19개·그림 대체 목록](V1213_U5D_MONSTER_2026-10-14.md). 사용자 지정 `codex/v1213-fix-plan` 최신 시작 `8ec51b425c6a5b86dbe06ade6eac7a18dee95dba` → 구현/검증/체크리스트 **dde3506dbefc6e6e34e0fb5f0a56307ab011d32e TARGETED_PASS**, 제품1.2.12 유지. IA U5-5 및 S4-01~09: 좌측 고정 보유/도감 목록·우측 훈련/스킬/전직/합동기/기억5탭, 실제 EXP바/횟수/장 상한/최근 훈련 결과, 해금 전 기존 진화·합동기 데이터/현재 조건·승급 누적 총원과 다음 확대, 유료+20/무료 집중성장+8와 다음 DAY 준비 구분. 실제 유대 기억·회차 계승의 파일 저장/새 GameRoot 복원, 합동 기억 누적 조건→해금→편성 signal 및 계약 선택/취소/예비 전환을 검증했다. 미해금 다음 회차5종은 기존 초상의 실루엣·역할·조건만 노출하며 이름/서사/엔딩과 첫 회차 인원 증가0. 기존 비용·해금·저장 스키마·성장 함수/튜토리얼 계약 유지.

지정 headless8종: S1 41/S1후속131/S2 1039/U5-A280/U5-B3115/U5-C997/Perf8/U5-D 마우스3740·터치3488 PASS. S1후속의 기존 can_process 진단7건 구분. 실제 변경 GUI3659/3419, 영어1280 터치 도감3419 PASS; ko/en/zh_CN ×1920/1280/2560 줄/글자·버튼·부모 경계 및 목록/탭/본문 겹침0, 번역 잔여/깨진 문자0. 정상 스크롤의 부분 행 가림은 구분. 실제 PNG에서 발견한 영어 도감/목록 버튼/계약 카드 경계 초과와 EXP 툴팁/왕관 확장 설명 번역은 보정 후 재검증했다.

Godot 모든 실행 단일1개/전후0·60FPS 상한·격리 APPDATA. GUI25/30장 생성 후 tmp/v1213_u5d/ 대표PNG6장만 유지·19장 삭제 목록 기록. 소스/검증/체크리스트12경로 영어 로컬 커밋 후 인계/CURRENT2경로만 후속 커밋. **push 금지**, fetch/원격 조회/PR/태그/이미지 생성/Sweep·갤러리/전체 검수/전체 플레이/export/배포0. 기존 import1423·uid31 보존·커밋 제외, 로컬main 부재/원격 최신 권위 미확정 유지. 다음은 헤드의 U5-D 검토 및 별도 지시 시 IA U5-6 결과 연결이다. 아래는 과거 U5-C 등 기록이다.

## 2026-10-14 V1213 U5-C · 전투 HUD/관리 안내 시안 보정 완료

[보정6항목·기존 아이콘 대체·검증·대표6장·삭제11개](V1213_U5C_COMBAT_HUD_2026-10-14.md#u5c-polish). 사용자 지정 **3cc86a0426ac56667c4a27eb060917b4880ad106**에서 시작, 최종 구현·검증 도구 **4b4b49f3eb8769774cb918ef95b2c096fc1bebca TARGETED_PASS**, codex/v1213-fix-plan / 제품1.2.12 유지. 하단을 정책 칩2개+정사각형 즉시 행동 한 줄로 통합하고 CP비용·흐림/자물쇠, 기존 그림의 행동별 아이콘과 미장착 합동기 잠금을 표시했다. 상단 설정·메뉴/저장/기록3아이콘, 큰 초상/이름/HP바/고정 대표 스킬과 접힌 상세, 실제 전투를 어둡게 깐 반투명 Style B 컷신 띠/버튼을 보정했다. U5-B 일반 건설의 클릭·드롭 즉시 설치/되돌리기 동작은 기존대로이며 안내를 ko/en/zh_CN 즉시 설치 의미로 수정했다. 별도 시설 교체 확정 경로와 전투 중 저장 거절/마지막 체크포인트 계약은 보존한다. 게임 규칙·비용·명령 효과·AI·저장·새 이미지 변경0.

최종 headless S1 41/S1후속131/S2 1027/U5-A280/U5-B3115/U5-C 마우스997·터치1024/Perf8 PASS. S1후속의 기존 can_process 진단7건 구분. 실제 최종 GUI HUD936/963·관리172 PASS. 자동 줄 수 검사에서 놓친 CP라벨 누출을 직접 캡처로 발견하고 라벨 경계 검사·최소 높이 재배치·긴 문구 공간으로 해결했다. 새 GUI16/16장, tmp/v1213_u5c_polish/에 **정상 최신5장+기존 HEAD 비교본1장**만 보존; 삭제11경로 목록/실패 이력 기록. 비교본은 기존 PNG 복사이며 새 캡처가 아니다. 모든 실행 단일 Godot/전후0·60FPS 상한. 독립 깃발/달리는 인물/개별 기술·합동기 전용 아이콘은 없어 감시탑 깃발·속도 화살표·기존 계열 그림으로 대체했다.

관련 구현·도구11파일 영어 로컬 커밋, 이후 인계/CURRENT만 후속 로컬 커밋. push/원격 조회·fetch/PR/태그/이미지 생성/Sweep·갤러리/전체 검수·전체 플레이/장시간 측정/export/배포0. 기존 import1423·uid31·v20 자료/원래 tmp/v1213_u5c 캡처 보존, 로컬main 부재/원격 최신 권위 미확정 유지. 다음은 헤드의 시안·대표6장·아이콘 대체 검토/통합이며 다른 U5/배포는 별도 지시 범위다. 아래는 최초 U5-C 및 과거 기록이다.

## 2026-10-14 V1213 U5-C · 전투 HUD 실제 교체 완료

[구현·관련 검사·대표 6장·운영 제한](V1213_U5C_COMBAT_HUD_2026-10-14.md). 오케스트라 0031 / 사용자 지정 시작 **0213a5f3f8447a6dad883b9da102b2dfe7b650bd**, 최종 구현·검증 도구 **9a6019d899f11619cf04828dda9fe8a2a100864a TARGETED_PASS**, codex/v1213-fix-plan / 제품 1.2.12 유지. 0030은 U5-B 작업 번호이며 e758e76 구현·0213a5f 인계를 포함한 HEAD에서 시작했다. U5-B/U4 공통 부품으로 상단 HP/명령/마력/남은 적, 펼침형 성 전체·이 방 정책, 하단 명령/선택 스킬/심장·합동기, 우측 제한 높이 상세, 고정 정지·배속·층 버튼을 교체했다. 실제 HUD 입력 경계·다른 층 선택 정리·중복 메뉴 제거·튜토리얼 ID 연결, 로그 이전 정지 복원, 컷신 Canvas40과 HUD/지원 알림 숨김·피해 숫자 표시/풀 복귀를 검증했다. 기존 비용/대상/스킬 효과/자동 AI/밸런스/저장/자산 바이트 변경 없음.

지정 headless S1 41/S1후속131/S2 991/U5-A280/U5-B3115/Perf8, 신규 U5-C 마우스808·터치815 전부 PASS. S1후속 기존 can_process 진단7건 구분. 최종 GUI755+762 PASS, ko/en/zh_CN·1920/1280의 관련 표시·고정 조작 겹침0; 긴 내용/다수 행동은 정상 스크롤이다. 기본 마우스 HUD 차감 가시 면적80.3117%; 열린 상세·터치에서80%를 주장하지 않는다. GUI 누적15장/상한30, tmp/v1213_u5c/에 대표 PNG6장만 유지하고 초안9장 삭제 목록 보관. 단일 Godot·실행 전후 tasklist0·60FPS 상한, 실제 창 성능 측정0회. 초기 실패/발견·보정은 인계에 보존했다.

관련 구현10파일 영어 로컬 커밋, 이후 인계2파일만 변경한다. push/PR/태그/이미지 생성/전체 Sweep·갤러리/2560 GUI/전체 검수/전체 플레이/export/배포0. 기존 혼합 import1423·uid·v20 자료 보존, 로컬main 부재/원격 최신 권위 미확정 유지. 다음은 헤드의 U5-C 검토·통합이며 새 구현은 별도 지시 시 IA U5-5로 이어간다. 아래는 U5-B 및 과거 제품 기록이다.

## 2026-10-14 V1213 U5-B · 지도·건설 상세 시각 보정 완료

[보정 원인·변경 파일·최종 검사·대표 4장](V1213_U5B_MANAGEMENT_2026-10-14.md#11-시안-대비-지도건설-상세-보정--2026-10-14). 사용자 지정 기준 b9a29872c73e68f9313e2afa213a0c098b8b4512, 최종 게임·검증 도구 **e758e7674cd7276ea03380c831cb1d9baddef696 TARGETED_PASS**, codex/v1213-fix-plan / 제품1.2.12 유지. 관리 동굴 배경의 월드 좌표 고정 사각형을 전체 viewport 표시로 보정하고 지도 카메라와 분리했다. 기본 지도 전체 렌더 범위는1690.038×874로 확대·중앙 맞춤, 기본 가시 면적85.6462%(HUD 가림 합집합 차감), 기본 방 바닥/HUD와 선택 상세/HUD 겹침0. 건설 카드 선택 상세에 기존 시설 그림·실제 이름/비용·효과 한 줄·배치 현재/최대·즉시 설치 안내를 ko/en/zh_CN로 표시하며 기존 경로/경고·유효 대상 강조·고스트 유지. 건설 도구를 열 때 좌측 공간을 예약해 대상 그림이 팝업 밖에 보이게 했다.

지정 headless S1 41/S1후속131/S2 977/U5-A280/U5-B3115/Perf8 전부 PASS. S1후속 기존 can_process7건은 구분; 초기 팝업 입력 차단·튜토리얼 카메라 재맞춤 회귀와 일시적 테스트 입력 실패 기록을 보존하고 최종 재검증했다. GUI360 PASS, 캡처4+4=누적8장(상한12), tmp/v1213_u5b_polish/에 최종 대표PNG4장만 유지·초안 삭제 목록 기록. 단일 Godot/매 실행 전후0개·60FPS 상한 준수. 게임 규칙·비용·밸런스·저장·스토리·이미지 생성·Sweep·갤러리·export·전체 검수·push0. 다음은 헤드의 보정·대표4장 검토/통합; U5-4 전투 HUD나 배포는 이번 범위 밖이다. 기존 혼합 import/uid/v20 자료 보존, 로컬main 부재/원격 최신 권위 미확정 유지. 이 SHA 뒤에는 인계 문서2파일만 변경한다. 아래는 최초 U5-B 및 이전 제품 기록이다.

## 2026-10-14 V1213 U5-B · 관리·출진 Workspace 교체 완료

[완료 조건·파일·표적 검사·가시 면적·남은 차이](V1213_U5B_MANAGEMENT_2026-10-14.md). 사용자 지정 codex/v1213-fix-plan / 기준2fb7f8c, 최종 게임·검증 도구 SHA **c0200cfe37b60f0c65bd3c1d53caa8c9473183d1 TARGETED_PASS**. 제품1.2.12 유지. 실제 기본 Workspace를 Style B 자원 바·5항목 독·접이식 작업/상세로 교체했다. 비용/효과/실제 경로/고유 시설 이전 영향을 먼저 표시하고 위치 클릭/드롭/Enter는 기존 확정 함수로1회 설치한다. 기존 정원·비용·경로·되돌리기·고정/DAY1 제한 유지. 자동 침입 예고 통합, 전체 예고 읽기 진입 보존, 출진3초 지도 위 띠/취소/입력 잠금, ESC 취소/초점 복원과 튜토리얼 ID 유지.

S1 41/S1후속131/S2 977/U5-A280/Perf8/U5-B2289 PASS. S1후속의 기존 can_process7건은 구분했다. 기본 지도 가시 면적 **85.6462%**(실제 HUD/버튼 가림 합집합 차감); 카드/상세 펼침은75.73/66.66% 등 별도 기록이다. ko/en/zh_CN ×1920·1280 관련 표시 검사, 관리 GUI 누적30장/대표PNG6장만 유지. 영어 상세 폭·경로 글자 보정 및 긴 내용 스크롤 구분. tmp/v1213_u5b/에 증거를 두며 전체Sweep·갤러리·2560GUI·장시간 측정·전체회귀·새이미지·export·push0. 최초 콘솔 런처 동반 프로세스 발견 후 본체 직접 실행으로 변경했고 이후 단일 엔진/전후0개 확인.

다음은 헤드의 U5-B 검토·통합과 IA U5-4 전투 HUD다. 이번에는 로컬 커밋만 한다. 이전 UI 계약의 V122ManagementInteractionTest는 향후 별도 전체 회귀 통합에서 갱신해야 한다. 로컬main 없음/원격 최신 권위 미확정·기존 혼합 import/uid와 v20 미추적 자료 보존. 아래의 이전 제품/성능 기록을 현재 U5-B 결과로 덮어 해석하지 않는다.

## 2026-10-14 긴급 P1 성능 조사 · 보호 수정 / 환경 판정 분리

[전후 수치·1초 기록·표적 검사·남은 제약](V1213_PERF_FREEZE_2026-10-14.md). `codex/v1213-perf`, base/HEAD `a21556c1155a6bceec084c1796ea33bdd58db89b`, 제품1.2.12 유지, 새 커밋·push·원래 작업본 수정0. VSync해제 무제한4200FPS/GPU86%를 측정하고 기본120/비활성30FPS 상한 및 동일 tutorial 재사용을40줄로 수정. 동등Vulkan/--disable-vsync/--max-fps60에서 관리60·전투약59.6FPS 유지, 고정 HUD 생성 호출당 비용92.9% 감소·반복label fitting0. S1 41/S1FU131/S2 907/신규8 PASS, desktop29/49·touch29/50 Sweep 및 표시스캔0지적. Native120→30→120 exit0/잔류0. 이후 Vulkan/VSync1FPS는 수정 전 및 최소엔진에도 재현돼 기본VSync 최종 정상판정과 원사용자 PC멈춤 유일원인 확정은 **PARTIAL**. 초기 수집기 종료 race와 최종 재검증은 보고서에 구분. 다른 writer의 GUI/headless는 종료하지 않고 시작 거부/대기, 최종GUI동시1개. 헤드는 정상디스플레이/VSync 재확인 뒤 patch 통합 및 제품SHA 바인딩. 로컬main 없음/원격최신권위미확정 유지. 아래 기존 인계 보존.
## 2026-10-14 V1213 U5-A · 타이틀·대화 완료

[완료·검증·제한 인계](V1213_U5A_TITLE_DIALOGUE_2026-10-14.md). `codex/v1213-fix-plan`, 미검증 WIP `cd9cd8f` 위에서 구현 `3cf3b2b`·검증 `58124ebce2cc5afdc203bfe4c0e2817b67e748aa` TARGETED_PASS. 제품1.2.12/브랜치 유지. 중앙 메뉴 폭520·글자36·큰 아이콘, 우하단 지구본+즉시 저장 언어 묶음, 작은 업데이트 내역/흐린 버전. 대화3계통은 본문40(하한32)/화자28(하한26)·큰 좌우 그림·자리 유지·청자0.5·가슴 높이 바티·도구 라벨/자동 강조/미독 자물쇠·반투명 띠/중앙·모서리 보석으로 마감했다. 버튼 스크립트의 실행 시점 로드와 안전한 지연 초점으로 종료 자원 진단/제거된 버튼의 초점 오류도 수정했다.

U5-A281/S1 41/S1후속131/S2 919/키트75 PASS, 후속의 기존 can_process7건은 구분. 3해상도×3언어45캡처 및 데스크톱/터치29화면씩49+50캡처 표시 스캐너 오류0. 새 게임→DAY1 관리 실제8클릭, 전체 첫DAY/30일 클릭 목표 달성으로 확대하지 않는다. 비교 `tmp/v1213_u5a/compare_title.png`, `compare_dialogue.png`; 가로1280 이하 JPG12장만 확인했고 큰 PNG를 직접 열지 않았다. [별도 입상 미보유29개와 기존 초상 대체](../design/v1213_uiux/U5A_PORTRAIT_FALLBACKS.md). 바티8종 실제 알파 확인·구 런타임 참조0. Godot 전부 종료, project.godot/.import 변경0, 기존 미추적v20_map_builder 보존. 전체 캠페인·전체 회귀·export·배포·push 없음.

다음은 헤드의 U5-A 통합 및 IA 순서의 U5 관리 화면이다. 개별 신규 입상/엔딩 배경은 후속 자산 범위이며 이번 종료 조건이 아니다. 로컬 main 참조는 없지만 origin/main `0ac9fdc7`과 원격 main 일치는 확인했다. 이 브랜치 기록을 공개 제품의 main CURRENT로 간주하지 않는다. 아래는 이전 시점 기록을 보존한다.

최종 기준 SHA는 `3aa052d5b83e5d7fe8f0f588c0f6240871b3e3aa`다. 검증 도구/게임의 마지막 변경은 위 `58124eb`이며, 뒤에는 저장소 정책 검사를 위한 기존 시안 문서4개/CURRENT 끝 빈 줄7개, 출처5문서의 버전/경로 형식과 원본4개의 바이트 동일 보존 사본을 정리했다. 런타임 기능/그림/도구는 그대로다. 이후에는 docs/handoff/ 문서만 변경한다.

`ValidateRepositoryPolicy.ps1 -BaseRef origin/main -HeadRef codex/v1213-fix-plan`도 PASS(601파일·108커밋, e86c71b 기준). 검사 뒤에는 이 통과 결과를 docs/handoff/에만 추가 기록했다.

## 2026-10-14 V1213 U4 fidelity · 시안 B 크기·표면·실제 아이콘 보정

[측정·보정·검증 SHA·잔여 차이](V1213_U4_FIDELITY_2026-10-14.md), [새 토큰표·사용법](../design/v1213_uiux/U4_UI_KIT.md). 사용자 지정 `codex/v1213-fix-plan`, 기준42b5b77/제품1.2.12 유지. 구현 **`e02bc45004635562c4db900d67c211cd21e9550f` TARGETED_PASS**. 기존51b54be의 작은 크기/임시SVG/평면 표면과4페이지 축소 비교를 대체한다. 네 시안1920 측정 원장, 버튼70·탭78·독96·본문26·아이콘56/타일84·HP/EXP24px, 저비용 단일 패스 세로 보라 그라데이션/glow/이중선/상단 하이라이트·선택 다이아/모달 보석. 실제 GPT32종64/128 PNG64개636452bytes 매핑·SOURCE Runtime64경로·임시SVG5개 제거. 기존 화면 UIStandard의 원래 치수/atlas·게임/저장/UIFont는 보존했다.

실제1920×1080 한 화면 kit/관리strip/상태 렌더와 전체3840×1080 좌우 비교, 두 차례 이상 직접 보정. **38치수/최대오차6.38%·75부품 계약 실패0**, S1 41/S1후속131/S2 907·Sweep29화면×2 49/50캡처 스캐너0. 엔진FPS60, 짧은120프레임 elapsed 계산약61.02(경계 오차 포함); 장치전체GPU32표본0~22%/중앙13%, 전용 Godot 사용률 아님. 근거 **`tmp/v1213_u4/fidelity/compare_kit.png`**, **`compare_management_strip.png`** 및 같은 폴더 로그/JSON. 빈 툴팁 경고1회·S1후속 기존진단7회는 구분했다. 전체회귀/전체플레이/export/개인세이브/push0. 초기 GPU표본은 성능 작업자의 실행과 겹쳐 제외하고, 이후 단일 GUI 시작 차단/대기로 최종 검증했다. 이 작업본의 Godot 종료; 다른 성능 worktree/프로세스 보존.

남는 시각 차이는 배경·마스코트·타이틀 아트·미세 문양/폰트 외곽선·시설 그림·아이콘 형태/배색·HP 빨간 미충족 구간이며 인계/키트 문서에 명시했다. 기하/기능 통과를 픽셀 동일성으로 해석하지 않는다. 다음은 헤드의 잔여 장식/기호 범위 결정과 **U5 실제 화면 연결**, 별도 성능 수정 독립 통합이다. 기존 미추적v20_map_builder 보존. 로컬main 부재/원격 최신성 미확정 유지. 아래는 이전 시점 기록이다.

## 2026-10-14 V1213 U4 공통 UI 부품 · 스타일 B

[U4 구현·검증·제한](V1213_U4_UI_KIT_2026-10-14.md), [부품 API·토큰표](../design/v1213_uiux/U4_UI_KIT.md). `codex/v1213-fix-plan`/제품1.2.12 유지, 구현 `51b54beaa77d661cd47a1cbf3f7897e7db387de0` TARGETED_PASS. 단일 토큰/아이콘 매핑·실제 StyleB Theme·13개 Container 기반 부품·레이어/컷신 HUD 복구 함수 완료. 기존 UIStandard/UIUXTheme 호출·UIFont·HUD 생성기·화면·게임 로직 보존. 격리1920×1080/1280×720 × 기본/터치1.35 × ko/en/zh_CN의12조합,102캡처/1284내용 요소 전체 표시·0줄/겹침0. 실제 입력·높이·폰트·모달 초점·툴팁·HUD 복구·토스트72검사 PASS, 기존 S1 41/S1 후속131/S2 907 및 데스크톱/터치Sweep29화면49+50캡처 스캐너0. 비교 `tmp/v1213_u4/final/kit_B_comparison.png`; 실행 도구 tools/ui_kit/. 빈 아이콘 툴팁 경고1회는 의도한 검사, S1 후속 headless 기존 로그7회는 동일. 다음은 U3/최종 자산 승인 결과를 받아 IA §8 순서의 **U5 실제 화면 교체**이며 이번 U4를 화면 개편 완료로 해석하지 않는다. 다른 작업자의 u3/·imagegen/v1213_*와 기존 미추적 보존, 개인 세이브·전체 회귀·검수 에이전트·export·push0. 로컬main 부재/원격 최신성 미확정 유지. 아래는 이전 기록이다.

## 2026-10-14 V1213 병합 확인 · D01~D09 표시 수정

[재측정·수정·검증·제한](V1213_UIUX_DISPLAY_FIX_2026-10-14.md). `codex/v1213-fix-plan`/제품1.2.12 유지, 구현 `dcd5743efb1d25a25b5f7ce2bc02bd97996affef` TARGETED_PASS. c57400c 병합 검사 및 변경 뒤 S1 41/S1 후속131/S2 907 PASS. D01·D02는 S2 포함 상태에서 미재현; 남은 Container 제목/행 충돌은 공통 최소 높이·18px 하한·행 공간으로 해결. 터치 도크/팔레트·상세 스크롤 공간, 컷신 배속/첫 보호 알림 숨김·복구, 무테 마스크와 지역 카드 경계 보완. 격리1920×1080 데스크톱/터치29화면+변형99캡처의 0줄/의도치 않은 겹침/지역 넘침/마스크 테두리 모두0. 근거 `tmp/v1213_uiux_fix/verified_desktop_final/`, `verified_touch/`; 스캐너와 재실행 절차는 tools/ux_audit/. S1 후속 headless 터치의 기존 can_process 로그7회는 baseline과 동일하며 인계에 구분. 기존 미추적3폴더와 외부 문서 전용 f258253 보존, 개인 세이브·전체 회귀·push·배포0. 다음은 별도 승인된 UI/UX 개편이며 이번 표시 수정과 혼동하지 않는다. 로컬main 부재/원격 최신성 미확정 유지. 아래는 이전 기록이다.

## 2026-10-14 1.2.12 수정판 · S2 공통 UI 표적 결과

[S2 결과·33개 변경 경로·검사·캡처 제한](V1213_S2_FIX_RESULTS_2026-10-14.md), [체크리스트](../plans/V1213_FIX_CHECKLIST_2026-10-14.md), [공통 UI 기준](../design/V1213_UI_STANDARD.md). `codex/v1213-fix-plan`/제품1.2.12 유지, 최종 구현 `08a6cd46e921053f09053be69af7bfed7bdb5e88`(공통 기반 `a738101`, 타이틀/대화 `c02a712`) TARGETED_PASS. 지정8개 S2와 S1 추가 완료: 글자/버튼/아이콘/툴팁 기준·세 언어 설명, 자국어 언어 목록, 타이틀 선표시, 번호 제거, 비율 유지21:9, 건설 문구 영역 공유·활성 강화 설명. 마지막 픽셀 확인의 영어 Location/값 겹침도 보완했고 버튼/선택기/슬라이더 툴팁 폭560px 공유. 격리 최종 headless907/1920 GUI1090/2560 GUI1108 PASS, 화면 관찰237/컨트롤2989에서 빈·18px 미만·자동 잘림0. 대표PNG252장 `tmp/v1213_s2/`; 2560은 실제 창의1920 콘텐츠 원본+좌우320px 여백 재구성을 구분, OS/실제21:9 하드웨어 캡처 아님. 개인 세이브·전체 회귀·전체 플레이·export·push·배포0. 다음은 헤드의 S2-06 시안 확인/별도 그림·대화 개편 배정 및 필요 시 S1-04 원 조작 특정. 새 그림·대화창 개편·3단계·맵 구조·네이티브21:9 전체폭 미진행. 미추적 디자인3폴더 보존, 로컬main 없음/원격 최신성 미확정 유지. 중간 c02a712 문서 판정은 이번 최종 SHA로 대체하며 아래는 이전 기록이다.
## 2026-10-14 UI/UX 감사 완료 · 감사 worktree 전용

[전수 화면 진단·측정·동선·교체 단위](../design/v1213_uiux/UX_AUDIT_2026-10-14.md), [감사 인계](V1213_UIUX_AUDIT_2026-10-14.md). `codex/v1213-uiux-audit`, 제품 기준 `45eb92541edb4e8bf7bb840a0fb13e1e1296a741`, 감사 artifact `6669a576b518c8dffebca0d9f82cc0cf21d07892`. 제품코드/데이터/씬/런타임자산 수정0, 제품1.2.12 유지. 격리 APPDATA 실제 GUI 화면29/29종, 원본 PNG147장·102상태 측정·대표960px JPG12장, 첫 방어 승리→집중성장→DAY2·감사 저장/별도 Continue 확인. 핵심 첫날 관찰경로51클릭·대화36회; 실제 훈련 직후 다른 동료 선택은143/144로 재확인. 우선 문제: 데스크톱 건설 이름5개/성장 이름·제목4개/터치 성장18개 라벨 소실, 터치 탭·Inspector·배속 및 컷신 알림 중첩. 수정하지 않았으며 다음은 헤드의 소실 선행 수정과 관리/성장/결과 정보구조·타이틀/대화 시안 결정. 직접 draw 글자는 Control 통계와 분리, 후기/확장/엔딩은 합성 진입, 전체30일·회귀·음악·21:9·실제기기 NOT_RUN. 원래 mawangseong-action은 지정 자료만 읽고 변경/실행0. 영어 로컬 커밋만, push/배포0, 감사 산출물 TARGETED_PASS이며 게임 품질 PASS 아님. 로컬main 없음; origin/main 캐시와 원격조회SHA 일치 확인, main 권위는 미확정. 아래 기존 제품/S1 기록을 보존한다.

## 2026-10-14 1.2.12 수정판 · S1-02~S1-07 표적 결과

[항목별 원인·검사·커밋·제한](V1213_S1_FIX_RESULTS_2026-10-14.md), [단일 체크리스트](../plans/V1213_FIX_CHECKLIST_2026-10-14.md). `codex/v1213-fix-plan` 유지, 구현 SHA `60629a0ea067120b6ec70e0dc1ad92d6bab527bd`/저장 수정 `be98a27`. 기존 저장 읽기 실패의 오류·종료 재시도 누락, 실제 구역 배치 인원 표시, 바닥 밖 건설 문구 클릭, 강화 재료 부족 활성/사유 없음 수정. 격리 APPDATA 저장 잠금 headless9/GUI11, 첫 승리 fresh14→별도 Continue6, S1 표적 headless41/GUI56 PASS. 1920×1080 PNG17장 `tmp/v1213_s1/`, 개인 세이브 변경0. S1-03 최근 DAY2 점유 목표는 기수정 확인; S1-04 훈련·승급 뒤 동료 선택 재현 불가로 미완료 사유 유지·추측 변경 없음. 다음은 헤드의 S1-04 원 화면/조작 특정. 제품버전1.2.12 유지, S2 이후·전체 회귀·전체 플레이·별도 검수·push·배포0, TARGETED_PASS. 기존 미추적 디자인 폴더2개 보존. 로컬main 없음/원격권위 최신성 미확정 유지. 아래는 이전 기록이다.

## 2026-10-13 HTTP 업로드 성공·향후 AI 배포 목표

[HTTP 성공과 AI업데이트 절차](STEAM_HTTP_AI_WORKFLOW_2026-10-13.md). 부모실제픽셀 확인 전달: 새DK웹업로드탭에서1.2.12 ZIP7파일 실제전송/Commit 성공, Build25899210/Manifest7910548240097529409/branchNone. 옛완료화면은파일명만바뀌고옛ID/Commit없음; 완료빌드먼저확인→새탭전송을스킬에반영. Builds는옛default25870353, ChangePreview는25870353→25899210/4.3MB; 실제default완료/모바일완료/7파일서버대조/공지미확인. 향후사용자업데이트요청시AI가업로드·Commit·공개적용·재조회진행하고필수휴대폰승인만사용자에게모으는목표,상시새출시권한아님. 현재자동브라우저준비완료미확인;복구담당01a13395별도. 기록담당은스킬/인계만수정,제품·브라우저·새배포·로그인0/기존검사반복0. 갱신목록에스킬표시·skills.read성공관찰,AGENTS직접링크유지. 아래는이전시점기록이다.

## 2026-10-13 Steam 성공 경로·재사용 스킬 기록

[성공 기록과 설치 검증](STEAM_SUCCESS_SKILL_2026-10-13.md). 개인 스킬 $mawangseong-steam-release 설치·AGENTS 진입점 연결.1.2.11은 사용자 DK Chrome ZIP 업로드/Commit→부모 서버대조·공개절차→사용자 모바일승인→default25870353 재확인 성공이며 SteamCMD 설치보다 앞섬. 기존공식SteamCMD 중첩경로/Valve서명/동일해시/+quit exit0 확인.1.2.7/1.2.9 브라우저 성공·1.2.10 업로드 증거와 공개 공지 API 근거도 기록. 오늘1.2.12 AUTH_BLOCKED와 성공 경로를 구분; 후보9f0/기존공개1.2.11 상태는 아래 인계 유지. 이번조사 Steam업로드/default/로그인/공지게시0·제품/세이브변경0. 실제사용자 원격작업과 중복배포금지. 문서3개만 로컬커밋으로 보존하며 제품원격push0; 비공개허브0a75b41c의 Work ledger checks/ deterministic-checks SUCCESS 확인. 다음세션 자동스킬목록 반영 미확인이지만 AGENTS 직접링크 접근 검증. 아래는 기존 인계를 그대로 보존한다.

## 2026-10-13 최종Steam1.2.12 · 업로드인증차단/원격인계완료

[최종파일·검증·업로드1회·재개](STEAM_V1212_UPLOAD_HANDOFF_2026-10-13.md). 최종제품소스9f0be3be3642eaa18a45bfca2679e187e2077d7a, 버전1.2.12. 공식anonymousSteamCMD fresh조회로현재공개Build25870353/Depot5267751 Manifest5824439082666467035=기존1.2.11확인. 이전‘SDK없음/공개버전미확정’기록을대체: 기존SteamPipe runtime설치찾음/Valve서명확인/새설치0. 새product는2df검증본에서version·KOENZH공지뿐; 새fullPCK3421중project.binary/PlayerContinuityUI.gdc만차이2, 나머지동일. WindowsSteam export0/PE1.2.12.0/최종EXE세언어1920×1080공지읽기·잘림없음·ERROR0/depotSETUP_PASS, 기존8스킬·성장·저장통과검사재실행0. 최종판정TARGETED_PASS이며전체campaign/재미·Steam설치/2PCCloud/사용자DAY30 NOT_RUN.

기존UploadSteamBuild.ps1 실제업로드한번은Cached credentials not found/password요구에서차단; 자격증명입력0/SteamCMDexit5/uploaderexit1/contentbuild시작0/새BuildID없음/프로세스종료. 잘못된사용자password라고단정하지않음. 현재공개1.2.11유지, default/패치노트게시0. C:/Users/blueh/Documents/Codex/2026-10-13/task/Steam-1.2.12-Ready 폴더에최종Content7파일·Upload.cmd·VDF·무결성검사·KOENZHpatchnotes·START_HERE_KO.md·안전증거준비. 사용자가기존Google원격으로DK→Upload.cmd직접인증→새BuildID/default확인→세언어공지게시; 부모와중복공개하지않고불확실업로드는먼저조회. 비밀번호/토큰파일0/개인세이브동봉0/Google원격·Cloud설정변경0/Library호출0/pushmerge태그0. 마지막개인698보존근거재사용, 새boots격리APPDATA. 현재main부재/원격권위최신성미확정. 다음턴은사용자지시에따라gpt-6.1-sol/high/일반속도로부모가생성하며현재turn설정변경주장없음. 아래는시점별역사기록이다.

## 2026-10-13 요구사항 판정 완료 · Steam 공개출시 승인/환경차단

최신 사용자02:17UTC 원문은필수검수뒤Steamapp5267750 업데이트/default공개/패치노트게시를명시승인했다. Library첨부중단, 이전‘Steam공개금지’범위는역사기록으로대체되며동일승인재요청0. [요구사항별SHA·검사·영향·출시gate](FINAL_PATCH_REQUIREMENT_MATRIX_2026-10-13.md). 제품 `2dfbaeea2e28b4d8d04631689eee24c9ef7b0800` 그대로,8스킬효과/공통모드/왕관·성장/배치/저장·Continue·정상및실패Quit은기존표적증거재사용. 빠진오류해결후Retry성공경계만추가: 실제같은Retrycallback→gold1475→1492·roster동일·정상Quitexit0; 후처리inspect인자오류INVALID보존, 성공Save/Quit반복0; 이미쓴5checkpointvalid+별도Continue자원/KokoEXP13bond44 보존 PASS. 개인698hash변경0, source/data/assets변경0.

현재공개default BuildID/version 직접확인은CUA초기화 `MXC launcher: cannot locate required Windows platform directory: HRESULT 0x80070003`로차단. 기존SDK/SteamCMD/설치appmanifest없음, 재사용browserdebugport없음. 공식공개News APIHTTP200은1.2.10기사1개만확인한것으로default증명아님. 높은새patchSemVer/releaseSHA 미확정, upload/default/패치노트게시 NOT_RUN/BLOCKED, 새BuildID/공개URL없음. 검증runtime는올바른depotroot로workspace스테이징하고KO/EN/ZH미게시초안준비; 현재public확인전업로드금지. 기존사용자승인은유효하고필요한것은포털제어가능한인증환경이다. 신규login/OTP/계정비밀/Cloud설정변경0. 실제사용자DAY30/전체campaign/자연두번째전투/사람재미/Steam설치/2PCCloud/downgrade실행은미검증. 새EXE부팅을wholeQA로승격0. Library실패action `mcp__codex_apps__library_prepare_uploads` / helper `prepare_uploads`, 오류 `Library prepare_uploads is not available`, tools/list발견단계/쓰기전실패로전송finalize0; 최신지시뒤호출0/우회0. 다음은제어가능한기존Steamworks환경에서현재default직접조회→높은version→그metadata영향만검수→공식upload/서버대조/설치관련경계/default재조회/패치노트URL확인이다. 원격pushmerge태그Release0, main권위최신성미확정유지.

## 2026-10-13 독립 Windows 검토 완성본

제품 `2dfbaeea2e28b4d8d04631689eee24c9ef7b0800` 그대로, 구현/데이터/자산/저장경로 추가변경0. [최종 인계 section12](FINAL_PATCH_SAVE_QUIT_2026-10-13.md#12-독립-windows-검토-빌드-추가--2026-10-13). 새WindowsSteam releaseEXE+전체PCK+Play.cmd+고지/공식GodotCOPYRIGHT를30entry ZIP에 동봉, 설치Godot/옛base/patch필요0. 새exportPCK는 검토fullPCK와 byte-identical/3421resource차이0. 수정없는Main1920×1080 타이틀/첫실행안내·정상quit-after exit0/resource-scriptERROR0. 초기 미지원외부script INVALID 보존, 기존통과save/gameplay 반복0. 개인698hash mismatch0. 로컬 `standalone-review/Mawang-Standalone-Windows-Review-2dfbaee.zip`,615708233B/hash952bc549f44dc68797c2623eb7abe94241f08f0395e03166887cb5181a4df0b8. Library 공식helper는 prepared action 미노출로 준비 전 실패해 **새Library 저장 미완료**; 옛델타Library와 구분. 실제사용자DAY30미수신·사람재미/전체캠페인/자연두번째전투/Steam2PCCloud NOT_RUN. 공개/원격변경0. 다음은 로컬독립완성본 사람검토·정상helper호스트 전달/실제DAY30복사본 좁은검증. 아래base+patch 안내는 이전전달의 역사기록이다.

## 2026-10-13 최종 검토 후보 · DAY30 코코 변환/안전 종료

제품 `2dfbaeea2e28b4d8d04631689eee24c9ef7b0800`, branch `codex/fresh-v5-result-save-fix`. [최종 범위·실패 보존·정확한 패키지](FINAL_PATCH_SAVE_QUIT_2026-10-13.md). DAY30 graveyard_hound 오류는 이전 Council P1과 별도이며 v1→v2 정상5종 매핑 누락을 보완했다. 정상14종 v1~v5/Continue와 모든 입력필드 의미비교 불일치0, unknown 거부/5primarybytes 보존, 명시 실패Quit PASS13/0·exit0. 오류/손실/취소/재저장/저장없이종료 유지, 자동 데이터 폐기0. DAY1 전열푸딩/후열핀 표식·카드·완료 문구와 기존 시설 측정3행/알림 동시 표시, KOENZH 보완. 최종 notice4 PASS. 최초 종합 하네스 실패와 경계 보정은 전부 기록했으며 literal one-process PASS/전체 QA를 주장하지 않는다. 기존 firstsave15/7/12+부모CUA·곱24·성장/스킬 통과검사 재실행0. 최종803base+통합16리소스는 full3421과 모두 일치; Library `libfile_0d8ab26307308191ba8917bc99b797b9` 검토ZIP 저장 succeeded. 개인698→698 mismatch0. 실제 local5save는 DAY2이며 사용자 첨부DAY30 live save/실행SHA 미수신; 첨부OCR는 일치하나 공식 수신Windowsxattr 실패로 원본픽셀 미확인. 새 사람재미/자연2번째전투/Steam실설치/2PCCloud NOT_RUN. 공개Steam/Cloud설정/원격pushmerge0, 로컬main부재/원격최신성미확정. 다음은 부모의 새 통합patch 검토 및 실제DAY30 복사본의 좁은 Save/Quit 경계다.

## 2026-10-13 첫 정상 승리 v5 저장 P1 최소 수정

제품 `b1a9e502cafc8a18d6161c4757fec9bdc1ebf96f`, branch `codex/fresh-v5-result-save-fix`. [원인·diff·경계·Library 패키지](FIRST_VICTORY_SAVE_P1_2026-10-13.md). NativeObjectiveRuntime이 모든 결산에 의회전용 native_1f_objectives를 넣어 LEGACY호환 첫회차의 v5 validator가 올바르게 거부했던 로컬 저장 P1. Council metric은 Council에서만 직렬화하고 New Game의 Update4 context/v5 cache 정리; next-cycle earned profile 보존. 생산7줄 삽입, validator/회차분류/세이브경로/Cloud 설정 변경0. 정확한803base+최종compiled4resource overlay에서 정상첫승리저장15/별도실행로드7/관련레거시12 PASS, Bootstrap90frames exit0. 다른 whole skill tests 재실행0, 개인698+백업 mismatch0. 약2.1MB 최소후속패키지 개인Library libfile_76ff7a9ba2d88191a1bd63db120e2e89 저장성공. Cloud진단ZIP 공식수신은Windowsxattr에서최종설치실패(우회/재시도/원본변경0). 실제실패stack과소스호출순서에 SteamAPI/Cloud 의존없음; 무시할 Cloud통신문제아님. 부모 Linux Cloud native CUA에서 새격리 천둥남작/곱전열 정상DAY1승리→자동RESULT저장→마지막자동저장 정상Quit→별도프로세스 Continue→메뉴Save PASS. 전후monsters/game_state/result/checkpoint/screen 동일, gold1443mana300 EXP22/20/19 bond6/5/3 보존·보상중복0·기존실패프로필보존. DK 새검사0/제품코드추가변경0. 부모DAY2/성장표시 약7분검토 결과대기; 자연재미/전체QA/실제SteamCloud2PC·공개배포 NOT_RUN. Steam공개/원격작업0, 로컬main부재/원격최신성미검증 유지.

## 2026-10-13 지원 툴팁·곱 자동 경계와 Library 초반 검토 패키지

제품 `80335024f813bf0b5052251714185d000fa76932`, branch `codex/skill-tooltip-auto-boundary`. [핸드오프](SKILL_TOOLTIP_AUTO_BOUNDARY_2026-10-13.md). night_relay/royal_emergency_plating 툴팁을 실제 승인된1F 범위로 ko/en/zh 동기화. 실제 곱 수동/자동 한 경계 PASS24/0(툴팁6 포함), 새PCK 문구6·private/native0·실제OpenGL main180frames 확인. 다른7스킬 전체 검사 재실행0. 개인698+백업 mismatch0. 최신PCK와 실행/조작/정상새게임 안내를 개인 Library Part1/Part2 두 파일로 저장 성공; ID·해시·격리 Linux 안내는 핸드오프. Windows xattr helper 미지원은 별도 identity JSON에 보존; Library 저장 실패 아님. Linux 실제 부팅/자연10–20분 선택·가독성·재도전 검토는 부모 다음 단계, 사람 재미/자연해금/전체QA/Cloud NOT_RUN. 실제2F·새밸런스·Steam공개/원격 작업0. 로컬main 부재/원격 최신성 미검증 유지.

## 2026-10-12 성장 대표·지원 기여 검토 빌드 고정

제품 `d7f662b845399f4946bc3f7d0d4e7dc69864f8b4`, branch `codex/growth-support-feedback`. [결과](GROWTH_SUPPORT_RECOVERY_2026-10-12.md), [계약](GROWTH_SUPPORT_SPEC_2026-10-12.md). 기존 푸딩 두 분기 실제 방패/경로 목표 차이 확인→선택 설명/첫 유효 보호→실제 회복·보호 적용·공유 합동기/actual redirect HP 비용→기존 최종 다음 선택 연결. 새 기본 AI/능력치/해금일/적 수/보상 변경 없음. baseline9/sourceclock8+8/v5read-titlecontinue7/새PCK15/editor-export-EXE180 PASS. 독립 소스11hash0/0. 초기72/6·14/2·16/2 FAIL은 전체 PASS로 승격 안 함. 개인698/이전9패키지27hash/원래자료 보존. 자연 전체 플레이·재미·밸런스·Cloud 현재 읽기/두 PC·전체 QA는 NOT_RUN. 승인된 대표 구현/검토 빌드까지 완료; Steam/원격 공개 작업은 하지 않았다. 실제1F 긴급전령 대체·핀 효율1.06/base24·28·16 등 이전 답변 수정도 포함한다. 출시 전체 PASS나 실제2F 확장 완료를 주장하지 않는다.

## 2026-10-12 지원 숙련·의회 보유 편성 고정

제품 `efc7aa12e58f5064016edd0ba67dc2f7c94ca8d9`, branch `codex/earned-support-progression`. [결과](EARNED_SUPPORT_RECOVERY_2026-10-12.md), [계약](EARNED_SUPPORT_SPEC_2026-10-12.md). 실제 성과→승리 숙련, 기존 획득 소유권→예비 편성, 빈 편성 차단, v5/continue/next-cycle 연결. 새 경계9/저장10/터치4/continuity89/PCK8/보이는 locale UI3/editor-export-EXE180 PASS. 독립 소스19hash P1/P2=0/0; 자연 전체 획득/재미/Cloud NOT_RUN. 초기39/1 FAIL과 script error는 전체 PASS로 세지 않았다. 기존8개 구현 패키지24hash/개인698 불변. 다음 승인 작업: 푸딩 DAY12 두 분기 행동 비교·지원 기여·기존 다음 회차 선택. Steam/원격 공개 작업 없음.

# 2026-10-12 Echo/native1F recovery frozen

[실제 경보·전령 가방·1층 목표 복구](ECHO_OBJECTIVE_RECOVERY_2026-10-12.md), productbdf886a. GUI190/0·desktop/touch9+9·컷씬34/합동기GUI70·독립 compiled touch5/0·18 source해시/6PNG TARGETED_PASS. 이전40b2 핵심24와 기존 Basic/Gob/Pynn/body/continuity는 SHA·범위를 재사용; 통합29 PASS 주장없음. PCK2F8FE046...584530580/EXE0, 개인698/이전7패키지21hash/40b중간본 보존. 사용자리셋뒤 디스크 복구·독립P2 터치가림 해결 완료. 정상 earned roster/mastery/왕관·승인 성장 작업은 다음, 전체완료 아님. Steamworks fresh읽기 실행기오류/두PCCloud NOT_RUN; 공개변경0.

## 2026-10-12 latest authorized skill implementation checkpoint

[곱 왕명·실제연쇄 복구](CROWN_GOB_RECOVERY_2026-10-12.md), product8b15d27: GUI112/0·CD0약화중재사용6/0·desktop/touch각9·native13·Basic253/Pynn220/Feedback136/continuity89·실제PCK19/독립19/추가contest22/EXE180frame0·오류0. 실제표식/기본간격2타·보행귀환·첫접촉use/debt1·반격callback·독립DEF.85/4s·실제함정/절도중단과화면수동버튼을구현했다. 세P2닫음/TARGETED_PASS·현재4PNG/개인698 mismatch0/이전6패키지18hash보존. 최초420빌드는중간본,최종별도gob패키지E602D706...불변. 다음메아리실제채널/회수·정상영입/숙련도·승인성장. 자연획득/사람밸런스/전체캠페인·Steamworks/두PCNOT_RUN;전체완료아님.

[핀 마나효율·삼색 복구](CROWN_PYNN_RECOVERY_2026-10-12.md), productdc22af2: GUI220/0·desktop/touch실제입력각8/0·기존livebody1051/basic253/continuity89·실제PCK18/독립18/EXE180frame0·최종오류0. 자기일반/왕관mana효율1.06/실지출·모드별NEW가격23/26/15·실제projectile/area/독립curse·일반→Royal세종이력→두번째할인을구현했다. 새확장inspector클릭world누수·auto효용0·contact봉쇄지적수정. 별도불변pynn패키지/현재8PNG·이전5패키지15hash/개인698변경0. 사용자두답처리완료. 다음곱실제연쇄/왕명·메아리실제공개/채널·정상영입/mastery·승인성장. 전체완료아님; 자연진행·실제상층·사람밸런스·Steamworks/두PCNOT_RUN. 추가필수질문은부모로보고.

[실제 방 긴급전령·젤 계승 복구](CROWN_MOBILITY_RECOVERY_2026-10-12.md), producta83460d: 최종GUI202/0·기본253/0·continuity89/0·순수계약29·실제PCK18/0·EXE180frame0·최종runtime오류0. 저장한Pudding승급에실제중앙보행/DEF3 또는안전구조44, 사용자답에따라Royal전령.20simulation방간이동→도착후아군6초/최초실제방진입CD회복을구현했다. 상층구현 아님. 별도불변mobility개발패키지와현재3PNG, 이전4패키지/개인698변경0. 다음핀마나효율/삼색비용·곱연쇄·메아리실제효과·정상영입/mastery·승인성장 계속. 미완료잔여3액티브/정상해금/사람밸런스/Steamworks·두PCNOT_RUN, 전체완료주장없음. 두사용자답승인완료; 새필수설계질문은부모로보고.

[최신 왕관body/외형 복구](CROWN_LIVE_STAT_RECOVERY_2026-10-12.md), productd9de8a7: 실제GUI1051/0+desktop8/touch8·오류0, 기존native140/대화373 기대값유지, 실제PCK15. 억제시기존base외형/성장능력치,복구시crown/기존배율; HP자동회복·부활0, 벽깊이/chroma/현재inspector갱신. 아래시설/모리/기본패키지모두보존. 최신사용자답 urgent상층대신다른밸런스 재설계(실제방간지원방향명시), 핀마나효율/비용재설계승인: 둘의선택대기종료·재질문0, 다음구현중. 추가설계결정은부모대화로질문/권장안/영향보고. 정상mastery/영입·잔여4액티브/계승·성장은미완료,전체완료아님. 아래‘상층/최대마나답pending’은이전시설freeze시점기록이다.

최신 사용자 승인 ‘이름에 맞게 스킬구현하고 컷신도 만들자’는 앞선5설계보류/DLC후보판단을 대체한다. [명세](SKILL_COMPLETION_SPEC_2026-10-12.md). 단층 실밥/보행중계 제품5f8554f, 모리우산/성찬6869de8, 톡톡실제시설15d5efb를 별도브랜치·불변개발패키지로보존. [최신 시설검증](ROYAL_FACILITY_RECOVERY_2026-10-12.md): GUI120/기본253/모리119/석골34/continuity89/PCK14 PASS, 독립TARGETED_PASS. 현재1F시설의최종30%수리cap/8초.30방호·실제lastHP-loss제련/실제배치art·HP컷신. 실제상층과핀최대마나모델은구체선택답pending, 그외잔여4액티브/젤계승/왕관body억제·정상영입/mastery를계속한다. 성장개발은스킬묶음뒤. 전체완료·정상해금/실제2F·사람밸런스·두PCCloud PASS 주장없음. 개인698·기존빌드/사용자프로세스보존, Steam공개설정/push/merge/홍보변경0. 아래는역사기록이며보류판단을현작업중단근거로사용하지않는다.

## 2026-10-12 remaining skill decisions, bounded balance probe and DAY2 fix

[기술별 이번패치/DLC/보류 자료와 DAY2 최소수정](SKILL_DECISION_DAY2_2026-10-12.md). Product979adcd44be41cc3583ff28a9ed597bafb4d94ba, codex/day2-room-selection. 점유된필수방 클릭이몬스터선택으로끝나는원인재현→목표방선택우선·management강조canvas변환. GUI61/0, 안내설정PASS/연습22/continuity89, 새export0/실제PCK스킬14/방선택110→120·메뉴callback120→130. 사람OS·nativePopup·전체DAY2방어NOT_RUN. 별도불변aabPCK8전투/동일조건40PASS, 구조·왕관발동0이라지원강도NOT_MEASURED. 기본문턱/단층중계이번복구권장; 나머지계약/실전기반보류, 새다층콘텐츠DLC후보. 의회DAY1합류는전선30완주뒤다음회차; Mori/TokTok/Popo왕관masteryproducer없어정상profile해금막힘. [전체결정표](REMAINING_SKILL_DECISION_AUDIT_2026-10-12.md)/[실전제한](LIMITED_ROLE_BALANCE_PROBE_2026-10-12.md). 성장코드미착수; 8처리방침/출시게이트뒤기존승인순서. 기존aab검토빌드·개인저장·Hubbaseline보존, 공개Steam/원격Git/홍보없음.

## 2026-10-12 private skill runtime connection and next growth plan

[두 효과의 실제 연결·검증·남은 범위](SKILL_RUNTIME_CONNECTION_2026-10-12.md). Product aab19e40edc77b5b9baa52e47cdd360232e578a4 / codex/skill-runtime-connection. 실키 응급 실밥과 왕관 푸딩 기본6초 방어·흡수 연결; 기존 현재 외형 컷신·수동/자동·off/once/always. GUI126/0, roster1030/0, manual124/auto56/lifecycle34/continuity89, 실제 새 PCK14/0·EXE180frame exit0·독립 TARGETED_PASS. 남은8스킬/왕관 분기 계승·패시브 전부 통합은 미완료. 개인698+백업/기존5산출물 보존. 새 desktop 검토 폴더만 생성, 기존 실행 빌드 유지. [기존6618 첫 방어 검토](FIRST_DEFENSE_REVIEW_2026-10-12.md)는 새 빌드 결과와 별개: 실제 선택 차이 확인, DAY2 TUT110 자동 입력 반복 정지 원인·사람 재현 미확정. [승인된 다음 성장 작업](GROWTH_APPEAL_NEXT_PLAN_2026-10-12.md)은 푸딩 두 승급 행동→지원 기여→다음 회차 선택 순서; 사용자 원문 보존, 이번 턴 구현 미착수. 사람 재미/자연OS/자연 영입/두PC Cloud NOT_RUN. 출시 차단 확인과 낮은 우선순위 미완 구분; 외부 홍보/Steam/push 없음.

## 2026-10-12 full playable-roster action audit (private)

[Full inventory, confirmed coverage, gaps and direct-test start](SKILL_ACTION_ROSTER_AUDIT_2026-10-12.md). Product6618c09. Fourteen species/26 appearances audited; linked24activeIDs:92controller/automatic cases, six duoIDs:52appearance routes; realGUI144action+3availability captures,1012checks PASS. Ordinary skills use production auto decision; five specialist paths use their real request helpers. Four simultaneous-two-crown routes are fixture-only. Current-appearance fallback0. Data-only Silky/Popo4actives and6royals remain unintegrated; fake success/cost/view-history blocked and actual native HUD informed. No new skill/art/balance. User can use updated isolated desktop shortcut; natural campaign/human feel are NOT_RUN. Next first10–20min meaningful choice/result review belongs to parent after this task; no broad UI/balance rewrite started.
## 2026-10-12 private character action cutscene review

[Implementation, fresh targeted tests, independent review and development build](SKILL_ACTION_CUTSCENE_2026-10-12.md). Isolated codex/skill-action-cutscenes worktree mawangseong-action, product748001f. About1s manual/automatic/two-member action with prepared targets and once(default)/always/off policies; history reset/persistence; saved-frame and pause-owner safety. Source127/56/11/70/30/34, continuity89, save246, actual PCK36 and EXE isolated boot exit0 PASS. Independent review findings corrected. Existing saves698/backup and old packages preserved. Full campaign/all form combinations/human feel/two-PC Cloud NOT_RUN. Public1.2.11 and remote/public settings unchanged. Hub baseline remains sibling mawangseong/562f0d1; do not confuse it with this implementation checkout.
## 2026-10-12 native contract-monster verification / four old assertions resolved

[Actual native actor/progression GUI, corrected contract and requested duo still](NATIVE_CONTRACT_PROFILE_RESOLUTION_2026-10-12.md). Test-only SHAcd8aea7; product4f425f0 and existing development package unchanged. Verified actual Silky/Popo native frames, tactical specialization handlers and Popo DAY23 crown/suppression. GUI140, corrected profile contract, services24+20, crown29, presentation37 PASS. The prior4 failures were obsolete legacy-path expectations and are now resolved with stronger own-native-frame assertions. Actual preserved-PCK Molten Carapace (핀+톡톡) impact still at0.119902s saved separately; no extra visual/balance changes or Library retry. Personal698 files, public/private ZIP/PCK and original17 screenshots preserved. Unrelated concurrent dev-work-hub AGENTS/README edits remain unstaged and preserved. Whole/low-end/human/full-campaign/Steam install/two-PC checks remain NOT_RUN. No public deployment or push.

## 2026-10-12 combat presentation / private development verification

[Implemented combat presentation, actual GUI/PCK results and recovery](COMBAT_PRESENTATION_FINAL_2026-10-12.md). Product4f425f0 on local `codex/combat-presentation-prototype`: missing contact feedback, readable bounded Maple damage numbers, representative x1/x3 skill visuals, optional current-form cutins, reduced-effects/settings persistence implemented. Final GUI317, continuity89, Duo92, actual new PCK25+44 and Windows EXEexit0 PASS. Existing visual-profile4-assertion failure reproduces in unchanged baseline; whole regression/independent review/human-feel/low-end/full campaign/actual Steam install/two-PC Cloud NOT_RUN. Personal698 files and immutable public ZIP unchanged. Private prototype uses isolated launcher; no new version, push/merge, Steam upload/default or account changes. SteamCMD login remains separate.

## 2026-10-12 combat presentation development / stages1–2 (completed checkpoint)

[Damage feedback and readable impact numbers](COMBAT_PRESENTATION_STAGES12_2026-10-12.md). Local branch `codex/combat-presentation-prototype`, codeca7d42b. Real GUI191, contact23, boss31, duo92, anchor12, corrected old GUI fixture122 PASS.698 personal files backed up. Numeric font/popup/screen size/merge/overflow implemented; no balance/version/public package changes. Representative skills/x3 VFX and optional cutins are the next approved steps. Low-end PC/human-feel/full-campaign NOT_RUN. No push/public deployment; SteamCMD login remains a separate user-confirmation workflow.

## 2026-10-11 1.2.11 final verification / approved Steam release

[Final implementation, regression evidence and release coordination](V1211_FINAL_VERIFICATION_2026-10-11.md). Product2786be4: actual reply portraits follow six promotion branches and six active crown forms; GUI373, continuity89, catalog1082/216scenes/1622cues, Steam PCK44, touch80, EXEexit0 PASS. First full run156/162 FAIL is preserved; fresh clean-source full run162/162 PASS,0failures,exit0. Public Steam1.2.11 approved; upload/default NOT_RUN here, parent owns portal. Remote push and Library ZIP delivery were rejected by automatic approval review; no workaround. Two-PC Cloud/earned continuous campaign/human balance NOT_RUN. Public1.2.10 Build25808943 is rollback baseline.

## 2026-10-11 private 1.2.11 candidate

[Version, prior-save compatibility, exported build verification and release limits](V1211_VERSION_REVIEW_2026-10-11.md). Product b0e0a79; version/labels/notes 1.2.11, Windows metadata 1.2.11.0. Public 515ed745 hotfix preserved. GUI62 / speed309 / input136 / save246 / prior-save11 / local-Cloud26 / exported-PCK14 and EXE boot PASS. Personal 698 file hashes unchanged. Parent observed public Steam Build25808943 remains 1.2.10. Actual Steam client/two-PC/offline-conflict tests NOT_RUN. No source push/merge or public game deployment.

## 2026-10-11 local save + Auto-Cloud follow-up

[Final local compatibility and two-PC release gates](V1210_AUTOCLOUD_LOCAL_COMPATIBILITY_2026-10-11.md). Product 386f29d unchanged. Default paths/six-file contract26, continuity58, campaign246 PASS. Parent confirmed settings published/developer-only0; store feature and real two-PC test remain incomplete. No local Steamworks changes or remote/public build actions.

## 2026-10-11 private continuity review (not publicly released)

[Implementation, tests, Cloud blockers and recovery point](V1210_CONTINUITY_REVIEW_2026-10-11.md). Branch codex/v1210-safety-dialogue-review, product 386f29d. Source GUI58 / speed309 / rapid-input136 / save246 / story58 and Windows EXE/PCK checks PASS. Current Steamworks and two-PC Cloud NOT_RUN. No remote push/merge or public Steam changes. See the dated handoff before continuing.

# 현재 작업 핸드오프

최종 갱신: 2026-10-09 (1.2.10 첫날 피드백 Build25808943 공개 default 적용·서버6파일 검증·출시 후 핫픽스 3언어 공지 공개 완료)

**최근 완료 작업:** [1.2.10 첫날 피드백 수정 및 공지](V1210_DAY1_FEEDBACK_HOTFIX_2026-10-09.md). 사용자의 수정·Steam 공개 업데이트·출시 후 공지 게시 요청을 완료했다. codex/v1210-day1-feedback의 제품 SHA515ed745d4ce731f7bafb31ee1f9381470794d72에서 이름40개/언어, 설명·자원·지도 태그 표시, 필수 성장 직접 안내, 전투 속도 유지 옵션을 수정했다. 최종 GUI/실제 PCK 각각323checks, 관련 기존5종, EXE exit0, ZIP6파일 검증 PASS. 버전1.2.10/1.2.10.0 유지. ZIP은 builds/steam/windows/MawangCastle-v1.2.10-SteamContent-hotfix-20261009.zip(615477902bytes). **공개 default Build25808943/Manifest7359545829337152740, 서버6파일 크기·SHA1 일치, Set live public 이력(서버8Oct9:42am)을 확인했다.** 시작 default25803750/Manifest2614967785369199063은 롤백 기준이다. 다운로드3.5MB. 사용자는 도구 오류로 웹 확인창 조작만 직접 처리했고 추가 재승인·휴대폰 작업 없이 반영됐다. **[출시 후 핫픽스 공지](https://store.steampowered.com/news/app/5267750/view/678511862081390358)**를 2026-10-09 01:53KST 공개했다. 한국어·영어·간체, 소규모 업데이트/패치 노트 유형, 새 빌드 연결, 라이브러리 상세 노출 켜기. 다운로드 패치 노트·뉴스·커뮤니티에서 확인할 수 있으며 라이브러리 검토 지연은 가능하다. 고객용 공지 본문과 공개 상태를 확인했다. 전체 회귀·전체 캠페인·Steam 실설치는 이번 요청 범위에서 미실행이며 TARGETED_PASS다. 소스 main 병합·원격push·태그 없음. 다음 필수 작업은 없으며 별도 요청 시 통합한다. 아래10월8일 기록은 앞선 수정본의 완료 이력이다.

이 문서는 **최신 `main`에서 지금 필요한 사실·활성 작업·다음 진입점만** 제공한다. 과거 진행 기록은 `docs/handoff/archive/current/README.md`에서 날짜와 버전 순서로 찾는다.

## 1. 권위 기준

- 작업 정책의 권위는 `main:AGENTS.md`, 제품 현재 상태의 권위는 `main:docs/handoff/CURRENT.md`다.
- 현재 작업트리가 `main`이 아니면 작업트리의 `CURRENT.md`를 제품 현재 상태로 사용하지 않는다.
- 비-`main` 작업트리에서는 아래를 먼저 확인한다.

```powershell
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
git show main:AGENTS.md
git show main:docs/handoff/CURRENT.md
```

- `main`과 `origin/main`이 다르거나 원격 최신성을 확인하지 못했으면 현재 권위를 확정하지 말고 보고한다.
- 과거 브랜치의 `CURRENT.md`에 적힌 `현재`, `다음 작업`, `최신 안정판`은 그 브랜치가 작성된 당시의 기록일 뿐이다.
- 작업트리가 더럽다면 브랜치를 전환하지 말고 `git show main:...` 또는 `git worktree list`로 확인한 깨끗한 `main` 작업트리를 사용한다.
- 현재 지시 검색에서는 `docs/handoff/archive/**`, `tmp/**`, `output/**`, `builds/**`, `web_Demo/**`를 제외한다.

## 2. 현재 제품 기준선

- 최신 제품 소스·Steam 기본 배포 빌드: **1.2.9** (2026-09-30 02:44 KST Valve 애플리케이션 승인 메일 확인).
- 불변 태그·제품 SHA: `v1.2.9` / `4076e099202f440c85a30699268d1c887c26c903`. [PR #104](https://github.com/bluehige/mawangseong-demo/pull/104) merge commit으로 main 반영. 이전 v1.2.8 태그는 보존한다.
- [PR #100](https://github.com/bluehige/mawangseong-demo/pull/100) merge commit으로 main 반영. DAY 1–30 전체 영어화, 한국어·영어 설정 선택, UI·저장 호환 검증 완료.
- [1.2.9 태그 Windows 자동 빌드](https://github.com/bluehige/mawangseong-demo/actions/runs/35676690799): SUCCESS, 별도 Windows 환경 export·실행·artifact 보관 완료.
- 기존 GitHub 공개 Release는 [1.2.7](https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.7)을 보존한다. 이번 요청은 Steam 배포이며 별도 GitHub Release는 만들지 않았다.
- [공개 Web](https://bluehige.github.io/mawangseong-demo/web_Demo/)는 기존1.2.6. 재배포하지 않았다.
- 이전 태그·Release·출시 바이너리는 변경하지 않는다.

## 3. 현재 활성 작업

- **2026-10-08 Steam 수정 배포 완료:** 공개 default가 **25803750**, Depot5267751 Manifest **2614967785369199063**으로 변경됐고 Set live BuildID25803750 for branch public 이력을 확인했다(서버 표시8Oct5:43am). 주인공 최대 일러스트·창모드/전체화면·대화창 클릭 수정 ZIP의 서버6파일 크기/SHA1은 모두 일치한다. **제품 버전1.2.10 유지, 추가 사용자 인증 처리 없음.** 이전 default25780940/Manifest1499837472719962438은 롤백 기준으로 보존한다. 모바일 승인 직후 목록이 잠시 기존default를 표시했으나 미리보기의 Current and next BuildID are identical(25803750), 이어 Builds의 default/이력으로 완료를 확인했다. 아래 승인 대기와 파일 선택 대기 기록은 완료 상태로 대체됐다. 결과 캡처 tmp/player_feedback/steam-default-25803750-applied.jpg. 소스 main 병합/원격push는 미실행이며 별도 통합 요청 시 진행한다. Steam 클라이언트 실설치·전체 회귀는 새로 수행하지 않았다.

- **2026-10-08 Steam 최신 후속:** 사용자가 수정 ZIP을 직접 선택하고 업로드했다. 새 Build **25803750**, Depot5267751 Manifest **2614967785369199063**를 등록했고 서버6파일의 크기/SHA1이 최종 수정 ZIP과 모두 일치함을 확인했다. default25780940/Manifest1499837472719962438에서 새 빌드로 적용하는 미리보기의 다운로드 크기는4.1MB다. 승인된 Set Build Live Now와 확인창을 처리하자 Steam Mobile authenticator의 **Confirmations 승인** 요구 화면이 나타났다. 공개 적용 완료는 아직 확인하지 않았다. 사용자가 휴대폰 Steam 확인에서 빌드25803750 적용 요청을 승인한 뒤 Builds의 default와 이력을 확인한다. 추가 업데이트 재승인은 불필요하다. 대기 탭과 ignored 캡처 steam-mobile-confirmation-required.jpg를 보존했다. 아래 파일 선택 대기 기록은 이 후속으로 해소됐다.

- **2026-10-08 Steam 후속:** 사용자가 열어둔 Chrome Steamworks에서 수정 빌드 업로드·업데이트를 명시적으로 승인했다. 앱은 Released, 현재 default **25780940**, Depot5267751 Manifest **1499837472719962438**, 설명은 기존1.2.10이다. Web Uploads의 Standard 업로드 화면에서 최종 수정 ZIP 선택을 시도했으나 `input.files=[]`로 파일이 전달되지 않았다. 공식 Chrome 업로드 안내의 확장 `Allow access to file URLs` 설정 또는 사용자 직접 ZIP 선택이 필요하다. 업로드·신규 Build 생성·default 변경은 아직 실행되지 않았다. 현재 업로드 탭을 handoff로 보존했다. 파일이 선택되면 추가 업데이트 재승인 없이 upload→서버6파일 대조→default 적용→전후Build/Manifest 보고를 이어간다. 기존 default는 롤백 기준으로 보존한다.

- **2026-10-08: [1.2.10 사용자 피드백 수정 빌드 완료](V1210_PLAYER_FEEDBACK_HOTFIX_2026-10-08.md).** fetch된 origin/main@0ac9fdc에서 새 codex/v1210-player-feedback 작업선으로 시작했다. 주인공 최대 크기·공통 하단 일러스트, 창모드/전체화면·Alt+Enter·설정 저장/취소, 일반·전투 대화창 클릭을 구현했다. 버전은 **1.2.10/1.2.10.0 유지**, 제품 SHA feb230dda34b77b971081bf986a683bcb88c2d43; manifest는 기존 불변 태그를 가리키지 않고 tag=null/build_kind=same_version_hotfix다. 소스 GUI145·headless136·관련 기존3종·validator11·최종 PCK GUI145·실제 EXE headless exit0·PCK3385/금지경로0·ZIP6파일 일치 PASS. 업로드 ZIP은 저장소 루트 `builds/steam/windows/MawangCastle-v1.2.10-SteamContent-hotfix-20261008.zip` (614425126bytes/SHA256 be7f77a92095f8382334b1ae021287010c1c80696acff2b829a6464520fe0523). **소스 main 병합·원격 push·Steam 업로드/default는 미실행이며 사용자가 업로드할 예정이다.** 기존 개인 저장·원래 작업 폴더·태그/Release는 보존한다. 전체 회귀/전체 플레이/별도 QA는 NOT_REQUESTED. 아래 10-07 원본 패키지는 과거 산출물로 유지하며, 이번 세 요청 수정본은 이 ZIP이다.

- **2026-10-07: [1.2.10 정식 간체 Steam 업데이트 진행](V1210_ZH_CN_STEAM_UPDATE_2026-10-07.md).** 사용자가 새 SemVer1.2.10을 확정했고 업데이트는 이미 승인됐다. 실제 서버 default25450324/Manifest1103993226303809008, 양쪽Approved for release, Visible/Prerelease, 최단8Oct, 미게시 앱 설정0, MawangCastle.exe/Windows64를 확인했다. 누적48소스+버전4경로 제품 commit e24a651b2c9a12f760760b5461b08503e1ecacaa의 관련6종·카탈로그·그래픽·새 Windows export/PCK·출시 EXE headless3언어 부팅을 표적 검증했다. 새 PCK는3389엔트리 중 project.binary만 버전 갱신; 원본후보 및 승인1.2.9 보존. PR108/main98a0ebe0·새 불변v1.2.10 태그·정식6파일ZIP(614419325bytes/SHA2562d624e4215747dc95dd5a247212b9d8f236cc441aad9b72e8940beb968937b33) 완료. 브라우저 자동파일선택 후 input.files=[]이므로 사용자의 최종ZIP 선택 대기; Steam upload/서버대조/default는 아직 미실행. 선택 후 추가 업데이트 재승인 없이 계속한다. 기존 접근불가 기록은 이번 실제 브라우저 조회로 해소. Release App·가격·일정·권한 변경 금지. 새 전체30일/원어민/Steam실설치/2PC Cloud 미완료.


- **2026-10-07: [Steam 실행 명령문 전달 완료](ZH_CN_STEAM_TRANSFER_2026-10-07.md).** 사용자 최신지시로 본세션의Steam직접추가시도를중단하고작업트리루트 handoff.txt에복사용명령문을저장했다. 최종SteamZIP615467464bytes/SHA256 b96f82e9…와6엔트리bytes/SHA256/SHA1을재검증PASS,제품48파일해시불변. 실제원본/ZIP/DELIVERY/UploadSteamBuild경로와6파일SHA1/PCKhash·실제serverread→정식commit/사용자확정SemVer/tag검증→공식upload→서버6파일대조→default적용→전후Build/Manifest보고순서를명시했다. 승인v1.2.9/rollback·개인save보존,ReleaseApp/가격/계약/권한별도,비밀번호/토큰출력금지. **Steam업데이트는사용자가지정한기존실행가능세션의후속이며아직미실행.** 새버전으로파일이바뀌면원본ZIP보존후별도정식ZIP·새해시/표적검증필요.

- **2026-10-07: [Steam 접근 경로 추가 확인](ZH_CN_STEAM_ACCESS_2026-10-07.md).** 직접 Browser/CUA·Chrome확장/IAB 도구와 관련skill은 노출되지 않았고 Native2 bridge는 승인된turn연결정보가 없다. Chrome프로세스는 존재하지만 명령환경에서Win32창0/foreground0·UIA자식0이므로 기존브라우저화면/현재로그인상태를읽지못한다. SDK/SteamCMD는프로젝트metadata·PATH·SDK설정3·표준6경로에서찾지못했으며다른PC경로의부재는단정하지않는다. 공개업로드스크립트와공식문서의CMD/GUI경로는확인. **currentdefault/manifest/approval/readiness 미조회, upload/default 미완료**; 부모의로그인브라우저제어가능성을추측하지않는다. 다음은브라우저/CUA지원세션에기존창연결또는사용자직접서버값확인·기존SDK경로제공이다. 로그인/SteamGuard는실제화면이나타날때사용자가직접처리. 기존source48/PCK/ZIP3/승인본유지;비밀파일조회·원격디버깅·다운로드·권한·Steamwrite0.

- **2026-10-07: [간체 최종후보·영문 동적 잔여 보완](ZH_CN_RELEASE_FINAL_2026-10-07.md).** 최신 사용자 지시로 전술/시설/보물/복도/지시피드백의 영문 한국어 잔여를 최소 수정하고 간체 기존4P2 보완을 유지했다. 관련6종 PASS396/1843·1794glyph/16/967·0issues/26/45 및 카탈로그3종 PASS. 동일정상DAY17 저장으로 한1080·영중720/1080, 상태25쌍·UI1240항목·영문 예정10텍스트 외 차이0·정확해상도50PNG를 확인했다. 최종PCK 정상DAY17승리→DAY18, 정상DAY30엔딩→후일담→엔딩→재부팅 PASS. **실제 후보EXE3언어1080p Continue/전술9PNG 직접확인, v1~v5 전체 재저장payload15쌍 승인1.2.9와 일치(시간2필드제외).** Noto GSUB ZHS와 실제TextServer1800한자/미지원0·ko대SC766glyph차이 확인; 원어민 승인은 미실행. 간체7capsule/logo+promo1 직접픽셀과 상점문장 의미 검토 완료, 서버 게시 미완. **TARGETED_PASS; 새전체30일·전체회귀·23엔딩·청취·Steam설치·2PC Cloud 미실행.** source48 지문 cea7cebda249… / PCK2a2372650dd3…·584255000bytes, tmp/zh_cn_release_final_20261007/windows_candidate_final/. 승인1.2.9/구후보·ZIP9·544캡처·원본저장 보존 PASS. 최신 지시는 Steam 업데이트 승인이나 현재 서버 read/업로드/default는 부모가 이어 수행한다. Git/SemVer 신규발급 없음, manifest의tag/source_commit=null이며 기존태그재사용/위조 안 함. Release App/가격/권한 변경0.

- **2026-10-07: [간체 정상플레이 P2 수정 새 로컬후보](ZH_CN_NATURAL_FIX_2026-10-07.md).** 사용자 수정승인에 따라 동적 전술/시설·보물/확장 복도 한국어 잔여와 닫기·확대 겹침4유형을 보완했다. 실제 정상DAY1→17 저장을 확보한 뒤 최종PCK로 동일저장720p·1080p 닫기/숨김/복원·전술/시설, DAY17 정상전투의 측문복도, 기존DAY30엔딩 로드→후일담→엔딩→재부팅을 확인했다. 관련6종 PASS(신규305·간체1843/1794glyph·영문958 등), 한영10화면491항목 예정된지도도구숨김 외 차이0, 의미상태20쌍 일치. 후보EXE 부팅2회 exit0이나 두Movie PNG는 실제1080p라 EXE720p로 계산하지 않는다. **간체표적 TARGETED_PASS; 새후보전체30일/전체회귀/검수에이전트 미실행.** 구영문에도 있던 전술 한국어잔여 BASELINE-EN-01은 미보완이며 원어민·KR Noto의 SC자형·홍보·새SemVer·채택은 별도다. 새후보는 `tmp/zh_cn_natural_fix_20261007/windows_candidate_natural_fixed/`, PCK `b59cecd7…`/584254504bytes, 최종46소스 지문 `544160cf…`. 승인1.2.9·구동결PCK·ZIP6·구544캡처·엔딩저장 해시보존. 아래 구30일보고서 OPEN은 구PCK 역사기록이며 이새후보에서4유형을 표적폐쇄했다. Steam/공개push/태그/권한변경0. 다음은 후보채택과 미실행승인범위 판단이다.

- **2026-10-07: [간체 DAY1–30 정상 플레이 완료](ZH_CN_FULL_PLAY_2026-10-07.md).** 같은 동결PCK의 정상 새 게임/UI 입력으로30/30일·29/29방어승리·DAY29준비·DAY30철벽마왕요새(E02)엔딩 도달, 패배/재도전0. 정상Continue6회 날짜·이름·자원·튜토리얼·왕좌 복원 확인. 실제1280×720캡처544장/대표18장/일별CSV는 `tmp/zh_cn_full_play_20261007/`에 있다. **품질 FAIL_OPEN_P2: 동적 전술/시설효과·보물경고/측문복도 한글잔재3유형, 닫기→지도확대 겹침1유형.** 제품을 고치지 않고 기록했으며 정상Escape 우회로 완주. 동일최종PCK를 공식Godot4.6.3+수동관측Node에서 정상Main/UI로 플레이했으므로 출시EXE 직접30일 자동화 주장과 구분. 소스40/후보8/승인6/기존ZIP4 해시 보존; 소스3fb94fed…·PCK4cbd9ea… 그대로. 전분기/23엔딩/후일담/NG+/청취/전체한영회귀/원어민·SC자형·홍보승인은 미완. 다음 결정은 네P2수정과 후보채택이며, 이번 Steam/공개push/태그/버전 변경0.

- **2026-10-07: [간체 검수 지적 수정 로컬 후보](ZH_CN_QA_FIX_2026-10-07.md).** 추가 검수의 도감 한글 발견23개·심장 영어부제/hunger·설정Compact/Standard·튜토리얼TUT표시·전투 보조줄 잘림6종을 간체에 한정해 수정했다. DAY/Stage/Lv는 第n天/第n阶段/n级, hunger는 饥饿值로 표시한다. 키·형식 토큰·실제 ID·단축키·개인 이름·게임 규칙/밸런스/저장은 보존했다. 간체1843검사/1794glyph, 정확1280×720와1920×1080 각각29재현화면/965텍스트/0문제, 한영 이전/새후보 각28고정화면/935기록 차이0, 실제 새후보EXE1920×1080 부팅exit0. PCK자산·게임 데이터·영문 카탈로그3002엔트리와 승인6·이전후보7·이전ZIP2 보존. 최신 후보/7497슬롯 대조/증거는 `tmp/zh_cn_fix_20261007/`, 소스40파일 지문3fb94fed82dbf4dfd95f0651f03aca95f930e7379728e8eafbc16059b3d2fd8c, PCK 4cbd9ea1538b3e17a250c27fd66521a70a5919db6f23c0bda2dcc51686e2dc6c이다. 아래 최초 후보는 역사 기록으로 보존한다. 이 시점의30일 실제완주 미실행은 위 새 정상완주 기록으로 대체한다. 전체회귀·원어민/SC자형·홍보승인·새SemVer는 미완이다. commit/push/Steam 변경 없이 미커밋 로컬 전달이며 승인1.2.9 공개 기준은 그대로다.

- **2026-10-07: [간체 추가 로컬 후보](ZH_CN_LOCAL_CANDIDATE_2026-10-07.md).** 사용자 지정 실제 최신 원본 `tmp/uiux_v2`에서 UI5344/5344·설정/이름/튜토리얼142/142·DAY1–30대사1741/1741·제목216/216·화자39/39·story UI9/9와 영어 장식제목2개를 실제 작성·연결했다. 감사 중복 제외 주요 원문7288/7288과 전체 슬롯7493은 다른 분모다. 기존 OFL Noto의1793종 중국어 글자·언어 선택/전환/취소/저장 관련1830검사 PASS. 실제1280×720와1080p요청 창(Windows실제1886×1061)의 화면/전 대사 표시0문제, 새 후보PCK+승인EXE의 정확1920×1080 간체제목 부팅exit0. 투명logo+capsule7종·별도promo·상점간체초안 준비. **원어민7493슬롯·상점/홍보 교정, KR패밀리 Noto의 SC지역자형·홍보취향 승인, 새SemVer는 미완이다.** 승인 v1.2.9/Build25450324/Manifest1103993226303809008과 배포6파일은 해시 일치로 보존했다. Steam업로드/default/지원언어 공개/출시/Git공개push0건. Git관리영역 읽기전용으로 브랜치/커밋은 만들지 못해 현재승인-status브랜치의 미커밋40소스+handoff2문서로 전달한다. Library필수공식도우미는 python3명령부재로 시작전 실패, 기존python/py도 찾지 못했으며 우회/설치/확인된ID없음. 검토5PNG/대조HTML/Windows후보와 파일해시는 `tmp/zh_cn_work_20261007/`에 있다. 다음 순서는 문장/자형/시각 검토, 새버전/채택 결정, 허용된writer의 실제SHA커밋 및 별도 공개 승인이다. 사용자확정2026-10-08출시와 후보채택을 구분한다. main병합 전 이 로컬 CURRENT는 공개 제품 상태의 권위가 아니다.

- **2026-09-30: [Valve 게임 빌드 승인 메일 확인](V129_BUILD_APPROVAL_2026-09-30.md).** 사용자가 열어둔 Chrome 네이버 메일에서 02:44 수신 애플리케이션 검토 결과를 읽었다. 게임 검토를 마쳤고 방해 요소나 문제가 없으며 기타 출시 조건 충족 후 자신의 일정에 따라 출시 가능하다고 명시한다. 컨트롤러 개발자 추천 설정·Remote Play 안내는 선택적 권고이며 실패/필수 수정/재제출 요구가 아니다. **이전 빌드 심사 대기 상태는 이 메일로 대체한다.** 사용자는 출시 일정 변경 없이 처리하라고 지시했다. 일정·Coming Soon 공개 상태·빌드·지원 기능 변경이나 추가 심사 제출은 하지 않았다. 사용자 로그인 후9월30일 Steamworks에서 상점·게임 빌드 모두 Approved for release, Store Presence: Visible, Prerelease와 최단일8Oct를 재확인했다. 기존 내부 예정일Sep28,2026 11:00PMGMT+9 및 공개Coming Soon 표시도 그대로다. Available worldwide로 한국 제외 제한이 없다. 선택 기능의 신규 구현을 출시 선행 조건으로 삼지 않는다.

- **2026-09-25: [상점 심사 승인 및 Coming Soon 공개 완료](V129_COMING_SOON_2026-09-25.md).** 네이버 메일 원문과 Steam 지원 답변에서 상점 승인만 확인했다. 사용자의 최단 출시 지시에 따라 상점을 최초 공개했고 Store Presence: Visible / App Release State: Prerelease를 확인했다. **당시 게임 빌드는 재심사 대기(9월30일 승인 메일로 해소)**, Steam 표시 기준 **Earliest possible release: 8 Oct (2026)**다. 공개일은 한국9월25일08:35 무렵(Steam 이력24Sep16:35)이다. 잠긴 기존9월28일 예정일 대신 공개 표시를 Coming Soon으로 바꾸고 Publish to public 성공 및 한/영 공개 상점에서 확인했다. 정확한 한국시간 판매 개시 시각은 확정하지 않았다. 추가 지원 메시지는 상점 승인 통지이며 새 수정 요구가 없다. 영어 공개 제목 Who Guards the Demon Castle?와 한/영 지원·12세 표시 정상. 상점 승인 메일 제목을 게임 빌드 승인으로 해석하지 않는다.

- **2026-09-22: [1.2.9 Steam 반려 수정 및 재심사 접수 완료](V129_STEAM_REVIEW_FIX_2026-09-22.md).** 사용자가 채팅에서 1.2.9 main 병합·태그·Steam 기본 빌드 교체·Valve 재심사 제출을 명시적으로 승인했다. 전체 화면 튜토리얼 Panel의 마우스 통과 설정을 무시한 입력 차단을 재현·수정하고 한/영 실제 시설 드래그·몬스터 배치·전투 진입을 검사했다. PR104 병합, v1.2.9 태그, 태그 Windows 빌드 성공. **Steam default25450324 / Manifest1103993226303809008**, 서버6파일 크기·SHA1 일치. 수정 원인과 새 게임 조작 순서를 포함해 빌드 재심사를 제출했고 랜딩의 **Game Build: in the review queue / Submitted for review on 21 Sep**를 확인했다(한국 작업일9월22일). 기존 반려 Build25423797을 현재 빌드로 해석하지 않는다.


- [한국 출시 증빙·등급 안내](V128_KOREA_RELEASE_2026-09-21.md): 사용자 제공 게임위 원본에서 Valve/Steam 유통 통보 정상 접수 및 통보 내용대로 운영 가능 회신을 확인했다. 한국 제외 제한 없음·KRW5,450. 한/영 상점에 12세 이용가·폭력성·STOVE 자체등급번호를 저장하고 BETA에서 확인했다. 에이전트의 확인란 클릭은 자동 승인 검토에서 차단됐으나, 이후 사용자가 직접 등록을 완료했다. 저장 성공 화면에서 KGRB 체크·등급12 및 STOVE/유통통보 근거 설명을 확인했으므로 현재 상태를 미등록으로 되돌려 해석하지 않는다. 지원 문의 전송/원본 첨부는 사용자 지시대로 하지 않고 초안만 보관한다.
- Steam Auto-Cloud: 용량0·미설정 상태를 확인해 10 MiB/50파일, 실제 캠페인 저장5종과 성 배치1종의 정확한 경로를 등록·게시했다. 개발자 테스트 모드 유지, Dynamic Sync 미사용, 상점 Cloud 지원은 미체크다. 두PC 실동기화와 Steam 클라이언트 실설치는 미완료다. 실행 경로 MawangCastle.exe/Windows64-bit 및 변경 전 미게시 앱 설정 없음도 확인했다.
- [최신 상점 마무리 세션](V128_STEAM_STORE_POLISH_2026-09-21.md): **BILINGUAL_VISUALS_SAVED / 당시 STORE_REVIEW_PENDING (9월25일 승인·공개 완료)** (당시1.2.8 기본 빌드는 아래1.2.9로 교체). [빌드 검증 근거](V128_STEAM_BILINGUAL_2026-09-21.md).
- Steam App **5267750**, Depot **5267751**, 현재 Build **25450324**, Manifest **1103993226303809008**.
- 서버 파일6개 크기·SHA1이 최종 로컬1.2.9와 일치한다. ZIP 무결성·manifest 검증 완료. EXE는 한/영1080p 부팅 확인한 후보와 동일하며, 최종 컴파일PCK 첫 플레이 회귀26개도 통과했다.
- Steam 서버의 default가 **25450324(1.2.9)**이고 Build history에 Set live 기록이 있다. Preview 확인창 도구 장애는 새 업로드 탭에서 default 지정 Commit 경로로 해결했다. 중간 Build25450138은 동일 Manifest를 사용하며 기본 빌드가 아니다.
- 업로드 폴더: `builds/steam/windows/v1.2.9/`. ZIP: `builds/steam/MawangCastle-v1.2.9-Windows-Steam.zip`, **614,172,557 bytes**. SHA256 `64df71332273f30027d324a9400734c636de3c770e05078bf9b01ba2321f1627`.
- 한국어·영어 상세 소개와 짧은 설명을 새로 저장했고 양쪽 Steam BETA 미리보기에서 실제 표시를 확인했다. 게임 내 설정에서 두 언어를 선택할 수 있음을 명시했다.
- Steam 영어 Interface·Subtitles 체크 저장 확인, Full Audio 미체크. 한국어 지원 유지. 영어 현지화 게임명 **Who Guards the Demon Castle?** 추가·게시 성공. 한국어 현지화 이름 유지.
- 상점은9월25일 승인 확인 후 Coming Soon으로 최초 공개했다. 기존9월28일 내부 예정일은2주 잠금 상태로 유지하며, 공개 날짜 표시만 Coming Soon으로 저장·게시했다. Steam 안내상 최소 대기 종료 후 내부 예정일과 무관하게 출시 버튼을 실행할 수 있다. 가격 변경 없음.
- 상점 심사는9월25일 승인됐다. 수정 빌드는21Sep 제출 후9월30일02:44 KST 승인 메일을 받았다. 중복 제출하지 않았다. Content Survey815414의 영어 Generative AI 설명도 미리보기에서 확인했다.
- 대표 이미지4종과 라이브러리 캡슐·헤더·로고3종을 한/영 각각 업로드·저장했다. 사용자는 드롭 입력만 도왔고 이후 분류·규격 확인·저장은 에이전트가 수행했다.
- 이전1.2.8에서 실제 한/영1080p 화면14장을 촬영했다. 갤러리는 구버전·중복 장면을 정리해 전투 우선 대표6장(한글3/영문3 공유 갤러리)으로 저장했다. 소개에는 전투·건설·동료성장3장씩을 언어별 자동 전환 및 대체 텍스트와 함께 연결했다.
- Steam BETA에서 한/영 헤더·설명 이미지 정상 로딩 및 갤러리 순서를 확인했다.9월25일 실제 공개 영어 상점에서 Who Guards the Demon Castle? 제목을 확인했으므로 과거 BETA의 한국어 제목 표시를 현재 문제로 취급하지 않는다. 공개 한국어 제목도 유지된다.
- Valve 랜딩의 제출 체크리스트는 완료 상태이며 상점 승인·공개 완료, 빌드도9월30일 승인 메일 확인 완료다. 최초 Coming Soon 공개 후 최소2주 요건 때문에 기존9월28일 출시는 불가하다. Steam 표시 최단일10월8일을 기준으로 출시 가능 여부를 확인해야 한다.
- [전체 영어화 근거](CONTENT_ENGLISH_FULL_DAY01_30_2026-09-21.md): 대사1,741개·장면216개·UI영문5,344항목. 73화면과 모든 대사 표시 검증. 게임 원문·ID·저장 형식·비용·보상 보존.
- 전체 번역 패키지 `tmp/MawangCastle-English-DAY01-30-20260921.zip`(25,236,693bytes)과 `tmp/english_full_delivery_20260921/dialogue-bilingual.html` 보존.
- Steam 실제 설치·삭제, 두PC Cloud, 성능 하한 측정은 완료한 검사가 아니다. Valve 상점 심사는9월25일, 게임 빌드는9월30일 승인 메일로 확인됐다. Valve 승인과 자체 실기기 검증을 구분한다. 기존 상점·등급 근거는 [v1.2.7 상점 기록](V127_STEAM_STORE_PROMOTION_2026-09-14.md), [등급 기록](V127_ENGLISH_PROMO_RATING_2026-09-14.md)에 있다.

## 4. 사용자 확정 방향

최신 UI·UX V2 요청(2026-09-12)은 이전 외형만 변경/현재 레이아웃 유지 제한을 대체한다. 아래의 과거 출시 지시는 출시 이력이며, 사용자의 계속 지시에 따라 U0~U3 보완과 U4/U5 구현·관련 직접 검사까지 이어갔다. 과거의 전체/8인 검수·출시 지시는 현재 실행 범위가 아니다.

1. 제품 매력 우선순위: `전술 지휘 쾌감 → 몬스터 애착 → 행정·상황 코미디`
2. 유효 명령은 최대 0.3초 안에 반응하고 지속시간 동안 평상시 AI보다 우선한다.
3. 수행 불가 시 대상 근처 이펙트와 비모달 소형 알림으로 `거부 이유 + 가능한 해결 행동`을 표시한다.
4. AI는 역할에 맞게 영리하되 독단적이지 않은 `예측 가능한 유능함`을 지향한다.
5. 기준 사용자는 전략게임 초보자이며 숙련 깊이는 별도 보조 기준으로 본다.
6. 한 화면 한 목적, 상시 핵심 행동 최대 3개, 중요 행동 2단계 이내를 지향한다.
7. 핵심 몬스터는 짧고 자주 반응하는 공동 주연이며 시스템 설명은 UI와 바티가 담당한다.
8. 마왕은 가벼운 허당미를 유지하되 후반 결정적 순간에는 신뢰받는 지휘관으로 성숙한다.
9. 기본 분위기는 계속 가볍게 유지하며, 마왕의 후반 성숙 장면만 진지함을 강화한다.
10. 미술은 실제 게임 크기에서 깨끗한 스타일라이즈드 2D를 우선하고 자글거림·계단·이동 중 shimmer를 결함으로 본다.
11. Windows PC가 품질 합격 기준이며 Web·모바일 등은 테스트 범위다.
12. 검수 대상은 타이틀부터 DAY 30까지의 전체 출시본이며, 실행 순서는 `핵심 전투·UI → 대사·그래픽 → 전체 캠페인`으로 나눈다.
13. 블라인드 검수단은 전략게임 초보 3명, 디자인 관심 게이머 2명, 스토리 관심 게이머 2명, 전략게임 숙련자 1명으로 구성한다.
14. 오디오·효과음·믹스를 검수 범위에 포함한다.
15. 검수 뒤 수정본의 목표 버전은 `v1.2.6`이며 기존 `v1.2.5` 태그는 보존한다.
16. 각 단계는 `검수 → 수정 → 재검수 통과`를 완료한 뒤에만 다음 단계로 넘어간다.
17. 역할별 AI 에이전트 8명의 단계별 검수·수정·재검수를 근거로 Codex가 `v1.2.6` 완성 판정을 내리고 완성품을 사용자에게 전달한다. 사용자와 지인의 테스트는 그 이후 진행하며, 새 피드백이 오면 별도 후속 개선 주기로 접수한다. 인간 테스트는 이번 완성 판정의 선행 게이트가 아니다.
18. 단계 게이트는 재현 가능한 P1/P2 0건, 독립 검수 8명 중 6명 이상 통과, 디자인 또는 스토리 담당 2명의 동일 핵심 결함 지적 시 보류로 한다. P3는 기록 후 다음 단계 진행이 가능하다.
19. 현재 수정 사항을 공통 런타임과 전체 캠페인 회귀에 적용해 `v1.2.6` 정식판으로 승격하고 `main`에 반영한다.
20. 정식 엔진은 Godot `4.6.3`으로 고정하고, 이번 출시는 Full·8인 역할 검수 대신 핵심 기능 표적 검수만 거쳐 `main`·`v1.2.6` 태그·Release로 등록한다. 이 최신 지시는 이번 출시의 4.5.2·Full 선행 요구를 대체한다.

## 5. 범위 경계와 교정 사항

- 이번 버전 오인의 직접 원인은 루트 안내가 `게임소스/`를 현재 구현 진입점으로 고정하고, 그 폴더의 과거 v20 브랜치 `CURRENT.md`가 자신을 단일 진입점으로 표시한 데 있다. 폴더명 대신 Git branch·HEAD·`main`·`origin/main`과 권위 문서 쌍을 확인하도록 루트·main·과거 작업트리 안내를 교정했다.
- 기존 `release/v2.0`과 `codex/v20-*`는 과거 DAY 1~5 실험·검증 참고선이다.
- 해당 브랜치의 UI·명령·AI 구현이나 `CURRENT.md`를 현재 제품으로 간주하지 않으며, 커밋 범위를 1.2.6에 그대로 이식하지 않는다.
- 이번 검수는 2.0 제품 개발 계획이 아니다. v20에서 얻은 아이디어는 비교 근거로만 사용하고 v1.2.5 기반의 1.2.6 런타임에서 다시 구현·확인했다.
- 목표 버전은 `1.2.6`으로 확정됐고 기존 `v1.2.5` 태그와 Release는 불변으로 보존한다.
- `INT-20260820-020`: Godot 4.6.3 정식 기준과 최소 표적 검수 출시가 `USER_CONFIRMED`됐으며, 이번 출시에 한해 과거 4.5.2 고정과 Full·8인 선행 게이트는 `SUPERSEDED`다.

## 6. 다음 작업 순서

- 간체제품최종검수는 [ZH_CN_RELEASE_FINAL_2026-10-07.md](ZH_CN_RELEASE_FINAL_2026-10-07.md), 최신담당이관은 [ZH_CN_STEAM_TRANSFER_2026-10-07.md](ZH_CN_STEAM_TRANSFER_2026-10-07.md)와작업트리루트 handoff.txt를따른다. 사용자가기존실행가능세션에전달하며본세션은Steam접근추가시도를하지않는다. 후속세션은실제currentdefault/readiness·rollback을읽고정식provenance요건처리후6종SteamContent만업로드·검증·default적용하고실제Build/Manifest를보고한다. 업데이트자체는승인됐으나새SemVer/실제SHA/tag는미발급;기존승인v1.2.9/태그/바이너리를보존하고ReleaseApp/가격/계약/권한은별도범위다.

0. [1.2.9 반영 완료 기록](V129_STEAM_REVIEW_FIX_2026-09-22.md)10절이 빌드 반영 결과다. 버전 승인은 받았으며 PR104/main·v1.2.9·Steam default25450324·재심사 접수까지 완료했다. 버전 승인을 다시 요청하거나 기존25423797로 되돌리지 않는다. 최신 현황은 [9월30일 게임 빌드 승인 기록](V129_BUILD_APPROVAL_2026-09-30.md)이며 출시 일정을 바꾸지 않고 최초 공개2주 대기와 최종 출시 절차를 처리한다.


1. [한국 출시 후속 기록](V128_KOREA_RELEASE_2026-09-21.md)과 [상점 마무리 세션](V128_STEAM_STORE_POLISH_2026-09-21.md)을 기준으로 이어간다. 게임위 원본 확인은 완료됐으므로 이전 유통통보 미확인 기록을 현재 상태로 사용하지 않는다. 한국 등급 안내는 상점 본문에 저장됐고 사용자가 별도 KGRB 12 등록까지 완료한 것을 확인했다. Cloud 정확한 경로6개도 개발자 테스트 모드로 게시했다. 지원 문의는 사용자 지시대로 초안만 보관한다. 기본1.2.9 활성화·전체 영어화·한영 소개·대표/라이브러리 이미지 업로드·갤러리 정리는 완료됐으므로 반복하지 않는다.
2. 상점 심사 승인·공개와 게임 빌드 승인 메일 확인을 완료했다. 컨트롤러·Remote Play 안내 때문에 추가 심사 제출이나 출시 일정 변경을 하지 않는다. 9월30일 로그인 복구 후 관리 화면의 양쪽Approved for release를 대조 완료했다.
3. 사용자는 무조건 최대한 빠른 출시를 지시했다. 9월30일 Steam에서 다시 확인한 최단일2026년10월8일을 기준으로 기존 일정과 출시 버튼 활성 여부를 확인한다. 빌드 승인 메일은 확인됐고9월30일 사용자 지시는 출시 일정 유지다. 기존 내부 예정일9월28일은 자동 출시나 출시 차단 조건이 아니다. 자동 출시 예약/정기 확인 작업은 아직 설정하지 않았으며 출시 가능해지면 Release App 절차를 실행해야 한다. 공개 영어 제목과 Coming Soon 표시는 확인 완료다.
4. Steam 실설치·실행·삭제 및 두PC Cloud 업로드/다운로드를 검증한다. 현재 도구는 브라우저 제어만 지원해 Steam 네이티브 클라이언트 조작은 수행하지 못했다. 두PC 검증 후 Cloud 개발자 테스트 제한을 해제·게시하고 상점 지원 기능을 켠다. 필요한 사양 확인, Valve 심사·공개 대기 요건 충족 후 사용자 지시에 따라 출시를 진행한다. 기존 태그·Release 파일은 보존하며 가격·할인·광고비는 임의로 변경하지 않는다.
5. 주 에이전트가 직접 수행한다. 서브에이전트·전체 캠페인·8인 검수를 자동 실행하지 않는다.
## 2026-10-12 actual skill completion — Group 1 checkpoint, continuing

[최신 승인·기술별 실행 명세와 다음 묶음](SKILL_COMPLETION_SPEC_2026-10-12.md). 사용자 ‘이름에 맞게 스킬구현하고 컷신도 만들자’로 앞선5설계보류/DLC후보 경계를 재승인. codex/basic-support-skill-recovery, product5f8554f3df4e63dc413f2f24de311041d4aa2102. 실제 문턱 거미줄4고유통과/화염제거, 포포 실제 보행 전달 후5초효과, 모리 현재왕관 치유배율, 푸딩 실제HP변화별첫40%방호 연결. GUI253/0·기존연결126/0·continuity89/0·DAY2선택headless61/0·editor0. 독립지적3건(억제치유배율/동일프레임방호/발사고정경로) 수정. 개발export/packed검증과남은메아리·왕관액티브·계승·passive/mastery정상경로 계속. 실제상층연결은 별도 범위 질문 대기; 그림/층라벨만을다층성공으로세지않음. 성장코드미착수. 개인698파일/이전aab·979빌드 보존, 원격Git·Steam·홍보없음. 사람OS/자연해금/재미·실제설치노출/두PC Cloud NOT_RUN. 전체기능완료 보고아님.

## 2026-10-12 actual skill completion — Mori royal support verified, continuing

[왕관모리실제우산·성찬연결](ROYAL_MORI_RECOVERY_2026-10-12.md). Product6869de87b9acb0684da935b9310380652282cb06 / codex/royal-support-skill-recovery. 실제전체정화·5초3/s재생·한명fatal직전HP1한번·종료후.85회복6초, 발신모리과회복50%/maxHP35%cap·독립TTL5초방호·실제소모와기여, 현재왕관컷신/자동·수동·사용표시 연결. 새재생크기·TTL·종료정책은명시NEW_DESIGN. GUI119/0, 기본지원회귀253/0·합동70/0·continuity89/0·editor/export0·실제PCK15/0·격리EXE180exit0, 독립읽기TARGETED_PASS. source/recipientqueued·즉시억제·단독skillseal·일반retaliation오인 수정, 실제HP1/life와overkill원피해분리. 현재1F실전,metadata가진짜2F증거아님. 정상영입/mastery·왕관body스탯억제/복귀와핀maxmana/저항의미후속, 남은5액티브·젤계승·passive/정상해금과성장계속. 새모리검토패키지분리, 이전5f/979/aab·개인698보존. DKChrome도구시작오류로실제Steamworks현재읽기NOT_RUN,과거parent보고와분리. Steam·원격Git·홍보없음.
