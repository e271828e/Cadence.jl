# Brief: step 1b, the spec conforms to D-250 through D-258

Step 1b's second commit (`roadmap_pipeline_redesign.md`). Tip: `ea86ae8`,
which added the nine entries to `decisions.md`. The spec now lags the log;
this commit makes the spec say what the entries decided. Docs only. One
commit. The code lags both until increments 43–48; `pending.md` records
that, not the spec.

## The authority

The nine entries in `docs/design/decisions.md`, D-250 through D-258, are the
positions the spec must state. Read them in full first. Where an entry's
Position and the spec disagree, the entry wins. Where the entry is silent,
the spec keeps its current text. Nothing in this commit decides anything
new: a place where you would have to invent a rule is a finding for the
report, not an edit.

Also read: `docs/design/tools/spec_style.md` whole, especially "Content
preservation" (the claim-inventory procedure) and "Terms";
`docs/design/briefs/notes_pipeline_redesign.md` whole (the register the
entries came from); `roadmap_pipeline_redesign.md`, section "Decisions
taken after the register".

## Register

The spec states the design as normative, in the present tense. It does not
say "will", "the redesign" or "formerly". History is the log's. Every
section stays locally re-readable: a type named for the first time in a
section gets its glossary link and a 5–10 word gloss. Sketches may be
simplified. No em-dashes. Short sentences.

## Section edits

Line numbers are at `ea86ae8` and shift as you edit; locate by heading. Work
top to bottom so the shifts stay predictable.

**§5.2 (572) and §5.3 (723).** D-252. The bundle law's "iff stage-1 ports
exist" loses its auto-published clause (628–640). §5.3's publication rule
(the **Rule.** paragraph near 777) and the hand-down's "auto-published
names excluded" (near 785) go: a declared output is produced by stage 1 or
stage 2; a component exposes a state or mode field by returning it from
`output_state`; a declared output no stage produces is
`DeclaredNotProduced` (§8.3). Near 4676, "Auto-publication is a sweep act
like any other stage-1 write" and its sentence go. §5.3's first prose use
of "execution order" takes `[execution order](#g-execution-order)` (the
sweeps left the section unlinked).

**§8.3 (2354).** D-252. The port classification (2366–2385) is two classes:
stage 1 and stage 2. Every sentence mentioning the auto-published class goes
or is respelled.

**Every other "auto-publ" site.** `rg -n -i 'auto-publ|auto_publ'
docs/design/spec.md` lists them (§7.x near 1388 and 1932, §9.1 near 3064,
§9.5 near 3281 and 3461–3477, §11.2 near 5047–5079, §14 near 8431, §15
near 9478, 9914 and 9966, Appendix B near 10446–10448, Appendix D near
11158). Each is respelled to the two-class model or removed. §11.2's "dev-mode
flag auto-publishing all state fields" note (near 5079) stays as a possible
reader over the stores, reworded so it does not name a port class. The
glossary entry "auto-published port" is retired; `check_glossary.jl` will
report any link left behind. §15's worked models return their exposed state
from `output_state` where a sketch shows it published.

**§8.8 (2794).** D-251. The helper sketch and prose take `select` as a
third selector, one per call; the refusal's reason is `:multiple_selectors`
("more than one selector given"); an empty selection under a given selector
is the warning `EmptyFaceSelection`, on the `Build`'s warnings (D-250).
State that a bare call over a faceless child is silent.

**§9.1 (2964).** D-253, D-254, D-250. Name each stratum's product in its
subsection: Stratum A returns `Structure` (the tiers, the provenance chain,
the scope triples with their `sample_times` key); Stratum B is its own
function returning `Dataflow` and `Events` with the `Float64` stage-1
products, `Events` last, after the nominal probes; Stratum B's prose says it
is the nominal evaluation's structural half and the nominal activation is
B's products plus C's typing; Stratum C takes structure, dataflow and
events and completes an `Activation`. The "Deployment binding" subsection
becomes the `Deployment` constructor: it consumes the build and the grid
parameters, returns a scalar-free `Deployment` carrying the `Schedule`, the
grid diagnostics and its warnings, and `Simulation` materializes it at `T`.
Warnings: a stratum that throws renders its warnings with the collection;
one that completes carries them on the artifact and the entry point logs
each once at return.

**§9.2 (3151).** D-253, D-254, D-257, D-250. The `Build` holds structure,
dataflow, events, the activations (one dictionary keyed by scalar type,
nominal included, under the lock) and `warnings`; `warnings(x)` on `Build`,
`Deployment` and `Simulation`. The anchor and component tables live on
`Structure`; the `Schedule` lives on the `Deployment`, typed rows with
anchor and provenance columns, the rate-scope rows, and the `D`, `Φ`, `Δt`
vectors. Each type renders itself through `show` (D-257); the chart guard is
binary at 100 base ticks with "chart omitted" otherwise; the grid
diagnostics print from the deployment. Keep the worked example. The
convenience constructors `Simulation(build; kw...)` and
`Simulation(root; kw...)` are defined as composing the `Deployment`
constructor and the materialization.

**§9.3, §9.4, §9.5, §9.7 (3266, 3362, 3448, 3622).** D-253, D-252. Where
these read name lists off the nominal activation, they read them off
`Structure` and `Dataflow`; the executor compiles from the `Dataflow` order.
Remove the auto-published sentences listed above.

**§10.5 (4256).** D-254. The schedule is the `Deployment`'s `Schedule`,
the single source of truth for `Δt` unchanged. Light touch.

**§11.3 (5226), §11.8 (6196).** D-250. `EmptyGreedyClaim` is reported into
the roster entry's diagnostic cell at `attach!` and surfaces through the
status record; the log line at return is presentation.

**§11.5 (5613).** D-255. The header holds the `Deployment` and `t₀`, no
policy; the schema list is one of two append-only lists beside the batches,
`attach!` and `detach!` pushing onto it; `Trace{T}` is the header plus the
two lists. Adjust D-217's "the header records the `t_end`/`stop_on` pair"
sentence: the termination record carries the terminating policy.

**§12.1 (6338), §12.4 (6514), §12.6 (6874).** D-255, D-256. `Run{T}` is
introduced where the run lifecycle is: its four `const` fields, its three
writable ones, `closed(run)`, the placeholder run at construction that
`init!` and `replay!` replace, `termination` off `Control`, `init!`
allocating fresh objects. `Control` keeps the stop word, the lifecycle and
the wait, and gains `join_timeout`. `ControlRequestedStop` is outside the
policy. `Simulation` is a mutable struct of six fields: build, deployment,
executor, run, plane, control.

**§12.7 (7016).** D-254, D-255. Replay compares two deployments as values;
the header check reads that comparison.

**§13.2 (7320).** D-250. The "two warning streams" passage (7417–7444)
becomes the artifact criterion: a warning raised producing an artifact
lives on the artifact, one raised mutating state lives in that state's
status, logging is presentation. The service-warning paragraph goes; trim's
warnings are the `TrimReport`'s. The build warning set is no longer empty:
`EmptyFaceSelection`. D-084 still stands for the unconnected-output warning.

**§13.4 (7566).** D-253. The cursor indexes the `Dataflow`'s order.

**§13.5 (7732).** D-255. The **Policy** bullet and the "Both are
`run!`-time overridable" passage with its sketch become: `t_end` and
`stop_on` are keywords of `run!` and `replay!`, `Inf` and no faces as
defaults, validated per call; `step!` states the same defaults; the policy
is a `StopPolicy` value bound on the run per advance; an unbounded run is
allowed and raises `UnboundedRun` into the loop's diagnostic cell. The
"two homes for one fact" paragraph goes.

**§13.7 (7934).** D-257. The renderings are each type's `show`; the
face-provenance printer joins `Structure` when the routing chain is
recorded.

**§14.1 (8131), §14.4 (8356).** D-253. Readers, plans and trim take names
from `Structure` and `Dataflow`, not the activation. Light touch.

**Appendix B (10399).** Signatures: `build`, the `Deployment` constructor,
`Simulation(deployment, T)` and the two convenience forms, `run!`,
`replay!` and `step!` with their keywords and defaults, `warnings`,
`closed`, `select` on the passthrough helpers. The bundle table loses
auto-published names.

**Appendix C (10735).** The `logged` policy widens to any
artifact-producing call, the build included. `EmptyGreedyClaim`: warning ·
service · rate-limited, in the roster entry's cell. `GridUtilization`:
warning · service, at the `Deployment` constructor · logged, on the
deployment's warnings. New row `EmptyFaceSelection` (§8.8): warning · build
· logged on the `Build`; payload the helper, the child path, the selector
given and its names, the child's face list. `UnknownFaceSelection`'s reason
column: unknown names / more than one selector given. `DeclaredNotProduced`:
the remedy is returning the name from `output_state`; its state-field list
stays as context. `UnboundedRun`: raised at `run!` when `t_end` is `Inf`
and no stop faces are given. Read the policy header first and keep each
row's format.

**Appendix D (11132).** New entries, each in its section and alphabetical
slot, glossed from the entries: `Structure`, `Dataflow`, `Events` (D.5);
`Deployment`, `Schedule` (D.5 or D.4, whichever holds the tick vocabulary);
`Run`, `StopPolicy` (D.6); "artifact" and "state" as the criterion's two
words (D.10). Retire "auto-published port". Reword "execution cursor" so
the "as" hinge reads as a sentence. Update "`Build`", "trace header",
"termination record", "control plane" where their text names the old homes.
Register every new coinage in `docs/design/tools/coinage_inventory.md` and
add a row to `docs/design/tools/gloss_table.md` in the matching section.

**Generic "dataflow".** Three sites (near 3694, 9285–9286, 9497) use the
word for data moving through ports. Respell each so the word is reserved
for the `Dataflow` type; "signal flow" or "data movement" suffice.

**`pending.md`.** The first "Not yet built" bullet (§8.8 beyond the helper
pair, D-187's grid diagnostics, every `show`) becomes one bullet: the
pipeline redesign, D-250 through D-258, delivered by increments 43–48 per
`docs/design/briefs/roadmap_pipeline_redesign.md`; it lists the seven
themes in one sentence each. Nothing else in `pending.md` changes.

## Not in scope

`decisions.md`, `implementation.md`, `extensions.md`, `companions/`, the
briefs, the register, the roadmap, `src/`, `test/`. `linkify.jl` may
regenerate definitions blocks in rostered files; those join the commit.

## Procedure

Per section, the claim inventory: list the normative claims before, edit,
verify each survives or is replaced by an entry's ruling, and diff the
decision citations and glossary links. Each new rule cites its entry once,
bare (`D-253`). Where a sentence resists because its meaning is unclear,
leave it and flag it.

## Battery, then commit

From the repository root, after the edits and before the commit:

    julia docs/design/tools/linkify.jl
    julia docs/design/tools/check_refs.jl
    julia docs/design/tools/check_rows.jl
    julia docs/design/tools/check_glossary.jl --strict
    julia docs/design/tools/linkify.jl        # must be a no-op

`check_glossary.jl --strict` fails on a retired anchor still linked and on a
new entry never linked; fix the spec, not the tool. Commit with `git add`
by path, never `-A` or `.`; the uncommitted audit refresh under
`docs/reports` stays out. Single-sentence subject, no body, no attribution:

    Conform the spec to D-250 through D-258: the port model, the stratum artifacts, the deployment, the run and the warning criterion

Let the post-commit PDF hook run. Never stash, reset or check out the working
tree. Do not run the Julia test suite.

## Report

- Per section: the claims removed, the claims added, each with its entry.
- Every flagged sentence with its line and your reading.
- Glossary entries added and retired; coinage inventory and gloss table rows.
- Appendix C rows changed.
- The battery's output and the files `linkify.jl` regenerated.
- The commit hash and the diff stat.
