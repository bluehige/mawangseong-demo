# V1.2.2 I1-2 관리 화면 BGM·UI음 대표 검수

- 검수일: 2026-08-02
- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 범위: 관리 화면 대표 렌더, 관리 BGM stream 선택·재생, UI 효과음 연결 여부
- 대표 해상도: `1280×720`
- 변경 원칙: 검수용 임시 캡처·문서만 추가. 런타임 코드·데이터·자산·빌드는 수정하지 않음

## 결과

상태는 `TARGETED_PASS_WITH_UI_SFX_GAP`이다.

- 관리 화면이 `1280×720`에서 정상 렌더링됐다.
- `GameRoot`의 음악 플레이어가 `res://assets/audio/bgm/management_castle_bustle.wav`를 선택하고 재생 중임을 확인했다.
- 관리 UI 계약은 PASS했다.
- `HUDController.gd`에는 전용 UI 클릭·탭 효과음 연결이 없고, `GameRoot.gd`의 오디오 플레이어는 BGM·Update3·전투 효과용이다. 따라서 관리 버튼 UI음은 “있다”고 판정하지 않고, 음원 부족·연결 공백으로 별도 후속 작업에 남겼다.

대표 캡처: [관리 화면 1280×720](../../tmp/v122_release_polish/i1_2_management_audio/i1_2_management_1280x720.png)

기계 결과: [`i1_2_inventory.json`](../../tmp/v122_release_polish/i1_2_management_audio/i1_2_inventory.json)

## 판정 경계

이번 패킷은 관리 BGM의 stream 선택·재생과 UI 효과음 연결 유무만 판정했다. 헤드폰·일반 스피커로 실제 음량·반복 피로를 듣는 OWNER 확인은 하지 않았다. UI 전용 효과음을 이번 패킷에서 새로 생성하거나 연결하지 않았다.

Related tests: `I1ManagementAudioRepresentative` 4 assertions PASS; `V122ManagementUIContractTest` PASS; 정적 UI 오디오 연결 scan 완료.

UI check: 실제 렌더링 `1280×720` 관리 화면 캡처 PASS. 관리 BGM 플레이어 stream·playing 상태 PASS.

Unresolved issues: 관리 UI 전용 클릭·탭 효과음 연결 없음, 헤드폰·일반 스피커 실제 청취와 UI음 체감 OWNER 검수 대기, Q1-R 오디오 manifest·권리 release gate 유지.
