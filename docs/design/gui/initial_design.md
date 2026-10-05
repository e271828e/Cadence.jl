# The built-in GUI: initial design

The first design session for the graphical layer over Cadence, held
2026-09-28 under the `initial-design` procedure. Its purpose was to constrain
the problem until it split into axes that later sessions address one at a
time. This document is not normative. Rulings that touch the framework land
in `spec.md` and `decisions.md` first, as usual, and the spec wins wherever
the two disagree. The session covered the whole graphical layer. Its
inspector material has since moved to
`docs/design/inspector/initial_design.md`, and this record keeps the
built-in GUI and the wire device.

Where the spec already rules, the ruling was taken as a fixed constraint.
The relevant ones are §11.7 (derived liveness, own-pending-else-snapshot
peek, stage-on-interaction, the orphan display, the four constraints on the
panel-authoring convention), §11.6 (the GUI is an ordinary device with the
same handle as every other), §11.2 (the log as retained snapshots under a
bound) and §9.2 (the `Build` and the `Deployment` as immutable, printable
artifacts).

## Pending questions

Filed by axis. Each later session picks an axis and works its list; a
question that turns out to cut across axes comes back to this file.

### Axis 1: the handle surface

The run-start facts were fixed and built the same day as this session
(D-270, 2026-09-28): the liveness table is the port-view table of
`port_views(handle)`, one view per port of every component, and the
incumbent writer with its task state comes from the view and
`incumbent_status`. Their spec home is §11.7 and Appendix B. The bake was
measured on 2026-10-05: about 50 ms to compile once per handle type, which
the GUI package can precompile, and a quarter of a microsecond and 700
bytes per view to build, so a few thousand ports bake in under a
millisecond once per run. What remains:

- The log-tail view: a per-frame copy of the reference vector, or a bounded
  tail accessor. Its torn-free guarantee against the loop's append and
  compaction (§11.2).
- Whether the compiled `Reader` of §14.4 is the right per-snapshot extractor
  for a device, and what it costs to hold one per plotted path.
- The spec home for the log view, §11.2.

### Axis 2: the built-in GUI

- Attachment: `gui = true` as the run-scoped sugar (Appendix B) against an
  explicit `attach!`; the greedy complement as the default claim;
  `should_abort = true` as the spec states.
- Launch: the render loop's frame rate and its interaction with the pacer
  (§10.7). The thread requirement is settled as the GUI's own, not the
  trait's: `needs_calling_task` guarantees the task, and the GUI's `init!`
  checks that the task runs on thread 1 and is sticky, throwing the
  package's own diagnostic otherwise. The two checks differ in origin, the
  same thread for the OpenGL context on every platform, the main thread for
  Cocoa on macOS, generalized by GLFW's contract.
- The run-control panel: pause, resume, stop, pace; whether partial advance
  (§12.6) is exposed as a step control.
- The path tree's status marks: orphaned inputs, dead device tasks, build and
  deployment warnings, diagnostic counters (§11.8).
- The "go to path" field in the path tree, the GUI's end of the clipboard
  bridge with the inspector.
- The raw-view affordance: an entry in the tree per node, or a toggle in the
  chrome around each panel.
- Discovery of authored panels: the method's name and signature, on the
  component type, subject to the exported-name audit in `pending.md`.
- The generic renderer's editable-type set (numbers, Booleans, enums, ranged
  values) and the recursive field walk with its `show` fallback for leaves it
  does not understand.
- The per-node store's lifetime: per run, per session, or persisted.
- The plot widget: window, decimation display, the sparse-log and log-off
  states, and whether `CImGui.lib`'s raw ImPlot bindings suffice or the
  package writes a thin layer over them. CImGuiPack_jll bundles ImPlot, so
  no second dependency is needed, but CImGui.jl v7 wraps none of it and
  ImPlot.jl's compatibility with v7 is unverified.
- Whether FlightApps panels are worth porting as a test of the convention.
  Migration is not a priority (memory, 2026-09-23).

### Axis 3: the wire device

- The message set, one per handle primitive: descriptor and run-start facts
  on connect, subscribe and unsubscribe, values, stage, report, control,
  history query over the log tail.
- The subscription rate model: per-subscription rate, latest-snapshot
  sampling against log-tail delivery.
- Serialization of snapshot values: the field walk for custom structs,
  opaque leaves, the eltype.
- Several clients at once with disjoint claims (§11.6), and one client with
  several browsers.
- Transport and security assumptions: local socket first, nothing else
  promised.
- The protocol document's home and its versioning against the descriptor's.
- The rule that no client ships with the framework, and how it is kept.

### Deferred

- The analysis view: plots over the log after a run, trace scrubbing, replay
  controls, run comparison. Open, not scheduled.

## Answered questions

**Q1. What is the layer for?** Runtime cockpit (A) and model viewer (B) now.
The model viewer is the inspector, designed in
`docs/design/inspector/initial_design.md`. The analysis view (D) is open but
deferred. A model editor (C) is out for good: it would be a second source of
truth for structure, against the plain-Julia, no-DSL criterion of §8.1.

**Q2. Where does it sit?** Reopened twice and settled as four pieces, in
working order:

1. The handle surface: run-start facts (partition, liveness table), since
   fixed by D-270, and the log-tail view, still spec work.
2. The built-in GUI, first because building it discovers the handle's gaps
   concretely and settles the panel-authoring convention §11.7 deferred.
3. The descriptor and its static inspector: a browser page over a
   serialized `Build`, no runtime data. Designed in
   `docs/design/inspector/initial_design.md`.
4. The wire device: an ordinary device hosting the handle serialized, so an
   external GUI can be built on it. The framework ships the server and the
   protocol document, and no client.

The principle recorded with it: *the handle is the only source of GUI
semantics; a transport adds nothing and removes nothing.* A feature any GUI
needs that the handle lacks is added to the handle first, for every client.
The built-in GUI reaches the framework through the handle and nothing else,
though it ships in the same repo, and its stage briefs carry that rule.

The wire device's runtime half, the handle serialized, is designed after the
built-in GUI fixes the handle's shape. The descriptor it sends on connect is
the inspector's, reused unchanged.

The static inspector cannot open or close anything in the built-in GUI.
Coupling between them is the path vocabulary of §8.6 and the clipboard
bridge. Click-to-open across tools waits for the live inspector.

**Q3. Rendering library for the built-in GUI?** Dear ImGui through
CImGui.jl, with ImPlot, which CImGuiPack_jll bundles with imgui and
imnodes. The peek-and-stage contract of §11.7 is an immediate-mode
contract, one call per widget per frame; retained mode would hold a second
copy of the state the framework avoids holding. Makie stays the right tool
for the deferred analysis view.

Settled 2026-10-05: the GUI uses CImGui.jl's bindings only, `CImGui.lib`
and the wrappers over the pack, and owns its loop. `init!` creates the
context and the window, turns VSync on and initialises the GLFW and
OpenGL3 backends. `loop` runs one frame per iteration, `PollEvents`, the
three `NewFrame` calls, the panels, `Render`, the draw and the swap, and
returns when the window closes or `running(handle)` turns false.
`shutdown!` reverses `init!`. CImGui.jl's `render` loop and its task
pinning are not used, since the framework owns the task, and `WaitEvents`
is never called, since §12.4 forbids a loop body that blocks between
`running` checks. The backend functions are Dear ImGui's own C API, which
survived CImGui.jl's v1 to v2 break unchanged; a compat bound and one glue
file hold the remaining risk. The one serious alternative is a browser
cockpit over the wire device, which would lift the main-thread constraint
and the OpenGL dependency at the cost of panel authoring in Julia. It stays
behind the built-in GUI, as the live inspector.

**Q4. What does zero panel authoring give?** A generic panel derived from
the declarations, shown for every component without an authored method and
also callable from an authored panel that wants to embed it. The author
decides where the raw view appears. Two consequences: a recursive field walk
with a `show` fallback, and framework widgets that honour the staging
contract in one tested place. A guaranteed raw view for authored components
is an open affordance under Axis 2.

**Q5. Window organization?** One dockable workspace with a path tree that
mirrors the assembly by canonical path. Selecting a node opens its panel in
the docking area. Framework panels, few and fixed: run control, device roster
with liveness, diagnostics log, build warnings. Authored panels are content
inside a dock node the framework owns and never open windows of their own.

**Q6. What does a panel author write against?** A context with two layers:
public primitives (`is_live`, `source`, `peek`, `stage!`), keyed by face
name and resolved through D-270's port view, and a widget vocabulary built
on them, in which the generic renderer is also written so authored and
generic panels share one look and one liveness handling. Panels name their
own faces by face-name string.

Settled 2026-10-05: the context holds its path, the whole port-view table
by reference, the handle and the snapshot, and every verb looks its face up
under the context's path. `peek(ctx, face)` is a method of the framework's
`peek`, so one verb has one meaning across both halves. A `read` verb was
dropped, because D-270 gives output ports views of their own and a read on
an output face is the same lookup. `stage!(ctx, face => v)` resolves the
port through its view and throws on a port that is not live. The verbs are
the whole authoring API, and the handle and the table stay unexported. That
is what keeps a panel on its own ports: a panel that reaches the handle
writes a root input inside the GUI's claim, and the framework cannot tell
two panels apart.

Two more context contents settled: a per-node store keyed by path for
state that outlives a frame (plot buffers, a map's zoom), and
`child!(ctx, :name)`, which draws a child's panel, authored or generic,
under a context scoped to the child's path, the same table under a longer
path and nothing else. Assembly authors never receive child instances.

**Q7. Where do cockpit plots get their history?** From the framework's log.
A plot walks a torn-free view of the log's tail and extracts its path per
snapshot with a compiled reader. Boundary-rate fidelity, no copies inside the
GUI, honest pause, and the same source the analysis view would use after the
run. The plot says so when the log is off or the window is sparse. The
log-tail view is a handle addition, and the same query the wire's history
message would carry.

**Q8. Where do the pieces live?** Core plus package extensions. The
built-in GUI as an extension activated by CImGui, the wire device as one
activated by the HTTP package. `gui = true` with the extension absent fails
with a diagnostic naming the package to load. The wire device attaches like
any device. Separate packages were rejected as several repos to version
together; a single package with hard dependencies was rejected for batch
users.

## Design axes

Three axes, in working order, plus the deferred set. Coupling is named where
it exists; the rest is independent.

1. **The handle surface.** What §11.6's handle must grow so that a client
   built on it alone is complete: the run-start facts, fixed by D-270, and
   the log-tail view. Couples to every other axis as their sole source of
   semantics, so it is worked as each need appears, not in advance.
2. **The built-in GUI.** CImGui, the dockable workspace, the path tree, the
   generic renderer, the panel context and authoring convention, plots over
   the log. Couples to axis 1 by the needs it discovers, and to the inspector
   by the path vocabulary and the "go to path" field.
3. **The wire device.** The handle serialized, subscriptions, the protocol
   document. Waits on axis 1 and on the inspector's descriptor. Couples to
   nothing else once they exist.
4. **Deferred.** The analysis view. Not scheduled; reachable from the axes
   above without reopening them.

## Glossary

- **Authored panel.** A component's own panel, given by a method on its
  type, written against the panel context.
- **Built-in GUI.** The CImGui runtime GUI shipped as a package extension,
  a client of the handle and nothing else.
- **Clipboard bridge.** The inspector copies a node's canonical path on
  click; the built-in GUI's tree accepts a pasted path in a "go to path"
  field. The only link between the two tools before a live inspector.
- **Descriptor.** The serialized `Build` the inspector reads, designed in
  `docs/design/inspector/initial_design.md`; the wire device's connect payload.
- **Generic panel.** The panel the framework derives from a component's
  declarations when no authored method exists; also callable from an
  authored panel.
- **Handle-only rule.** The built-in GUI reaches the framework through the
  device handle alone, so that what it needs is what every client needs.
- **Handle surface.** The set of primitives and run-start facts a device
  receives through its handle; axis 1's subject.
- **Liveness table.** The port-view table of D-270, baked once at run
  start: one view per port of every component, with its terminal producer,
  the live-or-read-only verdict of §11.7, its staging slot and its incumbent
  writer.
- **Panel context.** The framework-supplied object a panel draws against:
  primitives, widget vocabulary, per-node store, child composition.
- **Path tree.** The built-in GUI's navigator, mirroring the assembly by
  canonical path; also the home of status marks and of the raw view.
- **Per-node store.** State a panel keeps between frames, keyed by the
  node's path and owned by the GUI, in place of globals or `@cstatic`.
- **Primitives.** The context's public verbs: `is_live`, `source`, `peek`,
  `stage!`. Face-keyed methods over D-270's port-view reads; `peek` and
  `stage!` are the framework's own functions with a context method.
- **Raw view.** The generic panel shown for a component that has an
  authored panel, for debugging.
- **Runtime half.** The wire device's part of the external interface, the
  handle serialized: run-start facts, subscriptions, staging, control,
  history queries.
- **Subscription.** A wire client's declaration of the paths it displays
  and the rate it wants them at, so bandwidth scales with the screen, not
  the model.
- **Widget vocabulary.** The framework's widgets built on the primitives,
  each honouring liveness, source labels and the staging contract.
- **Wire device.** An ordinary device hosting the handle serialized over a
  socket, shipped without a client.
- **Workspace.** The built-in GUI's single dockable window.
