# O-RAN VIP — VCS Farm Runbook (RT-009 closure)

**Author:** AVIK MAJUMDAR · **Project:** AVIK VIP FACTORY — O-RAN VIP Suite

Goal: flip the VCS column of the portability matrix from **source-ready** to **proven** by executing the
native-UVM suite + RAL on a licensed VCS host, with captured evidence. The double-UVM blocker is already
fixed (vendor built-in UVM via `*_commercial.f`, zero re-export chains) — this run is expected to be a clean
compile+run. Until `regression/vcs_report.json` exists, the VCS column stays **NOT_RUN** (never inferred).

## 0. Prerequisites (on the farm)
- `vcs` and `urg` on `PATH` (VCS 2020.03+ ships UVM 1.2 built-in — do **not** set/compile `$UVM_HOME`).
- The repo checked out; `cd lane2/lane2b_native/suite`.

## 1. One command (turnkey)
```
cd lane2/lane2b_native/suite
./run_vcs_farm.sh 1            # seed 1 — builds suite+RAL, runs 13+1, captures logs, writes evidence
```
Outputs:
- `regression/vcs_logs/<test>.log` — per-test UVM log (PASS marker + report summary)
- `regression/vcs_logs/urgReport/dashboard.html` — merged code+functional coverage (urg)
- `regression/vcs_report.json` — `{suite_pass, suite_total, ral, STATUS}` from executed logs

## 2. Manual equivalent (if you prefer explicit steps)
```
cd lane2/lane2b_native/suite
# build once (vendor UVM; NO $UVM_HOME/src/uvm_pkg.sv in the filelist)
vcs -sverilog -full64 -ntb_opts uvm-1.2 -timescale=1ns/1ps \
    -cm line+cond+fsm+branch+tgl+assert -f suite_commercial.f -o simv_suite
# run each component
for t in ecpri_transport cpri_eth uplane cplane splane mplane beamforming \
         compression prach mimo_massive bwp mmwave laa; do
  ./simv_suite +UVM_TESTNAME=${t}_test +ntb_random_seed=1 -cm line+cond+fsm+branch+tgl+assert -l ${t}.log
done
# RAL
cd ../ral
vcs -sverilog -full64 -ntb_opts uvm-1.2 -timescale=1ns/1ps -f ral_commercial.f -o simv_ral
./simv_ral +UVM_TESTNAME=oran_ral_test +ntb_random_seed=1 -l ral.log
# coverage report
cd ../lane2b_native/suite && urg -dir simv_suite.vdb -report urgReport
```

## 3. PASS criteria (per test, from the log)
`** TEST PASSED **` present **AND** `UVM_ERROR : 0` **AND** `UVM_FATAL : 0`. Anything else = FAIL.
The RAL additionally must show `RAL_SUMMARY,ops=<n>,errs=0`.

## 4. Common failure — check the filelist FIRST
If names fail to resolve (`uvm_*` typedef/class not found), the filelist is compiling the Accellera
`uvm_pkg.sv` alongside `-ntb_opts uvm-1.2` → **double-UVM**. The `*_commercial.f` filelists must **not** list
`uvm_pkg.sv`. (The Verilator path `ecpri.f`/`build_*_uvm.sh` is the only place that compiles it.)

## 5. Fold results into the record (executed-only)
After a clean run, update the portability matrix **from `regression/vcs_report.json` only**:
```
python3 - <<'PY'
import json
c=json.load(open("regression/combined_regression.json"))
v=json.load(open("regression/vcs_report.json"))
c.setdefault("portability",{})["vcs"]={"suite":f"{v['suite_pass']}/{v['suite_total']}","ral":v["ral"],"status":v["STATUS"]}
json.dump(c,open("regression/combined_regression.json","w"),indent=2)
print("portability.vcs =",c["portability"]["vcs"])
PY
```
Then regenerate the reports (`make coverage`) and re-issue the signoff certificate row for the VCS column.
RT-009 is closed only when `vcs_report.json.STATUS == PASS` for suite (13/13) + RAL.
```
