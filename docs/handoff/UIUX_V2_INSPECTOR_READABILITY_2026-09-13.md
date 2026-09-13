# UIUX V2 전투 상세 가독성 핸드오프

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 공개1.2.6 기반 UIUX 개선, 새 버전 미확정
- WORKSTREAM_ID: UIUX-V2-INSPECTOR-20260913
- 브랜치: codex/v126-uiux-u0-u3
- 기준 main/origin/main/읽기 전용 확인한 원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD: b0ca7d9cc020d5bd0d212d680a6f1ef121d55946
- 마지막 구현·QA SHA: 66feb2abda3d5c44e697e8ce8ba44a97e4ddc888
- 이후 변경: 이 핸드오프와 CURRENT 문서만
- 원격 푸시: 없음. 새 PR·태그·Release·공개 배포 없음.
- 버전 충돌: main AGENTS 구 문구보다 main CURRENT 공개판1.2.6 및 최신 사용자 지시 적용.

## 2. 목표와 완료 조건

사용자 ‘진행해’에 따라 남은 완성도 작업을 이어갔다. 서브에이전트 없이 혼자 구현 후 마지막 관련 검증을 수행했다. 단일 고블린 방향 자산은 native alpha 실패로 미채택하고, 진행 가능한 전투 상세의 반복 문구·위험 표시·실제 경고 소실을 수정했다.

## 3. 완료한 작업

- 목표의 반복 지침·의도 제거, 서로 다른 실제 방/대상 정보 유지.
- 행동·목표를 그대로 반복하던 기본 상태문구 정리. 실제 약화 수치·지속시간·집중 준비 효과 보존.
- 적 경고가 처음 선택 후 주기 갱신에서 사라지던 결함 수정. 생성·갱신에 공통 상태 조합 사용.
- HP35% 이하에 주황색과 ‘체력 위험’, 전투 불능 문구와 흐린 색. 회복하면 경고 해제.
- 실제 활성 진화체/왕관 이름을 전투 초상과 일치.
- 밸런스·게임 규칙·AI·비용·해금·저장·스토리 변경 없음.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| scripts/ui/HUDController.gd | 실제 전투 상세 생성·갱신 | 완료 |
| tools/UIUXInspectorReadabilityTest.gd/.gd.uid/.tscn | 실제 UI 직접 검사 | 완료 |
| docs/design/UIUX_DIRECTIONAL_ASSET_REQUEST_2026-09-13.md | 단일 방향 생성 실패 기록 | 기록 완료·미술 차단 |
| docs/qa/UIUX_V2_INSPECTOR_READABILITY_2026-09-13.md | 증거·범위·실행 방법 | 완료 |

## 5. 그래픽·오디오

- imagegen 스킬 / GPT internal image generation 사용. 신규 채택 자산 없음.
- 고블린2×2 방향,1024×1024 native alpha PNG 요청. 실제1254×1254 RGB, 알파 없음/체크무늬로 미채택.
- 원본: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-c91638d3-e043-4f8b-b57a-762a49fd42bc.png
- 로컬 증거: tmp/uiux_inspector_20260913/goblin_direction_rejected.png, direction_attempt.json.
- 런타임/SOURCE 신규 연결 없음. 로컬 배경 제거·외부 API 사용 없음. 기존 검은 벽/앞벽 반투명/돌바닥/전장 캐릭터 보존.
- 오디오 변경 없음.

## 6. 마지막 관련 검사

| 검사 | 결과 | 증거 (tmp/uiux_inspector_20260913/) |
|---|---|---|
| Godot4.6.3 headless editor import | 오류 없음 | import.log |
| UIUXInspectorReadabilityTest | PASS132 | direct.log |
| 기존 UIUXCombatInteractionTest | PASS210 | commands.log |
| Windows1920×1080/1280×720 × 글자90/100/115% | 실제 UI6조합 | direct/*.png |
| git diff --cached --check | PASS | 실행 결과 |
| 전체 회귀/전체 플레이/검수 에이전트 | NOT_REQUESTED | 실행 안 함 |

- 두 검사 최종 ERROR/SCRIPT ERROR/WARNING0건. 생성/갱신 경고 유지, 약화 정보 보존, 회복/사망 상태와 닫기, 기존 명령3개·비용·ESC·시설가동·속도·일시정지·대화 Enter복귀 확인.
- 전투 입력 검사는 이전 캡처 보존을 위해 tmp복사본의 출력경로·상속경로만 변경, assertion은 원본 그대로. runner: tmp/uiux_inspector_20260913/CombatInteraction.tscn.
- 대표1280/115 아군 위험 및1920/100 적 경고 캡처를 직접 열어 확인. 나머지6조합은 캡처·글자 높이 assertion. 터치 생성 경로도 같은함수를 쓰지만 터치 플랫폼은 실행하지 않음.
- HP·약화 타이머를 주입한 통제된 UI 검사로서 실전 DAY30 완주·밸런스 근거가 아님. 전후 비교 이전 이미지는 직전 표정 작업의 실제1280/115 캡처이며 동일 애니메이션 프레임은 아님.
- 검증 이후 기능·데이터·자산 변경 없음.

### 정책 CI 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 66feb2abda3d5c44e697e8ce8ba44a97e4ddc888
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..66feb2abda3d5c44e697e8ce8ba44a97e4ddc888
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결·제약

- ASSET_BLOCKED_NATIVE_ALPHA 유지. 같은 prompt/reference 방식의 반복 생성은 중단. 실제 native transparency 출력 제어 등 조건이 바뀌면 재개. GPT 모델 일반의 투명 기능 부재로 단정하지 않음.
- 방향/적 미술, 초중후반 성장 전력 비교와 밸런스, 전체 캠페인/사람/Web/저사양/장시간 검증은 남음. 최종 출시 HOLD.

## 8. 다음 작업

1. 실패한 방향 생성 재시도를 반복하지 말고 초·중·후반 성장 구간 전력과 배치 안내의 남은 개선을 진행. 기존 비용·해금·보상 값을 근거 없이 바꾸지 않는다.
2. 자산 생성 조건이 해결되면 요청서 계약으로 방향 미술 진행. 원본 native alpha·현재정체성·발 기준·좌우 방향 확인 후 채택.
3. 사용자가 정한 범위의 마지막 관련 검증. 전체DAY1~30·8인검수·공개태그·배포를 자동 시작하지 않음.

## 9. 작업 트리

- 구현 커밋 뒤 변경은 이 핸드오프와 CURRENT뿐. 의도하지 않은 기존 변경 없음.
- tmp 증거·생성 실패파일·검사 runner는 커밋 제외. 빌드/캡처를 소스 브랜치에 넣지 않음.
- 원격 미푸시. 과거브랜치/태그/main 변경 없음.

## 10. 종료 체크

- [x] 실제 제품 UI 수정·관련132+210 검사
- [x] 실패한 방향 미술을 미채택으로 명시
- [x] 새 그래픽 생성 방식/프롬프트/결과 기록
- [x] Reviewed SHA·CURRENT 갱신
- [ ] 남은 방향미술·성장 전력 비교·최종 출시
