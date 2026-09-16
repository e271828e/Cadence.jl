# Increment 36 — the feedthrough tracer and the SCC cycle diagnostic (§5.5, §5.6, D-012, D-140, D-245)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `98eb908` plus the docs-first commit below. Never `cd` elsewhere
(`cd` is aliased to zoxide in the user's shell; use absolute paths).

**Standing.** §5.5 rejects an algebraic loop at build, and §5.6 says how the
rejection is named and classified. The stalled subgraph of Stratum B's
topological sort decomposes into strongly connected components (SCCs); each
nontrivial SCC is one `AlgebraicCycle` naming its members and the wires
among them; and a schedule-free per-member trace at the probe point labels
the loop real or artificial, with the remedy ladder of §5.4 as the hint.
Today `schedule_stage2` (`build.jl` 298–332) throws Kahn's stall residue as
one fail-fast `AlgebraicCycle`: every component the schedule could not
place, downstream acyclic ones included, as component paths in flatten order,
two disjoint cycles merged into one diagnostic, a self-wire reported as a
one-member cycle with no wire. **Three stages, one commit each**, after the
docs-first commit the coordinator lands; suite green, `Pkg.test()` green at
every commit.

**Read, all in `docs/design/spec.md`:** §5.4 in full (886–955, the ladder
and the exact hint wording at 936–941); §5.5 (957–974); **§5.6 in full
(976–1061)** — the Rule paragraph (1001–1010) and the caveats paragraph
(1019–1033) are this increment's contract, the two modes (1035–1046) and
the boundaries paragraph (1048–1058) its mechanism; §9.3's first two
paragraphs (3242–3290, probe sourcing and `probe_value`); §9.4's tracer
sentence (3356–3370, read for the distinction only: the tracer *activation*
is not built here); Appendix C's `AlgebraicCycle` row (search
"**`AlgebraicCycle`**"). In `docs/design/decisions.md`: D-012 (447–472),
D-140 (4397–4457, the ladder's rationale, read the three rejections), D-245
(8861–8900, this increment's ruling on tangles and the mode field).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (110–144).
- The file-table rows for `src/Cadence.jl` (18), `src/diagnostics.jl`
  (20), `src/declare.jl` (21), `src/build.jl` (25), `test/fixtures.jl` (37).
- **"Authoring caveats" in full (60–108)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module, so payload fields naming a user type go through `_typename`.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–28) is
the one this increment retires, at stage 3.

**Stance: conservative reading.** Build what the sections below say. Where
the spec and this brief disagree, stop and say so in the report rather than
improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root. While iterating, `julia --project=test test/runtests.jl build
diagnostics assembly declare` covers the files this change reaches; gate
each commit on the full suite and on
`julia --project=. -e 'using Pkg; Pkg.test()'`. Commit subject: one
sentence, no body, no attribution. Do not push. Never stash, reset or check
out the working tree; a baseline is read with `git show <tip>:path`.

---

## The construct

Facts verified at `98eb908`, in a REPL, before this brief was written:

1. **Where the stall happens.** `_stratum_c` (`build.jl` 661–697) runs
   `probe_stage1`, then `auto_published`, then `schedule_stage2`, then
   `cell_layout`, then `probe_stage2`. At the stall there is no layout and
   no stage-2 product for any component. `schedule_stage2` runs only at the
   nominal activation (`order === nothing`, line 686), so everything below
   is `Float64` territory except the tracer's own evaluations.
2. **A self-wire is legal.** Stratum A admits
   `Group((plant = Plant(),); wires = ("plant/power" => "plant/u",))`; the
   scheduler reports `AlgebraicCycle(["plant"])`. A self-edge is a
   nontrivial SCC of size one.
3. **The residue shape.** Five `Gain`s wired `a↔b`, `c↔d`, `b→e` report as
   `AlgebraicCycle(["a","b","c","d","e"])`: two cycles merged, the tail
   included.
4. **The declaration walk at a foreign scalar.**
   `declarations(Plant(), CONTINUOUS, Float32)` yields `x.q ::
   SVector{2,Float32}`, `ins = (u = Float32,)`, `outs = (y = Float32, power
   = Float32)`. `probe_value(SVector{2,Float32})` is the zero vector.
5. **A `Real` subtype rides the machinery as-is.** A forty-line prototype
   (`Tracer{S} <: Real` with `val::Float64`, `deps::UInt64`; arithmetic as
   set union; comparisons throwing on `S = true`) went through
   `declarations`, `probe_value`, `reconstruct`, `SVector` promotion and
   `_accepts(T, Float64, T) === true`, and `output_direct` of `Plant`,
   `Sum`, `StateFeedback` and `Motor` returned tracers whose sets were the
   expected input faces. A `u.g > 0 ? u.a : u.b` threw the marker at
   `S = true` and reported the taken arm at `S = false`.
6. **Leaf lifting must be leaf-wise.** `_embed` (`build.jl` 208) and
   `retype_value` (`leaves.jl` 239–242) build `T[T(l) for l in
   _leaf_values(v)]`, converting *every* leaf through `T`. At a `Dual` a
   `Bool` or `Int` leaf survives the round trip and an enum leaf does not
   (`pending.md`'s Retire-alone bullet records that defect); a `Tracer`
   converts none of them back. `reconstruct` accepts any `AbstractVector`
   buffer (it indexes and lets the constructor convert), so the tracer lifts
   with an `Any` buffer that touches `Float64` leaves only. Do not change
   `_embed` or `retype_value` here; their fix is a separate local commit.

### The diagnostic (all three stages construct it)

`src/diagnostics.jl` 716–723 becomes:

```julia
"""
§5.5, §5.6: one strongly connected cluster of the stage-2 feedthrough graph.
`members` are component paths in walk order and `wires` the cluster's own
wires as `producer/port => consumer/face`, in the same order. The
classification is D-245's graph verdict, `nothing` when a member's
evaluation threw; `dead` lists every hop the trace found unrouted, as
(member, input face, output port); `traced` records each member's mode,
`:global`, `:sampled` or `:structural`.
"""
Base.@kwdef struct AlgebraicCycle <: Diagnostic
    members::Vector{String}
    wires::Vector{Pair{String,String}}
    classification::Union{Nothing,Symbol} = nothing
    dead::Vector{Tuple{String,Symbol,Symbol}} = Tuple{String,Symbol,Symbol}[]
    traced::Vector{Pair{String,Symbol}} = Pair{String,Symbol}[]
end
path(d::AlgebraicCycle) = first(d.members)
```

**Walk order.** Members: depth-first preorder along the cluster's wires
(producer → consumer), starting at the member with the lowest flatten index,
neighbours visited in flatten order. Wires: sorted by (position of the
producer in `members`, position of the consumer in `members`, port name,
face name). `feedback_model(feedback_port = "power")` therefore reads
`members == ["plant", "sum", "ctl"]` and `wires == ["plant/power" =>
"sum/b", "sum/e" => "ctl/e", "ctl/out" => "plant/u"]`, one readable loop.

**Message.** Three forms, one line each, built from helpers beside the kind
(`_wirelist`, `_hop`, `_modes`):

- Unclassified: ``algebraic loop among `plant`, `sum`, `ctl`: plant/power →
  sum/b, sum/e → ctl/e, ctl/out → plant/u — break it with a state, a unit
  delay or a stage-1 (`output_state`) port (§5.5)``.
- Real: the same head, then `` — real: a loop survives the trace (traced
  globally)`` and, per dead hop, ``; `i`'s `y` does not route `b`, a wire
  the loop does not need``; then the §5.5 remedy sentence. The mode phrase
  is "traced globally" when every member is `:global`, otherwise the
  non-global members each as "`m` at sampled states" or "`p` structurally",
  joined by ", ", followed by ", the rest globally" when any member is
  global.
- Artificial: the head, then `` — artificial at port level: `d`'s `y` does
  not route `b``, per dead hop, joined by ", ", a hop found by sampling
  carrying " (on the sampled paths; an untaken branch may still route
  it)"; then ``; split `d`, or narrow the neighbor's contract if `b` is
  consumed only in a fallback branch (§5.4)``, naming each dead member
  once. A dead hop is never structural, so the hint is continuous-only by
  construction (§5.6).

Collected policy (Appendix C): the stall throws
`DiagnosticError(diags::Vector{Diagnostic})`, one entry per cluster, in
ascending order of each cluster's lowest flatten index.

### The tracer scalar (stage 2), in a new `src/tracer.jl`

Included right after `build.jl` in `src/Cadence.jl`. It calls
`_bundle_values`, `_probe_input`, `cell_layout` and `_probe_direct!` from
`build.jl` and `bundle_names`/`declarations`/`probe_value` from
`declare.jl`; dispatch resolves at call time, so the include order matters
only for the type, which nothing before it names.

```julia
"""
§5.6's set-propagation scalar. Every leaf carries the set of in-cycle input
faces it may depend on, as a bitmask, unioned by every operation; `val` is a
primal the local mode branches on. `S = true` is the global, value-blind
tracer: a comparison or a value-severing conversion touching a tagged operand
throws `Undecidable`, since either arm would drop the other's set. `S = false`
is the local tracer: it decides on `val` and reports the taken path (D-012).
"""
struct Tracer{S} <: Real
    val::Float64
    deps::UInt64
end
struct Undecidable <: Exception end                 # a marker, never rendered
```

Methods, all on `Tracer{S}` returning `Tracer{S}`:

- constructors and conversion: `Tracer{S}(x::Real)` (untagged), identity on
  a `Tracer{S}`, `promote_rule(::Type{Tracer{S}}, ::Type{<:Real})`,
  `convert`, `zero`, `one`, `float`, `Float64(x::Tracer{false})` (severing,
  the documented blind spot) and `Float64(::Tracer{true})` throwing the
  marker;
- binary set-union: `+ - * / ^ atan hypot min max muladd copysign rem mod`
  and `^(::Tracer, ::Integer)`, `clamp(x, lo, hi)` as `min(max(x, lo),
  hi)`, `ifelse(b, x::Tracer, y::Tracer)` as the union of both
  (branch-free by definition);
- unary pass-through: `- abs abs2 sqrt cbrt exp log log2 log10 sin cos tan
  asin acos sinh cosh tanh sign inv floor ceil round trunc`;
- the deciders: `< <= == isless iszero isnan isfinite isinf signbit`, and
  `Int`/`Bool`/`round(Int, ·)`/`floor(Int, ·)`/`trunc(Int, ·)`, decide on
  `val` when the operands' union set is empty **or `S === false`**, and
  throw `Undecidable()` otherwise. State, modes, parameters and time carry
  empty sets, so a branch on them decides at the probe state in either mode
  (§5.6's boundaries paragraph).

Anything not listed raises a `MethodError`, which the classifier treats as
"the member threw". Do not reach for `DiffRules` or add a dependency for
this list.

### Classification (stage 2 global and structural, stage 3 sampled)

`classify!(d::AlgebraicCycle, scc::Vector{Int}, edges, placed::Vector{Int},
flat, tiers, decls, stage1, published, mstores)` fills `classification`,
`dead` and `traced`, or returns leaving all three at their defaults. The
whole body runs under one `try`; any exception other than `Undecidable`
(handled per member, below) or `InternalInvariant` (rethrown) means the
diagnostic ships unclassified. Steps:

1. **The prefix's products.** `layout = cell_layout(flat, decls, Float64)`;
   `products = NamedTuple[merge(s1, pub) …]` as `probe_stage2` builds it;
   then `_probe_direct!(products, ci, …, Float64)` for each `ci in placed`.
   `_probe_direct!` is the body of `probe_stage2`'s `for ci in order` loop
   (`build.jl` 739–757) factored into a function that mutates
   `products[ci]` and returns nothing; `probe_stage2` calls it in that loop
   and is otherwise unchanged.
2. **Per member `ci`**, with `c = flat.comps[ci]`, its in-cluster input faces
   `fs` (the faces whose producer is in `scc`, in `decls[ci].ins` order) and
   its out-cluster ports `qs` (ports with a cluster wire out):
   - A discrete member, or a member with more than 64 in-cluster faces, is
     `:structural`: every hop alive, no map.
   - Otherwise the tag of face `fs[i]` is `UInt64(1) << (i - 1)`. A face
     whose entry type at `T` has no `T` leaf (`leaf_types` holds no
     `Tracer`) is untraceable: its hops are alive and it is seeded
     untagged. A port whose declared type at `T` has no `T` leaf is
     untraceable the same way. If no hop of the member is traceable, the
     member is `:structural`.
   - **Global evaluation**, at `T = Tracer{true}`: `dT = declarations(c,
     CONTINUOUS, T)`; `u` per face of `decls[ci].ins`: an in-cluster face
     from `_tag(T, probe_value(declarations(producer, t, T).outs[pport]),
     bit)`; a face fed by a placed component from
     `_lift(T, products[pi][pport])`; a face fed by an unplaced component
     outside the cluster from `probe_value` on the producer's declared
     type at `T`, untagged; a root input from `probe_value(retype(T,
     flat.root_types[k]))`. `x = dT.x`, `m = mstores[ci]`, `ws =
     init_workspace(c, T)` when declared, `y_x = _lift(T, stage1[ci])`, all
     through `_bundle_values(bundle_names(output_direct, c, CONTINUOUS,
     keys(stage1[ci])), …)`. Evaluate `output_direct(c, bundle)`. The map
     is `q => faces whose bit is set in the union over the `Tracer` leaves
     of y2[q]` for `q in qs`; a `Float64`-returned port has an empty set
     (the constant-branch idiom, D-166). Record `:global`.
   - On `Undecidable`: stage 2 leaves the whole diagnostic unclassified
     (treat it as a throw); stage 3 replaces that arm with the **sampled
     evaluation** at `T = Tracer{false}`: `rng = Xoshiro(0)` per member,
     eight evaluations, each with the `Float64` leaves of `decls[ci].x` and
     of the in-cluster faces drawn from `randn(rng)` (`_sample(rng, T, v,
     bit)`: the same walk as `_tag`, primal randomized), everything else as
     in the global evaluation; the map is the union over the eight. Record
     `:sampled`. A non-marker throw here ships unclassified like any other.
3. **The verdict.** Build the port graph: a node per cluster wire endpoint;
   an edge per wire (`producer/port → consumer/face`); inside member `ci`,
   an edge `face → port` for every `(f, q)` with `f` an entering face and
   `q` a leaving port, iff the hop is alive: structural, untraceable, or
   `f ∈ map[q]`. `classification = :real` iff the graph has a cycle
   (depth-first search), else `:artificial`. `dead` is every traced hop
   `(path, f, q)` with `f ∉ map[q]`, in member order then `decls` order,
   under either verdict (D-245). `traced` is every member with its mode,
   in `members` order.

The helpers `_lift(T, v)`, `_tag(T, v, bit)`, `_sample(rng, T, v, bit)`
share one walk: `reconstruct(retype(T, typeof(v)), Any[…], 0)` over
`_leaf_values(v)`, touching `Float64` and `Tracer` leaves only. An opaque
leaf (D-237) passes through untouched; if `retype` or `reconstruct` refuses
one, the member throws and the diagnostic ships unclassified — note the
case in the report if a fixture reaches it, do not design around it.

## Docs-first commit (coordinator, landed before launch)

§5.6's verdict paragraph became D-245's Rule (a cycle surviving the traced
port graph; every dead hop listed under either verdict), its caveats
paragraph gained the untraceable-face rule and the per-member mode, its
throw sentence now ships "members and wires alone, unclassified", and
Appendix C's row carries the wires as terminal pairs, every dead hop as
(member, input face, output port) and the mode per member. D-245 records
the ruling and its three rejections. Battery green.

## Stage 1 — SCC decomposition, wires, collected policy (Opus)

`src/build.jl`, section 3 (289–332):

- `schedule_stage2` keeps its signature and its Kahn loop. Beside `deps`,
  build `edges::Vector{Vector{Tuple{Int,Symbol,Symbol}}}` per consumer:
  `(pi, pport, face)` for every stage-2 dependence, the provenance Kahn
  discards. Kahn runs on `deps` exactly as today, so the schedule of every
  acyclic model is unchanged (`build_schedule` asserts the order).
- On a stall, `_cycle_diagnostics(flat, edges, remaining)`: Tarjan's
  algorithm over the subgraph induced on `remaining` (edges from `edges`,
  both ends in `remaining`), recursive is fine; nontrivial SCCs are those
  of size above one or with a self-edge; each becomes an `AlgebraicCycle`
  with `members` and `wires` in walk order, the other fields at their
  defaults; throw `DiagnosticError(diags)` with the clusters in ascending
  order of their lowest flatten index. Components in `remaining` that lie
  in no nontrivial SCC (the downstream tail) appear in no diagnostic.
- Amend the section docstring (291–297): the residue is decomposed, not
  reported.

`src/diagnostics.jl` 716–723: the struct above, `path`, and the three
message forms; at this stage only the unclassified form is reachable, but
write all three now so stage 2 touches no message.

`test/fixtures.jl`: a new section `# --- the algebraic-cycle coverage set
(§5.5, §5.6) ---` before "the reference models" (776), holding at this
stage nothing new — the tests below build from `Plant`, `Gain`, `Sum`,
`AutoPlant`, `StateFeedback` inline, as `build_auto_publication` already
does. Stage 2 fills the section.

`test/test_build.jl`:

- `build_schedule` (61–80): the loop test at 72–75 becomes `d =
  only(diagnostics(failure(() -> build(feedback_model(feedback_port =
  "power")))))`, asserting `d isa AlgebraicCycle`, the walk order above for
  `members` and `wires`, `classification === nothing`, `dead` and `traced`
  empty. The `DiagnosticError{AlgebraicCycle}` form is gone; assert the
  carrier is `DiagnosticError{Vector{Diagnostic}}` once here.
- `build_auto_publication` (104–109): the same conversion; `members ==
  ["plant", "g"]`, `wires == ["plant/power" => "g/e", "g/out" =>
  "plant/u"]`.
- A new function `build_algebraic_cycles()` registered after
  `build_schedule` in `test_build()` (897–911), testsets:
  - "each cluster is one diagnostic and the tail is in none (§5.6, D-012)":
    the five-`Gain` model of fact 3 yields two diagnostics, `members ==
    ["a", "b"]` and `["c", "d"]`, each with two wires; `"e"` appears in
    neither; the carrier is collected.
  - "a self-wire is a one-member cluster with its wire (§5.6)": the model
    of fact 2 yields one diagnostic, `members == ["plant"]`, `wires ==
    ["plant/power" => "plant/u"]`.
  - "a tangle is one cluster with every wire among its members (§5.6,
    D-245)": `s = Sum()`, `g = Gain(1.0)`, `i = DerivativeFed()` — this
    fixture is stage 2's; at stage 1 use a third `Gain` in its place with
    `s/e => i/e`, `i/out => s/b` — three members `["s", "g", "i"]`, four
    wires in the sorted order.
  - "the message names the loop (§5.5)": `occursin("plant/power → sum/b,
    sum/e → ctl/e, ctl/out → plant/u", message(d))` on the feedback loop.
- `test/test_diagnostics.jl` 328: `AlgebraicCycle(members = ["a/b",
  "a/c"], wires = ["a/b/y" => "a/c/u", "a/c/y" => "a/b/u"])` plus one entry
  with `classification = :artificial, dead = [("a/c", :u, :y)], traced =
  ["a/b" => :global, "a/c" => :sampled]` and one with `classification =
  :real, traced = ["a/b" => :structural, "a/c" => :structural]`, so every
  message arm renders.

**Commit:** "Name each algebraic loop by its strongly connected cluster and
its wires, collected (§5.6, D-012)".

## Stage 2 — the tracer scalar, global and structural classification (Opus)

`src/tracer.jl` as specified: the scalar, its methods, `_lift`/`_tag`,
`classify!`, and `_probe_direct!` factored out of `probe_stage2` in
`build.jl` (put the factored function in `build.jl` beside `probe_stage2`).
`src/Cadence.jl`: `include("tracer.jl")` after `build.jl`.

`schedule_stage2` gains the arguments `classify!` needs (`decls`, `stage1`
is already there, `mstores`) and passes Kahn's `order` at the stall as
`placed`; `_stratum_c` (686) passes them. `_cycle_diagnostics` calls
`classify!` on each diagnostic before throwing.

`test/fixtures.jl`, the new section:

```julia
"""
Consumes `b` in `state_derivative` only: stage 2 routes `a` and not `b`, so a
loop closed through `b` is §5.4's last paragraph, artificial at port level.
"""
struct DerivativeFed <: AbstractComponent end
init_x(::DerivativeFed) = (q = 0.0,)
input_types(::DerivativeFed, ::Type{T}) where {T <: Real} = (a = T, b = T)
output_types(::DerivativeFed, ::Type{T}) where {T <: Real} = (y = T,)
output_direct(::DerivativeFed, (; u)) = (y = 2u.a,)
state_derivative(::DerivativeFed, (; u)) = (q = u.b,)

"""`Gain` with both ends pinned `Float64`: no tracer scalar can enter, so its hops trace structurally."""
struct PinnedGain <: AbstractComponent end
input_types(::PinnedGain, ::Type{T}) where {T <: Real} = (e = Float64,)
output_types(::PinnedGain, ::Type{T}) where {T <: Real} = (out = Float64,)
output_direct(::PinnedGain, (; u)) = (out = 2u.e,)

"""`Gain` asserting its return `Float64`: fine at the nominal probe, a throw at any other scalar."""
struct TypedGain <: AbstractComponent end
input_types(::TypedGain, ::Type{T}) where {T <: Real} = (e = T,)
output_types(::TypedGain, ::Type{T}) where {T <: Real} = (out = T,)
output_direct(::TypedGain, (; u)) = (out = (2u.e)::Float64,)
```

`test/test_build.jl`, `build_algebraic_cycles()` gains:

- "a loop every hop routes is real (§5.6)": the feedback loop through
  `power`: `classification === :real`, `dead` empty, `traced == ["plant"
  => :global, "sum" => :global, "ctl" => :global]`; the self-wire likewise
  real.
- "a hop stage 2 does not route makes the loop artificial (§5.4, §5.6)":
  `Group((d = DerivativeFed(), g = Gain(1.0)); wires = ("d/y" => "g/e",
  "g/out" => "d/b"), inputs = "a" => "d/a")`: `:artificial`, `dead ==
  [("d", :b, :y)]`, `traced == ["d" => :global, "g" => :global]`, and the
  message contains "artificial at port level", "`d`'s `y` does not route
  `b`", "split `d`, or narrow". The same model wired through `a` (`"g/out"
  => "d/a"`, `inputs = "b" => "d/b"`) is `:real`.
- "a tangle is real through its surviving loop and lists the dead chord
  (D-245)": `Group((s = Sum(), g = Gain(1.0), i = DerivativeFed()); wires
  = ("s/e" => "g/e", "g/out" => "s/a", "s/e" => "i/b", "i/y" => "s/b"),
  inputs = "a" => "i/a")`: `:real`, `dead == [("i", :b, :y)]`, message
  contains "a wire the loop does not need". Replace stage 1's third-`Gain`
  stand-in with this.
- "a discrete member traces structurally (§5.6)": `Group((p =
  DiscreteMap(), q = DiscreteMap()); wires = ("p/b" => "q/a", "q/b" =>
  "p/a"))`: `:real`, `traced` both `:structural`, message contains
  "structurally".
- "a pinned face traces structurally (§5.6, D-245)": two `PinnedGain`s in
  a loop: `:real`, both `:structural`.
- "a member that throws ships the cluster unclassified (§5.6)": two
  `TypedGain`s in a loop: `classification === nothing`, `traced` empty,
  `members` and `wires` filled, message is the unclassified form.
- "out-of-cycle inputs come from the prefix and never tag (§5.6)": the
  tangle above with a `Gain` placed upstream feeding `i/a` from a root
  input through it (`inputs = "a" => "pre/e"`, `"pre/out" => "i/a"`): the
  same verdict and `dead`, and `"pre"` in no `members`.
- The scalar itself, one testset "the tracer unions sets and refuses a
  tainted branch (§5.6)": `Tracer{true}(1.0, 0b01) + Tracer{true}(2.0,
  0b10)` has `deps == 0b11`; `clamp(Tracer{true}(5.0, 0b1), 0.0, 1.0)`
  keeps its set; `Tracer{true}(1.0, 0b1) < Tracer{true}(0.0, 0)` throws
  `Undecidable`; the same on `Tracer{true}(1.0, 0)` operands is `false`;
  `Tracer{false}(1.0, 0b1) < Tracer{false}(2.0, 0b10)` is `true`. Add
  `Tracer` and `Undecidable` to `test/imports.jl`.

`test/test_diagnostics.jl`: the three constructed entries from stage 1
stand.

**Commit:** "Classify each algebraic loop by a global set-tracer at the
probe point, structural where no scalar enters (§5.6, D-012, D-245)".

## Stage 3 — the sampled fallback and the registers (Opus)

`Project.toml`: add `Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"` under
`[deps]` (a stdlib, no compat entry); `src/Cadence.jl`: `using Random:
Xoshiro, randn`. `src/tracer.jl`: `_sample` and the sampled arm of
`classify!` as specified, eight samples, seed 0, per member.

`test/fixtures.jl`, the section gains:

```julia
"""
A branch on an input: the global tracer refuses it and the sampled one
reports the taken paths. `f` is routed on both arms and `g` on neither, so a
loop through `f` is real and one through `g` artificial, both found by
sampling; `v` is the branch's subject and stays outside every loop.
"""
struct Piecewise <: AbstractComponent end
init_x(::Piecewise) = (q = 0.0,)
input_types(::Piecewise, ::Type{T}) where {T <: Real} = (v = T, f = T, g = T)
output_types(::Piecewise, ::Type{T}) where {T <: Real} = (F = T,)
output_direct(::Piecewise, (; u)) = (F = u.v > 0 ? u.f : -u.f,)
state_derivative(::Piecewise, (; u)) = (q = u.g,)
```

`test/test_build.jl`, `build_algebraic_cycles()` gains "an input-dependent
branch falls back to sampled states (§5.6, D-012)": `Group((m =
Piecewise(), g1 = Gain(1.0), g2 = Gain(1.0)); wires = ("m/F" => "g1/e",
"g1/out" => "m/f", "m/F" => "g2/e", "g2/out" => "m/g"), inputs = "v" =>
"m/v")` is `:real` with `dead == [("m", :g, :F)]` and `traced == ["m" =>
:sampled, "g1" => :global, "g2" => :global]`, message containing "`m` at
sampled states"; the same model without `g1` (`m/F => g2/e, g2/out => m/g`
only) is `:artificial`, message containing "on the sampled paths".
Determinism: build it twice and assert the two diagnostics are `==`.

**Timing, for the report only:** in a fresh process, `@elapsed` the first
`build` of the tangle fixture and of the `Piecewise` fixture (cold, tracer
compilation included) and a second build of each (warm); record the four
numbers.

### Register edits

- `docs/design/pending.md`: delete the first "Not yet built" bullet
  (21–28). Nothing else mentions the tracer or the residue.
- `docs/design/implementation.md`:
  - `src/Cadence.jl` row (18): unchanged text (`Random` is a dependency
    the row's phrase already covers).
  - `src/build.jl` row (25): "the feedthrough graph" becomes "the
    feedthrough graph with its edge provenance, Kahn's schedule and, at a
    stall, the SCC decomposition into one `AlgebraicCycle` per cluster
    (§5.6, D-012), `_probe_direct!` shared with the classifier's prefix
    probe"; add `§5.5`, `§5.6`, `D-012`.
  - A new row after `src/build.jl`: `| src/tracer.jl | §5.6's
    set-propagation scalar `Tracer{S}` (global on `true`, local on
    `false`, `Undecidable` the marker between them), the leaf-wise lift
    and tag walks, and `classify!` — the schedule-free per-member trace at
    the probe point, its prefix probe, D-245's port-graph verdict and the
    sampled fallback at a fixed seed | §5.4, §5.6, §9.3, D-012, D-140,
    D-245 |`.
  - `test/fixtures.jl` row (37): unchanged.
- From `docs/design`, run `julia --project=@. tools/check_refs.jl` and
  `julia --project=@. tools/check_rows.jl`; both must pass.

**Commit:** "Fall back to a sampled set-tracer where the global one meets an
input branch, and retire the tracer's pending bullet (§5.6, D-012)".

## Verification

- Full suite green and `Pkg.test()` green at each of the three commits.
- `rg -n "stall residue|Kahn's stall" src/ docs/design/pending.md
  docs/design/implementation.md` returns nothing after stage 3.
- `rg -n "DiagnosticError\{AlgebraicCycle\}" test/` returns nothing after
  stage 1.
- `rg -n "_probe_direct!" src/` lists the definition and two call sites.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals per stage.

## Report format

Per stage, under 300 words: the commit hash; the files touched; any test
you could not write as specified and why, with file:line; any place the
spec, D-245 and this brief disagreed; the assertion totals; the four timing
numbers (stage 3); any member that reached the opaque-leaf limit or a
missing `Tracer` method in a fixture; friction with this brief, especially
any line number that had drifted.
