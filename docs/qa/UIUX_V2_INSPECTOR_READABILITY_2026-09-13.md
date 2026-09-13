# UIUX V2 전투 상세 가독성 개선

- WORKSTREAM_ID: UIUX-V2-INSPECTOR-20260913
- 브랜치: codex/v126-uiux-u0-u3
- 시작 HEAD: b0ca7d9cc020d5bd0d212d680a6f1ef121d55946
- main/origin/main/원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112 (기본 네트워크 제한 후 승인된 읽기 전용 ls-remote로 확인)
- 공개 안정판1.2.6 유지. main AGENTS의 구 버전 문구와 CURRENT를 대조했다. 새 버전·공개 배포·태그·푸시 없음.
- 사용자 계속 지시에 따라 혼자 구현하고 마지막에 관련 검사. 전체 검수·서브에이전트 미실행.

## 실제 수정

변경 제품 코드: `scripts/ui/HUDController.gd` 한 파일.

- 목표 설명에 같은 지침·의도가 여러 번 이어지던 부분을 중복 제거한다. 서로 다른 방·대상 정보는 유지한다.
- 행동·목표와 동일한 기본 상태 설명은 되풀이하지 않는다. 별도 대상, 실제 약화 수치·지속시간과 집중 준비 효과는 보존한다.
- 적의 위협 문구를 처음 선택할 때만 조립하고 다음 HUD 갱신에서 잃던 결함을 수정했다. 생성·갱신 모두 같은 상태 조합 함수를 사용한다.
- 체력35% 이하에는 주황 HP와 ‘체력 위험’, 전투 불능에는 명시적 문구와 흐린 색을 적용한다. 회복 시 기존0.1초 HUD 갱신으로 복귀한다. 전투 판정·회복 수치는 바꾸지 않았다.
- 선택 상세 이름을 현재 진화체·왕관 형태에 맞춰 초상과 일치시킨다. 실제 왕관 선택/억제는 기존 능력치 선택 경로를 따른다.
- 데스크톱·터치 UI 생성 코드를 같은 표현 함수로 연결했다. 터치 플랫폼 실행 검증은 하지 않았다.
- 게임 규칙·AI·비용·해금·저장·스토리·그래픽 runtime 자산은 변경하지 않았다.

## 마지막 관련 검사

Godot4.6.3 Windows Forward+ RTX3060Ti. 증거 루트 `tmp/uiux_inspector_20260913/`.

| 검사 | 결과 | 증거 |
|---|---|---|
| headless editor import | 구문·임포트 오류 없음 | import.log |
| UIUXInspectorReadabilityTest | PASS132 assertions | direct.log |
| 기존 UIUXCombatInteractionTest | PASS210 assertions | commands.log |
| git diff --check | PASS | 실행 결과 |
| 1920×1080 /1280×720 × 글자90·100·115% | 실제 전투 UI6조합 | direct/*.png |

- 새 검사: 실제 전투 시작 후 시간만 일시정지, UI 주기 갱신은 유지. 낮은 HP→회복→전투 불능, 실제 적 생성→위협+약화→피격 사망→경고 해제, 선택창 닫기, 표현의 중복/실제 대상 유지, 글자 높이 검사.
- 적 약화 타이머·HP·의도는 표현을 재현하기 위한 통제된 값이다. 실전 DAY30 완주나 밸런스 결과가 아니다.
- 기존 입력 검사는 명령3개·직접 대상 선택·잘못된 입력의 비용 보존·ESC·시설 가동·속도·일시정지·대화 Enter 복귀를 그대로 확인했다.
- 기존 증거 보존을 위해 tools/UIUXU4InteractionTest.gd 및 UIUXCombatInteractionTest.gd를 tmp로 복사하고 출력 경로와 상속 참조만 변경했다. 테스트 조건·assertion은 원본 그대로다. runner는 tmp/uiux_inspector_20260913/CombatInteraction.tscn.
- 두 로그 모두 최종 ERROR/SCRIPT ERROR/WARNING 없음. 새 테스트도 첫 실행에 PASS.
- 대표 1280/115 아군 위험,1920/100 적 경고 화면을 열어 실제 표시를 확인했다. 나머지 해상도/배율은 테스트 캡처와 글자 높이 assertion으로 확인했다. 사람 사용성·모든 화면 시각 판정은 주장하지 않는다.

## 방향 미술 재시도

- imagegen 스킬·GPT 내부 이미지 생성 도구 사용. 고블린 단일 종,2×2 방향,1024×1024 native alpha PNG 요구를 실제 prompt에 전달했다.
- 실제 반환:1254×1254 RGB, 알파 없음, 체크무늬 픽셀. 전장 미채택. 로컬 배경 제거·외부 API 사용 안 함.
- 증거: goblin_direction_rejected.png / direction_attempt.json. 원본은 C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-c91638d3-e043-4f8b-b57a-762a49fd42bc.png.
- 상태 ASSET_BLOCKED_NATIVE_ALPHA 유지. 같은 prompt/reference 방식의 반복 생성은 중단한다. 내장 도구의 실제 native transparency 제어가 확보되는 등 조건이 바뀌면 재개한다. 모델 일반의 투명 기능 부재로 단정하지 않는다.
- 구체적 요청서: docs/design/UIUX_DIRECTIONAL_ASSET_REQUEST_2026-09-13.md에 후속 기록.

## 제출과 남은 작업

- 실제 화면 모음: tmp/uiux_inspector_20260913/index.html.
- 전후 비교의 이전 이미지는 직전 초상 작업에서 실행한1280/115 전투 상세 캡처다. 같은 시설 배치·낮은 HP 상황이나 적 위치/애니메이션은 동일 프레임 비교가 아니다.
- 새 코드·씬 테스트: tools/UIUXInspectorReadabilityTest.gd/.gd.uid/.tscn.
- 신규 런타임 그래픽 없음. 미채택 이미지와 로컬 캡처·빌드는 소스 커밋에 넣지 않는다.
- 방향/적 미술·연속 성장 밸런스·최종 전체 캠페인/사람/Web/저사양/장시간 검증은 남음. 최종 출시 HOLD.
