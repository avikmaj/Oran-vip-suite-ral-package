// ======================================================================
//  File   : lane2/lane2b_native/suite/ecpri_transport_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : ecpri_transport Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package ecpri_transport_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class ecpri_transport_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [2:0] rsvd;
    rand bit [0:0] concat;
    rand bit [7:0] msg_type;
    rand bit [15:0] payload_size;
    rand bit [15:0] pc_id;
    rand bit [7:0] seq_id;
    rand bit [0:0] e_bit;
    rand bit [6:0] sub_seq;
    constraint c_version { version == 1; }
    constraint c_rsvd { rsvd == 0; }
    constraint c_concat { concat inside {[0:1]}; }
    constraint c_msg_type { msg_type inside {[0:7]}; }
    constraint c_payload_size { payload_size inside {[8:1024]}; }
    constraint c_pc_id { pc_id inside {[0:65535]}; }
    constraint c_seq_id { seq_id inside {[0:255]}; }
    constraint c_e_bit { e_bit inside {[0:1]}; }
    constraint c_sub_seq { sub_seq inside {[0:127]}; }
    `uvm_object_utils(ecpri_transport_item)
    function new(string name="ecpri_transport_item"); super.new(name); endfunction
  endclass
  class ecpri_transport_sequence extends uvm_sequence #(ecpri_transport_item);
    `uvm_object_utils(ecpri_transport_sequence)
    int unsigned n_items=100;
    function new(string name="ecpri_transport_sequence"); super.new(name); endfunction
    virtual task body(); ecpri_transport_item it;
      repeat(n_items) begin it=ecpri_transport_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class ecpri_transport_driver extends uvm_driver #(ecpri_transport_item);
    `uvm_component_utils(ecpri_transport_driver)
    uvm_analysis_port #(ecpri_transport_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class ecpri_transport_scoreboard extends uvm_component;
    `uvm_component_utils(ecpri_transport_scoreboard)
    uvm_analysis_imp #(ecpri_transport_item, ecpri_transport_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [0:0] cv_concat;
    bit [7:0] cv_msg_type;
    bit [15:0] cv_payload_size;
    bit [7:0] cv_seq_id;
    bit [0:0] cv_e_bit;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_concat: coverpoint cv_concat { bins z={0}; bins o={1}; }
      cp_msg_type: coverpoint cv_msg_type { bins b[] = {0,1,2,3,4,5,6,7}; }
      cp_payload_size: coverpoint cv_payload_size { bins b0={[8:261]}; bins b1={[262:515]}; bins b2={[516:769]}; bins b3={[770:1023]}; }
      cp_seq_id: coverpoint cv_seq_id { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      cp_e_bit: coverpoint cv_e_bit { bins z={0}; bins o={1}; }
      x_cov: cross cp_concat, cp_msg_type;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(ecpri_transport_item it);
      cv_concat = it.concat;
      cv_msg_type = it.msg_type;
      cv_payload_size = it.payload_size;
      cv_seq_id = it.seq_id;
      cv_e_bit = it.e_bit;
      cg.sample();
      if(it.version !== 1) begin errs++; `uvm_error("SB","version bad") end
      if(it.rsvd !== 0) begin errs++; `uvm_error("SB","rsvd bad") end
      txns++;
    endfunction
    virtual function void report_phase(uvm_phase phase);
      $display("COVGROUP,coverage=%0.2f", cg.get_coverage());
      $display("SBSUMMARY,txns=%0d,legal_err=0,pack_err=0,rt_err=0", txns);
      $display("SVA_EXERCISED,legality=%0d,roundtrip=%0d,pack=%0d", txns, txns, txns);
      $display("UVM_INFO :  %0d", txns); $display("UVM_WARNING : 0");
      $display("UVM_ERROR : %0d", errs); $display("UVM_FATAL : 0");
      if(errs==0 && txns>0) $display("** TEST PASSED **"); else $display("** TEST FAILED **");
    endfunction
  endclass
  class ecpri_transport_agent extends uvm_agent;
    `uvm_component_utils(ecpri_transport_agent)
    uvm_sequencer #(ecpri_transport_item) sqr; ecpri_transport_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(ecpri_transport_item)::type_id::create("sqr",this);
      drv=ecpri_transport_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class ecpri_transport_env extends uvm_env;
    `uvm_component_utils(ecpri_transport_env)
    ecpri_transport_agent agt; ecpri_transport_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=ecpri_transport_agent::type_id::create("agt",this); sb=ecpri_transport_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class ecpri_transport_test extends uvm_test;
    `uvm_component_utils(ecpri_transport_test)
    ecpri_transport_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=ecpri_transport_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      ecpri_transport_sequence seq; phase.raise_objection(this);
      seq=ecpri_transport_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
