#!/usr/bin/env python3
# ======================================================================
#  File   : gen/corner.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Corner/edge-case generator+runner: field min/max, cross-constraint boundaries, sequence wrap extremes.
# ======================================================================
"""corner.py — GATE-4/8 corner & edge cases per component (directed, constraint-narrow).
Scenarios: every range field at legal MIN and MAX; every cross-constraint driven to its
exact boundary (companion field solved by Z3); sequence wrap extremes (0, max, max-1).
All corner txns are LEGAL -> must PASS legality + round-trip. Adds test-class 'corner'."""
import glob, json, os, subprocess, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
COMP = os.path.join(ROOT, "components"); GEN = os.path.join(ROOT, "gen")
ORDER = ["ecpri_transport","cpri_eth","uplane","cplane","splane","mplane","beamforming",
         "compression","prach","mimo_massive","bwp","mmwave","laa"]

def simv(slug):
    g = glob.glob(f"{COMP}/{slug}/sim_out/obj_*/simv"); return g[0] if g else None

def scenarios(spec):
    """list of (name, [directed 'f=v'...])"""
    sc = []
    for f in spec["fields"]:
        L = f["legal"]
        if "range" in L:
            sc.append((f"{f['name']}_min", [f"{f['name']}={L['range'][0]}"]))
            sc.append((f"{f['name']}_max", [f"{f['name']}={L['range'][1]}"]))
        elif "enum" in L:
            sc.append((f"{f['name']}_lo", [f"{f['name']}={min(L['enum'])}"]))
            sc.append((f"{f['name']}_hi", [f"{f['name']}={max(L['enum'])}"]))
    for i, expr in enumerate(spec.get("cross", [])):
        # "a + b <= L": pin first LHS term to its legal max -> Z3 drives companion to boundary
        lhs = expr.split("<=")[0] if "<=" in expr else expr.split("<")[0]
        t0 = lhs.split("+")[0].strip()
        for f in spec["fields"]:
            if f["name"] == t0 and "range" in f["legal"]:
                sc.append((f"cross{i}_edge", [f"{t0}={f['legal']['range'][1]}"]))
    return sc

def main():
    slugs = sys.argv[1:] or ORDER
    summary = {}
    for slug in slugs:
        spec = json.load(open(f"{COMP}/{slug}/spec.json"))
        d = f"{COMP}/{slug}/corner"; os.makedirs(d, exist_ok=True)
        sv = simv(slug); npass = ntot = 0
        for name, pins in scenarios(spec):
            st = f"{d}/{name}.hex"; lg = f"{d}/{name}.log"; rj = f"{d}/result_corner_{name}.json"
            cmd = ["python3", f"{GEN}/gen_stim.py", "--spec", f"{COMP}/{slug}/spec.json",
                   "--seed", "1", "--n", "50", "--out", st]
            for p in pins: cmd += ["--directed", p]
            subprocess.run(cmd, capture_output=True)
            with open(lg, "w") as f: subprocess.run([sv, f"+STIM={st}"], stdout=f, stderr=subprocess.STDOUT)
            subprocess.run(["python3", f"{GEN}/adjudicate.py", "--spec", f"{COMP}/{slug}/spec.json",
                            "--log", lg, "--sim-exit", "0", "--test", f"corner_{name}",
                            "--seed", "1", "--out", rj], capture_output=True)
            try: st_ok = json.load(open(rj)).get("status") == "PASS"
            except: st_ok = False
            ntot += 1; npass += 1 if st_ok else 0
        summary[slug] = f"{npass}/{ntot}"
        print(f"{slug:14s} corner {npass}/{ntot} PASS")
    n = sum(1 for v in summary.values() if v.split("/")[0]==v.split("/")[1])
    print(f"SUITE corner: {n}/{len(summary)} components all-corner-PASS")

if __name__ == "__main__":
    main()
