### 8.6 Paths, wiring and faces

An [assembly](#g-assembly) (a component of pure composition, with no dynamics
of its own) wires its children and names its boundary with strings. A
[face](#g-face) is the name a port wears on its component's boundary. This
section fixes the path form, the three wiring declarations and the direction
invariant they share, face names, root inputs, and face uniqueness at the
root. A worked assembly, the strapdown IMU, closes the section.

**Paths are slash-separated strings**, relative to the assembly or model root
they are read from, with no leading slash ([D-040][d-040]). There is one
canonical form. Declarations, error messages,
[device](#g-device)/[trace](#g-trace) addressing ([§11.3][s11-3]) and the HDF5
log tree share it verbatim. [Container children](#g-container-children) (the
elements of a tuple field holding only components, [§8.5][s8-5]) add index and
key segments, `"aircraft/2"` and `"aircraft/red"` ([D-085][d-085]). These are
ordinary segments, resolved against the container field. A container declared
name-transparent ([§8.5][s8-5]) adds no segment of its own, and its elements
go by bare key ([D-211][d-211]). Instance navigation, tuples of symbols and
dotted paths were all rejected ([D-040][d-040]).

The three wiring declarations use only the short case of that form, one child
segment and one face name ([§6.1][s6-1], [D-207][d-207]). The read side
walks the full depth, as `"systems/ldg/left/trn"` does in a [snapshot](#g-snapshot) (the
immutable per-boundary publication) or the log tree. That read side is the
inspection side. It resolves a path with `resolve` under the instance walk
([§13.3][s13-3]). One fact behind the rejection of instance navigation is
relied on downstream. Symmetric immutable siblings are `===`-identical, so a
path is unrecoverable from an instance. That is why the helpers
([§8.8][s8-8]) name the child by path.

`inner_connections(::A)` is an ordered collection of `"src/face" => "dst/face"`
pairs. **Every pair runs strictly from a child face to a child face**
([D-170][d-170]). The wiring rules apply ([§6.1][s6-1]). There is one wire per
input, and every endpoint is an immediate child and one of its faces,
container key segments included.

**The assembly's boundary is declared by two further methods, one per
direction** ([D-170][d-170]). `u_connections(::A)` is an ordered collection of
pairs, face name => internal endpoint path. An input face routed to several
immediate children takes a tuple of paths instead, as in
`"trn" => ("left/trn_field", "right/trn_field", …)`. This is fan-out through
the boundary. **Every entry routes to at least one internal endpoint**
([D-210][d-210]). An empty tuple is a declaration error, because a face
feeding nothing declares nothing ([D-210][d-210]). `y_connections(::A)` runs
the other way, internal source path => face name
(`"aircraft/pose" => "view_pose"`), so that its pairs, like every other pair
in the three declarations, read along the flow.

One invariant spans all three declarations. Every pair's arrow points the way
the signal flows. The left side is a producer or entry point, the right side
is a consumer, and every right side is fed exactly once. **Direction is
therefore declared by the method**, not inferred ([D-170][d-170]). The
resolved endpoints only *cross-check* it. An entry whose endpoint resolves to
a port of the wrong direction is a build error. The error names the method,
the entry and the resolved port's actual direction. A mixed entry is not
expressible, because the single list that made that error class possible does
not exist. Two entries producing the same output face remain the ordinary
two-producers error.

**Face *types and [tiers](#g-tier)* are derived from the internal endpoints**
([D-041][d-041]). A tier is the continuous or discrete side of the hybrid
formalism. This derivation is the [blessed](#g-blessed) (explicitly
sanctioned) derivation-from-declarations ([§8.2][s8-2]). The derivation is
forced, not merely convenient. An assembly is tier-neutral. It exports
continuous-sourced and discrete-sourced ports side by side. A face's
[cells](#g-cell) (entries of the signal table) follow the producer's own
declaration ([§8.5][s8-5]). They are evaluated at the
[activation](#g-activation) scalar on the continuous tier and
[pinned](#g-walked) on the discrete. Three alternative spellings are rejected
([D-041][d-041], [D-170][d-170]). Publicity is never implicit ([§8.3][s8-3]).

**Face names are arbitrary strings with two build-checked invariants**
([D-046][d-046]). The first is that a face name contains no `/`, which is
reserved for structural paths. The second is uniqueness across the union of
the two boundary declarations' face names ([D-170][d-170]). Every other naming
choice is author convention, not framework law. Separators and grouping
prefixes like `"pilot.throttle_axis"` are such choices. The
`input_passthrough` helper's defaults ([§8.8][s8-8]) document the house style
without legislating it.

The two-notation rule this rests on is directional. **It separates structure
from derived contract, not read from write** ([D-129][d-129]). Slash is
structure. It covers endpoint paths walking real children and ports, and the
inspection side's snapshot and log addressing. Face names are opaque
derived-contract tokens. The [periphery](#g-periphery) (everything outside the
loop that exchanges data with it) has a write side, made of input devices,
mappings, the trace and the GUI write path. That write side speaks face names
exclusively ([§11.3][s11-3]). The read side speaks them wherever it wants
meaning that outlives the build. It does so in integration bindings
(`get_face`, [§11.2][s11-2]) and service reads ([§14.4][s14-4]). The three
declarations return pairs of strings rather than NamedTuples
([D-046][d-046]).

[Root inputs](#g-root-input) fall out with no vocabulary of their own. At
every non-root level an input face declared through `u_connections` is fed by
the parent's wire. At the root there is no parent. There the root component's
input faces *are* the [write surface](#g-write-surface), the set of faces a
writer's batch entries may reach ([§11.3][s11-3]). Which declaration
supplies them follows the root's [class](#g-class) ([D-208][d-208]). Class is
a component's primitive-versus-assembly status. An assembly root supplies its
`u_connections` keys, and a primitive root its `u_types` keys
([§8.2][s8-2]). Nothing downstream distinguishes the two. The whole-tree
obligation model ([§6.1][s6-1]) states the complementary error rule. An
assembly never declares its external connections. Those live in the parent
that instantiates it, exactly as a leaf's do.

**At the root the uniqueness invariant follows the root's class**
([D-210][d-210]). A primitive root declares no boundary methods. Its face set
is therefore the union of its `u_types` and `y_types` keys. A key declared in
both is the same build error a duplicate face name is. The root is where those
two declarations first share an address space. A root input places a cell the
periphery writes ([§11.3][s11-3]), so a collision would put two cells at one
name. Below the root nothing collides, because a primitive's input faces alias
their producers' cells and place nothing. Non-root leaves are left alone.

#### A worked assembly: the strapdown IMU

The strapdown IMU of [§3.4][s3-4] is spelled here in full, as a
[worked](#g-worked) example (a full spelling of a mechanism against a concrete
case). It is a mixed-tier assembly. It exercises paths, faces and sample times
together:

```julia
struct IMU <: AbstractComponent
    integrals::IMUIntegrals    # continuous — cumulative Θ, q, Υ, V
    sampler::IMUSampler        # discrete — integrate-and-difference latches
    errors::IMUErrorModel      # discrete — scale/bias/noise on the sample
end

inner_connections(::IMU) = (
    "integrals/Θ" => "sampler/Θ", "integrals/q" => "sampler/q",
    "integrals/Υ" => "sampler/Υ", "integrals/V" => "sampler/V",
    "sampler/sample" => "errors/sample",
)

u_connections(imu::IMU) = (
    input_passthrough(imu, "integrals")...,       # kinematic-truth inputs pass through
)

y_connections(::IMU) = (
    "sampler/sample"     => "sample",             # ideal increments
    "errors/sample_meas" => "sample_meas",        # measured increments (the error
                                                  # model's output port)
)

sample_times(::IMU) = (sampler = Relative(1), errors = Relative(1))
```

Two spellings are worth reading closely. First, `input_passthrough` enumerates
the child's *input* faces and nothing else ([§8.8][s8-8]). That is why the
pass-through of the integrals' kinematic-truth inputs (`q_eb`, `r_eb_e`,
`ω_eb_b`, `a_ib_b`, `α_ib_b`) is a bare splat with nothing to say about
direction. Second, the measured-increment face sources `errors/sample_meas`,
the error model's *output* port. It does not source `errors/sample`, the
input the sampler already feeds. Listing `errors/sample` in `y_connections`
would fail the direction cross-check. Listing it in `u_connections` while it
is wired is the two-producers error of [§8.8][s8-8].

Two facts the example carries. The first is that the assembly is
tier-neutral. Every face's type and tier derive from its internal endpoint,
and a `sample_times` key on `integrals`, the continuous child, would be a
build error ([§8.7][s8-7]). The second is that the two discrete children
default to `Relative(1)` anyway, so this `sample_times` declaration is
declaratory. Their absolute rate arrives from the enclosing scope at
deployment ([§8.7][s8-7]). The latch-back wire (below), where the integrals
consume the sampler's published latch, would join `inner_connections` as one
more ordinary pair.
