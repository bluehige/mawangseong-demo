# v1.2.2 릴리스 브랜치 문서 마감 검수 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-release-closeout`
- 기준 브랜치 및 SHA: `release/v1.2.2` / `8cc14fabe0ab4a199ac4d8d33dc6918b6827056c`
- 검수 대상 SHA: `7c9d135d0fd1d5e1bb2ba5fc5ba158e57e646b60`
- 원격 푸시 여부: 이 문서 작성 시점에는 미푸시.
- 관련 PR: 최종 `release/v1.2.2 → main` PR `#82`.

## 2. 목표와 범위

- 목표: 정식 출시 전에 공개 안정판 표기와 릴리스 노트를 릴리스 브랜치에 반영한다.
- 변경 범위: `AGENTS.md`, `README.md`, `docs/release/V1_2_2_RELEASE_NOTES_2026-08-06.md`.
- 제외 범위: 제품 코드·데이터·자산·씬·빌드 프리셋·CI 구현.

## 3. 완료 내용

- 현재 공개 안정판을 `1.2.2`, 다음 정식 확장판을 `2.0.0`으로 갱신했다.
- README의 후보 표기를 정식 공개판·이동하지 않는 태그·GitHub Release 보관 규칙으로 갱신했다.
- 핵심 변경, 던전·UI, 그래픽·오디오, 호환성·배포와 출시 검증 게이트를 정식 릴리스 노트에 기록했다.
- 독립 검수에서 세 문서의 수치와 설명이 실제 구현·기존 검수 근거·저장소 출시 규칙과 일치함을 확인했다.

## 4. 테스트 및 검수

| 검수 | 결과 |
|---|---|
| `git diff --check` | PASS |
| 공개판·SemVer·태그 표기 대조 | PASS |
| 벽 투명도·깊이·방 지침·이미지 출처 수치 대조 | PASS |
| 독립 하위 범위 검수 | P1/P2/P3 0, PASS |

### 정책 CI용 최종 승인 필드

- Review task ID: 605bd0fe-c9e8-466c-aef5-029971fecf2e
- Reviewed SHA: 7c9d135d0fd1d5e1bb2ba5fc5ba158e57e646b60
- Review range: 8cc14fabe0ab4a199ac4d8d33dc6918b6827056c..7c9d135d0fd1d5e1bb2ba5fc5ba158e57e646b60
- Remaining P1/P2: 0
- Final review result: PASS

## 5. 미해결과 다음 작업

- 이 범위의 미해결 P1/P2/P3: 0건.
- 이 핸드오프를 포함한 PR을 `release/v1.2.2`에 merge commit으로 병합한다.
- 이후 PR `#82`의 `main` 기준 통합 핸드오프를 사용해 정책 체크와 최종 병합을 완료한다.
- 최종 `main` SHA에서 Full 156개와 Web/Windows 정식 산출물 검증을 실행한 뒤 태그·Release를 게시한다.

## 6. 작업 트리와 종료 체크

- 검수 대상 `7c9d135`는 깨끗했다.
- 검수 뒤에는 `docs/handoff/` 문서만 변경했다.
- 의도하지 않은 기존 변경과 스태시는 없다.
- [x] 직접 관련 문서 검수 완료
- [x] 독립 검수 P1/P2/P3 0건
- [x] 검수 SHA·범위·작업 ID 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 원격 푸시와 릴리스 브랜치 PR 병합
