# v0.3 Web 데모 정책 동기화

## 메타데이터

- 작성일: 2026-07-13
- 작업 브랜치: `test/web-v0.3`
- 기준 브랜치 및 SHA: `origin/test/web-v0.3` / `d6a54b97c6a0c9db582647e24d0f371e34dbca72`
- 마지막 구현 커밋 SHA: `b1ca9fea9a7eaf6d9bd5725dae43a9505adaecd4`
- 병합한 main SHA: `5b48cf923b726b0fe386e0987dab9f6fe193f413`
- 원격 푸시: `02f5cbd2ce889fb435ff552158bbfcf686d634b0` 완료

## 완료한 작업

- `test/web-v0.3`에 최신 `main`을 merge commit으로 병합했다.
- Web export 커밋 `d6a54b9`의 HTML, 아이콘과 LFS PCK 내용은 변경하지 않았다.
- 정책 성공 경로의 명시적 `exit 0` 수정과 최신 CURRENT 핸드오프를 Web 브랜치에 동기화했다.

## 관련 검사

- Web 데모 허용 정책: PASS, run `29238842740`
- PCK 선언 크기·실제 크기 181,257,848바이트 일치: PASS
- `git lfs fsck`: PASS
- 전체 게임·전체 플레이: NOT_REQUESTED
- 검수 에이전트: NOT_REQUESTED

- Review task ID: NOT_REQUESTED
- Reviewed SHA: b1ca9fea9a7eaf6d9bd5725dae43a9505adaecd4
- Review range: d6a54b97c6a0c9db582647e24d0f371e34dbca72..b1ca9fea9a7eaf6d9bd5725dae43a9505adaecd4
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 다음 작업

1. 정식 출시 검증은 사용자가 요청한 경우에만 실행한다.
2. 이후 소스 변경이 생기면 안정 SHA에서 Web export를 재생성한다.
