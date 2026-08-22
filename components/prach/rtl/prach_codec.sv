// ======================================================================
//  File   : components/prach/rtl/prach_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : prach block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module prach_codec import prach_pkg::*; (
  input prach_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output prach_hdr_t out_hdr);
  assign wire_hdr = prach_pack(in_hdr);
  assign out_hdr  = prach_unpack(rx_wire);
endmodule
