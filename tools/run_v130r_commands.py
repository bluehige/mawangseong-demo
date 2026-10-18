"""Serial isolated command tests; never open the player's save profile."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

from run_v130r_b04 import engines

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["unit", "paired", "capture"], default="unit")
    parser.add_argument("--label")
    args = parser.parse_args()
    assert not engines(), engines()
    label = args.label or args.mode
    assert re.fullmatch(r"[a-zA-Z0-9_-]+", label)
    folder = ROOT / "tmp/v130r_commands" / label
    folder.mkdir(parents=True, exist_ok=True)
    inputs = ["scripts/game/ApprovedBattleController.gd", "scripts/game/GameRoot.gd", "scripts/ui/ApprovedBattleUI.gd", "tools/tests/V130RCommandsTest.gd", "data/waves.json"]
    inputs += [str(p.relative_to(ROOT)).replace("\\", "/") for p in (ROOT / "data").rglob("*") if p.is_file()]
    hashes = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in inputs}
    wrapper = Path(subprocess.check_output(["where.exe", "godot.cmd"], text=True).splitlines()[0])
    exe = re.search(r'"([^"\r\n]+\.exe)"', wrapper.read_text()).group(1).replace("_console.exe", ".exe")
    env = os.environ.copy()
    env.update(APPDATA=str(folder / "appdata"), LOCALAPPDATA=str(folder / "localappdata"), MAWANG_DISABLE_STEAM="1")
    for key in ("APPDATA", "LOCALAPPDATA"):
        Path(env[key]).mkdir(exist_ok=True)
    cmd = [exe, "--path", str(ROOT), "--rendering-method", "gl_compatibility", "--resolution", "1920x1080"]
    if args.mode != "capture":
        cmd.append("--headless")
    cmd += ["--scene", "res://tools/tests/V130RCommandsTest.tscn", "--", "label=" + label]
    if args.mode == "unit":
        cmd.append("unit=true")
    if args.mode == "capture":
        cmd.append("capture=true")
    start = time.monotonic()
    peak = 0
    timed_out = False
    with (folder / "stdout.log").open("w", encoding="utf-8") as out, (folder / "stderr.log").open("w", encoding="utf-8") as err:
        proc = subprocess.Popen(cmd, cwd=ROOT, env=env, stdout=out, stderr=err, creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            while proc.poll() is None:
                peak = max(peak, len(engines()))
                errors = (folder / "stderr.log").read_text(encoding="utf-8", errors="replace")
                timed_out = time.monotonic() - start > 2400
                if timed_out or "SCRIPT ERROR" in errors or peak > 1:
                    proc.kill()
                    break
                time.sleep(.3)
            proc.wait(timeout=10)
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
    result = dict(exit_code=proc.returncode, seconds=round(time.monotonic()-start, 2), peak_godot=peak, godot_after=engines(), timed_out=timed_out, inputs_unchanged=all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p, h in hashes.items()), input_hashes=hashes)
    (folder / "run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    errors = (folder / "stderr.log").read_text(encoding="utf-8", errors="replace")
    print(json.dumps({k:v for k,v in result.items() if k!="input_hashes"}))
    if errors:
        print(errors[-6000:])
    return 0 if proc.returncode == 0 and not errors and not engines() and result["inputs_unchanged"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
