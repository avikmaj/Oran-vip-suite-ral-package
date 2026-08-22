#!/usr/bin/env python3
"""stamp_headers.py — prepend an authored, descriptive header to every source file.
Author of the suite: AVIK MAJUMDAR. Idempotent (skips already-stamped files)."""
import os, re, datetime
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATE = "2026-08-09"
AUTHOR = "AVIK MAJUMDAR"
SKIP_DIRS = ("obj", "obj_dir", "obj_suite", "obj_suite2", "obj050", ".ccache", "uvm", "verilator_src")

def desc(path):
    b = os.path.basename(path); rel = os.path.relpath(path, ROOT)
    slug = ""
    m = re.search(r"components/([a-z0-9_]+)/", rel) or re.search(r"suite/([a-z0-9_]+)_uvm_pkg", b) \
        or re.search(r"([a-z0-9_]+)_(l2a|uvm)_pkg", b)
    if m: slug = m.group(1)
    T = {
      "gen_stim.py": "Lane-1 Z3 constrained-random stimulus generator (positive/--neg/--directed). "
                     "The Z3 model IS the legal space; native randomize() ignored on Verilator 5.020.",
      "adjudicate.py": "Result adjudicator — STATUS from executed evidence only (PASS_FAIL_POLICY). "
                       "Parses UVM-format summary + COVROW; emits result.json.",
      "build_suite.py": "Lane-1 suite generator+driver: emits pkg/codec/TB/sim_main per component "
                        "from SPECS, coverage-enabled build, GATE 2/3.",
      "run_gates.py": "Lane-1 GATE 4-8 driver: literal-scan, random L3, negative, assertion "
                      "exercise, functional coverage closure.",
      "code_cov.py": "Lane-1 GATE-8 code coverage (line/branch/toggle) via verilated coverage.dat; "
                     "merges pos+neg+corrupt runs; TB-defensive branch waivers.",
      "corner.py": "Corner/edge-case generator+runner: field min/max, cross-constraint boundaries, "
                   "sequence wrap extremes.",
      "report.py": "Full-regression + full-coverage report/dashboard generator (all test classes).",
      "gen_uvm.py": "Lane-2A UVM-subset env generator (muvm_pkg) per component from spec.json.",
      "gen_uvm_native.py": "Lane-2B NATIVE UVM generator: native constraints + covergroup "
                           "(cross+illegal_bins) + full uvm_component env per component.",
      "muvm_pkg.sv": "UVM-1.1-compatible SUBSET that elaborates+runs on Verilator: object/component/"
                     "phasing/factory(+override)/config_db/analysis-port/run_test.",
      "vpi_stub.cc": "vpi_get_vlog_info stub enabling full Accellera UVM link on Verilator 5.050.",
    }
    if b in T: return T[b]
    if b.endswith("_pkg.sv") and "/rtl/" in rel:
        return (f"{slug} protocol field model (Lane-1): packed 64-bit header struct, explicit "
                f"pack/unpack, is_legal (per-field+cross), first_violation (negative naming).")
    if b.endswith("_codec.sv"):
        return f"{slug} block-under-test: combinational pack/unpack codec (round-trip verified)."
    if b.endswith("_tb_top.sv") and "/tb/" in rel:
        return (f"{slug} self-checking TESTBENCH (Lane-1): driver applies Z3 stimulus; SCOREBOARD "
                f"checks legality + pack-vs-golden + round-trip; ASSERTIONS as procedural invariant "
                f"checks with exercise counters; COVERAGE via COVROW monitor log; UVM-format reporter.")
    if b.endswith("_l2a_pkg.sv"):
        return (f"{slug} Lane-2A UVM-subset ENV: seq_item, SEQUENCER (Z3-loaded), DRIVER, component "
                f"SCOREBOARD (analysis port) with legality/pack/round-trip checks + COVROW COVERAGE.")
    if b.endswith("_l2a_tb_top.sv"):
        return f"{slug} Lane-2A UVM-subset top: factory registration + muvm_root::run_test."
    if b.endswith("_uvm_pkg.sv"):
        return (f"{slug} Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, "
                f"component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).")
    if b == "oran_uvm_tb_top.sv":
        return "Lane-2B combined native-UVM top: 13-component factory registration + run_test(+UVM_TESTNAME)."
    if b.endswith("ecpri_if.sv"):
        return "Lane-2B concurrent-SVA interface: version/msg/payload/seq-continuity ASSERTIONS + cover."
    if b == "sim_main.cpp":
        return "Verilator C++ main: drives eval loop + flushes coverage.dat (code coverage enable)."
    if b.endswith(".sh"):
        return "Build/run automation script."
    return f"O-RAN VIP Suite source ({rel})."

def stamp(path, cmt):
    txt = open(path, encoding="utf-8", errors="ignore").read()
    if AUTHOR in txt[:600]:
        return False
    d = desc(path)
    bar = cmt + "=" * 70
    hdr = (f"{bar}\n{cmt} File   : {os.path.relpath(path, ROOT)}\n"
           f"{cmt} Author : {AUTHOR}\n{cmt} Project: AVIK VIP FACTORY - O-RAN VIP Suite\n"
           f"{cmt} Date   : {DATE}\n{cmt} Desc   : {d}\n{bar}\n")
    # keep shebang first
    if txt.startswith("#!"):
        nl = txt.index("\n") + 1
        txt = txt[:nl] + hdr + txt[nl:]
    else:
        txt = hdr + txt
    open(path, "w", encoding="utf-8").write(txt)
    return True

def main():
    n = 0
    for dp, dn, fn in os.walk(ROOT):
        dn[:] = [d for d in dn if d not in SKIP_DIRS and not d.startswith("obj")]
        for f in fn:
            p = os.path.join(dp, f)
            if f.endswith((".sv", ".svh")): cmt = "// "
            elif f.endswith((".py", ".sh")): cmt = "# "
            elif f.endswith((".cpp", ".c", ".cc", ".h")): cmt = "// "
            else: continue
            try:
                if stamp(p, cmt): n += 1
            except Exception as e:
                print("skip", p, e)
    print(f"stamped {n} files with Author: {AUTHOR}")

if __name__ == "__main__":
    main()
