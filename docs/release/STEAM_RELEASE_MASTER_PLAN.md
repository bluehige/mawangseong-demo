# Steam 판매 출시 마스터 플랜

작성일: 2026-07-15
대상: `마왕님, 마왕성은 누가 지켜요?` Windows 유료 정식판
현재 판정: **기술 기반 세팅 중 / 외부 등록 정보 대기**

## 판매 가능 상태의 정의

다음 다섯 게이트가 모두 끝나야 `판매 가능`이다.

1. **사업자 게이트**: Steamworks 계약, 본인·법인, 은행, 세금 확인과 앱 등록비
2. **권리 게이트**: 게임명·로고·코드·폰트·음악·GPT 생성 자산의 상업 권리 확인
3. **스토어 게이트**: 설명, 캡슐, 실제 플레이 스크린샷, 콘텐츠·AI 설문과 가격
4. **빌드 게이트**: 태그 기반 Windows 빌드, SteamPipe 설치·실행·저장·삭제 검수
5. **출시 게이트**: Valve 스토어·빌드 승인, 공개 예정 14일, 출시일 운영 준비

## 현재 선택한 최소 판매 구조

- Windows 64-bit 단일 플랫폼으로 시작한다.
- 최종 상품은 Full Release이며, 그 전 공개 예정 페이지와 별도 Steam Demo를 쓴다.
- 런타임 Steamworks 플러그인은 넣지 않는다. 업로드에는 공식 SDK를 사용하고
  저장은 코드 변경 없는 Steam Auto-Cloud로 동기화한다.
- 출시 언어는 현재 구현된 한국어만 정확히 표시한다. 영문 상점 페이지와 영문
  지원 표시는 게임 내 현지화가 끝난 뒤 추가한다.
- 도전 과제, 컨트롤러, Steam Deck 인증, 트레이딩 카드 등 미구현 기능은 약속하지
  않는다.

## 저장소에서 완료한 기반

- `Windows Steam` 전용 Godot export preset
- 버전 태그와 프로젝트 버전 일치 검사, Windows depot 빌드 스크립트
- 전용 빌드 계정을 사용하는 SteamPipe VDF 생성·업로드 스크립트
- 비밀번호·Steam Guard 코드를 명령행이나 Git에 남기지 않는 흐름
- Steam 필수 그래픽 치수와 실제 플레이 스크린샷 자동 검사
- App ID, 권리, 콘텐츠 설문, 리뷰, 공개 예정 기간을 막는 엄격 출시 게이트
- Steam Auto-Cloud 경로와 동기화 대상 고정
- Godot·Noto Sans CJK·NEXON MapleStory 폰트 고지의 depot 포함
- 태그 푸시에서 Windows artifact를 생성하는 GitHub Actions

## 일정 역산

| 시점 | 완료 조건 |
|---|---|
| 지금 | Steamworks 가입, 계약 주체 결정, $100 앱 등록비, 세금·은행 확인 시작 |
| 출시 8주+ 전 | App ID 생성, 상표·권리 확인, Coming Soon 스토어 제작 |
| 출시 6주+ 전 | 스토어 심사 제출, Demo 또는 Playtest, 위시리스트 수집 |
| 출시 3주+ 전 | 거의 최종인 Steam 빌드 업로드, 설치·저장·저사양 검수 |
| 출시 2주+ 전 | Coming Soon 최소 14일 충족, 가격·출시일·지원 체계 확정 |
| 출시 7영업일+ 전 | 스토어와 빌드 Valve 승인 여유 확보 |
| 출시일 | 승인된 Default 빌드 확인 후 직접 Release App 실행 |

첫 몇 개 타이틀은 앱 등록비 결제와 출시 사이에 30일 대기 기간이 있다. 세금 정보
검증에도 통상 2~7영업일이 걸릴 수 있으므로 계정 등록을 가장 먼저 한다.

## 출시 직전 명령

```powershell
python tools/release/validate_steam_release.py --strict `
  --build-dir builds/steam/windows/v1.0.0
```

이 명령이 실패하면 출시 버튼을 누르지 않는다. 실패 메시지의 App ID, 그래픽,
권리, 연락처, 리뷰, 공개 예정 기간 또는 Steam 설치 검수 항목을 먼저 해결한다.

## 공식 기준 링크

- Steamworks 등록과 30일/2주 일정: https://partner.steamgames.com/doc/gettingstarted/onboarding
- 앱당 $100 등록비: https://partner.steamgames.com/doc/gettingstarted/appfee
- 콘텐츠 및 생성형 AI 설문: https://partner.steamgames.com/doc/gettingstarted/contentsurvey
- 출시·리뷰 절차: https://partner.steamgames.com/doc/store/releasing
- 스토어/빌드 심사: https://partner.steamgames.com/doc/store/review_process
- 그래픽 치수와 규칙: https://partner.steamgames.com/doc/store/assets
- SteamPipe 업로드: https://partner.steamgames.com/doc/sdk/uploading
- Steam Auto-Cloud: https://partner.steamgames.com/doc/features/cloud
- 가격: https://partner.steamgames.com/doc/store/pricing
- Demo: https://partner.steamgames.com/doc/store/application/demos

이 계획은 법률·세무 자문이 아니다. 계약 주체, 한국 사업·세금·등급 의무는 실제
상황을 아는 전문가와 Steamworks/관할 기관의 최신 안내로 최종 확인한다.
