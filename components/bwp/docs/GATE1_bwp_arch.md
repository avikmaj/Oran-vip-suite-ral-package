# GATE 1 arch — bwp
seq_item=bwp_hdr_t; CRV=Z3 seeded (constraint model=legal space);
driver=procedural apply; monitor=COVROW; scoreboard=legality+golden+round-trip;
coverage=Python COV-### engine; reporter=UVM-format. Lane-2 delta: native UVM/covergroup/SVA.
