"""Run B02/B03 checks serially in fresh, isolated profiles."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import time
import psutil
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tmp/v130r_b02_b03"

def engines():
    found = []
    for process in psutil.process_iter(["pid", "name", "cmdline"]):
        try:
            if "godot" not in (process.info["name"] or "").lower(): continue
            command = " ".join(process.info["cmdline"] or []).replace("\\", "/").lower()
            if str(ROOT).replace("\\", "/").lower() in command or Path(process.cwd()).resolve() == ROOT:
                found.append(process.info)
        except psutil.Error: pass
    return found

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--scene", default="V130RFixB02B03Test")
    parser.add_argument("--rendered", action="store_true")
    options = parser.parse_args()
    assert not engines(), engines()
    folder = OUT / (Path(options.scene).stem + ("_rendered" if options.rendered else "_headless"))
    folder.mkdir(parents=True, exist_ok=True)
    wrapper = Path(subprocess.check_output(["where.exe", "godot.cmd"], text=True).splitlines()[0])
    exe = re.search(r'"([^"\r\n]+\.exe)"', wrapper.read_text()).group(1).replace("_console.exe", ".exe")
    env = os.environ.copy()
    env.update(APPDATA=str(folder / "appdata"), LOCALAPPDATA=str(folder / "localappdata"), MAWANG_DISABLE_STEAM="1")
    for key in ("APPDATA", "LOCALAPPDATA"): Path(env[key]).mkdir(exist_ok=True)
    command = [exe, "--path", str(ROOT), "--rendering-method", "gl_compatibility", "--resolution", "1280x720"]
    if not options.rendered: command += ["--headless"]
    command += ["--scene", ("res://"+options.scene+".tscn" if "/" in options.scene else "res://tools/tests/" + options.scene + ".tscn"), "--", "--b02-b03", "--checks-only", "--mode=direct", "--ach-mode=direct"]
    started = time.monotonic()
    peak = 0
    with (folder / "stdout.log").open("w", encoding="utf-8") as stdout, (folder / "stderr.log").open("w", encoding="utf-8") as stderr:
        process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=stdout, stderr=stderr, creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            while process.poll() is None:
                peak = max(peak, len(engines()))
                errors = (folder / "stderr.log").read_text(encoding="utf-8", errors="replace")
                if time.monotonic() - started > 600 or "SCRIPT ERROR" in errors or peak > 1:
                    process.kill(); break
                time.sleep(.25)
            process.wait(timeout=10)
        finally:
            if process.poll() is None: process.kill(); process.wait()
    stderr = (folder / "stderr.log").read_text(encoding="utf-8", errors="replace")
    stdout = (folder / "stdout.log").read_text(encoding="utf-8", errors="replace")
    result = dict(command=command, exit_code=process.returncode, seconds=round(time.monotonic()-started, 2), peak_godot=peak, godot_after=engines(), stderr=stderr, tail=stdout[-3000:])
    (folder / "run.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=True))
    return 0 if process.returncode == 0 and not engines() and "ERROR:" not in stderr else 1
if __name__ == "__main__": raise SystemExit(main())
