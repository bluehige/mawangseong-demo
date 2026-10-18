"""Serial B01 checks with fresh test profiles; never access player saves."""
import argparse
import importlib.util
import json
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("case", choices=["unit", "replay", "continuous"])
    parser.add_argument("--seed", type=int, default=13011)
    parser.add_argument("--rendered", action="store_true")
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location(
        "audit_runner", ROOT / "_mockup/release_audit_v130/run_audit.py")
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    runner.OUT = ROOT / "tmp/v130r_b01"
    runner.STATE = runner.OUT / "profiles"
    name = f"{args.case}_{args.seed}_{'rendered' if args.rendered else 'headless'}_{datetime.now():%Y%m%d_%H%M%S}"
    relative = f"res://tmp/v130r_b01/{name}"
    result = runner.run(name, ["--scene", "res://tools/tests/V130RFixB01Test.tscn",
                              "--", "campaign", f"case={args.case}",
                              f"seed={args.seed}", f"out={relative}"],
                        timeout=900, gui=args.rendered)
    check_file = runner.OUT / name / "checks.json"
    if check_file.exists():
        checks = json.loads(check_file.read_text(encoding="utf-8"))
        print(json.dumps(checks, ensure_ascii=True))
    else:
        checks = None
    return 0 if (result["exit_code"] == 0 and not result["timeout"]
                 and result["error_lines"] == 0 and checks is not None
                 and not checks["failures"] and not result["engines_after"]) else 1


if __name__ == "__main__":
    sys.exit(main())
