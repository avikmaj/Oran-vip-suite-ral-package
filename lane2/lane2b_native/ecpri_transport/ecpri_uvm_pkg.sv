// ======================================================================
//  File   : lane2/lane2b_native/ecpri_transport/ecpri_uvm_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : ecpri Lane-2B NATIVE UVM: SEQ_ITEM (rand + native constraints), SEQUENCE, DRIVER, component SCOREBOARD, AGENT/ENV/TEST; native COVERGROUP (cross + illegal_bins).
// ======================================================================
//======================================================================
// ecpri_uvm_pkg.sv — Lane-2B NATIVE UVM reference (ecpri_transport).
// Requires a UVM-capable simulator (DSim / VCS / Questa / Xcelium). Uses
// native randomize() with {} constraint solving + native covergroup with
// cross + illegal_bins. Does NOT run on Verilator 5.020 (measured).
// STATUS: NOT_VERIFIED — advances to PASS only on returned venue result.json.
// The other 12 components follow this exact pattern (generator-emittable).
//======================================================================
package ecpri_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class ecpri_seq_item extends uvm_sequence_item;
    rand bit [3:0]  version;
    rand bit        concat;
    rand bit [7:0]  msg_type;
    rand bit [15:0] payload_size;
    rand bit [15:0] pc_id;
    rand bit [7:0]  seq_id;
    rand bit        e_bit;
    rand bit [6:0]  sub_seq;

    // NATIVE constraints (Verilator ignores these; a real solver honors them)
    constraint c_version { version == 4'h1; }
    constraint c_msgtype { msg_type inside {[0:7]}; }
    constraint c_payload { payload_size inside {[8:1024]}; }

    `uvm_object_utils_begin(ecpri_seq_item)
      `uvm_field_int(version, UVM_ALL_ON) `uvm_field_int(concat, UVM_ALL_ON)
      `uvm_field_int(msg_type, UVM_ALL_ON) `uvm_field_int(payload_size, UVM_ALL_ON)
      `uvm_field_int(pc_id, UVM_ALL_ON) `uvm_field_int(seq_id, UVM_ALL_ON)
      `uvm_field_int(e_bit, UVM_ALL_ON) `uvm_field_int(sub_seq, UVM_ALL_ON)
    `uvm_object_utils_end

    // NATIVE covergroup with cross + illegal_bins
    covergroup cg;
      cp_msg:    coverpoint msg_type { bins t[] = {[0:7]}; illegal_bins bad = {[8:255]}; }
      cp_concat: coverpoint concat;
      cp_psz:    coverpoint payload_size { bins lo={[8:16]}; bins mid={[17:512]}; bins hi={[513:1024]}; }
      cp_seq:    coverpoint seq_id { bins zero={0}; bins max={255}; bins mid={[1:254]}; }
      x_msg_concat: cross cp_msg, cp_concat;
    endgroup

    function new(string name="ecpri_seq_item"); super.new(name); cg=new(); endfunction
    function void sample_cov(); cg.sample(); endfunction
  endclass

  class ecpri_sequence extends uvm_sequence #(ecpri_seq_item);
    `uvm_object_utils(ecpri_sequence)
    int unsigned n_items = 100; // bounded (native item CRV below)
    function new(string name="ecpri_sequence"); super.new(name); endfunction
    virtual task body();
      ecpri_seq_item it;
      repeat (n_items) begin
        it = ecpri_seq_item::type_id::create("it");
        start_item(it);
        if (!it.randomize()) `uvm_fatal("RANDFAIL","randomize() failed")  // uvm_fatal on fail
        finish_item(it);
      end
    endtask
  endclass

  class ecpri_driver extends uvm_driver #(ecpri_seq_item);
    `uvm_component_utils(ecpri_driver)
    uvm_analysis_port #(ecpri_seq_item) ap;
    function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin
        seq_item_port.get_next_item(req);
        // drive to DUT/interface here; publish for scoreboard
        ap.write(req);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class ecpri_scoreboard extends uvm_component;
    `uvm_component_utils(ecpri_scoreboard)
    uvm_analysis_imp #(ecpri_seq_item, ecpri_scoreboard) imp;
    int unsigned txns, errs;
    function new(string name, uvm_component parent); super.new(name,parent); imp=new("imp",this); endfunction
    virtual function void write(ecpri_seq_item it);
      it.sample_cov();
      if (it.version !== 4'h1)        begin errs++; `uvm_error("SB","version != 0x1") end
      if (it.msg_type > 8'd7)         begin errs++; `uvm_error("SB","msg_type > 7") end
      if (!(it.payload_size inside {[8:1024]})) begin errs++; `uvm_error("SB","payload out of range") end
      txns++;
    endfunction
    virtual function void report_phase(uvm_phase phase);
      `uvm_info("SB", $sformatf("txns=%0d errs=%0d", txns, errs), UVM_LOW)
    endfunction
  endclass

  class ecpri_agent extends uvm_agent;
    `uvm_component_utils(ecpri_agent)
    uvm_sequencer #(ecpri_seq_item) sqr; ecpri_driver drv;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase);
      sqr = uvm_sequencer#(ecpri_seq_item)::type_id::create("sqr",this);
      drv = ecpri_driver::type_id::create("drv",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass

  class ecpri_env extends uvm_env;
    `uvm_component_utils(ecpri_env)
    ecpri_agent agt; ecpri_scoreboard sb;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase);
      agt = ecpri_agent::type_id::create("agt",this);
      sb  = ecpri_scoreboard::type_id::create("sb",this);
    endfunction
    virtual function void connect_phase(uvm_phase phase);
      agt.drv.ap.connect(sb.imp);
    endfunction
  endclass

  class ecpri_test extends uvm_test;
    `uvm_component_utils(ecpri_test)
    ecpri_env env;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase);
      env = ecpri_env::type_id::create("env",this);
    endfunction
    virtual task run_phase(uvm_phase phase);
      ecpri_sequence seq;
      phase.raise_objection(this);
      seq = ecpri_sequence::type_id::create("seq");
      void'(seq.randomize());
      seq.start(env.agt.sqr);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
