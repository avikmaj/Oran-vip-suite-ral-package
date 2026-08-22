// ======================================================================
//  File   : components/mmwave/rtl/mmwave_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mmwave protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package mmwave_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [2:0] band;
    bit [3:0] numerology;
    bit [1:0] scs;
    bit [3:0] ssb_period;
    bit [15:0] beam_id;
    bit [7:0] seq;
    bit [22:0] rsvd;
  } mmwave_hdr_t;
  function automatic bit [63:0] mmwave_pack(input mmwave_hdr_t h);
    return { h.version, h.band, h.numerology, h.scs, h.ssb_period, h.beam_id, h.seq, h.rsvd };
  endfunction
  function automatic mmwave_hdr_t mmwave_unpack(input bit [63:0] w);
    mmwave_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 3; h.band = w[p +: 3];
    p -= 4; h.numerology = w[p +: 4];
    p -= 2; h.scs = w[p +: 2];
    p -= 4; h.ssb_period = w[p +: 4];
    p -= 16; h.beam_id = w[p +: 16];
    p -= 8; h.seq = w[p +: 8];
    p -= 23; h.rsvd = w[p +: 23];
    return h;
  endfunction
  function automatic bit mmwave_is_legal(input mmwave_hdr_t h);
    return (h.version == 1) && (h.band==0 || h.band==1 || h.band==2 || h.band==3) && (h.numerology >= 2 && h.numerology <= 4) && (h.scs==0 || h.scs==1 || h.scs==2) && (h.ssb_period==0 || h.ssb_period==1 || h.ssb_period==2 || h.ssb_period==3 || h.ssb_period==4 || h.ssb_period==5) && (h.beam_id >= 0 && h.beam_id <= 65535) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0);
  endfunction
  function automatic string mmwave_first_violation(input mmwave_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.band==0 || h.band==1 || h.band==2 || h.band==3)) return "ENUM_band";
    if(!(h.numerology >= 2 && h.numerology <= 4)) return "RANGE_numerology";
    if(!(h.scs==0 || h.scs==1 || h.scs==2)) return "ENUM_scs";
    if(!(h.ssb_period==0 || h.ssb_period==1 || h.ssb_period==2 || h.ssb_period==3 || h.ssb_period==4 || h.ssb_period==5)) return "ENUM_ssb_period";
    if(!(h.beam_id >= 0 && h.beam_id <= 65535)) return "RANGE_beam_id";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    return "";
  endfunction
endpackage
