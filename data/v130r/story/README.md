# V130R 몬스터 대본 — 사용자 확인 대기

0110 대본을 Step11 런타임에 통합했다. 한국어·영어·간체 각930턴이며 본문 문장은 모두 유지했다. 감정511턴과 기존 그림 매핑만 다듬었다.

- 관리 합류20 + 첫 출전20, DAY 관리30, 상황 대사168, 유대72, 합동기16장면.
- 기존 합류 조건과 마지막 대화 후 지급 유지. DAY 오버레이는 원래 관리 앵커 뒤 보유 화자 블록만 재생한다. 블록별 읽음 상태는 기존 story 저장 목록을 재사용한다.
- DAY29는 전투 없는 준비일. 첫 전투 장면·전투 시작은 추가하지 않는다.
- barks는 실제 배치/교전/스킬/HP30%/동료 쓰러짐/승리/굶주림에 연결하고 동일 대사25초 재사용 제한을 둔다. 별도 정지나 입력 차단 없음.
- 유대는 기존 기억 해금 뒤 회상이며 진행/보상을 새로 해금하지 않는다.
- 신규10개는 안정적인 기존 planned_* ID를 실제 기술 ID로 사용한다. data/v130r/duo_links_new.json의 45/1/3/5 해금·게이지·효과에 연결한다. 기존6개 원본 데이터는 그대로다.
- 번역은 cue ID로 연결하며 ko/en/zh_CN 설정을 따른다. 연기/번역 취향은 사용자 확인 대기다.
- 감정 연기 지시는 speaker_registry의 실제 portrait_slots에만 매핑한다. 새 표정 그림을 생성하지 않았다. Claude 제공 지적을 반영했으며 Claude 호출 도구/로컬 명령이 없어 별도 Claude 재검수는 미실행.

정적 검증: `python -X utf8 tools/content/validate_v130r_story.py`
오류 주입: `python -X utf8 -m unittest discover -s tools/content -p test_validate_v130r_story.py`
런타임: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_v130r_step11.ps1 -Mode direct`
화면/난이도: 위 도구의 capture/balance 모드. 기존 사용자 세이브 대신 격리된 APPDATA와 시험 복사본만 사용한다.

인계: docs/handoff/V130R_STEP11_STORY_2026-10-17.md
증거: _mockup/game_step11_story/ (캡처·원자료는 로컬만 보관).
