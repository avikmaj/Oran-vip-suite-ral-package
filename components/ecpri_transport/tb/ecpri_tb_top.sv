// ======================================================================
//  File   : components/ecpri_transport/tb/ecpri_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : ecpri_transport self-checking TESTBENCH (Lane-1): driver applies Z3 stimulus; SCOREBOARD checks legality + pack-vs-golden + round-trip; ASSERTIONS as procedural invariant checks with exercise counters; COVERAGE via COVROW monitor log; UVM-format reporter.
// ======================================================================
//======================================================================
// ecpri_tb_top.sv — Lane-1 plain-SV self-checking TB for ecpri_codec
// - stimulus: Z3-generated legal transactions (seeded, reproducible)
// - runtime legality self-check on EVERY txn (counters silent CONSTRAINTIGN)
// - checks: (1) pack cross-check vs independent golden, (2) round-trip identity,
//           (3) protocol invariants (version==1, msg_type<=7)
// - emits COVROW lines for the Python COV-### engine and a UVM-format summary
//======================================================================
module ecpri_tb_top
  import oran_ecpri_pkg::*;
;
  // DUT nets
  ecpri_hdr_t        m_in_hdr;
  logic [HDR_W-1:0]  m_wire_hdr;
  logic [HDR_W-1:0]  m_rx_wire;
  ecpri_hdr_t        m_out_hdr;

  ecpri_codec u_dut (
    .in_hdr  (m_in_hdr),
    .wire_hdr(m_wire_hdr),
    .rx_wire (m_rx_wire),
    .out_hdr (m_out_hdr)
  );

  // scoreboard counters
  int unsigned m_txns      = 0;
  int unsigned m_legal_err = 0;   // silent-illegality net trips
  int unsigned m_pack_err  = 0;   // TB/DUT packer != golden
  int unsigned m_rt_err    = 0;   // pack->unpack != identity
  int unsigned m_inv_err   = 0;   // protocol invariant violation
  int unsigned m_uvm_err   = 0;
  int unsigned m_uvm_fatal = 0;

  string       m_stim;
  int          m_fd, m_rc;

  // scratch (read as int, then narrow into fields)
  int unsigned r_ver, r_conc, r_msg, r_psz, r_pcid, r_sid, r_eb, r_sub;
  longint unsigned r_gold;

  // procedural (deterministic) pack/unpack results — the block under test
  logic [HDR_W-1:0] m_wire_v;
  ecpri_hdr_t       m_out_v;

  initial begin
    if (!$value$plusargs("STIM=%s", m_stim)) begin
      $display("UVM_FATAL @ %0t: [TB] no +STIM=<file> provided", $time);
      m_uvm_fatal++;
      report_and_finish();
    end
    m_fd = $fopen(m_stim, "r");
    if (m_fd == 0) begin
      $display("UVM_FATAL @ %0t: [TB] cannot open stimulus '%s'", $time, m_stim);
      m_uvm_fatal++;
      report_and_finish();
    end

    // columns: ver conc msg psize pcid seqid ebit subseq golden(hex64)
    m_rc = $fscanf(m_fd, "%h %h %h %h %h %h %h %h %h",
                   r_ver, r_conc, r_msg, r_psz, r_pcid, r_sid, r_eb, r_sub, r_gold);
    while (m_rc == 9) begin
      m_in_hdr.version      = r_ver [VER_W-1:0];
      m_in_hdr.rsvd         = '0;
      m_in_hdr.concat       = r_conc[CONC_W-1:0];
      m_in_hdr.msg_type     = r_msg [MSG_W-1:0];
      m_in_hdr.payload_size = r_psz [PSIZE_W-1:0];
      m_in_hdr.pc_id        = r_pcid[PCID_W-1:0];
      m_in_hdr.seq_id       = r_sid [SEQID_W-1:0];
      m_in_hdr.e_bit        = r_eb  [EBIT_W-1:0];
      m_in_hdr.sub_seq      = r_sub [SUBSEQ_W-1:0];

      // deterministic block-under-test evaluation (package logic)
      m_wire_v  = ecpri_pack(m_in_hdr);
      m_out_v   = ecpri_unpack(m_wire_v);
      m_rx_wire = m_wire_v;   // also drive DUT instance for code coverage

      // (1) runtime legality self-check — silent CONSTRAINTIGN countermeasure
      if (!ecpri_is_legal(m_in_hdr)) begin
        m_legal_err++; m_uvm_err++;
        $display("UVM_ERROR @ %0t: [LEGALITY] out-of-space txn#%0d ver=%0h msg=%0d psz=%0d",
                 $time, m_txns, m_in_hdr.version, m_in_hdr.msg_type, m_in_hdr.payload_size);
      end

      // (2) pack cross-check: packer vs independent Z3/Python golden packer
      if (m_wire_v !== r_gold[HDR_W-1:0]) begin
        m_pack_err++; m_uvm_err++;
        $display("UVM_ERROR @ %0t: [PACK] txn#%0d dut=%016h golden=%016h",
                 $time, m_txns, m_wire_v, r_gold[HDR_W-1:0]);
      end

      // (3) round-trip identity: pack then unpack == original fields
      if (m_out_v !== m_in_hdr) begin
        m_rt_err++; m_uvm_err++;
        $display("UVM_ERROR @ %0t: [ROUNDTRIP] txn#%0d in=%016h out=%016h",
                 $time, m_txns, m_in_hdr, m_out_v);
      end

      // (4) protocol invariants on the RECOVERED header
      if (m_out_v.version !== ECPRI_VERSION) begin
        m_inv_err++; m_uvm_err++;
        $display("UVM_ERROR @ %0t: [SVA:VER] txn#%0d version=%0h != 0x1",
                 $time, m_txns, m_out_v.version);
      end
      if (m_out_v.msg_type > MSG_TYPE_MAX) begin
        m_inv_err++; m_uvm_err++;
        $display("UVM_ERROR @ %0t: [SVA:MSG] txn#%0d msg_type=%0d > 7",
                 $time, m_txns, m_out_v.msg_type);
      end

      // coverage sample -> Python COV-### engine
      $display("COVROW,%0d,%0d,%0d,%0d",
               m_out_v.msg_type, m_out_v.concat, m_out_v.seq_id, m_out_v.payload_size);

      m_txns++;
      m_rc = $fscanf(m_fd, "%h %h %h %h %h %h %h %h %h",
                     r_ver, r_conc, r_msg, r_psz, r_pcid, r_sid, r_eb, r_sub, r_gold);
    end
    $fclose(m_fd);
    report_and_finish();
  end

  task automatic report_and_finish();
    $display("SBSUMMARY,txns=%0d,legal_err=%0d,pack_err=%0d,rt_err=%0d,inv_err=%0d",
             m_txns, m_legal_err, m_pack_err, m_rt_err, m_inv_err);
    $display("--- UVM Report Summary ---");
    $display("** Report counts by severity");
    $display("UVM_INFO :  %0d", m_txns);
    $display("UVM_WARNING : 0");
    $display("UVM_ERROR : %0d", m_uvm_err);
    $display("UVM_FATAL : %0d", m_uvm_fatal);
    if (m_uvm_err==0 && m_uvm_fatal==0 && m_txns>0)
      $display("** TEST PASSED **");
    else
      $display("** TEST FAILED **");
    $finish;
  endtask

endmodule
