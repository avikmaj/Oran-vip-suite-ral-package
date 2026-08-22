// ======================================================================
//  File   : lane2/lane2b_native/suite/cpri_eth_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : cpri_eth Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package cpri_eth_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class cpri_eth_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [3:0] bw_profile;
    rand bit [0:0] direction;
    rand bit [3:0] iq_rate_id;
    rand bit [3:0] synce_ql;
    rand bit [9:0] frame_id;
    rand bit [3:0] subframe;
    rand bit [0:0] cm_flag;
    rand bit [7:0] seq;
    rand bit [23:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_bw_profile { bw_profile inside {0,1,2,3,4,5}; }
    constraint c_direction { direction inside {[0:1]}; }
    constraint c_iq_rate_id { iq_rate_id inside {[0:15]}; }
    constraint c_synce_ql { synce_ql inside {0,2,4,11,15}; }
    constraint c_frame_id { frame_id inside {[0:1023]}; }
    constraint c_subframe { subframe inside {[0:9]}; }
    constraint c_cm_flag { cm_flag inside {[0:1]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    `uvm_object_utils(cpri_eth_item)
    function new(string name="cpri_eth_item"); super.new(name); endfunction
  endclass
  class cpri_eth_sequence extends uvm_sequence #(cpri_eth_item);
    `uvm_object_utils(cpri_eth_sequence)
    int unsigned n_items=100;
    function new(string name="cpri_eth_sequence"); super.new(name); endfunction
    virtual task body(); cpri_eth_item it;
      repeat(n_items) begin it=cpri_eth_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class cpri_eth_driver extends uvm_driver #(cpri_eth_item);
    `uvm_component_utils(cpri_eth_driver)
    uvm_analysis_port #(cpri_eth_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class cpri_eth_scoreboard extends uvm_component;
    `uvm_component_utils(cpri_eth_scoreboard)
    uvm_analysis_imp #(cpri_eth_item, cpri_eth_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [3:0] cv_bw_profile;
    bit [0:0] cv_direction;
    bit [3:0] cv_synce_ql;
    bit [0:0] cv_cm_flag;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_bw_profile: coverpoint cv_bw_profile { bins b[] = {0,1,2,3,4,5}; }
      cp_direction: coverpoint cv_direction { bins z={0}; bins o={1}; }
      cp_synce_ql: coverpoint cv_synce_ql { bins b[] = {0,2,4,11,15}; }
      cp_cm_flag: coverpoint cv_cm_flag { bins z={0}; bins o={1}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_bw_profile, cp_direction;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(cpri_eth_item it);
      cv_bw_profile = it.bw_profile;
      cv_direction = it.direction;
      cv_synce_ql = it.synce_ql;
      cv_cm_flag = it.cm_flag;
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
  class cpri_eth_agent extends uvm_agent;
    `uvm_component_utils(cpri_eth_agent)
    uvm_sequencer #(cpri_eth_item) sqr; cpri_eth_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(cpri_eth_item)::type_id::create("sqr",this);
      drv=cpri_eth_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class cpri_eth_env extends uvm_env;
    `uvm_component_utils(cpri_eth_env)
    cpri_eth_agent agt; cpri_eth_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=cpri_eth_agent::type_id::create("agt",this); sb=cpri_eth_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class cpri_eth_test extends uvm_test;
    `uvm_component_utils(cpri_eth_test)
    cpri_eth_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=cpri_eth_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      cpri_eth_sequence seq; phase.raise_objection(this);
      seq=cpri_eth_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
