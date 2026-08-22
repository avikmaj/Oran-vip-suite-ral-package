// ======================================================================
//  File   : components/beamforming/rtl/beamforming_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : beamforming protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package beamforming_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [15:0] beam_id;
    bit [7:0] num_ports;
    bit [3:0] num_layers;
    bit [3:0] section_ext;
    bit [15:0] codebook_idx;
    bit [7:0] seq;
    bit [3:0] rsvd;
  } beamforming_hdr_t;
  function automatic bit [63:0] beamforming_pack(input beamforming_hdr_t h);
    return { h.version, h.beam_id, h.num_ports, h.num_layers, h.section_ext, h.codebook_idx, h.seq, h.rsvd };
  endfunction
  function automatic beamforming_hdr_t beamforming_unpack(input bit [63:0] w);
    beamforming_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 16; h.beam_id = w[p +: 16];
    p -= 8; h.num_ports = w[p +: 8];
    p -= 4; h.num_layers = w[p +: 4];
    p -= 4; h.section_ext = w[p +: 4];
    p -= 16; h.codebook_idx = w[p +: 16];
    p -= 8; h.seq = w[p +: 8];
    p -= 4; h.rsvd = w[p +: 4];
    return h;
  endfunction
  function automatic bit beamforming_is_legal(input beamforming_hdr_t h);
    return (h.version == 1) && (h.beam_id >= 0 && h.beam_id <= 65535) && (h.num_ports==1 || h.num_ports==2 || h.num_ports==4 || h.num_ports==8 || h.num_ports==16 || h.num_ports==32 || h.num_ports==64) && (h.num_layers >= 1 && h.num_layers <= 8) && (h.section_ext==1 || h.section_ext==4 || h.section_ext==5 || h.section_ext==6) && (h.codebook_idx >= 0 && h.codebook_idx <= 65535) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0) && (h.num_layers <= h.num_ports);
  endfunction
  function automatic string beamforming_first_violation(input beamforming_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.beam_id >= 0 && h.beam_id <= 65535)) return "RANGE_beam_id";
    if(!(h.num_ports==1 || h.num_ports==2 || h.num_ports==4 || h.num_ports==8 || h.num_ports==16 || h.num_ports==32 || h.num_ports==64)) return "ENUM_num_ports";
    if(!(h.num_layers >= 1 && h.num_layers <= 8)) return "RANGE_num_layers";
    if(!(h.section_ext==1 || h.section_ext==4 || h.section_ext==5 || h.section_ext==6)) return "ENUM_section_ext";
    if(!(h.codebook_idx >= 0 && h.codebook_idx <= 65535)) return "RANGE_codebook_idx";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    if(!(h.num_layers <= h.num_ports)) return "CROSS_0";
    return "";
  endfunction
endpackage
