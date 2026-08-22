// ======================================================================
//  File   : lane2/components/laa/laa_l2a_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : laa Lane-2A UVM-subset top: factory registration + muvm_root::run_test.
// ======================================================================
module laa_l2a_tb_top;
  import muvm_pkg::*; import laa_l2a_pkg::*;
  muvm_creator_t #(laa_test) c_test;
  muvm_creator_t #(laa_env) c_env;
  muvm_creator_t #(laa_agent) c_agent;
  muvm_creator_t #(laa_sqr) c_sqr;
  muvm_creator_t #(laa_driver) c_driver;
  muvm_creator_t #(laa_scoreboard) c_scoreboard;
  initial begin
    c_test=new(); muvm_factory::register("laa_test", c_test);
    c_env=new(); muvm_factory::register("laa_env", c_env);
    c_agent=new(); muvm_factory::register("laa_agent", c_agent);
    c_sqr=new(); muvm_factory::register("laa_sqr", c_sqr);
    c_driver=new(); muvm_factory::register("laa_driver", c_driver);
    c_scoreboard=new(); muvm_factory::register("laa_scoreboard", c_scoreboard);
    muvm_root::run_test("laa_test");
    $finish;
  end
endmodule
