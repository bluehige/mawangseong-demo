# 3차 업데이트 Phase 25B — 코코 전용 아트·유대 기억 완료 기록

## 완료 범위

- 개인 유대 기억 3종: `koko_bone_not_food`, `koko_wrong_scent`, `koko_home_is_route`
- 초상화 3종: 기본, 기쁨, 추적 결의
- 전술 특화 배지 2종: 현상금 냄새꾼, 왕좌 양치개
- 전투 애니메이션 16프레임: 대기 2, 이동 4, 공격 4, 스킬 4, 쓰러짐 2
- 스킬 효과 3종: 냄새 고정 문양, 묘지 등불 짖음, 귀환 발자국
- 생성 원본과 출처 기록: `assets/source/imagegen/koko/`
- 실제 전투 화면: 1920×1080, 1366×768

## 검증 결과

- `KokoPhase25BTest`: 61/61 통과
- `KokoPhase25BVisualReview`: 통과
- 두 해상도 모두 검보라 몸·푸른 눈·등불 꼬리 식별 가능
- 전투 중앙과 선택 유닛 패널에서 배경 격자·잘림 없음
- 축소 UI에서 패널·버튼·스킬 슬롯 겹침 없음

## 결과물

- `tmp/update3_phase25/koko/koko_combat_1920x1080.png`
- `tmp/update3_phase25/koko/koko_combat_1366x768.png`
