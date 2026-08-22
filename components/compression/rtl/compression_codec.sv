// ======================================================================
//  File   : components/compression/rtl/compression_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : compression block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module compression_codec import compression_pkg::*; (
  input compression_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output compression_hdr_t out_hdr);
  assign wire_hdr = compression_pack(in_hdr);
  assign out_hdr  = compression_unpack(rx_wire);
endmodule
