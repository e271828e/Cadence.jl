# V3 — cold verification: error discipline and the API surface

- **Tip**: `70672d1`, Julia 1.12.7, `julia --project=.` from the repository root.
- **Probes run**: three, all foreground, in
  `.../scratchpad/verify3/` — `p1.jl` (exports; the §13.1 typo'd-wire example and
  its unconnected-input control), `p2.jl` (`EventHalfMissing.found` on a
  parameterized type; `DeclarationOnWrongTier` across two components and within
  one), `p3.jl` (termination record under a constructor bound versus a `run!`
  override).
- **Decision entries read**: D-057, D-220. **Spec read**: §13.1 (6951–6999),
  §13.2 (7040–7060), §13.5 (7303–7440), Appendix B (9880–9891, 10070–10074),
  Appendix C (10130–10287).
- Files under `src/`, `test/` and `docs/design/` were not modified.

---

## 1. Appendix C `collected` kinds raised fail-fast — **CORRECTED**

The substance holds and is stronger than Agent G states; two details in the
report are wrong.

**What D-057 rejects** (`docs/design/decisions.md`, D-057 "Rejected"):

> - *Uniform fail-fast:* N build cycles for N clustered wiring errors.
> - *Full compiler-style batching:* poisoned nodes, cascade suppression,
>   dependent-check skipping — machinery for failures that are singular in
>   practice.
> - *Suppression heuristics:* adjacent path-sorted pairs are self-explanatory.

**The probe.** Two-child assembly (`G1` + `S2`), one wire typo'd `"g/ot" => "s/a"`,
leaving `s/a` and `s/b` both unfed. §13.1:6993 demands the did-you-mean *and* the
unconnected input, both reported:

```
== claim 1: typo'd wire (expect UnknownPort + 2 UnconnectedInput per 13.1) ==
n diagnostics = 1
  Cadence.UnknownPort :: child_connections at the root component, entry `"g/ot" => "s/a"`: `g/ot` names no `ot` on `g` — its faces are e, out

== claim 1 control: correct wire, s/b unfed ==
n diagnostics = 1
  Cadence.UnconnectedInput :: `s`.b is fed by nothing — every input is fed exactly once, ...
```

The did-you-mean renders; the two `UnconnectedInput`s never do. §13.1's own
worked example does not hold. **Confirmed.**

**The definitive sweep.** Every kind below reads `collected` in the Appendix C
policy column. "Lone" = `throw(BuildError(<one diagnostic>))`, nothing gathered.

| kind | policy col. | raising sites | behaviour |
|---|---|---|---|
| `UnknownPort` | collected | `assembly.jl:483` (`_wrong_direction`); `assembly.jl:730` (`:connection` arm) | **483 lone fail-fast**; 730 collects into `w.viol` (barrier `assembly.jl:658`) |
| `FaceDirectionConflict` | collected | `assembly.jl:487` | **lone fail-fast** (only site) |
| `PathResolution` | collected | `assembly.jl:261, 280, 286, 311` | **lone fail-fast** (all four) |
| `UnknownFaceSelection` | collected | `assembly.jl:421, 425` | **lone fail-fast** (both) |
| `ClassUnreadable` | collected | `assembly.jl:48` (`classify`) | **lone fail-fast** |
| `ClassMixed` | collected | `assembly.jl:44` (`classify`) | **lone fail-fast** |
| `StoreWithoutUpdate` | collected | `build.jl:77` (`classify_tier`) | **lone fail-fast** |
| `TierUnreadable` | collected | `build.jl:81` (`classify_tier`) | **lone fail-fast** |
| `WireTypeMismatch` | collected | `build.jl:1033` (`_probe_input`) | **lone fail-fast** |
| `ProducedByTwoStages` | collected | `build.jl:517` | **lone fail-fast** |
| `DeploymentInvalid` | collected | `build.jl:702, 704, 720, 723, 725, 735, 738, 749, 752`; `build.jl:764, 769`; `sim.jl:138–154` | **nine lone fail-fast arms in `bind_schedule`**, not two; 764/769 collect (barrier 774); `sim.jl` arms collect (barrier `sim.jl:156`) |
| `DeclarationOnWrongTier` | collected | `build.jl:91` (`:tier_form`); `build.jl:562, 567` (`:continuous_only`, `:no_manifold`) | 91 **collects within one component**, barrier `build.jl:96` throws before the next component; 562/567 collect model-wide (barrier 573) |
| `ContainerMixed` | collected | `assembly.jl:124` | **collects within one component**, barrier `assembly.jl:156` throws before the next |
| `ChildNameCollision` | collected | `assembly.jl:137, 143, 181` | same per-component barrier at `assembly.jl:156` |
| `TransparentContainerUnknown` | collected | `assembly.jl:169` | same per-component barrier at `assembly.jl:156` |
| `FaceNameCollision` | collected | `assembly.jl:774` (`:assembly`), `assembly.jl:790` (`:root`) | **collects model-wide** into `w.viol`, barrier `assembly.jl:658` — conformant |
| `RootInputTypeConflict` | collected | `build.jl:330` (`_root_input_type`) | **collects model-wide** into the layout pass's `viol`, barrier `build.jl:298` — conformant |

**Corrections to the report.**

1. The summary's count is wrong in both directions. §2 says "Nine Appendix C
   kinds whose policy column reads *collected* are raised fail-fast"; the report's
   own §3.6/§3.7 tables carry twelve rows tagged "rejected D-057", and the true
   count of kinds with at least one **lone** fail-fast site is **eleven**
   (the eleven bolded rows above). §4.1's own prose names ten and adds
   `assembly.jl:156` and `build.jl:96`, which are the weaker per-component case.
2. `RootInputTypeConflict` is **not** a fail-fast kind. Its §3.6 row is tagged
   "short, rejected D-057" while its own note says "check collects within its own
   pass"; the note is right and the tag is wrong. `build.jl:330` pushes into the
   layout pass's shared `viol`, which also carries every `IllegalPortType`, and
   the single barrier at `build.jl:298` throws them together, model-wide.
3. §4.1's "two `DeploymentInvalid` grid arms (`build.jl:749, 752`)" undercounts:
   `bind_schedule` has **nine** lone-throwing arms (702, 704, 720, 723, 725,
   735, 738, 749, 752) against a `collected` column. Only the per-anchor loop
   (764, 769) collects.
4. The two categories are genuinely different and the report conflates them.
   *Lone fail-fast* (eleven kinds) is exactly D-057's rejected "uniform
   fail-fast". *Per-component collection with a component-scoped barrier*
   (`DeclarationOnWrongTier(:tier_form)`, `ContainerMixed`, `ChildNameCollision`,
   `TransparentContainerUnknown`) reports every violation inside one component
   but hides every later component's — a partial short, not a full one.
   `FaceNameCollision` and `RootInputTypeConflict` are fully conformant.

---

## 2. `EventHalfMissing.found = typeof(c)` — **CONFIRMED**

`src/build.jl:411`:

```julia
    hasmethod(fn, Tuple{typeof(c),NamedTuple}) ||
        push!(viol, EventHalfMissing(path = path, event = name, reason = half,
                                     found = typeof(c)))
```

`src/diagnostics.jl:360` declares `found::Any`, and `src/diagnostics.jl:367`
interpolates it directly. Probe `p2` on `Bouncer{Float64,3}`:

```
Cadence.EventHalfMissing
  found  = Bouncer{Float64, 3}  ::DataType
  msg    = ``: event `touchdown`'s guard has no method for Bouncer{Float64, 3} — an event needs both halves (§8.2)
```

Against the doctrine at `docs/design/spec.md:7051`: "**Strings, never
instances.** Diagnostics carry paths and names as strings, never component
instances and never model types". `_typename` sits at `src/diagnostics.jl:29`.

*One citation fix:* the doctrine is at spec line **7051**, not 7068 (7068 is in
the runtime-warning-stream paragraph). The substance is unaffected.

---

## 3. `ServiceLifecycle.legal` filled only by `capture` — **CONFIRMED**

All eleven construction sites in `src/`, with their arguments:

| site | arguments |
|---|---|
| `src/conditions.jl:815` | `op = :capture, status = lc, legal = [:initialized, :stopped]` |
| `src/sim.jl:301` | `op = op, status = :running` |
| `src/sim.jl:302` | `op = op, status = :stopped` |
| `src/sim.jl:303` | `op = op, status = :errored` |
| `src/sim.jl:611` | `op = :init!, status = :running` |
| `src/sim.jl:612` | `op = :init!, status = :errored` |
| `src/sim.jl:724` | `op = :replay!, status = :running` |
| `src/sim.jl:725` | `op = :replay!, status = :errored` |
| `src/devices.jl:133` | `op = op, status = :running` |
| `src/trim.jl:386` | `op = :trim!, status = :running` |
| `src/trim.jl:387` | `op = :trim!, status = :errored` |

`legal` defaults to `Symbol[]` (`src/diagnostics.jl:723`). One site of eleven
fills it, and it is `capture`. The claim's three named sites (`init!`, `trim!`,
`replay!`) are correct; the gap is in fact wider — `_assert_advanceable`
(`run!`/`step!`/`live!`) and `assert_stopped` (`attach!`/`detach!` and the
stopped-sim readers) leave it empty too.

---

## 4. Device attribution in seven kinds — **CONFIRMED**

Per kind, the Appendix C payload column against the code:

| kind | column asks for | code payload | match |
|---|---|---|---|
| `OutOfClaimEntry` | "**device id**, face name, the discarded value, the device's claim set; the incumbent's device id" | `face, value, surface, incumbent` (`dataplane.jl:60-65`) | device id missing |
| `DeviceCrash` | "**device id**, the original exception as `cause`, whether `should_abort` was set" | `cause, abort` (`dataplane.jl:99-102`) | device id missing |
| `ReplayDiscardedStaging` | "**device id**, the discarded batch's face names, frame ordinal" | `faces, frame` (`dataplane.jl:126-129`) | device id missing |
| `MalformedDatum` | "**device id**, the cause exception" | `cause` (`dataplane.jl:56-58`) | device id missing |
| `EntryTypeMismatch` | "**writer id**, face name, the offending value's type, the root input's declared type, the discarded value" | `face, value, declared` (`dataplane.jl:76-80`) | writer id missing |
| `AttachUnknownFace` | "the **device (by type)**, binding entry, face name, the root input-face list" | `binding = _typename(b), face, candidates` (`roster.jl:205-206`) | names the **binding** type |
| `ReadBindingUnresolved` | "the **device (by type)**, the selector, path and field, candidates; a `reason`" | `binding = string(T), selector, reason, path, field, candidates` where `T = typeof(b)`, the binding (`sim.jl:1236` → `bindings.jl:138,157-186`) | names the **binding** type |

So every one of the five runtime rows does list a device or writer id in its
payload column, and none of the five payloads carries one. The argument sits at
`src/dataplane.jl:38-42`: "Writer attribution is never a payload field: the
channel is per-writer, so the cell supplies it (§11.8, §12.4: no call passes a
device id)." The two service rows ask for the device type by name and get the
binding type instead. Agent G's account is accurate throughout.

---

## 5. `method = RK4` versus `algorithm = RK4()` — **CONFIRMED** (one line citation off)

`src/sim.jl:131`: `Δt_base = nothing, method = RK4, firing_budget = 4,`
`src/sim.jl:137`: `method isa Type && method <: AbstractStepper ||`
`src/sim.jl:164`: `stepper = method(T, length(ex.xbuf))`

Appendix B: `docs/design/spec.md:9880` — "`Simulation(world; algorithm = RK4(),
h, n = 1, …`"; `:9891` — "| `algorithm` | `RK4()` | the stepper; `RK4` is the
default |". Also `spec.md:9171`. So both the keyword name and the value's kind
differ: the spec passes an instance, the code takes a `Type` and calls it as
`method(T, n)`.

`grep -n 'algorithm *=' docs/design/decisions.md` and `grep -n 'method *='
docs/design/decisions.md` both return **nothing**. D-220 is the authoring-family
rename (`state_derivative`, `output_state`, `state_events`, `init_workspace`,
…); it never mentions `algorithm`, `method`, or the stepper keyword. **No
decision ratifies the `method` spelling.**

*Citation fix:* the validation is at `src/sim.jl:137-138`, not `~172`
(`sim.jl:172` is inside the `Simulation` field list). `~130` (actually 131) and
`164` are right.

---

## 6. The termination record and the `run!` override — **CORRECTED**

The *fact* is confirmed; the *reading of the spec* is wrong.

Probe `p3`:

```
constructor t_end=0.5 -> source=Cadence.EndTimeReached()  t=0.5
override t_end=0.5   -> source=Cadence.EndTimeReached()  t=0.5
records identical? true
fieldnames(TerminationRecord) = (:t, :source, :residue)
fieldnames(EndTimeReached)    = ()
```

But §13.5 does not ask for the distinction — it forbids the payload that would
carry it. `docs/design/spec.md:7382-7383`:

> - `EndTimeReached` — `t_end`'s frame completed. **No payload: the record's own
>   `t` is the fact, and the configured bound lives in the run metadata.**

and `:7351-7352`: "The run metadata records the constructor's pair; a run's
effective bound is reported by its termination record when it fires". The
effective bound *is* reported — as the record's `t`, which is the only spelling
§13.5 permits. Appendix B `:10072-10074` ("the override is reported by the
termination record when it fires") says the same thing more loosely, and §13.5
is the owning section.

`src/devices.jl:36` (`struct EndTimeReached <: TerminationSource end`, no
fields) and `src/devices.jl:73-77` (`t`, `source`, `residue`) are **exactly**
what §13.5 prescribes: three fields, the four typed sources, `EndTimeReached`
payload-free.

**Corrected claim:** the termination record does not distinguish a `run!`
override from the constructor's bound, and the spec does not require it to —
§13.5:7382 explicitly gives `EndTimeReached` no payload and puts the configured
bound in the run metadata. i_api 4.14's verdict "short" should be "accurate";
what remains is at most a wording ambiguity in Appendix B, not an implementation
gap.

---

## 7. Three separate walks over the same stores — **CONFIRMED**

- `capture` (`src/conditions.jl:813-847`): per component, `_capture_x` walks
  `ex.xbuf` field by field through `reconstruct`, then `ex.sstores[ci][]` and
  `ex.mstores[ci][]` are dereferenced directly, then root inputs via
  `gather(ex.store, act.layout.addr[("", f)])` (`conditions.jl:832`).
- `_capture_header` (`src/trace.jl:277-296`): `copy(ex.xbuf)` wholesale,
  `deepcopy(st[])` over `ex.sstores` and `ex.mstores`, root inputs via
  `gather(ex.store, layout.addr[("", f)])` (`trace.jl:283`).
- The compiled `Reader` (`src/readers.jl:193-202`): a third path — a tuple of
  baked entries reduced by `gather(r::Reader, ex::Executor)`; neither of the
  first two constructs or consumes one.

Three walks, one layout. **Refinement:** the shared primitive is slightly wider
than "`gather` on root inputs" — `readers.jl:176`
(`_read(r::CellRead, ex) = _take(gather(ex.store, r.addr), r.i)`) means the
`Reader` also bottoms out in the same `gather(store, addr)`, just never for the
root-input faces specifically. The report's point stands: the three store walks
must be kept in step by hand.

---

## 8. Nothing is exported; `condition`, `ProbeDual`, `ProbeTag` absent — **CONFIRMED**

Probe `p1`:

```
names(Cadence) = [:Cadence]
isdefined(Cadence, :condition) = false
isdefined(Cadence, :ProbeDual) = false
isdefined(Cadence, :ProbeTag)  = false
Probe-ish names: Symbol[]
```

`src/Cadence.jl` is 24 lines — `module`, one `using`, twenty `include`s, `end`
— with no `export`. `names(Cadence, all=true)` filtered on "ondition" returns
only the `Condition*` diagnostic kinds, `ConditionNode`, `ConditionPlan`,
`_condition` (`bindings.jl`'s axis conditioning) and `resolve_condition`; no
`condition` generic. Filtered on "Probe" it returns the empty set, so neither
`ProbeDual` nor its `ProbeTag` exists even as an internal name.

---

## 9. `DeclarationOnWrongTier(:tier_form)` per component — **CONFIRMED**

Probe `p2`, two sibling components with the identical dissent (`init_x` +
`state_derivative` + `state_update`):

```
paths in walk order = ["m1", "m2"]
n diagnostics = 1
  Cadence.DeclarationOnWrongTier path="m1" decl=state_update reason=tier_form found=discrete announced=continuous
    msg = `m1`: `state_update` is declared in the discrete-tier form, but this component's other declarations announce the continuous tier (§8.2)
```

`m2`'s identical mismatch is unreported: `build.jl:702` is
`tiers = [classify_tier(p, c) for (p, c) in zip(flat.paths, flat.comps)]`, and
`classify_tier`'s barrier at `build.jl:96` throws inside the comprehension.

Within one component the pass does collect — a third component declaring both
`init_x`/`state_derivative` and `init_s`/`state_update`:

```
== claim 9b: two dissents inside one component ==
n diagnostics = 2
  state_update `m3`: `state_update` is declared in the discrete-tier form, ...
  init_s       `m3`: `init_s` is declared in the discrete-tier form, ...
```

The message names the two **tiers** (`found = :discrete`, `announced =
:continuous`), not the two declaration forms. That is consistent with the
Appendix C column, which asks only for "component path, the offending
declaration …, the tier the leaf's other declarations announce" — so the payload
is a superset, not a short.

**One addition the claim omits:** `DeclarationOnWrongTier` has two further
raising sites, `build.jl:562` (`:continuous_only`) and `build.jl:567`
(`:no_manifold`), in the Stratum C `state_projection` pass. Those two **do**
collect model-wide, with the barrier at `build.jl:573`. Only the `:tier_form`
arm is component-scoped.
