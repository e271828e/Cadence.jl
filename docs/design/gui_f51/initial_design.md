# The graphical layer: initial design

The first design session for the graphical layer over Cadence, held
2026-09-28 under the `initial-design` procedure. Its purpose was to constrain
the problem until it split into axes that later sessions address one at a
time. This document is not normative. Rulings that touch the framework land
in `spec.md` and `decisions.md` first, as usual, and the spec wins wherever
the two disagree. The separate design under `inspector/` is unrelated and
was kept out of view.

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

- The liveness table's form. Per input port in the tree: the resolved root
  input face, the owning roster entry, the verdict. Whether a device receives
  the whole table or only the rows under its own claim.
- The partition accessor: how a device learns which faces every entry claims,
  and the per-entry task liveness of §12.2 for the orphan label.
- The log-tail view: a per-frame copy of the reference vector, or a bounded
  tail accessor. Its torn-free guarantee against the loop's append and
  compaction (§11.2).
- Whether the compiled `Reader` of §14.4 is the right per-snapshot extractor
  for a device, and what it costs to hold one per plotted path.
- The spec home for each addition: §11.6 for the handle, §11.7 for the baked
  resolution, §11.2 for the log view.

### Axis 2: the built-in GUI

- Attachment: `gui = true` as the run-scoped sugar (Appendix B) against an
  explicit `attach!`; the greedy complement as the default claim;
  `should_abort = true` as the spec states.
- Launch: the main-thread constraint, the render loop's frame rate and its
  interaction with the pacer (§10.7).
- The run-control panel: pause, resume, stop, pace; whether partial advance
  (§12.6) is exposed as a step control.
- The path tree's status marks: orphaned inputs, dead device tasks, build and
  deployment warnings, diagnostic counters (§11.8).
- The raw-view affordance: an entry in the tree per node, or a toggle in the
  chrome around each panel.
- Discovery of authored panels: the method's name and signature, on the
  component type, subject to the exported-name audit in `pending.md`.
- The generic renderer's editable-type set (numbers, Booleans, enums, ranged
  values) and the recursive field walk with its `show` fallback for leaves it
  does not understand.
- The per-node store's lifetime: per run, per session, or persisted.
- The plot widget: window, decimation display, the sparse-log and log-off
  states, ImPlot as a second weak dependency.
- Whether FlightApps panels are worth porting as a test of the convention.
  Migration is not a priority (memory, 2026-09-23).

### Axis 3: the descriptor and the static inspector

- The schema: nodes with class and path; faces with printed type and kind
  marker; wires; the two-sided face table; the anchor and component tables in
  rational form; the execution order with port classes; state events; build
  warnings; face routes once §13.7's routing chain is retained (`pending.md`,
  M-B26), which this axis may pull forward.
- The deployment overlay: the `Schedule` rows, the hyperperiod, the grid
  diagnostics.
- The kind-marker taxonomy: number, Boolean, enum, struct with named fields,
  opaque. Function-valued signals (§4.4) are opaque.
- Instance data: the opt-in rendering per node, and the guard against a
  `show` that is not cheap and finite.
- Versioning, and the JSON writer dependency in core.
- The entry point: a function that writes the descriptor to disk and opens
  the page on it.
- The inspector's navigation: one assembly level at a time, the interface
  connections drawn at the frame's edge.
- Automatic layout: the layered-layout engine (the Eclipse Layout Kernel's
  JavaScript build is the candidate), and the layout sidecar keyed by path
  for user nudges.
- Overlays: feedthrough chains (§5.6), algebraic-loop cycles (§5.5),
  execution order, rate scopes as regions, face routes.
- Packaging of the page: a single HTML file or a built application; where
  it lives in the repo.
- The clipboard bridge: copy the canonical path on click; the "go to path"
  field in the built-in GUI's tree.

### Axis 4: the wire device

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
- The live inspector, or a full external GUI: the static inspector's
  rendering code as the seed of a client of the wire device, with values on
  wires, boundary highlighting, and click-to-open across tools.

## Answered questions

**Q1. What is the layer for?** Runtime cockpit (A) and model viewer (B) now.
The analysis view (D) is open but deferred. A model editor (C) is out for
good: it would be a second source of truth for structure, against the
plain-Julia, no-DSL criterion of §8.1.

**Q2. Where does it sit?** Reopened twice and settled as four pieces, in
working order:

1. The handle surface: descriptor export, run-start facts (partition,
   liveness table), log-tail view. Spec work, the earliest deadline.
2. The built-in GUI, first because building it discovers the handle's gaps
   concretely and settles the panel-authoring convention §11.7 deferred.
3. The descriptor and its static inspector: a browser page over a
   serialized `Build`, no runtime data.
4. The wire device: an ordinary device hosting the handle serialized, so an
   external GUI can be built on it. The framework ships the server and the
   protocol document, and no client.

The principle recorded with it: *the handle is the only source of GUI
semantics; a transport adds nothing and removes nothing.* A feature any GUI
needs that the handle lacks is added to the handle first, for every client.
The built-in GUI reaches the framework through the handle and nothing else,
though it ships in the same repo, and its stage briefs carry that rule.

The interface splits into a static half (the descriptor, designed now
against immutable artifacts) and a runtime half (the handle serialized,
designed after the built-in GUI fixes the handle's shape). The descriptor is
designed for the inspector with three properties that make it reusable by a
runtime client at no cost: every addressable thing carries its canonical
path; every face carries a kind marker beside its printed type; the document
is versioned.

The static inspector cannot open or close anything in the built-in GUI.
Coupling between them is the path vocabulary of §8.6 and the clipboard
bridge. Click-to-open across tools waits for the live inspector.

**Q3. Rendering library for the built-in GUI?** CImGui.jl with ImPlot. The
peek-and-stage contract of §11.7 is an immediate-mode contract, one call per
widget per frame; retained mode would hold a second copy of the state the
framework avoids holding. Makie stays the right tool for the deferred
analysis view.

**Q4. What does zero panel authoring give?** A generic panel derived from
the declarations, shown for every component without an authored method and
also callable from an authored panel that wants to embed it. The author
decides where the raw view appears. Two consequences: a recursive field walk
with a `show` fallback, and framework widgets that honour the staging
contract in one tested place. A guaranteed raw view for authored components
is an open affordance under Axis 2.

**Q5. What does the descriptor describe?** The whole `Build`: structure plus
the derived facts (execution order, port classes, events, warnings, routes
once retained), with the `Deployment`'s schedule as an optional overlay.
`describe(build)` yields the core, `describe(deployment)` the core plus the
overlay. Types as printed strings, never a type system. Instance data
opt-in. Structure-only was rejected because it pushes the viewer into
re-deriving what the build computes.

**Q6. Window organization?** One dockable workspace with a path tree that
mirrors the assembly by canonical path. Selecting a node opens its panel in
the docking area. Framework panels, few and fixed: run control, device roster
with liveness, diagnostics log, build warnings. Authored panels are content
inside a dock node the framework owns and never open windows of their own.

**Q7. What does a panel author write against?** A context with two layers:
public primitives (`is_live`, `source`, `peek`, `stage!`, `read`) and a
widget vocabulary built on them, in which the generic renderer is also
written so authored and generic panels share one look and one liveness
handling. Panels name their own faces by face-name string. Two more context
contents settled: a per-node store keyed by path for state that outlives a
frame (plot buffers, a map's zoom), and `child!(ctx, :name)`, which draws
a child's panel, authored or generic, under a context scoped to the child's
path. Assembly authors never receive child instances.

**Q8. Where do cockpit plots get their history?** From the framework's log.
A plot walks a torn-free view of the log's tail and extracts its path per
snapshot with a compiled reader. Boundary-rate fidelity, no copies inside the
GUI, honest pause, and the same source the analysis view would use after the
run. The plot says so when the log is off or the window is sparse. The
log-tail view is a handle addition, and the same query the wire's history
message would carry.

**Q9. Where do the pieces live?** Core plus package extensions. The
descriptor export in core with a small JSON writer. The built-in GUI as an
extension activated by CImGui, the wire device as one activated by the HTTP
package. `gui = true` with the extension absent fails with a diagnostic
naming the package to load. The inspector's page is a static asset in the
repo with no Julia dependency. The wire device attaches like any device.
Separate packages were rejected as three repos to version together; a single
package with hard dependencies was rejected for batch users.

## Design axes

Four axes, in working order, plus the deferred set. Coupling is named where
it exists; the rest is independent.

1. **The handle surface.** What §11.6's handle must grow so that a client
   built on it alone is complete: run-start facts and the log-tail view, plus
   the descriptor export in core. Couples to every other axis as their sole
   source of semantics, so it is worked as each need appears, not in
   advance.
2. **The built-in GUI.** CImGui, the dockable workspace, the path tree, the
   generic renderer, the panel context and authoring convention, plots over
   the log. Couples to axis 1 by the needs it discovers, and to axis 3 by
   the path vocabulary and the "go to path" field.
3. **The descriptor and the static inspector.** The schema, the overlay, the
   page, its layout and overlays. Couples to axis 1 through the export
   function, and to axis 4 as the connect payload it will reuse unchanged.
4. **The wire device.** The handle serialized, subscriptions, the protocol
   document. Waits on axes 1 and 3. Couples to nothing else once they
   exist.
5. **Deferred.** The analysis view and the live inspector. Neither is
   scheduled; both are reachable from the axes above without reopening them.

## Glossary

- **Authored panel.** A component's own panel, given by a method on its
  type, written against the panel context.
- **Built-in GUI.** The CImGui runtime GUI shipped as a package extension,
  a client of the handle and nothing else.
- **Clipboard bridge.** The inspector copies a node's canonical path on
  click; the built-in GUI's tree accepts a pasted path in a "go to path"
  field. The only link between the two tools before a live inspector.
- **Deployment overlay.** The optional descriptor section a `Deployment`
  adds: the schedule rows, the hyperperiod, the grid diagnostics.
- **Descriptor.** The serialized `Build`, `show`'s structured sibling: a
  versioned, language-neutral document with every addressable thing under
  its canonical path. The static half of the interface.
- **Generic panel.** The panel the framework derives from a component's
  declarations when no authored method exists; also callable from an
  authored panel.
- **Handle-only rule.** The built-in GUI reaches the framework through the
  device handle alone, so that what it needs is what every client needs.
- **Handle surface.** The set of primitives and run-start facts a device
  receives through its handle; axis 1's subject.
- **Inspector (static).** The browser page over a descriptor. Reads no
  runtime data.
- **Kind marker.** A small tag per face beside its printed Julia type
  (number, Boolean, enum, struct with named fields, opaque) so a client with
  no Julia can choose a widget.
- **Layout sidecar.** A file keyed by path that persists a user's box
  positions in the inspector. Presentation state, never model state.
- **Liveness table.** The run-start fact, baked once, that maps every input
  port to its resolved root input face, the owning roster entry, and the
  live-or-read-only verdict of §11.7.
- **Live inspector.** The deferred inspector that connects to the wire
  device and shows runtime data on the diagram.
- **One-level rule.** The inspector renders one assembly level at a time,
  with interface connections at the frame's edge, never the whole model on
  one canvas.
- **Panel context.** The framework-supplied object a panel draws against:
  primitives, widget vocabulary, per-node store, child composition.
- **Path tree.** The built-in GUI's navigator, mirroring the assembly by
  canonical path; also the home of status marks and of the raw view.
- **Per-node store.** State a panel keeps between frames, keyed by the
  node's path and owned by the GUI, in place of globals or `@cstatic`.
- **Primitives.** The context's public verbs: `is_live`, `source`, `peek`,
  `stage!`, `read`.
- **Raw view.** The generic panel shown for a component that has an
  authored panel, for debugging.
- **Runtime half.** The interface part that depends on the handle's final
  shape: run-start facts, subscriptions, staging, control, history queries.
- **Static half.** The interface part fixed by immutable artifacts: the
  descriptor and its overlay.
- **Subscription.** A wire client's declaration of the paths it displays
  and the rate it wants them at, so bandwidth scales with the screen, not
  the model.
- **Widget vocabulary.** The framework's widgets built on the primitives,
  each honouring liveness, source labels and the staging contract.
- **Wire device.** An ordinary device hosting the handle serialized over a
  socket, shipped without a client.
- **Workspace.** The built-in GUI's single dockable window.
