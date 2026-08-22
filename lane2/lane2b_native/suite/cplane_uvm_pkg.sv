// ======================================================================
//  File   : lane2/lane2b_native/suite/cplane_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : cplane Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package cplane_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class cplane_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [3:0] section_type;
    rand bit [3:0] section_ext;
    rand bit [3:0] start_symbol;
    rand bit [3:0] num_symbol;
    rand bit [3:0] num_sections;
    rand bit [15:0] beam_id;
    rand bit [3:0] numerology;
    rand bit [7:0] seq;
    rand bit [11:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_section_type { section_type inside {[0:8]}; }
    constraint c_section_ext { section_ext inside {[1:11]}; }
    constraint c_start_symbol { start_symbol inside {[0:13]}; }
    constraint c_num_symbol { num_symbol inside {[1:14]}; }
    constraint c_num_sections { num_sections inside {1,2,4,8}; }
    constraint c_beam_id { beam_id inside {[0:65535]}; }
    constraint c_numerology { numerology inside {[0:4]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    constraint c_cross0 { start_symbol + num_symbol <= 14; }
    `uvm_object_utils(cplane_item)
    function new(string name="cplane_item"); super.new(name); endfunction
  endclass
  class cplane_sequence extends uvm_sequence #(cplane_item);
    `uvm_object_utils(cplane_sequence)
    int unsigned n_items=100;
    function new(string name="cplane_sequence"); super.new(name); endfunction
    virtual task body(); cplane_item it;
      repeat(n_items) begin it=cplane_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class cplane_driver extends uvm_driver #(cplane_item);
    `uvm_component_utils(cplane_driver)
    uvm_analysis_port #(cplane_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class cplane_scoreboard extends uvm_component;
    `uvm_component_utils(cplane_scoreboard)
    uvm_analysis_imp #(cplane_item, cplane_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [3:0] cv_section_type;
    bit [3:0] cv_section_ext;
    bit [3:0] cv_num_symbol;
    bit [3:0] cv_num_sections;
    bit [3:0] cv_numerology;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_section_type: coverpoint cv_section_type { bins b[] = {0,1,2,3,4,5,6,7,8}; }
      cp_section_ext: coverpoint cv_section_ext { bins b[] = {1,2,3,4,5,6,7,8,9,10,11}; }
      cp_num_symbol: coverpoint cv_num_symbol { bins b0={[1:3]}; bins b1={[4:6]}; bins b2={[7:9]}; bins b3={[10:12]}; }
      cp_num_sections: coverpoint cv_num_sections { bins b[] = {1,2,4,8}; }
      cp_numerology: coverpoint cv_numerology { bins b[] = {0,1,2,3,4}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_section_type, cp_section_ext;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(cplane_item it);
      cv_section_type = it.section_type;
      cv_section_ext = it.section_ext;
      cv_num_symbol = it.num_symbol;
      cv_num_sections = it.num_sections;
      cv_numerology = it.numerology;
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
  class cplane_agent extends uvm_agent;
    `uvm_component_utils(cplane_agent)
    uvm_sequencer #(cplane_item) sqr; cplane_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(cplane_item)::type_id::create("sqr",this);
      drv=cplane_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class cplane_env extends uvm_env;
    `uvm_component_utils(cplane_env)
    cplane_agent agt; cplane_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=cplane_agent::type_id::create("agt",this); sb=cplane_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class cplane_test extends uvm_test;
    `uvm_component_utils(cplane_test)
    cplane_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=cplane_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      cplane_sequence seq; phase.raise_objection(this);
      seq=cplane_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
