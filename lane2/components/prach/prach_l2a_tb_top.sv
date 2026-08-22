// ======================================================================
//  File   : lane2/components/prach/prach_l2a_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : prach Lane-2A UVM-subset top: factory registration + muvm_root::run_test.
// ======================================================================
module prach_l2a_tb_top;
  import muvm_pkg::*; import prach_l2a_pkg::*;
  muvm_creator_t #(prach_test) c_test;
  muvm_creator_t #(prach_env) c_env;
  muvm_creator_t #(prach_agent) c_agent;
  muvm_creator_t #(prach_sqr) c_sqr;
  muvm_creator_t #(prach_driver) c_driver;
  muvm_creator_t #(prach_scoreboard) c_scoreboard;
  initial begin
    c_test=new(); muvm_factory::register("prach_test", c_test);
    c_env=new(); muvm_factory::register("prach_env", c_env);
    c_agent=new(); muvm_factory::register("prach_agent", c_agent);
    c_sqr=new(); muvm_factory::register("prach_sqr", c_sqr);
    c_driver=new(); muvm_factory::register("prach_driver", c_driver);
    c_scoreboard=new(); muvm_factory::register("prach_scoreboard", c_scoreboard);
    muvm_root::run_test("prach_test");
    $finish;
  end
endmodule
