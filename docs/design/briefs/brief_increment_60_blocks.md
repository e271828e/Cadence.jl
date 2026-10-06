# Brief: increment 60, the standard component library

Two code stages, one cold review and a fixer if the review needs one. The
docs arc is landed: D-311 (one generic `Junction`), D-312 (the leaf blocks'
spellings) and D-313 (the admission rule and the `Redstone.Blocks`
submodule), commits 8fdeb3c, ae15e46 and 0b7725d.

The tip at launch is 0b7725d, "Admit library blocks by the framework
mechanism they encode, house them in Redstone.Blocks, and record the
extended inventory in a companion (D-313)". Line numbers below are that
tip's. Find passages in `docs/design/implementation.md` by heading.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **The library is the submodule `Redstone.Blocks`** in `src/blocks.jl`,
  `Group` included. It is written as a user's component file is: its first
  lines import the declaration names from the parent module, and it reaches
  nothing else of the package (§13.7, D-313).
- **Six members.** `Junction{In, Out, N, F}` with the aliases
  `SumJunction{V, N}`, `Or{N}` and `And{N}` (D-311); `Constant{V}`,
  `UnitDelay{V}` and `Freeze{V}` (D-312); and `Group`, moved from
  `src/assembly.jl` with its `_entries` helper (D-184).
- **Every block's output port is `out`**; the junction's inputs are
  `in1…inN`, the delay's and the freeze's input is `in`.
- **The rig is an idiom, not code** (§13.7). Stage 2 demonstrates it as a
  test.
- **The §5.5 diagnostic names the block and its tier consequence.**
  `_BREAK_CYCLE` in `src/diagnostics.jl` is the one site.

## Out of scope

- Every candidate row of `docs/design/companions/library_inventory.md`.
- A struct-valued `Freeze` and the allocation-free leafwise map (D-312).
- Exports. The module exports nothing until the audit (D-226); tests reach
  the blocks through `test/imports.jl`.
- Any spec or log edit. The docs arc is done.

## Reading, in order

- `docs/design/spec.md` §13.7, lines 9713 to 9936, whole: the library and
  the rig. §6.2, lines 1354 to 1504: the junction. §5.5, lines 1108 to 1127:
  the loop remedy. §8.1, lines 1993 to 2212: the import list a component
  file opens with. Never read the spec whole.
- `docs/design/decisions.md` D-311, D-312, D-313, and D-184 with its
  annotations.
- `docs/design/implementation.md`: the head of "What is real here" down to
  its rule on deviations; the rows `### src/assembly.jl`,
  `### src/declare.jl`, `### src/Redstone.jl`, `### test/fixtures.jl` and
  `### test/imports.jl`; "Authoring caveats", above all its first three
  bullets; "Naming", which governs every name you add or touch; "Running
  the suite", the one home of test policy. Never restate either in a commit
  or a comment.
- `src/declare.jl` whole, for the names a component file imports.
- `src/assembly.jl` 268 to 320: `Group`, its constructor and `_entries`.
- `src/assembly.jl` 1040 to 1070: the shadowing check (D-246), which reads
  `parentmodule(typeof(comp))`. A block's parent module is `Blocks`, where
  the declaration names are imported bindings of the parent's functions,
  not foreign ones. Confirm that a block builds without `DeclarationShadowed`.
- `test/fixtures.jl` 1200 to 1300: the handle fixtures `HeightField`,
  `height_field`, `Terrain`, `Query`, `AbstractTerrain` and
  `AbstractTerrainQuery`.
- `test/test_build.jl` 1740 to 1800: the `Dual` sweep and how it enumerates
  the fixtures it builds. Report whether it reaches the blocks' types.
- `test/test_executor.jl` 1 to 60: the allocation idiom over a phase body.
- `test/test_linearize.jl` 1 to 120: how a linearization is requested and
  its matrices read.
- `test/test_assembly.jl` 780 to 840: the passthrough selectors in use.
- `README.md` 40 to 90: the quick start's import list and its `Group`.

## Stage 1: the submodule

### The shape

`src/blocks.jl` holds `module Blocks … end`, included last in
`src/Redstone.jl`: nothing in the package depends on it, and the order says
so. Its first lines:

```julia
module Blocks

import ..Redstone: AbstractComponent, Pinned,
    x_init, s_init, u_types, y_types, y_direct, y_state, s_update,
    inner_wires, input_wires, output_wires, sample_times, transparent_container
using StaticArrays: StaticArray
import ForwardDiff
```

Nothing else of `Redstone` is reached. A grep of the file for `Redstone.`
beyond that import, or for any `_`-prefixed parent name, must be empty.

The junction, in the spelling the probe confirmed on 2026-10-06:

```julia
struct Junction{In, Out, N, F} <: AbstractComponent
    f::F
end
(::Type{Junction{In, Out, N}})(f) where {In, Out, N} = Junction{In, Out, N, typeof(f)}(f)

const SumJunction{V, N} = Junction{V, V, N, typeof(+)}
const Or{N}  = Junction{Bool, Bool, N, typeof(|)}
const And{N} = Junction{Bool, Bool, N, typeof(&)}
(::Type{SumJunction{V, N}})() where {V, N} = SumJunction{V, N}(+)
(::Type{Or{N}})() where {N} = Or{N}(|)
(::Type{And{N}})() where {N} = And{N}(&)

x_init(::Junction) = (;)
u_types(::Junction{In, Out, N}) where {In, Out, N} =
    NamedTuple{ntuple(i -> Symbol(:in, i), N)}(ntuple(_ -> In, N))
y_types(::Junction{In, Out}) where {In, Out} = (out = Out,)
y_direct(j::Junction, (; u)) = (out = j.f(u...),)
```

`Constant{V}` with `value::V`, `(out = Pinned{V},)` and a `y_state` body
returning the value. `Freeze{V <: Union{Real, StaticArray{<:Tuple, <:Real}}}`
with `(in = V,)`, `(out = Pinned{V},)` and `y_direct` returning
`ForwardDiff.value.(u.in)`. `UnitDelay{V}` with `v0::V`, `s_init` returning
`(v = d.v0,)`, `(in = V,)`, `(out = V,)`, `y_state` publishing `s.v` and
`s_update` storing `u.in`. All three sketches are in §13.7 at the tip.

`Group` moves verbatim with its docstrings, its constructor and `_entries`.
`src/assembly.jl` keeps nothing of it, section comment included.

Each block carries a docstring that says what the spec says of it, in
particular `UnitDelay`'s tier consequence and `Constant`'s pin. Docstrings
describe behaviour; the register entry names constructs.

### Call sites that move

- `test/imports.jl`: `Group` leaves the `import Redstone:` list, and a second
  line `import Redstone.Blocks: Group, Junction, SumJunction, Or, And,
  Constant, Freeze, UnitDelay` joins it. `test/repl.jl` includes the same
  file and needs nothing.
- `README.md` line 48: `Group` moves to its own `import Redstone.Blocks:`
  line. The quick start is a component file.
- No file in `src/` names `Group` outside `assembly.jl`.

### Tests

A new `test/test_blocks.jl`, included in `test/RedstoneTests.jl` after
`test_build.jl` and registered wherever that file lists its test functions.
Each test is red at the tip, trivially, since the names do not exist; the
point is that each goes red again under the mutants the review runs.

- **The junction's contract.** `u_types(Or{3}())` has keys `in1`, `in2`,
  `in3` at `Bool` and `y_types` is `(out = Bool,)`; `Junction{Float64,
  Float64, 3}(f)` infers `F`; `Or{3}() isa Junction`; `SumJunction{Float64,
  2}()` folds with `+`. The alias prints by its own name: assert with
  `endswith(repr(typeof(Or{3}())), "Or{3}")`, never an interpolated full
  name (the printing-module caveat).
- **Truth tables.** One model per gate, inputs from `Constant(true)` and
  `Constant(false)`, `out` read off the snapshot with `port`. `Or{3}` and
  `And{3}` over at least a true-false mix and the all-true case.
- **The sum.** A `SumJunction{Float64, 3}` over a walking source, a
  `Constant` and a `UnitDelay` output, in one model: the value is the sum
  of the three cells read individually. The same model under
  `build(m; activations = (Float64, LinearizeDual))` builds, which is the
  pinned-into-tolerant wire of §6.1 under a `Dual` activation.
- **The delay.** A `UnitDelay(v0)` fed from a `TickCounter`-style discrete
  source: at tick `k` its `out` is the source's value at `k - 1`, and at the
  first publication it is `v0`. A `v0` that is not isbits is refused at
  build; assert the kind, not the text.
- **The freeze.** A model with one continuous state feeding an output twice,
  once directly and once through `Freeze{Float64}`. Linearized, the output
  row's entry through the freeze is `0` and the direct one is `1`.
  `Freeze{HeightField}` is a `TypeError` at the spelling. The freeze's
  nominal value equals its input.
- **The zero-contributor idiom.** `Constant(x)` wired straight into a
  tolerant `Float64` entry, and into a `Pinned{Float64}` entry
  (`PinnedEntry` in `test/test_build.jl`), both build at nominal and under
  `LinearizeDual`.
- **Allocation.** The sum model's phase bodies allocate nothing, by the
  `test_executor.jl` idiom. Interpolate every argument of `@ballocated`.
- **The shadow check.** Every block above builds; none raises
  `DeclarationShadowed`. This is the submodule's reason to exist as a test,
  so say so in the testset's comment.

Every new `AbstractComponent` fixture a test needs lives at top level in
`test/fixtures.jl`, grepped across `test/` before it is named. Report the
`Dual` sweep's three counts before and after.

### Routing

`src/Redstone.jl` changes, which is the table's last row: run the gate
itself, under the sandbox flags of "Running the suite", in the foreground,
600 s per invocation, split by file name as needed.

### Bookkeeping, in the same commit

In `docs/design/implementation.md`:

- A new row `### src/blocks.jl`, alphabetically after `### src/bindings.jl`:
  the submodule, its six members, that it reaches the parent through the
  import list alone, and its Spec line.
- `### src/assembly.jl`: the `Group` bullet goes.
- `### src/Redstone.jl`: unchanged in substance; add the include if the row
  lists them.
- `### test/imports.jl`: mention the `Blocks` line.
- "Running the suite": a row `| blocks | blocks build |` above the `show`
  row.

`implementation.md` is rostered. Run the docs battery after editing it.
Each tool's header says how; `--strict` is a separate argument to
`check_glossary.jl`.

## Stage 2: the rig and the diagnostic

### The rig

A named assembly at top level in `test/fixtures.jl`, in the shape of
§13.7's `StrutRig`:

- A new leaf `TerrainGain` with `u_types = (terrain = AbstractTerrain, k =
  Float64)` and `y_types = (h = Float64,)`, its `y_direct` returning the
  handle's `h0` times `k`. `AbstractTerrainQuery` has no concrete remainder
  to pass through, which is why a new leaf is needed.
- `TerrainRig` holding `dut::TerrainGain` and `stub::Constant{HeightField}`,
  with `inner_wires` wiring `"stub/out" => "dut/terrain"` and `input_wires`
  returning `input_passthrough(rig, "dut"; except = ("terrain",))`.

Tests, in `test/test_blocks.jl` under their own testset:

- `single(TerrainGain())` is refused with the abstract-at-root kind
  (`AbstractAtRoot`); assert the kind and the face it names.
- The rig builds. Its root input faces are exactly `k`. A run with
  `fragment(u = (k = 2.0,))` publishes `dut/h` equal to the stub's `h0`
  times `2`.
- `output_passthrough` is not the rig's business; do not add it.

### The diagnostic

`_BREAK_CYCLE` in `src/diagnostics.jl` (line 917 at the tip) becomes:

> break it with a state, a stage-1 (`y_state`) port, or a `UnitDelay`,
> which moves the signal onto the discrete tier and inserts a Δt_base-scale
> zero-order hold (§5.5)

`test/test_diagnostics.jl` line 920 asserts `"break it with a state"`;
extend the same assertion to `occursin("UnitDelay", rendered)`. Message text
is asserted in that file's rendering testset alone.

### Routing

`diagnostics.jl` beyond a new kind is the table's last row: the gate, as
in stage 1.

### Bookkeeping, in the same commit

- `docs/design/pending.md`: the first bullet under "Before the first
  release" retires, and the paragraph above it loses its sentence on the
  library running in parallel with the inspector. Run the docs battery.
- `docs/design/implementation.md` `### test/fixtures.jl`: `TerrainRig`
  joins the named assemblies if the row lists them by name.

## The cold review

One fresh Opus reviewer over the two code commits: open-mind stance, probe
scripts under `/tmp`, "empty is acceptable". Dimensions:

- **Each block against its spec sketch and its entry.** §13.7's four
  sketches and §6.2's, D-311's and D-312's Position bullets. Port names,
  the pin on `Constant`, the type constraint on `Freeze`, `v0` on the delay.
- **The submodule's imports.** `src/blocks.jl` reaches the parent through
  its import list alone: no qualified `Redstone.` access, no `_`-prefixed
  parent name, nothing of `build.jl`, `leaves.jl` or `assembly.jl`.
- **A mutant per block**, each on a scratch copy, each named test going
  red: `Constant`'s `Pinned` dropped; `Freeze`'s broadcast replaced by the
  identity; `UnitDelay`'s `s_update` returning `s.v`; the junction's fold
  applied in reverse order on a non-commutative `f`; the rig's `except`
  dropped. A surviving mutant is a missing test.
- **`Group` after the move.** `git diff` of the moved text against
  `git show 0b7725d:src/assembly.jl` is empty apart from location; the
  suite's assertion count did not drop.
- **The `Dual` sweep.** Its three counts, and whether the blocks' types
  enter it.
- **The diagnostic.** The rendered cycle message names `UnitDelay` and the
  tier consequence, and no other message text changed.
- **The register.** `implementation.md`'s new row names constructs and
  cites sections; behaviour is in docstrings. The routing row exists.
- "Naming" over every touched file.
- The docs battery, and the gate once on the real tree.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new fixture name across
`test/` before defining it. Fixtures live at top level. Report: the commit
hash, the files touched, the `Dual` sweep's counts, the gate's result with
the assertion count, and every deviation from this brief with its reason.
