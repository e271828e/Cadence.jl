# Brief: the source layout after the model split, `model.jl` and `frame.jl`

One code stage, no docs stage, no cold review: a move with no behaviour
change, gated by the full suite. Written at e631c3b on 2026-10-09; every
line number below is from `git show e631c3b:file`. The ruling it delivers
is the user's of 2026-10-09: the include order was forcing untyped
parameters wherever a function takes a `Model` or a `Simulation` from a
file loaded before those types exist, and the split calls for a model
layer between the executor layer and the runtime layer.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

- **The layout rule.** A file sits above `sim.jl` in the include order as
  soon as nothing in it names a `Simulation` in a signature, and below
  `model.jl` as soon as something in it names a `Model`. Every parameter
  that was untyped "for include order alone" becomes typed.
- **The order.** `src/Redstone.jl` 7 to 31 becomes:

  ```
  leaves, diagnostics, declare, assembly, store, executor, build, tracer,
  readers, deployment, dataplane, checkpoint, trace, roster, bindings,
  control, conditions, model, stepper, frame, sim, devices, trim,
  linearize, show, blocks
  ```

  `conditions.jl` moves up from after `sim.jl`; `model.jl` is new;
  `stepper.jl` moves below `model.jl`; `localization.jl` is renamed
  `frame.jl` and moves above `sim.jl`; `devices.jl` moves below `sim.jl`.
  Nothing else moves.
- **`model.jl` holds the model layer**, in this order: the `Model` struct
  with its docstring and three constructors (`sim.jl` 123 to 195); the
  status is written where it is today. `FrameHooks`, `NoHooks`,
  `frame_top!`, `settled!` and their docstring (`sim.jl` 1537 to 1566,
  the docstring's `LoopHooks` paragraph staying with `LoopHooks`). The
  model's doors: `init!`'s two methods and their docstring
  (`conditions.jl` 576 to 621), `apply!(model, plan)` (573),
  `phase_bodies` (494 to 495), `evaluate!` on the executor and the model
  (498 to 514), `boundary!`, `offtick_boundary!`, `boundary_zero!`,
  `_round!`, `event_phase!` (517 to 665), the stepper seam `integrate!`,
  `_check_finite!`, `_nonfinite` (666 to 730), `warnings` on the model
  (277 to 286), `port`, `state`, `modes` on the model (2357 to 2387, the
  model methods only). `_wrap_step` and `_species` (1700 to 1763). The
  model-level checkpoint functions `_fingerprint`, `_take_checkpoint` and
  `_restore_state!(model, cp)` (`checkpoint.jl` 55 to 113), typed
  `::Model`; the restore door takes `hooks::FrameHooks = NoHooks()`,
  restores the executor, calls `settled!(hooks)`, then writes
  `:consistent`, in `init!`'s shape, and `_enter_checkpoint!` (`sim.jl`
  939 to 967) opens the run and adjusts the boundary first, then calls
  `_restore_state!(sim.model, cp; hooks = LoopHooks(sim, sim.plane.roster,
  nothing, Bool[]))` in place of its own `publish!` and the earlier call.
  The file opens with a header comment in `checkpoint.jl` 1 to 6's form:
  what the layer is, and that every door writing the status lives here.
- **`frame.jl` is `localization.jl` renamed**, content unchanged except
  its header comment, which names the file as the frame with localization
  as its mechanism. `git mv`.
- **`sim.jl` keeps the runtime**: the sources, the policy, the record,
  `Run`, `Simulation` and its constructor and sugar, the forwarding methods
  of every model door (one line each, left where they are), the
  validators, `lifecycle`, `_stop_hit`, `_assert_advanceable`,
  `_reset_periphery!`, the simulation's doors, the loop, `LoopHooks`
  (1567 to 1580 with its docstring paragraph), the roster, the drain, the
  publication, the accessors. `assert_stopped` and `assert_configurable`
  (`control.jl` 112 to 135) move to `sim.jl` beside `_assert_advanceable`
  (469), typed `sim::Simulation`; their docstring comes with them.
- **`conditions.jl` keeps the plans.** Lines 573 to 621 leave it (the
  `apply!(sim, plan)` forwarding method goes to `sim.jl` beside the other
  forwarding methods). Its header and its `# --- the dynamic walk` section
  comment (542) lose any sentence about the model's `init!`.
- **`checkpoint.jl` keeps the value.** `Fingerprint`, `Checkpoint`,
  `_restore_state!(exec, cp)`, `_restore_stores!`, the copy for the trace,
  `_check_checkpoint!` and `_check_addresses!`. `_check_checkpoint!` keeps
  its `sim` untyped, since the file still precedes `sim.jl`, and a comment
  at the site says so. The header comment (1 to 6) loses "`sim` and
  `model` are untyped throughout" and says where the model-level functions
  went.
- **`stepper.jl`**: `integrate!(stepper::RK4, model::Model, h)` and the
  `Heun` method (62, 98) typed; the comments at 7 and 16 name `model.jl`.
- **`devices.jl`**: `_init_devices!`, `_finish!`, `_tail!`,
  `_report_join_timeout!`, `_sweep_tail!` (465 to 602) typed
  `sim::Simulation`; the header comment (6 to 17) loses "take `sim` untyped
  for include order" and says the file follows `sim.jl`. `control.jl`'s
  header (6 to 7) and `assert_*` docstring (120) are rewritten for the
  move.
- **Every file-name citation follows the construct.** The grep
  `localization\.jl|conditions\.jl|checkpoint\.jl|sim\.jl|control\.jl|stepper\.jl|devices\.jl`
  over `src/` and `docs/design/implementation.md` lists every site; each
  that names a construct this brief moves is rewritten (`sim.jl` 578 and
  1704 name `conditions.jl` and `localization.jl` for `init!` and
  `frame!`; `executor.jl` 11 names `sim.jl` for `_wrap_step`;
  `stepper.jl` 16; `checkpoint.jl` 106; `control.jl` 120; `devices.jl`
  17). A citation of a construct that does not move stands.
- **Verified before writing.** `model.jl` and `frame.jl` exist nowhere
  under `src/` or `test/`. No test includes a source file by name;
  `test/RedstoneTests.jl` includes test files only, and `test_localization.jl`
  keeps its name, the test tree being cut by property. `test/imports.jl`
  imports names, not files, and no name changes.

## Out of scope

- Any behaviour change. The suite is the proof: every assertion passes
  unchanged, and the count is e631c3b's.
- D-318, the claim on the model; it lands after this commit.
- `trim.jl` and `linearize.jl` above `sim.jl`: increment two, when they
  take a model.
- A `test_frame.jl` or any test rename.

## Reading, in order

- `src/Redstone.jl` whole. `docs/design/implementation.md`: "What is real
  here" head (11 to 42), the rows `### src/Redstone.jl` (43 to 47),
  `### src/checkpoint.jl` (224 to 247), `### src/conditions.jl` (248 to
  267), `### src/control.jl` (268 to 304), `### src/devices.jl` (387 to
  430), `### src/localization.jl` (555 to 570), `### src/sim.jl` (657 to
  708), `### src/stepper.jl` (709 to 716); "Authoring caveats" (821 to
  956), "Naming" (957 to 1037), "Running the suite" (1038 to 1111).
- `src/sim.jl` 1 to 320, 490 to 740, 930 to 970, 1535 to 1600, 1700 to
  1765, 2355 to 2387. `src/conditions.jl` 1 to 20 and 540 to 625.
  `src/checkpoint.jl` whole. `src/control.jl` 1 to 20 and 110 to 142.
  `src/devices.jl` 1 to 25 and 440 to 605. `src/stepper.jl` 1 to 20 and
  55 to 110. `src/localization.jl` 1 to 40.

## The stage

### The shape

As settled above. Move by cut and paste, never retype: `git show
e631c3b:file` is the baseline and `diff` of the concatenated moved blocks
against it is the check that no line changed but the typed signatures and
the comments named above. Docstrings move with their functions. Section
comments (`# --- … ---`) move with their sections.

### Tests

None added, none changed. The suite is the gate.

### Routing

`sim.jl` is touched: all of it, under the flags, in the foreground, 600 s.
The count equals e631c3b's 5904 of 5904.

### Bookkeeping, in the same commit

- `docs/design/implementation.md`: the `### src/Redstone.jl` row's include
  order; a new `### src/model.jl` row in alphabetical place (after
  `### src/linearize.jl`), naming the constructs it holds and the layout
  rule, citing §9.2, §12.6, §13.4, D-317; `### src/localization.jl`
  becomes `### src/frame.jl` in alphabetical place (after
  `### src/executor.jl`), its lines unchanged but for the rename; the
  `### src/sim.jl`, `### src/conditions.jl`, `### src/checkpoint.jl`,
  `### src/control.jl`, `### src/stepper.jl`, `### src/devices.jl` rows
  lose the constructs that left and say where they went. Constructs, not
  behaviour. The authoring caveats are re-read for a file name.
- No spec, log or pending edit: the spec names constructs, never files.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. Grep every new name across `test/`
before defining it. Report: the commit hash, the files touched, the suite's
result with the assertion count against 5904, the diff check of the moved
blocks against the baseline, every typed parameter, every rewritten
citation, and every deviation from this brief with its reason.
