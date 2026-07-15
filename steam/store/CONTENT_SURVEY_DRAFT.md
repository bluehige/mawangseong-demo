# Steam Content Survey 답변 초안

이 문서는 Steamworks 설문에 복사하기 전 빌드와 대조하는 작업지다. 최종 답변은
사용자가 직접 사실 확인하고 제출한다. 설문은 제출·승인 후 임의 수정이 제한될 수
있으므로 추측으로 체크하지 않는다.

## 일반·성인 콘텐츠

| 항목 | 현재 판단 | 제출 전 확인 |
|---|---|---|
| 판타지 폭력 | 있음 | 몬스터와 인간형 침입자의 2D 전투, 마법·무기 공격 |
| 유혈·고어 | 관찰상 없음 | 모든 사망·피격 애니메이션 재확인 |
| 공포 | 경미 | 큐트 호러 판타지, 해골·악마·던전 소재 |
| 성적 콘텐츠·노출 | 관찰상 없음 | 전체 캐릭터·엔딩 이미지 재확인 |
| 약물·음주 | 관찰상 없음 | 대사·아이템 데이터 검색 |
| 도박·확률형 현금 구매 | 없음 | 인앱 구매 자체가 없음 |
| 온라인 상호작용 | 없음 | 싱글 플레이 전용 |
| 사용자 생성 콘텐츠 | 로컬 커스텀 맵만 있음 | 외부 공유·업로드 기능 없음 |

Steam의 일반 콘텐츠 설문 결과로 일부 지역 등급이 생성될 수 있지만, 한국을
포함한 각 판매 지역의 별도 표시·신고 의무가 모두 해결된다고 단정하지 않는다.
App ID 생성 후 Steamworks 지원과 필요한 경우 게임물관리위원회 또는 전문가에게
한국 판매 절차를 확인한다.

## 생성형 AI — 반드시 `사전 생성(Pre-Generated)` 사용으로 신고

### 한국어 답변 초안

개발 과정에서 사전 생성형 AI 도구를 사용했습니다. 프로젝트 전용 프롬프트로
캐릭터, 몬스터, 환경, 타일, VFX, UI 및 엔딩 이미지의 원본을 생성하고 사람이
선택·크롭·투명화·분할·색상 보정하여 게임용 자산으로 제작했습니다. 일부 코드,
데이터 및 문서 작성에도 AI 코딩 보조를 사용했습니다. 출시 빌드는 실행 중
생성형 AI 서비스를 호출하지 않으며 플레이어 입력이나 데이터를 AI 서비스로
전송하지 않습니다. 이미지 원본, 생성 방식, 날짜, 대상 버전과 런타임 파생 경로는
`assets/source/imagegen/**/SOURCE.md`에 보관하고 사람이 최종 결과를 검토합니다.

### English draft

Pre-generated generative AI tools were used during development. Project-specific
prompts produced source artwork for characters, monsters, environments, tiles,
VFX, UI, and ending illustrations. Human-directed selection and post-processing
included cropping, background removal, slicing, and color correction before the
assets were included in the game. AI coding assistance was also used for parts
of the code, data, and documentation. The shipped build does not call a live
generative AI service and does not send player input or player data to any AI
service. Source images, generation method, date, target version, and derived
runtime paths are retained in `assets/source/imagegen/**/SOURCE.md`, and outputs
are reviewed by the developer.

### 권리 확인

- [ ] 모든 출시 이미지가 `SOURCE.md`에 연결되어 있다.
- [ ] 외부 주식 이미지·게임 IP·상표·실존 인물 모방이 없다.
- [ ] 게임명과 로고 상표 검색을 완료했다.
- [ ] 사용한 생성형 AI 서비스 약관상 상업 이용 권리를 확인했다.
- [ ] AI 코드 보조가 제3자 코드를 무단 포함하지 않았는지 라이선스 검토를 마쳤다.

## 개인정보·데이터

게임은 개발자 서버, 광고 SDK, 분석 SDK, 계정 서버를 사용하지 않는다. 진행 저장,
설정, 커스텀 맵과 첫 플레이 관찰 기록은 로컬에만 저장된다. 첫 플레이 관찰에는
이름·자유 입력문이 없고 자동 전송되지 않는다. Steam Cloud에는 진행 저장과
커스텀 맵만 지정하며 관찰 기록과 설정은 제외한다.

이 사실이 바뀌면 출시 전에 개인정보 처리방침과 설문을 모두 갱신한다.
