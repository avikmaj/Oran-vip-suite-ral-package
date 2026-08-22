// ======================================================================
//  File   : components/mplane/rtl/mplane_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mplane block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module mplane_codec import mplane_pkg::*; (
  input mplane_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output mplane_hdr_t out_hdr);
  assign wire_hdr = mplane_pack(in_hdr);
  assign out_hdr  = mplane_unpack(rx_wire);
endmodule
