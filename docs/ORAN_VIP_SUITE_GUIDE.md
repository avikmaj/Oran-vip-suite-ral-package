# O-RAN VIP Suite — Guide

Unified O-RAN VIP: 13 components covering 4G LTE (CPRI-over-Ethernet) and 5G NR
(eCPRI Split 7.2x). Lane-1 (Verilator 5.020 + Z3) header/transaction-level VIP.

## Layout
- common/pkg — shared eCPRI field model (pathfinder).
- components/<slug>/ — rtl/(pkg,codec), tb/, sim_main.cpp, spec.json, run.sh, docs/(GATE0,GATE1), sim_out/, gates/, corner/.
- gen/ — generator framework (single source of truth = SPECS in build_suite.py).
- regression/ — suite_regression*.json, gate4_8_report.json, code_cov.json.
- docs/ — FULL_COVERAGE_REPORT.md, COVERAGE_DASHBOARD.html, guide, architecture.
- signoff/ — ORAN_VIP_SUITE_SIGNED_OFF.md.

## Run
python3 gen/build_suite.py          # build+compile+GATE2/3 (coverage-enabled)
RAND=100 python3 gen/run_gates.py   # GATE4-8 (directed/random/negative/coverage)
python3 gen/code_cov.py             # GATE8 code coverage (stmt/branch + waivers)
python3 gen/corner.py               # corner/edge cases
python3 gen/report.py               # full regression + coverage reports + dashboard

## Method (Lane-1)
Native randomize()+{} is silently ignored on Verilator 5.020 (measured), so the
Z3 model IS the constraint block; every txn is proven-legal and seed-reproducible.
A runtime legality self-check backstops the CONSTRAINTIGN hazard. Functional coverage
via monitor-log COV-### engine; code coverage via custom sim_main coverage.dat.
Reporter emits UVM-format summary; STATUS from executed evidence only (never inferred).

## Adding a component
Add a spec entry to gen/build_suite.py SPECS (fields<=64b, legal, cross, cover) → rebuild → run.
