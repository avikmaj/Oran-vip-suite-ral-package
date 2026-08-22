// ======================================================================
//  File   : lane2/lane2b_native/ecpri_transport/ecpri_if.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : Lane-2B concurrent-SVA interface: version/msg/payload/seq-continuity ASSERTIONS + cover.
// ======================================================================
// Lane-2B concurrent SVA (temporal) — requires event-driven UVM sim.
interface ecpri_if(input logic clk, input logic rst_n);
  logic [3:0]  version;
  logic [7:0]  msg_type;
  logic [7:0]  seq_id;
  logic [15:0] payload_size;
  logic        valid;
  // Concurrent temporal properties (Verilator concurrent-SVA is limited; venue runs these)
  property p_version;   @(posedge clk) disable iff(!rst_n) valid |-> version == 4'h1; endproperty
  property p_msgtype;   @(posedge clk) disable iff(!rst_n) valid |-> msg_type <= 8'd7; endproperty
  property p_seq_inc;   @(posedge clk) disable iff(!rst_n) (valid ##1 valid) |-> (seq_id == $past(seq_id) + 8'd1); endproperty
  property p_payload;   @(posedge clk) disable iff(!rst_n) valid |-> (payload_size >= 16'd8 && payload_size <= 16'd1024); endproperty
  a_version: assert property(p_version); c_version: cover property(p_version);
  a_msgtype: assert property(p_msgtype); c_msgtype: cover property(p_msgtype);
  a_seq_inc: assert property(p_seq_inc); c_seq_inc: cover property(p_seq_inc);
  a_payload: assert property(p_payload); c_payload: cover property(p_payload);
endinterface
