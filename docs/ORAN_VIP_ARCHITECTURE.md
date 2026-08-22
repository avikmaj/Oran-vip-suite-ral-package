# O-RAN VIP Suite — Architecture

## Lane-1 UVM-role mapping (plain-SV subset)
seq_item = <slug>_hdr_t (64-bit protocol header, packed struct).
sequence/CRV = Z3 seeded generator (gen_stim.py) — pos/--neg/--directed.
driver = procedural field-apply in TB. monitor = COVROW emit.
scoreboard = 3 checks: runtime legality self-check, pack-vs-golden cross-check, round-trip identity.
coverage = Python COV-### engine (functional) + verilated coverage.dat (code).
reporter = UVM-format summary; adjudicate.py = truth authority.

## Cross-constraint solving
Z3 enforces cross-field legal bounds the SV simulator cannot (e.g. start_prb+num_prb<=275,
start_symbol+num_symbol<=14, num_layers<=num_ports<=ant_cfg, comp_width<=iq_width, rank<=num_layers).
Proven: 0 violations over 900+ txns per constrained component.

## Lane-2 delta (future, licensed sim / DSim — GAP-ORAN-002)
Native randomize()+{} replaces Z3 pre-gen; native covergroup (cross+illegal_bins) replaces
Python engine; concurrent SVA in bind replaces procedural checkers; UVM factory/config_db/
sequences/uvm_scoreboard replace plain-SV roles. Same FR/COV/SVA IDs; same result.json contract.

## Coverage model
Functional: per-field COV-### bins (enum/bool/wrap/bucket4). Code: line 100%, branch (DUT) 100%,
6 TB-defensive branches/comp waived. Toggle reported (not a GATE-8 criterion).
