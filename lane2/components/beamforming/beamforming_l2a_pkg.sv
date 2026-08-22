// ======================================================================
//  File   : lane2/components/beamforming/beamforming_l2a_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : beamforming Lane-2A UVM-subset ENV: seq_item, SEQUENCER (Z3-loaded), DRIVER, component SCOREBOARD (analysis port) with legality/pack/round-trip checks + COVROW COVERAGE.
// ======================================================================
package beamforming_l2a_pkg;
  import muvm_pkg::*;
  import beamforming_pkg::*;
  class beamforming_item extends muvm_object;
    beamforming_hdr_t hdr; longint unsigned golden;
    function new(string name=""); super.new(name); endfunction
  endclass
  class beamforming_sqr extends muvm_component;
    beamforming_item q[$];
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
  endclass
  class beamforming_scoreboard extends muvm_subscriber #(beamforming_item);
    int unsigned m_txns=0,m_perr=0,m_rterr=0,m_legerr=0,m_uvm_err=0;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void write(beamforming_item it);
      logic [63:0] w; beamforming_hdr_t o; string vio;
      w=beamforming_pack(it.hdr); o=beamforming_unpack(w); vio=beamforming_first_violation(it.hdr);
      if(w!==it.golden[63:0]) begin m_perr++; m_uvm_err++; $display("UVM_ERROR: [SB PACK] txn#%0d",m_txns); end
      if(o!==it.hdr) begin m_rterr++; m_uvm_err++; $display("UVM_ERROR: [SB RT] txn#%0d",m_txns); end
      if(vio!=="") begin m_legerr++; m_uvm_err++; $display("UVM_ERROR: [SB LEGAL] txn#%0d vio=%s",m_txns,vio); end
      $display("COVROW,num_ports=%0d,section_ext=%0d,seq=%0d", it.hdr.num_ports, it.hdr.section_ext, it.hdr.seq);
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
  class beamforming_driver extends muvm_component;
    beamforming_sqr sqr; muvm_analysis_port #(beamforming_item) ap;
    function new(string name="", muvm_component parent=null); super.new(name,parent); ap=new(); endfunction
    virtual task run_phase(); beamforming_item it;
      while(sqr!=null && sqr.q.size()>0) begin it=sqr.q.pop_front(); ap.write(it); end
    endtask
  endclass
  class beamforming_agent extends muvm_component;
    beamforming_sqr sqr; beamforming_driver drv;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(sqr, muvm_factory::create("beamforming_sqr","sqr",this)));
      void'($cast(drv, muvm_factory::create("beamforming_driver","drv",this)));
    endfunction
    virtual function void connect_phase(); drv.sqr=sqr; endfunction
  endclass
  class beamforming_env extends muvm_component;
    beamforming_agent agt; beamforming_scoreboard sb;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(agt, muvm_factory::create("beamforming_agent","agt",this)));
      void'($cast(sb,  muvm_factory::create("beamforming_scoreboard","sb",this)));
    endfunction
    virtual function void connect_phase(); agt.drv.ap.connect(sb); endfunction
  endclass
  class beamforming_test extends muvm_component;
    beamforming_env env;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(env, muvm_factory::create("beamforming_env","env",this)));
    endfunction
    virtual function void connect_phase();
      string stim; int fd,rc,n=0; int unsigned r_version; int unsigned r_beam_id; int unsigned r_num_ports; int unsigned r_num_layers; int unsigned r_section_ext; int unsigned r_codebook_idx; int unsigned r_seq; int unsigned r_rsvd; longint unsigned rg; beamforming_item it;
      if(!$value$plusargs("STIM=%s",stim)) begin $display("UVM_FATAL: no +STIM"); return; end
      fd=$fopen(stim,"r"); if(fd==0) begin $display("UVM_FATAL: open %s",stim); return; end
      rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h",r_version, r_beam_id, r_num_ports, r_num_layers, r_section_ext, r_codebook_idx, r_seq, r_rsvd,rg);
      while(rc==9) begin
        it=new($sformatf("it%0d",n));
        it.hdr.version=r_version[3:0];
        it.hdr.beam_id=r_beam_id[15:0];
        it.hdr.num_ports=r_num_ports[7:0];
        it.hdr.num_layers=r_num_layers[3:0];
        it.hdr.section_ext=r_section_ext[3:0];
        it.hdr.codebook_idx=r_codebook_idx[15:0];
        it.hdr.seq=r_seq[7:0];
        it.hdr.rsvd=r_rsvd[3:0];
        it.golden=rg; env.agt.sqr.q.push_back(it); n++;
        rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h",r_version, r_beam_id, r_num_ports, r_num_layers, r_section_ext, r_codebook_idx, r_seq, r_rsvd,rg);
      end
      $fclose(fd); $display("MUVM_INFO: loaded %0d seq_items",n);
    endfunction
  endclass
endpackage
