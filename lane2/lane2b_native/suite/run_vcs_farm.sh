#!/usr/bin/env bash
# ======================================================================
#  File   : lane2/lane2b_native/suite/run_vcs_farm.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Desc   : RT-009 closure — turnkey VCS run of the native-UVM suite + RAL on a
#           LICENSED farm, with evidence capture. Uses the vendor built-in UVM
#           via the *_commercial.f filelists (NO Accellera uvm_pkg.sv — avoids the
#           double-UVM name-resolution blocker). Emits regression/vcs_report.json
#           (STATUS per test from real logs) + coverage via urg. STATUS is from
#           executed evidence only; a component with no PASS marker is FAIL, never
#           inferred.
#  Usage   : ./run_vcs_farm.sh [seed]      (run from this directory; VCS on PATH)
#  Env     : requires `vcs`, `urg` (VCS toolchain). No UVM_HOME needed for VCS.
# ======================================================================
set -u
SEED="${1:-1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
RALDIR="$(cd "$HERE/../../ral" && pwd)"
OUT="$ROOT/regression/vcs_logs"; mkdir -p "$OUT"
TESTS=(ecpri_transport cpri_eth uplane cplane splane mplane beamforming \
       compression prach mimo_massive bwp mmwave laa)

command -v vcs >/dev/null || { echo "ERROR: vcs not on PATH — run on the licensed farm."; exit 2; }

CM="-cm line+cond+fsm+branch+tgl+assert"
echo "[vcs] building suite (vendor UVM, suite_commercial.f)..."
cd "$HERE"
vcs -sverilog -full64 -ntb_opts uvm-1.2 -timescale=1ns/1ps $CM \
    -f suite_commercial.f -o simv_suite -l "$OUT/compile_suite.log" || { echo "SUITE COMPILE FAIL"; exit 3; }

pass=0; total=0; declare -A RES
for t in "${TESTS[@]}"; do
  total=$((total+1)); log="$OUT/${t}.log"
  ./simv_suite +UVM_TESTNAME=${t}_test +ntb_random_seed=$SEED $CM -l "$log" >/dev/null 2>&1
  if grep -q "\*\* TEST PASSED \*\*" "$log" && ! grep -qE "UVM_ERROR :[[:space:]]*[1-9]|UVM_FATAL :[[:space:]]*[1-9]" "$log"; then
    RES[$t]=PASS; pass=$((pass+1)); echo "  $t PASS"
  else
    RES[$t]=FAIL; echo "  $t FAIL (see $log)"
  fi
done

echo "[vcs] building + running RAL (ral_commercial.f)..."
cd "$RALDIR"
ralstat=FAIL
if vcs -sverilog -full64 -ntb_opts uvm-1.2 -timescale=1ns/1ps $CM \
     -f ral_commercial.f -o simv_ral -l "$OUT/compile_ral.log"; then
  ./simv_ral +UVM_TESTNAME=oran_ral_test +ntb_random_seed=$SEED $CM -l "$OUT/ral.log" >/dev/null 2>&1
  grep -q "\*\* TEST PASSED \*\*" "$OUT/ral.log" && ralstat=PASS
fi
echo "  RAL $ralstat"

# coverage merge (suite .vdb) -> HTML
cd "$HERE"
if command -v urg >/dev/null && ls simv_suite.vdb >/dev/null 2>&1; then
  urg -dir simv_suite.vdb -report "$OUT/urgReport" >/dev/null 2>&1 && echo "[vcs] coverage: $OUT/urgReport/dashboard.html"
fi

# evidence json
python3 - "$OUT" "$pass" "$total" "$ralstat" <<'PY'
import json,sys
out,p,t,ral=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),sys.argv[4]
import os
res={"simulator":"VCS","uvm":"vendor built-in (-ntb_opts uvm-1.2)","filelist":"suite_commercial.f / ral_commercial.f",
     "suite_pass":p,"suite_total":t,"ral":ral,
     "STATUS":"PASS" if (p==t and ral=="PASS") else "FAIL",
     "note":"Executed on licensed farm. Fold into combined_regression portability matrix ONLY from this file."}
json.dump(res,open(os.path.join(os.path.dirname(out),"vcs_report.json"),"w"),indent=2)
print("wrote regression/vcs_report.json:",res["STATUS"],f"(suite {p}/{t}, RAL {ral})")
PY
echo "[vcs] DONE — update the portability matrix from regression/vcs_report.json only."
