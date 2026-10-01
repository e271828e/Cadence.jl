### D-280 — Build a `Dual` activation of every component in CI

**Status.** ratified

**Position.** The repository's test suite builds a `Dual` activation of every
component, with `build(world; activations = (Float64, ProbeDual))`.
Linearizability is an invariant held by this policy.

**Spec.** §8.2, §9.4, Appendix B

**Rationale.** Activations are lazy (D-052), so a successful `build` does not
certify the model linearizable. A pinned `Float64` hidden in a constructor, or
a misplaced `Pinned` leaf, lurks until the first `Dual` activation. The policy
moves that first activation into CI. An activation is a re-run of the
activation step alone, cheap per the kernel prototype (D-166). D-166's annotation records
that the policy survived D-166's supersession by D-263. D-099 spells the probe
scalar, and D-275 makes the keyword the whole entry point.

**Rejected.**
- *Eager `Dual` at every build:* doubles compile latency for a CI-only
  guarantee. (As recorded in D-052.)

### D-281 — Guarantee torn-state-free lazy materialization

**Status.** ratified

**Position.** Lazy materialization of an activation is torn-state-free under
concurrent first requests, as a normative guarantee. The mechanism is
unspecified, and a guard around insertion suffices, paid at service time and
never on the hot path.

**Spec.** §9.2, §9.4

**Rationale.** An activation is a pure function of the build and the scalar,
so the worst benign race is duplicated work. The lock under which D-253 merges
the activations into one dictionary, and which §9.2 describes, is one
mechanism that suffices.

**Rejected.**
- *Requiring explicit pre-materialization for any concurrent use:* turns a
  safety property into a user obligation — the guard is cheap and off the hot
  path, and a sweep that forgets the keyword would get corruption rather than a
  slower first request. (As recorded in D-135.)

### D-282 — Give every buffer set exactly one owner

**Status.** ratified

**Position.** Every buffer set has exactly one owner, so buffers are never
cached.

- The `Simulation` owns its nominal activation's buffers, materialized from
  the cached layouts at construction.
- Every service invocation owns the scratch set it instantiates from those
  same layouts.

**Spec.** §9.2, §9.4, §11.1, §14.8, §14.10

**Rationale.** §14.8's per-invocation rule for `trim!` is the general one.
D-070 forced it: iterating on shared buffers aliases the sim's authoritative
stores, warn-but-assign reborn. Single ownership is also what lets the `Build`
back any number of `Simulation`s concurrently (D-135).

**Rejected.**
- *Cached shared buffers:* D-070's aliasing — warn-but-assign reborn — and it
  makes the `Build` mutable in exactly the way multi-`Simulation` sharing
  forbids. (As recorded in D-135.)
