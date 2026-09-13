# v1.2.7 GitHub 정식 출시 완료

## 1. 메타데이터
- 작성일: 2026-09-14
- 제품 버전: 1.2.7, 화면 표시 1.2, Windows 파일·제품 버전 1.2.7.0.
- 제품 소스·불변 태그: `v1.2.7@076d706b66f4844137c18a4a77386397873dce66`
- 제품 통합: [PR #93](https://github.com/bluehige/mawangseong-demo/pull/93). 기존 빌드 기록: [PR #94](https://github.com/bluehige/mawangseong-demo/pull/94).
- 문서 기준 main: `89fde6497c334a3268bc6a2f396f1063088f33c3`, 작업 브랜치 codex/v127-release-complete.
- [정식 Release](https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.7), 공개 시각 2026-09-13T21:59:19Z (UTC).

## 2. 목표와 승인
사용자가 v1.2.7 태그와 검증된 약614MB ZIP의 정식 GitHub Release 공개 질문에 **“승인”**으로 답했다. 이전 자동 승인 검토 거절 이후 받은 명시적 승인으로 공개했다. Steam 업로드·판매 활성화는 이번 승인의 대상이 아니며 실행하지 않았다.

## 3. 구현·데이터·스토리·밸런스
이미 검증한 동일 제품 파일을 공개했다. 추가 게임 코드·데이터·이미지·음원·저장 변경과 기존 태그 이동은 없다. 현재 캐릭터 그림은 유지하고 방향별 미술은 후속이다.

## 4. 공개 산출물
- [final_build_verification.json](https://github.com/bluehige/mawangseong-demo/releases/download/v1.2.7/final_build_verification.json): 1339 bytes, `sha256:caff7d87d509a9718a0db55a74e2ad92fc6064769c152d421522f1c270fcd3da`.
- [MawangCastle-v1.2.7-Windows-Steam.zip](https://github.com/bluehige/mawangseong-demo/releases/download/v1.2.7/MawangCastle-v1.2.7-Windows-Steam.zip): 613918784 bytes, `sha256:f7748bb73b9dcd4d217d72d739c7c83b3ec39404071e29c1cf9548df8c6bd2c8`.
- [SHA256SUMS-v1.2.7.txt](https://github.com/bluehige/mawangseong-demo/releases/download/v1.2.7/SHA256SUMS-v1.2.7.txt): 105 bytes, `sha256:9cc56b9ac1ebb89a16c8eb28458c120bbc32f10279162b75a9e82822b68e5d1f`.
- [steam-build-manifest.json](https://github.com/bluehige/mawangseong-demo/releases/download/v1.2.7/steam-build-manifest.json): 1091 bytes, `sha256:b6eda2f5d5ee2b7bd6737f81e033aa6bad56aa9a0ebd97ba80bf44841f58f8df`.

로컬 업로드 폴더는 `builds/steam/windows/v1.2.7/`, ZIP은 `builds/steam/MawangCastle-v1.2.7-Windows-Steam.zip`이다. 바이너리는 Release에만 올렸으며 소스 브랜치에 커밋하지 않았다.

## 5. 그래픽·오디오
새로운 자산 제작·변경 없음. 승인된 기존 게임 자산과 라이선스 고지를 포함한 Windows Steam 빌드를 그대로 공개했다.

## 6. 검증
- 공개 Release는 draft=false, prerelease=false, latest로 등록했다.
- GitHub 서버의 업로드 파일4개 크기·SHA256이 로컬 최종 파일과 모두 일치한다.
- 공개 manifest를 실제 다운로드해 로컬 manifest와 바이트 단위로 비교했다. version=1.2.7, source_commit=076d706b66f4844137c18a4a77386397873dce66.
- 원격 annotated tag 객체가 로컬 태그 객체와 일치한다. 태그가 가리키는 제품 커밋은 main에 포함돼 있으며 이후 차이는 핸드오프 문서뿐이다.
- 기존 Windows Steam export·PCK·라이선스·해시·실제 부팅·타이틀 검증은 [빌드 완료 기록](V127_STEAM_BUILD_READY_2026-09-14.md)에 보존했다. 변경 없는 게임의 전체 검사를 다시 실행하지 않았다.
- [태그 자동 Windows 빌드](https://github.com/bluehige/mawangseong-demo/actions/runs/34785386951)는 **SUCCESS**. GitHub Windows 새 환경에서 태그 체크아웃·LFS·공식 엔진 다운로드·Steam export·실행 검사·artifact 업로드까지 통과했다. 로컬 Release ZIP과 같은 제품 소스에서 별도로 생성한 빌드다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 89fde6497c334a3268bc6a2f396f1063088f33c3
- Review range: 89fde6497c334a3268bc6a2f396f1063088f33c3..89fde6497c334a3268bc6a2f396f1063088f33c3
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 제한
Steam 실제 업로드·설치·클라우드·Valve 심사·판매 활성화는 수행하지 않았다. 저장소 App ID·Depot ID와 외부 등록 항목은 임의로 완료 처리하지 않았다. Web는 이번에 재배포하지 않아 기존v1.2.6 공개본을 유지한다.

## 8. 다음 작업
사용자가 ZIP을 풀고 전체 폴더를 Steam ContentRoot로 사용한다. 실행 파일은 MawangCastle.exe이며 PCK와 라이선스를 함께 업로드한다. 실제 Steamworks App ID·Depot ID를 사용한다.

## 9. 작업 트리와 원격
v1.2.7 태그와 Release 자산 공개 완료. 이후 변경은 본 핸드오프와 CURRENT뿐이다. 이전v1.2.6 및 과거 출시 기록 보존.

## 10. 판정
**v1.2.7 Windows Steam 빌드·GitHub 소스 반영·불변 태그·정식 Release 공개 완료. Steam 업로드는 사용자 수행.**
