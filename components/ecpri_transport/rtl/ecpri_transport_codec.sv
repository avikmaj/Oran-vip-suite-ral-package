// ======================================================================
//  File   : components/ecpri_transport/rtl/ecpri_transport_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : ecpri_transport block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
module ecpri_transport_codec import ecpri_transport_pkg::*; (
  input ecpri_transport_hdr_t in_hdr, output logic [63:0] wire_hdr,
  input logic [63:0] rx_wire, output ecpri_transport_hdr_t out_hdr);
  assign wire_hdr = ecpri_transport_pack(in_hdr);
  assign out_hdr  = ecpri_transport_unpack(rx_wire);
endmodule
