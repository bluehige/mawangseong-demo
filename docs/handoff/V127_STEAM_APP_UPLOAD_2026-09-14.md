# v1.2.7 Steam 앱 생성·업로드 진행

## 1. 메타데이터
- 작성일: 2026-09-14
- 목표 버전: 1.2.7
- 작업 브랜치: codex/v127-steam-app-upload
- 기준: 01b7b001d65f4d3a937aa07fc8485c84d84a785a
- 설정 검증 커밋: 84d09a00e9d4f87e1014421b52caa53950251b19
- 원격 반영: PR #96 https://github.com/bluehige/mawangseong-demo/pull/96. 제품 출시 태그는 변경하지 않는다.
- 최초 CI의 테스트2개 실패 원인은 App ID 미발급 고정 가정. 테스트 수정 후 10개 직접 검사 및 정책 검사 통과.
- 기존 제품 태그: v1.2.7 / 076d706b66f4844137c18a4a77386397873dce66 (불변)

## 2. 목표와 완료 내용
사용자가 앱 크레딧으로 게임 생성 및 기존 Steam 빌드 업로드를 승인했다.
- 게임 앱 생성 완료: App ID 5267750, 기본 Content Depot ID 5267751.
- 게임명: 마왕님, 마왕성은 누가 지켜요? / Game / 유료 제품.
- Developer Comp 1821597, Beta Testing 1821598, Store package 1821599.
- Windows / 64 Bit Only 및 실행 파일 MawangCastle.exe, Launch(Default), Windows 64비트 설정 저장.
- Publish 탭에서 실행 설정 diff 및 Prepare for Publishing 완료. 최종 Really Publish는 자동 승인 검토에서 거절되어 미실행.
- 브랜치 활성화, 판매 시작, 상점 게시, Valve 심사 제출은 미실행.
- 게임 코드·스토리·밸런스·미술·저장 형식 변경 없음.

## 3. 변경 파일
- steam/release_config.json: 실제 앱·디포 번호 반영.
- tools/ci/test_validate_steam_release.py: 실제 설정이 영구 미발급이라고 가정한 기존 테스트를 분리. 명시적 미발급·발급 fixture 및 strict 거부 검증. 10개 테스트 통과.
- docs/handoff/CURRENT.md 및 이 문서: 업로드 완료 및 설정 게시 승인 경계 기록.

## 4. 빌드 및 검증
- 기존 builds/steam/windows/v1.2.7 파일5개의 크기·SHA256을 출시 manifest와 대조: 일치.
- 설치 루트용 별도 ZIP: tmp/steam_release_v127/MawangCastle-v1.2.7-SteamDepot.zip.
- ZIP 613918544 bytes, SHA256 68b3d81eb9bdd24d76bfcd3975a6eea6f4f09f6080d7d71b5af5944d43b6a761.
- 루트 MawangCastle.exe/PCK 및 licenses·manifest·notices 6파일. ZIP CRC 검사 통과.
- 기존 GitHub 배포 ZIP과 제품 바이너리는 변경하지 않았다.
- validate_steam_release.py --build-dir builds/steam/windows/v1.2.7: SETUP_PASS, 외부 출시 항목 15개 PENDING. 전체 출시 통과 의미 아님.
- 전체 회귀·Steam 실설치·사람 검수 미실행.

## 5. Steam 업로드 완료
- 사용자가 Chrome 파일 URL 접근 권한을 직접 허용했다. Chrome 재연결 후 파일 선택 성공.
- 오래 열린 탭의 첫 전송은 진행되지 않아 갱신 후 동일 ZIP 재선택. 재시도는 파일 전송·디포 처리·Commit 성공.
- App ID 5267750 / Depot ID 5267751.
- Manifest ID: 6837654025339205229.
- Build ID: 25298646.
- 설명: v1.2.7 Windows x64 - source 076d706b66f4844137c18a4a77386397873dce66.
- Set build live for branch: None. 빌드 목록의 default BuildID는 0으로 미활성 상태.
- Steam 디포 서버 파일6개의 SHA1을 로컬 출시 파일과 대조: 6/6 일치. 실행 파일·PCK는 설치 루트에 존재.
- 서버 디스크 크기 687432245 bytes, 전송 압축 크기 610600992 bytes.
- 빌드: https://partner.steamgames.com/apps/builds/5267750
- 디포: https://partner.steamgames.com/apps/depotmanifest/5267750/5267751/6837654025339205229

## 6. 검증 범위와 승인 대기
- Review task ID: NOT_REQUESTED
- Reviewed SHA: 84d09a00e9d4f87e1014421b52caa53950251b19
- Review range: 01b7b001d65f4d3a937aa07fc8485c84d84a785a..84d09a00e9d4f87e1014421b52caa53950251b19
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
- 위 결과는 App/Depot ID 설정 및 동일 출시 파일 업로드 확인 범위다. Steam 실설치·Valve 승인·정식 판매 준비 완료 판정이 아니다.
- 최종 설정 게시 Really Publish가 자동 승인 검토에 거절됐다. 사유: 빌드 업로드 승인에 공개 universe 설정 게시가 포함되지 않음. 우회하지 않았다.
- 게시할 변경은 Windows x64 지원 및 MawangCastle.exe 실행 설정뿐이다. 게임 ReleaseState unavailable 및 설치 폴더 유지.
- 사용자에게 이 설정 게시만 승인 요청한다. 판매 시작·default 빌드 활성화는 아직 하지 않는다.
- 승인 후 기존 Publishing 화면에서 최종 설정 게시를 완료한다. 이후 실제 설치를 하려면 별도 배포 브랜치 활성화가 필요하다.
- 스토리·밸런스·그래픽·오디오·게임 코드 및 기존 출시 자산 변경 없음. 신규 이미지 생성 없음.

## 7. 작업 트리와 산출물
- 기존 사용자 변경 없음. 설정1개와 핸드오프2개만 변경.
- 빌드 ZIP·로컬 기록은 tmp/steam_release_v127 및 builds/steam 아래에 보존하고 소스에 추가하지 않았다.
- 현재 GitHub Release v1.2.7 및 공개 Web v1.2.6 유지.
