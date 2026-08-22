// ======================================================================
//  File   : components/mimo_massive/rtl/mimo_massive_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mimo_massive protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package mimo_massive_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [7:0] ant_cfg;
    bit [3:0] num_layers;
    bit [2:0] tdd_cfg;
    bit [3:0] rank;
    bit [7:0] precoder_idx;
    bit [7:0] seq;
    bit [24:0] rsvd;
  } mimo_massive_hdr_t;
  function automatic bit [63:0] mimo_massive_pack(input mimo_massive_hdr_t h);
    return { h.version, h.ant_cfg, h.num_layers, h.tdd_cfg, h.rank, h.precoder_idx, h.seq, h.rsvd };
  endfunction
  function automatic mimo_massive_hdr_t mimo_massive_unpack(input bit [63:0] w);
    mimo_massive_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 8; h.ant_cfg = w[p +: 8];
    p -= 4; h.num_layers = w[p +: 4];
    p -= 3; h.tdd_cfg = w[p +: 3];
    p -= 4; h.rank = w[p +: 4];
    p -= 8; h.precoder_idx = w[p +: 8];
    p -= 8; h.seq = w[p +: 8];
    p -= 25; h.rsvd = w[p +: 25];
    return h;
  endfunction
  function automatic bit mimo_massive_is_legal(input mimo_massive_hdr_t h);
    return (h.version == 1) && (h.ant_cfg==1 || h.ant_cfg==2 || h.ant_cfg==4 || h.ant_cfg==8 || h.ant_cfg==16 || h.ant_cfg==32 || h.ant_cfg==64) && (h.num_layers >= 1 && h.num_layers <= 8) && (h.tdd_cfg >= 0 && h.tdd_cfg <= 6) && (h.rank >= 1 && h.rank <= 8) && (h.precoder_idx >= 0 && h.precoder_idx <= 255) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0) && (h.num_layers <= h.ant_cfg) && (h.rank <= h.num_layers);
  endfunction
  function automatic string mimo_massive_first_violation(input mimo_massive_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.ant_cfg==1 || h.ant_cfg==2 || h.ant_cfg==4 || h.ant_cfg==8 || h.ant_cfg==16 || h.ant_cfg==32 || h.ant_cfg==64)) return "ENUM_ant_cfg";
    if(!(h.num_layers >= 1 && h.num_layers <= 8)) return "RANGE_num_layers";
    if(!(h.tdd_cfg >= 0 && h.tdd_cfg <= 6)) return "RANGE_tdd_cfg";
    if(!(h.rank >= 1 && h.rank <= 8)) return "RANGE_rank";
    if(!(h.precoder_idx >= 0 && h.precoder_idx <= 255)) return "RANGE_precoder_idx";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    if(!(h.num_layers <= h.ant_cfg)) return "CROSS_0";
    if(!(h.rank <= h.num_layers)) return "CROSS_1";
    return "";
  endfunction
endpackage
