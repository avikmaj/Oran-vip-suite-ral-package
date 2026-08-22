# GATE 0 vplan — ecpri_transport (DERIVED)
Spec: eCPRI v2.0 §3.1 common header + §3.2 Type-0 IQ
Fields (64b header): version, rsvd, concat, msg_type, payload_size, pc_id, seq_id, e_bit, sub_seq
Cross-constraints (Z3-enforced, SV cannot solve): none
Coverage COV-###: COV-003:concat, COV-004:msg_type, COV-005:payload_size, COV-007:seq_id, COV-008:e_bit
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
