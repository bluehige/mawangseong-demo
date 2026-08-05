# V1.2.2 I1-1 타이틀·설정 대표 검수

- 검수일: 2026-08-02
- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 범위: 타이틀 진입, 설정 화면 진입, 화면·오디오 설정 카테고리, 대표 해상도 `1280×720`
- 변경 원칙: 검수용 임시 캡처·문서만 추가. 런타임 코드·데이터·자산·빌드는 수정하지 않음

## 결과

`I1-1`은 `TARGETED_PASS_WITH_OWNER_LISTENING_PENDING`이다.

- 타이틀이 초기 화면으로 열리는지 PASS
- 타이틀에서 설정 화면으로 이동하는지 PASS
- 설정 화면이 화면 카테고리로 열리는지 PASS
- 오디오 카테고리 전환이 가능한지 PASS
- 1280×720 타이틀·화면 설정·오디오 설정 캡처 3장 생성, 모두 `1280×720`
- 현지화 카탈로그 42 assertions와 관리 UI 계약은 PASS

캡처는 아래 파일에서 확인할 수 있다.

- [타이틀](../../tmp/v122_release_polish/i1_1_title_settings/i1_1_title_1280x720.png)
- [화면 설정](../../tmp/v122_release_polish/i1_1_title_settings/i1_1_settings_display_1280x720.png)
- [오디오 설정](../../tmp/v122_release_polish/i1_1_title_settings/i1_1_settings_audio_1280x720.png)

기계 결과는 [`i1_1_inventory.json`](../../tmp/v122_release_polish/i1_1_title_settings/i1_1_inventory.json)에 고정했다.

## 판정 경계

이번 검수는 화면 구조와 설정 진입 계약을 확인한 것이다. 캡처 환경은 실제 Windows 후보와 같은 그래픽 장치를 사용했지만, 헤드폰·일반 스피커로 타이틀 진입과 설정 조작을 청취하는 OWNER 확인은 아직 하지 않았다. 이 결과만으로 BGM 음질·음량·반복 피로를 PASS로 판정하지 않는다.

Related tests: `I1TitleSettingsRepresentative` 4 assertions PASS; `V122Stage10LocalizationTest` 42 assertions PASS; `V122ManagementUIContractTest` PASS.

UI check: 실제 렌더링 `1280×720`에서 타이틀·설정 화면·오디오 설정 캡처 3장 PASS.

Unresolved issues: 헤드폰·일반 스피커 실제 청취, 실제 Windows 후보에서 버튼·최장 문구·음량 체감 OWNER 확인.
