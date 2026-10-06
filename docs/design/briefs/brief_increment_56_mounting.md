# Brief: increment 56, mounting (§14.9, D-277)

Tip at launch: `84f479c`, increment 57 complete with the dotted face name
ruled (`d970e38`, D-276's 2026-09-30 annotation) and fixed (`6be4e82`).
Three stages, docs first, then one cold review and one fixer. Retires
`pending.md`'s "Mounting" bullet under "Not yet built" (lines 21–23), the
audit's finding I 4.12.

Design and code are peers, neither subservient. The ruling lands docs-first
in stage 1 (the spec's §14.9 sketch, a new log entry D-277, the glossary);
stages 2 and 3 conform the code and the suite. If the ruled shape proves
wrong at the keyboard, stop and report rather than deviate silently.

Increment 57 (the leaf address, `brief_increment_57_leaf_address.md`,
D-276) landed before this one: every selector's second argument is a leaf
address, `leaf::Union{Symbol,String}`, the baked reads carry the resolved
step chain as a type parameter, and a face selector's head is matched
against the face list rather than parsed, since a face name may hold a
dot. This brief rewrites a selector's *path* and never its leaf: the mount
step parses or matches the leaf once, at the mount level, and hands the
head and the steps to the resolvers.

## The ruling, in one paragraph

A read set carries its mount chain as data. `at(prefix, read_set)` prepends
the prefix to the `Reads` value's own tuple of prefixes and joins nothing;
`Reads` is not a condition node and `Scoped` never wraps one. At resolution
the chain is walked from the root, each prefix from the level the previous
one reached (§13.3's "checked at the authoring or mount level"), and every
selector is rewritten into the root-authored selector it denotes before the
ordinary resolvers run: a path selector's path is joined to the mount path,
`get_input(face)` names an input face of the mount level and becomes
`get_input` of the root input the export chain lands on, and
`get_face(name)` names an output face of the mount level and becomes
`get_output` of the producer port behind it. A face fed by a component is
refused with the producer named, as a condition's `inputs` entry is. `at` on
a `TrimProblem` lifts field by field, the two check fields passing through;
`at` on a `Taps` lifts its three lists. A refusal spells the selector as
authored and names the mount.

## What the spec says

Read these by line range at `84f479c`; find each passage by wording and
recount after every edit. Every line stage 1 rewrites is listed under
"Stage 1"; this is the reading.

- §14.9, `spec.md` 10188–10272, in full: the sketch (10205–10214), the
  resolution paragraph (10216–10226), the environment doctrine.
- §14.3, 9331–9401: flattening is the one place paths join; the five checks
  of the collecting pass.
- §14.4, 9402–9550: the selector family (9440–9550); the leaf-address rule
  paragraph with the dotted-face sentence (9451–9456), "the head is
  matched rather than parsed: it is the longest declared face name that is
  a prefix of the address and is followed by the end, a `.` or a `[`, and
  a `Symbol` leaf names the face whole"; the sentence at 9510–9512 that
  `get_face` resolves through export chains exactly as mounting resolves
  root-input faces.
- §13.3, 8468–8568: the service walk's row of the table (8506) and the
  paragraph at 8511–8520, "checked at the authoring or mount level".
- §14.7, 9703–9787: the closed field set with `checks` and
  `check_tolerances` (9709–9720), "`at` passes it through untouched"
  (9721–9722), the read-side paragraph (9768–9787).
- §14.10, 10273–10359: "relocate whole via `at(prefix, taps)`" (10311).
- Appendix B, 10885–10886: `at` lifts problems and tap sets. Appendix C,
  11376–11380: the `TapResolution` row, which names the leaf address and
  the step (D-276). Appendix D: `at` / `Scoped` (12373–12376), `mounting`
  (12420–12422), `taps` (12439–12442).
- `decisions.md`: D-071 in full (1967–2001); D-276 (11134–11240) with its
  two annotations, the dotted face name (11148) and the continuous tier's
  flatness; D-262 (the check fields); D-272 (the tap set); D-207 (the
  input-side face graph is total under one-level routing); D-130 and
  D-125 (the service walk).
- `implementation.md`: the entries for `readers.jl` (285–306),
  `conditions.jl` (701–714), `trim.jl` (715–725), `linearize.jl`
  (726–750), `diagnostics.jl` (44–112), `bindings.jl` (610–621); the
  authoring caveats (825–889) in full; "Naming" (890) and "Running the
  suite" (968), cited below and never restated.
- `tools/spec_style.md` and `tools/decisions_style.md` before touching the
  spec or the log; the header of `tools/check_glossary.jl` before the
  glossary.

## What exists

At `84f479c`, by wording.

- `readers.jl`: the five selector structs, each with `path` where it has
  one and `leaf::Union{Symbol,String}` (56–78); the constructors (85–92),
  `_spell` (97–101), `_leaf_string` (104); the leaf address: `LeafRefusal`
  (119–125), `parse_leaf` (146–178), `match_leaf(leaf, faces)` (195–202)
  and `match_face` (204–214), which take the face list as an argument and
  read no structure, `resolve_leaf` (225–249); `Reads{NT}` with the one
  field `selectors` (278–280); `reads` and `_reads` (290–300); the entry
  types and `_read` (311–340); `_resolve_reads` (405–414);
  `_read_component` (416–429), whose comment says "No mounting exists" and
  which walks `selector.path` from the root with `resolve_authored`;
  `_reader_violation` (435–439), which sets `tap`, `path` and `leaf` off
  the selector; `_leaf_violation` (442–446) with its `field` keyword;
  `_field(selector)` for the path selectors (456–459) and
  `_field(selector, faces)` for the face selectors (463–465), the matched
  face or the whole address; `_exported_faces` (468); `_parsed_leaf`
  (472–478) and `_matched_leaf` (481–487), the two resolver entry points;
  `_leaf_chain` (490–496); the five `_resolve_selector` methods (508–606).
  The `GetInput` arm (573–588) matches against `structure.root_inputs` and
  refuses `:unknown_root_input`; the `GetFace` arm (590–606) matches
  against the exported faces, refuses a root input's name as
  `:root_input_not_face`, and reads `act.layout.addr[("", head)]`.
- `conditions.jl`: `Scoped{N}` (27–31), `ConditionNode` (49); the `at`
  methods (84–93), the node one and the catch-all raising
  `ConditionNodeMisuse`; `CEntry` (132–140); `_flat(::Scoped)` (185–192),
  which walks the prefix with `resolve_authored` from the current level and
  recurses with `_join`; `_root_input` (429–450), the three-arm export-chain
  lookup over `structure.root_inputs` and `structure.in_faces`, pushing
  `ConditionResolution` reasons `:unexported_face`, `:no_input_face`,
  `:internally_wired`. Its one caller is `_flat(::Fragment)` (163–166).
- `assembly.jl`: `_join` (75); `resolve_authored(entry, base, level, path,
  diags)` (364–409), returning the component or `nothing` after a
  `PathResolution`; `input_faces`/`output_faces` (475–490); `Structure`
  (758–769) with `root_inputs`, `in_faces`, `out_faces`. A probe on a
  two-level group (`rig` holding a plant and a discrete integrator, `trig`
  fed from `rig/y`) shows `in_faces` has a row for every level including
  the root (`("", :u) => ("", :u)`) and every primitive (`("rig/plant", :u)
  => ("", :u)`, `("trig", :sig) => ("rig/plant", :y)`); `out_faces` has
  `("rig", :y) => ("rig/plant", :y)` and `("", :y) => ("rig/plant", :y)`,
  the producer always a primitive port; and the activation's `layout.addr`
  has a key for every alias (`("rig", :y)`) and every port. `build.jl`
  583–585 installs the aliases.
- `trim.jl`: `TrimProblem` (65–83), nine fields, the keyword constructor;
  `_check_reads!` (344–352), `problem.reads isa Reads` then
  `_resolve_reads`; the seeded reader (477).
- `linearize.jl`: `Taps{X<:Reads,U<:Reads,Y<:Reads}` and `taps` (26–36);
  `_tap_kind` (214–216); `_resolve_taps` (229–256): per list, the kind
  check on the selector, then `_resolve_selector` at nominal, then
  `_seeded_tap`; `_site_key` (262–265); `_check_seedable` (275–291);
  `_seeded_tap`'s four methods (296–357). The `u` arm takes the root
  input's name from `_field(selector, structure.root_inputs)` for the
  pinning meet; the `y` arm takes the head the same way and reads
  `act.layout.addr[(_selpath(selector), head)]`.
- `diagnostics.jl`: `PathResolution` (435–446); `TapResolution`
  (1640–1659) with `leaf` and `step`, its shared prefix `_tap_violation`
  (1672–1674), `LEAF_REASONS` and `_leaf_clause` (1676–1704), its message
  (1706–1750); `ReadSetMisuse` (2044). `_at_path` (68).
- `bindings.jl`: `_compile_gather` (143): an output binding's `reads` is a
  bare NamedTuple of selectors, never a `Reads`, so a mounted set cannot
  reach a binding; `_matched_binding_leaf` (203) is its face matcher.
- `Redstone.jl` includes `readers.jl` (15) before `conditions.jl` (26),
  `trim.jl` (27) and `linearize.jl` (28).
- Tests: `test_readers.jl` (388 lines, testsets at 88, 132, 151, 231, 266,
  307, 351, 379; the comment at 232 says "No mounting exists"; the
  `:root_input_not_face` assertion at 180; the dotted-face fixtures
  `DottedFaces`, `dotted_model`, `dotted_condition` at 67–78, whose root
  input is `left.brake` and whose faces `pose` and `pose.v` sit side by
  side); `test_conditions.jl` 35–50
  (composition is inert) and 197–217 (the chain, `tri()` at 10–12 with
  `trig/sig` internally wired); `test_trim.jl` 1–100 (fixtures:
  `fed(Pendulum(), :u)` from `test/utils.jl:19`, `pend_base`, `θ_problem`,
  `sampled_pend`); `test_linearize.jl` 1–82 (`lin_pend`, `lin_point`,
  `lin_taps`, `lin_pinned`, `same_linearization`; the fixtures
  `MatrixDecay`, `PoseConsumer`, `MatrixConsumer` are 57's);
  `test_diagnostics.jl` 505–564 (the `TapResolution` renderings,
  `:root_input_not_face` at 513) and 677–685 (the kinds loop).
  `test/imports.jl` imports `at`, `reads`, `Reads`, `taps`, `Taps`,
  `TapResolution`, `_compile_reads`.
- `show.jl` and `README.md` have no site.

## Scope

In:

- `Reads.prefixes`; `at` on a `Reads`, a `Taps` and a `TrimProblem`.
- The read-side mount step: the chain walk and the rebase of every
  selector, owning every face-level check; the resolvers keeping the
  schema checks.
- `TapResolution`'s `mount` and `producer` fields and its two new reasons;
  one reason renamed.
- The spec's §14.9, the glossary, D-277, `implementation.md`, `pending.md`,
  the suite.

Out:

- `product(p₁ => "lead", p₂ => "wing")`, recorded not built (§14.9).
- `design_world(ac)`, the §13.7 library.
- Mounted read sets in output bindings: a binding takes a bare NamedTuple
  (§11.2), and nothing changes there.
- The leaf address itself and the binding register (increment 57, D-276).
- The untracked GUI, inspector and audit folders.

## Shapes

### The read set and the three lifts

```julia
# readers.jl
struct Reads{NT<:NamedTuple}
    prefixes::Tuple{Vararg{String}}   # the mount chain, outermost first; () at the root
    selectors::NT
end
_reads(selectors::NamedTuple) = (…checks as today…; Reads((), selectors))

# conditions.jl, beside the node method
at(prefix::AbstractString, read_set::Reads) =
    Reads((String(prefix), read_set.prefixes...), read_set.selectors)

# linearize.jl
at(prefix::AbstractString, tap_set::Taps) =
    Taps(at(prefix, tap_set.x), at(prefix, tap_set.u), at(prefix, tap_set.y))

# trim.jl
at(prefix::AbstractString, problem::TrimProblem) = TrimProblem(
    problem.guess, problem.lower, problem.upper,
    d -> at(prefix, problem.condition(d)),
    problem.reads isa Reads ? at(prefix, problem.reads) : problem.reads,
    problem.residuals, problem.tolerances, problem.checks, problem.check_tolerances)
```

A `reads` field that is no `Reads` passes through untouched, so `trim!`'s
setup names it (`TrimProblemInvalid`, `:not_a_read_set`) as today; the
lift never raises. The catch-all `at(::AbstractString, other)` stays in
`conditions.jl`, the three new methods being more specific. `Taps`' type
parameters, `_check_reads!`'s guard and the labels `keys(read_set.selectors)`
are unchanged.

### The mount step

```julia
# readers.jl
"""
One read after §14.3's flattening on the read side: the selector rebased to
the root with its leaf parsed or matched, beside the selector as authored
and the mount it was authored at, which is what a refusal spells (D-277).
"""
struct MountedRead
    label::Symbol
    authored::ReadSelector   # as written
    mount::String            # the joined mount path; "" at the root
    selector::ReadSelector   # root-authored: the path joined, the face resolved
    head::Symbol             # the field, port or root input the read names
    steps::Vector{LeafStep}  # the leaf's steps after the head
end
```

`_mount(read_set::Reads, build::Build, diags) →
Union{Nothing,Vector{MountedRead}}`, the one place a leaf is parsed or
matched:

1. Walk the chain: `mount, level = "", structure.root`; for each prefix,
   `resolve_authored(description, mount, level, prefix, diags)`, the
   description accumulating as `_flat` does ("the read set at(\"wing\")",
   then "the read set at(\"wing\") → at(\"aircraft\")"); `nothing` from the
   walk returns `nothing`, the chain being the one offender, reported once.
   Then `mount = _join(mount, prefix)`.
2. Rebase each selector at `(mount, level)`; a selector that fails is
   skipped and the others go on, in §13.1's collecting form:
   - `GetState`, `GetDeriv`, `GetOutput`: `resolve_authored(description,
     mount, level, selector.path, diags)` with the description "the read
     labeled `q`, get_state(\"dynamics\", :q), mounted at `wing`" (no
     mount clause at the root); `parse_leaf` for the head and steps, a
     `LeafRefusal` collected through `_leaf_violation`; the rebased
     selector is the same kind at `_join(mount, selector.path)` with the
     leaf as authored. The empty path names the level itself.
   - `GetInput`: `match_leaf(selector.leaf, faces)` with `faces` the
     level's input faces, `structure.root_inputs` at the root and the
     `in_faces` rows at `mount` elsewhere (they cover every level, the
     primitives included). `nothing` is `:no_input_face` with those faces
     as candidates at the mount, and the existing `:unknown_root_input` at
     the root, `field` from `_field(selector, faces)`; a `LeafRefusal` is
     collected. The matched face's producer comes off `in_faces` at
     `(mount, face)`. Producer `("", root_input)` rebases to
     `GetInput(root_input)` with `head = root_input` and the matched
     steps; the rebased leaf is the root input's name and is never
     re-parsed, since resolution reads `head` and `steps`. A producer with
     a non-empty path is `:internally_wired` with `producer` set.
   - `GetFace`: `match_leaf` the same way against the level's output
     faces, `_exported_faces(structure)` at the root, the `out_faces` rows
     at `mount` for an assembly level, and the ports off
     `build.outputs.components[ci]` for a primitive level. For an assembly
     the `out_faces` row at `(mount, face)` gives the producer port and the
     rebased selector is `GetOutput(producer_path, port)` with `head =
     port`; for a primitive it is `GetOutput(mount, face)` with `head =
     face`; the matched steps ride along in both. No such face: when
     `match_face` finds the name among the level's input faces,
     `:input_face_not_output` (the renamed `:root_input_not_face`, at
     every level); otherwise `:unknown_output_face` with the level's output
     faces as candidates. At the root this reproduces today's checks
     exactly, the dotted testset (307–350) included.

`_root_input` in `conditions.jl` and the `GetInput` arm above share one
lookup: factor the table walk into a helper in `conditions.jl` that returns
what it found (the root input, the missing face with the level's
candidates, or the producer) and let each side push its own kind. The
builder chooses the spelling; the root fork of `_root_input` may fold into
the table now that the table has the root's rows.

`_resolve_reads` becomes: activation, `_mount`, then for each
`MountedRead` `_resolve_selector(read.selector, read, build, act, diags)`.
The resolvers' second parameter changes from `label::Symbol` to
`read::MountedRead`; they take `read.head` and `read.steps` in place of
`_parsed_leaf` and `_matched_leaf`, which fold into `_mount`, and keep the
schema checks and `_leaf_chain`. `_reader_violation(read, reason; kw...)`
spells `read.authored`, sets `mount = read.mount` and `field = read.head`
by default, takes `path` and `tap` off `read.selector` (the joined path is
what `_at_path(d.path)` should print) and `leaf` off `read.authored`.
`_read_component` loses its walk and keeps the lookup and the
`:assembly_path` refusal. The `GetFace` resolver and the face match in the
`GetInput` resolver are dead after the rebase and go; the `GetInput`
resolver keeps the address and the leaf chain. `Reader{T,L}`, `_read` and
`gather_reads` are untouched.

`_resolve_taps` mounts each list with `_mount`, runs the kind check on
`read.authored` (a `get_face` in the `y` list is admitted although it
rebases to a `GetOutput`), and hands `read.selector` and `read` to
`_resolve_selector` and `_seeded_tap`. `_seeded_tap`'s `label::Symbol`
parameter becomes `read::MountedRead`; its `u` arm takes the root input's
name from `read.head`, which is what makes the pinning meet right at a
mount; its `y` arm's signature narrows to `GetOutput` and takes `read.head`
too. The site key is unchanged. The `x` list's mount walks the mount level as a service
path, so a tap set authored for a subsystem mounted *to* a generically held
child resolves, while a root-authored `get_state("inner/plant", :q)` is
refused, which is §13.3's point and a test below.

### Diagnostics

`TapResolution` gains `mount::String = ""` and
`producer::Union{Nothing,Tuple{String,Symbol}} = nothing`, the reasons
`:no_input_face` and `:internally_wired`, and `:root_input_not_face`
renamed `:input_face_not_output`. `_tap_violation`'s prefix adds
", mounted at `wing`" after the selector when `mount` is non-empty. The
new arms, in the file's style: `:no_input_face` "`x` is no input face of
`wing` — its input faces are …"; `:internally_wired` "`x` is fed by
`plant/y`, so no root input holds it — a mounted problem reads and writes
its level's faces through the export chain, and a face the world computes
is not free (§14.9)"; `:input_face_not_output` generalizes the root
arm's text to the level. Every `PathResolution` from the walks is as today,
with the descriptions above. The `_read_component` comment, the
`test_readers.jl:232` comment and Appendix C's row say mounting exists.

### Naming

`read_set` for a `Reads` parameter, `tap_set` for a `Taps`, `problem` for
a `TrimProblem`, `read` for a `MountedRead`, `authored` for the selector as
written, `mount` for the joined mount path, `level` for the component at
it, `prefixes` for the field, `producer` as in `conditions.jl`, `face`,
`faces`, `head` and `steps` as in `readers.jl`. `_mount` and `MountedRead` are the new names; no local named
`mount` in a scope that calls `_mount`.

## Stage 1: the docs amendment

One commit. Rostered files use the linkified spelling; run `linkify.jl`,
`check_refs.jl`, `check_rows.jl` and `check_glossary.jl --strict`, all
green, and `audit_fragments.jl` against `84f479c` for the log. Line
numbers are `84f479c`'s; find each passage by wording and recount after
every edit. Write citations bare in the log and let `linkify.jl` link
them; the new entry goes after D-276 and before the `<!-- citation link
definitions` marker (11241).

- §14.9, 10205–10214: the sketch gains the two check fields as pass-through
  lines, and line 10211's comment becomes "#inert selector data: the prefix
  joins the read set's mount chain". 10216–10226: replace "Resolution then
  needs nothing new. The flattening accumulator of §14.3 enters the
  `Scoped` wrapper and prefixes every entry (…)." with a **Rule.**
  paragraph: a read set carries its mount chain as data, `at` prepends a
  prefix and joins nothing; at resolution the chain is walked from the
  root, each prefix from the level the previous one reached (§13.3), and
  every selector is rebased to the root before it resolves. A path
  selector's path is joined to the mount (`"vehicle/dynamics"` →
  `"wing/vehicle/dynamics"`); `get_input` names an input face of the mount
  level and follows the export chain to the root input it lands on;
  `get_face` names an output face of the mount level and reads its
  producer's port (D-277). Keep the root-input sentences that follow
  ("`throttle` at `"wing"` → root input `"wing.throttle"`", the unexported
  face, the internally wired input) as they are; they now read as
  consequences of the rule. One sentence on refusals: a refusal spells the
  selector as authored and names the mount. Every existing normative claim
  of the section survives; run the claim inventory of `spec_style.md`.
- Appendix C, 11376–11380: the `TapResolution` row adds "the mount path;
  for an internally wired face at a mount, the producer".
- Appendix D, 12373–12376: after "Path concatenation happens once, at
  resolution." add "A read set keeps its prefixes as a chain and is not a
  condition node (D-277)." 12420–12422 (`mounting`): add "The read side
  rebases every selector to the root at resolution (§14.9)."
- `decisions.md`: D-277, the text below, verbatim but for the style
  guide's wrap. D-071's second bullet ("inert selector data reusing the
  `Scoped` node") gets a trailing annotation in the log's own form, the
  one D-276 carries at 11148, "(amended by D-277: the read set carries
  its chain; `Scoped` never wraps one)", its Status staying ratified.

```markdown
### D-277 — A read set carries its mount chain, and resolution rebases every selector to the root

**Status.** ratified

**Position.** `at(prefix, read_set)` prepends the prefix to the read set's
own chain of prefixes and joins nothing; `Reads` is not a condition node
and `Scoped` never wraps one. Resolution walks the chain from the root,
each prefix from the level the previous one reached, and rewrites every
selector into the root-authored selector it denotes before the ordinary
resolvers run.

- A path selector's path is joined to the mount path; its leaf address is
  untouched.
- `get_input(face)` names an input face of the mount level and becomes
  `get_input` of the root input the export chain lands on, the address's
  steps following the root input's name. A face fed by a component is
  refused with the producer named, as a condition's `inputs` entry is
  (§14.2).
- `get_face(name)` names an output face of the mount level and becomes
  `get_output` of the producer port behind it; at the root it is the
  integration read it was.
- `at` on a `TrimProblem` lifts field by field, `checks` and
  `check_tolerances` passing through with the other path-free fields; `at`
  on a tap set lifts its three lists.
- A refusal spells the selector as authored and names the mount.

**Spec.** §13.3, §14.4, §14.9, §14.10

**Rationale.** D-071 had the read set reuse the `Scoped` node. `Scoped` is
a member of the condition-node union with its payload unconstrained, so a
scoped read set would pass every guard of the algebra by type and fail
inside the flattening pass with a `MethodError`, the slip the algebra
refuses at composition with `ConditionNodeMisuse`. Julia has no recursive
union that admits `Scoped{Scoped{Fragment}}` and excludes
`Scoped{Scoped{Reads}}`. The chain on the read set keeps the two algebras
apart at the type level, with every existing guard, `Taps`' parameters and
the trim setup's check intact. The rebase is §14.3's flattening on the
read side: the mount step answers where a selector reads, the resolvers
answer what is declared there, and linearization's seeding logic runs on
root-authored selectors unchanged, the pinning meet seeing the root input
the chain landed on.

**Rejected.**
- *`Scoped{Reads}`, the sketch's literal reuse:* the union leak above; the
  guards on `Taps` and in the trim setup widen, and a catch-all in the
  flattening pass stands in for a composition-time refusal.
- *Joining the prefix into every selector's path at `at`:* path arithmetic
  at composition (§14.2), and the chain could no longer be walked level by
  level (§13.3).
- *A mount-aware resolver per selector kind instead of a rebase:* every
  resolver and the seeding logic would take the mount as an argument, and
  the face-level checks would be repeated per kind.
```

## Stage 2: the read side

One commit, on stage 1's. `readers.jl` with
`Reads.prefixes`, `MountedRead`, `_mount`, the rebase and the resolvers'
new second parameter; `conditions.jl` with `at(::Reads)` and the shared
face lookup; `linearize.jl`'s `_resolve_taps` and `_seeded_tap` over
`MountedRead` (the `at(::Taps)` method is stage 3's); `diagnostics.jl`;
`test/imports.jl` for what the tests name. The routed subset is the
`readers`, `conditions`, `trim`, `linearize` row of "Running the suite",
plus `diagnostics` and `bindings` for the kind fields and the face matcher,
under the gate's flags.

Tests in `test_readers.jl` unless named. Every refusal asserts kind,
reason, `mount` and the payload field the testset names; message text is
asserted only in `test_diagnostics.jl`'s rendering testset.

- **Composition is inert.** `at("a", at("b", reads(q = get_state("p",
  :q))))` has `prefixes == ("a", "b")` and the selector untouched, no
  string joined; `reads(...)` has `prefixes == ()`.
- **A mounted set reads what a root-authored set reads.** A group holding
  `readable()` at `inner`, its two root inputs and its face re-exported.
  `at("inner", readable_reads())` compiled and gathered at `Float64` and
  `D8` equals, field by field, a root-authored twin whose paths carry
  `inner/`, whose `get_input(:u)` is the root's and whose `get_face(:y)` is
  the root's; and the mounted `face` read equals `y`, the producer's cell.
  A mounted `get_state("plant", "q[2]")` reads the component, the leaf
  carried through.
- **Dotted faces behind a mount.** `dotted_model()` wrapped at `inner`,
  its root input re-exported as `outer.left.brake` and its faces `pose`
  and `pose.v` as `pose` and `pose.v`. `at("inner", reads(b =
  get_input("left.brake[2]"), v = get_face("pose.v[2]"), m =
  get_face("pose.m[1,2]")))` reads `2.5`, `8.0` and `3.0`: the longest
  face wins at the mount level as at the root, and the steps ride through
  the rebase to a dotted root input. A root-authored
  `get_input("outer.left.brake[2]")` reads the same cell.
- **The chain at a mount.** In a world where a level's face is fed by a
  sibling (`tri()`'s shape, `trig/sig` from `plant/y`, in `test_readers.jl`
  as its own fixture): `at("trig", reads(s = get_input(:sig)))` is
  `:internally_wired` with `producer == ("plant", :y)` and `mount ==
  "trig"`; `at("plant", reads(n = get_input(:nope)))` is `:no_input_face`
  with the plant's input faces as candidates; at the root,
  `reads(n = get_input(:nope))` stays `:unknown_root_input`.
- **The faces at a mount.** `at("inner", reads(f = get_face(:nope)))` is
  `:unknown_output_face` with `inner`'s faces as candidates;
  `at("inner", reads(f = get_face(:u)))`, `u` an input face there, is
  `:input_face_not_output`; the root case of the renamed reason keeps its
  existing assertion (180).
- **A primitive as the mount.** `at("inner/plant", reads(q = get_state("",
  :q), y = get_face(:y), u = get_input(:u)))` reads the plant's state, its
  own port and the root input feeding it.
- **The walk at the mount level** (extend 231–265). On
  `GenericHold(SampledLoop())`, `at("inner", reads(q = get_state("plant",
  :q)))` resolves where `get_state("inner/plant", :q)` is refused
  `:past_generic`: mounting *to* a generic child is legal, and the authored
  path below it is checked from the mount. A mount chain that walks past a
  generic child (`at("inner/plant", …)` there) is `:past_generic` with
  `entry` starting "the read set". An unknown prefix is `:unknown_child`
  with the sibling list.
- **Collecting.** One mounted set with a bad path, a wired input and an
  unknown face yields one refusal with three diagnostics, every `mount`
  set.
- `test_diagnostics.jl`: renderings for `:no_input_face`,
  `:internally_wired` and a mounted `:undeclared` (non-empty strings);
  `:root_input_not_face` renamed at 513.

## Stage 3: the lifts

One commit, on stage 2's. `at(::TrimProblem)` in `trim.jl`, `at(::Taps)`
in `linearize.jl`, their docstrings, `implementation.md`, `pending.md`.
Same routed subset.

- **A problem relocates** (`test_trim.jl`). `fed(Pendulum(), :u)` wrapped
  once more, `Group((; rig = fed(Pendulum(), :u)); inputs = ("in" =>
  "rig/in",))`. `trim!` of `θ_problem()` on the flat world and of `at("rig",
  θ_problem())` on the wrapped one, both with `baseline = pend_base()`:
  `converged`, `solution`, `residuals`, `status`, `n_evaluations` and
  `n_iterations` equal, and `state(sim, "c")` equals `state(sim, "rig/c")`
  after the commits. The decision's `inputs = (in = d.u,)` reaches the
  root input through `rig`'s face. Then the same problem mounted twice,
  `at("outer", at("rig", …))` on a three-level world, equal again.
- **A problem with checks relocates**: `check_tolerances` and
  `committed_checks` pass through.
- **The untrimmable face** (`test_trim.jl`). A problem authored against the
  pendulum alone (`inputs = (u = d.u,)`, `reads(ω̇ = get_deriv("", :ω))`)
  mounted at `c` in `fed(Pendulum(), :u)` solves; mounted at `c` in
  `sampled_pend()`, where `c/u` is fed by `ctl/u`, `trim!` refuses: the
  condition's `ConditionResolution` `:internally_wired` from the nominal
  resolve, with the producer.
- **A malformed `reads` passes through the lift**: `at("rig", problem)`
  with `reads = (;)` raises nothing, and `trim!` reports
  `TrimProblemInvalid` `:not_a_read_set`.
- **A tap set relocates** (`test_linearize.jl`). `lin_pend()` wrapped at
  `rig` with both root inputs and both faces re-exported; `linearize` of
  `lin_taps()` on the flat world at `lin_point()` and of `at("rig",
  lin_taps())` on the wrapped one at `at("rig", lin_point())`, compared
  with `same_linearization`, labels included.
- **The meet at a mount.** `at("g", taps(u = (e = get_input(:e),)))` on
  `lin_pinned()` is `:unseedable` with `field == :τ` (the root input the
  chain landed on) and `g` the pinning consumer; `at("c", taps(u = (u =
  get_input(:u),)))` on `lin_pend()` is `:internally_wired` with producer
  `("s", :e)`; a `get_face` in the `x` list of a mounted set is still
  `:tap_kind`.
- `implementation.md`: the `readers.jl` entry replaces "The family's path
  selectors are walked from the root (§13.3)" with the mount chain, the
  rebase and `MountedRead`, citing D-277; the `conditions.jl` entry says
  `at` lifts read sets, problems and tap sets; the `trim.jl` and
  `linearize.jl` entries name their `at` method; the `diagnostics.jl`
  entry's `TapResolution` line names `mount`, `producer` and the two
  reasons. `pending.md`: delete the "Mounting" bullet (21–23) and keep
  the "Compile time" bullet another session added below the NLopt
  fallback (`eac7773`).

## The cold review

One fresh Opus reviewer over the three commits: open-mind stance, probe
scripts in the scratchpad, "empty is acceptable". Dimensions: the ruling's
conformance in the spec and the code; §13.3's mount-level rule (a mount
*to* a generic child legal, a chain *past* one refused); the root case
bit-for-bit as before (every existing `test_readers.jl`, `test_trim.jl`,
`test_linearize.jl` assertion unchanged); the leaf address carried through
every rebase, dotted faces included; the pinning meet at a mount; "Naming"
(`implementation.md` 890) over every touched file; no `Scoped` wrapping a
`Reads` anywhere; the docs battery green; the gate, run once, reported
with the findings.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or
check out the working tree; baselines come from `git show <tip>:file`
with the tip the prompt names. Never add or commit a file this brief does
not name: the tree carries another session's untracked and modified
files, and `git add -A` is forbidden. Re-read any file right before a
scripted edit, and never restore or overwrite a file from HEAD. Grep every new fixture name across `test/` before defining
it: a same-named type rebinds a fixture module silently. Fixtures live at
top level. Report: the commit hash, the files touched, the routed subset's
result with the assertion count, and every deviation from this brief with
its reason.
