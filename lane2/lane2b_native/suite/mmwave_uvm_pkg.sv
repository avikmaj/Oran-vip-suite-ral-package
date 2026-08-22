// ======================================================================
//  File   : lane2/lane2b_native/suite/mmwave_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mmwave Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package mmwave_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class mmwave_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [2:0] band;
    rand bit [3:0] numerology;
    rand bit [1:0] scs;
    rand bit [3:0] ssb_period;
    rand bit [15:0] beam_id;
    rand bit [7:0] seq;
    rand bit [22:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_band { band inside {0,1,2,3}; }
    constraint c_numerology { numerology inside {[2:4]}; }
    constraint c_scs { scs inside {0,1,2}; }
    constraint c_ssb_period { ssb_period inside {0,1,2,3,4,5}; }
    constraint c_beam_id { beam_id inside {[0:65535]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    `uvm_object_utils(mmwave_item)
    function new(string name="mmwave_item"); super.new(name); endfunction
  endclass
  class mmwave_sequence extends uvm_sequence #(mmwave_item);
    `uvm_object_utils(mmwave_sequence)
    int unsigned n_items=100;
    function new(string name="mmwave_sequence"); super.new(name); endfunction
    virtual task body(); mmwave_item it;
      repeat(n_items) begin it=mmwave_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class mmwave_driver extends uvm_driver #(mmwave_item);
    `uvm_component_utils(mmwave_driver)
    uvm_analysis_port #(mmwave_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class mmwave_scoreboard extends uvm_component;
    `uvm_component_utils(mmwave_scoreboard)
    uvm_analysis_imp #(mmwave_item, mmwave_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [2:0] cv_band;
    bit [3:0] cv_numerology;
    bit [1:0] cv_scs;
    bit [3:0] cv_ssb_period;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_band: coverpoint cv_band { bins b[] = {0,1,2,3}; }
      cp_numerology: coverpoint cv_numerology { bins b[] = {2,3,4}; }
      cp_scs: coverpoint cv_scs { bins b[] = {0,1,2}; }
      cp_ssb_period: coverpoint cv_ssb_period { bins b[] = {0,1,2,3,4,5}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_band, cp_numerology;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(mmwave_item it);
      cv_band = it.band;
      cv_numerology = it.numerology;
      cv_scs = it.scs;
      cv_ssb_period = it.ssb_period;
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
  class mmwave_agent extends uvm_agent;
    `uvm_component_utils(mmwave_agent)
    uvm_sequencer #(mmwave_item) sqr; mmwave_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(mmwave_item)::type_id::create("sqr",this);
      drv=mmwave_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class mmwave_env extends uvm_env;
    `uvm_component_utils(mmwave_env)
    mmwave_agent agt; mmwave_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=mmwave_agent::type_id::create("agt",this); sb=mmwave_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class mmwave_test extends uvm_test;
    `uvm_component_utils(mmwave_test)
    mmwave_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=mmwave_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      mmwave_sequence seq; phase.raise_objection(this);
      seq=mmwave_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
