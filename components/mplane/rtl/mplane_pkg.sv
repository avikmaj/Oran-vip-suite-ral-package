// ======================================================================
//  File   : components/mplane/rtl/mplane_pkg.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mplane protocol field model (Lane-1): packed 64-bit header struct, explicit pack/unpack, is_legal (per-field+cross), first_violation (negative naming).
// ======================================================================
package mplane_pkg;
  localparam int HDR_W = 64;
  typedef struct packed {
    bit [3:0] version;
    bit [2:0] netconf_op;
    bit [1:0] datastore;
    bit [15:0] item_id;
    bit [0:0] ant_cal;
    bit [2:0] sw_slot;
    bit [7:0] seq;
    bit [26:0] rsvd;
  } mplane_hdr_t;
  function automatic bit [63:0] mplane_pack(input mplane_hdr_t h);
    return { h.version, h.netconf_op, h.datastore, h.item_id, h.ant_cal, h.sw_slot, h.seq, h.rsvd };
  endfunction
  function automatic mplane_hdr_t mplane_unpack(input bit [63:0] w);
    mplane_hdr_t h; int p; p = 64;
    p -= 4; h.version = w[p +: 4];
    p -= 3; h.netconf_op = w[p +: 3];
    p -= 2; h.datastore = w[p +: 2];
    p -= 16; h.item_id = w[p +: 16];
    p -= 1; h.ant_cal = w[p +: 1];
    p -= 3; h.sw_slot = w[p +: 3];
    p -= 8; h.seq = w[p +: 8];
    p -= 27; h.rsvd = w[p +: 27];
    return h;
  endfunction
  function automatic bit mplane_is_legal(input mplane_hdr_t h);
    return (h.version == 1) && (h.netconf_op==0 || h.netconf_op==1 || h.netconf_op==2 || h.netconf_op==3 || h.netconf_op==4) && (h.datastore==0 || h.datastore==1 || h.datastore==2) && (h.item_id >= 0 && h.item_id <= 65535) && (h.ant_cal >= 0 && h.ant_cal <= 1) && (h.sw_slot >= 0 && h.sw_slot <= 7) && (h.seq >= 0 && h.seq <= 255) && (h.rsvd == 0);
  endfunction
  function automatic string mplane_first_violation(input mplane_hdr_t h);
    if(!(h.version == 1)) return "CONST_version";
    if(!(h.netconf_op==0 || h.netconf_op==1 || h.netconf_op==2 || h.netconf_op==3 || h.netconf_op==4)) return "ENUM_netconf_op";
    if(!(h.datastore==0 || h.datastore==1 || h.datastore==2)) return "ENUM_datastore";
    if(!(h.item_id >= 0 && h.item_id <= 65535)) return "RANGE_item_id";
    if(!(h.ant_cal >= 0 && h.ant_cal <= 1)) return "RANGE_ant_cal";
    if(!(h.sw_slot >= 0 && h.sw_slot <= 7)) return "RANGE_sw_slot";
    if(!(h.seq >= 0 && h.seq <= 255)) return "RANGE_seq";
    if(!(h.rsvd == 0)) return "CONST_rsvd";
    return "";
  endfunction
endpackage
