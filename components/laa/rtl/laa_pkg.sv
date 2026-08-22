// ======================================================================
//  File   : components/laa/rtl/laa_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : laa protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package laa_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [3:0] section_type;
    bit [2:0] lbt_cat;
    bit [0:0] lbt_result;
    bit [0:0] burst_type;
    bit [1:0] cap;
    bit [3:0] section_ext;
    bit [7:0] seq;
    bit [36:0] rsvd;
  } laa_hdr_t;
  function automatic bit [63:0] laa_pack(input laa_hdr_t h);
    return { h.version, h.section_type, h.lbt_cat, h.lbt_result, h.burst_type, h.cap, h.section_ext, h.seq, h.rsvd };
  endfunction
  function automatic laa_hdr_t laa_unpack(input bit [63:0] w);
    laa_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 4; h.section_type = w[p +: 4];
    p -= 3; h.lbt_cat = w[p +: 3];
    p -= 1; h.lbt_result = w[p +: 1];
    p -= 1; h.burst_type = w[p +: 1];
    p -= 2; h.cap = w[p +: 2];
    p -= 4; h.section_ext = w[p +: 4];
    p -= 8; h.seq = w[p +: 8];
    p -= 37; h.rsvd = w[p +: 37];
    return h;
  endfunction
  function automatic bit laa_is_legal(input laa_hdr_t h);
    return (h.version == 1) && (h.section_type == 5) && (h.lbt_cat==1 || h.lbt_cat==2 || h.lbt_cat==3 || h.lbt_cat==4) && (h.lbt_result >= 0 && h.lbt_result <= 1) && (h.burst_type >= 0 && h.burst_type <= 1) && (h.cap >= 0 && h.cap <= 3) && (h.section_ext == 3) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0);
  endfunction
  function automatic string laa_first_violation(input laa_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.section_type == 5)) return "CONST_section_type";
    if(!(h.lbt_cat==1 || h.lbt_cat==2 || h.lbt_cat==3 || h.lbt_cat==4)) return "ENUM_lbt_cat";
    if(!(h.lbt_result >= 0 && h.lbt_result <= 1)) return "RANGE_lbt_result";
    if(!(h.burst_type >= 0 && h.burst_type <= 1)) return "RANGE_burst_type";
    if(!(h.cap >= 0 && h.cap <= 3)) return "RANGE_cap";
    if(!(h.section_ext == 3)) return "CONST_section_ext";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    return "";
  endfunction
endpackage
