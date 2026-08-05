# V1.2.2 출시 마무리 I1-2 핸드오프 — 관리 화면 BGM·UI음

- 목표 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 패킷은 커밋하지 않음)
- 상태: `TARGETED_PASS_WITH_UI_SFX_GAP`

## 완료한 내용

- `1280×720` 관리 화면 대표 캡처를 생성했다.
- 관리 화면에서 `management_castle_bustle.wav` stream이 선택되고 재생 중인지 4 assertions로 확인했다.
- 정적 코드 확인으로 전용 관리 UI 클릭·탭 효과음 hook이 없음을 분리했다. 이는 BGM 실패가 아니라 UI음 자산·연결 공백이다.
- 검수 중 발생하던 테스트용 자동 저장 경고가 캡처에 들어오지 않도록 임시 검수에서 저장을 비활성화했다. 제품 저장 코드는 바꾸지 않았다.
- 런타임 코드·데이터·자산·빌드는 수정하지 않았다.

## 변경 파일

- 추가: `docs/qa/V122_I1_2_MANAGEMENT_AUDIO_REPRESENTATIVE_2026-08-02.md`
- 추가: `docs/handoff/V122_RELEASE_POLISH_I1_2_MANAGEMENT_AUDIO_REPRESENTATIVE_2026-08-02.md`
- 임시·무추적: `tmp/v122_release_polish/i1_2_management_audio/I1ManagementAudioRepresentative.gd`, `.tscn`, 캡처 PNG, 인벤토리 JSON, 실행 로그

## 다음 작업

1. I1-3 DAY 3 도둑 침입·집중 명령·도둑 사냥꾼 특성·혼잡 타격 대표 검수
2. UI 전용 효과음은 새 음원을 바로 만들지 말고 Q1-R manifest/권리 정리 후 별도 A1 패킷으로 처리
3. 실제 청취 OWNER 검수 전에는 I1 전체를 완료로 표시하지 않음

## 검수와 미해결

Related tests: `I1ManagementAudioRepresentative` 4 assertions PASS; `V122ManagementUIContractTest` PASS; 정적 UI 오디오 연결 scan 완료.

UI check: 관리 화면을 실제 `1280×720`으로 캡처했고, BGM stream 선택·재생 상태 PASS.

Unresolved issues: 관리 UI 전용 클릭·탭 효과음 연결 없음, 실제 청취 OWNER 대기, Q1-R 오디오 manifest·출처 release gate 유지.

## 작업 트리와 원격

- 기존 사용자 변경 `.import` 6개와 `.uid` 7개를 건드리지 않았다.
- I1-2 문서와 계획/CURRENT 갱신은 아직 커밋하지 않았다.
- 원격 푸시는 하지 않았다.
