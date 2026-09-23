# The inspector: initial design

A graphical layer over Cadence.jl, sketched on 2026-09-21 before the
implementation closes `pending.md`. This document records the first pass:
the questions that constrained the solution space, the answers, the axes
left for later sessions, and the words the design uses. It is not a
specification. Spec terms keep their spec meaning; the glossary below only
adds the inspector's own.

## Standing constraints

Four rules fell out of the answers and every later axis is checked against
them.

1. **The document is a projection, never a serialization.** The framework
   emits what a viewer needs to draw and nothing else. No Julia object, no
   `Build` inside a `Deployment`, no field that exists because a type has it.
2. **No geometry in the document.** Layout is the viewer's business. Any
   persisted layout lives in a viewer-owned sidecar keyed by identity.
3. **A component author writes nothing for the inspector.** Everything the
   diagram draws is already declared for the framework to work. Panels
   (`GUI.draw!`, §11.7, `pending.md`) are A's obligation and predate this design.
4. **Native vocabulary, borrowed form.** Labels, legend and schema field
   names are the spec glossary's. The drawing grammar is Simulink's, because
   it is the lingua franca of block diagrams.

## Pending questions

Questions for the axes, not for this pass. Each names the axis it belongs
to.

- **Schema versioning** (axis 1). How a document declares its schema version,
  what the viewer does with an older or newer one, and whether the
  projection's tests pin fixtures per version.
- **Which activation the dataflow draws** (axis 1). The `Build` carries one
  activation dictionary. Whether the document projects the nominal dataflow,
  every activation, or one chosen at `inspect` time.
- **What `Events` contributes** (axis 1). Whether the `Events` product has a
  visible counterpart in the diagram or the schedule view, or is left out of
  the first iteration.
- **Where rates become known** (axes 1, 5). At which product rate colouring
  and the schedule view have data, so that a `Structure` or `Outputs`
  inspected alone degrades honestly.
- **Docstring projection** (axis 1). Whether the projection reads a
  component's docstring for hover text, and if so from where, since no product
  holds it.
- **Session policy** (axis 3). What happens when `inspect` is called several
  times in one Julia session: replace the page's document, open a tab per
  document, or keep a history. What identifies a document, since a `Build`
  has no id.
- **Server lifecycle** (axis 3). Whether the server outlives the first
  `inspect`, how the port is chosen, and how a page reconnects after Julia
  restarts. Localhost only is assumed.
- **Bundle delivery** (axes 3, 7). Whether the built bundle is committed to
  the delivery package or fetched as a release artifact, and how its version
  is tied to the schema version.
- **Viewer fixtures** (axis 7). How the viewer's tests obtain documents:
  generated from Cadence.jl's suite fixtures and committed, or produced on
  demand.
- **Device read side** (axis 4). How a device's output binding, its reads of
  root outputs, is drawn beside its claims, and whether the two need
  distinct wire styles.
- **Port stages** (axis 4). Whether stage 1 and stage 2 ports (D-252) are
  visually distinct on a block, and how an exposed state field returned from
  `output_state` appears.
- **An `errored` simulation** (axis 1). Whether `inspect` accepts one, and if
  so what its surface section shows, given that an errored simulation has no
  next run.
- **The run-data container** (later addition b). The columnar format for the
  log and trace payload and its relation to the persistence deferral in `pending.md`. To be
  designed once, not twice.

## Answered questions

Each entry gives the question, the answer, and the reason the answer won.

1. **What is the layer for?** A staged combination. First an inspector:
   read-only graphical views of the products the pipeline already makes.
   Then the runtime cockpit of §11.7 built on the inspector's views. A model
   editor last, if ever. The inspector is independent by construction because
   it reads artifacts D-253 to D-257 already make first-class, it answers the
   Simulink user's first question ("show me the diagram") without the editor's
   source-of-truth problem, and a live widget on a port in the inspector's
   diagram is exactly the cockpit's panel.
2. **How does the inspector attach to the framework?** Through a document.
   The framework projects each product to a document; the viewer consumes
   documents and never sees a Julia type. `inspect(x)` projects, serves and
   opens the page; the same page opens a saved document with no Julia
   process behind it. The document is a stable contract that survives
   refactors of `src/`, lets the viewer use web diagram tooling, and makes a
   model shareable with someone who has no Julia.
3. **Build or run?** Build only in the first iteration: `Structure`,
   `Outputs`, `Schedule`, `Deployment`. Run data (log, trace) is a later,
   additive payload that references ports by identity. The diagram is the
   hook; plotting a log is three lines of Makie at the REPL; and `pending.md` defers
   on-disk persistence of the log and trace, which the run payload would
   pre-empt. Live streaming during a run is recorded as "an ordinary read
   device" under §11 and needs no framework hook; it belongs after run data
   and largely to the cockpit.
4. **Whose vocabulary?** Cadence's, in Simulink's visual grammar. A
   translation to Simulink's concepts (inports for faces, devices hidden)
   would mislead at exactly the concepts that are Cadence's advantages, the
   device surface and derived liveness. Simulink's drawing conventions are
   borrowed because they carry no semantics of their own.
5. **Where does layout live?** Nowhere in the document. The viewer lays out
   every canvas automatically with a layered algorithm (ELK). A persisted
   drag override is a later, viewer-owned sidecar keyed by identity. Geometry
   in the document would break the projection rule and has no natural home
   in the framework. Automatic-only first is also a deliberate test of
   whether dragging is a need or a reflex. Consequence: every component, port
   and wire carries a stable identity, the §8.6 slash path, from the start.
6. **Built with what?** A prebuilt static page (TypeScript, ELK, an SVG or
   canvas renderer), vendored as an asset into a small Julia package that
   serves it over HTTP.jl and opens the default browser. Node is confined to
   the viewer's repository. A Julia-native web stack would still need ELK
   and would fight the one library the hard part depends on. A desktop
   wrapper buys a native window at a packaging cost an inspector does not
   justify. Live refresh is a websocket from the same server: the page opens
   one on load, `inspect` broadcasts the new document to every open socket,
   the page re-renders.
7. **Where does the export live?** Split. The projection lives in Cadence.jl
   as a small module with no viewer knowledge, gated by the framework's own
   suite so that a type change and its projection change land in one test
   run. The server and the bundle live in a separate package. The projection
   is the framework's obligation; delivery is not.
8. **What does `inspect` accept?** Any product from `Structure` up, and a
   `Simulation`. The document has a section per product, present when that
   stage exists, plus a diagnostics section. Each warning (on the `Build`)
   and grid diagnostic (on the `Deployment`, D-187) is an entry anchored by
   identity to the element it concerns, drawn as a badge on that block, port
   or row with detail in a side panel; an unanchored diagnostic anchors to
   its section. A build that threw has no product and is the REPL's business.
9. **How does the visitor move through the hierarchy?** Drill-down: one
   assembly per canvas, its children as blocks, its own faces as boundary
   ports, a breadcrumb of the slash path and a tree outline beside the
   canvas. Expand-in-place is a later refinement on the same document. Each
   canvas is then a small layout problem, the convention is the one the
   audience knows, and a canvas is exactly what the framework calls an
   assembly.
10. **How does time appear?** Both ways, linked. Rate colouring on the
    diagram with a legend, and a schedule view in a tab beside it that draws
    one hyperperiod as rows against ticks, one lane per rate, rows in
    execution order, grid diagnostics badged. Selection is shared across
    canvas, chart and outline through the slash path. The schedule view
    draws one hyperperiod and scrolls; it never draws a whole run.
11. **Where does the root canvas end?** Beyond the root faces. For a
    `Simulation`, the root canvas draws each rostered device as a block
    outside the root boundary, wired to the root inputs it claims and the
    root outputs it reads, from the roster as it stands at projection. The
    roster is resolved at every moment of its life (claims and the greedy
    complement are computed at `attach!`, §11.3), so there is no unresolved
    case to draw; "frozen" means only that the roster cannot move while
    `running`. `EmptyGreedyClaim` is a badge on the device block. Device
    blocks carry their roster order, because a greedy claim is the
    complement at attach time and order shapes the picture.

## Design axes

Quasi-orthogonal, each a session of its own. Coupling is named where it
exists.

1. **The document schema.** One section per product (`Structure`,
   `Outputs`, `Events`, `Schedule`, `Deployment`), a surface section for a
   `Simulation`, a diagnostics section. Identities on every component, port,
   wire, row and device. Versioning. Field names from the spec glossary.
   Couples to every other axis, since it is the contract, and to the later
   run-data payload, which keys on its identities.
2. **The projection in Cadence.jl.** The module, its JSON dependency, the
   walk over each product, the suite tests that gate drift, and its
   relationship to the D-257 `show` methods, which may share or cross-check
   it. Couples to axis 1 only.
3. **The delivery package.** `inspect`, the HTTP.jl server, the websocket
   broadcast, bundle vendoring, session and server lifecycle, opening the
   browser. Couples to axis 7 through the bundle's version.
4. **The diagram.** Drawing grammar for blocks, ports, boundary ports,
   wires, interface connections, device blocks and claim wires. Drill-down
   navigation, breadcrumb and outline. Automatic layout with ELK, ports on
   fixed sides. Rate colouring and the legend. The selection model shared
   with axis 5.
5. **The schedule view.** The hyperperiod chart, its lanes, scrolling and
   bounds, and the linked selection with axis 4.
6. **Diagnostics presentation.** Badges, the side panel, anchored and
   unanchored entries, the roster entry's cell for devices. Reads axis 1's
   diagnostics section; draws on axes 4 and 5.
7. **Viewer engineering.** Repository, toolchain, renderer choice, tests
   against fixture documents, the saved-document path (file picker,
   drag-and-drop), theming. Couples to axis 3 through delivery.
8. **Held-open additions.** Each is additive on the axes above and none is
   designed now: the run-data payload (Question 3), the layout sidecar
   (Question 5), expand-in-place (Question 9), the live read device
   (Question 3), and the cockpit on top of the diagram (Question 1).

## Glossary

Spec terms (assembly, face, root input, root output, claim, greedy claim,
roster, device, snapshot, slash path, hyperperiod, activation) keep their
spec meaning and are not redefined here.

- **Inspector.** The whole layer: projection, delivery package and viewer.
  Read-only over the framework's products.
- **Cockpit.** The runtime GUI of §11.7, panels and live widgets, to be
  built later on the inspector's views. Not part of this design.
- **Editor.** A hypothetical block-diagram authoring tool. Deferred
  indefinitely; named only to say what the inspector is not.
- **Product.** A named output of the pipeline: `Structure`, `Outputs`,
  `Events`, `Schedule`, `Build`, `Deployment`, and by extension a
  `Simulation`.
- **Document.** The JSON description of one inspected object. Composed of
  sections, carries a schema version, holds no geometry and no run data.
- **Projection.** The function from a product to its document, and the
  principle that the document names what a viewer needs rather than what a
  type contains.
- **Section.** The part of a document that describes one product, the
  surface, or the diagnostics. Present when its stage exists.
- **Identity.** The stable name of a diagram element: the §8.6 slash path
  for components and ports, derived paths for wires and rows, the device id
  for devices. Everything that anchors, keys or links uses it.
- **Viewer.** The static page. Consumes documents, draws canvases and the
  schedule view, knows no Julia.
- **Delivery package.** The Julia package that vendors the bundle, serves
  it, and implements `inspect`.
- **Bundle.** The viewer built into static files.
- **Saved document.** A document opened by the viewer from a file, with no
  server and no websocket.
- **Live refresh.** The page re-rendering when `inspect` broadcasts a new
  document over the websocket.
- **Canvas.** The drawing of one assembly: its children as blocks, its faces
  as boundary ports, its wires. The root canvas is the root assembly's.
- **Block.** The rectangle drawn for one child of the current assembly, leaf
  or assembly. Input ports on the left, output ports on the right.
- **Boundary port.** A face of the current assembly, drawn on the canvas
  edge. The parent's canvas draws the same face as a port on a block.
- **Device block.** The block drawn on the root canvas for a rostered
  device, outside the root boundary, carrying its roster order.
- **Claim wire.** A wire from a device block to a root input it claims.
- **Drill-down.** Entering a child assembly replaces the canvas. The
  breadcrumb and the outline keep the position.
- **Expand in place.** A held-open alternative where an assembly opens
  inside its own block on the parent's canvas.
- **Automatic layout.** The viewer's layered layout of a canvas, computed
  on every render, with no persisted positions.
- **Sidecar.** A held-open, viewer-owned file of dragged positions keyed by
  identity. Never part of the document.
- **Rate colouring.** Blocks and wires coloured by rate, with a legend.
- **Schedule view.** The tab that draws one hyperperiod as rows against
  ticks, one lane per rate.
- **Linked selection.** One selection shared by canvas, schedule view and
  outline, keyed by identity.
- **Diagnostic badge.** The mark drawn on the element a diagnostic anchors
  to; its detail is in the side panel.
- **Anchor.** The identity a diagnostic entry names, or the section it
  belongs to when it names none.
- **Run data.** The held-open payload of log and trace values, separate
  from the document and keyed on its identities.
