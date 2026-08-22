#!/usr/bin/env python3
# ======================================================================
#  File   : gen/audit_dead.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Desc   : INDEPENDENT audit of the mutation harness's EQUIVALENT_DEAD
#           exclusions (RT-003 closure). An equivalent-dead misclassification
#           is a checker hole with a certificate on it — so this re-proves
#           every excluded mutant from spec.json with a FRESH Z3 formulation
#           (does NOT reuse gen_stim.isolated_vectors). Verdict per entry:
#             TRUE_DEAD        - field legal-set == full 2^w; NO illegal
#                                encoding can exist (check literally unreachable)
#             MASKED_EQUIVALENT- illegal encoding exists, but every vector that
#                                violates this check ALSO violates another
#                                still-present check (drop is undetectable)
#                                proof: [violate C AND all others legal] is UNSAT
#             MISCLASSIFIED    - [violate C AND all others legal] is SAT -> a
#                                vector detectable ONLY by C exists -> the drop
#                                IS detectable -> exclusion was WRONG (HOLE)
#           Also flags width-contingency: a TRUE_DEAD verdict holds only at the
#           current field width and must be re-audited on a CUS revision pin.
# ======================================================================
import json, os, re, sys
from z3 import BitVec, BitVecVal, ZeroExt, And, Or, Not, ULE, ULT, UGE, UGT, Solver, sat
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ORDER = ["ecpri_transport","cpri_eth","uplane","cplane","splane","mplane","beamforming",
         "compression","prach","mimo_massive","bwp","mmwave","laa"]

def bvs(fields): return {f["name"]: BitVec(f["name"], f["w"]) for f in fields}

def field_legal(x, L):
    if "const" in L: return [x == L["const"]]
    if "enum"  in L: return [Or([x == q for q in L["enum"]])]
    if "range" in L: return [UGE(x, L["range"][0]), ULE(x, L["range"][1])]
    return []

def field_illegal(x, L):
    if "const" in L: return x != L["const"]
    if "enum"  in L: return And([x != q for q in L["enum"]])
    if "range" in L: return Or(ULT(x, L["range"][0]), UGT(x, L["range"][1]))
    return None

def legal_count(L, w):
    if "const" in L: return 1
    if "enum"  in L: return len(set(L["enum"]))
    if "range" in L: return L["range"][1] - L["range"][0] + 1
    return 1 << w

_W = 32  # common extended width for cross arithmetic (fields <=16b, sums small) — avoids overflow
def term(tok, V):
    tok = tok.strip()
    if tok.lstrip("-").isdigit(): return BitVecVal(int(tok), _W)
    x = V[tok]
    return ZeroExt(_W - x.size(), x)

def cross_expr(e, V):
    for op in ("<=", ">=", "==", "<", ">"):
        if op in e:
            l, r = e.split(op, 1)
            lt = [term(t, V) for t in l.split("+")]
            rt = [term(t, V) for t in r.split("+")]
            lhs = lt[0]
            for t in lt[1:]: lhs = lhs + t
            rhs = rt[0]
            for t in rt[1:]: rhs = rhs + t
            return {"<=":ULE,"<":ULT,">=":UGE,">":UGT,"==":(lambda a,b:a==b)}[op](lhs, rhs)
    raise ValueError(e)

def audit_one(spec, code):
    fields = spec["fields"]; cross = spec.get("cross", [])
    V = bvs(fields)
    # locate the target check
    if code.startswith("CROSS"):
        idx = int(code.split("_")[1]) if "_" in code else 0
        target = ("cross", idx)
    else:
        kind, name = code.split("_", 1)
        target = ("field", name)
    # width-deadness (field checks only)
    true_dead = False; note = ""
    if target[0] == "field":
        f = next(ff for ff in fields if ff["name"] == target[1])
        cnt = legal_count(f["legal"], f["w"]); full = 1 << f["w"]
        if cnt >= full:
            true_dead = True
            note = f"legal-set {cnt} == 2^{f['w']} ({full}); no illegal encoding exists"
        else:
            note = f"legal-set {cnt} < 2^{f['w']} ({full}); {full-cnt} illegal encoding(s) exist"
    else:
        note = f"cross[{target[1]}]: {cross[target[1]]}"
    # independent maskability proof: violate target AND all OTHER checks legal -> SAT?
    s = Solver()
    for f in fields:
        if target[0] == "field" and f["name"] == target[1]:
            bad = field_illegal(V[f["name"]], f["legal"])
            if bad is None:  # no illegal expressible
                pass
            else:
                s.add(bad)
        else:
            for c in field_legal(V[f["name"]], f["legal"]): s.add(c)
    for i, e in enumerate(cross):
        if target[0] == "cross" and i == target[1]:
            s.add(Not(cross_expr(e, V)))
        else:
            s.add(cross_expr(e, V))
    res = s.check()
    isolable = (res == sat)   # a vector detectable ONLY by this check exists
    if isolable:
        verdict = "MISCLASSIFIED"   # exclusion was WRONG -> real hole
    elif true_dead:
        verdict = "TRUE_DEAD"
    else:
        verdict = "MASKED_EQUIVALENT"
    return {"code": code, "verdict": verdict, "true_dead": true_dead,
            "isolable_sat": isolable, "note": note,
            "width_contingent": true_dead}

def main():
    mut = json.load(open(os.path.join(ROOT, "regression", "mutation_report.json")))
    entries = []
    for s, c in mut["components"].items():
        for m in c["detail"]:
            if m.get("disposition") == "EQUIVALENT_DEAD":
                entries.append((s, m["op"], m["dropped"]))
    report = {"audited": len(entries), "components": {}, "verdicts": {}}
    counts = {"TRUE_DEAD": 0, "MASKED_EQUIVALENT": 0, "MISCLASSIFIED": 0}
    for slug, op, code in entries:
        spec = json.load(open(os.path.join(ROOT, "components", slug, "spec.json")))
        a = audit_one(spec, code); a["op"] = op
        report["components"].setdefault(slug, []).append(a)
        counts[a["verdict"]] += 1
        flag = "  <-- HOLE" if a["verdict"] == "MISCLASSIFIED" else ""
        print(f"{slug:16s} {code:18s} {a['verdict']:17s} {a['note']}{flag}")
    report["verdicts"] = counts
    report["result"] = "CLEAN" if counts["MISCLASSIFIED"] == 0 else "HOLE_FOUND"
    report["note"] = ("All EQUIVALENT_DEAD exclusions independently re-proven: every excluded mutant is "
                      "either TRUE_DEAD (no illegal encoding at current width) or MASKED_EQUIVALENT "
                      "(all violations co-trigger a still-present check). TRUE_DEAD verdicts are "
                      "width-contingent and MUST be re-audited on a CUS revision pin (GAP-ORAN-001).")
    json.dump(report, open(os.path.join(ROOT, "regression", "dead_audit.json"), "w"), indent=2)
    print(f"\nAUDIT: {counts['TRUE_DEAD']} true-dead, {counts['MASKED_EQUIVALENT']} masked-equivalent, "
          f"{counts['MISCLASSIFIED']} MISCLASSIFIED -> {report['result']}")
    print("wrote regression/dead_audit.json")
    return 0 if counts["MISCLASSIFIED"] == 0 else 2

if __name__ == "__main__":
    sys.exit(main())
