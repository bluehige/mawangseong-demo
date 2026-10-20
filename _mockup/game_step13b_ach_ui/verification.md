# Step13B 도전과제 UI 표적 검증

- 결과: TARGETED_PASS / 사용자 확인 대기
- Godot 4.6.3, OpenGL 호환 렌더러, 실제 시작 메뉴 진입.
- 논리 UI 1920×1080, 실제 렌더/공유 PNG 1280×720. 해상도 확대 검수는 실행하지 않음.
- 124검사, 실패 0; 3언어×8세트=24조합에서 모든 카드/탭 글자 넘침 0.
- 잠금 225픽셀: 채도 0, 원본 명도×35% 기준 최대 오차 0.003411. 배지 영역은 제외하고 실제 화면 변환 좌표로 비교.
- 세트 진행도, 27/50 진행바, 완료 진행바/날짜 동시 표시, 해제 날짜 2026-10-18, 숨김 7개 제목/아이콘/진행도 은폐, 해제 시 복원, 언어 변경 시 세트 유지, ESC 닫기, 인메모리 프로필 불변 확인.
- APPDATA/LOCALAPPDATA는 tmp/v130r_step13b 아래로 격리, MAWANG_DISABLE_STEAM=1. 사용자 세이브를 읽거나 수정하지 않음.
- 새 물음표 원본 RGBA 1265×1244, alpha 0..255, 완전 투명 픽셀 72.49%. 네이티브 투명, 배경 제거 없음.
- 전체 회귀/전체 플레이/별도 검수 에이전트/export: NOT_REQUESTED, 미실행.
- 최초 실행의 테스트 타입 추론 오류, 로컬 문구 인코딩, 간체 탭 높이를 수정한 후 최종 재검사 완료. GPU 검사는 창 좌표 변환 및 배지 제외를 바로잡음.

| 이미지 | 확인 내용 |
|---|---|
| [menu_ko.png](menu_ko.png) | 한국어·8세트·해제 날짜 |
| [menu_en.png](menu_en.png) | 영어 글자 넘침 |
| [menu_zh.png](menu_zh.png) | 간체 글자 넘침 |
| [locked_vs_unlocked.png](locked_vs_unlocked.png) | 컬러 해제·어두운 원본+배지·27/50 |
| [hidden.png](hidden.png) | ???·GPT 물음표·조건 은폐 |

재현: `./tools/run_v130r_step13b.ps1 -Mode import`, `./tools/run_v130r_step13b.ps1 -Mode capture`.
원시 검사 결과: [checks.json](checks.json).
