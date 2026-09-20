# v1.2.8 한국어·영어 Steam 배포

후속 완료 기록: [상점 마무리 세션](V128_STEAM_STORE_POLISH_2026-09-21.md)에서 default25423797 활성화 확인과 한/영 대표·라이브러리 이미지 업로드, 최신 갤러리 및 소개 이미지 구성을 완료했다. 아래 확인창/이미지 대기 항목은 이 초기 배포 세션 당시의 기록이며 최신 상태는 후속 문서와 CURRENT를 따른다.

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
1. PR 병합·v1.2.8 태그·최종 export·업로드는 완료했다. 상세 증거는 7절.
2. Steam 기본 빌드 확인창이 처리되면 default가25423797인지 서버에서 확인한다.
3. 추가 영어 상점 이미지는 파일 선택이 정상 작동하는 환경에서 연결한다. 소개와 언어 지원은 이미 저장·미리보기 확인했다.
4. Valve 심사·상점 최초 공개는 대기 중이다. 산출물은 builds/ 또는 tmp/에만 보관한다.

기존 루트의 혼합 작업 트리는 변경하지 않았다. Godot 자동 import가 만든 내용 동일 줄바꿈 변경만 비교 후 복원한다. 현재 세션 변경 이외의 파일은 스테이징하지 않는다.

## 7. 최종 빌드와 Steam 업로드 근거
- PR100 필수 repository-policy PASS 뒤 merge commit 4d49c1a1c4f283c365513b207de36581dc73cb30으로 main 병합.
- 사용자 확정 불변 v1.2.8 태그 생성·push. 기존 태그 변경 없음.
- 태그 자동 빌드 SUCCESS: https://github.com/bluehige/mawangseong-demo/actions/runs/35528853211. 별도 Windows 환경의 export·실행·artifact 보관까지 완료.
- 같은 태그의 로컬 Windows Steam export 및 validate_steam_release.py SETUP_PASS. 미확정 외부 출시 항목15개는 전체 판매 READY 의미가 아니므로 그대로 기록했다.
- 실제 최종 EXE 한국어/영어 headless 부팅 exit0, 오류0. 파일/제품 버전1.2.8.0.
- PCK3,384파일: 전체 스토리/UI 번역 카탈로그3종 포함. 개발 도구·원본 자산 차단 검사 통과.
- 설치 루트 구조의 ZIP614,171,381bytes, SHA256134a46a43b1f2f817a75cf95c27523ae5ec21babfeb05062147c07fcdc01825d. 압축 CRC·각 manifest SHA256 재검증 PASS.
- Steam App5267750 / Depot5267751 / Build25423797 / Manifest6231007988850841416.
- 서버 파일6개 크기·SHA1 대조6/6 PASS. 1.2.7 대비 업데이트 다운로드량4.1MB(Steam 미리보기 계산).
- 근거: tmp/steam_english_release/{final_export.log,final_boot_ko.log,final_boot_en.log,final_verification.json,steam_server_verification.json}.

## 8. 상점 반영과 실제 남은 단계
- 한/영 상세 소개 각6구획, 주요 특징7항목과 언어 선택 안내. 짧은 설명213/264자. 두 언어 BETA 미리보기의 실제 렌더에서 확인했다.
- 영어 Interface/Subtitles 저장, Full Audio 미체크. 한국어 지원 유지.
- 영어 localized app name 추가 후 Publish to Steam / Really Publish를 실행했고 Publishing successful 확인. 한국어 이름 유지.
- Steam 상점은 최초 공개 전 Valve 심사 중이다. 상점 Publish 탭에 실행 버튼이 없어 공개 게시를 했다고 주장하지 않는다. 저장된 심사용 소개는 최신이다.
- 그래픽 드롭 영역은 실제 파일 선택을 열지 않는다. 별도 숨김 input은 설명용 Custom Image이며 캡슐 입력이 아니므로 잘못된 목적에 업로드하지 않았다. 새 영문 캡슐/스크린샷 추가 업로드 미완료, 기존 미술 보존.
- Set Build Live Now를 누르자 'Set build 25423797 live for branch default?' 확인창이 열렸다. 브라우저 도구의 확인창 처리가 시간 초과돼 사용자가 해당 확인창을 한 번 누르도록 도움 요청. 마지막 별도 서버 조회의 default는25298646. 새 빌드 활성화는 확인 대기다.
- 빌드 확인창 탭874252598을 handoff로 보존했다. 인증/판매 시작/가격 변경을 우회하지 않았다.
- 기본 빌드 확인이 끝나면 CURRENT의 DEFAULT_CONFIRMATION_PENDING을 실제 결과로 바꾸고 서버 조회 근거를 추가한다.
- GitHub Release 추가 공개, 전체 게임 회귀·모든 캠페인 완주, 실제 Steam 설치는 이번 세션에서 실행하지 않았다.

## 9. 문서 후속 반영
- 결과 문서 브랜치 codex/v128-steam-deployment는 태그 제품 커밋에서 시작했다. 제품 바이너리와 태그는 고정한다.
- 마지막 제품 커밋: 4d49c1a1c4f283c365513b207de36581dc73cb30. main·태그 원격 푸시 완료. 후속 문서는 별도 PR로 반영한다.
- 후속 변경은 CURRENT.md와 이 세션 문서 두 파일뿐이며 기존 루트 작업 트리의 변경은 그대로 보존한다.
- 로컬 main 강제 이동 명령은 자동 검토에서 거절됐다. 이후 조상 관계를 확인하고 비강제 fast-forward push로만 동기화했다. 강제 변경 및 사용자 커밋 손실 없음.
