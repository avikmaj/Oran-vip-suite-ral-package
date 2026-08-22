#!/usr/bin/env python3
# ======================================================================
#  File   : gen/adjudicate.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Result adjudicator — STATUS from executed evidence only (PASS_FAIL_POLICY). Parses UVM-format summary + COVROW; emits result.json.
# ======================================================================
"""adjudicate.py — GENERIC spec-driven adjudicator. STATUS from executed evidence
only: PASS iff sim_exit==0 AND UVM_ERROR==0 AND UVM_FATAL==0 AND transactions>0.
Unparseable -> NOT_VERIFIED. Functional coverage from COVROW lines vs spec cover."""
import argparse, json, re, sys, datetime

def cover_bins(cover, samples):
    bins = {}
    for c in cover:
        fld, kind = c["field"], c["kind"]
        vals = [s[fld] for s in samples if fld in s]
        if kind == "enum":
            for e in c["args"]: bins[f"{c['id']}.{fld}_{e}"] = int(e in vals)
        elif kind == "bool":
            for b in (0, 1): bins[f"{c['id']}.{fld}_{b}"] = int(b in vals)
        elif kind == "wrap":
            lo, hi = c["args"]
            bins[f"{c['id']}.{fld}_min"] = int(lo in vals)
            bins[f"{c['id']}.{fld}_max"] = int(hi in vals)
            bins[f"{c['id']}.{fld}_mid"] = int(any(lo < x < hi for x in vals))
        elif kind == "bucket4":
            lo, hi = c["args"]; step = max(1, (hi - lo + 1) // 4)
            def b(x): return min(3, (x - lo) // step)
            hit = {b(x) for x in vals}
            for k in range(4): bins[f"{c['id']}.{fld}_b{k}"] = int(k in hit)
    return bins

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", required=True)
    ap.add_argument("--log", required=True)
    ap.add_argument("--sim-exit", type=int, required=True)
    ap.add_argument("--test", required=True)
    ap.add_argument("--seed", type=int, required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--neg", action="store_true")
    a = ap.parse_args()
    spec = json.load(open(a.spec))

    ue = uf = txns = None; samples = []; sva = {}; exp = unexp = None
    for ln in open(a.log):
        if ln.startswith("COVROW,"):
            d = {}
            for kv in ln.strip()[7:].split(","):
                if "=" in kv:
                    k, val = kv.split("="); d[k] = int(val)
            samples.append(d)
        elif ln.startswith("UVM_ERROR :"): ue = int(ln.split(":")[1])
        elif ln.startswith("UVM_FATAL :"): uf = int(ln.split(":")[1])
        elif ln.startswith("SBSUMMARY,"):
            m = re.search(r"txns=(\d+)", ln); txns = int(m.group(1)) if m else None
        elif ln.startswith("SVA_EXERCISED,"):
            for kv in ln.strip()[len("SVA_EXERCISED,"):].split(","):
                k, val = kv.split("="); sva[k] = int(val)
        elif ln.startswith("NEGSUMMARY,"):
            exp = int(re.search(r"expected=(\d+)", ln).group(1))
            unexp = int(re.search(r"unexpected=(\d+)", ln).group(1))

    vacuous = [k for k, v in sva.items() if v == 0]
    if ue is None or uf is None or txns is None:
        status = "NOT_VERIFIED"
    elif a.neg:
        status = ("EXPECTED_FAILURE_DETECTED" if (a.sim_exit == 0 and ue == 0 and uf == 0
                  and txns > 0 and unexp == 0 and exp == txns) else "FAIL")
    elif a.sim_exit == 0 and ue == 0 and uf == 0 and txns > 0:
        status = "PASS"
    else:
        status = "FAIL"

    bins = cover_bins(spec.get("cover", []), samples)
    covered, total = sum(bins.values()), len(bins)
    fcov = round(100.0 * covered / total, 2) if total else 0.0

    result = {
        "component": spec["slug"], "test": a.test, "seed": a.seed, "lane": 1,
        "sim": "verilator", "sim_version": "Verilator 5.020", "status": status,
        "uvm_error": ue, "uvm_fatal": uf, "transactions": txns, "sim_exit": a.sim_exit,
        "functional_coverage": fcov, "functional_bins_covered": covered,
        "functional_bins_total": total, "cov_bins": bins,
        "assertions_exercised": sva, "vacuous_assertions": vacuous,
        "spec_ref": spec.get("spec_ref", ""), "req_provenance": "DERIVED",
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    }
    if a.neg:
        result["expected"] = "PROTOCOL_VIOLATION"
        result["observed"] = "PROTOCOL_VIOLATION" if (exp and exp > 0) else "NONE"
        result["expected_detected"] = exp; result["unexpected_pass"] = unexp
    json.dump(result, open(a.out, "w"), indent=2)
    ok = status in ("PASS", "EXPECTED_FAILURE_DETECTED")
    print(f"{spec['slug']:14s} {a.test:18s} seed={a.seed:<3d} {status:24s} "
          f"err={ue} txns={txns} fcov={fcov}% vac={len(vacuous)}")
    sys.exit(0 if ok else 1)

if __name__ == "__main__":
    main()
