"""Send JSON actions on stdin to the isolated graphical Godot audit scene."""
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tmp/v1213_uiux_audit"


def send(actions, timeout=55):
    identity = str(time.time_ns())
    pending = OUT / "command.pending"
    pending.write_text(json.dumps({"id": identity, "actions": actions}, ensure_ascii=False), encoding="utf-8")
    pending.replace(OUT / "command.json")
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            response = json.loads((OUT / "response.json").read_text(encoding="utf-8"))
            if response["id"] == identity:
                return response
        except (FileNotFoundError, json.JSONDecodeError):
            pass
        time.sleep(0.1)
    raise TimeoutError(f"Audit command {identity} did not complete; inspect profile.log")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    result = send(json.load(sys.stdin))
    state = result["state"]
    print(json.dumps({"screen": state["screen"], "day": state["day"], "tutorial": state["tutorial"], "stage": state["stage"], "dialogue": [state["dialogue_index"], state["dialogue_count"]], "story": [state["story_scene"], state["story_cursor"], state["story_active"]], "buttons": state["buttons"], "errors": [r for r in result["results"] if isinstance(r["result"], dict) and "error" in r["result"]]}, ensure_ascii=False, indent=2))
