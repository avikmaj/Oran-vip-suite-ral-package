// ======================================================================
//  File   : lane2/lane2b_native/ecpri_transport/ecpri_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : O-RAN VIP Suite source (lane2/lane2b_native/ecpri_transport/ecpri_tb_top.sv).
// ======================================================================
module ecpri_tb_top;
  import uvm_pkg::*; `include "uvm_macros.svh"
  import ecpri_uvm_pkg::*;
  logic clk=0, rst_n=0;
  always #5 clk = ~clk;
  ecpri_if vif(.clk(clk), .rst_n(rst_n));
  initial begin rst_n=0; #20 rst_n=1; end
  initial begin
    uvm_config_db#(virtual ecpri_if)::set(null,"*","vif",vif);
    fork begin #500000; $display("WATCHDOG_FINISH"); $finish; end join_none
    run_test("ecpri_test");
  end
endmodule
