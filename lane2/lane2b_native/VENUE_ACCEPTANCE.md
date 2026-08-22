# Lane-2B Venue Acceptance (SI-001) — run before Lane-2B evidence counts
A venue (DSim/VCS/Questa/Xcelium) enters service only after the acceptance suite
executes ON it and returns result.json. Verilator cannot host Lane-2B (measured).

Acceptance criteria (all four must produce evidence on the venue):
1. UVM hello-world reaches report_phase with a UVM summary (factory/config_db/phasing).
2. Native randomize() with {} constraints honored + runtime legal-space self-check (0 violations).
3. covergroup with cross + illegal_bins samples (illegal_bins never hit on legal stimulus).
4. One concurrent SVA property exercised non-vacuously (antecedent triggers >=1).

Run (from lane2b_native/ecpri_transport/, UVM_HOME set):
  ./run_lane2b.sh dsim 1        # or vcs | questa | xcelium
Then adjudicate the produced log and return result.json to the ledger.
Priority (SI-001): company farm (Questa/VCS/Xcelium, IP-governance) > DSim Desktop > Questa Intel Starter.

Until a venue returns result.json, Lane-2B STATUS = NOT_VERIFIED (never converted).
The other 12 components are generator-emittable from the same pattern once a venue is accepted.
