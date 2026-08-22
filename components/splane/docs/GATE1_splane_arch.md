# GATE 1 arch — splane
seq_item=splane_hdr_t; CRV=Z3 seeded (constraint model=legal space);
driver=procedural apply; monitor=COVROW; scoreboard=legality+golden+round-trip;
coverage=Python COV-### engine; reporter=UVM-format. Lane-2 delta: native UVM/covergroup/SVA.
