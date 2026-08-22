#!/usr/bin/env python3
# ======================================================================
#  File   : gen/cus_pin_diff.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Desc   : GAP-ORAN-001 closure SCAFFOLD. Emits the requirement-diff worksheet
#           for pinning O-RAN.WG4.CUS to R004-v16: every DERIVED requirement
#           (per component, per field + per cross), fully populated on the
#           DERIVED side, with fillable PINNED columns (clause ref + pinned
#           legal value) and the downstream checker/coverage/isoneg artifact it
#           traces to. Fill the PINNED_* columns from the pinned text, set
#           STATUS to PINNED/CHANGED, then re-run gen/audit_dead.py — a width
#           change can turn a TRUE_DEAD check live (deadness is width-contingent).
#  Out     : regression/cus_pin_diff.csv  +  docs/CUS_PIN_DIFF.md
# ======================================================================
import json, os, csv
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ORDER = ["ecpri_transport","cpri_eth","uplane","cplane","splane","mplane","beamforming",
         "compression","prach","mimo_massive","bwp","mmwave","laa"]
# clause anchors per component (WG4.CUS §; fill exact clause/table on pin)
SPECREF = {}
def dead_set(slug):
    try:
        m = json.load(open(os.path.join(ROOT,"regression","dead_audit.json")))
    except Exception: return set()
    return set()  # per-check deadness is read from isoneg header below
def iso_meta(slug):
    p = os.path.join(ROOT,"components",slug,"sim_out",f"{slug}_isoneg_seed1.hex.isohdr")
    try: d=json.load(open(p)); return set(d.get("isolable",[])), {c for c,_ in d.get("non_isolable",[])}
    except Exception: return set(), set()

def legal_str(L):
    if "const" in L: return f"const={L['const']}"
    if "enum"  in L: return "enum{" + ",".join(map(str,L["enum"])) + "}"
    if "range" in L: return f"range[{L['range'][0]}:{L['range'][1]}]"
    return "?"
def kind_of(L): return "const" if "const" in L else ("enum" if "enum" in L else "range")

ROWS = []
HDR = ["FR_ID","component","spec_ref_DERIVED","element","kind","width_bits",
       "DERIVED_legal","PINNED_clause_ref(TODO)","PINNED_legal(TODO)",
       "STATUS(DERIVED|PINNED|CHANGED)","reachable_now","traces_to_checker","traces_to_cover/isoneg","notes"]
for slug in ORDER:
    spec = json.load(open(os.path.join(ROOT,"components",slug,"spec.json")))
    tag = slug.upper(); ref = spec.get("spec_ref","O-RAN.WG4.CUS (clause TBD)")
    iso, dead = iso_meta(slug)
    n = 0
    for f in spec["fields"]:
        n += 1
        L = f["legal"]; k = kind_of(L); code = f"{k.upper()}_{f['name']}"
        # reachable if an illegal encoding exists at current width
        if k=="const": reach = "yes" if (1<<f["w"])>1 else "no"
        elif k=="enum": reach = "yes" if len(set(L["enum"]))<(1<<f["w"]) else "no(TRUE_DEAD)"
        else:
            lo,hi=L["range"]; reach = "yes" if (hi-lo+1)<(1<<f["w"]) else "no(TRUE_DEAD)"
        ROWS.append([f"FR-{tag}-{n:02d}", slug, ref, f["name"], k, f["w"],
                     legal_str(L), "", "", "DERIVED", reach,
                     f"CHK-{tag}-{n:02d} / first_violation:{code}",
                     f"cover:{f['name']} / isoneg:{code}",
                     "width-contingent deadness" if reach.startswith("no") else ""])
    for j,e in enumerate(spec.get("cross",[]),1):
        n += 1
        ROWS.append([f"FR-{tag}-{n:02d}", slug, ref, e, "cross", "-",
                     e, "", "", "DERIVED", "yes",
                     f"CHK-{tag}-cross{j} / first_violation:CROSS_{j-1}",
                     f"cover:cross / isoneg:CROSS", ""])

# CSV
csvp = os.path.join(ROOT,"regression","cus_pin_diff.csv")
with open(csvp,"w",newline="") as fh:
    w=csv.writer(fh); w.writerow(HDR); w.writerows(ROWS)

# Markdown view
md = ["# O-RAN VIP — CUS R004-v16 Requirement Pin/Diff Worksheet",
      "",
      "**Author:** AVIK MAJUMDAR · **Project:** AVIK VIP FACTORY — O-RAN VIP Suite · GAP-ORAN-001",
      "",
      "Purpose: reclassify GATE-0 from **DERIVED** to **PINNED** by diffing every derived requirement "
      "against the pinned O-RAN.WG4.CUS.0 **R004-v16.01** text. Fill `PINNED_clause_ref` and `PINNED_legal`, "
      "set `STATUS`, then **re-run `gen/audit_dead.py`** — narrowing a field can turn a TRUE_DEAD check live "
      "(deadness is width-contingent), and any legal-space change must flow to its checker, coverage bin, and "
      "isolated-negative vector.",
      "",
      f"Total requirements to reconcile: **{len(ROWS)}** across 13 components "
      f"({sum(1 for r in ROWS if r[4]!='cross')} field + {sum(1 for r in ROWS if r[4]=='cross')} cross). "
      "Machine-fillable copy: `regression/cus_pin_diff.csv`.",
      ""]
cur = None
for r in ROWS:
    if r[1] != cur:
        cur = r[1]
        md += ["", f"## {cur} — {r[2]}", "",
               "| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |",
               "|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|"]
    md.append(f"| {r[0]} | `{r[3]}` | {r[4]} | {r[5]} | {r[6]} |  |  | {r[10]} | {r[11]} |")
md += ["","## Procedure","",
       "1. For each row, locate the governing clause/table in R004-v16 and record `PINNED_clause_ref`.",
       "2. Enter `PINNED_legal`; set `STATUS=PINNED` if unchanged, `CHANGED` if the legal space moves.",
       "3. For every `CHANGED` row: update `spec.json`, regenerate stimulus/coverage, and re-run "
       "`make regress && make mutation && make isoneg && make audit-dead`.",
       "4. Re-audit deadness: a `CHANGED` narrowing may flip `reachable=no(TRUE_DEAD)` to `yes` — that check "
       "then MUST appear in the isolated-negative set (kill_iso denominator grows).",
       "5. When all rows are PINNED/CHANGED and clean, reclassify GATE-0 DERIVED→PINNED and close GAP-ORAN-001.",
       ""]
open(os.path.join(ROOT,"docs","CUS_PIN_DIFF.md"),"w").write("\n".join(md))
print(f"wrote regression/cus_pin_diff.csv ({len(ROWS)} requirements) + docs/CUS_PIN_DIFF.md")
