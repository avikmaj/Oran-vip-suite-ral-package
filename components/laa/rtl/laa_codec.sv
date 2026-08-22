// ======================================================================
//  File   : components/laa/rtl/laa_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : laa block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module laa_codec import laa_pkg::*; (
  input laa_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output laa_hdr_t out_hdr);
  assign wire_hdr = laa_pack(in_hdr);
  assign out_hdr  = laa_unpack(rx_wire);
endmodule
