"""Validate complete paired command evidence, with per-seed throne HP checks."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def report(label):
    folder = ROOT / "tmp/v130r_commands" / label
    rows = json.loads((folder / "battles.json").read_text(encoding="utf-8"))
    failures = []
    pairs = []
    for day in (5, 15, 27, 30):
        for seed in (130401, 130402, 130403):
            matches = [r for r in rows if (r["day"], r["seed"]) == (day, seed)]
            modes = {r["policy"]: r for r in matches}
            if len(matches) != 2 or set(modes) != {"none", "crisis"}:
                failures.append(f"D{day} seed {seed}: incomplete/duplicate pair")
                continue
            baseline, command = modes["none"], modes["crisis"]
            for key in ("entry_file_sha256", "hp_start", "max_hp_start", "defenders"):
                if baseline[key] != command[key]:
                    failures.append(f"D{day} seed {seed}: unequal {key}")
            if baseline["commands"] or [c["id"] for c in command["commands"]] != ["focus_attack", "hold_ground"]:
                failures.append(f"D{day} seed {seed}: missing actual command use")
            passed = int(command["win"]) >= int(baseline["win"]) and command["hp"] >= baseline["hp"]
            if not passed:
                failures.append(f"D{day} seed {seed}: commands worsen win/HP")
            pairs.append(dict(day=day, seed=seed, baseline_win=baseline["win"], command_win=command["win"], baseline_hp=baseline["hp"], command_hp=command["hp"], hp_delta=command["hp"]-baseline["hp"], baseline_survivors=baseline["survivors"], command_survivors=command["survivors"], passed=passed))
    if len(rows) != 24:
        failures.append(f"Expected 24 battles, got {len(rows)}")
    result = dict(battles=len(rows), pairs=pairs, failures=failures, accepted=not failures)
    (folder / "comparison.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if pairs:
        with (folder / "comparison.csv").open("w", encoding="utf-8-sig", newline="") as out:
            writer = csv.DictWriter(out, fieldnames=pairs[0].keys())
            writer.writeheader()
            writer.writerows(pairs)
    print(json.dumps(result, ensure_ascii=True))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("label")
    raise SystemExit(0 if report(parser.parse_args().label)["accepted"] else 1)
