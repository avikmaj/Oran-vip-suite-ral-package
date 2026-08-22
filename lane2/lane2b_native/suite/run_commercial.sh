#!/usr/bin/env bash
# ======================================================================
#  File   : lane2/lane2b_native/suite/run_commercial.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Commercial-simulator (VCS / Questa / Xcelium) build+run for the
#           13-component native-UVM suite AND the uvm_reg RAL.
#
#  VCS NAME-RESOLUTION RULE (bulletproof):
#    Use the VENDOR built-in UVM ONLY. Do NOT also compile
#    $UVM_HOME/src/uvm_pkg.sv — compiling the Accellera source alongside
#    the vendor's -ntb_opts/-uvm library double-defines uvm_pkg and VCS
#    then fails to resolve typedefs/classes through the import chain.
#    Every leaf package is compiled and imported DIRECTLY (see the *_commercial.f
#    filelists); there is no package re-export chain to resolve through.
#    (The Verilator 5.050 path is the opposite: it has NO built-in UVM, so
#     build_suite_uvm.sh / build_ral.sh DO compile $UVM/src/uvm_pkg.sv.)
#
#  Usage: ./run_commercial.sh <vcs|questa|xcelium> [test_or_all] [seed]
# ======================================================================
set -u
SIM="${1:?usage: run_commercial.sh <vcs|questa|xcelium> [test|all] [seed]}"
WHICH="${2:-all}"; SEED="${3:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
RALDIR="$(cd "$HERE/../../ral" && pwd)"
SUITE_TESTS=(ecpri_transport cpri_eth uplane cplane splane mplane beamforming \
             compression prach mimo_massive bwp mmwave laa)

run_one_vcs() { # $1=filelist $2=simv $3=test
  vcs -sverilog -full64 -ntb_opts uvm-1.2 -timescale=1ns/1ps \
      -cm line+cond+fsm+branch+tgl+assert -f "$1" -o "$2"
  "./$2" +UVM_TESTNAME="$3" +ntb_random_seed="$SEED" -cm line+cond+fsm+branch+tgl+assert
}
run_one_xcelium() { # $1=filelist $2=test
  xrun -uvm -sv -timescale 1ns/1ps -coverage all -f "$1" \
       +UVM_TESTNAME="$2" -svseed "$SEED"
}
run_one_questa() { # $1=filelist $2=test  (vendor UVM via -L uvm precompiled lib)
  qverilog -sv -mfcu -timescale 1ns/1ps -f "$1" \
       -R -L uvm +UVM_TESTNAME="$2" -sv_seed "$SEED" -coverage
}

do_suite() {
  for t in "${SUITE_TESTS[@]}"; do
    echo "=== SUITE $SIM :: ${t}_test ==="
    ( cd "$HERE"
      case "$SIM" in
        vcs)     run_one_vcs     suite_commercial.f simv_suite "${t}_test" ;;
        xcelium) run_one_xcelium suite_commercial.f "${t}_test" ;;
        questa)  run_one_questa  suite_commercial.f "${t}_test" ;;
      esac )
  done
}
do_ral() {
  echo "=== RAL $SIM :: oran_ral_test ==="
  ( cd "$RALDIR"
    case "$SIM" in
      vcs)     run_one_vcs     ral_commercial.f simv_ral oran_ral_test ;;
      xcelium) run_one_xcelium ral_commercial.f oran_ral_test ;;
      questa)  run_one_questa  ral_commercial.f oran_ral_test ;;
    esac )
}

case "$WHICH" in
  all)          do_suite; do_ral ;;
  ral)          do_ral ;;
  oran_ral_test) do_ral ;;
  *)            ( cd "$HERE"
                  case "$SIM" in
                    vcs)     run_one_vcs     suite_commercial.f simv_suite "$WHICH" ;;
                    xcelium) run_one_xcelium suite_commercial.f "$WHICH" ;;
                    questa)  run_one_questa  suite_commercial.f "$WHICH" ;;
                  esac ) ;;
esac
