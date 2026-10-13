"""One rendered Godot replay at a time, with one-second OS/engine evidence.

Use --project tmp/v1213_perf/before --out tmp/v1213_perf/run_before.
Snapshots contain the instrumented scripts; production scripts stay untouched.
"""
import argparse
import atexit
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

import psutil


METHODS = {
    "scripts/game/GameRoot.gd": ["_tutorial_build_overlay", "_tutorial_badge_overlaps_management_ui", "_evaluate_facility_placement", "_management_label_layout", "_set_screen", "_story_tick_auto"],
    "scripts/game/BuildingPlacementController.gd": ["target_room"],
    "scripts/ui/HUDController.gd": ["_fit_label_to_bounds", "_fit_rich_label_to_bounds", "clear"],
    "scripts/ui/ReadableTooltipButton.gd": ["_make_custom_tooltip"],
    "scripts/ui/PlayerContinuityUI.gd": ["tick"],
}


def godot_snapshot():
    # Fetch command lines in process_iter's guarded snapshot. A game can exit
    # between CPU sampling and enumeration; avoid querying a stale PID later.
    return [{"pid":p.pid,"name":p.info["name"],"cmd":p.info["cmdline"] or []}
            for p in psutil.process_iter(["name","cmdline"],ad_value=None)
            if p.info["name"] and "godot" in p.info["name"].lower()]


def instrument(project, source):
    harness = project / "tmp/perf_harness"
    harness.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source / "tools/tests/PerfFreezeScenario.gd", harness / "Scenario.gd")
    (harness / "Scenario.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tmp/perf_harness/Scenario.gd" id="1"]\n[node name="Replay" type="Node"]\nscript = ExtResource("1")\n', encoding="utf-8")
    (harness / "Counters.gd").write_text('''extends Node
var values := {}
func record(id: String, started: int) -> void:
	var row: Dictionary = values.get(id,{"calls":0,"usec":0,"max_usec":0})
	var elapsed := Time.get_ticks_usec()-started
	row.calls += 1
	row.usec += elapsed
	row.max_usec = maxi(row.max_usec,elapsed)
	values[id] = row
func take() -> Dictionary:
	var result := values.duplicate(true)
	values.clear()
	return result
''', encoding="utf-8")
    for name, methods in METHODS.items():
        path = project / name
        original = path.read_text(encoding="utf-8")
        # Refresh instrumentation, including snapshots prepared by an earlier
        # invocation. Source files in the user's worktree are never touched.
        original = "\n".join(line for line in original.splitlines() if "var perf_started_usec :=" not in line and "PerfCounters.record(" not in line)
        lines = original.splitlines()
        result, active, header = [], None, False
        for line in lines:
            if line.startswith("func "):
                if active:
                    result.append(f'\tPerfCounters.record("{active}",perf_started_usec)')
                active = None
                m = re.match(r"func (\w+)\(", line)
                if m and m[1] in methods:
                    active = path.stem + "." + m[1]
                    header = True
                result.append(line)
                if active and line.rstrip().endswith(":"):
                    result.append("\tvar perf_started_usec := Time.get_ticks_usec()")
                    header = False
                continue
            if active and header:
                result.append(line)
                if line.rstrip().endswith(":"):
                    result.append("\tvar perf_started_usec := Time.get_ticks_usec()")
                    header = False
                continue
            if active and re.match(r"^\s*return\b", line):
                indentation = line[:len(line)-len(line.lstrip())]
                result.append(f'{indentation}PerfCounters.record("{active}",perf_started_usec)')
            inline = re.match(r"^(\s*)(if\s+.+):\s*(return(?:\s+.*)?)$",line) if active else None
            if inline:
                indentation, condition, returned = inline.groups()
                result.extend([indentation+condition+":",indentation+f'\tPerfCounters.record("{active}",perf_started_usec)',indentation+"\t"+returned])
                continue
            result.append(line)
        if active:
            result.append(f'\tPerfCounters.record("{active}",perf_started_usec)')
        path.write_text("\n".join(result)+"\n", encoding="utf-8")
    config = project / "project.godot"
    content = config.read_text(encoding="utf-8")
    if "PerfCounters=" not in content:
        content = content.replace("[autoload]", '[autoload]\n\nPerfCounters="*res://tmp/perf_harness/Counters.gd"')
        config.write_text(content, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--renderer", default="")
    parser.add_argument("--disable-vsync", action="store_true")
    parser.add_argument("--title-only", action="store_true")
    parser.add_argument("--cap-probe", action="store_true")
    parser.add_argument("--max-fps", type=int)
    parser.add_argument("--hotpaths-only", action="store_true")
    parser.add_argument("--prepare-only", action="store_true")
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[2]
    project, out = args.project.resolve(), args.out.resolve()
    if not project.is_relative_to(source / "tmp/v1213_perf"):
        raise ValueError("Only instrument a disposable snapshot under tmp/v1213_perf")
    out.mkdir(parents=True, exist_ok=True)
    instrument(project, source)
    if args.prepare_only:
        return
    wrapper = Path(shutil.which("godot.cmd"))
    match = re.search(r'^"([^"]+\.exe)"', wrapper.read_text(), re.M)
    engine = match[1]
    env = os.environ.copy()
    env["APPDATA"] = str(out / "profile")
    Path(env["APPDATA"]).mkdir(exist_ok=True)
    args_engine = [engine, "--path", str(project), "--windowed", "--resolution", "1920x1080", "--verbose", "res://tmp/perf_harness/Scenario.tscn", "--", "--perf-out="+out.as_posix()]
    if args.renderer:
        args_engine[1:1] = ["--rendering-method", args.renderer]
    if args.disable_vsync:
        args_engine.insert(1,"--disable-vsync")
    if args.max_fps is not None:
        args_engine[1:1] = ["--max-fps",str(args.max_fps)]
    if args.title_only:
        args_engine.append("--title-only")
    if args.cap_probe:
        args_engine.append("--cap-probe")
    if args.hotpaths_only:
        args_engine.append("--hotpaths-only")
    user32 = ctypes.windll.user32
    user32.GetForegroundWindow.restype = wintypes.HWND
    user32.SetForegroundWindow.argtypes = [wintypes.HWND]
    user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND,ctypes.POINTER(wintypes.DWORD)]
    user32.IsWindow.argtypes = [wintypes.HWND]
    previous_window = user32.GetForegroundWindow()
    background_applied = False
    def background_window():
        nonlocal previous_window
        callback_type = ctypes.WINFUNCTYPE(wintypes.BOOL,wintypes.HWND,wintypes.LPARAM)
        def find_window(hwnd, _):
            nonlocal previous_window
            title = ctypes.create_unicode_buffer(512)
            user32.GetWindowTextW(hwnd,title,512)
            if user32.IsWindowVisible(hwnd) and title.value == "ChatGPT":
                previous_window = hwnd
                return False
            return True
        user32.EnumWindows(callback_type(find_window),0)
        # ALT grants normal Windows foreground activation. Attaching input
        # queues can retain the game's keyboard focus after foreground moves,
        # so it must not be used for an inactive-window measurement.
        user32.keybd_event(0x12,0,0,0)
        try:
            user32.SetForegroundWindow(previous_window)
        finally:
            user32.keybd_event(0x12,0,2,0)
    before = godot_snapshot()
    if before:
        raise RuntimeError("Another Godot process is running; finish it before this replay: "+str(before))
    (out / "metadata.json").write_text(json.dumps({"args":args_engine,"godot_before":before,"logical_cpus":psutil.cpu_count(),"start":time.time()},indent=2),encoding="utf-8")
    with (out / "verbose.log").open("w",encoding="utf-8") as log, (out / "os.jsonl").open("w",encoding="utf-8") as osfile:
        creationflags = subprocess.CREATE_NO_WINDOW
        process = subprocess.Popen(args_engine,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=creationflags)
        def cleanup():
            if process.poll() is None:
                try:
                    owned = psutil.Process(process.pid).children(recursive=True)
                    for child in owned: child.terminate()
                    process.terminate()
                    psutil.wait_procs(owned,timeout=5)
                except psutil.NoSuchProcess:
                    pass
        atexit.register(cleanup)
        tracked = psutil.Process(process.pid)
        tracked.cpu_percent()
        psutil.cpu_percent()
        last_size, last_second = 0, time.monotonic()
        deadline = time.monotonic()+450
        while process.poll() is None:
            if time.monotonic() >= deadline:
                cleanup()
                raise TimeoutError("Performance replay exceeded 450 wall-clock seconds")
            time.sleep(max(0,1.0-(time.monotonic()-last_second)))
            last_second = time.monotonic()
            try:
                children = tracked.children(recursive=True)
                if children and tracked.name().endswith("_console.exe"):
                    tracked = max(children,key=lambda p:p.memory_info().rss)
                    tracked.cpu_percent()
                cpu = tracked.cpu_percent()/psutil.cpu_count()
                ram = tracked.memory_info()
            except psutil.NoSuchProcess:
                break
            godot_processes = godot_snapshot()
            procs = [p["pid"] for p in godot_processes]
            gui_pids = [p["pid"] for p in godot_processes if not p["name"].endswith("_console.exe") and "--headless" not in p["cmd"]]
            gpu = subprocess.run(["C:/Windows/System32/nvidia-smi.exe","--query-gpu=utilization.gpu,memory.used,power.draw","--format=csv,noheader,nounits"],capture_output=True,text=True,creationflags=creationflags)
            size = (out/"verbose.log").stat().st_size
            foreground_pid = wintypes.DWORD()
            user32.GetWindowThreadProcessId(user32.GetForegroundWindow(),ctypes.byref(foreground_pid))
            row = {"wall_ms":time.time()*1000,"pid":tracked.pid,"launcher_pid":process.pid,"cpu_pct_machine":cpu,"rss_mib":ram.rss/1048576,"private_mib":ram.private/1048576,
                   "system_cpu_pct":psutil.cpu_percent(),"available_mib":psutil.virtual_memory().available/1048576,"godot_pids":procs,"godot_count":len(procs),"gui_pids":gui_pids,"gui_count":len(gui_pids),"gpu_global":gpu.stdout.strip(),"log_bytes_s":size-last_size,"foreground_pid":foreground_pid.value,"os_focused":foreground_pid.value==tracked.pid}
            last_size=size
            osfile.write(json.dumps(row)+"\n");osfile.flush()
            engine_file = out / "engine.jsonl"
            if engine_file.exists():
                tail = engine_file.read_text(encoding="utf-8").splitlines()
                if tail:
                    inactive = json.loads(tail[-1])["stage"].endswith("background")
                    if inactive and not background_applied:
                        background_window()
                        background_applied = True
                    elif not inactive:
                        background_applied = False
        return_code = process.wait()
        remaining = [p["pid"] for p in godot_snapshot()]
        owned_pids = [process.pid,tracked.pid]
        result = {"exit_code":return_code,"godot_after":remaining,"owned_pids":owned_pids,
                  "owned_godot_after":[pid for pid in remaining if pid in owned_pids],
                  "other_godot_after":[pid for pid in remaining if pid not in owned_pids]}
        (out/"completion.json").write_text(json.dumps(result),encoding="utf-8")
        print(json.dumps(result))


if __name__ == "__main__":
    main()
