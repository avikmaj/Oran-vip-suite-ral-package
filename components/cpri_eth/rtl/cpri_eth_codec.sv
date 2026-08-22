// ======================================================================
//  File   : components/cpri_eth/rtl/cpri_eth_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : cpri_eth block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module cpri_eth_codec import cpri_eth_pkg::*; (
  input cpri_eth_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output cpri_eth_hdr_t out_hdr);
  assign wire_hdr = cpri_eth_pack(in_hdr);
  assign out_hdr  = cpri_eth_unpack(rx_wire);
endmodule
