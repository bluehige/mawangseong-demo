"""Isolated, single-process dialogue layout audit. Never reads personal saves."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import shutil
import csv
import base64
import io
import tarfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/dialogue_overflow"


def prepare():
    OUT.mkdir(parents=True, exist_ok=True)
    if not (OUT / "baseline_head.txt").exists():
        (OUT / "baseline_head.txt").write_bytes(subprocess.check_output(["git","rev-parse","0141647b"],cwd=ROOT))
    if not (OUT / "baseline_files.json").exists():
        paths = subprocess.check_output(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT).decode().split("\0")
        manifest = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths if p and (ROOT / p).is_file() and not p.startswith(("tmp/", "output/", "builds/"))}
        (OUT / "baseline_files.json").write_text(json.dumps(manifest), encoding="utf-8")
        (OUT / "baseline_status.txt").write_bytes(subprocess.check_output(["git", "status", "--porcelain", "-uall"], cwd=ROOT))
    fields = {"text", "text_ko", "text_key", "prompt", "description", "summary", "quote", "speaker_label", "speaker_name", "label", "display_name", "title", "join_dialogue", "battle_bark", "victory_bark", "defeat_bark", "memory_text", "short_text", "instruction", "content", "ending_hint", "activation_hint", "tradeoff"}
    fields.update(prefix+lang for prefix in ("name_", "desc_") for lang in ("ko", "en", "zh_cn"))
    arrays = {"dialogue", "dialogues", "dialogue_templates", "barks", "lines", "prologue", "name_talk", "join_lines", "result_lines", "management_dialogue"}
    rows = []

    def walk(value, path, pointer="", locale="", cue_id="", parent="", spoken=False):
        if isinstance(value, dict):
            cue_id = str(value.get("id", cue_id))
            for k, v in value.items():
                lang = k if k in ("ko", "en", "zh_CN", "zh_cn") else locale
                if k.startswith(("name_", "desc_")) and k.rsplit("_",1)[-1] in ("ko","en"):
                    lang = k.rsplit("_",1)[-1]
                if k.endswith("_zh_cn"): lang = "zh_CN"
                if isinstance(v, str) and (k in fields or spoken or parent in arrays or ("start_flow" in path and k not in ("schema_version",)) or k.startswith("guide_")):
                    if v.strip() and not v.startswith("res://"):
                        rows.append(dict(source=path, pointer=pointer+"/"+k, text=v, key=k, id=cue_id, locale=lang))
                elif isinstance(v, (dict, list)):
                    walk(v, path, pointer+"/"+k, lang, cue_id, k, spoken or k in arrays or k.endswith(("_lines","_dialogue")) or k == "relation_tiers")
        elif isinstance(value, list):
            for i, v in enumerate(value):
                if isinstance(v, str) and (parent in arrays or spoken):
                    rows.append(dict(source=path, pointer=pointer+"/"+str(i), text=v, key=parent, id=cue_id, locale=locale))
                else:
                    walk(v, path, pointer+"/"+str(i), locale, cue_id, parent, spoken)

    files = []
    for p in sorted((ROOT / "data").rglob("*.json")):
        path = p.relative_to(ROOT).as_posix()
        if any(s in path for s in ("/audio/", "/maps/", "/dungeon_quarter/", "/map_builder/", "localization_", "/localization/")):
            # Full translated v130r story documents are independent dialogue sources.
            if "/story/localization_story_" not in path:
                continue
        value = json.loads(p.read_text(encoding="utf-8-sig"))
        locale = "en" if "localization_story_en" in path else "zh_CN" if "localization_story_zh_cn" in path else "ko" if path.startswith("data/v130r/story/") else ""
        start = len(rows)
        walk(value, path, locale=locale)
        if len(rows) > start:
            files.append(dict(path=path, sha256=hashlib.sha256(p.read_bytes()).hexdigest(), fields=len(rows)-start))
    quoted = r'"(?:[^"\\]|\\.)*"'
    inline = re.compile(r'\b(?:localized|loc)\(\s*('+quoted+r')\s*,\s*('+quoted+r')\s*,\s*('+quoted+r')\s*\)', re.S)
    for folder in ("scripts/story", "scripts/ui", "scripts/game", "scripts/map_builder"):
        for p in sorted((ROOT / folder).rglob("*.gd")):
            start = len(rows)
            source = p.read_text(encoding="utf-8-sig")
            for match in inline.finditer(source):
                for locale, literal in zip(("ko","en","zh_CN"), match.groups()):
                    try:
                        value = json.loads(literal)
                    except json.JSONDecodeError:
                        continue
                    if value.strip():
                        rows.append(dict(source=p.relative_to(ROOT).as_posix(), pointer="line:"+str(source.count("\n",0,match.start())+1),text=value,key="text",id="",locale=locale))
            if len(rows)>start:
                files.append(dict(path=p.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),fields=len(rows)-start))
    (OUT / "corpus.json").write_text(json.dumps(rows, ensure_ascii=False), encoding="utf-8")
    (OUT / "sources.json").write_text(json.dumps(files, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Inventory: {len(files)} JSON/script sources, {len(rows)} text fields", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("phase", choices=["prepare", "before", "after", "render", "render-before", "behavior", "fixture", "export", "launch"])
    args = parser.parse_args()
    prepare()
    if args.phase == "prepare":
        return
    wrapper = subprocess.check_output(["where.exe", "godot.cmd"], text=True).strip().splitlines()[0]
    engine = re.search(r'"([^"\r\n]+\.exe)"', Path(wrapper).read_text()).group(1)
    # The console wrapper launches a second Godot process. Run the discovered
    # sibling directly so this task owns exactly one engine process at a time.
    engine = engine.replace("_console.exe", ".exe")
    env = os.environ.copy()
    env["APPDATA"] = str(OUT / "appdata")
    env["LOCALAPPDATA"] = str(OUT / "localappdata")
    env["PYTHONIOENCODING"] = "utf-8"
    env["MAWANG_DISABLE_STEAM"] = "1"
    Path(env["APPDATA"]).mkdir(parents=True, exist_ok=True)
    Path(env["LOCALAPPDATA"]).mkdir(parents=True, exist_ok=True)
    tasks = list(csv.reader(subprocess.check_output(["tasklist.exe","/fo","csv","/nh"],text=True).splitlines()))
    active = [row[0] for row in tasks if row and (row[0].lower().startswith("godot") or row[0].lower()=="mawangdialogue.exe")]
    if active:
        raise RuntimeError("Finish the existing Godot process before starting another: "+", ".join(active))
    cmd = [engine, "--path", str(ROOT), "--audio-driver", "Dummy"]
    audit_root = ROOT
    if args.phase in ("before","render-before"):
        # Recover the immutable starting implementation without switching the
        # mixed worktree or touching any user's files. Assets/imports are read
        # through directory junctions; all writable scripts remain in tmp.
        audit_root = OUT / "baseline_project"
        for folder in ("scripts", "scenes", "addons"):
            shutil.copytree(ROOT / folder, audit_root / folder, dirs_exist_ok=True)
        for name in ("project.godot", "export_presets.cfg"):
            shutil.copy2(ROOT / name, audit_root / name)
        base_head = (OUT / "baseline_head.txt").read_text().strip()
        archive_bytes = subprocess.check_output(["git","archive",base_head,"scripts","scenes","project.godot"],cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive_bytes)) as archive:
            for item in archive:
                if not item.isfile(): continue
                target = audit_root / item.name
                if not target.resolve().is_relative_to(audit_root.resolve()): raise ValueError("Archive escapes baseline workspace")
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.extractfile(item).read())
        shutil.copytree(ROOT / "tools/tests", audit_root / "tools/tests", dirs_exist_ok=True)
        for folder, source in (("assets", ROOT / "assets"), ("data", ROOT / "data"), (".godot/imported", ROOT / ".godot/imported")):
            target = audit_root / folder
            target.parent.mkdir(parents=True, exist_ok=True)
            if not target.exists():
                subprocess.run(["cmd.exe", "/c", "mklink", "/J", str(target), str(source)], stdout=subprocess.DEVNULL, check=True)
        for name in ("global_script_class_cache.cfg", "uid_cache.bin"):
            if (ROOT / ".godot" / name).exists(): shutil.copy2(ROOT / ".godot" / name, audit_root / ".godot" / name)
        baseline_out = audit_root / "tmp/dialogue_overflow"
        baseline_out.mkdir(parents=True, exist_ok=True)
        shutil.copy2(OUT / "corpus.json", baseline_out / "corpus.json")
        cmd = [engine,"--path",str(audit_root),"--audio-driver","Dummy"]
    if args.phase == "launch":
        log = (OUT / "exe.log").open("w", encoding="utf-8")
        cmd = [str(OUT / "exe/MawangDialogue.exe"),"--resolution","920x518","--position","80,80","--audio-driver","Dummy"]
        proc = subprocess.Popen(cmd, env=env, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
        (OUT / "exe_pid.txt").write_text(str(proc.pid))
        print(f"Isolated EXE started: PID {proc.pid}")
        return
    if args.phase == "export":
        # Release templates ignore --script. Keep the real Main entry and all
        # product scripts, adding only a window-sizing autoload in a tmp copy.
        # This prevents CU from opening any image wider than the user's limit.
        audit_root = OUT / "export_project"
        for folder in ("scripts","scenes","addons"):
            shutil.copytree(ROOT / folder,audit_root / folder,dirs_exist_ok=True)
        for name in ("project.godot","export_presets.cfg"):
            shutil.copy2(ROOT / name,audit_root / name)
        for folder, source in (("assets",ROOT / "assets"),("data",ROOT / "data"),(".godot/imported",ROOT / ".godot/imported")):
            destination=audit_root / folder; destination.parent.mkdir(parents=True,exist_ok=True)
            if not destination.exists(): subprocess.run(["cmd.exe","/c","mklink","/J",str(destination),str(source)],stdout=subprocess.DEVNULL,check=True)
        for name in ("global_script_class_cache.cfg","uid_cache.bin"):
            if (ROOT / ".godot" / name).exists(): shutil.copy2(ROOT / ".godot" / name,audit_root / ".godot" / name)
        window_script=audit_root / "scripts/tests/DialogueExeWindow.gd"
        window_script.parent.mkdir(parents=True,exist_ok=True)
        window_script.write_text('extends Node\nfunc _ready() -> void:\n\tget_window().size=Vector2i(920,518)\n\tget_window().position=Vector2i(80,80)\n\tvar file=FileAccess.open("user://cu_window.json",FileAccess.WRITE)\n\tfile.store_string(JSON.stringify({"width":get_window().size.x,"height":get_window().size.y,"user_dir":OS.get_user_data_dir(),"steam_disabled":OS.get_environment("MAWANG_DISABLE_STEAM")}))\n',encoding="utf-8")
        project_file=audit_root / "project.godot"
        project_file.write_text(project_file.read_text(encoding="utf-8-sig").replace('[debug]','DialogueExeWindow="*res://scripts/tests/DialogueExeWindow.gd"\n\n[debug]',1),encoding="utf-8")
        cmd=[engine,"--path",str(audit_root),"--audio-driver","Dummy"]
        target = OUT / "exe/MawangDialogue.exe"
        target.parent.mkdir(exist_ok=True)
        version = subprocess.check_output([engine,"--version"],env=env,text=True).strip().split(".")
        template_version = ".".join(version[:4])
        installed = Path(os.environ["APPDATA"]) / "Godot/export_templates" / template_version
        isolated = Path(env["APPDATA"]) / "Godot/export_templates" / template_version
        isolated.mkdir(parents=True,exist_ok=True)
        for name in ("windows_release_x86_64.exe",):
            if not (isolated / name).exists(): shutil.copy2(installed / name, isolated / name)
        cmd += ["--headless", "--export-release", "Windows Desktop", str(target)]
    else:
        if args.phase not in ("render","render-before"):
            cmd += ["--headless"]
        cmd += ["--resolution", "920x518", "--position", "80,80", "res://tools/tests/DialogueOverflowTest.tscn", "--", "--dialogue-phase="+args.phase]
    preserved_imports = {}
    if args.phase == "export":
        for path in json.loads((OUT / "baseline_files.json").read_text(encoding="utf-8")):
            if path.endswith(".import") and (ROOT / path).is_file():
                preserved_imports[path] = (ROOT / path).read_bytes()
        (OUT / "pre_export_imports.json").write_text(json.dumps({p:base64.b64encode(v).decode() for p,v in preserved_imports.items()}),encoding="utf-8")
    with (OUT / (args.phase+".log")).open("w", encoding="utf-8") as log:
        result = subprocess.run(cmd, env=env, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    restored = []
    for path, original in preserved_imports.items():
        if (ROOT / path).read_bytes() != original:
            (ROOT / path).write_bytes(original)
            restored.append(path)
    if preserved_imports:
        (OUT / "export_import_preservation.json").write_text(json.dumps(dict(checked=len(preserved_imports),restored=restored)),encoding="utf-8")
    lines = (OUT / (args.phase+".log")).read_text(encoding="utf-8", errors="replace").splitlines()
    if args.phase == "before":
        for name in ("before.json","samples.json","before_profiles.json"):
            if (baseline_out / name).exists(): shutil.copy2(baseline_out / name, OUT / name)
    if args.phase == "render-before":
        for picture in baseline_out.glob("before_*.png"): shutil.copy2(picture, OUT / picture.name)
    errors = [line for line in lines if any(x in line for x in ("SCRIPT ERROR", "Parse Error", "ERROR:", "WARNING:"))]
    print(json.dumps(dict(phase=args.phase, exit=result.returncode, errors=errors[:8], error_count=len(errors), tail=lines[-4:]), ensure_ascii=False))
    raise SystemExit(result.returncode or (1 if errors else 0))


if __name__ == "__main__":
    main()
