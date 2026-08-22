// ======================================================================
//  File   : components/prach/rtl/prach_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : prach protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package prach_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [3:0] section_type;
    bit [3:0] format;
    bit [3:0] numerology;
    bit [0:0] fr;
    bit [7:0] zc_root;
    bit [5:0] occasion;
    bit [7:0] seq;
    bit [24:0] rsvd;
  } prach_hdr_t;
  function automatic bit [63:0] prach_pack(input prach_hdr_t h);
    return { h.version, h.section_type, h.format, h.numerology, h.fr, h.zc_root, h.occasion, h.seq, h.rsvd };
  endfunction
  function automatic prach_hdr_t prach_unpack(input bit [63:0] w);
    prach_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 4; h.section_type = w[p +: 4];
    p -= 4; h.format = w[p +: 4];
    p -= 4; h.numerology = w[p +: 4];
    p -= 1; h.fr = w[p +: 1];
    p -= 8; h.zc_root = w[p +: 8];
    p -= 6; h.occasion = w[p +: 6];
    p -= 8; h.seq = w[p +: 8];
    p -= 25; h.rsvd = w[p +: 25];
    return h;
  endfunction
  function automatic bit prach_is_legal(input prach_hdr_t h);
    return (h.version == 1) && (h.section_type == 3) && (h.format==0 || h.format==1 || h.format==2 || h.format==3 || h.format==4 || h.format==5 || h.format==6 || h.format==7 || h.format==8 || h.format==9) && (h.numerology >= 0 && h.numerology <= 4) && (h.fr >= 0 && h.fr <= 1) && (h.zc_root >= 0 && h.zc_root <= 255) && (h.occasion >= 0 && h.occasion <= 63) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0);
  endfunction
  function automatic string prach_first_violation(input prach_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.section_type == 3)) return "CONST_section_type";
    if(!(h.format==0 || h.format==1 || h.format==2 || h.format==3 || h.format==4 || h.format==5 || h.format==6 || h.format==7 || h.format==8 || h.format==9)) return "ENUM_format";
    if(!(h.numerology >= 0 && h.numerology <= 4)) return "RANGE_numerology";
    if(!(h.fr >= 0 && h.fr <= 1)) return "RANGE_fr";
    if(!(h.zc_root >= 0 && h.zc_root <= 255)) return "RANGE_zc_root";
    if(!(h.occasion >= 0 && h.occasion <= 63)) return "RANGE_occasion";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    return "";
  endfunction
endpackage
