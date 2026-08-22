// ======================================================================
//  File   : components/uplane/rtl/uplane_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : uplane block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module uplane_codec import uplane_pkg::*; (
  input uplane_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output uplane_hdr_t out_hdr);
  assign wire_hdr = uplane_pack(in_hdr);
  assign out_hdr  = uplane_unpack(rx_wire);
endmodule
