#!/usr/bin/env python3
"""Aggregates run_matrix.jl output: per cell, the minimum over the runs and the
spread of the total.

    tabulate.py <raw_file> [opt = 2] [mode ...]

Prints one table per scenario and mode. `first sim` is construct + build +
Simulation + walks + init! + run!, the time to the first simulated frame after
`using`. `spread` is (max - min) / min of that sum over the runs.
"""
import sys
from collections import defaultdict

STEPS = ("construct", "build", "sim", "walks", "init", "run")

def parse(path):
    cells = defaultdict(list)
    order = []
    for line in open(path):
        d = dict(kv.split("=", 1) for kv in line.split() if "=" in kv)
        status = "TIMEOUT" if " TIMEOUT " in line else "FAILED" if " FAILED " in line else "ok"
        key = (d["scenario"], d["mode"], d["opt"], d["label"])
        if d["label"] not in order:
            order.append(d["label"])
        cells[key].append((status, d))
    return cells, order

def main():
    cells, order = parse(sys.argv[1])
    opt = sys.argv[2] if len(sys.argv) > 2 else "2"
    modes = sys.argv[3:] or ["cold", "types", "iter"]
    for scenario in ("small", "repeated", "distinct"):
        for mode in modes:
            rows = [(label, cells[(scenario, mode, opt, label)]) for label in order
                    if (scenario, mode, opt, label) in cells]
            if not rows:
                continue
            print(f"\n## {scenario}, {mode}, -O{opt}\n")
            print("| config | construct | build | Simulation | walks | init! | run! | first sim | spread | warm ms/s | alloc | runs |")
            print("|---|---|---|---|---|---|---|---|---|---|---|---|")
            for label, runs in rows:
                ok = [d for status, d in runs if status == "ok"]
                bad = [status for status, d in runs if status != "ok"]
                if not ok:
                    print(f"| {label} | {' '.join(bad)} |")
                    continue
                totals = [sum(float(d[s]) for s in STEPS) for d in ok]
                best = ok[totals.index(min(totals))]
                spread = (max(totals) - min(totals)) / min(totals)
                alloc = max(int(d["alloc"]) + int(d["alloc_at"]) + int(d["alloc_boundary"]) for d in ok)
                warm = min(float(d["warm_ms_per_s"]) for d in ok)
                hashes = {d["xhash"] for d in ok}
                steps = " | ".join(f"{float(best[s]):.2f}" for s in STEPS)
                note = f"{len(ok)}" + (f" +{len(bad)} {bad[0]}" if bad else "") + ("" if len(hashes) == 1 else " HASH!")
                print(f"| {label} | {steps} | {min(totals):.2f} | {spread:.0%} | {warm:.1f} | {alloc} | {note} |")

if __name__ == "__main__":
    main()
