"""Join one-second engine and OS samples; emit reproducible comparison rows."""
import argparse
import csv
import json
from pathlib import Path
import statistics


def summarize(directory):
    directory = Path(directory)
    engine = [json.loads(line) for line in (directory / "engine.jsonl").read_text(encoding="utf-8").splitlines()]
    samples = [json.loads(line) for line in (directory / "os.jsonl").read_text(encoding="utf-8").splitlines()]
    metadata = json.loads((directory / "metadata.json").read_text(encoding="utf-8"))
    joined, summary = [], []
    for row in engine:
        os_row = min(samples,key=lambda x:abs(x["wall_ms"]-row["wall_ms"]))
        merged = dict(row)
        merged.update({key:value for key,value in os_row.items() if key != "wall_ms"})
        merged["gpu_pct_global"] = float(os_row["gpu_global"].split(",")[0])
        merged["alignment_ms"] = abs(os_row["wall_ms"]-row["wall_ms"])
        joined.append(merged)
    for stage in dict.fromkeys(x["stage"] for x in joined):
        # Native focus is switched after the first sample, then TIME_FPS still
        # reports the previous second. Cold placement fixtures likewise need
        # their first rendered world/layout samples to settle.
        warmup = 4 if stage.endswith("background") or (stage == "placement" and "--hotpaths-only" in metadata["args"]) else 2
        rows = [x for x in joined if x["stage"] == stage and x["stage_s"] > warmup]
        if stage == "transition" or not rows:
            continue
        info = {"run":directory.name,"stage":stage,"samples":len(rows),"warmup_s":warmup,"screens":sorted(set(x["screen"] for x in rows))}
        for key in ["fps","frame_mean_ms","frame_p95_ms","process_ms","physics_ms","cpu_pct_machine","rss_mib","private_mib","gpu_pct_global","draw_calls"]:
            info[key+"_mean"] = round(statistics.mean(x[key] for x in rows),3)
        for key in ["frame_max_ms","nodes","objects","orphans","rss_mib","cpu_pct_machine","godot_count","log_bytes_s"]:
            info[key+"_max"] = round(max(x[key] for x in rows),3)
        info["rss_start_end_mib"] = [round(rows[0]["rss_mib"],2),round(rows[-1]["rss_mib"],2)]
        info["nodes_min"] = min(x["nodes"] for x in rows)
        info["objects_min"] = min(x["objects"] for x in rows)
        info["engine_focused_samples"] = sum(x["focused"] for x in rows)
        info["os_focused_samples"] = sum(x.get("os_focused",False) for x in rows)
        names = set().union(*(set(x["counters"]) for x in rows))
        info["counters"] = {name:{"calls_s":round(statistics.mean(x["counters"].get(name,{}).get("calls",0) for x in rows),3),"ms_s":round(statistics.mean(x["counters"].get(name,{}).get("usec",0)/1000 for x in rows),3),"max_ms":round(max(x["counters"].get(name,{}).get("max_usec",0)/1000 for x in rows),3)} for name in sorted(names)}
        summary.append(info)
    (directory/"joined.json").write_text(json.dumps(joined,ensure_ascii=False,indent=2),encoding="utf-8")
    (directory/"summary.json").write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding="utf-8")
    fields = [x for x in joined[0] if x != "counters"]
    with (directory/"samples.csv").open("w",encoding="utf-8-sig",newline="") as file:
        writer = csv.DictWriter(file,fieldnames=fields,extrasaction="ignore")
        writer.writeheader();writer.writerows(joined)
    for info in summary:
        print(f'{directory.name:18} {info["stage"]:18} FPS={info["fps_mean"]:6.1f} p95={info["frame_p95_ms_mean"]:6.2f}ms CPU={info["cpu_pct_machine_mean"]:5.2f}% RAM={info["rss_start_end_mib"]} GPU={info["gpu_pct_global_mean"]:5.1f}% nodes={info["nodes_min"]:.0f}..{info["nodes_max"]:.0f}')


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directories",nargs="+")
    for directory in parser.parse_args().directories:
        summarize(directory)
