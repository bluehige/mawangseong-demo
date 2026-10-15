# Lyria 3 source record — v130_final_ending_02_home_after_siege

- Generation model: lyria-3-pro-preview
- Generated date: 2026-10-15
- Target version: v1.3.0
- API: Gemini Interactions API (`v1beta/interactions`, `store=false`)
- Interaction ID: `not returned by the Lyria preview response`
- Source audio path: `assets/source/audio/lyria/v1.3.0/v130_final_ending_02_home_after_siege/source.mp3`
- Runtime audio path: `assets/audio/bgm/v130/final_ending_02_home_after_siege.wav`
- Source SHA-256: `4eb5f8298eea9f282d23387950186d102c0c3beb2368636f019ff8e226f61b69`
- Prompt SHA-256: `cfde865fe72be7f53bb978fde8179dd749c026c57daec1627da9eba2babeb5e2`
- Source reel asset: `v130_final_ending_02_home_after_siege`
- Post-processing: decoded to 44100 Hz, 2 channel(s); render contract `{"channels": 2, "duration_seconds": 132.0, "loop_crossfade_seconds": 2.0, "peak_dbfs": -5.0, "sample_rate": 44100}`.
- Watermark: Lyria-generated audio contains Google's SynthID audio watermark.
- Approval: this file was written only by an explicit `promote --confirm` command.

## 자동 점검 및 채택

- 표시 이름: 귀환의 난롯가 / Hearth of Return / 归来的炉火. 내부 ID 유지.
- 청취 상태: **사용자 청취 전**. 사용자 승인으로 자동 점검 통과 후보를 승격했다. 보컬·음악적 자연스러움은 직접 청취하지 않았다.
- 원본 무변경. 44100Hz/stereo/PCM16, 2초 루프 중첩 후 bgm_quality.py 상수 이득 적용.
- 자동 점검 7/7 PASS. 상세 실측은 generation.json quality_report.
- 길이 130.000000초; LUFS -16.536241; sample peak -4.957117 dBFS; 추정 true peak -4.948082 dBTP; 최대 무음 0.000초; 추가 이득 0.043318dB.
- Runtime SHA-256: `9cbedd6217c901aefd7f3f5b42ff28a82a2295dc481d63d74f65aa23323c1193`
- 이전 HTTP400 거절2회 보존. 이번 사용자 승인 추가1회 성공, SDK 자동 재시도0. 평화로운 귀가·난롯가 전체 프롬프트를 직접 전달했고 기본 전투 문구를 사용하지 않았다. 정확한 요청은 generation.json prompt에 보존. 거절 원인은 서비스가 밝히지 않아 어휘 원인 가설은 미확인이다.
