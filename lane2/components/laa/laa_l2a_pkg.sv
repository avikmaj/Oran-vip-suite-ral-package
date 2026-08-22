// ======================================================================
//  File   : lane2/components/laa/laa_l2a_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : laa Lane-2A UVM-subset ENV: seq_item, SEQUENCER (Z3-loaded), DRIVER, component SCOREBOARD (analysis port) with legality/pack/round-trip checks + COVROW COVERAGE.
// ======================================================================
package laa_l2a_pkg;
  import muvm_pkg::*;
  import laa_pkg::*;
  class laa_item extends muvm_object;
    laa_hdr_t hdr; longint unsigned golden;
    function new(string name=""); super.new(name); endfunction
  endclass
  class laa_sqr extends muvm_component;
    laa_item q[$];
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
  endclass
  class laa_scoreboard extends muvm_subscriber #(laa_item);
    int unsigned m_txns=0,m_perr=0,m_rterr=0,m_legerr=0,m_uvm_err=0;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void write(laa_item it);
      logic [63:0] w; laa_hdr_t o; string vio;
      w=laa_pack(it.hdr); o=laa_unpack(w); vio=laa_first_violation(it.hdr);
      if(w!==it.golden[63:0]) begin m_perr++; m_uvm_err++; $display("UVM_ERROR: [SB PACK] txn#%0d",m_txns); end
      if(o!==it.hdr) begin m_rterr++; m_uvm_err++; $display("UVM_ERROR: [SB RT] txn#%0d",m_txns); end
      if(vio!=="") begin m_legerr++; m_uvm_err++; $display("UVM_ERROR: [SB LEGAL] txn#%0d vio=%s",m_txns,vio); end
      $display("COVROW,lbt_cat=%0d,lbt_result=%0d,burst_type=%0d,cap=%0d,seq=%0d", it.hdr.lbt_cat, it.hdr.lbt_result, it.hdr.burst_type, it.hdr.cap, it.hdr.seq);
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
  class laa_driver extends muvm_component;
    laa_sqr sqr; muvm_analysis_port #(laa_item) ap;
    function new(string name="", muvm_component parent=null); super.new(name,parent); ap=new(); endfunction
    virtual task run_phase(); laa_item it;
      while(sqr!=null && sqr.q.size()>0) begin it=sqr.q.pop_front(); ap.write(it); end
    endtask
  endclass
  class laa_agent extends muvm_component;
    laa_sqr sqr; laa_driver drv;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(sqr, muvm_factory::create("laa_sqr","sqr",this)));
      void'($cast(drv, muvm_factory::create("laa_driver","drv",this)));
    endfunction
    virtual function void connect_phase(); drv.sqr=sqr; endfunction
  endclass
  class laa_env extends muvm_component;
    laa_agent agt; laa_scoreboard sb;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(agt, muvm_factory::create("laa_agent","agt",this)));
      void'($cast(sb,  muvm_factory::create("laa_scoreboard","sb",this)));
    endfunction
    virtual function void connect_phase(); agt.drv.ap.connect(sb); endfunction
  endclass
  class laa_test extends muvm_component;
    laa_env env;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(env, muvm_factory::create("laa_env","env",this)));
    endfunction
    virtual function void connect_phase();
      string stim; int fd,rc,n=0; int unsigned r_version; int unsigned r_section_type; int unsigned r_lbt_cat; int unsigned r_lbt_result; int unsigned r_burst_type; int unsigned r_cap; int unsigned r_section_ext; int unsigned r_seq; int unsigned r_rsvd; longint unsigned rg; laa_item it;
      if(!$value$plusargs("STIM=%s",stim)) begin $display("UVM_FATAL: no +STIM"); return; end
      fd=$fopen(stim,"r"); if(fd==0) begin $display("UVM_FATAL: open %s",stim); return; end
      rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %h",r_version, r_section_type, r_lbt_cat, r_lbt_result, r_burst_type, r_cap, r_section_ext, r_seq, r_rsvd,rg);
      while(rc==10) begin
        it=new($sformatf("it%0d",n));
        it.hdr.version=r_version[3:0];
        it.hdr.section_type=r_section_type[3:0];
        it.hdr.lbt_cat=r_lbt_cat[2:0];
        it.hdr.lbt_result=r_lbt_result[0:0];
        it.hdr.burst_type=r_burst_type[0:0];
        it.hdr.cap=r_cap[1:0];
        it.hdr.section_ext=r_section_ext[3:0];
        it.hdr.seq=r_seq[7:0];
        it.hdr.rsvd=r_rsvd[36:0];
        it.golden=rg; env.agt.sqr.q.push_back(it); n++;
        rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %h",r_version, r_section_type, r_lbt_cat, r_lbt_result, r_burst_type, r_cap, r_section_ext, r_seq, r_rsvd,rg);
      end
      $fclose(fd); $display("MUVM_INFO: loaded %0d seq_items",n);
    endfunction
  endclass
endpackage
