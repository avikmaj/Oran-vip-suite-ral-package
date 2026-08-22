// ======================================================================
//  File   : lane2/components/mimo_massive/mimo_massive_l2a_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : mimo_massive Lane-2A UVM-subset top: factory registration + muvm_root::run_test.
// ======================================================================
module mimo_massive_l2a_tb_top;
  import muvm_pkg::*; import mimo_massive_l2a_pkg::*;
  muvm_creator_t #(mimo_massive_test) c_test;
  muvm_creator_t #(mimo_massive_env) c_env;
  muvm_creator_t #(mimo_massive_agent) c_agent;
  muvm_creator_t #(mimo_massive_sqr) c_sqr;
  muvm_creator_t #(mimo_massive_driver) c_driver;
  muvm_creator_t #(mimo_massive_scoreboard) c_scoreboard;
  initial begin
    c_test=new(); muvm_factory::register("mimo_massive_test", c_test);
    c_env=new(); muvm_factory::register("mimo_massive_env", c_env);
    c_agent=new(); muvm_factory::register("mimo_massive_agent", c_agent);
    c_sqr=new(); muvm_factory::register("mimo_massive_sqr", c_sqr);
    c_driver=new(); muvm_factory::register("mimo_massive_driver", c_driver);
    c_scoreboard=new(); muvm_factory::register("mimo_massive_scoreboard", c_scoreboard);
    muvm_root::run_test("mimo_massive_test");
    $finish;
  end
endmodule
