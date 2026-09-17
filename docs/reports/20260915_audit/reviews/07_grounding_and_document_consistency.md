# Primary review: grounding, exclusions, and document consistency

## Scope and method

Read specification §§1–2.2, 7.5, 11.2 (logging), 11.5, 13.7, 15.1–15.5,
16, and the API/diagnostic appendices; cross-checked relevant decisions and
`src/Cadence.jl`, publication/trace machinery and allocation tests. The more
detailed executable contracts are owned by the subsystem reviews. External
FlightPhysics/FlightApps references and linked excluded documents were not opened.

## DOC-01 — Allocation claims conflict inside the specification

- **Category:** document inconsistency, medium priority, high confidence.
- **Requirement conflict:** spec lines 1671–1682 (§7.5) describe inline snapshot
  records, amortized-zero logging, and zero per-boundary allocation. Spec lines
  5036–5042 (§11.2) instead prescribe retaining snapshot references and allocating
  one snapshot per boundary. D-023 (decisions lines 715–727) ratifies the latter
  and rejects preallocated rings.
- **Implementation:** `src/sim.jl:1488` captures/publishes every boundary;
  `src/dataplane.jl:570` defines snapshots with a store bundle and shared layout;
  `src/dataplane.jl:576` copies cell buffers; `src/dataplane.jl:619` stores retained
  snapshots in a vector of snapshot references. This agrees with §11.2/D-023.
- **Measurement:** `probes/publication_allocation.jl`, Julia 1.13.0, warmed minimum
  over ten samples: publication 576 bytes with logging off and 736 bytes with
  logging on; complete deviceless, stateless frames 592/752 bytes. Trace disabled.
  These numbers characterize this tiny fixture on this runtime, not a model-scale
  performance guarantee. See `validation/publication-allocation.log`.
- **Disposition:** do not report these allocations as a demonstrated implementation
  defect. Align §7.5 with §11.2/D-023 and distinguish zero-allocation phase bodies
  from allocating publication/retention. Existing phase-body allocation assertions
  test a narrower contract than whole-frame allocation.

## DOC-02 — The snapshot overview still puts heartbeat capture at frame top

- **Category:** document inconsistency, low priority, high confidence.
- Spec §11.2:4990–4995 says the loop takes liveness timestamps at frame top.
  §11.8:6193–6205 and D-240 (`decisions.md:8666–8688`) instead require reading
  heartbeat at publication, beside task state. D-240 explicitly rejects a
  drain-side read because localized boundaries would publish stale timestamps.
- `src/sim.jl:1520–1529` reads `_heartbeat` while assembling publication status,
  agreeing with the later ruling and owning section. Update the stale overview;
  no implementation change follows from this inconsistency.

## Grounding/exclusion dispositions

| Specification area | Disposition |
|---|---|
| §1 | Normative target and method; no source-compatibility obligation to the old framework. |
| §2.2 | DAE/SDE solvers and unconditional per-step hooks are explicit exclusions, not omissions. RNG-state replay guarantees depend on authored state discipline. |
| §13.7 | `Group` and passthrough helpers are core machinery. The standard component library is expressly a migration-phase deliverable (spec 7965); examples existing only in test fixtures are not a current kernel defect. Face-provenance rendering is a separate current obligation reviewed with build. |
| §15.1 | Historical Vehicle grounding, not a requirement to include a Vehicle model in `src/`. Maps to stage order, explicit wiring, handles and events. |
| §15.2 | Engine/PID/supervisor examples ground two-stage output reuse and same-tick reset semantics. Auto-publication in the saturation-latch example is affected by the build omission. Actual external migrations are outside scope. |
| §15.3 | Historical contested-writer comparison explicitly superseded by exclusive claims. Its GUI-wins ordering must not be treated as a current competing-writer requirement. |
| §15.4 | End-to-end capability scenario. Missing pacing/control/GUI integration is covered in subsystem reviews; aircraft/device implementations and plots are outside this kernel audit. |
| §15.5 | Cumulative-integral/sampler-latch example grounds continuous/discrete sampling order. It depends on missing auto-publication. Tick-triggered continuous handlers are expressly recorded, unbuilt. No independent quaternion/sculling numerical-equivalence experiment was performed. |
| §16 | Migration outline is explicitly not a specification. GUI authoring convention and on-disk log/trace persistence are deferred. Export-surface decisions and named residual design questions stay open; no new ruling is inferred here. |
| Appendices A/B/C | Indices cross-checked against owning sections, not independent duplicated obligations; Appendix C kind/payload coverage receives its own diagnostic inventory. |
| Appendix D | Terminology/reference support for the owning sections. It does not establish implementation evidence. |

## Optional improvement: make trace memory growth observable

The snapshot retention cap bounds snapshot count, not total session memory.
`TraceRegister.batches` grows for each nonempty drained batch (`src/trace.jl`,
`_record!`), deliberately without sampling/rolling eviction (§11.5:5657–5670).
The default-on primary trace and the deferred persistence interface make very long
interactive sessions a useful measurement target. The specification's “tens of MB
per hour worst case” is workload-dependent: writer count, drain rate, root-value
width and value representation all affect the footprint.

Consider reporting retained batch count and estimated trace bytes/growth rate
beside the existing log retention information. Lossless streaming can be evaluated
when the §16 persistence work is undertaken. This is an optional observability
improvement, not a recommendation to discard primary data or silently disable
recording. No long-duration memory benchmark was run in this audit.
