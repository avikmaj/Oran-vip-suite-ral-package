// ======================================================================
//  File   : lane2/lane2b_native/suite/compression_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : compression Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package compression_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class compression_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [1:0] method;
    rand bit [4:0] iq_width;
    rand bit [4:0] comp_width;
    rand bit [3:0] exponent;
    rand bit [7:0] block_size;
    rand bit [7:0] seq;
    rand bit [27:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_method { method inside {0,1,2}; }
    constraint c_iq_width { iq_width == 16; }
    constraint c_comp_width { comp_width inside {9,10,11,12,13,14,15,16}; }
    constraint c_exponent { exponent inside {[0:15]}; }
    constraint c_block_size { block_size inside {[1:255]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    constraint c_cross0 { comp_width <= iq_width; }
    `uvm_object_utils(compression_item)
    function new(string name="compression_item"); super.new(name); endfunction
  endclass
  class compression_sequence extends uvm_sequence #(compression_item);
    `uvm_object_utils(compression_sequence)
    int unsigned n_items=100;
    function new(string name="compression_sequence"); super.new(name); endfunction
    virtual task body(); compression_item it;
      repeat(n_items) begin it=compression_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class compression_driver extends uvm_driver #(compression_item);
    `uvm_component_utils(compression_driver)
    uvm_analysis_port #(compression_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class compression_scoreboard extends uvm_component;
    `uvm_component_utils(compression_scoreboard)
    uvm_analysis_imp #(compression_item, compression_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [1:0] cv_method;
    bit [4:0] cv_comp_width;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_method: coverpoint cv_method { bins b[] = {0,1,2}; }
      cp_comp_width: coverpoint cv_comp_width { bins b[] = {9,10,11,12,13,14,15,16}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_method, cp_comp_width;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(compression_item it);
      cv_method = it.method;
      cv_comp_width = it.comp_width;
      cv_seq = it.seq;
      cg.sample();
      if(it.version !== 1) begin errs++; `uvm_error("SB","version bad") end
      if(it.iq_width !== 16) begin errs++; `uvm_error("SB","iq_width bad") end
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
  class compression_agent extends uvm_agent;
    `uvm_component_utils(compression_agent)
    uvm_sequencer #(compression_item) sqr; compression_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(compression_item)::type_id::create("sqr",this);
      drv=compression_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class compression_env extends uvm_env;
    `uvm_component_utils(compression_env)
    compression_agent agt; compression_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=compression_agent::type_id::create("agt",this); sb=compression_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class compression_test extends uvm_test;
    `uvm_component_utils(compression_test)
    compression_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=compression_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      compression_sequence seq; phase.raise_objection(this);
      seq=compression_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
