# GATE 0 vplan — mimo_massive (DERIVED)
Spec: O-RAN.WG4.CUS Sect Ext 5/6 + 3GPP massive MIMO 64T64R
Fields (64b header): version, ant_cfg, num_layers, tdd_cfg, rank, precoder_idx, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): ['num_layers <= ant_cfg', 'rank <= num_layers']
Coverage COV-###: COV-002:ant_cfg, COV-004:tdd_cfg, COV-007:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
