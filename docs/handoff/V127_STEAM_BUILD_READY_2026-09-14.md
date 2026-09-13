# v1.2.7 Windows Steam 빌드·GitHub 소스 반영 완료 — 2026-09-14

## 1. 메타데이터
- 사용자 확정 버전:1.2.7, 화면표시1.2, Windows파일/제품버전1.2.7.0
- 최종빌드소스/main병합SHA: `076d706b66f4844137c18a4a77386397873dce66`
- 소스PR: https://github.com/bluehige/mawangseong-demo/pull/93 (MERGED)
- 시작원격main:69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 결과문서브랜치:codex/v127-steam-handoff
- 공개태그v1.2.6과과거Release는보존. v1.2.7태그는현재로컬에만존재.

## 2. 목표·완료한 범위
사용자가직접Steam에업로드할Windows정식빌드완료. 검증된UIUX개선내용과1.2.7메타데이터를GitHubmain에커밋/PR병합하고빌드manifest의source_commit일치확인.

## 3. 구현·데이터·스토리·밸런스
직전검증된UIUX코드에버전메타데이터만변경. 이번최종빌드뒤게임코드·데이터·이미지·음원·저장변경없음. 현재캐릭터그림유지,방향별미술후속.

## 4. 파일·산출물
- Steam업로드폴더: `builds/steam/windows/v1.2.7/`
- 실행파일: `MawangCastle.exe`, PCK/라이선스/고지/manifest를같이사용.
- ZIP: `builds/steam/MawangCastle-v1.2.7-Windows-Steam.zip`
- ZIP크기: 613918784 bytes
- ZIP SHA256: `f7748bb73b9dcd4d217d72d739c7c83b3ec39404071e29c1cf9548df8c6bd2c8`
- 사용안내: `builds/steam/V1.2.7_UPLOAD_README.txt`
- 최종검증: `tmp/steam_release_v127/final_build_verification.json`
- 소스커밋에는빌드/ZIP/캡처추가없음.

## 5. 그래픽·오디오
새자산생성없음. Steam전용프리셋으로개발자료제외,PCK필수런타임과Noto/NEXON/Godot고지포함. 실제최종타이틀1920×1080확인.

## 6. 검증
- 후보·최종 Godot4.6.3 Windows Steam release export PASS.
- 최종manifest버전1.2.7,source_commit==로컬태그v1.2.7==main소스병합SHA.
- PCK금지경로/파일해시/라이선스검사PASS,ZIP testzip PASS.
- 실제최종exe headless부팅exit0,네이티브Vulkan타이틀렌더exit0(1920×1080),log ERROR/SCRIPT ERROR0건. final_boot.log/final_render.log/final_title00000029.png.
- Steam검증도구8개/manifest검증도구13개/LFS fsck PASS.
- PR #93필수 repository-policy PASS: https://github.com/bluehige/mawangseong-demo/actions/runs/34784021845
- main병합뒤정책PASS: https://github.com/bluehige/mawangseong-demo/actions/runs/34784127379
- 직전전체·캠페인검증은 [통합QA](UIUX_V2_FINAL_VALIDATION_2026-09-14.md) 참조. 버전변경후전체게임회귀를반복하거나사람/Steam실설치를통과했다고표시하지않음.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 076d706b66f4844137c18a4a77386397873dce66
- Review range: 076d706b66f4844137c18a4a77386397873dce66..076d706b66f4844137c18a4a77386397873dce66
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 제한·승인 경계
- Steam업로드·기본브랜치활성화미실행(사용자가직접수행예정).
- 저장소SteamAppID/DepotID0,외부게이트17개PENDING. 실제Steamworks앱/디포값사용필요. 판매READY로승격하지않음.
- GitHubv1.2.7태그push 및614MB ZIP을포함한정식Release공개요청은자동승인검토에서거절. 이유: 사용자요청은GitHub소스커밋확인까지이며외부게임배포/아티팩트공개업로드의명시승인이없음.
- 따라서GitHub소스main반영완료와GitHubRelease공개미실행을구분한다. 우회실행없음. 기존v1.2.6최신공개Release유지.

## 8. 다음 작업
1. 사용자는완성된폴더/ZIP으로Steam업로드가능. 저장소업로드스크립트를쓰면실제AppID/DepotID입력필요.
2. 사용자명시승인시만고정된v1.2.7태그와현재검증ZIP/manifest를GitHubRelease에공개. 새제품빌드나태그이동불필요.

## 9. 작업 트리·원격
구현소스는PR93으로원격main에반영. 이후이번핸드오프와CURRENT만갱신. main참조도원격과fast-forward동기화. 자동import줄바꿈만원본과비교해정리했으며사용자파일변경없음.

## 10. 판정
**Windows Steam 정식빌드완료 / GitHubmain소스반영확인완료 / Steam업로드미실행 / GitHub태그·Release공개승인대기.**
