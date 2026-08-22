#!/usr/bin/env bash
# ======================================================================
#  File   : lane2/lane2b_native/ecpri_transport/run_lane2b.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Date   : 2026-08-09
#  Desc   : Build/run automation script (commercial-sim ecpri single component).
# ======================================================================
# Lane-2B run harness — execute on a UVM-capable venue. Produces result.json.
# STATUS stays NOT_VERIFIED until a venue returns a real log.
#
# VCS NAME-RESOLUTION RULE: use the VENDOR built-in UVM ONLY. Filelist
# ecpri_commercial.f does NOT compile $UVM_HOME/src/uvm_pkg.sv — compiling the
# Accellera source alongside -ntb_opts/-uvm double-defines uvm_pkg and VCS then
# fails to resolve names through the import chain. Leaf package (ecpri_uvm_pkg)
# is imported DIRECTLY in the tb; there is no re-export chain.
# (ecpri.f — WITH uvm_pkg.sv — is the Verilator-5.050 filelist; do not use it here.)
SIM="${1:?usage: run_lane2b.sh <dsim|vcs|questa|xcelium> [seed]}"; SEED="${2:-1}"
FL=ecpri_commercial.f
case "$SIM" in
  dsim)    dsim -uvm 1.2 -f $FL +UVM_TESTNAME=ecpri_test +ntb_random_seed=$SEED -cov all ;;
  vcs)     vcs -sverilog -full64 -ntb_opts uvm-1.2 -timescale=1ns/1ps -f $FL \
               -cm line+cond+fsm+branch+tgl+assert -o simv && \
           ./simv +UVM_TESTNAME=ecpri_test +ntb_random_seed=$SEED -cm line+cond+fsm+branch+tgl+assert ;;
  questa)  qverilog -sv -mfcu -timescale 1ns/1ps -f $FL -R -L uvm \
               +UVM_TESTNAME=ecpri_test -sv_seed $SEED -coverage ;;
  xcelium) xrun -uvm -sv -timescale 1ns/1ps -f $FL +UVM_TESTNAME=ecpri_test -svseed $SEED -coverage all ;;
  *) echo "unknown sim $SIM"; exit 2 ;;
esac
