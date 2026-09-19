# Increment 45 — §8.8's selectors and the empty selection (§8.8, §9.1, §13.3, Appendix C, D-250, D-251)

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `55b9f5e` plus the commit that adds this brief.
Never `cd` elsewhere (`cd` is aliased to zoxide in the user's shell; use
absolute paths).

**Standing.** D-251 made the passthrough selectors exclusive, added the
`select` predicate, and made an empty selection the warning
`EmptyFaceSelection` on the `Build`'s list through D-250's channel. The
spec says so since `5502e1a` (§8.8's sketch and its two rules, §13.3's
signatures, Appendix C's two rows). The code has `except` and `only` with
the `:both_given` refusal, no `select`, and no `EmptyFaceSelection`.
Increment 44 built the channel (`BUILD_WARNINGS`, `_warn!`, `warnings(b)`,
the log at return, the rendering beside a throw) with no producer; the
channel's tests are synthetic. This increment is step 4 of
`roadmap_pipeline_redesign.md`, items 7–10 of `notes_pipeline_redesign.md`.

It also folds in the residue increment 44 deferred, `pending.md`'s "Smaller"
bullet: the face-list primitives `input_faces`/`output_faces` evaluate an
assembly's boundary declarations afresh on every call, so a warning raised
inside a child's `input_connections` lands once for the child's own walk
plus once per level whose passthrough helper asks for that child's faces,
and once more on the endpoint-resolution path that builds a did-you-mean
list from the child's faces. Appendix C's `logged` policy says once per
call. The fix lands first, so the producer's tests count once from the
start.

**The pre-flight probe** (2026-09-19, `probe45.jl` in the session
scratchpad, against `55b9f5e`). A child assembly whose `input_connections`
raises a synthetic warning, built alone, warns once; under one passthrough
level, twice; under two, three times; under a parent whose wire names a
face the child lacks (the did-you-mean path), three times, on the throw.
`IdDict` keyed by component instances behaves: the same instance hits, and
two immutable instances of equal content share a key, which is sound for a
face list since it is a function of the instance's value. A second
`ScopedValue` bound inside `build`'s existing `with` block binds and
unbinds as expected on 1.13.

**Three stages, three commits, in this order.**

- **Stage 1, the walk's face memo.** The walk records each assembly's
  evaluated face lists, and the primitives read them while a walk is
  running. The channel's test gains the nested cases at count one.
- **Stage 2, the selectors and the warning.** `select`,
  `:multiple_selectors`, `EmptyFaceSelection` through `_warn!`.
- **Stage 3, the feed-list test.** §8.8's `ACT_FEEDS` sketch transcribed
  against the real helpers. No source change.

Stages 1 and 2 touch `assembly.jl` and add a kind in `diagnostics.jl`, the
routing table's first row: `declare assembly build diagnostics leaves`.
Stage 3 touches `test_assembly.jl` alone and runs `assembly`. The gate is
the reviewer's. `implementation.md`'s "Running the suite" (113–164) is the
one home of test policy; this brief does not restate it.

**Read, in `docs/design/spec.md`:** §8.8 whole, 2790–2978: the sketch
(2796–2830), the two rules and their "why" (2852–2874), the output sibling
(2881–2897), the feed-list idiom (2908–2960). §9.1's "Where a build warning
lives", 3231–3240. §13.3's primitives and helpers, 10701–10714. Appendix C's
`logged` policy, 11042–11047, and the rows for `UnknownFaceSelection` and
`EmptyFaceSelection`, 11152–11158. In `docs/design/decisions.md`: **D-250
(9157–9218)** and **D-251 (9220–9265)**.

**Routed reading in `docs/design/implementation.md`** — do not read the
whole file:

- **"Running the suite" (113–164)**: the routed subset, the flags, the gate.
- The file-table rows for `src/diagnostics.jl` (20), `src/assembly.jl` (22),
  `test/fixtures.jl` (38), `test/imports.jl` (39).
- **"Authoring caveats" in full (61–111)** — always. Fixtures live at top
  level; every framework name a test calls or extends is on
  `test/imports.jl`'s list; a type's printed form depends on the printing
  module.

In `docs/design/pending.md`: the first "Not yet built" bullet (21–41), the
umbrella for increments 43–48, whose §8.8 sentence (29–30) this increment
delivers; and the "Smaller" bullet (54–73), whose face-list clause (64–73)
stage 1 retires.

**Stance: conservative reading.** Build what the sections below say. Where
the spec, the two decisions and this brief disagree, stop and say so in the
report rather than improvising. Where a site does not hold what the brief
claims, report it rather than inventing a substitute.

**The design documents and the implementation are peers, neither
subservient to the other.** A deviation that improves the design is raised
in your report, not kept as a liberty.

Commit subject: one sentence, no body, no attribution. Do not push. Never
stash, reset or check out the working tree; a baseline is read with
`git show <tip>:path`. Never run the suite in the background. The build
tests assert kind and payload; message text is asserted only in
`test_diagnostics.jl`'s rendering testset. A REPL check of a fixture defined
in a `test_*.jl` file loads `test/repl.jl`, `using Test, Logging` and
`test/utils.jl` (`single`, `fed`, `failure`, `carried`), then reproduces the
fixture. The audit refresh under `docs/reports/20260915_audit` sits
uncommitted on purpose: never `git add -A`; add each path by name.

## Stage 1 — the walk's face memo

Files: `src/assembly.jl`, `test/test_build.jl`, `test/imports.jl`,
`docs/design/implementation.md`, `docs/design/pending.md`.

### The mechanism

The walk (`_walk!`, `assembly.jl:914–1036`) walks an assembly's children
before it reads the assembly's own boundary declarations, and since `a4c5d50`
evaluates each of `input_connections` and `output_connections` exactly once
per component (`ins` and `outs` at 990–991). So by the time a parent's body
runs and calls `input_passthrough(parent, "kid")`, the walk has already
evaluated the kid's boundary and knows its face lists. The primitives
(`input_faces`/`output_faces`, 489–507) do not know that and evaluate the
body again. The same happens on `resolve_source` (609), `resolve_dest`
(632) and `_wrong_direction` (650), which ask a child's face lists for a
recorded-row miss or a did-you-mean list.

The walk memoizes for the primitives. Not the helpers reading from the
walk: the did-you-mean path calls the primitives directly, so the memo has
to sit under the primitives to cover every asker with one change.

- `Walk` (719–736) gains a field
  `faces::IdDict{Any,Tuple{Vector{String},Vector{String}}}`, the evaluated
  `(inputs, outputs)` face lists per assembly instance; the constructor at
  737 initializes it empty. Keyed by instance because the helpers name a
  child by a path relative to `asm`, never by an absolute path, and the
  face list is a function of the instance's value (§8.8: the declarations
  are evaluated against the concrete instance). Two immutable instances of
  equal content share a key, which is sound for the same reason.
- A scoped value beside `Walk`:

```julia
"""
The running walk's evaluated face lists (§13.3, Appendix C): `flatten!`
binds it around the walk, so a primitive asked for an assembly's faces
while the walk runs — by a passthrough helper inside a parent's body, or by
endpoint resolution building a did-you-mean list — reads the lists the walk
already evaluated rather than evaluating the body again. Unbound outside a
walk, where the primitives evaluate the body themselves.
"""
const WALK_FACES = ScopedValue{Union{Nothing,IdDict{Any,Tuple{Vector{String},Vector{String}}}}}(nothing)
```

  `Base.ScopedValues` is already imported in `src/Cadence.jl:5`.
- `flatten!` (849) binds it: `with(WALK_FACES => w.faces) do _walk!(…) end`.
  The obligation loop after the walk uses `_contract(input_types, c)` and
  needs no binding. `build` keeps binding `BUILD_WARNINGS` alone; the memo
  is the walk's and lives with it.
- In `_walk!`'s assembly branch, right after `ins` and `outs` are evaluated
  (990–991), record the lists:
  `w.faces[comp] = (String[String(f) for (f, _) in ins], String[String(f) for (_, f) in outs])`.
  Record before `_check_face_names`, since nothing below reads the memo for
  the component itself; the readers are the parent's body and its wire
  resolution, both later.
- The primitives' assembly arm consults the memo first, one side per
  primitive, so that a miss evaluates only the body asked for (outside a
  walk a caller asks for one side, and evaluating the other body for
  nothing would raise its warnings for nothing):

```julia
input_faces(c) = classify("", c) === PRIMITIVE ?
                 String[String(k) for k in keys(_contract(input_types, c))] :
                 _walked_faces(c, 1, input_connections, first)
output_faces(c) = classify("", c) === PRIMITIVE ?
                  String[String(k) for k in keys(_contract(output_types, c))] :
                  _walked_faces(c, 2, output_connections, last)

# The walk's list when the walk evaluated this assembly, the one body otherwise.
function _walked_faces(c, side::Int, fn, name)
    memo = WALK_FACES[]
    memo !== nothing && haskey(memo, c) && return memo[c][side]
    String[String(name(pair)) for pair in invoke_declaration(fn, c)]
end
```

  Two plain functions instead of the `(side, fn, name)` triple are equally
  acceptable; the requirement is one body per miss. A miss inside a walk
  happens for no asker today (children are walked before any parent reads
  them); the fallback is correctness, not a path with a reader.
- Docstrings of `input_faces`/`output_faces`: one added sentence each,
  saying that inside a walk the list is the one the walk evaluated, once
  per call (Appendix C), and that standalone the body is evaluated. Keep
  the "declaration order is preserved" sentence; the memo keeps it.

### The tests

In `test/test_build.jl`, the `build_warnings` section (1571–1660). Its
header comment says "No build-side producer of a warning exists yet"; leave
that to stage 2. Add to the first testset (`a warning raised inside a
declaration body lands on the Build…`), after the existing `Group` case,
the three shapes the probe measured, each expecting exactly one warning on
the `Build` and one log line:

- a parent whose boundary is computed over `WarningWires` by
  `input_passthrough(p, "w")` and `output_passthrough(p, "w")`;
- a grandparent whose boundary is computed the same way over that parent;
- a parent whose `child_connections` wires `"w/nope" => "g/e"` from
  `WarningWires` into a `Gain`, so the wire meets the did-you-mean path
  (`UnknownPort` in the collection) and the throw carries exactly one
  warning. This one belongs in the second testset (`a step that throws
  carries its warnings…`), with `failure` and `@test_logs` as there.

Fixtures at top level beside `WarningWires`, three new types; grep every
new name across `test/` first. Assert `length(warnings(b)) == 1` and the
`@test_logs` pattern once, as the existing cases do. Add `WALK_FACES` to
`test/imports.jl` only if a test reads it; a test that
`@test WALK_FACES[] === nothing` after `build` returns is worth one line,
beside the existing `BUILD_WARNINGS[]` check.

### The registers

- `implementation.md`, the `src/assembly.jl` row (22): after "§13.3's
  `resolve`/`resolve_terminal`/face-list primitives", add that the walk
  records each assembly's evaluated face lists in `Walk.faces` and binds
  them as `WALK_FACES` so the primitives read them once per call (Appendix
  C), evaluating the body only outside a walk.
- `pending.md`, the "Smaller" bullet (54–73): delete the face-list clause,
  from "the face-list primitives" (64) through "the helpers take them from
  the walk" (73), leaving the bullet ending at "replay is unpresented
  (§11.8)". Run `docs/design/tools/check_refs.jl` and `check_rows.jl`
  after.

### The routed run

`julia --project=test test/runtests.jl declare assembly build diagnostics leaves`
under the flags of "Running the suite". One commit.

## Stage 2 — the selectors and the warning

Files: `src/assembly.jl`, `src/diagnostics.jl`, `test/test_assembly.jl`,
`test/test_build.jl`, `test/test_diagnostics.jl`, `test/imports.jl`,
`docs/design/implementation.md`, `docs/design/pending.md`.

### `src/diagnostics.jl`

- `UnknownFaceSelection` (645–659): the `reason` comment becomes
  `:multiple_selectors | :unknown_names`; `names` carries, for
  `:multiple_selectors`, the selectors given as strings in the order
  `except`, `only`, `select`. The `:both_given` arm of `message` becomes the
  `:multiple_selectors` arm, naming the selectors given through `_namelist`
  and stating one selector per call (§8.8). The `:unknown_names` arm is
  unchanged.
- A new kind directly after it, the build's first warning-severity kind on
  the build side:

```julia
"§8.8, D-251: a passthrough selector that kept no face of the child."
Base.@kwdef struct EmptyFaceSelection <: Diagnostic
    who::String                              # the calling helper
    path::String                             # the child path
    selector::Symbol                         # :except | :only | :select
    names::Vector{String} = String[]         # the selector's names; empty for `select`
    candidates::Vector{String} = String[]    # the child's face list on that side
end
severity(::EmptyFaceSelection) = :warning
path(d::EmptyFaceSelection) = d.path
```

  `message`, the didactic style: the helper at the path, the selector with
  its names where it has them (`except` naming every face, `select`
  accepting none), that nothing passes through, and the child's face list
  in hand, or that the child has no faces on that side when `candidates`
  is empty; cite §8.8. The side is read off `who` (`input_passthrough` →
  input faces). Two or three arms at most; the shape of
  `UnknownFaceSelection`'s message is the model.

### `src/assembly.jl`

The helpers (509–582).

- Both signatures gain `select = nothing`, untyped: any callable over a
  `String` face name. Both docstrings say the three selectors are exclusive,
  one per call, `select` is a predicate over face names receiving each name
  as a `String` and keeping the names it accepts, and a selector that keeps
  nothing warns `EmptyFaceSelection` on the `Build` while a bare call over
  a faceless child is silent (§8.8).
- `_passthrough_faces` takes `select` too. Its shape, following the spec's
  sketch (2811–2822):

```julia
function _passthrough_faces(who::String, child_path::AbstractString,
                            names::Vector{String}, except::Tuple, only::Tuple, select)
    given = Symbol[]
    isempty(except) || push!(given, :except)
    isempty(only) || push!(given, :only)
    select === nothing || push!(given, :select)
    length(given) ≤ 1 ||
        throw(DiagnosticError(UnknownFaceSelection(who = who, path = String(child_path),
                                              reason = :multiple_selectors,
                                              names = String.(given))))
    unknown = …                                  # unchanged
    wanted = !isempty(only)     ? String[String(n) for n in only] :
             select !== nothing ? filter(select, names) :
                                  setdiff(names, String[String(n) for n in except])
    if length(given) == 1 && isempty(wanted)
        sel = only(given)
        _warn!(EmptyFaceSelection(who = who, path = String(child_path), selector = sel,
                                  names = sel === :except ? String[String(n) for n in except] :
                                          sel === :only   ? String[String(n) for n in only] :
                                                            String[],
                                  candidates = names))
    end
    wanted
end
```

  Note `only(given)` is `Base.only` and the keyword `only::Tuple` shadows it
  inside the function; write `given[1]` or rename the local. The `:only`
  arm of `names` can never fire (a non-empty `only` of known names keeps
  them all) and stays for the payload's completeness; say so in a comment
  or drop the arm and let `only` carry `String[]`, your call, stated in the
  report. `filter(select, names)` keeps declaration order; `only` keeps the
  author's order, as today.
- Order of checks, as the sketch: exclusivity, then unknown names, then the
  selection, then the warning. A faceless child with `select` given warns
  (`given == 1`, `wanted` empty, `candidates` empty); a faceless child with
  `except` or `only` given meets `:unknown_names` first. A bare call over a
  faceless child returns the empty tuple silently.

### The tests

- `test/test_assembly.jl`, the testset "the passthrough filters, and
  refuses what it cannot mean (§8.8)" (836–876):
  - `select`: `input_passthrough(m, "s"; select = n -> n == "b")` returns
    `("s.b" => "s/b",)`; `select = startswith("a")` on the input side and a
    `select` on the output side, one assertion each.
  - the exclusivity case (861–863) becomes `:multiple_selectors` with
    `names == ["except", "only"]`; add one three-selector call asserting
    `names == ["except", "only", "select"]` and one `only` plus `select`
    call asserting `["only", "select"]`.
  - the warning, standalone, where the channel is unbound and the helper
    logs directly (D-250): `@test_logs (:warn, r"^EmptyFaceSelection")` around
    `input_passthrough(m, "s"; except = ("a", "b"))`, which returns `()`;
    the same for `select = _ -> false`. A bare call over a faceless child is
    silent: build a `Group` with `inputs = ()` as the child of a parent
    `Group`, and assert `@test_logs input_passthrough(parent, "kid") == ()`
    with no log expectation, then that `select = _ -> true` over the same
    child warns with empty `candidates`.
- `test/test_build.jl`, the `build_warnings` section: replace the header
  comment's first sentence ("No build-side producer… increment 45's") with
  one saying the synthetic kind stays because it tests the channel without
  the producer's own selection logic, and add a testset "the empty
  selection lands on the Build (§8.8, D-251)": an assembly whose
  `input_connections` is `input_passthrough(a, "kid"; except = (every face))`
  over a `Gain` child, building green with the gain's input then unfed —
  so give the assembly a hand-written entry feeding it, or make the child a
  `Group` with two faces and pass `except` naming both while a hand-written
  wire feeds them. Assert `only(warnings(b)) isa EmptyFaceSelection`, its
  `who`, `path`, `selector`, `names` and `candidates`, and the one log line.
  Nest it under one passthrough level to assert the count stays one under
  stage 1's memo.
- `test/test_diagnostics.jl`, the kinds testset (248): the
  `:both_given` entry (308) becomes `reason = :multiple_selectors, names =
  ["except", "only"]`; add two `EmptyFaceSelection` entries, `except` with
  names and candidates, and `select` with empty names and empty candidates.
  The rendering testset (590) asserts no message of these kinds today;
  leave it so unless the message shape needs a claim, in which case one
  `startswith`/`occursin` pair there.
- `test/imports.jl`: `EmptyFaceSelection`.

### The registers

- `implementation.md`, the `src/diagnostics.jl` row (20): no change unless
  a mechanism changed; a new kind is not a mechanism. The `src/assembly.jl`
  row (22): "§8.8's `input_passthrough`/`output_passthrough`" gains "with
  the three exclusive selectors and `EmptyFaceSelection` through the
  channel (D-251)".
- `pending.md`, the umbrella bullet (21–41): the sentence "§8.8's
  selectors: the `select` predicate, `:multiple_selectors` and
  `EmptyFaceSelection` (D-251)." gains ", delivered by increment 45". Run
  `check_refs.jl` and `check_rows.jl`.

### The routed run

`julia --project=test test/runtests.jl declare assembly build diagnostics leaves`
under the flags. One commit.

## Stage 3 — the feed-list test

Files: `test/test_assembly.jl` alone. No source change; if the sketch
cannot run against the helpers as they stand, that is a finding for the
report, not a source edit.

Transcribe §8.8's "One authored list, two declarations" sketch (spec
2916–2941) into a testset "the feed-list idiom: one authored list, two
declarations (§8.8, D-251)" in the §8.8 section of `test_assembly.jl`,
after the existing passthrough testsets. The claims under test are the
paragraph's: the two declarations are projections of the list, adding a
pair is one edit, a mistyped destination stays loud.

The fixture, at top level, grep every name across `test/` first:

- `Actuator`, a leaf with one input `cmd` and four outputs `e`, `a`, `r`,
  `brake_left`, each `output_direct` some multiple of `cmd`, shaped like
  `Gain` (`fixtures.jl:145–151`).
- `Aero`, a leaf with inputs `e`, `a`, `r`, `alpha` and one output
  `wrench`, a sum.
- `ldg`, not a type: a `Group` over two `Gain`s `left` and `right` with
  `inputs = ("left.brake" => "left/e", "right.brake" => "right/e")` and
  outputs re-exporting both `out`s, so its faces carry the dotted names the
  sketch uses (`"ldg/left.brake"`).
- `Systems{L}` holding `act::Actuator`, `aero::Aero`, `ldg::L`, and a
  `const ACT_FEEDS` tuple of four pairs exactly as the spec writes them,
  the fourth `"brake_left" => "ldg/left.brake"`; `fed_faces` verbatim from
  the sketch; `child_connections` and `input_connections` as sketched,
  `input_connections` passing through `aero` and `ldg` with
  `except = fed_faces(ACT_FEEDS, child)`, plus the actuator's own `cmd`
  hand-written; `output_connections` exporting `aero/wrench`.

Assertions:

- `fed_faces(ACT_FEEDS, "aero") == ("e", "a", "r")` and
  `fed_faces(ACT_FEEDS, "ldg") == ("left.brake",)`.
- `input_connections(sys)` equals the hand-written expectation, entry for
  entry: `aero.alpha`, `ldg.right.brake` and the actuator's `cmd`, in the
  order the sketch produces.
- `build(sys)` builds with no warnings and root inputs
  `[:var"aero.alpha", :var"ldg.right.brake", :cmd]` (the order the
  structure records; read it off `b.structure.root_inputs` and assert what
  you find, stating it in the report), and the four wires resolved: read
  `feeds` for `("aero", :e)` and the `ldg` route, or simulate one step and
  check `wrench`.
- One edit: a second list `ACT_FEEDS2` adding `"brake_right" =>
  "ldg/right.brake"` under a second `Systems`-shaped type (or a type
  parameter selecting the list, your call) drops `ldg.right.brake` from the
  input surface and builds green with one root input fewer. The actuator
  then needs a fifth output; give `Actuator` five outputs from the start and
  let the first list leave `brake_right` unwired, which is an unconnected
  output and legal (§6.1, D-084).
- A mistyped destination `"aero/ee"` in a third list is loud: the walk
  evaluates the boundary before the wires (`_walk!` 990 before 1000), so
  the `except` entry meets it first as fail-fast `UnknownFaceSelection`
  with `names == ["ee"]` and `candidates == ["e", "a", "r", "alpha"]`.
  Assert the kind and that payload; if the wire meets it first instead,
  the spec's "whether the wire or the `except` entry meets it first" allows
  it, and the assertion is `UnknownPort` in the collection; say which in
  the report.

The routed run is `julia --project=test test/runtests.jl assembly` under
the flags. One commit.

## Report

For each stage, in the handoff: the commit hash; per file, what changed;
the fixtures and kinds added, by name; the routed run, pass or fail, with
the output on failure; every place the brief's claim about a site was wrong
(a line number off, a value not in hand, a test the brief did not foresee),
and what you did instead; and any deviation from the spec you chose or
noticed, stated as such.
