// ======================================================================
//  File   : components/splane/rtl/splane_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : splane block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module splane_codec import splane_pkg::*; (
  input splane_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output splane_hdr_t out_hdr);
  assign wire_hdr = splane_pack(in_hdr);
  assign out_hdr  = splane_unpack(rx_wire);
endmodule
