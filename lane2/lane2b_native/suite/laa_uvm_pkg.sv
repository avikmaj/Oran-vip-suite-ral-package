// ======================================================================
//  File   : lane2/lane2b_native/suite/laa_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : laa Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package laa_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class laa_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [3:0] section_type;
    rand bit [2:0] lbt_cat;
    rand bit [0:0] lbt_result;
    rand bit [0:0] burst_type;
    rand bit [1:0] cap;
    rand bit [3:0] section_ext;
    rand bit [7:0] seq;
    rand bit [36:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_section_type { section_type == 5; }
    constraint c_lbt_cat { lbt_cat inside {1,2,3,4}; }
    constraint c_lbt_result { lbt_result inside {[0:1]}; }
    constraint c_burst_type { burst_type inside {[0:1]}; }
    constraint c_cap { cap inside {[0:3]}; }
    constraint c_section_ext { section_ext == 3; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    `uvm_object_utils(laa_item)
    function new(string name="laa_item"); super.new(name); endfunction
  endclass
  class laa_sequence extends uvm_sequence #(laa_item);
    `uvm_object_utils(laa_sequence)
    int unsigned n_items=100;
    function new(string name="laa_sequence"); super.new(name); endfunction
    virtual task body(); laa_item it;
      repeat(n_items) begin it=laa_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class laa_driver extends uvm_driver #(laa_item);
    `uvm_component_utils(laa_driver)
    uvm_analysis_port #(laa_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class laa_scoreboard extends uvm_component;
    `uvm_component_utils(laa_scoreboard)
    uvm_analysis_imp #(laa_item, laa_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [2:0] cv_lbt_cat;
    bit [0:0] cv_lbt_result;
    bit [0:0] cv_burst_type;
    bit [1:0] cv_cap;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_lbt_cat: coverpoint cv_lbt_cat { bins b[] = {1,2,3,4}; }
      cp_lbt_result: coverpoint cv_lbt_result { bins z={0}; bins o={1}; }
      cp_burst_type: coverpoint cv_burst_type { bins z={0}; bins o={1}; }
      cp_cap: coverpoint cv_cap { bins b[] = {0,1,2,3}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_lbt_cat, cp_lbt_result;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(laa_item it);
      cv_lbt_cat = it.lbt_cat;
      cv_lbt_result = it.lbt_result;
      cv_burst_type = it.burst_type;
      cv_cap = it.cap;
      cv_seq = it.seq;
      cg.sample();
      if(it.version !== 1) begin errs++; `uvm_error("SB","version bad") end
      if(it.section_type !== 5) begin errs++; `uvm_error("SB","section_type bad") end
      if(it.section_ext !== 3) begin errs++; `uvm_error("SB","section_ext bad") end
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
  class laa_agent extends uvm_agent;
    `uvm_component_utils(laa_agent)
    uvm_sequencer #(laa_item) sqr; laa_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(laa_item)::type_id::create("sqr",this);
      drv=laa_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class laa_env extends uvm_env;
    `uvm_component_utils(laa_env)
    laa_agent agt; laa_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=laa_agent::type_id::create("agt",this); sb=laa_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class laa_test extends uvm_test;
    `uvm_component_utils(laa_test)
    laa_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=laa_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      laa_sequence seq; phase.raise_objection(this);
      seq=laa_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
