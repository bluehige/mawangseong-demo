# v2.0.1 STOVE 자체등급 심의자료 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v2.0.1 STOVE 최초 출시
- 작업 브랜치: `codex/v201-stove-release`
- 기준 브랜치 및 SHA: `origin/main` merge base / `7131110245bc9ea45e4603fe32fdf38e5c2363d9`
- 마지막 기능 커밋 SHA: `7429c67fb82cd5c100aa4ff0ee52cb1551001cd2`
- 원격 푸시 여부: 미실행
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: STOVE 자체등급분류에 필요한 게임 영상, CG 이미지, 대사 파일을
  준비하고 잘못 만든 Windows 아이콘을 교체한 뒤, STOVE에는 올리지 않고 현재
  Google Drive 계정에 업로드한다.
- 완료 조건: 초·중·후반 각 6분 이상, 전체 엔딩, 전체 대사와 CG 패키지, 설명서,
  아이콘이 있고 Drive 업로드 결과를 Chrome에서 확인한다.
- 범위에서 제외한 사항: STOVE 자료 업로드·심사요청·등급 설문 제출, v2.0.1
  Windows 빌드 생성·포털 교체, 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 구현: 실제 `GameRoot` 화면을 이용하는 심의 전용 Movie Writer 장면과 제출
  패키지 빌더를 추가했다. 판매 빌드 저장은 비활성화되고 캡처 도구는 export되지 않는다.
- 영상: 초반 6:29, 중반 6:19, 후반 6:25, 엔딩 4:08의 1920×1080 H.264/AAC
  MP4를 생성했다. E00~E22 23개 엔딩은 요청 ID와 실제 렌더 데이터 ID를 매 화면
  대조하고 CG 경로를 로그에 남겼다.
- CG·대사: 캐릭터 35종, 몬스터 14종, 적/보스 33종 접촉표와 엔딩 23장,
  런타임 이미지 1,065개 목록을 만들었다. 전체 문자열 5,411개는 201쪽 PDF와
  TSV로, 설명서는 2쪽 PDF로 만들었다.
- 그래픽: 보라색 슬라임 마왕과 금색 성 왕관을 사용한 새 전용 Windows 아이콘을
  GPT 내부 이미지 생성으로 만들고 1024 PNG, 256 PNG, 7단계 ICO로 변환했다.
- 외부 보관: 단일 ZIP 146,437,352바이트가 Drive 업로드 100MB 제한을 넘어서
  아래 두 ZIP으로 나눠 My Drive 루트에 업로드했다. Chrome 검색 결과에서 두 파일을
  모두 확인했다.
  - [PART1 VIDEOS](https://drive.google.com/file/d/10HV8A-zUVC5Xkg7qWWfC3oJvHvXHKUMx/view?usp=drivesdk) — 67,585,284바이트
  - [PART2 CG TEXT ICON](https://drive.google.com/file/d/1As9HphlswdjqvtteJ0bP7tOymIy6uYIt/view?usp=drivesdk) — 78,854,208바이트
- STOVE: 사용자 지시대로 포털 업로드·심사요청은 수행하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/release/RatingVideoCapture.gd` | 초·중·후반·23개 엔딩 심의 영상 자동 캡처 | 완료 |
| `tools/release/RatingVideoCapture.tscn` | 캡처 실행 장면 | 완료 |
| `tools/release/build_stove_rating_package.py` | CG 접촉표·PDF·목록·패키지 생성 | 완료 |
| `stove/ratings/GAME_MANUAL.md` | v2.0.1 설명서와 엔딩 접근법 | 완료 |
| `stove/ratings/language_text.tsv` | 현재 소스 전체 문자열 5,411개 | 완료 |
| `stove/ratings/VIDEO_CAPTURE_PLAN.md` | 실제 영상 파일·길이·검증 상태 | 완료 |
| `stove/ratings/RATING_SUBMISSION_DRAFT.md` | 첨부자료 완료 상태와 빌드 교체 경고 | 완료 |
| `assets/source/imagegen/stove_windows_icon/` | 새 아이콘 생성 원본과 출처 | 완료 |
| `marketing/stove/icons/` | 새 PNG·ICO 업로드 자산 | 완료 |
| `marketing/stove/ARTWORK_PROVENANCE.md` | 신규 이미지 생성 출처 연결 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용
- 생성 모델: GPT internal image generation
- 생성 원본 경로: `assets/source/imagegen/stove_windows_icon/stove_windows_icon_source_2026-07-15.png`
- `SOURCE.md` 경로: `assets/source/imagegen/stove_windows_icon/SOURCE.md`
- 런타임 최종 자산 경로: `marketing/stove/icons/windows_desktop.png`,
  `marketing/stove/icons/windows_desktop_256.png`, `marketing/stove/icons/windows_desktop.ico`
- 프롬프트/후처리/크롭/알파 처리 요약: 승인된 STOVE 썸네일과 게임 엔딩
  일러스트를 분위기 참고로 사용해 글자 없는 정사각 아이콘을 생성하고 Lanczos
  리사이즈와 16~256px ICO 패킹을 적용했다.
- 게임 연결 및 실제 렌더 확인 결과: 마케팅/실행설정 업로드 자산이며 게임 장면
  연결은 변경하지 않았다. 1024·256 PNG와 ICO 7개 크기를 직접 확인했다.
- 오디오: 심의 MP4 네 편에 AAC 48kHz 스테레오 트랙이 포함됐다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `python tools/release/build_stove_rating_package.py` | PASS, 문자열 5,411·이미지 1,065·엔딩 23 | Desktop `STOVE_UPLOAD` 패키지 |
| 2 | Godot Movie Writer 초·중·후반 캡처 | PASS, 6:29·6:19·6:25 | 패키지 `VIDEOS/01~03` |
| 3 | Godot Movie Writer 전체 엔딩 캡처 | PASS, E00~E22 23/23 | 패키지 `VIDEOS/04` |
| 4 | ffmpeg 코덱·길이·오디오 검사와 대표 프레임 확인 | PASS, 1080p H.264/AAC | 로컬 임시 검수 프레임 |
| 5 | Poppler PDF 렌더와 텍스트 샘플 추출 | PASS, 설명서 2쪽·전체 텍스트 201쪽 | 패키지 `DOCUMENTS/` |
| 6 | Pillow ICO 레이어 검사 | PASS, 16·24·32·48·64·128·256 | `marketing/stove/icons/windows_desktop.ico` |
| 7 | `python -m py_compile`·`git diff --check`·패키지 누락 단언 | PASS | 관련 스크립트와 작업 트리 |
| 8 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 직접 영향 범위만 검수 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. Reviewed SHA 이후에는 이 핸드오프와
  `CURRENT.md`만 변경했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 7429c67fb82cd5c100aa4ff0ee52cb1551001cd2
- Review range: 7131110245bc9ea45e4603fe32fdf38e5c2363d9..7429c67fb82cd5c100aa4ff0ee52cb1551001cd2
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- STOVE 자체등급 페이지의 선택 빌드는 아직 `47924 (v.0.2.1)`이다. 심사요청 전에
  반드시 최초 출시본 v2.0.1 빌드로 교체하고 영상과 동일성을 확인해야 한다.
- Drive 파일은 업로드만 했고 공유 권한은 바꾸지 않았다. STOVE에 링크를 제출할
  경우 심사자가 열 수 있는 권한으로 사용자가 설정해야 한다.
- E05~E11 일부 엔딩은 실제 게임 데이터에서 기존 CG를 공유한다. 영상은 화면의
  제목·대사·엔딩 ID를 각각 별도로 보여 주며 데이터와 일치한다.
- 단일 통합 ZIP은 로컬에 있고 Drive에는 업로드 제한 때문에 두 묶음으로 나뉘어 있다.

## 8. 다음 작업 순서

1. 사용자가 Google Drive 두 파일의 공유 권한을 필요한 범위로 설정한다.
2. STOVE에 v2.0.1 Windows 빌드를 업로드하고 실행설정을 검증한 뒤 자체등급 페이지의
   v0.2.1 선택값을 v2.0.1로 바꾼다.
3. 사용자가 자료·설문 답변을 최종 확인한 뒤에만 자체등급과 빌드 심사를 요청한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 핸드오프 문서 외에는 기존 미추적 UID 5개만 남음
- 미커밋 파일: 이 핸드오프와 `docs/handoff/CURRENT.md`
- 의도하지 않은 기존 변경: `tools/tests/*.gd.uid` 2개,
  `tools/update3_baseline/*.gd.uid` 3개는 사용자 작업으로 간주해 제외
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물 위치:
  `C:\Users\LDK-6248\Desktop\STOVE_UPLOAD\STOVE_SUBMISSION_v2.0.1`

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 기능 파일만 커밋
- [ ] 원격 푸시 및 PR 미실행
