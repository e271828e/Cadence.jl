# Inspector: initial design

A browser inspector that helps a user understand a Cadence model. It reads
serialized descriptors of a `Build` or a `Deployment` and never shows
runtime data. This document records the questions that narrow the solution
space, the answers, and the axes left for later sessions. The proposal in
`docs/design/inspector/` is deliberately left out, so that it does not bias
this one.

## Pending Questions

None. The open questions now live under each design axis below.

## Answered Questions

1. **Scope: the inspector alone.** Cadence offers three graphical pieces:
   - a built-in immediate-mode GUI in Flight.jl's style, which is §11.7's GUI;
   - a browser inspector that reads serialized `Build` and `Deployment`
     descriptors and helps a user understand a model, with no runtime data;
   - a generic interface for fully external GUIs, which serves those
     descriptors plus runtime data through subscriptions.

   This document designs the inspector. The built-in GUI stays with §11.7,
   and its two `pending.md` entries stay where they are. The external
   interface is parked in `external.md` in this folder.
   *Note for the built-in GUI:* an earlier round of this session favored a
   generated panel for every component, which an author may override with a
   custom `draw!`, the way `Base.show` has a default. That remains a
   suggestion for §11.7's calling convention, not a ruling here.
2. **No graphical authoring, ever.** The inspector never writes model
   structure, whether by one-way code generation or by round-trip editing.
   Julia source stays the only model, as §8.1 requires.
3. **Independence.** The core never depends on the inspector. This was agreed
   before the scope split, and question 8 revisits the package boundaries.
4. **Descriptor constraints owed to the external interface.** The external
   interface will reuse the descriptor, so the descriptor keeps three
   properties:
   - canonical addressing, with components named by slash path and faces by
     face name (§8.6);
   - transport independence, as a self-contained document that works as a
     file or as a message;
   - additive versioning, so that the interface can later add a value type
     schema without breaking the inspector.
5. **Descriptor content: the artifacts' facts plus instance context.** A
   descriptor carries, as data, everything `show` prints for its artifact:
   the component tree, faces with value types and tiers, wires, root inputs,
   the execution order with port classes, and the timing tables. Each
   component adds three things: its type's docstring, the source location of
   its declaration methods, and a parameter summary. Internals such as
   initial states, cell layouts and compiled forms stay out.
   There are two kinds. A build descriptor projects a `Build`. A deployment
   descriptor projects a `Deployment` and embeds the build descriptor it
   deploys, as answer 7 requires. With a build descriptor alone the inspector shows anchor-relative
   timing; a deployment descriptor adds concrete `Δt` values and the
   hyperperiod chart.
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
   is cheap now and becomes the external interface's contract later. Tying
   the format version to Cadence's would force bumps on releases that leave
   descriptors untouched.
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
   view needs dependence maps that only a failed loop's tracing produces.
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
    `describe` to data. The external interface later calls the same function.
    *Cost:* the descriptor format becomes core API. It needs its own spec
    section, an explicit ruling that a rendering to data is not an accessor
    in D-257's sense, and the carrier change. None of it touches the spec or
    `pending.md` yet.
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

    The help page states the refusals: editing (answer 2), a Run button,
    scopes and any runtime data (answer 1), saved hand layout (answer 12),
    and author-supplied icons or masks, for now.
    *Why:* the additions are front-end work on data the descriptor already
    carries. Cadence's terms stay because diagnostics, the spec and
    descriptors all use them. Stating the refusals spares a Simulink user from
    hunting for a Run button.

## Design Axes

Each axis can be designed in its own session. The answers it builds on are
cited by number. Couplings are named where they exist.

1. **Descriptor schema.** The exact data model of the build, deployment and
   failure descriptors: field names, nesting, how types, paths, faces,
   routes, timing tables, diagnostics and parameter summaries are encoded.
   It also covers the JSON Schema, the minor and major bump rules, and a set
   of fixture descriptors. *Builds on* answers 4 to 7 and 13. *Coupled to*
   axis 3, which says what the drawing needs, and to the parked external
   interface, which will extend the schema.
2. **Core integration.** The spec work answer 13 calls for: a section for
   `describe`, the D-257 ruling that a rendering to data is not an accessor,
   and the carrier exception holding the last clean artifact (§13.1, §13.2).
   It also covers collecting instance context: docstrings, source locations,
   and the truncation rule for parameter summaries. *Builds on* answers 5,
   6 and 13. *Coupled to* axis 1.
3. **Visual grammar.** How each model concept is drawn. This covers blocks;
   faces as ports; an opened assembly's boundary faces inside the subsystem;
   fan-out; container children and name-transparent containers; root inputs;
   tier and rate colors; wire styles and type labels; library icons; and the
   diagnostics overlay with loop wires and dead hops. *Builds on* answers 6,
   9 and 15. *Coupled to* axis 4.
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
   candidate. *Builds on* answers 8, 10 and 13.
7. **Build, release and verification.** The repo layout, and a CI that
   builds the bundle, attaches it to the release, updates `Artifacts.toml`
   and publishes to GitHub Pages. It also covers the fixture pipeline against
   a pinned Cadence, front-end tests, the no-CDN rule and the privacy
   statement. *Builds on* answers 10, 11 and 14.

**Deferred, not refused:** a diff of two builds; a general view of what feeds
an output instantaneously; saved hand layout; author-supplied icons; the
standalone HTML export.

## Glossary

- **Built-in GUI.** §11.7's in-process immediate-mode GUI. Out of scope here.
- **Inspector.** The browser application that explains a model's structure
  from descriptors. It never shows runtime data.
- **External interface.** The generic surface for GUIs outside the
  simulation, parked in `external.md`.
- **`describe`.** The core's rendering of an artifact to descriptor data,
  beside `show`'s rendering to text. The name is a placeholder.
- **Descriptor.** A serialized, language-neutral projection of a `Build`, a
  `Deployment` or a failed build. The artifact stays the truth, and a descriptor is one
  consumer's reading of it.
- **Build descriptor.** The descriptor of a `Build`. Its timing is
  anchor-relative.
- **Deployment descriptor.** The descriptor of a `Deployment`. It embeds the
  build descriptor it deploys and adds the schedule and grid facts.
- **Bundle.** The inspector's built front end: a few static files that run
  in any browser with nothing installed.
- **Hosted copy.** The bundle published on GitHub Pages. It opens descriptor
  files locally and uploads nothing.
- **Live session.** The inspector package's local web server and the tab it
  feeds, updated by explicit `inspect` calls.
- **Failure descriptor.** The descriptor of a failed build: its diagnostics,
  plus the `Structure` projection when the structure step passed.
- **Format version.** The descriptor format's own `major.minor` version,
  independent of Cadence's. Minor bumps only add.
- **Parameter summary.** A component's inert parameters as truncated `show`
  text beside each type name. It is for a human to read, never for a program
  to reconstruct values from.
