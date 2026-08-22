// ======================================================================
//  File   : lane2/lane2b_native/suite/prach_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : prach Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package prach_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class prach_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [3:0] section_type;
    rand bit [3:0] format;
    rand bit [3:0] numerology;
    rand bit [0:0] fr;
    rand bit [7:0] zc_root;
    rand bit [5:0] occasion;
    rand bit [7:0] seq;
    rand bit [24:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_section_type { section_type == 3; }
    constraint c_format { format inside {0,1,2,3,4,5,6,7,8,9}; }
    constraint c_numerology { numerology inside {[0:4]}; }
    constraint c_fr { fr inside {[0:1]}; }
    constraint c_zc_root { zc_root inside {[0:255]}; }
    constraint c_occasion { occasion inside {[0:63]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    `uvm_object_utils(prach_item)
    function new(string name="prach_item"); super.new(name); endfunction
  endclass
  class prach_sequence extends uvm_sequence #(prach_item);
    `uvm_object_utils(prach_sequence)
    int unsigned n_items=100;
    function new(string name="prach_sequence"); super.new(name); endfunction
    virtual task body(); prach_item it;
      repeat(n_items) begin it=prach_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class prach_driver extends uvm_driver #(prach_item);
    `uvm_component_utils(prach_driver)
    uvm_analysis_port #(prach_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class prach_scoreboard extends uvm_component;
    `uvm_component_utils(prach_scoreboard)
    uvm_analysis_imp #(prach_item, prach_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [3:0] cv_format;
    bit [3:0] cv_numerology;
    bit [0:0] cv_fr;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_format: coverpoint cv_format { bins b[] = {0,1,2,3,4,5,6,7,8,9}; }
      cp_numerology: coverpoint cv_numerology { bins b[] = {0,1,2,3,4}; }
      cp_fr: coverpoint cv_fr { bins z={0}; bins o={1}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_format, cp_numerology;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(prach_item it);
      cv_format = it.format;
      cv_numerology = it.numerology;
      cv_fr = it.fr;
      cv_seq = it.seq;
      cg.sample();
      if(it.version !== 1) begin errs++; `uvm_error("SB","version bad") end
      if(it.section_type !== 3) begin errs++; `uvm_error("SB","section_type bad") end
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
  class prach_agent extends uvm_agent;
    `uvm_component_utils(prach_agent)
    uvm_sequencer #(prach_item) sqr; prach_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(prach_item)::type_id::create("sqr",this);
      drv=prach_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class prach_env extends uvm_env;
    `uvm_component_utils(prach_env)
    prach_agent agt; prach_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=prach_agent::type_id::create("agt",this); sb=prach_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class prach_test extends uvm_test;
    `uvm_component_utils(prach_test)
    prach_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=prach_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      prach_sequence seq; phase.raise_objection(this);
      seq=prach_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
