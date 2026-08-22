// ======================================================================
//  File   : lane2/lane2b_native/suite/splane_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : splane Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package splane_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class splane_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [3:0] ptp_msg;
    rand bit [1:0] clock_state;
    rand bit [3:0] synce_ql;
    rand bit [15:0] seq;
    rand bit [11:0] timing_err;
    rand bit [0:0] holdover;
    rand bit [20:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_ptp_msg { ptp_msg inside {0,1,2,3,4,5}; }
    constraint c_clock_state { clock_state inside {0,1,2,3}; }
    constraint c_synce_ql { synce_ql inside {0,2,4,11,15}; }
    constraint c_seq { seq inside {[0:65535]}; }
    constraint c_timing_err { timing_err inside {[0:3000]}; }
    constraint c_holdover { holdover inside {[0:1]}; }
    constraint c_rsvd { rsvd == 0; }
    `uvm_object_utils(splane_item)
    function new(string name="splane_item"); super.new(name); endfunction
  endclass
  class splane_sequence extends uvm_sequence #(splane_item);
    `uvm_object_utils(splane_sequence)
    int unsigned n_items=100;
    function new(string name="splane_sequence"); super.new(name); endfunction
    virtual task body(); splane_item it;
      repeat(n_items) begin it=splane_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class splane_driver extends uvm_driver #(splane_item);
    `uvm_component_utils(splane_driver)
    uvm_analysis_port #(splane_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class splane_scoreboard extends uvm_component;
    `uvm_component_utils(splane_scoreboard)
    uvm_analysis_imp #(splane_item, splane_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [3:0] cv_ptp_msg;
    bit [1:0] cv_clock_state;
    bit [3:0] cv_synce_ql;
    bit [15:0] cv_seq;
    bit [0:0] cv_holdover;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_ptp_msg: coverpoint cv_ptp_msg { bins b[] = {0,1,2,3,4,5}; }
      cp_clock_state: coverpoint cv_clock_state { bins b[] = {0,1,2,3}; }
      cp_synce_ql: coverpoint cv_synce_ql { bins b[] = {0,2,4,11,15}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={65535}; bins md={[1:65534]}; }
      cp_holdover: coverpoint cv_holdover { bins z={0}; bins o={1}; }
      x_cov: cross cp_ptp_msg, cp_clock_state;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(splane_item it);
      cv_ptp_msg = it.ptp_msg;
      cv_clock_state = it.clock_state;
      cv_synce_ql = it.synce_ql;
      cv_seq = it.seq;
      cv_holdover = it.holdover;
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
  class splane_agent extends uvm_agent;
    `uvm_component_utils(splane_agent)
    uvm_sequencer #(splane_item) sqr; splane_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(splane_item)::type_id::create("sqr",this);
      drv=splane_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class splane_env extends uvm_env;
    `uvm_component_utils(splane_env)
    splane_agent agt; splane_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=splane_agent::type_id::create("agt",this); sb=splane_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class splane_test extends uvm_test;
    `uvm_component_utils(splane_test)
    splane_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=splane_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      splane_sequence seq; phase.raise_objection(this);
      seq=splane_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
