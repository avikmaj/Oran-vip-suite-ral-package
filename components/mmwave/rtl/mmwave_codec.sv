// ======================================================================
//  File   : components/mmwave/rtl/mmwave_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mmwave block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module mmwave_codec import mmwave_pkg::*; (
  input mmwave_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output mmwave_hdr_t out_hdr);
  assign wire_hdr = mmwave_pack(in_hdr);
  assign out_hdr  = mmwave_unpack(rx_wire);
endmodule
