# v1.2.7 Steam 제출 진행

## 1. 메타데이터
- 작성일: 2026-09-14
- 목표 버전: v1.2.7 (제품 바이너리 불변)
- 작업 브랜치: codex/v127-steam-submission
- 기준 브랜치 및 SHA: main / 8df8a027e8caa165735e587eb952148ac5bc610c
- 마지막 문안 커밋 SHA: ab31f5c798b21ae6ae531a019458b3a47fe22e7b
- 원격 푸시 여부: 이 핸드오프와 함께 PR 제출
- 제품 태그: v1.2.7 / 076d706b66f4844137c18a4a77386397873dce66

## 2. 이번 세션 목표
사용자가 절대 직접 할 수 없는 부분만 요청하고 출시/상점/심의 처리를 직접 진행하도록 위임했다. 브라우저 실제 상태 확인, 영어 홍보 반영, 심의 증빙 조사와 문의 접수가 범위다.

## 3. 완료한 작업
- 영어 홍보 이미지 promo 그룹 업로드, 영어 본문 이미지 연결 및 부분 영어 지원 문구 저장·재조회.
- 영어 짧은 소개의 Full gameplay requires Korean 문구 저장·재조회.
- 전체 자막 번역 근거 없는 English Subtitles 체크 해제·저장·재조회.
- 상점 캡슐/스크린샷/라이브러리/영상 등록 완료를 체크리스트에서 확인. 기존 사용자 업로드 중복 요청 제거.
- STOVE 7월21일 15:11 공식 등급 결과 메일에서 자체심의12세 확인. 로컬 파일 저장은 확인 못함.
- STOVE 문의2006381841, 2026-09-14 23:03 접수 완료 및 상세 확인. 발급 문서/타 플랫폼 통보/분류일자/내용수정신고 자료 요청. 담당자 답변 대기.
- 게임 코드·스토리·밸런스·저장·바이너리 변경 없음.

## 4. 변경 파일
- steam/store/CONTENT_SURVEY_DRAFT.md: 실제 설문 작성 항목과 근거, AI 오디오/서사 보완, 거절 상태.
- steam/store/LANGUAGE_AND_KOREA_RATING_V127.md: 증빙 메일·문의 접수·Steam 저장 결과.
- steam/store/STORE_PAGE_COPY.md: 반영 완료 상태.
- docs/handoff/CURRENT.md 및 이 파일: 다음 작업.

## 5. 그래픽 및 오디오
기존 PR98 영어 promo_english.png 사용. 신규 생성/자산 수정 없음. 영어 캡슐·영어 영상 별도 제작 미완료.

## 6. 검증
- Steam 영어 짧은/긴 소개 저장 후 재조회: 일치.
- English Subtitles 저장 후 재조회: 해제.
- STOVE 문의 정상 등록 메시지 및 상세 접수번호: 확인.
- Steam 체크리스트: 미완료는 설문·예정일·가격/가격 게시. 사양 체크를 성능 검증 통과로 해석하지 않음.
- git diff --check: PASS.
- 전체 게임 회귀/실설치/사람 검수: NOT_REQUESTED, 미실행.
- Review task ID: NOT_REQUESTED
- Reviewed SHA: 92892055400665aa2d088f74b1365cd2a91bbaaa
- Review range: 8df8a027e8caa165735e587eb952148ac5bc610c..92892055400665aa2d088f74b1365cd2a91bbaaa
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

TARGETED_PASS는 문안·등록 상태 확인에 한정된다. 설문 및 상점 출시 전체 완료 판정이 아니다.

## 7. 미해결 항목과 위험
콘텐츠 설문 Save가 자동 승인 검토에서 폭력·범죄·욕설·AI 범위 검증/구체적 승인 부족으로 거절됨. 우회 안 함. 브라우저 입력 초안을 보존함. STOVE 발급 PDF 확보/Steam 한국 등급 적용은 미완료. 예정일/판매가 미확정. Valve 상점/빌드 심사와 Coming Soon 최소2주 조건 남음. Steam Cloud 미설정.

## 8. 다음 작업
1. 설문 구체적 신고 승인/보완, 저장·게시.
2. 가격/예정일 결정과 등록. 현재 STOVE 가격 $4.99는 참고이며 Steam 가격 승인으로 단정하지 않음.
3. STOVE 문의 답변 확인 후 증빙·유통 통보/내용수정신고 후속. 새 유료 심의 필요 단정 금지.
4. 필수 항목 완료 후 Valve 상점/빌드 검토 요청. 자동 출시/태그 재지정 금지.

## 9. 작업 트리
기존 혼합 변경 없음. 문서만 명시적으로 스테이징. 바이너리·비공개 메일·연락처 미커밋. 브라우저의 설문 초안, STOVE 문의 상세, 메일 원본 화면 보존.

## 최종 재조회 보정 (초기 관찰보다 우선)
- 작업 중 사용자 측 설정이 추가됐다. 현재 가격 USD4.99/KRW5,450, 예정일 2026-09-28 23:00 KST. 에이전트가 정한 값은 아니다.
- 최신 landing에서 Game Build checklist complete, Store Presence는 Content Survey만 미완료다. 상점 심사 요청 전에는 빌드 심사를 제출할 수 없다는 안내를 확인했다. 가격/예정일 추가 입력을 요구하지 않는다.
- 첫 GitHub CI는 문서의 대소문자 고정 Pre-Generated 및 SOURCE.md 표시 누락으로 실패했다. 실제 AI 출처 경로와 함께 복구했으며 test_validate_steam_release.py 10개 테스트 모두 통과했다. 제품 코드 변경은 없다.
