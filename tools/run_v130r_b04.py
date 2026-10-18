"""Serial real-campaign B04 runner; all saves live in isolated test profiles."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time
import psutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/v130r_b04"

def engines():
    result = []
    for proc in psutil.process_iter(["pid", "name", "cmdline"]):
        try:
            if "godot" not in (proc.info["name"] or "").lower():
                continue
            if str(ROOT).lower().replace("\\", "/") in " ".join(proc.info["cmdline"] or []).lower().replace("\\", "/") or Path(proc.cwd()).resolve() == ROOT:
                result.append(proc.info)
        except psutil.Error:
            pass
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--label", default="baseline")
    parser.add_argument("--seeds", default="130401")
    parser.add_argument("--rendered", action="store_true")
    parser.add_argument("--last-day", type=int, default=30)
    parser.add_argument("--layout", default="recommended")
    parser.add_argument("--full-raster", action="store_true")
    parser.add_argument("--checkpoint", default="")
    parser.add_argument("--day", type=int, default=1)
    parser.add_argument("--retries", type=int, choices=[0,1], default=1)
    parser.add_argument("--stack-source", default="")
    parser.add_argument("--stack-days", default="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,30")
    args = parser.parse_args()
    assert not engines(), engines()
    folder = OUT / args.label
    folder.mkdir(parents=True, exist_ok=True)
    wave_bytes = (ROOT / "data/waves.json").read_bytes()
    (folder / "input_waves.json").write_bytes(wave_bytes)
    early_bytes = (ROOT / "data/v122/dual_front_day01_05_waves.json").read_bytes()
    (folder / "input_early_waves.json").write_bytes(early_bytes)
    input_paths = ["data/waves.json", "data/v122/dual_front_day01_05_waves.json", "scripts/game/GameRoot.gd", "scripts/game/ApprovedBattleController.gd", "scripts/map_builder/ApprovedMonsterPlacement.gd", "scripts/map_builder/ApprovedPlacement.gd", "tools/tests/V130RB04Campaign.gd", "tools/tests/V130RB04FastController.gd", "tools/tests/V130RB04FastUnit.gd"]
    if args.stack_source:
        input_paths.append("tools/tests/V130RB04Stacking.gd")
    input_paths.append("tools/tests/V130RB04FastMap.gd")
    input_hashes = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in input_paths}
    (folder / "input_hashes.json").write_text(json.dumps(input_hashes, indent=2), encoding="utf-8")
    wrapper = Path(subprocess.check_output(["where.exe", "godot.cmd"], text=True).splitlines()[0])
    exe = re.search(r'"([^"\r\n]+\.exe)"', wrapper.read_text()).group(1).replace("_console.exe", ".exe")
    env = os.environ.copy()
    env.update(APPDATA=str(folder / "appdata"), LOCALAPPDATA=str(folder / "localappdata"), MAWANG_DISABLE_STEAM="1")
    for key in ("APPDATA", "LOCALAPPDATA"):
        Path(env[key]).mkdir(exist_ok=True)
    command = [exe, "--path", str(ROOT), "--rendering-method", "gl_compatibility", "--resolution", "1280x720"]
    if not args.rendered:
        command.append("--headless")
    scene="V130RB04Stacking" if args.stack_source else "V130RB04Campaign"
    command += ["--scene", "res://tools/tests/"+scene+".tscn", "--", "label=" + args.label, "seeds=" + args.seeds, "last_day=" + str(args.last_day), "layout=" + args.layout]
    if args.stack_source:
        command += ["stack_source="+args.stack_source, "stack_days="+args.stack_days]
    command += ["retries="+str(args.retries)]
    if args.full_raster:
        command += ["raster=full"]
    if args.checkpoint:
        command += ["checkpoint="+args.checkpoint, "day="+str(args.day)]
    started = time.monotonic()
    peak = 0
    with (folder / "stdout.log").open("w", encoding="utf-8") as stdout, (folder / "stderr.log").open("w", encoding="utf-8") as stderr:
        process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=stdout, stderr=stderr, creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            while process.poll() is None:
                peak = max(peak, len(engines()))
                errors = (folder / "stderr.log").read_text(encoding="utf-8", errors="replace")
                if time.monotonic() - started > 7200 or "SCRIPT ERROR" in errors or peak > 1:
                    process.kill()
                    break
                time.sleep(.3)
            process.wait(timeout=10)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
    stderr = (folder / "stderr.log").read_text(encoding="utf-8", errors="replace")
    result = dict(command=command, exit_code=process.returncode, seconds=round(time.monotonic()-started, 2), peak_godot=peak, godot_after=engines(), stderr=stderr, waves_sha256=hashlib.sha256(wave_bytes).hexdigest(), waves_unchanged_during_run=wave_bytes==(ROOT / "data/waves.json").read_bytes())
    result["inputs_unchanged"] = all(hashlib.sha256((ROOT / p).read_bytes()).hexdigest()==digest for p,digest in input_hashes.items())
    (folder / "run.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=True))
    return 0 if process.returncode == 0 and not engines() and "ERROR:" not in stderr else 1

if __name__ == "__main__":
    raise SystemExit(main())
