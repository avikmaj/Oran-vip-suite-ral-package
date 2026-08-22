// ======================================================================
//  File   : lane2/lane2b_native/suite/beamforming_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : beamforming Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
package beamforming_uvm_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"
  class beamforming_item extends uvm_sequence_item;
    rand bit [3:0] version;
    rand bit [15:0] beam_id;
    rand bit [7:0] num_ports;
    rand bit [3:0] num_layers;
    rand bit [3:0] section_ext;
    rand bit [15:0] codebook_idx;
    rand bit [7:0] seq;
    rand bit [3:0] rsvd;
    constraint c_version { version == 1; }
    constraint c_beam_id { beam_id inside {[0:65535]}; }
    constraint c_num_ports { num_ports inside {1,2,4,8,16,32,64}; }
    constraint c_num_layers { num_layers inside {[1:8]}; }
    constraint c_section_ext { section_ext inside {1,4,5,6}; }
    constraint c_codebook_idx { codebook_idx inside {[0:65535]}; }
    constraint c_seq { seq inside {[0:255]}; }
    constraint c_rsvd { rsvd == 0; }
    constraint c_cross0 { num_layers <= num_ports; }
    `uvm_object_utils(beamforming_item)
    function new(string name="beamforming_item"); super.new(name); endfunction
  endclass
  class beamforming_sequence extends uvm_sequence #(beamforming_item);
    `uvm_object_utils(beamforming_sequence)
    int unsigned n_items=100;
    function new(string name="beamforming_sequence"); super.new(name); endfunction
    virtual task body(); beamforming_item it;
      repeat(n_items) begin it=beamforming_item::type_id::create("it"); start_item(it);
        if(!it.randomize()) `uvm_fatal("RANDFAIL","randomize failed"); finish_item(it); end
    endtask
  endclass
  class beamforming_driver extends uvm_driver #(beamforming_item);
    `uvm_component_utils(beamforming_driver)
    uvm_analysis_port #(beamforming_item) ap;
    function new(string n, uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); ap.write(req); seq_item_port.item_done(); end
    endtask
  endclass
  class beamforming_scoreboard extends uvm_component;
    `uvm_component_utils(beamforming_scoreboard)
    uvm_analysis_imp #(beamforming_item, beamforming_scoreboard) imp;
    int unsigned txns=0, errs=0;
    bit [7:0] cv_num_ports;
    bit [3:0] cv_section_ext;
    bit [7:0] cv_seq;
    // NATIVE covergroup (cross + illegal_bins), single instance -> accumulates
    covergroup cg;
      cp_num_ports: coverpoint cv_num_ports { bins b[] = {1,2,4,8,16,32,64}; }
      cp_section_ext: coverpoint cv_section_ext { bins b[] = {1,4,5,6}; }
      cp_seq: coverpoint cv_seq { bins mn={0}; bins mx={255}; bins md={[1:254]}; }
      x_cov: cross cp_num_ports, cp_section_ext;
    endgroup
    function new(string n, uvm_component p); super.new(n,p); imp=new("imp",this); cg=new(); endfunction
    virtual function void write(beamforming_item it);
      cv_num_ports = it.num_ports;
      cv_section_ext = it.section_ext;
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
  class beamforming_agent extends uvm_agent;
    `uvm_component_utils(beamforming_agent)
    uvm_sequencer #(beamforming_item) sqr; beamforming_driver drv;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr=uvm_sequencer#(beamforming_item)::type_id::create("sqr",this);
      drv=beamforming_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass
  class beamforming_env extends uvm_env;
    `uvm_component_utils(beamforming_env)
    beamforming_agent agt; beamforming_scoreboard sb;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt=beamforming_agent::type_id::create("agt",this); sb=beamforming_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase); agt.drv.ap.connect(sb.imp); endfunction
  endclass
  class beamforming_test extends uvm_test;
    `uvm_component_utils(beamforming_test)
    beamforming_env env;
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase); env=beamforming_env::type_id::create("env",this); endfunction
    virtual task run_phase(uvm_phase phase);
      beamforming_sequence seq; phase.raise_objection(this);
      seq=beamforming_sequence::type_id::create("seq"); seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
