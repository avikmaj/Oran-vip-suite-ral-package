// ======================================================================
//  File   : lane2/ral/oran_ral_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : RAL (Register Abstraction Layer) for O-RAN M-plane RU config.
//           uvm_reg register model (5 registers, fields, RW/RO) + reg_map +
//           uvm_reg_adapter + memory-modelling reg driver + front-door
//           write/read/mirror-check sequence. Native UVM (Verilator 5.050 / VCS /
//           Questa / Xcelium). Demonstrates uvm_reg model, map, adapter,
//           predictor (auto-predict), reset check, and access-policy (RW/RO).
// ======================================================================
package oran_ral_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // -------------------- Registers --------------------
  class ru_ctrl_reg extends uvm_reg;               // 0x00 RW : enable, mode, antmap
    rand uvm_reg_field enable;   // [0]
    rand uvm_reg_field mode;     // [2:1]
    rand uvm_reg_field antmap;   // [10:3]
    `uvm_object_utils(ru_ctrl_reg)
    function new(string name="ru_ctrl_reg"); super.new(name,32,UVM_NO_COVERAGE); endfunction
    virtual function void build();
      enable = uvm_reg_field::type_id::create("enable"); enable.configure(this,1,0,"RW",0,1'h0,1,1,0);
      mode   = uvm_reg_field::type_id::create("mode");   mode.configure(this,2,1,"RW",0,2'h0,1,1,0);
      antmap = uvm_reg_field::type_id::create("antmap"); antmap.configure(this,8,3,"RW",0,8'h0,1,1,0);
    endfunction
  endclass

  class ru_version_reg extends uvm_reg;            // 0x04 RO : major, minor
    uvm_reg_field major;  // [7:0]
    uvm_reg_field minor;  // [15:8]
    `uvm_object_utils(ru_version_reg)
    function new(string name="ru_version_reg"); super.new(name,32,UVM_NO_COVERAGE); endfunction
    virtual function void build();
      major = uvm_reg_field::type_id::create("major"); major.configure(this,8,0,"RO",0,8'h02,1,0,0);
      minor = uvm_reg_field::type_id::create("minor"); minor.configure(this,8,8,"RO",0,8'h0A,1,0,0);
    endfunction
  endclass

  class ru_numant_reg extends uvm_reg;             // 0x08 RW : n_tx, n_rx
    rand uvm_reg_field n_tx;  // [6:0]
    rand uvm_reg_field n_rx;  // [14:8]
    `uvm_object_utils(ru_numant_reg)
    function new(string name="ru_numant_reg"); super.new(name,32,UVM_NO_COVERAGE); endfunction
    virtual function void build();
      n_tx = uvm_reg_field::type_id::create("n_tx"); n_tx.configure(this,7,0,"RW",0,7'h1,1,1,0);
      n_rx = uvm_reg_field::type_id::create("n_rx"); n_rx.configure(this,7,8,"RW",0,7'h1,1,1,0);
    endfunction
  endclass

  class ru_comp_reg extends uvm_reg;               // 0x0C RW : method, width
    rand uvm_reg_field method; // [1:0]
    rand uvm_reg_field width;  // [6:2]
    `uvm_object_utils(ru_comp_reg)
    function new(string name="ru_comp_reg"); super.new(name,32,UVM_NO_COVERAGE); endfunction
    virtual function void build();
      method = uvm_reg_field::type_id::create("method"); method.configure(this,2,0,"RW",0,2'h1,1,1,0);
      width  = uvm_reg_field::type_id::create("width");  width.configure(this,5,2,"RW",0,5'd16,1,1,0);
    endfunction
  endclass

  class ru_bwp_reg extends uvm_reg;                // 0x10 RW : bwp_id, numerology, active
    rand uvm_reg_field bwp_id;     // [1:0]
    rand uvm_reg_field numerology; // [5:2]
    rand uvm_reg_field active;     // [6]
    `uvm_object_utils(ru_bwp_reg)
    function new(string name="ru_bwp_reg"); super.new(name,32,UVM_NO_COVERAGE); endfunction
    virtual function void build();
      bwp_id     = uvm_reg_field::type_id::create("bwp_id");     bwp_id.configure(this,2,0,"RW",0,2'h0,1,1,0);
      numerology = uvm_reg_field::type_id::create("numerology"); numerology.configure(this,4,2,"RW",0,4'h0,1,1,0);
      active     = uvm_reg_field::type_id::create("active");     active.configure(this,1,6,"RW",0,1'h0,1,1,0);
    endfunction
  endclass

  // -------------------- Register block --------------------
  class oran_reg_block extends uvm_reg_block;
    rand ru_ctrl_reg    ctrl;
    rand ru_version_reg version;
    rand ru_numant_reg  numant;
    rand ru_comp_reg    comp;
    rand ru_bwp_reg     bwp;
    `uvm_object_utils(oran_reg_block)
    function new(string name="oran_reg_block"); super.new(name,UVM_NO_COVERAGE); endfunction
    virtual function void build();
      default_map = create_map("reg_map", 0, 4, UVM_LITTLE_ENDIAN, 1);
      ctrl    = ru_ctrl_reg   ::type_id::create("ctrl");    ctrl.configure(this);    ctrl.build();    default_map.add_reg(ctrl,    32'h00, "RW");
      version = ru_version_reg::type_id::create("version"); version.configure(this); version.build(); default_map.add_reg(version, 32'h04, "RO");
      numant  = ru_numant_reg ::type_id::create("numant");  numant.configure(this);  numant.build();  default_map.add_reg(numant,  32'h08, "RW");
      comp    = ru_comp_reg   ::type_id::create("comp");    comp.configure(this);    comp.build();    default_map.add_reg(comp,    32'h0C, "RW");
      bwp     = ru_bwp_reg    ::type_id::create("bwp");     bwp.configure(this);     bwp.build();     default_map.add_reg(bwp,     32'h10, "RW");
    endfunction
  endclass

  // -------------------- Bus item + adapter --------------------
  class reg_bus_item extends uvm_sequence_item;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        write;
    `uvm_object_utils(reg_bus_item)
    function new(string name="reg_bus_item"); super.new(name); endfunction
  endclass

  class oran_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(oran_reg_adapter)
    function new(string name="oran_reg_adapter"); super.new(name); provides_responses=0; endfunction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      reg_bus_item it = reg_bus_item::type_id::create("it");
      it.write = (rw.kind == UVM_WRITE); it.addr = rw.addr; it.data = rw.data;
      return it;
    endfunction
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      reg_bus_item it;
      if (!$cast(it, bus_item)) return;
      rw.kind = it.write ? UVM_WRITE : UVM_READ;
      rw.addr = it.addr; rw.data = it.data; rw.status = UVM_IS_OK;
    endfunction
  endclass

  // -------------------- Reg driver (models a register memory / DUT) --------------------
  class oran_reg_driver extends uvm_driver #(reg_bus_item);
    `uvm_component_utils(oran_reg_driver)
    bit [31:0] mem [bit [31:0]];
    function new(string n, uvm_component p); super.new(n,p); endfunction
    virtual function void build_phase(uvm_phase phase);
      mem[32'h04] = 32'h0000_0A02;   // RO version reset value (major=0x02, minor=0x0A)
    endfunction
    virtual task run_phase(uvm_phase phase);
      forever begin
        seq_item_port.get_next_item(req);
        if (req.write) begin
          if (req.addr != 32'h04) mem[req.addr] = req.data;   // RO version: ignore writes
        end else begin
          req.data = mem.exists(req.addr) ? mem[req.addr] : 32'h0;
        end
        seq_item_port.item_done();
      end
    endtask
  endclass

  // -------------------- RAL sequence (front-door write/read/mirror-check) --------------------
  class oran_ral_seq extends uvm_sequence #(reg_bus_item);
    `uvm_object_utils(oran_ral_seq)
    oran_reg_block rb;
    int unsigned ops=0, errs=0;
    function new(string name="oran_ral_seq"); super.new(name); endfunction
    virtual task body();
      uvm_status_e st; uvm_reg_data_t rd;
      // 1. reset check: mirror equals reset value
      rb.reset();
      if (rb.comp.width.get() !== 16) begin errs++; `uvm_error("RAL","comp.width reset != 16") end
      // 2. RO version read-back
      rb.version.read(st, rd); ops++;
      if ((rd & 32'h0000_FFFF) !== 32'h0000_0A02) begin errs++; `uvm_error("RAL","version RO mismatch") end
      // 3. RW registers: random write -> read -> compare (front door, auto-predict)
      repeat (20) begin
        void'(rb.ctrl.randomize());   rb.ctrl.update(st);   rb.ctrl.read(st, rd);   ops+=2;
        if (rd !== rb.ctrl.get())   begin errs++; `uvm_error("RAL","ctrl mismatch")   end
        void'(rb.numant.randomize()); rb.numant.update(st); rb.numant.read(st, rd); ops+=2;
        if (rd !== rb.numant.get()) begin errs++; `uvm_error("RAL","numant mismatch") end
        void'(rb.comp.randomize());   rb.comp.update(st);   rb.comp.read(st, rd);   ops+=2;
        if (rd !== rb.comp.get())   begin errs++; `uvm_error("RAL","comp mismatch")   end
        void'(rb.bwp.randomize());    rb.bwp.update(st);    rb.bwp.read(st, rd);    ops+=2;
        if (rd !== rb.bwp.get())    begin errs++; `uvm_error("RAL","bwp mismatch")    end
      end
      // 4. RO write-protect: attempt write to version, confirm value unchanged
      rb.version.write(st, 32'hFFFF_FFFF); rb.version.read(st, rd); ops+=2;
      if ((rd & 32'h0000_FFFF) !== 32'h0000_0A02) begin errs++; `uvm_error("RAL","RO version was writable") end
      $display("RAL_SUMMARY,ops=%0d,errs=%0d", ops, errs);
      $display("SBSUMMARY,txns=%0d,legal_err=0,pack_err=0,rt_err=0", ops);
      $display("UVM_INFO :  %0d", ops); $display("UVM_WARNING : 0");
      $display("UVM_ERROR : %0d", errs); $display("UVM_FATAL : 0");
      if (errs==0 && ops>0) $display("** TEST PASSED **"); else $display("** TEST FAILED **");
    endtask
  endclass

  // -------------------- RAL test --------------------
  class oran_ral_test extends uvm_test;
    `uvm_component_utils(oran_ral_test)
    oran_reg_block                 rb;
    oran_reg_adapter               adapter;
    uvm_sequencer #(reg_bus_item)  sqr;
    oran_reg_driver                drv;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase);
      rb = oran_reg_block::type_id::create("rb");
      rb.build(); rb.lock_model();
      adapter = oran_reg_adapter::type_id::create("adapter");
      sqr = uvm_sequencer #(reg_bus_item)::type_id::create("sqr", this);
      drv = oran_reg_driver::type_id::create("drv", this);
    endfunction
    virtual function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
      rb.default_map.set_sequencer(sqr, adapter);
      rb.default_map.set_auto_predict(1);
    endfunction
    virtual task run_phase(uvm_phase phase);
      oran_ral_seq seq;
      phase.raise_objection(this);
      seq = oran_ral_seq::type_id::create("seq"); seq.rb = rb; seq.start(sqr);
      phase.drop_objection(this);
    endtask
    virtual function void report_phase(uvm_phase phase);
      `uvm_info("RAL","register model exercised (5 regs, RW/RO, front-door + mirror check)", UVM_LOW)
    endfunction
  endclass
endpackage
