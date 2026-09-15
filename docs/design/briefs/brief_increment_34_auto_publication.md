# Increment 34 — auto-published ports (§5.3, §8.3, D-016, D-169)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `8199949`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** The spec has carried auto-publication since D-016 and every
clause around it is in place — the bundle law's `y` row, D-169's hand-down
exclusion, §7.1's state-cell table, §9.1's three-way port classification,
§9.5's `Expected` with auto-published names removed. The code owes the
mechanism itself. Today a declared port naming a state field is refused as
`DeclaredNotProduced`, so §8.2's own worked `Engine` does not build
(verified at `8199949`, below). **Two stages, two commits**, suite green
after each, `Pkg.test()` green.

**Read, all in `docs/design/spec.md`:** §5.3's stage roles (760–800; the
rule at 774–779 is the construct); §8.3 in full (2316–2371; the conformance
bullet at 2340–2352 names the refusals); §5.2's bundle law (613–636, the `y`
row at 625 and the hand-down paragraph at 630–636); §9.1 Stratum B
(3007–3026); §9.3's probe argument sourcing (3234–3242); §9.5's opening
(3403–3412) and the names-are-the-pairing paragraph (3428–3436); §7.1's
one-home-per-datum paragraph (1366–1373); §9.7's phase-body paragraphs
(3600–3625); Appendix C's `ProducedByTwoStages` and `DeclaredNotProduced`
rows (10840–10846); the glossary's auto-published-port entry (11066–11070);
Appendix B's bundle footnote (10366–10373). In `docs/design/decisions.md`:
D-016 (517–545, the origin), D-154 (5153–5195, why the table is written by
sweeps alone), D-169 (5782–5820, the hand-down exclusion).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (110–144).
- The file-table rows for `src/diagnostics.jl` (20), `src/declare.jl` (21),
  `src/store.jl` (23), `src/executor.jl` (24), `src/build.jl` (25) and
  `test/fixtures.jl` (37).
- **"Authoring caveats" in full (60–108)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (20–28) is the
one this increment retires, its auto-publication half; the `DeclaredNotProduced`
clause of the payload bullet (76) retires with it. The §13.3 generic-holding
clause in the same first bullet is a different mechanism (the load-bearing
read register) and stays.

**Stance: conservative reading.** Build what the sections below say. Where
the spec and this brief disagree, stop and say so in the report rather than
improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root. While iterating, `julia --project=test test/runtests.jl declare store
build executor continuous discrete events diagnostics` covers the files
this change reaches; gate each commit on the full suite and on
`julia --project=. -e 'using Pkg; Pkg.test()'`. Commit subject: one
sentence, no body, no attribution. Do not push. Never stash, reset or check
out the working tree; a baseline is read with `git show <tip>:path`.

---

## The problem

Verified at `8199949` with four one-component models (the probe script is
`/private/tmp/claude-501/-Users-miguel--julia-dev-Cadence-jl/054fdbf4-a13c-4c82-b071-845d18c23b65/scratchpad/probe_engine2.jl`,
reproduced from §8.2's inventory; copy it into your own scratch space):

| model | today |
|---|---|
| §8.2's `Engine` (`ω` in `output_types`, produced by no stage) | `DeclaredNotProduced("e", [:ω], [:M_shaft])` |
| a `Bool` mode field `armed` declared in `output_types` | `DeclaredNotProduced("c", [:armed], Symbol[])` |
| a discrete `s.n` declared as `n = Int` with no output stage | `DeclaredNotProduced("c", [:n], Symbol[])` |
| a state field `q` declared at the wrong type, `q = Int` | `DeclaredNotProduced("c", [:q], Symbol[])` — same message, and no state-field list to tell it apart |

Also verified, and **out of scope**: `ismutabletype(Symbol) === true`, so a
`Symbol`-typed port is refused by `mutable_position` (`IllegalPortType`,
`reason = :mutable`), and an `Enum` port has no leaves (`leaf_types` empty,
M-B7). Both idiomatic mode labels of §7.3 are therefore closed out of
publication until the port-value-coverage bullet lands. Every mode this
increment publishes is `Bool` or `Int`. The `Symbol` finding is recorded in
the register (below), not fixed here.

## The construct

§5.3: a declared output that matches a state or mode field **by name and
type**, and that no stage produces, is written by the framework from the
store into its cell **at stage-1 position**. The match is against `init_x`
plus `init_m` on the continuous tier, `init_s` on the discrete. Three
consequences the code must show:

1. **Classification precedes stage 2.** §9.1 classifies ports over
   `output_types` alone, and the stage-2 schedule is built from the wires
   carrying stage-2 ports, so the auto-published set must be known before
   `schedule_stage2` runs — it cannot wait to see what `output_direct`
   returns. Hence the reading built here: *a declared port naming a store
   field at the matching type, which `output_state` did not return, is
   auto-published.* `output_state` returning it is legal and wins (the
   stage-1 probe runs first). `output_direct` returning it is
   `ProducedByTwoStages`, auto-publication being the framework's own
   stage-1-position write. If you find the spec contradicts this reading,
   stop and report.
2. **The hand-down excludes it** (D-169). `stage1[ci]` stays the probe's
   return; a component whose only stage-1-position ports are auto-published
   has no `y_x`/`y_s` in its stage-2 bundle. `bundle_names` needs no change:
   it receives `keys(stage1[ci])`, which never held the published names.
3. **The table is written by sweeps alone** (D-154), so the write is an
   entry in `sweep_1`, gated like its component. A handler's mode flip is
   republished by the next round's sweep, which is exactly the coherence
   D-154 buys; nothing runs between handler and sweep.

## Stage 1 — build, executor, diagnostics (Opus)

### Classification, in `src/build.jl`

One function beside `probe_stage1` (146–163):

```julia
"""
§5.3's auto-published set for one component: the declared ports naming a
field of the tier's stores — `x` and `m` on the continuous tier, `s` on the
discrete — at the matching type, that stage 1 did not return. Port name =>
`(home, value)`, the home one of `:x`/`:s`/`:m` and the value the store's own
declared initial, which is what the cell holds until the first sweep (§10.5).
A declared name a store holds at another type is *not* published: it falls
through to `DeclaredNotProduced`, whose state-field list then names it.
"""
function auto_published(d::Decls, t::Tier, m, s1::NamedTuple, ::Type{T}) where {T}
```

- Homes: `d.x` and (`m === nothing ? NamedTuple() : m[]`) on the continuous
  tier, `d.s` on the discrete. `mstores[ci]` is the probe-scoped `Ref`
  `_stratum_c` already builds (585).
- Match: `haskey(home, n)` and `!haskey(s1, n)` and the type test. **At the
  nominal activation the test is exact**, `d.outs[n] === typeof(home[n])`.
  At a non-nominal `T` the set is fixed by the nominal (the schedule is
  `T`-independent), so the test is `_accepts(d.outs[n], typeof(home[n]),
  T)`, and a failure is a refusal, not a silent drop: collect a
  `ConformanceFailure(path, what = "auto-publication", reason =
  :field_type, shape = :ports, field = n, observed = typeof(home[n]),
  declared = d.outs[n], activation = T)` per port, throw the vector once per
  activation under the usual barrier. This is what a `Float64`-pinned
  declaration of a walking state field meets at the `Dual` activation:
  `_accepts(Float64, Dual, Dual) === false` (verified), and stripping would
  be a stop-gradient the author never wrote. State this in the docstring.
- Return a `NamedTuple` of `(home, value)` pairs, port order = declaration
  order in `d.outs`.

Wire it into `_stratum_c` (580–594) right after `probe_stage1`:
`published = [auto_published(decls[ci], tiers[ci], mstores[ci], stage1[ci], T)
for ci in …]`, a frozen component taking `carry.published[ci]` exactly as
`probe_stage1` takes `carry.stage1[ci]` (150). Then:

- `schedule_stage2` (221–254) gains a `published` argument; the
  stage-1-port exemption at 229 becomes
  `(haskey(stage1[pi], pport) || haskey(published[pi], pport)) && continue`.
  Amend the docstring (216–220): consuming a stage-1 *or auto-published*
  port adds no edge.
- `Activation` (355–360) gains `published::Vector{NamedTuple}` — the
  port => value map, values only (drop the home; the executor needs it,
  so keep the full pairs in a local and store `map(p -> map(last, p),
  published)` on the artifact, or store the pairs and take `last` where
  read — pick one and say which in the report).
- `probe_stage2` (619–712): `products = NamedTuple[merge(s1, pub) for …]`
  at 622, so the completeness pass (656–669) sees the published cells as
  produced and the seed in `compile` (1076–1085) writes them. The
  two-stages test at 646–649 becomes `intersect(union(keys(s1),
  keys(pub)), keys(y2))`. The completeness pass fills the new payload
  field (below): `state_fields = collect(keys(<the tier's homes merged>))`.
- The **ordering invariant** every downstream reader relies on:
  `keys(products[ci]) == (keys(stage1[ci])…, keys(published[ci])…,
  keys(y2)…)`. `compile`'s `y2keys` (1088) becomes
  `keys(act.products[ci])[length(keys(act.stage1[ci])) +
  length(keys(act.published[ci])) + 1:end]`. Put the invariant in a
  comment at 622.

### The entry, in `src/executor.jl`

Beside `UpdateEntry` (73–86), a fourth kind — the framework's write, no user
dispatch, so it never touches the cursor:

```julia
# §5.3's auto-publication: the framework's stage-1-position copy of store
# fields into their declared cells. `S` names the home (:x, :s or :m), `Ns`
# the fields copied; both select code. No user function runs here, so the
# cursor is not written (§13.4 frames user code only).
struct PublishEntry{S,XT,Ns,OA<:NamedTuple,CL,SS,MS}
    outs::OA        # port => cell address, in `Ns` order
    x_off::Int
    clock::CL
    sstore::SS
    mstore::MS
    path::String
end
```

with the outer constructor pattern the file uses (88–108), and

```julia
@inline function run!(e::PublishEntry{S,XT,Ns}, store, xbuf, ẋbuf) where {S,XT,Ns}
    v = S === :x ? reconstruct(XT, xbuf, e.x_off) :
        S === :s ? e.sstore[] : e.mstore[]
    scatter_group!(store, e.outs, NamedTuple{Ns}(v), activation_scalar(e.clock),
                   e.path, :auto_publish)
end
```

`NamedTuple{Ns}(v)` selects fields by name from the store value; `Ns` is a
type parameter, so the selection is static. `scatter_group!` (`store.jl`
81–104) then generates the straight stores, its §9.5 check decided at
generation and passing by construction (the classification admitted exactly
these types). Amend the file's entry comment (30–40): four kinds, by where
the product comes from and goes.

In `compile` (1033–1200), before the `output_state` loop (1093–1102): for
every non-frozen component and each home with a non-empty published subset,
push a `PublishEntry{home, typeof(d.x), names}(addr_group(path, names),
x_offs[ci], clock, sstores[ci], mstores[ci], path)` onto `stage1_entries`
with `gate(ci)`. Framework writes first, then the stages: the block is
order-free (§9.7 — stage 1 reads no cell), so the position is legibility
only; say so in a comment. A discrete component's entry is gated like its
`output_state`, so the `ESTABLISH` walk (executor.jl 413–435) publishes the
authored `s` at boundary zero, due or not, and the interior variant
(`chunked_body`, 502–520) carries a continuous component's entry into every
RHS evaluation — the cell tracks the trial state within a step exactly as a
stage-1 port computed from `x` would.

### Diagnostics, in `src/diagnostics.jl`

- `DeclaredNotProduced` (708–718) gains `state_fields::Vector{Symbol} =
  Symbol[]` — the tier's store field names — and the message becomes, per
  §8.3's wording: "`path`: declared port(s) … produced by no stage and not a
  state field of the declared type — a stage returns them, a store field of
  that name and type carries them (§5.3), or `output_types` drops them; the
  stages return …; the state fields are …". Keep the default so the
  existing constructor calls (`test_build.jl` 43, `test_diagnostics.jl`
  325) stay valid.
- `ProducedByTwoStages` (700–706): message "`path`: … produced twice — by
  two stages, or by a stage and the framework's auto-publication (§5.3,
  §8.3)". No payload change (the missing stage names are a separate
  register clause; leave it).
- `ConformanceFailure` needs no new arm: `what = "auto-publication"` rides
  the existing `:field_type` rendering. Check the message reads sensibly
  with that `what` and adjust the wording only if it does not.

### Where nothing changes, and why

- `bundle_names` (`declare.jl` 283–300): the `y` row is `output_types`
  non-empty, and every auto-published name is in `output_types`, so
  "`output_types` ∪ auto-published" is already that test. The `y_x`/`y_s`
  row takes `keys(stage1[ci])`, which excludes published names by
  construction (D-169).
- `cell_layout` (274–331): cells are laid out over `d.outs`; a published
  port already owns one.
- `RHSEntry`/`UpdateEntry`/`EventEntry` read `y` as `addr_group(path,
  keys(d.outs))`: the published cells are in it, which is §5.3's "the
  complete fresh table".
- The log, the snapshot, the trace, `capture`, readers: cells are cells.
  `port(latest(sim), path, name)` returns the published value with no code
  here; assert it (stage 2).
- `establish_defaults!` and the probe seed: the seed writes
  `act.products[ci]`, which now includes the published initials, so the
  pre-`init!` table shows the declared initial state; `init!`'s
  `ESTABLISH` round then republishes from the authored stores.
- Trim (`trim.jl` 407, 571) runs `_round!(…, ESTABLISH)` before `rhs()`,
  so its scratch world's published cells are fresh.

### Stage 1 tests

**Fixtures** in `test/fixtures.jl`, all top level, beside `Plant` (15–37):

- `Motor` — §8.2's `Engine` at the suite's size: field `J::Float64`;
  `init_x = (ω = 0.0,)`, `init_m = (running = false,)`, `input_types =
  (M_load = T,)`, `output_types = (M_shaft = T, ω = T, running = Bool)`;
  `output_direct(m, (; x, m, u)) = (; M_shaft = m.running ? one(x.ω) :
  zero(x.ω))`; `state_derivative = (ω = (y.M_shaft - u.M_load) / J,)`; one
  boundary-detected event `start`, guard `(; m, t) -> !m.running && t ≥
  0.1`, handler `(; m = (; running = true))`. With `M_load = 0` and `J =
  1`: `ω(t) = max(t − 0.1, 0)` at every boundary, up to the grid's
  placement of 0.1.
- `AutoPlant` — `Plant` without `output_state`: `output_types = (q =
  SVector{2,T}, power = T)`, the same derivative and `power`. `StateFeedback`
  — `k::Float64`, `input_types = (q = SVector{2,T},)`, `output_types = (u =
  T,)`, `output_direct = (u = -k * u.q[1],)`. `auto_feedback_model(; k)` =
  `Group((; plant = AutoPlant(…), fb = StateFeedback(k)); wires =
  ("plant/q" => "fb/q", "fb/u" => "plant/u"), outputs = ("plant/q" =>
  "q",))`. With `ref = 0`, `feedback_model(; k)` (643–655) closes the same
  loop through `Sum` and `Gain`, so the two trajectories agree.
- `AutoCounter` — `DiscreteCounter` (104–110) without `output_state`.
- `PinnedState` — `init_x = (q = 0.0,)`, `output_types = (q = Float64,)`,
  `state_derivative = (q = 0.0,)`: a pinned declaration of a walking field.
- `WrongTyped` — the same with `output_types = (q = Int,)`.
- `Twice` — `init_x = (q = 0.0,)`, `output_types = (q = T,)`,
  `output_direct(c, (; x)) = (q = x.q,)`, `state_derivative`; and
  `TwiceState`, the same with `output_state` in place of `output_direct`.

`test/test_build.jl`, a new function `build_auto_publication()` registered
in `test_build()` (750):

- `build(fed(Motor(1.0), "M_load"))` builds; on `b.nominal`: `stage1[i]`
  empty, `keys(published[i]) == (:ω, :running)`, `keys(products[i]) == (:ω,
  :running, :M_shaft)`; `bundle_names(output_direct, Motor(1.0),
  CONTINUOUS, ()) === (:x, :m, :u, :t)` — no `y_x` (D-169).
- `build(auto_feedback_model())` builds: the loop through `q` adds no edge.
  Wiring `plant/power` into a second consumer feeding `plant/u` instead
  raises `AlgebraicCycle` — one assertion, so the exemption is shown to be
  the published port's alone.
- `build(single(AutoCounter()))`: `published[i]` is `(n = 0,)`.
- `build(single(WrongTyped()))` fails with one `DeclaredNotProduced`, `ports
  == [:q]`, `products == Symbol[]`, `state_fields == [:q]`; the existing
  `Unproduced` assertion (42–43) gains `d.state_fields == Symbol[]`.
- `build(single(Twice()))` fails with one `ProducedByTwoStages`, `ports ==
  [:q]`. `build(single(TwiceState()))` builds with `stage1[i] == (q = 0.0,)`
  and `published[i]` empty.
- `build(single(PinnedState()))` builds; `activation(b, D8)` (the alias
  `test_store.jl` uses, 23) fails with one `ConformanceFailure`, `what ==
  "auto-publication"`, `reason === :field_type`, `field === :q`, `observed
  === D8`, `declared === Float64`.

`test/test_diagnostics.jl`: in the kinds list (324–325), give
`DeclaredNotProduced` a `state_fields`, and add a `ConformanceFailure` with
`what = "auto-publication"` so its message renders. Add `PublishEntry` and
`auto_published` to `test/imports.jl` if the tests name them.

**Commit:** "Publish declared state and mode fields from their stores at
stage-1 position (§5.3, D-016, D-169)".

## Stage 2 — runtime properties and the registers (Opus)

Read stage 1's handoff, then the tests below, each in the file that owns
the property (`implementation.md` 50–58: `test/` is cut by property).

`test/test_executor.jl` (9–40): in the roster testset, a
`Simulation(fed(Motor(1.0), "M_load"); h = 1//100)` — `walked(b.sweep_1,
:interior)` (`utils.jl` 8–12) holds two `PublishEntry`s and no
`StageEntry`; every block satisfies `@ballocated($body()) == 0` and
`@ballocated($body(1)) == 0`.

`test/test_continuous.jl` (60): a new testset —
- the `Motor` sim after `init!(sim, fragment(inputs = (in = 0.0,)))` — a root
  input must be covered at `init!` (§14.6, `UninitializedInputs`): `port(sim, "c", :ω) == 0.0`, `port(sim,
  "c", :running) === false`;
- after `run!(sim; t_end = 0.5)`: `port(sim, "c", :ω) ≈ 0.4 rtol = 1e-9`
  (the event is boundary-detected on a grid holding 0.1 exactly, so the
  reference is the closed form; state the tolerance's reason as
  `test_discrete.jl` 33–36 does), `port(sim, "c", :running) === true`, and
  `port(sim, "c", :ω) == state(sim, "c").ω` — bitwise, because the claim is
  that the cell *is* a copy of the store at the boundary, not an
  integration result (D-163's stamp exception, `implementation.md` 41–43);
- `port(latest(sim), "c", :ω)` equals the same value: the snapshot carries
  the published cell (§11.2);
- `auto_feedback_model(; k = 4.0)` against `feedback_model(; k = 4.0)`, the latter
  initialized with `fragment(inputs = (ref = 0.0,))` and the former bare: after `run!` to `t_end = 2.0` on `h = 1//100`, `port(a,
  "plant", :q) ≈ state(f, "plant").q rtol = 1e-12` — the same RK4 steps on
  the same closed loop.

`test/test_discrete.jl`, in `discrete_one_rate` (10) or beside it:
`Simulation(single(AutoCounter()); h = 1//10)` — after `init!`, `port(sim,
"c", :n) == 0` (the `ESTABLISH` round published the authored `s`); after
`run!(sim; t_end = 0.3)`, `port(sim, "c", :n) == 3` and `state(sim,
"c").n == 4`, the sampled-data gap the file already asserts at 40–44; and
at `D8`, `Simulation(build(single(AutoCounter())), D8; h = 1//10)` has no
`PublishEntry` in `sweep_1` (frozen, §9.4) and `port(simd, "c", :n) == 0`
after `run!`.

`test/test_events.jl` (71): an `AutoOverload` fixture — `Overload`
(fixtures.jl 425–439) without its `output_state`, `tripped` published
from `m` — under `overloaded()`'s wiring (`test_lifecycle.jl` 19–21, copy
the group, do not touch that file): after the trip boundary, `port(sim,
"mon", :tripped) === true` and `modes(sim, "mon").tripped === true`; the
snapshot at that boundary carries `true` (D-154: the handler's round is
followed by a sweep before publication).

### Register edits

- `docs/design/pending.md`:
  - The first bullet (20–28) becomes "**§13.3's generic-holding check in
    the *load-bearing* register** — the deep paths condition entries and
    trim `reads` write are policed by nothing, so §14.2's locality law
    rides as convention here (M-B21)." Delete the auto-publication clauses.
  - The payload bullet (76): delete "`DeclaredNotProduced` no state-field
    list, ".
  - The port-value-coverage bullet: after "§7.5's publish-a-mode remedy",
    insert "; `Symbol`-valued ports are refused as mutable
    (`ismutabletype(Symbol)` holds, so D-237's walk meets it), which with
    the enum refusal closes both of §7.3's mode labels out of §5.3's
    auto-publication until ruled".
- `docs/design/implementation.md`:
  - `src/build.jl` row (25): add "`auto_published` and the published set
    on the `Activation` (§5.3, D-169)" where the probe chain is described;
    add `§5.3`, `D-016`, `D-169` to the citations.
  - `src/executor.jl` row (24): "entries (each carrying …)" → "entries
    (each carrying …; `PublishEntry`, the framework's stage-1-position copy
    of store fields into cells, §5.3)"; add `§5.3`.
  - `src/diagnostics.jl` row (20): no change.
- Run `julia --project=@. docs/design/tools/check_refs.jl` and
  `julia --project=@. docs/design/tools/check_rows.jl` from
  `docs/design`; both must pass.

**Commit:** "Assert auto-publication's runtime properties and retire its
register bullet".

## Verification

- Full suite green after each stage; `Pkg.test()` green after each.
- `probe_engine2.jl`'s four models: the first three build, the fourth
  reports `state_fields == [:q]`. Rerun it and report.
- `rg -n "PublishEntry" src/` lists the struct, its constructor, `run!`
  and the `compile` site; report the count.
- `rg -n "auto_publish" src/` lists `run!`'s `what` symbol only.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words per stage: the commit hash; the files touched; the choice
made for `Activation.published` (pairs or values); any test you could not
write as specified and why, with file:line; any place the spec and this
brief disagreed, the stage-2 clash rule especially; the assertion totals;
friction with this brief, especially any line number that had drifted.
