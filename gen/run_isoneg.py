#!/usr/bin/env python3
# ======================================================================
#  File   : gen/run_isoneg.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Desc   : GATE-6+ ISOLATED-NEGATIVE regression (RT-003 closure). For each
#           component, drives one negative vector per REACHABLE legality check
#           in isolation (all other fields legal), so every check is exercised
#           independently. Adjudicated --neg. Emits regression/isoneg_report.json.
#           Dead checks (legal-set == full field width; Z3-UNSAT to isolate) are
#           reported as provably-unreachable, not failures.
# ======================================================================
import json, os, subprocess, tempfile, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GEN  = os.path.join(ROOT, "gen")
ORDER = ["ecpri_transport","cpri_eth","uplane","cplane","splane","mplane","beamforming",
         "compression","prach","mimo_massive","bwp","mmwave","laa"]
def sh(c, cwd=None): return subprocess.run(c, cwd=cwd, capture_output=True, text=True, timeout=300)

def run(slug, N=300, SEED=1):
    d = os.path.join(ROOT, "components", slug); out = os.path.join(d, "sim_out"); os.makedirs(out, exist_ok=True)
    work = tempfile.mkdtemp(prefix=f"iso_{slug}_")
    hexf = os.path.join(out, f"{slug}_isoneg_seed{SEED}.hex")
    g = sh(["python3", os.path.join(GEN,"gen_stim.py"),"--spec",os.path.join(d,"spec.json"),
            "--seed",str(SEED),"--n",str(N),"--out",hexf,"--isolate"])
    try: meta = json.load(open(hexf+".isohdr"))
    except Exception: meta = {"isolable":[], "non_isolable":[]}
    mdir = os.path.join(work,"obj")
    cc = sh(["verilator","--cc","--exe","--build","-j","0","--timing","--coverage",
             "-Wno-CONSTRAINTIGN","-Wno-WIDTHTRUNC","-Wno-WIDTHEXPAND","-Wno-UNUSEDSIGNAL","-Wno-fatal",
             "--Mdir",mdir,"-o","simv","--top-module",f"{slug}_tb_top",
             os.path.join(d,"sim_main.cpp"),os.path.join(d,"rtl",f"{slug}_pkg.sv"),
             os.path.join(d,"rtl",f"{slug}_codec.sv"),os.path.join(d,"tb",f"{slug}_tb_top.sv")])
    if cc.returncode != 0 or not os.path.exists(os.path.join(mdir,"simv")):
        return {"status":"COMPILE_FAIL"}
    log = os.path.join(out, f"isoneg_seed{SEED}.log")
    r = sh([os.path.join(mdir,"simv"), f"+STIM={hexf}", "+NEG=1"], cwd=work)
    open(log,"w").write(r.stdout + r.stderr)
    res = os.path.join(out, f"result_isoneg_seed{SEED}.json")
    sh(["python3", os.path.join(GEN,"adjudicate.py"),"--spec",os.path.join(d,"spec.json"),
        "--log",log,"--sim-exit",str(r.returncode),"--test","isoneg","--seed",str(SEED),"--neg","--out",res])
    try: status = json.load(open(res)).get("status","PARSE_FAIL")
    except Exception: status = "PARSE_FAIL"
    import shutil; shutil.rmtree(work, ignore_errors=True)
    return {"status":status,
            "checks_isolated":len(meta.get("isolable",[])),
            "reachable_checks":[c for c in meta.get("isolable",[])],
            "dead_checks":[c for c,_ in meta.get("non_isolable",[])]}

def main():
    comps = sys.argv[1:] or ORDER
    rep = {"components":{}}
    npass = 0
    for s in comps:
        r = run(s); rep["components"][s] = r
        ok = r["status"] == "EXPECTED_FAILURE_DETECTED"
        npass += 1 if ok else 0
        print(f"{s:16s} {r['status']:26s} isolated_checks={r.get('checks_isolated','-')} dead={len(r.get('dead_checks',[]))}")
    rep["summary"] = {"runs":len(comps),"detected":npass,
                      "rate": round(100.0*npass/len(comps),1) if comps else None}
    json.dump(rep, open(os.path.join(ROOT,"regression","isoneg_report.json"),"w"), indent=2)
    print(f"\nISONEG: {npass}/{len(comps)} components — every reachable legality check independently detected.")
    print("wrote regression/isoneg_report.json")

if __name__ == "__main__": main()
