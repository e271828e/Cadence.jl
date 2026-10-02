# Unit A verification

**Counts.** Phase 1 found 70 assertions. The inventory has 91 claims: 90 MATCH, 1 DRIFT (minor), 0 LOST. The 5 R2 claims moved to `companion_addition.md` all MATCH there, and A-010 matches D-017's first Rejected bullet. There are 9 ADDED entries. None changes meaning. The R6 clause is a ruled edit, and the `t*` gloss restates old §10.2 and the glossary. `check_unit.py` reports 0 failures.

**DRIFT**
- A-068. Old: "If a future model exceeds *that region*", meaning RK4's stability region at `h = 0.02`. New: "exceeds RK4's stability region", which leaves `h` unstated. This is the result of the R2 move and is harmless. Fix (optional): "exceeds RK4's stability region at the deployed `h`".

**Intro and roadmap.** These are pointers only. "Owns time" and "takes §5.3/§9.7 as given" match Part III's intro (spec 4671–4687). The roadmap's §10.1–§10.7 match the old titles (4691, 4711, 4798, 4810, 5145, 5470, 5684).

**R2.** The moved claims in the companion say the same as old.md. Its intro only restates the three claims and points to them. Nits: (a) "the current codebase" in a Cadence.jl repo is ambiguous, so "Flight.jl's codebase" would be clearer. (b) The heading "Integration today → fixed-step RK4" implies a before/after contrast that the section never draws.

What stayed in §10.2:
- "Every application beyond bare propagation runs periodic avionics" is a domain claim with no codebase or number. It can stay.
- "the RHS costs microseconds and 500 Hz real-time is unremarkable" measures a specific model's RHS, Flight.jl's aircraft model, in the present tense. Cadence has no such model (survey F3). I judge it a Flight.jl fact. Fix: keep "First shrink `h`." and move the cost clause into companion item 3. rulings.md OQ3 already flags this.

**R6.** The new clause is "The seam carries what a backend needs across a frame top through a checkpoint hook, empty for a single-step method". It matches D-274 bullet 1 ("The stepper seam gets a checkpoint hook, empty for a single-step method") plus the `src/stepper.jl` docstring ("what a backend carries across a frame top"). It adds nothing beyond those two sources. Nit: "checkpoint" has a glossary entry but no link here.

**Citations.** Every old citation survives with its claim. The self-citation §10.3 became §10.6, which is correct. I checked each added or replaced citation against its entry:
- D-017 Position carries A-005, A-014, A-041 and A-051.
- D-156 Position carries A-027 (sentence 1 plus "Empty continuous block…") and A-030 ("never invoked with a zero-length buffer").
- D-227 Position carries A-046 ("`RK4` by default").
- D-081 Position carries A-089 ("`t*` is a boundary, not a frame").
- D-147 Position carries A-074.
- D-023 has the reader rule only in Rejected ("Mid-step publication: see §10.3"). rulings.md lists it as Rationale-only. Note that the entry points back at §10.3, so no Position exists.
- §10.6 is right for the step-boundary contract (glossary, spec 11965).

**Bold.** There are 8 bolds, each a headline clause followed by its D-entry. D-017's Position chains four rulings with semicolons (loop; seam; RK4/Heun; `OrdinaryDiffEq` dropped), so its four bolds pass the one-bold-per-ruling test. The one-step clause stays unbolded. D-081 is bold once, in A. B2's three D-081 bolds (event phase runs at `t*`, no drain, not paced) are distinct Rationale-only rulings, not duplicates. B1 restates the `t*` sentence unbolded, but it lacks the D-081 citation that rulings OQ1 expects. Minor: D-227's headline is arguably the `algorithm` keyword, not "RK4 is the default", but the old bold sat there too.

**Moves.** R1, R2, R3 (4704–4706), R6, F13 and M2 are done, and there are no unlisted moves. One deviation: §10.1 puts the two units before the six activities, where survey part C's order was activities first. This serves define-before-use, since the pacing gloss uses "frames".

**Reader-cold names.**
- No FlightCore, FlightPhysics or FlightApps names appear in new.md.
- (3) "the new core" points at the predecessor without naming it, as old.md did. That is fine.
- (2) "periodic avionics" might take a clause.
- The companion's "crosswind-landing demo" is a FlightApps demo named as if known (1). It is not introduced in old.md either.
- Minor: `N = 0` is never defined as the buffer length. The feedthrough tracer is glossed but lacks its glossary link (`#g-feedthrough-tracer` exists).

## Re-check

I re-checked the edits against old.md, the log, the current new.md, companion_addition.md and inventory.json. `check_unit.py` reports 0 failures.

- **A-068.** It now reads "RK4's stability region at the deployed `h`", which matches old.md. Clean.
- **The microseconds clause.** It now sits in the companion's stiffness item, and A-069's second half is mapped there. The meaning is unchanged. Clean.
- **Checkpoint gloss.** The new sentence "A checkpoint is the executor's state at a frame top" matches D-274's Position ("A `Checkpoint{T}` is the executor's state at a frame top") and the glossary. Clean.
- **Feedthrough tracer gloss.** "Classifies a rejected cycle as real or artificial" matches the glossary entry (spec 12889–12892) and §5.6. Clean.
- **Companion retitle.** "Fixed-step RK4 on Flight.jl's aircraft model" and "Flight.jl's codebase" are clean.
- **Periodic-avionics clause.** PROBLEM. The new clause is "(onboard flight systems run as discrete components on a tick grid)". The old text says only "periodic avionics, whose commands are zero-order-held signals". "Discrete components" adds a modeling claim that old.md does not make, and "on a tick grid" repeats "periodic". Fix: "(onboard flight systems)".
- **Demo name and file.** PROBLEM. No file in docs/design/companions/ or docs/reports/ names `crosswind_landing`. None ties the crosswind demo to `c172_demos.jl` or to a C172 either. `c172_demos.jl` appears only for `generic_simulation()` and the scripted pilot. rulings.md cites the Flight.jl source, which lives outside this repo. Fix: "The crosswind-landing demo, a Flight.jl demo of a landing in a crosswind, is the empirical proof."
