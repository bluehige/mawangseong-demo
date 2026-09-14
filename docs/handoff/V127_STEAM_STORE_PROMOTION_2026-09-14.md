# v1.2.7 Steam 상점·홍보 게시

## 1. 메타데이터

- 작성일: 2026-09-14
- 목표 버전: v1.2.7 (상점 자료, 게임 런타임 불변)
- 작업 브랜치: codex/v127-steam-store
- 기준 브랜치 및 SHA: main / e1ff5e7a14c095a20e20ef476f452a1ae508d702
- 마지막 구현 커밋 SHA: 37013c3051b7350c313d90bfa894b35bf34860f5
- 원격 푸시 여부: 본 핸드오프 커밋 후 PR로 반영
- 제품 태그 SHA: 076d706b66f4844137c18a4a77386397873dce66 (이동·재빌드 없음)

## 2. 이번 세션 목표

사용자의 “다 게시해 그리고 게임 소개라던지 광고 같은것도 만들어서 올려” 요청. Steam 설정 게시, 상점 소개와 홍보 미술·실제 캡처·영상 제작 및 게시. 판매 가격·출시일·상호·연락처·권리 확인을 임의 확정하지 않는다. 유료 광고 집행과 외부 SNS 대상은 지정되지 않았다.

## 3. 완료한 작업

- Steam App 5267750 / Depot 5267751의 Windows x64 실행 메타데이터 게시 성공.
- 사용자 추가 승인 후 기본(default) 빌드 25298646 활성화 성공. Steam Build history의 Set live 기록과 Public default branch를 확인했다. Manifest 6837654025339205229, 설치 크기687.4MB. 판매 시작과는 별개다.
- 한국어 소개·213자 요약, 기본 영어 소개·245자 요약 저장. 영어 안내는 한국어 게임만 지원함을 명시한다. 게임 영어 지원 체크는 추가하지 않았다.
- 기존 자유 방·경로 건설 초안을 고정 미궁·지정 건설 구역 설명으로 수정했다.
- 새 GPT 홍보 그림을 Steam Description Custom Image에 Korean으로 업로드했다. Success와 Steam 서버 AVIF의 실제 렌더를 확인했다. 본문947자, 그림1개, 제목 중복0을 확인했다.
- 17개 태그 게시 성공: Real Time Tactics, Auto Battler, Tower Defense, Management, Base Building, Strategy, 2D, Cute, Isometric, Multiple Endings, Simulation, Stylized, Demons, Fantasy, Comedy, Resource Management, Singleplayer.
- 한국어 Interface/Subtitles, Single-player, Strategy/Simulation/Indie 저장. Mouse and keyboard only 마법사 완료. 앱·바로가기 아이콘 업로드 및 메타데이터 게시 성공.
- 랜딩 체크리스트에서 Basic Info, Descriptions, Controller Support Description, Tags, App Icon, Shortcut Icon 완료를 확인했다. Game Build의 At Least One Build Configured도 기본 빌드 활성화 후 완료됐다.
- GitHub v1.2.7 Release에 소개·홍보 자료 ZIP, 체크섬, 36초 실제 게임플레이 소개 영상과 영상 체크섬을 추가했다. 기존 출시 파일4개·태그 불변.
- 게임 코드·데이터·스토리·밸런스·세이브·오디오 자산 변경 없음.

## 4. 변경 파일

- steam/store/STORE_PAGE_COPY.md: 현재 기능에 맞는 한/영 소개. 미측정 최소 사양과 부정확한 자유 경로 건설 표현 제거.
- steam/store/PROMOTION_COPY_V127.md: 광고 문구와 게시 범위.
- marketing/steam/promo/promo_koreana.png: 새 설명용 홍보 그림.
- assets/source/imagegen/steam_promo_v127/SOURCE.md 및 promo_source.png: GPT 출처 기록.
- tools/ci/ValidateRepositoryPolicy.ps1: marketing/steam 이미지에도 출처 매핑 검사를 적용하고 상점 최종 경로를 허용한다. 게임 자산 예외를 만들지 않았다.
- tools/ci/TestRepositoryPolicy.ps1: 매핑된 홍보 이미지 허용/누락된 출처 거부 시나리오 추가.
- docs/handoff/CURRENT.md 및 이 문서.

## 5. 그래픽·영상

- Generation model: GPT internal image generation
- 그림:1672x941 PNG, 원본과 최종 파일 바이트 동일. 마왕·동료·검은 성의 홍보 일러스트이며 실제 스크린샷으로 분류하지 않는다.
- 그림 SHA256:713cf3e762fe36a1c451238e3acc7b1da15e7d0bfc5e5e5779d86c3d66215156
- 현재 Godot4.6.3 엔진에서1920x1080 캡처7장, 그 중 플레이 화면6장을 홍보 ZIP에 포함했다. DAY2/DAY8 상태를 준비한 촬영이며 전체 수동 플레이 증거가 아니다. 사용자 세이브는 별도 APPDATA로 보호했다.
- 영상: 실제 카드 드래그·후보 검토·건설·전투32초 + 홍보 일러스트4초. 1920x1080, 고정30fps, H.264 High4.1, 평균영상7956kbps, AAC stereo48kHz. 기존 게임 오디오 사용. 미술 요소를 합성한 가짜 플레이 장면 없음.
- 영상 제작: Godot --write-movie AVI + 작업용 PyPI imageio-ffmpeg. 라이브 게임 종료 때 정리 누수 경고가 있으나 녹화1007프레임·출력36초·전체 디코딩 완료. 이 경고를 제품 회귀 PASS로 숨기지 않는다.
- 로컬 촬영·영상·업로드 파일: tmp/steam_store_v127/ (Git 미포함).
- PressKit ZIP:15869217bytes, SHA256 c56202db36250888c2ab75aa20876f270946dcb19b2296cfb705fdf986a8be5d. 서버 digest 일치.
- GameplayTrailer MP4:36629239bytes, SHA256 e488df3ce7e23a8f0ca18c37f95262a05f9ddc02d65be2f0029ecf2d54f0ea75.

## 6. 테스트·검수

- TestRepositoryPolicy.ps1: PASS. 기존 시나리오와 상점 출처 누락 거부/정상 매핑 검사를 포함. 첫 테스트의 임시 fixture가 marketing 파일을 커밋하지 않던 준비 오류를 수정 후 통과했다. 테스트 종료의 기존 “12 scenarios” 문구는 이번 추가분을 반영하지 않으므로 총횟수로 인용하지 않는다.
- validate_steam_release.py: SETUP_PASS, 외부 확인15개 pending. 공개 출시 완료 판정이 아니다.
- test_validate_steam_release.py:10 tests PASS. 최초 읽기 전용 실행의 temp 생성 실패는 쓰기 가능한 실행에서 해소했다.
- git diff --check: PASS.
- 소개문: 저장 후 재진입, 한국어/영어 요약과 본문 보존, Steam Descriptions 체크 완료.
- UI: 게임 캡처7장 시각 확인, 실제 드래그/건설/전투/엔드카드 대표 프레임 확인. 영상 전체 디코딩 완료, 최대 음량 클리핑 없음. 전체 영상을 사람처럼 재생 청취한 것은 아니다.
- GitHub 홍보 ZIP CRC PASS, 서버 해시 동일. 기존 WindowsZIP digest 동일.
- 전체 게임 회귀·사람 사용성·Steam 실설치: 이번 마케팅 작업에서 재실행하지 않음.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 37013c3051b7350c313d90bfa894b35bf34860f5
- Review range: e1ff5e7a14c095a20e20ef476f452a1ae508d702..37013c3051b7350c313d90bfa894b35bf34860f5
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

위 결과는 상점 자료·출처 검사 변경에 대한 표적 검증이다. Steam 출시 요건 완료를 뜻하지 않는다.

## 7. 미해결·도구 경계

- Steam 상점 첫 공개/심사/판매 시작 미완료. 필수 미완료: 콘텐츠 설문(AI 사용 포함), 출시 예정일, 측정된 시스템 요구사항, 스크린샷5장 이상, 캡슐4종, 라이브러리 미술, 지원 연락처, 개발사/배급사 이름. 판매 빌드에는 가격 승인과 예고편도 필요하다.
- 가격·공개 개발사/배급사·지원 이메일·출시일은 비동기 질문 답변 대기. 임의값 입력 없음.
- Steam 최초 공개는 Valve 심사 필요. 현재 랜딩은 Coming Soon 공개 후 최소2주 및 계정의 크레딧 기준 대기 요건을 표시한다. 임의 날짜 확정 없음.
- Graphical Assets와 Trailers는 파일 선택 input 없는 로컬 파일 드롭 전용. 현재 cua 브라우저 API는 로컬 파일 드래그를 지원하지 않고 native API도 비활성이다. 클릭해도 chooser가 열리지 않는 것을 확인했으며 브라우저 보안을 우회하지 않았다.
- 사용자가 tmp/steam_store_v127/upload/01_store,02_screenshots,03_library,04_trailer의 파일을 각 Steam 드롭 영역에 직접 넣어야 한다. 그 뒤 분류·저장·검수 요청은 이어서 진행할 수 있다. 안내: 같은 폴더 읽어주세요.txt.
- 예고편은 Steam에 “마왕성 게임플레이 소개” 빈 항목까지 생성했고 파일 드롭 대기다. 영상 파일은 GitHub에는 게시했다.
- 기본 빌드 활성화 첫 시도는 자동 검토가 이전 범위 제한을 근거로 거절했다. 사용자 “v1.2.7 기본 빌드 활성화 승인” 답변으로 해소하고 실행·검증 완료했다. 추가 승인 대기로 잘못 기록하지 않는다.

## 8. 다음 작업

1. 사용자 제공 상호/연락처/가격/출시일 반영.
2. 준비된 이미지·영상 파일을 사용자가 Steam 드롭 영역에 놓으면 분류와 업로드 완료 확인. 그래픽0/4,스크린샷0/5,라이브러리0/5 상태를 완료로 오인하지 않는다.
3. 전체 콘텐츠·AI 사용 설문과 권리 확인, 실측 최소 사양, Steam 설치 실행 확인을 마친 뒤 Valve 상점·빌드 심사 요청.
4. 심사·대기 조건 충족 후 공개/판매. 새 버전·태그·가격·할인을 임의로 추가하지 않는다.

## 9. 작업트리

기존 혼합 변경 없음. 소스 변경7파일 커밋 후 핸드오프2파일만 추가한다. 로컬 빌드·캡처·영상은 tmp에 두고 GitHub Release 첨부로만 배포한다. main에는 PR merge commit으로 반영한다.
