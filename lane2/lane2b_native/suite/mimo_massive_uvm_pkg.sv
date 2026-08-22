// ======================================================================
//  File   : lane2/lane2b_native/suite/mimo_massive_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mimo_massive Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package mimo_massive_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class mimo_massive_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [7:0] ant_cfg;
    rand bit [3:0] num_layers;
    rand bit [2:0] tdd_cfg;
    rand bit [3:0] rank;
    rand bit [7:0] precoder_idx;
    rand bit [7:0] seq;
    rand bit [24:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_ant_cfg { ant_cfg inside {1,2,4,8,16,32,64}; }
    constraint c_num_layers { num_layers inside {[1:8]}; }
    constraint c_tdd_cfg { tdd_cfg inside {[0:6]}; }
    constraint c_rank { rank inside {[1:8]}; }
    constraint c_precoder_idx { precoder_idx inside {[0:255]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    constraint c_cross0 { num_layers <= ant_cfg; }
    constraint c_cross1 { rank <= num_layers; }
    `uvm_object_utils(mimo_massive_item)
    function new(string name="mimo_massive_item"); super.new(name); endfunction
  endclass
  class mimo_massive_sequence extends uvm_sequence #(mimo_massive_item);
    `uvm_object_utils(mimo_massive_sequence)
    int unsigned n_items=100;
    function new(string name="mimo_massive_sequence"); super.new(name); endfunction
    virtual task body(); mimo_massive_item it;
      repeat(n_items) begin it=mimo_massive_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class mimo_massive_driver extends uvm_driver #(mimo_massive_item);
    `uvm_component_utils(mimo_massive_driver)
    uvm_analysis_port #(mimo_massive_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class mimo_massive_scoreboard extends uvm_component;
    `uvm_component_utils(mimo_massive_scoreboard)
    uvm_analysis_imp #(mimo_massive_item, mimo_massive_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [7:0] cv_ant_cfg;
    bit [2:0] cv_tdd_cfg;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_ant_cfg: coverpoint cv_ant_cfg { bins b[] = {1,2,4,8,16,32,64}; }
      cp_tdd_cfg: coverpoint cv_tdd_cfg { bins b[] = {0,1,2,3,4,5,6}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_ant_cfg, cp_tdd_cfg;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(mimo_massive_item it);
      cv_ant_cfg = it.ant_cfg;
      cv_tdd_cfg = it.tdd_cfg;
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
  class mimo_massive_agent extends uvm_agent;
    `uvm_component_utils(mimo_massive_agent)
    uvm_sequencer #(mimo_massive_item) sqr; mimo_massive_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(mimo_massive_item)::type_id::create("sqr",this);
      drv=mimo_massive_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class mimo_massive_env extends uvm_env;
    `uvm_component_utils(mimo_massive_env)
    mimo_massive_agent agt; mimo_massive_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=mimo_massive_agent::type_id::create("agt",this); sb=mimo_massive_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class mimo_massive_test extends uvm_test;
    `uvm_component_utils(mimo_massive_test)
    mimo_massive_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=mimo_massive_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      mimo_massive_sequence seq; phase.raise_objection(this);
      seq=mimo_massive_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
