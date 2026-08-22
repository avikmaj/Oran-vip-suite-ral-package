#!/usr/bin/env bash
# ======================================================================
#  File   : lane2/lane2b_native/suite/run_all.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Build/run automation script.
# ======================================================================
cd "$(dirname "$0")"
S="ecpri_transport cpri_eth uplane cplane splane mplane beamforming compression prach mimo_massive bwp mmwave laa"
pass=0; n=0
for s in $S; do
  n=$((n+1))
  timeout 150 ./obj_suite2/simv_uvm +UVM_TESTNAME=${s}_test +ntb_random_seed=1 > run_${s}.log 2>&1
  r=$(grep -E '\*\* TEST PASSED|\*\* TEST FAILED|NOCOMP' run_${s}.log | head -1)
  t=$(grep -oE 'SBSUMMARY,txns=[0-9]+' run_${s}.log | head -1)
  e=$(grep -oE 'UVM_ERROR :[[:space:]]+[0-9]+' run_${s}.log | head -1)
  echo "$s | $t | $e | $r"
  echo "$r" | grep -q 'TEST PASSED' && pass=$((pass+1))
done
echo "==============================================="
echo "Lane-2B NATIVE UVM on Verilator 5.050: $pass/$n PASS"
