# GATE 0 vplan — cplane (DERIVED)
Spec: O-RAN.WG4.CUS §5 C-plane Section Types 0-8, Ext 1-11
Fields (64b header): version, section_type, section_ext, start_symbol, num_symbol, num_sections, beam_id, numerology, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): ['start_symbol + num_symbol <= 14']
Coverage COV-###: COV-002:section_type, COV-003:section_ext, COV-005:num_symbol, COV-006:num_sections, COV-008:numerology, COV-009:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
