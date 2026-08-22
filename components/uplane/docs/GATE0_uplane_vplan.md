# GATE 0 vplan — uplane (DERIVED)
Spec: O-RAN.WG4.CUS §7 U-plane Section Types 1/3/5/6
Fields (64b header): version, section_type, numerology, start_prb, num_prb, symbol_id, comp_type, comp_bits, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): ['start_prb + num_prb <= 275']
Coverage COV-###: COV-002:section_type, COV-003:numerology, COV-005:num_prb, COV-007:comp_type, COV-009:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
