"""Generate UTF-8 specialization and paired balance evidence from real Godot runs."""
import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from statistics import mean

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "_mockup/game_step9_spec"

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":")).replace("|", "\\|")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec-only", action="store_true")
    args = parser.parse_args()
    specs = {}
    for path in ["data/specializations.json", "data/regular_version/update4/specializations.json", "data/v130r/specializations_new.json"]:
        values = read(path)
        assert not (specs.keys() & values.keys()), "duplicate specialization IDs"
        specs.update(values)
    assert len(specs) == 48
    assert set(Counter(s["monster_id"] for s in specs.values()).values()) == {2}
    tests = {row["id"]: row for row in read("_mockup/game_step9_spec/spec_results.json")}
    assert set(tests) == set(specs) and all(row["pass"] for row in tests.values())
    direct = read("_mockup/game_step9_spec/direct_checks.json")
    assert not direct["failures"]
    lines = ["# 전문화 효과·검증 표", "", "기준: 0106 `9d1e9bf7` 위, 목표 1.3.0. 기존12 + update4 4 + 신규·보충32 = 24종×2, 중복 ID0. 설명문은 보존했다.",
             "", "선택: 기존 몬스터 관리 → 스킬의 DAY2 해금/팀1명(DAY2~3)/DAY4 추가 선택·변경 불가를 재사용한다. 배치 카드나 배치 몬스터를 클릭하면 옆 정보창에서도 GPT 배지2개로 고른다. Lv3 대체 규칙은 적용하지 않았다. 로로도 전문화 가능하며 실제 합류 명단에서만 정보창을 연다.",
             "", "공통 처리: stat_multipliers/stat_bonuses는 본체에 한 번, skill_mods[skill_id][field]는 기본값에 더하는 차이값, flags는 시간·위치·명중·정산 사건에 적용한다. 구 skill_upgrade는 호환 대체 경로이며 같은 항목을 이중 합산하지 않는다. 기존 실키·포포 서비스의 전문화 ID별 수치 분기도 데이터 조회로 교체했다.",
             "", f"직접 검사 {direct['checks']}개, 실패0. 전문화48/48에 효과1개 이상과 수치 화살표 표시를 검사했다. 신규32개는 실제 시전·상태·정산 결과를 확인했다. 추가로 선택 잠금/영구 선택/종 불일치 거부/복사본 저장·복원/구 형식·잘못된 ID 호환/DAY29 전투 차단을 검사했다.",
             "", "| 몬스터 / 전문화 ID | 이름·원문 효과 | 실제 데이터(배율·가산·스킬 차이·조건) | 개별 검사 |", "|---|---|---|---|"]
    for key, rule in sorted(specs.items(), key=lambda item: (item[1]["monster_id"], item[0])):
        payload = {field: rule[field] for field in ["stat_multipliers", "stat_bonuses", "skill_mods", "flags"] if rule.get(field)}
        if rule.get("ai_behavior"):
            payload["ai_behavior"] = rule["ai_behavior"]
        # Legacy flags remain readable until all older save consumers retire.
        extra = {k: rule[k] for k in ["remove_marked_damage_bonus", "bark_damage_reduction"] if k in rule}
        if extra:
            payload["legacy_flags"] = extra
        row = tests[key]
        effect = rule.get("short_effect", rule.get("description", "")).replace("|", "\\|")
        lines.append(f"| {rule['monster_id']} / `{key}` | {rule['display_name']} — {effect} | `{compact(payload)}` | PASS {row['checks']} |")
    lines += ["", "## 가정·기획과의 차이", "",
              "- 1칸은 기존 전투의71.554175월드px. 범위 미지정인 은신 회복·굴 도착 보호는2칸, 은신 회복은 자신을 포함한 범위 내 생존 아군에 적용한다. 화상은 설명에 피해량이 없어 초당3,2초로 정했다. 재적용은 남은 시간을 갱신한다.",
              "- 웅덩이 합창단은 최종 방어+4, 지도 펼치기는 최종 이동+25%, 바느질 저주는 받는 피해+30%/공격−20%, 회복+20%는 포자 재생과 정화 개화 모두에 적용한다. 포자 재생은2명, 기존 개화는 같은 방 전체다.",
              "- 전투 악단은 기존 같은 방 아군을 유지하면서180px+1칸 반경의 다른 방 아군도 포함한다. 기존 리듬은 숫자 반경이 아닌 같은 방 판정이어서180px를 확장 반경의 기준으로 가정했다. 자장 북은180px의 적 공격 간격을1/0.85배로 바꾸고 아군 방어 버프를 주지 않는다.",
              "- 달빛 길잡이는 표식 위치를 전원 공유하되 기존 수비 칸3칸 이동 한도·사용자 명령·강제 도발을 유지한다. 이동+10%는 표식이 살아 있는6초 동안 공유하며 전장 전체를 무제한 추격하지 않는다. 사냥꾼은 루미 자신의 표식 대상 피해에 적용한다.",
              "- 금고 이빨은 자신이 유인한 대상마다 유인 중 첫 명중1회에 적용한다. 세금 징수원은 기존 통행세로 소지금50%가 떨어지는 규칙을 유지하고 그 금화100%를 전투 종료 때 회수한다. 회수할 금화를 즉시 도둑 소지금에서 빼서 재회수·중복 정산을 막는다.",
              "- 금고 지부는 회수 원금100%와 추가20%를 분리한다. 추가 보상을 도난 손실에서 이중 차감하지 않는다. 실키/포포의 기존 교환 비용도 보존한다.",
              "- 구 전문화의 +12% 표식은 기존 계수1.10→1.22(+12%p), 베베 빗자루+30%는 기존 skill_upgrade 의미인 공격 계수0.9→1.2를 유지한다. 고정 피해8은 유지하므로 전체 최종 피해×1.30과는 다르다.",
              "- **로로 원정 위험−1은 위험 단계 표시·결과 기록에서만1 낮춘다. 기존 원정은 확률 실패/피해 판정이 없고 risk는 설명 문자열이므로 실제 실패 확률이나 피해 감소를 새로 만들지 않았다. 명시 risk_level이 없으면 기존 위험 문구 낮음=1,그 외=2로 표시 단계를 가정했다.** 악명은 기존 지휘+10%에 추가10%를 합산한다. 질문을 남겼으며 답변 없으면 이 해석으로 사용자 확인 대기다.",
              "- 시설 수리는 기존 시설HP 훼손에 적용하며0106 공병의 일시 무력화 시간을 줄이는 효과로 바꾸지 않았다. 기존6개 고유 배지 보존, 배지가 없던42개는 GPT 공통 배지2개를 재사용한다. 종별48개 고유 그림을 생성한 것은 아니다. 실제 알파0..255 검증, NEXON Maplestory 사용. 선택 확정 후 상시·스킬·조건 수치의 전후 화살표를 보여주며 긴 내용은 툴팁으로 제공한다.",
              "", "증거: `spec_results.json`, `direct_checks.json`, `capture_checks.json`, `spec_choose.png`, `spec_info.png`, `spec_battle.png`. PNG·JSON은 로컬 검수 산출물이며 소스 커밋에 넣지 않는다. 전체 회귀·전체 캠페인·export·별도 검수 에이전트는 미요청/미실행. **사용자 확인 대기.**", ""]
    (OUT / "spec_table.md").write_text("\n".join(lines), encoding="utf-8")
    if args.spec_only:
        print(f"spec48 PASS, direct{direct['checks']} PASS")
        return
    rows = read("_mockup/game_step9_spec/balance_rows.json")
    keys = {(int(r["spec_variant"]), int(r["day"]), int(r["trial"])) for r in rows}
    assert keys == {(v, d, t) for v in [-1, 0, 1] for d in [15, 24, 30] for t in range(10)}
    assert len(rows) == 90 and not any(r["timeout"] for r in rows)
    waves = read("data/waves.json")
    assert not waves["day_29"]
    assert all(r["wave_entries"] == waves[f"day_{int(r['day'])}"] for r in rows)
    old = read("_mockup/game_step8b_spread/trial_rows.json")
    pairs = []
    for row in rows:
        if row["spec_variant"] != -1:
            continue
        baseline = next(r for r in old if r["day"] == row["day"] and r["trial"] == row["trial"] and r["layout"] == "recommended")
        fields = ["win", "throne_hp", "duration", "gold_loss", "spawned"]
        assert all(baseline[f] == row[f] for f in fields), (row["day"], row["trial"])
        pairs.append({"day": row["day"], "trial": row["trial"], "fields": fields, "equal": True})
    before_hash = (ROOT / "tmp/v130r_step9/waves.sha256").read_text(encoding="utf-8")
    assert hashlib.sha256((ROOT / "data/waves.json").read_bytes()).hexdigest() == before_hash
    lines = ["# 전문화 적용 후 추천 배치 재측정", "", "DAY15·24·30 × 전문화 없음/첫 선택안 전원/둘째 선택안 전원 × 같은10시드 =90전투. 기존60Hz, seed130800~130809, 날짜별 독립 입력, 옥좌1500·금1200·마나600, 기본E시설Lv1·합법 추천 배치·식량 한도 유지. 성장/합류/계약은0104·0106과 동일하다.",
             "", "48개를 동시에 중첩하지 않는다. 전문화마다 직접 검사는48개 모두 수행하고, 전투에서는 종별2개를ID순으로 정렬한 첫/둘째 안 중 하나씩 선택한다. 24종 명단에 선택을 저장하되 실제 출전은 날짜별 합류·계약·식량 및 수비 칸에 맞는 병력만 한다. 이는 누적 캠페인 전체의 승률이 아니다.",
             "", "`waves.json` SHA256 불변, DAY29는 준비일/전투 없음. 전문화 미적용30행은0106 추천 배치의 승패·옥좌HP·시간·금고 손실·생성 수가 시드별 모두 일치한다. 기존 난이도 곡선 보존을 확인했으며 전문화 성장 때문에 생긴 차이와 구분했다.",
             "", "| DAY | 적용 | 표본 승률 | 평균 옥좌HP | 미적용 대비 HP | 평균 금고 순손실 | 평균 고유 시설 무력화 | 보고 조건 |", "|---:|---|---:|---:|---:|---:|---:|---|"]
    summary = []
    for day in [15, 24, 30]:
        baseline_hp = mean(r["throne_hp"] / 15 for r in rows if r["day"] == day and r["spec_variant"] == -1)
        for variant in [-1, 0, 1]:
            part = [r for r in rows if r["day"] == day and r["spec_variant"] == variant]
            win = mean(bool(r["win"]) for r in part) * 100
            hp = mean(r["throne_hp"] / 15 for r in part)
            gold = mean(r["gold_loss"] for r in part)
            facilities = mean(len({e["building"] for e in r["facility_losses"] if e["building"] in ["barracks", "recovery_nest", "ward_core", "watchtower", "bait_treasure"]}) for r in part)
            alerts = (["승률100%"] if win == 100 else []) + (["옥좌90%↑"] if hp >= 90 else [])
            label = {-1: "미적용", 0: "첫 선택안 전원", 1: "둘째 선택안 전원"}[variant]
            lines.append(f"| {day} | {label} | {win:.0f}% | {hp:.1f}% | {hp-baseline_hp:+.1f}%p | {gold:.1f} | {facilities:.1f} | {', '.join(alerts) or '—'} |")
            summary.append({"day":day,"variant":variant,"trials":10,"win_percent":win,"mean_throne_percent":hp,"gold_loss":gold,"alerts":alerts})
    lines += ["", "## 선택안 대응표", "", "| 몬스터 | 첫 선택안 | 둘째 선택안 |", "|---|---|---|"]
    for species in sorted({s["monster_id"] for s in specs.values()}):
        options = sorted(k for k, s in specs.items() if s["monster_id"] == species)
        lines.append(f"| {species} | {specs[options[0]]['display_name']} | {specs[options[1]]['display_name']} |")
    lines += ["", "판정: 전문화 성장 효과를 관찰했으며 웨이브를 재조정하지 않았다. 상향뿐 아니라 공격/방어·지원 간 교환 비용과 AI 변화가 있어 특정 날짜·선택안이 미적용보다 어려울 수 있다. 승률100% 또는 평균 옥좌90% 이상인 행은 위 표에 그대로 표시한다. 시설 손실은 영구 파괴가 아닌 일시 무력화다.",
              "", "실험 중 완료된 행을 저장하고 재개했다. 재개 전 행은 전문화 미적용으로, 이후 추가한 시험 도구의 전문화 통행세 정산과 무관하다. 호위 이동 요청을 적 추격으로 바꾸던 배치 어댑터도 보정했고 해당 분기가 활성화되는 둘째 선택안30행은 새로 측정했다. 미적용/첫안60행에서는 이 분기가 실행되지 않는다. 같은 시드·60Hz를 유지했다. 직접/화면/밸런스 검사와 원본 파일 보존은 인계에 기록한다. **사용자 확인 대기.**", ""]
    (OUT / "balance_with_spec.md").write_text("\n".join(lines), encoding="utf-8")
    (OUT / "balance_summary.json").write_text(json.dumps({"summary":summary,"baseline_pairs":pairs,"waves_unchanged":True}, ensure_ascii=False, indent=2), encoding="utf-8")
    print("balance90 PASS; baseline30 identical; waves unchanged")

if __name__ == "__main__":
    main()
