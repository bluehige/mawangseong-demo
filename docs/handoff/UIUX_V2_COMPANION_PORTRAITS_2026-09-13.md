# UIUX V2 동료 큰 초상·감정 연결

## 1. 메타데이터

- 작성일: 2026-09-13
- 목표 버전: 공개 기준 v1.2.6, 새 제품 버전 미확정
- WORKSTREAM_ID: UIUX-V2-COMPANION-PORTRAITS-20260913
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 main / origin/main / 원격 main: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112
- 시작 HEAD: cada8b765771f564c6c1dd4291bf7d8fd30b02af
- 마지막 구현 커밋 SHA: 6682396a8011cdbc0ba43620e1d9ae5b4724dccf
- 원격 푸시 여부: 미푸시. PR·태그·Release·공개 배포 없음.
- 권위 확인: 선택 작업트리는 시작 시 clean. 브랜치·HEAD·main·origin/main, main:AGENTS.md / main:docs/handoff/CURRENT.md를 확인하고 git ls-remote로 원격 main 일치를 재확인했다.
- AGENTS의 과거 1.2.5 문구는 최신 사용자 지시와 권위 CURRENT의 1.2.6에 대조했다. 기존 v20·출시 태그·루트 혼합 작업트리는 보존했다.

## 2. 이번 세션 목표

사용자의 계속 지시에 따라 이미 입체화한 전투 캐릭터와 큰 초상의 불일치를 줄이고, 실제 표시 경로에서 잘못된 인물·빈 초상 문제를 고친다. 이번 묶음은 동료 기본 초상 4장과 감정 1장, 후반 감정 및 왕관 초상 연결이다. 후반 전투 시트 전체와 진화 미술을 완료한 것이 아니다.

지정 참고는 이전 Chrome에서 확인한 Curse of the Dead Gods 설정/전리품 화면이다(REFERENCE_VERIFIED, 2026-09-12). 이번 캐릭터 정체성 참조는 기존 게임의 uiux3d 시트 4종이다.

## 3. 완료한 작업

- 푸딩·고브·핀·모리의 전용 큰 초상 4장과 고브 eager 표정 1장을 GPT 내부에서 생성했다. 현재 전투 시트의 색·장비·형태와 입체 재질을 참조했다.
- 몬스터 상세와 명단이 작은 전투 프레임을 확대하던 분기를 큰 초상 우선으로 바꿨다. 큰 그림이 없는 경우의 실제 전투 외형 fallback은 유지했다.
- 모리의 characters.json 기본 초상을 푸딩에서 실제 버섯 치유사로 교체했다. 공통 경로를 쓰는 상세·회상·타이틀·원정·결과·대화에 연결했다.
- 새 투명 초상은 대화와 기억 화면에서 전체 비율을 유지하여 귀·뿔·방패가 과도하게 잘리지 않게 했다.
- 후반 characters의 portraits 복수 형식을 공통 대화 해석 경로에서 지원했다. 실키·포포·브라사·베스퍼·미렐라의 기존 감정 그림 18개 경로를 검사했다. 감정이 없거나 일치하지 않으면 실제 base/council로 돌아가며 원본 catalog는 변경하지 않는다.
- 큰 초상은 실제 유닛의 왕관 활성/억제 선택을 따른다. 왕관 6종의 기본·승리·기타 감정 선택을 검사했다. 기억 화면에서 단계1 진화 그림으로 다시 덮던 중복 처리를 제거했다.
- 기억이 없을 때 VBoxContainer에 눌려 사라지던 안내에 실제 최소 높이를 주었다.
- 게임 규칙·AI·전투 시트·16프레임·비용·해금·성장 수치·보상·스토리 문장·저장 구조는 변경하지 않았다. 건설·배치 조작은 기존 구현을 유지했다.

## 4. 변경 파일

구현 커밋 24개 파일.

| 경로 | 변경 목적 |
|---|---|
| data/characters.json | 동료 기본 4장과 고브 eager 경로 5곳 |
| scripts/ui/MonsterWorkspaceUI.gd | 큰 전용 초상 우선 표시와 선형 밉맵 |
| scripts/game/GameRoot.gd | 새 초상 비율 유지, 후반 감정 schema 읽기 |
| scripts/game/ManagementSceneController.gd | 현재 왕관/진화/기본 초상 선택, 기억 빈 상태 표시 |
| assets/sprites/portraits/uiux3d/ | 최종 PNG 5장과 무손실·밉맵 import 5개 |
| assets/source/imagegen/uiux_portraits_20260913/ | 같은 원본 5장, SOURCE.md, .gdignore |
| tools/UIUXPortraitArtTest.gd/.gd.uid/.tscn | 두 해상도·세 글자 배율의 경로/표시/키보드 및 전후 캡처 |

## 5. 그래픽 및 오디오 자산

- Generation model: GPT internal image generation
- [원본·실제 프롬프트·SHA-256](../../assets/source/imagegen/uiux_portraits_20260913/SOURCE.md)
- 기본 4종: pudding_base, gob_base, pynn_base, mori_base. 감정: gob_eager.
- 5장 모두 RGBA, 모서리 alpha 0. 1216×1293 / 1216×1294 / 1254×1254. 런타임 PNG 합계 7,494,036 bytes, 약 7.15 MiB.
- 원본/런타임 PNG 바이트 동일. 로컬 배경 제거·크롭·리사이즈·색상 변환 없음. process/size_limit=0, compress/mode=0, mipmaps/generate=true.
- 푸딩의 초기 RGB 체크무늬 2개 후보는 탈락시켰다. 원래 투명 전투 시트를 다시 참조한 네이티브 RGBA를 채택했다. 도구에는 prompt/reference만 제공되므로 지원하지 않는 background 인수를 넘겼다고 주장하지 않는다.
- 입체 음영의 2D PNG이며 실제 3D 모델은 아니다. 새 오디오 없음.

## 6. 테스트 및 검수

Windows / Godot 4.6.3.stable.official.7d41c59c4 / Vulkan Forward+ / RTX 3060 Ti. APPDATA는 tmp 내부 격리 경로를 사용했다.

| 검사 | 결과 | 근거 |
|---|---|---|
| UIUXPortraitArtTest -- --before | PASS 234개, 기존 126장 | tmp/uiux_portrait_before.log |
| 최종 UIUXPortraitArtTest | PASS 1,414개, 개선 138장 | tmp/uiux_portrait_final.log |
| V122StoryRuntimeIntegrationTest | PASS 58개 | tmp/uiux_portrait_story.log |
| PNG 실제 알파·해상도·원본 동일성 | PASS 5장 | tmp/uiux_portraits_20260913/assets.json, SOURCE.md |
| HTML 이미지 연결 / node --check | PASS 269개 PNG 연결 / JS 문법 | tmp/uiux_portraits_20260913/index.html |
| git diff --check | PASS | 구현 커밋 전 |
| ValidateRepositoryPolicy.ps1 -BaseRef main | 아래 최종 정책 결과에 기록 | tmp/uiux_portrait_policy.log |
| 전체 회귀·전체 캠페인·8인·사람 사용성·다른 플랫폼 | NOT_REQUESTED / 미실시 | 전체 PASS로 확대하지 않음 |

화면은 1920×1080 / 1280×720 × 글자 90/100/115%. 상세 4종 → 실제 Memory 버튼에 Enter 입력 → 회상, 대화 기본 4종/고브 eager/후반 5종, 타이틀, 원정과 결과 presenter를 캡처했다. 결과 화면의 성장 행과 대화 문장은 통제된 표시 fixture이며 실제 전투 완주·원래 이야기 문장을 검증한 캡처로 주장하지 않는다. 스토리의 실제 승급/감정 연결은 별도 58개 기존 검사로 확인했다.

공통 기본 4종, 새 감정, 후반 18개 감정 경로와 기본 fallback, 기존 진화 경로, 왕관 6종의 기본/승리/억제, 원본 catalog 불변, 드래그에 쓰는 실제 전투 시트 보존을 검사했다. 모든 단계의 전투 애니메이션을 이번에 새로 순회한 것은 아니다. 건설/드래그/Undo 검사는 이번 변경 대상이 아니며 직전 작업흐름에서 통과한 기록을 새 실행 결과로 재사용하지 않는다.

전후 같은 장면 126쌍과 왕관 새 캡처 12장 = 총 264장. 최종 대표 720p 115% 상세·대화, 1080p 모리 회상·왕관 회상, 기존 빈 초상과 새 후반 감정 표시를 직접 시각 확인했다. 고브는 의도된 허벅지 위 초상이며 모리·핀·푸딩은 전체 실루엣이다.

초기 import에서 잘못된 함수 위치의 변수 참조 및 Label 타입 추론 오류를 수정했다. 첫 after는 1,414개 중 4개 알파 메타데이터 검사만 실패했다. [Godot 4.6.3 공식 소스](https://github.com/godotengine/godot/blob/4.6.3-stable/scene/resources/compressed_texture.cpp#L215)에서 CompressedTexture2D.has_alpha()가 false를 반환함을 확인했다. 이미 검사 중이던 GPU 이미지의 실제 알파/투명 픽셀을 유지하고 불필요한 has_alpha 검사를 실제 mipmap 검사로 교체했다. 최종 로그에는 FAIL·SCRIPT ERROR·ERROR·WARNING이 없다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 6682396a8011cdbc0ba43620e1d9ae5b4724dccf
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..6682396a8011cdbc0ba43620e1d9ae5b4724dccf
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

portrait_path_audit는 활성 큰 초상 경로와 기존 자산의 읽기 전용 조사 보조다. 별도 전체 검수 에이전트를 실행한 것이 아니며 구현 writer는 root 한 명이다. Reviewed SHA 이후에는 docs/handoff 문서만 변경한다.

## 7. 미해결 항목과 위험

- 돌콩(stone_sentinel), 두둠(war_drummer), 루미(moon_tracker), 미미(mimic_porter)의 큰 기본 초상이 아직 푸딩/고브/로로 그림을 재사용한다. 새 전용 초상과 현재 update4 전투 외형의 일치 작업이 우선이다.
- 로로·적 대화 초상과 나머지 후반 전투 시트, 진화/왕관 미술의 입체 재질 통일은 남았다. 이번에 연결을 고친 후반 5명의 그림 자체는 기존 자산이다.
- 기존 기본 이름 표기는 일부 화면에서 슬라임/고블린/임프 같은 종족명을 사용한다. 동료 이름/진화 이름의 화면 간 일관성도 후속 확인 대상이다.
- 기존 배경·조명·벽/바닥과 새 그림의 전체 조화, 프레임별 자세·효과, 많은 동료 이름표 밀도.
- 이름 입력·기록/회상 전체 구조·상층·전초기지 전투의 정보 구조와 키보드 접근.
- 전체 캠페인·사람 사용성·다른 플랫폼·공개 배포 미실시.

## 8. 다음 작업 순서

1. 돌콩·두둠·루미·미미의 실제 update4 전투 그림을 참조해 전용 큰 초상을 제작하고 characters.json의 타 인물 재사용을 제거한다. 새 기본 초상/현재 전투 모습 일치와 2해상도·3글자 배율 확인이 완료 조건이다.
2. 나머지 후반 캐릭터·적·진화·왕관의 프레임/발 기준점과 큰 초상을 입체 재질로 확장한다. 기존 완료 자산을 재생성하지 않는다.
3. 이름 입력·기록/회상·상층·전초기지 전투의 활성 UI를 개선한다. 관련 직접 검사와 대표 화면을 남기며 새 버전·태그·배포를 자동 실행하지 않는다.

## 9. 작업 트리 상태와 제출

선택 작업트리: tmp/uiux_v2. 구현은 로컬 커밋했고 문서는 별도 로컬 커밋으로 마감한다. 원격 푸시 없음. 루트의 기존 혼합 변경과 다른 브랜치·태그는 보존했다. 캡처·로그·HTML은 소스 커밋에 포함하지 않는다.

비교 페이지: tmp/uiux_portraits_20260913/index.html. 전후 PNG와 JSON은 같은 디렉터리. CURRENT와 미술 잔여 문서를 갱신했다.

## 10. 종료 확인

구현·직접 검사·실제 알파·전후 대표 화면을 확인했다. 전체 검수는 요청되지 않았다. 공개 배포·태그 없음. 최종 정책 검사와 문서 커밋 후 clean 상태를 확인한다.
