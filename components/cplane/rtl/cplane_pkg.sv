// ======================================================================
//  File   : components/cplane/rtl/cplane_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : cplane protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package cplane_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [3:0] section_type;
    bit [3:0] section_ext;
    bit [3:0] start_symbol;
    bit [3:0] num_symbol;
    bit [3:0] num_sections;
    bit [15:0] beam_id;
    bit [3:0] numerology;
    bit [7:0] seq;
    bit [11:0] rsvd;
  } cplane_hdr_t;
  function automatic bit [63:0] cplane_pack(input cplane_hdr_t h);
    return { h.version, h.section_type, h.section_ext, h.start_symbol, h.num_symbol, h.num_sections, h.beam_id, h.numerology, h.seq, h.rsvd };
  endfunction
  function automatic cplane_hdr_t cplane_unpack(input bit [63:0] w);
    cplane_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 4; h.section_type = w[p +: 4];
    p -= 4; h.section_ext = w[p +: 4];
    p -= 4; h.start_symbol = w[p +: 4];
    p -= 4; h.num_symbol = w[p +: 4];
    p -= 4; h.num_sections = w[p +: 4];
    p -= 16; h.beam_id = w[p +: 16];
    p -= 4; h.numerology = w[p +: 4];
    p -= 8; h.seq = w[p +: 8];
    p -= 12; h.rsvd = w[p +: 12];
    return h;
  endfunction
  function automatic bit cplane_is_legal(input cplane_hdr_t h);
    return (h.version == 1) && (h.section_type >= 0 && h.section_type <= 8) && (h.section_ext >= 1 && h.section_ext <= 11) && (h.start_symbol >= 0 && h.start_symbol <= 13) && (h.num_symbol >= 1 && h.num_symbol <= 14) && (h.num_sections==1 || h.num_sections==2 || h.num_sections==4 || h.num_sections==8) && (h.beam_id >= 0 && h.beam_id <= 65535) && (h.numerology >= 0 && h.numerology <= 4) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0) && (h.start_symbol + h.num_symbol <= 14);
  endfunction
  function automatic string cplane_first_violation(input cplane_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.section_type >= 0 && h.section_type <= 8)) return "RANGE_section_type";
    if(!(h.section_ext >= 1 && h.section_ext <= 11)) return "RANGE_section_ext";
    if(!(h.start_symbol >= 0 && h.start_symbol <= 13)) return "RANGE_start_symbol";
    if(!(h.num_symbol >= 1 && h.num_symbol <= 14)) return "RANGE_num_symbol";
    if(!(h.num_sections==1 || h.num_sections==2 || h.num_sections==4 || h.num_sections==8)) return "ENUM_num_sections";
    if(!(h.beam_id >= 0 && h.beam_id <= 65535)) return "RANGE_beam_id";
    if(!(h.numerology >= 0 && h.numerology <= 4)) return "RANGE_numerology";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    if(!(h.start_symbol + h.num_symbol <= 14)) return "CROSS_0";
    return "";
  endfunction
endpackage
