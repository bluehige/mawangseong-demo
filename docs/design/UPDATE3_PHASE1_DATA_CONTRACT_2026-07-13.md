# 3차 업데이트 Phase 1 데이터 계약 결과

- 완료일: 2026-07-13 (KST)
- 범위: 데이터 schema, 빈 최소 fixture, 참조 검증기
- 런타임 적용: 없음
- 저장 버전: v3 유지

## 구현 결과

1. `data/regular_version/update3/`에 front, overlay, heart, duo link, monster/enemy extension, rival finale, ending, chronicle 카탈로그 9종을 만들었다.
2. Phase 1의 실제 카탈로그는 모두 빈 `{}`이며 `DataRegistry`는 읽기만 한다.
3. `ValidateUpdate3Content.gd`가 필수 필드, 전역 ID 중복, 캐릭터·스킬·리소스, front→overlay→DAY 30 적, heart 스킬·Stage HP, duo 멤버·handler, rival 3단계, ending front·metric·E12~E16을 검사한다.
4. `Update3DataContractTest`가 정상 합성 fixture와 의도적 오류 11종을 함께 검증한다.

## 검증 결과

- Phase 1 전용: **PASS, 17/17**
- Quick 핵심 통합: **PASS, 14/14**
- 기존 저장 목표 버전: **3 유지**
- 기존 게임 데이터 변화: 빈 카탈로그이므로 없음

## 결정 로그

| ID | 결정 | 이유 |
|---|---|---|
| U3-P1-D001 | 3차 데이터는 `data/regular_version/update3/` 한 곳에만 둔다. | 루트와 update3 폴더의 중복 저장을 금지한다. |
| U3-P1-D002 | Phase 1 실제 fixture는 빈 `{}`로 둔다. | 이후 Phase의 콘텐츠를 미리 구현하지 않고 schema만 고정한다. |
| U3-P1-D003 | schema를 별도 외부 라이브러리 대신 Godot 검증기로 고정한다. | 실제 `ResourceLoader`, 기존 카탈로그와 같은 환경에서 참조를 검사한다. |
| U3-P1-D004 | front의 `final_enemy_id`와 overlay DAY 30 `boss_enemy_id`를 모두 검증한다. | 최종 보스 누락과 overlay 연결 누락을 각각 조기에 찾는다. |
| U3-P1-D005 | 합동기 멤버는 개체 ID를 사용한다. | 같은 종이라도 실제 관계·계승 개체를 정확히 식별한다. |
| U3-P1-D006 | E12~E16만 3차 ending code로 허용한다. | 기존 E00~E11 도감을 보존한다. |
