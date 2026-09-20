# v1.2.8 한국 유통 증빙·등급 등록 확인 및 Steam Cloud 구성

## 1. 메타데이터
- 작성일: 2026-09-21
- 목표 버전: 1.2.8 (상점 안내·문서만 변경)
- 작업 브랜치: codex/v128-korea-release
- 기준 main SHA: 6d53e2f1148a261cf5e183431f2f4a051744ed2a
- 마지막 상점 문서 커밋 SHA: 8ca42c99a5c9fd2b9a674b215a7a62af21d906cc
- 원격 PR: https://github.com/bluehige/mawangseong-demo/pull/103
- 제품 태그: v1.2.8 유지. 빌드/태그 이동 및 바이너리 변경 없음.
- 상태: KOREA_DISTRIBUTION_RECEIPT_VERIFIED / BILINGUAL_RATING_NOTICE_SAVED / MANUAL_RATING_SAVED_BY_USER_VERIFIED / CLOUD_CONFIG_PUBLISHED_DEV_TEST / VALVE_REVIEW_PENDING

## 2. 목표와 사용자 결정
사용자가 한국 판매를 위해 게임물관리위원회의 유통 통보 접수 결과 원본 PDF를 제공했다. 원본 확인, 한국 판매 설정 확인, 가능한 상점 등급 표시를 수행한다.

후속 사용자 지시: 한국 등급은 직접 등록했으므로 다음 출시 작업을 진행한다. 저장 성공 화면에서 등록 사실을 확인한 뒤 Steam 실행 설정·Cloud 구성을 이어갔다.

사용자는 Steamworks 지원 문의와 원본 첨부 제안에 **전송하지 말고 초안만 보관**하라고 명시했다. 이후 원본을 근거로 한국 등급을 즉시 등록하라고 명시적으로 지시했다. 지원 문의·첨부는 실행하지 않았으며 추후에도 재승인 없이 전송하지 않는다.

## 3. 완료한 작업
- 2026-09-16 발행 게임위 원본 1쪽의 본문과 렌더 페이지, 직인을 확인했다. Valve/Steam을 신규 유통사업자로 명시하며 유통 통보가 정상 접수됐고 통보서 내용대로 운영 가능하다고 회신한다.
- 원본은 자체등급분류본과 신규 유통본의 게임 내용 동일성, 표시의무, 직권 등급 변경·취소 시 후속 조치를 조건으로 안내한다. 접수 결과를 모든 업데이트의 포괄적 승인으로 해석하지 않는다.
- STOVE 제품105282에서 12세 이용가·폭력성·SGHS-SP-260821-0002를 확인했다. 기존 적용 빌드49279와 최근 심사완료 빌드50206(v1.2.7)을 구분한다. 최근 심사 완료는 2026-09-15 15:57로 표시된다.
- Steam 판매 패키지1821599는 한국 구매 제외 제한이 없으며 KRW5,450이 등록돼 있다. 선물 교환의 지역 제한은 구매 제외와 구분했다.
- 한·영 Steam 상세 소개 끝에 한국의 12세 이용가, 폭력성, 12세 미만 부적합 안내, STOVE 자체등급분류 발급기관, 등급번호를 추가·저장했다.
- 한·영 BETA 미리보기에서 새 안내를 재조회했다. 기존 설명, 언어지원, 이미지3개씩, 짧은 소개는 보존했다.
- 오래된 '유통 통보/증빙 미확인' 기록은 이번 원본 확인으로 갱신했다. 비공개 공문, 접수번호, 개인정보는 공개 Git에 넣지 않았다.

- 사용자 직접 등록 후 Steam Ratings 저장 성공 화면에서 KGRB 체크·12 선택 및 STOVE 등급 기반의 유통통보 확인 설명을 읽었다. 등급 입력은 사용자 수행, 등록 확인은 에이전트 수행으로 구분한다.
- Steam 실행 설정: MawangCastle.exe, Windows, 64-bit only, default launch 확인. 기존 설정에 미게시 변경 없음 확인.
- Steam Cloud 용량0·경로 미설정 발견 후 10485760bytes/50파일, WinAppDataRoaming/Godot/app_userdata/마왕님, 마왕성 지켜주세요! Demo에 campaign_save_v1~v5.json 및 quarter_custom_layouts.json을 각각 등록했다. Windows 전용·비재귀, 동적 동기화 미사용.
- Publish 변경 비교에서 ufs만 변경됨을 확인한 뒤 게시했다. 결과: Your changes have been published / Publish to steam OK / Publishing successful. 개발자 전용 테스트 모드 유지. 상점 Steam Cloud 기능은 미체크임을 확인했다.

## 4. 변경 파일
- steam/store/STORE_PAGE_COPY.md
- steam/store/store_copy_bilingual.json
- steam/store/CONTENT_SURVEY_DRAFT.md
- steam/store/LANGUAGE_AND_KOREA_RATING_V127.md
- steam/store/STEAMWORKS_PORTAL_VALUES.md
- docs/handoff/CURRENT.md
- docs/handoff/V128_KOREA_RELEASE_2026-09-21.md

코드·한국어 원문·밸런스·게임 자산·음원·저장 데이터는 이번에 변경하지 않았다. 새 이미지 생성 없음.

## 5. 검증
- PDF 원본: pypdf 전체1쪽 추출 및 Poppler 렌더 직접 확인.
- v1.2.7..v1.2.8 소스 비교: localization과 이미지 생성 원본을 제외한 data/assets 변경 없음. 주요 실행 코드 차이는 영어 번역 연결과 표시 레이아웃이다. 이는 소스 비교 결과이며 기관의 1.2.8 별도 판정을 대신하지 않는다.
- 상점 BBCode/JSON: 언어별 등급번호1회, 기존 이미지3개, 짧은 소개 한국어213자/영어264자, 치환문자 없음.
- Steam 저장 성공과 한·영 BETA 본문 표시 확인. 사용자 직접 등급 등록 후 KGRB12 저장 화면 확인.
- Cloud 경로6개를 저장 코드/project.godot 및 release_config.json과 대조했다. 각 행의 root/path/pattern/os/recursive 저장값과 게시 성공을 직접 확인. 게임 설정·임시·백업 파일은 패턴에 없음.
- 현재 C/D Steam 라이브러리에는 App5267750 설치 기록이 없다. 네이티브 앱 제어가 현재 도구에서 비활성화돼 실제 Steam 설치·실행·삭제는 수행하지 않았다. 파일 검사를 Steam 실설치 통과로 기록하지 않는다.
- git diff --check 통과. ValidateRepositoryPolicy.ps1은 실제 브랜치 이름으로 실행해 통과했다(6파일/2커밋). 최초 HeadRef=HEAD 실행의 브랜치명 정책 오류는 인자 수정으로 해결했다.
- 런타임 변경 없음으로 게임 회귀·재빌드 미실행. 전체 회귀/별도 검수 에이전트 NOT_REQUESTED.

### 정책 CI용 필드
- Review task ID: NOT_REQUESTED
- Reviewed SHA: 8ca42c99a5c9fd2b9a674b215a7a62af21d906cc
- Review range: 6d53e2f1148a261cf5e183431f2f4a051744ed2a..8ca42c99a5c9fd2b9a674b215a7a62af21d906cc
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 남은 제한과 다음 순서
1. **현재 한국 등급 등록은 사용자 직접 수행 후 저장 확인 완료다.** 다음은 과거 에이전트 실행 차단 이력으로 남긴다: Steam Ratings > KGRB는 'information provided directly by the KGRB Game Rating Board rating agency' 확인을 요구한다. 사용자의 명시적인 즉시 등록 지시 후 확인란 클릭을 시도했으나 자동 승인 검토가 실행 전에 거절했다. 거절 사유는 STOVE 자체등급분류를 KGRB 직접발급으로 확인하면 사실과 다른 정보를 제출할 위험이 있다는 것이었다. 공식 자료 추가 조회에서도 이 확인 문구의 적용을 해소할 Steam 안내를 확보하지 못했다. 재시도·다른 경로 저장으로 우회하지 않았다. KGRB 선택만 원상 복원했고 확인란은 false였다. 사용자 승인 부족으로 보류된 것과 구분한다. 그 뒤 사용자가 직접 완료한 등록을 저장 화면에서 확인했으므로 이 차단 이력을 현재 미등록 상태로 오해하지 않는다.
2. 지원 문의 초안은 로컬 tmp/korea_release_v128/steam_support_draft.txt. 사용자가 발송을 원하지 않으므로 미전송을 유지한다. 원본 첨부도 없다.
3. 상점은 최초 공개 전 Valve 심사 상태다. Publish에 공개 실행 버튼이 없음을 재확인했다. 이번 저장은 심사용 BETA 반영이며 대중 공개/판매 시작이 아니다.
4. Valve 상점20Sep·빌드14Sep 제출 심사 중이며 체크리스트는 모두 완료다. 승인 후 Coming Soon 최소2주가 필요해 현재 표시된9월28일 출시일은 그대로 달성할 수 있는 일정으로 확정하지 않는다. Steam 실설치와 두PC Cloud 동기화 검증은 남아 있다. 두PC 검증 후 개발자 테스트 제한 해제·게시 및 상점 Cloud 지원 체크를 진행한다. 국가 설정만으로 오늘 구매 가능한 상태라고 말하지 않는다.
5. 제공 공문의 범위는 게임 등급/유통이다. 사업자등록·게임제작업 등록증까지 이 공문으로 확인됐다고 확장하지 않는다. 별도의 원본·담당기관 판단이 필요한 항목을 임의로 완료 처리하지 않는다.

## 7. 작업트리 및 로컬 증거
혼합 루트 작업트리를 건드리지 않고 tmp/uiux_v2 작업트리만 사용했다. 로컬 증거는 tmp/korea_release_v128/verification.json, 원본 렌더는 tmp/pdfs/korea_release/grac-receipt.png에 있으며 소스 커밋에서 제외한다. 원본 PDF는 사용자 제공 바탕화면 파일을 수정 없이 보존했다. 원격 PR과 필수 검사 결과는 최종 대화에서 보고한다.
