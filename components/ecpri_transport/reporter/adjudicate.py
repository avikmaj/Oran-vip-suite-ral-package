#!/usr/bin/env python3
# ======================================================================
#  File   : components/ecpri_transport/reporter/adjudicate.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Result adjudicator — STATUS from executed evidence only (PASS_FAIL_POLICY). Parses UVM-format summary + COVROW; emits result.json.
# ======================================================================
"""
adjudicate.py — Lane-1 adjudicator. Parses the simulation log (UVM-format
summary + COVROW lines) and Verilator coverage.dat, computes COV-### functional
coverage, and writes result.json. STATUS is derived ONLY from executed evidence:
PASS iff sim exited 0 AND UVM_ERROR==0 AND UVM_FATAL==0 AND transactions>0.
Anything unparseable -> NOT_VERIFIED (never silently PASS).
"""
import argparse, json, os, re, sys, datetime

def parse_log(path):
    uvm_err = uvm_fatal = txns = None
    msg, conc, seqid, psz = set(), set(), set(), []
    with open(path) as f:
        for ln in f:
            if ln.startswith("COVROW,"):
                _, m, c, s, p = ln.strip().split(",")
                msg.add(int(m)); conc.add(int(c)); seqid.add(int(s)); psz.append(int(p))
            elif ln.startswith("UVM_ERROR :"):
                uvm_err = int(ln.split(":")[1])
            elif ln.startswith("UVM_FATAL :"):
                uvm_fatal = int(ln.split(":")[1])
            elif ln.startswith("SBSUMMARY,"):
                m = re.search(r"txns=(\d+)", ln); txns = int(m.group(1)) if m else None
    return uvm_err, uvm_fatal, txns, msg, conc, seqid, psz

def func_cov(msg, conc, seqid, psz):
    # COV-001 msg_type 0..7 ; COV-002 concat 0/1 ; COV-003 seq wrap {0,255,mid} ;
    # COV-004 payload buckets {[8..16],(16..256],(256..768],(768..1024]}
    bins = {}
    for t in range(8):   bins[f"COV-001.msg_{t}"]     = int(t in msg)
    for c in range(2):   bins[f"COV-002.concat_{c}"]  = int(c in conc)
    bins["COV-003.seq_min0"]  = int(0 in seqid)
    bins["COV-003.seq_max255"]= int(255 in seqid)
    bins["COV-003.seq_mid"]   = int(any(0 < s < 255 for s in seqid))
    def buck(p): return 0 if p<=16 else 1 if p<=256 else 2 if p<=768 else 3
    hit = {buck(p) for p in psz}
    for b in range(4): bins[f"COV-004.psize_b{b}"] = int(b in hit)
    covered = sum(bins.values()); total = len(bins)
    return bins, covered, total, round(100.0*covered/total, 2) if total else 0.0

def code_cov(dat):
    if not os.path.exists(dat): return None, 0, 0
    pts = cov = 0
    with open(dat) as f:
        for ln in f:
            m = re.search(r"'\s+(\d+)\s*$", ln.strip())
            if ln.startswith("C ") and m:
                pts += 1; cov += 1 if int(m.group(1)) > 0 else 0
    return (round(100.0*cov/pts,2) if pts else 0.0), cov, pts

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", required=True)
    ap.add_argument("--sim-exit", type=int, required=True)
    ap.add_argument("--coverage-dat", default="coverage.dat")
    ap.add_argument("--component", default="ecpri_transport")
    ap.add_argument("--test", required=True)
    ap.add_argument("--seed", type=int, required=True)
    ap.add_argument("--sim-version", default="Verilator 5.020")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    ue, uf, txns, msg, conc, seqid, psz = parse_log(a.log)
    if ue is None or uf is None or txns is None:
        status = "NOT_VERIFIED"
    elif a.sim_exit == 0 and ue == 0 and uf == 0 and txns > 0:
        status = "PASS"
    else:
        status = "FAIL"

    bins, covered, total, fcov = func_cov(msg, conc, seqid, psz)
    ccov, ccov_hit, ccov_pts = code_cov(a.coverage_dat)

    result = {
        "component": a.component, "test": a.test, "seed": a.seed,
        "lane": 1, "sim": "verilator", "sim_version": a.sim_version,
        "status": status,
        "uvm_error": ue, "uvm_fatal": uf, "transactions": txns, "sim_exit": a.sim_exit,
        "functional_coverage": fcov,
        "functional_bins_covered": covered, "functional_bins_total": total,
        "code_coverage": ccov, "code_points_covered": ccov_hit, "code_points_total": ccov_pts,
        "cov_bins": bins,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
    }
    with open(a.out, "w") as f:
        json.dump(result, f, indent=2)
    print(json.dumps({k: result[k] for k in
          ("component","test","seed","status","uvm_error","uvm_fatal",
           "transactions","functional_coverage","code_coverage")}, indent=2))
    sys.exit(0 if status == "PASS" else 1)

if __name__ == "__main__":
    main()
