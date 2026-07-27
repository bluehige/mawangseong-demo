# v1.2.2 P17 출시·플랫폼 준비

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v122-release-readiness`
- 기준 브랜치 및 SHA: `codex/v122-implementation-closure@e98fc3701d00047e5702ff0915650ee84d8ffaf7`
- 기능 커밋 SHA: `4051d9a3e45baa48038da68cdb9bb4e05e68ebcc`
- 원격 푸시: 미실행

## 2. 완료한 작업

- `project.godot` 기술 버전을 `1.2.2`로 정합화하고 기존 제품 표시 `1.2`, 메인 scene, 사용자 저장 디렉터리를 유지했다.
- Windows Desktop·Windows Steam의 file/product version을 `1.2.2.0`으로 올리고 Desktop 후보 경로를 `builds/MawangCastle_v1.2.2/MawangCastle_v1.2.2.exe`로 고정했다.
- PC Web·Mobile Web·Windows Desktop·Windows Steam 4개 preset의 플랫폼 설정과 생성 원본·문서·도구·임시 파일 제외 규칙을 감사했다.
- Windows ZIP, Web ZIP, 태그, GitHub Release의 예정 이름을 기계 판독 감사 파일에 기록했다. 실제 artifact·태그·Release는 만들지 않았다.
- `V122ReleaseReadinessTest`를 Quick·Full 스위트에 등록하고 프로젝트·export·Steam·P16 closure·사용자 체크리스트 계약을 자동 검증한다.
- 사용자가 직접 수행할 새 게임 DAY 1~30, 1.2.1 저장 호환, 대표 빌드·Update 2~4·화면·입력·저장 복구 체크리스트와 PASS/FAIL 전달 형식을 작성했다.

## 3. 테스트

| 방법 | 결과 |
|---|---|
| `V122ReleaseReadinessTest` | PASS, 84 assertions |
| `V122SaveProgressionTest` | PASS |
| `V122ImplementationClosureTest` | PASS, 665 assertions |
| Steam release validator | `SETUP_PASS`, 외부 owner gate 17개 명시 |
| Steam validator unit test | PASS, 7/7 |
| `RunCoreVerification.ps1 -Mode Quick` | PASS, 116/116 |
| JSON parse·구버전 문자열·`git diff --check` | PASS |
| Full·DAY 1~30 전체 플레이·최종 수동 검수 | NOT_RUN, 사용자 최종검수 단계로 보류 |
| Windows·Web·Steam export·hash·태그·Release | NOT_CREATED |

저장 진행 테스트가 손상 JSON의 `.tmp`·`.bak` 복구 경로를 의도적으로 실행하므로 중간에 JSON parse 오류가 출력되지만 최종 판정은 PASS다. Godot headless 실행의 Windows 루트 인증서 읽기 경고도 기존 환경 경고이며 테스트 결과에는 영향을 주지 않았다. 검증 중 Godot가 새로 만든 무관한 UID 5개와 대량 `.import` 재기록은 제거하고 P17 검사 UID만 보존했다.

## 4. 출시 경계

- 현재 상태는 **READY_FOR_OWNER_FINAL_QA**다.
- Full 전체 회귀, DAY 1~30 수동 플레이, 물리 Windows IME, 실제 브라우저·모바일 검수는 아직 완료로 판정하지 않는다.
- Windows·PC Web·Mobile Web·Steam 후보 빌드와 ZIP·PCK·SHA-256은 아직 없다.
- `v1.2.2` 태그, GitHub Release, 공개 배포는 사용자 PASS 뒤 동일 검수 SHA에서만 진행한다.
- `v1.2.1` 태그·Release와 기존 저장 경로는 변경하지 않는다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 4051d9a3e45baa48038da68cdb9bb4e05e68ebcc
- Review range: e98fc3701d00047e5702ff0915650ee84d8ffaf7..4051d9a3e45baa48038da68cdb9bb4e05e68ebcc
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 5. 다음 작업

1. 사용자가 `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md`에 따라 기능·화면·입력·저장 호환을 직접 검수한다.
2. `V122_OWNER_QA_FAIL` 피드백이 오면 동일 SHA와 재현 조건을 기준으로 수정하고 관련 회귀부터 다시 실행한다.
3. `V122_OWNER_QA_PASS` 뒤에만 Full 검증, 후보 export·실행 확인·hash 고정, 태그·Release·배포를 순서대로 진행한다.
