# Lyria 3 source record — v130_final_ending_03_truce_lanterns

- Generation model: lyria-3-pro-preview
- Generated date: 2026-10-15
- Target version: v1.3.0
- API: Gemini Interactions API (`v1beta/interactions`, `store=false`)
- Interaction ID: `not returned by the Lyria preview response`
- Source audio path: `assets/source/audio/lyria/v1.3.0/v130_final_ending_03_truce_lanterns/source.mp3`
- Runtime audio path: `assets/audio/bgm/v130/final_ending_03_truce_lanterns.wav`
- Source SHA-256: `2cda4e144aafb9b61b52203274f00a0adc6059e57f3f1886e6c236b6431e63c1`
- Prompt SHA-256: `ecc795a6a0a53ef42416d902228e5ebdd6a304a903ad5cffc84609effe7d53f1`
- Source reel asset: `v130_final_ending_03_truce_lanterns`
- Source reel run: `tmp/lyria_audio_v130/v130-20261015-remaining`
- Post-processing: decoded to 44100 Hz, 2 channel(s); render contract `{"channels": 2, "duration_seconds": 128.0, "loop_crossfade_seconds": 2.0, "peak_dbfs": -5.0, "sample_rate": 44100}`.
- Watermark: Lyria-generated audio contains Google's SynthID audio watermark.
- Approval: this file was written only by an explicit `promote --confirm` command.

## 자동 점검 및 채택

- 청취 상태: **사용자 청취 전**. 2026-10-15 사용자 위임으로 자동 점검 통과 후보를 승격했다.
- 보컬 유무·음악적 자연스러움·장면 적합성은 직접 청취로 확인하지 않았다.
- 원본 무변경; 파이프라인의 2초 루프 크로스페이드 후 `tools/audio/bgm_quality.py`로 상수 이득만 적용했다.
- 추가 이득: -0.559834 dB; 기존 장면 곡 LUFS 중앙값 -16.536239 기준.
- 최종 실측: 126.000000초, -16.536240 LUFS, 피크 -5.560135 dBFS, 4배 오버샘플 피크 추정 -5.507587 dBTP.
- -60 dBFS 미만 최대 연속 무음: 0.000초(50ms RMS 창). 루프 경계 차이 0.00112915, 일반 인접 차이 99.9백분위 0.07968140.
- 검사 기준: 길이90~150초·피크/추정true peak≤-3·연속무음<1초·기준음량±1LU·경계차≤일반transient. 자동 점검 PASS.
- Runtime SHA-256: `3f4e6b561629cc991871c9444e97554f5270c429ee8b412633f8c0a52fd0fa53`
- 재현 환경: numpy1.26.4/scipy1.15.2/pyloudnorm0.2.0(ITU-R BS.1770 integrated loudness). 상세 수치는 generation.json의 quality_report.
- 성공 생성 1회, 총 요청 1회, SDK 전송 재시도0; `store=false`. Google SynthID 표기는 서비스 설명이며 워터마크 검출을 별도 수행하지 않았다.
- 서비스 참고: https://ai.google.dev/gemini-api/docs/music-generation / https://ai.google.dev/gemini-api/terms . 개별 이용권·독점권을 별도 보증하지 않는다.
