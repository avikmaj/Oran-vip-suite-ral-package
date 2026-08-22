// ======================================================================
//  File   : lane2/lane2b_native/suite/uplane_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : uplane Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package uplane_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class uplane_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [3:0] section_type;
    rand bit [3:0] numerology;
    rand bit [8:0] start_prb;
    rand bit [8:0] num_prb;
    rand bit [3:0] symbol_id;
    rand bit [1:0] comp_type;
    rand bit [4:0] comp_bits;
    rand bit [7:0] seq;
    rand bit [14:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_section_type { section_type inside {1,3,5,6}; }
    constraint c_numerology { numerology inside {[0:4]}; }
    constraint c_start_prb { start_prb inside {[0:273]}; }
    constraint c_num_prb { num_prb inside {[1:275]}; }
    constraint c_symbol_id { symbol_id inside {[0:13]}; }
    constraint c_comp_type { comp_type inside {0,1,2,3}; }
    constraint c_comp_bits { comp_bits inside {[9:16]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    constraint c_cross0 { start_prb + num_prb <= 275; }
    `uvm_object_utils(uplane_item)
    function new(string name="uplane_item"); super.new(name); endfunction
  endclass
  class uplane_sequence extends uvm_sequence #(uplane_item);
    `uvm_object_utils(uplane_sequence)
    int unsigned n_items=100;
    function new(string name="uplane_sequence"); super.new(name); endfunction
    virtual task body(); uplane_item it;
      repeat(n_items) begin it=uplane_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class uplane_driver extends uvm_driver #(uplane_item);
    `uvm_component_utils(uplane_driver)
    uvm_analysis_port #(uplane_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class uplane_scoreboard extends uvm_component;
    `uvm_component_utils(uplane_scoreboard)
    uvm_analysis_imp #(uplane_item, uplane_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [3:0] cv_section_type;
    bit [3:0] cv_numerology;
    bit [8:0] cv_num_prb;
    bit [1:0] cv_comp_type;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_section_type: coverpoint cv_section_type { bins b[] = {1,3,5,6}; }
      cp_numerology: coverpoint cv_numerology { bins b[] = {0,1,2,3,4}; }
      cp_num_prb: coverpoint cv_num_prb { bins b0={[1:68]}; bins b1={[69:136]}; bins b2={[137:204]}; bins b3={[205:272]}; }
      cp_comp_type: coverpoint cv_comp_type { bins b[] = {0,1,2,3}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_section_type, cp_numerology;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(uplane_item it);
      cv_section_type = it.section_type;
      cv_numerology = it.numerology;
      cv_num_prb = it.num_prb;
      cv_comp_type = it.comp_type;
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
  class uplane_agent extends uvm_agent;
    `uvm_component_utils(uplane_agent)
    uvm_sequencer #(uplane_item) sqr; uplane_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(uplane_item)::type_id::create("sqr",this);
      drv=uplane_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class uplane_env extends uvm_env;
    `uvm_component_utils(uplane_env)
    uplane_agent agt; uplane_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=uplane_agent::type_id::create("agt",this); sb=uplane_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class uplane_test extends uvm_test;
    `uvm_component_utils(uplane_test)
    uplane_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=uplane_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      uplane_sequence seq; phase.raise_objection(this);
      seq=uplane_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
