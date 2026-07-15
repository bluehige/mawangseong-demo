# v0.5 모바일 전용 PCK 최적화 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5 모바일 Web 공개 플레이테스트
- 작업 브랜치: `codex/v05-mobile-pck-optimization`
- 기준 브랜치 및 SHA: `main` / `2282257783ffb4218c126078c35e295bd851526b`
- 마지막 기능 커밋 SHA: `35abd218a5de01209b4eb4c88bfa7c297c8462d4`
- 원격 푸시 여부: 문서 작성 시점 미푸시
- 관련 PR 또는 태그: 소스 PR 미생성 / 신규 태그 없음

## 2. 이번 세션 목표

- 요청 사항: 폰트를 제거하지 않고 모바일판 용량을 합리적으로 줄이며 일반 Web판과 다른 모바일 전용 PCK를 만든다.
- 완료 조건: 원본 프로젝트의 폰트·전투 스프라이트·Web PCK를 바꾸지 않고 격리된 모바일 export가 더 작은 PCK를 재현하며 모바일 터치 흐름이 유지된다.
- 범위에서 제외한 사항: Noto 폰트 제거, 전투 스프라이트 손실 압축, BGM 재인코딩, 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 구현: `Web Mobile` export 프리셋과 격리 빌드 도구를 추가했다. 도구는 프로젝트를 `tmp/mobile_web_stage`로 복제하고 모바일용 대형 일러스트 134개의 임포트만 품질 0.90 손실 압축으로 바꾼 뒤 별도 PCK를 export한다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음.
- UI/UX: 초상화, 엔딩, 지역 카드, 온보딩 배경과 일반 배경만 모바일 빌드에서 압축한다. 폰트, 적·몬스터 전투 스프라이트, UI 조작 자산은 원본 설정을 유지한다.
- 저장 및 호환성: 저장 형식과 런타임 경로 변경 없음. 일반 `Web` 프리셋과 Windows 프리셋은 기존 자산을 그대로 사용한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `export_presets.cfg` | `mobile_web` 기능 태그를 가진 `Web Mobile` 프리셋 추가 | 완료 |
| `tools/mobile_web_export.py` | 격리 복제·134개 일러스트 임포트 오버라이드·모바일 Web export·해시 출력 | 완료 |
| `tools/ci/test_mobile_web_export.py` | 최적화 범위, 폰트·전투 스프라이트 제외, 안전한 임시 경로 삭제 계약 검증 | 완료 |
| `docs/handoff/CURRENT.md` | 현재 검수 SHA와 다음 배포 단계 갱신 | 완료 |
| `docs/handoff/V05_MOBILE_PCK_OPTIMIZATION_2026-07-15.md` | 세션 핸드오프 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 기존 `assets/sprites/portraits/`, `assets/ui/endings/`, `assets/ui/regions/`, `assets/ui/onboarding/`, `assets/backgrounds/`
- 프롬프트/후처리/크롭/알파 처리 요약: 원본 파일은 수정하지 않는다. 격리 모바일 export에서만 Godot 임포트 `compress/mode=1`, `compress/lossy_quality=0.9`를 적용한다.
- 게임 연결 및 실제 렌더 확인 결과: 844×390 브라우저에서 타이틀 배경과 첫 이름 등록 초상화가 정상 렌더됐고 눈에 띄는 블록·알파 깨짐은 없었다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `python -m unittest tools.ci.test_mobile_web_export -v` | PASS, 3 tests | `tools/ci/test_mobile_web_export.py` |
| 2 | `python tools/mobile_web_export.py --godot <Godot 4.5.2>` | PASS | 134개 최적화, PCK 149,196,724 bytes, SHA-256 `c694c662c6c27ce187773d706fcabe3517de2824a0f38ee8053a4220fa72a575` |
| 3 | `Godot --headless --path . res://tools/MobileTouchUISmokeTest.tscn -- --mobile-touch-ui` | PASS, 23 assertions | 모바일 터치·튜토리얼·폰트 계약 |
| 4 | `Godot --headless --main-pack tmp/mobile_web_export/index.pck --quit-after 5 -- --mobile-touch-ui` | PASS | 모바일 전용 PCK 부팅 |
| 5 | PCK 디렉터리 감사 | PASS | Noto 폰트, 관리·일반전·보스전 BGM, `fireball.wav` 포함 |
| 6 | 844×390 실제 브라우저 확인 | PASS | 타이틀과 첫 초상화 렌더 |
| 7 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 직접 영향 범위만 검수 |

- 기존 모바일 PCK 231,477,848바이트 대비 82,281,124바이트, 약 35.5% 감소했다.
- 일반 Web 공개 저장소의 PCK는 이 작업에서 변경하지 않는다.

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `35abd218a5de01209b4eb4c88bfa7c297c8462d4` 이후에는 `docs/handoff/` 문서만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 35abd218a5de01209b4eb4c88bfa7c297c8462d4
- Review range: 2282257783ffb4218c126078c35e295bd851526b..35abd218a5de01209b4eb4c88bfa7c297c8462d4
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 손실 압축은 모바일 일러스트에만 적용되지만 후반 엔딩 26종 전체를 화면별로 열어보는 전체 시각 검수는 요청되지 않아 실행하지 않았다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 없음. 빌드 스테이징과 결과물은 `tmp/`에만 존재한다.
- 외부 환경/도구 제약: 공개 모바일 저장소의 Pages 검증 PCK 크기는 새 모바일 전용 PCK 배포 시 함께 갱신해야 한다.

## 8. 다음 작업 순서

1. 이 소스 PR을 merge commit으로 `main`에 병합한다.
2. `tmp/mobile_web_export/index.pck`를 모바일 공개 저장소에만 반영하고 HTML 선언 크기와 Pages 검증값을 149,196,724바이트로 갱신한다.
3. 모바일 Pages 배포 성공과 공개 URL 응답을 확인한 뒤 이 핸드오프의 원격·PR·배포 상태를 문서 전용 커밋으로 갱신한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 기능 커밋 후 핸드오프 문서 변경만 존재
- 미커밋 파일: 이 핸드오프와 `docs/handoff/CURRENT.md`
- 의도하지 않은 기존 변경: 없음
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물 위치: `tmp/mobile_web_export/`, Git 미추적

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처 대상 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 기능 파일만 커밋
- [ ] 원격 푸시·소스 PR 병합 및 모바일 Pages 재배포
