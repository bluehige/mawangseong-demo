# v1.2.7 Steam 빌드와 GitHub 소스 반영 결과

## 1. 메타데이터
- 작성일: 2026-09-14
- 사용자 확정 버전: 1.2.7. 화면은 1.2, Windows 파일·제품 버전은 1.2.7.0.
- 제품 소스 SHA: `076d706b66f4844137c18a4a77386397873dce66`
- 구현 병합: [PR #93](https://github.com/bluehige/mawangseong-demo/pull/93), 원격 main 반영 완료.
- 결과 문서 브랜치: codex/v127-steam-handoff
- 기존 v1.2.6과 과거 출시 기록은 보존. v1.2.7 태그는 로컬에만 존재한다.

## 2. 목표와 완료 범위
사용자가 Steam에 직접 업로드할 Windows 정식 빌드를 생성하고, 해당 소스가 GitHub main에 반영됐는지 확인했다. GitHub Release 공개와 Steam 업로드는 실행하지 않았다.

## 3. 구현·데이터·스토리·밸런스
검증된 UIUX 개선 내용에 버전 메타데이터만 변경했다. 직전 최종 검증 이후 게임 규칙·비용·보상·대사·저장·이미지·음원은 변경하지 않았다. 현재 캐릭터 그림을 유지하며 방향별 미술은 사용자 승인 후속 작업이다.

## 4. 파일과 산출물
- 업로드 폴더: `builds/steam/windows/v1.2.7/`
- 실행 파일: `MawangCastle.exe`. 같은 폴더의 PCK·라이선스·고지·manifest를 함께 사용한다.
- ZIP: `builds/steam/MawangCastle-v1.2.7-Windows-Steam.zip`, 613918784 bytes.
- ZIP SHA256: `f7748bb73b9dcd4d217d72d739c7c83b3ec39404071e29c1cf9548df8c6bd2c8`
- 사용 안내: `builds/steam/V1.2.7_UPLOAD_README.txt`
- 검증 기록: `tmp/steam_release_v127/final_build_verification.json`
- 빌드·ZIP·캡처는 소스 커밋에 포함하지 않았다.

## 5. 그래픽과 오디오
신규 생성 없음. Steam 전용 프리셋으로 개발 자료를 제외하고 필요한 런타임과 라이선스 고지를 포함했다. 실제 최종 실행 파일의 타이틀을 1920×1080으로 확인했다.

## 6. 검증
- Godot 4.6.3 Windows Steam release export, PCK 금지 경로·라이선스·파일 해시 검사, ZIP 무결성 검사 PASS.
- manifest 버전 1.2.7, source_commit과 로컬 v1.2.7 태그 및 제품 병합 커밋 일치.
- 실제 최종 실행 파일: headless 부팅 exit0, Vulkan 타이틀 렌더 exit0. 두 로그의 ERROR/SCRIPT ERROR 0건. `final_boot.log`, `final_render.log`, `final_title00000029.png`에 증거 보존.
- Steam 검사 도구 8개, manifest 검사 도구 13개, Git LFS fsck PASS.
- [PR 필수 정책](https://github.com/bluehige/mawangseong-demo/actions/runs/34784021845), [main 병합 뒤 정책](https://github.com/bluehige/mawangseong-demo/actions/runs/34784127379) PASS.
- 직전 전체·캠페인 검증은 [통합 QA](UIUX_V2_FINAL_VALIDATION_2026-09-14.md)를 참조한다. 이번 버전 변경 후 전체 게임 회귀·사람 사용성·Steam 실설치를 재실행하지 않았다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 076d706b66f4844137c18a4a77386397873dce66
- Review range: 076d706b66f4844137c18a4a77386397873dce66..076d706b66f4844137c18a4a77386397873dce66
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 제한과 승인 경계
- Steam 업로드·기본 브랜치 활성화는 사용자가 수행할 예정이다.
- 저장소 App ID·Depot ID는 0이며 외부 등록 항목 17개는 PENDING이다. 실제 업로드 환경의 앱·디포 값을 사용해야 한다. 판매 READY로 표시하지 않았다.
- GitHub 태그 push와 약 614MB ZIP을 포함하는 정식 Release 공개는 자동 승인 검토에서 거절됐다. 사용자의 요청이 소스 커밋 확인까지이며 외부 게임 파일 공개에 대한 명시적 승인이 없다는 이유다.
- 따라서 main 소스 반영 완료와 Release 공개 미실행을 구분한다. 우회 실행은 없으며 GitHub 최신 공개 Release는 v1.2.6이다.

## 8. 다음 작업
1. 사용자는 완성된 폴더나 ZIP을 이용해 Steam 업로드를 진행할 수 있다. 저장소 업로드 스크립트를 사용한다면 실제 App ID·Depot ID를 입력한다.
2. 사용자가 명시적으로 승인하면 현재 고정된 v1.2.7 태그와 검증된 ZIP·manifest를 GitHub Release에 공개한다. 기존 태그 이동은 필요 없다.

## 9. 작업 트리와 원격
제품은 PR #93으로 원격 main에 반영했다. 이후에는 핸드오프 문서만 변경했다. 자동 import의 줄바꿈 변경만 원본과 비교해 복구했으며 사용자 변경은 없다. 로컬 main 참조도 원격과 fast-forward로 동기화했다.

## 10. 최종 상태
**Windows Steam 정식 빌드 완료 / GitHub main 소스 반영 확인 완료 / Steam 업로드 미실행 / GitHub 태그·Release 공개 승인 대기.**
