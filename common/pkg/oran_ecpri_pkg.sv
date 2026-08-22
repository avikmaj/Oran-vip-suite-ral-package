// ======================================================================
//  File   : common/pkg/oran_ecpri_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : O-RAN VIP Suite source (common/pkg/oran_ecpri_pkg.sv).
// ======================================================================
//======================================================================
// oran_ecpri_pkg.sv  — eCPRI transport-layer field model (Lane-1 subset)
// Spec of record: eCPRI Specification v2.0, §3.1 Common Header + Type-0 (IQ).
// Revision-stable across O-RAN.WG4.CUS R003/R004. Requirements: DERIVED.
// Targets the 5.020 plain-SV subset (no UVM, no covergroup, no constraint solver).
//======================================================================
package oran_ecpri_pkg;

  // ---- field widths (eCPRI v2.0 common header + Type-0 payload header) ----
  localparam int VER_W    = 4;   // ecpriVersion
  localparam int RSVD_W   = 3;   // ecpriReserved
  localparam int CONC_W   = 1;   // ecpriConcatenation (C-bit)
  localparam int MSG_W    = 8;   // ecpriMessage
  localparam int PSIZE_W  = 16;  // ecpriPayloadSize (bytes)
  localparam int PCID_W   = 16;  // pc_id (real-time control / eAxC)
  localparam int SEQID_W  = 8;   // seqId
  localparam int EBIT_W   = 1;   // E-bit (last concatenation segment)
  localparam int SUBSEQ_W = 7;   // subSeqId
  localparam int HDR_W = VER_W+RSVD_W+CONC_W+MSG_W+PSIZE_W+PCID_W+SEQID_W+EBIT_W+SUBSEQ_W; // 64

  localparam bit [VER_W-1:0] ECPRI_VERSION = 4'h1;   // eCPRI v2.0: version field = 0x1

  // legal-space bounds (the "constraint model" — mirrored in Z3 generator)
  localparam int PSIZE_MIN = 8;      // Type-0 payload header min
  localparam int PSIZE_MAX = 1024;   // scoped legal max for this VIP

  // eCPRI v2.0 Table 5 message types
  typedef enum bit [MSG_W-1:0] {
    ECPRI_IQ_DATA        = 8'd0,
    ECPRI_BIT_SEQUENCE   = 8'd1,
    ECPRI_RT_CONTROL     = 8'd2,
    ECPRI_GEN_DATA_XFER  = 8'd3,
    ECPRI_REMOTE_MEM_ACC = 8'd4,
    ECPRI_ONEWAY_DELAY   = 8'd5,
    ECPRI_REMOTE_RESET   = 8'd6,
    ECPRI_EVENT_IND      = 8'd7
  } ecpri_msg_e;
  localparam bit [MSG_W-1:0] MSG_TYPE_MAX = 8'd7;

  typedef struct packed {
    bit [VER_W-1:0]    version;
    bit [RSVD_W-1:0]   rsvd;
    bit [CONC_W-1:0]   concat;
    bit [MSG_W-1:0]    msg_type;
    bit [PSIZE_W-1:0]  payload_size;
    bit [PCID_W-1:0]   pc_id;
    bit [SEQID_W-1:0]  seq_id;
    bit [EBIT_W-1:0]   e_bit;
    bit [SUBSEQ_W-1:0] sub_seq;
  } ecpri_hdr_t;

  // ---- explicit pack: fields -> 64-bit wire vector (big-endian field order)
  function automatic bit [HDR_W-1:0] ecpri_pack(input ecpri_hdr_t h);
    return { h.version, h.rsvd, h.concat, h.msg_type, h.payload_size,
             h.pc_id, h.seq_id, h.e_bit, h.sub_seq };
  endfunction

  // ---- explicit unpack: 64-bit wire vector -> fields (inverse slicing)
  function automatic ecpri_hdr_t ecpri_unpack(input bit [HDR_W-1:0] w);
    ecpri_hdr_t h;
    h.version      = w[63:60];
    h.rsvd         = w[59:57];
    h.concat       = w[56];
    h.msg_type     = w[55:48];
    h.payload_size = w[47:32];
    h.pc_id        = w[31:16];
    h.seq_id       = w[15:8];
    h.e_bit        = w[7];
    h.sub_seq      = w[6:0];
    return h;
  endfunction

  // ---- legality predicate (runtime self-check == CONSTRAINTIGN countermeasure)
  function automatic bit ecpri_is_legal(input ecpri_hdr_t h);
    return (h.version == ECPRI_VERSION)
        && (h.msg_type <= MSG_TYPE_MAX)
        && (h.e_bit <= 1'b1)
        && (h.concat <= 1'b1)
        && (h.payload_size >= PSIZE_MIN)
        && (h.payload_size <= PSIZE_MAX);
  endfunction

endpackage
