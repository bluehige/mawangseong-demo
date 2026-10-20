# 감정 재지정 — 사용자 확인 대기

Claude 호출 도구가 없어 Claude 재검수는 미실행. 제공된 지적을 반영한 문맥·성격별 수정이다. 세 언어 본문 930턴씩 보존. 새로운 표정 그림은 만들지 않았다.

| 화자 | 이전 담담 | 이후 담담 | 최종 감정 집계 |
|---|---:|---:|---|
| 골딘 | 0 | 0 | 당황 1, 계산 49, 진땀 1 |
| 퐁당 | 16 | 0 | 무표정 11, 단호 5, 결심 4, 당황 1, 기쁨 4, 시무룩 1 |
| 마왕 | 128 | 0 | 발끈 1, 허세 54, 감동 1, 복잡 1, 결심 9, 흠칫 1, 흡족 1, 감탄 1, 당황 3, 오싹 1, 다정 81, 기쁨 1, 억울 1 |
| 바티 | 0 | 0 | 건조 63, 확인 2, 기록 1, 냉정 6 |
| 느릿 | 15 | 0 | 숨참 1, 속삭임 8, 기쁨 5, 결심 7, 당황 1, 시무룩 1, 미소 1 |
| 핀 | 15 | 0 | 자신만만 6, 결심 6, 당황 1, 기쁨 4, 시무룩 1, 미소 3 |
| 벙벙 | 15 | 0 | 간절 4, 울먹 10, 기쁨 5, 결심 3, 당황 1, 시무룩 1, 감동 1 |
| 쉿 | 15 | 0 | 속삭임 14, 시무룩 1, 기쁨 5, 결심 3, 수줍음 2 |
| 텅텅 | 15 | 0 | 정의감 8, 당황 7, 기쁨 5, 결심 3, 단호 2 |
| 셀렌 | 0 | 0 | 엄숙 1 |
| 녹녹 | 15 | 0 | 발끈 1, 비명 6, 겁 9, 기쁨 6, 결심 3 |
| 곱 | 14 | 0 | 자랑 1, 씩 6, 결심 2, 당황 1, 자신만만 4, 기쁨 4, 시무룩 1, 흡족 2 |
| 파파 | 15 | 0 | 단호 4, 씩 1, 확인 9, 결심 4, 당황 1, 기쁨 4, 시무룩 1, 자랑 1 |
| 밀로 | 0 | 0 | 당황 1 |
| 꼬깃 | 17 | 0 | 자신만만 12, 기쁨 5, 결심 2, 당황 4, 시무룩 1, 자랑 1 |
| 로로 | 9 | 0 | 결심 5, 확인 4, 당황 1, 기쁨 4, 시무룩 1, 미소 1 |
| 찍찍단 | 14 | 0 | 합창 10, 기쁨 6, 결심 3, 당황 1, 단호 3, 시무룩 1, 흡족 1 |
| 니아 | 0 | 0 | 질겁 1 |
| 누비 | 16 | 0 | 미소 2, 무심 10, 기쁨 5, 결심 2, 당황 1, 간절 3, 시무룩 1 |
| 실키 | 22 | 0 | 무심 1, 다정 11, 단호 5, 결심 4, 당황 1, 기쁨 1, 시무룩 1, 미소 4 |
| 모리 | 16 | 0 | 다정 8, 결심 8, 당황 1, 기쁨 4, 시무룩 1, 미소 1 |
| 푸딩 | 10 | 0 | 기쁨 12, 결심 4, 당황 1, 시무룩 1 |
| 돌콩 | 18 | 0 | 엄숙 10, 결심 4, 단호 4, 당황 1, 기쁨 4, 시무룩 1, 감동 2 |
| 두둠 | 16 | 0 | 기쁨 7, 자랑 10, 결심 7, 당황 1, 시무룩 1 |
| 루미 | 18 | 0 | 속삭임 11, 결심 4, 당황 1, 단호 3, 기쁨 4, 시무룩 1, 미소 2 |
| 미미 | 18 | 0 | 자신만만 11, 결심 3, 당황 4, 기쁨 6, 시무룩 1 |
| 베베 | 17 | 0 | 다정 12, 결심 3, 당황 1, 단호 2, 기쁨 4, 시무룩 1, 미소 1 |
| 코코 | 17 | 0 | 확인 10, 결심 7, 당황 1, 기쁨 5, 시무룩 1 |
| 톡톡 | 19 | 0 | 확인 11, 결심 4, 당황 1, 단호 4, 기쁨 4, 시무룩 1, 흡족 2 |
| 포포 | 15 | 0 | 기쁨 6, 자랑 8, 결심 3, 자신만만 3, 당황 1, 시무룩 1 |
| 내레이션 | 72 | 72 | 담담 72 |

감정 변경 511턴. 마왕 허세→proud·당황→flustered·억울→offended·결심→serious, 바티 건조→dry·냉정→stern. 골딘은 accounting 외 별도 당황 그림이 없어 base를 사용한다.

| 대사 ID | 화자 | 이전 | 이후 | 실제 초상화 슬롯 | 본문(보존) |
|---|---|---|---|---|---|
| V130R_JOIN_RIVER_FROG_008 | 퐁당 | 담담 | 무표정 | base | 그럼 망토 끝부터 빼 주세요. 지금 제 거실을 닦고 계신데요. |
| V130R_JOIN_GLUE_SNAIL_005 | 느릿 | 담담 | 속삭임 | base | 집은… 있는데… 돌아올… 곳이… 없어서요… |
| V130R_FIRST_COMBAT_GLUE_SNAIL_002 | 핀 | 담담 | 자신만만 | base | 알았어. 네가 깔고 내가 데울게. 집까지 굽진 않고. |
| V130R_JOIN_BRIDGE_TROLL_005 | 벙벙 | 담담 | 울먹 | base | 근무지를 잃으면 이름도 필요 없어지는 줄 알았어요. |
| V130R_JOIN_UNDER_BED_SHADOW_006 | 쉿 | 담담 | 속삭임 | base | 그럼… 제 자리도… 등 뒤에 있나요? |
| V130R_JOIN_UNDER_BED_SHADOW_007 | 마왕 | 담담 | 허세 | proud | 앞이든 뒤든 네 자리는 있다. 내 찻잔 바로 밑만 피해라. |
| V130R_JOIN_HOLLOW_ARMOR_005 | 텅텅 | 담담 | 당황 | base | 레온이 보면… 빈 갑옷이 용사 흉내 낸다고 하겠지요. |
| V130R_JOIN_CANDLE_WISP_005 | 마왕 | 담담 | 허세 | proud | 이백 년 경력이면 나보다 선임 아닌가? |
| V130R_JOIN_CANDLE_WISP_006 | 녹녹 | 담담 | 겁 | base | 선임이면 지붕부터 주세요! 저 물방울 방금 저 봤어요! |
| V130R_JOIN_MOLE_DIGGER_005 | 파파 | 담담 | 확인 | base | 붕괴 때 왕국 동료들은 제 이름을 못 들은 척했죠. |
| V130R_JOIN_MOLE_DIGGER_006 | 곱 | 담담 | 씩 | base | 곱은 들었다! 소리 나는 데 팠다! |
| V130R_JOIN_MOLE_DIGGER_008 | 마왕 | 담담 | 허세 | proud | 좋다. 우리 성의 첫 안전 수칙은 곱도 무사히 돌아오기다. |
| V130R_FIRST_COMBAT_MOLE_DIGGER_002 | 곱 | 담담 | 씩 | base | 알았다! 땅 때리기 전에 옆에 누가 있나 본다! |
| V130R_JOIN_CRUMPLED_MAP_005 | 꼬깃 | 담담 | 자신만만 | happy | 내가 틀린 게 아니라 동굴이 자꾸 접히는 거야! |
| V130R_FIRST_COMBAT_CRUMPLED_MAP_001 | 꼬깃 | 담담 | 자신만만 | happy | 밀로가 또 오면 오른쪽으로 보낼게! 내 오른쪽이 어느 쪽이지? |
| V130R_JOIN_CURSE_DOLL_005 | 누비 | 담담 | 무심 | base | 엄마, 나 이제 버려지는 쪽 말고 기다리는 쪽 해도 돼? |
| V130R_JOIN_CURSE_DOLL_006 | 실키 | 담담 | 다정 | base | 응. 다만 현관 한가운데 앉지는 마. 손님이 돌아가. |
| V130R_FIRST_COMBAT_CURSE_DOLL_001 | 누비 | 담담 | 무심 | base | 니아한테도 너무 아픈 저주는 안 할게. 여기까지 데려다줬으니까. |
| V130R_FIRST_COMBAT_CURSE_DOLL_002 | 마왕 | 담담 | 허세 | proud | 마음은 따뜻한데 내 등은 왜 서늘하지? |
| V130R_JOIN_SPORE_HEALER_002 | 모리 | 담담 | 다정 | base | 천장도 많이 아파 보이는데. 물을 자꾸 흘리네. |
| V130R_JOIN_SPORE_HEALER_004 | 모리 | 담담 | 다정 | base | 그럼 위엄 옆에 버섯을 심어도 될까? 습한 게 좋아서. |
| V130R_JOIN_SPORE_HEALER_006 | 모리 | 담담 | 다정 | base | 먹는 건 나중에. 다친 애들부터 편히 눕히자. |
| V130R_JOIN_STONE_SENTINEL_001 | 마왕 | 담담 | 허세 | proud | 입구에 새 바위가 생겼다. 누가 허가했지? |
| V130R_JOIN_STONE_SENTINEL_002 | 돌콩 | 담담 | 엄숙 | base | 굴러왔다. 콩. |
| V130R_JOIN_STONE_SENTINEL_004 | 마왕 | 담담 | 허세 | proud | 입구를 조금만 비켜 줄 수 있나? |
| V130R_JOIN_STONE_SENTINEL_007 | 마왕 | 담담 | 다정 | base | 그럼 네 옆에 식구가 지날 길은 남겨 두자. |
| V130R_JOIN_STONE_SENTINEL_008 | 돌콩 | 담담 | 엄숙 | base | 그 길은 막지 않는다. 콩. |
| V130R_JOIN_WAR_DRUMMER_006 | 두둠 | 담담 | 자랑 | happy | 밥 먹고 치면 더 힘나긴 하는데. 둥? |
| V130R_JOIN_WAR_DRUMMER_007 | 마왕 | 담담 | 다정 | base | 식구에게 박자를 맞춰라. 내 허세보다 느려도 좋다. |
| V130R_JOIN_MOON_TRACKER_001 | 루미 | 담담 | 속삭임 | base | 감시탑 자리 확인했어. 그런데 여기선 달이 안 보여. |
| V130R_JOIN_MOON_TRACKER_004 | 루미 | 담담 | 속삭임 | base | 지붕을 부수라는 뜻은 아니야. 작은 빛부터 찾으면 돼. |
| V130R_JOIN_MOON_TRACKER_005 | 마왕 | 담담 | 허세 | proud | 저 촛불이 쓸 만하겠나? |
| V130R_JOIN_MOON_TRACKER_006 | 루미 | 담담 | 속삭임 | base | 응. 집에 돌아올 방향을 알 만큼은 밝네. |
| V130R_JOIN_MIMIC_PORTER_002 | 미미 | 담담 | 자신만만 | happy | 물품… 아니고… 미미야. |
| V130R_JOIN_MIMIC_PORTER_004 | 미미 | 담담 | 자신만만 | happy | 열어 보지 마세요… 쪽지는 내가 붙였어. |
| V130R_JOIN_MIMIC_PORTER_006 | 미미 | 담담 | 자신만만 | happy | 필요한 짐은… 앞에 두면 내가 챙길게. |
| V130R_JOIN_MIMIC_PORTER_007 | 마왕 | 담담 | 다정 | base | 좋다. 식구가 나를 때리는 고지서는 맨 밑에 넣어라. |
| V130R_JOIN_GHOST_HOUSEMAID_002 | 베베 | 담담 | 다정 | base | 이미 들어왔어. 문은 닫아 뒀고. |
| V130R_JOIN_GHOST_HOUSEMAID_005 | 베베 | 담담 | 다정 | base | 식구들 돌아올 문은 열어 둘게. 왕좌 아래도 쓸고. |
| V130R_JOIN_GHOST_HOUSEMAID_007 | 베베 | 담담 | 다정 | base | 네 두개골도 먼지라고 버리진 않을게. |
| V130R_JOIN_GRAVEYARD_HOUND_001 | 코코 | 담담 | 확인 | base | 새 집 냄새… 젖은 돌, 불씨, 걱정. |
| V130R_JOIN_GRAVEYARD_HOUND_005 | 코코 | 담담 | 확인 | base | 이 뼈는 밥 아니야. 냄새도 잊으면 안 돼. |
| V130R_JOIN_GRAVEYARD_HOUND_007 | 코코 | 담담 | 확인 | base | 마왕 냄새도 기억할게. 길 잃으면 내가 와. |
| V130R_FIRST_COMBAT_GRAVEYARD_HOUND_002 | 마왕 | 담담 | 허세 | proud | 잡으러 나갈 때도 돌아올 길은 잊지 마라. |
| V130R_JOIN_ARMORED_BEETLE_001 | 톡톡 | 담담 | 확인 | base | 톡. 전선에서 왔다. 고칠 곳은? |
| V130R_JOIN_ARMORED_BEETLE_002 | 마왕 | 담담 | 허세 | proud | 그 질문은 입구에서부터 시작하면 된다. |
| V130R_JOIN_ARMORED_BEETLE_004 | 톡톡 | 담담 | 확인 | base | 흠집은 돈이 무서워도 남는다. 톡. |
| V130R_JOIN_ARMORED_BEETLE_006 | 마왕 | 담담 | 허세 | proud | 네 등에도 흠집이 있는데 먼저 고쳐야 하지 않나? |
| V130R_FIRST_COMBAT_ARMORED_BEETLE_002 | 핀 | 담담 | 자신만만 | base | 네 판금까지 태우진 않을게. 불은 저쪽에만. |
| V130R_JOIN_SPIDER_TAILOR_001 | 실키 | 담담 | 단호 | determined | 기존 계약대로 왔어. 먼저 망토 치수부터. |
| V130R_JOIN_SPIDER_TAILOR_003 | 실키 | 담담 | 다정 | base | 바닥에 끌리는 만큼 줄일 거야. |
| V130R_JOIN_SPIDER_TAILOR_004 | 마왕 | 담담 | 허세 | proud | 합류 첫날부터 권위를 삭감하는 건가? |
| V130R_JOIN_SPIDER_TAILOR_008 | 실키 | 담담 | 다정 | base | 계산 끝나면 가만히 서. 해골 옷도 올이 풀렸어. |
| V130R_JOIN_BAT_COURIER_003 | 포포 | 담담 | 자랑 | happy | 품격은 올랐는데 천장 물은 그대로네! |
| V130R_JOIN_BAT_COURIER_006 | 포포 | 담담 | 자랑 | happy | 토벌 경고문은 어느 쪽이야? 글씨가 엄청 큰데. |
| V130R_JOIN_BAT_COURIER_007 | 마왕 | 담담 | 허세 | proud | 내게 다오. 접어서 작게 만들면 덜 위협적이겠지. |
| V130R_D01_MANAGEMENT_S1_001 | 실키 | 담담 | 다정 | base | 물이 떨어지는 데는 실을 안 걸게. 젖은 망토는 무거우니까. |
| V130R_D01_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 내 위엄은 원래 무겁다. 그래도 마른 쪽으로 부탁한다. |
| V130R_D01_MANAGEMENT_S2_001 | 포포 | 담담 | 자신만만 | happy | 밀로 앞으로 온 우편은 없어! 본인이 먼저 걸어오나 봐! |
| V130R_D02_MANAGEMENT_S1_001 | 베베 | 담담 | 다정 | base | 니아가 손댈 만한 문손잡이는 닦았어. 지문은 잘 보이겠지. |
| V130R_D02_MANAGEMENT_S2_001 | 코코 | 담담 | 확인 | base | 도둑 향수 냄새가 나. 금고 앞에서 제일 짙어. |
| V130R_D02_MANAGEMENT_S2_002 | 마왕 | 담담 | 허세 | proud | 금화는 향수를 안 쓴다. 그 냄새를 따라가라. |
| V130R_D02_MANAGEMENT_S3_001 | 톡톡 | 담담 | 확인 | base | 금고 문틀 받쳤다. 안에 걱정도 많다. 톡. |
| V130R_D03_MANAGEMENT_S1_001 | 실키 | 담담 | 다정 | base | 레온이 기술 이름 외칠 때 발에 망토가 걸리면 곤란해. 조금 걷을게. |
| V130R_D03_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 내 대사까지 걷지는 마라. 아직 첫 문장이다. |
| V130R_D03_MANAGEMENT_S2_001 | 포포 | 담담 | 자신만만 | happy | 견습 용사 도착 예고! 발소리보다 자기소개가 먼저야! |
| V130R_D03_MANAGEMENT_S3_001 | 베베 | 담담 | 다정 | base | 회복 둥지 바닥은 닦았어. 치료받으러 오다가 미끄러지진 않아. |
| V130R_D03_MANAGEMENT_S3_002 | 마왕 | 담담 | 허세 | proud | 좋다. 공포는 적에게만 제공하자. |
| V130R_D04_MANAGEMENT_S1_001 | 찍찍단 | 담담 | 합창 | happy | 표지판 원정에도 치즈 조항 적용! 멀리 가도 배는 같다! |
| V130R_D04_MANAGEMENT_S2_001 | 코코 | 담담 | 확인 | base | 로로가 나간 길 냄새, 기억했어. 돌아오면 알 수 있어. |
| V130R_D04_MANAGEMENT_S3_001 | 톡톡 | 담담 | 확인 | base | 표지판 못, 남은 거 있나. 문틀에도 쓴다. |
| V130R_D04_MANAGEMENT_S3_002 | 마왕 | 담담 | 허세 | proud | 내 이름 적을 못 하나는 남겨라. |
| V130R_D05_MANAGEMENT_S1_001 | 꼬깃 | 담담 | 자신만만 | happy | 밀로가 왕좌 셋을 지우려 해! 선택지를 줄이는 건 너무 잔인해! |
| V130R_D05_MANAGEMENT_S1_002 | 마왕 | 담담 | 다정 | base | 식구용 귀환로만 정확하면 적의 선택지는 넉넉해도 된다. |
| V130R_D05_MANAGEMENT_S2_001 | 찍찍단 | 담담 | 합창 | happy | 길 잃은 탐험가가 금고로 오면 추가 근무다! |
| V130R_D05_MANAGEMENT_S3_001 | 실키 | 담담 | 다정 | base | 지도 구겨진 데 실 한 가닥 묶을까? 펴기 쉽게. |
| V130R_D06_MANAGEMENT_S1_001 | 퐁당 | 담담 | 단호 | determined | 니아 씨 방문 예약서보다 제 반환 요구서가 먼저인데요. |
| V130R_D06_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 예약은 거절하고 요구서는 읽겠다. 순서에 공정한 마왕이다. |
| V130R_D06_MANAGEMENT_S2_001 | 꼬깃 | 담담 | 자신만만 | happy | 예약 손님용 길은 더 길게 그렸어! 정성이야! |
| V130R_D06_MANAGEMENT_S3_001 | 포포 | 담담 | 자랑 | happy | 니아 쪽지 수령인 확인! 왕좌 서랍까지 배달하면 돼? |
| V130R_D07_MANAGEMENT_S1_001 | 모리 | 담담 | 결심 | determined | 시설 강화 전에 손 좀 보여 줘. 망치보다 손이 먼저야. |
| V130R_D07_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 마왕의 손도 점검 대상인가? 좋아, 장갑은 벗겠다. |
| V130R_D07_MANAGEMENT_S2_001 | 퐁당 | 담담 | 무표정 | base | 시설이 단단해져도 연못은 그대로 두실 건데요? |
| V130R_D07_MANAGEMENT_S3_001 | 베베 | 담담 | 다정 | base | 왕좌 쿠션 대신 먼지라도 털었어. 조금 덜 딱딱할 거야. |
| V130R_D08_MANAGEMENT_S1_001 | 느릿 | 담담 | 속삭임 | base | 다들… 빨라져도… 제 자리… 남나요… |
| V130R_D08_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 느린 자리를 지키는 것도 성장이다. 네 속도까지 내 재산이다. |
| V130R_D08_MANAGEMENT_S2_001 | 모리 | 담담 | 다정 | base | 벽에 부딪힌 애부터 살필게. 단단해져도 아픈 건 아프니까. |
| V130R_D08_MANAGEMENT_S3_001 | 코코 | 담담 | 확인 | base | 벽 금 간 냄새가 나. 수리할 데 찾았어. |
| V130R_D09_MANAGEMENT_S1_001 | 돌콩 | 담담 | 엄숙 | base | 아이리스가 내 자리도 적는다. 콩. |
| V130R_D09_MANAGEMENT_S2_001 | 느릿 | 담담 | 속삭임 | base | 조사관이… 제 흔적도… 적나요… |
| V130R_D09_MANAGEMENT_S2_002 | 마왕 | 담담 | 허세 | proud | 적어도 된다. 지워야 할 낙서가 아니라 네가 온 길이다. |
| V130R_D09_MANAGEMENT_S3_001 | 톡톡 | 담담 | 확인 | base | 문틀 흠집도 조사하더군. 톡. |
| V130R_D10_MANAGEMENT_S1_001 | 쉿 | 담담 | 수줍음 | happy | 게시판에… 제 이름도 있어요…? 뒤쪽이라도… |
| V130R_D10_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 아직 없다면 우리 명단에 먼저 적자. 뒤쪽이 아니라 네 칸이다. |
| V130R_D10_MANAGEMENT_S2_001 | 돌콩 | 담담 | 엄숙 | base | 조사대가 와도 자리 같다. 콩. |
| V130R_D10_MANAGEMENT_S3_001 | 꼬깃 | 담담 | 자신만만 | happy | 현상금 종이에 지도 그려도 돼? 뒷면이 비었어! |
| V130R_D11_MANAGEMENT_S1_001 | 찍찍단 | 담담 | 합창 | happy | 토벌 경고문도 협약서만큼 세 장 필요하나? |
| V130R_D11_MANAGEMENT_S2_001 | 퐁당 | 담담 | 무표정 | base | 고급지면 요구서로 쓰기 좋겠는데요. 잘 안 찢어지고요. |
| V130R_D11_MANAGEMENT_S2_002 | 마왕 | 담담 | 허세 | proud | 왕국의 위협을 민원 용지로 바꾸는군. 고등 전술이다. |
| V130R_D11_MANAGEMENT_S3_001 | 쉿 | 담담 | 속삭임 | base | 거꾸로 붙이면… 읽는 동안 뒤에 숨을 수 있겠어요… |
| V130R_D12_MANAGEMENT_S1_001 | 두둠 | 담담 | 자랑 | happy | 승급곡 준비했어! 천둥 예산 없어도 북은 있지! |
| V130R_D12_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 좋다. 내 위엄은 오늘부터 타악기 지원을 받는다. |
| V130R_D12_MANAGEMENT_S2_001 | 모리 | 담담 | 결심 | determined | 누가 먼저 강해져도 치료 순서는 아픈 순서야. |
| V130R_D12_MANAGEMENT_S3_001 | 느릿 | 담담 | 속삭임 | base | 박수는… 제가… 제일 늦어도… 끝까지… |
| V130R_D13_MANAGEMENT_S1_001 | 벙벙 | 담담 | 울먹 | base | 방패병이 문짝이면 제 다리는 현관입니다! 신발 털고 오세요! |
| V130R_D13_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 좋다. 침입 허가는 내주지 말고 신발만 털어라. |
| V130R_D13_MANAGEMENT_S2_001 | 돌콩 | 담담 | 엄숙 | base | 큰 방패도 길은 하나다. 콩. |
| V130R_D13_MANAGEMENT_S3_001 | 두둠 | 담담 | 자랑 | happy | 느린 발엔 느린 곡! 오래 버티는 박자로 간다! |
| V130R_D14_MANAGEMENT_S1_001 | 벙벙 | 담담 | 울먹 | base | 소마왕성 되면 다리지기도 승진인가요? 넥타이 꺼내도 돼요? |
| V130R_D14_MANAGEMENT_S2_001 | 쉿 | 담담 | 속삭임 | base | 성이 커지면… 저를 못 찾을까요…? |
| V130R_D14_MANAGEMENT_S2_002 | 마왕 | 담담 | 허세 | proud | 이름을 부르면 된다. 성이 커져도 네 이름은 안 줄인다. |
| V130R_D14_MANAGEMENT_S3_001 | 두둠 | 담담 | 자랑 | happy | 악명은 안 내도 북은 쳐도 되지? 축하 예행연습! |
| V130R_D15_MANAGEMENT_S1_001 | 녹녹 | 담담 | 겁 | base | 셀렌 씨 점검표에 빛 담당도 적어 주세요! 저요, 저! |
| V130R_D15_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 좋다. 경력 이백 년을 한 칸에 구겨 넣어 보마. |
| V130R_D15_MANAGEMENT_S2_001 | 벙벙 | 담담 | 울먹 | base | 비상구도 제가 지켜요? 도망갈 땐 통행세 안 받습니다! |
| V130R_D15_MANAGEMENT_S3_001 | 베베 | 담담 | 다정 | base | 심사 전에 바닥 닦았어. 물기는 조금 남았지만. |
| V130R_D16_MANAGEMENT_S1_001 | 루미 | 담담 | 속삭임 | base | 셀렌 지도에 점심 자국이 있네. 길보다 밥시간이 정확해. |
| V130R_D16_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 우리 귀환 시간도 그만큼 정확히 하자. |
| V130R_D16_MANAGEMENT_S2_001 | 녹녹 | 담담 | 겁 | base | 정찰 가는 식구들 발밑 비출게요! 물 없는 쪽으로만요! |
| V130R_D16_MANAGEMENT_S3_001 | 퐁당 | 담담 | 무표정 | base | 강변 창고면 제 친척도 사는데요. 물은 건드리지 마세요. |
| V130R_D17_MANAGEMENT_S1_001 | 미미 | 담담 | 자신만만 | happy | 니아가 두 번 온대… 놀라는 것도 두 번 준비해야 해? |
| V130R_D17_MANAGEMENT_S2_001 | 루미 | 담담 | 속삭임 | base | 첫 발자국이 끝나도 표식은 지우지 않을게. |
| V130R_D17_MANAGEMENT_S2_002 | 마왕 | 담담 | 결심 | serious | 그래. 조용하다고 식구를 혼자 두지는 말자. |
| V130R_D17_MANAGEMENT_S3_001 | 찍찍단 | 담담 | 합창 | happy | 두 번 와도 근무자는 셋! 계산은 여섯이 아니지? |
| V130R_D18_MANAGEMENT_S1_001 | 누비 | 담담 | 무심 | base | 니아가 버린 나도 여기 들어왔잖아. 막힌 길에도 틈은 있어. |
| V130R_D18_MANAGEMENT_S1_002 | 마왕 | 담담 | 다정 | base | 우리 식구가 돌아올 틈부터 찾자. 저주는 그다음이다. |
| V130R_D18_MANAGEMENT_S2_001 | 미미 | 담담 | 자신만만 | happy | 가짜 장부… 내 안에 넣으면 진짜 금화랑 섞일까? |
| V130R_D18_MANAGEMENT_S3_001 | 실키 | 담담 | 다정 | base | 봉쇄로 끊긴 통로엔 실을 더 남길게. 돌아오는 쪽에서 잡도록. |
| V130R_D19_MANAGEMENT_S1_001 | 누비 | 담담 | 무심 | base | 니아한테 편지 쓸 종이, 저 명령서 뒷면은 안 되겠지? |
| V130R_D19_MANAGEMENT_S2_001 | 미미 | 담담 | 자신만만 | happy | 금화보다 종이를 노린다니… 내가 보물 보는 눈이 없는 줄 알았어. |
| V130R_D19_MANAGEMENT_S2_002 | 마왕 | 담담 | 다정 | base | 식구가 지키는 종이면 오늘의 보물이다. 가격표는 나중에 붙여라. |
| V130R_D19_MANAGEMENT_S3_001 | 포포 | 담담 | 자랑 | happy | 명령서 반송 봉투는 만들지 말까? 도둑이 직접 오는데. |
| V130R_D20_MANAGEMENT_S1_001 | 파파 | 담담 | 확인 | base | 로만이 온다니 현장표부터 다시 보죠. 식구 이름은 지우지 맙시다. |
| V130R_D20_MANAGEMENT_S1_002 | 마왕 | 담담 | 결심 | serious | 좋다. 공사 완료보다 전원 귀환을 먼저 적어라. |
| V130R_D20_MANAGEMENT_S2_001 | 녹녹 | 담담 | 겁 | base | 공병이 감시초소 끄면 제가 비출게요! 비 새는 곳만 알려 줘요! |
| V130R_D20_MANAGEMENT_S3_001 | 돌콩 | 담담 | 단호 | determined | 시설 멈춰도 나는 선다. 콩. |
| V130R_D20_MANAGEMENT_S3_002 | 바티 | 건조 | 냉정 | stern | 공병은 서로 다른 목표로 갑니다. 보이는 길부터 지키십시오. |
| V130R_D21_MANAGEMENT_S1_001 | 파파 | 담담 | 확인 | base | 셀렌은 교대 틈을 보겠죠. 안전선은 끊지 않고 넘겨야 합니다. |
| V130R_D21_MANAGEMENT_S2_001 | 루미 | 담담 | 속삭임 | base | 빛이 오는 쪽만 보면 뒤를 놓쳐. 오늘은 돌아오는 발도 셀게. |
| V130R_D21_MANAGEMENT_S2_002 | 마왕 | 담담 | 허세 | proud | 출발 때 센 수와 같게. 그 보고가 제일 듣고 싶다. |
| V130R_D21_MANAGEMENT_S3_001 | 톡톡 | 담담 | 확인 | base | 로만 공병이 남긴 흠집, 표시했다. 톡. |
| V130R_D22_MANAGEMENT_S1_001 | 누비 | 담담 | 무심 | base | 조사관이 간식 시간도 적었대. 내 바느질 시간은 못 줘. |
| V130R_D22_MANAGEMENT_S1_002 | 마왕 | 담담 | 다정 | base | 그건 식구만 보는 일정이다. 적에게 바늘땀까지 설명할 의무는 없다. |
| V130R_D22_MANAGEMENT_S2_001 | 두둠 | 담담 | 자랑 | happy | 교대 북소리까지 적히면 어떡해? 오늘부터 조용히 둥? |
| V130R_D22_MANAGEMENT_S3_001 | 꼬깃 | 담담 | 자신만만 | happy | 아이리스가 사각을 찾으면 내가 종이를 한번 접을까? |
| V130R_D23_MANAGEMENT_S1_001 | 파파 | 담담 | 확인 | base | 승급 둘이면 발판도 둘 점검! 높아질수록 바닥이 중요합니다. |
| V130R_D23_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 내 왕좌도 점검 목록에 넣어라. 높이만 높은 건 곤란하다. |
| V130R_D23_MANAGEMENT_S2_001 | 느릿 | 담담 | 결심 | determined | 누가… 먼저여도… 박수 칠… 준비는… 됐어요… |
| V130R_D23_MANAGEMENT_S3_001 | 모리 | 담담 | 결심 | determined | 공병 먼저 잡겠다는 애도 잠은 자야 해. 침대 점검도 하자. |
| V130R_D24_MANAGEMENT_S1_001 | 루미 | 담담 | 속삭임 | base | 레온 지도에 빵 냄새가 나. 외운 길은 쉽게 안 바꾸겠어. |
| V130R_D24_MANAGEMENT_S2_001 | 미미 | 담담 | 자신만만 | happy | 왕좌 옆 동그라미… 내 뚜껑에 그려도 돼? 당황할 자리. |
| V130R_D24_MANAGEMENT_S2_002 | 마왕 | 담담 | 허세 | proud | 굳이 표시하지 마라. 내 것은 전술 이동 표시다. |
| V130R_D24_MANAGEMENT_S3_001 | 코코 | 담담 | 결심 | determined | 빵 냄새보다 돌아올 손 냄새 먼저 맡을게. |
| V130R_D25_MANAGEMENT_S1_001 | 텅텅 | 담담 | 정의감 | determined | 레온은 돌진한다고 들었습니다. 저는 제 이름으로 여기 서겠습니다. |
| V130R_D25_MANAGEMENT_S1_002 | 마왕 | 담담 | 다정 | base | 정의의 자격증은 필요 없다. 네 뒤에 식구가 있다는 것만 기억해라. |
| V130R_D25_MANAGEMENT_S2_001 | 톡톡 | 담담 | 확인 | base | 빈 갑옷도 판금은 판금이다. 이음새 봐 뒀다. 톡. |
| V130R_D25_MANAGEMENT_S3_001 | 벙벙 | 담담 | 울먹 | base | 용사가 와도 다리 근무는 그대로죠? 오늘도 제 자리죠? |
| V130R_D26_MANAGEMENT_S1_001 | 텅텅 | 담담 | 정의감 | determined | 정식 마왕성 등록증에 제 이름은 없어도 됩니다. 투구 안에는 있거든요. |
| V130R_D26_MANAGEMENT_S2_001 | 파파 | 담담 | 확인 | base | 명칭 바뀌어도 비상구 표시는 그대로 알아보게 합시다. |
| V130R_D26_MANAGEMENT_S3_001 | 녹녹 | 담담 | 겁 | base | 정식 등록이면 제 촛대도 정식 근무지죠?! 비 안 새게 해 줘요! |
| V130R_D26_MANAGEMENT_S3_002 | 마왕 | 담담 | 허세 | proud | 공식 위협보다 빗물이 더 무섭다는 건 기밀로 하자. |
| V130R_D27_MANAGEMENT_S1_001 | 텅텅 | 담담 | 당황 | base | 성채 심장은 뛰는데 저는 비었습니다. 그래도 같은 편이지요? |
| V130R_D27_MANAGEMENT_S1_002 | 마왕 | 담담 | 다정 | base | 같은 식구다. 심장 소리보다 그 말을 먼저 기억해라. |
| V130R_D27_MANAGEMENT_S2_001 | 돌콩 | 담담 | 엄숙 | base | 공병이 둘이어도 돌아올 문은 지킨다. 콩. |
| V130R_D27_MANAGEMENT_S3_001 | 두둠 | 담담 | 자랑 | happy | 심장 박자 들리면 맞춰 칠게! 네 장부보다 느리겠지? |
| V130R_D28_MANAGEMENT_S1_001 | 꼬깃 | 담담 | 자신만만 | happy | 공성로든 공병 수레든, 식구 귀환로는 안 구길게! |
| V130R_D28_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 선택은 내가 한다. 돌아올 표시는 네가 맡아라. |
| V130R_D28_MANAGEMENT_S2_001 | 포포 | 담담 | 자랑 | happy | 원정 결과는 돌아온 식구한테 직접 받을게! 소문은 임시 우편! |
| V130R_D28_MANAGEMENT_S3_001 | 퐁당 | 담담 | 무표정 | base | 수레가 물길로 빠져도 흙으로 막지는 마세요. 연못인데요. |
| V130R_D29_MANAGEMENT_S1_001 | 누비 | 담담 | 무심 | base | 내일 레온이 오기 전에 오늘 실밥부터 볼래? 아픈 곳 숨기지 마. |
| V130R_D29_MANAGEMENT_S1_002 | 마왕 | 담담 | 결심 | serious | 오늘은 싸우지 않는다. 그러니 아픈 척 안 하는 것도 금지다. |
| V130R_D29_MANAGEMENT_S2_001 | 쉿 | 담담 | 속삭임 | base | 오늘은… 무섭게 안 할게요… 잠들 때 옆에 있을게요… |
| V130R_D29_MANAGEMENT_S2_002 | 바티 | 건조 | 냉정 | stern | 침입 일정 없음. 조용한 근무도 정식 근무로 기록합니다. |
| V130R_D29_MANAGEMENT_S3_001 | 실키 | 담담 | 단호 | determined | 내일 잡아당길 실은 준비됐어. 오늘은 해진 데만 꿰맬게. |
| V130R_D30_MANAGEMENT_S1_001 | 텅텅 | 담담 | 정의감 | determined | 레온이 마지막이라 들었습니다. 제 뒤 이름은 하나도 빼지 않겠습니다. |
| V130R_D30_MANAGEMENT_S1_002 | 마왕 | 담담 | 허세 | proud | 돌아올 때 다시 세자. 연설보다 그 점호를 길게 하겠다. |
| V130R_D30_MANAGEMENT_S2_001 | 베베 | 담담 | 다정 | base | 셀렌과 공병이 와도 돌아올 문은 열어 둘게. 청소는 다 온 뒤에. |
| V130R_D30_MANAGEMENT_S3_001 | 코코 | 담담 | 결심 | determined | 오늘도 식구 냄새부터 센다. 적보다 먼저. |
| V130R_BARK_SLIME_DEPLOYED_001 | 푸딩 | 담담 | 기쁨 | base | 푸딩 자리! 말랑한 벽 세웠다! |
| V130R_BARK_SLIME_HP_BELOW_30_001 | 푸딩 | 담담 | 당황 | base | 푸딩, 조금 납작해졌어… |
| V130R_BARK_SLIME_ALLY_DOWNED_001 | 푸딩 | 담담 | 결심 | base | 잠깐 누워 있어! 푸딩이 가릴게! |
| V130R_BARK_SLIME_HUNGRY_001 | 푸딩 | 담담 | 시무룩 | base | 배가 비면 더 납작해져… |
| V130R_BARK_GOBLIN_DEPLOYED_001 | 곱 | 담담 | 씩 | base | 곱 자리다! 금고도 보인다! |
| V130R_BARK_GOBLIN_HP_BELOW_30_001 | 곱 | 담담 | 당황 | base | 곱 아직 선다! 조금 기울었다! |
| V130R_BARK_GOBLIN_ALLY_DOWNED_001 | 곱 | 담담 | 자신만만 | base | 곱 뒤로 와! 아니, 누워 있으면 곱이 간다! |
| V130R_BARK_GOBLIN_HUNGRY_001 | 곱 | 담담 | 시무룩 | base | 곱 배에서 적보다 큰 소리 난다… |
| V130R_BARK_IMP_DEPLOYED_001 | 핀 | 담담 | 자신만만 | base | 뒤쪽 확보. 이제 앞쪽만 뜨거워지면 돼. |
| V130R_BARK_IMP_HP_BELOW_30_001 | 핀 | 담담 | 당황 | base | 심지는 남았어. 바람만 좀 막아 줘. |
| V130R_BARK_IMP_ALLY_DOWNED_001 | 핀 | 담담 | 결심 | base | 그쪽 손대지 마. 아직 따뜻하잖아. |
| V130R_BARK_IMP_HUNGRY_001 | 핀 | 담담 | 시무룩 | base | 불도 땔감 없이 허세만 태울 순 없거든. |
| V130R_BARK_KOBOLD_SCOUT_DEPLOYED_001 | 로로 | 담담 | 확인 | base | 갈림길 확인! 돌아오는 표시는 이쪽이에요. |
| V130R_BARK_KOBOLD_SCOUT_HP_BELOW_30_001 | 로로 | 담담 | 당황 | base | 보고는 짧게… 저 좀 위험해요! |
| V130R_BARK_KOBOLD_SCOUT_ALLY_DOWNED_001 | 로로 | 담담 | 결심 | base | 귀환로 비워 주세요! 식구가 누웠어요! |
| V130R_BARK_KOBOLD_SCOUT_HUNGRY_001 | 로로 | 담담 | 시무룩 | base | 정찰보다 밥 냄새가 먼저 잡혀요… |
| V130R_BARK_SPORE_HEALER_DEPLOYED_001 | 모리 | 담담 | 다정 | base | 돌아와 누울 자리, 여기야. |
| V130R_BARK_SPORE_HEALER_HP_BELOW_30_001 | 모리 | 담담 | 당황 | base | 나도 잠깐 쉬어야겠네… |
| V130R_BARK_SPORE_HEALER_ALLY_DOWNED_001 | 모리 | 담담 | 결심 | determined | 눈 감아도 돼. 혼자 두진 않아. |
| V130R_BARK_SPORE_HEALER_HUNGRY_001 | 모리 | 담담 | 시무룩 | base | 오늘은 둥지보다 밥부터 필요하겠네. |
| V130R_BARK_STONE_SENTINEL_DEPLOYED_001 | 돌콩 | 담담 | 엄숙 | base | 여기 선다. 콩. |
| V130R_BARK_STONE_SENTINEL_HP_BELOW_30_001 | 돌콩 | 담담 | 당황 | base | 금 갔다. 아직 둘은 아니다. 콩. |
| V130R_BARK_STONE_SENTINEL_ALLY_DOWNED_001 | 돌콩 | 담담 | 단호 | determined | 내 옆에 눕혀라. 콩. |
| V130R_BARK_STONE_SENTINEL_HUNGRY_001 | 돌콩 | 담담 | 시무룩 | base | 돌도 배고프다. 콩… |
| V130R_BARK_WAR_DRUMMER_DEPLOYED_001 | 두둠 | 담담 | 자랑 | happy | 여기가 첫 박자! 둥! |
| V130R_BARK_WAR_DRUMMER_HP_BELOW_30_001 | 두둠 | 담담 | 당황 | base | 북은 안 찢어졌어… 나만 좀… |
| V130R_BARK_WAR_DRUMMER_ALLY_DOWNED_001 | 두둠 | 담담 | 결심 | determined | 구조 박자로! 둥, 쉬고, 둥! |
| V130R_BARK_WAR_DRUMMER_HUNGRY_001 | 두둠 | 담담 | 시무룩 | base | 배에서 저음이 나네… 둥… |
| V130R_BARK_MOON_TRACKER_DEPLOYED_001 | 루미 | 담담 | 속삭임 | base | 돌아올 방향까지 봤어. |
| V130R_BARK_MOON_TRACKER_HP_BELOW_30_001 | 루미 | 담담 | 당황 | base | 달이 좀 흐려졌네… |
| V130R_BARK_MOON_TRACKER_ALLY_DOWNED_001 | 루미 | 담담 | 단호 | determined | 표적은 나중. 식구부터. |
| V130R_BARK_MOON_TRACKER_HUNGRY_001 | 루미 | 담담 | 시무룩 | base | 빈속에는 달도 멀어 보여. |
| V130R_BARK_MIMIC_PORTER_DEPLOYED_001 | 미미 | 담담 | 자신만만 | happy | 여기… 놓으면 돼? 나를. |
| V130R_BARK_MIMIC_PORTER_HP_BELOW_30_001 | 미미 | 담담 | 당황 | base | 경첩이… 떨려. |
| V130R_BARK_MIMIC_PORTER_ALLY_DOWNED_001 | 미미 | 담담 | 당황 | base | 그 짐은 내가 들게. 너는 쉬어. |
| V130R_BARK_MIMIC_PORTER_HUNGRY_001 | 미미 | 담담 | 시무룩 | base | 가짜 금화는… 못 먹는구나. |
| V130R_BARK_GHOST_HOUSEMAID_DEPLOYED_001 | 베베 | 담담 | 다정 | base | 먼지부터 쓸고 지킬게. |
| V130R_BARK_GHOST_HOUSEMAID_HP_BELOW_30_001 | 베베 | 담담 | 당황 | base | 좀 더 흐려졌네… 아직 여기 있어. |
| V130R_BARK_GHOST_HOUSEMAID_ALLY_DOWNED_001 | 베베 | 담담 | 단호 | determined | 청소는 나중. 식구부터 옮겨. |
| V130R_BARK_GHOST_HOUSEMAID_HUNGRY_001 | 베베 | 담담 | 시무룩 | base | 유령도 밥시간은 기억하거든. |
| V130R_BARK_GRAVEYARD_HOUND_DEPLOYED_001 | 코코 | 담담 | 확인 | base | 이 자리, 집 냄새. |
| V130R_BARK_GRAVEYARD_HOUND_HP_BELOW_30_001 | 코코 | 담담 | 당황 | base | 아직 돌아갈 냄새가 남았어… |
| V130R_BARK_GRAVEYARD_HOUND_ALLY_DOWNED_001 | 코코 | 담담 | 결심 | determined | 움직이지 마. 내가 네 냄새로 갈게. |
| V130R_BARK_GRAVEYARD_HOUND_HUNGRY_001 | 코코 | 담담 | 시무룩 | base | 목걸이 뼈는… 밥 아니야. |
| V130R_BARK_ARMORED_BEETLE_DEPLOYED_001 | 톡톡 | 담담 | 확인 | base | 발밑 확인. 톡. |
| V130R_BARK_ARMORED_BEETLE_HP_BELOW_30_001 | 톡톡 | 담담 | 당황 | base | 리벳은 남았다… 톡. |
| V130R_BARK_ARMORED_BEETLE_ALLY_DOWNED_001 | 톡톡 | 담담 | 단호 | determined | 내 등으로 가려라. 먼저 옮겨. |
| V130R_BARK_ARMORED_BEETLE_HUNGRY_001 | 톡톡 | 담담 | 시무룩 | base | 빈속은 판금으로 못 막는다. |
| V130R_BARK_SPIDER_TAILOR_DEPLOYED_001 | 실키 | 담담 | 다정 | base | 문턱에 실 걸었어. 식구 길은 비웠고. |
| V130R_BARK_SPIDER_TAILOR_HP_BELOW_30_001 | 실키 | 담담 | 당황 | base | 손이 떨려도 매듭은 안 풀어. |
| V130R_BARK_SPIDER_TAILOR_ALLY_DOWNED_001 | 실키 | 담담 | 단호 | determined | 움직이지 마. 실이 데리러 갈 거야. |
| V130R_BARK_SPIDER_TAILOR_HUNGRY_001 | 실키 | 담담 | 시무룩 | base | 오늘은 바늘보다 손이 무겁네. |
| V130R_BARK_BAT_COURIER_DEPLOYED_001 | 포포 | 담담 | 자랑 | happy | 새 주소 확인! 내 자리는 여기! |
| V130R_BARK_BAT_COURIER_HP_BELOW_30_001 | 포포 | 담담 | 당황 | base | 날개가… 반송되려 해! |
| V130R_BARK_BAT_COURIER_ALLY_DOWNED_001 | 포포 | 담담 | 자신만만 | happy | 구조 요청! 수령인은 우리 전원! |
| V130R_BARK_BAT_COURIER_HUNGRY_001 | 포포 | 담담 | 시무룩 | base | 배고픔 속보… 배송 지연이야. |
| V130R_BARK_RIVER_FROG_DEPLOYED_001 | 퐁당 | 담담 | 무표정 | base | 여기 제 물가인데요. |
| V130R_BARK_RIVER_FROG_HP_BELOW_30_001 | 퐁당 | 담담 | 당황 | base | 물 밖에 너무 오래 있었는데요… |
| V130R_BARK_RIVER_FROG_ALLY_DOWNED_001 | 퐁당 | 담담 | 단호 | determined | 그쪽은 우리 세입자인데요. 손 떼시죠. |
| V130R_BARK_RIVER_FROG_HUNGRY_001 | 퐁당 | 담담 | 시무룩 | base | 연못 월세에 밥은 별도인데요… |
| V130R_BARK_GLUE_SNAIL_DEPLOYED_001 | 느릿 | 담담 | 속삭임 | base | 도착… 했어요… |
| V130R_BARK_GLUE_SNAIL_HP_BELOW_30_001 | 느릿 | 담담 | 당황 | base | 집으로… 잠깐만… |
| V130R_BARK_GLUE_SNAIL_ALLY_DOWNED_001 | 느릿 | 담담 | 결심 | determined | 기다려… 나도… 갈게… |
| V130R_BARK_GLUE_SNAIL_HUNGRY_001 | 느릿 | 담담 | 시무룩 | base | 밥은… 너무… 늦지… 않게… |
| V130R_BARK_BRIDGE_TROLL_DEPLOYED_001 | 벙벙 | 담담 | 울먹 | base | 이 다리, 제가 맡겠습니다! |
| V130R_BARK_BRIDGE_TROLL_HP_BELOW_30_001 | 벙벙 | 담담 | 당황 | base | 다리보다… 먼저 무너지면 안 되는데… |
| V130R_BARK_BRIDGE_TROLL_ALLY_DOWNED_001 | 벙벙 | 담담 | 간절 | determined | 다리 안쪽으로 옮겨요! 제가 지킬게요! |
| V130R_BARK_BRIDGE_TROLL_HUNGRY_001 | 벙벙 | 담담 | 시무룩 | base | 밥시간도 근무표에… 넣어 주세요… |
| V130R_BARK_UNDER_BED_SHADOW_DEPLOYED_001 | 쉿 | 담담 | 속삭임 | base | 여기… 뒤에 있어요… |
| V130R_BARK_UNDER_BED_SHADOW_HP_BELOW_30_001 | 쉿 | 담담 | 속삭임 | base | 그림자가… 얇아졌어요… |
| V130R_BARK_UNDER_BED_SHADOW_ALLY_DOWNED_001 | 쉿 | 담담 | 속삭임 | base | 혼자 아니에요… 제가 옆에… |
| V130R_BARK_UNDER_BED_SHADOW_HUNGRY_001 | 쉿 | 담담 | 속삭임 | base | 배 소리가… 제일 무서워요… |
| V130R_BARK_HOLLOW_ARMOR_DEPLOYED_001 | 텅텅 | 담담 | 정의감 | determined | 옥좌 앞, 정의롭게 출근! |
| V130R_BARK_HOLLOW_ARMOR_HP_BELOW_30_001 | 텅텅 | 담담 | 당황 | base | 투구가… 조금 멀리 보이는군… |
| V130R_BARK_HOLLOW_ARMOR_ALLY_DOWNED_001 | 텅텅 | 담담 | 단호 | determined | 내 뒤로! 누워 있어도 식구다! |
| V130R_BARK_HOLLOW_ARMOR_HUNGRY_001 | 텅텅 | 담담 | 당황 | base | 속은 원래 비었는데, 오늘은 더 비었다… |
| V130R_BARK_CANDLE_WISP_DEPLOYED_001 | 녹녹 | 담담 | 겁 | base | 물방울 안 떨어지는 자리 맞죠?! |
| V130R_BARK_CANDLE_WISP_HP_BELOW_30_001 | 녹녹 | 담담 | 비명 | base | 심지 짧아진 거 아니죠? 아니죠?! |
| V130R_BARK_CANDLE_WISP_ALLY_DOWNED_001 | 녹녹 | 담담 | 비명 | base | 어두워지지 마! 내가 비춰 줄게! |
| V130R_BARK_CANDLE_WISP_HUNGRY_001 | 녹녹 | 담담 | 겁 | base | 불꽃도 밥은 먹어야 해요… 아마도! |
| V130R_BARK_MOLE_DIGGER_DEPLOYED_001 | 파파 | 담담 | 확인 | base | 발판 확인! 안전 제일! |
| V130R_BARK_MOLE_DIGGER_HP_BELOW_30_001 | 파파 | 담담 | 당황 | base | 버팀목… 하나 더 필요합니다… |
| V130R_BARK_MOLE_DIGGER_ALLY_DOWNED_001 | 파파 | 담담 | 단호 | determined | 구조 동선 확보! 곱, 같이 갑시다! |
| V130R_BARK_MOLE_DIGGER_HUNGRY_001 | 파파 | 담담 | 시무룩 | base | 빈속 작업은 안전 위반입니다… |
| V130R_BARK_CRUMPLED_MAP_DEPLOYED_001 | 꼬깃 | 담담 | 자신만만 | happy | 여기 맞아! 아마! |
| V130R_BARK_CRUMPLED_MAP_HP_BELOW_30_001 | 꼬깃 | 담담 | 당황 | base | 모서리가… 더 구겨졌어… |
| V130R_BARK_CRUMPLED_MAP_ALLY_DOWNED_001 | 꼬깃 | 담담 | 당황 | base | 그 애 돌아올 길은 안 틀려! |
| V130R_BARK_CRUMPLED_MAP_HUNGRY_001 | 꼬깃 | 담담 | 시무룩 | base | 종이도 식량은 필요하더라… |
| V130R_BARK_RAT_UNION_DEPLOYED_001 | 찍찍단 | 담담 | 합창 | happy | 한 칸에 셋! 대표도 셋! |
| V130R_BARK_RAT_UNION_HP_BELOW_30_001 | 찍찍단 | 담담 | 당황 | base | 찍… 셋 다 좀 아프다… |
| V130R_BARK_RAT_UNION_ALLY_DOWNED_001 | 찍찍단 | 담담 | 단호 | determined | 구조에 찬성! 만장일치! |
| V130R_BARK_RAT_UNION_HUNGRY_001 | 찍찍단 | 담담 | 시무룩 | base | 치즈 미지급! 배에서 시위 중! |
| V130R_BARK_CURSE_DOLL_DEPLOYED_001 | 누비 | 담담 | 무심 | base | 엄마가 꿰맨 자리, 여기서 지킬게. |
| V130R_BARK_CURSE_DOLL_HP_BELOW_30_001 | 누비 | 담담 | 당황 | base | 실밥이… 또 늘겠네. |
| V130R_BARK_CURSE_DOLL_ALLY_DOWNED_001 | 누비 | 담담 | 간절 | determined | 버려 두지 않아. 내가 옆에 앉을게. |
| V130R_BARK_CURSE_DOLL_HUNGRY_001 | 누비 | 담담 | 시무룩 | base | 솜으로 배고픔까지 채울 순 없나 봐. |
| V130R_BOND_SLIME_1_002 | 푸딩 | 담담 | 기쁨 | base | 말은 못 해도, 먼저 손을 내밀 수는 있어. |
| V130R_BOND_SLIME_1_003 | 마왕 | 담담 | 다정 | base | 저 돌더미에서 손을 먼저 내민 건 나보다 너였다. |
| V130R_BOND_SLIME_2_002 | 푸딩 | 담담 | 기쁨 | base | 푸딩이 버티는 동안에는 누구도 혼자 남지 않는다. |
| V130R_BOND_SLIME_2_003 | 마왕 | 담담 | 다정 | base | 문을 지키느라 너까지 못 나오는 건 허락하지 않는다. |
| V130R_BOND_SLIME_3_002 | 푸딩 | 담담 | 기쁨 | base | 나누어 먹으면 전리품도 식구의 맛이 난다. |
| V130R_BOND_SLIME_3_003 | 마왕 | 담담 | 다정 | base | 내 접시에도 체리가 생겼군. 왕관보다 이게 더 붉다. |
| V130R_BOND_GOBLIN_1_002 | 곱 | 담담 | 씩 | base | 훔친 게 아니라, 아무도 안 보는 데서 투자한 거야. |
| V130R_BOND_GOBLIN_1_003 | 마왕 | 담담 | 다정 | base | 내가 봤다. 수리비 상자에는 네가 웃는 소리도 들어갔다. |
| V130R_BOND_GOBLIN_2_002 | 곱 | 담담 | 씩 | base | 잃어버리면 갚아. 금화 말고 목숨으로. |
| V130R_BOND_GOBLIN_2_003 | 마왕 | 담담 | 다정 | base | 복제 열쇠는 내 쪽에 두겠다. 네가 돌아오면 같이 열자. |
| V130R_BOND_GOBLIN_3_002 | 곱 | 담담 | 씩 | base | 같이 털면 더 큰 금고도 열 수 있잖아. |
| V130R_BOND_GOBLIN_3_003 | 마왕 | 담담 | 다정 | base | 지도를 나눴는데 왜 가격을 안 적었나? |
| V130R_BOND_IMP_1_002 | 핀 | 담담 | 자신만만 | base | 불은 태우기만 하는 게 아니거든. |
| V130R_BOND_IMP_1_003 | 마왕 | 담담 | 다정 | base | 밤새 화로를 지켰으면 오늘 아침엔 네가 쉬어라. |
| V130R_BOND_IMP_2_002 | 핀 | 담담 | 자신만만 | base | 다음에는 벽 말고 적만 날려 버릴게. |
| V130R_BOND_IMP_2_003 | 마왕 | 담담 | 다정 | base | 벽 값보다 네 다음 주문식이 먼저다. 이번엔 같이 보자. |
| V130R_BOND_IMP_3_002 | 핀 | 담담 | 자신만만 | base | 기억하는 동안에는 완전히 꺼진 게 아니야. |
| V130R_BOND_IMP_3_003 | 마왕 | 담담 | 다정 | base | 잿가루 이름을 오늘도 읽자. 빨리 읽을 필요는 없다. |
| V130R_BOND_KOBOLD_SCOUT_1_002 | 로로 | 담담 | 확인 | base | 이제 도망길이 아니라 우리 길이에요. |
| V130R_BOND_KOBOLD_SCOUT_1_003 | 마왕 | 담담 | 억울 | offended | 비밀 통로를 같이 안다는 건 비밀이 없어진 게 아니다. |
| V130R_BOND_KOBOLD_SCOUT_2_002 | 로로 | 담담 | 확인 | base | 이번에는 소문보다 사실이 더 중요하니까요. |
| V130R_BOND_KOBOLD_SCOUT_2_003 | 마왕 | 담담 | 다정 | base | 틀린 보고보다 돌아온 네 목소리가 낫다. 사실대로 계속 말해라. |
| V130R_BOND_KOBOLD_SCOUT_3_002 | 로로 | 담담 | 확인 | base | 길을 잃어도 제 표시를 따라오면 집이에요. |
| V130R_BOND_KOBOLD_SCOUT_3_003 | 마왕 | 담담 | 다정 | base | 발톱표가 여기서 끝나니 진짜 집까지 왔군. |
| V130R_BOND_RIVER_FROG_1_002 | 퐁당 | 담담 | 무표정 | base | 집주인이 누구든, 물은 지켜야 하는 거거든요. |
| V130R_BOND_RIVER_FROG_1_003 | 마왕 | 담담 | 다정 | base | 서른일곱 번째도 읽었다. 다리는 지킨다는 작은 글씨까지. |
| V130R_BOND_RIVER_FROG_2_002 | 퐁당 | 담담 | 무표정 | base | 물방울도 박자만 맞으면 자장가인데요. |
| V130R_BOND_RIVER_FROG_2_003 | 마왕 | 담담 | 다정 | base | 오늘 밤에는 양동이들이 먼저 잠들겠군. |
| V130R_BOND_RIVER_FROG_3_002 | 퐁당 | 담담 | 무표정 | base | 반환은 취소예요. 이제 같이 쓰는 연못이니까. |
| V130R_BOND_RIVER_FROG_3_003 | 마왕 | 담담 | 다정 | base | 요구서 대신 문패라. 내 이름도 들어갈 자리가 있나? |
| V130R_BOND_GLUE_SNAIL_1_002 | 느릿 | 담담 | 속삭임 | base | 기다려…준…사람은… 처음…이에요. |
| V130R_BOND_GLUE_SNAIL_1_003 | 마왕 | 담담 | 다정 | base | 왕좌까지 하루 기다린 보람이 있다. 네 인사는 끝까지 들었다. |
| V130R_BOND_GLUE_SNAIL_2_002 | 느릿 | 담담 | 속삭임 | base | 내 흔적을… 지켜 주는… 집이네요. |
| V130R_BOND_GLUE_SNAIL_2_003 | 마왕 | 담담 | 다정 | base | 까치발이 좀 우스워도 네 흔적을 남겨두겠다. |
| V130R_BOND_GLUE_SNAIL_3_002 | 느릿 | 담담 | 속삭임 | base | 여기서는… 천천히… 살아도… 되죠? |
| V130R_BOND_GLUE_SNAIL_3_003 | 마왕 | 담담 | 다정 | base | 선반 한 칸은 네 것이다. 이삿짐이 다 나올 때까지 비워 두마. |
| V130R_BOND_BRIDGE_TROLL_1_002 | 벙벙 | 담담 | 울먹 | base | 빈칸은… 여기 다리 이름 쓰려고 남겨 둔 거예요. |
| V130R_BOND_BRIDGE_TROLL_1_003 | 마왕 | 담담 | 다정 | base | 마지막 빈칸은 우리 다리다. 이름은 같이 정해도 되겠나? |
| V130R_BOND_BRIDGE_TROLL_2_002 | 벙벙 | 담담 | 울먹 | base | 다리가 단단해지면 저도 단단해져야죠! |
| V130R_BOND_BRIDGE_TROLL_2_003 | 마왕 | 담담 | 다정 | base | 다리 승진이라면 축하는 하겠다. 넥타이는 너무 조이지 마라. |
| V130R_BOND_BRIDGE_TROLL_3_002 | 벙벙 | 담담 | 울먹 | base | 튼튼한 다리 말고, 지키고 싶은 다리를 찾은 거예요. |
| V130R_BOND_BRIDGE_TROLL_3_003 | 마왕 | 담담 | 다정 | base | 팻말은 고맙다. 하지만 네가 다리가 되기 전 우리가 받치겠다. |
| V130R_BOND_UNDER_BED_SHADOW_1_002 | 쉿 | 담담 | 속삭임 | base | 앞에서는… 아직 부끄러워요. |
| V130R_BOND_UNDER_BED_SHADOW_1_003 | 마왕 | 담담 | 당황 | flustered | 망토 먼지가 사라졌다. 정면 인사보다 더 자세히 알아들었다. |
| V130R_BOND_UNDER_BED_SHADOW_2_002 | 쉿 | 담담 | 속삭임 | base | 무서운 것보다… 옆에 있는 게 더 좋은 거였어요. |
| V130R_BOND_UNDER_BED_SHADOW_2_003 | 마왕 | 담담 | 다정 | base | 밤새 괜찮다고 말해 줬구나. 오늘은 네 옆에도 누가 있어 주마. |
| V130R_BOND_UNDER_BED_SHADOW_3_002 | 쉿 | 담담 | 수줍음 | happy | 찾아 주는 사람이 있으면, 그림자도 집이 생겨요. |
| V130R_BOND_UNDER_BED_SHADOW_3_003 | 마왕 | 담담 | 다정 | base | 쉿, 내 앞에 있구나. 이번엔 돌아보지 않아도 찾았다. |
| V130R_BOND_HOLLOW_ARMOR_1_002 | 텅텅 | 담담 | 정의감 | determined | 안이 비어 있어도, 이름은 하나쯤 있어야지. |
| V130R_BOND_HOLLOW_ARMOR_1_003 | 마왕 | 담담 | 다정 | base | 옛 이름을 지우지 않고 네 이름을 보탰군. 잘했다. |
| V130R_BOND_HOLLOW_ARMOR_2_002 | 텅텅 | 담담 | 정의감 | determined | 용사는 혼자인 줄 알았다. 식구가 있는 용사도 있구나. |
| V130R_BOND_HOLLOW_ARMOR_2_003 | 마왕 | 담담 | 다정 | base | 녹을 닦는 손이 있어도 용사는 용사다. 혼자일 필요는 없다. |
| V130R_BOND_HOLLOW_ARMOR_3_002 | 텅텅 | 담담 | 정의감 | determined | 정의는 모르겠다. 하지만 이 자리는 내가 지킨다. |
| V130R_BOND_HOLLOW_ARMOR_3_003 | 마왕 | 담담 | 다정 | base | 레온이 오기 전날의 맹세, 나는 지금도 기억한다. |
| V130R_BOND_CANDLE_WISP_1_002 | 녹녹 | 담담 | 겁 | base | 축하하려고 켜진 불이니까, 쉽게 꺼질 순 없지! |
| V130R_BOND_CANDLE_WISP_1_003 | 마왕 | 담담 | 다정 | base | 케이크에서 온 심지가 이 성을 비췄군. 다음 축하도 부탁한다. |
| V130R_BOND_CANDLE_WISP_2_002 | 녹녹 | 담담 | 겁 | base | 무서운 건 무서운 거고, 할 일은 할 일이야! |
| V130R_BOND_CANDLE_WISP_2_003 | 마왕 | 담담 | 다정 | base | 네 위 양동이보다 침대 위부터 옮긴 걸 봤다. 무서워도 용감했다. |
| V130R_BOND_CANDLE_WISP_3_002 | 녹녹 | 담담 | 비명 | base | 여기선 안 꺼져도 돼. 지켜 주는 지붕이 있으니까. |
| V130R_BOND_CANDLE_WISP_3_003 | 마왕 | 담담 | 다정 | base | 작은 지붕이지만 밤새 지켜 주더군. 네 빛을 나도 지키고 싶었다. |
| V130R_BOND_MOLE_DIGGER_1_002 | 파파 | 담담 | 확인 | base | 안전 제일이라고 외친 건, 날 버린 쪽이 아니라 나였지. |
| V130R_BOND_MOLE_DIGGER_1_003 | 마왕 | 담담 | 다정 | base | 돌아오지 않은 목소리를 네 잘못으로 적지 마라. |
| V130R_BOND_MOLE_DIGGER_2_002 | 파파 | 담담 | 확인 | base | 모두 나갈 길이 있어야 진짜 안전한 현장입니다. |
| V130R_BOND_MOLE_DIGGER_2_003 | 마왕 | 담담 | 다정 | base | 이 작은 표시가 식구 수만큼 있군. 누구도 빠뜨리지 않았구나. |
| V130R_BOND_MOLE_DIGGER_3_002 | 파파 | 담담 | 확인 | base | 구해 준 동료한테는, 제일 좋은 장비를 줘야죠. |
| V130R_BOND_MOLE_DIGGER_3_003 | 마왕 | 담담 | 다정 | base | 곱 머리에 꼭 맞는구나. 이번엔 구한 쪽도 보호받는다. |
| V130R_BOND_CRUMPLED_MAP_1_002 | 꼬깃 | 담담 | 자신만만 | happy | 왕좌가 하나뿐이면 침입자가 너무 쉽잖아! |
| V130R_BOND_CRUMPLED_MAP_1_003 | 마왕 | 담담 | 다정 | base | 왕좌가 셋이면 내가 셋처럼 일해야 하지 않나? |
| V130R_BOND_CRUMPLED_MAP_2_002 | 꼬깃 | 담담 | 자신만만 | happy | 펴고 보니… 내가 그린 길, 다 집으로 가고 있었네. |
| V130R_BOND_CRUMPLED_MAP_2_003 | 마왕 | 담담 | 다정 | base | 장부 누르는 돌이 길도 펴 줬다. 이번엔 집을 제대로 봤구나. |
| V130R_BOND_CRUMPLED_MAP_3_002 | 꼬깃 | 담담 | 자신만만 | happy | 밖에선 헤매게 하고, 안에선 길을 잃지 않게 할게. |
| V130R_BOND_CRUMPLED_MAP_3_003 | 마왕 | 담담 | 다정 | base | 식구 방 표시는 하나도 안 틀렸군. 이제 내가 길을 물어도 되겠다. |
| V130R_BOND_RAT_UNION_1_002 | 찍찍단 | 담담 | 합창 | happy | 찍! 찍! 찍! (계약은 셋이 지킨다!) |
| V130R_BOND_RAT_UNION_1_003 | 마왕 | 담담 | 다정 | base | 발도장 셋, 치즈 한 항목. 서명보다 시끄럽구나. |
| V130R_BOND_RAT_UNION_2_002 | 찍찍단 | 담담 | 합창 | happy | 제일 늦게 오는 동료 몫은 미리 떼어 두는 거다! |
| V130R_BOND_RAT_UNION_2_003 | 마왕 | 담담 | 다정 | base | 야근 수당을 반이나 나눴군. 느릿 몫은 잘 전해졌다. |
| V130R_BOND_RAT_UNION_3_002 | 찍찍단 | 담담 | 합창 | happy | 주인 말고 식구로 하자. 그게 더 오래 간다! |
| V130R_BOND_RAT_UNION_3_003 | 마왕 | 담담 | 다정 | base | 문패 아래에 이름이 나란하군. 이제 소유권 싸움은 끝인가? |
| V130R_BOND_CURSE_DOLL_1_002 | 누비 | 담담 | 무심 | base | 꿰매 준 손은… 저주하지 않을게. |
| V130R_BOND_CURSE_DOLL_1_003 | 마왕 | 담담 | 다정 | base | 서른두 번째 매듭까지 다 기억하는구나. |
| V130R_BOND_CURSE_DOLL_2_002 | 누비 | 담담 | 무심 | base | 무서워해도 괜찮아. 다음엔 놀러 와. |
| V130R_BOND_CURSE_DOLL_2_003 | 마왕 | 담담 | 다정 | base | 답장은 없었어도 사탕이 왔군. 봉투보다 솔직한 모양이다. |
| V130R_BOND_CURSE_DOLL_3_002 | 누비 | 담담 | 무심 | base | 이제 내 몸엔 식구들 바늘땀이 제일 많아. |
| V130R_BOND_CURSE_DOLL_3_003 | 마왕 | 담담 | 다정 | base | 우리 바늘땀이 늘었군. 네가 혼자 아프게 두지 않겠다. |
| V130R_BOND_SPORE_HEALER_1_002 | 모리 | 담담 | 다정 | base | 상처는 천천히 낫는 게 제일 덜 아파. |
| V130R_BOND_SPORE_HEALER_1_003 | 마왕 | 담담 | 다정 | base | 푸딩 위 이불을 밤새 지켰구나. 네 잠자리는 내가 봐 주마. |
| V130R_BOND_SPORE_HEALER_2_002 | 모리 | 담담 | 다정 | base | 습한 곳에서도 예쁘게 자랄 수 있어. |
| V130R_BOND_SPORE_HEALER_2_003 | 마왕 | 담담 | 다정 | base | 곰팡이 대신 권위의 정원인가. 이름은 대단하고 냄새는 순하군. |
| V130R_BOND_SPORE_HEALER_3_002 | 모리 | 담담 | 다정 | base | 이 성이 건강해지면, 나도 피는 거야. |
| V130R_BOND_SPORE_HEALER_3_003 | 마왕 | 담담 | 당황 | flustered | 망토 단추에 꽃이 꽂혔다. 오늘은 허세보다 이걸 먼저 보여 주마. |
| V130R_BOND_STONE_SENTINEL_1_002 | 돌콩 | 담담 | 엄숙 | base | 굴러온 돌이 박힌 돌 된다. 콩. |
| V130R_BOND_STONE_SENTINEL_1_003 | 마왕 | 담담 | 다정 | base | 아무도 못 빼낸 돌이 문지기가 됐군. 이제는 네가 선택해 서는 자리다. |
| V130R_BOND_STONE_SENTINEL_2_002 | 돌콩 | 담담 | 엄숙 | base | 돌도 따뜻해질 수 있다. 콩. |
| V130R_BOND_STONE_SENTINEL_2_003 | 마왕 | 담담 | 다정 | base | 퐁당 물 덕에 이끼가 목도리가 됐구나. 그 색이 잘 맞는다. |
| V130R_BOND_STONE_SENTINEL_3_002 | 돌콩 | 담담 | 엄숙 | base | 내가 서 있는 곳이, 다들 돌아오는 문이다. 콩. |
| V130R_BOND_STONE_SENTINEL_3_003 | 마왕 | 담담 | 다정 | base | 네가 서서 길이 열린다는 말, 잘 기억하겠다. |
| V130R_BOND_WAR_DRUMMER_1_002 | 두둠 | 담담 | 자랑 | happy | 둥! 다시 울리면 다시 시작이다! |
| V130R_BOND_WAR_DRUMMER_1_003 | 마왕 | 담담 | 다정 | base | 버려진 북이 다시 울렸군. 핀도 그 소리를 들었겠지. |
| V130R_BOND_WAR_DRUMMER_2_002 | 두둠 | 담담 | 자랑 | happy | 박자가 너무 좋아서 참을 수가 없었어. 둥… |
| V130R_BOND_WAR_DRUMMER_2_003 | 마왕 | 담담 | 다정 | base | 물방울 박자가 좋은 건 알았다. 다음엔 잠든 식구 박자부터 봐라. |
| V130R_BOND_WAR_DRUMMER_3_002 | 두둠 | 담담 | 자랑 | happy | 새 식구가 오면 채울 자리야. 둥둥! |
| V130R_BOND_WAR_DRUMMER_3_003 | 마왕 | 담담 | 다정 | base | 마지막 소절이 비었군. 아직 만날 식구 자리인가? |
| V130R_BOND_MOON_TRACKER_1_002 | 루미 | 담담 | 속삭임 | base | 달이 없으면 만들면 돼. 작게라도. |
| V130R_BOND_MOON_TRACKER_1_003 | 마왕 | 담담 | 다정 | base | 녹녹을 작은 달이라 부르니 저쪽도 덜 떨더군. |
| V130R_BOND_MOON_TRACKER_2_002 | 루미 | 담담 | 속삭임 | base | 쫓을 건 또 와. 식구는 한 번 놓치면 끝이야. |
| V130R_BOND_MOON_TRACKER_2_003 | 마왕 | 담담 | 다정 | base | 표적을 놓쳤어도 곱을 데려왔다. 보고서 첫 줄은 그거다. |
| V130R_BOND_MOON_TRACKER_3_002 | 루미 | 담담 | 속삭임 | base | 내 표식은 원래 찾으려고 남기는 거야. |
| V130R_BOND_MOON_TRACKER_3_003 | 마왕 | 담담 | 다정 | base | 보이지 않아도 이마가 따뜻하군. 찾으러 온다는 표시라 그런가. |
| V130R_BOND_MIMIC_PORTER_1_002 | 미미 | 담담 | 자신만만 | happy | 열면… 놀라는 건 내가 먼저야. |
| V130R_BOND_MIMIC_PORTER_1_003 | 마왕 | 담담 | 다정 | base | 열지 말라는 쪽지는 네가 붙였군. 허락 전엔 기다리마. |
| V130R_BOND_MIMIC_PORTER_2_002 | 미미 | 담담 | 자신만만 | happy | 이건 아무한테도 안 뱉을 거야. |
| V130R_BOND_MIMIC_PORTER_2_003 | 마왕 | 담담 | 다정 | base | 조약돌 하나가 금화보다 안쪽에 있구나. |
| V130R_BOND_MIMIC_PORTER_3_002 | 미미 | 담담 | 자신만만 | happy | 큰 성이 되면 나도 커질 거야. 다 담을 수 있게. |
| V130R_BOND_MIMIC_PORTER_3_003 | 마왕 | 담담 | 다정 | base | 이사하는 날 짐은 같이 들자. 너까지 짐 속에 숨지는 마라. |
| V130R_BOND_GHOST_HOUSEMAID_1_002 | 베베 | 담담 | 다정 | base | 나는 열쇠가 없어도 돼. 하지만 돌아오는 식구에게는 열린 문이 필요해. |
| V130R_BOND_GHOST_HOUSEMAID_1_003 | 마왕 | 담담 | 다정 | base | 네가 문을 통과해도 우리를 위해 열어 두는 걸 봤다. |
| V130R_BOND_GHOST_HOUSEMAID_2_002 | 베베 | 담담 | 다정 | base | 먼지는 치워도, 그 아래 남은 마음까지 버리면 안 돼. |
| V130R_BOND_GHOST_HOUSEMAID_2_003 | 마왕 | 담담 | 다정 | base | 초대 마왕의 단추를 쓰레기와 구분했구나. 나도 조심히 두마. |
| V130R_BOND_GHOST_HOUSEMAID_3_002 | 베베 | 담담 | 다정 | base | 마지막 한 바퀴는 같이 돌아 줘. 그래야 이 성이 정말 우리 집 같아. |
| V130R_BOND_GHOST_HOUSEMAID_3_003 | 마왕 | 담담 | 다정 | base | 빈 방에 등을 놓으니 내일이 조금 보이는군. 다음 순찰도 같이 돌자. |
| V130R_BOND_GRAVEYARD_HOUND_1_002 | 코코 | 담담 | 확인 | base | 이 뼈는 밥 아니야. 길을 잃지 않게 해 준 약속이야. |
| V130R_BOND_GRAVEYARD_HOUND_1_003 | 마왕 | 담담 | 다정 | base | 묘지기의 약속이었구나. 배가 고파도 안 건드리는 이유를 알았다. |
| V130R_BOND_GRAVEYARD_HOUND_2_002 | 코코 | 담담 | 확인 | base | 한 번 틀려도 괜찮아. 네 냄새를 기억하면 다시 찾을 수 있어. |
| V130R_BOND_GRAVEYARD_HOUND_2_003 | 마왕 | 담담 | 다정 | base | 잘못된 냄새에서 스스로 돌아왔군. 내 손은 여기 있다. |
| V130R_BOND_GRAVEYARD_HOUND_3_002 | 코코 | 담담 | 확인 | base | 집은 한 장소가 아니야. 너에게 돌아오는 길 전부가 집이야. |
| V130R_BOND_GRAVEYARD_HOUND_3_003 | 마왕 | 담담 | 다정 | base | 마지막 푸른 불씨가 왕좌 앞이군. 길 전체가 우리 집이 됐다. |
| V130R_BOND_ARMORED_BEETLE_1_002 | 톡톡 | 담담 | 확인 | base | 내 등은 아직 단단해. 이 판은 네가 먼저 써. |
| V130R_BOND_ARMORED_BEETLE_1_003 | 마왕 | 담담 | 다정 | base | 좋은 판금을 내 갑옷에 먼저 줬군. 다음 장은 네 등을 위한 것이다. |
| V130R_BOND_ARMORED_BEETLE_2_002 | 톡톡 | 담담 | 확인 | base | 고치는 날 말고, 빛나게 하는 날도 필요하구나. |
| V130R_BOND_ARMORED_BEETLE_2_003 | 마왕 | 담담 | 다정 | base | 리벳을 닦아 보니 보라색이 이렇게 밝았나 싶다. |
| V130R_BOND_ARMORED_BEETLE_3_002 | 톡톡 | 담담 | 확인 | base | 성이 뛰는 동안 나도 버틸게. 우리는 같은 껍질 안에 있으니까. |
| V130R_BOND_ARMORED_BEETLE_3_003 | 마왕 | 담담 | 다정 | base | 심장 판금이 굳는 동안 네 등이 성벽이었다. 이제 우리가 받치마. |
| V130R_BOND_SPIDER_TAILOR_1_003 | 실키 | 담담 | 다정 | base | 발이 안 걸리면 위엄도 안 넘어진다. |
| V130R_BOND_SPIDER_TAILOR_1_004 | 마왕 | 담담 | 다정 | base | 그럼 오늘부터 안전한 위엄이라고 부르겠다. |
| V130R_BOND_SPIDER_TAILOR_2_002 | 실키 | 담담 | 다정 | base | 커튼은 돌아보라고 단 게 아니야. 나가는 길 표시야. |
| V130R_BOND_SPIDER_TAILOR_2_003 | 마왕 | 담담 | 다정 | base | 식구들이 살아서 다시 감상하게 하자. |
| V130R_BOND_SPIDER_TAILOR_2_004 | 실키 | 담담 | 미소 | happy | 응. 예쁜 건 나중에도 예쁘니까. |
| V130R_BOND_SPIDER_TAILOR_3_002 | 실키 | 담담 | 다정 | base | 덮개 치수는 머리 기준. 귀는 눌리지 않게 따로 둘게. |
| V130R_BOND_SPIDER_TAILOR_3_003 | 마왕 | 담담 | 다정 | base | 왕관실은 생겼는데 또 치수로 싸우는군. |
| V130R_BOND_SPIDER_TAILOR_3_004 | 실키 | 담담 | 미소 | happy | 쓰는 식구한테 맞아야 왕관도 안 굴러가. |
| V130R_BOND_BAT_COURIER_1_003 | 마왕 | 담담 | 다정 | base | 의회 초청장이 나보다 예의가 빠르군. |
| V130R_BOND_BAT_COURIER_1_004 | 포포 | 담담 | 기쁨 | happy | 다음엔 펼치는 안내도 같이 배달할게! |
| V130R_BOND_BAT_COURIER_2_002 | 마왕 | 담담 | 다정 | base | 경쟁 마왕 우편함에서 되찾았다니 날개가 떨렸겠군. |
| V130R_BOND_BAT_COURIER_2_003 | 포포 | 담담 | 자랑 | happy | 금액을 읽으니까 날개가 알아서 돌아섰어! |
| V130R_BOND_BAT_COURIER_2_004 | 마왕 | 담담 | 다정 | base | 다음엔 주소부터 읽어라. 금액보다 짧다. |
| V130R_BOND_BAT_COURIER_3_002 | 포포 | 담담 | 자랑 | happy | 왕관 대전령을 다 쓰면 받는 사람 이름이 날아가! |
| V130R_BOND_BAT_COURIER_3_003 | 마왕 | 담담 | 다정 | base | 실키의 약칭 자수가 붙으면 직함보다 수령인을 먼저 보자. |
| V130R_BOND_BAT_COURIER_3_004 | 포포 | 담담 | 기쁨 | happy | 좋아! 내 직함보다 식구 이름이 우선 배달! |
| V130R_DUO_LINK_SPORE_JELLY_SHELTER_001 | 모리 | 담담 | 결심 | determined | 포자 이불을 넓히려면 흔들리지 않는 자리가 필요해. |
| V130R_DUO_LINK_SPORE_JELLY_SHELTER_003 | 바티 | 건조 | 냉정 | stern | 두 분이 멈추는 동안 다른 식구가 엄호합니다. |
| V130R_DUO_LINK_SPORE_JELLY_SHELTER_004 | 푸딩 | 담담 | 기쁨 | base | 때리는 건 나중! 지금은 덮어 주는 시간! |
| V130R_DUO_LINK_SPORE_JELLY_SHELTER_005 | 모리 | 담담 | 미소 | happy | 응. 가리는 동안 상처도 조용히 돌보자. |
| V130R_DUO_LINK_SPORE_JELLY_SHELTER_006 | 마왕 | 담담 | 다정 | base | 좋다. 공격 이름처럼 들리는데 식구 쉬는 자리군. |
| V130R_DUO_LINK_GHOSTLY_EVACUATE_001 | 베베 | 담담 | 단호 | determined | 다친 식구가 나갈 틈, 내가 찾을게. |
| V130R_DUO_LINK_GHOSTLY_EVACUATE_002 | 푸딩 | 담담 | 결심 | base | 푸딩이 옆에서 가려! 조금 무거워져도 괜찮아! |
| V130R_DUO_LINK_GHOSTLY_EVACUATE_003 | 바티 | 건조 | 냉정 | stern | 대신 받는 몫만큼 푸딩도 위험해집니다. 무한한 벽은 아닙니다. |
| V130R_DUO_LINK_GHOSTLY_EVACUATE_004 | 베베 | 담담 | 미소 | happy | 그래서 빈자리부터 확인하는 거야. |
| V130R_DUO_LINK_GHOSTLY_EVACUATE_005 | 푸딩 | 담담 | 기쁨 | base | 푸딩 느려져도 기다려 줘! 이삿짐은 같이 와야지! |
| V130R_DUO_LINK_GHOSTLY_EVACUATE_006 | 마왕 | 담담 | 다정 | base | 짐보다 식구를 먼저 센다. 이 성의 이사 원칙이다. |
| V130R_DUO_LINK_MOON_SCENT_HUNT_001 | 곱 | 담담 | 자신만만 | base | 코코, 표적 냄새 봤다? 아니, 맡았다? |
| V130R_DUO_LINK_MOON_SCENT_HUNT_002 | 코코 | 담담 | 결심 | determined | 맡았다. 돌아오는 냄새도 같이. |
| V130R_DUO_LINK_MOON_SCENT_HUNT_003 | 곱 | 담담 | 자신만만 | base | 그럼 곱은 앞으로! 주먹도 앞으로! |
| V130R_DUO_LINK_MOON_SCENT_HUNT_004 | 바티 | 건조 | 냉정 | stern | 추격 뒤에는 두 분 모두 더 위험합니다. 퇴로까지 확인하십시오. |
| V130R_DUO_LINK_MOON_SCENT_HUNT_005 | 코코 | 담담 | 기쁨 | happy | 곱 냄새가 멀어지면 내가 데려와. |
| V130R_DUO_LINK_MOON_SCENT_HUNT_006 | 곱 | 담담 | 흡족 | base | 혼자 앞서면 곱 귀 잡아! 돈은 말고! |
| V130R_DUO_LINK_MOLTEN_CARAPACE_001 | 톡톡 | 담담 | 단호 | determined | 판금 달굴 자리는 비웠다. 톡. |
| V130R_DUO_LINK_MOLTEN_CARAPACE_002 | 핀 | 담담 | 결심 | base | 불은 내가 맡아. 네 등까지 익히는 건 아니고. |
| V130R_DUO_LINK_MOLTEN_CARAPACE_003 | 톡톡 | 담담 | 단호 | determined | 수리 손은 조금 늦어진다. 먼저 알린다. |
| V130R_DUO_LINK_MOLTEN_CARAPACE_004 | 바티 | 건조 | 냉정 | stern | 공격 뒤 수리 대기까지 감당하는 연계입니다. |
| V130R_DUO_LINK_MOLTEN_CARAPACE_005 | 핀 | 담담 | 미소 | base | 알았어. 멋진 불 한 번보다 돌아오는 등 하나가 중요하니까. |
| V130R_DUO_LINK_MOLTEN_CARAPACE_006 | 톡톡 | 담담 | 흡족 | happy | 그 말이면 출발한다. 톡톡. |
| V130R_DUO_LINK_STONE_MARCH_001 | 두둠 | 담담 | 결심 | determined | 돌콩, 한 박자에 한 걸음 어때! |
| V130R_DUO_LINK_STONE_MARCH_002 | 돌콩 | 담담 | 단호 | determined | 멈추는 박자도 넣어라. 콩. |
| V130R_DUO_LINK_STONE_MARCH_003 | 두둠 | 담담 | 결심 | determined | 멈추는 것도 행진곡이지! 둥, 쉼! |
| V130R_DUO_LINK_STONE_MARCH_005 | 돌콩 | 담담 | 감동 | happy | 내가 서면 옆이 길이다. 콩. |
| V130R_DUO_LINK_STONE_MARCH_006 | 두둠 | 담담 | 기쁨 | happy | 좋아! 네가 쉬는 박자까지 식구들이 맞출게! |
| V130R_DUO_LINK_FALSE_BEACON_VAULT_001 | 미미 | 담담 | 당황 | base | 내 안의 가짜 보물… 빛나게 할 수 있어? |
| V130R_DUO_LINK_FALSE_BEACON_VAULT_002 | 루미 | 담담 | 단호 | determined | 응. 표식은 달아도 돌아올 길은 비워 둘게. |
| V130R_DUO_LINK_FALSE_BEACON_VAULT_004 | 미미 | 담담 | 기쁨 | happy | 안 속아도… 식구가 기다리는 쪽은 진짜야. |
| V130R_DUO_LINK_FALSE_BEACON_VAULT_005 | 루미 | 담담 | 미소 | happy | 미끼가 꺼진 뒤엔 네가 쉴 틈도 챙기자. |
| V130R_DUO_LINK_FALSE_BEACON_VAULT_006 | 마왕 | 담담 | 허세 | proud | 가짜는 보물뿐이다. 뒤에서 지켜 주는 건 진짜다. |
| V130R_DUO_PLANNED_WEB_BRIDGE_001 | 퐁당 | 담담 | 단호 | determined | 다리 위에 실을 걸면 제 물가까지 안 들어오겠는데요. |
| V130R_DUO_PLANNED_WEB_BRIDGE_002 | 실키 | 담담 | 단호 | determined | 네 혀가 걸릴 자리는 비워 둘게. |
| V130R_DUO_PLANNED_WEB_BRIDGE_003 | 퐁당 | 담담 | 단호 | determined | 혀까지 꿰매시면 항의할 건데요. |
| V130R_DUO_PLANNED_WEB_BRIDGE_004 | 실키 | 담담 | 미소 | happy | 혀 말고 적의 발. 식구 길은 그대로야. |
| V130R_DUO_PLANNED_WEB_BRIDGE_005 | 마왕 | 담담 | 허세 | proud | 연못과 재봉실의 공동 방어군. 이름부터 든든하다. |
| V130R_DUO_PLANNED_WEB_BRIDGE_006 | 퐁당 | 담담 | 무표정 | base | 그럼 공동 관리에도 반환 요구서는 유효한 건데요. |
| V130R_DUO_PLANNED_SLIPPERY_FLAME_001 | 느릿 | 담담 | 결심 | determined | 제가… 먼저… 길에… |
| V130R_DUO_PLANNED_SLIPPERY_FLAME_002 | 핀 | 담담 | 결심 | base | 응, 다 말할 때까지 불 안 붙여. |
| V130R_DUO_PLANNED_SLIPPERY_FLAME_003 | 느릿 | 담담 | 결심 | determined | 흔적… 남기고… 나올게요… |
| V130R_DUO_PLANNED_SLIPPERY_FLAME_004 | 핀 | 담담 | 미소 | base | 좋아. 네 껍질이 빠진 걸 보고 데울게. |
| V130R_DUO_PLANNED_SLIPPERY_FLAME_005 | 마왕 | 담담 | 허세 | proud | 급할수록 느릿의 마지막 말을 듣는다. 나도 외워 두마. |
| V130R_DUO_PLANNED_SLIPPERY_FLAME_006 | 느릿 | 담담 | 미소 | happy | 기다리는… 불도… 있네요… |
| V130R_DUO_PLANNED_TOLL_VAULT_001 | 벙벙 | 담담 | 간절 | determined | 도둑이 동전을 들고 다리를 건너면 어떻게 하죠? |
| V130R_DUO_PLANNED_TOLL_VAULT_002 | 곱 | 담담 | 자신만만 | base | 곱이 가져온다! 원래 우리 거면 안 훔친 거다! |
| V130R_DUO_PLANNED_TOLL_VAULT_003 | 벙벙 | 담담 | 간절 | determined | 그럼 제가 앞을 막을게요. 통행 사유부터 듣고요! |
| V130R_DUO_PLANNED_TOLL_VAULT_004 | 곱 | 담담 | 흡족 | base | 도망간다는 사유는 반려다! |
| V130R_DUO_PLANNED_TOLL_VAULT_006 | 벙벙 | 담담 | 감동 | happy | 일도 있고 장부도 있네요. 저, 오래 다닐 수 있겠죠? |
| V130R_DUO_PLANNED_MARKED_AMBUSH_001 | 쉿 | 담담 | 속삭임 | base | 빛을 비추면… 제가 보일까 봐… |
| V130R_DUO_PLANNED_MARKED_AMBUSH_002 | 루미 | 담담 | 단호 | determined | 널 비추는 게 아니야. 우리가 볼 대상을 고르는 거야. |
| V130R_DUO_PLANNED_MARKED_AMBUSH_003 | 쉿 | 담담 | 속삭임 | base | 그 뒤에서… 까꿍하면 돼요…? |
| V130R_DUO_PLANNED_MARKED_AMBUSH_004 | 루미 | 담담 | 미소 | happy | 응. 끝나면 내가 남긴 돌아오는 표식을 봐. |
| V130R_DUO_PLANNED_MARKED_AMBUSH_005 | 마왕 | 담담 | 허세 | proud | 기습보다 귀환 설명이 길군. 아주 좋다. |
| V130R_DUO_PLANNED_MARKED_AMBUSH_006 | 쉿 | 담담 | 속삭임 | base | 찾아 주는 빛이면… 무섭지 않네요… |
| V130R_DUO_PLANNED_PLATE_EXCHANGE_001 | 텅텅 | 담담 | 단호 | determined | 이 판금은 내 몸인데 빌려줘도 되는가? |
| V130R_DUO_PLANNED_PLATE_EXCHANGE_002 | 톡톡 | 담담 | 단호 | determined | 식구 등 받치는 동안만. 돌려받는다. 톡. |
| V130R_DUO_PLANNED_PLATE_EXCHANGE_003 | 텅텅 | 담담 | 당황 | base | 정의의 대여 계약인가! 빈 곳이 더 생기는 건 조금 무섭군. |
| V130R_DUO_PLANNED_PLATE_EXCHANGE_004 | 톡톡 | 담담 | 흡족 | happy | 빈 곳은 내가 받친다. 번갈아. |
| V130R_DUO_PLANNED_PLATE_EXCHANGE_006 | 텅텅 | 담담 | 당황 | base | 그럼 내 이름도 판금 안쪽에 남기겠다. 돌아올 자리다. |
| V130R_DUO_PLANNED_CANDLE_EMBER_001 | 녹녹 | 담담 | 비명 | base | 제 불도 셀렌 빛한테 안 밀릴 수 있겠죠?! |
| V130R_DUO_PLANNED_CANDLE_EMBER_002 | 핀 | 담담 | 결심 | base | 먼저 네 물방울부터 피하자. 불씨 얘기는 그다음. |
| V130R_DUO_PLANNED_CANDLE_EMBER_003 | 녹녹 | 담담 | 비명 | base | 동료 불이 옆에 있으니까 비명도 조금 줄겠어요! |
| V130R_DUO_PLANNED_CANDLE_EMBER_004 | 핀 | 담담 | 미소 | base | 줄어든 만큼 우리 편 발밑을 봐 줘. |
| V130R_DUO_PLANNED_CANDLE_EMBER_005 | 마왕 | 담담 | 허세 | proud | 우리 성의 조명 회의는 늘 목소리가 크군. |
| V130R_DUO_PLANNED_CANDLE_EMBER_006 | 녹녹 | 담담 | 기쁨 | happy | 공포 연출이 아니라 업무 열정이에요! |
| V130R_DUO_PLANNED_UNDERGROUND_MARCH_001 | 파파 | 담담 | 단호 | determined | 굴로 이동해도 도착 지점부터 확인합니다. 돌콩, 부탁합니다! |
| V130R_DUO_PLANNED_UNDERGROUND_MARCH_002 | 돌콩 | 담담 | 단호 | determined | 내 옆 비었다. 콩. |
| V130R_DUO_PLANNED_UNDERGROUND_MARCH_003 | 파파 | 담담 | 단호 | determined | 빈 곳이 있어야 식구가 나옵니다. 입구를 버티는 것도 구조죠. |
| V130R_DUO_PLANNED_UNDERGROUND_MARCH_004 | 돌콩 | 담담 | 감동 | happy | 땅 위 길도 남긴다. 콩. |
| V130R_DUO_PLANNED_UNDERGROUND_MARCH_005 | 마왕 | 담담 | 허세 | proud | 로만의 공사보다 우리 귀환 순서가 먼저다. |
| V130R_DUO_PLANNED_UNDERGROUND_MARCH_006 | 파파 | 담담 | 자랑 | happy | 전원 나온 뒤에 완료 도장 찍겠습니다! |
| V130R_DUO_PLANNED_FALSE_MAP_001 | 꼬깃 | 담담 | 당황 | base | 밀로를 왼쪽 오른쪽 셋째 왕좌로 보내자! |
| V130R_DUO_PLANNED_FALSE_MAP_002 | 로로 | 담담 | 결심 | base | 가짜 발자국도 그쪽에 둘게요. 식구 표시는 따로예요. |
| V130R_DUO_PLANNED_FALSE_MAP_003 | 꼬깃 | 담담 | 당황 | base | 이번엔 일부러 틀리는 거야! 자신감이 두 배야! |
| V130R_DUO_PLANNED_FALSE_MAP_004 | 로로 | 담담 | 미소 | base | 그럼 진짜 귀환로는 제가 한 번 더 확인할게요. |
| V130R_DUO_PLANNED_FALSE_MAP_006 | 꼬깃 | 담담 | 자랑 | happy | 알았어! 안쪽 지도는 안 접어! |
| V130R_DUO_PLANNED_FALSE_TREASURE_001 | 찍찍단 | 담담 | 단호 | determined | 니아 유인용 치즈인가? 우리 배식용인가? 중요 안건! |
| V130R_DUO_PLANNED_FALSE_TREASURE_002 | 미미 | 담담 | 당황 | base | 미끼는 가짜… 너희 몫은 따로… |
| V130R_DUO_PLANNED_FALSE_TREASURE_003 | 찍찍단 | 담담 | 단호 | determined | 진짜와 가짜 분리 찬성! 만장일치! |
| V130R_DUO_PLANNED_FALSE_TREASURE_004 | 미미 | 담담 | 기쁨 | happy | 상자를 열 때… 나는 먼저 놀라지 않게 알려 줘. |
| V130R_DUO_PLANNED_FALSE_TREASURE_006 | 찍찍단 | 담담 | 흡족 | happy | 회수조 출근! 치즈는 퇴근 뒤! |
| V130R_DUO_PLANNED_SEWN_BOND_001 | 누비 | 담담 | 간절 | determined | 엄마가 당겨 주면 내가 대신 아파 줄게. |
| V130R_DUO_PLANNED_SEWN_BOND_002 | 실키 | 담담 | 단호 | determined | 전부 대신 아플 필요는 없어. 잡아당기는 건 덜 다치라고 하는 거야. |
| V130R_DUO_PLANNED_SEWN_BOND_003 | 누비 | 담담 | 간절 | determined | 그럼 실이 닿는 데까지만. 끊어지지 않게. |
| V130R_DUO_PLANNED_SEWN_BOND_004 | 실키 | 담담 | 미소 | happy | 네 실밥도 확인할게. 구조에 너도 들어가. |
| V130R_DUO_PLANNED_SEWN_BOND_005 | 마왕 | 담담 | 결심 | serious | 대신 아픈 식구를 혼자 두지 않는 것까지가 연계다. |
| V130R_DUO_PLANNED_SEWN_BOND_006 | 누비 | 담담 | 미소 | happy | 그럼 이 저주는 안 무섭네. 같이 묶이는 거니까. |

## 문장 수정표

없음 — 명백한 오류로 확정할 문장이 없어 본문을 유지했다.
