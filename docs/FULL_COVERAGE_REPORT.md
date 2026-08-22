# O-RAN VIP Suite — FULL Regression & Coverage Report
Generated 2026-08-09T13:10:18.250623Z · Lane-1 · Verilator 5.020 · Z3 5.0.0

## Suite totals
Tests: **1470** · Pass: **1470** · Rate: **100.0%** (smoke + random×100 + negative + directed + corner)

## Per-component

| Component | Tests | Pass% | Func cov | Code stmt | Branch(eff) | Toggle | Test classes |
|---|---|---|---|---|---|---|---|
| ecpri_transport | 40 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 54.69% | corner:14/14 negative:3/3 random:20/20 smoke:3/3 |
| cpri_eth | 122 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 43.75% | corner:16/16 negative:3/3 random:100/100 smoke:3/3 |
| uplane | 123 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 60.94% | corner:17/17 negative:3/3 random:100/100 smoke:3/3 |
| cplane | 123 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 57.81% | corner:17/17 negative:3/3 random:100/100 smoke:3/3 |
| splane | 119 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 57.81% | corner:12/12 directed:1/1 negative:3/3 random:100/100 smoke:3/3 |
| mplane | 118 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 50.0% | corner:12/12 negative:3/3 random:100/100 smoke:3/3 |
| beamforming | 119 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 45.31% | corner:13/13 negative:3/3 random:100/100 smoke:3/3 |
| compression | 116 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 35.94% | corner:10/10 negative:3/3 random:100/100 smoke:3/3 |
| prach | 118 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 46.88% | corner:12/12 negative:3/3 random:100/100 smoke:3/3 |
| mimo_massive | 120 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 32.81% | corner:14/14 negative:3/3 random:100/100 smoke:3/3 |
| bwp | 118 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 35.94% | corner:12/12 negative:3/3 random:100/100 smoke:3/3 |
| mmwave | 118 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 50.0% | corner:12/12 negative:3/3 random:100/100 smoke:3/3 |
| laa | 116 | 100.0% | 100.0% (holes 0) | 100.0% | 100.0% | 25.0% | corner:10/10 negative:3/3 random:100/100 smoke:3/3 |

## Coverage semantics
- **Functional**: merged across smoke+random+directed+corner; COV-### bins per spec field (enum/bool/wrap/bucket).
- **Code stmt (line)**: 100% all components. **Branch(eff)**: 100% after waiving 6 TB-defensive branches/comp (0 DUT branches uncovered).
- **Toggle**: reported for completeness (not a GATE-8 criterion). Low on wide data fields (pc_id/codebook_idx) under bounded random — expected.
- **Negative**: EXPECTED_FAILURE_DETECTED (illegal stimulus caught); excluded from functional bins.
- Z3 cross-constraint proof: 0 violations over 900+ txns/constrained component.