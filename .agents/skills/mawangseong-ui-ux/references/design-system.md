# 마왕성 UI 디자인 시스템

## 현재 baseline 출처

- `scripts/v20/ui/V20UITheme.gd`
- `scripts/ui/UIFont.gd`
- 실제 화면 controller와 scene

baseline은 현재 구현의 시작점이며, 사용자 승인과 실제 렌더 결과에 따라 수정할 수 있다.

## 현재 색 역할

| 역할 | 현재 baseline |
|---|---|
| void/background overlay | `#08070DCC` |
| panel | `#100E16F2` |
| strong panel | `#0D0B12F7` |
| soft panel | `#17131FE8` |
| line | `#5F536A` |
| primary gold | `#E8BB58` |
| bright gold | `#FFE4A0` |
| primary text | `#F3EADC` |
| muted text | `#BDB3C6` |
| danger | `#E56A72` |
| route/secondary emphasis | `#9E7BD1` |
| success/available | `#58C997` |

## 사용 규칙

- gold: 주 행동, 현재 선택, 최고 우선 강조에 제한
- route purple: 경로·전술 맥락·보조 선택
- danger red: 즉시 위험, 실패, 파괴적 상태에 제한
- green: 사용 가능·성공·회복. 안전과 승리를 혼용하지 않도록 문구 병행
- muted: 읽어야 하는 본문에 과도하게 사용하지 않음
- panel alpha: 배경 가독성을 만들되 전장과 마왕성 아트를 검게 덮지 않음

## 타이포 baseline

| 역할 | 크기 |
|---|---:|
| hero | 30 |
| title | 20 |
| value | 18 |
| button | 15 |
| body | 13 |
| support | 11 |

1280×720을 기준으로 반응형 scale 0.85~1.35를 사용한다. 최소값은 단순한 합격 증명이 아니다. 실제 거리, 한국어 획 복잡도, 배경 대비, 정보 중요도를 함께 본다.

## 공간 baseline

- screen margin: 20
- panel gap: 12
- button minimum height: 44
- panel radius: 8

44는 높이 기준일 뿐이다. 실제 버튼 폭, hit rect, 인접 간격, 카드·슬롯 drag target 크기도 검사한다.

## 컴포넌트 규칙

### 버튼

- primary와 secondary를 테두리 색만으로 구분하지 않는다.
- normal, hover, pressed, focus, disabled를 제공한다.
- disabled는 이유를 인접 문구·상태로 설명한다.
- 위험 행동은 gold primary와 같은 형태를 사용하지 않는다.

### 카드

- 초상, 이름, 역할, 비용/상태, drag 가능 여부의 위계를 유지한다.
- 모든 수치를 카드 전면에 펼치지 않는다.
- 선택과 drag 상태를 서로 구분한다.

### 슬롯·구역

- 빈 슬롯, 유효 대상, 비유효 대상, 점유, 교체 가능 상태를 형태와 색으로 표현한다.
- 시각 marker와 실제 world/logical slot ID가 일치해야 한다.

### 패널

- P0 정보만 상시 유지한다.
- P1은 위협·선택 때 표시하고 상황 종료 후 닫는다.
- P2/P3는 drawer, tooltip, 접기 영역으로 제공한다.
- 패널 수가 줄었다는 사실보다 플레이어 시선 경로가 명확한지를 우선한다.

## 아트 디렉션

- 어두운 판타지 + 코믹한 캐릭터 매력을 유지한다.
- 석재·금속·마력 문양은 기능 그룹을 강화하는 장식으로 사용한다.
- 장식 프레임이 너무 두꺼워 전장과 카드 면적을 빼앗지 않는다.
- 지도·캐릭터·시설 이미지는 UI보다 먼저 읽혀야 할 때 충분히 노출한다.
- 생성 자산은 저장소의 이미지 생성 출처 정책과 `SOURCE.md`를 따른다.
