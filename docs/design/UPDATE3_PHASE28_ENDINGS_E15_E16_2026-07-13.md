# 3차 업데이트 Phase 28 완료 기록 — E15·E16

작성일: 2026-07-13

## 구현 결과

- E15 `둘씩 걷는 복도`를 합동기 3종 사용, DAY 30 사용, 평균 유대, 기여도 상한, 전투 불능 여부로 판정한다.
- E15 동점 점수에 합동 기억 2개, DAY 30 장착 합동기 사용, 5인 균등 기여, DAY 29 선호, 미발견 여부를 반영한다.
- E15 보상으로 합동기 편성 프리셋 2칸과 현재 출전 인원 기준 자동 추천을 해금한다.
- 전투 사이 관리 화면에서 합동기 편성을 다시 열 수 있어 E15를 실제 회차 플레이로 달성할 수 있다.
- E16 `세 전선의 휴전문`은 세 전선 클리어, 레온·셀렌·로만 관계 65, E12·E13 발견을 모두 갖춘 프로필에만 DAY 29 선택지가 노출된다.
- E16은 현재 회차의 최종 승리, 휴전문 선택, 보물 손실·심장방 무력화·포기 횟수 조건까지 모두 만족해야 한다.
- E16 보상은 다음 회차 세 전선 즉시 해금, 전선 순환 옵션, 연대기 최종 명패이며 전투 능력치 보상은 없다.
- 전선 순환 옵션은 해금 직후에도 반드시 꺼짐으로 시작한다.
- E14·E15 동점은 심장/합동 지표 점수, DAY 29 선호, 미발견 여부 순으로 갈리고 완전 동점은 E14가 이긴다.

## 저장 호환성

- v3→v4 변환 기본값에 프리셋, 자동 추천, 전선 순환, 연대기 명패 필드를 추가했다.
- v4 보조 저장에 새 프로필 필드가 모두 복사된다.
- 엔딩 지표는 JSON 직렬화 후 복원해도 같은 E15·E16 판정을 유지한다.

## 그래픽

- `assets/ui/endings/ending_linked_corridors.png`
- `assets/ui/endings/ending_three_front_armistice.png`
- 원본과 제작 기록: `assets/source/imagegen/update3_endings/`

## 검증

- `EndingPhase28Test`: 45/45 PASS
- `EndingPhase28VisualReview`: PASS
- `EndingPhase27Test`: 44/44 PASS
- `SaveV4MigrationTest`: 42/42 PASS
- `Update3DataContractTest`: 17/17 PASS
- `Update2EndingCatalogSmokeTest`: 38/38 PASS
- `ChroniclePhase26Test`: 37/37 PASS

시각 검수 산출물은 `tmp/update3_phase28/`에 저장했다.
