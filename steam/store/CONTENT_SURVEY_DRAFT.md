# Steam v1.2.7 Content Survey 제출 작업지

> 2026-09-21 최신 상태: 아래 9월14일의 미제출 기록은 과거 이력이다. 현재 콘텐츠 설문과 한·영 AI 고지가 등록돼 상점 체크리스트가 완료됐고 Valve 심사 중이다. 사용자 직접 한국 등급 등록 후 KGRB 12 선택 저장도 확인했다. Steam Auto-Cloud 6개 경로는 개발자 테스트 모드로 게시했다. 최신 상태는 docs/handoff/V128_KOREA_RELEASE_2026-09-21.md를 따른다.

확인일: 2026-09-14. 제품 SHA: 076d706b66f4844137c18a4a77386397873dce66.
상태: DRAFT_ONLY / SAVE_REJECTED_BY_AUTO_REVIEW. 등급 생성·게시 완료 아님.

사용자는 출시 처리를 위임했다. 단, 실제 저장은 자동 승인 검토에서 폭력·범죄·욕설 및 AI 사용 범위의 검증과 구체적 신고 승인 부족으로 거절됐다. 다른 방식으로 우회하지 않는다. 현재 브라우저 입력 상태와 제출 상태를 구분한다.

## 작성한 선택지와 근거

| 선택지 | 근거 / 한계 |
|---|---|
| 만화적·판타지 폭력 | 실제 몬스터/인간형 적 전투와 무기·마법 공격, STOVE 기존 폭력성 분류 |
| 유혈 없는 싸움·무기·뼈/해골·고통·경멸적 언어 | 전투 및 던전 소재를 보고 작성한 초안. 세부 표현의 모든 장면 대조 완료를 뜻하지 않음 |
| 범죄 행위 묘사 | scripts/game/CombatSceneController.gd의 도둑 약탈 경로와 금화 차감, 약탈 후 도주 |
| 어둡고 비현실적인 공포 배경 | 악마·해골·미궁의 판타지 환경 |
| 가벼운 욕설 | data/story/v122_main/day_30.json의 '젠장…' |
| 사전 생성 AI 사용 | assets/source/imagegen 및 assets/source/audio/lyria 아래 출처 문서. 스토리/번역 작성에도 AI 보조 사용 |

선정된 없음 답변은 새 전체 회귀·전체 자산 법률 검토 통과를 의미하지 않는다. 확인되지 않은 권리 보장이나 법적 확약을 임의 제출하지 않는다.

## 사전 생성 AI (Pre-Generated) 공개 설명

출처 기록: `assets/source/imagegen/**/SOURCE.md`, `assets/source/audio/lyria/**/SOURCE.md`.

### English

Pre-generated AI tools assisted the creation of artwork, music and sound effects, and portions of narrative and localization text. Artwork includes characters, monsters, environments, UI, ending illustrations and store promotional images. The assets and text were selected and integrated during development. The game does not generate AI content during gameplay and does not connect to external AI services or send player input to them.

### 한국어

개발 과정에서 사전 생성형 AI 도구로 미술, 음악·효과음과 일부 스토리·번역 문구를 제작했습니다. 미술에는 캐릭터, 몬스터, 배경, UI, 엔딩 일러스트와 상점 홍보 이미지가 포함됩니다. 제작된 자산과 문구를 선택하여 게임에 연결했습니다. 게임 실행 중 AI 콘텐츠를 생성하거나 외부 AI 서비스에 접속하지 않으며, 플레이어 입력을 AI 서비스로 전송하지 않습니다.

이전 초안에서 누락됐던 AI 음악·효과음과 서사·현지화 범위를 보완했다. 실행 중 AI 생성 없음, 외부 AI 서비스 연결 없음으로 작성했다.

## 저장·개인정보와 별도 출시 절차

진행/설정은 로컬 저장이다. 2026-09-21 Steam Auto-Cloud에 캠페인 저장5종과 성 배치 파일의 정확한 경로6개, 10 MiB/50파일을 등록·게시했다. 개발자 테스트 모드를 유지하며 두PC 동기화 검증 전에는 상점 지원 기능으로 표시하지 않는다. settings.cfg, 임시·백업·관찰 로그 파일은 동기화 대상에 포함하지 않았다.
2026-09-21 사용자 제공 게임물관리위원회 원본 공문을 텍스트·페이지 렌더로 확인했다. Valve/Steam 신규 유통 통보는 정상 접수됐으며, 통보 내용대로 운영 가능하다는 회신이다. STOVE 12세 이용가·폭력성(SGHS-SP-260821-0002)을 한·영 Steam 상점 본문에 표시하고 BETA 재조회했다. 이후 사용자가 직접 Steam Ratings 등록을 완료했고, 에이전트는 저장 성공 화면에서 KGRB 체크와 12 선택값을 확인했다. 설명에는 STOVE 등급을 근거로 게임위 유통 통보를 확인받았다는 사용자 입력 문구가 저장돼 있다. 사용자가 지원 문의 전송을 원하지 않아 초안만 로컬 보관했다. 상세 상태와 남은 공개 조건은 docs/handoff/V128_KOREA_RELEASE_2026-09-21.md를 따른다. 원본 공문과 개인 정보는 공개 저장소에 포함하지 않는다.

공식 안내: https://partner.steamgames.com/doc/gettingstarted/contentsurvey
