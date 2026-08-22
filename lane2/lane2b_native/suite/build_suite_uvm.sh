#!/usr/bin/env bash
# ======================================================================
#  File   : lane2/lane2b_native/suite/build_suite_uvm.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Build/run automation script.
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
  ecpri_transport_uvm_pkg.sv cpri_eth_uvm_pkg.sv uplane_uvm_pkg.sv cplane_uvm_pkg.sv \
  splane_uvm_pkg.sv mplane_uvm_pkg.sv beamforming_uvm_pkg.sv compression_uvm_pkg.sv \
  prach_uvm_pkg.sv mimo_massive_uvm_pkg.sv bwp_uvm_pkg.sv mmwave_uvm_pkg.sv laa_uvm_pkg.sv \
  oran_uvm_tb_top.sv \
  -CFLAGS "-I$DPI -I$UVM/src" "$DPI/uvm_dpi.cc" "$VPI" \
  --Mdir obj_suite2 -o simv_uvm
echo "BUILD_DONE_EXIT=$?"
