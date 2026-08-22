# GATE 0 vplan — mplane (DERIVED)
Spec: O-RAN.WG4.MP M-plane NETCONF/YANG O1
Fields (64b header): version, netconf_op, datastore, item_id, ant_cal, sw_slot, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): none
Coverage COV-###: COV-002:netconf_op, COV-003:datastore, COV-005:ant_cal, COV-007:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
