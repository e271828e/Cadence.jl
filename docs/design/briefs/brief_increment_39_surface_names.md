# Increment 39 — two surface names: the `condition` generic and `ProbeDual` (§8.1, §9.4, §14.2, Appendix B, D-117, D-166, D-226)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `cf0c069` (the docs-first commit) plus the register commit that adds
this brief. Never `cd` elsewhere (`cd` is aliased to zoxide in the user's
shell; use absolute paths).

**Standing.** Two names the spec puts on the framework's surface do not exist
in `src/`.

- `condition`, the fragment function's generic (§14.2). Today the suite owns
  the function: `test/fixtures.jl` and `test/test_trim.jl` define six methods
  on a `condition` the test module itself creates, and nothing in `src/`
  spells the name. Two model packages doing the same would define two
  functions, and an owner's pull, `condition(sys.pwp.engine; n_eng)`, would
  find neither across the package seam. The docs-first commit `cf0c069`
  reworded §14.2 to say the fragment function is a method of the framework's
  `condition` generic, extended through `import Cadence: condition`, with no
  shadowing check because a foreign `condition` fails loudly at the pull.
- `ProbeDual` and `ProbeTag`, §9.4's public canonical probe scalar,
  `const ProbeDual = ForwardDiff.Dual{ProbeTag, Float64, 1}`. It is the one
  concrete `Dual` a CI activation list spells,
  `build(world; activations = (Float64, ProbeDual))`, under D-166's policy.
  Today D-166's pin at `test/test_build.jl:1132` spells it with the suite's
  private width-8 `D8`. `src/trim.jl:62–68` already owns the sibling,
  `TrimTag`, for trim's own activation, and is the model.

Both are unexported, reached by qualified name or per-name `import` (D-117,
D-226). **One stage, one commit**, the routed subset green.

Measured on Julia 1.13.0 before this brief was written, with the fixtures
loaded through `test/repl.jl`: a `Dual{ProbeTag,Float64,1}` is concrete with
`ForwardDiff.npartials` 1; `build(fed_pendulum; activations = (Float64, PD))`
materializes the activation eagerly (`haskey(b.cache, PD)` before any
request); the pinned fixture fails at it as one `ConformanceFailure` with
`activation === PD`; and `condition(::NoCond; θ = 1.0)` on a component with
no method is a `MethodError` whose text names `NoCond`.

**Read, all in `docs/design/spec.md`:** §14.2's fragment-function passage
(8177–8199: the reworded paragraph 8177–8185, the two examples after it).
§9.4's "Lazy, with an opt-in exhaustive mode" (3395–3418; `ProbeDual`'s
sentences are 3411–3418). §8.1's "The namespace: declarations are extended,
not called" (1780–1833), the import-list idiom this generic joins. §16's
"The exported-name surface" (10120–10131), why nothing is exported.
Appendix B's two lines (10406–10407, 10595–10597). In
`docs/design/decisions.md`: D-117 (3368–3401), D-226 (8096–8142), D-166
(5584–5676, the CI policy), D-246 (8909–8969, the shadowing check this
generic stays out of).

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (112–164)**: the routed subset, the flags, the gate.
- The file-table rows for `src/build.jl` (25), `src/conditions.jl` (36),
  `src/trim.jl` (37), `test/fixtures.jl` (38), `test/imports.jl` (39).
- **"Authoring caveats" in full (61–110)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–23) is
the one this increment retires.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the cited decisions and this brief disagree, stop and say so in
the report rather than improvising.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

This change reaches `declare assembly build diagnostics leaves readers
conditions trim` (rows one and four of the routing table: `build.jl` and
`conditions.jl`). Run that subset as "Running the suite" says, under the
sandbox flags, and gate the commit on it; the full suite is the reviewer's,
once per increment. Commit subject: one sentence, no body, no attribution.
Do not push. Never stash, reset or check out the working tree; a baseline is
read with `git show <tip>:path`.

---

## The construct

### The generic, in `src/conditions.jl`

Directly before `fragment`'s docstring (line 52), inside the node-kinds
section, so the file reads leaf constructor after the generic that returns
one:

```julia
"""
    condition(c; kw...)

The fragment function's generic (§14.2, Appendix B). A component ships its
initialization vocabulary as a method, `condition(::C; kw...) = fragment(…)`,
and the owner of a structure pulls its children's under `at`. The generic is
framework-owned so that pull crosses a package seam; a model package extends
it through `import Cadence: condition`, as it extends the declaration family
(§8.1). No fallback method: a child without one fails at the owner's pull as
a `MethodError` naming it.
"""
function condition end
```

Nothing else in `src/` changes for it. It does not join `DECLARATION_FAMILY`
in `src/declare.jl` (§14.2, last sentence of the reworded paragraph). No
export (D-226).

### The probe scalar, in `src/build.jl`

In section 5, directly after the `Build` struct (ends line 577) and before
`build`'s docstring (578), so the keyword's documented value is defined one
screen above its use. `ForwardDiff` is already `using`'d in `Cadence.jl`.

```julia
"""
The framework's public canonical probe scalar (§9.4, D-166): the one concrete
`Dual` a CI activation list spells, `build(world; activations = (Float64,
ProbeDual))`. An activation is keyed by a concrete scalar, and the bare `Dual`
`UnionAll` can key none. The tag keeps a probe activation distinguishable from
trim's (`TrimTag`) and from a user's own; the width is one because what CI
pins is genericity, not any particular Jacobian (§14.10 chunks at its own).
"""
struct ProbeTag end
const ProbeDual = ForwardDiff.Dual{ProbeTag,Float64,1}
```

No tag-ordering method (`ForwardDiff.≺`): a probe activation runs every
scalar at one tag and never meets a trim or user `Dual` in one expression.

### The suite's list, `test/imports.jl`

- `ProbeDual, ProbeTag,` on line 24, between `Period,` and
  `ProducedByTwoStages,`.
- `condition,` on line 40, between `compile_plan,` and `declarations,`.

`imports.jl` is included before `fixtures.jl` (`test/CadenceTests.jl` 6, 8;
`test/repl.jl` likewise), so the six fixture methods become extensions of
the framework's generic with no textual change to their definitions.

### Fixtures, in `test/fixtures.jl`

The section comment at 962–968 says the opposite of what is now true
("User-idiom material, not framework API: `condition` is an ordinary
function … nothing in `src/` outside this file knows the name exists").
Replace those seven lines with:

```julia
# --- the fragment-function idiom (§14.2) ----------------------------------------
# Methods of the framework's `condition` generic, one per component, shipped
# beside it. What the idiom buys is locality — the caller says "start the plant
# at this displacement", and only `Plant` knows displacement and rate pack into
# `q` — composed by *pull* from the structure's owner, never by a schema routing
# sub-specs down the tree (D-064).
```

One new fixture, at top level, directly after `Pendulum`'s `condition`
method (1346):

```julia
"""A component that ships no fragment function: the owner's pull fails on it by name."""
struct Voiceless <: AbstractComponent end
init_x(::Voiceless) = (; a = 0.0)
state_derivative(::Voiceless, (; x)) = (; a = 0.0)
```

`rg -n Voiceless test/` returns nothing at this tip; grep again before
defining it, since a same-named type silently rebinds a fixture module on
1.13. The shapes are the contract, not the exact text.

### Tests

The build tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset.

- `test/test_conditions.jl`, in `conditions_algebra()` (34), a new testset
  after the first one, "the fragment function is a method of the framework's
  generic (§14.2, Appendix B)": `condition === Cadence.condition` (the name
  the suite extends is the framework's, not a module-local one);
  `parentmodule(condition) === Cadence`; `hasmethod(condition,
  Tuple{Pendulum})` and `Tuple{Vehicle}` (a leaf's and an owner's methods
  land on it); `failure(() -> condition(Voiceless(); θ = 1.0)) isa
  MethodError` (no fallback); and `condition(Pendulum(); θ = 0.5) isa
  Fragment`.
- `test/test_build.jl`, `build_activations()` (1106), the exhaustive-mode
  block (1130–1135): spell D-166's pin with `ProbeDual` in place of `D8`,
  asserting `d.activation === ProbeDual`. Before it, three lines on the
  scalar itself: `isconcretetype(ProbeDual)`, `ProbeDual <: ForwardDiff.Dual`
  with `ForwardDiff.npartials(ProbeDual) == 1`, and on the `pair()` build of
  that testset, `b = build(pair(); activations = (Float64, ProbeDual))` then
  `haskey(b.cache, ProbeDual)` before any request (eager materialization,
  §9.4). Every other `D8` use in the file stays: width 8 is what those tests
  exercise.

### Register edits, in the same commit

- `docs/design/pending.md`: delete the first "Not yet built" bullet (21–23).
  The `check` entry point M-B23 also names stays where it is, in the §14
  bullet.
- `docs/design/implementation.md`: the `src/conditions.jl` row (36) gains
  "`condition`, the fragment function's generic (§14.2, Appendix B)" at its
  head; the `src/build.jl` row (25) gains "`ProbeTag`/`ProbeDual`, the
  canonical probe scalar (§9.4)" after "the `Build` and its activations";
  the `test/fixtures.jl` row (38) reads "the `condition` methods (the
  fragment-function idiom over the framework's generic)" in place of "the
  `condition` fragment-function idiom". Add "D-117" and "D-226" to the
  `conditions.jl` row's spec column. `src/trim.jl` (37) and `test/imports.jl`
  (39) need nothing.
- Run `julia docs/design/tools/check_refs.jl` and `check_rows.jl` after
  editing either register: both must print `OK`.

## Verification

- The routed subset green under the sandbox flags at the commit.
- `rg -n "Two surface names" docs/design/pending.md` returns nothing.
- `rg -n "^function condition end" src/` lists one line, in
  `conditions.jl`; `rg -n "ProbeTag" src/` lists the struct and the alias in
  `build.jl` and nothing else.
- `names(Cadence)` is still `[:Cadence]` (D-226: nothing exported).
- In a `julia --project=test -L test/repl.jl` session,
  `condition(Voiceless(); θ = 1.0)` throws a `MethodError` whose text names
  `Voiceless`, and `which(condition, Tuple{Pendulum}).module` is `Main`
  (the extension landed on the framework's generic from the fixtures'
  module).
- The suite's recorded assertion total rises by at least the count of new
  `@test` lines; report both totals.

## Report format

Under 300 words: the commit hash; the files touched; the REPL check above;
any test you could not write as specified and why, with file:line; any place
the spec, the cited decisions and this brief disagreed; the assertion
totals; friction with this brief, especially any line number that had
drifted.
