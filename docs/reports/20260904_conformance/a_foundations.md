# Agent A — Part I, §1–§7 (foundations)

## 1. Header

- **Agent**: A
- **Slice**: `docs/design/spec.md`, Part I, §1–§7
- **Line range**: 127–1628
- **Tip**: `70672d1`, Julia 1.12.7
- **Probes run**: yes. Five scripts under the session scratchpad
  (`probe_a.jl` … `probe_e.jl`), each a foreground `julia --project=.` from
  the repository root. They settled: reference-carrying port values, abstract
  input entries, the state-leaf vocabulary, auto-published ports, `DeadStage`,
  the bundle-framing diagnostic, the walk-compatibility clause, and
  enum-valued ports.
- **Forbidden reads**: none. I read the spec slice, `src/`, `test/`, the
  "What is real here" file table in `implementation.md` (rows 11–57 only,
  which carried the authoring-caveat block on the same screen), and the
  `decisions.md` entries D-012, D-016, D-036, D-094, D-167, D-168, D-169,
  D-190 that my slice cites.

## 2. Summary

Part I is in good shape where it describes machinery that the hot loop needs.
The two-stage split, the bundle law, the schedule, the boundary macro-sequence,
the store/buffer/table separation, the one-level wiring rule, the fan-in rule
and the allocation invariant are all built in the spec's own shape, and several
of them are asserted by tests that match the claim closely. §5.3's boundary
sequence and §6.1's connection rules are the strongest passages: every rule has
a line behind it and a diagnostic kind with a payload.

The gaps cluster in four places.

**The diagnostic layer around the schedule is the thinnest.** §5.6's
feedthrough tracer does not exist at all — no set-tracer type, no SCC
decomposition, no real/artificial classification, no per-member dependence
maps. §5.5's cycle diagnostic exists but reports the whole topological-sort
residue as a list of *component* paths, not one diagnostic per strongly
connected component naming the loop in the `aero/F → dyn/a → aero/α̇` port
form, and it offers one exit ("insert a stage-1 port") where §5.4 asks for two.
D-012 ratifies both the tracer and the SCC shape, so this is a gap against a
settled decision rather than a reading.

**The declared-value vocabularies are unenforced in one direction and
over-tight in the other.** §7.1 closes the state-leaf vocabulary to real
scalars and `SArray`s; `init_x` accepts `Int`, `Bool` and invariant-carrying
structs without a word, and D-094 names the invariant-carrying case as the
alternative it *rejected*. The probe showed a normalizing constructor running
on a view, which is the exact silent-projection failure D-094 was written to
prevent. Meanwhile §4.1 lists enums among legal port values and §4.4 requires
bulk-data field handles to travel as ordinary port values; the cell layout
refuses an enum port outright (`IllegalPortType`) and accepts a
reference-carrying port only to fail with a raw `MethodError` inside generated
code at the first gather.

**Two structural checks the spec names by kind are not built.** `DeadStage`
(an output stage returning `(;)`) and auto-published ports (a declared output
matching a state or mode field that no stage produces). The second is worse
than merely missing: the completeness pass actively refuses that declaration
with `DeclaredNotProduced`, so the shape §5.3 mandates is a build error today.
D-016 ratifies "selective auto-publication of declared state/mode fields".

**§6.1's walk-compatibility clause is absent, and its absence reproduces the
failure mode the spec wrote it to remove.** The input-side forgotten-`T` is
supposed to fail at the first *nominal* build, at the wire; the probe showed it
building cleanly at nominal and failing only at the first `Dual` activation,
which is the behaviour the spec assigns to the *output* side alone. What is
built instead is a value-level structural test (`_accepts`) at the probe, not
the declaration-level `<:` test the spec states, and one consequence is that
§4.4's abstract input entry (`terrain = AbstractTerrainField`) is refused.

What surprised me: how much of §5.2's law surface is genuinely enforced by
construction rather than by checking (the bundle names come from the same
`bundle_names` call at probe and at compile, so the shape cannot drift), and
how far §5.6's absence has been *left silent* rather than degraded — the code
carries no marker at the `AlgebraicCycle` throw site that classification was
skipped.

## 3. Findings

| § | claim | verdict | location | test | note |
|---|---|---|---|---|---|
| §1 (145–180) | purpose, ground rules, capability grounding, guarded additions, "all axes settled", `decisions.md` citation convention | n/a | — | — | rationale and method; no obligation on code |
| §2 (183) | continuous dynamics `ẋ = f(x, m, u, t)` with algebraic outputs | accurate | declare.jl:226, build.jl:959 | test_continuous.jl:4 | |
| §2 (184–185) | multi-rate periodic discrete `s⁺ = g(s, u, t)` at declared rates, outputs held ZOH between ticks | accurate | declare.jl:227, executor.jl:160, executor.jl:445 | test_discrete.jl:11, test_discrete.jl:46 | ZOH by compile-time absence from the interior walk |
| §2 (186) | zero-crossing guards with handlers under two detection policies | accurate | declare.jl:182, executor.jl:176 | test_events.jl:108 | |
| §2 (187–189) | optional per-component `x ← state_projection(x)` after each accepted step | accurate | declare.jl:202, executor.jl:220 | test_events.jl:247 | |
| §2 (191–192) | external inputs injected asynchronously by the runtime | accurate | sim.jl:1294 (`stage!`), dataplane.jl | test_dataplane.jl:177 | detail is §11's |
| §2.1 (199–201) | both policies share one declaration; only detection differs | accurate | declare.jl:182 | test_events.jl:108 | `StateEvent(guard, handler)` carries no policy keyword |
| §2.1 (203–207) | boundary-detected: edge against the prior at boundaries only, no root-finding | accurate | sim.jl:431, executor.jl:250 | test_events.jl:114 | iteration detail is §10.6's |
| §2.1 (208–209) | localized: crossing instant found by root-finding | accurate | localization.jl:1 | test_localization.jl | detail is §10.4's |
| §2.1 (211) | detection policy never depends on real-time pacing | n/a | — | — | §10.7's claim |
| §2.1 (213–222) | ticks are time events (`sample_times`), `StateEvent` declares state events; criterion is detection vs scheduling | accurate | declare.jl:171, declare.jl:193 | test_discrete.jl:105 | |
| §2.1 (226–228) | guard predicate is a `Bool` form or a sign form, positive = holds, holding = `σ ≥ 0` | accurate | declare.jl:205–206 | test_events.jl:108 | |
| §2.1 (230–233) | edge semantics: fires on not-holding → holding | accurate | sim.jl:446 | test_events.jl:114 | |
| §2.1 (232–233) | opposite direction declared as a second event with the negated guard | n/a | — | — | authoring idiom |
| §2.1 (237–241) | the guard's *return type* is the declared policy (`Bool` → boundary, sign → localized), D-179 | accurate | build.jl:630–634 | test_events.jl:108 | `GuardForm` names both admissible forms |
| §2.2 (243–245) | no DAEs / algebraic constraints; projection covers the need | accurate | declare.jl:202 | — | absence honoured; no constraint surface exists |
| §2.2 (246–253) | no SDEs; RNG state lives in component `s`, never in ambient globals; deterministic replay | accurate | declare.jl:30, sim.jl:720 (`replay!`) | test_trace.jl | `init_s` admits it; replay is §12.7's |
| §2.2 (254–260) | no unconditional per-step hook (no `f_step!` equivalent) | accurate | declare.jl:224–227, assembly.jl:13 | — | the leaf declaration family is closed and carries none |
| §3.1 (267) | continuous state `x` declared by value | accurate | declare.jl:22 | test_store.jl:81 | vocabulary itself: see §7.1 row |
| §3.1 (268–270) | mode variables `m`, piecewise-constant, changed *only* through event handlers | accurate | executor.jl:315 | test_events.jl:114 | only `_latch!` writes a mode store during a run; `establish_defaults!` and the §14 condition apply are the stopped-sim writers |
| §3.1 (271–275) | flow, two output stages, events reading the fresh boundary table, optional projection | accurate | executor.jl:287–324 | test_events.jl:247 | |
| §3.1 (277–280) | any facet may be empty; a component with no `x` — modes, events, mode-valued outputs — is an FSM | accurate | build.jl:73–83, declare.jl:278 | — | probed: an `init_m` + `state_events` leaf with no `init_x` builds and inits |
| §3.1 (286–288) | supervisor commanding a mode is an input; a component detecting its own transition is an event | n/a | — | — | rule of meaning, not a check |
| §3.2 (293) | discrete state `s`: any immutable value | accurate | declare.jl:30, build.jl:881 | test_store.jl:81 | see 4.11 for a docstring divergence |
| §3.2 (294–296) | update `s⁺ = g(s, u, t)` at a declared rate; two output stages; feedthrough at update instants | accurate | declare.jl:227, executor.jl:160 | test_discrete.jl:11 | |
| §3.2 (298–306) | `x` and `s` are different objects, spelled differently (D-195); a leaf is strictly one tier; no component reads another's state | accurate | build.jl:58–98, declare.jl:278–299 | test_build.jl:145, test_declare.jl:35 | |
| §3.2 (308–315) | `m` is continuous-only; a discrete component has no mode store | accurate | build.jl:64, build.jl:88–96 | test_build.jl:145 | `DeclarationOnWrongTier` |
| §3.3 (318–319) | assembly is pure composition — submodels, child connections, boundary faces — with no dynamics of its own | accurate | assembly.jl:40–50 | test_assembly.jl:29 | `ClassMixed` |
| §3.3 (322–325) | assemblies flattened away for scheduling, retained as navigation hierarchy and as declaration-level rate scopes | accurate | assembly.jl:504, assembly.jl:600 | test_assembly.jl:475, test_discrete.jl:199 | `Flat` keeps absolute paths and the two-sided face table |
| §4.1 (331–332) | ports exchange immutable values — floats, `SVector`s, **enums**, nested immutables | short | build.jl:275–287, leaves.jl:25–27 | — | see 4.1: an enum-valued port is refused with `IllegalPortType` |
| §4.1 (332–334) | the framework owns a signal table: one concretely-typed cell per output port in the flattened model | accurate | store.jl:11–31, build.jl:288–292 | test_store.jl:17, test_store.jl:53 | |
| §4.1 (334–338) | a stage returns a NamedTuple; the framework scatters each field into its cell; consumers read cells | accurate | executor.jl:144–148, store.jl:81 | test_continuous.jl:4 | |
| §4.1 (340–348) | vocabulary: bare *cell*, *store*, *staging cell*, *root input* — three distinct homes | accurate | store.jl:11, build.jl:881–883, dataplane.jl, build.jl:263 | test_store.jl:81 | |
| §4.1 (350–352) | the signal requirement is immutability plus **frozen references**; `isbits` is the common case, not the rule | absent | build.jl:275–287, store.jl:42–67 | — | see 4.2 |
| §4.1 (354–360) | consequences: no aliasing, safe concurrent reads, zero allocation for isbits, definite freshness per cell | accurate | dataplane.jl:577, executor.jl:384 | test_continuous.jl:39, test_dataplane.jl:177 | |
| §4.2 (363–366) | the port is the addressable unit; a component's outputs appear as one flat namespace, materializable lazily as a view | short | readers.jl:22–54 | test_readers.jl | see 4.3: reads address a port whole or by element index; no nested-field selector |
| §4.2 (366–369) | which stage computes which port is invisible outside the component; moving an output between stages is non-breaking for consumers | accurate | declare.jl:68, build.jl:503–521 | test_build.jl:44 | one `output_types` declaration, stage discovered by probe |
| §4.2 (371–376) | the output contract *is* the public interface; no private intermediates; a stage result outside the contract is a build error | accurate | build.jl:155–158 | test_build.jl:28 | `UndeclaredReturnField` with the declared-port list |
| §4.2 (375–376) | a presentational *unlisted* flag is closed (D-016) | n/a | — | — | rejected alternative; nothing built |
| §4.3 (387–392) | a leaf's ports and faces coincide; an assembly face aliases an interior port and never creates an endpoint | accurate | build.jl:299–300, assembly.jl:439–450 | test_assembly.jl:496 | |
| §4.3 (392–394) | the distinction is kind-blind: wiring and the periphery address a child's faces without knowing its class | accurate | assembly.jl:439–469 | test_assembly.jl:496 | |
| §4.3 (396) | the port is the atomic unit of the whole periphery — one cell, one root input, one staged write, one device claim, one trace address | accurate | build.jl:293–297, roster.jl:163, trace.jl | test_roster.jl, test_trace.jl | the GUI liveness verdict half is §11.7/§16 |
| §4.3 (400–405) | scatter/gather is the whole protocol; every reader gathers views from cells | accurate | store.jl:42–88 | test_store.jl:53 | |
| §4.3 (407–413) | `y` is a merge semantically and virtual physically — reconstructed per call from cells, never stored; carries declared ports only | accurate | executor.jl:105–120, build.jl:520 | test_continuous.jl:39 | |
| §4.3 (413) | name collisions across a component's stages are a build error | accurate | build.jl:516–519 | test_build.jl:28 | `ProducedByTwoStages` |
| §4.3 (417–421) | stage returns are NamedTuples of port values, period; a custom struct is a first-class port value with one cell; bare-struct returns rejected (D-036) | accurate | build.jl:124–127, build.jl:511–514 | test_build.jl:28 | |
| §4.3 (420–421) | nested fields get no cells of their own | accurate | build.jl:280–286 | test_store.jl:53 | one `CellAddr` per declared port |
| §4.3 (425–428) | wiring is port-granular: no sub-field connections | accurate | assembly.jl:257–290 | test_assembly.jl:325 | enforced by absence: a terminal's final segment is a face name |
| §4.3 (428–431) | a field-projection connector is a guarded addition, not built | n/a | — | — | |
| §4.3 (433–448) | granularity guideline: bundle what shares a stage and is consumed together | n/a | — | — | authoring guidance |
| §4.3 (452–457) | write-side rule: data written by different external writers, or at different cadences, must not share a port | accurate | roster.jl:163–210 | test_roster.jl | one claim per port; `ClaimConflict` |
| §4.3 (459–465) | field-addressed staging stays a recorded guarded addition, unbuilt | n/a | — | — | |
| §4.4 (469–478) | environment fields carried by ordinary ports as immutable query objects; consumers call query functions inside their own stages | short | build.jl:275–287 | — | the parametric isbits case works; the bulk-data case does not (4.2) |
| §4.4 (479–484) | parametric models are isbits; **bulk-data models use the handle pattern** — isbits parameters plus references to build-time-frozen data | absent | build.jl:275–287, store.jl:42 | — | see 4.2 |
| §4.4 (485–488) | no mutable caches inside field objects | n/a | — | — | contract on component authors |
| §4.4 (489) | loggers treat field-handle signals specially (skip or summarize) | absent | dataplane.jl:564–577 | — | the log copies raw cell buffers; no per-signal policy exists |
| §4.4 (491–512) | the value-level constructor obligation on a field-emitting component | n/a | — | — | a shipped component's obligation; no shipped components in `src/` |
| §4.4 (514–522) | pre-sampling is an idiom built on top, not a mechanism | n/a | — | — | |
| §4.4 (524–530) | substitutability behind a stable face declared with an abstract input entry (`terrain = AbstractTerrainField`) | absent | build.jl:179–190, build.jl:1032 | — | see 4.4 |
| §4.4 (530–531) | resource injection closed (D-008) | n/a | — | — | |
| §5.1 (540–544) | build the graph of wiring edges plus intra-component feedthrough; if acyclic, one topological sort yields a static schedule computed at build time | accurate | build.jl:216–249 | test_build.jl:44 | |
| §5.1 (544–545) | the hot loop runs a flat list of `(component, stage)` entries — zero runtime graph logic | accurate | executor.jl:415–447, build.jl:1005–1009 | test_continuous.jl:24, test_continuous.jl:39 | |
| §5.2 (548–571) | exactly two output stages per component; feedthrough declared structurally by signature; no dependency annotations anywhere | accurate | declare.jl:224–227, build.jl:216–227 | test_build.jl:44 | |
| §5.2 (577–581) | every function receives exactly two arguments: the component and one NamedTuple bundle, destructured by name | accurate | executor.jl:144–164, executor.jl:105–120 | test_declare.jl:35 | |
| §5.2 (587–589) | positional, `kwarg_decl` and slurping spellings closed (D-074); `state_projection` alone stays positional | accurate | declare.jl:202, executor.jl:220–224 | test_events.jl:247 | |
| §5.2 (594–596) | bundle law: a name appears iff the corresponding store or fact exists | accurate | declare.jl:278–299 | test_declare.jl:35 | |
| §5.2 (600) | `x` present iff `init_x` declared | accurate | declare.jl:282 | test_declare.jl:38 | |
| §5.2 (601) | `s` present iff `init_s` declared | accurate | declare.jl:285 | test_declare.jl:45 | |
| §5.2 (602) | `m` present iff `init_m` declared | accurate | declare.jl:283 | — | |
| §5.2 (603) | `ws` present iff `init_workspace` declared | accurate | declare.jl:295, declare.jl:301 | test_store.jl:112 | |
| §5.2 (604) | `u` present iff the function family may see inputs **and** `input_types` is declared | accurate | declare.jl:287–289, declare.jl:314 | test_declare.jl:39, test_declare.jl:41 | |
| §5.2 (605) | `y` present iff the component produces any table cell at all (`output_types` ∪ auto-published) | accurate | declare.jl:292–293 | test_declare.jl:40 | the union's second term is vacuous while auto-publication is absent (4.5) |
| §5.2 (606) | `y_x` / `y_s` present iff stage-1 ports exist, under the tier's own spelling | accurate | declare.jl:290–291, build.jl:507 | test_declare.jl:39, test_declare.jl:48 | |
| §5.2 (607) | `t` always | accurate | declare.jl:296 | test_declare.jl:38 | |
| §5.2 (608) | `Δt` present iff on the discrete tier | accurate | declare.jl:297 | test_declare.jl:45 | |
| §5.2 (610–617) | the stage-1 hand-down carries the stage-1 *return*, auto-published names excluded (D-169) | accurate | build.jl:507, build.jl:941 | test_declare.jl:48 | the exclusion is vacuous today (4.5) |
| §5.2 (619–620) | undeclared stores are *absent*, never `nothing`-filled | accurate | declare.jl:278–299, executor.jl:105–120 | test_declare.jl:35 | |
| §5.2 (620–626) | destructuring an absent field fails at the probe inside §13.2's framing diagnostic, with did-you-mean against the legal field set | absent | — | — | see 4.6 |
| §5.2 (628–638) | the mechanism is structured: `FieldError` caught matched against the bundle's NamedTuple type, classified as undeclared store / wrong tier / illegal name; no text scraped | absent | — | — | see 4.6 |
| §5.2 (636–638) | the wrong-tier class covers the state letters: `x`/`m` continuous-only, `s`/`Δt` discrete-only | short | build.jl:58–98 | test_build.jl:145 | enforced on *declarations* (`DeclarationOnWrongTier`); on destructuring it is the raw `FieldError` of 4.6 |
| §5.2 (640–651) | the per-function, per-tier name sets are closed, one set per function per tier | accurate | declare.jl:278–319 | test_declare.jl:35 | |
| §5.2 (654–656) | an output stage returns its port NamedTuple, `y`, and nothing else | accurate | build.jl:124–127, build.jl:511–514 | test_build.jl:28 | |
| §5.2 (658–660) | stages are discovered by method existence; stage membership is a partition of the declared ports | accurate | declare.jl:229, build.jl:516–519, build.jl:528–536 | test_build.jl:28 | |
| §5.2 (662–665) | an empty `y = (;)` is a `DeadStage` build error at the probe — the inert-component check | absent | — | — | see 4.7 |
| §5.2 (668–671) | handler return law: a key is present iff the store exists **and** the handler updates it | accurate | build.jl:649–691, executor.jl:313–317 | test_events.jl:72 | |
| §5.2 (673–678) | padding forms `((;), m⁺)` / `(x⁺, (;))` do not exist (D-090) | accurate | build.jl:651–653 | test_events.jl:72 | a non-NamedTuple return is `ConformanceFailure` |
| §5.2 (680–684) | per key: `x` complete against the state field set; `m` a names-subset; an unknown key ⇒ did-you-mean against `{x, m}` | accurate | build.jl:659–688, diagnostics.jl:693–705 | test_events.jl:72 | `HandlerReturnKey` carries the store list |
| §5.2 (688–694) | what the views are: `x` from the buffer, `m`/`s` from stores, `y` from own cells, `u` from foreign cells, `t`/`Δt`, `ws` | accurate | executor.jl:105–120 | test_store.jl:81 | |
| §5.2 (696–701) | the table holds only *produced* signals; one home per datum; no store mirrors another | accurate | build.jl:877–887, store.jl:1–31 | test_store.jl:81 | |
| §5.3 (711–724) | symbol/API correspondence: `f`→`state_derivative`, `g`→`state_update`, `h(x)`→`output_state`, `h(x,u)`→`output_direct` | accurate | declare.jl:224–227, declare.jl:258 | test_declare.jl:35 | |
| §5.3 (726–731) | a stage's *name* states the dependence class, not the argument list; "no `direct` in the name" is the no-feedthrough property | accurate | declare.jl:214–218, build.jl:216–227 | test_build.jl:44 | |
| §5.3 (733–735) | names deliberately non-exhaustive: modes fold under the state, ambient facts and scratch ride unnamed (D-075) | accurate | declare.jl:278–299 | test_declare.jl:35 | |
| §5.3 (737–742) | the update law carries the tier in its name; the two output stages serve both tiers; a leaf mixing them is a build error | accurate | declare.jl:258, build.jl:58–98 | test_build.jl:145 | |
| §5.3 (745–749) | `output_state` is the no-feedthrough stage: its bundle carries no `u`, so the property cannot be violated by construction | accurate | declare.jl:287–289 | test_declare.jl:38 | |
| §5.3 (751–754) | stage 1 exists when the component has state-derived ports; otherwise it is simply absent | accurate | build.jl:119 | test_build.jl:44 | |
| §5.3 (756–761) | a declared output matching a state or mode field by name and type, produced by no stage, is auto-published from the stores at stage-1 position | absent | build.jl:528–536 | — | see 4.5 |
| §5.3 (763–769) | `output_direct` receives all wired inputs plus its own stage-1 hand-down, and the state views | accurate | build.jl:507–510, executor.jl:105–120 | test_declare.jl:39 | |
| §5.3 (769–770) | conservatively, every stage-2 output is presumed dependent on every wired input | accurate | build.jl:219–226 | test_build.jl:44 | |
| §5.3 (772–775) | `state_derivative`/`state_update` run after the sweep, against the complete fresh table, own stage-2 ports included | accurate | build.jl:957, sim.jl:326–332 | test_continuous.jl:4 | |
| §5.3 (777–778) | all output stages must be pure (no side effects) | n/a | — | — | author contract; not checkable |
| §5.3 (781–783) | the schedule: all stage-1 in any order, then stage 2 in topological order, then all `state_derivative` calls | accurate | sim.jl:326–332, build.jl:1006–1009 | test_build.jl:44 | |
| §5.3 (785–791) | evaluating the RHS means running the sweep; no incremental `state_derivative`-only re-evaluation; RHS and guard trials run the *interior* sweep, discrete entries absent by construction | accurate | sim.jl:320–332, localization.jl:113, executor.jl:399–421 | test_discrete.jl:46, test_continuous.jl:39 | |
| §5.3 (795–800) | at a step boundary the order is integrate → project → boundary sweep → guards | accurate | sim.jl:350–358, sim.jl:431–434 | test_events.jl:247 | |
| §5.3 (802–806) | `state_projection` runs between a state write and its decode — after integration and after any handler `x`-reset | accurate | sim.jl:352–353, executor.jl:319–324 | test_events.jl:247 | |
| §5.3 (808–819) | boundary sequence: all guards evaluated once, eligible events fired as `handler → state_projection`, sweep→guards→handlers iterated to quiescence | accurate | sim.jl:431–473 | test_events.jl:138 | |
| §5.3 (817–819) | the signal table is written **only** by sweeps; a transition reaches the table at the next round's re-sweep | accurate | executor.jl:144–148, sim.jl:467–469 | test_events.jl:186 | |
| §5.3 (821–824) | the epoch rule: a handler executes against exactly the world its guard fired on | accurate | sim.jl:442–467 | test_events.jl:153 | one guard walk, one masked fire walk, no re-sweep between |
| §5.3 (826–830) | within a round each component fires at most one event, declaration order deciding; sequential composition happens across rounds | accurate | sim.jl:455–461 | test_events.jl:153 | §10.6 owns the detail |
| §5.3 (832–856) | why derivatives may read outputs; the FlightPhysics survey; shared expensive computations | n/a | — | — | rationale |
| §5.4 (860–864) | the two-stage split resolves the artificial-loop class; the `VehicleDynamics` instance dissolves under it | accurate | build.jl:216–227 | test_build.jl:44 | property of the split |
| §5.4 (866–868) | the tracer labels the surviving stage-level-cyclic case **artificial** | absent | — | — | see 4.8 |
| §5.4 (870–911) | the remedy ladder: re-factor the contract, then split the component | n/a | — | — | authoring guidance |
| §5.4 (913–916) | the build diagnostic offers both exits explicitly ("split the component, or narrow the neighbor's contract") | short | diagnostics.jl:585–587 | test_build.jl:54 | see 4.9 |
| §5.4 (916–917) | the offending stage-2 function is carried as a separate payload field | absent | diagnostics.jl:581–583 | — | `AlgebraicCycle` carries `members` only |
| §5.4 (910–911) | no visibility register for orphaned intermediates: D-034 / D-055 stay closed | n/a | — | — | |
| §5.4 (923–925) | an input consumed only by `state_derivative` still creates a scheduling edge if the component has stage-2 outputs | accurate | build.jl:220–226 | test_build.jl:44 | edges are per declared input, gated on `has_stage(output_direct, …)` |
| §5.5 (928–930) | a genuine cycle in the instantaneous dependency graph is a build error | accurate | build.jl:244–248 | test_build.jl:54 | |
| §5.5 (929–931) | the diagnostic names the full path in the canonical slash form `aero/F → dyn/a → aero/α̇ → aero/F` | short | build.jl:246, diagnostics.jl:581–587 | test_build.jl:59 | see 4.9 |
| §5.5 (932–939) | the user breaks the cycle by dynamics, an explicit `UnitDelay` (§13.7), or restructuring | absent | — | — | no `UnitDelay` in `src/`; the library inventory is §13.7's |
| §5.5 (938–939) | implicit delays and per-step numerical loop solving are closed (D-005) | n/a | — | — | |
| §5.5 (941–944) | implicit algebraic balances inside a component remain the author's business | n/a | — | — | |
| §5.6 (947–951) | tracing is diagnostic only, triggered when the scheduler finds a cycle, to classify it | absent | — | — | see 4.8 |
| §5.6 (953–961) | the stalled subgraph is decomposed into SCCs; each nontrivial SCC becomes one diagnostic naming its members and the wires among them (D-012) | absent | build.jl:244–248 | test_build.jl:59 | see 4.9 |
| §5.6 (963–976) | classification is schedule-free, per member at the probe point, in-cycle cells synthesized through `probe_value` under tracer tags | absent | — | — | see 4.8 |
| §5.6 (971–973) | the loop is **real** iff every hop survives the traced per-member maps; **artificial** iff some hop dies | absent | — | — | see 4.8 |
| §5.6 (978–990) | the caveats carried in the diagnostic: branch taken at the probe state, discrete members traced structurally, hint offered for continuous members only, member-list-only fallback | absent | — | — | see 4.8 |
| §5.6 (992–1003) | two tracer modes: global value-blind set-tracer, local primal-carrying set-tracer at sampled states | absent | — | — | see 4.8 |
| §5.6 (1005–1013) | boundaries: only inputs seeded; stage-1 never traced; derivatives/guards/handlers/projections outside jurisdiction; the value-severing blind spot documented | absent | — | — | see 4.8 |
| §6.1 (1036–1043) | every connection endpoint names an immediate child and one of its faces (D-207), across all three wiring declarations | accurate | assembly.jl:257–290 | test_assembly.jl:325 | `PathResolution(reason = :reaches_past)` |
| §6.1 (1043–1047) | container children keep their key segment; a name-transparent container's elements go by bare key | accurate | assembly.jl:91–158, assembly.jl:277–278 | test_assembly.jl:103, test_assembly.jl:195 | |
| §6.1 (1049–1063) | routing across several levels is declared level by level, each assembly speaking only of its own children; fan-out declared where the paths diverge | accurate | assembly.jl:457–476, assembly.jl:722–740 | test_assembly.jl:475 | |
| §6.1 (1065–1072) | the face graph is **total**: every signal crossing a boundary bears a declared face there, at every level | accurate | assembly.jl:660–672 | test_assembly.jl:496 | `Flat.in_faces` records every input face at every level |
| §6.1 (1074–1077) | enforcement lives in `resolve`, which walks declared field types alongside instances; paths validated at build time; renames break loudly | accurate | assembly.jl:273–315 | test_assembly.jl:647 | |
| §6.1 (1082–1086) | the nominal bound check: the producer's declaration at `Float64` must be `<:` the consumer's entry at `Float64`; a violation is `WireTypeMismatch` | stand-in | build.jl:1024–1037, build.jl:179–190 | test_build.jl:100 | see 4.4 |
| §6.1 (1088–1099) | the walk-compatibility clause for a continuous consumer, decided in Stratum A at a marker scalar; violation `WalkingFaceAtFrozenEntry` naming both endpoints, the leaf and both declared leaf types, with both remedies | absent | — | — | see 4.10 |
| §6.1 (1101–1108) | the tier scope: a discrete consumer takes the bound check alone; a continuous producer feeding a discrete consumer is unconditionally legal (D-167) | accurate | build.jl:471–472, build.jl:495–497 | test_discrete.jl:73 | frozen components are never re-probed at a non-nominal activation |
| §6.1 (1110–1115) | the failure asymmetry: the input-side forgotten-`T` fails at the *first nominal build*, at the wire, with both endpoints named | short | build.jl:1032–1035 | — | see 4.10 |
| §6.1 (1118) | fan-out is free: one producer, many consumers | accurate | assembly.jl:754–763 | test_assembly.jl:547 | |
| §6.1 (1120–1122) | every input port takes **exactly one** connection, no exceptions | accurate | assembly.jl:754–763 | test_assembly.jl:547 | `TwoProducers` |
| §6.1 (1124–1126) | the rule spans levels: a child input fed by a sibling wire *and* handed up is a two-producers build error | accurate | assembly.jl:754–763 | test_assembly.jl:547 | |
| §6.1 (1129) | no auto-bubbling of unconnected inputs (D-043) | accurate | assembly.jl:642–651 | test_assembly.jl:547 | |
| §6.1 (1129–1130) | unconnected output ports are legal, silently, with no build-time warning (D-084) | accurate | — | — | nothing inspects unconsumed outputs |
| §6.1 (1130–1131) | unconnected input ports are a build error, with no silent defaults | accurate | assembly.jl:646–647 | test_assembly.jl:547 | `UnconnectedInput` |
| §6.1 (1133–1139) | the check is a whole-tree property; the error fires at the root build for any obligation chain that never terminates; the one legitimate terminus is the root's own input face | accurate | assembly.jl:638–658, assembly.jl:685–692 | test_assembly.jl:62, test_assembly.jl:547 | |
| §6.2 (1148–1149) | N-to-1 physical aggregation is expressed by ordinary junction components and explicit wires | accurate | — | test_assembly.jl (fixtures' `Sum`) | honoured by the absence of any framework mechanism |
| §6.2 (1151–1154) | no framework aggregation mechanism: no multi-connection ports, no declared fold ops, no identity-element opt-outs | accurate | assembly.jl:754–763 | test_assembly.jl:547 | |
| §6.2 (1156–1163) | the library `SumJunction{W, N}` with its computed contracts | absent | — | — | no library component set in `src/`; the inventory is §13.7's |
| §6.2 (1165–1172) | UnionAlls are legal type parameters; both contracts derive their entries by applying the constructor to the activation scalar | accurate | declare.jl:55, declare.jl:68 | test_build.jl:241 | declarations are ordinary functions of the instance and `T` |
| §6.2 (1176–1185) | a junction wired at an ownership boundary is ordinary structure, a field of the parent like any other child | accurate | assembly.jl:114–119 | test_assembly.jl:29 | |
| §6.2 (1187–1209) | what the explicit form buys: loud mistakes, first-class aggregate, arbitrary stage-2 code, author-visible fold order, named site-specific junctions | n/a | — | — | consequences of the rules above |
| §6.2 (1211–1246) | the hierarchical aggregation idiom; do not bundle ragged contributions | n/a | — | — | authoring guidance |
| §6.2 (1258–1259) | the zero-contributor spelling is a library `Constant` source wired straight to the consumer | absent | — | — | no `Constant` in `src/`; §13.7's inventory |
| §6.2 (1271–1282) | the cost, recorded; consumer-declared folds closed (D-007, D-037) | n/a | — | — | |
| §7.1 (1288–1294) | `init_x` leaves are drawn from a **closed vocabulary** — plain real scalars and `SArray`s of a common eltype `T` — and nothing else; `Int`/enums/`Bool` belong in modes; domain wrappers are not state leaves | absent | declare.jl:22, leaves.jl:14–37 | — | see 4.11 — **rejected D-094** |
| §7.1 (1296–1297) | a flat layout computed at build time: compile-time offsets over one contiguous `Vector{T}` buffer the framework owns | accurate | build.jl:889–898, leaves.jl:166–172 | test_leaves.jl:107, test_store.jl:81 | |
| §7.1 (1298–1300) | the typed immutable state value is reconstructed at each evaluation and passed to every function receiving state views | accurate | executor.jl:107, leaves.jl:166 | test_continuous.jl:39 | |
| §7.1 (1301–1304) | immutable results come back: `Ẋ` scattered into the flat `ẋ` buffer; handlers and projection return a new `X` written back | accurate | executor.jl:150–155, executor.jl:313–324 | test_events.jl:168 | |
| §7.1 (1306–1317) | `Ẋ` has exactly `X`'s shape at the activation scalar; the conformance predicate is structural; no `derivative_type` hook (D-190) | short | build.jl:1041–1061 | test_build.jl:28 | see 4.12: the per-field test is `nleaves` equality, not shape at `T` |
| §7.1 (1319–1327) | the buffer is authoritative; typed values are ephemeral reconstructions; nobody outside the framework holds a mutable reference to state | accurate | build.jl:840, executor.jl:107 | test_store.jl:81 | |
| §7.1 (1329–1336) | whether repeated reads re-materialize is codegen freedom; the CSE legality condition is buffer-unchanged-within-a-sweep | n/a | — | — | statement about the code generator |
| §7.1 (1338–1344) | one home per datum: buffer for `x`, stores for `s` and `m`, table for produced signals; no store mirrors another; no state cells beyond auto-published ports | accurate | build.jl:877–887 | test_store.jl:81 | |
| §7.1 (1346–1360) | the vocabulary is closed so views materialize without running anyone's invariants: `reconstruct(flatten(x)) == x` identically, no constructor bypass | short | leaves.jl:69–91, leaves.jl:166 | test_leaves.jl:107 | see 4.11 — holds only for the vocabulary that nothing enforces |
| §7.1 (1361–1367) | what the closed vocabulary buys against the `ComponentArrays` pattern | n/a | — | — | rationale |
| §7.2 (1370–1372) | the state buffer, pack/unpack machinery and the whole continuous evaluation path are generic over `T <: Real` | accurate | build.jl:444–458, leaves.jl:185–195 | test_continuous.jl:50, test_build.jl:241 | |
| §7.2 (1372–1378) | four consumers: linearization, trim, the feedthrough tracer, the CI `Dual` invariant | short | trim.jl, test_continuous.jl:50 | test_trim.jl | consumer 3 is absent (4.8); the other three exist |
| §7.2 (1380–1384) | the discrete side's exemption: a frozen discrete cell is a constant with zero partials | accurate | build.jl:467–472, build.jl:488–497 | test_discrete.jl:73 | |
| §7.2 (1386–1389) | a continuous producer's output declaration is a function of the activation scalar; cell types per activation are that declaration *evaluated* | accurate | declare.jl:58–68, build.jl:36 | test_build.jl:241 | |
| §7.2 (1389–1391) | participation is authored per leaf: `T` follows the activation, a concrete type is deliberately pinned | accurate | build.jl:179–190 | test_build.jl:201, test_store.jl:17 | |
| §7.2 (1391–1394) | the state type is *derived*: the framework walks the `init_x`-derived type, real leaves and `Real` type parameters following the scalar | accurate | leaves.jl:185–195, build.jl:36 | test_leaves.jl:167 | |
| §7.2 (1394–1395) | the discrete side stays plain and pins wholesale | accurate | build.jl:37–38 | test_discrete.jl:73 | |
| §7.2 (1395–1396) | nothing anywhere comes from inference through user code | accurate | build.jl:16–38, declare.jl:250–252 | test_build.jl:241 | |
| §7.2 (1398–1414) | the three scoping tiers (walked / pinned / exempt) and the ~25-struct inventory | n/a | — | — | a migration inventory for `FlightPhysics` |
| §7.2 (1415–1423) | lookups: table data is a pinned parameter, the query coordinate is walked traffic | n/a | — | — | modeling guidance |
| §7.2 (1425–1428) | three author-facing rules: no `::Float64` argument annotations, no `Float64`-pinned intermediates, no `::SomeType{Float64}` return annotations | n/a | — | — | author contract; the `Dual` activation is the only detector |
| §7.3 (1439–1442) | discrete state and modes live in **typed stores**; the framework overwrites a store when an update or a handler returns a new value | accurate | build.jl:881–883, executor.jl:160–164, executor.jl:313–317 | test_store.jl:81 | |
| §7.3 (1444–1449) | a store keeps the cells' immutable-value discipline in a separate home; stores never touch the integrator buffer; no arithmetic is done on them | accurate | build.jl:877–887, build.jl:1067–1078 | test_store.jl:172 | |
| §7.3 (1451–1456) | type freedom: `s` may be *any immutable value*, isbits not required; RNG state is required to live in `s` | accurate | declare.jl:30, build.jl:881 | test_store.jl:81 | the `init_s` docstring says "any isbits type" — see 6 |
| §7.3 (1458–1461) | snapshots are free: copying a store copies a reference to immutable data | accurate | sim.jl:767 | test_lifecycle.jl | |
| §7.3 (1465–1471) | a workspace is component-declared mutable scratch, instantiated by the framework, arriving as `ws` in every bundle-receiving function of the declaring component; `state_projection` receives none | accurate | build.jl:462–465, declare.jl:295, executor.jl:114 | test_store.jl:112 | |
| §7.3 (1473–1476) | a workspace is excluded from state semantics: not snapshotted, not replayed, never a condition target | accurate | dataplane.jl:564–571, conditions.jl:447–457 | test_conditions.jl | `role = :workspace` refusal |
| §7.3 (1478–1485) | the framework never inspects or mutates a workspace; contents unspecified at call entry; no poisoning of scratch (D-183) | accurate | executor.jl:114, build.jl:462–465 | test_store.jl:112 | |
| §7.3 (1487–1500) | declared by allocation; `init_workspace` follows the tier split `(::C, ::Type{T})` / `(::C)` while `init_x`/`init_s`/`init_m` take the component alone | accurate | declare.jl:39–46, declare.jl:301–302, build.jl:462–465 | test_store.jl:112 | |
| §7.3 (1502–1505) | a one-argument `init_workspace` on a continuous leaf is an ordinary tier disagreement | accurate | build.jl:66–70 | test_build.jl:145 | |
| §7.3 (1507–1510) | the allocator is called once per activation and once per scratch-store set | accurate | build.jl:451, build.jl:884 | test_store.jl:112 | |
| §7.3 (1512–1518) | the `undef` spelling is the recommended idiom; `init_` means *establish* (D-077, D-220) | n/a | — | — | idiom |
| §7.3 (1520–1526) | available on both tiers; under a `Dual` activation the allocator is called at `Dual` | accurate | build.jl:462–465 | test_store.jl:112 | |
| §7.3 (1528–1536) | the blessed zero-allocation-tick idiom; the optional `ValueSnapshot{N,T}` wrapper | n/a | — | — | idiom; the wrapper is explicitly optional and unbuilt |
| §7.3 (1537–1540) | double-buffered mutable state deferred (D-013) | n/a | — | — | |
| §7.4 (1542–1582) | the four-step simplification arc and the prior-art survey | n/a | — | — | lineage |
| §7.5 (1586–1592) | the three reasons for the policy, the canary among them | n/a | — | — | rationale |
| §7.5 (1594–1600) | continuous hot path budget is exactly zero, CI-enforced at the phase-body seam (`phase_bodies`), guards and `state_projection` at both positions included | accurate | sim.jl:307–316, executor.jl:415–433 | test_continuous.jl:39, test_discrete.jl:337, test_events.jl:273 | |
| §7.5 (1601–1607) | periodic ticks and event handlers: zero by idiom, the rare exception scoped per body by the seam's granularity | accurate | executor.jl:440–447 | test_discrete.jl:337, test_events.jl:273 | |
| §7.5 (1608–1621) | logging is amortized-zero: snapshots are records stored **inline** in a `Vector`, with `sizehint!` for the expected duration | stand-in | dataplane.jl:575–577, dataplane.jl:617 | test_log.jl | see 4.13 |
| §7.5 (1622–1628) | what is not recorded: event firings; no per-event record in log or trace; recovered by replay plus published modes | accurate | dataplane.jl:564–571, trace.jl | test_trace.jl | |
| §7.5 (1629–1631) | tools where garbage is unavoidable: arena allocation, scheduled `GC.gc(false)` | n/a | — | — | advisory; nothing built, nothing claimed |

## 4. Deviations in detail

### 4.1 Enum-valued ports are refused

§4.1 (331–332): "Ports exchange **immutable values** — typically isbits
structs (floats, `SVector`s, enums, nested immutables)." §3.1 (277–280) leans
on the same fact when it says a component with only "modes, events and
mode-valued outputs" is an FSM.

`cell_layout`'s `place!` (`src/build.jl:275–287`) computes `leaf_types(P)` and
refuses an empty result with `IllegalPortType`. `leaf_types`
(`src/leaves.jl:25–27`) dispatches on `P <: Real`, `P <: StaticArray`, else
`fieldtypes(P)`. A `@enum` type is `<: Enum{Int32}`, not `<: Real`, and it is a
primitive type with no fields, so `leaf_types` returns `Type[]`.

Probe (`probe_e.jl`), with `@enum Phase OFF ON` and
`output_types(::FSM, ::Type{T}) where {T<:Real} = (phase = Phase,)`:

```
BuildError: IllegalPortType: `f`: port `phase` declares Phase, which has no leaves
```

Recoding the mode as an `Int` builds and inits. It matters because publishing a
mode is the spec's own remedy for the missing event-firing stream
(§7.5, 1622–1628: "the honest remedy is to declare the mode field public"), and
the natural spelling of a mode is an enum.

### 4.2 Reference-carrying signals build and then fail at the first gather

§4.1 (350–352): "The signal requirement, stated precisely, is **immutability
plus frozen references**: signals may reference bulk data (see §4.4) provided
that data is read-only for the duration of the run. `isbits` is the common
case, not the rule." §4.4 (479–484) makes it an obligation: "**Bulk-data
models use the handle pattern**: an immutable struct combining isbits
parameters with references to bulk data (heightmaps, wind grids, the geoid
undulation grid) loaded at build time and frozen."

`leaf_types` walks `fieldtypes` unconditionally, so it descends *into* an
`Array`'s internals rather than treating the reference as an opaque leaf.
Probe (`probe_b.jl`):

```
fieldtypes(Vector{Float64}) = (MemoryRef{Float64}, Tuple{Int64})
leaf_types(Vector{Float64}) = Type[Int64, Int64]
```

A component publishing `BulkField(p_sl::Float64, grid::Vector{Float64})`
builds, and `Simulation(b; h = 1//100)` constructs. The failure comes at the
first `gather` of that cell (`src/store.jl:42–53`), as a raw `MethodError`
inside generated code trying to rebuild a `GenericMemory` from two `Int`s. So
the framework neither supports the shape nor refuses it: the declaration passes
`place!`, garbage is written into the `Int` buffer at scatter, and the failure
surfaces with no diagnostic kind and no path attribution. Terrain heightmaps
and wind grids — the motivating cases named in §4.4 — cannot be carried today.

### 4.3 Reads address a port whole or by element index; there is no lazy view into nested fields

§4.2 (363–366): "A component's outputs appear to consumers, GUI and logs as one
flat namespace (`dyn.vel`, `dyn.f_c_c`), materializable lazily as a view."
§4.3 (420–421) restates it: "Nested fields get no cells of their own; GUI and
logs drill into them lazily (the view clause, §4.2)."

The read-selector family (`src/readers.jl:22–54`) addresses
`(path, field[, i])`, where `i` is a component index into a vector leaf. There
is no selector that drills into a nested struct field of a port value, and
`port(snap, path, name)` (`src/dataplane.jl:573`) returns the whole value. A
consumer inside the graph destructures in Julia, which covers the wiring case;
what is missing is the addressing surface the "flat namespace" sentence
promises for logs and inspection. Bundle ports (`pose = KinPose{T}`) are
therefore all-or-nothing on the read side.

### 4.4 The wire type check is a structural test over probe values, not a `<:` test over declarations

§6.1 (1082–1086): "**The nominal bound check** is stated over declaration
evaluations: the producer's declaration at `Float64` must be `<:` the
consumer's entry at `Float64`. It is one uniform rule, degenerating to exact
equality for a concrete entry."

What is built is `_probe_input` (`src/build.jl:1024–1037`) comparing the
producer's *probed value type* against the consumer's declared entry through
`_accepts` (`src/build.jl:179–190`). `_accepts` is structural equality with the
D-166 embed exception: identical types, or a `Real` pair under the activation
rule, or `StaticArray`s of matching size, or two types with the same
`P.name` and matching field types. It is not subtyping.

The practical consequence is §4.4's substitutability claim (524–530):
"Substitutability behind a stable face is declared with an abstract input entry
— `terrain = AbstractTerrainField`, structural substitutability (§8.2). The
consumer wires to any concrete field type below the bound." Probe
(`probe_a.jl`), with a producer declaring `FlatTerrain <: AbstractTerrainField`
and a consumer declaring `trn = AbstractTerrainField`:

```
BuildError: WireTypeMismatch: `cons`.trn declared AbstractTerrainField,
fed from `src`.trn::FlatTerrain
```

The abstract-bound idiom that preserves today's `AbstractTerrain` polymorphism
is refused. A concrete-only reading of the check would be defensible if the
spec said so; it says `<:` and it names the abstract entry as the mechanism.

### 4.5 Auto-published ports are absent, and the shape is a build error

§5.3 (756–761): "**Rule.** A declared output that matches a state or mode field
by name and type, and that no stage produces, is auto-published by the
framework from the state stores at stage-1 position (§8.3). The match is
against the declared stores — `init_x` plus `init_m` on the continuous tier,
`init_s` on the discrete — and the publication position is stage 1 on either
tier."

Nothing in `src/` implements it: `grep -rn "auto_publish\|auto-publish"` over
`src/` and `test/` returns nothing. Worse, `probe_stage2`'s completeness pass
(`src/build.jl:528–536`) refuses exactly that declaration. Probe (`probe_c.jl`),
with `init_x(::AutoPub) = (q = 0.0,)`, `output_types = (q = T,)` and no
`output_state`:

```
BuildError: DeclaredNotProduced: ``: declared port(s) q produced by no stage
— either a stage returns them or `output_types` drops them; the stages return none
```

D-016 ratifies "selective auto-publication of declared state/mode fields", so
this is a gap against a settled position and not a reading. Two other
statements in my slice quietly depend on it: the bundle law's `y` row (605,
"`output_types` ∪ auto-published") and D-169's hand-down exclusion (610–617,
`y_x` carries the stage-1 return "auto-published names excluded"). Both are
built correctly for the world in which auto-publication exists, and are vacuous
today. §7.1 (1342–1344) also refers to "contract-driven auto-published ports"
as the one class of state cell in the table.

### 4.6 Destructuring an absent bundle field gives a raw `FieldError`

§5.2 (620–626): "Destructuring a field that is not a thing for you fails at the
probe inside the §13.2 framing diagnostic, with did-you-mean (the offending
name plus the list-in-hand it should have matched) against the legal field set:
'`state_derivative` of `Foo` destructures `m`, but `Foo` declares no
`init_m`'." (628–638) fixes the mechanism: catch the `FieldError`, match it
against the bundle's own NamedTuple type, and classify the field as an
undeclared store, a wrong-tier fact, or a name illegal for this function
family.

No `FieldError` appears anywhere in `src/`. The probe calls user stage code
directly (`src/build.jl:122`, `src/build.jl:509`) with no `try`. Probe
(`probe_c.jl`), a component with no `init_m` whose `output_state` destructures
`m`:

```
ERROR TYPE: FieldError
FieldError: type NamedTuple has no field `m`, available fields: `x`, `t`
```

The message is not wrong, but it names neither the component, nor the stage,
nor the declaration the author forgot, and it arrives outside `BuildError`'s
carrier so it does not join the collected register. The §13.2 framing kind is
agent G's to audit; the obligation is stated here.

### 4.7 `DeadStage` is not built

§5.2 (662–665): "An empty `y = (;)` is a `DeadStage` build error at the probe
(§9.3): a stage returning nothing at all computes nothing any consumer can
read. That is the inert-component check in the stage register (§8.1)." §5.3
(753–754) repeats it: "A stage that would produce none is the `DeadStage`
error, an empty stage being unwritable on purpose."

`grep -rn "DeadStage" src/ test/` returns nothing, and there is no diagnostic
kind of that name. `_check_ports` (`src/build.jl:152–168`) iterates the returned
pairs, so an empty return passes vacuously. Probe (`probe_c.jl`), a component
whose `output_state` returns `(;)` and whose `output_direct` produces the
declared port:

```
build OK — no DeadStage error
```

`implementation.md`'s authoring-caveat block names the omission, so it is known
inside the project; it is still an absent obligation against the spec.

### 4.8 The feedthrough tracer does not exist

§5.6 (945–1013) specifies a complete instrument: the global value-blind
set-tracer (a `Real` subtype carrying a set of input indices, unioned by every
operation, may-depend semantics), the local primal-carrying tracer at sampled
states as the fallback, the per-member dependence maps, the hop-survival test
that decides real versus artificial, the seeding boundaries (inputs only), and
the four caveats that ride in the diagnostic.

Nothing of it is built. `grep -rn "tracer\|Tracer" src/ test/` returns one hit,
a comment in `src/diagnostics.jl:580` citing §5.6 beside the `AlgebraicCycle`
docstring. §5.4 (866–868)'s "the tracer labels that case **artificial**" and
§7.2 (1375)'s consumer 3 both fall with it. D-012 ratifies both tracer modes
and names them as the cycle classifier's mechanism.

The classification is described as "a bonus on the cycle error, never its
precondition" (§5.6, 988–990), so its absence does not break scheduling. What
it costs is the remedy: today a cycle error tells the author to insert a
stage-1 port, which is the wrong advice for exactly the artificial case §5.4
spends thirty lines on.

### 4.9 The cycle diagnostic reports the topological residue, not one SCC per cluster in port form

§5.5 (929–931): "The diagnostic names the full path in the canonical slash form
of §8.6: `aero/F → dyn/a → aero/α̇ → aero/F`." §5.6 (955–961): "The stalled
subgraph is decomposed into **strongly connected components**. Each nontrivial
SCC names one cyclic cluster exactly, and each cluster becomes one diagnostic
... Neither the raw stall residue nor a single back edge names the cluster
correctly (D-012)."

`schedule_stage2` (`src/build.jl:244–248`) throws one `AlgebraicCycle` carrying
`sort!(collect(remaining))` — the entire set of components the sort could not
place, mapped to component paths. Three facts follow. First, it is the raw
stall residue that D-012 names as wrong: two disjoint cycles in one model
produce one diagnostic listing both, and an acyclic component downstream of a
cycle is listed as a member. Second, the members are *component* paths, not
port terminals, so the rendered message is `ctl → plant → sum` where the spec
asks for `aero/F → dyn/a → aero/α̇ → aero/F`. Third, the ordering is
`sort!`ed, so it is alphabetical rather than the loop order.

`test/test_build.jl:59` asserts the current shape
(`sort(d.members) == ["ctl", "plant", "sum"]`), and `src/diagnostics.jl:582`
describes the field as "the SCC's member terminals, in slash form" — the
docstring already states the shape the code does not produce.

The message (`src/diagnostics.jl:585–587`) offers one exit, "break it with a
stage-1 (`output_state`) port", where §5.4 (913–916) requires both: "cycle
through `systems/aero` is artificial at port level — split the component, or
narrow the neighbor's contract". The offending stage-2 function payload field
(§5.4, 916–917) is likewise absent.

### 4.10 The walk-compatibility clause is absent, and the input-side forgotten-`T` lurks

§6.1 (1088–1099): "Beside it, and **for a continuous consumer only**, stands
the **walk-compatibility clause**. A walking producer leaf — the producer
declared `T` there — requires a `T` entry. ... Both sides are declaration
functions of `T`, so the clause is decided in Stratum A ... A violation is
`WalkingFaceAtFrozenEntry`, naming both endpoints, the leaf and both declared
leaf types. The message carries both remedies." (1110–1115): "The input-side
forgotten-`T` — the habitual `Float64` written at an entry whose consumer
really promotes — fails at the *first nominal build*, at the wire, with both
endpoints named, because an input has a build-time counterparty."

There is no `WalkingFaceAtFrozenEntry` kind and no Stratum-A pass evaluating
both declarations at a marker scalar. Probe (`probe_d.jl`), a walking producer
(`output_types(::Walker, ::Type{T}) = (y = T,)`) wired to a consumer whose
entry is the forgotten `Float64`:

```
== nominal build ==
  build OK at nominal — no refusal
== Dual activation ==
  REFUSED: BuildError: WireTypeMismatch: `f`.e declared Float64, fed from
  `w`.y::Dual{Nothing, Float64, 1} — if this leaf participates in
  differentiation, declare it `T`
```

So the input side behaves exactly as the spec says only the *output* side may:
it lurks until the first `Dual` activation. The failure asymmetry sentence
(1110–1115) is therefore not honoured either. What is built in its place —
`WireTypeMismatch` carrying both endpoints, both types, the activation and the
`_pin_hint` remedy — is a reasonable stand-in for the *message*, but it fires
one build phase and one activation later than the clause requires, and it
carries one remedy where the clause carries two.

### 4.11 The state-leaf vocabulary is not enforced, and D-094's rejected shape is admitted

§7.1 (1288–1294): "The declaration is a NamedTuple whose leaves are drawn from
a **deliberately closed vocabulary — plain real scalars and `SArray`s (static
vectors and matrices) of a common eltype `T`** — and nothing else. `Int`s /
enums / `Bool`s belong in modes, and domain wrapper types (`RQuat`, `Ranged`)
are not state leaves". (1346–1352): "Scalars and `SArray`s have invariant-free
constructors ... Building a view through ordinary public construction is
therefore bit-faithful automatically — `reconstruct(flatten(x)) == x`
identically ... Invariant-carrying leaves are closed (D-094)."

No check exists. `declarations` (`src/build.jl:36`) calls
`retype_value(T, init_x(c))`, which round-trips whatever leaves it finds
through the generic `leaves.jl` walk. Probe (`probe_c.jl`):

```
== 3. Int/Bool leaves in init_x ==
  build OK; nominal x decl = (n = 3, flag = true, q = 0.0)
== 3b. invariant-carrying state leaf ==
  build OK; x = (u = UnitVec([0.6, 0.8]),)
```

The second case is the one D-094 names as the alternative it *rejected*:
"*Invariant-carrying leaves with constructors run on read:*
`reconstruct(flatten(x)) ≠ x`: every consumer sees a silently projected value
over a runaway buffer". `_reconstruct_expr` (`src/leaves.jl:69–91`) emits
`Expr(:call, P, args...)`, so `UnitVec`'s normalizing inner constructor runs on
every view materialization. That is the silent projection, built.

The first case is milder but real: an `Int` state leaf lives in the `Float64`
buffer and is rebuilt through `Int64(buf[i])`, so it truncates or throws
`InexactError` the moment its derivative moves it off an integer — at run time,
inside generated code, rather than at build.

Marking: **rejected D-094**.

### 4.12 Derivative conformance is checked by leaf count, not by shape at `T`

§7.1 (1306–1313): "`Ẋ` has exactly `X`'s shape at the activation scalar ... The
conformance predicate is structural: *each field of `state_derivative`'s return
scatters into its field's block at `T`* (§9.5 states the check). That makes
derivative completeness a property of the layout rather than of author
discipline."

`_check_derivative` (`src/build.jl:1041–1061`) checks that the return is a
NamedTuple, that `keys(ẋ) === keys(x)`, and per field that
`nleaves(typeof(ẋ[k])) == nleaves(typeof(x[k]))`. `_check_state_write`
(`src/build.jl:585–604`), which serves `state_projection` and a handler's `x`
key, does the same.

Leaf count is weaker than shape at `T`. An `SVector{4,T}` state field whose
derivative comes back as an `SMatrix{2,2,T}`, or as a four-field struct of
`T`s, passes the check and then flattens into the block in whatever order the
walk produces. The completeness half of the claim — no forgotten `ẋ` entry —
is fully enforced by the key-set test; the shape half is not. §9.5 owns the
check's statement, so agent C sees the same code from the other side; the
claim is made here.

### 4.13 The log is a vector of snapshot references over per-boundary buffer copies

§7.5 (1608–1612): "**Logging**: amortized-zero. Snapshots are records stored
*inline* in a `Vector`, and `sizehint!` for the expected duration makes
regrowth a non-event."

`capture` (`src/dataplane.jl:577`) allocates a fresh `CellStore` per element
type per published boundary:
`capture(b) = StoreBundle(map(cs -> CellStore(copy(cs.buf)), b.stores))`. The
code comment beside it is explicit — "fresh buffers, one allocation per
boundary". `SnapshotLog` (`src/dataplane.jl:617`) then holds
`Vector{Union{Nothing,Snapshot}}`, a vector of heap references, not inline
records. `grep -rn "sizehint!" src/` returns nothing.

The per-boundary cost is bounded and independent of the run length, which is
what "amortized-zero" is reaching for, and D-023 (cited in the log docstring)
rejected preallocated buffers deliberately. But the two concrete mechanisms the
spec names — inline storage and `sizehint!` — are neither of them what is
built, so the row is a stand-in rather than a short one. The retention policy
(`log_every`, `log_max`, progressive re-decimation) is §11.2's and is out of my
slice.

## 5. Tally

| verdict | count |
|---|---|
| accurate | 129 |
| short | 10 |
| stand-in | 2 |
| absent | 22 |
| n/a | 32 |
| **total** | **195** |

Thirteen of the twenty-two absent rows belong to two mechanisms: §5.6's
feedthrough tracer (seven rows) and the auto-publish / `DeadStage` /
walk-compatibility trio plus their consequences. Counted by mechanism rather
than by claim, the slice owes ten distinct things.

## 6. Friction

- **The `init_s` docstring contradicts §7.3.** `src/declare.jl:26` says "any
  isbits type, pinned wholesale", where §7.3 (1451–1456) says "any *immutable
  value*: the frozen-reference rule governs, and isbits is not required", and
  then requires `Xoshiro`'s RNG state — a mutable struct — to live there. The
  code enforces neither, so the behaviour matches the spec and only the
  docstring is wrong; but I spent a probe deciding which of the two was
  normative for the code.

- **`AlgebraicCycle`'s docstring describes a shape its own construction site
  does not produce.** `src/diagnostics.jl:580–582` says "a strongly connected
  component of the stage-2 port graph" and "the SCC's member terminals, in slash
  form"; `src/build.jl:246` passes the whole topological residue as component
  paths. Two readings fit the file until you read both ends. The test
  (`test/test_build.jl:59`) asserts the weaker shape, so nothing catches the
  divergence.

- **§5.6's absence carries no marker.** Everywhere else the implementation is
  scrupulous about naming what it does not build (the D-nnn citations in the
  source comments are dense and accurate). The `AlgebraicCycle` throw site
  carries no note that classification was skipped, and §5.6's only trace in
  `src/` is a section reference in a docstring. I had to prove the absence by
  exhaustive grep rather than by reading a stated omission.

- **"Auto-published" is load-bearing in three separate places in my slice**
  (§5.2's bundle law row for `y`, D-169's hand-down exclusion, §7.1's "no state
  cells beyond auto-published ports") and absent in the code. Each of those
  three claims is *correctly implemented for the world without auto-publication*,
  which made them individually hard to score: the code is right, the clause is
  vacuous, and the mechanism it refers to is a build error. I scored the three
  as accurate and gave the mechanism its own absent row.

- **The brief asks for one claim per row, but §5.6 is one absent mechanism
  spread over seven paragraphs.** I gave it seven rows to keep the granularity
  rule, all pointing at 4.8. A reader counting absences should treat them as one
  feature.

- **I could not decide §4.3's "one GUI liveness verdict" half.** The port-atomic
  rule (396) lists six periphery registers; five are built and checkable, the
  sixth points at §11.7 and the GUI is §16's deferred item. I scored the row
  accurate on the five and noted the sixth rather than splitting it, because
  splitting it would report an absence that belongs to a section nobody audits.
