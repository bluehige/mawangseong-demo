# v1.2.8 Steam 상점 시각 구성 마무리

## 1. 메타데이터
- 작성일: 2026-09-21
- 목표 버전: 1.2.8, 불변 태그 v1.2.8 유지
- 작업 브랜치: codex/v128-steam-store-polish
- 기준 main SHA: 590491e4e14fbb4dd9d64c12e6db88da879645f3
- 마지막 게시 원문 커밋: 6fe9a3b24673ca36f8dee011c6eaffbb239d261e
- 제품 SHA: 4d49c1a1c4f283c365513b207de36581dc73cb30
- 원격 반영: 아래 문서와 함께 별도 PR로 반영한다. 제품 태그·실행 파일 변경 없음.

## 2. 목표와 완료한 작업
사용자 요청: 남은 Steam 작업을 마무리하고 사람들이 게임의 매력을 이해할 수 있도록 상점을 꾸민다.

- Steam App5267750의 default가 Build25423797(1.2.8)임을 Builds 화면과 Set live 이력에서 확인. 이전 확인창 장애 해결.
- 기존 GPT 생성 원본으로 만든 대표 이미지4종×2언어, 라이브러리 캡슐·헤더·로고3종×2언어를 업로드·저장했다. 글자 없는 기존 hero는 공용으로 유지.
- 드롭 전용 업로드의 OS 파일 전달은 사용자가 수행했다. 에이전트가 종류·언어 분류, 규격 확인, 연령 노출 분류와 저장을 완료했다.
- 기존 촬영 도구를 tmp에 복사해 현재1.2.8의 한/영1920×1080 게임 화면을 각각7장 촬영했다. 사용자 저장과 분리한 APPDATA, 저장 비활성화, 원본 런타임 사용.
- 최종 공유 갤러리6장: 영어 전투 → 한국어 확장 성 → 영어 건설 검토 → 한국어 동료 성장 → 영어 시설 카드 → 한국어 관리. 언어별 동일 장면 중복과 구버전6장은 목록에서 정리했다. 원본 파일은 보존했다.
- 소개 본문은 기존6개 제목과 기능 설명을 유지하고 전투·건설·동료 성장 이미지3개를 배치했다. 각 이미지 그룹에 한/영 원본과 화면 읽기용 대체 텍스트를 연결했다. 소개 이미지들은 언어별 자동 전환, 상단 갤러리는 한영 공유6장이라는 차이를 명시한다.
- 영어 Interface·Subtitles, 한국어 지원, 게임 내 한국어/English 선택 안내 유지. Full Audio·가격·예정일·게임 규칙 변경 없음.
- 생성 AI 고지 유지. 새 이미지 생성, 과장된 기능·수상·평가 문구 추가 없음.

## 3. 변경 파일과 산출물
- steam/store/store_copy_bilingual.json, STORE_PAGE_COPY.md: 서버와 같은 이미지 참조3개/언어.
- marketing/steam/english/README.md: 업로드 완료와 갤러리·소개 언어 구분 기록.
- docs/handoff/CURRENT.md, 이 문서: 현재 상태와 실제 남은 출시 요건.
- 촬영 원본/로그: tmp/steam_store_v128/{screens_ko,screens_en,capture_ko.log,capture_en.log}.
- 소개 업로드6개: tmp/steam_store_v128/description/.
- 대표/갤러리/라이브러리 업로드 복사본: tmp/steam_store_v128/upload/.
- Steam 기본 빌드 증거 갱신: tmp/steam_english_release/steam_server_verification.json.
- 기존 자산 출처: assets/source/imagegen/steam_english_title_v127/SOURCE.md. 이번 촬영은 생성 그림이나 합성 화면이 아니다.

## 4. 검증
- 두 촬영 프로세스 exit0, 한/영 각각7개 capture PASS. 실제 전투9초/15초 진행 화면 포함.
- 로컬 파일 SHA1과 Steam 갤러리 자산 식별자 대조. 최종6개 순서의 서버 저장 후 재조회 확인.
- 최종 갤러리: 52ff95c19901d9254c90caa01708793ce230b74d, 85d613c2ab0e9c2824c12d6c9a1e40162a32b710, f4f228ce19290a55088ab0e0473dbb70b368f018, 5d8c8407dbe70245c2c9827a4ed4f837419b9107, 983176eab1cf8f884b6d34526763b8534f415827, 6adb7f82ee42b6ca811e78b637aa0c114d9b9e89.
- Steamworks의 대표4종/라이브러리3종에 English·Korean 행 저장 확인.
- BETA 실제 소개 이미지 한/영 각3개 정상 로딩(1560×878), 해당 언어 대체 텍스트 확인. 영문 상점 첫 화면의 영문 헤더와 실제 갤러리/기존 트레일러 표시 직접 확인.
- 한국어·영어 게시 원문의 이미지3개, 제목6개, 짧은 설명300자 이하 및 git diff --check PASS.
- 제품 코드 변경이 없어 전체 게임 테스트·전체 캠페인·검수 에이전트는 실행하지 않았다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 6fe9a3b24673ca36f8dee011c6eaffbb239d261e
- Review range: 590491e4e14fbb4dd9d64c12e6db88da879645f3..6fe9a3b24673ca36f8dee011c6eaffbb239d261e
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 5. 실제 남은 출시 요건
1. Valve 상점 심사(20Sep 제출)·빌드 심사(14Sep 제출). 체크리스트는 모두 완료, 심사 대기라 중복 제출하지 않음.
2. 첫 Coming Soon 공개 및 최소2주 공개 요건. Steam 안내상 첫 공개 전이므로 표시된9월28일 출시일은 재확인 필요. 날짜·판매 시작을 임의 실행하지 않음.
3. 영어 현지화 이름 Who Guards the Demon Castle?은 Steamworks 설정에 등록·게시됐고 Store Basic Info에도 표시된다. BETA 상단은 기본 한국어명으로 표시돼 첫 공개 후 실제 언어별 제목 확인 필요. 기본명을 영어로 바꾸면 한국어 BETA도 영어로 바뀌는 것을 확인해 원래 한국어 기본명으로 복원했다.
4. 실제 Steam 클라이언트 설치·삭제 및 최소사양 실측은 이번 상점 작업에서 실행하지 않았다. 현재 최소사양의 CPU/GPU/메모리 수치를 임의로 만들지 않았다.

## 6. 작업 트리와 다음 진입점
- 기존 루트의 혼합 작업 트리를 수정하지 않았다.
- 이번 제품 코드·오디오·저장·자산 원본 변경 없음. 캡처/빌드는 소스 브랜치에 넣지 않는다.
- CURRENT 및 이 기록을 커밋·푸시하고 필수 정책 검사 뒤 merge commit으로 main 반영한다. v1.2.8 태그는 제품 커밋에서 고정한다.
