# Reproduce O-RAN VIP Suite Lane-1 (SI-002 export)
Env: Ubuntu 24.04, Verilator 5.020 (apt), python3 + z3-solver. Run project sandbox_bootstrap.sh first.
Build + GATE2/3 (13):  python3 gen/build_suite.py         # coverage-enabled build (custom sim_main)
Gates 4-8 (100 seeds): RAND=100 python3 gen/run_gates.py
Code coverage (G8):    python3 gen/code_cov.py             # stmt/branch via coverage.dat + waivers
Ledger: regression/{suite_regression.json,gate4_8_report.json,code_cov.json}, signoff/ORAN_VIP_SUITE_SIGNOFF.md
Framework: gen/gen_stim.py (Z3 pos/--neg/--directed) · gen/adjudicate.py · gen/build_suite.py · gen/run_gates.py · gen/code_cov.py
GATE9: 1299/1299=100%. GATE8 code: stmt 100%, DUT branch 100% (TB-defensive waived). GAP-ORAN-003 fixed.
