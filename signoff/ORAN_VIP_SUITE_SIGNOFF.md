# O-RAN VIP Suite — Signoff Ledger (Lane-1) · COMPLETE gates 0–9 + code coverage

**Date:** 2026-08-09 · **Lane:** 1 · **Simulator:** Verilator 5.020 (apt) · **Stimulus:** Z3 5.0.0
**Evidence:** regression/suite_regression.json (GATE9 **1299/1299=100%**), gate4_8_report.json,
code_cov.json; per-component components/<slug>/{sim_out,gates}/*.json. Req provenance: **DERIVED**.

## Per-component gate status — 13/13 through GATE 9 + code coverage

| Component | G0 | G1 | G2 | G3 | G4 | G5(100s) | G6 | G7 | G8 func | G8 stmt | G8 br-eff | G9 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ecpri_transport | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| cpri_eth | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| uplane | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| cplane | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| splane | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| mplane | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| beamforming | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| compression | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| prach | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| mimo_massive | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| bwp | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| mmwave | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |
| laa | D | A | PASS | PASS | PASS | PASS | PASS | PASS | 100% | 100% | 100%* | 100% |

D=DERIVED · A=APPROVED · G5 ran **100 seeds** ×300 txns, 100% PASS.
G8 func = merged functional coverage (100%). G8 stmt = code line coverage (100%).
*G8 br-eff = **effective** branch coverage after waiving 6 TB-defensive branches/comp (see waivers);
**0 DUT (pkg/codec) branches uncovered**. Raw branch (incl. TB harness) = 75%.

## Gate evidence semantics (PASS_FAIL_POLICY honored — every STATUS from executed sim)
- G4: literal scan of every TB drive path = 0 hardcoded field literals (stimulus from Z3/spec).
- G5: 100 seeds × 300 txns/comp, 100% PASS.
- G6: negative mode injects guaranteed-illegal txns; EXPECTED_FAILURE_DETECTED 3/3, fired check named; 0 UNEXPECTED_PASS.
- G7: assertion-exercise counters ≥300/seed per invariant family — 0 vacuous.
- G8 functional: 100% merged (directed closure available for wide fields e.g. splane.seq=65535).
- G8 code: coverage.dat via custom sim_main (GAP-ORAN-003 fixed); stmt 100%, DUT branch 100%, TB-defensive waived.
- G9: all tests (smoke+100 random+negative+directed) = **1299/1299 = 100%**.
- Z3 cross-constraint proof: 900 txns/constrained comp, 0 violations.

## Code-coverage waivers (GATE 8 — documented, not silent)
Per component, 6 uncovered branches, all in `<slug>_tb_top.sv` harness, waived as defensive:
`$fatal` no-`+STIM` path; `$fatal` file-open-fail path; positive-mode pack/roundtrip-mismatch
error handlers; NEG-mode UNEXPECTED_PASS handler; `** TEST FAILED **` summary else.
Rationale: these execute only on an infrastructure fault or a DUT/format defect that does not
occur (pack∘unpack is identity; golden agrees). The pack-mismatch branch IS exercised by the
corrupt-golden checker self-test. No DUT-logic branch is uncovered.

## Simulator portability
| Simulator | Status |
|---|---|
| Verilator 5.020 (Lane-1) | PASS (GATE 2–9 + code coverage) |
| VCS | NOT_RUN |
| Questa | NOT_RUN |
| Xcelium | NOT_RUN |
NOT_RUN is not PASS — stated explicitly.

## Verdict & remaining path to ORAN_VIP_SUITE_SIGNED_OFF
**Lane-1 GATE 0–9 + code coverage COMPLETE for all 13 components**, observable and reproducible.
Full **ORAN_VIP_SUITE_SIGNED_OFF** is withheld pending, and ONLY pending:
1. **External re-adjudication** — the adjudication session re-executes this exported bundle on its
   host and enters the gates in the single ledger (per its authority). This doc is the candidate.
2. **B1 — CUS revision pin** (principal): upgrades GATE 0 refs from DERIVED to authoritative
   R004-v16 clause citations. Interim DERIVED accepted per directive.
3. **B2 — Lane-2 UVM venue** (principal, DSim): adds the native-UVM/covergroup/SVA portability
   row (GAP-ORAN-002). Lane-1 signoff does not require it; full-stack portability does.

GATE 10/11 are held (not self-stamped) — the ledger authority is external. No gate inferred.
