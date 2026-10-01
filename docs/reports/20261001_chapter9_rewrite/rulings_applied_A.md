# Rulings applied to A1, A2 and S94

The owner accepted every recommendation in groups 2 and 5 of
`rulings_batch.md`, ruling the discussed items as follows. R15 scopes "per
leaf" to concrete entries, as D-236's Position does. R60 fixes each name after
checking its meaning at the source. This file logs the edits made to units A1,
A2 and S94 on 2026-10-01.

Lines are `new.md` lines after the edits. The scripts are
`units/A1/rulings_applied_A1.py`, `units/A2/rulings_applied_A2.py` and
`units/S94/rulings_applied_S94.py`. The inventory updates are in
`units/A1/rulings_inventory_A1.py` and `units/A2/rulings_inventory_A2.py`.
The pre-edit copies are `units/<U>/new_prerulings.md` and
`units/<U>/inventory_prerulings.json`. After the edits, `check9.py check A1`
and `check A2` both print "checks failed: 0". Bold spans are unchanged: A1
has 10 and A2 has 17. No edit added bold.

Changed claims are tagged `"R"` with `"ruling"` in each unit's
`inventory.json`. The added sentences of R14, R20 and R22 are listed in
`"added"` and in `"ruled_additions"`.

## A1

**R13** (A1 6–7, claim A1-003)
- Before: "absolute rate divisors, the flat state layout and the root inputs"
- After: "the anchor-relative rate triples, the nominal activation's flat state
  layout and the root inputs"
- Source: A2 73–80, "`Structure`'s timing tables are anchor-relative" and "the
  `(anchor, m, c)` triples" (D-186). S94 103–107: each activation entry "holds
  layouts", and "The nominal `Float64` entry is one key in the activation
  dictionary like any other" (D-253 b5). The state layout is laid out per
  activation (S94 19–20). The build does produce the nominal activation (D-259
  b1), so the layout stays in the list and is now attributed to it.
- Not changed: "the typed signal table" in the same list is also an
  activation's product (S94 11–17 re-types the cells per activation). I left
  it, since the ruling named only the layout.

**R10** (A1 40, claim A1-018, newcites §9.3)
- Before: "the stage functions, guards and handlers, at `Float64`"
- After: "every user function once, at `Float64` ([§9.3][s9-3])"
- Source: D-050 Position, "All user functions — the `h_*` stages, `f`, `g`,
  guards, handlers and `project` — are probed once, at the initial state and
  nominal `T`". Spec 3813–3814: "probes every user function once". D-259
  Rationale: "B runs the whole nominal chain".

**R14** (A1 69–70, added, ruled_additions)
- Before: none.
- After: "Before a component's class is read, the walk runs the shadowing check
  ([§8.1][s8-1], [D-246][d-246])." It is a paragraph of its own between the
  walk list and "Resolution runs these checks".
- Source: D-246 Position, "The shadowing check is one pass of Stratum A's
  structural walk, run on every component before its class is read." Spec
  1979–1980: "a **shadowing check** in the structural walk ([§9.1][s9-1]), run
  on every component before its class is read ([D-246][d-246])."
- Plain, not bold. D-246's headline (its title) is the fail-fast
  `DeclarationShadowed` kind. Its Spec field lists §8.1 and Appendix C, not
  §9.1, and §8.1 already marks the check bold. If R6 rules that a section
  stating where an entry's check runs takes the bold, this sentence becomes a
  candidate.

**R60, "the classifier"** (A1 83, claim A1-042)
- Before: "**The store form is checked before the classifier and the vocabulary
  checks read the value**"
- After: "**The store form is checked before the tier classifier and the
  vocabulary checks read the value**"
- Source: D-247 Position, "Stratum A checks the form on every primitive before
  the tier classifier and the vocabulary checks read the value". Spec 2873:
  "The tier is read from the store every leaf declares". This departs from the
  batch's proposal, "the class reading (step 2)". Step 2 reads the
  primitive-versus-assembly class. The classifier that reads the store value
  is the tier classifier. D-247's Rationale names it the same way: "a `Symbol`
  from `init_m` failed as `isempty(::Symbol)` in the classifier".

**R15** (A1 97–100, claim A1-054, ruling R15; previously R3)
- Before: "**The walk-compatibility clause is decided by retyping both
  declarations at a marker scalar** and comparing per leaf ([D-263][d-263],
  [D-236][d-236])."
- After: "**…at a marker scalar** and comparing per leaf at a concrete entry, or
  on the whole declaration at an abstract one ([D-263][d-263],
  [D-236][d-236])."
- Source: D-236 Position bullet 1, "A concrete entry is checked leaf by leaf.
  An abstract entry is checked on the whole declaration: the producer's
  declaration, or the same with every pinned leaf lifted, must be `<:` the
  entry."

**R44** (A1 137–139, claim A1-077, where `units/A2/new.md`)
- Before: "…happens in the structure step. Final divisors for anchored entries
  genuinely cannot exist until `Δt_base` binds."
- After: "…happens in the structure step. [§9.2][s9-2] states why final
  divisors wait for that binding."
- Source: A2 87–89 holds the statement with its reason: "When anchors exist,
  final divisors cannot live here. They do not exist until `Δt_base` binds,
  and the same `Build` already backs many `Deployment`s with different grid
  parameters." Claim A1-077 now maps to that span. The pointer sentence is in
  `"added"`.
- A2's part: no text change. A2 87–89 is the statement the survey judged best
  and stays. A2 195's example sentence ("`gnss` is the entry whose divisor
  could not exist before `Δt_base` bound") stays, because the batch proposed
  no change to it.

**R60, "the probing scalar"** (A1 176–178, claim A1-098)
- Before: "is allocated at the probing scalar ([§9.3][s9-3])."
- After: "is allocated at the probing scalar, `Float64` ([§9.3][s9-3])."
- Source: the bullet sits in the nominal evaluation, whose probes run at
  `Float64` (A1 179). D-259 Rationale: "the nominal evaluation consumes one
  evaluation at `Float64`". D-077's annotation: the allocator "takes the scalar
  on both tiers, the discrete side always receiving `Float64`". Spec 3838–3839:
  "`ws` comes from invoking the component's `ws_init` allocator at the probing
  scalar". I used an appositive in place of the proposed "(`Float64` at
  build)", because the sentence already has a parenthetical.

**R11** (A1 190, claim A1-107)
- Before: "Both products are structural."
- After: "`Outputs` and `Events` are structural."
- Source: D-259 b2, "The nominal evaluation's products are names only." The
  third product, the nominal activation, is typed.

**R12** (A1 209–210, claims A1-122 and A1-123)
- Before: "The nominal `Float64` activation runs at build. Other activations
  re-run *only this step* ([§9.4][s9-4])."
- After: "The nominal evaluation produces the `Float64` activation at build.
  Every other activation re-runs *only this step* ([§9.4][s9-4])."
- Source: D-259 b1 (the nominal evaluation outputs "the nominal `Float64`
  `Activation`") and b2 ("Only activation re-runs per scalar"). D-259
  Rationale: "a C run at `Float64` would be the separate pass [§9.1][s9-1]
  forbade." Plain.

## A2

**R17** (A2 17, claim A2-084)
- Before: "`attach!` validates device bindings against it."
- After: "`attach!` validates device bindings against the `Build`."
- Source: D-049 Rejected, "acceptance tests and `attach!` want the contract
  artifact". D-253 Rationale (log 9433–9434): "[D-049]'s reasons for a
  standalone `Build` hold unchanged: … bindings validate against it".

**R18** (A2 21–22, claim A2-053)
- Before: "The first three are the products of [§9.1][s9-1]'s three steps."
- After: "The first three are the products of the structure step and the
  nominal evaluation ([§9.1][s9-1])."
- Source: D-259 Position b1, the structure step outputs `Structure` and the
  nominal evaluation outputs "`Dataflow`, `Events` and the nominal `Float64`
  `Activation`".

**R45** (A2 25, claims A2-058 and A2-060)
- Before: "The `Deployment` constructor takes a `Build` and the grid
  parameters."
- After: "The `Deployment` constructor (below) is the first step."
- Source: A2 95–96 keeps the inputs, "The constructor consumes the `Build` and
  the grid parameters." Both claims now map there. The new sentence is in
  `"added"`.

**R16** (A2 41–43, claim A2-066)
- Before: "The `Build` is immutable and may back any number of `Deployment`s
  and `Simulation`s, concurrently ([D-135][d-135])."
- After: "The `Build` is immutable apart from its lazily filled activation
  dictionary, and may back any number of `Deployment`s and `Simulation`s,
  concurrently ([D-135][d-135])."
- Source: D-135 Position limits the cache to "**immutable compiled
  artifacts** … living on the **`Build`**". S94 103–104: "An entry is
  immutable once constructed".
- Note: the next sentence, from the F6 ruling, again names the activation
  dictionary as the one mutable thing. The two now overlap. I kept both
  because both texts were ruled. A later pass could cut the second to "Its
  insertion is torn-state-free."

**R19** (A2 109, claim A2-013)
- Before: "when only `N_base` is given, today's rule, with the default"
- After: "when only `N_base` is given, with the default"
- Source: survey F4. D-186 added derivation, so "today's" is a stale date.

**R20** (A2 163, added, ruled_additions)
- Before: none.
- After: "Every check whose premise holds runs, and the constructor throws
  once." It is a paragraph of its own after the violation list. Plain: D-229
  is already bold and cited at A2 149–150.
- Source: D-229 Position, last bullet: "Outside the strata the unit is the
  call. Deployment validation ([§9.1][s9-1]) runs every check whose premise
  holds and throws once."

**R21** (A2 169–175): no text change. The reading of two row kinds is
confirmed. D-254 b2: "per discrete component `(D, Φ, Δt)` with anchor and
rate-chain columns, the rate-scope rows". D-261 (log 9887): "The `Schedule` is
its component rows and its rate-scope rows".

**R50** (A2 180–182, claim A2-125)
- Before: "At the root, the declarations are `fcs = Relative(1)` and
  `gnss = Absolute(Hz(50))`."
- After: "The root holds a flight-control scope `fcs` and a GNSS receiver
  `gnss`, declared as `fcs = Relative(1)` and `gnss = Absolute(Hz(50))`."
- Source: spec 5058–5062 (§10.5's code block).
  `sample_times(::Vehicle) = (fcs = Relative(1), gnss = Absolute(Hz(50)))` puts
  both at the root. "# fcs is the enclosing scope of its own children" and
  `sample_times(::FCS)` make `fcs` a scope. `gnss` has no `sample_times` of its
  own and is one of the three discrete components. "FCS" is used for flight
  control elsewhere in the spec (389 "flight-control stack", 5351 "a 50 Hz
  FCS").
- Caveat: "receiver" is the batch's proposed word. The spec never says what
  `gnss` is beyond a discrete component at 50 Hz. "GNSS receiver" is the plain
  reading of the name, but no source states it.

**R22** (A2 209 and 211–214, added, ruled_additions)
- Before: the Rendering list had no `show(::Events)` bullet. The `show(::Build)`
  bullet read "`show(::Build)` and `show(::Deployment)` print a summary and
  their parts."
- After: a new bullet after `show(::Outputs)`: "`show(::Events)` prints each
  component's event names with their policies." The `show(::Build)` bullet adds
  "`show(::Build)`'s parts include the events, and a line of the feedthrough
  edges between the outputs table and the events table. The edges are derived
  from the structure's connections and the producers' stage-2 names." Plain,
  under the bold D-257 lead at A2 200.
- Source: D-257 Position b1 amendments (log 9641–9648): "`Events` renders
  itself too, each component's event names with their policies, and it is
  among the parts `show(::Build)` prints." And: "`show(::Build)` also prints
  the feedthrough edges the execution order was computed over, on a line of its
  own between the outputs table and the events table, derived from the
  structure's connections and the producers' stage-2 names".

**R59** (A2 218–219, claim A2-119, newcites §9.7)
- Before: "and the gate is pure modulo arithmetic."
- After: "and the gate (`(tick − Φ) % D == 0`, [§9.7][s9-7]) is pure modulo
  arithmetic."
- Source: spec 4193 (§9.7): "Gating compiles to `(tick − Φ) % D == 0` inside
  the specialized *boundary* body". The same form is at spec 4849 (§10.5).

## S94

**R54** (S94 59–60 and 126–127; logged in `units/S94/changes.md`)
- Before: "and for interactive fly-around use that cost is pure waste."
- After: "and for interactive use, such as flying the model by hand, that cost
  is pure waste."
- Before: "In the envelope-grid gain-schedule case, hundreds of
  trim-then-linearize points pay those costs once."
- After: "One such loop computes a gain schedule over a grid of flight
  conditions, where hundreds of trim-then-linearize points pay those costs
  once."
- Source: spec 3948–3949, "pure waste for interactive fly-around use". Spec
  3986–3988: "activation-reusing loops, such as the envelope-grid
  gain-schedule case, where hundreds of trim-then-linearize points pay those
  costs once". "One such loop" keeps the old "such as": the case is an
  instance of the loops named in the previous sentence.
