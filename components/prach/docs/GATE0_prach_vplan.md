# GATE 0 vplan — prach (DERIVED)
Spec: O-RAN.WG4.CUS Section Type 3 PRACH + 3GPP TS38.211 formats
Fields (64b header): version, section_type, format, numerology, fr, zc_root, occasion, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): none
Coverage COV-###: COV-003:format, COV-004:numerology, COV-005:fr, COV-008:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
