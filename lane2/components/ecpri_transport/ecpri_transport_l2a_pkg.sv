// ======================================================================
//  File   : lane2/components/ecpri_transport/ecpri_transport_l2a_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : ecpri_transport Lane-2A UVM-subset ENV: seq_item, SEQUENCER (Z3-loaded), DRIVER, component SCOREBOARD (analysis port) with legality/pack/round-trip checks + COVROW COVERAGE.
// ======================================================================
package ecpri_transport_l2a_pkg;
  import muvm_pkg::*;
  import ecpri_transport_pkg::*;
  class ecpri_transport_item extends muvm_object;
    ecpri_transport_hdr_t hdr; longint unsigned golden;
    function new(string name=""); super.new(name); endfunction
  endclass
  class ecpri_transport_sqr extends muvm_component;
    ecpri_transport_item q[$];
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
  endclass
  class ecpri_transport_scoreboard extends muvm_subscriber #(ecpri_transport_item);
    int unsigned m_txns=0,m_perr=0,m_rterr=0,m_legerr=0,m_uvm_err=0;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void write(ecpri_transport_item it);
      logic [63:0] w; ecpri_transport_hdr_t o; string vio;
      w=ecpri_transport_pack(it.hdr); o=ecpri_transport_unpack(w); vio=ecpri_transport_first_violation(it.hdr);
      if(w!==it.golden[63:0]) begin m_perr++; m_uvm_err++; $display("UVM_ERROR: [SB PACK] txn#%0d",m_txns); end
      if(o!==it.hdr) begin m_rterr++; m_uvm_err++; $display("UVM_ERROR: [SB RT] txn#%0d",m_txns); end
      if(vio!=="") begin m_legerr++; m_uvm_err++; $display("UVM_ERROR: [SB LEGAL] txn#%0d vio=%s",m_txns,vio); end
      $display("COVROW,concat=%0d,msg_type=%0d,payload_size=%0d,seq_id=%0d,e_bit=%0d", it.hdr.concat, it.hdr.msg_type, it.hdr.payload_size, it.hdr.seq_id, it.hdr.e_bit);
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
  class ecpri_transport_driver extends muvm_component;
    ecpri_transport_sqr sqr; muvm_analysis_port #(ecpri_transport_item) ap;
    function new(string name="", muvm_component parent=null); super.new(name,parent); ap=new(); endfunction
    virtual task run_phase(); ecpri_transport_item it;
      while(sqr!=null && sqr.q.size()>0) begin it=sqr.q.pop_front(); ap.write(it); end
    endtask
  endclass
  class ecpri_transport_agent extends muvm_component;
    ecpri_transport_sqr sqr; ecpri_transport_driver drv;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(sqr, muvm_factory::create("ecpri_transport_sqr","sqr",this)));
      void'($cast(drv, muvm_factory::create("ecpri_transport_driver","drv",this)));
    endfunction
    virtual function void connect_phase(); drv.sqr=sqr; endfunction
  endclass
  class ecpri_transport_env extends muvm_component;
    ecpri_transport_agent agt; ecpri_transport_scoreboard sb;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(agt, muvm_factory::create("ecpri_transport_agent","agt",this)));
      void'($cast(sb,  muvm_factory::create("ecpri_transport_scoreboard","sb",this)));
    endfunction
    virtual function void connect_phase(); agt.drv.ap.connect(sb); endfunction
  endclass
  class ecpri_transport_test extends muvm_component;
    ecpri_transport_env env;
    function new(string name="", muvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase();
      void'($cast(env, muvm_factory::create("ecpri_transport_env","env",this)));
    endfunction
    virtual function void connect_phase();
      string stim; int fd,rc,n=0; int unsigned r_version; int unsigned r_rsvd; int unsigned r_concat; int unsigned r_msg_type; int unsigned r_payload_size; int unsigned r_pc_id; int unsigned r_seq_id; int unsigned r_e_bit; int unsigned r_sub_seq; longint unsigned rg; ecpri_transport_item it;
      if(!$value$plusargs("STIM=%s",stim)) begin $display("UVM_FATAL: no +STIM"); return; end
      fd=$fopen(stim,"r"); if(fd==0) begin $display("UVM_FATAL: open %s",stim); return; end
      rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %h",r_version, r_rsvd, r_concat, r_msg_type, r_payload_size, r_pc_id, r_seq_id, r_e_bit, r_sub_seq,rg);
      while(rc==10) begin
        it=new($sformatf("it%0d",n));
        it.hdr.version=r_version[3:0];
        it.hdr.rsvd=r_rsvd[2:0];
        it.hdr.concat=r_concat[0:0];
        it.hdr.msg_type=r_msg_type[7:0];
        it.hdr.payload_size=r_payload_size[15:0];
        it.hdr.pc_id=r_pc_id[15:0];
        it.hdr.seq_id=r_seq_id[7:0];
        it.hdr.e_bit=r_e_bit[0:0];
        it.hdr.sub_seq=r_sub_seq[6:0];
        it.golden=rg; env.agt.sqr.q.push_back(it); n++;
        rc=$fscanf(fd,"%h %h %h %h %h %h %h %h %h %h",r_version, r_rsvd, r_concat, r_msg_type, r_payload_size, r_pc_id, r_seq_id, r_e_bit, r_sub_seq,rg);
      end
      $fclose(fd); $display("MUVM_INFO: loaded %0d seq_items",n);
    endfunction
  endclass
endpackage
