// ======================================================================
//  File   : components/mimo_massive/rtl/mimo_massive_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mimo_massive block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module mimo_massive_codec import mimo_massive_pkg::*; (
  input mimo_massive_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output mimo_massive_hdr_t out_hdr);
  assign wire_hdr = mimo_massive_pack(in_hdr);
  assign out_hdr  = mimo_massive_unpack(rx_wire);
endmodule
