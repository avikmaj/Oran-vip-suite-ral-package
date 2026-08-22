#!/usr/bin/env python3
# ======================================================================
#  File   : gen/mutation.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Desc   : RT-003 MUTATION / FAULT-INJECTION harness. Perturbs each Lane-1
#           codec/legality model, rebuilds, and requires the self-checking
#           scoreboard to DETECT the fault. Reports kill-rate — the real
#           measure of checker sensitivity (does the TB catch a bug it did
#           not itself plant?). A SURVIVOR is a genuine hole in the checks.
#
#  Kill criterion (mirrors the real regression):
#    positive smoke  -> KILLED if adjudicated STATUS != PASS  (pack/unpack/zero faults)
#    negative inject -> KILLED if STATUS != EXPECTED_FAILURE_DETECTED (legality faults)
#    A mutant is KILLED if EITHER run detects it; SURVIVED only if both green.
#    Non-compiling mutants are reported separately (excluded from kill-rate).
# ======================================================================
import json, os, re, subprocess, sys, shutil, tempfile
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GEN  = os.path.join(ROOT, "gen")
ORDER = ["ecpri_transport","cpri_eth","uplane","cplane","splane","mplane","beamforming",
         "compression","prach","mimo_massive","bwp","mmwave","laa"]
N = int(os.environ.get("MUT_N", "300")); SEED = 1

def sh(cmd, cwd=None, timeout=300):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)

# ---------------- mutation operators (regex on the pkg source) ----------------
def op_pack_swap(src, slug):
    m = re.search(rf"function automatic bit \[63:0\] {slug}_pack.*?return\s*\{{(.*?)\}};", src, re.S)
    if not m: return None, None
    inner = m.group(1); parts = [p.strip() for p in inner.split(",")]
    if len(parts) < 2: return None, None
    parts[0], parts[1] = parts[1], parts[0]
    return src[:m.start(1)] + " " + ", ".join(parts) + " " + src[m.end(1):], None

def op_pack_zero(src, slug):
    m = re.search(rf"function automatic bit \[63:0\] {slug}_pack.*?return\s*\{{(.*?)\}};", src, re.S)
    if not m: return None, None
    inner = m.group(1); parts = [p.strip() for p in inner.split(",")]
    parts[0] = "'0"
    return src[:m.start(1)] + " " + ", ".join(parts) + " " + src[m.end(1):], None

def op_unpack_swap(src, slug):
    fn = re.search(rf"function automatic {slug}_hdr_t {slug}_unpack.*?endfunction", src, re.S)
    if not fn: return None, None
    body = fn.group(0)
    assigns = list(re.finditer(r"h\.(\w+)\s*=\s*w\[p \+: \d+\];", body))
    if len(assigns) < 2: return None, None
    a, b = assigns[0], assigns[1]
    na, nb = a.group(1), b.group(1)
    new_a = a.group(0).replace(f"h.{na}", f"h.{nb}", 1)
    new_b = b.group(0).replace(f"h.{nb}", f"h.{na}", 1)
    nbody = body[:a.start()] + new_a + body[a.end():b.start()] + new_b + body[b.end():]
    return src.replace(body, nbody), None

def _drop_fv(src, slug, code_prefix):
    """In first_violation, neutralize the check whose return code starts with code_prefix.
    Returns (mutated_src, dropped_code) or (None, None)."""
    fn = re.search(rf"function automatic string {slug}_first_violation.*?endfunction", src, re.S)
    if not fn: return None, None
    body = fn.group(0)
    m = re.search(rf'if\(!\((.*?)\)\) return "({code_prefix}[^"]*)";', body)
    if not m: return None, None
    neutered = body[:m.start()] + f'if(!(1)) return "{m.group(2)}";' + body[m.end():]
    return src.replace(body, neutered), m.group(2)

def op_legal_const_drop(src, slug): return _drop_fv(src, slug, "CONST_")
def op_legal_range_drop(src, slug): return _drop_fv(src, slug, "RANGE_")
def op_legal_enum_drop(src, slug):  return _drop_fv(src, slug, "ENUM_")
def op_legal_cross_drop(src, slug): return _drop_fv(src, slug, "CROSS")

OPERATORS = [
    ("PACK_SWAP",       "swap two fields in pack() -> wire mismatch",           op_pack_swap,       "pos"),
    ("PACK_FIELD_ZERO", "zero a field in pack() -> wire mismatch",              op_pack_zero,       "pos"),
    ("UNPACK_SWAP",     "swap two unpack field targets -> round-trip mismatch", op_unpack_swap,     "pos"),
    ("LEGAL_CONST_DROP","remove a CONST legality check -> illegal escapes",     op_legal_const_drop,"neg"),
    ("LEGAL_RANGE_DROP","remove a RANGE legality check -> illegal escapes",      op_legal_range_drop,"neg"),
    ("LEGAL_ENUM_DROP", "remove an ENUM legality check -> illegal escapes",      op_legal_enum_drop, "neg"),
    ("LEGAL_CROSS_DROP","remove the CROSS legality check -> illegal escapes",    op_legal_cross_drop,"neg"),
]

def build_and_run(slug, workdir, pkg_src, pos_hex, neg_hex, iso_hex):
    """Compile mutant; run positive + random-neg + isolated-neg. Returns dict of statuses."""
    d = os.path.join(ROOT, "components", slug)
    open(os.path.join(workdir, f"{slug}_pkg.sv"), "w").write(pkg_src)
    mdir = os.path.join(workdir, "obj")
    cc = sh(["verilator","--cc","--exe","--build","-j","0","--timing",
             "-Wno-CONSTRAINTIGN","-Wno-WIDTHTRUNC","-Wno-WIDTHEXPAND","-Wno-UNUSEDSIGNAL","-Wno-fatal",
             "--Mdir", mdir, "-o","simv","--top-module", f"{slug}_tb_top",
             os.path.join(d,"sim_main.cpp"),
             os.path.join(workdir, f"{slug}_pkg.sv"),
             os.path.join(d,"rtl",f"{slug}_codec.sv"),
             os.path.join(d,"tb",f"{slug}_tb_top.sv")], timeout=300)
    if cc.returncode != 0 or not os.path.exists(os.path.join(mdir,"simv")):
        return {"pos":"COMPILE_FAIL","neg":"COMPILE_FAIL","iso":"COMPILE_FAIL"}
    def run(hexf, neg, tag):
        log = os.path.join(workdir, tag+".log")
        r = sh([os.path.join(mdir,"simv"), f"+STIM={hexf}"] + (["+NEG=1"] if neg else []), cwd=workdir)
        open(log,"w").write(r.stdout + r.stderr)
        res = os.path.join(workdir, tag+".json")
        sh(["python3", os.path.join(GEN,"adjudicate.py"), "--spec", os.path.join(d,"spec.json"),
            "--log", log, "--sim-exit", str(r.returncode), "--test", tag,
            "--seed", str(SEED)] + (["--neg"] if neg else []) + ["--out", res])
        try: return json.load(open(res)).get("status","PARSE_FAIL")
        except Exception: return "PARSE_FAIL"
    return {"pos":run(pos_hex,False,"pos"),"neg":run(neg_hex,True,"neg"),"iso":run(iso_hex,True,"iso")}

def main():
    comps = sys.argv[1:] or ORDER
    report = {"components": {}, "operators": [o[0] for o in OPERATORS]}
    T = {"valid":0,"kill_base":0,"kill_iso":0,"equivalent":0,"open":0,"compilefail":0}
    for slug in comps:
        d = os.path.join(ROOT, "components", slug)
        orig = open(os.path.join(d,"rtl",f"{slug}_pkg.sv")).read()
        work = tempfile.mkdtemp(prefix=f"mut_{slug}_")
        pos_hex = os.path.join(work,"pos.hex"); neg_hex = os.path.join(work,"neg.hex"); iso_hex = os.path.join(work,"iso.hex")
        sh(["python3",os.path.join(GEN,"gen_stim.py"),"--spec",os.path.join(d,"spec.json"),"--seed",str(SEED),"--n",str(N),"--out",pos_hex])
        sh(["python3",os.path.join(GEN,"gen_stim.py"),"--spec",os.path.join(d,"spec.json"),"--seed",str(SEED),"--n",str(N),"--out",neg_hex,"--neg"])
        sh(["python3",os.path.join(GEN,"gen_stim.py"),"--spec",os.path.join(d,"spec.json"),"--seed",str(SEED),"--n",str(N),"--out",iso_hex,"--isolate"])
        try: iso_meta = json.load(open(iso_hex+".isohdr")); dead = {c for c,_ in iso_meta.get("non_isolable",[])}
        except Exception: dead = set()
        b = build_and_run(slug, work, orig, pos_hex, neg_hex, iso_hex)
        base_ok = (b["pos"]=="PASS" and b["neg"]=="EXPECTED_FAILURE_DETECTED" and b["iso"]=="EXPECTED_FAILURE_DETECTED")
        muts = []
        for name, desc, fn, killer in OPERATORS:
            mutated, dropped = fn(orig, slug)
            if mutated is None or mutated == orig:
                muts.append({"op":name,"applicable":False}); continue
            r = build_and_run(slug, work, mutated, pos_hex, neg_hex, iso_hex)
            if r["pos"]=="COMPILE_FAIL":
                muts.append({"op":name,"applicable":True,"result":"COMPILE_FAIL"}); T["compilefail"]+=1; continue
            EF="EXPECTED_FAILURE_DETECTED"
            kill_base = (r["pos"]!="PASS") or (r["neg"]!=EF)          # original regression sensitivity
            kill_iso  = kill_base or (r["iso"]!=EF)                    # with isolated stimulus added
            # disposition
            dcode = "CROSS" if (dropped and dropped.startswith("CROSS")) else dropped
            if kill_iso:
                disp = "KILLED_BASE" if kill_base else "KILLED_BY_ISOLATION"
            elif dcode in dead:
                disp = "EQUIVALENT_DEAD"     # provably unreachable/coupled check (no isolating vector exists)
            else:
                disp = "OPEN_SURVIVOR"
            muts.append({"op":name,"dropped":dropped,"pos":r["pos"],"neg":r["neg"],"iso":r["iso"],
                         "kill_base":kill_base,"kill_iso":kill_iso,"disposition":disp,"expected_killer":killer})
            if disp=="EQUIVALENT_DEAD": T["equivalent"]+=1
            else:
                T["valid"]+=1
                if kill_base: T["kill_base"]+=1
                if kill_iso:  T["kill_iso"]+=1
                if disp=="OPEN_SURVIVOR": T["open"]+=1
        valid=[m for m in muts if m.get("disposition") in ("KILLED_BASE","KILLED_BY_ISOLATION","OPEN_SURVIVOR")]
        equiv=[m for m in muts if m.get("disposition")=="EQUIVALENT_DEAD"]
        kb=sum(1 for m in valid if m["kill_base"]); ki=sum(1 for m in valid if m["kill_iso"])
        report["components"][slug]={"baseline_ok":base_ok,"baseline":b,"dead_checks":sorted(dead),
            "valid":len(valid),"kill_base":kb,"kill_iso":ki,"equivalent_dead":len(equiv),
            "kill_rate_base": round(100.0*kb/len(valid),1) if valid else None,
            "kill_rate_iso": round(100.0*ki/len(valid),1) if valid else None,
            "open_survivors":[m["op"]+"("+str(m["dropped"])+")" for m in valid if m["disposition"]=="OPEN_SURVIVOR"],
            "detail":muts}
        shutil.rmtree(work, ignore_errors=True)
        c=report["components"][slug]
        print(f"{slug:16s} base={'OK' if base_ok else 'BAD'} kill_base={kb}/{len(valid)}={c['kill_rate_base']}% "
              f"kill_iso={ki}/{len(valid)}={c['kill_rate_iso']}% equiv_dead={len(equiv)} open={c['open_survivors']}")
    report["summary"]={"mutants_valid":T["valid"],"kill_base":T["kill_base"],"kill_iso":T["kill_iso"],
        "equivalent_dead":T["equivalent"],"open_survivors":T["open"],"compile_fail":T["compilefail"],
        "kill_rate_base": round(100.0*T["kill_base"]/T["valid"],1) if T["valid"] else None,
        "kill_rate_iso": round(100.0*T["kill_iso"]/T["valid"],1) if T["valid"] else None}
    json.dump(report, open(os.path.join(ROOT,"regression","mutation_report.json"),"w"), indent=2)
    s=report["summary"]
    print(f"\nSUITE MUTATION — kill_base {s['kill_base']}/{s['mutants_valid']} = {s['kill_rate_base']}%  "
          f"| kill_iso {s['kill_iso']}/{s['mutants_valid']} = {s['kill_rate_iso']}%  "
          f"| equivalent_dead={s['equivalent_dead']} open={s['open_survivors']}")
    print("wrote regression/mutation_report.json")

if __name__ == "__main__":
    main()
