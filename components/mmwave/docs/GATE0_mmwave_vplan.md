# GATE 0 vplan — mmwave (DERIVED)
Spec: 3GPP TS38.211 FR2 mmWave n257/n258/n260/n261, mu=2/3/4
Fields (64b header): version, band, numerology, scs, ssb_period, beam_id, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): none
Coverage COV-###: COV-002:band, COV-003:numerology, COV-004:scs, COV-005:ssb_period, COV-007:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
