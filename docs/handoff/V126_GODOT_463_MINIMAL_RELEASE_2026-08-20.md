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
- Windows 정식 export·manifest·부팅: `PASS`
- main PR·tag·Release: `COMPLETE`

## Godot 4.6.3 표적 검수 결과

- 고정 검수 SHA: `ab817105bc56869cedae18a3acd7d115f3372996`
- 엔진: `4.6.3.stable.official.7d41c59c4`
- `V122CommandButtonIntegrationTest`: PASS
- `V122DefenderConnectorTest`: PASS
- `V122ManagementInteractionTest`: PASS
- `V122DualFrontStageMigrationTest`: PASS
- `DemoSmokeTest`: PASS
- `V122ReleaseReadinessTest`: PASS, 85 assertions
- `V122Day02VisualCapture`: PASS, 10개 캡처 생성
- 1920×1080·1280×720에서 보물 보관실 이름표와 `+ 건설 가능` 표시가 전면 소품에 가려지지 않음을 확인했다.
- 방 지침 배지, 문맥 시설 목록, 시설 미리보기·확정 흐름을 실제 합성 화면에서 확인했다.
- Python Steam validator: 8/8 PASS
- Python build-manifest validator: 13/13 PASS
- 테스트 뒤 검수 worktree: clean

Windows 로컬 환경의 root certificate store 경고와 일부 headless 테스트 종료 시 resource cleanup 경고가 있었지만, exit code·PASS marker·스크립트/파싱 결과 및 제품 소스에는 영향이 없었다. 이는 Windows 정식 export 패키지 부팅 결과와 별도로 판정한다.

## 최종 main·출시 증거

- main merge SHA: `1f36c8a775b471c4dbc7c7714f85f33efb00876d`
- PR: <https://github.com/bluehige/mawangseong-demo/pull/91>
- annotated tag: `v1.2.6` → `1f36c8a775b471c4dbc7c7714f85f33efb00876d`
- tag CI: <https://github.com/bluehige/mawangseong-demo/actions/runs/32353965901> — export·manifest·부팅·artifact PASS
- Release: <https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.6>
- Windows ZIP SHA-256: `1dff6f381ec188da256219f04efaaffab958fc09d002ed00f142664fd1146588`

## 정책 필드

- Review task ID: V126-GODOT-463-MINIMAL-RELEASE
- Reviewed SHA: ab817105bc56869cedae18a3acd7d115f3372996
- Review range: ce601b81b8f283543a04867e11632d0e87beea3c..ab817105bc56869cedae18a3acd7d115f3372996
- Remaining P1/P2: 0
- Final review result: PASS
