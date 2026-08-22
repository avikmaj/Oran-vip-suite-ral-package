// ======================================================================
//  File   : components/compression/rtl/compression_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : compression protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package compression_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [1:0] method;
    bit [4:0] iq_width;
    bit [4:0] comp_width;
    bit [3:0] exponent;
    bit [7:0] block_size;
    bit [7:0] seq;
    bit [27:0] rsvd;
  } compression_hdr_t;
  function automatic bit [63:0] compression_pack(input compression_hdr_t h);
    return { h.version, h.method, h.iq_width, h.comp_width, h.exponent, h.block_size, h.seq, h.rsvd };
  endfunction
  function automatic compression_hdr_t compression_unpack(input bit [63:0] w);
    compression_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 2; h.method = w[p +: 2];
    p -= 5; h.iq_width = w[p +: 5];
    p -= 5; h.comp_width = w[p +: 5];
    p -= 4; h.exponent = w[p +: 4];
    p -= 8; h.block_size = w[p +: 8];
    p -= 8; h.seq = w[p +: 8];
    p -= 28; h.rsvd = w[p +: 28];
    return h;
  endfunction
  function automatic bit compression_is_legal(input compression_hdr_t h);
    return (h.version == 1) && (h.method==0 || h.method==1 || h.method==2) && (h.iq_width == 16) && (h.comp_width==9 || h.comp_width==10 || h.comp_width==11 || h.comp_width==12 || h.comp_width==13 || h.comp_width==14 || h.comp_width==15 || h.comp_width==16) && (h.exponent >= 0 && h.exponent <= 15) && (h.block_size >= 1 && h.block_size <= 255) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0) && (h.comp_width <= h.iq_width);
  endfunction
  function automatic string compression_first_violation(input compression_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.method==0 || h.method==1 || h.method==2)) return "ENUM_method";
    if(!(h.iq_width == 16)) return "CONST_iq_width";
    if(!(h.comp_width==9 || h.comp_width==10 || h.comp_width==11 || h.comp_width==12 || h.comp_width==13 || h.comp_width==14 || h.comp_width==15 || h.comp_width==16)) return "ENUM_comp_width";
    if(!(h.exponent >= 0 && h.exponent <= 15)) return "RANGE_exponent";
    if(!(h.block_size >= 1 && h.block_size <= 255)) return "RANGE_block_size";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    if(!(h.comp_width <= h.iq_width)) return "CROSS_0";
    return "";
  endfunction
endpackage
