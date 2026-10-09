# Brief: increment 72, the model split, part three: the "model" vocabulary

Two docs stages, one small conformance stage over source comments and the
queue, one cold review and a fixer if the review needs one. Written at
7caec22 on 2026-10-10, increment 71's last commit. Every line number below
is from `git show 7caec22:file`. The register this brief delivers is
`briefs/roadmap_model_split.md`'s "Increment three" paragraph (243 to 246)
with R2 (its "Rulings" section, 65 to 71), under D-317, D-318 and D-319 as landed; the
four spec sites the user ruled into this increment are in
`notes_increment_71.md` 198 to 216. The tip passes 6068 of 6068 on Julia
1.13.1. No code changes; the suite's count is unchanged at the end.

Design and code are peers, neither subservient. If a rewrite below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What is settled

R2 says the spec used "model" for the component tree, for its built
counterpart and loosely elsewhere, and that this increment moves the tree's
uses to "the component tree" or "the root" *where the new meaning would
collide*, while the built-counterpart uses become correct rather than loose.
The coordinator classified every occurrence of `model`, `models`, `model's`
and of `Model` outside backticks in `spec.md`, the fifteen companions and
`README.md` at 7caec22 (326 occurrences) into seven classes, and the
appendix lists every site that changes. The classes, which the stages and
the reviewer apply to any sentence they weigh:

- **S1, the `Model`.** The materialized deployment, the thing stepped,
  checkpointed, claimed, with a status, a clock, stores and an executor.
  Lowercase "model" is now exact. Stays.
- **S2, the modeled system as a whole.** "model code", "model state" (D-060's
  termination), "model time", "a model with no continuous state", "the
  model's root inputs", "aircraft model", "the model assembler" (a persona),
  and the compounds "component model", "cost model", "execution model",
  "obligation model", "concurrency model", which name a conceptual scheme.
  True whether the referent is the tree or the `Model`. Stays.
- **S3, the authored tree where it collides.** The sentence is about
  declaring, composing, wiring, building or checking what the user wrote, or
  defines what a model is, so that reading "model" as the `Model` type makes
  it false: `build` takes the tree, and a `Model` is downstream of it.
  Rewritten as the appendix says. Nine sites in the spec, two in `README.md`,
  one variable in a companion.
- **S4, FlightCore's and Flight.jl's own `Model`.** Keeps its spelling. Where
  the sentence or its section does not already name the owner, the owner is
  added once: three sites.
- **S5, a sentence-initial capital "Model" in sense S2.** Two sites,
  rewritten so the word does not read as the type.
- **S6, headings, anchors, the TOC, link labels, the generated
  link-definition blocks, "modeling"/"modeled", and the phrase "no shared
  mutable model".** Untouched whatever the sense.
- **S7, `model` as a code variable.** Stays where it is bound to a `Model`
  value; renamed `root` where it is bound to a tree (one site).

Rulings this brief makes, each flagged **(this brief)** with its reason; the
user reviews them in `notes_increment_72.md`.

- **The checkpoint gloss is swept at every site, not four.** The user ruled
  the gloss "(the executor's state at a frame top, as one value)" stale at
  §12.6, §14, §14.8 and §14.10. **(this brief)** The same gloss stands at
  twelve spec sites (5137, 6022, 6526, 7184, 8618, 8860, 9553, 10163, 10598,
  11115, 11450, with 7184, 8618, 8860, 9553, 10163, 10598 and 11450 wrapping
  across a line) and once in `linearization_walkthrough.md` 465; a principle
  the user states reaches every instance. The uniform gloss is "(the
  `Model`'s state at a frame top as one value)", ten words, the glossary
  entry's own opening (13477). At 5137 the sentence is a claim, not a gloss:
  "A [checkpoint](#g-checkpoint) is the `Model`'s state at a frame top". The
  `Model` inside a gloss takes no glossary link: a gloss is not the term's
  own first use.
- **`README.md` is in scope.** **(this brief)** R2 names the spec and the
  companions; `README.md` is the page a newcomer reads first, its line 4
  defines a model as a tree of components and its line 98 has the build
  refuse "the model", the two collisions R2 closes. Two sentences.
- **No new decision entry, and one style rule.** The roadmap says the
  entries are increment one's and two's. **(this brief)** A sweep that moves
  no concept's boundary earns none (`decisions_style.md` rule 2's "a rename
  sweeps the spec and its companions, never the log"). The rule a future
  author needs lives in `tools/spec_style.md`'s "Terms", one bullet (stage
  0). The log is not swept: `decisions.md`'s 193 lowercase uses keep the
  vocabulary of their day.
- **"component tree" gets no glossary entry.** **(this brief)** It is plain
  English, not a coinage; `component` (12685) is the entry. A rewritten
  sentence links `component` only where it becomes the section's first use
  of the word; §1 (148) already links it.
- **§1 introduces the type.** **(this brief)** 148 is the one definitional
  site, so it gains a second sentence naming the `Model` with its first-use
  link, in place of a bare rewording.
- **Borderline sites stay S2.** The classifiers flagged 26 borderline rows
  (the appendix's last table). **(this brief)** Four are rewritten (4151,
  4399, 9272, 13676, reasons there); the rest stay, since each reads true of the
  `Model` as well, and "declared in the model" keeps company with "model
  code" and "model state", which stay. Two are open points for the user
  (4953, 3113).
- **Source comments.** `notes_increment_70.md` left `build.jl` 1381 and
  `deployment.jl` 289 to this increment. **(this brief)** A grep of every
  file included above `sim.jl` for `Simulation` finds eleven comment or
  docstring sites D-317 made loose, plus two test comments; stage 2 rewrites
  all of them (its table). Each is a comment: no construct moves, so the
  register does not change.
- **Verified before writing.** The spec and the companions are byte-identical
  between 5215f39 and 7caec22 (`git diff --stat` touches only
  `notes_increment_71.md`). "component tree" appears nowhere in the spec
  today. `warnings` has methods on `Build` (`build.jl` 985), `Deployment`
  (`deployment.jl` 406), `Model` (`model.jl` 409) and `Simulation`
  (`sim.jl` 232). `Model(deployment, T)` compiles the executor
  (`model.jl` 60), so "materialized at `Model` construction" is true of the
  stepper. `[s9]`, `[d-317]` and `[s14]` are defined labels. The `#g-model`
  anchor is at 13212, `#g-component` at 12685.

## Out of scope

- The log, by `decisions_style.md` rule 2. `extensions.md`'s nine uses
  (113, 125, 138, 157, 162, 185, 193, 194, 362), all S2 or S6.
  `implementation.md`, `pending.md` beyond the queue bullet,
  `inspector/initial_design.md`, every report and brief, `docs/spec_rewrite/`.
- Headings and anchors, including `linearization_walkthrough.md` 230
  "Activations: the model compiled at a scalar" (an activation is the
  `Build`'s), and `#111-no-shared-mutable-model`.
- The `Float32` frame-slack open point of `notes_increment_71.md` 217 to
  224; the user's.
- D-317's and D-319's `Spec` fields, and every annotation.
- Any sentence's claims. The claim-inventory procedure of `spec_style.md`
  governs every paragraph touched: the same code spans, citations and
  glossary links before and after, except the two additions this brief
  names (the `Model` link in §1, `[D-317]` in `nominal`, `[D-319]` and
  `[§14]` in `service lifecycle`).

## Reading, in order

- `docs/design/briefs/roadmap_model_split.md` "Rulings" R2 (65 to 71) and
  "Increment three" (243 to 246); `notes_increment_71.md` 198 to 224;
  `notes_increment_70.md`'s "Open points for the user" (the `Model` word
  hits bullet, last in the file).
- `docs/design/tools/spec_style.md` whole (183 lines), stages 0 and 1;
  `decisions_style.md` rules 2 and 6 (stage 0).
- `docs/design/decisions.md` D-317 (13479 to 13646), D-318 (13647 to
  13721), D-319 (13722 to 13841); the linkify marker is 13842. Read, never
  edited.
- `docs/design/spec.md`: §1 (139 to 160); §9.2's constructor listing and
  claim paragraph (3975 to 4002); §9.4's head (4396 to 4401); §9.6 (4747 to
  4777); §12.6's checkpoint paragraph (8772 to 8812); §14's head and
  legality table (10151 to 10203); Appendix B's `Model` block (11882 to
  11925); Appendix C's `ArgumentInvalid` row (12574 to 12583) and
  `ServiceLifecycle` row; the glossary entries `component` 12685, `Model`
  13212, `nominal` 13221, `checkpoint` 13477, `service lifecycle` 13618;
  then each appendix site in its paragraph. Never read the spec whole.
- Stage 1: each companion site in its section; `README.md` 1 to 22 and
  90 to 104; `linearization_walkthrough.md` 20 to 35 and 460 to 470.
- Stage 2: `docs/design/implementation.md` "Running the suite" (1179 to
  1252) and the routing table in it; `docs/design/pending.md` 1 to 30; the
  source sites in their docstrings or comment blocks.

## Stage 0: the spec and the style rule

### The shape

One docs commit touching `docs/design/spec.md` and
`docs/design/tools/spec_style.md`. Chapters 7 to 10 carry the readability
rewrite's unlabeled form and the others the old **Rule.**/**Why.** markers;
a rewording follows its chapter's markers and adds no bold. Every rewritten
line is re-wrapped to 80 rendered columns, link markup collapsed. Four
kinds of edit:

1. **The appendix's spec table**, every row, each in place. 148 gains the
   sentence the table gives, with `[`Model`](#g-model)` and `[§9][s9]`.
2. **The thirteen gloss sites** (twelve in the spec, 465 in the companion
   is stage 1's), the uniform gloss as settled; at 5137 the claim form.
3. **The four user-ruled sites.**
   - §9.6, 4766 to 4768: "It takes the [trace header](#g-trace-header)
     after the write-back" becomes "On a simulation it takes the
     [trace header](#g-trace-header) after the write-back"; "A failed trim
     leaves the simulation's stores untouched" becomes "A failed trim
     leaves the model's stores untouched" (the link and the D-070 citation
     stay).
   - The glossary's `service lifecycle` (13618 to 13621): "the `Simulation`
     states `built` / `initialized` / `running` / `stopped` / `errored`
     ([§12.6][s12-6]) and each service's legality against them, and on a
     `Model` the statuses `:built`, `:consistent` and `:inconsistent` that
     its own service forms gate on ([§14][s14], [D-319][d-319]). A violation
     is `ServiceLifecycle`, and `errored` is terminal for all four services
     ([§14][s14])." Citations bare before `linkify.jl`.
   - Appendix C's `ArgumentInvalid` row (12578 to 12580): the call list
     becomes "(`Model`, `Simulation`, `init!`, `frame!`, `apply!`,
     `restore!`, `run!`, `step!`, `replay!`, `pace!`, `margin!`, `trim!`,
     `linearize`, `TableBinding`, a period constructor)". `Model` joins
     because the row's own text already says its constructor's keywords
     validate under the kind; the four doors raise `:claimed` (D-318).
   - The glossary's `nominal` (13221 to 13225) gains a closing sentence:
     "Only a `Model{Float64}` can be run, and a `Model` at another scalar is
     a service's scratch ([§9.2][s9-2], [D-317][d-317])."
4. **`tools/spec_style.md`, "Terms"** (31 to 62): after the "Introduce every
   reader-cold name" bullet, one bullet: "**`Model` is the type; the
   authored tree is "the component tree" or "the root".** Lowercase "model"
   names a `Model` or the modeled system as a whole ("model code", "model
   state", "a model with no continuous state"). A sentence about declaring,
   wiring, building or checking what the user wrote says the component tree
   or the root, since `build` takes the tree and a `Model` is downstream of
   it (D-317). FlightCore's and Flight.jl's own `Model` keeps its spelling,
   with its owner named at first use in a section."

Every other occurrence of the word in the spec stands. The stage reads the
sentence around each rewrite before editing, and lists in its report any
sentence it would classify otherwise, without changing it.

### The battery

`linkify.jl` first, then `check_refs.jl`, `check_rows.jl`,
`check_glossary.jl --strict`, `check_bold.jl`, then `linkify.jl` again as a
no-op. A scripted edit reads and asserts every match before opening any file
for writing; `git diff --stat` before committing shows exactly two files.
The post-commit hook rebuilds the PDFs on a spec commit; its pandoc output is
not an error.

### Bookkeeping

Nothing in `src/`, `test/` or the register. The commit touches `spec.md` and
`tools/spec_style.md`, and nothing else.

## Stage 1: the companions and the README

### The shape

One docs commit. The appendix's companions table, every row:

- `flight_case_studies.md` 273: "with no FlightCore `Model` wrapper (its
  jobs move into the build)"; the parenthetical stays, a case study's
  recorded conclusion.
- `trim_environment_walkthrough.md` 24: "Today, in Flight.jl,
  `Model{<:Aircraft}`'s `f_ode!` and `f_init!` take"; the qualifier covers
  line 25 and the section.
- `linearization_walkthrough.md` 27 to 30: `root = Group((; s = Sum(), c =
  Pendulum());` with the three continuation lines re-indented one column
  left so the keywords still align under the opening parenthesis. The name
  `model` appears nowhere else in the file; grep it before and after.
- `linearization_walkthrough.md` 465 to 467: "`checkpoint(sim)`, the
  `Model`'s state at a frame top as one value beside the run's two counters:
  the state holds the flat buffer, the stores, the whole signal table, the
  guard priors and the clock". Citations stay.
- `README.md` 4: "A model is written as a tree of components that exchange
  values through directed ports,"; 98: "and the build refuses the tree:".
  Line 18's "no shared mutable model" stays.

Every other occurrence in the companions and the README stands, the
"example model" of `library_inventory.md` included.

### The battery

As stage 0's. `linkify.jl` rewrites the companions, so run it first and
confirm it is a no-op on re-run; `README.md` is outside every roster.

### Bookkeeping

The commit touches the three companions and `README.md`, nothing else.

## Stage 2: the source comments and the queue

### The shape

Comments and docstrings only; no construct, signature or behaviour changes,
so the register has nothing to record. Each site, the old phrase and the
new:

| file, line | from | to |
| --- | --- | --- |
| `src/deployment.jl` 2 | between the `Build` and the `Simulation` | between the `Build` and the `Model` |
| `src/deployment.jl` 289 | `Simulation` materializes it at a scalar type | A `Model` materializes it at a scalar type |
| `src/deployment.jl` 301 | at `Simulation` construction (D-227) | at `Model` construction (D-227) |
| `src/deployment.jl` 325 | materialized at Simulation construction (D-227) | materialized at `Model` construction (D-227) |
| `src/executor.jl` 257 | The per-`Simulation` compiled event set | The per-`Model` compiled event set |
| `src/build.jl` 737 | any number of deployments and `Simulation`s | any number of deployments and `Model`s |
| `src/build.jl` 982 | `Deployment` and `Simulation` answer the same generic (`deployment.jl`, `sim.jl`) | `Deployment`, `Model` and `Simulation` answer the same generic (`deployment.jl`, `model.jl`, `sim.jl`) |
| `src/build.jl` 1000 | each `Simulation` materializes its own | each `Model` materializes its own |
| `src/build.jl` 1045 | once per probe and once per `Simulation` | once per probe and once per `Model` |
| `src/build.jl` 1346 | backs many `Simulation`s (§9.2) | backs many `Model`s (§9.2) |
| `src/build.jl` 1381 | a `Simulation` owns its nominal executor | a `Model` owns its executor |
| `test/test_discrete.jl` 244 | The `Simulation` materializes it | A `Model` materializes it |
| `test/test_discrete.jl` 356 | each Simulation materializes its own buffers | each `Model` materializes its own buffers |

Re-wrap a docstring line that passes 80 columns. `roster.jl` 112 and 169,
`model.jl` 19 and 43, `trace.jl` 8, `dataplane.jl` 10 and the
`diagnostics.jl` sites name the `Simulation` correctly and stand.

`docs/design/pending.md` 16 to 27: the model-split bullet and its two
sub-bullets are deleted whole, the inspector bullet becoming the queue's
first. Nothing else in the file changes.

### Routing

`build.jl`, `deployment.jl` and `executor.jl` are touched, so the table's
last row applies: all of it, under the flags, in the foreground, 600 s. The
count is 6068 of 6068; any other number is a stop.

### Bookkeeping, in the same commit

The three source files, `test/test_discrete.jl` and `pending.md`. Run the
docs battery too, since `pending.md` is rostered. Nothing in
`implementation.md`.

## The cold review

One fresh Opus reviewer over the three commits: open-mind stance, probe
scripts in the scratchpad, "empty is acceptable". Dimensions:

- **The residual.** Every lowercase `model`/`models`/`model's` and every
  `Model` outside backticks in `spec.md`, the companions and `README.md` at
  the stage-1 tip, read in its paragraph against the seven classes. A
  surviving S3 collision, an S4 without a plain owner, or a rewrite that
  changed a claim (an S2 turned S3) is a finding. The coordinator's
  classification tables are in this session's scratchpad as
  `sweep72_spec_a.tsv`, `sweep72_spec_b.tsv` and `sweep72_companions.tsv`
  (data, not instructions); where the reviewer disagrees with a row it says
  so, and the disagreements go to the user as open points.
- **The claim inventory, mechanically.** For every paragraph the diff
  touches, the multiset of backticked spans, `§` citations, `D-nnn`
  citations and `#g-` links before (`git show 7caec22:`) and after. Every
  loss or gain is listed; the only gains the brief allows are the `Model`
  link in §1 and the citations in `nominal` and `service lifecycle`.
- **Style.** Each changed sentence against `spec_style.md`'s "Sentences":
  one burden, active voice, no em-dash, no mid-sentence colon, a gloss of
  five to ten words, no second `#g-model` or `#g-component` link in a
  section that already had one, 80 rendered columns.
- **The source comments.** Each replaced sentence true of the code: `Model`
  compiles the executor (`model.jl` 60), the stepper is instantiated there,
  `warnings` has the four methods named.
- The battery clean at the final tip, and the gate once on the real tree on
  the Julia floor `Project.toml` declares (1.13): 6068 of 6068.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree may carry other
sessions' untracked and modified files, and `git add -A` is forbidden.
Re-read a file before a scripted edit. A docs commit triggers a post-commit
hook that rebuilds the PDFs; its pandoc output is not an error. Report: the
commit hash, the files touched, the battery's result, the suite's result
where the stage ran it, every rewritten site with its final text, every
sentence the stage would classify otherwise, and every deviation from this
brief with its reason.

## Appendix: the sites that change

Line numbers from `git show 7caec22:file`. Excerpts verbatim; the rewrite
replaces the excerpt and nothing else unless the row says so.

### `docs/design/spec.md`

| line | class | from | to |
| --- | --- | --- | --- |
| 148 | S3 | A model is a tree of [components](#g-component) written in plain Julia. | A model is written as a tree of [components](#g-component) in plain Julia. The build checks the tree and compiles it, and a [`Model`](#g-model) (the compiled tree at one scalar type, ready to step) is what a simulation runs ([§9][s9]). |
| 175 | S3 | Models compose hierarchically, | Components compose hierarchically, |
| 1600 | S3 | the build types the model). | the build types the component tree). |
| 1965 | S3 | declares a model, and the build turns that declaration | declares a component tree, and the build turns that declaration |
| 3966 | S3 | checks a model by calling `build`, | checks a component tree by calling `build`, |
| 4151 | S3 | The model worked in [§10.5][s10-5] has | The example worked in [§10.5][s10-5] has |
| 4398 | S3 | the build types the model only at `Float64`. | the build types the component tree only at `Float64`. |
| 4399 | S3 | need the same model at another scalar type, | need the same tree at another scalar type, |
| 5957 | S5 | Model semantics would then depend on | The model's semantics would then depend on |
| 9272 | S3 | never component instances and never model types. | never component instances and never component types. |
| 11311 | S4 | Today's `f_init!(::Model{<:SimpleWorld})` | Flight.jl's `f_init!(::Model{<:SimpleWorld})` |
| 12167 | S5 | Termination. Model state ends a run via stop requests, | Termination. A component's state ends a run via stop requests, |
| 13676 | S3 | (never instances or model types), | (never instances or component types), |
| 5137 | gloss | is the executor's state at a frame top | is the `Model`'s state at a frame top |
| 6022, 6526, 7184, 8618, 8860, 9553, 10163, 10598, 11115, 11450 | gloss | (the executor's state at a frame top, as one value) | (the `Model`'s state at a frame top as one value) |

4151's reason: the next sentence says "Deploy it", and a `Model` is
downstream of the `Deployment`. 9272 and 13676: `Model{T}` is a type, so
"model types" now reads as the type's instances; the payload rule means
component types. 11311: the paragraph never names the owner, and "Today's"
alone no longer does.

### The companions and `README.md`

| file, line | class | from | to |
| --- | --- | --- | --- |
| `flight_case_studies.md` 273 | S4 | with no `Model` wrapper | with no FlightCore `Model` wrapper |
| `trim_environment_walkthrough.md` 24 | S4 | Today, `Model{<:Aircraft}`'s | Today, in Flight.jl, `Model{<:Aircraft}`'s |
| `linearization_walkthrough.md` 27 | S7→S3 | `model = Group((; s = Sum(), c = Pendulum());` | `root = Group((; s = Sum(), c = Pendulum());`, lines 28 to 30 one column left |
| `linearization_walkthrough.md` 465 | gloss | the executor's state at a frame top as one value: the flat | as stage 1 states it |
| `README.md` 4 | S3 | A model is a tree of components that exchange values | A model is written as a tree of components that exchange values |
| `README.md` 98 | S3 | and the build refuses the model: | and the build refuses the tree: |

### Borderline rows kept as S2

Spec 2038 (the D-032 bold headline), 3095 and 9990 (the persona), 3113
("model root"), 4035, 4399 is rewritten with 4398, 4953 (open point), 6645,
8593, 9847, 10565 (the three "declares" sites keep company with "model
code" and "model state"), 10271, 11323 (owner plain once 11311 names
Flight.jl), 9120, 11449, 13400. Companions: `inbound_periphery_walkthrough.md`
26, `library_inventory.md` 67, 79, 167, 175, `linearization_walkthrough.md`
14, 593, `pid_anti_windup.md` 458, `sample_time_proposal.md` 289, 454.
