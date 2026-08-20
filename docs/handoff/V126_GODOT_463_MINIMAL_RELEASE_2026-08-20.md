# v1.2.6 Godot 4.6.3 최소 검수 정식 출시 핸드오프

## 사용자 최신 지시

- Intent ID: `INT-20260820-020`
- Evidence level: `E1_DIRECT_USER`
- 상태: `USER_CONFIRMED`
- 정식 엔진을 Godot `4.6.3`으로 사용한다.
- 4.5.2 고정 규칙보다 최신 사용자 지시를 우선한다.
- Full·8인 역할 검수는 실행하지 않고 핵심 표적 검수로 최소화한다.
- 현재 1.2.6 수정본을 `main`, `v1.2.6` 태그와 GitHub Release에 정식 등록한다.

이번 출시에 한해 기존 4.5.2 고정 및 Full·8인 선행 게이트는 `SUPERSEDED`다. 기존 기록은 역사 근거로 보존하며 삭제하지 않는다.

## 변경 범위

- `project.godot` feature level: Godot 4.6
- Windows 태그 빌드 workflow: Godot 4.6.3
- Steam build 계약·validator: Godot 4.6.3
- build manifest 예시·단위 테스트: Godot 4.6.3
- README·CURRENT·릴리스 노트: Godot 4.6.3 정식 기준
- 제품 전투·스토리·밸런스·저장 형식 추가 변경 없음

## 최소 검수 범위

1. `V122CommandButtonIntegrationTest`
2. `V122DefenderConnectorTest`
3. `V122ManagementInteractionTest`
4. `V122DualFrontStageMigrationTest`
5. `DemoSmokeTest`
6. `V122Day02VisualCapture` 및 1920×1080·1280×720 확인
7. `V122ReleaseReadinessTest`
8. Python release validator 단위 테스트와 repository policy

## 출시 경계

- Full verification: `NOT_RUN` — 사용자 지시
- DAY 1~30 8인 독립 완주: `NOT_RUN` — 사용자 지시
- Web·모바일 정식 품질 판정: `NOT_RUN`
- Windows 정식 export·manifest·부팅: `PENDING`
- main PR·tag·Release: `PENDING`

## 정책 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `PENDING`
- Review range: `PENDING`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PENDING`
