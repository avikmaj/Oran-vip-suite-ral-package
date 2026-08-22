// ======================================================================
//  File   : components/uplane/rtl/uplane_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : uplane protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package uplane_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [3:0] section_type;
    bit [3:0] numerology;
    bit [8:0] start_prb;
    bit [8:0] num_prb;
    bit [3:0] symbol_id;
    bit [1:0] comp_type;
    bit [4:0] comp_bits;
    bit [7:0] seq;
    bit [14:0] rsvd;
  } uplane_hdr_t;
  function automatic bit [63:0] uplane_pack(input uplane_hdr_t h);
    return { h.version, h.section_type, h.numerology, h.start_prb, h.num_prb, h.symbol_id, h.comp_type, h.comp_bits, h.seq, h.rsvd };
  endfunction
  function automatic uplane_hdr_t uplane_unpack(input bit [63:0] w);
    uplane_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 4; h.section_type = w[p +: 4];
    p -= 4; h.numerology = w[p +: 4];
    p -= 9; h.start_prb = w[p +: 9];
    p -= 9; h.num_prb = w[p +: 9];
    p -= 4; h.symbol_id = w[p +: 4];
    p -= 2; h.comp_type = w[p +: 2];
    p -= 5; h.comp_bits = w[p +: 5];
    p -= 8; h.seq = w[p +: 8];
    p -= 15; h.rsvd = w[p +: 15];
    return h;
  endfunction
  function automatic bit uplane_is_legal(input uplane_hdr_t h);
    return (h.version == 1) && (h.section_type==1 || h.section_type==3 || h.section_type==5 || h.section_type==6) && (h.numerology >= 0 && h.numerology <= 4) && (h.start_prb >= 0 && h.start_prb <= 273) && (h.num_prb >= 1 && h.num_prb <= 275) && (h.symbol_id >= 0 && h.symbol_id <= 13) && (h.comp_type==0 || h.comp_type==1 || h.comp_type==2 || h.comp_type==3) && (h.comp_bits >= 9 && h.comp_bits <= 16) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0) && (h.start_prb + h.num_prb <= 275);
  endfunction
  function automatic string uplane_first_violation(input uplane_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.section_type==1 || h.section_type==3 || h.section_type==5 || h.section_type==6)) return "ENUM_section_type";
    if(!(h.numerology >= 0 && h.numerology <= 4)) return "RANGE_numerology";
    if(!(h.start_prb >= 0 && h.start_prb <= 273)) return "RANGE_start_prb";
    if(!(h.num_prb >= 1 && h.num_prb <= 275)) return "RANGE_num_prb";
    if(!(h.symbol_id >= 0 && h.symbol_id <= 13)) return "RANGE_symbol_id";
    if(!(h.comp_type==0 || h.comp_type==1 || h.comp_type==2 || h.comp_type==3)) return "ENUM_comp_type";
    if(!(h.comp_bits >= 9 && h.comp_bits <= 16)) return "RANGE_comp_bits";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    if(!(h.start_prb + h.num_prb <= 275)) return "CROSS_0";
    return "";
  endfunction
endpackage
