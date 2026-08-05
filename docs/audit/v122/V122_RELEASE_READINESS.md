# v1.2.2 출시·플랫폼 준비 감사

- 기준일: 2026-07-27
- 기계 판독본: `docs/audit/v122/V122_RELEASE_READINESS.json`
- 자동 검사: `tools/tests/V122ReleaseReadinessTest.tscn`
- 상태: `READY_FOR_OWNER_FINAL_QA`

## 버전 정합성

| 항목 | v1.2.2 기준 |
|---|---|
| 화면 표시 | `1.2` 유지 |
| `project.godot` | `1.2.2` |
| Windows file/product version | `1.2.2.0` |
| Windows Desktop 경로 | `builds/MawangCastle_v1.2.2/MawangCastle_v1.2.2.exe` |
| Windows ZIP 예정명 | `MawangCastle-v1.2.2-Windows.zip` |
| Web ZIP 예정명 | `mawangseong-v1.2.2-web.zip` |
| 예정 태그 | `v1.2.2` |
| 예정 Release | `마왕성 v1.2.2` |

기존 저장 경로 `Godot/app_userdata/마왕님, 마왕성 지켜주세요! Demo`는 1.2.1 저장 호환을 위해 변경하지 않았다.

## 플랫폼 preset

| 플랫폼 | 설정 | 판정 |
|---|---|---|
| Windows Desktop | x86_64, 외부 PCK, 제품 아이콘, 1.2.2.0 리소스 | CONFIGURED |
| PC Web | `web_Demo/index.html`, source·docs·tools·tmp 제외 | CONFIGURED |
| Mobile Web | landscape, `mobile_web`, 임시 검수 경로 | CONFIGURED |
| Windows Steam | x86_64, source·docs·legal·marketing·tools 제외, 1.2.2.0 | CONFIGURED |

모든 preset이 생성 원본·문서·도구·임시 산출물을 런타임 패키지에서 제외한다. Windows 코드 서명은 인증서가 없는 상태를 숨기지 않기 위해 `false`로 유지하고 사용자 외부 gate로 기록했다.

## 실행 경계

이번 단계는 소스 RC 준비까지다. 다음 작업은 실행하지 않았다.

- Full 전체 회귀와 DAY 1~30 수동 플레이
- Windows·PC Web·Mobile Web·Steam export
- ZIP·PCK·실행 파일 생성과 SHA-256 고정
- 태그·GitHub Release·공개 URL 갱신

따라서 이 문서는 출시 승인이 아니라 **사용자 최종검수 시작 전 소스 준비 완료**를 뜻한다. 사용자 체크리스트는 `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md`다.

## 보존·외부 gate

- `v1.2.1` 태그와 Release는 이동·교체하지 않는다.
- release/v2 참고선은 병합하지 않는다.
- 기존 저장 디렉터리를 유지한다.
- Windows 코드 서명, 물리 한국어 IME 조합, Steamworks 가입·ID·심사는 사용자 외부 작업으로 남는다.

## P17 판정

- 프로젝트·export 버전 불일치: 0
- 플랫폼 preset 누락: 0
- 기존 저장 경로 변경: 0
- P16 금지 구현 상태: 0
- export·배포 오실행: 0
- 소스 RC 상태: **READY_FOR_OWNER_FINAL_QA**
