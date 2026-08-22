#!/usr/bin/env bash
# ======================================================================
#  File   : lane2/ral/build_ral.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Build the native-UVM RAL (uvm_reg) testbench on Verilator 5.050
#           and run oran_ral_test. Mirrors the Lane-2B suite build recipe
#           (DPI shim + vpi_stub). Emits result to obj_ral/simv_ral.
# ======================================================================
set -e
cd "$(dirname "$0")"
UVM=/tmp/uvmtest/uvm
DPI="$UVM/src/dpi"
VPI=/home/claude/oran_vip_suite/lane2/uvm050/vpi_stub.cc
export CCACHE_DIR=/home/claude/.ccache; export CCACHE_MAXSIZE=5G
verilator --binary -j 2 --timing \
  -Wno-fatal -Wno-IMPLICITSTATIC -Wno-CASEINCOMPLETE -Wno-WIDTH -Wno-CONSTRAINTIGN \
  +incdir+"$UVM/src" "$UVM/src/uvm_pkg.sv" \
  oran_ral_pkg.sv oran_ral_tb_top.sv \
  -CFLAGS "-I$DPI -I$UVM/src" "$DPI/uvm_dpi.cc" "$VPI" \
  --Mdir obj_ral -o simv_ral
echo "BUILD_DONE_EXIT=$?"
