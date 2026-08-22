#!/usr/bin/env python3
# ======================================================================
#  File   : gen/build_suite.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Lane-1 suite generator+driver: emits pkg/codec/TB/sim_main per component from SPECS, coverage-enabled build, GATE 2/3.
# ======================================================================
"""
build_suite.py — scaffolds + runs the O-RAN VIP Lane-1 suite from component specs.
For each component: emits <slug>_pkg.sv, <slug>_codec.sv, <slug>_tb_top.sv,
spec.json, run.sh, docs/GATE0+GATE1; then compiles (Verilator 5.020) and runs
GATE 2 (compile) + GATE 3 (smoke seeds 1,2,3). Aggregates suite_regression.json.
Requirements: DERIVED from O-RAN.WG4.CUS v13 / eCPRI v2.0 / 3GPP TS 38.211 knowledge
(revision-reconciled when CUS pin closes GAP-ORAN-001).
"""
import json, os, subprocess, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GEN  = os.path.join(ROOT, "gen")
COMP = os.path.join(ROOT, "components")

# ---- component field specs (each header totals <=64b; auto-padded) ----------
# field: (name, width, legal_dict, cover_kind_or_None)
SPECS = {
 "ecpri_transport": dict(spec_ref="eCPRI v2.0 §3.1 common header + §3.2 Type-0 IQ",
   fields=[("version",4,{"const":1},None),("rsvd",3,{"const":0},None),
     ("concat",1,{"range":[0,1]},"bool"),("msg_type",8,{"range":[0,7]},"enum"),
     ("payload_size",16,{"range":[8,1024]},"bucket4"),("pc_id",16,{"range":[0,65535]},None),
     ("seq_id",8,{"range":[0,255]},"wrap"),("e_bit",1,{"range":[0,1]},"bool"),
     ("sub_seq",7,{"range":[0,127]},None)], cross=[]),
 "cpri_eth": dict(spec_ref="CPRI-over-Ethernet 4G (IEEE1914.3 RoE + eCPRI transport)",
   fields=[("version",4,{"const":1},None),("bw_profile",4,{"enum":[0,1,2,3,4,5]},"enum"),
     ("direction",1,{"range":[0,1]},"bool"),("iq_rate_id",4,{"range":[0,15]},None),
     ("synce_ql",4,{"enum":[0,2,4,11,15]},"enum"),("frame_id",10,{"range":[0,1023]},None),
     ("subframe",4,{"range":[0,9]},None),("cm_flag",1,{"range":[0,1]},"bool"),
     ("seq",8,{"range":[0,255]},"wrap")], cross=[]),
 "uplane": dict(spec_ref="O-RAN.WG4.CUS §7 U-plane Section Types 1/3/5/6",
   fields=[("version",4,{"const":1},None),("section_type",4,{"enum":[1,3,5,6]},"enum"),
     ("numerology",4,{"range":[0,4]},"enum"),("start_prb",9,{"range":[0,273]},None),
     ("num_prb",9,{"range":[1,275]},"bucket4"),("symbol_id",4,{"range":[0,13]},None),
     ("comp_type",2,{"enum":[0,1,2,3]},"enum"),("comp_bits",5,{"range":[9,16]},None),
     ("seq",8,{"range":[0,255]},"wrap")], cross=["start_prb + num_prb <= 275"]),
 "cplane": dict(spec_ref="O-RAN.WG4.CUS §5 C-plane Section Types 0-8, Ext 1-11",
   fields=[("version",4,{"const":1},None),("section_type",4,{"range":[0,8]},"enum"),
     ("section_ext",4,{"range":[1,11]},"enum"),("start_symbol",4,{"range":[0,13]},None),
     ("num_symbol",4,{"range":[1,14]},"bucket4"),("num_sections",4,{"enum":[1,2,4,8]},"enum"),
     ("beam_id",16,{"range":[0,65535]},None),("numerology",4,{"range":[0,4]},"enum"),
     ("seq",8,{"range":[0,255]},"wrap")], cross=["start_symbol + num_symbol <= 14"]),
 "splane": dict(spec_ref="O-RAN.WG4.CUS §9 S-plane IEEE1588v2 PTP + SyncE",
   fields=[("version",4,{"const":1},None),("ptp_msg",4,{"enum":[0,1,2,3,4,5]},"enum"),
     ("clock_state",2,{"enum":[0,1,2,3]},"enum"),("synce_ql",4,{"enum":[0,2,4,11,15]},"enum"),
     ("seq",16,{"range":[0,65535]},"wrap"),("timing_err",12,{"range":[0,3000]},None),
     ("holdover",1,{"range":[0,1]},"bool")], cross=[]),
 "mplane": dict(spec_ref="O-RAN.WG4.MP M-plane NETCONF/YANG O1",
   fields=[("version",4,{"const":1},None),("netconf_op",3,{"enum":[0,1,2,3,4]},"enum"),
     ("datastore",2,{"enum":[0,1,2]},"enum"),("item_id",16,{"range":[0,65535]},None),
     ("ant_cal",1,{"range":[0,1]},"bool"),("sw_slot",3,{"range":[0,7]},None),
     ("seq",8,{"range":[0,255]},"wrap")], cross=[]),
 "beamforming": dict(spec_ref="O-RAN.WG4.CUS Section Ext 1/4/5/6 beamforming",
   fields=[("version",4,{"const":1},None),("beam_id",16,{"range":[0,65535]},None),
     ("num_ports",8,{"enum":[1,2,4,8,16,32,64]},"enum"),("num_layers",4,{"range":[1,8]},None),
     ("section_ext",4,{"enum":[1,4,5,6]},"enum"),("codebook_idx",16,{"range":[0,65535]},None),
     ("seq",8,{"range":[0,255]},"wrap")], cross=["num_layers <= num_ports"]),
 "compression": dict(spec_ref="O-RAN.WG4.CUS Annex A IQ compression BFP/mu-law/static",
   fields=[("version",4,{"const":1},None),("method",2,{"enum":[0,1,2]},"enum"),
     ("iq_width",5,{"const":16},None),("comp_width",5,{"enum":[9,10,11,12,13,14,15,16]},"enum"),
     ("exponent",4,{"range":[0,15]},None),("block_size",8,{"range":[1,255]},None),
     ("seq",8,{"range":[0,255]},"wrap")], cross=["comp_width <= iq_width"]),
 "prach": dict(spec_ref="O-RAN.WG4.CUS Section Type 3 PRACH + 3GPP TS38.211 formats",
   fields=[("version",4,{"const":1},None),("section_type",4,{"const":3},None),
     ("format",4,{"enum":[0,1,2,3,4,5,6,7,8,9]},"enum"),("numerology",4,{"range":[0,4]},"enum"),
     ("fr",1,{"range":[0,1]},"bool"),("zc_root",8,{"range":[0,255]},None),
     ("occasion",6,{"range":[0,63]},None),("seq",8,{"range":[0,255]},"wrap")], cross=[]),
 "mimo_massive": dict(spec_ref="O-RAN.WG4.CUS Sect Ext 5/6 + 3GPP massive MIMO 64T64R",
   fields=[("version",4,{"const":1},None),("ant_cfg",8,{"enum":[1,2,4,8,16,32,64]},"enum"),
     ("num_layers",4,{"range":[1,8]},None),("tdd_cfg",3,{"range":[0,6]},"enum"),
     ("rank",4,{"range":[1,8]},None),("precoder_idx",8,{"range":[0,255]},None),
     ("seq",8,{"range":[0,255]},"wrap")], cross=["num_layers <= ant_cfg","rank <= num_layers"]),
 "bwp": dict(spec_ref="O-RAN.WG4.CUS BWP + 3GPP TS38.211 FR1/FR2 numerology",
   fields=[("version",4,{"const":1},None),("bwp_id",2,{"range":[0,3]},"enum"),
     ("numerology",4,{"range":[0,4]},"enum"),("bw_mhz",9,{"enum":[5,10,15,20,25,40,50,60,80,100,200,400]},"enum"),
     ("fr",1,{"range":[0,1]},"bool"),("active",1,{"range":[0,1]},"bool"),
     ("seq",8,{"range":[0,255]},"wrap")], cross=[]),
 "mmwave": dict(spec_ref="3GPP TS38.211 FR2 mmWave n257/n258/n260/n261, mu=2/3/4",
   fields=[("version",4,{"const":1},None),("band",3,{"enum":[0,1,2,3]},"enum"),
     ("numerology",4,{"range":[2,4]},"enum"),("scs",2,{"enum":[0,1,2]},"enum"),
     ("ssb_period",4,{"enum":[0,1,2,3,4,5]},"enum"),("beam_id",16,{"range":[0,65535]},None),
     ("seq",8,{"range":[0,255]},"wrap")], cross=[]),
 "laa": dict(spec_ref="O-RAN.WG4.CUS Section Type 5 LAA + LBT Cat1-4",
   fields=[("version",4,{"const":1},None),("section_type",4,{"const":5},None),
     ("lbt_cat",3,{"enum":[1,2,3,4]},"enum"),("lbt_result",1,{"range":[0,1]},"bool"),
     ("burst_type",1,{"range":[0,1]},"bool"),("cap",2,{"range":[0,3]},"enum"),
     ("section_ext",4,{"const":3},None),("seq",8,{"range":[0,255]},"wrap")], cross=[]),
}

def pad(fields):
    tot = sum(w for _, w, _, _ in fields)
    assert tot <= 64, f"header {tot}b > 64"
    if tot < 64: fields = fields + [("rsvd", 64 - tot, {"const": 0}, None)]
    return fields

def cover_list(fields):
    out = []
    for i, (n, w, L, ck) in enumerate(fields):
        if not ck: continue
        cid = f"COV-{i+1:03d}"
        if ck == "enum":
            args = L["enum"] if "enum" in L else list(range(L["range"][0], L["range"][1] + 1))
            out.append(dict(id=cid, field=n, kind="enum", args=args))
        elif ck == "bool": out.append(dict(id=cid, field=n, kind="bool", args=[0, 1]))
        elif ck in ("wrap", "bucket4"): out.append(dict(id=cid, field=n, kind=ck, args=L["range"]))
    return out

def emit_pkg(slug, fields):
    lines = [f"package {slug}_pkg;", "  localparam int HDR_W = 64;",
             f"  typedef struct packed {{"]
    for n, w, L, _ in fields: lines.append(f"    bit [{w-1}:0] {n};")
    lines.append(f"  }} {slug}_hdr_t;")
    cat = ", ".join(f"h.{n}" for n, _, _, _ in fields)
    lines.append(f"  function automatic bit [63:0] {slug}_pack(input {slug}_hdr_t h);")
    lines.append(f"    return {{ {cat} }};")
    lines.append("  endfunction")
    lines.append(f"  function automatic {slug}_hdr_t {slug}_unpack(input bit [63:0] w);")
    lines.append(f"    {slug}_hdr_t h; int p; p = 64;")
    for n, w, _, _ in fields:
        lines.append(f"    p -= {w}; h.{n} = w[p +: {w}];")
    lines.append("    return h;")
    lines.append("  endfunction")
    # per-check (code, condition) — drives both is_legal and first_violation
    checks = []
    for n, w, L, _ in fields:
        if "const" in L: checks.append((f"CONST_{n}", f"(h.{n} == {L['const']})"))
        elif "enum" in L: checks.append((f"ENUM_{n}", "(" + " || ".join(f"h.{n}=={e}" for e in L["enum"]) + ")"))
        elif "range" in L: checks.append((f"RANGE_{n}", f"(h.{n} >= {L['range'][0]} && h.{n} <= {L['range'][1]})"))
    return "\n".join(lines), checks

def emit(slug, spec):
    d = os.path.join(COMP, slug)
    for sub in ("rtl", "tb", "sim_out", "docs"): os.makedirs(os.path.join(d, sub), exist_ok=True)
    fields = pad([(n, w, L, ck) for (n, w, L, ck) in spec["fields"]])
    cover = cover_list(fields)
    # spec.json (source of truth for stim + adjudicate)
    json.dump(dict(slug=slug, spec_ref=spec["spec_ref"],
                   fields=[dict(name=n, w=w, legal=L) for n, w, L, _ in fields],
                   cross=spec["cross"], cover=cover),
              open(os.path.join(d, "spec.json"), "w"), indent=2)
    pkg_body, checks = emit_pkg(slug, fields)
    # cross into checks (h.<name> substitution); longest names first to avoid partial hits
    for i, expr in enumerate(spec["cross"]):
        e = expr
        for n, _, _, _ in sorted(fields, key=lambda t: -len(t[0])): e = e.replace(n, f"h.{n}")
        checks.append((f"CROSS_{i}", f"({e})"))
    is_legal = "    return " + " && ".join(c for _, c in checks) + ";"
    fv = "\n".join(f'    if(!{cond}) return "{code}";' for code, cond in checks) + '\n    return "";'
    pkg = (pkg_body +
           f"\n  function automatic bit {slug}_is_legal(input {slug}_hdr_t h);\n{is_legal}\n  endfunction\n"
           f"  function automatic string {slug}_first_violation(input {slug}_hdr_t h);\n{fv}\n  endfunction\n"
           f"endpackage\n")
    open(os.path.join(d, "rtl", f"{slug}_pkg.sv"), "w").write(pkg)
    # codec
    open(os.path.join(d, "rtl", f"{slug}_codec.sv"), "w").write(
        f"module {slug}_codec import {slug}_pkg::*; (\n"
        f"  input {slug}_hdr_t in_hdr, output logic [63:0] wire_hdr,\n"
        f"  input logic [63:0] rx_wire, output {slug}_hdr_t out_hdr);\n"
        f"  assign wire_hdr = {slug}_pack(in_hdr);\n"
        f"  assign out_hdr  = {slug}_unpack(rx_wire);\nendmodule\n")
    # tb
    fscan = " ".join(["%h"] * (len(fields) + 1))
    reads = ", ".join([f"r_{n}" for n, _, _, _ in fields] + ["r_gold"])
    decls = "\n".join(f"  int unsigned r_{n};" for n, _, _, _ in fields)
    assigns = "\n".join(f"      m_in.{n} = r_{n}[{w-1}:0];" for n, w, _, _ in fields)
    covrow = ",".join(f"{n}=%0d" for n in [c["field"] for c in cover])
    covargs = "".join(f", m_out.{c['field']}" for c in cover)
    tb = f"""module {slug}_tb_top import {slug}_pkg::*; ;
  {slug}_hdr_t m_in, m_out; logic [63:0] m_wire; string vio;
  int unsigned m_txns=0,m_legal=0,m_pack=0,m_rt=0,m_uvm_err=0,m_uvm_fatal=0;
  int unsigned m_exp=0,m_unexp=0,m_ex_leg=0,m_ex_rt=0,m_ex_pack=0,m_neg=0;
  string m_stim; int m_fd,m_rc; longint unsigned r_gold;
{decls}
  initial begin
    if(!$value$plusargs("STIM=%s",m_stim)) begin $display("UVM_FATAL @ 0: [TB] no +STIM"); m_uvm_fatal++; finish_up(); end
    void'($value$plusargs("NEG=%d",m_neg));
    m_fd=$fopen(m_stim,"r");
    if(m_fd==0) begin $display("UVM_FATAL @ 0: [TB] cannot open %s",m_stim); m_uvm_fatal++; finish_up(); end
    m_rc=$fscanf(m_fd,"{fscan}",{reads});
    while(m_rc=={len(fields)+1}) begin
{assigns}
      m_wire={slug}_pack(m_in); m_out={slug}_unpack(m_wire);
      // format invariants (hold for legal AND illegal field values)
      m_ex_pack++; if(m_wire!==r_gold[63:0]) begin m_pack++; m_uvm_err++; $display("UVM_ERROR @ %0t: [PACK] txn#%0d dut=%016h gold=%016h",$time,m_txns,m_wire,r_gold[63:0]); end
      m_ex_rt++;   if(m_out!==m_in) begin m_rt++; m_uvm_err++; $display("UVM_ERROR @ %0t: [ROUNDTRIP] txn#%0d",$time,m_txns); end
      // legality invariant (GATE 6/7)
      m_ex_leg++; vio={slug}_first_violation(m_in);
      if(m_neg) begin
        if(vio!="") begin m_exp++; if(m_exp<=5) $display("EXPECTED_FAILURE_DETECTED: %s",vio); end
        else begin m_unexp++; m_uvm_err++; $display("UVM_ERROR @ %0t: [NEG] UNEXPECTED_PASS txn#%0d (illegal stim not detected)",$time,m_txns); end
      end else begin
        if(vio!="") begin m_legal++; m_uvm_err++; $display("UVM_ERROR @ %0t: [LEGALITY] txn#%0d vio=%s",$time,m_txns,vio); end
        $display("COVROW,{covrow}"{covargs});
      end
      m_txns++;
      m_rc=$fscanf(m_fd,"{fscan}",{reads});
    end
    $fclose(m_fd); finish_up();
  end
  task automatic finish_up();
    $display("SBSUMMARY,txns=%0d,legal_err=%0d,pack_err=%0d,rt_err=%0d",m_txns,m_legal,m_pack,m_rt);
    $display("SVA_EXERCISED,legality=%0d,roundtrip=%0d,pack=%0d",m_ex_leg,m_ex_rt,m_ex_pack);
    if(m_neg) $display("NEGSUMMARY,expected=%0d,unexpected=%0d",m_exp,m_unexp);
    $display("--- UVM Report Summary ---");
    $display("UVM_INFO :  %0d",m_txns); $display("UVM_WARNING : 0");
    $display("UVM_ERROR : %0d",m_uvm_err); $display("UVM_FATAL : %0d",m_uvm_fatal);
    if(m_neg) begin
      if(m_uvm_err==0 && m_uvm_fatal==0 && m_txns>0 && m_unexp==0 && m_exp==m_txns) $display("** TEST PASSED **");
      else $display("** TEST FAILED **");
    end else begin
      if(m_uvm_err==0 && m_uvm_fatal==0 && m_txns>0) $display("** TEST PASSED **");
      else $display("** TEST FAILED **");
    end
    $finish;
  endtask
endmodule
"""
    open(os.path.join(d, "tb", f"{slug}_tb_top.sv"), "w").write(tb)
    # run.sh
    open(os.path.join(d, "run.sh"), "w").write(f"""#!/usr/bin/env bash
set -u
S="{slug}"; TEST="${{1:-smoke}}"; SEED="${{2:-1}}"; N="${{3:-300}}"
D="$(cd "$(dirname "$0")" && pwd)"; GEN="{GEN}"; OUT="$D/sim_out"; mkdir -p "$OUT"
STIM="$OUT/${{S}}_${{TEST}}_seed${{SEED}}.hex"; LOG="$OUT/${{TEST}}_seed${{SEED}}.log"
RES="$OUT/result_${{TEST}}_seed${{SEED}}.json"; MDIR="$OUT/obj_${{TEST}}_${{SEED}}"
python3 "$GEN/gen_stim.py" --spec "$D/spec.json" --seed "$SEED" --n "$N" --out "$STIM" || exit 2
verilator --cc --exe --build -j 0 --timing --coverage -Wno-CONSTRAINTIGN -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-UNUSEDSIGNAL -Wno-fatal \\
  --Mdir "$MDIR" -o simv --top-module ${{S}}_tb_top \\
  "$D/sim_main.cpp" "$D/rtl/${{S}}_pkg.sv" "$D/rtl/${{S}}_codec.sv" "$D/tb/${{S}}_tb_top.sv" > "$OUT/${{TEST}}_seed${{SEED}}.compile.log" 2>&1 || {{ echo "COMPILE FAIL"; tail -15 "$OUT/${{TEST}}_seed${{SEED}}.compile.log"; exit 3; }}
( cd "$OUT" && "$MDIR/simv" +STIM="$STIM" +verilator+seed+"$SEED" ) > "$LOG" 2>&1; SRC=$?
python3 "$GEN/adjudicate.py" --spec "$D/spec.json" --log "$LOG" --sim-exit "$SRC" --test "$TEST" --seed "$SEED" --out "$RES"
""")
    os.chmod(os.path.join(d, "run.sh"), 0o755)
    # custom main -> enables coverage.dat write (--binary main omits it; GAP-ORAN-003 fix)
    open(os.path.join(d, "sim_main.cpp"), "w").write(f"""#include "verilated.h"
#include "verilated_cov.h"
#include "V{slug}_tb_top.h"
int main(int argc, char** argv) {{
  VerilatedContext* ctx = new VerilatedContext; ctx->commandArgs(argc, argv);
  V{slug}_tb_top* top = new V{slug}_tb_top{{ctx}};
  int g = 0;
  while (!ctx->gotFinish() && g++ < 4000000) {{
    ctx->timeInc(1); top->eval();
    if (!top->eventsPending()) {{ top->eval(); break; }}
  }}
  top->final();
#if VM_COVERAGE
  ctx->coveragep()->write("coverage.dat");
#endif
  delete top; delete ctx; return 0;
}}
""")
    # gate docs
    open(os.path.join(d, "docs", f"GATE0_{slug}_vplan.md"), "w").write(
        f"# GATE 0 vplan — {slug} (DERIVED)\nSpec: {spec['spec_ref']}\n"
        f"Fields (64b header): {', '.join(n for n,_,_,_ in fields)}\n"
        f"Cross-constraints (Z3-enforced, SV cannot solve): {spec['cross'] or 'none'}\n"
        f"Coverage COV-###: {', '.join(c['id']+':'+c['field'] for c in cover)}\n"
        f"Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.\n"
        f"Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.\n")
    open(os.path.join(d, "docs", f"GATE1_{slug}_arch.md"), "w").write(
        f"# GATE 1 arch — {slug}\nseq_item={slug}_hdr_t; CRV=Z3 seeded (constraint model=legal space);\n"
        f"driver=procedural apply; monitor=COVROW; scoreboard=legality+golden+round-trip;\n"
        f"coverage=Python COV-### engine; reporter=UVM-format. Lane-2 delta: native UVM/covergroup/SVA.\n")
    return slug, len(fields), cover

def run_gate23(slug):
    d = os.path.join(COMP, slug)
    res = {}
    for seed in (1, 2, 3):
        p = subprocess.run(["bash", os.path.join(d, "run.sh"), "smoke", str(seed), "300"],
                           capture_output=True, text=True)
        rp = os.path.join(d, "sim_out", f"result_smoke_seed{seed}.json")
        if os.path.exists(rp): res[seed] = json.load(open(rp))
        else: res[seed] = {"status": "NOT_VERIFIED", "stderr": p.stdout[-400:]}
    return res

def main():
    only = sys.argv[1:] or list(SPECS.keys())
    agg = {}
    for slug in only:
        emit(slug, SPECS[slug])
        r = run_gate23(slug)
        statuses = [r[s].get("status") for s in (1, 2, 3)]
        fcov = [r[s].get("functional_coverage") for s in (1, 2, 3)]
        gate2 = "PASS" if all(s in ("PASS", "FAIL") for s in statuses) and all(s != "NOT_VERIFIED" for s in statuses) else "FAIL"
        gate3 = "PASS" if all(s == "PASS" for s in statuses) else "FAIL"
        agg[slug] = dict(gate2_compile=gate2, gate3_smoke=gate3, seed_status=statuses, fcov=fcov)
        print(f"{slug:14s} GATE2={gate2:4s} GATE3={gate3:4s} status={statuses} fcov={fcov}")
    json.dump(agg, open(os.path.join(ROOT, "regression", "suite_regression.json") if os.path.isdir(os.path.join(ROOT,"regression")) else os.path.join(ROOT, "suite_regression.json"), "w"), indent=2)
    npass = sum(1 for v in agg.values() if v["gate3_smoke"] == "PASS")
    print(f"\nSUITE GATE 2/3: {npass}/{len(agg)} components PASS smoke")

if __name__ == "__main__":
    main()
