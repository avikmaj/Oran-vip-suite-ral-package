// ======================================================================
//  File   : components/cpri_eth/rtl/cpri_eth_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : cpri_eth protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package cpri_eth_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [3:0] bw_profile;
    bit [0:0] direction;
    bit [3:0] iq_rate_id;
    bit [3:0] synce_ql;
    bit [9:0] frame_id;
    bit [3:0] subframe;
    bit [0:0] cm_flag;
    bit [7:0] seq;
    bit [23:0] rsvd;
  } cpri_eth_hdr_t;
  function automatic bit [63:0] cpri_eth_pack(input cpri_eth_hdr_t h);
    return { h.version, h.bw_profile, h.direction, h.iq_rate_id, h.synce_ql, h.frame_id, h.subframe, h.cm_flag, h.seq, h.rsvd };
  endfunction
  function automatic cpri_eth_hdr_t cpri_eth_unpack(input bit [63:0] w);
    cpri_eth_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 4; h.bw_profile = w[p +: 4];
    p -= 1; h.direction = w[p +: 1];
    p -= 4; h.iq_rate_id = w[p +: 4];
    p -= 4; h.synce_ql = w[p +: 4];
    p -= 10; h.frame_id = w[p +: 10];
    p -= 4; h.subframe = w[p +: 4];
    p -= 1; h.cm_flag = w[p +: 1];
    p -= 8; h.seq = w[p +: 8];
    p -= 24; h.rsvd = w[p +: 24];
    return h;
  endfunction
  function automatic bit cpri_eth_is_legal(input cpri_eth_hdr_t h);
    return (h.version == 1) && (h.bw_profile==0 || h.bw_profile==1 || h.bw_profile==2 || h.bw_profile==3 || h.bw_profile==4 || h.bw_profile==5) && (h.direction >= 0 && h.direction <= 1) && (h.iq_rate_id >= 0 && h.iq_rate_id <= 15) && (h.synce_ql==0 || h.synce_ql==2 || h.synce_ql==4 || h.synce_ql==11 || h.synce_ql==15) && (h.frame_id >= 0 && h.frame_id <= 1023) && (h.subframe >= 0 && h.subframe <= 9) && (h.cm_flag >= 0 && h.cm_flag <= 1) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0);
  endfunction
  function automatic string cpri_eth_first_violation(input cpri_eth_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.bw_profile==0 || h.bw_profile==1 || h.bw_profile==2 || h.bw_profile==3 || h.bw_profile==4 || h.bw_profile==5)) return "ENUM_bw_profile";
    if(!(h.direction >= 0 && h.direction <= 1)) return "RANGE_direction";
    if(!(h.iq_rate_id >= 0 && h.iq_rate_id <= 15)) return "RANGE_iq_rate_id";
    if(!(h.synce_ql==0 || h.synce_ql==2 || h.synce_ql==4 || h.synce_ql==11 || h.synce_ql==15)) return "ENUM_synce_ql";
    if(!(h.frame_id >= 0 && h.frame_id <= 1023)) return "RANGE_frame_id";
    if(!(h.subframe >= 0 && h.subframe <= 9)) return "RANGE_subframe";
    if(!(h.cm_flag >= 0 && h.cm_flag <= 1)) return "RANGE_cm_flag";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    return "";
  endfunction
endpackage
