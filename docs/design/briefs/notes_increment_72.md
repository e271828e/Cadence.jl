# Notes: increment 72, the "model" vocabulary

Rulings made while the user was away, each with its reason, and the open
points for the user. Brief: `brief_increment_72_model_vocabulary.md`,
written at 7caec22 on 2026-10-10 and launched without the user's review of
the brief, as instructed. Nothing here is pushed.

## Before launch: the classification

Three Opus agents classified every occurrence of `model`, `models`,
`model's` and of `Model` outside backticks in `spec.md` (237), the fifteen
companions (86) and `README.md` (3) at 5215f39, which is byte-identical to
7caec22 for those files, into the brief's seven classes. Their tables are
the session scratchpad's `sweep72_*.tsv`. The result is smaller than the
roadmap's R2 anticipated: nine S3 collisions in the spec, two in the
README, one code variable in a companion, three owner qualifiers for the
predecessor's `Model`, two sentence-initial capitals. Everything else reads
true of the `Model` as well as of the tree, so it stands.

## Rulings made in the user's absence

1. **Every checkpoint gloss site is swept, thirteen instead of four.** The
   user ruled the gloss stale at §12.6, §14, §14.8 and §14.10; the same
   gloss stands at eight more spec sites and once in
   `linearization_walkthrough.md`. A principle reaches every instance. The
   uniform gloss is the glossary entry's own opening, "(the `Model`'s state
   at a frame top as one value)".
2. **`README.md` joins the sweep.** R2 names the spec and the companions.
   The README's line 4 defines a model as a tree of components and line 98
   has the build refuse "the model", the two collisions R2 closes, on the
   first page a newcomer reads. Two sentences.
3. **No new decision entry; one `spec_style.md` bullet.** The roadmap says
   the entries are increment one's and two's, and `decisions_style.md` rule
   2 has a rename sweep the spec and the companions, never the log. The
   rule a future author needs (lowercase "model" names a `Model` or the
   modeled system; a sentence about declaring, wiring or building says the
   component tree or the root) is an authoring rule, so it lands in
   `tools/spec_style.md`'s "Terms" rather than in the log or the glossary.
4. **"component tree" is plain English, not a coinage**, so no glossary
   entry; `component` is the entry, linked where a rewrite creates a
   section's first use.
5. **§1 introduces the type in a second sentence** rather than by a bare
   rewording, since 148 is the one definitional site and a cold reader
   should meet `Model` there.
6. **Borderline rows.** 26 rows the classifiers marked borderline were
   adjudicated. Four are rewritten: 4151 ("The model worked in §10.5 …
   Deploy it", and a `Model` is downstream of the `Deployment`); 4399 with
   4398 for consistency within the paragraph; 9272 and 13676 ("never model
   types", since `Model{T}` is now a type and the payload rule means
   component types). The rest stay S2: "declared in the model" (8593, 9847,
   10565) keeps company with "model code" and "model state", which stay by
   D-060's vocabulary; the persona "model assembler" (3095, 9990) is a
   name; "model root" (3113) is a path term; the compounds ("component
   model", "cost model", "execution model") name a conceptual scheme.
7. **Source comments widened from two sites to thirteen.**
   `notes_increment_70.md` left `build.jl` 1381 and `deployment.jl` 289 to
   this increment; a grep of every file included above `sim.jl` for
   `Simulation` found nine more comment sites D-317 made loose, and two
   test comments. All thirteen are rewritten in stage 2. Comments only, so
   the register does not change.
8. **The brief was committed and launched without the user's review**, as
   the user instructed before leaving.

## Stage 0 (72c6214): accepted deviations and rulings

1. **A twelfth gloss site, §14.2 at 10222.** The brief counted twelve spec
   sites and listed eleven; the grep that built the list missed the one
   where the phrase breaks between "executor's" and "state". The stage found
   it with a whitespace-collapsed search and gave it the uniform gloss,
   under the every-instance principle. Accepted.
2. **The `component` glossary link in §9.4.** "component tree" at 4399 is
   now the section's first use of "component", and the section's only link
   sits later at 4408. The brief's ruling asks for the link at first use;
   its appendix text has none, and the claim inventory forbids other gains.
   Ruled: the link moves to 4399 and leaves 4408, a move, not a gain, under
   `spec_style.md`'s first-use rule. Lands with the review fix, or alone if
   the review is empty.
3. **No link in Part II's intro (1967).** A Part roadmap is not a section;
   it had no `component` link before, and §1 links the term. Nothing added.
4. `spec_style.md`'s "Document structure" says "how a model is authored
   before how it executes". That is the rule's own sense S2 ("a model is
   written as a tree"), so it stands.

## Stage 1 (82c7ace): accepted deviations

1. The Step 1 paragraph of `linearization_walkthrough.md` (465 to 473) was
   re-wrapped to its end, since the longer gloss left a 42-column line
   mid-paragraph. Words unchanged beyond the gloss.
2. The gloss sentence keeps its mid-sentence colon ("beside the run's two
   counters: the state holds …"), the brief's wording and the paragraph's
   own shape before the edit. Routed to the reviewer under
   `spec_style.md`'s "Sentences".

## Stage 2 (f185ba9): accepted deviations

Gate 6068 of 6068, unchanged, as a comments-only commit should leave it.

1. Two of the brief's phrases wrapped across two lines (`build.jl` 1345 to
   1346, `test_discrete.jl` 243 to 244); edited at the line the word sits
   on, reading as the brief's.
2. `deployment.jl` 325, a struct field's trailing comment, stays at 100
   columns beside its siblings; wrapping it would re-lay the field block.

## The cold review

Gate 6068 of 6068 on Julia 1.13.1, battery clean, claim inventory with no
loss and only the brief's allowed gains, all thirteen source comments true
of the code, the queue bullet gone whole. Four findings, three of them in
sentences the brief itself dictated, and two open points raised into fixes.
Probe scripts are in this session's scratchpad under `review/`.

### Rulings made in the user's absence

1. **Appendix B's termination bullet** had become "A component's state
   ends a run", against §13.5 and the glossary ("termination is model
   state"; a stop request is a port whoever publishes it). Ruled: "The
   model's state ends a run", the S5 treatment §10.6 got.
2. **§7.1's parenthetical** grew to twelve words. Ruled: "(the scalar `T`
   at which the build types the tree)", ten.
3. **§1's new sentence** carried two burdens and said the build compiles,
   which happens at `Model` construction. Ruled: "The build checks the
   tree. A simulation runs a `Model` (the tree compiled at one scalar type,
   ready to step) (§9)."
4. **`linearization_walkthrough.md`'s gloss sentence** kept a colon joining
   two clauses. Ruled: split into two sentences.
5. **§14.10's "Today's restore-the-trim dance"** names no owner, the reason
   §14.9's sentence received "Flight.jl's" in stage 0. Ruled the same.
6. **§9.7's "from constructing the model to the end of its first `run!`"**:
   the report harness's total (`probes/measure.jl` 63 to 65) starts at
   `t_build` and leaves the tree's construction out, so "constructing the
   model" read as `Model(...)` understates the interval. Ruled: "from
   calling `build`". The user may prefer another spelling.
7. **Two spec sentences D-317 falsified and the earlier sweeps missed**,
   §9.7's "At `Simulation` construction, and per activation, that data is
   compiled" and §10.2's "Materialization at `Simulation` construction
   binds the stepper": both say `Model` now, the twins of the
   `deployment.jl` comments stage 2 fixed.
8. The §9.4 `component` link moved to the first use (ruling 2 under stage
   0).

### The fix and its verification

61c0f2b, "Fix increment 72's review findings", `spec.md` and
`linearization_walkthrough.md`. The reviewer verified every site on the
delta, the claim inventory (the moved link, two `Simulation` to `Model`
swaps and one gained `build`, nothing else), the style rules and the
battery at 61c0f2b. No code changed after f185ba9, whose gate was the last.

### Open points from the review

- **Appendix C claims a check no code makes.** The `ArgumentInvalid` row
  says the `Model` constructor's keywords validate under the kind, and
  `Model` now heads its call list, but nothing validates `chunk_size` in
  `Model(deployment, T)` or in the sugar forms. Pre-existing (the sentence
  predates this increment); the increment made it visible. A code fix or a
  spec retraction is the user's call.
- §13's "parameterized model types make rendered output unreadable" (9120)
  is FlightCore's lesson and reads as S4 with the owner plain; it now sits
  beside §13.2's rewritten "component types". Kept.
- `sample_time_proposal.md` 303 still reads "At `Simulation` construction";
  a historical proposal, left.
- The §7.1 re-wrap leaves one 66-column line; cosmetic.

## Not pushed

Seven commits on 7caec22: 65262d8 (the brief and these notes), 72c6214,
82c7ace, 4ae873b (notes), f185ba9, 61c0f2b and this notes commit, which
also adds the roadmap's landing paragraph. The user diff-verifies the arc,
rules on the open points, and pushes.

## Open points for the user, from the brief

- §9.7, 4953: "from constructing the model to the end of its first `run!`".
  If the measured interval starts at `build`, "constructing the model" now
  reads as `Model(deployment, T)` and understates it. Left as S2 because
  the report's harness, not the spec, says where the clock starts.
- §8.6, 3113: "relative to the assembly or model root". Kept; "the root
  component" would be plainer if the user wants it.
- `flight_case_studies.md` 273: the parenthetical "(its jobs move into the
  build)" is now only partly true, since Redstone's `Model` holds the
  executor and the status. Kept as a case study's recorded conclusion.
- `linearization_walkthrough.md` 230, the heading "Activations: the model
  compiled at a scalar": an activation is the `Build`'s. Headings are out
  of scope.
- The `Float32` frame-slack point of `notes_increment_71.md` is untouched.
