# v1.2.7 Steam 정식 빌드 후보 — 2026-09-14

## 1. 메타데이터
- 목표 버전: 1.2.7 (사용자 확정), 화면 표시1.2
- 브랜치: codex/v127-uiux-release
- 기준 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 검증 소스 SHA: 9988846bebb702db52ac00bb715a46317069224c
- 이전 개선 완료 HEAD:8918efd1a6da5f74fb36749b1c91084419c3ad98
- GitHub 원격 확인: 시작 시 개선판 브랜치/PR 없음, 최신 Release v1.2.6. 이번 요청에 따라 출시 소스 반영을 진행한다.

## 2. 목표·범위
사용자가 Steam에 직접 업로드할 정식 Windows 빌드와 GitHub 출시 소스·태그의 일치를 준비한다. 기존 v1.2.6 및 과거 태그 보존. Steam 계정 업로드·판매 활성화는 수행하지 않는다.

## 3. 구현·데이터·스토리·밸런스
- 최신main에서 새 출시 브랜치를 시작해 검증된 UIUX 작업 브랜치를 merge commit으로 통합. 과거v20 실험선 미사용.
- project.godot 및 Windows export 프리셋의 버전을1.2.7/1.2.7.0으로 변경하고 제품 버전 문서에 사용자 확정 기록.
- 직전 최종 검증 이후 게임 규칙·대사·비용·보상·저장 형식·이미지·오디오 변경 없음. 캐릭터 방향 미술은 사용자 승인 후속.

## 4. 변경 파일
project.godot, export_presets.cfg, docs/PRODUCT_VERSIONING.md, 본 핸드오프, CURRENT.md.

## 5. 그래픽·오디오
신규 생성 없음. 기존 자산 사용. Steam depot에는 소스·QA 자료를 제외하고 필요한 폰트 라이선스/고지를 포함.

## 6. 검증
- Godot4.6.3 Windows Steam release 후보 export PASS, PCK 내부 금지 경로·파일 해시·라이선스 검사 PASS. tmp/steam_release_v127/candidate_build.log.
- 실제 후보 MawangCastle.exe 파일/제품버전1.2.7.0 확인. headless 부팅exit0, 실제 Windows Vulkan/RTX3060Ti 타이틀1920×1080 렌더 확인(title00000029.png). 엔진 녹화이며 사람 직접 입력 검사는 아님.
- Steam 검사 도구8개, build manifest 검사13개 PASS. Git LFS fsck PASS.
- 기존 전체161개 실행160PASS+튜토리얼 검사 수정후177항목PASS, 누적UIUX32개 및DAY30 실제캠페인2조건은 [최종 검증](UIUX_V2_FINAL_VALIDATION_2026-09-14.md) 참조. 이번 메타데이터 변경에 전체 플레이를 재실행하지 않았다.
- Godot import가194개 .import의 줄바꿈만 변경함을 원본 정규화 비교로 확인하고 해당 자동 변경만 복구. 기능 설정 변경 없음.
- Steam 설정검사 SETUP_PASS(외부17항목PENDING). AppID/DepotID, Steam 설치/심사/상점 완료 여부를 추정해 PASS로 바꾸지 않는다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 9988846bebb702db52ac00bb715a46317069224c
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..9988846bebb702db52ac00bb715a46317069224c
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 제한
이 세션의 추가 전체 회귀/사람 사용성/Web·모바일/Steam 실설치 미실행. Steamworks AppID·DepotID는 저장소에0이므로 사용자 실제 업로드 환경에서 지정한다. 공개 판매 READY와 depot 빌드 성공은 구분한다.

## 8. 다음 순서
1. 후보 소스 PR의 필수 repository-policy PASS 후 merge commit으로 main 반영.
2. 최종main 커밋에서 Steam depot 재빌드·검증, 같은커밋에불변v1.2.7태그와GitHubRelease/zip/manifest 연결.
3. 원격main·tag·manifest source_commit 일치 확인 후 사용자에게폴더와zip 제공. Steam 업로드는 사용자 수행.

## 9. 작업 트리·원격
빌드/캡처는tmp에만 두고소스커밋에넣지 않는다. 기존사용자수정없음. 후속원격결과는출시완료핸드오프에기록.

## 10. 완료 경계
현재상태는검증된출시후보. 최종병합/태그/Release/최종build검증후출시기록을갱신한다.
