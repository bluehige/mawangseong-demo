# v1.2.8 한국어·영어 Steam 배포

## 1. 메타데이터
- 작성일: 2026-09-21
- 목표 버전: 사용자 확정 1.2.8, 화면 표시 1.2
- 작업 브랜치: codex/content-english
- 기준: main / df9b4f886806c960e15431a5e2a15ffe7373c0ee
- 구현 SHA: 1408261a79c492c6ba1fd062938eddff3f83555d
- PR: https://github.com/bluehige/mawangseong-demo/pull/100

## 2. 목표
전체 영어화 완료본을 Steam용 Windows 빌드로 만들어 기존 default 빌드를 교체하고, 한국어·영어 소개와 게임 내 언어 선택 안내를 게시한다. 판매 시작·가격·출시 예정일 변경은 범위 밖이다.

## 3. 구현과 변경 파일
- 이전 전체 영어화 구현·검증: CONTENT_ENGLISH_FULL_DAY01_30_2026-09-21.md.
- project.godot, export_presets.cfg: 사용자 확정 1.2.8 및 Windows 1.2.8.0.
- docs/PRODUCT_VERSIONING.md: 불변 버전 계보 기록.
- steam/release_config.json: 영어 인터페이스·대사 지원.
- steam/store/STORE_PAGE_COPY.md, store_copy_bilingual.json: 한·영 6개 설명 구획과 주요 특징, 게임 내 언어 선택. 짧은 설명 한국어213자·영어264자.
- 게임 규칙·밸런스·저장 형식·오디오 변경 없음. 이번 세션의 신규 이미지 생성 없음.

## 4. 검증
- DAY 1~30 카탈로그: 1,741대사/216장면 PASS.
- UI 카탈로그: 원문5,334개/영문5,344항목 PASS.
- V122Stage10LocalizationTest: 42 assertions PASS, 언어 설정·이름·튜토리얼 확인.
- Steam 릴리스·manifest 검사 도구 단위 검사: 23 PASS.
- 버전 갱신 전 동일 런타임의 Windows Steam export 및 실제 EXE 한국어·영어1080p 렌더: exit0, 오류0. tmp/steam_english_release/에 로그와 캡처.
- 이전 세션의 73화면/1,741대사 표시 검사 이후 게임 런타임 변경 없음. 전체 회귀·전체 캠페인 완주·검수 에이전트는 요청되지 않아 실행하지 않음.
- 최종 태그 빌드의 패키지·실행·Steam 서버 확인 결과는 아래에 추가한다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 1408261a79c492c6ba1fd062938eddff3f83555d
- Review range: df9b4f886806c960e15431a5e2a15ffe7373c0ee..1408261a79c492c6ba1fd062938eddff3f83555d
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 5. Steam 운영 상태
- App5267750 / Depot5267751. 기존 default Build25298646은 새 빌드 활성화 전까지 유지.
- 한·영 상세/짧은 설명 저장 후 재조회 확인. 영어 인터페이스·자막 체크 저장 확인, Full Audio 미체크 유지.
- 상점 심사20Sep, 빌드 심사14Sep 제출 대기 상태 확인. 심사 중 새 빌드 업로드 허용 문구 확인.
- 영문 캡슐·로고와 실제 영어 캡처는 준비돼 있으나 이번 세션의 이미지 파일 전송은 아직 미완료.

## 6. 남은 작업과 작업 트리
1. PR 필수 검사 및 merge commit 병합, 불변v1.2.8 태그.
2. 최종 Windows Steam export, manifest·압축 무결성 및 실제 실행 확인.
3. 새 Steam 빌드 업로드/default 활성화, 한·영 상점 게시와 서버 확인.
4. 최종 결과와 CURRENT 갱신. 산출물은 builds/ 또는 tmp/에만 보관.

기존 루트의 혼합 작업 트리는 변경하지 않았다. Godot 자동 import가 만든 내용 동일 줄바꿈 변경만 비교 후 복원한다. 현재 세션 변경 이외의 파일은 스테이징하지 않는다.
