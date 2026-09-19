# The pipeline redesign: implementation roadmap

The increments that deliver `notes_pipeline_redesign.md`, the settled register
of the 2026-09-18 session. The register is the map of *what* lands; this file
is *how* and *in what order*, grounded in the tree at `7b1c1e8` and the
2026-09-18 pre-flight probe. Item numbers below are the register's. Each
increment follows the delegation pipeline: a brief in this directory, one
fresh agent per stage, one cold review, a fixer, push. The suite is green at
every push.

## Decisions taken after the register

Settled 2026-09-18, and folded into the steps below:

- **Item 11's error is `DeclaredNotProduced`.** No new kind. Its docstring
  already names the fall-through; once publication goes, every declared and
  unreturned name takes that path. Its message and `state_fields` column lose
  the "a store field of that name and type carries them" remedy; the remedy
  becomes "return it from `output_state`".
- **§8.8's names.** The warning of item 8 is `EmptyFaceSelection`, beside the
  existing `UnknownFaceSelection`: `who`, `path`, the selector given and its
  names, the child's face list as candidates. The `:both_given` reason
  becomes `:multiple_selectors`, its payload naming the selectors given.
- **The convenience constructors stay.** `Simulation(build; kw...)` is sugar
  over the deployment constructor and `Simulation(root; kw...)` over both.
  The suite's 531 `h =` call sites are untouched by increment 46.
- **An unbounded run is allowed** with the §11.8 `UnboundedRun` advisory
  (Appendix C, spec line ~11126). `run!` mutates state, so by the artifact
  criterion the advisory lives in the loop's diagnostic cell and surfaces
  through the status record; the log line is presentation. Increment 47
  builds it and retires that part of the §11.8 pending bullet.
- **`Run{T}` exists from construction.** `Simulation{T}` is built with a
  placeholder run: `t₀ = zero(T)`, `mode = :live`, empty log and trace,
  `termination = nothing`. `init!` and `replay!` replace the object, which is
  item 23's "fresh objects rather than clearing". The field is `Run{T}`, never
  `nothing`; `Control.lifecycle` says whether the run ever started.

## Step 0: the audit refresh

Deferred. The 2026-09-17 refresh under `docs/reports/20260915_audit` is still
in progress and stays uncommitted. Step 1's commits touch `docs/design` only
and add their paths explicitly, so the refresh never rides along. It is
committed when the audit closes.

## Step 1: the docs commit

Landed 2026-09-18: step 1a as `d0b7712`, `d687271` and `f8f1746`; step 1b as
`ea86ae8` (the entries), `5502e1a` (the spec), `a85f5e5` (D-256's keyword
ruling), `6b754fa` and `5f48741` (the cold review's findings, recorded in
`review_step1b_findings.md`). The spec and the log now say the redesign; the
code owes it from increment 43 on.

Two commits, both before any code.

**1a, the vocabulary sweep (item 31).** Two passes, `d0b7712` and its
follow-up. The spec had 104 occurrences of "schedule", 5 of them "bound
schedule"; every one is assigned to "schedule" (the tick timing, matching
`Schedule`) or "execution order" (the stage sequence, carried by `Dataflow`;
"ordering" for the activity). The first pass wrote "dataflow" for the order
and was corrected by the second (`brief_step1a2_execution_order.md`). §5.1's heading, Stratum B's heading
and the glossary's "sweep" entry change with it. The log's 42 occurrences stay
as history; entry 1b's vocabulary decision records the renaming. A Sonnet
agent over a frozen copy (`git show 7b1c1e8:docs/design/spec.md`), then
`linkify.jl`, `check_refs.jl`, `check_rows.jl`, `check_glossary.jl`.

**1b, the normative commit.** Decision entries drafted and shown before the
spec is touched. Nine themes, D-250 through D-258:

| entry | register items | supersedes |
| --- | --- | --- |
| the artifact criterion and warning homes | 1–6 | D-084's slot stays open |
| §8.8's selectors and the empty selection | 7–10 | D-209's arm |
| the port model | 11 | D-016's publication rule, D-152, D-169 |
| the build-side types | 12–18 | §9.2's `Build` roster |
| `Deployment` and `Schedule` | 19–21 | D-187's "named artifact" wording |
| the run, the trace split, the stop policy | 22–27 | §13.5's second binding site |
| the `Simulation` regroup | 28 | — |
| the renderings and the chart guard | 29–30 | D-187's `show`-form |
| the vocabulary | 31 | records commit 1a |

Spec sections touched: §5.3, §8.8, §9.1, §9.2, a new subsection for the
deployment and its schedule, §11.5, §12 for the run, §13.2, §13.5, Appendix
C, Appendix D. Appendix C: `logged` widens to any artifact-producing call;
`EmptyGreedyClaim` moves to the roster entry's cell; `GridUtilization` moves
to the deployment's warnings; `EmptyFaceSelection` gains a row;
`DeclaredNotProduced`'s message and `UnknownFaceSelection`'s reason column
change. Read `tools/spec_style.md` and `tools/decisions_style.md` first; run
the four tools after.

Bookkeeping: `pending.md`'s first bullet becomes one umbrella bullet naming
this file, since after 1b the code owes the spec every item in steps 2–7.
`implementation.md`'s rows stay true until each increment changes them.

**1c, the strata retirement.** Landed 2026-09-19, after increment 43 and
ahead of increment 44: D-259 and the sweep's brief as `09e4151`, the spec
sweep as `e6352ff` (`brief_step1c_retire_strata.md`), the code's comments
and testset names as `0b81efd`, two leftover sentences as `3815392`. The
build's three steps are named by their products (the structure step, the
nominal evaluation, activation) and §9.1 opens with the table of what each
step consumes and produces. Raised while briefing increment 44: D-253's
fourth bullet had Stratum C complete the nominal activation from B's
stage-1 products, but `Events` needs the complete nominal products, so the
nominal evaluation returns the nominal activation itself (D-253 amended in
place).

## Step 2: increment 43, the auto-publishing removal

Landed 2026-09-18: the brief as `f2bf173`, the fixture sweep as `43b7149`,
the framework removal as `ae23a2b`, the cold review's amendment to D-252
(`ProducedByTwoStages` loses its producer column, §7.5's remedy returns the
mode field) as `904748f`, and the review's fixes as `77cf4ba`. The stages ran
in the reverse of the order below, the sweep first, because a stage-1 return
already won over publication and so the sweep could land green under the
machinery it retired. The probe table's names are the pre-sweep ones:
`AutoPlant` is now `VectorPlant`, `AutoCounter` is `UnreturnedCounter`,
`AutoOverload` is `UnreturnedMode`.

Item 11. Two stages.

**The pre-flight probe** (2026-09-18, suite green under the hook, script
`probe_autopub.jl` in the session scratchpad): nine fixture types rely on
publication, all in `test/fixtures.jl`, 18 use sites outside it.

| type | published | why it exists |
| --- | --- | --- |
| `Motor` | `ω::Float64`, `running::Bool` | §5.3's basic publication test |
| `AutoPlant` | `q::SVector{2,Float64}` | a loop closing through a published port (D-169) |
| `AutoCounter` | `n::Int` | the discrete tier publishing from `init_s` |
| `PinnedState` | `q::Float64` | a pinned walking field refused at `Dual` (D-166) |
| `ModeNamedProduct` | `q::Float64` | the non-nominal set is the nominal's |
| `AutoOverload` | `tripped::Bool` | a handler's mode flip reaching its cell (D-154) |
| `Twice` | `q::Float64` | §8.3's one-writer rule |
| `GearMode` | `gear::Gear` | an enum mode (§7.5) |
| `PhaseMode` | `phase::Symbol` | a `Symbol` leaf at the root (D-243) |

The first six were written for publication; their testsets become the
`DeclaredNotProduced` refusal, and each fixture gains an explicit
`output_state` return or retires where the refusal test needs the unreturned
port. The last three carry an unrelated property; they keep their tests and
gain the return. `PinnedState` is the delicate one: its stop-gradient refusal
at the `Dual` activation must now come from the stage-1 contract check, and
the brief names the kind that carries it.

- **Stage 1, the framework.** Remove `auto_published` (`build.jl:355–410`),
  `Activation.published`, `PublishEntry` in `executor.jl`, the `published`
  argument threaded through `schedule_stage2`, `probe_stage2`,
  `_probe_direct!` and `tracer.jl`'s `_classify`, and `compile`'s slicing at
  `build.jl:1484–1497`. Every declared and unreturned name reaches
  `DeclaredNotProduced`; edit its message.
- **Stage 2, the sweep.** The nine fixtures and the `build_auto_publication`
  testsets in `test_build.jl` (lines 313–390 and ~1161).
- Routing: the fixtures change, so the table's last row.

## Step 3: increment 44, the build-side types

Landed 2026-09-19: the brief as `bd43b4c`, `Structure` as `8f666a2`, the
nominal evaluation and the `Build` as `2c21b2e`, the consumers as `169ea66`,
the channel as `b5edf0e`, the cold review's doc amendments as `10050ae` (the
build binds the channel, `Structure`'s sentence, the scopes sentence), its
fixes as `a4c5d50` (the walk evaluates each boundary declaration once) and
the verification's residues as `00bf0eb`. Deferred to increment 45, in
`pending.md`'s "Smaller" bullet: the face-list primitives re-evaluate a
child's boundary declarations for a passthrough helper and on the
did-you-mean path, so a warning raised there lands once per asking level.

Items 12–17 and the warnings channel (items 2–5, build side). The largest
increment. Five stages; stages 1–3 and 4–5 split cleanly into two increments
if the count is too many for one review. The brief
(`brief_increment_44_build_side_types.md`, 2026-09-19) merges stages 2 and 3
into one, since a `Dataflow` flattened back into an `order` field would be
an interim state with no reader; its stages are numbered 1–4.

- **Stage 1, `Structure` replaces `Flat`** (`assembly.jl:679`). `tiers` moves
  in, plus the per-component `Relative`/`Absolute` provenance chain and the
  assembly scope triples with their `sample_times` key. Mechanical rename
  across the 19 readers outside `build.jl` and the 32 test hits in 7 files.
- **Stage 2, Stratum B's function.** `dataflow(structure)` returns
  `Dataflow`, `Events` and the `Float64` stage-1 products, splitting the
  current activation flow at `build.jl:905–932`. `Events` is built last,
  after the nominal stage probes; the `policies` vector leaves `Build` for
  it. Stratum C is a function of the structure, the dataflow and the events.
- **Stage 3, `Build` recomposition.** Structure, dataflow, events, one
  activation dictionary keyed by scalar type under the existing lock, and
  `warnings`. Every `b.nominal` (26 reads in `sim.jl`, 13 test hits) becomes
  a lookup.
- **Stage 4, the consumers (item 17).** Readers, trim, the tracer, `compile`'s
  key slicing and the catch site's field-error species take name lists from
  `Structure` and `Dataflow`.
- **Stage 5, the channel.** A scoped binding the build establishes
  (`ScopedValue`; the package's compat is 1.12, so it is available), an
  append helper, `warnings(::Build)`, the once-per-warning log at return, and
  the rendering of warnings beside a thrown collection. No build-side
  producer exists today, so the test is synthetic until increment 45.
- Routing: the last row.

## Step 4: increment 45, §8.8

Landed 2026-09-19: the brief as `903c037`
(`brief_increment_45_face_selectors.md`), the walk's face memo as
`414da76`, the selectors and `EmptyFaceSelection` as `97c6380`, the
feed-list test as `21b6922`, and the cold review's fixes as `4ed28bb` (the
memo hands out a copy, two test gaps closed). The brief folded in increment
44's deferred residue as a stage ahead of the roadmap's two: the walk
records each assembly's evaluated face lists under `WALK_FACES`, so the
primitives read them once per call and a warning inside a boundary body
fires once whatever asks. The review found one spec residue, Appendix C's
`logged` bullet still carrying the pre-D-250 once-per-call sentence, ruled
and amended after the push: a warning raised at a call site inside the call
fires once per raising site with that site's payload.

Items 7–10 with the names above. Two stages, small.

- **Stage 1.** The `select` predicate, exclusive selectors with
  `:multiple_selectors`, and `EmptyFaceSelection` through the channel.
  Files: `assembly.jl:523–582`, the two kinds in `diagnostics.jl`, the
  rendering testset.
- **Stage 2.** The feed-list test transcribing the spec's sketch (§8.8, near
  spec line 2900) against the real helpers. No source change.
- Routing: the table's first row.

## Step 5: increment 46, `Deployment` and `Schedule`

Items 19–21 and the deployment half of item 28. Three stages.

- **Stage 1, `Schedule`.** Per-component rows with anchor and provenance
  columns, the rate-scope rows, and the `D`, `Φ`, `Δt` vectors, derived from
  the structure's triples and anchors.
- **Stage 2, `Deployment`.** The binding code leaves `Simulation`'s
  constructor (`sim.jl:131`) for a constructor over a build; the convenience
  constructors compose it. `h`, `N_base`, `Δt_base`, the three event
  parameters, `sched`, `D`, `Φ`, `Δt` leave `Simulation` for it. Equality by
  value, since replay compares two.
- **Stage 3, D-187's grid diagnostics.** Leave-one-out factors, prime
  attribution, nearest non-refining offsets, the derivation line and
  `GridUtilization` on the deployment's warnings. New construction: none of
  it exists in `src/`.
- Routing: the last row.

## Step 6: increment 47, the run

Items 22–27, item 6, the rest of item 28, and `UnboundedRun`. Five stages.

- **Stage 1, `StopPolicy`** replaces `RunPolicy` (`sim.jl:13`): immutable,
  built and validated per advance, `hit` in the loop's scratch. `t_end` and
  `stop_on` leave the constructor for `run!`, `replay!` and `step!`, with
  `Inf` and no faces as defaults; 3 constructor uses in the suite, 114 `run!`
  uses already pass `t_end`. `UnboundedRun` lands here.
- **Stage 2, `Run{T}` and a mutable `Simulation`.** The placeholder run at
  construction, `init!` and `replay!` replacing it, `termination` leaving
  `Control` (`devices.jl:115`; 52 test hits in 7 files), `closed(run)`.
- **Stage 3, the trace split.** `Trace{T}` as a fixed header plus append-only
  `schemas` and `batches`; the header holds the deployment and `t₀`, no
  policy. The register keeps its cursor fields and the feed. `attach!` and
  `detach!` push schemas in place. 18 `header.` hits, all in `test_trace.jl`.
- **Stage 4, `EmptyGreedyClaim`** through `_report!` on the roster entry's
  cell (`sim.jl:1354` → `dataplane.jl:271`), the log line kept.
- **Stage 5, the regroup's remainder.** `chunk_size`, the stepper and the
  arrival buffers into the executor; `join_timeout` into `Control`; the loop
  cells and `published` into the plane. `Simulation` ends as build,
  deployment, executor, run, plane, control.
- Routing: all of it.

## Step 7: increment 48, the renderings

Items 29–30. `show` for `Structure`, `Dataflow`, `Schedule`, `Build` and
`Deployment`, the binary chart guard at 100 base ticks. One stage per type
family, or one stage if a single agent holds them. A new `test_show.jl`, cut
by property, with its routing-table row; `test_diagnostics.jl`'s rendering
testset asserts messages, not artifacts. The face-provenance printer stays
with the "Smaller" bullet.
