# O-RAN VIP Suite — VCS run cheat-sheet

**Author:** AVIK MAJUMDAR · AVIK VIP FACTORY — O-RAN VIP Suite
Real Makefile idiom: `SIM=` + `COMPONENT=<slug>` (not `PROTOCOL=`). 13 components + RAL (not 20).
`SIM = verilator5050 | vcs | questa | xcelium`. VCS uses **vendor built-in UVM** via `*_commercial.f`
(never compiles Accellera `uvm_pkg.sv` → avoids the double-UVM name-resolution blocker).

COMPONENT ∈ { ecpri_transport, cpri_eth, uplane, cplane, splane, mplane, beamforming,
              compression, prach, mimo_massive, bwp, mmwave, laa }

```
# --- toolchain (VCS on PATH; UVM_HOME NOT needed for VCS — vendor UVM) ---
make help                                             # target list

# --- single component, native UVM on VCS (build + run) ---
make run  LANE=2b SIM=vcs COMPONENT=uplane SEED=1     # +UVM_TESTNAME=uplane_test +ntb_random_seed=1
make ral        SIM=vcs SEED=1                        # RAL uvm_reg model on VCS

# --- full 13-component native-UVM suite on VCS (loops all tests) ---
make lane2b     SIM=vcs SEED=1                        # run_commercial.sh vcs all  (suite + RAL)

# --- 100-random-seed soak on VCS (regress-l3 equivalent) for one component ---
for s in $(seq 1 100); do \
  make run LANE=2b SIM=vcs COMPONENT=uplane SEED=$s ; done

# --- FULL regression on VCS, suite + RAL, WITH evidence capture -> regression/vcs_report.json ---
make vcs-farm   SEED=1                                # turnkey: build+run 13+RAL, per-test logs, urg cov
                                                      # (equivalent: cd lane2/lane2b_native/suite && ./run_vcs_farm.sh 1)

# --- coverage report on VCS (merge + HTML) ---
make cov-report SIM=vcs                               # urg -dir simv_suite.vdb -report urgReport  (HTML)

# --- waveforms on VCS (VPD/FSDB; view in DVE/Verdi) ---
make waves      SIM=vcs COMPONENT=uplane TEST=smoke SEED=1
```

## Questa / Xcelium (same flow, swap SIM)
```
make lane2b   SIM=questa   SEED=1      # vendor UVM via -L uvm
make lane2b   SIM=xcelium  SEED=1      # vendor UVM via -uvm
make ral      SIM=questa|xcelium
make cov-report SIM=questa             # vcover merge + report -html
make cov-report SIM=xcelium            # imc merge + report -html
```

## Reference lane (Verilator 5.050 — no license) for comparison
```
make lane1                             # Lane-1 plain-SV VIP (Z3) — 1470/1470
make lane2b   SIM=verilator5050        # Lane-2B native UVM — 13/13
make ral      SIM=verilator5050        # RAL — PASS (163 ops)
make regress                           # ALL lanes + RAL -> combined_regression.json (1536/1536)
make coverage                          # code + functional + HTML dashboard/reports
make mutation ; make isoneg ; make audit-dead   # RT-003 kill-rate + isolated-neg + dead-exclusion audit
```

## PASS criteria (per test, from the log)
`** TEST PASSED **` AND `UVM_ERROR : 0` AND `UVM_FATAL : 0`. RAL also needs `RAL_SUMMARY,ops=<n>,errs=0`.

## First VCS failure to check: the filelist
Names not resolving (`uvm_*` typedef/class) = **double-UVM**: the filelist compiled Accellera `uvm_pkg.sv`
alongside `-ntb_opts uvm-1.2`. The `*_commercial.f` filelists must NOT list `uvm_pkg.sv`. Only the
Verilator path (`ecpri.f` / `build_*_uvm.sh`) compiles it. See `docs/VCS_RUN_RUNBOOK.md`.

## Fold VCS results into the record (executed-only)
After `make vcs-farm`, update the portability matrix **from `regression/vcs_report.json` only** — never infer.
See `docs/VCS_RUN_RUNBOOK.md` §5. RT-009 closes when `vcs_report.json.STATUS == PASS` (suite 13/13 + RAL).
```
