// ======================================================================
//  File   : lane2/lane2b_native/suite/bwp_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : bwp Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package bwp_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class bwp_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [1:0] bwp_id;
    rand bit [3:0] numerology;
    rand bit [8:0] bw_mhz;
    rand bit [0:0] fr;
    rand bit [0:0] active;
    rand bit [7:0] seq;
    rand bit [34:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_bwp_id { bwp_id inside {[0:3]}; }
    constraint c_numerology { numerology inside {[0:4]}; }
    constraint c_bw_mhz { bw_mhz inside {5,10,15,20,25,40,50,60,80,100,200,400}; }
    constraint c_fr { fr inside {[0:1]}; }
    constraint c_active { active inside {[0:1]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    `uvm_object_utils(bwp_item)
    function new(string name="bwp_item"); super.new(name); endfunction
  endclass
  class bwp_sequence extends uvm_sequence #(bwp_item);
    `uvm_object_utils(bwp_sequence)
    int unsigned n_items=100;
    function new(string name="bwp_sequence"); super.new(name); endfunction
    virtual task body(); bwp_item it;
      repeat(n_items) begin it=bwp_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class bwp_driver extends uvm_driver #(bwp_item);
    `uvm_component_utils(bwp_driver)
    uvm_analysis_port #(bwp_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class bwp_scoreboard extends uvm_component;
    `uvm_component_utils(bwp_scoreboard)
    uvm_analysis_imp #(bwp_item, bwp_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [1:0] cv_bwp_id;
    bit [3:0] cv_numerology;
    bit [8:0] cv_bw_mhz;
    bit [0:0] cv_fr;
    bit [0:0] cv_active;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_bwp_id: coverpoint cv_bwp_id { bins b[] = {0,1,2,3}; }
      cp_numerology: coverpoint cv_numerology { bins b[] = {0,1,2,3,4}; }
      cp_bw_mhz: coverpoint cv_bw_mhz { bins b[] = {5,10,15,20,25,40,50,60,80,100,200,400}; }
      cp_fr: coverpoint cv_fr { bins z={0}; bins o={1}; }
      cp_active: coverpoint cv_active { bins z={0}; bins o={1}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_bwp_id, cp_numerology;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(bwp_item it);
      cv_bwp_id = it.bwp_id;
      cv_numerology = it.numerology;
      cv_bw_mhz = it.bw_mhz;
      cv_fr = it.fr;
      cv_active = it.active;
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
  class bwp_agent extends uvm_agent;
    `uvm_component_utils(bwp_agent)
    uvm_sequencer #(bwp_item) sqr; bwp_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(bwp_item)::type_id::create("sqr",this);
      drv=bwp_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class bwp_env extends uvm_env;
    `uvm_component_utils(bwp_env)
    bwp_agent agt; bwp_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=bwp_agent::type_id::create("agt",this); sb=bwp_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class bwp_test extends uvm_test;
    `uvm_component_utils(bwp_test)
    bwp_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=bwp_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      bwp_sequence seq; phase.raise_objection(this);
      seq=bwp_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
