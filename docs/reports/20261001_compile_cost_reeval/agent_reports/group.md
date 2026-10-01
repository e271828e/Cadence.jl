# group track: what a typed `Group` still costs, and two variants

Julia 1.13.0, `-O2`, chunk size 16, single runs on a shared machine (load 4.5 to 5.5).
Probes in `$STUDY/group_probes/`; exports `$STUDY/{groupabs,grouperased}` (on nospec)
and `$STUDY/{groupabs,grouperased}_alone` (on base).

## Patches

| file | against | content |
|---|---|---|
| `patches/grouperased.patch` | base | nospec + `Group` with no type parameters |
| `patches/grouperased_over_nospec.patch` | nospec | the `Group` change alone (45 lines) |
| `patches/grouperased_alone.patch` | base | the `Group` change without nospec |
| `patches/groupabs.patch`, `_over_nospec`, `_alone` | same | `Group{W,I,O,R}` with `children::NamedTuple` |
| `patches/group_kidsmemo_over_grouperased.patch` | grouperased | experiment, not a `Group` change: walk-scoped memo of child lists |

- **groupabs**: `struct Group{W, I, O, R <: NamedTuple}`, `children::NamedTuple`; inner
  constructor `@nospecialize(children)`, kw constructor `@nospecialize(children)`.
  W, I, O, R stay parameters, so the root's type still changes with the fanned
  input's length (`Tuple{Pair{String,NTuple{N,String}}}`), and that tuple is stored inline.
- **grouperased**: `struct Group`, fields `children::NamedTuple`, `wires`, `inputs`,
  `outputs` untyped, `rates::NamedTuple`; both constructors `@nospecialize` throughout.
  The declarations return the stored values unchanged, so every reader sees what it saw.

## 1. Harness, `construct / build` seconds

| scenario | mode | base | groupabs_alone | grouperased_alone | nospec | groupabs | grouperased |
|---|---|---|---|---|---|---|---|
| small | cold | 0.337 / 6.982 | 0.318 / 6.354 | 0.202 / 5.430 | 0.320 / 5.036 | 0.419 / 5.452 | 0.212 / 5.007 |
| small | types | 0.284 / 2.942 | 0.261 / 1.468 | 0.154 / 1.179 | 0.337 / 0.082 | 0.267 / 0.075 | 0.173 / 0.083 |
| small | iter | 0.170 / 0.761 | 0.155 / 0.028 | 0.130 / 0.015 | 0.315 / 0.004 | 0.175 / 0.003 | 0.115 / 0.003 |
| repeated | cold | 0.446 / 16.596 | 0.248 / 5.989 | 0.210 / 4.622 | 0.491 / 4.779 | 0.266 / 4.879 | 0.211 / 4.559 |
| repeated | types | 0.419 / 12.588 | 0.200 / 2.006 | 0.161 / 0.635 | 0.461 / 0.128 | 0.218 / 0.105 | 0.167 / 0.101 |
| repeated | iter | 0.328 / 11.358 | 0.129 / 1.473 | 0.124 / 0.123 | 0.342 / 0.090 | 0.140 / 0.075 | 0.131 / 0.078 |
| distinct | cold | 0.702 / 40.844 | 0.424 / 20.932 | 0.391 / 20.395 | 0.751 / 5.545 | 0.460 / 5.365 | 0.430 / 5.382 |
| distinct | types | 0.663 / 37.364 | 0.364 / 16.916 | 0.340 / 16.163 | 0.683 / 0.745 | 0.399 / 0.755 | 0.345 / 0.706 |
| distinct | iter | 0.242 / 10.481 | 0.124 / 0.318 | 0.128 / 0.031 | 0.262 / 0.016 | 0.122 / 0.018 | 0.142 / 0.020 |

`sim / walks / init / run` are unchanged by either variant in every row (within ±0.5 s
noise; full lines in `group_probes/harness.txt`). Every `xhash` equals the reference
(small `29ecd83a8ddc20c2`, repeated `2ec2c14b24189565`, distinct `361f7aeacfda9226`);
`alloc = alloc_at = 0` everywhere; `alloc_boundary = 595072` on repeated in all six
exports, 0 elsewhere; `warm_ms_per_s` within noise (small 1.14–1.18, repeated 83–98,
distinct 9.4–10.2).

About 0.12 s of every `construct=` is the fixture's own `model(::Symbol)` compiling
on first call (traced, `trace_hconstruct.jl`); it is not the `Group`.

## 2. Scaling probes (`scale.jl`): new root of known types, seconds

Warm-up: a 2-loop flat root and a 2×2 nested root through build, Simulation, walks,
`init!`, `run!`. Columns: `construct`; `build`; a second `build` (ms); `resolve_condition`
on the harness condition (the root-dependent part of `init!`); `precompile` of the
`Simulation(root; h, chunk_size)` sugar; `r -> (r, 1)` first call; `repr(root)`.

| export | root | construct | build | warm build ms | cond | sugar | `(r,1)` | show | type chars | show chars |
|---|---|---|---|---|---|---|---|---|---|---|
| base | flat 64 | 0.235 | 12.779 | 45.4 | 0.043 | 0.270 | 0.354 | 1.199 | 13459 | 52140 |
| base | flat 256 | 0.173 | 2.225 | 204.6 | 0.014 | 0.060 | 0.066 | 1.287 | 53745 | 208708 |
| base | nested 16x16 | 0.750 | 4.095 | 113.8 | 0.015 | 0.069 | 0.003 | 0.960 | 55027 | 265292 |
| groupabs_alone | flat 64 | 0.019 | 1.566 | 32.7 | 0.013 | 0.055 | 0.007 | 1.068 | 79 | 36328 |
| groupabs_alone | flat 256 | 0.097 | 6.824 | 276.2 | 0.015 | 0.058 | 0.038 | 3.848 | 80 | 145315 |
| groupabs_alone | nested 16x16 | 0.034 | 0.628 | 106.0 | 0.014 | 0.062 | 0.003 | 0.567 | 79 | 147048 |
| grouperased_alone | flat 64 | 0.010 | 0.135 | 27.4 | 0.003 | 0.058 | 0.002 | 0.292 | 5 | 26078 |
| grouperased_alone | flat 256 | 0.041 | 0.449 | 178.7 | 0.003 | 0.060 | 0.002 | 0.746 | 5 | 104536 |
| grouperased_alone | nested 16x16 | 0.003 | 0.196 | 106.3 | 0.003 | 0.066 | 0.002 | 0.241 | 5 | 105086 |
| nospec | flat 64 | 0.232 | 0.082 | 31.0 | 0.040 | 0.218 | 0.258 | 1.056 | 13459 | 52140 |
| nospec | flat 256 | 0.082 | 0.352 | 298.1 | 0.014 | 0.020 | 0.040 | 1.208 | 53745 | 208708 |
| nospec | flat 1024 | 0.432 | 10.550 | 10353.9 | 0.015 | 0.021 | 0.199 | 6.355 | 215051 | 835472 |
| nospec | nested 16x16 | 0.751 | 0.189 | 113.5 | 0.015 | 0.022 | 0.003 | 1.056 | 55027 | 265292 |
| groupabs | flat 64 | 0.019 | 0.075 | 32.3 | 0.014 | 0.020 | 0.009 | 1.077 | 79 | 36328 |
| groupabs | flat 256 | 0.103 | 0.328 | 291.5 | 0.015 | 0.021 | 0.040 | 3.867 | 80 | 145315 |
| groupabs | flat 1024 | 0.530 | 10.430 | 10271.4 | 0.015 | 0.019 | 0.205 | 6.119 | 81 | 581590 |
| groupabs | nested 16x16 | 0.034 | 0.160 | 116.1 | 0.014 | 0.025 | 0.003 | 0.573 | 79 | 147048 |
| grouperased | flat 64 | 0.013 | 0.078 | 30.9 | 0.003 | 0.020 | 0.002 | 0.308 | 5 | 26078 |
| grouperased | flat 256 | 0.041 | 0.324 | 278.7 | 0.003 | 0.019 | 0.002 | 0.788 | 5 | 104536 |
| grouperased | flat 1024 | 0.218 | 10.548 | 10118.3 | 0.004 | 0.020 | 0.002 | 4.695 | 5 | 418698 |
| grouperased | nested 16x16 | 0.003 | 0.165 | 114.8 | 0.003 | 0.021 | 0.003 | 0.241 | 5 | 105086 |
| kidsmemo (experiment) | flat 256 | 0.041 | 0.164 | 113.7 | 0.003 | 0.019 | 0.002 | 0.719 | 5 | — |
| kidsmemo (experiment) | flat 1024 | 0.201 | 0.693 | 642.8 | 0.004 | 0.019 | 0.002 | 4.811 | 5 | — |
| kidsmemo (experiment) | nested 16x16 | 0.003 | 0.153 | 106.0 | 0.003 | 0.019 | 0.002 | 0.232 | 5 | — |

Base at 1024 was not run. The 0.02 s `sugar` floor is the kwcall's first compile for a
new argument type; under grouperased a second root pays nothing.

## 3. Mechanisms

**The typed root is a large inline value.** `Group` is immutable and so are its
children, so the whole tree is stored inline (`mech.jl`):

| loops | `sizeof` typed root | inline | LLVM lines of `r -> r` | groupabs `sizeof` | grouperased `sizeof` |
|---|---|---|---|---|---|
| 16 | 5 640 | yes | 360 | 144 | 40 |
| 32 | 11 272 | yes | 712 | 272 | 40 |
| 64 | 22 536 | yes | 2 488 | 528 | 40 |
| 128 | 45 064 | no (root boxed) | 5 | 1 040 | 40 |
| 256, 1024 | 2 064, 8 208 | yes; children NamedTuple boxed | 6 | 2 064, 8 208 | 40 |

Any code that moves the root by value compiles a copy of that layout: returning it,
boxing it for a `@nospecialize` callee, storing it in a tuple or array. Traced:
the `Group` kw constructor for the 64-loop children, 0.218 s (`tc_nospec_flat64.trace`);
`collect_to_with_first!` storing the 16 inline 16-loop groups of the nested root,
0.687 s (`tc_nospec_nested16.trace`); `r -> r` 0.261 s and `r -> nothing` 0.010 s on
the same root (`triv.jl`). The cost peaks at 64 loops, which is the harness's size, and
falls where Julia stops inlining (128+). On base the same mechanism makes `Base.count`
over the 64 inline loop groups cost 0.58 s in groupabs_alone and 0.007 s in
grouperased_alone, whose elements are 40-byte `Group`s (`tr_*_rep_iter.trace`).

**Type identity.** On base, `build` specializes on the root: 0.50 s for
`Group{Tuple{}, Tuple{Pair{String,NTuple{64,String}}}, Tuple{}, @NamedTuple{}}` under
groupabs_alone, recompiled for every new fan length; under grouperased_alone `build(::Group)`
compiles once per process, which is why it alone takes repeated iter from 11.4 s to 0.12 s
and distinct types from 37.4 s to 16.2 s. On nospec nothing in `build` specializes on the
root any more; what still does is `_flat(::Fragment, …, level, …)` in `conditions.jl`
(0.040 s → 0.003 s), the `Simulation(root; kw…)` sugar (0.218 s → 0.020 s), and any user
function taking the root.

**What remains under grouperased at 1024**: `Pair(::String, ::NTuple{1024,String})`, 0.198 s
(`tc_grouperased_flat1024.trace`), the fixture's fanned tuple, which a named assembly
pays identically.

## 4. Superlinear `build` runtime, not the `Group`'s type

Warm `build`: 31 ms at 64, 280–298 ms at 256, 10.1–10.4 s at 1024, in all three
nospec-based exports alike. Profile at 1024 (`prof.jl`): 99% under `_fanout`; each of the
root's N fan endpoints calls `resolve_terminal → _one_level → children(base, root)`,
re-deriving the root's N children; inside, `_element_keys` (nospec's helper, one dynamic
`fieldname` call per key) takes 82% and `_check_child_names` (O(N²) per call) 16%.
The experiment patch memoizes child lists per instance for the walk's duration, as
`WALK_FACES` does for faces: 1024 goes to 0.64 s warm, 256 to 0.11 s. Routed subset plus
conditions and readers: 2072/2072. Not gated, and outside this track's brief.

## 5. What else carries or prints the root's type (`periph.jl`, 64 loops)

- `Build`, `Deployment`, `Structure.root` (`::AbstractComponent`) and `Simulation`
  (16 579-char type) never mention `Group`, in every export.
- Build error at the root (unknown port): 1 433 chars, no `Group{`. User error in a
  component declaration under the root: 4 181 chars, no `Group{`. Both unchanged.
- `MethodError` from a misspelled `Group` keyword: 41 562 chars with 192 `Group{` on
  nospec; 2 948 chars, none, on grouperased.
- No `Base.show` method for `Group`: the default prints the full value with each
  element's type, 52 140 chars at 64 loops typed, 26 078 erased; compiling that display
  costs 1.06 s typed, 0.31 s erased at 64, and 4.7–6.4 s at 1024 in every export.

## 6. Tests and spec

No test pins `Group`'s type parameters; no `src/` code dispatches on `Group{…}` or reads
the children's type. `_declared_holding(Group, :children)` is the `TypeVar` `C<:NamedTuple`
typed and `NamedTuple` erased; both are "not held concretely", so the service walk's
`:past_generic` refusal past a `Group` child is unchanged (checked; only the
diagnostic's `declared` field reads `NamedTuple` instead of `C<:NamedTuple`). Gate on
grouperased: 4278/4278, the same total as nospec's gate, no test edited.

Spec owed: §8.5's code block (`struct Group{C <: NamedTuple, W, I, O}`, already missing
`rates`) and its sentence "The type parameters still carry the children's concrete types,
so activation is unchanged. So is the executor", which becomes "the type carries no
topology; activation and the executor are built from the primitives and never saw it";
D-184's Position (`Group{C <: NamedTuple, W, I, O}`) and the "Stratum C specialization"
phrase in its Rationale. §13.7 ("topology is data rather than a named type") fits better
than before. No Rule sentence is contradicted.

## 7. Warm `build` runtime (`nospec_work/warm.jl`, 20 builds, min / median ms, MB)

| export | small | repeated | distinct |
|---|---|---|---|
| base | 1.80 / 1.81, 1.39 | 35.7 / 37.3, 135.1 | 14.9 / 18.6, 17.0 |
| groupabs_alone | 1.80 / 1.81, 1.22 | 32.1 / 33.0, 52.1 | 13.7 / 14.5, 9.7 |
| grouperased_alone | 1.90 / 1.93, 1.17 | 26.7 / 27.4, 18.8 | 14.7 / 15.2, 8.8 |
| nospec | 1.99 / 2.01, 1.27 | 29.2 / 30.9, 24.8 | 14.0 / 14.6, 10.6 |
| groupabs | 1.99 / 2.02, 1.23 | 29.9 / 30.5, 19.8 | 14.3 / 14.5, 9.3 |
| grouperased | 2.00 / 2.02, 1.22 | 30.1 / 30.5, 18.9 | 14.0 / 14.2, 9.0 |
