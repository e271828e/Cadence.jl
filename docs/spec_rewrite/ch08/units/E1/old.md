### 8.6 Paths, wiring and faces

**Paths are slash-separated strings**, relative to the [assembly](#g-assembly) or model root
they are read from, with no leading slash. There is one canonical form, shared
verbatim by declarations, error messages, [device](#g-device)/[trace](#g-trace) addressing
([§11.3][s11-3]) and the HDF5 log tree. [Container children](#g-container-children) ([§8.5][s8-5]) add index and
key segments, `"aircraft/2"` and `"aircraft/red"`, which are ordinary segments
resolved against the container field. A container declared name-transparent
([§8.5][s8-5]) adds no segment of its own, and its elements go by bare key. Instance
navigation, tuples of symbols and dotted paths were all rejected ([D-040][d-040]). A
path-tracking proxy remains addable sugar. The three wiring declarations use
only the short case of that form, one child segment and one [face](#g-face) name
([§6.1][s6-1]). The read side walks the full depth (`"systems/ldg/left/trn"` in a
[snapshot](#g-snapshot) or the log tree). That read side is the inspection side and
`resolve` as the inspection primitive ([§13.3][s13-3]). One fact from that
adjudication is relied on downstream. Symmetric immutable siblings are
`===`-identical, so a path is unrecoverable from an instance. That is why the
helpers ([§8.8][s8-8]) name the child by path.

**`inner_connections(::A)`** is an ordered collection of `"src/face" => "dst/face"`
pairs, strictly from a child face to a child face. The rules ([§6.1][s6-1]) apply:
one wire per input, and every endpoint an immediate child and one of its
[faces](#g-face), container key segments included. The assembly's **boundary** is
declared by two further methods, one per direction. **`u_connections(::A)`**
is an ordered collection of pairs, face name => internal endpoint path, or a
tuple of paths for an input face routed to several immediate children
(fan-out through the boundary), as in
`"trn" => ("left/trn_field", "right/trn_field", …)`. Every entry routes to
**at least one** internal endpoint. An empty tuple is a declaration error,
because a face feeding nothing declares nothing ([D-210][d-210]).
**`y_connections(::A)`** runs the other way, internal source path => face
name (`"aircraft/pose" => "view_pose"`), so that its pairs, like every other
pair in the three declarations, read along the flow.

**Face names are arbitrary strings with two build-checked invariants.** The
first is that a face name contains no `/` (reserved for structural paths). The
second is uniqueness across the union of the two boundary declarations' face
names. Every other naming choice (separators, grouping prefixes like
`"pilot.throttle_axis"`) is author convention, not framework law. The
`input_passthrough` helper's defaults ([§8.8][s8-8]) document the house style
without legislating it.

**At the root the uniqueness invariant follows the root's [class](#g-class)**
([D-210][d-210]). A primitive root declares no boundary methods, so its face set is
the union of its `u_types` and `y_types` keys, and a key declared in
both is the same build error a duplicate face name is. The root is where those
two declarations first share an address space. A [root input](#g-root-input) places a [cell](#g-cell)
the [periphery](#g-periphery) writes ([§11.3][s11-3]), so a collision would put two cells at one
name. Below the root nothing collides, because a primitive's input faces alias
their producers' cells and place nothing. Non-root leaves are left alone.

The two-notation rule this rests on is directional. It separates structure
from derived contract, not read from write. **Slash is structure**: endpoint
paths walking real children and ports, and the inspection side's
[snapshot](#g-snapshot) and log addressing. **Face names are opaque derived-contract
tokens.** The [periphery](#g-periphery)'s write side (input devices, mappings, the trace,
the GUI write path) speaks face names exclusively ([§11.3][s11-3]). The read side
speaks them wherever it wants meaning that outlives the build, in integration
bindings (`get_face`, [§11.2][s11-2]) and service reads ([§14.4][s14-4]). The
three declarations return pairs of strings rather than NamedTuples ([D-046][d-046]).

One invariant spans all three declarations. Every pair's arrow points the way
the signal flows, with the left side a producer or entry point and the right
side a consumer, and every right side is fed exactly once. **Direction is
therefore declared by the method**, not inferred. The resolved endpoints only
*cross-check* it, and an entry whose endpoint resolves to a port of the wrong
direction is a build error naming the method, the entry and the resolved
port's actual direction. A mixed entry is not expressible, because the single
list that made that error class possible does not exist. Two entries producing
the same output face remain the ordinary two-producers error. Face *types and
[tiers](#g-tier)* are derived from the internal endpoints, which is the [blessed](#g-blessed)
derivation-from-declarations ([§8.2][s8-2]). The derivation is forced, not merely
convenient ([D-041][d-041]). An assembly is tier-neutral, exporting
continuous-sourced and discrete-sourced ports side by side, and a face's
[cells](#g-cell) follow the producer's own declaration ([§8.5][s8-5]), evaluated at the
[activation](#g-activation) scalar on the continuous tier and [pinned](#g-walked) on the discrete. Three
alternative spellings are rejected ([D-041][d-041], [D-170][d-170]): routing values under the
leaf names `u_types`/`y_types`, leaf-style *typed* faces with face
wires inside `inner_connections`, and routing-as-wires with derived types and
no face list. Publicity is never implicit ([§8.3][s8-3]).

**[Root inputs](#g-root-input) fall out with no vocabulary.** At every non-root level an input
face declared through `u_connections` is fed by the parent's wire. At the
root there is no parent, and the root component's input faces *are* the
[write surface](#g-write-surface), the set of faces a writer's batch entries may reach ([§11.3][s11-3]).
Which declaration supplies them follows the root's [class](#g-class),
`u_connections` keys for an assembly and `u_types` keys for a
primitive ([§8.2][s8-2]), and nothing downstream distinguishes the two. The
whole-tree obligation model ([§6.1][s6-1]) states the complementary error rule. An
assembly never declares its external connections. Those live in the parent
that instantiates it, exactly as a leaf's do.

**A [worked](#g-worked) assembly.** The strapdown IMU of [§3.4][s3-4], spelled in full. It is a
mixed-tier assembly exercising paths, faces and sample times together:

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

Two spellings are worth reading closely. `input_passthrough` enumerates the
child's **input** faces and nothing else ([§8.8][s8-8]), which is why the
pass-through of the integrals' kinematic-truth inputs (`q_eb`, `r_eb_e`,
`ω_eb_b`, `a_ib_b`, `α_ib_b`) is a bare splat with nothing to say
about direction. And the measured-increment face sources `errors/sample_meas`,
the error model's *output* port, not the `errors/sample` input the sampler
already feeds. Listing `errors/sample` in `y_connections` would fail the
direction cross-check, and listing it in `u_connections` while it is wired
is the two-producers error of [§8.8][s8-8].

Three facts the example carries. The assembly is tier-neutral. Every face's
type and tier derive from its internal endpoint, and a `sample_times` key on
`integrals`, the continuous child, would be a [§8.7][s8-7] build error. The two
discrete children default to `Relative(1)` anyway, so this `sample_times`
declaration is declaratory, and their absolute rate arrives from the enclosing
scope at deployment ([§8.7][s8-7]). And the latch-back wire (below), where the
integrals consume the sampler's published latch, joins `inner_connections` as
one more ordinary pair.

