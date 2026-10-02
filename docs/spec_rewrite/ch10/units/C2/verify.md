# C2 verify

**Counts.** 91 inventory claims: 91 MATCH, 0 DRIFT, 0 LOST. Phase 1 found 99 assertions (V1–V99). Every one maps to an old claim or to an allowed gloss. No ADDED item changes meaning. The table, the julia block and the chart are byte-identical to old.md (compared directly). The checker prints `checks failed: 0`.

**Glosses checked.** `fcs` and `gnss` follow §9.2 (spec 3779, "flight-control scope `fcs`", "discrete GNSS component `gnss`"). `contract` matches #g-contract ("a component's declared interface"). For `sample_time_proposal.md`, D-185 says "the proposal remains the worked companion", and the file is in `docs/design/companions/`. ADC is spelled out correctly. "(one declared `Absolute`, below)" matches D-186. The headings that became sentences (C2-009, -024, -039, -056, -066, -078) claim nothing the old headings did not.

**Citations.** Every old citation survives with its claim. D-185 moved from the constructors sentence to the bold validation sentence in the same paragraph, which is fine by adjacency. Every added citation says what rulings.md claims for it. Checked against the log:
- D-187 Position: "the single source of truth for `Δt`". Its annotation points to D-254, and D-254's Position says the `Deployment` "carries the `Schedule`". Both hold.
- D-019, D-185 and D-186: all quoted fields are verbatim and carry their claims.
- **Better entry available.** D-283's Position states two claims that rulings.md calls "Rationale-only" under D-186. Bullet 1 has "`Absolute` severs and re-seeds…, and a nested anchor seeds again". Bullet 5 has "the constraint pool, every anchor period plus every nonzero anchor offset". spec_style prefers the entry whose Position states the ruling. Fix: cite D-283 beside D-186 at C2-048 and at the bold C2-050, and drop those two from the Rationale-only list. Note that D-283's Spec field lacks §10.5.

**Bold.** There are 11 bold spans. None sits on a lead-in, term or definition.
- **V19 "Validation belongs to the structure step" is bold twice.** §9.1 (spec 3504) already bolds "**`sample_times` validation is the structure step's too** (D-185)". The rule "bold where the run is described" puts it there. V19 also shares D-185's single Position sentence with V2. Fix: make V19 plain.
- **D-185 has five bolds.** V2 is the Position. V24, V36 and V98 are three separate semicolon items in the Rationale. These four pass. V19 fails (above).
- **D-186 has four bolds.** V39 is the Position. V49, V56 and V62 are separate semicolon items in the Rationale. All four pass.
- **D-019: V84 and V93 bold one chained Position item.** The item reads "`Δt` arrives as a discrete-bundle field, single source of truth, no stored `Δt`-derived parameters". The mechanical test allows one bold, so V93 should go plain. The other option is to accept the author rule as a separate ruling and flag the log as owing a split. This is the user's decision.
- **The fastest-relative-member convention is correctly plain.** Grepping the log for "fastest" finds only D-186 6542, which presupposes the convention, and D-187 6614. No entry rules it.

**Moves.** M7 and M8 were done as briefed. The stagger block absorbs the example's last sentence. The label order matches the brief. The `Schedule` gloss moved from the stagger block to the first use in Anchors, which the M7 move forced. There are no other moves.

**Reader-cold names.**
- (1) `LeadLag` (V89) is a FlightPhysics type (`lib/FlightPhysics/src/control.jl`). `PID` is one too, but it reads as the generic controller. Fix: "a PID controller's backward-difference coefficients and a lead-lag compensator's Tustin transform".
- (2) "a bus schedule" (V57) needs a clause, for example "an avionics data bus's fixed transmission schedule". "GPS receiver" reads fine.
- (3) None.
- `Vehicle` and `FCS` appear only inside the verbatim code block, and `fcs` is glossed in the prose.

**Other.**
- "the teaching error" (V13) uses a definite article as if the reader already knows the term. The old text did the same, so it stays.
- rulings.md open question 2 still stands: the `[frame](#g-frame)` link depends on what C1 does.

## Re-check

I checked each fix against old.md, the log, the current new.md and inventory.json. The checker still prints `checks failed: 0`.

- **C2-048 and C2-050** now cite D-186 and D-283. The D-283 Position bullets that rulings.md quotes are verbatim and carry both claims. The citations attach only to their own sentences, so their scope did not change. The Rationale-only list no longer names these two claims.
- **C2-021** is plain now. It still cites §9.1, §13.1 and D-185, and that D-185 still covers the constructors sentence by adjacency. "It covers" still points to validation. No clause was dropped.
- **C2-086** is plain and keeps D-019. "that author rule" (C2-088) still points to it. The bundle-field bold (C2-079) remains, so D-019 now has one bold for its Δt item.
- **C2-083** now reads "A PID controller's … a lead-lag compensator's Tustin transform". Both are generic control terms, and no claim was added. Both glosses are in `added`.
- **C2-070** now reads "a data bus's fixed transmission schedule". D-186 says only "a bus schedule". "Fixed" adds a little, but it is the property the sentence relies on. Optional: drop "fixed".
- **Wrap.** new.md line 102 is 102 columns of plain prose ("intrinsic to the assembly as its wiring. Forcing them to the root breaks encapsulation, since the root"). Fix: rewrap the paragraph to 80 columns.

Verdict: clean, apart from the wrap.
