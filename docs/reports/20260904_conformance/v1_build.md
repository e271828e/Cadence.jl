# Cold verification 1 — foundations, declaration, build

Tip `70672d1`, Julia 1.12.7, `julia --project=.` from the repository root.
Thirteen claims, thirteen probes run in
`scratchpad/verify1/` (`p1.jl`, `p2.jl`, `p2b.jl`, `p3.jl`, `p4b.jl`, `p5.jl`,
`p6.jl`, `p7.jl`, `p7b.jl`, `p8.jl`, `p9.jl`, `p11.jl`, `p12b.jl`, `p13.jl`).
Decision entries read: D-012, D-053, D-094, D-168. No test suite was run and
nothing under `src/`, `test/` or `docs/design/` was modified.

Verdicts: 11 CONFIRMED, 2 CORRECTED (7, 13 — both corrections cosmetic; the
substantive finding stands in each).

---

## 1. Enum-valued ports are refused with `IllegalPortType` — **CONFIRMED**

`leaf_types` returns empty for an `@enum` type, `place!` refuses, and
`probe_value` has no `Enum` method.

```
== 1. leaf_types(Phase) = Type[]
   Phase <: Enum: true
   REFUSED: BuildError: IllegalPortType: the root component: port `phase`
            declares Phase, which has no leaves
   probe_value methods:
     probe_value(::Type{Bool})                    @ src/declare.jl:327
     probe_value(::Type{T}) where T<:Real         @ src/declare.jl:326
     probe_value(::Type{P}) where P<:StaticArray  @ src/declare.jl:328
     probe_value(::Type{P}) where P               @ src/declare.jl:329
   probe_value(Phase): MethodError: no method matching Phase()
```

Mechanism as cited: `src/leaves.jl:27` is
`leaf_types(::Type{P}) where {P} = reduce(vcat, (leaf_types(FT) for FT in fieldtypes(P)); init = Type[])`,
and an `@enum` is a fieldless primitive that is not `<: Real`. `src/build.jl:276-279`
is the `IllegalPortType` push. Spec side holds: `docs/design/spec.md:331` —
"Ports exchange **immutable values** — typically isbits structs (floats,
`SVector`s," / `:332` "enums, nested immutables)"; `spec.md:3187-3188` —
"framework methods for `Real` (`zero(T)`), `Bool` (`false`), enums (first
instance)". Only four `probe_value` methods exist, none for `Enum`.

## 2. A `Vector{Float64}`-carrying port builds, then fails at the first gather — **CONFIRMED**

```
== 2. fieldtypes(Vector{Float64}) = (MemoryRef{Float64}, Tuple{Int64})
   leaf_types(Vector{Float64}) = Type[Int64, Int64]
   leaf_types(BulkField)       = Type[Float64, Int64, Int64]
   build OK
   Simulation OK
```

`p2b.jl`, with a consumer wired to the port, fails inside `init!`:

```
FAIL: MethodError
MethodError: no method matching Memory{Float64}(::Int64, ::Ptr{Nothing})
```

The same raw `MethodError` is what a port read (`port(snap, "", :f)`) produces
on the producer-only model. One refinement, not a correction: the failure is at
the first *gather of that cell*, so a published-but-never-read port lets `init!`
succeed (`p2.jl` prints `init! OK`); the moment anything gathers it — a
consumer's bundle or a snapshot read — the `MethodError` fires. Spec side holds:
`spec.md:348-350` — "The signal requirement, stated precisely, is **immutability
plus frozen references**: signals may reference bulk data (see §4.4) …".

## 3. `_accepts` is equality-modulo-embedding, not subtyping; both root cases hold — **CONFIRMED**

`src/build.jl:179-190` has no `<:` anywhere; the non-`Real`, non-`StaticArray`
arm is `P.name === V.name || return false`. Probe `p3.jl`:

```
== 3a. component-fed abstract struct entry ==
  FlatTerrain <: AbstractTerrain: true
  _accepts(AbstractTerrain, FlatTerrain, Float64) = false
  REFUSED: BuildError: WireTypeMismatch: `usr`.terrain declared AbstractTerrain,
           fed from `src`.terrain::FlatTerrain

== 3b. abstract struct entry AT ROOT ==
  REFUSED: ArgumentError: type does not have a definite number of fields

== 3c. Real entry at root ==
  REFUSED: BuildError: WireTypeMismatch: ``.i declared Real,
           fed from root input `i`::Int64
  probe_value(Real) = 0::Int64

== 3d. Real entry component-fed by Float64 ==
  REFUSED: BuildError: WireTypeMismatch: `k`.i declared Real,
           fed from `s`.o::Float64
```

Both reports are right about their own case, and neither generalizes: an
abstract *struct* root entry dies in `leaf_types`'s `fieldtypes` call with a
bare `ArgumentError` outside the `BuildError` carrier (agent B), while an
abstract `Real` root entry survives `leaf_types` (the `P <: Real` method returns
`Type[Real]`) and is refused later by `_probe_input` blaming the synthesized
`Int64` from `zero(Real)` (agent C). The split is exactly `P <: Real` vs. not.
Spec side holds: `spec.md:1082-1084` — "the producer's declaration at `Float64`
must be `<:` the consumer's entry at `Float64`"; `spec.md:1963-1964` repeats it.

## 4. `_root_input_type` takes the first consumer, so fan-out is order-dependent, and one order is D-168's rejected join — **CONFIRMED**

`src/build.jl:329` is `P = first(declared)`, and line 330's conflict check is
gated on `check`, set only at the nominal activation. Probe `p4b.jl`, a `Group`
fanning one root input into a `T` entry (`a`) and a `Float64` entry (`b`), at
`Dual{Nothing,Float64,1}`:

```
== a=Tolerant, b=Pinned ==
  nominal build OK
  Dual REFUSED: BuildError: WireTypeMismatch: `b`.u declared Float64, fed from
    root input `in`::ForwardDiff.Dual{Nothing, Float64, 1} — if this leaf
    participates in differentiation, declare it `T`
== a=Pinned, b=Tolerant ==
  nominal build OK
  Dual activation OK
```

The two models differ only in field order and disagree on legality. In the
first order the slot walks because one consumer tolerates — the join. D-168
(`docs/design/decisions.md`, status ratified) lists under **Rejected**: "*Join
semantics (the slot walks if any consumer tolerates):* unsound in the direction
that matters — it delivers `Dual`s to an entry that declared it cannot take
them". Ratified position is the meet: "the slot's cells **pin at every
activation if any consumer entry pins**". Spec side holds: `spec.md:2015-2016`.

## 5. Derivative and state-write conformance is `nleaves`, not leaf type at `T` — **CONFIRMED**

`src/build.jl:1055` and `src/build.jl:597` are both
`nleaves(typeof(ẋ[k])) == nleaves(typeof(x[k]))` after an exact `keys` test.
Probe `p5.jl`:

```
== Int64 derivative leaf for Float64 state: BUILD OK (accepted)
== SVector{3,Int64} for SVector{3,Float64}: BUILD OK (accepted)
== SMatrix{2,2} for SVector{4}: BUILD OK (accepted)
```

All three build and run. The third is a bonus beyond the claim: a
2×2 `SMatrix` derivative for an `SVector{4}` state field also passes, so the
weakness is leaf *count* in the strict sense, not just eltype. Spec side holds:
`spec.md:1306-1307` — "`Ẋ` has exactly `X`'s shape at the activation scalar. A
scalar leaf's derivative is a `T`, and an `SArray` leaf's is the same `SArray`
at `T`"; `spec.md:3423-3424` states the check.

## 6. The runtime table write converts, ignores extras, and surfaces a raw `FieldError` — **CONFIRMED**

Probe `p6.jl` diverges the stage's branch after the probe (a `Ref` flag flipped
between `init!` and `step!`), with both ports declared `T`:

```
== 6. runtime table write ==
  mode=int:     ACCEPTED; q = 1.0, r = 0.0
  mode=extra:   ACCEPTED; q = 0.0, r = 0.0
  mode=missing: RAISED Cadence.StepError
    StepError: in the root component output_direct, event round 1 of the frame
    from boundary 0 (t = 0.01):
      replay!(sim2, trc; to_boundary = 0) then step!(sim2) reproduces it
      cause: FieldError: type NamedTuple has no field `r`, available fields: `q`
```

`Int64` `1` is written and reads back `1.0`; the extra field is silently
dropped; the missing field is a raw `FieldError` framed by `StepError`. Write
path as cited, modulo one-line offsets: `run!(e::StageEntry, …)` at
`src/executor.jl:144` calls `scatter_group!` at `src/store.jl:81`, which is
`getfield(y, name)` per address-group name; no expected type, no reorder, no
`isa`. D-053 (ratified) lists under **Rejected**: "*Field-assignment `convert`
semantics:* `Float64 → Dual` silently zeroes partials — wrong Jacobian, no
error; `Int` sloppiness passing at nominal but detonating under `Dual` makes
'it runs' activation-dependent."

## 7. `AlgebraicCycle.members` is the whole unscheduled remainder — **CORRECTED**

The substance is confirmed; the ordering sub-claim is wrong.

Probe `p7.jl`, a two-component cycle `a ⇄ b` with `a/o → z/e → w/e` acyclic
downstream:

```
BuildError: AlgebraicCycle: algebraic loop through stage-2 ports: a → b → z → w
  — break it with a stage-1 (`output_state`) port …
kind = Cadence.AlgebraicCycle
members = ["a", "b", "z", "w"]
fieldnames = (:members,)
```

Two innocent downstream components are named as cycle members, the payload is
component paths (`String`), and there is one field — no port terminals, no SCC
partition.

**What is wrong:** the ordering is not alphabetical. `src/build.jl:245` is
`cycle = sort!(collect(remaining))` where `remaining::Set{Int}` holds *component
indices* (`src/build.jl:230`), so `sort!` orders by flatten index and the paths
come out in declaration order. Probe `p7b.jl`, children declared `(z, y, a)`:

```
members = ["z", "y", "a"]
alphabetical would be = ["a", "y", "z"]
```

**Corrected claim:** `AlgebraicCycle.members` is the whole unscheduled
remainder — cycle plus its innocent downstream cone — as component paths in
flatten (declaration) order, not one SCC per cluster in port form and not
alphabetical. `test/test_build.jl:59` asserting `sort(d.members) == [...]` masks
the ordering either way. D-012 (ratified) lists under **Rejected**: "*Naming the
cycle by the topological stall's raw residue:* over-reports — the residue holds
the innocent downstream cone", and its Position requires "cycle diagnostics from
SCC decomposition … (one SCC = one named loop)". `src/diagnostics.jl:582`
documents the field as "the SCC's member terminals, in slash form".

## 8. A container of containers is silently dropped — **CONFIRMED**

Probe `p8.jl`, `Nested(((Tiny(), Tiny()), (Tiny(),)))` with
`child_connections(::Nested) = ()`:

```
build OK
flat.paths = String[]
isempty = true
```

Three components vanish with no diagnostic. Mechanism as cited: `_children`
(`src/assembly.jl:91`) reaches `elseif v isa NamedTuple || v isa Tuple` at line
120, computes `n = count(e -> e isa AbstractComponent, v)` at 121, and takes
`n == 0 && continue   # inert data; an empty container too` at line 122. Spec
side holds: `spec.md:2382-2383` — "Containers of containers are rejected in the
first cut, deeper grouping being what assemblies are for."

## 9. Deployment validation runs under three sequential barriers — **CONFIRMED**

Probe `p9.jl`, a model with a continuous child and a `Absolute(Period(1//3))`
anchored discrete child:

```
build OK; anchors = Tuple{Rational{Int64}, Rational{Int64}}[(1//3, 0)]
bad firing_budget + missing h         -> 1 diagnostic(s): [(:firing_budget, :range)]
bad firing_budget + nonpositive h     -> 1 diagnostic(s): [(:firing_budget, :range)]
nonpositive h alone                   -> 1 diagnostic(s): [(:h, :range)]
h ok, Δt_base=1//100 (anchor 1/3)     -> 1 diagnostic(s): [(:Δt_base, :anchor_period)]
nonpositive h + non-dividing Δt_base  -> 1 diagnostic(s): [(:h, :range)]
h=1//100, n=0 (barrier2) + bad anchor -> 1 diagnostic(s): [(:n, :range)]
```

Line 2 is barrier 1 swallowing barrier 2; line 6 is barrier 2 swallowing barrier
3 (`n = 0` reported, the anchor `1//3` that the default `Δt_base = 1//100` cannot
express not reported). One-line offset in the citation: the `Simulation` barrier
throws at `src/sim.jl:159`, not 160 (`isempty(diags) || throw(BuildError(diags))`).
`bind_schedule` begins at `src/build.jl:718` and its first checks each `throw`
individually through line 752; the anchor loop collecting into `viol` runs at
758-774. Spec side holds: `spec.md:3027` — "Deployment validation is collected
like its declarative siblings ([§13.1]). Collected and reported as
`DeploymentInvalid`".

## 10. `activation` is an unguarded `get!` on a plain `Dict` — **CONFIRMED**

`src/build.jl:429-434`:

```julia
function activation(b::Build, ::Type{T}) where {T}
    T === Float64 && return b.nominal
    get!(b.cache, T) do
        first(_stratum_c(b.flat, b.tiers, b.order, b.nominal, T))
    end::Activation{T}
end
```

The field is `cache::Dict{DataType,Any}` (`src/build.jl:370`, "non-nominal
activations, lazily materialized"). No lock, no atomic, no `ReentrantLock`
anywhere near it; the docstring concedes the guarantee is met "by having none".
Spec side holds: `spec.md:3337` — "**Lazy materialization is torn-state-free**,
normatively: concurrent first requests for the same activation must never expose
partially populated cache state. The mechanism is unspecified — a guard around
insertion suffices"; `spec.md:3062-3063` — "**The `Build` is immutable and may
back any number of `Simulation`s, concurrently**".

## 11. A typo'd return field yields only `UndeclaredReturnField` — **CONFIRMED**

Probe `p11.jl`, a component declaring `(M = T, P_shaft = T)` whose
`output_state` returns `(M = 1.0, P_shft = 2.0)`:

```
kinds: DataType[Cadence.UndeclaredReturnField]
  ``: output_state returns `P_shft`, which `output_types` does not declare —
  declare it, or drop it from the return; the declared ports are `M`, `P_shaft`
```

One diagnostic, not two. `_check_ports` (`src/build.jl:152`) ends with
`isempty(viol) || throw(BuildError(viol))` at line 166, inside stage-1 probing,
so the `DeclaredNotProduced` pass at `src/build.jl:524-536` is never reached for
this model. Spec side holds: `spec.md:2317-2321` — "a probe error with
did-you-mean … against `output_types`, plus the unproduced-`P_shaft` error with
both the stage-product and state-field lists in hand."

## 12. Invariant-carrying and `Int` state leaves are admitted; `reconstruct` runs the constructor — **CONFIRMED**

Probe `p12b.jl`, with `UnitVec` normalizing in its inner constructor:

```
== 12a. invariant-carrying state leaf ==
  build OK
  state after init = (u = UnitVec([0.6, 0.8]),)
  reconstruct(@NamedTuple{u::UnitVec}, [3.0,4.0]) = (u = UnitVec([0.6, 0.8]),)
      <-- constructor ran on read
  flatten(x) = [0.6, 0.8]; reconstruct(flatten(x)) == x : true

== 12b. Int/Bool leaves in init_x ==
  build OK
  state after init = (n = 3, flag = true, q = 0.0)
  xbuf eltype = Float64; xbuf = [3.0, 1.0, 0.0]
  after one step: state = (n = 3, flag = true, q = 0.01)  xbuf = [3.0, 1.0, 0.01]
```

The `[3.0, 4.0]` line is the silent projection made visible: a buffer that has
drifted off the manifold reads back as `[0.6, 0.8]`, so no consumer and no probe
can see the divergence. Mechanism as cited: `_reconstruct_expr`
(`src/leaves.jl:69-91`) emits `Expr(:call, P, args...)` for a struct leaf, which
is ordinary public construction and therefore runs the normalizing constructor
on every view materialization. The `Int`/`Bool` leaves live in the `Float64`
`xbuf` as `3.0` and `1.0`. D-094 (ratified) lists under **Rejected**:
"*Invariant-carrying leaves with constructors run on read:*
`reconstruct(flatten(x)) ≠ x`: every consumer sees a silently projected value
over a runaway buffer … §10.4's off-manifold probes impossible." Its Position
closes the vocabulary to "plain real scalars and `SArray`s at the common
eltype — no domain wrapper types", which the `Int`/`Bool` case also violates.

## 13. `phase_bodies(sim)` returns exactly four bodies — **CORRECTED**

The finding is confirmed; one line citation in `c_build.md 4.17` is wrong.

Probe `p13.jl`, a model with one `StateEvent` and one `state_projection`:

```
keys(phase_bodies) = (:sweep_1, :sweep_2, :rhs, :ticks)
length = 4
Executor fields = (:act, :store, :xbuf, :ẋbuf, :sstores, :mstores, :clock,
                   :bodies, :events, :cursor, :xblocks)
EventSet entries = 1; projects = 1
EventSet names = [("", :zc)]
```

`phase_bodies(sim::Simulation) = sim.exec.bodies` at `src/sim.jl:316`. Guards,
handlers and projections go into `EventSet.entries` / `EventSet.projects`
(`src/executor.jl:242-262`), reachable only through the private `sim.exec.events`
field — `grep` finds no `events(`, `guards(`, `handlers(` or `projections(`
accessor in `src/`. `test/test_executor.jl:11` pins the key set:
`@test keys(b) === (:sweep_1, :sweep_2, :rhs, :ticks)`.

**Corrected claim:** the `bodies` NamedTuple is built at `src/build.jl:1006-1009`,
as `i_api.md 4.15` states, not `1002-1006` as `c_build.md 4.17` states (lines
1001-1003 are `proj_entries`). Spec side holds: `spec.md:3627-3628` — "Returned
with them are the per-event guards and handlers and the per-component
`state_projection` callables, keyed by the model's own roster."

---

## Minor line-citation drift (no verdict impact)

- `c_build.md 4.5`: the `Simulation` barrier throws at `src/sim.jl:159`, not 160.
- `c_build.md 4.11`: `run!(e::StageEntry, …)` starts at `src/executor.jl:144`
  (cited 145-149); `scatter_group!` starts at `src/store.jl:81` (cited 82-88).
- `c_build.md 4.17`: `bodies` is at `src/build.jl:1006-1009` (cited 1002-1006).

Every other cited span in the thirteen claims resolves exactly.
