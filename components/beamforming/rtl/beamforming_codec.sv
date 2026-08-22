// ======================================================================
//  File   : components/beamforming/rtl/beamforming_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : beamforming block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module beamforming_codec import beamforming_pkg::*; (
  input beamforming_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output beamforming_hdr_t out_hdr);
  assign wire_hdr = beamforming_pack(in_hdr);
  assign out_hdr  = beamforming_unpack(rx_wire);
endmodule
