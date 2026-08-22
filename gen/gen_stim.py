#!/usr/bin/env python3
# ======================================================================
#  File   : gen/gen_stim.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Lane-1 Z3 constrained-random stimulus generator (positive/--neg/--directed). The Z3 model IS the legal space; native randomize() ignored on Verilator 5.020.
# ======================================================================
"""
gen_stim.py — GENERIC Z3 seeded stimulus generator (spec-driven).
Modes:
  (default)   positive: every txn Z3-proven LEGAL (per-field + cross constraints).
  --neg       negative: every txn carries a GUARANTEED illegal injection (out-of-
              legal-space or cross-violation). Reproducible by seed. Used for GATE 6.
  --directed "field=val" (repeatable): pin fields to force an FR scenario (GATE 4).
The Z3 model IS the legal space; native randomize()+{} is silently ignored on
Verilator 5.020 (measured), so cross-field constraints are solved here. Golden
64-bit word computed here as the independent pack oracle for the TB.
"""
import argparse, json, random
from z3 import (BitVec, BitVecVal, ZeroExt, And, Or, Not, ULE, ULT, UGE, UGT, Solver, sat)

def _term(tok, v5):
    tok = tok.strip()
    if tok.lstrip("-").isdigit(): return BitVecVal(int(tok), 40)
    return ZeroExt(40 - v5[tok].size(), v5[tok])
def _side(s, v5):
    parts = s.split("+"); acc = _term(parts[0], v5)
    for p in parts[1:]: acc = acc + _term(p, v5)
    return acc
def parse_cross(expr, v5):
    for c, op in (("<=", ULE), (">=", UGE), ("==", lambda a, b: a == b),
                  ("<", ULT), (">", UGT)):
        if c in expr:
            l, r = expr.split(c, 1); return op(_side(l, v5), _side(r, v5))
    raise ValueError(expr)

# ---- python-side legality (mirror of SV is_legal) for negative guarantee -----
def _pyterm(tok, vals):
    tok = tok.strip()
    return int(tok) if tok.lstrip("-").isdigit() else vals[tok]
def py_cross_ok(expr, vals):
    for c in ("<=", ">=", "==", "<", ">"):
        if c in expr:
            l, r = expr.split(c, 1)
            lv = sum(_pyterm(t, vals) for t in l.split("+"))
            rv = sum(_pyterm(t, vals) for t in r.split("+"))
            return {"<=":lv<=rv,">=":lv>=rv,"==":lv==rv,"<":lv<rv,">":lv>rv}[c]
    raise ValueError(expr)
def py_field_ok(f, vals):
    L, x = f["legal"], vals[f["name"]]
    if "const" in L: return x == L["const"]
    if "enum" in L:  return x in L["enum"]
    if "range" in L: return L["range"][0] <= x <= L["range"][1]
    return True
def py_is_legal(spec, vals):
    return all(py_field_ok(f, vals) for f in spec["fields"]) and \
           all(py_cross_ok(e, vals) for e in spec.get("cross", []))

def legal_draw(f, rng):
    L = f["legal"]
    if "const" in L: return None
    if "enum" in L:  return rng.choice(L["enum"])
    if "range" in L: return rng.randint(L["range"][0], L["range"][1])
    return rng.randint(0, (1 << f["w"]) - 1)

def inject_illegal(spec, vals, rng, idx):
    """Return (vals, code) with a guaranteed illegal field. Rotates conditions."""
    fields = spec["fields"]
    v = dict(vals)
    # candidate injections that are guaranteed to leave legal space
    cands = []
    for f in fields:
        L, n, w = f["legal"], f["name"], f["w"]
        if "const" in L:
            bad = (L["const"] + 1) & ((1 << w) - 1)
            if bad != L["const"]: cands.append((n, bad, f"CONST_{n}"))
        elif "range" in L:
            hi = L["range"][1]
            if hi + 1 < (1 << w): cands.append((n, hi + 1, f"RANGE_{n}"))
            elif L["range"][0] - 1 >= 0: cands.append((n, L["range"][0]-1, f"RANGE_{n}"))
        elif "enum" in L:
            for c in range(1 << w):
                if c not in L["enum"]: cands.append((n, c, f"ENUM_{n}")); break
    # cross-violation option
    cross = spec.get("cross", [])
    pick = idx % (len(cands) + (1 if cross else 0))
    if cross and pick == len(cands):
        # push a max-out on the first term of first cross expr
        expr = cross[0]; lhs = expr.split("<=")[0] if "<=" in expr else expr.split("<")[0]
        f0 = lhs.split("+")[0].strip()
        for f in fields:
            if f["name"] == f0:
                v[f0] = (1 << f["w"]) - 1
        if not py_is_legal(spec, v): return v, f"CROSS"
        pick = 0  # fallback
    n, bad, code = cands[pick]
    v[n] = bad
    assert not py_is_legal(spec, v), f"injection failed {code}"
    return v, code

def _which_violations(spec, vals):
    """Return the set of check-codes this vector violates (per py legality model)."""
    bad = set()
    for f in spec["fields"]:
        if not py_field_ok(f, vals):
            L = f["legal"]
            kind = "CONST" if "const" in L else ("ENUM" if "enum" in L else "RANGE")
            bad.add(f"{kind}_{f['name']}")
    for i, e in enumerate(spec.get("cross", [])):
        if not py_cross_ok(e, vals): bad.add("CROSS")
    return bad

def isolated_vectors(spec, seed=1):
    """For each legality check emit a vector that violates ONLY that check, using Z3:
      violate(C) AND satisfy(all other checks). UNSAT => provably non-isolable (dead or
      spec-coupled/equivalent). Returns (vectors=[(vals,code)], non_isolable=[(code,reason)])."""
    fields = spec["fields"]; cross = spec.get("cross", [])
    def v5(): return {f["name"]: BitVec(f["name"], f["w"]) for f in fields}
    def field_legal(x, L):
        if "const" in L: return [x == L["const"]]
        if "enum" in L:  return [Or([x == q for q in L["enum"]])]
        if "range" in L: return [UGE(x, L["range"][0]), ULE(x, L["range"][1])]
        return []
    def minimal_illegal(w, L):
        """Smallest-magnitude illegal value for the field (avoids overflowing TB read width)."""
        if "const" in L:
            c = L["const"]
            for cand in ((c + 1) & ((1 << w) - 1), (c - 1) & ((1 << w) - 1)):
                if cand != c: return cand
            return None
        if "enum" in L:
            return next((c for c in range(1 << w) if c not in L["enum"]), None)
        if "range" in L:
            lo, hi = L["range"]
            if hi + 1 < (1 << w): return hi + 1
            if lo - 1 >= 0: return lo - 1
            return None
        return None
    def field_illegal(x, L, w):
        # const (often a WIDE reserved field): pin to the minimal illegal value so a
        # wide value can't overflow the TB stimulus-read width. enum/range: use the
        # GENERAL illegal constraint so Z3 can find an isolating value even when the
        # minimal one collides with a cross bound (fixes num_ports/ant_cfg misclass).
        if "const" in L:
            val = minimal_illegal(w, L)
            return None if val is None else (x == val)
        if "enum" in L:
            return And([x != q for q in L["enum"]])
        if "range" in L:
            lo, hi = L["range"]
            return Or(ULT(x, lo), UGT(x, hi))
        return None
    # checks: (code, kind, index)
    checks = []
    for f in fields:
        L = f["legal"]; kind = "CONST" if "const" in L else ("ENUM" if "enum" in L else "RANGE")
        checks.append((f"{kind}_{f['name']}", "field", f["name"]))
    for i, e in enumerate(cross): checks.append(("CROSS", "cross", i))
    vectors, non_isolable = [], []
    for code, ctype, key in checks:
        V = v5(); s = Solver()
        # satisfy every OTHER field-legality and every OTHER cross
        for f in fields:
            if ctype == "field" and f["name"] == key:  # this is the target field: make it illegal
                bad = field_illegal(V[f["name"]], f["legal"], f["w"])
                if bad is None:
                    non_isolable.append((code, "no-illegal-value")); continue
                s.add(bad)
            else:
                for c in field_legal(V[f["name"]], f["legal"]): s.add(c)
        for i, e in enumerate(cross):
            if ctype == "cross" and i == key:
                s.add(Not(parse_cross(e, V)))       # violate this cross
            else:
                s.add(parse_cross(e, V))            # keep other crosses legal
        if s.check() == sat:
            m = s.model()
            vals = {f["name"]: (m[V[f["name"]]].as_long() if m[V[f["name"]]] is not None else 0) for f in fields}
            if _which_violations(spec, vals) == {code}: vectors.append((vals, code))
            else: non_isolable.append((code, "coupled"))
        else:
            non_isolable.append((code, "unsat-dead-or-coupled"))
    return vectors, non_isolable

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", required=True)
    ap.add_argument("--seed", type=int, required=True)
    ap.add_argument("--n", type=int, default=300)
    ap.add_argument("--out", required=True)
    ap.add_argument("--neg", action="store_true")
    ap.add_argument("--isolate", action="store_true",
                    help="negative, ISOLATED: each txn violates exactly ONE legality check (RT-003 closure)")
    ap.add_argument("--directed", action="append", default=[])
    a = ap.parse_args()
    spec = json.load(open(a.spec)); fields = spec["fields"]
    assert sum(f["w"] for f in fields) == 64
    directed = dict(kv.split("=") for kv in a.directed)

    if a.isolate:
        vecs, non_iso = isolated_vectors(spec, a.seed)
        with open(a.out, "w") as fh:
            written = 0
            # repeat the isolated set to fill n, preserving one-per-check coverage
            while written < a.n and vecs:
                for vals, code in vecs:
                    word, pos = 0, 64
                    for f in fields:
                        pos -= f["w"]; word |= (vals[f["name"]] & ((1 << f["w"]) - 1)) << pos
                    cols = " ".join(f"{vals[f['name']]:x}" for f in fields)
                    fh.write(f"{cols} {word:016x}\n"); written += 1
                    if written >= a.n: break
        open(a.out + ".isohdr", "w").write(json.dumps(
            {"isolable": [c for _, c in vecs], "non_isolable": non_iso}, indent=1))
        print(f"[gen] {spec['slug']} ISOLATE seed={a.seed} isolable={len(vecs)} "
              f"non_isolable={non_iso} emitted={written} -> {a.out}")
        return

    rng = random.Random(a.seed if not a.neg else a.seed + 100000)
    v5 = {f["name"]: BitVec(f["name"], f["w"]) for f in fields}
    base = []
    for f in fields:
        L, x = f["legal"], v5[f["name"]]
        if "const" in L: base.append(x == L["const"])
        elif "enum" in L: base.append(Or([x == e for e in L["enum"]]))
        elif "range" in L: base += [UGE(x, L["range"][0]), ULE(x, L["range"][1])]
    for e in spec.get("cross", []): base.append(parse_cross(e, v5))
    for fn, val in directed.items(): base.append(v5[fn] == int(val))

    s = Solver(); s.add(base); emitted = 0
    with open(a.out, "w") as fh:
        for i in range(a.n):
            s.push()
            for f in fields:
                d = legal_draw(f, rng)
                if d is not None and f["name"] not in directed and rng.random() < 0.75:
                    s.add(v5[f["name"]] == d)
            if s.check() != sat:
                s.pop(); s.push(); assert s.check() == sat, "legal space UNSAT"
            m = s.model()
            vals = {f["name"]: (m[v5[f["name"]]].as_long() if m[v5[f["name"]]] is not None else 0)
                    for f in fields}
            s.pop()
            if a.neg:
                vals, _ = inject_illegal(spec, vals, rng, i)
            word, pos = 0, 64
            for f in fields:
                pos -= f["w"]; word |= (vals[f["name"]] & ((1 << f["w"]) - 1)) << pos
            cols = " ".join(f"{vals[f['name']]:x}" for f in fields)
            fh.write(f"{cols} {word:016x}\n"); emitted += 1
    mode = "NEG" if a.neg else ("DIR" if directed else "POS")
    print(f"[gen] {spec['slug']} {mode} seed={a.seed} emitted={emitted} -> {a.out}")

if __name__ == "__main__":
    main()
