% O-RAN VIP Suite — FULL REGRESSION REPORT
% Author: AVIK MAJUMDAR — AVIK VIP FACTORY
% 2026-08-09

# 1. Headline
**Combined executed regression: 1523/1523 = 100.0% REAL pass.**
Every STATUS derived from executed simulator evidence (adjudicate.py); none inferred.

| Lane | Description | Simulator | Tests | Pass | Rate |
|---|---|---|---|---|---|
| Lane-1 | plain-SV VIP (smoke+random100+negative+directed+corner) | Verilator 5.020/5.050 | 1470 | 1470 | 100% |
| Lane-2A | UVM-subset architecture (muvm_pkg) | Verilator 5.020/5.050 | 39 | 39 | 100% |
| Lane-2B | native Accellera UVM | Verilator 5.050 | 13 | 13 | 100% |
| RAL | uvm_reg register model (5 regs, RW/RO) | Verilator 5.050 | 1 | 1 | 100% |
| **Total** | | | **1523** | **1523** | **100.0%** |

# 2. Lane-1 — per component, per test class
| Component | smoke | random(100) | negative | directed | corner | Total | Pass% | Func cov | Code stmt | Branch(eff) |
|---|---|---|---|---|---|---|---|---|---|---|
| ecpri_transport | 3/3 | 20/20 | 3/3 | - | 14/14 | 40/40 | 100.0% | 100.0% | 100.0% | 100.0% |
| cpri_eth | 3/3 | 100/100 | 3/3 | - | 16/16 | 122/122 | 100.0% | 100.0% | 100.0% | 100.0% |
| uplane | 3/3 | 100/100 | 3/3 | - | 17/17 | 123/123 | 100.0% | 100.0% | 100.0% | 100.0% |
| cplane | 3/3 | 100/100 | 3/3 | - | 17/17 | 123/123 | 100.0% | 100.0% | 100.0% | 100.0% |
| splane | 3/3 | 100/100 | 3/3 | 1/1 | 12/12 | 119/119 | 100.0% | 100.0% | 100.0% | 100.0% |
| mplane | 3/3 | 100/100 | 3/3 | - | 12/12 | 118/118 | 100.0% | 100.0% | 100.0% | 100.0% |
| beamforming | 3/3 | 100/100 | 3/3 | - | 13/13 | 119/119 | 100.0% | 100.0% | 100.0% | 100.0% |
| compression | 3/3 | 100/100 | 3/3 | - | 10/10 | 116/116 | 100.0% | 100.0% | 100.0% | 100.0% |
| prach | 3/3 | 100/100 | 3/3 | - | 12/12 | 118/118 | 100.0% | 100.0% | 100.0% | 100.0% |
| mimo_massive | 3/3 | 100/100 | 3/3 | - | 14/14 | 120/120 | 100.0% | 100.0% | 100.0% | 100.0% |
| bwp | 3/3 | 100/100 | 3/3 | - | 12/12 | 118/118 | 100.0% | 100.0% | 100.0% | 100.0% |
| mmwave | 3/3 | 100/100 | 3/3 | - | 12/12 | 118/118 | 100.0% | 100.0% | 100.0% | 100.0% |
| laa | 3/3 | 100/100 | 3/3 | - | 10/10 | 116/116 | 100.0% | 100.0% | 100.0% | 100.0% |

Lane-1 total: **1470/1470 = 100.0%**. Negative = EXPECTED_FAILURE_DETECTED. Code branch effective 100% (6 TB-defensive branches/comp waived, 0 DUT uncovered).

# 3. Lane-2A — UVM-subset architecture (Verilator, executed)
| Component | build | seeds 1/2/3 |
|---|---|---|
| ecpri_transport | PASS | PASS,PASS,PASS |
| cpri_eth | PASS | PASS,PASS,PASS |
| uplane | PASS | PASS,PASS,PASS |
| cplane | PASS | PASS,PASS,PASS |
| splane | PASS | PASS,PASS,PASS |
| mplane | PASS | PASS,PASS,PASS |
| beamforming | PASS | PASS,PASS,PASS |
| compression | PASS | PASS,PASS,PASS |
| prach | PASS | PASS,PASS,PASS |
| mimo_massive | PASS | PASS,PASS,PASS |
| bwp | PASS | PASS,PASS,PASS |
| mmwave | PASS | PASS,PASS,PASS |
| laa | PASS | PASS,PASS,PASS |
Lane-2A total: **39/39 PASS** (factory/config_db/phasing/component-scoreboard executed).

# 4. Lane-2B — native UVM on Verilator 5.050 (executed)
Command: `make lane2b SIM=verilator5050`  (native randomize() with {}, native covergroup cross+illegal_bins, full UVM).
| Component | txns | UVM_ERROR | status |
|---|---|---|---|
| ecpri_transport | 100 | 0 | PASS |
| cpri_eth | 100 | 0 | PASS |
| uplane | 100 | 0 | PASS |
| cplane | 100 | 0 | PASS |
| splane | 100 | 0 | PASS |
| mplane | 100 | 0 | PASS |
| beamforming | 100 | 0 | PASS |
| compression | 100 | 0 | PASS |
| prach | 100 | 0 | PASS |
| mimo_massive | 100 | 0 | PASS |
| bwp | 100 | 0 | PASS |
| mmwave | 100 | 0 | PASS |
| laa | 100 | 0 | PASS |
Lane-2B total: **13/13 PASS** — each 100 txns, 0 errors, ** TEST PASSED **. Native constraints honored (scoreboard 0 errors), covergroup illegal_bins never hit.

# 4a. RAL — uvm_reg register model on Verilator 5.050 (executed)
Command: `make ral SIM=verilator5050`. Native UVM register model, front-door access via adapter + auto-predict.
| Test | Registers | Ops | UVM_ERROR | UVM_FATAL | status |
|---|---|---|---|---|---|
| oran_ral_test | 5 (ctrl/version/numant/comp/bwp) | 163 | 0 | 0 | PASS |

Checks executed: reset-value mirror · RO version read-back (0x0A02) · 20× RW randomize/update/read/mirror-compare per RW register · RO write-protect. Access policies (RW/RO) enforced and confirmed. RAL total: **1/1 PASS**.

# 5. Coverage summary
- Functional: 100% merged (smoke+random+directed+corner), COV-### bins per field.
- Code: stmt 100% · DUT branch 100% (TB-defensive waived) · toggle reported.
- Native covergroup (Lane-2B): coverpoints + cross + illegal_bins sampled in-sim.
- Reports: docs/FULL_COVERAGE_REPORT.md, docs/COVERAGE_DASHBOARD.html, regression/code_cov.json.

# 6. Simulator portability (executed)
| Simulator | Lane-1 | Lane-2A | Lane-2B | RAL |
|---|---|---|---|---|
| Verilator 5.020 | PASS 1470/1470 | PASS 39/39 | N/A | N/A |
| Verilator 5.050 | PASS | PASS | **PASS 13/13** | **PASS 1/1** |
| VCS / Questa / Xcelium | NOT_RUN | NOT_RUN | source-ready (same UVM) | source-ready (same UVM) |

# 7. Open items (non-blocking)
GAP-ORAN-001 GATE-0 DERIVED (pin R004-v16). GAP-ORAN-002 commercial-sim optional. GAP-003/004 RESOLVED.