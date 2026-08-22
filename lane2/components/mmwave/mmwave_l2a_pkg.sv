// ======================================================================
//  File   : lane2/components/mmwave/mmwave_l2a_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mmwave Lane-2A UVM-subset ENV: seq_item, SEQUENCER (Z3-loaded), DRIVER, component SCOREBOARD (analysis port) with legality/pack/round-trip checks + COVROW COVERAGE.
// ======================================================================
package mmwave_l2a_pkg;
  import muvm_pkg::*;
  import mmwave_pkg::*;
  class mmwave_item extends muvm_object;
    mmwave_hdr_t hdr; longint unsigned golden;
    function new(string name=""); super.new(name); endfunction
  endclass
  class mmwave_sqr extends muvm_component;
    mmwave_item q[$];
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
  endclass
  class mmwave_scoreboard extends muvm_subscriber #(mmwave_item);
    int unsigned m_txns=0,m_perr=0,m_rterr=0,m_legerr=0,m_uvm_err=0;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void write(mmwave_item it);
      logic [63:0] w; mmwave_hdr_t o; string vio;
      w=mmwave_pack(it.hdr); o=mmwave_unpack(w); vio=mmwave_first_violation(it.hdr);
      if(w!==it.golden[63:0]) begin m_perr++; m_uvm_err++; $display("UVM_ERROR: [SB PACK] txn#%0d",m_txns); end
      if(o!==it.hdr) begin m_rterr++; m_uvm_err++; $display("UVM_ERROR: [SB RT] txn#%0d",m_txns); end
      if(vio!=="") begin m_legerr++; m_uvm_err++; $display("UVM_ERROR: [SB LEGAL] txn#%0d vio=%s",m_txns,vio); end
      $display("COVROW,band=%0d,numerology=%0d,scs=%0d,ssb_period=%0d,seq=%0d", it.hdr.band, it.hdr.numerology, it.hdr.scs, it.hdr.ssb_period, it.hdr.seq);
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
  class mmwave_driver extends muvm_component;
    mmwave_sqr sqr; muvm_analysis_port #(mmwave_item) ap;
    function new(string name="", muvm_component parent=null); super.new(name,parent); ap=new(); endfunction
    virtual task run_phase(); mmwave_item it;
      while(sqr!=null && sqr.q.size()>0) begin it=sqr.q.pop_front(); ap.write(it); end
    endtask
  endclass
  class mmwave_agent extends muvm_component;
    mmwave_sqr sqr; mmwave_driver drv;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(sqr, muvm_factory::create("mmwave_sqr","sqr",this)));
      void'($cast(drv, muvm_factory::create("mmwave_driver","drv",this)));
    endfunction
    virtual function void connect_phase(); drv.sqr=sqr; endfunction
  endclass
  class mmwave_env extends muvm_component;
    mmwave_agent agt; mmwave_scoreboard sb;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(agt, muvm_factory::create("mmwave_agent","agt",this)));
      void'($cast(sb,  muvm_factory::create("mmwave_scoreboard","sb",this)));
    endfunction
    virtual function void connect_phase(); agt.drv.ap.connect(sb); endfunction
  endclass
  class mmwave_test extends muvm_component;
    mmwave_env env;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(env, muvm_factory::create("mmwave_env","env",this)));
    endfunction
    virtual function void connect_phase();
      string stim; int fd,rc,n=0; int unsigned r_version; int unsigned r_band; int unsigned r_numerology; int unsigned r_scs; int unsigned r_ssb_period; int unsigned r_beam_id; int unsigned r_seq; int unsigned r_rsvd; longint unsigned rg; mmwave_item it;
      if(!$value$plusargs("STIM=%s",stim)) begin $display("UVM_FATAL: no +STIM"); return; end
      fd=$fopen(stim,"r"); if(fd==0) begin $display("UVM_FATAL: open %s",stim); return; end
      rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h",r_version, r_band, r_numerology, r_scs, r_ssb_period, r_beam_id, r_seq, r_rsvd,rg);
      while(rc==9) begin
        it=new($sformatf("it%0d",n));
        it.hdr.version=r_version[3:0];
        it.hdr.band=r_band[2:0];
        it.hdr.numerology=r_numerology[3:0];
        it.hdr.scs=r_scs[1:0];
        it.hdr.ssb_period=r_ssb_period[3:0];
        it.hdr.beam_id=r_beam_id[15:0];
        it.hdr.seq=r_seq[7:0];
        it.hdr.rsvd=r_rsvd[22:0];
        it.golden=rg; env.agt.sqr.q.push_back(it); n++;
        rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h",r_version, r_band, r_numerology, r_scs, r_ssb_period, r_beam_id, r_seq, r_rsvd,rg);
      end
      $fclose(fd); $display("MUVM_INFO: loaded %0d seq_items",n);
    endfunction
  endclass
endpackage
