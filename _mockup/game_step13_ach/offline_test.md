# Steam 없는 실행과 큐 — TARGETED_PASS · 사용자 확인 대기

실행: `tools/run_v130r_step13.ps1 -Mode offline` → 640검사, 실패 0, stderr 비어 있음. MAWANG_DISABLE_STEAM=0으로 공식 DLL의 실제 초기화를 호출했다. Steam 클라이언트 프로세스가 없는 환경에서 initialized=false/status=offline, 초기화 18.075ms. GameRoot 타이틀/Start 버튼까지 정상 구성했다. Steam 실행·재시작·네트워크 응답 대기는 없다.

별도 시험 프로필에 해제/진행도를 저장하고 다시 로드해 pending이 보존되는지 확인했다. 모의 Steam을 연결해 다음 실행의 전송 → store 실패 → 재전송 → 성공 확인 콜백 → 해당 배치만 제거되는 순서를 검사했다. 전송 중 추가된 stat는 남겨 다음 배치로 보냈다. API 수락 거절도 큐를 유지한다. 프로필 쓰기에 실패하면 Steam 전송을 먼저 하지 않는다.

실제 release EXE도 Steam이 없는 상태에서 격리 APPDATA/LOCALAPPDATA, headless 60프레임 부팅·정상 종료했다. export_smoke.err.log 비어 있음. 실제 Steam 계정에 전송하거나 해제를 확인한 시험은 아니다. 사용자 PC 순서는 인계서 8절에 있다.

근거: offline_runtime.json, offline_checks.json, direct_checks.json, tmp/v130r_step13/offline.log 및 export_smoke.log. 실행 종료 Godot 0, 동시 최대 1. 사용자 저장은 열거나 수정하지 않았다.
