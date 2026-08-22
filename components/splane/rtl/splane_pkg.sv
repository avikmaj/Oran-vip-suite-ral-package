// ======================================================================
//  File   : components/splane/rtl/splane_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : splane protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package splane_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [3:0] ptp_msg;
    bit [1:0] clock_state;
    bit [3:0] synce_ql;
    bit [15:0] seq;
    bit [11:0] timing_err;
    bit [0:0] holdover;
    bit [20:0] rsvd;
  } splane_hdr_t;
  function automatic bit [63:0] splane_pack(input splane_hdr_t h);
    return { h.version, h.ptp_msg, h.clock_state, h.synce_ql, h.seq, h.timing_err, h.holdover, h.rsvd };
  endfunction
  function automatic splane_hdr_t splane_unpack(input bit [63:0] w);
    splane_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 4; h.ptp_msg = w[p +: 4];
    p -= 2; h.clock_state = w[p +: 2];
    p -= 4; h.synce_ql = w[p +: 4];
    p -= 16; h.seq = w[p +: 16];
    p -= 12; h.timing_err = w[p +: 12];
    p -= 1; h.holdover = w[p +: 1];
    p -= 21; h.rsvd = w[p +: 21];
    return h;
  endfunction
  function automatic bit splane_is_legal(input splane_hdr_t h);
    return (h.version == 1) && (h.ptp_msg==0 || h.ptp_msg==1 || h.ptp_msg==2 || h.ptp_msg==3 || h.ptp_msg==4 || h.ptp_msg==5) && (h.clock_state==0 || h.clock_state==1 || h.clock_state==2 || h.clock_state==3) && (h.synce_ql==0 || h.synce_ql==2 || h.synce_ql==4 || h.synce_ql==11 || h.synce_ql==15) && (h.seq >= 0 && h.seq <= 65535) && (h.timing_err >= 0 && h.timing_err <= 3000) && (h.holdover >= 0 && h.holdover <= 1) && (h.rsvd == 0);
  endfunction
  function automatic string splane_first_violation(input splane_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.ptp_msg==0 || h.ptp_msg==1 || h.ptp_msg==2 || h.ptp_msg==3 || h.ptp_msg==4 || h.ptp_msg==5)) return "ENUM_ptp_msg";
    if(!(h.clock_state==0 || h.clock_state==1 || h.clock_state==2 || h.clock_state==3)) return "ENUM_clock_state";
    if(!(h.synce_ql==0 || h.synce_ql==2 || h.synce_ql==4 || h.synce_ql==11 || h.synce_ql==15)) return "ENUM_synce_ql";
    if(!(h.seq >= 0 && h.seq <= 65535)) return "RANGE_seq";
    if(!(h.timing_err >= 0 && h.timing_err <= 3000)) return "RANGE_timing_err";
    if(!(h.holdover >= 0 && h.holdover <= 1)) return "RANGE_holdover";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    return "";
  endfunction
endpackage
