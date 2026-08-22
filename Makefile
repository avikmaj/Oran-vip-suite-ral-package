#=======================================================================
# Makefile — O-RAN VIP Suite (Lane-1 / Lane-2A / Lane-2B)
# Author : AVIK MAJUMDAR
# Project: AVIK VIP FACTORY - O-RAN VIP Suite
# Desc   : Unified build / run(standalone) / regress / coverage / waves
#          across ALL simulators.
#   SIM       = verilator5020 | verilator5050 | vcs | questa | xcelium
#   LANE      = 1 (plain-SV+Z3) | 2a (UVM-subset) | 2b (native UVM)
#   COMPONENT = <slug> | all     TEST=<name>  SEED=<n>  N=<txns>  RAND=<seeds>
#   WAVES=1   dumps a waveform (FST Verilator / VPD VCS / WLF Questa / SHM Xcelium)
# Note: Lane-1 & Lane-2A are Verilator-native (Z3 stimulus + custom sim_main).
#       Lane-2B native UVM runs on Verilator 5.050 AND VCS / Questa / Xcelium.
#=======================================================================
SHELL     := /bin/bash
ROOT      := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
GEN       := $(ROOT)/gen
L2        := $(ROOT)/lane2
L2BE      := $(L2)/lane2b_native/ecpri_transport
L2BS      := $(L2)/lane2b_native/suite
UVM_HOME  ?= /tmp/uvmtest/uvm
SIM       ?= verilator5050
COMPONENT ?= all
COMPONENTS:= ecpri_transport cpri_eth uplane cplane splane mplane beamforming \
             compression prach mimo_massive bwp mmwave laa
SEED      ?= 1
N         ?= 300
RAND      ?= 100
WAVES     ?= 0
TEST      ?= smoke

.PHONY: help all verilator050 uvm-setup lane1 lane2a lane2b ral regress \
        compile run standalone regress-l1 regress-l2 regress-l3 regress-l5 \
        coverage cov-report waves clean testplan mutation isoneg audit-dead cus-pin-diff vcs-farm

help:
	@echo "O-RAN VIP Suite — Makefile (Author: AVIK MAJUMDAR)"
	@echo "ENV bring-up:"
	@echo "  make verilator050                       # build Verilator 5.050 from source"
	@echo "  make uvm-setup                          # clone+patch Accellera UVM (DPI shim)"
	@echo "Standalone (single test):"
	@echo "  make run LANE=1  COMPONENT=<slug> TEST=smoke SEED=1   # Verilator"
	@echo "  make run LANE=2b SIM=verilator5050 COMPONENT=<slug> SEED=1"
	@echo "  make run LANE=2b SIM=vcs|questa|xcelium COMPONENT=<slug> SEED=1"
	@echo "Regression:"
	@echo "  make lane1                              # Lane-1 full (Verilator)"
	@echo "  make lane2a                             # Lane-2A UVM-subset (Verilator)"
	@echo "  make lane2b SIM=verilator5050|vcs|questa|xcelium   # Lane-2B native UVM"
	@echo "  make ral    SIM=verilator5050|vcs|questa|xcelium   # RAL uvm_reg model test"
	@echo "  make regress RAND=100                   # ALL lanes + RAL -> combined_regression.json"
	@echo "Coverage:"
	@echo "  make coverage                           # Verilator code+functional -> HTML dashboard"
	@echo "  make cov-report SIM=vcs|questa|xcelium  # urg / vcover / imc merge+report"
	@echo "Waves:"
	@echo "  make waves SIM=<sim> COMPONENT=<slug> TEST=<t> SEED=<n>"
	@echo "  make clean"

# ---------------- environment ----------------
verilator050: ; bash $(L2)/uvm050/build_verilator050.sh
uvm-setup:    ; bash $(L2)/uvm050/setup_uvm050.sh $(UVM_HOME)

# ---------------- Lane-1 (Verilator) ----------------
lane1:
	cd $(ROOT) && python3 $(GEN)/build_suite.py && RAND=$(RAND) python3 $(GEN)/run_gates.py \
	  && python3 $(GEN)/code_cov.py && python3 $(GEN)/corner.py && python3 $(GEN)/report.py
compile:
	cd $(ROOT) && python3 $(GEN)/build_suite.py $(if $(filter all,$(COMPONENT)),,$(COMPONENT))
regress-l1:
	cd $(ROOT) && for s in $(if $(filter all,$(COMPONENT)),$(COMPONENTS),$(COMPONENT)); do \
	  for sd in 1 2 3; do bash components/$$s/run.sh smoke $$sd $(N) $(WAVES); done; done
regress-l2 regress-l3 regress-l5:
	cd $(ROOT) && RAND=$(RAND) python3 $(GEN)/run_gates.py $(if $(filter all,$(COMPONENT)),,$(COMPONENT))

# ---------------- Lane-2A (Verilator UVM-subset) ----------------
lane2a:
	cd $(ROOT) && python3 $(L2)/gen/gen_uvm.py $(if $(filter all,$(COMPONENT)),,$(COMPONENT))

# ---------------- Lane-2B (native UVM, all simulators) ----------------
lane2b:
ifeq ($(SIM),verilator5050)
	cd $(ROOT) && python3 $(L2)/gen/gen_uvm_native.py
	cd $(L2BS) && UVM_HOME=$(UVM_HOME) ./build_suite_uvm.sh && ./run_all.sh
else ifeq ($(SIM),vcs)
	cd $(L2BS) && ./run_commercial.sh vcs all $(SEED)      # vendor UVM, *_commercial.f (no double-UVM)
else ifeq ($(SIM),questa)
	cd $(L2BS) && ./run_commercial.sh questa all $(SEED)
else ifeq ($(SIM),xcelium)
	cd $(L2BS) && ./run_commercial.sh xcelium all $(SEED)
else
	@echo "SIM=$(SIM) invalid for lane2b (verilator5050|vcs|questa|xcelium)"; exit 2
endif

# ---------------- RAL (uvm_reg register model) ----------------
RAL := $(L2)/ral
ral:
ifeq ($(SIM),verilator5050)
	cd $(RAL) && UVM_HOME=$(UVM_HOME) bash build_ral.sh \
	  && ./obj_ral/simv_ral +UVM_TESTNAME=oran_ral_test +ntb_random_seed=$(SEED) | tee ral_run.log \
	  && grep -q "\*\* TEST PASSED \*\*" ral_run.log && echo "RAL STATUS=PASS (uvm_reg, 5 regs, RW/RO)"
else
	cd $(L2BS) && ./run_commercial.sh $(SIM) ral $(SEED)  # vendor UVM, ral_commercial.f (no double-UVM)
endif

# ---------------- standalone (single test) ----------------
run standalone:
ifeq ($(LANE),2b)
  ifeq ($(SIM),verilator5050)
	cd $(L2BS) && ./obj_suite2/simv_uvm +UVM_TESTNAME=$(COMPONENT)_test +ntb_random_seed=$(SEED)
  else
	cd $(L2BE) && UVM_HOME=$(UVM_HOME) ./run_lane2b.sh $(SIM) $(SEED)
  endif
else
	cd $(ROOT)/components/$(COMPONENT) && bash run.sh $(TEST) $(SEED) $(N) $(WAVES)
endif

# ---------------- full regression (all lanes + RAL) ----------------
regress: lane1 lane2a lane2b ral
	cd $(ROOT) && python3 -c "import json; d=json.load(open('regression/combined_regression.json')); \
	print('COMBINED', d['combined_pass'],'/',d['combined_executed'],'=',d['combined_rate'],'%')"

# ---------------- coverage ----------------
coverage:            # Verilator: code (stmt/branch/toggle) + functional + HTML dashboard + final report
	cd $(ROOT) && python3 $(GEN)/code_cov.py && python3 $(GEN)/report.py && python3 $(GEN)/dashboard.py && python3 $(GEN)/final_report.py && python3 $(GEN)/testplan.py
	@echo "Functional: regression/suite_regression_full.json | Code: regression/code_cov.json"
	@echo "HTML dashboard: docs/COVERAGE_DASHBOARD.html"
	@echo "HTML final report: docs/FINAL_REGRESSION_COVERAGE_REPORT.html | Report(md): docs/FULL_COVERAGE_REPORT.md"
	@echo "HTML test plan + coverage: docs/TEST_PLAN_AND_COVERAGE.html"

testplan:            # detailed vplan + coverage (HTML) from spec.json + evidence
	cd $(ROOT) && python3 $(GEN)/testplan.py && echo "wrote docs/TEST_PLAN_AND_COVERAGE.html"

mutation:            # RT-003 fault-injection: codec/legality mutants -> scoreboard kill-rate
	cd $(ROOT) && python3 $(GEN)/mutation.py

isoneg:              # GATE-6+ isolated-negative regression: each reachable legality check independently
	cd $(ROOT) && python3 $(GEN)/run_isoneg.py

audit-dead:          # independent Z3 re-proof of mutation equivalent-dead exclusions
	cd $(ROOT) && python3 $(GEN)/audit_dead.py

cus-pin-diff:        # GAP-ORAN-001: emit CUS R004-v16 requirement pin/diff worksheet
	cd $(ROOT) && python3 $(GEN)/cus_pin_diff.py

vcs-farm:            # RT-009: turnkey VCS suite+RAL run on a licensed farm (evidence-capturing)
	cd $(L2BS) && ./run_vcs_farm.sh $(SEED)

cov-report:          # commercial-sim coverage merge + report
ifeq ($(SIM),vcs)
	@# real executor: merge the suite .vdb produced by vcs-farm into an HTML urg report
	cd $(L2BS) && ( ls simv_suite.vdb >/dev/null 2>&1 && urg -dir simv_suite.vdb -report $(ROOT)/regression/vcs_logs/urgReport \
	  && echo "VCS coverage: regression/vcs_logs/urgReport/dashboard.html" ) \
	  || echo "no simv_suite.vdb — run 'make vcs-farm' first (it builds with -cm and runs urg)"
else ifeq ($(SIM),questa)
	@echo "Questa: vcover merge merged.ucdb *.ucdb && vcover report -html -htmldir covhtml merged.ucdb"
else ifeq ($(SIM),xcelium)
	@echo "Xcelium: imc -exec 'merge cov_work/scope/* -out merged; load merged; report -html -out covhtml'"
else
	@$(MAKE) coverage
endif

# ---------------- waveforms (per simulator) ----------------
waves:
ifneq (,$(filter $(SIM),verilator5020 verilator5050))
	cd $(ROOT)/components/$(COMPONENT) && bash run.sh $(TEST) $(SEED) $(N) 1
	@echo "FST: components/$(COMPONENT)/sim_out/*.fst  (view: gtkwave <file>.fst)"
else ifeq ($(SIM),vcs)
	@# real executor: rebuild suite with debug access + dump VPD for the named component
	cd $(L2BS) && vcs -sverilog -full64 -ntb_opts uvm-1.2 -timescale=1ns/1ps -debug_access+all -kdb \
	  -f suite_commercial.f -o simv_dbg \
	  && ./simv_dbg +UVM_TESTNAME=$(COMPONENT)_test +ntb_random_seed=$(SEED) \
	     -ucli -do "dump -file $(COMPONENT).vpd -add /; run; quit" \
	  && echo "VPD: lane2/lane2b_native/suite/$(COMPONENT).vpd (view: dve -vpd <file> / verdi)"
else ifeq ($(SIM),questa)
	@echo "Questa : vsim -voptargs=+acc -do 'add wave -r /*; run -all; wlf2vcd vsim.wlf -o waves.vcd'  (WLF/VCD; view: vsim/gtkwave)"
else ifeq ($(SIM),xcelium)
	@echo "Xcelium: xrun -uvm -access +rwc -input @'database -open waves -shm; probe -create -all -depth all; run'  (SHM/VCD; view: simvision)"
endif

clean:
	@find $(ROOT) -type d -name 'obj*' -prune -exec rm -rf {} + 2>/dev/null; \
	 find $(ROOT) -name '*.hex' -delete 2>/dev/null; \
	 find $(ROOT) -name '*.fst' -delete 2>/dev/null; \
	 echo "cleaned build dirs / stimulus / waves"
