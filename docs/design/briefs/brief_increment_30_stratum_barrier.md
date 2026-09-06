# Increment 30 — collect Stratum A to one barrier; deployment to one throw per call

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at launch `9049a4e` for stage 1, `f7c96ae` for stage 2. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Standing.** A conformance increment in two stages. The design change landed
docs-first at `33bb172` as D-229; `9049a4e` then renamed the collected
vectors to `diags` and the walk state to `Walk`, with no behaviour change.
The code owes the spec exactly what D-229 says, and nothing else. Stage 1 is
Stratum A; stage 2 is deployment binding plus the register edits. One commit
per stage, suite green at each. **Stage 1 landed as `f7c96ae`** (assertions
2132 → 2138); its report's corrections are folded in below. One note for the
reviewer: the coordinator's concurrent D-230 commit `5eac582` swept up stage
1's one-line `_tier` hunk in `src/sim.jl`, so that line sits in the wrong
commit; the code at HEAD is right and the boundary is left as is.

**Read, all in `docs/design/spec.md`:** §13.1 in full (6964–7017), the
ruling's home — the "Strata are barriers" paragraph (6989–7009) is the
mechanism, the worked example (7011–7017) is the acceptance case; §9.1's Stratum A list and its resolution checks (2871–2901) for what the walk reads and checks; §9.1's
deployment validation passage (3027–3042) for the call scope; Appendix C's policy glosses for `collected` and `fail-fast` (10263–10273) and the rows for `UnknownPort`,
`UnconnectedInput`, `PathResolution`, `FaceDirectionConflict`,
`TwoProducers`, `TierUnreadable`, `StoreWithoutUpdate`,
`DeclarationOnWrongTier`, `EventHalfMissing`, `DeploymentInvalid` — all
`collected` — and for `ClassUnreadable`, `ClassMixed`, `ContainerMixed`,
`ChildNameCollision`, `TransparentContainerUnknown`, `UnknownFaceSelection`,
`WireTypeMismatch`, `ProducedByTwoStages` — all `fail-fast`. In
`docs/design/decisions.md`: D-229 in full (8176–8231); its Rejected list is
what you must not build instead. D-057 (the entry it narrows) and D-222 (the
carrier's type parameter is the policy: a kind for fail-fast, `Vector{Diagnostic}`
for collected).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (110–140).
- The file-table rows for `src/assembly.jl` (22), `src/build.jl` (25) and
  `src/sim.jl` (27).
- **"Authoring caveats" in full (60–107)** — always. The `import Cadence:`
  bullet bites in stage 1: the tests call `classify_tier` and `kinds`
  directly; check `test/imports.jl` has every name a new test uses.

In `docs/design/pending.md`, the deviation bullet **"First-violation
refusals where the kinds' policy reads `collected`"** (36–50) is the one this
increment retires. It names every site. Nothing else in that file bears on
the work.

**Stance: conservative reading.** Build what the tables below say. Where
the spec and this brief disagree, stop and say so in the report rather than
improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** The spec is written before the code, not instead
of it, and the two are kept mutually consistent. A deviation that improves
the design is raised in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root (the first run after an `src/` edit pays a ~15 s precompile). While
iterating, stage 1 runs `julia --project=test test/runtests.jl assembly
build discrete events diagnostics` and stage 2 runs `... build discrete
lifecycle localization log stepper devices events`. Gate each commit on the
full suite and then on `julia --project=. -e 'using Pkg; Pkg.test()'`.
Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with `git show f7c96ae:path` (stage 2) or `git show 9049a4e:path` (pre-increment).

---

## The problem

D-229 rules that "collected" reaches the stratum barrier under a dependency
rule: a declarative pass runs when the results it reads are clean, records
every violation, returns a total result, and every pass that ran merges into
one throw. Today Stratum A has three barriers and a set of lone throws inside
the first:

- The walk's resolvers throw at the first miss (`_one_level`
  `assembly.jl:273`, `_wrong_direction` `assembly.jl:479`), so the §13.1
  worked example fails: a typo'd wire reports its `UnknownPort` and never the
  `UnconnectedInput` it caused.
- `classify_tier` (`build.jl:58`) throws alone on `StoreWithoutUpdate` and
  `TierUnreadable`, and gathers `DeclarationOnWrongTier(:tier_form)` per
  component then throws before the next.
- `flatten` (`assembly.jl:630`), the tier pass (`build.jl:383`) and `_check_event_declarations` (`build.jl:398`) each throw their own list; keyed children are tier-classified twice, once in the walk (`assembly.jl:704`) and once in the pass.
- Deployment validation runs under three barriers: the keyword pass in
  `Simulation` (`sim.jl:137–158`), the first five `bind_schedule` checks (`build.jl:731–765`, nine lone arms counting `_exact` at 714–717), and the anchor loop (`build.jl:771–787`).

What stays as it is, by the same ruling: `classify` (`assembly.jl:40`) and
`_children` (`assembly.jl:91`) throw at once — structural failures, the
subtree behind them unknown. `_check_ports`, `_probe_input`'s
`WireTypeMismatch` and `probe_stage2`'s `ProducedByTwoStages` are fail-fast
with the probe chain. The public §13.3 forms `resolve(asm, path)`
(`assembly.jl:308`) and `resolve_terminal(asm, path)` (`assembly.jl:324`) run
inside declaration bodies, which §13.1 classes as user code: they keep
throwing a lone `DiagnosticError{PathResolution}`.

## Stage 1 — Stratum A (Opus)

### The design core

`build` owns the stratum's list and its one throw:

```julia
function build(root::AbstractComponent; activations::Tuple = ())
    diags = Diagnostic[]
    walk = Walk()
    flatten!(walk, root, diags)                 # structure, tiers, claims, the obligation check
    _check_event_declarations(walk.flat, diags)
    isempty(diags) || throw(DiagnosticError(diags))    # Stratum A's barrier (§13.1, D-229)
    flat = wire!(walk)                          # the derivation, on a clean walk
    tiers = Vector{Tier}(walk.tiers)
    _stratum_c(...)                             # unchanged from here
```

`Walk` owns the `Flat` it is building (option A, agreed with the user; do not
split `Flat` into structure and wiring halves):

```julia
struct Walk
    flat::Flat      # appended to directly; `conns` and `in_faces` stay empty until `wire!`
    tiers::Vector{Union{Nothing,Tier}}   # per primitive, beside `flat.paths`; `nothing` = recorded
    feeds::Dict{Tuple{String,Symbol},Tuple{String,Symbol}}     # consumer => producer
    claims::Dict{Tuple{String,Symbol},String}                  # who claimed it, for the message
    routes::Vector{Tuple{String,Symbol,Vector{Tuple{String,Symbol}}}}   # (path, face, consumers)
end
Walk() = Walk(Flat(String[], Any[], Vector{Pair{Symbol,Tuple{String,Symbol}}}[], Symbol[],
                   Pair{Tuple{String,Symbol},Tuple{String,Symbol}}[],
                   Pair{Tuple{String,Symbol},Tuple{String,Symbol}}[],
                   NTuple{3,Int}[], NTuple{2,Rational{Int}}[], String[]),
              Union{Nothing,Tier}[], Dict(), Dict(),
              Tuple{String,Symbol,Vector{Tuple{String,Symbol}}}[])
```

The seven fields `Walk` shared with `Flat` (`paths`, `comps`, `root_inputs`,
`out_faces`, `triples`, `anchors`, `aprov`) go: the walk pushes into
`w.flat.<field>`. The `diags` field goes too: the list is an explicit argument
of every walk helper that can add to it, as `_check_face_names`,
`_check_sample_times` and `_check_root_faces` already take it.

`flatten!(w, root, diags)` is today's `flatten` up to and including the
obligation check, minus the barrier and the derivation. `_walk!` gains a
`diags` argument. The obligation pass records `UnconnectedInput` and builds
nothing else. `wire!(w)` is the derivation: `conns` as a lookup into `feeds`
for every declared input of every component, then `in_faces` exactly as
today (`assembly.jl:666–672`), both pushed into `w.flat`; it returns
`w.flat`. It runs only after the barrier, so every face is in `feeds` and no
`nothing` arm exists.

**The resolvers record and return nothing.** `_one_level`, the entry-taking
`resolve_terminal`, `resolve_source`, `resolve_dest` and `_wrong_direction`
each take `diags::Vector{Diagnostic}` as their last positional argument.
Where they threw, they `push!` the same diagnostic and return `nothing`
(`resolve_dest` and `_fanout` return an empty or shortened vector — a failed
endpoint contributes nothing, the others resolve). In `_walk!`:

```julia
for pair in child_connections(comp)
    entry = _entry("child_connections", path, pair)
    producer = resolve_source(entry, path, comp, first(pair), diags)
    producer === nothing && continue            # recorded; the destination stays unfed
    for consumer in resolve_dest(entry, path, comp, last(pair), diags)
        _claim!(w, consumer, producer, entry, diags)
    end
end
```

`_claim!` pushes `TwoProducers` into the `diags` argument instead of
`w.diags`. `output_connections` entries whose source fails to resolve
register no `out_faces` row.

The empty-route check (`assembly.jl:725–733`) must now tell "declared empty"
from "every endpoint failed": test `isempty(_endpoints(inner))` for the
`UnknownPort(:connection)` refusal, and when the consumers come back empty
because each endpoint was recorded, `continue` with nothing more. A route
some of whose endpoints resolved is pushed with those consumers; the barrier
throws anyway.

**The public §13.3 forms keep fail-fast.** `resolve(asm, path)` and
`resolve_terminal(asm, path)` call `_one_level` with a fresh vector and throw
the one diagnostic it recorded:

```julia
function resolve(asm, path::AbstractString)
    who = "`resolve` on `$(nameof(typeof(asm)))`"
    isempty(path) && throw(DiagnosticError(PathResolution(...)))      # unchanged
    diags = Diagnostic[]
    r = _one_level(who, "", asm, path, String.(split(path, '/')), 0, diags;
                   owner = "the component in hand")
    r === nothing && throw(DiagnosticError(only(diags)))              # declaration code: fail-fast
    first(r)
end
```

Same shape for the public `resolve_terminal`. `input_passthrough` and
`output_passthrough` reach `resolve` and are covered by it.

**`classify_tier(path, c, diags)`** records where it threw and returns
`nothing`; the vote loop pushes into `diags` and returns `nothing` when it
pushed anything. **The walk classifies the tier where it classifies the
class**, once per primitive, and the separate tier pass in `build`
(`build.jl:383`) goes. `_walk!` pushes the tier beside the path and returns it,
`nothing` for an assembly, which is what the parent's rate-key check
(`assembly.jl:704`) reads once it moves *after* the recursive call:

```julia
function _walk!(w::Walk, path::String, comp, scope::NTuple{3,Int}, diags::Vector{Diagnostic})
    if classify(path, comp) === PRIMITIVE
        push!(w.flat.paths, path); push!(w.flat.comps, comp); push!(w.flat.triples, scope)
        t = classify_tier(path, comp, diags)      # the one classification; failures recorded here
        push!(w.tiers, t)
        ...                                        # the root-primitive block, unchanged
        return t
    end
    ...
    for ((seg, kid), fld) in zip(kids, fields)
        kidpath = _join(path, seg)
        kscope, keyed = _child_scope(w, path, st, seg, fld, scope)
        t = _walk!(w, kidpath, kid, kscope, diags)   # a primitive's tier, nothing for an assembly
        keyed && t === CONTINUOUS &&                 # §8.7: a key on a continuous child
            push!(diags, RatesViolation(path = path, reason = :continuous_child, key = Symbol(seg)))
    end
    ...
    nothing
end
```

A `nothing` tier is not `CONTINUOUS`, so an unreadable child skips the check
with no extra arm. Tier diagnostics now interleave with the walk's in walk
order rather than following them; rendering groups by kind and sorts by path,
so nothing visible changes. `_check_event_declarations(flat, diags)` pushes
and returns.

`classify` and `_children` are untouched. Do not add a skip arm to
`resolve_source`/`resolve_dest` for an unreadable class; the throw from
`classify` inside them is the ruling.

Update the comments that state the old shape: `flatten`'s docstring and its
"Stratum A's barrier (§13.1)" block (`assembly.jl:620–660`), the `Walk`
field comments, `classify_tier`'s docstring ("or a `DiagnosticError` naming
what disagrees"), the `_check_event_declarations` comment ("One barrier for
the whole pass"). Each says what the code now does, in one or two lines;
cite D-229 once, at `build`'s barrier.

### Tests, stage 1

The rule: a build refusal whose kind is `collected` now arrives as
`DiagnosticError{Vector{Diagnostic}}`, and the typo'd wire that used to be
the only diagnostic is joined by the input it left unfed. Convert each site
below to read the list; keep every assertion on the payload.

- `test/test_assembly.jl:343` — `carried(@test_throws DiagnosticError{PathResolution} …)`
  becomes `err = failure(() -> build(bad))`, then
  `d = only(filter(x -> x isa PathResolution, diagnostics(err)))`. Read the
  actual list off the run before asserting what else is in it; the brief
  expects an `UnconnectedInput` beside it and you must confirm that.
- `test/test_assembly.jl:393, 397` — the two `FaceDirectionConflict` sites,
  same conversion.
- `test/test_assembly.jl:440, 447, 455` — the `only(diagnostics(err))` on
  `UnknownPort(:connection)`: check whether the dead face leaves anything
  else unfed. If the list is still a singleton, the sites stand; if not,
  filter by kind as above and say so in the report.
- `test/test_assembly.jl:540, 545, 553` — `Starved`, `DoubleFed`: expected
  unchanged; confirm.
- `test/test_assembly.jl:652, 654, 719` — public forms, fail-fast, unchanged.
- `test/test_build.jl:156–165` — the direct `classify_tier` calls:
  `diags = Diagnostic[]; @test classify_tier("c", c, diags) === nothing`, then
  the existing assertions over `diags` instead of `diagnostics(err)`; line
  165 becomes `@test only(diags) isa StoreWithoutUpdate` on a fresh vector.
- `test/test_build.jl:36` — `carried(@test_throws DiagnosticError{StoreWithoutUpdate} build(…))`
  becomes a list read: `only(diagnostics(failure(() -> build(single(NoFlow())))))`.
- `test/test_events.jl:73–77` — already list reads; unchanged.
- `test/test_discrete.jl:111–140` — `RatesViolation` sites, list reads;
  expected unchanged, confirm.

Four additions, pinning D-229. Put the fixtures at top level beside the file's
others (authoring caveat: never inside a testset).

1. **The worked example**, in `test/test_assembly.jl`'s obligations testset
   (~535). A two-child assembly, one wire typo'd on the producer's port —
   follow the audit's probe: children `g::Gain`, `s::<a two-input leaf already
   in the fixtures>`, `child_connections = ("g/ot" => "s/a",)`, root `inputs`
   feeding `g/e` and `s/b`. Assert `kinds(err) == [UnknownPort, UnconnectedInput]`
   (walk order, then the obligation pass), the `UnknownPort` naming port
   `:ot` with `:out` among its candidates, and the `UnconnectedInput` at
   `"s"`, face `:a`.
2. **Cross-pass merge**, in `test/test_build.jl` after the tier testset: the
   typo fixture's assembly with `NoFlow()` as a third child and a `HalfEvent()`
   as a fourth (both from the existing fixtures; wire what needs wiring so
   the only failures are the three intended). Assert `Set(kinds(err)) ==
   Set([UnknownPort, UnconnectedInput, StoreWithoutUpdate, EventHalfMissing])`
   — one throw.
3. **Structural failures throw alone**, in `test/test_assembly.jl` beside the
   `ClassUnreadable` sites (~37): the typo fixture with an `Inert()` child
   added — `@test_throws DiagnosticError{ClassUnreadable} build(…)`; the wire
   typo is never reported with it. A one-line comment: `# D-229: a structural
   failure is fail-fast; nothing downstream of it can run.`
4. **The public forms stay fail-fast** — already asserted at 652/654/719;
   add nothing, but confirm in the report that they still pass unchanged.

### Commit, stage 1

Subject: `Collect Stratum A to one barrier with recording resolvers under D-229`.

## Stage 2 — deployment, one throw per call, and the register (Opus)

### The design core

The call is the barrier. `Simulation` (`sim.jl:131`) keeps its keyword pass
and moves the throw below `bind_schedule`:

```julia
    d_t = _t_bound_diag(t_end)
    d_t === nothing || push!(diags, d_t)
    bound = bind_schedule(b, h, n, Δt_base, diags)
    isempty(diags) || throw(DiagnosticError(diags))    # one throw per call (§9.1, D-229)
    act = activation(b, T)
    (stop_faces, stop_addrs) = _stop_faces(act.layout, stop_on)
```

`bind_schedule(b, h, n, Δt_base, diags)` records and returns `nothing` when
a premise fails. `h` and `n` are checked independently of each other, and
everything after reads one or both, so the dependency rule stops the pass
there:

```julia
function bind_schedule(b::Build, h, n, Δt_base, diags::Vector{Diagnostic})
    k = length(diags)
    h === nothing && push!(diags, DeploymentInvalid(parameter = :h, reason = :missing))
    h_r = h === nothing ? nothing : _exact(:h, h, diags)
    h_r === nothing || h_r > 0 ||
        push!(diags, DeploymentInvalid(parameter = :h, reason = :range, value = h_r))
    n === nothing || n ≥ 1 ||
        push!(diags, DeploymentInvalid(parameter = :n, reason = :range, value = n))
    length(diags) == k || return nothing       # every later check reads h or n (D-229)
    ...
```

Each later arm — `:unanchored`, `:no_constraint`, `_exact` on `Δt_base`,
`:not_harmonic`, `:disagrees_with_n` — pushes and returns `nothing` in place
of its throw; each reads the result of the one before it. The anchor loop
keeps collecting, into `diags` directly, and returns `nothing` if it pushed.
`_exact(name, v, diags)` pushes and returns `nothing` on its two refusing
arms. `bind_schedule` has no other caller (`rg "bind_schedule\(" src test`
must show `sim.jl:161` and the definition at `build.jl:731` only — confirm).

Update `bind_schedule`'s docstring and the anchor-loop comment ("The loop
collects (§13.1)") to the call scope.

### Tests, stage 2

- `test/test_build.jl:175` — `carried(@test_throws DiagnosticError{DeploymentInvalid} Simulation(b))`
  becomes `d = only(diagnostics(failure(() -> Simulation(b))))`.
- `test/test_discrete.jl:256–258` — `diagnostic(failure(f))` becomes
  `only(diagnostics(failure(f)))`; the loop's five cases stay singletons
  (confirm `n = 0` alone is one diagnostic: the dependency rule returns before
  the default `Δt_base` path can read `n`).
- `test/test_discrete.jl:264–266` — already a list read; unchanged.
- `test/test_discrete.jl:273` — same conversion as `test_build.jl:175`.
- `test/test_lifecycle.jl:124` — `run!`'s own `t_end` check, a different
  call; unchanged.
- The keyword-pass sites in `test_localization.jl`, `test_log.jl`,
  `test_stepper.jl`, `test_events.jl:242`, `test_devices.jl:317, 320`
  already read the list; run them, expect no change.

Two additions in `test/test_discrete.jl`'s cross-validation testset (~248):

1. `Simulation(b; h = 1e-3, n = 0)` — both `:h/:inexact` and `:n/:range` in
   one throw: `Set((d.parameter, d.reason) for d in diagnostics(err)) ==
   Set([(:h, :inexact), (:n, :range)])`.
2. `Simulation(b; log_every = 0)` with `h` omitted — the keyword pass and the
   schedule in one throw: parameters `Set([:log_every, :h])`.

### Register edits, stage 2

- `docs/design/implementation.md`, the `src/assembly.jl` row (22): "the
  flatten pass, its two-sided face graph and the sample-time fold" becomes
  "the flatten pass under one Stratum A barrier (`Walk` owning the `Flat` it
  builds, resolvers recording into the stratum's list, `wire!` deriving the
  two-sided face graph after the barrier) and the sample-time fold"; append
  `D-229` to the row's citation column. The `src/build.jl` row (25): after
  "tier classification" add "(recording, the tier pass merging into
  `build`'s one Stratum A throw)"; after "deployment binding" add "(one
  throw per `Simulation` call)"; append `D-229`.
- `docs/design/pending.md`: delete the deviation bullet "First-violation
  refusals where the kinds' policy reads `collected`" (36–50). Nothing else.
- Run `julia --project=@. docs/design/tools/check_refs.jl` and
  `julia --project=@. docs/design/tools/check_rows.jl`; both must pass.

### Commit, stage 2

Subject: `Bind the deployment under one throw per call and retire the collected-policy deviation`.

## Verification, both stages

- Full suite green in the foreground, then `Pkg.test()` green.
- `rg -n "throw\(DiagnosticError" src/assembly.jl` shows only: `classify`'s two, `_children`'s one, `resolve`'s `:empty_path` one plus the two new rethrows in the public `resolve`/`resolve_terminal`, and `_passthrough_faces`'s two — eight sites (stage 1 confirmed this count). `rg -n "throw\(DiagnosticError" src/build.jl`
  shows no site inside `classify_tier`, `_check_event_declarations` or
  `bind_schedule`, and exactly one in `build`.
- `rg -n "w\.diags|w\.paths|w\.comps|w\.root_inputs|w\.out_faces|w\.triples|w\.anchors|w\.aprov" src/assembly.jl`
  is empty, and `rg -n "classify_tier\(" src` shows the definition and the one
  call in `_walk!` only.
- The suite's recorded assertion total rises by at least six.

## Report format

Under 300 words per stage: the commit hash; the sites converted, by file;
every list whose contents differed from what this brief expected, with the
actual kinds; any site left and why, with file:line; the assertion totals
before and after; friction with this brief.

---

## Review fixes (Opus) — one commit, `Fix increment 30's review findings`

Tip `fddab2b`. The cold reviewer's five findings, adjudicated; build exactly
these. Iterate with `julia --project=test test/runtests.jl assembly build
discrete lifecycle events`; gate on the full suite, then `Pkg.test()`.

**F1. `bind_schedule`'s gate suppresses three checks that read neither `h`
nor `n`** (`build.jl:731–770`). `_exact(:Δt_base, …)`, `:unanchored` and
`:no_constraint` read only `Δt_base`, the tiers and the anchors. Restructure:
check `h` and `n` and record; run the `Δt_base` branch and record its own
refusals regardless (it needs `h_r` and `n` only on the default path,
`something(n, 1) * h_r`, which is skipped when either is missing or refused);
then gate the harmonic checks, `:not_harmonic`, `:disagrees_with_n` and the
anchor loop, on `h_r`, `n` (when given) and `Δt_r` all being sound. Return
`nothing` whenever the call recorded anything. Rewrite the docstring sentence
"`h` and `n` are checked independently, and every later check reads one or
both" and the gate comment at 744 to say what the gate actually reads. Probes
that must now report both: `Simulation(b; h = 1e-3, Δt_base = 1e-3)` →
`{(:h,:inexact), (:Δt_base,:inexact)}`; `Simulation(build(MultiRate()); h =
1//500, Δt_base = :derive, n = 0)` → `{(:n,:range), (:Δt_base,:unanchored)}`.
Add both as tests beside the two co-occurrence cases in `test_discrete.jl`.
Also in the `n` check (`build.jl:742`): require `n isa Integer`, so `n = 2.5`
is `DeploymentInvalid(:n, :range)` rather than a `MethodError` from `_as_int`;
one assertion for it in the same testset.

**F2. A parent wire reads the child's recorded route instead of re-resolving
it** (`assembly.jl:452–500`). Today `resolve_dest` on a sub-assembly face
calls `_fanout` on the child's inner endpoints and `resolve_source` recurses
through `output_connections`, so every parent wire through a face repeats the
child's resolution and re-records its refusals. Children are walked before
wires (`_walk!`, 710–790), so the child's faces are already resolved when a
parent names them. Thread `w::Walk` into `resolve_source` and `resolve_dest`
(the walk-internal forms only; the public §13.3 forms are untouched) and
replace the assembly arm of each with a three-way split:

```julia
    else
        # Children are walked before wires, so the child's faces are already
        # resolved: a face's consumers are its recorded route, and a face whose
        # route was refused was refused there, once (D-229).
        i = findfirst(rt -> rt[1] == cpath && rt[2] === name, w.routes)
        i !== nothing && return copy(w.routes[i][3])
        String(name) in input_faces(comp) && return Tuple{String,Symbol}[]   # declared, refused at the child
    end
    _wrong_direction(entry, path, cpath, name, comp, "consumer", diags)     # the parent's own typo
```

and for the source side the lookup is over `w.flat.out_faces` (`first(p) ==
(cpath, name)`, returning `last(p)`), the declared-but-refused arm tests
`output_faces(comp)` and returns `nothing`. `_fanout` stays as it is and is
now called only by the declaring level on its own children's endpoints. Pin
the order dependency with the comment above; do not reorder `_walk!`.
Acceptance: the reviewer's probe — `inner = Group((; a = Gain(1.0)); inputs =
("f" => "a/e",), outputs = ("a/outt" => "y",))` read by three parent wires —
reports exactly one `UnknownPort` (at `inner`, port `outt`) and the unfed
inputs the wires left, each once. Add it as a test in `test_assembly.jl`
beside the worked example, asserting `count(d -> d isa UnknownPort,
diagnostics(err)) == 1`. Also confirm and assert the parent's *own* typo
against a child face (`"inner/g" => …` where `inner` declares `f`) still
reports an `UnknownPort` whose candidates are the child's face list.

**F3. `_stop_faces` joins the `Simulation` call's one throw** (`sim.jl:158–161`,
`199–225`). `_stop_faces(layout, stop_on, diags)` records into the list it is
given and returns the pair; `Simulation` computes `act = activation(b, T)`
and calls it *above* the deployment throw, passing its own `diags`. The two
other callers, `run!` (768) and `replay!` (892), are their own calls: each
passes a fresh vector and throws it if non-empty, exactly one barrier each,
as today. Probe: `Simulation(b; stop_on = ("nope",))` with `h` omitted →
`kinds == [DeploymentInvalid, StopFaceInvalid]` in one throw; add it as a
test in `test_lifecycle.jl` beside the existing `StopFaceInvalid` case.

**F4.** `test/test_build.jl:175–176` and `test/test_discrete.jl:283–284`:
add `@test d isa DeploymentInvalid` before the field reads.

**F5.** `docs/design/implementation.md`, the `src/build.jl` row: "(recording,
the tier pass merging into `build`'s one Stratum A throw)" becomes
"(recording, the tier read in the walk beside the class, `build` owning
Stratum A's one throw)". Run `check_refs.jl` and `check_rows.jl` after.
Leave the `TypoWithInert` test as it is.

Report under 300 words: commit hash, each finding's outcome with file:line,
every probe's actual output, assertion totals, friction.
