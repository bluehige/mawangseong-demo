# v1.2.7 영어 홍보 및 등급 증빙 조사

## 1. 메타데이터
- 작성일: 2026-09-14
- 목표 버전: v1.2.7 (마케팅만)
- 작업 브랜치: codex/v127-english-promo
- 기준 브랜치 및 SHA: main / 43c6dabcadc0ecb8c1e088667b81f74a58cd71cc
- 마지막 구현 커밋 SHA: ccd742047f57237723a0bae6f40e3f83011d1b1d
- 원격 푸시 여부: 종료 시 PR 반영 예정

## 2. 목표와 완료
사용자의 한/영 지원·STOVE 심의 증빙·영어 홍보 이미지 질문에 따라 코드와 공식 법령을 조사했다. 영어 홍보 그림 생성 완료. 게임 런타임·스토리·밸런스·저장·출시 빌드 불변.

## 3. 실제 언어 범위
LanguageSettings와 v122_stage10_ui.json의 영어142키는 settings61/name20/tutorial61이다. 설정·이름 입력·초반 튜토리얼 일부 영어를 지원하며 캠페인 전체 영어 번역은 미완료다. 관련3파일은 v1.2.7 태그와 diff가 없다. 이전 한국어 전용 설명은 너무 단정적이어서 일부 영어/전체 한국어 필요로 보정했다. 영어 지원 Steam 체크를 추가하지 않았다.

## 4. 변경 파일 및 자산
- marketing/steam/promo/promo_english.png
- assets/source/imagegen/steam_promo_v127_english/SOURCE.md 및 promo_source.png
- steam/store/STORE_PAGE_COPY.md
- steam/store/LANGUAGE_AND_KOREA_RATING_V127.md
- docs/handoff/CURRENT.md 및 본 문서

GPT internal image generation으로 한국어 그림의 문구를 영어로 교체. 기존 영문 가제와 슬로건 적용. 원본 바이트 그대로 보존, 로컬 이미지 편집 없음. 영어 이미지 문구/구도 시각 확인 완료. Steam 업로드는 미실행, 캡슐 세트 전체·영상 영어판 미완료.

## 5. 검증
- 이미지 출력과 최종 저장 해시 일치: 4276c446ce3487e5531a3a6f2794c43a995e90b04358b315399db50ed45a9513
- git diff --check PASS
- 데이터 카탈로그 키 수 및 코드 사용 범위 직접 확인. 영어 실플레이·전체 회귀는 NOT_REQUESTED.
- 정책 검사는 핸드오프 커밋 후 실행.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: ccd742047f57237723a0bae6f40e3f83011d1b1d
- Review range: 43c6dabcadc0ecb8c1e088667b81f74a58cd71cc..ccd742047f57237723a0bae6f40e3f83011d1b1d
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 미해결·다음 작업
STOVE 제품105282 심사 결과: 자체심의등급분류 / 12세 이용가 / 폭력성 / SGHS-SP-260821-0002 / 빌드49279. 심사완료2026.08.21 12:54와 별도 분류일자2026.07.21 15:10이 달라 통지서 날짜 확인이 필요하다. 결과 화면에 PDF 다운로드는 보이지 않았다. 직접 발급/Steam 제출은 미실행이다. 사용자 제공 페이지에서 읽기만 했고 개인 연락처는 공개 문서에 복사하지 않았다. 법령 제21조의3/제21조의4와 Steam 공식 Content Survey의 Ratings 지침을 확인했으나 특정 게임의 효력이나 증빙 제출 완료로 간주하지 않는다. 발급기관/번호/분류 버전/유통 통보 여부 확인 후 Steam 등록 경로를 정한다. 원본 심의 문서나 비공개 계정 정보는 공개 Git에 넣지 않는다.

## 7. 작업트리
관련 자료만 명시 스테이징. 출시 태그 이동, 빌드 교체, 언어 기능 변경 없음.