# GATE 0 vplan — beamforming (DERIVED)
Spec: O-RAN.WG4.CUS Section Ext 1/4/5/6 beamforming
Fields (64b header): version, beam_id, num_ports, num_layers, section_ext, codebook_idx, seq, rsvd
Cross-constraints (Z3-enforced, SV cannot solve): ['num_layers <= num_ports']
Coverage COV-###: COV-003:num_ports, COV-005:section_ext, COV-007:seq
Checks: legality self-check, pack-vs-golden cross-check, round-trip identity.
Reconcile fields vs pinned CUS revision when GAP-ORAN-001 closes.
