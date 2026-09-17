# Increment 41 — the §13.2 framing kinds: `UserCodeFraming` and `BundleFieldError` (§5.2, §9.3, §13.1, §13.2, §13.4, Appendix C, D-142, D-221, D-225, D-248)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `3c4efa1` (the docs-first commit) plus the register commit that adds
this brief. Never `cd` elsewhere (`cd` is aliased to zoxide in the user's
shell; use absolute paths).

**Standing.** Nothing frames user code at the build. Every user-authored
method the build invokes is a bare call, so a throw inside one escapes
`build` raw, and the runtime catch site carries a bundle-field miss as a
raw `FieldError` cause. Measured on Julia 1.13.0 before this brief was
written, fixtures loaded through `test/repl.jl` (`FieldError` has the two
fields `type` and `field`):

| case | today |
|---|---|
| `output_state` calls `error("boom")` | raw `ErrorException` escapes `build` |
| `output_state(::C, (; x, m))` on a component with no `init_m` | raw `FieldError: type NamedTuple has no field m, available fields: x, t` escapes `build` |
| `init_x(::C) = error("init boom")` | raw `ErrorException` escapes `build`, from the walk's classifier |
| `output_state` destructures `m` only on a branch the probe never takes | `StepError{FieldError}`, the raw `FieldError` as `cause` |

D-248 rules the fix, docs-committed at `3c4efa1`. **Two stages, two
commits.** Stage 1 builds the frame at the build with both kinds. Stage 2
adds the runtime arm at §13.4's catch site and retires the register bullet.
Each stage runs its routed subset; the full suite is the reviewer's, once
per increment, except that stage 2 touches `sim.jl` (the routing table's
last row) and therefore runs the gate itself.

**Read, all in `docs/design/spec.md`:** §13.2's framing passage
(7368–7392: the framed set, the payload, the pass-through rule, the
`FieldError` match and its three classes). §5.2's bundle law (617–676: the
iff rule, the framing diagnostic, the closed per-function sets). §9.3's
totality paragraph (3330–3345). §13.1's user-code rule (7276–7283, D-057).
§13.4's catch site and species rule (7576–7620). Appendix B's legal-set
table (10419–10428). Appendix C's rows: `BundleFieldError` (10928–10932),
`HandlerReturnKey` (10933–10935, the neighbour), `UserCodeFraming`
(10936–10940). In `docs/design/decisions.md`: **D-248 (the ruling, at the
end of the log before the link block)**, D-142 (4550–4590), D-221
(7909–7986), D-225 (8052–8095), D-215 (7552, `InternalInvariant`).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (112–164)**: the routed subset, the flags, the gate.
- The file-table rows for `src/diagnostics.jl` (20), `src/declare.jl` (21),
  `src/assembly.jl` (22), `src/executor.jl` (24), `src/build.jl` (25),
  `src/tracer.jl` (26), `src/sim.jl` (28), `test/fixtures.jl` (38),
  `test/imports.jl` (39).
- **"Authoring caveats" in full (61–110)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module; `_typename` for a user type in a payload.

In `docs/design/pending.md`: the first "Not yet built" bullet, "The §13.2
framing kinds" (21–26), is the one stage 2 retires.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, D-248 and this brief disagree, stop and say so in the report
rather than improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with
`git show <tip>:path`. Grep every new fixture name across `test/` and
`src/` before defining it: a same-named type silently rebinds a fixture
module on 1.13. At this tip none of the names this brief coins exists.

---

## Stage 1 — the frame at the build, both kinds

Routed subset: `declare assembly build diagnostics leaves events`
(row one plus `events`, whose tests probe guards and handlers).

### The two kinds, in `src/diagnostics.jl`

Appendix C's order: `BundleFieldError` directly before `HandlerReturnKey`
(line 953); `UserCodeFraming` directly after `HandlerReturnKey`'s methods
and before the next kind. Severity error (the default), no `severity`
method.

```julia
"§5.2, §13.2: a bundle field a component function destructured that its bundle does not carry, classified against the legal sets."
Base.@kwdef struct BundleFieldError <: Diagnostic
    path::String
    family::String                           # "output_state" | "output_direct" | "state_derivative" | "state_update" | "guard" | "handler"
    tier::Symbol                             # :continuous | :discrete
    field::Symbol                            # the requested field
    legal::Vector{Symbol}                    # the bundle's own field names, the list in hand
    reason::Symbol                           # :undeclared | :wrong_tier | :illegal_for_family
end
path(d::BundleFieldError) = d.path
```

Three message arms, didactic, `_at_path` for the path, `_faceset` for the
list:

- `:undeclared`: "`c`: `output_state` destructures `m`, but `c` declares no
  `init_m` — the bundle carries {x, t} (§5.2)". The declaration named per
  field: `x` → `init_x`, `s` → `init_s`, `m` → `init_m`, `ws` →
  `init_workspace`, `u` → `input_types`, `y` → `output_types`, `y_x`/`y_s`
  → "no stage-1 port" (spell that arm as "but `c` produces no stage-1
  port").
- `:wrong_tier`: "`c`: `output_state` destructures `s`, a discrete-tier
  fact, and `c` is continuous — the bundle carries {x, t} (§5.2, D-195)".
- `:illegal_for_family`: "`c`: `output_state` destructures `u`, which no
  `output_state` bundle carries on the continuous tier — the bundle carries
  {x, t} (§5.2)".

```julia
"§13.2, D-248: a throw out of a user-authored method the build invoked, framed with where it ran."
Base.@kwdef struct UserCodeFraming <: Diagnostic
    path::String = ""                        # empty until the component frame fills it
    fn::String                               # the method's name
    bundle::Vector{Symbol} = Symbol[]        # the bundle's field names; empty for a declaration
    inputs::String = ""                      # the synthesized inputs as a spelling; empty without `u`
    cause::Exception
end
path(d::UserCodeFraming) = d.path
```

Message: the frame first, the raw throw second, on two lines: "`c`:
`output_state` threw during the build's probe — bundle {x, u, t}, inputs
(sig = false) (§13.2)\n  cause: " followed by `sprint(showerror, d.cause)`.
For a declaration (empty `bundle`) the first line reads "`c`: `init_x`
threw while the build read its declarations (§13.2)". The `inputs`
spelling is `sprint(show, bundle.u; context = :compact => true)` when the
bundle has a `u` field, empty otherwise. `cause::Exception` is admitted by
the row ("the original exception as `cause`"); §13.2's strings-never-
instances rule is about component instances and model types.

### The legal sets and the classifier, in `src/declare.jl`

After `event_bundle_names` (ends ~line 345), Appendix B's table verbatim
as data, plus the classifier:

```julia
# The maximal legal sets (§5.2, Appendix B), keyed by family and tier. A
# component's bundle narrows one of these to declared reality.
const LEGAL_BUNDLE = Dict(
    (:output_state, CONTINUOUS)     => (:x, :m, :t, :ws),
    (:output_direct, CONTINUOUS)    => (:x, :m, :u, :y_x, :t, :ws),
    (:state_derivative, CONTINUOUS) => (:x, :m, :y, :u, :t, :ws),
    (:output_state, DISCRETE)       => (:s, :t, :Δt, :ws),
    (:output_direct, DISCRETE)      => (:s, :u, :y_s, :t, :Δt, :ws),
    (:state_update, DISCRETE)       => (:s, :y, :u, :t, :Δt, :ws),
    (:guard, CONTINUOUS)            => (:x, :m, :y, :u, :t, :ws),
    (:handler, CONTINUOUS)          => (:x, :m, :y, :u, :t, :ws))

# Every name any family may carry at a tier: the wrong-tier test's universe.
_tier_names(t::Tier) = union((v for ((_, tt), v) in LEGAL_BUNDLE if tt === t)...)

"""
§5.2's three classes for a bundle field the component's bundle lacks: a name
this family may carry that the component did not declare; a name this tier
never carries but the other does (the state letters included, D-195); or a
name illegal for this family, which is also every name from nowhere.
"""
function classify_bundle_field(family::Symbol, t::Tier, field::Symbol)
    field in get(LEGAL_BUNDLE, (family, t), ()) && return :undeclared
    field in _tier_names(t) && return :illegal_for_family
    field in _tier_names(t === CONTINUOUS ? DISCRETE : CONTINUOUS) && return :wrong_tier
    :illegal_for_family
end
```

`Tier`, `CONTINUOUS` and `DISCRETE` are defined above in the same file;
check that `LEGAL_BUNDLE` sits after them.

### The three framing accessors, in `src/build.jl`

A new section at the top of the file, after the includes-facing header
comment and before `declarations` (line 35), "the user-code frame (§13.2,
D-248)":

```julia
# What passes through a frame unwrapped: none of these is user code failing.
_passes_frame(e) = e isa DiagnosticError || e isa InternalInvariant || e isa InterruptException

"""
The framing accessor for a declaration (§13.2, D-248): `fn(c, args...)`, a
throw out of it framed as `UserCodeFraming` naming the method. The path is
not known here; `at_component` fills it.
"""
function invoke_declaration(fn, c, args...)
    try
        fn(c, args...)
    catch e
        _passes_frame(e) && rethrow()
        throw(DiagnosticError(UserCodeFraming(fn = String(nameof(fn)), cause = e)))
    end
end

"""
The framing accessor for a probed bundle-taking function (§13.2, D-248):
`fn(c, bundle)`. A `FieldError` matched against the bundle's own type is the
bundle-law diagnostic, classified (§5.2); any other throw is the plain frame,
carrying the bundle's names and the synthesized inputs as a spelling.
"""
function invoke_probed(fn, family::Symbol, path::String, c, t::Tier, bundle::NamedTuple)
    try
        fn(c, bundle)
    catch e
        _passes_frame(e) && rethrow()
        if e isa FieldError && e.type === typeof(bundle)
            throw(DiagnosticError(BundleFieldError(path = path, family = String(family),
                tier = t === CONTINUOUS ? :continuous : :discrete, field = e.field,
                legal = collect(keys(bundle)),
                reason = classify_bundle_field(family, t, e.field))))
        end
        throw(DiagnosticError(UserCodeFraming(path = path, fn = String(family),
            bundle = collect(keys(bundle)), inputs = _inputs_spelling(bundle), cause = e)))
    end
end

_inputs_spelling(b::NamedTuple) =
    haskey(b, :u) ? sprint(show, b.u; context = :compact => true) : ""

"""
The component frame (§13.2, D-248): runs `f()` for the component at `path`
and fills the path into a `UserCodeFraming` an accessor raised without one.
Every other throw passes.
"""
function at_component(f, path::String)
    try
        f()
    catch e
        if e isa DiagnosticError{UserCodeFraming} && isempty(e.carried.path)
            d = e.carried
            throw(DiagnosticError(UserCodeFraming(path = path, fn = d.fn, bundle = d.bundle,
                                                  inputs = d.inputs, cause = d.cause)))
        end
        rethrow()
    end
end
```

Read `DiagnosticError`'s fail-fast field name off `src/diagnostics.jl`
(the species rule in `sim.jl` spells it `err.carried`) before writing the
match.

### Where the accessors go

**Declarations, through `invoke_declaration`.** Every site that calls a
user-authored declaration on a component instance. At this tip:

- `src/declare.jl`: `declared_at` (277–279, both arms), `bundle_names`
  (`init_x`, `init_m`, `init_s` at 309–312), `event_bundle_names`
  (339–340), `has_stage`/`_declares` need nothing (they call `hasmethod`
  and `which`, never the method).
- `src/assembly.jl`: `transparent_container` (92), `_contract` (457–458),
  `input_connections`/`output_connections` (469, 479, 902, 924, 952–953),
  `sample_times` (870), `child_connections` (890).
- `src/build.jl`: `declarations` (36–39), `check_state_leaves` (60),
  `check_store_form` (77), `check_stores` (87), `classify_tier` (104–107,
  `state_events` included), `_check_event_declarations` (643),
  `_stratum_c`'s `mstores` comprehension (805) and the two like it (1014,
  1302), `_workspaces` (836), `probe_events` (1018) and the compile-side
  `state_events` read (1423).

Leave the two service-time reads in `src/conditions.jl` (354, 470) and the
classifier's sampled trace in `src/tracer.jl` (197) as bare calls: they run
after the build has invoked the same pure declaration successfully. Leave
`probe_value` as increment 40 left it: a type-keyed override, not a
component method, outside D-248's "component path, which function"
payload; say so in the report if you disagree.

**Probed functions, through `invoke_probed`.** The six bundle-taking
calls, each with its family symbol and the tier in hand:

- `output_state` in `probe_stage1` (168), family `:output_state`.
- `output_direct` in `_probe_direct!` (957), family `:output_direct`.
- `state_derivative` and `state_update` in the update-law loop (912–913),
  families by name.
- the guard and the handler in `probe_events` (1027, 1032), families
  `:guard` and `:handler`, tier `CONTINUOUS`.

`state_projection` (935) takes `x` positionally, not a bundle (Appendix B's
last row): call it through `invoke_declaration(state_projection, c, d.x)`,
so a throw out of it is the plain frame naming `state_projection`, and a
`FieldError` on `x` is a plain frame too.

The probe's own checks after each call (the return-shape check, `DeadStage`,
`_check_ports`, `_check_derivative`, `_check_update`, `GuardForm`,
`_check_handler`) stay outside the accessor: the accessor wraps the one
user call and nothing else, so their carriers are never wrapped.

**The component frame, `at_component`.** Around every per-component body
that reads declarations without a path in hand, so the path lands on the
frame:

- `src/assembly.jl`, `_walk!`: the primitive branch's body (from the
  store-form check through the root-faces block, ~840–868) and the assembly
  branch's body (from `sample_times` at 870 to the end of the function),
  each under `at_component(path) do … end`. The shadowing check at
  835–839 stays outside: it reads bindings, not methods.
- `src/build.jl`: the per-component bodies of `_check_event_declarations`,
  `_stratum_c`'s three comprehensions (`decls`, `mstores`, `wss` via
  `_workspaces`), `probe_stage1`'s `map` body, `_probe_direct!`, the
  update-law loop body, the projection loop body, `probe_events`' body,
  and the compile-side `state_events` read at 1423. Use `flat.paths[ci]`.

The frame is idempotent: a `UserCodeFraming` that already carries a path
passes through an outer `at_component` untouched, so nesting two is
harmless.

`_classify` in `src/tracer.jl` (275) swallows every throw out of its prefix
probe into an unclassified cluster. A frame raised there disappears the same
way a `DeadStage` does today. Pre-existing; leave it, note it in the
report.

### Fixtures, in `test/test_build.jl`

At top level, in a new block after the `MissingProbeValue` fixtures
(~692–718), commented as the framing coverage set (§13.2, D-248):

```julia
# A stage that throws: the plain frame names the method, the bundle and the
# probe's inputs.
struct Thrower <: AbstractComponent end
init_x(::Thrower) = (; a = 0.0)
output_types(::Thrower, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::Thrower, (; x)) = error("boom")
state_derivative(::Thrower, (; x)) = (; a = 0.0)

# A throw out of each other probed function, one fixture each: a
# `state_derivative`, a guard, a handler and a `state_projection` that throw
# `ErrorException`; keep them minimal (a `Float64` guard so the probe runs it).
struct ThrowingDerivative <: AbstractComponent end
…
struct ThrowingGuard <: AbstractComponent end
…
struct ThrowingHandler <: AbstractComponent end
…
struct ThrowingProjection <: AbstractComponent end
…

# Declarations that throw: the frame names the declaration and the walk's
# path. One by value, one by type at `T`, one by allocation, one assembly
# declaration.
struct BadInit <: AbstractComponent end
init_x(::BadInit) = error("init boom")
state_derivative(::BadInit, (; x)) = (; a = 0.0)

struct BadInputTypes <: AbstractComponent end
…  # input_types(::BadInputTypes, ::Type{T}) throws
struct BadWorkspace <: AbstractComponent end
…  # init_workspace(::BadWorkspace, ::Type{T}) throws
struct BadChildren <: AbstractComponent end
…  # child_connections(::BadChildren) throws; needs one child field

# Bundle-law misses, one per class and per direction (§5.2): the continuous
# `output_state` reading `m` with no `init_m` (undeclared), `u` (illegal for
# the family), `s` (wrong tier); a discrete `output_state` reading `x` (wrong
# tier); a `state_derivative` reading `y_x` (illegal: that is `output_direct`'s
# name) and `foo` (illegal, a name from nowhere); a guard reading `s`.
struct ReadsM <: AbstractComponent end
init_x(::ReadsM) = (; a = 0.0)
output_types(::ReadsM, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::ReadsM, (; x, m)) = (p = x.a,)
state_derivative(::ReadsM, (; x)) = (; a = 0.0)
struct ReadsU <: AbstractComponent end
…
struct ReadsS <: AbstractComponent end
…
struct DiscreteReadsX <: AbstractComponent end
…
struct DerivativeReadsYx <: AbstractComponent end
…
struct ReadsFoo <: AbstractComponent end
…
struct GuardReadsS <: AbstractComponent end
…

# The type match's negative: a `FieldError` on the author's own struct inside
# a stage is not a bundle miss, and frames as the plain frame with the
# `FieldError` as cause.
struct Own; a::Float64; end
struct OwnFieldMiss <: AbstractComponent end
init_x(::OwnFieldMiss) = (; a = 0.0)
output_types(::OwnFieldMiss, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::OwnFieldMiss, (; x)) = (p = Own(x.a).b,)
state_derivative(::OwnFieldMiss, (; x)) = (; a = 0.0)

# The pass-through: a carrier a framework call inside the stage threw, and
# an interrupt, both leave the frame unwrapped.
struct CarrierInside <: AbstractComponent end
…  # output_state calls fragment(x = 1.0), which throws DiagnosticError{ConditionNodeMisuse}
struct InterruptInside <: AbstractComponent end
…  # output_state throws InterruptException()
```

The shapes are the contract, not the exact text. Every fixture builds
under `single(c)`; give each the declarations its class needs and nothing
more.

### Tests, stage 1

The build tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset. A fail-fast alone throw is
`DiagnosticError{K}` and its accessor is `diagnostic(err)` (D-222); never
`diagnostics` on it.

`test/test_build.jl`, a new function `build_user_code_framing()` after
`build_probe_refusals()` (55–89), called from `test_build()` (1252) right
after it. Testsets:

- "a throw out of a probed function is framed with the method, the bundle
  and the inputs (§13.2, D-248)": `Thrower` → `err isa
  DiagnosticError{UserCodeFraming}`, `d = diagnostic(err)`, `path(d) ==
  "c"`, `d.fn == "output_state"`, `d.bundle == [:x, :t]`, `d.inputs == ""`,
  `d.cause isa ErrorException`. One assertion each on the other four
  fixtures for `d.fn` (`"state_derivative"`, `"guard"`, `"handler"`,
  `"state_projection"`); the guard's and the handler's `d.bundle` are the
  event bundle's names.
- "a throw out of a declaration is framed with the walk's path (§13.2,
  D-248)": `BadInit` → `d.fn == "init_x"`, `path(d) == "c"`, `isempty(d.bundle)`;
  `BadInputTypes` → `"input_types"`; `BadWorkspace` → `"init_workspace"`;
  `BadChildren` under `Group((; a = BadChildren()))` → `"child_connections"`,
  `path(d) == "a"`.
- "a bundle field the bundle lacks is `BundleFieldError`, classified
  (§5.2, §13.2)": for each of the seven misses, `err isa
  DiagnosticError{BundleFieldError}` and `(d.family, d.field, d.reason)`:
  `("output_state", :m, :undeclared)`, `("output_state", :u,
  :illegal_for_family)`, `("output_state", :s, :wrong_tier)`,
  `("output_state", :x, :wrong_tier)` with `d.tier === :discrete`,
  `("state_derivative", :y_x, :illegal_for_family)`, `("state_derivative",
  :foo, :illegal_for_family)`, `("guard", :s, :wrong_tier)`. On the first,
  `d.legal == [:x, :t]` and `path(d) == "c"`.
- "the match is by the bundle's own type (§5.2)": `OwnFieldMiss` →
  `DiagnosticError{UserCodeFraming}` with `d.cause isa FieldError`.
- "a carrier and an interrupt pass through the frame unwrapped (§13.2,
  D-248)": `CarrierInside` → `failure(...) isa
  DiagnosticError{ConditionNodeMisuse}`; `InterruptInside` → `failure(...)
  isa InterruptException`.
- `classify_bundle_field` directly, one line per class on the table:
  `classify_bundle_field(:output_state, CONTINUOUS, :m) === :undeclared`,
  `(:output_state, CONTINUOUS, :u) === :illegal_for_family`,
  `(:output_state, CONTINUOUS, :Δt) === :wrong_tier`, `(:state_update,
  DISCRETE, :x) === :wrong_tier`, `(:guard, CONTINUOUS, :foo) ===
  :illegal_for_family`. `classify_bundle_field` and `LEGAL_BUNDLE` join
  `test/imports.jl`.

`test/test_diagnostics.jl`: kind-list occurrences in Appendix C's order,
`BundleFieldError(path = "a/b", family = "output_state", tier =
:continuous, field = :m, legal = [:x, :t], reason = :undeclared)` before
`HandlerReturnKey(…)` (365) and `UserCodeFraming(path = "a/b", fn =
"output_state", bundle = [:x, :t], inputs = "", cause =
ErrorException("boom"))` after it. The coverage check (~548–550) fails
otherwise. In the rendering testset (~561): the three `BundleFieldError`
arms each carry their distinguishing phrase (`"init_m"`, `"discrete-tier
fact"`, `"no `output_state` bundle carries"`) and the list `"{x, t}"`; the
`UserCodeFraming` message carries `"output_state"`, `"{x, t}"` and, after
`"cause:"`, `"boom"`; the declaration form carries `"read its
declarations"`.

`test/imports.jl`: `BundleFieldError` after `Build,` (line 7);
`UserCodeFraming` after `UnknownPort,` (line 35); `LEGAL_BUNDLE` in the
constants (beside `DIAG_RING`, line 12); `classify_bundle_field` in the
functions (alphabetical, after `classify_tier`, line 40).

### Register edits, stage 1

- `docs/design/implementation.md`: the `src/build.jl` row (25) gains "the
  user-code frame — `invoke_declaration`, `invoke_probed`, `at_component`
  (§13.2, D-248)" at its head; the `src/declare.jl` row (21) gains "the
  legal bundle sets and `classify_bundle_field` (§5.2, Appendix B)"; the
  `src/assembly.jl` row (22) gains "the component frame around the walk's
  two branches (D-248)". Add "D-248" to the three rows' spec columns.
  `src/diagnostics.jl` (20) needs nothing.
- The pending bullet stays until stage 2.
- Run `julia docs/design/tools/check_refs.jl` and `check_rows.jl` after
  editing the register: both must print `OK`.

### Handoff, stage 1 → stage 2

The stage-1 report ends with a handoff note: the commit hash; the exact
signatures of `invoke_probed`, `classify_bundle_field` and
`BundleFieldError`; the `test_build.jl` line range of the framing fixtures;
and any deviation from this brief.

---

## Stage 2 — the runtime arm at §13.4's catch site

Tip: stage 1's commit. Routed subset: `sim.jl` is in the routing table's
last row, so this stage runs **the full gate** itself, under the sandbox
flags. Read stage 1's handoff note and `git show <stage-1 hash>` first.

### The arm, in `src/sim.jl`

The species rule (~1120–1125) has one arm per cause shape: `_species(err) =
err` and `_species(err::DiagnosticError{<:Diagnostic}) = err.carried`.
Both take a `sim` now, and a third arm recognizes the bundle miss:

```julia
_species(::Simulation, err) = err
_species(::Simulation, err::DiagnosticError{<:Diagnostic}) = err.carried

# §13.2's bundle-field match at runtime (D-248): a `FieldError` whose type is
# the bundle the cursor's function received is the bundle-law diagnostic,
# classified as at the probe. Any other `FieldError` is the author's own.
function _species(sim::Simulation, err::FieldError)
    cur = sim.exec.cursor
    cur.comp == 0 && return err
    ci, fam = cur.comp, cur.fn
    c, t = sim.build.flat.comps[ci], sim.build.tiers[ci]
    bn = fam === :guard || fam === :handler ? event_bundle_names(c) :
         fam === :output_state  ? bundle_names(output_state, c, t, keys(sim.build.nominal.stage1[ci])) :
         fam === :output_direct ? bundle_names(output_direct, c, t, keys(sim.build.nominal.stage1[ci])) :
         fam === :state_derivative || fam === :state_update ? bundle_names(update_of(t), c, t, keys(sim.build.nominal.stage1[ci])) :
         return err
    (err.type <: NamedTuple && fieldnames(err.type) == bn) || return err
    BundleFieldError(path = sim.build.flat.paths[ci], family = String(fam),
                     tier = t === CONTINUOUS ? :continuous : :discrete, field = err.field,
                     legal = collect(bn), reason = classify_bundle_field(fam, t, err.field))
end
```

`_wrap_step` (~1108–1116) passes `sim` to `_species`. The match is by
names, not by the exact type, because the runtime bundle's value types
differ from the probe's at a non-nominal activation and the names are the
law's invariant. Read the cursor's `fn` symbols off `src/executor.jl`
(`fname`, the `:guard`/`:handler`/`:state_derivative`/`:state_update`
assignments) before writing the arms; `bundle_names` re-invokes
declarations on the error path only. `UserCodeFraming` gets no runtime
arm (D-248): a raw throw stays `StepError{<its type>}` with the cursor's
frame, as today.

### Fixtures and tests, stage 2

`test/test_build.jl`, beside the stage-1 framing fixtures:

```julia
# A destructure the probe never sees: `m` is read only past t = 0.05, so
# the build passes and the miss surfaces at the frame loop (§13.2, §13.4).
struct LateRead <: AbstractComponent end
init_x(::LateRead) = (; a = 0.0)
output_types(::LateRead, ::Type{T}) where {T <: Real} = (p = T,)
output_state(::LateRead, b) = b.t > 0.05 ? (p = b.m.phase,) : (p = b.x.a,)
state_derivative(::LateRead, (; x)) = (; a = 1.0)

# The same lateness on the author's own struct: stays a raw `FieldError`.
struct LateOwnMiss <: AbstractComponent end
…  # output_state(::LateOwnMiss, b) = b.t > 0.05 ? (p = Own(b.x.a).b,) : (p = b.x.a,)
```

`test/test_failures.jl`, `failures_runtime()` (116), a new testset after
"a throw in a handler names the event round": "a bundle field missed past
the probe is a `BundleFieldError` species (§13.2, §13.4, D-248)":
`Simulation(single(LateRead()); h = 1//100)`, `init!`, `run!(sim; t_end =
0.2)` → `e isa StepError{BundleFieldError}`, `e.frame.fn ===
:output_state`, `diagnostic(e).reason === :undeclared`,
`diagnostic(e).field === :m`, `diagnostic(e).legal == [:x, :t]`,
`lifecycle(sim) === :errored`. Then `LateOwnMiss` → `e isa
StepError{FieldError}` (the author's own, unmatched). Measured before this
brief: `LateRead` today ends as `StepError{FieldError}` at `t = 0.055`,
integration stage 2 of the frame from boundary 5.

`test/test_diagnostics.jl` needs nothing new: the kind already has its
occurrences from stage 1.

### Register edits, stage 2

- `docs/design/pending.md`: delete the "The §13.2 framing kinds" bullet
  (21–26) whole.
- `docs/design/implementation.md`: the `src/sim.jl` row (28) gains "the
  runtime bundle-field match in the species rule (§13.2, §13.4, D-248)".
  Add "D-248" to its spec column.
- Run `check_refs.jl` and `check_rows.jl`: both must print `OK`.

## Verification, both stages

- The routed subset (stage 1) and the full gate (stage 2) green under the
  sandbox flags at each commit.
- After stage 2, `rg -n "framing kinds" docs/design/pending.md` returns
  nothing.
- `rg -n "invoke_declaration\(|invoke_probed\(|at_component\(" src/` lists
  every site named above and no bare call remains:
  `rg -n '\b(init_x|init_s|init_m|init_workspace|input_types|output_types|state_events|child_connections|input_connections|output_connections|sample_times|transparent_container)\((c|comp)\b' src/build.jl src/assembly.jl src/declare.jl`
  returns only lines inside `invoke_declaration` calls, plus the two in
  `conditions.jl` and the one in `tracer.jl` that this brief leaves bare.
- In a `julia --project=test -L test/repl.jl` session, the four cases of
  the standing table now read: `DiagnosticError{UserCodeFraming}` naming
  `output_state` and `"boom"`; `DiagnosticError{BundleFieldError}` with
  `reason === :undeclared`; `DiagnosticError{UserCodeFraming}` naming
  `init_x` at path `c`; and (after stage 2) `StepError{BundleFieldError}`.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals per stage.

## Report format, each stage

Under 350 words: the commit hash; the files touched; the REPL check above;
any test you could not write as specified and why, with file:line; any
place the spec, D-248 and this brief disagreed; the assertion totals;
friction with this brief, especially any line number that had drifted;
and, for stage 1, the handoff note.
