# GATE 0 vplan — compression (DERIVED)
Spec: O-RAN.WG4.CUS Annex A IQ compression BFP/mu-law/static
Fields (64b header): version, method, iq_width, comp_width, exponent, block_size, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): ['comp_width <= iq_width']
Coverage COV-###: COV-002:method, COV-004:comp_width, COV-007:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
