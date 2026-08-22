// ======================================================================
//  File   : lane2/ral/oran_ral_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : Top module for the O-RAN RAL (uvm_reg) testbench. Imports
//           oran_ral_pkg, force-registers oran_ral_test with the factory
//           (Verilator elides bare type_id::get() calls), starts run_test
//           from +UVM_TESTNAME (default oran_ral_test), and arms a
//           simulation watchdog. Native UVM on Verilator 5.050 / VCS /
//           Questa / Xcelium.
// ======================================================================
module oran_ral_tb_top;
  import uvm_pkg::*; `include "uvm_macros.svh"
  import oran_ral_pkg::*;
  initial begin
    int reg_cnt = 0; string tn;
    if (oran_ral_test::type_id::get() != null) reg_cnt++;
    $display("MUVM_REG: %0d test types registered", reg_cnt);
    fork begin #2000000; $display("WATCHDOG"); $finish; end join_none
    if ($value$plusargs("UVM_TESTNAME=%s", tn)) run_test(tn);
    else run_test("oran_ral_test");
    $finish;
  end
endmodule
