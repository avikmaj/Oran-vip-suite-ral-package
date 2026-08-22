// ======================================================================
//  File   : components/cplane/rtl/cplane_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : cplane block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module cplane_codec import cplane_pkg::*; (
  input cplane_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output cplane_hdr_t out_hdr);
  assign wire_hdr = cplane_pack(in_hdr);
  assign out_hdr  = cplane_unpack(rx_wire);
endmodule
