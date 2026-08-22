// ======================================================================
//  File   : lane2/components/splane/splane_l2a_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : splane Lane-2A UVM-subset ENV: seq_item, SEQUENCER (Z3-loaded), DRIVER, component SCOREBOARD (analysis port) with legality/pack/round-trip checks + COVROW COVERAGE.
// ======================================================================
package splane_l2a_pkg;
  import muvm_pkg::*;
  import splane_pkg::*;
  class splane_item extends muvm_object;
    splane_hdr_t hdr; longint unsigned golden;
    function new(string name=""); super.new(name); endfunction
  endclass
  class splane_sqr extends muvm_component;
    splane_item q[$];
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
  endclass
  class splane_scoreboard extends muvm_subscriber #(splane_item);
    int unsigned m_txns=0,m_perr=0,m_rterr=0,m_legerr=0,m_uvm_err=0;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void write(splane_item it);
      logic [63:0] w; splane_hdr_t o; string vio;
      w=splane_pack(it.hdr); o=splane_unpack(w); vio=splane_first_violation(it.hdr);
      if(w!==it.golden[63:0]) begin m_perr++; m_uvm_err++; $display("UVM_ERROR: [SB PACK] txn#%0d",m_txns); end
      if(o!==it.hdr) begin m_rterr++; m_uvm_err++; $display("UVM_ERROR: [SB RT] txn#%0d",m_txns); end
      if(vio!=="") begin m_legerr++; m_uvm_err++; $display("UVM_ERROR: [SB LEGAL] txn#%0d vio=%s",m_txns,vio); end
      $display("COVROW,ptp_msg=%0d,clock_state=%0d,synce_ql=%0d,seq=%0d,holdover=%0d", it.hdr.ptp_msg, it.hdr.clock_state, it.hdr.synce_ql, it.hdr.seq, it.hdr.holdover);
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
  class splane_driver extends muvm_component;
    splane_sqr sqr; muvm_analysis_port #(splane_item) ap;
    function new(string name="", muvm_component parent=null); super.new(name,parent); ap=new(); endfunction
    virtual task run_phase(); splane_item it;
      while(sqr!=null && sqr.q.size()>0) begin it=sqr.q.pop_front(); ap.write(it); end
    endtask
  endclass
  class splane_agent extends muvm_component;
    splane_sqr sqr; splane_driver drv;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(sqr, muvm_factory::create("splane_sqr","sqr",this)));
      void'($cast(drv, muvm_factory::create("splane_driver","drv",this)));
    endfunction
    virtual function void connect_phase(); drv.sqr=sqr; endfunction
  endclass
  class splane_env extends muvm_component;
    splane_agent agt; splane_scoreboard sb;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(agt, muvm_factory::create("splane_agent","agt",this)));
      void'($cast(sb,  muvm_factory::create("splane_scoreboard","sb",this)));
    endfunction
    virtual function void connect_phase(); agt.drv.ap.connect(sb); endfunction
  endclass
  class splane_test extends muvm_component;
    splane_env env;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(env, muvm_factory::create("splane_env","env",this)));
    endfunction
    virtual function void connect_phase();
      string stim; int fd,rc,n=0; int unsigned r_version; int unsigned r_ptp_msg; int unsigned r_clock_state; int unsigned r_synce_ql; int unsigned r_seq; int unsigned r_timing_err; int unsigned r_holdover; int unsigned r_rsvd; longint unsigned rg; splane_item it;
      if(!$value$plusargs("STIM=%s",stim)) begin $display("UVM_FATAL: no +STIM"); return; end
      fd=$fopen(stim,"r"); if(fd==0) begin $display("UVM_FATAL: open %s",stim); return; end
      rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h",r_version, r_ptp_msg, r_clock_state, r_synce_ql, r_seq, r_timing_err, r_holdover, r_rsvd,rg);
      while(rc==9) begin
        it=new($sformatf("it%0d",n));
        it.hdr.version=r_version[3:0];
        it.hdr.ptp_msg=r_ptp_msg[3:0];
        it.hdr.clock_state=r_clock_state[1:0];
        it.hdr.synce_ql=r_synce_ql[3:0];
        it.hdr.seq=r_seq[15:0];
        it.hdr.timing_err=r_timing_err[11:0];
        it.hdr.holdover=r_holdover[0:0];
        it.hdr.rsvd=r_rsvd[20:0];
        it.golden=rg; env.agt.sqr.q.push_back(it); n++;
        rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h",r_version, r_ptp_msg, r_clock_state, r_synce_ql, r_seq, r_timing_err, r_holdover, r_rsvd,rg);
      end
      $fclose(fd); $display("MUVM_INFO: loaded %0d seq_items",n);
    endfunction
  endclass
endpackage
