# Web 튜토리얼 포커스 Pages 재배포

## 1. 메타데이터

- 작성일: 2026-07-13
- 목표 버전: v0.3 Web 데모
- 작업 브랜치: `codex/v03-tutorial-target-fix`
- 기준 브랜치 및 SHA: `origin/main` / `4606ad92b3e087a0e562e3012d590b2bffd839d1`
- 마지막 구현 커밋 SHA: `3858c967a9b00f4ad1aa4c68125d876c77c74655`
- 원격 푸시 여부: GitHub 앱 브랜치 커밋 완료
- 관련 배포: `update3-web-20260713` Release 및 GitHub Pages

## 2. 이번 세션 목표

- 요청 사항: 수정된 튜토리얼 포커스가 공개 Web 주소에 실제 반영되도록 재커밋·재배포한다.
- 완료 조건: 배포 워크플로가 수정 ZIP의 SHA-256을 검증하고 Pages 공개 주소에서 새 PCK와 빌드 식별 파일을 제공한다.
- 범위에서 제외한 사항: 전체 게임 회귀 및 전체 플레이 검수.

## 3. 완료한 작업

- 공개 Pages가 206,275,120바이트의 이전 PCK를 제공하던 상태를 확인했다.
- `test/web-v0.3`의 수정 PCK로 새 ZIP을 생성했다.
- 새 ZIP 크기: 189,470,689바이트.
- 새 ZIP SHA-256: `d65740eace5234b9f46f4df4984b776724b4a612f634dd18d6607dcfa35702f6`.
- `.github/workflows/deploy-web-demo.yml`의 legacy Release 체크섬을 새 ZIP과 일치시켰다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `.github/workflows/deploy-web-demo.yml` | 수정 Web ZIP 무결성 검증 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |
| `docs/handoff/WEB_DEMO_TUTORIAL_DEPLOY_2026-07-13.md` | 배포 변경과 검증 근거 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 게임 연결 및 실제 렌더 확인 결과: 수정 PCK의 로컬 브라우저 부팅과 튜토리얼 대상 링 배치를 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | ZIP 엔트리 및 SHA-256 확인 | PASS | 로컬 명령 로그 |
| 2 | PCK SHA-256 및 크기 확인 | PASS | `web_Demo/build-version.txt` |
| 3 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 3858c967a9b00f4ad1aa4c68125d876c77c74655
- Review range: 4606ad92b3e087a0e562e3012d590b2bffd839d1..3858c967a9b00f4ad1aa4c68125d876c77c74655
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- Pages 재배포 직후 CDN 또는 브라우저 캐시가 최대 약 10분간 남을 수 있다.

## 8. 다음 작업 순서

1. PR을 merge commit으로 `main`에 병합한다.
2. Release ZIP을 교체하고 Pages 워크플로를 실행한다.
3. 공개 주소의 PCK 크기와 `build-version.txt`를 확인한다.

## 9. 작업 트리 상태

- 미커밋 파일: 이 핸드오프 문서와 `CURRENT.md`만 남긴 뒤 문서 커밋 예정
- 의도하지 않은 기존 변경: 없음
- 빌드 산출물 위치: `C:/Users/LDK-6248/AppData/Local/Temp/mawangseong-update3-web-20260713-fixed.zip`

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 검수 대상 최종 SHA 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 원격 푸시, PR 병합 및 Pages 재배포
