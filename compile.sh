#!/usr/bin/env bash
#=======================================================================
# compile.sh — cross-simulator compile wrapper, O-RAN VIP Suite
# Author : AVIK MAJUMDAR
# Usage  : ./compile.sh <sim> <lane> [component]
#          sim  = verilator5020 | verilator5050 | vcs | questa | xcelium
#          lane = 1 | 2a | 2b
#=======================================================================
set -u
SIM="${1:-verilator5050}"; LANE="${2:-1}"; COMP="${3:-all}"
ROOT="$(cd "$(dirname "$0")" && pwd)"; UVM_HOME="${UVM_HOME:-/tmp/uvmtest/uvm}"
DPI="$UVM_HOME/src/dpi"; VPI="$ROOT/lane2/uvm050/vpi_stub.cc"

case "$LANE:$SIM" in
  1:verilator*)   python3 "$ROOT/gen/build_suite.py" $([ "$COMP" = all ] || echo "$COMP");;
  2a:verilator*)  python3 "$ROOT/lane2/gen/gen_uvm.py" $([ "$COMP" = all ] || echo "$COMP");;
  2b:verilator5050)
    python3 "$ROOT/lane2/gen/gen_uvm_native.py"
    cd "$ROOT/lane2/lane2b_native/suite" && UVM_HOME="$UVM_HOME" ./build_suite_uvm.sh ;;
  2b:vcs)
    cd "$ROOT/lane2/lane2b_native/ecpri_transport" && \
    vcs -sverilog -full64 -ntb_opts uvm-1.2 -timescale=1ns/1ps -f ecpri.f -o simv_vcs \
        -cm line+cond+fsm+branch+tgl+assert ;;
  2b:questa)
    cd "$ROOT/lane2/lane2b_native/ecpri_transport" && \
    qverilog -sv -mfcu -timescale 1ns/1ps +incdir+$UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv -f ecpri.f -coveropt 3 +cover ;;
  2b:xcelium)
    cd "$ROOT/lane2/lane2b_native/ecpri_transport" && \
    xrun -uvm -sv -timescale 1ns/1ps -f ecpri.f -coverage all -elaborate ;;
  *) echo "unsupported LANE:SIM = $LANE:$SIM"; exit 2;;
esac
echo "compile.sh done: SIM=$SIM LANE=$LANE COMPONENT=$COMP"
