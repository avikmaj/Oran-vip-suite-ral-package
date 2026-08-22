// ======================================================================
//  File   : components/ecpri_transport/rtl/ecpri_transport_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : ecpri_transport protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package ecpri_transport_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [2:0] rsvd;
    bit [0:0] concat;
    bit [7:0] msg_type;
    bit [15:0] payload_size;
    bit [15:0] pc_id;
    bit [7:0] seq_id;
    bit [0:0] e_bit;
    bit [6:0] sub_seq;
  } ecpri_transport_hdr_t;
  function automatic bit [63:0] ecpri_transport_pack(input ecpri_transport_hdr_t h);
    return { h.version, h.rsvd, h.concat, h.msg_type, h.payload_size, h.pc_id, h.seq_id, h.e_bit, h.sub_seq };
  endfunction
  function automatic ecpri_transport_hdr_t ecpri_transport_unpack(input bit [63:0] w);
    ecpri_transport_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 3; h.rsvd = w[p +: 3];
    p -= 1; h.concat = w[p +: 1];
    p -= 8; h.msg_type = w[p +: 8];
    p -= 16; h.payload_size = w[p +: 16];
    p -= 16; h.pc_id = w[p +: 16];
    p -= 8; h.seq_id = w[p +: 8];
    p -= 1; h.e_bit = w[p +: 1];
    p -= 7; h.sub_seq = w[p +: 7];
    return h;
  endfunction
  function automatic bit ecpri_transport_is_legal(input ecpri_transport_hdr_t h);
    return (h.version == 1) && (h.rsvd == 0) && (h.concat >= 0 && h.concat <= 1) && (h.msg_type >= 0 && h.msg_type <= 7) && (h.payload_size >= 8 && h.payload_size <= 1024) && (h.pc_id >= 0 && h.pc_id <= 65535) && (h.seq_id >= 0 && h.seq_id <= 255) && (h.e_bit >= 0 && h.e_bit <= 1) && (h.sub_seq >= 0 && h.sub_seq <= 127);
  endfunction
  function automatic string ecpri_transport_first_violation(input ecpri_transport_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    if(!(h.concat >= 0 && h.concat <= 1)) return "RANGE_concat";
    if(!(h.msg_type >= 0 && h.msg_type <= 7)) return "RANGE_msg_type";
    if(!(h.payload_size >= 8 && h.payload_size <= 1024)) return "RANGE_payload_size";
    if(!(h.pc_id >= 0 && h.pc_id <= 65535)) return "RANGE_pc_id";
    if(!(h.seq_id >= 0 && h.seq_id <= 255)) return "RANGE_seq_id";
    if(!(h.e_bit >= 0 && h.e_bit <= 1)) return "RANGE_e_bit";
    if(!(h.sub_seq >= 0 && h.sub_seq <= 127)) return "RANGE_sub_seq";
    return "";
  endfunction
endpackage
