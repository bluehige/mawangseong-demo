# 3차 업데이트 Phase 25C — 톡톡 전용 아트·유대 기억 완료 기록

## 완료 범위

- 개인 유대 기억 3종: `toktok_spare_plate`, `toktok_polish_day`, `toktok_heart_patch`
- 초상화 3종: 기본, 기쁨, 결의
- 전술 특화 배지 2종: 강철 돌진, 긴급 수리
- 전투 애니메이션 16프레임: 대기 2, 이동 4, 공격 4, 스킬 4, 쓰러짐 2
- 스킬 효과 3종: 장갑 충돌, 심장 수리, 고철 리벳
- 생성 원본과 출처 기록: `assets/source/imagegen/toktok/`
- 실제 전투 화면 검수: 1920×1080, 1366×768

## 배경 정리 보정

- 생성 원본의 금속 그림자와 회색 격자 배경이 비슷해 일부 격자가 남는 문제를 확인했습니다.
- 자산 준비 도구의 중성색 배경 판정 기준을 조정한 뒤 전체 톡톡 자산을 다시 만들고 Godot에서 재가져왔습니다.
- 재생성 뒤 두 해상도 모두에서 투명 가장자리, 캐릭터 윤곽, UI 겹침을 다시 확인했습니다.

## 검증 결과

- `ToktokPhase25CTest`: 61/61 통과
- `ToktokPhase25CVisualReview`: 통과
- 두 해상도에서 회색 격자 잔여물 없음
- 전투 중앙과 선택 패널에서 캐릭터·효과 잘림 없음
- 축소 UI에서 패널·버튼·효과 겹침 없음

## 결과물

- `tmp/update3_phase25/toktok/toktok_combat_1920x1080.png`
- `tmp/update3_phase25/toktok/toktok_combat_1366x768.png`
