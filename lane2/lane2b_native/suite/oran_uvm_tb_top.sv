// ======================================================================
//  File   : lane2/lane2b_native/suite/oran_uvm_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : Lane-2B combined native-UVM top: 13-component factory registration + run_test(+UVM_TESTNAME).
// ======================================================================
module oran_uvm_tb_top;
  import uvm_pkg::*; `include "uvm_macros.svh"
  import ecpri_transport_uvm_pkg::*;
  import cpri_eth_uvm_pkg::*;
  import uplane_uvm_pkg::*;
  import cplane_uvm_pkg::*;
  import splane_uvm_pkg::*;
  import mplane_uvm_pkg::*;
  import beamforming_uvm_pkg::*;
  import compression_uvm_pkg::*;
  import prach_uvm_pkg::*;
  import mimo_massive_uvm_pkg::*;
  import bwp_uvm_pkg::*;
  import mmwave_uvm_pkg::*;
  import laa_uvm_pkg::*;
  initial begin
    int reg_cnt = 0; string tn;
    if(ecpri_transport_test::type_id::get() != null) reg_cnt++;
    if(cpri_eth_test::type_id::get() != null) reg_cnt++;
    if(uplane_test::type_id::get() != null) reg_cnt++;
    if(cplane_test::type_id::get() != null) reg_cnt++;
    if(splane_test::type_id::get() != null) reg_cnt++;
    if(mplane_test::type_id::get() != null) reg_cnt++;
    if(beamforming_test::type_id::get() != null) reg_cnt++;
    if(compression_test::type_id::get() != null) reg_cnt++;
    if(prach_test::type_id::get() != null) reg_cnt++;
    if(mimo_massive_test::type_id::get() != null) reg_cnt++;
    if(bwp_test::type_id::get() != null) reg_cnt++;
    if(mmwave_test::type_id::get() != null) reg_cnt++;
    if(laa_test::type_id::get() != null) reg_cnt++;
    $display("MUVM_REG: %0d test types registered", reg_cnt);
    fork begin #2000000; $display("WATCHDOG"); $finish; end join_none
    if ($value$plusargs("UVM_TESTNAME=%s", tn)) run_test(tn);
    else run_test();
    $finish;
  end
endmodule
