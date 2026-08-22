// ======================================================================
//  File   : components/mmwave/tb/mmwave_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mmwave self-checking TESTBENCH (Lane-1): driver applies Z3 stimulus; SCOREBOARD checks legality + pack-vs-golden + round-trip; ASSERTIONS as procedural invariant checks with exercise counters; COVERAGE via COVROW monitor log; UVM-format reporter.
// ======================================================================
module mmwave_tb_top import mmwave_pkg::*; ;
  mmwave_hdr_t m_in, m_out; logic [63:0] m_wire; string vio;
  int unsigned m_txns=0,m_legal=0,m_pack=0,m_rt=0,m_uvm_err=0,m_uvm_fatal=0;
  int unsigned m_exp=0,m_unexp=0,m_ex_leg=0,m_ex_rt=0,m_ex_pack=0,m_neg=0;
  string m_stim; int m_fd,m_rc; longint unsigned r_gold;
  int unsigned r_version;
  int unsigned r_band;
  int unsigned r_numerology;
  int unsigned r_scs;
  int unsigned r_ssb_period;
  int unsigned r_beam_id;
  int unsigned r_seq;
  int unsigned r_rsvd;
  initial begin
    if(!$value$plusargs("STIM=%s",m_stim)) begin $display("UVM_FATAL @ 0: [TB] no +STIM"); m_uvm_fatal++; finish_up(); end
    void'($value$plusargs("NEG=%d",m_neg));
    m_fd=$fopen(m_stim,"r");
    if(m_fd==0) begin $display("UVM_FATAL @ 0: [TB] cannot open %s",m_stim); m_uvm_fatal++; finish_up(); end
    m_rc=$fscanf(m_fd,"%h %h %h %h %h %h %h %h %h",r_version, r_band, r_numerology, r_scs, r_ssb_period, r_beam_id, r_seq, r_rsvd, r_gold);
    while(m_rc==9) begin
      m_in.version = r_version[3:0];
      m_in.band = r_band[2:0];
      m_in.numerology = r_numerology[3:0];
      m_in.scs = r_scs[1:0];
      m_in.ssb_period = r_ssb_period[3:0];
      m_in.beam_id = r_beam_id[15:0];
      m_in.seq = r_seq[7:0];
      m_in.rsvd = r_rsvd[22:0];
      m_wire=mmwave_pack(m_in); m_out=mmwave_unpack(m_wire);
      // format invariants (hold for legal AND illegal field values)
      m_ex_pack++; if(m_wire!==r_gold[63:0]) begin m_pack++; m_uvm_err++; $display("UVM_ERROR @ %0t: [PACK] txn#%0d dut=%016h gold=%016h",$time,m_txns,m_wire,r_gold[63:0]); end
      m_ex_rt++;   if(m_out!==m_in) begin m_rt++; m_uvm_err++; $display("UVM_ERROR @ %0t: [ROUNDTRIP] txn#%0d",$time,m_txns); end
      // legality invariant (GATE 6/7)
      m_ex_leg++; vio=mmwave_first_violation(m_in);
      if(m_neg) begin
        if(vio!="") begin m_exp++; if(m_exp<=5) $display("EXPECTED_FAILURE_DETECTED: %s",vio); end
        else begin m_unexp++; m_uvm_err++; $display("UVM_ERROR @ %0t: [NEG] UNEXPECTED_PASS txn#%0d (illegal stim not detected)",$time,m_txns); end
      end else begin
        if(vio!="") begin m_legal++; m_uvm_err++; $display("UVM_ERROR @ %0t: [LEGALITY] txn#%0d vio=%s",$time,m_txns,vio); end
        $display("COVROW,band=%0d,numerology=%0d,scs=%0d,ssb_period=%0d,seq=%0d", m_out.band, m_out.numerology, m_out.scs, m_out.ssb_period, m_out.seq);
      end
      m_txns++;
      m_rc=$fscanf(m_fd,"%h %h %h %h %h %h %h %h %h",r_version, r_band, r_numerology, r_scs, r_ssb_period, r_beam_id, r_seq, r_rsvd, r_gold);
    end
    $fclose(m_fd); finish_up();
  end
  task automatic finish_up();
    $display("SBSUMMARY,txns=%0d,legal_err=%0d,pack_err=%0d,rt_err=%0d",m_txns,m_legal,m_pack,m_rt);
    $display("SVA_EXERCISED,legality=%0d,roundtrip=%0d,pack=%0d",m_ex_leg,m_ex_rt,m_ex_pack);
    if(m_neg) $display("NEGSUMMARY,expected=%0d,unexpected=%0d",m_exp,m_unexp);
    $display("--- UVM Report Summary ---");
    $display("UVM_INFO :  %0d",m_txns); $display("UVM_WARNING : 0");
    $display("UVM_ERROR : %0d",m_uvm_err); $display("UVM_FATAL : %0d",m_uvm_fatal);
    if(m_neg) begin
      if(m_uvm_err==0 && m_uvm_fatal==0 && m_txns>0 && m_unexp==0 && m_exp==m_txns) $display("** TEST PASSED **");
      else $display("** TEST FAILED **");
    end else begin
      if(m_uvm_err==0 && m_uvm_fatal==0 && m_txns>0) $display("** TEST PASSED **");
      else $display("** TEST FAILED **");
    end
    $finish;
  endtask
endmodule
