# GATE 0 vplan — bwp (DERIVED)
Spec: O-RAN.WG4.CUS BWP + 3GPP TS38.211 FR1/FR2 numerology
Fields (64b header): version, bwp_id, numerology, bw_mhz, fr, active, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): none
Coverage COV-###: COV-002:bwp_id, COV-003:numerology, COV-004:bw_mhz, COV-005:fr, COV-006:active, COV-007:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
