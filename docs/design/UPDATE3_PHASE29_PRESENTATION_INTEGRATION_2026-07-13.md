# 3차 업데이트 Phase 29 완료 기록 — 최종 프레젠테이션 통합

작성일: 2026-07-13

## 구현 결과

- 신규 적 6종에 4×4 최종 프레임 시트를 연결했다. 각 시트는 대기 2, 아래 방향 2, 이동 4, 공격 4, 기술 4의 총 16프레임을 제공한다.
- 석골·포식·몽등 심장의 Stage 02/03/04 장식 9종과 비활성 표시, 선택 아이콘, 발동 효과를 연결했다.
- 합동기 6종의 문장과 발동 효과, 세 전선 문장·최종 라이벌 문장, 연대기 세 전선 지도, 상태 아이콘 16종을 연결했다.
- 심장·합동기·신규 적·보스·몬스터용 효과음 31개를 생성하고 실제 재생 경로에 연결했다.
- 같은 효과음은 동시에 한 번만 재생하고, 3차 업데이트 효과음은 최대 4개, 심장 반복음은 최대 1개만 겹치도록 제한했다.
- 마젠타 임시 배경은 실행 중 셰이더로 투명 처리한다. 셰이더는 이미지의 붉은색·보라색 본체를 지우지 않도록 색 균형과 명도 차이를 함께 검사한다.
- 1920×1080과 1366×768에서 심장 선택, 전선 선택, 연대기 지도, 적 프레임, 심장·합동기 자원을 직접 촬영해 잘림과 UI 겹침이 없음을 확인했다.

## 원본·생성 기록

- 신규 적 원본: `assets/source/imagegen/update3_enemy_atlases/SOURCE.md`
- 프레젠테이션 원본: `assets/source/imagegen/update3_presentation/SOURCE.md`
- 엔딩 원본: `assets/source/imagegen/update3_endings/SOURCE.md`
- 오디오 생성 기록: `assets/audio/update3/SOURCE.md`
- 재현 가능한 오디오 생성기: `tools/generate_update3_audio.py`

## 웹 내보내기 용량 감사

- 실제 Web 내보내기: `output/phase29_web/`
- 전체 크기: 244,761,500바이트, 약 233.42 MiB
- PCK 게임 자료 묶음: 206,274,816바이트, 약 196.72 MiB
- WebAssembly 실행 파일: 38,047,590바이트, 약 36.29 MiB
- Phase 29 실행용 신규 자원 42개: 26,003,192바이트, 약 24.80 MiB
- 배포에서 제외한 제작 원본: 226,218,641바이트, 약 215.74 MiB
- `assets/source`, `docs`, `tmp`, `output`, `tools`는 Web 배포 묶음에서 제외한다.

## 검증

- `PresentationPhase29Test`: 110/110 PASS
- `PresentationPhase29VisualReview`: PASS
- `EndingPhase28Test`: 45/45 PASS
- `SaveV4MigrationTest`: 42/42 PASS
- `Update3DataContractTest`: 17/17 PASS
- Godot 프로젝트 전체 파싱: PASS
- Web release export: PASS

시각 검수 산출물은 `tmp/update3_phase29/`에 저장했다.
