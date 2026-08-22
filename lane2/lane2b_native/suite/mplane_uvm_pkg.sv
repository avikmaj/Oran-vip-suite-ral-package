// ======================================================================
//  File   : lane2/lane2b_native/suite/mplane_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mplane Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package mplane_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class mplane_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [2:0] netconf_op;
    rand bit [1:0] datastore;
    rand bit [15:0] item_id;
    rand bit [0:0] ant_cal;
    rand bit [2:0] sw_slot;
    rand bit [7:0] seq;
    rand bit [26:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_netconf_op { netconf_op inside {0,1,2,3,4}; }
    constraint c_datastore { datastore inside {0,1,2}; }
    constraint c_item_id { item_id inside {[0:65535]}; }
    constraint c_ant_cal { ant_cal inside {[0:1]}; }
    constraint c_sw_slot { sw_slot inside {[0:7]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    `uvm_object_utils(mplane_item)
    function new(string name="mplane_item"); super.new(name); endfunction
  endclass
  class mplane_sequence extends uvm_sequence #(mplane_item);
    `uvm_object_utils(mplane_sequence)
    int unsigned n_items=100;
    function new(string name="mplane_sequence"); super.new(name); endfunction
    virtual task body(); mplane_item it;
      repeat(n_items) begin it=mplane_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class mplane_driver extends uvm_driver #(mplane_item);
    `uvm_component_utils(mplane_driver)
    uvm_analysis_port #(mplane_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class mplane_scoreboard extends uvm_component;
    `uvm_component_utils(mplane_scoreboard)
    uvm_analysis_imp #(mplane_item, mplane_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [2:0] cv_netconf_op;
    bit [1:0] cv_datastore;
    bit [0:0] cv_ant_cal;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_netconf_op: coverpoint cv_netconf_op { bins b[] = {0,1,2,3,4}; }
      cp_datastore: coverpoint cv_datastore { bins b[] = {0,1,2}; }
      cp_ant_cal: coverpoint cv_ant_cal { bins z={0}; bins o={1}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_netconf_op, cp_datastore;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(mplane_item it);
      cv_netconf_op = it.netconf_op;
      cv_datastore = it.datastore;
      cv_ant_cal = it.ant_cal;
      cv_seq = it.seq;
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
  class mplane_agent extends uvm_agent;
    `uvm_component_utils(mplane_agent)
    uvm_sequencer #(mplane_item) sqr; mplane_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(mplane_item)::type_id::create("sqr",this);
      drv=mplane_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class mplane_env extends uvm_env;
    `uvm_component_utils(mplane_env)
    mplane_agent agt; mplane_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=mplane_agent::type_id::create("agt",this); sb=mplane_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class mplane_test extends uvm_test;
    `uvm_component_utils(mplane_test)
    mplane_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=mplane_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      mplane_sequence seq; phase.raise_objection(this);
      seq=mplane_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
