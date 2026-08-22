// ======================================================================
//  File   : components/bwp/rtl/bwp_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : bwp block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module bwp_codec import bwp_pkg::*; (
  input bwp_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output bwp_hdr_t out_hdr);
  assign wire_hdr = bwp_pack(in_hdr);
  assign out_hdr  = bwp_unpack(rx_wire);
endmodule
