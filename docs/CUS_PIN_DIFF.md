# O-RAN VIP — CUS R004-v16 Requirement Pin/Diff Worksheet

**Author:** AVIK MAJUMDAR · **Project:** AVIK VIP FACTORY — O-RAN VIP Suite · GAP-ORAN-001

Purpose: reclassify GATE-0 from **DERIVED** to **PINNED** by diffing every derived requirement against the pinned O-RAN.WG4.CUS.0 **R004-v16.01** text. Fill `PINNED_clause_ref` and `PINNED_legal`, set `STATUS`, then **re-run `gen/audit_dead.py`** — narrowing a field can turn a TRUE_DEAD check live (deadness is width-contingent), and any legal-space change must flow to its checker, coverage bin, and isolated-negative vector.

Total requirements to reconcile: **119** across 13 components (113 field + 6 cross). Machine-fillable copy: `regression/cus_pin_diff.csv`.


## ecpri_transport — eCPRI v2.0 §3.1 common header + §3.2 Type-0 IQ

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-ECPRI_TRANSPORT-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-ECPRI_TRANSPORT-01 / first_violation:CONST_version |
| FR-ECPRI_TRANSPORT-02 | `rsvd` | const | 3 | const=0 |  |  | yes | CHK-ECPRI_TRANSPORT-02 / first_violation:CONST_rsvd |
| FR-ECPRI_TRANSPORT-03 | `concat` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-ECPRI_TRANSPORT-03 / first_violation:RANGE_concat |
| FR-ECPRI_TRANSPORT-04 | `msg_type` | range | 8 | range[0:7] |  |  | yes | CHK-ECPRI_TRANSPORT-04 / first_violation:RANGE_msg_type |
| FR-ECPRI_TRANSPORT-05 | `payload_size` | range | 16 | range[8:1024] |  |  | yes | CHK-ECPRI_TRANSPORT-05 / first_violation:RANGE_payload_size |
| FR-ECPRI_TRANSPORT-06 | `pc_id` | range | 16 | range[0:65535] |  |  | no(TRUE_DEAD) | CHK-ECPRI_TRANSPORT-06 / first_violation:RANGE_pc_id |
| FR-ECPRI_TRANSPORT-07 | `seq_id` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-ECPRI_TRANSPORT-07 / first_violation:RANGE_seq_id |
| FR-ECPRI_TRANSPORT-08 | `e_bit` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-ECPRI_TRANSPORT-08 / first_violation:RANGE_e_bit |
| FR-ECPRI_TRANSPORT-09 | `sub_seq` | range | 7 | range[0:127] |  |  | no(TRUE_DEAD) | CHK-ECPRI_TRANSPORT-09 / first_violation:RANGE_sub_seq |

## cpri_eth — CPRI-over-Ethernet 4G (IEEE1914.3 RoE + eCPRI transport)

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-CPRI_ETH-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-CPRI_ETH-01 / first_violation:CONST_version |
| FR-CPRI_ETH-02 | `bw_profile` | enum | 4 | enum{0,1,2,3,4,5} |  |  | yes | CHK-CPRI_ETH-02 / first_violation:ENUM_bw_profile |
| FR-CPRI_ETH-03 | `direction` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-CPRI_ETH-03 / first_violation:RANGE_direction |
| FR-CPRI_ETH-04 | `iq_rate_id` | range | 4 | range[0:15] |  |  | no(TRUE_DEAD) | CHK-CPRI_ETH-04 / first_violation:RANGE_iq_rate_id |
| FR-CPRI_ETH-05 | `synce_ql` | enum | 4 | enum{0,2,4,11,15} |  |  | yes | CHK-CPRI_ETH-05 / first_violation:ENUM_synce_ql |
| FR-CPRI_ETH-06 | `frame_id` | range | 10 | range[0:1023] |  |  | no(TRUE_DEAD) | CHK-CPRI_ETH-06 / first_violation:RANGE_frame_id |
| FR-CPRI_ETH-07 | `subframe` | range | 4 | range[0:9] |  |  | yes | CHK-CPRI_ETH-07 / first_violation:RANGE_subframe |
| FR-CPRI_ETH-08 | `cm_flag` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-CPRI_ETH-08 / first_violation:RANGE_cm_flag |
| FR-CPRI_ETH-09 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-CPRI_ETH-09 / first_violation:RANGE_seq |
| FR-CPRI_ETH-10 | `rsvd` | const | 24 | const=0 |  |  | yes | CHK-CPRI_ETH-10 / first_violation:CONST_rsvd |

## uplane — O-RAN.WG4.CUS §7 U-plane Section Types 1/3/5/6

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-UPLANE-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-UPLANE-01 / first_violation:CONST_version |
| FR-UPLANE-02 | `section_type` | enum | 4 | enum{1,3,5,6} |  |  | yes | CHK-UPLANE-02 / first_violation:ENUM_section_type |
| FR-UPLANE-03 | `numerology` | range | 4 | range[0:4] |  |  | yes | CHK-UPLANE-03 / first_violation:RANGE_numerology |
| FR-UPLANE-04 | `start_prb` | range | 9 | range[0:273] |  |  | yes | CHK-UPLANE-04 / first_violation:RANGE_start_prb |
| FR-UPLANE-05 | `num_prb` | range | 9 | range[1:275] |  |  | yes | CHK-UPLANE-05 / first_violation:RANGE_num_prb |
| FR-UPLANE-06 | `symbol_id` | range | 4 | range[0:13] |  |  | yes | CHK-UPLANE-06 / first_violation:RANGE_symbol_id |
| FR-UPLANE-07 | `comp_type` | enum | 2 | enum{0,1,2,3} |  |  | no(TRUE_DEAD) | CHK-UPLANE-07 / first_violation:ENUM_comp_type |
| FR-UPLANE-08 | `comp_bits` | range | 5 | range[9:16] |  |  | yes | CHK-UPLANE-08 / first_violation:RANGE_comp_bits |
| FR-UPLANE-09 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-UPLANE-09 / first_violation:RANGE_seq |
| FR-UPLANE-10 | `rsvd` | const | 15 | const=0 |  |  | yes | CHK-UPLANE-10 / first_violation:CONST_rsvd |
| FR-UPLANE-11 | `start_prb + num_prb <= 275` | cross | - | start_prb + num_prb <= 275 |  |  | yes | CHK-UPLANE-cross1 / first_violation:CROSS_0 |

## cplane — O-RAN.WG4.CUS §5 C-plane Section Types 0-8, Ext 1-11

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-CPLANE-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-CPLANE-01 / first_violation:CONST_version |
| FR-CPLANE-02 | `section_type` | range | 4 | range[0:8] |  |  | yes | CHK-CPLANE-02 / first_violation:RANGE_section_type |
| FR-CPLANE-03 | `section_ext` | range | 4 | range[1:11] |  |  | yes | CHK-CPLANE-03 / first_violation:RANGE_section_ext |
| FR-CPLANE-04 | `start_symbol` | range | 4 | range[0:13] |  |  | yes | CHK-CPLANE-04 / first_violation:RANGE_start_symbol |
| FR-CPLANE-05 | `num_symbol` | range | 4 | range[1:14] |  |  | yes | CHK-CPLANE-05 / first_violation:RANGE_num_symbol |
| FR-CPLANE-06 | `num_sections` | enum | 4 | enum{1,2,4,8} |  |  | yes | CHK-CPLANE-06 / first_violation:ENUM_num_sections |
| FR-CPLANE-07 | `beam_id` | range | 16 | range[0:65535] |  |  | no(TRUE_DEAD) | CHK-CPLANE-07 / first_violation:RANGE_beam_id |
| FR-CPLANE-08 | `numerology` | range | 4 | range[0:4] |  |  | yes | CHK-CPLANE-08 / first_violation:RANGE_numerology |
| FR-CPLANE-09 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-CPLANE-09 / first_violation:RANGE_seq |
| FR-CPLANE-10 | `rsvd` | const | 12 | const=0 |  |  | yes | CHK-CPLANE-10 / first_violation:CONST_rsvd |
| FR-CPLANE-11 | `start_symbol + num_symbol <= 14` | cross | - | start_symbol + num_symbol <= 14 |  |  | yes | CHK-CPLANE-cross1 / first_violation:CROSS_0 |

## splane — O-RAN.WG4.CUS §9 S-plane IEEE1588v2 PTP + SyncE

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-SPLANE-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-SPLANE-01 / first_violation:CONST_version |
| FR-SPLANE-02 | `ptp_msg` | enum | 4 | enum{0,1,2,3,4,5} |  |  | yes | CHK-SPLANE-02 / first_violation:ENUM_ptp_msg |
| FR-SPLANE-03 | `clock_state` | enum | 2 | enum{0,1,2,3} |  |  | no(TRUE_DEAD) | CHK-SPLANE-03 / first_violation:ENUM_clock_state |
| FR-SPLANE-04 | `synce_ql` | enum | 4 | enum{0,2,4,11,15} |  |  | yes | CHK-SPLANE-04 / first_violation:ENUM_synce_ql |
| FR-SPLANE-05 | `seq` | range | 16 | range[0:65535] |  |  | no(TRUE_DEAD) | CHK-SPLANE-05 / first_violation:RANGE_seq |
| FR-SPLANE-06 | `timing_err` | range | 12 | range[0:3000] |  |  | yes | CHK-SPLANE-06 / first_violation:RANGE_timing_err |
| FR-SPLANE-07 | `holdover` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-SPLANE-07 / first_violation:RANGE_holdover |
| FR-SPLANE-08 | `rsvd` | const | 21 | const=0 |  |  | yes | CHK-SPLANE-08 / first_violation:CONST_rsvd |

## mplane — O-RAN.WG4.MP M-plane NETCONF/YANG O1

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-MPLANE-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-MPLANE-01 / first_violation:CONST_version |
| FR-MPLANE-02 | `netconf_op` | enum | 3 | enum{0,1,2,3,4} |  |  | yes | CHK-MPLANE-02 / first_violation:ENUM_netconf_op |
| FR-MPLANE-03 | `datastore` | enum | 2 | enum{0,1,2} |  |  | yes | CHK-MPLANE-03 / first_violation:ENUM_datastore |
| FR-MPLANE-04 | `item_id` | range | 16 | range[0:65535] |  |  | no(TRUE_DEAD) | CHK-MPLANE-04 / first_violation:RANGE_item_id |
| FR-MPLANE-05 | `ant_cal` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-MPLANE-05 / first_violation:RANGE_ant_cal |
| FR-MPLANE-06 | `sw_slot` | range | 3 | range[0:7] |  |  | no(TRUE_DEAD) | CHK-MPLANE-06 / first_violation:RANGE_sw_slot |
| FR-MPLANE-07 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-MPLANE-07 / first_violation:RANGE_seq |
| FR-MPLANE-08 | `rsvd` | const | 27 | const=0 |  |  | yes | CHK-MPLANE-08 / first_violation:CONST_rsvd |

## beamforming — O-RAN.WG4.CUS Section Ext 1/4/5/6 beamforming

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-BEAMFORMING-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-BEAMFORMING-01 / first_violation:CONST_version |
| FR-BEAMFORMING-02 | `beam_id` | range | 16 | range[0:65535] |  |  | no(TRUE_DEAD) | CHK-BEAMFORMING-02 / first_violation:RANGE_beam_id |
| FR-BEAMFORMING-03 | `num_ports` | enum | 8 | enum{1,2,4,8,16,32,64} |  |  | yes | CHK-BEAMFORMING-03 / first_violation:ENUM_num_ports |
| FR-BEAMFORMING-04 | `num_layers` | range | 4 | range[1:8] |  |  | yes | CHK-BEAMFORMING-04 / first_violation:RANGE_num_layers |
| FR-BEAMFORMING-05 | `section_ext` | enum | 4 | enum{1,4,5,6} |  |  | yes | CHK-BEAMFORMING-05 / first_violation:ENUM_section_ext |
| FR-BEAMFORMING-06 | `codebook_idx` | range | 16 | range[0:65535] |  |  | no(TRUE_DEAD) | CHK-BEAMFORMING-06 / first_violation:RANGE_codebook_idx |
| FR-BEAMFORMING-07 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-BEAMFORMING-07 / first_violation:RANGE_seq |
| FR-BEAMFORMING-08 | `rsvd` | const | 4 | const=0 |  |  | yes | CHK-BEAMFORMING-08 / first_violation:CONST_rsvd |
| FR-BEAMFORMING-09 | `num_layers <= num_ports` | cross | - | num_layers <= num_ports |  |  | yes | CHK-BEAMFORMING-cross1 / first_violation:CROSS_0 |

## compression — O-RAN.WG4.CUS Annex A IQ compression BFP/mu-law/static

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-COMPRESSION-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-COMPRESSION-01 / first_violation:CONST_version |
| FR-COMPRESSION-02 | `method` | enum | 2 | enum{0,1,2} |  |  | yes | CHK-COMPRESSION-02 / first_violation:ENUM_method |
| FR-COMPRESSION-03 | `iq_width` | const | 5 | const=16 |  |  | yes | CHK-COMPRESSION-03 / first_violation:CONST_iq_width |
| FR-COMPRESSION-04 | `comp_width` | enum | 5 | enum{9,10,11,12,13,14,15,16} |  |  | yes | CHK-COMPRESSION-04 / first_violation:ENUM_comp_width |
| FR-COMPRESSION-05 | `exponent` | range | 4 | range[0:15] |  |  | no(TRUE_DEAD) | CHK-COMPRESSION-05 / first_violation:RANGE_exponent |
| FR-COMPRESSION-06 | `block_size` | range | 8 | range[1:255] |  |  | yes | CHK-COMPRESSION-06 / first_violation:RANGE_block_size |
| FR-COMPRESSION-07 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-COMPRESSION-07 / first_violation:RANGE_seq |
| FR-COMPRESSION-08 | `rsvd` | const | 28 | const=0 |  |  | yes | CHK-COMPRESSION-08 / first_violation:CONST_rsvd |
| FR-COMPRESSION-09 | `comp_width <= iq_width` | cross | - | comp_width <= iq_width |  |  | yes | CHK-COMPRESSION-cross1 / first_violation:CROSS_0 |

## prach — O-RAN.WG4.CUS Section Type 3 PRACH + 3GPP TS38.211 formats

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-PRACH-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-PRACH-01 / first_violation:CONST_version |
| FR-PRACH-02 | `section_type` | const | 4 | const=3 |  |  | yes | CHK-PRACH-02 / first_violation:CONST_section_type |
| FR-PRACH-03 | `format` | enum | 4 | enum{0,1,2,3,4,5,6,7,8,9} |  |  | yes | CHK-PRACH-03 / first_violation:ENUM_format |
| FR-PRACH-04 | `numerology` | range | 4 | range[0:4] |  |  | yes | CHK-PRACH-04 / first_violation:RANGE_numerology |
| FR-PRACH-05 | `fr` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-PRACH-05 / first_violation:RANGE_fr |
| FR-PRACH-06 | `zc_root` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-PRACH-06 / first_violation:RANGE_zc_root |
| FR-PRACH-07 | `occasion` | range | 6 | range[0:63] |  |  | no(TRUE_DEAD) | CHK-PRACH-07 / first_violation:RANGE_occasion |
| FR-PRACH-08 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-PRACH-08 / first_violation:RANGE_seq |
| FR-PRACH-09 | `rsvd` | const | 25 | const=0 |  |  | yes | CHK-PRACH-09 / first_violation:CONST_rsvd |

## mimo_massive — O-RAN.WG4.CUS Sect Ext 5/6 + 3GPP massive MIMO 64T64R

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-MIMO_MASSIVE-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-MIMO_MASSIVE-01 / first_violation:CONST_version |
| FR-MIMO_MASSIVE-02 | `ant_cfg` | enum | 8 | enum{1,2,4,8,16,32,64} |  |  | yes | CHK-MIMO_MASSIVE-02 / first_violation:ENUM_ant_cfg |
| FR-MIMO_MASSIVE-03 | `num_layers` | range | 4 | range[1:8] |  |  | yes | CHK-MIMO_MASSIVE-03 / first_violation:RANGE_num_layers |
| FR-MIMO_MASSIVE-04 | `tdd_cfg` | range | 3 | range[0:6] |  |  | yes | CHK-MIMO_MASSIVE-04 / first_violation:RANGE_tdd_cfg |
| FR-MIMO_MASSIVE-05 | `rank` | range | 4 | range[1:8] |  |  | yes | CHK-MIMO_MASSIVE-05 / first_violation:RANGE_rank |
| FR-MIMO_MASSIVE-06 | `precoder_idx` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-MIMO_MASSIVE-06 / first_violation:RANGE_precoder_idx |
| FR-MIMO_MASSIVE-07 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-MIMO_MASSIVE-07 / first_violation:RANGE_seq |
| FR-MIMO_MASSIVE-08 | `rsvd` | const | 25 | const=0 |  |  | yes | CHK-MIMO_MASSIVE-08 / first_violation:CONST_rsvd |
| FR-MIMO_MASSIVE-09 | `num_layers <= ant_cfg` | cross | - | num_layers <= ant_cfg |  |  | yes | CHK-MIMO_MASSIVE-cross1 / first_violation:CROSS_0 |
| FR-MIMO_MASSIVE-10 | `rank <= num_layers` | cross | - | rank <= num_layers |  |  | yes | CHK-MIMO_MASSIVE-cross2 / first_violation:CROSS_1 |

## bwp — O-RAN.WG4.CUS BWP + 3GPP TS38.211 FR1/FR2 numerology

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-BWP-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-BWP-01 / first_violation:CONST_version |
| FR-BWP-02 | `bwp_id` | range | 2 | range[0:3] |  |  | no(TRUE_DEAD) | CHK-BWP-02 / first_violation:RANGE_bwp_id |
| FR-BWP-03 | `numerology` | range | 4 | range[0:4] |  |  | yes | CHK-BWP-03 / first_violation:RANGE_numerology |
| FR-BWP-04 | `bw_mhz` | enum | 9 | enum{5,10,15,20,25,40,50,60,80,100,200,400} |  |  | yes | CHK-BWP-04 / first_violation:ENUM_bw_mhz |
| FR-BWP-05 | `fr` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-BWP-05 / first_violation:RANGE_fr |
| FR-BWP-06 | `active` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-BWP-06 / first_violation:RANGE_active |
| FR-BWP-07 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-BWP-07 / first_violation:RANGE_seq |
| FR-BWP-08 | `rsvd` | const | 35 | const=0 |  |  | yes | CHK-BWP-08 / first_violation:CONST_rsvd |

## mmwave — 3GPP TS38.211 FR2 mmWave n257/n258/n260/n261, mu=2/3/4

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-MMWAVE-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-MMWAVE-01 / first_violation:CONST_version |
| FR-MMWAVE-02 | `band` | enum | 3 | enum{0,1,2,3} |  |  | yes | CHK-MMWAVE-02 / first_violation:ENUM_band |
| FR-MMWAVE-03 | `numerology` | range | 4 | range[2:4] |  |  | yes | CHK-MMWAVE-03 / first_violation:RANGE_numerology |
| FR-MMWAVE-04 | `scs` | enum | 2 | enum{0,1,2} |  |  | yes | CHK-MMWAVE-04 / first_violation:ENUM_scs |
| FR-MMWAVE-05 | `ssb_period` | enum | 4 | enum{0,1,2,3,4,5} |  |  | yes | CHK-MMWAVE-05 / first_violation:ENUM_ssb_period |
| FR-MMWAVE-06 | `beam_id` | range | 16 | range[0:65535] |  |  | no(TRUE_DEAD) | CHK-MMWAVE-06 / first_violation:RANGE_beam_id |
| FR-MMWAVE-07 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-MMWAVE-07 / first_violation:RANGE_seq |
| FR-MMWAVE-08 | `rsvd` | const | 23 | const=0 |  |  | yes | CHK-MMWAVE-08 / first_violation:CONST_rsvd |

## laa — O-RAN.WG4.CUS Section Type 5 LAA + LBT Cat1-4

| FR | element | kind | w | DERIVED legal | PINNED clause (TODO) | PINNED legal (TODO) | reachable | traces to |
|----|---------|------|---|---------------|----------------------|---------------------|-----------|-----------|
| FR-LAA-01 | `version` | const | 4 | const=1 |  |  | yes | CHK-LAA-01 / first_violation:CONST_version |
| FR-LAA-02 | `section_type` | const | 4 | const=5 |  |  | yes | CHK-LAA-02 / first_violation:CONST_section_type |
| FR-LAA-03 | `lbt_cat` | enum | 3 | enum{1,2,3,4} |  |  | yes | CHK-LAA-03 / first_violation:ENUM_lbt_cat |
| FR-LAA-04 | `lbt_result` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-LAA-04 / first_violation:RANGE_lbt_result |
| FR-LAA-05 | `burst_type` | range | 1 | range[0:1] |  |  | no(TRUE_DEAD) | CHK-LAA-05 / first_violation:RANGE_burst_type |
| FR-LAA-06 | `cap` | range | 2 | range[0:3] |  |  | no(TRUE_DEAD) | CHK-LAA-06 / first_violation:RANGE_cap |
| FR-LAA-07 | `section_ext` | const | 4 | const=3 |  |  | yes | CHK-LAA-07 / first_violation:CONST_section_ext |
| FR-LAA-08 | `seq` | range | 8 | range[0:255] |  |  | no(TRUE_DEAD) | CHK-LAA-08 / first_violation:RANGE_seq |
| FR-LAA-09 | `rsvd` | const | 37 | const=0 |  |  | yes | CHK-LAA-09 / first_violation:CONST_rsvd |

## Procedure

1. For each row, locate the governing clause/table in R004-v16 and record `PINNED_clause_ref`.
2. Enter `PINNED_legal`; set `STATUS=PINNED` if unchanged, `CHANGED` if the legal space moves.
3. For every `CHANGED` row: update `spec.json`, regenerate stimulus/coverage, and re-run `make regress && make mutation && make isoneg && make audit-dead`.
4. Re-audit deadness: a `CHANGED` narrowing may flip `reachable=no(TRUE_DEAD)` to `yes` — that check then MUST appear in the isolated-negative set (kill_iso denominator grows).
5. When all rows are PINNED/CHANGED and clean, reclassify GATE-0 DERIVED→PINNED and close GAP-ORAN-001.
