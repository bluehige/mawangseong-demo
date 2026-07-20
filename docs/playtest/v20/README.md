# 제품 2.0 Phase 11 블라인드 플레이테스트

이 폴더는 DAY 1~5 버티컬 슬라이스의 실제 첫 플레이 판매 가능성 게이트를 재현 가능하게 실행하기 위한 단일 패키지다. 자동 테스트나 개발자 플레이는 실제 사람 6~10명의 결과를 대신하지 않는다.

## 현재 상태

- 판정 상태: `PENDING`
- 실제 참가자: 0명
- 고정 대상 코드: `release/v2.0` merge SHA `4b687aeea80b487f237e6c153dce8600989ec81b`
- Phase 12: 시작 금지. Phase 11이 `GO`일 때만 허용한다.

## 파일

- `BLIND_PLAYTEST_PROTOCOL.md`: 진행자용 순서, 허용 발화, 관찰 규칙
- `PARTICIPANT_FORM.md`: 동의, 사후 질문, 주관 점수 양식
- `PARTICIPANT_RECORD_TEMPLATE.json`: 참가자 1명의 익명 구조
- `RESULTS.json`: 실제 cohort 원본. 현재 참가자를 만들지 않고 빈 배열로 둔다.
- `V20SellabilityGate.gd`: 80%·70%·70% 기준을 계산하는 순수 판정기

## 판정 실행

Godot 4.5.2 console 실행 파일로 다음 scene을 실행한다.

```powershell
& 'C:\Users\LDK-6248\.local\godot45\Godot_v4.5.2-stable_win64_console.exe' --headless --path . 'res://tools/v20/V20SellabilityReport.tscn'
```

`PENDING`은 실패나 성공이 아니라 실제 참가자 부족을 뜻한다. `GO`는 유효한 첫 플레이 6~10명과 세 비율 기준을 모두 만족할 때만 나온다. `NO_GO`면 Phase 12로 진행하지 않고 실패한 관찰 지점으로 돌아간다.

## 개인정보 원칙

- 이름, 이메일, 계정, 음성·영상 파일 경로를 저장소에 넣지 않는다.
- `P01`~`P10` 같은 세션 전용 익명 ID만 기록한다.
- 원문 응답에는 게임 판단에 필요한 문장만 남기고 개인 식별 정보는 즉시 제거한다.
- 녹화가 필요하면 별도 동의를 받고 저장소 밖의 접근 제한 위치에 보관한다.
