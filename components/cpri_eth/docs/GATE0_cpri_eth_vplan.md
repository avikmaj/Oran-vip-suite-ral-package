# GATE 0 vplan — cpri_eth (DERIVED)
Spec: CPRI-over-Ethernet 4G (IEEE1914.3 RoE + eCPRI transport)
Fields (64b header): version, bw_profile, direction, iq_rate_id, synce_ql, frame_id, subframe, cm_flag, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): none
Coverage COV-###: COV-002:bw_profile, COV-003:direction, COV-005:synce_ql, COV-008:cm_flag, COV-009:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
