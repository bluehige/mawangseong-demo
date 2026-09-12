# UIUX V2 계약 동료 초상·전투 미술

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 공개 기준 v1.2.6, 새 제품 버전 미확정
- WORKSTREAM_ID: UIUX-V2-CONTRACT-ART-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 main / origin/main / 원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD: 8da16ebcff02008204c9357c699e8cb28e25d1c0
- 마지막 구현 커밋 SHA: 2ab6eb3663d1c7454fac555210c58a8753f0eab4
- 원격 푸시 여부: 미푸시. PR·태그·Release·공개 배포 없음.
- 선택 작업트리 tmp/uiux_v2의 clean 상태·브랜치·HEAD·main·origin/main과 main:AGENTS.md / main:docs/handoff/CURRENT.md를 시작 시 확인했다. git ls-remote로 원격 main 일치를 재확인했다.
- AGENTS의 과거 1.2.5 문구는 최신 사용자 지시와 권위 CURRENT의 1.2.6에 대조했다. 기존 v20·출시 태그·루트 혼합 작업트리를 보존했다.

## 2. 이번 세션 목표

사용자의 계속 지시에 따라 돌콩·두둠·루미·미미가 다른 인물의 큰 초상을 재사용하는 문제를 제거하고, 같은 네 동료의 전투 그림을 입체 재질로 맞춘다. 기존 대기/이동/공격/기술/쓰러짐과 체격·부유 동작을 유지하고 실제 상세·회상·대화·관리·전투에서 확인한다.

지정 참고는 이전 Chrome에서 확인한 Curse of the Dead Gods 설정/전리품 화면이다(REFERENCE_VERIFIED, 2026-09-12). 이번 캐릭터 정체성 참조는 실제 게임의 update4/monster_dolkong, dudum, moon, mimi 시트다. 다른 게임을 같은 원본으로 취급하지 않았다.

## 3. 완료한 작업

- 돌콩의 현무암 가고일, 두둠의 해골 북 연주자, 루미의 보라색 달빛 추적자, 미미의 나무 미믹 모습을 보존한 큰 초상 4장과 전투 시트 4장을 내부 생성했다.
- characters.json 기본 초상 4개와 monsters.json sprite 4개만 교체했다. 푸딩/고브/로로 초상 재사용을 제거했다.
- 기존 공통 초상 선택 경로와 실제 전투 생성 경로에 연결했다. 지도·수비대 카드·배치 미리보기는 같은 현재 전투 시트의 대기 프레임을 쓴다.
- 정확히 16프레임: 첫 행 대기 2/쓰러짐 2, 다음 행 이동 4/공격 4/기술 4. UIUXActorArt의 GPU AtlasTexture 영역과 384 논리 여백을 사용하며 PNG를 작게 다시 저장하지 않는다.
- 기존 large_grounded / normal_grounded / small_flying / normal_grounded 체격·동작 분류를 유지했다. 발 기준은 논리 y=346이며 실제 idle/down 불투명 바닥은 y=344~346이다.
- 두둠 쓰러짐 프레임에 이웃 그림 한 열이 보이던 부분, 루미의 공격 효과가 다음 칸에 넘어가던 부분을 영역 측정 도구에서 제외했다. 칸 경계에서 들어오는 분리 조각과 부드러운 여백에 들어온 이웃의 불투명 픽셀을 구분한다. 원본 PNG는 바꾸지 않는다.
- 새 네 동료의 이전 프로필을 기존 비교 fixture에 추가해 원래 그림과 체격을 재현할 수 있게 했다.
- 데이터 구조·비용·능력치·성장·AI·보상·스토리·저장 구조를 변경하지 않았다. 기존 건설·확정·Undo 코드는 이번 묶음에서 변경하지 않았다.

## 4. 변경 파일

구현 커밋 38개 파일.

| 경로 | 변경 목적 |
|---|---|
| data/characters.json | 기본 큰 초상 4개 경로 |
| data/monsters.json | 실제 전투 시트 4개 경로 |
| data/uiux_actor_art.json | 새 64프레임 영역·논리 여백·보이는 몸체 측정 |
| data/v122/combat_visual_profiles.json | 기존 4개 체격과 동작 보존, 새 크기/발 기준·원본·별칭 |
| assets/sprites/portraits/uiux3d/ | 큰 초상 4장과 손실 없는 밉맵 import |
| assets/sprites/uiux3d/ | 전투 시트 4장과 손실 없는 밉맵 import |
| assets/source/imagegen/uiux_contract_art_20260913/ | 동일 원본 8장, SOURCE.md, .gdignore |
| tools/UIUXContractArtTest.gd/.gd.uid/.tscn | 실제 UI·키보드·전투 연결, 두 해상도·세 글자 배율 |
| tools/tests/UIUXContractArtPixelsTest.py | 원본 해시·알파·64프레임 픽셀·발 기준·혼입 재발 검사 |
| tools/measure_uiux_actor_art.py | 표시 여백에 이웃 프레임 조각이 들어오지 않게 측정 |
| tools/UIUXActorArtTest.gd | 증거 경로 인수, 큰 동료 비교 화면의 잘림 방지 |
| tools/fixtures/uiux_actor_legacy_profiles.json | 새 4종의 기존 프로필 보존 |
| tools/tests/V122CombatVisualRuntimeProfileContractTest.gd | 4종 네이티브 아틀라스·기존 경로 별칭·동작 계약 |

## 5. 그래픽 및 오디오 자산

- Generation model: GPT internal image generation
- [실제 프롬프트·원본·출력 경로·SHA-256](../../assets/source/imagegen/uiux_contract_art_20260913/SOURCE.md)
- 큰 초상: dolkong_base / dudum_base / moon_base / mimi_base.
- 전투 시트: stone_sentinel / war_drummer / moon_tracker / mimic_porter.
- 최종 8장 RGBA. 좌상단 alpha 0, 네 모서리 최대 1/255의 투명 잔여값. 불투명 체크무늬가 아니다.
- 초상 1223×1286 / 1254×1254 / 1254×1254 / 1402×1122, 전투 4장 모두 1254×1254. 런타임 합계 약 16.00 MiB.
- 원본/런타임 바이트 동일. 로컬 배경 제거·크롭·축소·색 변환 없음. 실제 프롬프트에 투명 PNG 요구를 전달했으며 인터페이스에 없는 background 인수를 사용했다고 주장하지 않는다.
- 루미·미미의 처음 RGB 체크무늬 초상은 미채택했고, 원래 투명 전투 그림을 참조해 내부 생성으로 다시 만들었다.
- 손실 없는 import, mipmap=true, size_limit=0. 원본 폴더는 .gdignore로 게임 import에서 제외한다.
- 실제 3D 모델이 아닌 입체 재질의 2D PNG다. 오디오 변경 없음.

## 6. 테스트 및 검수

Windows / Godot 4.6.3.stable.official.7d41c59c4 / Vulkan Forward+ / RTX 3060 Ti. APPDATA는 tmp 내부 전용 경로로 격리했다. 네이티브 실행은 순차 수행했다.

| 검사 | 결과 | 근거 |
|---|---|---|
| UIUXContractArtTest -- --before | PASS 437개, 120개 흐름 캡처 | tmp/uiux_contract_before_verified.log |
| 최종 UIUXContractArtTest | PASS 1,505개, 120개 흐름 캡처 | tmp/uiux_contract_after_verified.log |
| 최종 UIUXActorArtTest | PASS 590개 | tmp/uiux_contract_actor_final.log |
| UIUXContractArtPixelsTest.py | PASS 394개 | tmp/uiux_contract_pixels.log |
| V122CombatVisualHierarchyTest | PASS | tmp/uiux_contract_V122CombatVisualHierarchyTest.log |
| V122CombatVisualProfileContractTest | PASS | tmp/uiux_contract_V122CombatVisualProfileContractTest.log |
| V122CombatVisualRuntimeProfileContractTest | PASS | tmp/uiux_contract_V122CombatVisualRuntimeProfileContractTest.log |
| JSON 변경 한정 검사 | characters/monsters 각각 4개 그림 경로 외 모든 데이터 동일 | 시작 HEAD와 구조 비교 |
| HTML 연결·캡처 해상도 / node --check | PASS 256개 이미지 연결 / JS 문법 | tmp/uiux_contract_art_20260913/index.html |
| git diff --check | PASS | 구현 커밋 전 |
| Repository policy | 문서 커밋 뒤 실행·아래 종료 기록에 결과 추가 | tmp/uiux_contract_policy.log |
| 전체 회귀·DAY 1~30·8인·사람 사용성·다른 플랫폼 | NOT_REQUESTED / 미실시 | 전체 PASS로 확대하지 않음 |

1920×1080 / 1280×720 × 글자 90/100/115%에서 네 동료의 상세·Memory 버튼 Enter·기억 없음·통제 대화·실제 수비대 탭·카드 Enter·ESC 취소·기존 전투 진입 및 유닛 생성 경로를 확인했다. 키보드 배치 진입/취소와 기존 방 불변을 검사했다. 이번 묶음에서 새로 마우스 드래그 전체·건설 확정·Undo를 반복 검사한 것은 아니다.

fixture는 두 계약 선택과 보유 출전 규칙을 검증하며, 핵심 동료·대상·모리를 소유하고 대상/특화 고브를 출전시킨다. 후반 동료를 DAY2 전투에 통제 배치한 경로 검사다. 전체 해금·원래 이야기·캠페인 진행 증거가 아니다. 지도에는 기존 구현에 따라 예비 동료도 보인다. 대화 문장은 표시 시험용이며 기억은 미해금 상태다. 글자 속성 검사는 상세에서 수행했고 다른 화면은 캡처·경로 확인 범위다.

기존 12종 아틀라스, 진화·왕관·라이벌의 실제 sprite 경로와 프레임을 보존 검사했다. 프로필 검사는 기존 오래된 시트 경로를 입력해도 새 기본형을 선택하는 별칭과, 별도 진화·왕관을 기본형으로 덮지 않는 경우를 포함한다.

비교 페이지는 실제 흐름 120쌍과 같은 렌더러의 동작 비교 4쌍이다. 최종 720p 115% 지도/전투/미미 상세·대화, 1080p 돌콩 상세와 동작 시트를 직접 시각 확인했다. 모든 PNG를 사람이 개별 검수했다고 주장하지 않는다.

초기 검사의 수정 사항: 가변 fixture를 const로 둔 오류, 고브 미출전으로 특화 준비가 거부되던 상태, 계약 수 1종 및 잘못된 탭 식별자, 숫자 Array의 정수/실수 비교 오판을 고쳤다. 수정 전 실패를 게임 규칙 변경으로 우회하지 않았다. 픽셀/동작 확인에서 발견한 프레임 조각 혼입을 수정하고 최종 1,505/590/394 검사를 다시 실행했다. 최종 게임 로그에 ERROR·WARNING·FAIL 없음.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 2ab6eb3663d1c7454fac555210c58a8753f0eab4
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..2ab6eb3663d1c7454fac555210c58a8753f0eab4
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

contract_actor_path_audit는 읽기 전용 경로/fixture 조사 보조이며 별도 전체 검수 에이전트를 실행한 것이 아니다. root만 파일을 수정했다. Reviewed SHA 뒤에는 docs/handoff만 변경한다.

## 7. 미해결 항목과 위험

- 루미는 기존 small_flying 목표 약 59.30px에 맞췄다. 이전 median=125와 idle 실측 145의 차이로 기존 idle 약 68.8px보다 새 표시가 작아졌으며 실제 720p 전투에서 확인했다. 체격 분류·부유·그림자 규칙은 유지했다.
- 예비 동료도 관리 지도에 보이는 기존 표시와 많은 동료가 한곳에 모일 때의 밀도. 출전/예비 상태를 더 명확히 구분할 후속 개선이 필요하다.
- 로로·실키·포포·나머지 후반 동료/적·진화·왕관의 큰 초상과 전투 미술 통일. 기본 입체 시트는 총 12종까지 연결된 상태다.
- 일부 화면의 슬라임/고블린/임프 종족명과 동료 이름 일관성, 이름 입력·기록/회상·상층·전초기지 메뉴의 정보 구조/키보드 접근.
- 배경·벽·바닥·조명과 새 그림의 최종 조화, 프레임별 주관적 미술 품질, 전체 캠페인·사람 사용성·다른 플랫폼 확인은 남았다.

## 8. 다음 작업 순서

1. 수비대의 출전/예비·이름·지도 표시를 실제 상태와 대조하고 정보 구조와 과밀 표시를 개선한다. 기존 편성 규칙을 보존하며 실제 UI 직접 검사와 전후 화면을 남긴다.
2. 로로·실키·포포와 나머지 후반 적/동료의 활성 그림 경로를 조사해 전용 큰 초상과 전투 미술을 확장한다. 완료한 12종은 임의 재생성하지 않는다.
3. 이름 입력·기록/회상·상층·전초기지의 남은 메뉴 개선을 이어간다. 새 버전·태그·공개 배포를 자동 실행하지 않는다.

## 9. 작업 트리 상태

선택 작업트리 tmp/uiux_v2에서 구현을 로컬 커밋했다. 문서는 별도 로컬 커밋으로 마감한다. 원격 푸시 없음. 루트의 기존 혼합 변경과 다른 작업트리/출시 태그는 보존했다. 캡처·로그·HTML은 tmp/uiux_contract_art_20260913 및 tmp/uiux_contract_*.log에 있으며 소스 커밋에 포함하지 않는다.

## 10. 종료 확인

실제 동료 미술 연결, 관련 자동 검사와 대표 게임 화면, 원본 출처를 확인했다. CURRENT와 잔여 문서를 갱신했다. 전체 미술 완료 또는 전체 캠페인 PASS로 기록하지 않는다. 공개 배포·태그 없음.
