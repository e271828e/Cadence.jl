# Notes: increment 68, the run of 2026-10-08

The coordinator's rulings, each with its reason, and the open points left
for the user. Nothing here is pushed.

## The arc

| commit | what |
| --- | --- |
| 9d9f78f | the brief rebased at cacc95b |
| 9ae53c8 | the brief amended: `stop_reason` joins the declaration family (ruling 3) |
| 6e3c902 | stage 0: D-316, the spec, the companions, `gloss_table.md`, `pending.md` |
| 0feb5d2 | two companion sentences stage 0 left: a stale `stop faces` and the walkthrough's `pol.hit` |
| 0624f37 | stage 1: `StopFlag`, `stop_reason` and its family membership, `Requester` and the roster, the two refusals, `STOP_FLAG_KEY`, `StopRequest` |
| a682407 | stage 2: the policy, `ignore_stop_requests`, `_stop_hit`, the record payload, `UnboundedRun`, `StopRequestInvalid`, `stop_on` retired |
| a9eaf1c | docs: the root-input refusal covers any root input carrying a `StopFlag`, bare or nested (ruling 14) |
| a038498 | the review fixes |
| 6b1f910 | the `StopFlag` docstring's one-word nit, landed by the coordinator |

## Rulings made

### The rebase (9d9f78f)

1. **Three anchors moved.** The two loose commits and the memory-to-docs
   move shifted `pending.md`'s "Stop candidates" to 93 to 104 and
   `src/diagnostics.jl` by three lines (`IllegalPortType` at 798 with its
   message at 807, `StopFaceInvalid` 1202 to 1223). Every other source,
   spec, log, companion and test anchor was recounted at cacc95b and holds,
   the 41 `stop_on` spec lines included.
2. **A peer session was live** (`redstone-jl-df`) and confirmed it edits
   nothing: a read-only design discussion. No serialization needed.

### Before stage 0's edits (the brief amendment)

3. **`stop_reason` joins the declaration family.** Stage 0 stopped before
   editing: the brief called `stop_reason` an optional declaration without
   saying whether §8.1's import list and D-246's shadowing check cover it.
   The spec's own rule decides it. §8.1 says the check runs on every
   component because an optional declaration has no absence to notice and,
   shadowed, drops its feature silently; `condition` stays outside only
   because a foreign `condition` fails loudly (`src/conditions.jl` 55 to 63).
   A foreign `stop_reason` would silently read `""`, the case D-246 exists
   for. Hence (a): §8.1's list gains it, `DECLARATION_FAMILY` and
   `_OTHER_FAMILY` gain it, and stage 1 adds a `ForgottenImport` arm. The
   default method `stop_reason(::Any)` is excluded by `_declares`'s `!== Any`
   test, so `declarations_found` needs no change. Recorded in the brief.
4. **Stage 0's other findings, disposed:** §8.2 line 2356 reworded (a
   `StopFlag` input is a second piece of framework vocabulary `u_types`
   admits); §13.6 needs no edit; every `stop_on` hit the brief did not list
   is treated under the brief's "treat every hit"; log entries beyond the
   brief's six (D-081 … D-290, D-268 included) stay unannotated under
   `decisions_style.md`'s rule 2, since D-268's rule carries over unchanged
   and the spec keeps citing it; §12.7's replay rewrite gains one sentence
   on replaying under the same `ignore_stop_requests`.

### After stage 0 (0feb5d2)

5. **Two companion sentences landed by the coordinator**, sentence-sized:
   `limited_integrator_variants.md` 261 ("stop faces" to "stop requests"),
   which stage 0 found outside its file list, and `frame_walkthrough.md`'s
   loop sketch, whose `pol.hit` had been stale since D-261 (`frame!` returns
   the hit). Battery green.
6. **Stage 0's D-316 does not list §9.7 in its Spec field**, since the
   per-eltype storage it rests on was not edited. Kept.

### Stage 1 (0624f37)

7. **Stage 1's four deviations accepted:** the block test uses a
   `requested(value, reason)` helper instead of `fed_by`, whose wire names
   `in`, not `request`; the `IllegalPortType` testset is retitled to cover
   its new arms; `StopRequest` joins the shadowing-check list and the
   fixtures row names the `ForgottenImport.Reason` submodule. The nested
   refusal sits in `place!`, so a root input whose struct nests a `StopFlag`
   is refused `:stop_flag_nested` at site `:root_input`, untested; handed to
   the reviewer as a probe.
8. **`docs/design/pdf/gallery/sample.jl` keeps `stop_on = :quiescence`.**
   It is a highlighting sample under `pdf/`, not code, and reports and
   gallery material stay untouched before the first release.

### Stage 2, before its edits

9. **`test/test_localization.jl` enters stage 2's file list.** Its lines
   226, 227 and 237 call `frame!` directly with `Any[]`, like
   `test_stepper.jl`; the brief missed it (a grep for `frame!(` across
   `test/` finds only those two files). Three lines, mirroring the stepper's.
10. **The `addrs` sweep is narrowed** to `src/sim.jl`, `src/localization.jl`,
    `test/test_stepper.jl` and `test/test_localization.jl`. The name is
    legitimate in `checkpoint.jl`, `dataplane.jl`'s `Writer`, `store.jl`'s
    gather and scatter, `trace.jl` and `build.jl`'s `output_addrs`, and
    "Naming" admits `addr`/`addrs`. The brief's reviewer dimension already
    scoped it so; the stage prompt had widened it by mistake.
11. **`_stop_hit` asserts the buffer `::Vector{StopFlag}`**, since
    `sim.plane.published.latest` is not concretely typed, with a site comment
    saying so; the honoured-requester `frame!` allocation test proves it.

### Stage 2 (a682407)

12. **Stage 2's deviations accepted:** the allocation-free scan asserts the
    snapshot's type (`latest(sim)::Snapshot{T,typeof(sim.exec.store)}`)
    rather than the buffer's, since the buffer form still allocated 80 B;
    `hooked_interrupted()` gains no `StopRequest` (it exports no face, and
    one fed from its trigger would stop before the hook fires), the
    honoured cases using a new `hooked_requested(c)`; all five fixture
    exports are dropped since no test reads a root face;
    `ModelRequestedStop(::Requester)` is a convenience constructor;
    `candidates` and the `:all` expansion deduplicate by path, so a
    component with two `StopFlag` ports is one path (handed to the reviewer
    against §13.5's text); two `UnboundedRun` literals in the kinds list.
13. **Handed to the reviewer, for the fix commit if confirmed:** `policy` is
    unread in `_stop_hit`, `frame!` and `_localized_frame!` (dead under
    D-261's placements?); the stale "a policy's addresses beside its faces"
    example in the artifact caveat; stage 1's untested nested-at-root case.

### The cold review (at a682407)

Gate green at a682407 (5507, Julia 1.13.1); battery green; the retirement
grep clean; 71 models in the alignment sweep, 6 requesters, no misalignment;
the no-lag probe agrees in every snapshot; `frame!` equals `publish!` on the
bouncer (800 B) and `requested_bouncer()` (944 B), `_stop_hit` 0 B. Thirteen
of fifteen mutants went red; M5a (`isempty` for `all` in `_stop_hit`'s early
return) is equivalent, M12 (`unique!` dropped) survived.

14. **Finding 1, a nested `StopFlag` at a root input, fixed as (a):** the
    root-input refusal covers any root input whose type carries a `StopFlag`
    leaf, since "a request is the model's, never an operator's" covers it;
    the nested reason's advice ("publish the flag as a port of its own") is
    wrong at that site. D-316's and §13.5's "declared `StopFlag`" clause is
    edited in place, docs-commit-first, then the code conforms.
15. **Finding 3, `policy` dead in `_stop_hit`, `_advance!`, `frame!` and
    `_localized_frame!`: dropped.** D-261's rule, a callee takes what it
    reads, decides it; `_run_body!` and `step!` keep it for the record. The
    brief's "renamed and retyped" settled the mask, not the policy's travel.
16. **Findings 2, 4 and 6 fixed as proposed:** a two-port fixture test that
    kills M12; the artifact caveat's example; `honoured_mask`.
17. **Finding 5 left for the user:** `ignore_stop_requests = "stop"` iterates
    characters (four `StopRequestInvalid`), and a `Symbol` other than `:all`
    is a raw `MethodError`. Pre-existing with `stop_on`; an API choice
    (refuse as `ArgumentInvalid`, or accept one `String` as one path).
18. **Out of scope, for the user:** under `Float32` the `Trigger` fixture
    never fires (`on` stays false while the ramp reaches 1.0). Not this
    increment's; uninvestigated.

### The fix (a9eaf1c, a038498)

19. **D-316 edited in place**, not annotated: the entry landed today in
    this unpushed arc, and the edit narrows one clause's wording.
    `decisions_style.md` rule 1 guards settled history.
20. **The fixer's deviations accepted:** a `mutable_position(cell_type) ===
    nothing` guard ahead of the `leaf_types` walk at the root-input check
    (the same guard `:handle_at_root` uses; a self-referencing mutable type
    would otherwise recurse, and a mutable carrier is still refused as
    `:mutable`); `StopPolicy` removed from `test/imports.jl` as unused once
    `no_policy` went; the walkthrough's section 2 sketch, stale since before
    this increment (`sim.policy.hit`), rewritten with the `pol` drop; one
    `_run_body!` comment that the drop made false.

### After verification (6b1f910)

21. **The reviewer's two nits:** the `StopFlag` docstring now says "a root
    input carrying one" (landed by the coordinator, gate green at 5517); the
    mutable guard's ordering stays untested, since a mutable root type that
    carries a flag is refused either way and the guard's real purpose is to
    keep `leaf_types` off a self-referencing mutable type.

## Verification summary

Routed subsets and gates: stage 1 whole suite 5488; stage 2 gate 5507; the
reviewer's gate at a682407 5507 (Julia 1.13.1); the fixer's gate at a038498
5517; the coordinator's gate at 6b1f910 5517. Docs battery green after every
docs edit. Fifteen mutants: thirteen red at a682407, one equivalent, the
survivor (M12) red after the fix; the reviewer's extra M7b red, M7c the
accepted gap above.

**What is left for you:** finding 5 (bare `String`/`Symbol` in
`ignore_stop_requests`), the `Float32` `Trigger` observation, the diff
review of the arc (9d9f78f..HEAD) and the push.
