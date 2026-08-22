# UVM on Verilator 5.050 — working recipe (executed 2026-08-09)
Verilator 5.050 (source-built) runs full Accellera UVM with a small DPI shim:
1. build Verilator 5.050 from source (git tag v5.050).
2. setup_uvm050.sh: clone uvm-core + patch (no-op HDL backdoor stubs matching uvm_dpi.h;
   disable VPI polling include).
3. vpi_stub.cc: provide vpi_get_vlog_info (tool-name query).
Compile: verilator --binary --timing +incdir+$UVM/src $UVM/src/uvm_pkg.sv <tb> \
  -CFLAGS "-I$UVM/src/dpi -I$UVM/src" $UVM/src/dpi/uvm_dpi.cc vpi_stub.cc
PROVEN: native randomize() with {} HONORED; covergroup + cross + illegal_bins; concurrent SVA;
full uvm_pkg run_test/factory/phasing/sequencer/scoreboard. hello_test + ecpri_test = 0 errors.

## RESULT (executed 2026-08-09)
Lane-2B NATIVE UVM ran on Verilator 5.050 for ALL 13 O-RAN components:
each txns=100, UVM_ERROR=0, ** TEST PASSED **. Native randomize() with {} honored
(scoreboard 0 errors), native covergroup cross+illegal_bins sampled, full UVM
factory/config_db/phasing/sequencer/driver/scoreboard. build: build_suite_uvm.sh.
COMBINED (all lanes): 1522/1522 = 100% real executed pass.
