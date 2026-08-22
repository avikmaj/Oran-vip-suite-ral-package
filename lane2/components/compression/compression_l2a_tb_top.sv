// ======================================================================
//  File   : lane2/components/compression/compression_l2a_tb_top.sv
//  Author : AVIK MAJUMDAR
//  Project: AVIK VIP FACTORY - O-RAN VIP Suite
//  Date   : 2026-08-09
//  Desc   : compression Lane-2A UVM-subset top: factory registration + muvm_root::run_test.
// ======================================================================
module compression_l2a_tb_top;
  import muvm_pkg::*; import compression_l2a_pkg::*;
  muvm_creator_t #(compression_test) c_test;
  muvm_creator_t #(compression_env) c_env;
  muvm_creator_t #(compression_agent) c_agent;
  muvm_creator_t #(compression_sqr) c_sqr;
  muvm_creator_t #(compression_driver) c_driver;
  muvm_creator_t #(compression_scoreboard) c_scoreboard;
  initial begin
    c_test=new(); muvm_factory::register("compression_test", c_test);
    c_env=new(); muvm_factory::register("compression_env", c_env);
    c_agent=new(); muvm_factory::register("compression_agent", c_agent);
    c_sqr=new(); muvm_factory::register("compression_sqr", c_sqr);
    c_driver=new(); muvm_factory::register("compression_driver", c_driver);
    c_scoreboard=new(); muvm_factory::register("compression_scoreboard", c_scoreboard);
    muvm_root::run_test("compression_test");
    $finish;
  end
endmodule
