# v1.2.6 정식 출시 완료 핸드오프

## 출시 결과

- 상태: `RELEASED`
- 제품 버전: `1.2.6`
- 사용자 표시 버전: `1.2`
- 정식 엔진: `4.6.3.stable.official.7d41c59c4`
- main merge SHA: `1f36c8a775b471c4dbc7c7714f85f33efb00876d`
- PR: <https://github.com/bluehige/mawangseong-demo/pull/91>
- annotated tag: `v1.2.6` → `1f36c8a775b471c4dbc7c7714f85f33efb00876d`
- Release: <https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.6>

## 공개 자산

- `MawangCastle-v1.2.6-Windows.zip`: 320,360,242 bytes
- ZIP SHA-256: `1dff6f381ec188da256219f04efaaffab958fc09d002ed00f142664fd1146588`
- `SHA256SUMS.txt`: 98 bytes
- ZIP 내용: `MawangCastle.exe`, `MawangCastle.pck`, `steam-build-manifest.json`, 제3자 고지와 폰트 라이선스
- EXE: File/Product version `1.2.6.0`, `IsDebug=False`

## 검증 근거

- Godot 4.6.3 핵심 표적 검수 SHA: `ab817105bc56869cedae18a3acd7d115f3372996`
- main merge tree는 최종 후보 tree와 동일했다.
- 명령·AI·방 지침·건설·기본 통합·릴리스 준비 테스트 6종: PASS
- DAY 02 시각 캡처: 1920×1080·1280×720 이름표, 건설 배지, 지침 배지, 시설 목록·미리보기 PASS
- Python Steam validator: 8/8 PASS
- Python build-manifest validator: 13/13 PASS
- main SHA 로컬 Windows export manifest·부팅: PASS
- 태그 CI: <https://github.com/bluehige/mawangseong-demo/actions/runs/32353965901> — LFS, official Godot 4.6.3, export, manifest, 부팅, immutable artifact PASS

## 범위 경계

- Full verification: `NOT_RUN` — 최신 사용자 지시로 대체
- DAY 1~30 8인 역할 검수: `NOT_RUN` — 최신 사용자 지시로 대체
- Web·모바일 정식 판정: `NOT_RUN` — PC 정식판 뒤 별도 테스트 범위
- Steam App/Depot ID와 상점·법무·Coming Soon 등 외부 17개 항목은 GitHub Windows Release를 막지 않으며 실제 Valve 제출 전 `--strict` 게이트로 남는다.
- 사용자와 지인의 플레이테스트는 완성품 전달 뒤 새 피드백 주기로 접수한다.

## 최종 판정

- 출시 범위 P1/P2: 0
- Godot 4.6.3 Windows v1.2.6: PASS
- GitHub main·tag·Release 등록: COMPLETE

## 정책 필드

- Review task ID: V126-GODOT-463-RELEASE-COMPLETE
- Reviewed SHA: bff6fdfa7910227ed1e6b301351dd3b5f95fc032
- Review range: 1f36c8a775b471c4dbc7c7714f85f33efb00876d..bff6fdfa7910227ed1e6b301351dd3b5f95fc032
- Remaining P1/P2: 0
- Final review result: PASS
