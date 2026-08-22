# O-RAN VIP Suite — Lane-2 Status

## Lane-2A — UVM component architecture on Verilator (EXECUTED, real evidence)
muvm_pkg: UVM-1.1-compatible subset that ELABORATES AND RUNS on Verilator 5.020 —
object, component, phasing (build/connect/run/report), factory (with override),
config_db, analysis port, sequencer/driver + component scoreboard.
Result: 13/13 components build + run (seeds 1,2,3) PASS. Factory-created env drives
Z3 stimulus through the sequencer/driver to a component scoreboard that checks
pack/unpack round-trip + legality. Functional COVROW emitted through the UVM monitor path.
Evidence: lane2/lane2a_report.json + lane2/components/<slug>/result_l2a_seed*.json.
Covers the UVM STRUCTURAL layer Lane-1 plain-SV cannot: factory/config_db/phasing/component-scoreboard.

## Lane-2B — native UVM on licensed simulator (AUTHORED, NOT_VERIFIED)
Real Accellera-UVM source (lane2/lane2b_native/ecpri_transport/): uvm_sequence_item with
NATIVE randomize() with {} constraints, NATIVE covergroup with cross + illegal_bins,
concurrent SVA temporal properties (seq continuity, version/msg/payload invariants) in a
bound interface, full uvm_component env/agent/driver/scoreboard/test.
STATUS: NOT_VERIFIED — no UVM-capable simulator in sandbox (Verilator 5.020 fails UVM
elaboration: PKGNODECL, measured). Advances to PASS only on a venue's returned result.json.
Run harness: run_lane2b.sh (dsim/vcs/questa/xcelium). Acceptance: VENUE_ACCEPTANCE.md. GAP-ORAN-002.

## What each lane proves
- Lane-1 (Verilator): protocol field encoding, pack/unpack, legal-space (per-field+cross via Z3),
  negative detection, functional + code coverage. 1470/1470 = 100% (executed).
- Lane-2A (Verilator UVM-subset): UVM component architecture executes — 39/39 runs PASS (executed).
- Lane-2B (licensed venue): native constraint-solving + covergroup cross/illegal_bins + concurrent
  SVA + full-stack portability. NOT_VERIFIED until venue runs it.
