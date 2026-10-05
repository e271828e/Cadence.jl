# The inspector: initial design

One browser client over a Cadence model, grown in four stages. It starts
as a static page that explains a model from serialized descriptors of a
`Build` or a `Deployment`, gains a wire to a running simulation, shows the
run on the diagram, and ends as an interactive cockpit with panels over
the wire. This document records the questions that narrow the solution
space, the answers, and the axes left for later sessions, stage by stage.
It is not normative. Rulings that touch the framework land in `spec.md` and
`decisions.md` first, and the spec wins wherever the two disagree.

Two sessions on 2026-09-28 fed it: one on the inspector alone, whose
answers stage 1 keeps whole, and one on the whole graphical layer, whose
wire device and panel material stages 2 to 4 keep. An earlier inspector
proposal, deleted in commit 084d6f0, was left out of both. The built-in
Julia GUI the second session designed was parked on 2026-10-05 (D-310).
Its reasons are in that entry, and its record last stands at commit
b6f08b1.

## Scope

- **One client, two sources.** The descriptor, a serialized projection of
  an immutable artifact, and the wire device, an ordinary device serving
  the handle over a socket. Everything the client knows comes from one of
  the two.
- **Four stages, in working order.** The static inspector, the wire
  device, the live inspector, the cockpit. Each is a visible result, and
  nothing built for one is discarded by the next.
- **No graphical authoring, ever.** The client never writes model
  structure, whether by code generation or by round-trip editing. Julia
  source stays the only model, as §8.1 requires. A model editor is out for
  good: it would be a second source of truth for structure.
- **Independence.** The core never depends on the client. What the core
  gains is `describe`, the carrier change and, with stage 2, the handle's
  control verbs.
- **The handle-only rule.** The wire device reaches the framework through
  the device handle and nothing else, so what it needs is what every client
  needs. A feature any front end needs that the handle lacks is added to
  the handle first.
- **Parked.** The built-in Julia GUI (D-310). The analysis view, plots over
  the log after a run with trace scrubbing and run comparison, is open and
  not scheduled, and Makie stays the right tool for it.

## Stage 1: the static inspector

### Answered questions

1. **Scope: the static page.** A browser inspector that reads serialized
   `Build` and `Deployment` descriptors and helps a user understand a model,
   with no runtime data. Stages 2 to 4 add the runtime data over the wire;
   nothing in this stage depends on them.
2. **No graphical authoring, ever.** The inspector never writes model
   structure, whether by one-way code generation or by round-trip editing.
   Julia source stays the only model, as §8.1 requires.
3. **Independence.** The core never depends on the inspector. This was agreed
   before the scope split, and question 8 revisits the package boundaries.
4. **Descriptor constraints owed to the wire.** The wire device reuses the
   descriptor as its connect payload, so the descriptor keeps three
   properties:
   - canonical addressing, with components named by slash path and faces by
     face name (§8.6);
   - transport independence, as a self-contained document that works as a
     file or as a message;
   - additive versioning, so that later stages can add a value type schema
     without breaking the inspector.
5. **Descriptor content: the artifacts' facts plus instance context.** A
   descriptor carries, as data, everything `show` prints for its artifact:
   the component tree, faces with value types and tiers, wires, root inputs,
   the execution order with port classes, and the timing tables. Each
   component adds three things: its type's docstring, the source location of
   its declaration methods, and a parameter summary. Internals such as
   initial states, cell layouts and compiled forms stay out.
   There are two kinds. A build descriptor projects a `Build`. A deployment
   descriptor projects a `Deployment` and embeds the build descriptor it
   deploys, as answer 7 requires. With a build descriptor alone the
   inspector shows anchor-relative timing; a deployment descriptor adds
   concrete `Δt` values and the hyperperiod chart.
   *Why:* understanding a model means knowing what its parts are, how they
   are configured and where they are defined, not only how they are wired.
   Parameter summaries stay display text, so the descriptor never promises a
   serialization of arbitrary Julia values. Internals would turn every
   implementation change into a descriptor change.
6. **Failed builds: the last complete step's artifact plus the
   diagnostics.** When the structure step passes and the nominal evaluation
   fails, the failure carries the complete `Structure` beside the
   diagnostics. The inspector then draws the whole diagram and marks the
   error on it: an algebraic loop's wires, or the block whose code threw
   while being probed. When the structure step fails, only the diagnostics
   remain, shown as a list grouped by path. The core change this needs is
   that the build's carrier exception holds the last clean artifact.
   *Why:* it covers the failures a picture explains best, and it carries a
   complete artifact from an earlier step, never a partial one, so it keeps
   §13.1's rule. Drawing structure-step failures would mean carrying a
   partial `Structure` past the barrier, which §13.1 rejects. Revisiting that
   is a separate decision against §13.1.
7. **Format: JSON under a published schema, versioned on its own.**
   - *Encoding.* Descriptors are JSON. They hold structure, not runtime data,
     so size never pushes toward binary. A `git diff` of two descriptors reads
     as a structural diff of two builds.
   - *Schema.* A JSON Schema is published with the format. The writer's tests
     validate against it, and every reader shares it as the contract.
   - *Versioning.* Each descriptor carries a `format_version` independent of
     Cadence's version, plus `cadence_version` for information only. A minor
     bump only adds fields, and readers ignore fields they do not know. A major
     bump may break readers, and a reader refuses a major version it does not
     know.
   - *Self-containment.* A deployment descriptor embeds its build descriptor
     whole, and a failure descriptor embeds its `Structure` projection. One
     file always opens on its own.

   *Why:* the browser reads JSON natively and people can read it. The schema
   is cheap now and becomes the wire's contract later. Tying the format
   version to Cadence's would force bumps on releases that leave descriptors
   untouched.
8. **Delivery: files and a live session.** A file is the format of record:
   one call writes a descriptor, and the inspector opens it by picker or
   drag-and-drop. The inspector's Julia package also runs a local web server.
   An explicit call such as `inspect(world)` builds, opens a tab, and on a
   build error sends the failure descriptor. Later calls push the new
   descriptor to the same tab. The tab keeps its view across updates, meaning
   the open subsystem, the zoom and the selection, matched by path. Nothing
   updates without an explicit call.
   *Why:* the live session serves the code-first edit loop, and files serve
   sharing, CI and archiving. An automatic trigger would need a callback hook
   in the core, against answer 3. Keeping the view by path stops every
   rebuild from throwing the user back to the root.
9. **Workspace and views: diagram-centered, first release by data at hand.**
   The diagram sits at the center. A model tree on the left stays in sync
   with it, and a breadcrumb shows the open subsystem's path. A detail pane on
   the right shows the selection: a component's type, class, docstring,
   source location, parameter summary and faces; a wire's endpoints and value
   type; a face's route. A bottom drawer holds diagnostics and warnings, each
   linked to its location, plus the root inputs and the timing tables. The
   views come in four tiers:
   - *Core:* the hierarchical diagram, the tree, search by path, type or face
     name, the detail pane, the diagnostics overlay of answer 6 with dead hops
     marked, and block coloring by tier or by rate with a legend.
   - *Analysis:* execution-order badges with port classes, the anchor and
     component tables, the schedule and hyperperiod chart for a deployment
     descriptor, and the root-input surface.
   - *Face routes:* selecting a root face highlights its chain through every
     level. The structure step records the routing chain (D-257, amended
     2026-09-30), so the data is at hand.
   - *Later, deferred and not refused:* a diff of two builds drawn on the
     diagram, and a general view of what feeds an output instantaneously.

   The first release carries the core, analysis and face-route tiers.
   *Why:* the first two tiers need no new data from the core. They turn what
   `show` prints today into something to navigate. The general feedthrough
   view needs dependence maps that only a failed loop's tracing produces, or
   a §9.4 tracer activation run on request.
10. **Distribution: one static bundle, fetched by Julia, also hosted.**
    The inspector is a static bundle: HTML, JavaScript and CSS that run
    entirely in the browser. Its sources live in their own repo, and CI
    builds the bundle and attaches it to each GitHub Release. Node and npm
    are needed only to build it, never to use it.
    - *Through Julia.* The inspector's Julia package lists the bundle as an
      artifact, so the package manager downloads and caches it on install.
      `inspect` starts a server on `localhost` that serves the bundle and
      pushes descriptors to the page over a WebSocket. It opens the browser
      itself. The page always matches the package version.
    - *Hosted.* The same bundle is published to GitHub Pages. Anyone can open
      it and drop a descriptor file in. The browser reads the file locally,
      and the model is never uploaded. The page says so.
    - *Offline.* Nothing loads from a CDN at runtime, so the inspector works
      air-gapped.
    - *Candidate, not committed:* a standalone HTML export that inlines the
      bundle and one descriptor into a single file anyone can double-click.

    *Why:* a page cannot accept incoming connections, so the REPL side must
    be the server. Serving the bundle from that same server keeps the page
    and the data in step, with no manual download. The hosted copy serves
    people without Julia.
11. **Stack: TypeScript, Svelte, ELK.js; rendering by spike.** The bundle is
    written in TypeScript with Svelte as the UI framework, and ELK.js
    computes diagram layout. The canvas is either hand-rolled SVG or Svelte
    Flow, chosen by a small prototype. That choice stays inside the canvas.
    *Review model:* agents write most of this code, and the user does not
    review it line by line as with the core. Verification rests on three
    checks: the type checker, tests of the front end against example
    descriptors that the JSON Schema validates, and looking at the result in
    a browser.
    *Why:* the type checker is the cheapest reviewer for code read rarely.
    Svelte components read close to plain HTML. ELK has no serious rival for
    layered diagrams with ports and right-angle wires.
12. **Layout: computed, steered by declaration order, stable, never saved.**
    ELK lays out one subsystem level at a time, with child assemblies drawn
    as closed blocks. Ties break by declaration order, the order of the
    struct's fields and of each connection list, so the code steers the
    picture. When `inspect` pushes a new descriptor, the previous positions
    go to ELK as hints, so surviving blocks keep their places. A user may
    drag a block to untangle a view. The change lasts until the page reloads
    and is never saved. Hand arrangement saved beside the code is refused for
    now. It could be added on top later.
    *Why:* a saved arrangement is a second file to version that drifts from
    the code, and it would bring back through layout the second source of
    truth that answer 2 removed. Computed layout works the same in the live
    session and in the hosted copy.
13. **Framework hooks: the core renders descriptors.** The core gains
    `describe(x)` for a `Build`, a `Deployment` and a failed build. It
    returns plain Julia data in the descriptor's shape: dictionaries,
    vectors, strings and numbers. `format_version` and the JSON Schema live
    in the core repo, and the core's suite checks `describe`'s output against
    the schema. The core takes no JSON dependency. Encoding to text is the
    inspector package's job. The build's carrier exception holds the last
    clean artifact, as answer 6 requires.
    *Why:* the artifacts' fields are internal under D-257, and the core
    reshapes them freely. Keeping the writer beside them lets the core's own
    suite catch a refactor that would break descriptors. It extends D-257's
    idea that an artifact renders itself: `show` renders to text and
    `describe` to data. The wire device later calls the same function.
    *Cost:* the descriptor format becomes core API. It needs its own spec
    section, an explicit ruling that a rendering to data is not an accessor
    in D-257's sense, and the carrier change.
14. **Packaging: one inspector repo, apart from the core.** The inspector
    repo holds the Julia package at its root and the TypeScript sources in
    `frontend/`. One tag releases both, so a package version and its bundle
    always match. The core repo stays Julia-only. The schema keeps one home,
    the core repo, and the inspector reads it from the installed Cadence.
    The inspector's CI pins a Cadence version, builds fixture models, runs
    `describe` on them, validates the output against the schema, and runs
    the front-end tests on those descriptors.
    *Why:* the core keeps its strict review, apart from code reviewed under
    answer 11's lighter model. The version match holds by construction. A
    format change in the core fails the inspector's CI when the pin moves,
    never silently.
15. **The Simulink pitch: familiar where cheap, refusals stated openly.**
    Beyond what earlier answers already give (subsystems by double-click,
    the model tree, rate colors, execution-order badges, loop highlighting,
    face routes), four additions:
    - a toggle labeling wires with their value types;
    - wire styles by the kind of value: thin for a scalar, thicker for a
      vector, a triple line for a NamedTuple, the way Simulink draws a bus;
    - icons for §13.7's standard library, matched by type name: `SumJunction`
      as a circle with its signs, `UnitDelay` as z⁻¹, `Constant` as its value;
    - a "Coming from Simulink" help page mapping the vocabulary (assembly ≈
      subsystem, face ≈ port, root input ≈ inport). The interface itself keeps
      Cadence's terms everywhere.

    The help page states the refusals: editing (answer 2), saved hand layout
    (answer 12), and author-supplied icons or masks, for now. A Run button,
    scopes and runtime data are stage 3's and stage 4's, and the page says
    so until they arrive.
    *Why:* the additions are front-end work on data the descriptor already
    carries. Cadence's terms stay because diagnostics, the spec and
    descriptors all use them. Stating the refusals spares a Simulink user from
    hunting for a Run button.
16. **The kind marker is a requirement, not a question.** Every face
    carries a small tag beside its printed Julia type: number, Boolean,
    enum, struct with named fields, opaque; function-valued signals of §4.4
    are opaque. Answer 15's wire styles need it, and stage 4's generic
    panels need it to choose a widget with no Julia at hand. The value type
    schema for struct faces stays with stage 2.

### Design axes

Each axis can be designed in its own session. The answers it builds on are
cited by number. Couplings are named where they exist.

1. **Descriptor schema.** The exact data model of the build, deployment and
   failure descriptors: field names, nesting, how types, paths, faces, kind
   markers, routes, timing tables, diagnostics and parameter summaries are
   encoded. It also covers the JSON Schema, the minor and major bump rules,
   and a set of fixture descriptors. Three details to absorb: the two-sided
   face table, the anchor and component tables in rational form, and state
   events among the derived facts. *Builds on* answers 4 to 7, 13 and 16.
   *Coupled to* axis 3, which says what the drawing needs, and to stage 2,
   which extends the schema.
2. **Core integration.** The spec work answer 13 calls for: a section for
   `describe`, the D-257 ruling that a rendering to data is not an accessor,
   and the carrier exception holding the last clean artifact (§13.1, §13.2).
   It also covers collecting instance context: docstrings, source locations,
   and the truncation rule for parameter summaries. *Builds on* answers 5,
   6 and 13. *Coupled to* axis 1.
3. **Visual grammar.** How each model concept is drawn. This covers blocks;
   faces as ports; an opened assembly's boundary faces inside the subsystem;
   fan-out; container children and name-transparent containers; root inputs;
   tier and rate colors, or rate scopes drawn as regions; wire styles and
   type labels; library icons; and the diagnostics overlay with loop wires
   and dead hops. *Builds on* answers 6, 9 and 15. *Coupled to* axis 4.
4. **Layout and rendering.** ELK configuration: one level at a time, model
   order, port constraints, right-angle routing, and stability hints across
   pushes. It also covers the rendering spike, hand-rolled SVG against Svelte
   Flow, and performance on the largest expected subsystem. *Builds on*
   answers 11 and 12.
5. **Workspace and interaction.** The tree, canvas, detail pane and drawer;
   search; selection; view state kept by path across pushes; the analysis
   views (execution order, anchor and component tables, schedule and
   hyperperiod chart, root inputs); face-route highlighting; the help page.
   *Builds on* answers 8, 9 and 15.
6. **Julia package and live session.** The `inspect` and `write_descriptor`
   API, and the server's life in the REPL: a background task, port choice,
   opening the browser, binding to `localhost` only. It also covers the page
   protocol (a greeting that checks `format_version`, then descriptor
   pushes), the failure path of answer 6, and the standalone export
   candidate. *Builds on* answers 8, 10 and 13. *Coupled to* stage 2, which
   gives the same server a device side.
7. **Build, release and verification.** The repo layout, and a CI that
   builds the bundle, attaches it to the release, updates `Artifacts.toml`
   and publishes to GitHub Pages. It also covers the fixture pipeline against
   a pinned Cadence, front-end tests, the no-CDN rule and the privacy
   statement. *Builds on* answers 10, 11 and 14.

## Stage 2: the wire device

An ordinary device that serves the handle over a socket, so that the page
stage 1 built can follow a running simulation and, in stage 4, command it.

### Settled

- **An ordinary device.** It subtypes `AbstractDevice`, attaches under a
  binding like any other, and runs its loop on a spawned task. It reads
  `latest(handle)` or waits on the next snapshot, writes through `stage!`,
  and touches nothing else. The handle-only rule is literal.
- **The greedy binding, `should_abort` clear.** It declares `is_input` and
  `is_greedy`, stakes the computed claim over everything unclaimed, and
  declares no `reads`, since its read set changes as clients subscribe. A
  dropped connection is a client reconnecting, not a run ending. The same
  device attaches with explicit claims beside other front ends.
- **Session-level server, per-simulation attach.** The inspector's server
  and tab exist before any simulation and outlive runs and rebuilds. A
  simulation joins the session by one `attach!` of the device, which the
  roster keeps across that simulation's runs, and `inspect(sim)` is the
  sugar that attaches and pushes the deployment descriptor in one call.
  `gui = true` is withdrawn (D-310).
- **What goes over the wire on connect.** The descriptor, the run-start
  facts (the port-view table with each port's liveness verdict and
  incumbent, and the claim partition) and the format version. The port
  view, the peek and the orphan fact are D-270's three values, consumed by
  the device instead of a drawing context.
- **Newest wins.** Values go at each subscription's rate, coalesced to the
  latest snapshot, the same rule the snapshot already follows. A slow
  client skips frames and never queues.
- **The peek rule crosses the wire intact.** The client keeps one pending
  map keyed by root-input face, the mirror of the staging cell, and a
  widget shows its own pending value if any, else the latest received. Two
  ports resolving to one face read the same entry. The device may echo
  `pending(handle, slot)` so the client needs no acknowledgements. The drain
  window grows by one round trip, which the levels doctrine makes harmless.
- **Physical inputs stay in-process.** A joystick is a device of its own,
  never routed through the browser.

### Pending questions

- The message set, one per handle primitive: descriptor and run-start facts
  on connect, subscribe and unsubscribe, values, stage, report, control,
  history query over the log tail.
- The subscription rate model: per-subscription rate, latest-snapshot
  sampling against log-tail delivery.
- Serialization of snapshot values. The candidate: binary frames for
  values, a `Float64` array in the order fixed at subscription so decoding
  is free, and JSON for structure. The field walk for custom structs, the
  value type schema that answer 4 left additive, opaque leaves, the eltype.
- The log-tail view: a per-frame copy of the reference vector, or a bounded
  tail accessor, with its torn-free guarantee against the loop's append and
  compaction (§11.2). Whether the compiled `Reader` of §14.4 is the right
  per-snapshot extractor, and what it costs to hold one per subscribed
  path. The spec home is §11.2.
- Control from a device. §12.1 rules that the handle carries no pause, and
  the device must issue pause, resume, pace and margin from a client
  message. Either the handle gains the four verbs, a few lines since it
  holds the control block by reference, or the device holds the
  simulation, against the handle-only rule. Stop is already an operator
  channel from a handle.
- Several clients at once with disjoint claims (§11.6), and one client with
  several tabs.
- Transport and security assumptions: `localhost` first, nothing else
  promised.
- The protocol document's home and its versioning against the descriptor's.
- What proves it works: the stage 3 client is the reference client, and
  whether a conformance suite is wanted beside it.

### Precedents

Simulink's external mode and Simulink Real-Time keep the engine and the
instrumentation in separate processes over a subscription-and-tune
protocol, even on the desktop. Foxglove's WebSocket protocol is the model
for subscriptions and schemas, FlightGear's Phi for an aircraft cockpit in
a browser, and NASA's Open MCT and OpenC3 COSMOS for commanding from a
page. In Julia, Pluto, Bonito and Stipple already run a process serving a
reactive page over WebSocket.

## Stage 3: the live inspector

The stage 1 page connected to the stage 2 device: the diagram stays, and
the run appears on it.

### Pending questions

- Values on wires and faces, at subscription rate, with the kind marker
  choosing the rendering.
- Boundary highlighting: which blocks ran at the last boundary, by rate
  scope.
- The status marks on the tree: orphaned inputs, dead device tasks, build
  and deployment warnings, diagnostic counters (§11.8). An orphan reads its
  label from the incumbent's writer record, as §11.7 rules.
- The roster panel with liveness: each writer's heartbeat, task state and
  claim.
- The run-control panel: pause, resume, stop, pace, margin; whether partial
  advance (§12.6) is exposed as a step control. It waits on stage 2's
  control question.
- The diagnostics drawer going live: the per-writer accounts of §11.8 as
  they change.
- Click-to-open from the diagram to the component's panel, which stage 4
  fills.

## Stage 4: the cockpit

Panels over the wire, so that the page commands the model it shows.

### Settled

- **Three panel sources, by how much the author writes.** A generic panel
  derived from the descriptor's faces and kind markers, shown for every
  component with nothing authored. A declarative panel authored in Julia as
  data, a method on the component type that returns a description the
  descriptor carries, such as `panel(::Type{LowPassFilter}) =
  Column(Slider(:cutoff), Readout(:y), Plot(:y))`. A custom panel in
  TypeScript, keyed by component type name, for what data cannot express:
  instruments drawn on a canvas, maps, 3D views. The declarative form is
  §11.7's per-type method with its drawing replaced by data, and that
  amendment is this stage's spec work (D-310).
- **The widget rules, enforced once in the client.** A widget is live
  exactly when its port's view says so, read-only otherwise with its source
  labelled, and an orphaned incumbent is shown in the label. Value widgets
  stage the new level on edit, edge widgets stage a level computed from the
  peek on activation, and held buttons do not re-stage. The generic
  renderer is written against the same widget layer, so authored and
  generic panels share one look and one liveness handling.
- **Plots read the log.** A plot walks the log's tail through stage 2's
  history message, at boundary-rate fidelity, and says so when the log is
  off or the window is sparse. uPlot on a canvas is the candidate renderer.
- **Workspace.** A docking layout over the stage 1 page, the model tree as
  the navigator, and the fixed framework panels of stage 3. Authored panels
  are content inside a dock node the client owns.

### Pending questions

- The panel description's vocabulary: the widget set, layout primitives,
  ranges and units, how a panel embeds the generic panel or a child's.
- Discovery of the panel method: its name and signature on the component
  type, subject to the exported-name audit in `pending.md`, and how the
  description reaches the descriptor.
- The generic panel's editable-type set (numbers, Booleans, enums, ranged
  values) and the recursive field walk for struct faces, with text for
  leaves it does not understand.
- Per-node view state, keyed by path, for what outlives a tick: plot
  windows, a map's zoom. Its lifetime: per run, per session, or persisted.
- The raw-view affordance: the generic panel for a component that has an
  authored one, as an entry in the tree or a toggle on the panel.
- Browser input devices through the gamepad API, for teleoperation-grade
  latency only, never in place of an in-process device.
- Whether FlightApps panels are worth porting as a test of the convention.
  Migration is not a priority (memory, 2026-09-23).

**Deferred, not refused:** a diff of two builds; a general view of what feeds
an output instantaneously; saved hand layout, which would take the form of a
sidecar file keyed by path, presentation state and never model state;
author-supplied icons; the standalone HTML export; the analysis view.

## Glossary

- **Authored panel.** A component's own panel, given by a method on its
  type that returns a panel description, or by a custom front-end panel
  keyed by the type's name.
- **Build descriptor.** The descriptor of a `Build`. Its timing is
  anchor-relative.
- **Bundle.** The inspector's built front end: a few static files that run
  in any browser with nothing installed.
- **Cockpit.** Stage 4: the page with panels that command the model over
  the wire.
- **Deployment descriptor.** The descriptor of a `Deployment`. It embeds the
  build descriptor it deploys and adds the schedule and grid facts.
- **`describe`.** The core's rendering of an artifact to descriptor data,
  beside `show`'s rendering to text. The name is a placeholder.
- **Descriptor.** A serialized, language-neutral projection of a `Build`, a
  `Deployment` or a failed build. The artifact stays the truth, and a
  descriptor is one consumer's reading of it. The wire device's connect
  payload.
- **Failure descriptor.** The descriptor of a failed build: its diagnostics,
  plus the `Structure` projection when the structure step passed.
- **Format version.** The descriptor format's own `major.minor` version,
  independent of Cadence's. Minor bumps only add.
- **Generic panel.** The panel the client derives from a component's faces
  and kind markers when no authored panel exists; also embeddable by an
  authored one.
- **Handle-only rule.** The wire device reaches the framework through the
  device handle alone, so that what it needs is what every client needs.
- **Hosted copy.** The bundle published on GitHub Pages. It opens descriptor
  files locally and uploads nothing.
- **Inspector.** The browser client, at whichever stage. Static, it
  explains a model's structure from descriptors; live, it shows a run on
  the diagram; as the cockpit, it commands the run.
- **Kind marker.** A small tag per face beside its printed Julia type
  (number, Boolean, enum, struct with named fields, opaque) so a client with
  no Julia can choose a widget or a wire style.
- **Live inspector.** Stage 3: the page connected to the wire device,
  showing runtime data on the diagram.
- **Live session.** The inspector package's local web server and the tab it
  feeds, updated by explicit `inspect` calls and, from stage 2, by the wire
  device.
- **Liveness table.** The port-view table of D-270, baked once at run
  start: one view per port of every component, with its terminal producer,
  the live-or-read-only verdict of §11.7, its staging slot and its incumbent
  writer. A run-start fact on the wire.
- **Parameter summary.** A component's inert parameters as truncated `show`
  text beside each type name. It is for a human to read, never for a program
  to reconstruct values from.
- **Pending map.** The client's one record of what it has staged and not
  yet seen applied, keyed by root-input face, the mirror of the staging
  cell.
- **Per-node view state.** State a panel keeps between ticks, keyed by the
  node's path and owned by the client.
- **Raw view.** The generic panel shown for a component that has an
  authored panel, for debugging.
- **Subscription.** A client's declaration of the paths it displays and the
  rate it wants them at, so bandwidth scales with the screen, not the
  model.
- **Wire device.** Stage 2: an ordinary device hosting the handle serialized
  over a socket.
