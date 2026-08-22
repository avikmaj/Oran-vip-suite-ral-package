# GATE 0 vplan — laa (DERIVED)
Spec: O-RAN.WG4.CUS Section Type 5 LAA + LBT Cat1-4
Fields (64b header): version, section_type, lbt_cat, lbt_result, burst_type, cap, section_ext, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): none
Coverage COV-###: COV-003:lbt_cat, COV-004:lbt_result, COV-005:burst_type, COV-006:cap, COV-008:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
