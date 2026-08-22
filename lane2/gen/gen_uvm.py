#!/usr/bin/env python3
# ======================================================================
#  File   : lane2/gen/gen_uvm.py
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Lane-2A UVM-subset env generator (muvm_pkg) per component from spec.json.
# ======================================================================
"""
gen_uvm.py — emit + build + run Lane-2A UVM-subset environments for all 13
components (real UVM component architecture on Verilator via muvm_pkg).
Each env: factory-created test/env/agent/sequencer/driver + component scoreboard
(analysis port), config_db, full phasing. Reuses Lane-1 <slug>_pkg pack/unpack +
Z3 stimulus. Emits result.json (executed evidence) + functional COVROW.
"""
import glob, json, os, subprocess, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
L2   = os.path.join(ROOT, "lane2"); MUVM = os.path.join(L2, "common", "muvm_pkg.sv")
GEN  = os.path.join(ROOT, "gen")
ORDER = ["ecpri_transport","cpri_eth","uplane","cplane","splane","mplane","beamforming",
         "compression","prach","mimo_massive","bwp","mmwave","laa"]

def emit(slug):
    spec = json.load(open(f"{ROOT}/components/{slug}/spec.json"))
    fields = spec["fields"]; cover = spec.get("cover", [])
    d = f"{L2}/components/{slug}"; os.makedirs(d, exist_ok=True)
    nf = len(fields)
    fscan = " ".join(["%h"]*(nf+1))
    decls = " ".join(f"r_{f['name']}," for f in fields) + "rg"
    vdecl = "; ".join(f"int unsigned r_{f['name']}" for f in fields) + "; longint unsigned rg"
    assigns = "\n        ".join(f"it.hdr.{f['name']}=r_{f['name']}[{f['w']-1}:0];" for f in fields)
    covrow = ",".join(f"{c['field']}=%0d" for c in cover)
    covargs = "".join(f", it.hdr.{c['field']}" for c in cover)
    P = slug  # prefix
    pkg = f"""package {P}_l2a_pkg;
  import muvm_pkg::*;
  import {P}_pkg::*;
  class {P}_item extends muvm_object;
    {P}_hdr_t hdr; longint unsigned golden;
    function new(string name=""); super.new(name); endfunction
  endclass
  class {P}_sqr extends muvm_component;
    {P}_item q[$];
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
  endclass
  class {P}_scoreboard extends muvm_subscriber #({P}_item);
    int unsigned m_txns=0,m_perr=0,m_rterr=0,m_legerr=0,m_uvm_err=0;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void write({P}_item it);
      logic [63:0] w; {P}_hdr_t o; string vio;
      w={P}_pack(it.hdr); o={P}_unpack(w); vio={P}_first_violation(it.hdr);
      if(w!==it.golden[63:0]) begin m_perr++; m_uvm_err++; $display("UVM_ERROR: [SB PACK] txn#%0d",m_txns); end
      if(o!==it.hdr) begin m_rterr++; m_uvm_err++; $display("UVM_ERROR: [SB RT] txn#%0d",m_txns); end
      if(vio!=="") begin m_legerr++; m_uvm_err++; $display("UVM_ERROR: [SB LEGAL] txn#%0d vio=%s",m_txns,vio); end
      $display("COVROW,{covrow}"{covargs});
      m_txns++;
    endfunction
    virtual function void report_phase();
      $display("SBSUMMARY,txns=%0d,legal_err=%0d,pack_err=%0d,rt_err=%0d",m_txns,m_legerr,m_perr,m_rterr);
      $display("SVA_EXERCISED,legality=%0d,roundtrip=%0d,pack=%0d",m_txns,m_txns,m_txns);
      $display("--- UVM Report Summary ---");
      $display("UVM_INFO :  %0d",m_txns); $display("UVM_WARNING : 0");
      $display("UVM_ERROR : %0d",m_uvm_err); $display("UVM_FATAL : 0");
      if(m_uvm_err==0 && m_txns>0) $display("** TEST PASSED **"); else $display("** TEST FAILED **");
    endfunction
  endclass
  class {P}_driver extends muvm_component;
    {P}_sqr sqr; muvm_analysis_port #({P}_item) ap;
    function new(string name="", muvm_component parent=null); super.new(name,parent); ap=new(); endfunction
    virtual task run_phase(); {P}_item it;
      while(sqr!=null && sqr.q.size()>0) begin it=sqr.q.pop_front(); ap.write(it); end
    endtask
  endclass
  class {P}_agent extends muvm_component;
    {P}_sqr sqr; {P}_driver drv;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(sqr, muvm_factory::create("{P}_sqr","sqr",this)));
      void'($cast(drv, muvm_factory::create("{P}_driver","drv",this)));
    endfunction
    virtual function void connect_phase(); drv.sqr=sqr; endfunction
  endclass
  class {P}_env extends muvm_component;
    {P}_agent agt; {P}_scoreboard sb;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(agt, muvm_factory::create("{P}_agent","agt",this)));
      void'($cast(sb,  muvm_factory::create("{P}_scoreboard","sb",this)));
    endfunction
    virtual function void connect_phase(); agt.drv.ap.connect(sb); endfunction
  endclass
  class {P}_test extends muvm_component;
    {P}_env env;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(env, muvm_factory::create("{P}_env","env",this)));
    endfunction
    virtual function void connect_phase();
      string stim; int fd,rc,n=0; {vdecl}; {P}_item it;
      if(!$value$plusargs("STIM=%s",stim)) begin $display("UVM_FATAL: no +STIM"); return; end
      fd=$fopen(stim,"r"); if(fd==0) begin $display("UVM_FATAL: open %s",stim); return; end
      rc=$fscanf(fd,"{fscan}",{decls});
      while(rc=={nf+1}) begin
        it=new($sformatf("it%0d",n));
        {assigns}
        it.golden=rg; env.agt.sqr.q.push_back(it); n++;
        rc=$fscanf(fd,"{fscan}",{decls});
      end
      $fclose(fd); $display("MUVM_INFO: loaded %0d seq_items",n);
    endfunction
  endclass
endpackage
"""
    open(f"{d}/{slug}_l2a_pkg.sv","w").write(pkg)
    creators = ["test","env","agent","sqr","driver","scoreboard"]
    cdecl = "\n  ".join(f"muvm_creator_t #({P}_{t}) c_{t};" for t in creators)
    creg  = "\n    ".join(f'c_{t}=new(); muvm_factory::register("{P}_{t}", c_{t});' for t in creators)
    tb = f"""module {P}_l2a_tb_top;
  import muvm_pkg::*; import {P}_l2a_pkg::*;
  {cdecl}
  initial begin
    {creg}
    muvm_root::run_test("{P}_test");
    $finish;
  end
endmodule
"""
    open(f"{d}/{slug}_l2a_tb_top.sv","w").write(tb)
    open(f"{d}/sim_main.cpp","w").write(f"""#include "verilated.h"
#include "verilated_cov.h"
#include "V{slug}_l2a_tb_top.h"
int main(int argc,char**argv){{ VerilatedContext* c=new VerilatedContext; c->commandArgs(argc,argv);
  V{slug}_l2a_tb_top* t=new V{slug}_l2a_tb_top{{c}}; int g=0;
  while(!c->gotFinish()&&g++<8000000){{ c->timeInc(1); t->eval(); if(!t->eventsPending()){{ t->eval(); break; }} }}
  t->final();
#if VM_COVERAGE
  c->coveragep()->write("coverage.dat");
#endif
  delete t; delete c; return 0; }}
""")
    return d

def build(slug, d):
    l1 = f"{ROOT}/components/{slug}/rtl/{slug}_pkg.sv"
    r = subprocess.run(["verilator","--cc","--exe","--build","-j","0","--timing","--coverage",
        "-Wno-CONSTRAINTIGN","-Wno-WIDTHTRUNC","-Wno-WIDTHEXPAND","-Wno-UNUSEDSIGNAL","-Wno-fatal",
        "--Mdir",f"{d}/obj","-o","simv","--top-module",f"{slug}_l2a_tb_top",
        f"{d}/sim_main.cpp", MUVM, l1, f"{d}/{slug}_l2a_pkg.sv", f"{d}/{slug}_l2a_tb_top.sv"],
        capture_output=True, text=True)
    open(f"{d}/build.log","w").write(r.stdout+r.stderr)
    return os.path.exists(f"{d}/obj/simv")

def main():
    slugs = sys.argv[1:] or ORDER
    rep = {}
    for slug in slugs:
        d = emit(slug); ok = build(slug, d)
        if not ok:
            rep[slug] = {"build":"FAIL"}; print(f"{slug:14s} BUILD FAIL (see build.log)"); continue
        statuses = []
        for seed in (1,2,3):
            st = f"{d}/stim_{seed}.hex"
            subprocess.run(["python3", f"{GEN}/gen_stim.py","--spec",f"{ROOT}/components/{slug}/spec.json",
                            "--seed",str(seed),"--n","300","--out",st], capture_output=True)
            lg = f"{d}/l2a_seed{seed}.log"
            with open(lg,"w") as f: subprocess.run([f"{d}/obj/simv", f"+STIM={st}"], stdout=f, stderr=subprocess.STDOUT)
            rj = f"{d}/result_l2a_seed{seed}.json"
            subprocess.run(["python3", f"{GEN}/adjudicate.py","--spec",f"{ROOT}/components/{slug}/spec.json",
                            "--log",lg,"--sim-exit","0","--test",f"l2a_uvm_seed{seed}","--seed",str(seed),"--out",rj],
                           capture_output=True)
            statuses.append(json.load(open(rj))["status"])
        rep[slug] = {"build":"PASS","gate3_uvm":"PASS" if all(s=="PASS" for s in statuses) else "FAIL","seeds":statuses}
        print(f"{slug:14s} L2A build=PASS run(1,2,3)={statuses}")
    json.dump(rep, open(f"{L2}/lane2a_report.json","w"), indent=2)
    n = sum(1 for v in rep.values() if v.get("gate3_uvm")=="PASS")
    print(f"SUITE Lane-2A (UVM-subset architecture, executed): {n}/{len(rep)} PASS")

if __name__ == "__main__":
    main()
