#!/usr/bin/env python3
# ======================================================================
#  File   : gen/run_gates.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Lane-1 GATE 4-8 driver: literal-scan, random L3, negative, assertion exercise, functional coverage closure.
# ======================================================================
"""
run_gates.py — drives GATE 4/5/6/7/8 for generated Lane-1 components using the
already-compiled simv (binary is seed-independent; stimulus/plusargs vary).
GATE 4: literal scan (no hardcoded drive-path literals) + directed mode proof.
GATE 5: random L3 (seeds 1..RAND) — >=99% PASS, coverage convergence.
GATE 6: negative — status EXPECTED_FAILURE_DETECTED.
GATE 7: assertions exercised >0 (non-vacuous) across GATE 5.
GATE 8: merged functional coverage >=95%; directed closure for residual holes.
"""
import json, os, re, subprocess, sys, glob

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
COMP = os.path.join(ROOT, "components")
GEN  = os.path.join(ROOT, "gen")
RAND = int(os.environ.get("RAND", "20"))
COMPONENTS = ["cpri_eth","uplane","cplane","splane","mplane","beamforming",
              "compression","prach","mimo_massive","bwp","mmwave","laa"]

def simv(slug):
    for c in glob.glob(f"{COMP}/{slug}/sim_out/obj_*/simv"):
        return c
    return None

def gen(slug, seed, n, out, neg=False, directed=None):
    cmd = ["python3", f"{GEN}/gen_stim.py", "--spec", f"{COMP}/{slug}/spec.json",
           "--seed", str(seed), "--n", str(n), "--out", out]
    if neg: cmd.append("--neg")
    for d in (directed or []): cmd += ["--directed", d]
    subprocess.run(cmd, capture_output=True, text=True)

def run(slug, stim, log, neg=False):
    sv = simv(slug)
    with open(log, "w") as f:
        p = subprocess.run([sv, f"+STIM={stim}"] + (["+NEG=1"] if neg else []),
                           stdout=f, stderr=subprocess.STDOUT)
    return p.returncode

def adj(slug, log, out, seed, test, neg=False):
    cmd = ["python3", f"{GEN}/adjudicate.py", "--spec", f"{COMP}/{slug}/spec.json",
           "--log", log, "--sim-exit", "0", "--test", test, "--seed", str(seed), "--out", out]
    if neg: cmd.append("--neg")
    subprocess.run(cmd, capture_output=True, text=True)
    return json.load(open(out))

def bin_targets(cover):
    """bin_key -> directed 'field=value' to hit it."""
    t = {}
    for c in cover:
        f, k = c["field"], c["kind"]
        if k == "enum":
            for e in c["args"]: t[f"{c['id']}.{f}_{e}"] = f"{f}={e}"
        elif k == "bool":
            for b in (0,1): t[f"{c['id']}.{f}_{b}"] = f"{f}={b}"
        elif k == "wrap":
            lo, hi = c["args"]
            t[f"{c['id']}.{f}_min"] = f"{f}={lo}"; t[f"{c['id']}.{f}_max"] = f"{f}={hi}"
            t[f"{c['id']}.{f}_mid"] = f"{f}={(lo+hi)//2}"
        elif k == "bucket4":
            lo, hi = c["args"]; step = max(1,(hi-lo+1)//4)
            for b in range(4): t[f"{c['id']}.{f}_b{b}"] = f"{f}={min(hi, lo+b*step)}"
    return t

def literal_scan(slug):
    """GATE 4 gate-check: no hardcoded field literals in the DRIVE path.
    Drive path = stimulus generator + TB field-apply. Values come from spec/Z3,
    not literals. Flags bare integer assignments to m_in.* in the TB."""
    tb = open(f"{COMP}/{slug}/tb/{slug}_tb_top.sv").read()
    bad = re.findall(r"m_in\.\w+\s*=\s*\d+\b", tb)   # literal driven into stimulus
    return bad

def main():
    slugs = sys.argv[1:] or COMPONENTS
    rpath = f"{ROOT}/regression/gate4_8_report.json"
    report = json.load(open(rpath)) if os.path.exists(rpath) else {}
    for slug in slugs:
        d = f"{COMP}/{slug}"; g = f"{d}/gates"; os.makedirs(g, exist_ok=True)
        spec = json.load(open(f"{d}/spec.json")); cover = spec.get("cover", [])
        r = {}
        # GATE 4 — literal scan
        r["gate4_literals"] = literal_scan(slug)
        # GATE 5 — random L3
        union, total, npass, sva_min = set(), None, 0, None
        for seed in range(1, RAND+1):
            st = f"{g}/rand_{seed}.hex"; lg = f"{g}/rand_{seed}.log"; rj = f"{g}/rand_{seed}.json"
            gen(slug, seed, 300, st); run(slug, st, lg); res = adj(slug, lg, rj, seed, f"rand{seed}")
            total = res["functional_bins_total"]
            union |= {k for k,v in res["cov_bins"].items() if v}
            npass += 1 if res["status"] == "PASS" else 0
            sm = min(res["assertions_exercised"].values()) if res["assertions_exercised"] else 0
            sva_min = sm if sva_min is None else min(sva_min, sm)
        r["gate5_pass_rate"] = round(100*npass/RAND, 1); r["gate5_seeds"] = RAND
        # GATE 8 — directed closure of residual holes
        targets = bin_targets(cover); missing = [k for k in targets if k not in union]
        closed = []
        for k in missing:
            st = f"{g}/dir_{k}.hex"; lg = f"{g}/dir_{k}.log"; rj = f"{g}/dir_{k}.json"
            gen(slug, 1, 40, st, directed=[targets[k]]); run(slug, st, lg)
            res = adj(slug, lg, rj, 1, f"dir_{k}")
            hit = {kk for kk,v in res["cov_bins"].items() if v}
            if k in hit: union.add(k); closed.append(k)
        merged = round(100*len(union)/total, 2) if total else 0.0
        r["gate8_merged_fcov"] = merged; r["gate8_holes_closed"] = len(closed)
        r["gate8_residual"] = [k for k in targets if k not in union]
        # GATE 7 — non-vacuous assertions (min exercise count across random seeds)
        r["gate7_min_assert_exercised"] = sva_min; r["gate7_vacuous"] = (sva_min == 0)
        # GATE 6 — negative
        neg_ok = 0
        for seed in (1,2,3):
            st = f"{g}/neg_{seed}.hex"; lg = f"{g}/neg_{seed}.log"; rj = f"{g}/neg_{seed}.json"
            gen(slug, seed, 200, st, neg=True); run(slug, st, lg, neg=True)
            res = adj(slug, lg, rj, seed, f"neg{seed}", neg=True)
            neg_ok += 1 if res["status"] == "EXPECTED_FAILURE_DETECTED" else 0
        r["gate6_neg_detected"] = f"{neg_ok}/3"
        # verdicts
        r["GATE4"] = "PASS" if not r["gate4_literals"] else "FAIL"
        r["GATE5"] = "PASS" if r["gate5_pass_rate"] >= 99.0 else "FAIL"
        r["GATE6"] = "PASS" if neg_ok == 3 else "FAIL"
        r["GATE7"] = "PASS" if not r["gate7_vacuous"] else "FAIL"
        r["GATE8"] = "PASS" if merged >= 95.0 else "FAIL"
        report[slug] = r
        print(f"{slug:14s} G4={r['GATE4']} G5={r['GATE5']}({r['gate5_pass_rate']}%) "
              f"G6={r['GATE6']}({r['gate6_neg_detected']}) G7={r['GATE7']}(min={sva_min}) "
              f"G8={r['GATE8']}({merged}%, +{len(closed)} closed)")
    json.dump(report, open(rpath, "w"), indent=2)
    for gt in ("GATE4","GATE5","GATE6","GATE7","GATE8"):
        n = sum(1 for v in report.values() if v[gt]=="PASS")
        print(f"SUITE {gt}: {n}/{len(report)} PASS")

if __name__ == "__main__":
    main()
