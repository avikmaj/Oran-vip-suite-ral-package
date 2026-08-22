# GATE 0 vplan — splane (DERIVED)
Spec: O-RAN.WG4.CUS §9 S-plane IEEE1588v2 PTP + SyncE
Fields (64b header): version, ptp_msg, clock_state, synce_ql, seq, timing_err, holdover, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): none
Coverage COV-###: COV-002:ptp_msg, COV-003:clock_state, COV-004:synce_ql, COV-005:seq, COV-007:holdover
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
