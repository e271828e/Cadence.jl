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

## Open points for the user

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
