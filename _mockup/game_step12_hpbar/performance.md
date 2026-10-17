# Step12 HP바 C안 — 사용자 확인 대기

기준: 0e08fd1c82005a5968a297079b902610da380d6e. 적용 전 baseline은 제품 수정 전에 측정했다.
아래는 같은 시드12017, 기존 F DAY1 스트레스 장면, 아군19명+적10명, 1920×1080,
Godot4.6.3 OpenGL Compatibility / RTX3060Ti / 60fps 제한, 준비2초+측정18초 결과다.
적 HP×100/공격×0.1, 아군 HP100000은 측정 장면에서만 주입했다. 실제 밸런스 데이터 변경0.
비전투 숨김은 끄고 측정했다. E DAY7 캡처와 성능 장면은 별개다.

|항목|적용 전|C안 적용 후|
|---|---:|---:|
|평균 FPS|59.885|60.031|
|평균 프레임 ms|16.699|16.658|
|프레임 p95 ms|20.801|20.748|
|프레임 p99 ms|26.666|26.432|
|process 평균 ms|16.792|16.508|
|physics 평균 ms|11.989|12.513|

평균 약60fps 유지(1081프레임). p95/p99에는 16.67ms를 넘는 프레임이 있으므로
모든 프레임의 고정60fps나 다른 기기의 성능을 보장하는 결과는 아니다.
process/physics 값은 Godot 모니터 값이며 서로 더해서 프레임 시간으로 해석하지 않는다.

직접 검사 732항목, 실제 렌더 검사 15항목: 실패0.
몬스터24종+적33종(현재 합쳐진 실제 등록 목록), 전체64px 캐시 썸네일 검증.
적20종은 기존 전용 초상, 나머지13종은 기존 상세창처럼 자기 idle 단일 프레임.
대체 목록: engineer, royal_scout, monster_binder, ward_breaker, supply_raider, anti_magic_archer, royal_field_medic, coal_spark, dusk_courier, bronze_automaton, shadow_duelist, spore_doll, root_tender.
적 데이터에 level이 없으면1; 몬스터 레벨은 기존 roster 값. 새 적 레벨 수치 생성 없음.
보스4종은 기존0097 배율1.35. 10명 이상일 때 초상/레벨 배지만0.85, 바와 몸 배율은 유지.
피해 잔상은 전투시간0.4초 유지 후 초당HP비율1.8로 감소, 회복은0.35초 초록 반짝.
일시정지에서는 잔상/반짝 타이머도 정지한다. 보호막은 실제 흡수량/최대HP,
시간제 피해감소 방패는 기존 감소비율로 덧바를 표시한다.

원형 마스크 GPU 투명 코너/원본 중심색 보존, 리본 단일 이름,
0099 머리6화면px/겹침 회피/연결선, 0100 실제 자세 윤곽, 설정 저장·취소·기본값,
DAY29 준비일 전투 차단을 확인했다. 상태 받침4개는 방호/속박/둔화/약화 우선 표시다.

`battle_e_day7.png`: E DAY7 실제 웨이브 첫 교전 후 정지.
`battle_crowd.png`, `boss_leon.png`: 정지 상태의 명시적 혼잡 배치, 레온 시험 추가 출현.
`damage_ghost.png`: 실제 receive_damage/grant_duo_barrier API로 잔상과 보호막 표시.
`compare_hpbar_vs_mockup.png`: 왼쪽 요청 원본 hpbar_C.png, 오른쪽 실제 혼잡 장면.
비교 화면의 날짜/카메라/배치는 동일한 재현이 아니며 UI 형태 비교용이다.

기존 혼합 파일 1637개 SHA256/존재 보존, 변화0. 사용자 세이브 접근/수정0.
APPDATA/LOCALAPPDATA는 tmp/v130r_step12 아래 시험 복사본 환경만 사용.
전체 회귀·전체 캠페인·export·별도 검수 에이전트는 NOT_REQUESTED/NOT_RUN.
신규 그림 생성0; 사용자 선택 GPT C 원본과 기존 초상만 재사용. 알파 자산 49개 확인.

재현: `tools/run_v130r_step12.ps1 -Mode direct`, `-Mode capture`, `-Mode performance` 순서로
각각 엔진1개씩 실행 후 `python tools/tests/v130r_step12_report.py`.
baseline_checks.json은 수정 전 측정 기록이며 현재 C안으로 다시 생성하지 않는다.
원자료/원본 캡처/개별 축소본은 이 폴더에만 보관한다. **사용자 확인 대기.**
