// ======================================================================
//  File   : lane2/components/uplane/uplane_l2a_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : uplane Lane-2A UVM-subset ENV: seq_item, SEQUENCER (Z3-loaded), DRIVER, component SCOREBOARD (analysis port) with legality/pack/round-trip checks + COVROW COVERAGE.
// ======================================================================
package uplane_l2a_pkg;
  import muvm_pkg::*;
  import uplane_pkg::*;
  class uplane_item extends muvm_object;
    uplane_hdr_t hdr; longint unsigned golden;
    function new(string name=""); super.new(name); endfunction
  endclass
  class uplane_sqr extends muvm_component;
    uplane_item q[$];
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
  endclass
  class uplane_scoreboard extends muvm_subscriber #(uplane_item);
    int unsigned m_txns=0,m_perr=0,m_rterr=0,m_legerr=0,m_uvm_err=0;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void write(uplane_item it);
      logic [63:0] w; uplane_hdr_t o; string vio;
      w=uplane_pack(it.hdr); o=uplane_unpack(w); vio=uplane_first_violation(it.hdr);
      if(w!==it.golden[63:0]) begin m_perr++; m_uvm_err++; $display("UVM_ERROR: [SB PACK] txn#%0d",m_txns); end
      if(o!==it.hdr) begin m_rterr++; m_uvm_err++; $display("UVM_ERROR: [SB RT] txn#%0d",m_txns); end
      if(vio!=="") begin m_legerr++; m_uvm_err++; $display("UVM_ERROR: [SB LEGAL] txn#%0d vio=%s",m_txns,vio); end
      $display("COVROW,section_type=%0d,numerology=%0d,num_prb=%0d,comp_type=%0d,seq=%0d", it.hdr.section_type, it.hdr.numerology, it.hdr.num_prb, it.hdr.comp_type, it.hdr.seq);
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
  class uplane_driver extends muvm_component;
    uplane_sqr sqr; muvm_analysis_port #(uplane_item) ap;
    function new(string name="", muvm_component parent=null); super.new(name,parent); ap=new(); endfunction
    virtual task run_phase(); uplane_item it;
      while(sqr!=null && sqr.q.size()>0) begin it=sqr.q.pop_front(); ap.write(it); end
    endtask
  endclass
  class uplane_agent extends muvm_component;
    uplane_sqr sqr; uplane_driver drv;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(sqr, muvm_factory::create("uplane_sqr","sqr",this)));
      void'($cast(drv, muvm_factory::create("uplane_driver","drv",this)));
    endfunction
    virtual function void connect_phase(); drv.sqr=sqr; endfunction
  endclass
  class uplane_env extends muvm_component;
    uplane_agent agt; uplane_scoreboard sb;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(agt, muvm_factory::create("uplane_agent","agt",this)));
      void'($cast(sb,  muvm_factory::create("uplane_scoreboard","sb",this)));
    endfunction
    virtual function void connect_phase(); agt.drv.ap.connect(sb); endfunction
  endclass
  class uplane_test extends muvm_component;
    uplane_env env;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(env, muvm_factory::create("uplane_env","env",this)));
    endfunction
    virtual function void connect_phase();
      string stim; int fd,rc,n=0; int unsigned r_version; int unsigned r_section_type; int unsigned r_numerology; int unsigned r_start_prb; int unsigned r_num_prb; int unsigned r_symbol_id; int unsigned r_comp_type; int unsigned r_comp_bits; int unsigned r_seq; int unsigned r_rsvd; longint unsigned rg; uplane_item it;
      if(!$value$plusargs("STIM=%s",stim)) begin $display("UVM_FATAL: no +STIM"); return; end
      fd=$fopen(stim,"r"); if(fd==0) begin $display("UVM_FATAL: open %s",stim); return; end
      rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %h %h",r_version, r_section_type, r_numerology, r_start_prb, r_num_prb, r_symbol_id, r_comp_type, r_comp_bits, r_seq, r_rsvd,rg);
      while(rc==11) begin
        it=new($sformatf("it%0d",n));
        it.hdr.version=r_version[3:0];
        it.hdr.section_type=r_section_type[3:0];
        it.hdr.numerology=r_numerology[3:0];
        it.hdr.start_prb=r_start_prb[8:0];
        it.hdr.num_prb=r_num_prb[8:0];
        it.hdr.symbol_id=r_symbol_id[3:0];
        it.hdr.comp_type=r_comp_type[1:0];
        it.hdr.comp_bits=r_comp_bits[4:0];
        it.hdr.seq=r_seq[7:0];
        it.hdr.rsvd=r_rsvd[14:0];
        it.golden=rg; env.agt.sqr.q.push_back(it); n++;
        rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %h %h",r_version, r_section_type, r_numerology, r_start_prb, r_num_prb, r_symbol_id, r_comp_type, r_comp_bits, r_seq, r_rsvd,rg);
      end
      $fclose(fd); $display("MUVM_INFO: loaded %0d seq_items",n);
    endfunction
  endclass
endpackage
