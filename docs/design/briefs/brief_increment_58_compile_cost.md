# Brief: increment 58, the compile-cost stack (§9.7)

Tip at launch: `d69a33c`, the chapter 9 rewrite with its backlog closed.
Its `src/` and `test/` equal `2556df4`, the tip every measurement here was
taken at. Five stages, the docs first and then four of code, then one cold
review and one fixer. Retires `pending.md`'s "Compile time" bullet (lines
17–24).

Every line number below is `d69a33c`'s. If the tip has moved by launch, find
each passage by wording and say so in the report.

The source is `docs/reports/20261001_compile_cost_reeval/report.md`, called
"the report" below. It measured a stack of four changes that takes a topology
change from 3 to 33 s down to 0.9 to 3.6 s, with bit-identical trajectories,
and that passes the gate. This increment lands that stack as it would be
written by hand: with the house names, with comments, with a regression test
for each change, and with the spec and the register brought up to date.

Design and code are peers, neither subservient. The ruling is the section
"The ruling" below, settled with the user on 2026-10-02: §9.7's compile-cost
block is rewritten to what the report measured. It lands docs-first as
stage 1, and stages 2 to 5 conform the code. If a ruled shape proves wrong at
the keyboard, stop and report rather than deviate silently.

## What the report established

Read its Summary, §2, §4.1 to §4.4, §6's last three paragraphs, §7, §9 and
§11. In short:

1. **A tuple walk by `Base.tail` recursion stops inferring past 32
   elements.** At the tip, a chunk of more than 32 entries, a body of more
   than 32 chunks, or an event set with more than 32 projections, guards or
   handlers loses static dispatch and allocates at every call. A generated
   body with one statement per element has no such limit and also compiles
   faster.
2. **Every hand-off of a chunk copies it.** `Chunk`, `PhaseBody` and
   `EventSet` are immutable and stored inline in the executor, which is
   stored inline in the `Simulation`. Each call that passes one to a
   non-inlined function emits a copy and a GC root per pointer. Those copies
   are most of what `init!` and `run!` compile per topology, and a fifth to a
   third of the loop's runtime. Holding chunks and the event set by reference
   removes them.
3. **`build` re-derives an assembly's child list once per endpoint.** A root
   with N fanned endpoints derives its N children N times. A per-walk cache
   of child lists, beside the face cache, removes it.
4. **The declaration layer compiles again for every component type and every
   root type.** It runs once per build and has no performance requirement.
   Taking components unspecialized cuts `build` from 12 to 40 s to under 1 s
   once the generic machinery is warm.

## The ruling

What §9.7's "Compile cost" block says once stage 1 has rewritten it. Items 1
to 4 are rulings, and so is the set of mitigations in item 9. Each takes
bold once, on its headline clause, with its D-citation in the same sentence,
as the chapter's convention has it (the rewrite report's §3). Items 5 to 8
are description and take no bold; the bold in this list is the brief's own
formatting. `D-289` is the new entry stage 1 adds, the next free number at
`d69a33c`; take the next free one if another entry has it by launch. Every
figure is the report's; cite `docs/reports/20261001_compile_cost_reeval/`
once, beside the measured figures.

1. **Every walk over an entry tuple or a chunk tuple is a generated unroll**,
   one statement per element (D-289). Why: a recursion on the tuple's tail is
   inferred up to 32 elements. Past that its calls dispatch dynamically and
   allocate at every call. Measured on a model with 64 projecting components:
   595 KB allocated per boundary and a loop 5 times slower.
2. **Chunking bounds the compile cost** (D-086; its event-set half D-289).
   The existing rule
   keeps its substance: within a large block the tuple splits into chunks
   behind non-inlined, statically typed barriers; inside a chunk static
   dispatch, inlining, view SROA, check folding and zero allocation survive;
   at the barriers only cross-entry fusion is lost. New: the event set's
   projection, guard and handler walks chunk the same way.
3. **A barrier takes its chunk by reference** (D-289). The executor holds one
   pointer per chunk, and it holds the event set by reference. Why: a chunk
   stored inline in the executor is copied at every call site, with a GC root
   per pointer. Measured at 128 components: `init!` and the first `run!`
   cost 16.9 s per new topology with chunks stored inline and 0.5 s with
   items 1 and 3 in place, and the copies were a fifth to a third of the
   loop's runtime.
4. **The declaration layer takes components unspecialized** (D-289). Code
   that runs once per build does not compile again per component type or per
   root type, and a closure created per component reads the instance from an
   unspecialized binding. Why: that code has no performance requirement.
   Measured: `build` of 64 components of 64 new types 40.5 s → 0.86 s, and
   of a new 64-loop root over known types 12.1 s → 0.08 s.
5. **What chunking buys**, in order of size. Equal chunks share one compiled
   function: on 128 components of 2 types the walks compile in 23.2 s
   unchunked and 2.8 s at chunk size 16. And a function's compile cost grows
   faster than its entry count: on 64 components of 64 types, 6.4 s
   unchunked, 3.7 s at 16, 2.7 s at 4.
6. **What chunking costs.** A chunk's type is its entries' types in order, so
   a topology change that shifts the order compiles every shifted chunk
   again: 2.4 s on the 64-type model at chunk size 16, 1.3 s at 4.
7. **Chunk size** stays the implementation's only representation freedom,
   fully fused and chunk-of-one being its endpoints, and it still converts
   the compile cost from superlinear in the largest body to linear in entry
   count. It trades item 6 against runtime: 4 runs 3 to 9 % slower than 16.
   The default is 16.
8. **The measured figures**, replacing the 2026-07 table. The block never
   calls them anchors: in this spec an anchor is a rate's `(T, τ)` pair.
   Measured 2026-10 on Julia
   1.13.0 and Apple Silicon, components with real arithmetic, the minimum of
   three runs, from constructing the model to its first simulated frame:

   | model | situation | `-O2` | `-O0` |
   |---|---|---|---|
   | 10 components, 5 types | cold process | 8.6 s | 3.7 s |
   | | new topology, types known | 0.85 s | 0.34 s |
   | 128 components, 2 types | cold process | 9.4 s | 4.4 s |
   | | new topology, types known | 0.96 s | 0.30 s |
   | 64 components, 64 types | cold process | 13.5 s | 6.6 s |
   | | new topology, types known | 3.6 s | 2.3 s |

   Where the time goes: about 9 s of a cold process is generic machinery,
   the same for every model. A new component type adds about 0.01 s to
   `build`, plus the compilation of its own stage methods. A new topology
   pays for the chunks whose content changed. The figures are the nominal
   activation's. A `Dual` activation compiled in about the nominal time when
   last measured (`docs/reports/20260930_compile_cost/report.md` §4, before
   this stack).
9. **What mitigates the rest**, replacing the mitigation ladder.
   - Activations are lazy (§9.4), so a session that never linearizes never
     compiles `Dual`. Unchanged.
   - Precompile workloads. The generic machinery bakes into the package
     image, and a component package's workload does the same for its types,
     which turns TTFX from a session tax into a CI artifact.
   - The optimization level is an iteration session's knob. `-O0` about
     halves what remains, for a loop 2.3 to 2.8 times slower with the
     allocation invariant intact. Its trajectories differ from `-O2`'s by
     round-off, so a trace recorded at one level does not replay bit for bit
     at the other.
10. **Deleted by this ruling:** the 2026-07 table and the two
    paragraphs after it, and the ladder's rung about compiling non-nominal
    activations at a reduced optimizer level. The 2026-09-30 report measured
    no gain from that rung (its §7).

## Out of scope

- `Group` stays typed. The report's §6 shows that erasing its parameters
  changes what the service walk admits (D-130).
- The closure executors of the report's §4.5 and §4.6.
- The default `chunk_size`, which stays 16.
- A precompile workload. Stage 5 records it in `pending.md`.
- Any spec or log edit beyond stage 1's.
- `src/sim.jl`, `src/localization.jl`, `src/stepper.jl`, `src/trim.jl`,
  `src/linearize.jl`: no line changes. The three event-set walks keep their
  signatures.

## Reading, in order

- The report, as listed above. Its `patches/` hold the reference patches.
- `docs/design/spec.md` §9.7 "The compiled executor" (lines 4401–4608), its
  "Compile cost" block above all (4517–4552), and §7.5 "Allocation policy"
  (from 1834 to the next heading). Never read the spec whole.
- `docs/design/implementation.md`: the rows for `src/declare.jl` (122–141),
  `src/assembly.jl` (142–184), `src/executor.jl` (201–220) and `src/build.jl`
  (221–277); "Authoring caveats" (864–928); "Naming" (929–1007), which
  governs every name you add or touch; "Running the suite" (1008–end), the
  one home of test policy. Never restate either in a commit or a comment.
- `docs/design/pending.md` lines 10–24 and 70–84.
- `src/executor.jl`: the event set and its three walks (243–330), `Gated` and
  `run_at!` (402–448), `Chunk`, `PhaseBody` and `chunked_body` (450–524).
- `src/build.jl`: the user-code frame (19–95), `build` (732–760), the probes
  (259–270, 1017–1130, 1190–1210), `compile`'s event-set construction
  (1528–1541).
- `src/assembly.jl`: `children` and `_children` (104–236), `_one_level`
  (320–345), `_walked_faces` (500–510), `WALK_FACES` (822–830), `flatten!`
  (944–960), `_walk!` (1034 on).
- `test/test_executor.jl` in full (70 lines), `test/utils.jl` lines 1–20,
  `test/imports.jl`. `test/fixtures.jl` for `feedback_model`, `Rotor` and
  `Sawtooth`.

## The reference patches

Four files in `docs/reports/20261001_compile_cost_reeval/patches/`, one per
code stage, each a `diff -ru` of `src/` that applies with `git apply` on top
of the one before:

| stage | file | changed lines | touches |
|---|---|---|---|
| 2 | `stage2_generated_unroll.patch` | 52 | `executor.jl` |
| 3 | `stage3_pointer_chunks.patch` | 47 | `executor.jl`, `build.jl` |
| 4 | `stage4_child_list_cache.patch` | 12 | `assembly.jl` |
| 5 | `stage5_nospecialize.patch` | 131 | `assembly.jl`, `build.jl`, `declare.jl` |

Applied in order to `2556df4` they give exactly `recommended.patch`, the
stack the report measured and gated. Each is the measured behaviour, not the
landing text. A stage starts from its patch and then conforms it: the names
below, a comment where a reader needs one, docstrings that describe what is
now true. A change that could alter what the patch does, as opposed to how
it reads, is a deviation: make it only for a stated reason and report it.

## Shapes

### Stage 2: every tuple walk unrolls by a generated body

One helper builds the body: an inline marker, one statement per element,
then `nothing`. Six walks use it: the entry walk in both arities (`_walk`,
`_walk_at`), the chunk walk in both arities (`_walkchunks`), and the
projection, guard and fire walks. The guard and fire walks' per-entry bodies
move into two inlined helpers so the generated body stays one call per
element.

- A generator may call only functions defined before it. The helper sits
  above its first use.
- An empty tuple yields a body that returns `nothing`. The two-method
  `::Tuple{}` base cases go.
- `_proj_walk` is touched, so it takes its word in full: `_project_walk`.

### Stage 3: chunks and the event set are held by reference

- `Chunk` becomes a `mutable struct`. Nothing else about it changes. A phase
  body is then a tuple of pointers, and a call site loads one pointer.
- A second chunk type, `EventChunk`, holds a tuple of event entries or of
  projection entries behind a pointer. `EventSet` becomes a `mutable struct`
  whose `entries` and `projects` hold tuples of `EventChunk`s. Its
  constructor takes `chunk_size` as a keyword, and `compile` passes its own.
- `_projects!`, `_guards!` and `_fire!` keep their signatures. Each becomes
  an unrolled sequence of `@noinline` calls, one per chunk, and the entry
  walks of stage 2 run inside each chunk. The new helpers spell `project` in
  full: `_project_chunks`, `_project_chunk!`.
- A `PhaseBody` whose two tuple types are equal walks its interior at a
  boundary. That is correct only because `chunked_body` is the one
  constructor and wraps every discrete entry in `Gated`, so equal types mean
  equal lists. Say so in the method's comment.
- `chunked_body` builds its two entry lists as `Any[...]`.

Traps:

- **The reference patch misplaces a docstring.** It inserts `EventChunk`
  between `EventSet`'s docstring and the struct, so the docstring attaches to
  the wrong type. Define `EventChunk` above that docstring.
- **`entries` and `projects` now hold chunks.** Say it on the two fields.
  `length` of either counts chunks; the event count is `length(events.prior)`.
  Grep the readers twice, as a field read (`\.entries\b`, `\.projects\b`) and
  as an argument. At the tip they are the three walks and
  `test/test_events.jl:306`, an `isempty` that still holds.
- Nothing compares, hashes or copies a `Chunk` or an `EventSet` by value at
  the tip. Confirm it with a grep and say so in the report.

### Stage 4: the walk caches child lists

`WALK_CHILDREN`, a `ScopedValue` holding an `IdDict` from an assembly
instance to its child list, sits beside `WALK_FACES`. `flatten!` binds a
fresh one around the walk. `_walked_children(base, assembly)` reads through
it and falls back to `children` outside a walk. `_one_level` calls it in
place of `children`. The reference patch names the constant `WALK_KIDS`;
`WALK_CHILDREN` is the name to land.

- Two instances equal by value share one key. That is sound: a child list is
  a function of the value, and `path` reaches `_children` for its diagnostics
  only. A derivation that fails throws before anything is stored.
- The cached list is shared and read-only. `_walked_faces` copies on the way
  out; this one does not, because a copy per endpoint would bring back the
  cost the cache removes. Say so in its comment. `_one_level` only searches
  it.

### Stage 5: the declaration layer takes components unspecialized

The principle, which governs every instance and not only the ones the patch
lists: **code that runs once per build takes a component, an assembly or the
root unspecialized, and a closure created per component reads the instance
from an unspecialized binding instead of capturing a typed local.** A
closure that captures a typed local is itself parameterized by that type, so
it compiles once per component type even inside an unspecialized function.

The patch applies it to about 35 signatures across the three files, to five
closures under `at_component`, and to `_children`, which walks containers
through `getfield` and `fieldname` into a `Vector{Any}` (`_elements`,
`_element_keys`) in place of tuple operations. `build`, `flatten!` and
`_walk!` also take `Base.@nospecializeinfer`. Apply the principle to every
function and closure it covers in `assembly.jl`, `declare.jl` and the
structural half of `build.jl`, and list in the report whatever you add
beyond the patch.

- **One known remainder.** `probe_events`' inner `map` closure captures
  `declared_events`, so a component with state events still compiles one
  closure per type. Fix it here if a local change does it, and report either
  way. The report's fixtures had no events.
- **Out of scope:** the closure in `compile` (line 1496), which runs at
  `Simulation`, and the callers in `conditions.jl` and `tracer.jl`.
- **Every diagnostic names the site it named before.** The suite decides.
- Do not touch `Group`'s definition.

### Naming

"Naming" governs. The names fixed by this brief: `_unrolled`,
`_guard_entry!`, `_fire_entry!`, `_project_walk`, `EventChunk`,
`_event_chunks`, `_project_chunks`, `_project_chunk!`, `_guard_chunks`,
`_guard_chunk!`, `_fire_chunks`, `_fire_chunk!`, `WALK_CHILDREN`,
`_walked_children`, `_elements`, `_element_keys`. No new abbreviation. A
local never takes the name `children`, which is a package function.

## Stage 1: the docs

One commit: `docs/design/spec.md`, `docs/design/decisions.md`,
`docs/design/pending.md`.

Read first, beyond the list above: `docs/design/tools/spec_style.md` and
`docs/design/tools/decisions_style.md`; the chapter's rewrite recipe,
`docs/reports/20261001_chapter9_rewrite/report.md`, which holds the
convention chapter 9 is written in; that report's `rulings_batch.md`, items
R29 (445–457) and R57 (756–762), the two rulings this stage closes; D-086 and
D-288 in the log (D-288 at line 11789); the glossary's `chunking` entry
(spec line 12339); the headers of the docs tools, which say what each checks
and how to run it.

The rewrite froze the "Compile cost" block for this ruling. Its words are
the old spec's, and its two bold lead-ins, "Chunking bounds the compile
cost" and "The mitigation ladder", were taken off until a ruling could give
them an entry to cite. This stage gives them one.

1. **§9.7's "Compile cost" block** is rewritten to carry the ruling, items 1
   to 9, in the convention of the rewrite report's §3 (its lines 197–232): no
   labels, bold once per ruling on its headline clause with the citation in
   the same sentence, a reason after its rule. Rationale against an
   alternative never goes inline; it goes in the entry. Spell out SROA and
   TTFX at first use, or write the block without them (R57). Do not edit the
   rewrite report: R29 stays marked open there, and your own report says
   this commit closes it.
2. **Account for the old block.** In your report, list every sentence of the
   block as it stood and say where its content went: kept, restated, moved
   into D-289, or deleted under item 10. Nothing leaves silently.
3. **One clause in "Phase bodies, arities and seams".** "The seams therefore
   cost nothing" is true of the values that cross them. Add that each barrier
   takes its chunk by reference, pointing at the compile-cost block, so the
   sentence cannot be read against item 3.
4. **The glossary's `chunking` entry** says chunks are held by reference and
   that the event set's walks chunk too. Its last sentence stays.
5. **D-289**, in the log's form. Position, one sentence or bullet per
   ruling: items 1, 3 and 4, the event-set half of item 2, and item 9's set
   of mitigations. Those five are the block's new bolds, and "Chunking
   bounds the compile cost" gets its bold back citing D-086. Rationale: the
   constructive reasons and the measurements, with the report's path.
   Rejected, each with its measured reason from the report:
   - `@noinline` at the phase-body call over a body stored inline: each site
     then copies the whole body, and the first `run!` goes from 12 s to 46 s
     (its §4.2).
   - Phase bodies behind opaque closures: 0.5 s per topology, for an
     experimental interface and a live simulation that no longer sees a
     redefined method; the FunctionWrappers form runs 6 to 22 % slower
     (§4.5).
   - One opaque closure per entry: it removes the per-topology compile, but
     the loop runs 70 % slower on distinct types, and the form that does not
     allocate on Julia 1.13 calls an internal field (§4.6).
   - A `Group` without type parameters: 0.2 to 0.75 s per root, and it
     changes which service paths D-130 refuses (§6).
   - A default chunk size of 4: about 1 s per topology change against 3 to
     9 % of runtime (§7).
   - A reduced optimizer level for non-nominal activations: no measured gain.
6. **D-086** takes an amendment in the log's amendment form, dated: D-289
   restates its compile-cost figures and its mitigation ladder, and its
   rejection of type-erased call tables stands, now measured.
7. **`pending.md`.** The "Compile time" bullet becomes:

   > - **Compile time** (§9.7, D-086, D-289): §9.7's compile-cost rules are
   >   ruled and not yet built. Increment 58 builds them
   >   (`briefs/brief_increment_58_compile_cost.md`): the generated unroll,
   >   chunks and the event set by reference, the walk's child-list cache,
   >   and the unspecialized declaration layer.

   And "The spec's readability rewrite" bullet loses its last sentence,
   "§9.7's compile-cost block waits on the compile-time ruling above."
8. Run the battery `spec_style.md` names (lines 97–101): `check_refs.jl`,
   `check_rows.jl`, `check_glossary.jl --strict`, and `linkify.jl` as a no-op
   on re-run. All green. The pandoc line after the commit is the
   post-commit hook rebuilding the PDFs.

No test subset: this stage touches no code.

## Stage 2: the generated unroll

One commit. `src/executor.jl` alone.

Tests, in `test/test_executor.jl`, extending "the chunk walk is
allocation-free at any width (§9.7)". Each is red at the tip; run it there
first and quote the figure in the report.

- 40 copies of `feedback_model()` under one `Group` with a fanned `ref`, at
  `chunk_size = 1`: `sweep_2` walks 120 chunks. All four bodies, both
  arities, `@ballocated == 0`. Tip: 1 762 400 B.
- The same model at `chunk_size = 40`: one chunk holds 40 entries. The same
  assertions. Tip: 190 304 B.
- 40 copies of `Group((; rot = Rotor(), saw = Sawtooth(1.0)))`: 40
  projections and 40 events. After `init!`, `_projects!`, `_guards!` and
  `_fire!` each `@ballocated == 0`, with every argument interpolated. Tip:
  44 832, 47 392 and 47 392 B. Add the three names to `test/imports.jl`.

Routed subset: `executor stepper continuous discrete events localization
failures`.

Bookkeeping: `implementation.md`'s `src/executor.jl` row says the walks
unroll through a generated body. "Authoring caveats" gains one bullet: a
tuple walk by `Base.tail` recursion stops inferring past 32 elements and then
allocates at every call, so a walk over an entry or chunk tuple is a
generated unroll.

## Stage 3: chunks and the event set by reference

One commit. `src/executor.jl`, and `src/build.jl` for the one call in
`compile`.

Tests, in `test/test_executor.jl`, a new testset citing §9.7:

- **The executor holds one pointer per chunk.** With 6 and with 40 copies of
  `feedback_model()` at the default chunk size, count the chunks of the four
  bodies in both variants plus the event set's two tuples. Assert
  `sizeof(big.exec) - sizeof(small.exec) == sizeof(Int) * (chunks(big) -
  chunks(small))`. On the reference: 264 B at 8 chunks, 424 B at 28. Tip:
  6 264 and 39 384 B.
- **The event-set walks cross chunk borders.** The 40-rotor model at
  `chunk_size = 4`: `length(sim.exec.events.entries) == 10`. Run it past
  several wraps and assert its state equals, by `==`, the same model's at
  chunk sizes 16 and 64.
- **A body with no gated entry walks its interior at a boundary.** On a
  continuous-only model, `rhs`'s two type parameters are identical, and
  `ẋbuf` after `rhs(3)` equals `ẋbuf` after `rhs()`.

Routed subset: `declare assembly build diagnostics leaves show executor
stepper continuous discrete events localization failures trim linearize`.

Bookkeeping: the `src/executor.jl` row (chunks and the event set held by
reference, `EventChunk`, the boundary reuse) and the `compile` bullet of the
`src/build.jl` row (the event set takes the chunk size).

## Stage 4: the child-list cache

One commit. `src/assembly.jl` alone.

Test, in `test/test_assembly.jl`: a named assembly fixture holding its loops
in a `NamedTuple` field, with a fanned input over all of them, whose
`transparent_container` method increments a counter. Build one of 4 loops and
one of 64, reset the counter, build each again, and assert the two counts are
equal. On the reference both are 2. Tip: 5 and 65. The fixture lives at top
level in `test/fixtures.jl`; grep its name across `test/` first. It is a new
`AbstractComponent` fixture, so `build` is in the subset.

Also assert, on a root of two value-equal loops, that each loop's output
route names its own path. Equal instances share a cache key, and this is the
assertion that would catch a list leaking a path.

Routed subset: `declare assembly build diagnostics leaves show readers
conditions devices`.

Bookkeeping: the `src/assembly.jl` row's `WALK_FACES` bullet names
`WALK_CHILDREN` beside it.

## Stage 5: the declaration layer unspecialized

One commit, the largest. `src/assembly.jl`, `src/build.jl`, `src/declare.jl`.

Tests, in `test/test_build.jl`:

- **`build` adds no specialization per component type.** Two fixture types
  that no other test builds, at top level in `test/fixtures.jl`. Count
  `Base.specializations` over the methods of `_walk!`. Build a model of the
  first type, count, build a model of the second, count again: equal. Tip:
  the count grows by one per new type. Add `_walk!` to `test/imports.jl`.
  Extend the assertion to every other
  declaration-layer function you verify at the keyboard, `build` and
  `flatten!` among them, and say which in the report.
- **Nor per root.** Two `Group` roots of different widths over one known
  type: the same counts stay equal.

No timing assertion anywhere.

Routed subset: `declare assembly build diagnostics leaves show readers
conditions devices trim linearize`.

Bookkeeping:

- `implementation.md`: one sentence in each of the `src/declare.jl`,
  `src/assembly.jl` and `src/build.jl` rows. "Authoring caveats" gains one
  bullet stating the principle of this stage's shape, closures included.
- `pending.md`. The "Compile time" bullet is deleted. The paragraph above
  the bullets becomes:

  > The bullets stand in working order, the first one next. The GUI's design
  > runs in parallel with the library. The audit comes last, because it
  > sweeps the whole surface and the library and the GUI both add names.

  And "Outside the spec" gains one bullet:

  > - **A precompile workload** for the generic machinery a cold process
  >   pays, about 9 s whatever the model (§9.7).

- Both files are rostered. Run the docs battery after editing them; each
  tool's header says how.

## The cold review

One fresh Opus reviewer over the five commits: open-mind stance, probe
scripts in the scratchpad, "empty is acceptable". Dimensions:

- **§9.7 against the ruling.** The rewritten block claim by claim against
  items 1 to 10, every figure against the report's tables, one bold per
  ruling of D-289's Position and none elsewhere, the old block's sentences
  all accounted for, and D-289 in the log's form with each rejection
  carrying its measured reason.
- **The code against §9.7.** Each of the four rules read off the landed
  code: no tuple walk left on a tail recursion in `src/`, no chunk or event
  set handed by value, no declaration-layer function or per-component
  closure specialized on a component.

- **The landed diff against the measured one.** `git diff <tip>..HEAD --
  src` beside `recommended.patch`. Every difference is a name, a comment, a
  docstring, or a deviation a stage reported.
- **A mutant per stage**, each on a scratch copy, each named test going red:
  one walk back to `Base.tail` recursion; `Chunk` immutable again;
  `_one_level` calling `children`; `@nospecialize` off `_walk!`. A surviving
  mutant is a missing test.
- **The numbers still hold.** With the report's harness against the landed
  tree, `-O2`, chunk size 16, mode `iter`:
  `julia -O2 --project=test docs/reports/20261001_compile_cost_reeval/probes/measure.jl <scenario> iter 16`.
  Expected first simulation 0.85 s (small), 0.96 s (repeated), 3.6 s
  (distinct), within 20 %; every allocation count 0; `xhash`
  `29ecd83a8ddc20c2`, `2ec2c14b24189565`, `361f7aeacfda9226`. And
  `probes/mechanism.jl`: `evaluate!` near 47 LLVM lines with no `memcpy`.
- **What the report's fixtures lacked.** A model with state events, modes
  and a workspace through `build`, `init!` and `run!`, beyond 32 events:
  `probes/review_events.jl` is a start. A component with state events
  through stage 5's `probe_events`.
- **Julia 1.12**, the floor `Project.toml` declares: `julia +release` is
  1.12.7 on this machine. Run the gate under it if the manifest resolves
  there. If it does not, report that and change nothing.
- "Naming" (`implementation.md` 929) over every touched file.
- The docs battery green.
- The gate, run once, reported with the findings.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree carries other sessions'
untracked and modified files, and `git add -A` is forbidden. Re-read a file
before a scripted edit. Grep every new fixture name across `test/` before
defining it: a same-named type rebinds a fixture module silently. Fixtures
live at top level. Run the routed subset under the sandbox flags of "Running
the suite", in the foreground, with a 600 s timeout; the gate is the
reviewer's. Report: the commit hash, the files touched, each new test's
figure at the tip and after, the routed subset's result with the assertion
count, and every deviation from this brief or from the stage's reference
patch with its reason.
