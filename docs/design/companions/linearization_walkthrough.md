# Linearization from scratch: the math, the dual numbers, and the pass through Redstone

*A companion explainer, not normative text. The ground truth is `spec.md`
[§14.10][s14-10] (the tap set, the seeded pass, the frozen tier) and [§14.4][s14-4] (the
read-selector family), with decisions [D-271][d-271] (the index on `get_input` and
`get_face`) and [D-272][d-272] (the calling convention). If this document and the
spec ever disagree, the spec wins. It was written on 2026-09-28 as the
study note for increment 54, which built `src/linearize.jl`, and kept
because the question it answers, how one evaluation yields four exact
Jacobians, recurs.*

It builds the whole chain in order: what a linearization is, how
forward-mode automatic differentiation computes one exactly, what the
framework already had for it, and what `linearize` adds. One model runs
through every section.

Read beside: `src/linearize.jl`; `trim!` in `src/trim.jl` for the seeded
half it shares; the selectors and `_resolve_selector` in `src/readers.jl`;
`_root_input_cell` in `src/build.jl`; `Authored` in `src/conditions.jl`;
`Sum` and `Pendulum` in `test/fixtures.jl`.

## 1. The system

Two fixtures from `test/fixtures.jl`, wired into one assembly:

```julia
root = Group((; s = Sum(), c = Pendulum());
             local_wires  = ("s/e" => "c/u",),
             input_wires  = ("τ" => "s/a", "d" => "s/b"),
             output_wires = ("c/θ" => "θ", "s/e" => "u_eff"))
```

`Sum` is stateless with two inputs and one feedthrough output,
$e = s_a\,a + s_b\,b$, and the fixture's defaults are $s_a = 1$, $s_b = -1$.
`Pendulum` has two continuous states and one input:

```julia
x_init(::Pendulum) = (θ = 0.0, ω = 0.0)
u_types(::Pendulum) = (u = Float64,)
y_types(::Pendulum) = (θ = Float64, ω = Float64)
y_state(::Pendulum, (; x)) = (θ = x.θ, ω = x.ω)
x_deriv(c::Pendulum, (; x, u)) = (θ = x.ω, ω = -c.g_l * sin(x.θ) - c.c * x.ω + u.u)
```

with $g/l = 9.81$ and $c = 0.5$. Two root inputs, $\tau$ (torque) and $d$
(disturbance), enter the sum, and the sum drives the pendulum's torque. Two
faces leave the root: `θ`, aliasing the pendulum's own output cell, and
`u_eff`, aliasing the sum's. As one system:

$$
\begin{aligned}
\dot\theta &= \omega \\
\dot\omega &= -\tfrac{g}{l}\sin\theta - c\,\omega + (\tau - d) \\
y_\theta &= \theta \\
y_{u_\text{eff}} &= \tau - d
\end{aligned}
$$

So $n_x = 2$, $n_u = 2$, $n_y = 2$: small, but every matrix is a real matrix
and one of them ($D$) is nonzero, which exercises the feedthrough path.

## 2. What a linearization is

Write the continuous dynamics and the outputs as two functions:

$$\dot x = f(x, u), \qquad y = h(x, u).$$

Pick an operating point $(x_0, u_0)$. A first-order Taylor expansion around it
gives, for small deviations $\delta x = x - x_0$ and $\delta u = u - u_0$,

$$
\dot x \approx f(x_0, u_0) + A\,\delta x + B\,\delta u, \qquad
y \approx h(x_0, u_0) + C\,\delta x + D\,\delta u,
$$

where the four matrices are Jacobians, matrices of partial derivatives
evaluated at the point:

$$
A = \frac{\partial f}{\partial x}\Big|_{0} \in \mathbb{R}^{n_x \times n_x},\quad
B = \frac{\partial f}{\partial u}\Big|_{0} \in \mathbb{R}^{n_x \times n_u},\quad
C = \frac{\partial h}{\partial x}\Big|_{0} \in \mathbb{R}^{n_y \times n_x},\quad
D = \frac{\partial h}{\partial u}\Big|_{0} \in \mathbb{R}^{n_y \times n_u}.
$$

Entry $(i, j)$ of $A$ is "how much does $\dot x_i$ change per unit change of
$x_j$, holding everything else fixed". The constant terms $\dot x_0 = f(x_0,
u_0)$ and $y_0 = h(x_0, u_0)$ come out of the same evaluation. At a trim
point $\dot x_0 = 0$ by definition, but `linearize` does not assume one.

For our system, differentiating by hand at $(\theta_0, \omega_0, \tau_0,
d_0)$:

$$
A = \begin{pmatrix} 0 & 1 \\ -\tfrac{g}{l}\cos\theta_0 & -c \end{pmatrix},\quad
B = \begin{pmatrix} 0 & 0 \\ 1 & -1 \end{pmatrix},\quad
C = \begin{pmatrix} 1 & 0 \\ 0 & 0 \end{pmatrix},\quad
D = \begin{pmatrix} 0 & 0 \\ 1 & -1 \end{pmatrix}.
$$

Take the trim point $\theta_0 = 0.3$, $\omega_0 = 0$, $d_0 = 0$, and
$\tau_0 = 9.81 \sin 0.3 \approx 2.899$ so that $\dot\omega_0 = 0$. Then

$$
A = \begin{pmatrix} 0 & 1 \\ -9.372 & -0.5 \end{pmatrix}.
$$

These numbers are the answer the whole machinery below must reproduce. Keep
them in view.

**The old way.** Flight.jl's `linearize` computed each Jacobian with
`FiniteDiff`: perturb one variable by a small $h$, re-evaluate the model, take
$(f(x + h e_j) - f(x)) / h$ as column $j$. That is about $n_x + n_u$
evaluations per matrix pair, a step-size heuristic, truncation error of order
$h$ and round-off of order $\epsilon / h$, and a model left dirty by the
perturbations. Automatic differentiation removes all four.

## 3. Forward-mode automatic differentiation

### 3.1 Dual numbers

A dual number is a pair $a + b\,\varepsilon$ with the rule $\varepsilon^2 =
0$. Arithmetic follows from that rule alone:

$$
\begin{aligned}
(a + b\varepsilon) + (c + d\varepsilon) &= (a + c) + (b + d)\varepsilon \\
(a + b\varepsilon)(c + d\varepsilon) &= ac + (ad + bc)\varepsilon
  \qquad (\text{the } bd\,\varepsilon^2 \text{ term vanishes})
\end{aligned}
$$

Now read $a$ as a value and $b$ as a derivative. The product rule above is
exactly $(fg)' = f'g + fg'$. Every elementary function gets one rule by the
same Taylor argument, truncated after the first order because $\varepsilon^2
= 0$:

$$
\sin(a + b\varepsilon) = \sin a + b\cos a\,\varepsilon, \qquad
\exp(a + b\varepsilon) = e^a + b\,e^a\,\varepsilon, \qquad \ldots
$$

Feed a function $F$ the dual $x_0 + 1\cdot\varepsilon$ and compute with these
rules. The result is $F(x_0) + F'(x_0)\,\varepsilon$: the value in the first
slot and the exact derivative in the second, to machine precision, with no
step size anywhere. The chain rule is not applied by anyone; it falls out of
the rules composing, one operation at a time, in whatever order the code
happens to execute them. That is why this works on ordinary imperative code,
loops, branches and `if`s included: every branch taken computes its own
derivative rule as it goes.

Work our $\dot\omega$ expression by hand with $\theta = 0.3 + 1\varepsilon$,
everything else a plain number ($\omega = 0$, $u = 2.899$):

$$
\begin{aligned}
\sin\theta &= \sin 0.3 + \cos 0.3\,\varepsilon = 0.2955 + 0.9553\,\varepsilon \\
-9.81 \sin\theta &= -2.899 - 9.372\,\varepsilon \\
-0.5\,\omega &= 0 \\
+\,u &= 2.899 \\
\dot\omega &= 0.000 - 9.372\,\varepsilon
\end{aligned}
$$

Value $0$ (the trim residual) and derivative $-9.372$, which is $A_{2,1}$.
One evaluation gave one column entry exactly.

### 3.2 Several directions at once

A dual with one $\varepsilon$ gives one directional derivative per
evaluation. To get a whole Jacobian, widen the derivative slot from a scalar
to a vector of length $N$:

$$
a + \mathbf{b}\,\varepsilon, \qquad \mathbf{b} \in \mathbb{R}^N,
$$

with the same rules applied componentwise to $\mathbf b$. Seed the $k$-th
variable with the unit vector $\mathbf e_k$ in its derivative slot. Then after
the evaluation, the derivative slot of any output holds its gradient with
respect to all $N$ seeded variables. Row $i$ of the Jacobian is output $i$'s
partials vector. The whole matrix comes from one pass.

This is what ForwardDiff.jl implements. Its type is

```julia
ForwardDiff.Dual{Tag, V, N}      # value type V, N partials, a Tag to keep nested uses apart
```

with the accessors `ForwardDiff.value(x)` and `ForwardDiff.partials(x, k)`.
Constructing a seed, with a tag of our own (the framework's is
`LinearizeTag`):

```julia
julia> using ForwardDiff
julia> struct LinTag end
julia> θ = ForwardDiff.Dual{LinTag}(0.3, 1.0, 0.0, 0.0, 0.0)   # value 0.3, partials e₁ of width 4
Dual{LinTag}(0.3,1.0,0.0,0.0,0.0)
julia> ω = ForwardDiff.Dual{LinTag}(0.0, 0.0, 1.0, 0.0, 0.0)
julia> τ = ForwardDiff.Dual{LinTag}(9.81 * sin(0.3), 0.0, 0.0, 1.0, 0.0)   # the trim torque, 2.899
julia> d = ForwardDiff.Dual{LinTag}(0.0, 0.0, 0.0, 0.0, 1.0)
julia> ω̇ = -9.81 * sin(θ) - 0.5 * ω + (τ - d)
Dual{LinTag}(0.0,-9.372,-0.5,1.0,-1.0)
```

The value is $\dot\omega_0 = 0$, and the four partials are, in seed order,
$\partial\dot\omega/\partial\theta$, $\partial\dot\omega/\partial\omega$,
$\partial\dot\omega/\partial\tau$, $\partial\dot\omega/\partial d$. That is the
second row of $[A \;|\; B]$, read off one expression. `linearize` is this,
applied to the model's whole evaluation instead of one line.

Two things to hold on to:

- **The width $N$ is part of the type.** `Dual{LinTag,Float64,4}` and
  `Dual{LinTag,Float64,5}` are different types, and code specialized on one
  is compiled again for the other. This is where the `width` keyword comes
  from, section 7 below.
- **Anything not seeded is a constant.** A plain `Float64` mixed into dual
  arithmetic behaves as a dual with an all-zero partials vector. Its
  derivative is zero, which is exactly right for a value held fixed at the
  operating point. Julia's `convert(Dual{...}, 0.5)` produces that zero-partial
  dual, and the framework leans on this in one specific place (section 4.3).

## 4. What the framework already had

The framework was designed so that a model evaluates at any scalar type, and
`Dual` is the scalar type this whole section cares about. Four pieces of
existing machinery do the work.

### 4.1 Activations: the build typed at a scalar

An *activation* ([§9.4][s9-4]) is the build's typed products at one concrete scalar
type `T`: every declaration retyped with `Float64` replaced by `T`, the probe
run at `T`, the cell layout at `T`. `activation(build, T)` returns a cached
one per `T`. The nominal activation is `T = Float64`; a seeded one is `T =
ForwardDiff.Dual{SomeTag,Float64,N}`.

The retyping is a type walk (`retype` in `src/leaves.jl`):

```julia
retype(::Type{T}, ::Type{Float64}) where {T} = T
retype(::Type{T}, ::Type{P}) where {T,P} = ...   # rebuild P with every Float64 parameter retyped
```

So `SVector{2,Float64}` becomes `SVector{2,Dual{...}}`, and a `Pinned{Float64}`
entry becomes `Float64` at every activation: its top marker is stripped and
nothing inside follows `T` (`retype_entry`). That marker is the whole story
behind one of the tap refusals (section 6.3).

An executor compiled at an activation (`compile(build, act, schedule)`) owns
buffers at that scalar: `xbuf::Vector{T}` for the flat continuous state,
`ẋbuf::Vector{T}` for its derivative, and a signal-table `store` with one
homogeneous buffer per leaf element type. At a `Dual` activation, `xbuf` is a
`Vector{Dual{...}}` and the cells whose types follow `T` live in a
`Dual`-typed buffer. The component code never knows: `x_deriv(::Pendulum,
(; x, u))` runs on whatever scalars the bundle carries.

### 4.2 The flat state and the layout

Each continuous component's `x_init` fields are flattened in declaration
order into `xbuf`, and `layout.xblocks[ci]` is that component's range. For
our model the component indices follow the structure's order: `s` is 1 and
`c` is 2. `Sum` owns no state, so its block is empty, and `Pendulum` gets
`1:2`: `xbuf[1]` is $\theta$, `xbuf[2]` is $\omega$. `ẋbuf` has the same
shape, so $\dot\theta$ is `ẋbuf[1]` and $\dot\omega$ is `ẋbuf[2]`.

The signal table's addresses are `layout.addr`, keyed `(path, name)`:

| key | what it is |
|---|---|
| `("", :τ)`, `("", :d)` | the two root-input cells |
| `("s", :e)` | the sum's output cell |
| `("c", :θ)`, `("c", :ω)` | the pendulum's output cells |
| `("", :θ)`, `("", :u_eff)` | the two faces, entered as aliases onto `("c", :θ)` and `("s", :e)` |

A root input's cell type at an activation is decided by [D-168][d-168]'s meet
(`_root_input_cell` in `src/build.jl`): it follows `T` when every consumer's
entry admits a walked value, and stays the declared `Float64` otherwise. Both
consumers of `τ` and `d` are `Sum`'s plain `Float64` entries, so both cells
are `Dual` at a seeded activation. Had one consumer declared
`Pinned{Float64}`, or been a discrete component, whose entries pin wholesale
([§8.2][s8-2]), the cell would be `Float64` at every activation, and a seed could not
be written there. This is the input-side no-silent-zeros rule ([D-167][d-167]) as a
*type*, not a check.

### 4.3 Conditions at a seeded activation: the zero-partial embedding

A condition ([§14.1][s14-1]) is the path-addressed overlay that sets a build's state:
`at("c", fragment(x = (θ = 0.3, ω = 0.0)))` combined with `fragment(u =
(τ = 2.899, d = 0.0))`. Resolving it against a build yields a plan of baked
destinations, each with the destination leaf's type at that activation as its
converter (`Authored{P,L}` in `src/conditions.jl`):

```julia
@inline (::Authored{P,L})(tree) where {P,L} = convert(L, walk_steps(tree, Val(P)))
```

At `T = Float64` the convert is the identity. At a `Dual` activation, `L` is
`Dual{...}` and `convert` embeds the authored `Float64` as a zero-partial dual
(section 3.2's second point). Its docstring states the limit precisely: this
is exact for a value *held fixed* at the operating point, and for nothing
else. For linearization every authored value is held fixed, so applying the
operating-point condition at the seeded activation is exactly right, and the
seeds are written afterwards, on top.

### 4.4 The frozen discrete tier

At any non-nominal activation a discrete component's stages are outside the
executable set (`_frozen` in `src/build.jl`): its output cells are pinned
`Float64` constants, zero partials, holding whatever the nominal world last
published. That is "linearize the continuous dynamics with the discrete state
held" ([§8.2][s8-2]), and [D-213][d-213]'s copy in trim (`_establish_frozen!`) is what fills
those cells from the nominal half before the seeded pass reads them. Trim and
`linearize`'s `about` form establish them there with one round. In
`linearize`'s default form they are the checkpoint's held cells
([D-274][d-274]). Our model has no discrete component, so the copy is a no-op here, but
`linearize` runs it for the same reason trim does.

### 4.5 Trim's seeded half is already a Jacobian pass

Everything above is exercised by `trim!`. Read its seeded half as a
linearization of the residual map $r(d)$ with respect to the decisions $d$:

```julia
T = ForwardDiff.Dual{TrimTag,Float64,N}             # N = number of decisions
act = activation(build, T)
seeded_exec = _scratch(sim, T, act)                  # buffers at T, die with the call
_establish_frozen!(seeded_exec, act, nominal_exec, build)
d_dual = _seeded(decision_names, guess, T)           # decision k carries unit partial k
seeded_plan = compile_plan(override(baseline, problem.condition(d_dual)), build, T)
seeded_reader = _compile_reads(problem.reads, build, T)

function eval!(r, J, d)
    decisions = _seeded(decision_names, d, T)
    apply!(seeded_exec, seeded_plan, override(baseline, problem.condition(decisions)))
    evaluate!(seeded_exec)                           # sweep_1, sweep_2, rhs
    raw = problem.residuals(gather_reads(seeded_reader, seeded_exec), decisions)
    for i in eachindex(r)
        r[i] = ForwardDiff.value(residuals[i])
        for j in 1:N
            J[i, j] = ForwardDiff.partials(residuals[i], j)
        end
    end
end
```

The seeds enter *through the condition*: `_seeded` builds decision duals with
unit partials, the problem's `condition(d)` places them in the tree, and the
plan's converters pass them through untouched because they are already at
`T`. Value parts give $r$, partials give $J = \partial r/\partial d$.

`linearize` needs the same pass with two differences. The seeds go on state
leaves and root inputs directly, not on a user's decision vector. And the
reads are fixed by the tap lists rather than by a residual function. Nothing
else is new.

## 5. The tap declaration and its resolution

### 5.1 The declaration

The three lists name what to seed and what to read, with the labels the
result will carry:

```julia
tp = taps(x = (θ = get_state("c", :θ), ω = get_state("c", :ω)),
          u = (τ = get_input(:τ), d = get_input(:d)),
          y = (θ = get_face(:θ), u_eff = get_face(:u_eff)))
```

The selectors are [§14.4][s14-4]'s closed family. `get_state(path, field[, i])` names
a state leaf, with an optional component index for a vector leaf.
`get_input(face[, i])` names a root input and `get_face(name[, i])` a
root-exported output face, both with the same index since [D-271][d-271].
`get_output(path, name[, i])` names a component's own output port. `taps`
returns a `Taps` value holding three `Reads`, so a bare NamedTuple handed to
`linearize` gets the same directive refusal `reads` gives (`ReadSetMisuse`).

Membership is closed per list, because each list has one job:

| list | admits | job in the pass |
|---|---|---|
| `x` | `get_state` | a state leaf to seed, and the row of $\dot x$ to read |
| `u` | `get_input` | a root-input cell to seed |
| `y` | `get_output`, `get_face` | a cell to read after the sweep |

The labels are the axes: `x` labels index the rows and columns of $A$, `u`
labels the columns of $B$ and $D$, `y` labels the rows of $C$ and $D$.

### 5.2 What resolution yields

`_resolve_selector` turns each selector into a compiled read entry against
an activation. For our taps:

| tap | resolves to | meaning |
|---|---|---|
| `x.θ` | `StateRead{Dual,Nothing}(offset = 0)` | `xbuf[1]`, and `ẋbuf[1]` for its derivative |
| `x.ω` | `StateRead{Dual,Nothing}(offset = 1)` | `xbuf[2]`, `ẋbuf[2]` |
| `u.τ` | `CellRead(addr = layout.addr[("", :τ)])` | the root-input cell |
| `u.d` | `CellRead(addr = layout.addr[("", :d)])` | likewise |
| `y.θ` | `CellRead(addr = layout.addr[("", :θ)])` | the alias onto `("c", :θ)` |
| `y.u_eff` | `CellRead(addr = layout.addr[("", :u_eff)])` | the alias onto `("s", :e)` |

Here is the observation the design rests on: **a resolved read entry is
also a write site.** A `StateRead` bakes the `xbuf` offset, which is where the
seed for that state goes, and a `CellRead` bakes the cell address, which
`scatter_cell!` takes as well as `gather_cell`. So tap resolution gives the
seeding sites and the readback sites in one step, with no new addressing
code ([D-272][d-272]).

Directions are numbered in list order, `x` first then `u`:

| direction $k$ | seeded leaf | where the unit partial is written |
|---|---|---|
| 1 | `x.θ` | `xbuf[1] = Dual(θ₀, e₁)` |
| 2 | `x.ω` | `xbuf[2] = Dual(ω₀, e₂)` |
| 3 | `u.τ` | `scatter_cell!(store, addr_τ, Dual(τ₀, e₃))` |
| 4 | `u.d` | `scatter_cell!(store, addr_d, Dual(d₀, e₄))` |

so $N = n_x + n_u = 4$.

### 5.3 What resolution refuses

Every refusal is a `TapResolution`, collected in [§13.1][s13-1]'s form: the whole
list is checked, every violation gathered, one `DiagnosticError` thrown. The
name-shaped misses (an undeclared field, an unknown root input, an assembly
path where a component path was expected, an index on a scalar leaf) are the
reader's own. The tap set adds five:

- **A discrete store in the `x` list** ([D-197][d-197]). The pass freezes the discrete
  tier, so a discrete `x` tap could only produce a zero row and a zero column
  in $A$, manufacturing a zero eigenvalue the plant does not have. Refused
  with the tier in hand and the step-map extension as the next move.
- **An unseedable root input in the `u` list** ([D-167][d-167], [D-168][d-168]). If any
  consumer's entry is `Pinned{Float64}`, the meet types the cell `Float64`
  at every activation and no seed can be written. Refused naming the
  pinning consumer's path and its entry, since under fan-out the author
  needs to know *which* consumer froze the face, and the remedy is to
  promote that entry or route around it. A discrete consumer pins by tier
  rather than by declaration, so there the refusal names the tier and
  points at the continuous cell that consumer drives, or at the recorded
  step map ([D-272][d-272]). Admitting such a tap as a true zero column was
  considered and rejected: the column would read as "no effect" where the
  effect is temporal and held.
- **A vector leaf without an index.** A Jacobian column is one scalar
  direction. `get_state("plant", :q)` on an `SVector{2}` state is refused; the
  author writes `get_state("plant", "q[1]")` and `get_state("plant", "q[2]")`
  as two labeled taps, and likewise `get_input("wind[1]")` for a vector root
  input (the leaf address, [§14.4][s14-4], [D-276][d-276]).
- **A selector of the wrong kind in a list**, such as `get_deriv` in `x` or
  `get_state` in `y`.
- **Two taps resolving to one site**, in `x`, in `u`, or one in each: a
  second seed at a site would overwrite the first and the earlier label's
  column would read as zeros, the silent zero every other refusal here
  exists to prevent. The later tap is refused naming the earlier label.
  `y` taps may repeat freely, being reads.

## 6. The pass, step by step

With the taps resolved, `linearize(sim, tp)` does the following. Every step
names the existing function it reuses. The seeds are shown at width 4 for
legibility; the default width is 8 (section 7), and the same four directions
then occupy four of eight slots.

**Step 1: the operating point.** With no `about` keyword it is
`checkpoint(sim)`, the `Model`'s state at a frame top as one value beside the
run's two counters. The state holds the flat buffer, the stores, the whole
signal table, the guard priors and the clock ([§12.6][s12-6], [D-274][d-274]).
For our trimmed sim it holds `x = [0.3, 0.0]` and the root-input cells
`τ = 2.899` and `d = 0.0`. A checkpoint is not a condition, so nothing is
resolved from it. `checkpoint` is legal in `initialized` and `stopped`, and it
is refused mid-frame after a `t*` stop. The default form inherits both.
`about = <condition>` bypasses the checkpoint, takes `t0` beside it, and is
legal wherever `init!` is.

**Step 2: the nominal half.** A scratch executor at `Float64` (`_scratch`).
In the default form `_restore_state!` copies the checkpoint into it, and that
is all. No condition is applied and no establishment round runs, because the
checkpoint's table already holds every cell, the discrete ones included. In
the `about` form the condition is applied by the dynamic walk, root-input
totality is checked (`assert_total`, so an `about` that forgets a root input
fails before any evaluation), and one establishment round runs. In both
forms this half exists for the discrete cells [D-213][d-213]'s copy needs. It is
cheap, and it keeps one code path for every model.

**Step 3: the seeded half.** `T = Dual{LinearizeTag,Float64,width}`, `act =
activation(build, T)` (cached after the first call at this width), and a
scratch executor at `T`. The checkpoint cannot be restored into it: its table
has `Dual` buffers where the checkpoint's has `Float64` ones. The default
form writes it by hand instead. It copies `x` with a conversion, writes the
`s` and `m` stores by value, gathers each root-input cell from the nominal
half and converts it to its declared type at `T`, and sets the clock. The
`about` form applies the same condition at `T`. In both forms every value
written is a zero-partial constant (section 4.3), and `_establish_frozen!`
then copies the discrete cells across. At this moment every state leaf and every root input
holds its operating-point value with an all-zero partials vector.

**Step 4: the seeds.** The four writes of section 5.2's last table. After
them:

```
xbuf   = [ Dual(0.3,   1,0,0,0),  Dual(0.0, 0,1,0,0) ]
cell τ =   Dual(2.899, 0,0,1,0)
cell d =   Dual(0.0,   0,0,0,1)
```

Nothing else in the executor carries a nonzero partial.

**Step 5: one evaluation.** `evaluate!(exec)` runs the three phase bodies in
order:

1. `sweep_1`, the state-derived output stages. `Pendulum.y_state` publishes
   `("c", :θ)` = `Dual(0.3, 1,0,0,0)` and `("c", :ω)` = `Dual(0, 0,1,0,0)`.
   The partials ride along unchanged, since `y_state` copies.
2. `sweep_2`, the feedthrough stages in feedthrough order. `Sum.y_direct`
   reads its two input cells and publishes `("s", :e)` $= \tau - d$ =
   `Dual(2.899, 0,0,1,-1)`. That partials vector is already the second row
   of $D$.
3. `rhs`, the derivative stages. `Pendulum.x_deriv` reads `x` off `xbuf`
   and `u.u` off the wire, which is the cell `("s", :e)`, and writes
   `ẋbuf[1]` = `Dual(0, 0,1,0,0)` and `ẋbuf[2]` = `Dual(0, -9.372,-0.5,1,-1)`,
   the hand computation of section 3.2 done by the model's own code.

**Step 6: the readback.** The `x` entries read `ẋbuf` at their offsets, the
`y` entries gather their cells. Values and partials split into the eight
results:

$$
\dot x_0 = \begin{pmatrix} 0 \\ 0 \end{pmatrix},\;
x_0 = \begin{pmatrix} 0.3 \\ 0 \end{pmatrix},\;
u_0 = \begin{pmatrix} 2.899 \\ 0 \end{pmatrix},\;
y_0 = \begin{pmatrix} 0.3 \\ 2.899 \end{pmatrix}
$$

and, from the partials, columns 1–2 being the `x` directions and 3–4 the `u`
directions:

$$
\underbrace{\begin{pmatrix} 0 & 1 \\ -9.372 & -0.5 \end{pmatrix}}_{A}
\;\Big|\;
\underbrace{\begin{pmatrix} 0 & 0 \\ 1 & -1 \end{pmatrix}}_{B}
\qquad\text{from } \dot x \text{'s partials,}
$$

$$
\underbrace{\begin{pmatrix} 1 & 0 \\ 0 & 0 \end{pmatrix}}_{C}
\;\Big|\;
\underbrace{\begin{pmatrix} 0 & 0 \\ 1 & -1 \end{pmatrix}}_{D}
\qquad\text{from } y \text{'s partials.}
$$

These are section 2's matrices, entry for entry. In code, the split is the
same loop trim runs, with two column ranges:

```julia
for (i, entry) in enumerate(x_entries)              # rows of A and B
    ẋ = _read(entry, ẋbuf_at(exec))                 # the DerivRead twin of the StateRead
    ẋ₀[i] = ForwardDiff.value(ẋ)
    for j in 1:n_x;  A[i, j] = ForwardDiff.partials(ẋ, j);        end
    for j in 1:n_u;  B[i, j] = ForwardDiff.partials(ẋ, n_x + j);  end
end
for (i, entry) in enumerate(y_entries)              # rows of C and D
    y = _read(entry, exec)
    y₀[i] = ForwardDiff.value(y)
    for j in 1:n_x;  C[i, j] = ForwardDiff.partials(y, j);        end
    for j in 1:n_u;  D[i, j] = ForwardDiff.partials(y, n_x + j);  end
end
```

**Step 7: return, and nothing else.** Both scratch executors are locals and
die with the call. `sim.exec` was never touched, and the sim's lifecycle is
what it was. This is [§14.10][s14-10]'s "pure query": no commit, no boundary zero, no
restore step. The return is a `Linearization` value holding the four vectors
as NamedTuples under the tap labels, the four matrices, and the three label
tuples so a consumer can slice by name.

## 7. The width: why the passes are grouped

Section 3.2's first point: the width is in the type, and the model's whole
continuous chain is compiled once per activation, that is once per distinct
width. A model with 12 states and 4 inputs linearized at its full width
compiles at `Dual{_,_,16}`; a tap set with one input fewer compiles again at
width 15. Trim has the same property today, once per decision count.

`linearize` instead runs the pass in groups of `width` directions, `width` a
keyword defaulting to 8: the $N$ directions are split into $\lceil N /
\text{width} \rceil$ groups, and each group is one evaluation at the single
activation `Dual{LinearizeTag,Float64,width}`, filling that many columns of
each matrix per pass. The setup, the operating point's writes and the
frozen-cell copy happen once; only the seed writes and `evaluate!` repeat.

The arithmetic does not decide the width. A pass at width $C$ costs about
$(1 + C)$ nominal evaluations, so $N$ directions cost about $(N + N/C)$
whatever the grouping, at most a factor of two between $C = 1$ and $C = N$.
The compile cost does: a fixed width compiles once per model and can be paid
ahead of time through `build(m; activations = (Float64, LinearizeDual))`
([§9.4][s9-4]), where a full-width pass compiles once per distinct tap count and
never ahead of time. Predictable latency at the keyboard and behind a GUI is
what the fixed width buys ([D-272][d-272]).

## 8. Three edge cases worth seeing

**The frozen discrete tier, concretely.** Take a `DiscreteAccumulator` `ctl`
driving the pendulum's torque. At the seeded activation `ctl` never runs; its
output cell holds the `Float64` the nominal half carries, zero partials.
Seeding $\theta$ and $\omega$ therefore gives the open-loop $A$ of the
pendulum alone, with the controller's contribution held constant. That is
the intended answer ([§14.10][s14-10]'s frozen-exact doctrine), and the reason an `x`
tap on `ctl`'s store is refused rather than admitted with zeros: a zero row
there would look like a plant mode, not like a held controller.

**The root input only the controller reads.** In the same model the root
input `in` feeds `ctl` alone. Discrete entries pin wholesale, so `in`'s cell
is `Float64` at every `Dual` activation and a `u` tap on it is refused by
tier: the effect of `in` on the plant is real but temporal, one tick behind
through the controller, and the pass holds it. The message points at the
continuous cell `ctl` drives, which is the tap the author wanted, or at the
recorded step map.

**The pinned root input, concretely.** Replace `Sum` by `PinnedGain`, whose
input entry is `e = Pinned{Float64}`. Wire a root input `τ` to it. The meet
types `("", :τ)`'s cell `Float64` at every activation. A `u` tap on `τ` is
refused at resolution naming `g` and its entry. Without that refusal the seed
write would either throw a `convert` error deep in `scatter_cell!` or, worse,
be silently truncated to its value, giving a zero column in $B$ that the
author would read as "this input has no effect".

## 9. Checking the result

Two checks the tests make, independently of the mechanism:

- **Closed form.** For the pendulum model, `A ≈ [0 1; -9.81cos(0.3) -0.5]`,
  `B ≈ [0 0; 1 -1]`, `C ≈ [1 0; 0 0]`, `D ≈ [0 0; 1 -1]` to `1e-12`. Exactness
  is the claim, so the tolerance is round-off, not a finite-difference
  budget. Widths 1, 3 and 8 give bitwise-equal matrices.
- **Finite differences as a witness.** Perturb one root input by `1e-6`
  through `about`, linearize twice, and compare the difference quotient of
  $\dot x_0$ against the corresponding column of $B$. This is a test-side
  cross-check only; [§14.10][s14-10] and [D-266][d-266] keep every perturbation-based path out
  of the framework.

And two invariants the tests pin: the sim's `lifecycle`, `latest` snapshot
and `xbuf` are identical before and after the call, and a second `linearize`
at the same width compiles nothing new, the activation being cached on the
build.

## 10. The surface, mapped onto the sections above

| item | where it lives in this note |
|---|---|
| `taps(; x, u, y)` returning `Taps` of three `Reads` | section 5.1 |
| closed membership per list | section 5.1's table |
| one scalar per tap, the index on every member ([D-271][d-271]) | section 5.3 |
| duplicate sites refused | section 5.3 |
| seeding by direct write at the resolved read entry's site | section 5.2, section 6 step 4 |
| the two-half scratch world, nominal then seeded | section 6 steps 2–3, section 4.4 |
| the unseedable root input, by declaration and by tier | section 4.2, section 5.3, section 8 |
| `about` and `t0`, the checkpoint as the default | section 6 step 1 |
| `Linearization` return with labels | section 6 step 7 |
| groups of `width` directions per pass, default 8 ([D-272][d-272]) | section 7 |
| pure query, sim untouched | section 6 step 7, section 9 |

<!-- citation link definitions — generated by tools/linkify.jl; do not edit -->
[d-167]: ../decisions.md#d-167--mandate-typet-input-signatures-under-the-permissive-reading
[d-168]: ../decisions.md#d-168--root-slot-fan-out-tolerance-combines-by-meet-not-agreement
[d-197]: ../decisions.md#d-197--reject-discrete-stores-in-linearizations-x-tap-list
[d-213]: ../decisions.md#d-213--establish-a-services-frozen-cells-from-the-authored-discrete-state
[d-266]: ../decisions.md#d-266--two-doors-for-an-ad-opaque-implementation-the-local-rule-and-the-freeze-block
[d-271]: ../decisions.md#d-271--admit-the-component-index-on-get_input-and-get_face
[d-272]: ../decisions.md#d-272--fix-linearizes-surface-the-tap-set-the-chunk-width-the-operating-point-and-the-return
[d-274]: ../decisions.md#d-274--checkpoints-the-executors-state-as-one-value-restored-without-boundary-zero
[d-276]: ../decisions.md#d-276--address-a-leaf-inside-a-port-value-by-a-dotted-leaf-address
[s12-6]: ../spec.md#126-run-lifecycle-and-partial-advance
[s13-1]: ../spec.md#131-reporting-policy-collect-the-checks-fail-the-evaluations-fast
[s14-1]: ../spec.md#141-conditions-are-path-addressed-overlays-on-the-declared-defaults
[s14-10]: ../spec.md#1410-linearization-tap-selectors-one-seeded-pass-a-pure-query
[s14-4]: ../spec.md#144-one-plan-two-ways-to-apply-it
[s8-2]: ../spec.md#82-the-declaration-inventory
[s9-4]: ../spec.md#94-activations-executable-sets-laziness-caching
