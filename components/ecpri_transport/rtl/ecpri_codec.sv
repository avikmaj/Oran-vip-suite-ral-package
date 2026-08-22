// ======================================================================
//  File   : components/ecpri_transport/rtl/ecpri_codec.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : ecpri_transport block-under-test: combinational pack/unpack codec (round-trip verified).
// ======================================================================
//======================================================================
// ecpri_codec.sv — block-under-test: eCPRI transport header pack/unpack
// Combinational codec. TB verifies pack->unpack round-trip == identity,
// and cross-checks pack() against an independent Z3/Python golden packer.
//======================================================================
module ecpri_codec
  import oran_ecpri_pkg::*;
(
  input  ecpri_hdr_t        in_hdr,     // fields to transmit
  output logic [HDR_W-1:0]  wire_hdr,   // packed on-wire vector (TX)
  input  logic [HDR_W-1:0]  rx_wire,    // received on-wire vector (RX)
  output ecpri_hdr_t        out_hdr     // recovered fields
);
  assign wire_hdr = ecpri_pack(in_hdr);
  assign out_hdr  = ecpri_unpack(rx_wire);
endmodule
