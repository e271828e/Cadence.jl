# Brief: increment 66, the structure blocks `Pack`, `Unpack` and `Switch`, and the time source `Source`

Two code stages, one cold review and a fixer if the review needs one. No
docs arc precedes it: the four blocks are the candidate rows of
`docs/design/companions/library_inventory.md` under "Structure" and
"Sources", and none needs a companion. The tip at launch is the commit
adding this brief; line numbers below are e228e88's. Find passages in
`docs/design/implementation.md` by heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **Four blocks, two mechanisms.** `Pack`, `Unpack` and `Switch` exist
  because the declaration layer forces them: wires name whole ports, and a
  junction has one `In`. `Source` exists because a ramp and a sine do not
  each earn a block. None earns a log entry: D-313 admits by judgement, and
  the PID and the linear blocks set the precedent. Every one is a stateless
  continuous leaf, `x_init` the empty store, with no event and no mode.
  `Freeze` over a struct `V` is out of the tranche (user, 2026-10-07).
- **`Pack{V, N}` is a junction alias at a named fold.** As `SumJunction{V,
  N}` is `Junction{V, V, N, typeof(+)}`, `Pack{V, N}` is `Junction{V,
  SVector{N, V}, N, typeof(pack)}`, with `pack(args...) = SVector(args)` a
  package function of the submodule and the zero-argument constructor
  `Pack{V, N}() = Pack{V, N}(pack)`. The fold is a named function and not
  `SVector` itself because `typeof(SVector)` is `UnionAll`, which pins
  nothing: with `SVector` as `f`, the sweep dispatches dynamically and
  allocated 224 bytes per stage-2 sweep in the probe, where `pack` allocates
  nothing. `pending.md`'s `Junction{V, SVector{N, V}, N}(SVector)` is that
  shape with the fold named. `V` is the scalar, spelled, so `Pack{Float64,
  3}()` has `u_types == (in1 = Float64, in2 = Float64, in3 = Float64)` and
  `y_types == (out = SVector{3, Float64},)`; `Pack{Bool, 2}` is admitted as
  any junction parameter is. The two parameters mirror `SumJunction`'s; the
  inventory's `Pack{N}` spelling predates the choice and is updated in the
  bookkeeping.
- **`Unpack{V, N}` is the inverse, a block with `N` outputs.** A struct with
  no fields, `u_types == (in = SVector{N, V},)`, `y_types == (out1 = V, …,
  outN = V)`, and `y_direct` returning `NamedTuple{names}(Tuple(u.in))`
  from stage 2. The names come from one generated helper,

  ```julia
  @generated output_names(::Val{N}) where {N} = ntuple(i -> Symbol(:out, i), N)
  ```

  which returns the literal tuple, so the body sees a constant. `y_types`
  and `y_direct` both spell `NamedTuple{output_names(Val(N))}`. The
  junction's `ntuple(i -> Symbol(:in, i), N)` idiom is fine in a
  declaration, which runs at build, and wrong in a body: with the names
  built in `y_direct` the sweep allocated 736 bytes in the probe. `out1…outN`
  is the one place the library's output is not `out`, mirroring `in1…inN`;
  the inventory's port-name sentence gains it.
- **`Switch{V}` selects on a `Bool`.** A struct with no fields,
  `u_types == (in1 = V, in2 = V, select = Bool)`, `y_types == (out = V,)`,
  and `y_direct` publishing `ifelse(u.select, u.in1, u.in2)`: `in1` while
  `select` holds, `in2` otherwise. `ifelse` over `? :` so both arms stay one
  value of `V`. The block is memoryless and declares no event, so the jump
  in `out` lands where `select` flips. A `select` published from a mode, or
  held between ticks, flips on a boundary and the jump is clean; one
  computed from a continuous quantity inside a stage body flips inside a
  step and smears that step, the mode made silently that the junction's
  docstring already names and the moded blocks exist to declare (§2.1,
  D-179). The docstring says so. `select` makes a feedthrough edge like the
  two values: a selector wired from a memoryless function of the switch's
  own output is refused at build as an `AlgebraicCycle` classified `:real`,
  confirmed in the probe.
- **`Source{V}(f)` publishes `f(t)`, pinned, from stage 1.** The struct
  holds `f::F`, `F` inferred as the junction infers its fold, with `V`
  spelled: `Source{V}(f)`, and `Source(f) = Source{Float64}(f)` for the
  common case. `y_types == (out = Pinned{V},)` and `y_state(c, (; t)) =
  (out = c.f(ForwardDiff.value(t)),)`. The strip is the point: the clock's
  `t` is the activation scalar, a `Dual{LinearizeTag, Float64, 8}` under
  `LinearizeDual` in the probe, so an unstripped `f(t)` returns a `Dual`
  into a `Float64` cell and the Dual build fails with a
  `ConformanceFailure`. Stripped, `f` receives the nominal `Float64` time
  under every activation and need not be generic, and `out` carries exactly
  zero partials, which is D-312's argument for the pin: it depends on
  neither a state nor a walking input, and the pinned form is the more
  connectable one. A walking `out` would be refused at a pinned entry
  (`WalkingFaceAtFrozenEntry`), the mutant the review runs. `f` returns a
  `V`, and nothing converts: a `Source(t -> 1)`, a `Source(t -> 1f0)` and a
  `Source(t -> SVector(t, t))` are each refused at build as a
  `ConformanceFailure`, while `Source{Int}(t -> 1)` builds and publishes an
  `Int`. `ForwardDiff` is already imported by the submodule.
- **Names.** `Pack`, `Unpack`, `Switch`, `Source`, `pack` and `output_names`
  are free across `src/` and `test/` (grepped; `select` exists only as the
  passthrough keyword of `src/assembly.jl`, a different namespace, and as a
  port name it reads as the verb). `t` stays time.
- **Every number below was probed at e228e88's tree** with the shapes above,
  sampling by `step!`. Confirm each in a probe before writing an assertion,
  and report the probe's numbers.

## Out of scope

- `Freeze` over a struct `V`. D-312's "waits for a model to demonstrate it"
  stands, and the inventory row stays a candidate under `pending.md`'s
  after-release bullet on the library's remaining candidates.
- A switch with a threshold on a continuous selector (the relay is that
  mode), a multi-way switch, a switch whose `select` is pinned.
- A `Pack` over mixed element types, an `Unpack` into a struct, a `Pack`
  into an `SMatrix`.
- A discrete-tier source, the noise source (increment 65), and a `Source`
  reading anything but `t`.
- A `show` method, an export, any spec or log edit, and any companion edit
  beyond the inventory rows named in the bookkeeping.

## Reading, in order

- `docs/design/pending.md`, the increment 66 bullet, lines 27 to 35.
- `docs/design/companions/library_inventory.md` sections 2 to 4.
- `docs/design/spec.md` §2.1, lines 229 to 273; §5.3, lines 826 to 1037,
  above all the two rules under "Stage roles"; §6.1, lines 1223 to 1353,
  the walk clause on pinned entries; §6.2, lines 1354 to 1504; §7.2, lines
  1625 to 1694; §7.5, lines 1894 to 1976; §13.7, lines 9726 to 9954; §14.10,
  lines 11130 to 11383. Never read the spec whole.
- `docs/design/decisions.md` D-179, D-263, D-311, D-312 with its annotation,
  and D-313.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/blocks.jl` and
  `### test/imports.jl`; "Authoring caveats", its first three bullets;
  "Naming"; "Running the suite". Never restate either in a commit or a
  comment.
- `src/blocks.jl` whole, 684 lines. The junction section (lines 14 to 67)
  is the alias pattern `Pack` copies, `Constant` (lines 71 to 87) the
  pinned stage-1 source `Source` copies, `Freeze` (lines 109 to 122) the
  strip, and `Step` (lines 331 to 371) a block reading `t`. The section
  comments at lines 14, 69, 124, 169, 331, 373, 553 and 633 give the file's
  order.
- `test/test_blocks.jl` whole, 996 lines: the models at top level (lines 1
  to 237), `gate_model` (line 10) and `blocks_sum_model` (line 15), the
  junction testsets (lines 239 to 262), the sum model's allocation testset
  (line 314), the step testsets (lines 500 to 560) for the `single` idiom
  and a `Dual` build beside a run, `block_linearization` (line 80), the
  keyword testset (line 913), the loops' allocation testset (line 937), the
  shadowing testset (line 961).
- `test/utils.jl` lines 1 to 30: `single` and `fed`. `test/test_build.jl`
  lines 432 to 451: `RealEntry` and `PinnedEntry`, the two consumers the
  freeze and constant testsets reuse. `test/fixtures.jl` line 1170: `Ramp`,
  a walking source of `t`.

## Stage 1: `Pack` and `Unpack`

### The shape

`pack`, the `Pack{V, N}` alias and its zero-argument constructor join the
junction section after `And`'s, with a docstring in `SumJunction`'s form
that names the fold and says why it is not `SVector`. A new section
`# --- the structure blocks (§13.7, D-313) ---` follows the junction's,
before the leaf blocks, holding `output_names`, `Unpack` and, after stage
2, `Switch`. `Unpack`'s docstring shows `Unpack{V, N}()`, names the port
types and `out1…outN`, and says in one sentence why the names come from a
generated helper.

Probed values, at `h = 1//10` unless said:

- `pack_model(p) = Group((; a = Ramp(0.0), b = Constant(2.0), p = p);
  local_wires = ("a/out" => "p/in1", "b/out" => "p/in2"))` with
  `Pack{Float64, 2}()`, stepped to `t = 0.3`: `out ≈ SVector(0.3, 2.0)` at
  `atol = 1e-12` (the probe's first component is `0.30000000000000004`);
  the model builds under `(Float64, LinearizeDual)`; its four phase bodies
  allocate nothing, and the same model at `Junction{Float64, SVector{2,
  Float64}, 2}(SVector)` allocates 224 bytes in `sweep_2`, the mutant;
- the root form `Group((; p = Pack{Float64, 2}()); input_wires = ("a" =>
  "p/in1", "b" => "p/in2"), output_wires = ("p/out" => "v",))` at
  `h = 1//100`, `init!` with `a = 1.0, b = 2.0`, `linearize` over
  `u = (a, b)` by `get_input` and `y = (v1, v2)` by `get_face("v[1]")`,
  `get_face("v[2]")`: `D ≈ [1 0; 0 1]` at `atol = 1e-12`;
- `unpack_model() = Group((; k = Constant(SVector(1.0, -2.0, 3.5)), u =
  Unpack{Float64, 3}()); local_wires = ("k/out" => "u/in",))`: after
  `init!`, `out1`, `out2`, `out3` read `1.0`, `-2.0`, `3.5` exactly (a copy,
  not an integration, so `==` is right); builds under `(Float64,
  LinearizeDual)`; allocates nothing, where the names built in the body
  allocate 736 bytes in `sweep_2`;
- the root form `Group((; u = Unpack{Float64, 2}()); input_wires = ("v" =>
  "u/in",), output_wires = ("u/out1" => "a", "u/out2" => "b"))`, `init!`
  with `v = SVector(1.0, 2.0)`, `linearize` over `u = (v1, v2)` by
  `get_input("v[1]")`… and `y = (a, b)` by `get_face`: `D ≈ [1 0; 0 1]`;
- the round trip `Group((; a = Ramp(0.0), b = Constant(2.0), p =
  Pack{Float64, 2}(), u = Unpack{Float64, 2}()); local_wires = ("a/out" =>
  "p/in1", "b/out" => "p/in2", "p/out" => "u/in"))` at `t = 0.3`: `out1 ≈
  0.3`, `out2 == 2.0`; builds under `(Float64, LinearizeDual)`; allocates
  nothing;
- `y_types(Unpack{Float64, 1}()) == (out1 = Float64,)`, and
  `Pack{Float64, 2}().f === Redstone.Blocks.pack`.

### Tests

New testsets in `test/test_blocks.jl` after the junction's, models at top
level:

- "the pack is the junction at a static vector, and linearizes to the
  identity (§6.2, §14.10, D-311)": the `u_types`/`y_types` pair for
  `Pack{Float64, 3}`, `typeof(Pack{Float64, 2}()) === Junction{Float64,
  SVector{2, Float64}, 2, typeof(Redstone.Blocks.pack)}`, the `t = 0.3`
  sample, the `D == I` linearization, the `Dual` build.
- "the unpack splits a static vector into scalar ports, named `out1` on
  (§13.7, D-313)": the three exact reads, `y_types` at `N = 3` and `N = 1`,
  the `D == I` linearization, the `Dual` build, and the round trip's two
  reads.
- "the structure blocks' phase bodies allocate nothing (§7.5)" over
  `phase_bodies`, the idiom of line 314, for `pack_model`, `unpack_model`
  and the round trip; stage 2 extends it.
- The shadowing testset's tuple gains `Pack{Float64, 2}()` and
  `Unpack{Float64, 2}()`.

### Routing

`src/blocks.jl` is the `blocks` row: run `blocks build` under the flags of
"Running the suite", in the foreground, 600 s per invocation.

### Bookkeeping, in the same commit

- `test/imports.jl` line 77: `Pack` and `Unpack` join the `import
  Redstone.Blocks:` line.
- `docs/design/implementation.md` `### src/blocks.jl`: the junction bullet
  grows to "`Junction`, with the aliases `SumJunction`, `Or`, `And` and, at
  the fold `pack`, `Pack` (D-311, D-313)", and a new bullet after it,
  "`Unpack`, its output names from the generated `output_names` (D-313)".
  Constructs, not behaviour.
- `docs/design/companions/library_inventory.md`: the `Pack`/`Unpack` row's
  status becomes *shipped*, its block cell reads "`Pack{V, N}`, a junction
  alias at a named fold, and `Unpack{V, N}` between scalar ports and an
  `SVector{N, V}` port", and section 3's port-name sentence (line 82) gains
  "and `out1…outN` for a block with several outputs". Linkified spelling;
  run the battery, `linkify` a no-op on rerun.

## Stage 2: `Switch` and `Source`

### The shape

`Switch` closes the structure section after `Unpack`. `Source` gets a
section of its own, `# --- the time source (§13.7, D-313) ---`, after the
leaf blocks and before the continuous dynamics. `Switch`'s docstring shows
`Switch{V}()`, names the three ports and the rule, and carries the
where-the-jump-lands sentence of "What is settled". `Source`'s shows
`Source{V}(f)` and `Source(f)`, says `f` receives the nominal `Float64`
time under every activation and returns a `V`, that `out` is pinned and
why in one sentence (D-312), and that a source set from outside is a root
input (§11.3), as `Constant`'s does.

Probed values, at `h = 1//10` unless said:

- `switch_root() = Group((; s = Switch{Float64}()); input_wires = ("in1" =>
  "s/in1", "in2" => "s/in2", "select" => "s/select"), output_wires =
  ("s/out" => "out",))` at `h = 1//100`: `init!` with `in1 = 1.0, in2 =
  -1.0, select = true` reads `out == 1.0`, and `linearize` over `u = (in1,
  in2)`, `y = (out,)` gives `D == [1 0]`; the same `init!` with `select =
  false` reads `-1.0` and `D == [0 1]`, both at `atol = 1e-12`. A `Bool`
  root input takes `true` from a fragment as any other does. Builds under
  `(Float64, LinearizeDual)`; allocates nothing;
- the vector switch `Group((; a = Constant(SVector(1.0, 2.0)), b =
  Constant(SVector(-1.0, -2.0)), k = Constant(false), s = Switch{SVector{2,
  Float64}}()); local_wires = ("a/out" => "s/in1", "b/out" => "s/in2",
  "k/out" => "s/select"))`: `out == SVector(-1.0, -2.0)`; `u_types` is
  `(in1 = SVector{2, Float64}, in2 = SVector{2, Float64}, select = Bool)`;
  `Dual` build and zero allocation;
- the mixed model `Group((; r = Ramp(0.0), k = Constant(2.0), f =
  Constant(true), s = Switch{Float64}()); …)`, a walking value beside a
  pinned one, builds under `(Float64, LinearizeDual)`;
- the cycle `Group((; s = Switch{Float64}(), a = Constant(1.0), b =
  Constant(-1.0), g = Junction{Float64, Bool, 1}(x -> x > 0)); local_wires
  = ("a/out" => "s/in1", "b/out" => "s/in2", "s/out" => "g/in1", "g/out" =>
  "s/select"))` is refused: `DiagnosticError`, one `AlgebraicCycle`,
  `classification === :real`;
- `source_model(src, i) = Group((; s = src, i = i); local_wires = ("s/out"
  => "i/in",))` with `Source(sin)` and `Integrator()` at `h = 1//100`,
  stepped to `t = 1`: `q = 0.45969769413345646` against `1 - cos(1) =
  0.45969769413186023`, error `1.6e-12`, so assert `atol = 1e-10`; `out ==
  sin(1.0)` exactly, `0.8414709848078965`, a frame-top stamp of the grid
  time; `y_types(Source(sin)) == (out = Pinned{Float64},)`;
  `typeof(Source(sin)) === Source{Float64, typeof(sin)}`; `Dual` build; zero
  allocation, with `sin` and with the closure `t -> 2 * sin(t)` alike;
- `Source{SVector{2, Float64}}(t -> SVector(sin(t), cos(t)))` into
  `Integrator(x0 = SVector(0.0, 0.0))`, `t = 1`: `q ≈ SVector(1 - cos(1),
  sin(1))`, errors `1.6e-12` and `2.9e-12`, assert `atol = 1e-10`; `Dual`
  build; zero allocation;
- `single(Source(t -> 2t))` with `init!(sim, fragment(); t0 = 1.0)` reads
  `out == 2.0` at `t₀`, and stepped from `t₀ = 0` to `t = 0.3` reads `≈
  0.6`;
- `Group((; s = Source(sin), e = PinnedEntry()); local_wires = ("s/out" =>
  "e/u",))` builds under `(Float64, LinearizeDual)`: the pinned source feeds
  the pinned entry, which a walking `out` could not;
- `single(Source(t -> 1))`, `single(Source(t -> 1f0))` and
  `single(Source(t -> SVector(t, t)))` are each refused at build with one
  `ConformanceFailure`; `single(Source{Int}(t -> 1))` builds and reads
  `out === 1`;
- the flip `Group((; a = Constant(1.0), b = Constant(-1.0), k =
  Source{Bool}(t -> t >= 0.5), s = Switch{Float64}(), i = Integrator());
  local_wires = ("a/out" => "s/in1", "b/out" => "s/in2", "k/out" =>
  "s/select", "s/out" => "i/in"))` builds under `(Float64, LinearizeDual)`
  and allocates nothing. Its trajectory is the smear the docstring warns of
  (`q(0.5) = -0.4667` where a boundary flip would give `-0.5`, the last
  RK4 stage of the step reading `true`), a stepper fact no test asserts.

### Tests

- "the switch publishes the selected input and linearizes to its selection
  (§13.7, §14.10, D-313)": the two root reads and their `D` rows, the vector
  read and `u_types`, the mixed model's `Dual` build.
- "a selector wired from a memoryless function of the switch's own output
  closes an algebraic cycle (§5.3, §5.5)": the refusal, kind and
  classification.
- "the source publishes `f` at the grid time, pinned, and walks nothing
  (§13.7, §7.2, D-312, D-313)": the `∫ sin` sample and the exact `out`, the
  vector integral, the `t₀ = 1` read, `y_types`, the pinned-entry `Dual`
  build, and `Source{Int}`'s read.
- "the source refuses a value that is not a `V` (§9.5)": the three
  `ConformanceFailure`s, kind asserted on the one diagnostic through
  `failure` and `diagnostics`, as the delay testset at line 274 does.
- The keyword testset is untouched, since none of the four blocks takes a
  keyword; the shadowing tuple gains `Switch{Float64}()`, `Source(sin)` and
  `Source{Bool}(t -> t >= 0.5)`; the
  structure blocks' allocation testset gains `switch_root()`, the vector
  switch, `source_model(Source(sin), Integrator())`, the vector source and
  the flip.

### Routing

`blocks build`, as in stage 1.

### Bookkeeping, in the same commit

- `test/imports.jl`: `Switch` and `Source` join the line.
- `docs/design/implementation.md` `### src/blocks.jl`: the stage 1 `Unpack`
  bullet grows to "`Unpack`, its output names from the generated
  `output_names`, and `Switch` (D-313)", and a new bullet "`Source`, pinned,
  its `f` fed the nominal time (D-312, D-313)".
- `docs/design/companions/library_inventory.md`: the `Switch` row's status
  becomes *shipped* and its mechanism cell reads "the `Bool` a junction's
  one `In` cannot type; the jump lands where the selector flips, so the
  event is the selector's producer's"; the `Source` row's status becomes
  *shipped*, its block cell "`Source{V}(f)`, a user function of the nominal
  `t`", its mechanism cell gaining "pinned (D-312): `t` is the activation
  scalar, stripped before `f`".
- `docs/design/pending.md`: the increment 66 sub-bullet is removed, the
  struct `Freeze` sentence with it. If the increment 65 sub-bullet is
  already gone, the parent bullet goes too; otherwise the parent reads "one
  remaining tranche". `check_refs.jl` and `check_rows.jl` read this file;
  run the battery.

## The cold review

One fresh Opus reviewer over the two code commits: open-mind stance, probe
scripts under `/tmp`, "empty is acceptable". Dimensions:

- **Each block against its sketch here**: the alias at the named fold, the
  generated names, the three ports and `ifelse`, the strip of `t` and the
  pin, the stage of each (`has_stage` on the instance: `Source` declares
  `y_state` alone, the other three `y_direct` alone).
- **The submodule's imports.** `src/blocks.jl` reaches the parent through
  its import list alone; `SVector` and `ForwardDiff` are already there, and
  nothing new is needed.
- **Mutants on a scratch copy**, each named test going red: `SVector`
  itself as `Pack`'s fold (the allocation testset, 224 bytes); `Unpack`'s
  names built in the body (the allocation testset, 736 bytes); `Unpack`'s
  outputs in reverse order (the exact reads); the switch's arms swapped (the
  root reads and `D`); `Source` calling `f(t)` unstripped (the `Dual`
  builds, `ConformanceFailure`); `Source` with `(out = V,)` (the
  pinned-entry build, `WalkingFaceAtFrozenEntry`); `Source` converting its
  value with `convert(V, …)` (the three refusals). A surviving mutant is a
  missing test.
- **The numbers.** Re-probe every asserted value against this brief.
- **`Dual`.** Every new model builds under `(Float64, LinearizeDual)`, and
  the linearizations assert `D`, so a `Float64` pin on a walking path is a
  red test.
- **The register and the inventory.** `implementation.md`'s rows name
  constructs; behaviour is in docstrings; the docstrings and the inventory
  rows agree, the where-the-jump-lands sentence and the strip above all.
- "Naming" over every touched file, the docs battery, and the gate once on
  the real tree.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new name across `test/`
before defining it. Models and helpers live at top level. Report: the
commit hash, the files touched, the routed subset's result with the
assertion count, the probe's numbers for every asserted value, and every
deviation from this brief with its reason.
