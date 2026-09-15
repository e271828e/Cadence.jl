# Increment 35 — the load-bearing walk (§13.3, §14.2, D-061, D-130)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `f941c50` (plus the docs-first commit below). Never `cd` elsewhere
(`cd` is aliased to zoxide in the user's shell; use absolute paths).

**Standing.** §13.3 gives the path-resolution primitive two duties on two
registers. The structural register (wiring) enforces §6.1's one-level rule,
and it is built (`_one_level`, D-207). The load-bearing register (condition
entries, trim `reads`, taps) enforces the generic-holding rule: the walk
follows *declared field types* alongside instances, and a segment that
traverses **past** a generically held field is a diagnostic even though the
instance in hand would resolve it. Today nothing walks. `_component`
(`conditions.jl` ~397) and `_read_component` (`readers.jl` ~257) look the
compiled absolute path up in `flat.paths`, so §14.2's locality law rides as
convention, and a mistyped path gets no did-you-mean anywhere. **One stage,
one commit**, after the docs-first commit the coordinator lands; suite green,
`Pkg.test()` green.

**Read, all in `docs/design/spec.md`:** §13.3 in full (7412–7492; the table
at 7448–7452 and the two-reasons paragraph at 7453–7468 are the construct);
§14.2's locality-law paragraph (8171–8186); §14.3's check list (8212–8224);
§6.1's enforcement sentence (1100–1102) and its generic-seam sentence
(1092–1094); §8.5's container-concreteness bullet (2453–2457); the glossary's
generic-holding entry (11139–11142); Appendix C's `PathResolution` row
(10750–10754), `ConditionResolution` row (10922–10928; the sub-kind sentence at 10926–10928) and `TapResolution` row
(10936–10939). In `docs/design/decisions.md`: D-061 (1655–1675, the
declared-type walk), D-130 (3755–3787, the register scoping — read the three
rejections), D-125 (3603–3640, why a deep read past a generic seam is a
`get_face`). Do not open §14.9 or §14.10; mounting and taps are not built and
this increment does not build them.

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- "Running the suite" (110–144).
- The file-table rows for `src/diagnostics.jl` (20), `src/assembly.jl` (22),
  `src/readers.jl` (26), `src/conditions.jl` (35), `src/trim.jl` (36).
- **"Authoring caveats" in full (60–108)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–23) is the
one this increment retires; two clauses elsewhere retire with it (below).

**Stance: conservative reading.** Build what the sections below say. Where
the spec and this brief disagree, stop and say so in the report rather than
improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository
root. While iterating, `julia --project=test test/runtests.jl assembly
conditions readers trim diagnostics` covers the files this change reaches;
gate the commit on the full suite and on
`julia --project=. -e 'using Pkg; Pkg.test()'`. Commit subject: one
sentence, no body, no attribution. Do not push. Never stash, reset or check
out the working tree; a baseline is read with `git show <tip>:path`.

---

## The construct

Three facts, each verified at `f941c50`:

1. **A declared holding reads off the type's definition, not the instance.**
   `fieldtype(Base.unwrap_unionall(typeof(c).name.wrapper), f)` is the field
   type as written: a `TypeVar` for a field typed by a parameter
   (`GenericHold{L}.inner` → `L<:AbstractComponent`), the abstract type for
   a directly abstract field, `Tuple{P,P}` for a concrete container,
   `NTuple{N,L}` (non-concrete) for a parametric one. A child is **held
   concretely** iff that type is not a `TypeVar` and `isconcretetype` holds.
   A container element follows its container's declared type (§8.5's
   "same concreteness discipline"): a concrete tuple type has concrete
   elements, and every other container holds generically. Note the
   consequence: `Group{C<:NamedTuple,…}` holds `children::C`, so **every
   child of a `Group` is generically held**. A two-segment path from a
   `Group` root refuses in this register; the remedies below apply.
2. **The rule is evaluated at the authoring level.** For conditions, each
   `at` prefix is walked from the component at the level where the `Scoped`
   node sits, the level its enclosing `at`s compiled. `at("a", at("b",
   frag))` therefore resolves `a` *to* a child (legal, generic or not), then
   `b` from `a`'s instance; `at("a/b", frag)` traverses past `a` and is
   legal only if `a` is held concretely. The nested spelling is §14.2's
   pull-composition idiom, and it is the remedy the refusal names. For
   `reads`, no mounting exists, so every selector path is authored at the
   root and walked from it in full: `get_state("a/b", :q)` needs `a`
   concrete; `b` may be generic. The remedy is a face read (`get_face`,
   D-125) or a concrete declaration.
3. **The walk is one site.** §13.3 closes on "one splitter and one
   did-you-mean site", and Appendix C's `PathResolution` row carries the
   read side's payload ("for a read-side traversal past a generically-held
   field, that field's declared type"). So the walk records
   `PathResolution` for both of its refusals, an unknown segment (with the
   sibling list) and a past-generic segment (with the declared type), on
   every client. The clients keep their own kinds for what lies beyond the
   walk: a prefix that lands on an assembly (`:assembly_path`), an
   undeclared field, an unconvertible value. Their `:unknown_path` arms
   retire, with the docs-first edit below.

The suite uses no multi-segment path in any `at` or read selector (verified
by grep), so no existing fixture meets the new refusal.

## Docs-first commit (coordinator, before launch)

Appendix C's `ConditionResolution` sub-kind sentence (10926–10928) reads "Its sub-kinds
are unknown path, undeclared field, unconvertible value and unexported
root-input face." It becomes "Its sub-kinds are assembly path, undeclared
field, unconvertible value and unexported root-input face. An unknown or
past-generic path is `PathResolution`'s ([§13.3][s13-3])." Battery green.
Commit: "Route the condition register's path refusals to `PathResolution`
(§13.3, Appendix C)".

## Stage 1 — the walk, its clients, tests and registers (Opus)

### The root on the `Flat`, in `src/assembly.jl`

`Flat` (542–553) gains `root::Any` as its first field: the tree the paths
index, which the load-bearing walk resolves against. `Walk()` (573) becomes
`Walk(root)` and `build` (`build.jl` 472) passes its root; `wire!` returns
`w.flat` (714), so nothing else constructs one. Add the field to the
struct's docstring in one clause.

### The walk

Beside `_one_level` (274–300), the load-bearing register's twin:

```julia
"""
The load-bearing register's walk (§13.3, D-130): `path`'s segments from
`level`, the component at `base`, following the declared field types
alongside the instances. Resolving *to* a generically held child is legal;
traversing *past* one is the refusal, whatever the instance in hand — the
authoring level speaks its own fields and its declared children's names
(§14.2), and a deep path is legitimate exactly within an owned concrete
subtree. Returns the component the path names, primitive or assembly, or
`nothing` after recording the refusal against `entry`. The empty path names
`level` itself.
"""
function resolve_authored(entry::String, base::String, level, path::AbstractString,
                          diags::Vector{Diagnostic})
```

- Segments split on `/`; the empty path returns `level`.
- Per step: `kids, fields = _children(at, here)`; match `segs[i]`, and where
  that fails with a segment to spare, `segs[i] * "/" * segs[i+1]`
  (`_one_level`'s two-segment lookahead, the D-211 container naming; a
  matched pair consumes two segments). No match records
  `PathResolution(entry, spelling = path, reason = :unknown_child, owner =
  _at(at), segment = segs[i], candidates = [first(k) for k in kids])` and
  returns `nothing`.
- If segments remain after the match and the child is not held concretely,
  record `PathResolution(entry, spelling = path, reason = :past_generic,
  owner = _at(base), segment = seg, level = _join(at, seg), declared =
  <the declared type>)` and return `nothing`.
- Otherwise descend: `here, at = kid, _join(at, seg)`.

The holding test, beside it:

```julia
# A child's holding, read off the type's definition rather than the instance:
# a field typed by a parameter is a `TypeVar` there, whatever the
# instantiation filled in (§8.5, D-061). Container elements follow their
# container's declared type.
_declared_holding(c, field::Symbol) =
    fieldtype(Base.unwrap_unionall(typeof(c).name.wrapper), field)
_held_concretely(c, field::Symbol) =
    (ft = _declared_holding(c, field); !(ft isa TypeVar) && isconcretetype(ft))
```

`_children` re-runs the container collision checks and throws on its own
when they fail; the build proved the tree clean, so here it only hands the
list back. Say so in a comment rather than guarding.

Amend the section comment at 303–307 ("The four the declaration surface
calls…"): the public `resolve`/`resolve_terminal` are the structural
register; `resolve_authored` is the load-bearing one, entered by the
services with an entry to attribute the refusal to.

### `PathResolution`, in `src/diagnostics.jl` (361–391)

- `reason` gains `:past_generic`; a new field `declared::Any = nothing`, the
  offending field's declared type (a `TypeVar` or a non-concrete type).
- Message for the arm: "`entry`: `spelling` reaches past `level`, which
  `owner` holds through the non-concrete declared type `declared` — a path
  in this register stops at a generically held child or stays within a
  concretely declared subtree: address the child at its own level, read a
  face it exports, or declare the field's concrete type (§13.3, §14.2)".
  Render `declared` with `_typename` when it is a `Type` and `string` when
  it is a `TypeVar` (`_typename` is `nameof`, which a `TypeVar` lacks; add
  the one-line method beside it rather than branching in the message).
- The `:unknown_child` message is register-neutral already; leave it.

### Conditions, in `src/conditions.jl`

`_flat` (153–199) carries the instance at the current level: signature
`_flat(n, path, level, prov, pos, flat, diags)`, entered from
`_resolve_entries` (318) as `_flat(node, "", flat.root, "", (), flat,
diags)`. `Fragment`, `Combined` and `Override` pass `level` through
unchanged. `Scoped`:

```julia
function _flat(n::Scoped, path::String, level, prov::String, pos::Tuple,
               flat::Flat, diags::Vector{Diagnostic})
    entry = _step(prov, "at(\"$(n.prefix)\")")
    kid = resolve_authored(entry, path, level, n.prefix, diags)
    kid === nothing && return CEntry[]        # the path is the offender, reported once
    _flat(n.node, _join(path, n.prefix), kid, entry, (pos..., :node), flat, diags)
end
```

The refusal is per node, once, with the provenance chain to the `at` as its
`entry`; the subtree is dropped, so no leaf beneath it reaches
`_check_duplicates!` or the store checks. `_component` (397–403) then sees a
path the walk admitted: a primitive, or a level with no row of its own. Its
`:unknown_path` arm is unreachable — reduce it to the `:assembly_path` push,
and amend its comment. `_root_input` (409–431): the `isempty(here) &&
!_addresses_level(…)` discrimination at 423–425 is likewise unreachable;
reduce it to the `:no_input_face` push. `_addresses_level` (439–440) then has
no caller left once `_read_component` (below) changes too; delete it.
`ConditionResolution`'s `reason` comment (1106–1107) drops `:unknown_path`.
`compile_plan` and `capture` go through `_resolve_entries` and need no
change.

### Readers, in `src/readers.jl`

`_read_component` (257–265) walks first:

```julia
function _read_component(s, label::Symbol, flat::Flat, diags::Vector{Diagnostic})
    entry = "the read labeled `$label`, $(_spell(s))"
    resolve_authored(entry, "", flat.root, s.path, diags) === nothing && return nothing
    i = findfirst(==(s.path), flat.paths)
    i === nothing || return i
    push!(diags, _rviol(label, s, :assembly_path))
    nothing
end
```

Amend its comment (253–256): the walk owns the unknown-segment refusal and
its candidates; what stays here is a level the walk admitted that owns no
state. `TapResolution`'s `reason` comment (1215–1216) drops
`:unknown_path`. Trim's `_resolve_reads` call (`trim.jl` 309) needs no
change.

### Tests

**Fixtures.** `ConcreteHold`/`GenericHold` (`test_assembly.jl` 303–314) are
top-level structs in the suite module and `test_assembly.jl` is included
before `test_conditions.jl` and `test_readers.jl`, so reuse them; they hold
a `SampledLoop`, whose `plant` (a `Plant`, state `q::SVector{2}`) and `ctl`
(a `DiscreteIntegrator`, store `acc`) are the leaves below. Both holders
export `ref` and `y`; a `Simulation` over either needs `init!` with
`fragment(inputs = (ref = …,))`. Add nothing to `fixtures.jl` unless a
test below cannot be written with these.

`test/test_conditions.jl`, a new function `conditions_load_bearing_walk()`
registered in `test_conditions()` (518–520), one testset "a deep `at` path
stays within a concretely declared subtree (§13.3, §14.2, D-130)":

- `resolve_condition(at("inner/plant", fragment(x = (q = SVector(0.3,
  0.1),))), build(ConcreteHold(SampledLoop())))` resolves; applied through
  `init!` (with `ref`), `state(sim, "inner/plant").q == SVector(0.3, 0.1)`.
- The same tree against `build(GenericHold(SampledLoop()))` fails with one
  `PathResolution`: `reason === :past_generic`, `segment == "inner"`,
  `level == "inner"`, `owner == "the root component"`, `declared isa
  TypeVar`, `entry == "at(\"inner/plant\")"`.
- The nested spelling `at("inner", at("plant", fragment(x = (q = …,))))`
  resolves against the generic holder, and after `init!` both holders'
  sims agree bitwise on `state(_, "inner/plant").q`.
- Per-node reporting: `at("inner/plant", fragment(x = (q = …,), m = (…)))`
  — pick a second leaf `Plant` declares, or a `combine` of two fragments
  under the one `at` — yields exactly one diagnostic against the generic
  holder.
- An unknown segment mid-path: `at("inner/plnt", …)` against the concrete
  holder fails with `PathResolution(:unknown_child)`, `segment == "plnt"`,
  `owner == "`inner`"`, `candidates == ["plant", "ctl", "sum"]`.
- A `Group` holds generically: `at("loop/plant", fragment(x = (q = …,)))`
  against `build(nested())` is `:past_generic` with `segment == "loop"`,
  and `at("loop", at("plant", …))` resolves.
- Under a `combine`, the entry string carries the chain: `combine(at("x",
  fragment(x = (q = 1.0,))), …)` — assert `d.entry == "combine[1] →
  at(\"x\")"` on the tri build (unknown child `x`, candidates `["plant",
  "ctl", "trig"]`).

Amend the existing collecting testset (138–152): the `at("nope", …)` entry
now yields a `PathResolution` (assert `reason === :unknown_child`,
`segment == "nope"`, `candidates == ["plant", "ctl", "trig"]`); the total
stays 5; the `Set` of `ConditionResolution` reasons loses `:unknown_path`.
The `:assembly_path` assertion (157–158) stands.

`test/test_readers.jl`, in the collecting testset (78–100): `a` is now a
`PathResolution` with `reason === :unknown_child && segment == "plnt" &&
candidates == ["plant", "ctl", "src"]` and `entry` starting with "the read
labeled `a`"; the label-order assertion at 91 becomes one over the three
`TapResolution`s plus the `PathResolution`'s entry. Add to the same
function a testset "a read selector's path stays within a concretely
declared subtree (§13.3, §14.7, D-125)": `_compile_reads(reads(q =
get_state("inner/plant", :q)), build(GenericHold(SampledLoop())))` fails
`:past_generic` with `segment == "inner"`; against
`ConcreteHold(SampledLoop())` it compiles, and after `init!` and
`evaluate!` the gather returns the authored `q`; `get_face(:y)` compiles
against both (the D-125 remedy).

`test/test_trim.jl` (247–249): `tap` becomes the `PathResolution`
(`reason === :unknown_child`, `segment == "nope"`); the count of 3 stands.

`test/test_diagnostics.jl`, kinds list (266–272): add
`PathResolution(entry = "at(\"a/b\")", spelling = "a/b", reason =
:past_generic, owner = "the root component", segment = "a", level = "a",
declared = TypeVar(:L, AbstractComponent))` so the arm renders.

`test/imports.jl`: add `resolve_authored` only if a test names it directly;
the tests above go through the clients.

### Register edits

- `docs/design/pending.md`:
  - Delete the first "Not yet built" bullet (21–23).
  - In the Appendix C absence bullet (53–66), the did-you-mean sentence at
    61–65 becomes: "Absent with them: did-you-mean **ranking** (no list is
    ever ordered), and the list itself on one arm —
    `ReadBindingUnresolved` fills `candidates` on the `get_input` miss only;
    and §11.8's maxlog renderer (count-only display past 25 cumulative
    occurrences per writer × kind)." The M-A2 citation goes with the clause
    it qualified.
  - In the payload bullet (67–89): delete "`PathResolution` no
    generic-holding arm, " (82).
- `docs/design/implementation.md`:
  - `src/assembly.jl` row (22): after "§13.3's
    `resolve`/`resolve_terminal`/face-list primitives" add "and the
    load-bearing register's walk `resolve_authored` over the `Flat`'s
    retained root, declared holdings read off the type definition
    (D-061, D-130)"; add `§14.2`, `D-061`, `D-130` to the citations.
  - `src/conditions.jl` row (35): after "one collecting pass behind both
    application registers" add "each `at` prefix walked from its authoring
    level (§13.3)"; add `§13.3`, `D-130`.
  - `src/readers.jl` row (26): after "`reads`" add ", its path selectors
    walked from the root (§13.3)"; add `§13.3`, `D-125`, `D-130`.
- From `docs/design`, run `julia --project=@. tools/check_refs.jl` and
  `julia --project=@. tools/check_rows.jl`; both must pass.

**Commit:** "Walk condition and read paths from their authoring level past
no generically held child (§13.3, D-130)".

## Verification

- Full suite green; `Pkg.test()` green.
- `rg -n "unknown_path" src/ test/` returns nothing.
- `rg -n "resolve_authored" src/` lists the definition and its two call
  sites; report the count.
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words: the commit hash; the files touched; any test you could
not write as specified and why, with file:line; any place the spec and this
brief disagreed; the assertion totals; friction with this brief, especially
any line number that had drifted.
