# 몬스터 애착·다중 엔딩 기반 구현 작업 기록

작성일: 2026-07-12

## 결론

기존 DAY 1~30 흐름을 유지하면서, 다중 엔딩과 다음 회차가 실제 플레이 화면에서 이어지도록 연결했다.

- 이름 있는 핵심 몬스터 4명의 개체 ID
- 회차 지표 정의와 안전한 누적/복원
- 5개 엔딩의 조건식, 점수, 우선순위, 기본 엔딩 규칙
- 저장 v1의 몬스터·선택·원정·성장 참조를 개체 ID로 바꾸는 v2 변환
- 기존 v1을 보존하는 별도 v2 안전 저장
- DAY 30 결과에 따라 기본/식구/철벽/공포/라이벌 엔딩을 고르는 실제 판정
- DAY 29의 `재전 약속`/`성 수호` 최후 선언 선택
- 엔딩 화면의 계승 몬스터 선택과 `다음 회차 시작`
- 엔딩 도감·완료 회차·기억 1개를 보존하고 레벨·자원·시설·진화를 초기화하는 DAY 4 압축 시작
- 방어전·원정에서 오르는 유대, 25점 단위 관계 단계와 기억 해금
- 몬스터 관리 화면의 유대·관계 단계·기억 개수 표시
- 푸딩·곱·핀 각각 2갈래 진화 선택과 유대 조건
- 타이틀 저장 요약과 엔딩 화면의 현재 회차·발견 엔딩 수 표시

## 구현 파일

데이터:

- `data/monster_instances.json`
- `data/run_metric_definitions.json`
- `data/ending_rules.json`

코드:

- `scripts/systems/monsters/MonsterInstanceValidator.gd`
- `scripts/systems/endings/RunMetricsTracker.gd`
- `scripts/systems/endings/EndingConditionEvaluator.gd`
- `scripts/systems/legacy/NewCycleService.gd`
- `scripts/core/CampaignSaveMigratorV1ToV2.gd`
- `scripts/core/CampaignSaveV2Store.gd`
- `scripts/core/DataRegistry.gd`
- `scripts/game/GameRoot.gd`
- `scripts/game/ManagementSceneController.gd`

검사:

- `tools/MonsterLegacySystemsSmokeTest.gd`
- `tools/MonsterLegacySystemsSmokeTest.tscn`

## 저장 안전성

v2는 `user://campaign_save_v2.json`을 사용한다. 기존 `user://campaign_save_v1.json`과 경로가 다르므로 변환 과정에서 v1을 삭제하거나 덮어쓰지 않는다.

v2 쓰기 순서:

1. 메모리에서 전체 계약 검사
2. `.tmp`에 기록
3. `.tmp`를 다시 읽어 검사
4. 기존 v2가 있으면 `.bak`으로 이동
5. `.tmp`를 기본 v2로 교체
6. 기본 v2를 다시 검사
7. 실패하면 이전 `.bak` 복원

## 전용 검사 결과

```powershell
Godot_v4.5.2-stable_win64.exe --headless --path . --scene res://tools/MonsterLegacySystemsSmokeTest.tscn
```

결과:

```text
MONSTER_LEGACY_SYSTEMS_SMOKE_TEST: PASS (31 assertions)
```

확인 항목:

- 핵심 몬스터 4명 데이터 참조
- 엔딩 5개 지표 참조
- 알 수 없는 지표·연산자 거부
- 몬스터 식구 엔딩 판정
- 조건 미달 시 기존 기본 엔딩 유지
- 지표 자료형 변조 거부와 저장 왕복
- v1의 레벨·EXP·방·특화·승급 보존
- 선택 몬스터·원정 편성·성장 대상 ID 변환
- 완료 v1의 기본 엔딩 도감 보존
- v2 임시 저장·재검증·안전 교체
- 손상된 v2 덮어쓰기 거부와 이전 정상 파일 유지
- 엔딩별 조건 판정과 기본 엔딩 후퇴
- 완료 회차와 엔딩 도감 누적
- 다음 회차에서 레벨·진화 초기화 및 기억 1개 계승
- 푸딩·곱·핀의 진화 분기 각 2개 구성
- `GameRoot.gd`와 관리 화면 코드의 문법 연결

## 2026-07-12 그래픽 진행 현황

- 엔딩 일러스트: 5/5 생성 및 엔딩 화면 연결 완료
- 진화 배지: 6/6 생성 및 진화 데이터/선택 버튼 연결 완료
- 진화 기본 초상: 6/6 생성 및 진화 완료 뒤 몬스터 화면 연결 완료
- 진화 감정 변형 초상: 12/12 (승리·부상 각 1장, 진화 데이터 연결 완료)
- 전투 프레임: 96/96 (진화 6종 각 16프레임, 실제 전투 스프라이트 연결 완료)
- 스킬 아이콘: 8/8 (`skills.json`에 실제 등록된 스킬 전부, 관리 화면 연결 완료)
- 신규 VFX: 6/6세트 (진화별 전용 4프레임 효과와 스킬 연결 완료)
- 엔딩 문양: 5/5, 도감 썸네일: 5/5, 유대·추억·기풍 UI 아이콘: 3/3 (데이터와 실제 화면 연결 완료)

현재 계획서에 수량으로 명시된 그래픽 계약은 모두 제작했다. 완료 범위는 엔딩 일러스트 5장, 엔딩 문양 5개, 도감 썸네일 5장, 진화 배지 6개, 진화 초상 18장, 전투 프레임 96장, 스킬 아이콘 8개, VFX 6세트(24장), 유대·추억·기풍 UI 아이콘 3개다.

## 확장 마감

- 엔딩 도감은 타이틀 화면에서 열 수 있는 5칸 카드 화면으로 구현했다. 발견한 엔딩은 전용 썸네일·문양·발견 횟수·최초 회차를 표시하고, 미발견 엔딩은 잠금 카드로 표시한다.
- 기억 ID 20종을 실제 회상 제목·사건 요약·대사와 연결하고 몬스터별 기억 상세 화면을 추가했다.
- 2회차 시작 시 왕국 교리 대응 3종 중 하나를 선택하고 즉시 자원·수입·유대 효과를 받도록 했다. 선택은 회차 프로필과 저장 자료에 남는다.
- 2회차부터 본 대화 건너뛰기와 전투 x2 배속을 사용할 수 있다.

## Python 직접 제작 런타임 그래픽 교체

직접 도형을 그리던 Python 산출물은 GPT 내장 ImageGen 원본으로 교체했다.

- 기본 몬스터 3종, 기본 적 3종, 방패병, 셀렌: 총 128 전투 프레임
- 방패병 전용 초상 1장
- 진화 배지 6개
- 기본 VFX 24프레임과 선택 원 1장
- 기본 UI 아이콘 9개
- 구형 방 소품 9개와 구형 타일 3개

원본 15개와 출처 설명은 `docs/concepts/gpt_runtime_replacement_2026-07-12/`에 보존했다. `tools/prepare_gpt_runtime_assets.py`는 원본을 자르고 투명 처리하는 준비 도구이며 그림을 직접 그리지 않는다. 기존 직접 그리기 진입점 5개도 이 준비 도구를 호출하도록 교체했다.

조사관·공병·로만·레온·진화형·엔딩·스킬 아이콘·진화 VFX·던전 쿼터 v2는 현재 런타임 파일이 이미 GPT 내장 생성 원본에서 준비된 자료라 재생성 대상에서 제외했다. 게임에 쓰이지 않는 QA/컨셉 미리보기도 런타임 교체 대상이 아니다.
