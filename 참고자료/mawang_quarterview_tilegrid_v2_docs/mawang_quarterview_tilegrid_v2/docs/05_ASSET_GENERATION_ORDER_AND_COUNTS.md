# 05. 이미지 생성 순서와 필요 수량 규칙

이 문서의 핵심은 "그냥 16장씩 뽑지 말고, 순서대로 생성하라"는 것이다.

## 1. 생성 순서

### Step 0. 기준 시트 정의
먼저 아래를 문서로 확정한다.

- 타일 논리 크기: 1 cell
- 화면상 쿼터뷰 바닥 타일 크기 예: 128x64 px
- 기준 스타일: 큐트 호러 판타지
- 테마: F급 동굴
- 렌더 축: 동일한 쿼터뷰 각도
- 라이트: 왼쪽 위 보랏빛 마력 조명

이 기준이 없으면 Codex와 이미지 생성 결과가 서로 안 맞는다.

---

### Step 1. Background / Void 생성
가장 먼저 만들 것:

1. `bg_void_cave_f_01.png`
2. `bg_void_cave_f_02.png`
3. `bg_void_cave_f_03.png`

용도:
- 화면 뒤에 까는 큰 배경
- 반복 타일이 아니라 넓은 배경 이미지

권장 수량:
- 등급당 2~3장

---

### Step 2. Base Floor Center 생성
다음으로 만들 것:

- 중심 바닥 패턴 4~6장

예:
- `floor_cave_f_center_01.png`
- `floor_cave_f_center_02.png`
- ...

용도:
- 마스크 15(사방연결) 또는 큰 방 내부 랜덤 배치 변형

권장 수량:
- 테마당 4~6장

---

### Step 3. 16 Mask Floor 생성
그 다음으로 반드시 만들 것:

- `floor_cave_f_mask_00 ~ 15`

이 16장이 floor silhouette의 핵심이다.

권장 수량:
- 테마당 16장
- 필요시 `mask_15`만 2~4 변형 추가 가능

---

### Step 4. Exposed Edge / Skirt 생성
floor tile만 있으면 끊기는 가장자리가 어색하다.
따라서 다음을 만든다.

- 북쪽 edge
- 동쪽 edge
- 남쪽 edge
- 서쪽 edge
- 코너 skirt 4종
- 그림자 강화 버전

권장 수량:
- 8~12장

---

### Step 5. Closed Socket / Open Socket / Doorway 생성
연결 전후 상태를 위해 반드시 필요하다.

- `socket_closed_n/e/s/w`
- `socket_open_placeholder_n/e/s/w`
- `socket_connected_doorway_n/e/s/w`

권장 수량:
- 최소 12장

---

### Step 6. Wall / Pillar / Front Wall 생성
방과 통로 외곽을 입체적으로 보이게 한다.

권장 수량:
- back wall 8~12장
- front wall 8~12장
- pillar 4~6장

---

### Step 7. Room Objects 생성
왕좌, 보물더미, 병영 침상, 회복 둥지 등.

중요: 큰 오브젝트는 가능하면
- back part
- front part
로 쪼개서 만든다.

예:
- `prop_throne_back.png`
- `prop_throne_front.png`

권장 수량:
- 방당 3~5개

---

### Step 8. Trap / Decor / Overlay 생성
- 가시 함정
- 해골 장식
- 촛불
- 마력 룬
- 균열
- 슬라임 흔적

---

## 2. F급 동굴 테마 최소 수량

| 분류 | 최소 수량 |
|---|---:|
| 배경 | 3 |
| center floor | 4 |
| 16 mask floor | 16 |
| edge/skirt | 8 |
| socket states | 12 |
| wall/front wall | 16 |
| 문/기둥 | 8 |
| 방 오브젝트 | 20 |
| 데칼/오버레이 | 12 |
| 함정 | 8 |
| 합계 | 약 107 |

이 수치는 "많아 보이지만", 방 1장씩 만드는 것보다 훨씬 재사용성이 높다.

---

## 3. 업그레이드 시 같은 수량만 써도 되나

### 답: 기본 연결 타일 세트는 같은 수량을 써도 된다.

즉, 등급이 올라가도 아래는 동일한 구조를 재사용할 수 있다.

- 16 mask floor 구조
- socket 상태 구조
- edge/skirt 구조
- wall/front wall 구조

바뀌는 것은 다음이다.

- 색감
- 재질
- 장식 정도
- 데칼 종류
- 문/기둥 디자인

즉, **구조는 재사용, 비주얼 테마만 교체**가 정답이다.

---

## 4. Codex가 이해해야 할 것

Codex는 "방 크기가 커지면 이미지 파일 수가 계속 늘어난다"고 생각하면 안 된다.
그리드가 커질수록 늘어나는 것은:

- 배치되는 셀 수
- 배치 연산량
- 카메라 범위
- 소품 배치량

이미지 파일 수는 크게 늘지 않는다.
