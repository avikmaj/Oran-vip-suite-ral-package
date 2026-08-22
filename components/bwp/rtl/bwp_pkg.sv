// ======================================================================
//  File   : components/bwp/rtl/bwp_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : bwp protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package bwp_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [1:0] bwp_id;
    bit [3:0] numerology;
    bit [8:0] bw_mhz;
    bit [0:0] fr;
    bit [0:0] active;
    bit [7:0] seq;
    bit [34:0] rsvd;
  } bwp_hdr_t;
  function automatic bit [63:0] bwp_pack(input bwp_hdr_t h);
    return { h.version, h.bwp_id, h.numerology, h.bw_mhz, h.fr, h.active, h.seq, h.rsvd };
  endfunction
  function automatic bwp_hdr_t bwp_unpack(input bit [63:0] w);
    bwp_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 2; h.bwp_id = w[p +: 2];
    p -= 4; h.numerology = w[p +: 4];
    p -= 9; h.bw_mhz = w[p +: 9];
    p -= 1; h.fr = w[p +: 1];
    p -= 1; h.active = w[p +: 1];
    p -= 8; h.seq = w[p +: 8];
    p -= 35; h.rsvd = w[p +: 35];
    return h;
  endfunction
  function automatic bit bwp_is_legal(input bwp_hdr_t h);
    return (h.version == 1) && (h.bwp_id >= 0 && h.bwp_id <= 3) && (h.numerology >= 0 && h.numerology <= 4) && (h.bw_mhz==5 || h.bw_mhz==10 || h.bw_mhz==15 || h.bw_mhz==20 || h.bw_mhz==25 || h.bw_mhz==40 || h.bw_mhz==50 || h.bw_mhz==60 || h.bw_mhz==80 || h.bw_mhz==100 || h.bw_mhz==200 || h.bw_mhz==400) && (h.fr >= 0 && h.fr <= 1) && (h.active >= 0 && h.active <= 1) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0);
  endfunction
  function automatic string bwp_first_violation(input bwp_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.bwp_id >= 0 && h.bwp_id <= 3)) return "RANGE_bwp_id";
    if(!(h.numerology >= 0 && h.numerology <= 4)) return "RANGE_numerology";
    if(!(h.bw_mhz==5 || h.bw_mhz==10 || h.bw_mhz==15 || h.bw_mhz==20 || h.bw_mhz==25 || h.bw_mhz==40 || h.bw_mhz==50 || h.bw_mhz==60 || h.bw_mhz==80 || h.bw_mhz==100 || h.bw_mhz==200 || h.bw_mhz==400)) return "ENUM_bw_mhz";
    if(!(h.fr >= 0 && h.fr <= 1)) return "RANGE_fr";
    if(!(h.active >= 0 && h.active <= 1)) return "RANGE_active";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    return "";
  endfunction
endpackage
