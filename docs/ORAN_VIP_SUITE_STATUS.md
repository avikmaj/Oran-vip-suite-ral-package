# O-RAN VIP Suite — Status (Lane-1, evidence-based)

**Date:** 2026-08-09 · **Simulator:** Verilator 5.020 (apt) · **Stimulus:** Z3 5.0.0 seeded CRV
**Lane:** 1 (sandbox, real PASS evidence) · **Requirements provenance:** DERIVED (O-RAN.WG4.CUS / eCPRI v2.0 / 3GPP TS 38.211), reconcile at CUS pin (GAP-ORAN-001)

## Gate roll-up — 13/13 components PASS GATE 2 (compile) + GATE 3 (smoke, seeds 1/2/3)

| Component | GATE2 | GATE3 | Merged fcov (s1/2/3) | Cross-constraints (Z3-enforced) |
|---|---|---|---|---|
| ecpri_transport | PASS | PASS | 100% (17/17) | — |
| cpri_eth | PASS | PASS | 100% (18/18) | — |
| uplane | PASS | PASS | 100% (20/20) | start_prb+num_prb≤275 |
| cplane | PASS | PASS | 100% (36/36) | start_symbol+num_symbol≤14 |
| splane | PASS | PASS | 95% (19/20) | — |
| mplane | PASS | PASS | 100% (13/13) | — |
| beamforming | PASS | PASS | 100% (14/14) | num_layers≤num_ports |
| compression | PASS | PASS | 100% (14/14) | comp_width≤iq_width |
| prach | PASS | PASS | 100% (20/20) | — |
| mimo_massive | PASS | PASS | 94.1% (16/17) | num_layers≤ant_cfg, rank≤num_layers |
| bwp | PASS | PASS | 100% (28/28) | — |
| mmwave | PASS | PASS | 100% (19/19) | — |
| laa | PASS | PASS | 93.3% (14/15) | — |

Every GATE3 run: 300 txns/seed, uvm_error=0, uvm_fatal=0, `** TEST PASSED **`. STATUS derived from
executed evidence only (adjudicate.py). result.json per component under `components/<slug>/sim_out/`.

## Z3 cross-constraint proof
900 stimulus txns per constrained component, **0 violations** of the cross-field legal bounds —
constraints native SV `randomize()` silently ignores on Verilator 5.020 (measured CONSTRAINTIGN).
The Z3 model is the constraint block; the TB runtime legality self-check is the backstop.

## Honest scope — what is NOT done (tracked, not hidden)
- **GATES 4–11 OPEN** for all components: directed FR tests (GATE4), random L3 (GATE5), negative
  (GATE6), assertion exercise (GATE7), coverage closure ≥95% merged incl. GATE-8 holes below,
  full L5 regression (GATE9), review (GATE10), signoff (GATE11). No component is SIGNED_OFF.
- **Coverage holes (GATE 8):** laa 93.3%, mimo_massive 94.1%, splane 95% — closeable via directed
  seeds / more samples (e.g. rare enum value, 16-bit seq wrap-max). Not silently passed.
- **Lane-2 UVM tier** (factory/config_db/sequences/native covergroup+SVA): authored pattern only,
  NOT_VERIFIED until a venue is accepted (GAP-ORAN-002).
- **code_coverage** field: GAP-ORAN-003 (--binary coverage flush).
- **GATE 0 authoritative** for C/U/S/M-plane components pending CUS revision pin (GAP-ORAN-001);
  current FR models are DERIVED and revision-reconciled on pin.
- **Header-model fidelity:** Lane-1 models each component's 64-bit protocol header (fields, legality,
  cross-constraints, coverage). Deep behavioural layers (scheduling timing T12/T34, beam-weight math,
  compression SNR fidelity, PTP servo, concatenation reassembly) are Lane-2/deferred, tracked per component.

## Reproduce
`python3 gen/build_suite.py [slug...]` regenerates + runs GATE2/3 for all (or named) components.
Single component: `bash components/<slug>/run.sh smoke <seed> 300`. Framework: `gen/gen_stim.py`
(Z3), `gen/adjudicate.py`, `gen/build_suite.py` (specs + SV emitters). Rebuild toolchain each
session via project `sandbox_bootstrap.sh` (fs resets).
