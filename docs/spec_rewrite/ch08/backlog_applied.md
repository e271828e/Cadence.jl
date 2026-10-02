# Chapter 8 track 2: edits applied — 2026-10-02

Applies `rulings_batch.md` K10 to K30 as its Status section rules them. `log`
is `docs/design/decisions.md`, `spec` is `docs/design/spec.md`, and `ext` is
`docs/design/extensions.md`. Every line number is the line **after** all
edits and the `linkify.jl` run. The batch's `N` lines were taken at
`cf9c45c`. The landed chapter sits two lines earlier from §8.2 onward, so
every chapter edit was matched by its text, not its line. New citations were
written bare, and `linkify.jl` linked them afterwards.

## Step 1. New entries (K10 to K15)

The ids follow the Status: D-295 (K10), D-296 (K11), D-297 (K12 with K13),
D-298 (K14) and D-299 (K15). K15's proposal numbered its entry D-300, which
the Status corrects to D-299. The entries sit after D-294 and before the
link-definition block, at log 12259 to 12419. Vocabulary is today's:
`x_init`, `s_init`, `m_init`, `u_types`, `ws_init`, `sample_times`,
`y_connections`, "root input" and "unpinned"/`Pinned`. The source entries say
`init_x`, `init_z`, `init_m`, `workspace`, `rates`, `output_connections`,
"root slot", "`T`-entry" and "`Float64`-entry". The mapping from the last two
to today's words is D-167's own annotation (log 5916–5917): "with
`Pinned{P}` as the spelling of "demands frozen" and an unpinned `Float64`
position as "tolerant"".

### D-295 (K10) — The walk clause's tier scope, the obligation's scope, seedability and the unmarked stores (log 12259)

Spec: §6.1, §8.2, §14.10, as proposed.

- Bullet 1, the clause binds continuous consumers only, and discrete ones take
  the bound check only ← D-167 Rationale, log 5888–5893: "**The clause is
  tier-scoped, and the scope is decisive**: discrete consumers take the
  nominal bound check only, because their stages read exclusively at real
  ticks in the nominal world — a `Dual`-carrying cell exists only inside
  activations discrete stages never run in — so continuous → discrete wires
  are unconditionally legal". The unscoped clause rejected ← D-167 Rejected,
  log 5930: "*The unscoped wiring clause:* rejects every continuous → discrete
  wire". Both stand per D-167's annotation, log 5915–5916: "the permissive
  reading, the walk-compatibility clause, its tier scope and the root-slot
  rules all stand".
- Bullet 2, the genericity obligation binds unpinned entries only ← D-167
  Rationale, log 5905–5908: "The genericity obligation ("whatever scalars the
  wiring delivers, the consumer's math promotes") stays checked by the `Dual`
  probe, now scoped to the `T`-entries — a `Float64`-entry input imposes no
  such obligation, that being its point."
- Bullet 3, a root input's type and cells, and schema-visible seedability ←
  D-167 Rationale, log 5900–5903: "Root slots: the slot type remains the
  entry at `Float64` (concrete tight bound, unchanged); slot cells walk by
  evaluating the entry at the activation's `T`, making **seedability
  schema-visible** — a `T`-entry slot is a lawful linearization `B`-matrix
  tap, a `Float64`-entry slot is declaredly unseedable." "Evaluating" is
  written "retyped", as D-263's Position (log 10242, "by retyping the
  declarations instead of calling them") and K28 spell it today.
- Bullet 4, the stores take no marker, `x_init` walks, `m_init` and `s_init`
  pin wholesale ← D-079 Rationale, log 2340–2342: "The type derived from
  `init_x` walks like a continuous producer's … while `init_m`/`init_z` pin
  wholesale". `Pinned` has no place in a store ← D-166 Rejected, log
  5847–5848: "*Two-argument `init_x` by evaluation:* the `T` records no
  choice — [§7.1] admits no pinned state leaf". The D-079 source is added
  beyond K10's draft. It carries the walk half of the chapter's sentence
  (spec 2589–2591), which D-263's Position covers for `x_init` alone.

### D-296 (K11) — Abstract entries, the record-and-check doctrine, the tight root bound and the tap's pinning consumer (log 12297)

Spec: §8.2, §14.10, as proposed.

- Bullet 1 ← D-078 Rationale, log 2306–2308: "Abstract entries = structural
  substitutability ([§4.4] field handles), never needed for eltype genericity
  (an eltype-generic producer's nominal face is concrete by construction)".
- Bullet 2 ← D-078 Rationale, log 2311–2312: "doctrine: declarations record
  choices, obligations are checked."
- Bullet 3 ← D-078 Rationale, log 2308–2309: "root-slot carve-out — only a
  tight (concrete) bound determines a producerless cell's type".
- Bullet 4 ← D-168 Rationale, log 5956–5960: "such a slot is declaredly
  unseedable, and a `B`-matrix tap selecting it is rejected at tap resolution
  naming the **pinning consumer** and its entry (`TapResolution` payload
  extended), not the face alone, because the author's next move — promote
  that leaf, or route the tap around it — depends on knowing which leaf froze
  the slot."

Left out as not K11's: D-078's abstract-at-root and fan-out clauses, which the
chapter cites to D-236.

### D-297 (K12, K13) — Contracts by type, seeding not typing, one walk convention and declared publicity (log 12323)

Spec: §8.1, §8.2 (K12), with §8.3 and §8.6 added for K13's bullet, as the
Status rules. The title shortens K12's proposal, which named "frozen-exact
discrete outputs" too, so that it can add publicity and stay near fifteen
words.

- Bullet 1, contracts are functions of the type ← D-033 Rationale, log
  1028–1033: "Contract declarations are functions of the component's *type*,
  parameters included (`SumJunction{W,N}`, `Or{N}`), never of field values —
  `workspace` explicitly exempt (by-allocation, [D-077]) — because [§9.7]'s
  entry typing derives the bundle key set from the type; a rule authors keep,
  not a check the build can run".
- Bullet 2, never through typing ← D-079 Rationale, log 2349:
  "differentiation participation = per-invocation seeding, never typing";
  never through initialization ← D-166 Rationale, log 5800: "partials enter
  by per-invocation seeding, never initialization". The D-166 source is added.
  The chapter's sentence (spec 2193) says "initialization", which D-079 does
  not record.
- Bullet 3, frozen-exact discrete outputs and zero-partial initial values ←
  D-079 Rationale, log 2343–2344: "declared `Float64` initial values
  embedding as zero-partial constants; discrete producers pin wholesale
  (frozen-exact by typing rule; …)".
- Bullet 4, the criterion ← D-166 Rejected, log 5856: "the criterion, not
  uniformity, is the rule"; D-263 Rationale, log 10266–10267: "[D-166]'s own
  criterion says a `T` belongs in a signature exactly where the declaration's
  non-nominal behavior is underdetermined by its nominal restriction." D-166
  is added as the source of the sentence's exact words.
- Bullet 5, one walk rule ← D-263 Rationale, log 10273–10274: "carrying two
  conventions cost more than carrying one"; log 10283–10285: "The walk rule
  is one rule, already taught for the state side; a reader who knows that
  `Float64` follows the scalar on the continuous tier reads every declaration
  in the framework with it"; log 10287–10288: "A `Float64` written at a
  participating leaf now walks, which is what the author meant"; log 10280:
  "the pin is on the page, per leaf, schema-visible and conformance-checked".
- Bullet 6, the empty store's absent letter ← D-263 Rationale, log
  10301–10302: "the bundle law puts a store's letter in the bundle only when
  the store is non-empty, so nothing downstream changes."
- Bullet 7, the declaration read as written ← D-265 Rationale, log
  10483–10485: "One consequence for the reader's rule: "every `Float64`
  position follows the scalar" reads the declaration as written, so a
  concretely typed field is frozen without appearing in the contract".
- Bullet 8 (K13), publicity never implicit ← D-034 Rejected, log 1085:
  "*Identity-public on missing `outputs()`:* implicit publicity."; D-041
  Rejected, log 1265: "*Wires-only with implicit facehood:* publicity never
  implicit." The port and the face are named after the two sources: D-034
  is about a leaf's outputs, and D-041 about an assembly's faces.

### D-298 (K14) — Container edges, the builder rejection, `Group`'s trade and the directional two-notation rule (log 12367)

Spec: §8.5, §8.6, as proposed. Restricted as the Status and K14's
recommendation rule. The `===` fact (D-040 Rejected, spec 3031–3032) and the
below-root aliasing (D-210 Rejected, spec 3113–3114) are facts behind
rejections. They stay with those lists, so the title drops "the `===` fact"
and "root-only face uniqueness".

- Bullet 1 ← D-085 Rationale, log 2521–2523: "mixed component/non-component
  elements = build error, zero-component containers = inert data, no
  container nesting (first cut), empty containers legal".
- Bullet 2 ← D-039 Rejected, log 1216–1218: "*Builder (`add!`/`connect!`):*
  dispatch type and structure recipe drift apart — [§8.1]'s disease at
  assembly scale; mutable declaration state; doesn't even capture source
  locations."; D-184 Rejected, log 6586–6588: "*The mutable builder
  (`Assembly()` + `add!`/`connect!`):* [§8.5]'s standing rejection —
  type/recipe drift, mutable state through declaration code, no
  source-location capture." The reasons sit in the Rationale.
- Bullet 3 ← D-184 Rationale, log 6573–6574: "gives up dispatchable identity,
  which exploratory/programmatic composition does not want".
- Bullet 4 ← D-129 Rejected, log 3908: "the rule's real axis was never read
  vs. write"; the directional half is D-129's Position ("slash is structure,
  face names are contract").

### D-299 (K15) — Rate scopes by type, the feed-list doctrine and the helper pair (log 12395)

Spec: §8.7, §8.8, as proposed. Restricted as the Status rules. The bare
rejections stay cited to their Rejected lists: auto-bubbling (D-043, spec
3510), `rename` hooks (D-046, spec 3471) and the two artifacts (D-039, spec
3556). Also left out: the element names as rate keys and the field-name
sugar (D-085 Rationale, spec 3385–3390). K15's evidence lists it, but its
proposal does not name it among the constructive rulings, and the batch puts
the sugar sentence in escalation E1's scope.

- Bullet 1 ← D-042 Rejected, log 1285–1286: "*Instance wrappers
  (`Subsampled`-style):* wraps the field type, pollutes
  paths/dispatch/contract; makes the type-intrinsic ratio a per-instance
  value."
- Bullet 2, one edit and the removed drift class ← D-145 Rationale, log
  4912–4915: "Doctrine recorded with it: adding a channel is one edit (the
  pair simultaneously creates the wire and removes the face from the export
  surface), the two declarations cannot drift because neither holds the
  shared names — the drift class is removed, not merely detected"; authored
  data ← D-145 Rejected, log 4939–4940: "the single source must be authored
  data, never inferred structure." "Export surface" is written "input face
  surface", as the chapter says.
- Bullet 3 ← D-171 Rationale, log 6065–6070: "after [D-170]'s split a single
  call cannot emit into two declarations, so the guarded addition's landing
  shape is a sibling `output_passthrough` splatted into `output_connections` —
  … the name now carrying the direction."
- Bullet 4 ← D-209 Rationale, log 7534–7536: "[D-207] supplies one: with deep
  sourcing removed, every level re-exports the outputs it surfaces, and the
  output side needs the computed spelling the input side already has."
- Bullet 5 ← D-207 Rejected, log 7488–7490: "*Bundled faces as the universal
  ceremony mitigation:* bundling serves component-fed signal highways; at a
  root input it collides with [§4.3]'s write-side granularity and forfeits
  partial scripting ([§8.8])."

## Step 2. Chapter 8 citations

Each new entry joins the source entry's citation. No bold span changed.
`check_bold.jl` still counts 67 spans and 632 bold words in chapter 8.

- D-295: spec 2348 (bold, beside D-263), 2354 ("The unscoped variant is
  rejected", uncited before, so it cites D-295 alone), 2364 (bold, beside
  D-263), 2402 (bold, beside D-263), 2589 (beside D-263), 2593 ("`Pinned` has
  no place in a store", uncited before, so it cites D-295 alone).
- D-296: spec 2319 (bold, beside D-078), 2366 (bold, beside D-078), 2381
  (beside D-078), 2430 (beside §14.10 and D-168).
- D-297: spec 1976 (bold, beside D-033), 2194 (beside D-079), 2521 (the
  second D-265, the declaration read as written), 2545, 2562 and 2595 (beside
  D-079), 2567 and 2587 (beside D-263), 2734 ("Publicity is never implicit",
  uncited before) and 3071 (beside §8.3).
- D-298: spec 2914, 2918 and 2922 (beside D-085), 2985 (`Group`'s trade,
  uncited before, as K14 proposes), 2988 (bold, beside D-039), 3083 (bold,
  beside D-129).
- D-299: spec 3402 (beside the first D-042 only), 3516 and 3543 (beside
  D-171), 3532 (beside §6.1 and D-209), 3593 (beside D-145), 3615 (bold,
  beside D-145), 3626 (beside D-207).

Sentences an entry covers that cite no source entry gain nothing, as in
chapter 10. These are spec 2207 ("The criterion, not uniformity, is the
rule"), 2238 and 2702 (the empty store's letter, cited to §5.2 alone), all
D-297's. Bare rejections and facts behind rejections keep their old
citations: spec 3405 (instance wrapper, D-042), 3510 (auto-bubble, D-043),
3471 (`rename`, D-046), 3556 (two artifacts, D-039), 3613 (auto-bubbling,
D-043 and D-145), 3031–3032 (`===`) and 3113–3114 (aliasing).

## Step 3. K17, annotations and Spec fields

- K17, spec 2670–2671 (§8.2, Completeness). New sentence: "An entry that is
  not a `StateEvent` is `EventHalfMissing` too ([D-215][d-215])." **Placed at
  the end of the paragraph, not straight after the `EventHalfMissing`
  sentence as K17 proposes.** There it would have come before "Method lookup
  catches it at declaration-reading time", so "it" would have pointed at the
  wrong entry, and "the omission" two sentences later would have lost its
  referent. The sentence's text is as proposed.
- K17's consequence: D-215 is now cited in §8.2, so its Spec field gains §8.2
  beside K20's §8.5 (log 7785). This goes beyond K20's list. It is the same
  kind of change recipe step 7.3 makes for the moves.

Annotations are new paragraphs before each entry's `**Rejected.**` line, after
its Rationale. Old text: none.

- K18, D-033, log 1035: "Annotation (2026-10-02): amended by D-165 and D-179.
  `local_types` is deleted, and an event carries no `localize` flag, since the
  guard's return type declares its detection policy. The three declaration
  conventions and derived stage membership stand."
- K18, D-034, log 1072: "Annotation (2026-10-02): amended by D-194. An
  intermediate is an ordinary declared port, so the strict `local_types`
  clause is retired. Declared = public, branch-shape-stable returns and the
  build error for an undeclared return field stand."
- K19, D-039, log 1211: "Annotation (2026-10-02): "per §8.3" in the second
  rejection reads "per §8.5", which states that class, this entry's kind, is
  implementation detail behind the contract."
- K18, D-041, log 1253: "Annotation (2026-10-02): amended by D-170 and D-279.
  The single `exports` method splits by direction into `u_connections` and
  `y_connections`, and endpoint derivation becomes a cross-check on the
  direction each method declares. Face types and tiers derived from the
  endpoints, and wires strictly from child to child, stand."
- K18, D-042, log 1279: "Annotation (2026-10-02): amended by D-254 and D-256.
  `Δt_base` and `h` are fixed at deployment, as `Deployment` constructor
  parameters, not at `Simulation` construction. The optional declaration, its
  immediate-children keys and the error for a key on a continuous child
  stand."
- K18, D-055, log 1608: "Annotation (2026-10-02): amended by D-165 and D-194.
  `local_types` is deleted, and an intermediate is an ordinary declared port.
  The Rejected list stands."
- K19, D-145, log 4928: "Annotation (2026-10-02): "structure kept in two
  artifacts" is D-039's alone, and §8.8 states it; §8.1 holds no such
  phrase."
- K18, D-164, log 5649: "Annotation (2026-10-02): the build error is
  `ClassUnreadable`, the kind for a type declaring neither family (D-039,
  D-122). The error and the authoring rule stand." No later entry amends
  D-164's ruling, so this annotation names the entries that rule the kind:
  D-039's Position ("declaring neither family is a build error") and
  D-122's rename to `ClassUnreadable`.
- K18, D-171, log 6072: "Annotation (2026-10-02): amended by D-209.
  `output_passthrough` is built, so the third rejection no longer holds. The
  rename and the other two rejections stand."
- K19, D-177, log 6335 and 6339, two paragraphs: "Annotation (2026-10-02):
  "§8.3-hidden" in the Position reads "§8.5-hidden": §8.5 states that a
  component's class is implementation detail behind its contract." and
  "Annotation (2026-10-02): "§8.1's reflection class" in the Rationale reads
  "§8.1's shadowing check", the `isdefined`/`!==` test §8.1 holds; §8.1 names
  no reflection class."
- K18, D-184, log 6579: "Annotation (2026-10-02): amended by D-211 and D-279.
  `Group` declares its `children` field name-transparent, one opt-in
  declaration where this entry claimed zero new declaration rules, and its
  connection declarations are `inner_connections`, `u_connections` and
  `y_connections`. The single library type, its instance-field declarations
  and the builder rejection stand."

No annotation on D-166 (Status). K19's other pointers are left (Status).

K20 Spec fields. Each section was confirmed to be cited by the entry in that
section of the landed chapter. Each goes in its field's own order. D-170's
field runs §11.3 before §8.x, and D-179's runs §10.4 before §8.1, so §8.1
and §8.2 join each field's §8 run.

| entry | log | added | field after |
|---|---|---|---|
| D-032 | 989 | §8.3 | §8.1, §8.3, §8.4 |
| D-046 | 1397 | §8.8 | §8.6, §8.8 |
| D-078 | 2304 | §8.2 | §4.4, §8.2, §9.1 |
| D-079 | 2338 | §8.2 | §7.1, §8.2, §8.5, §9.4, §9.5, §14.10 |
| D-094 | 2765 | §8.2 | §7.1, §8.2, §10.4, §14.3 |
| D-170 | 6036 | §8.1 | … §11.3, §8.1, §8.2, §8.5 … |
| D-171 | 6062 | §8.1 | §8.1, §8.8 |
| D-179 | 6411 | §8.2 | §2.1, §10.4, §8.1, §8.2, §9.3, §9.5 |
| D-194 | 6944 | §8.2 | … §5.4, §8.2, §8.3, §9.1 … |
| D-215 | 7785 | §8.5 (and §8.2, K17) | §8.2, §8.5, §13.2, Appendix C |
| D-226 | 8333 | §8.1 | §4.4, §8.1, §9.4, Appendix B, Appendix D |
| D-237 | 8796 | §8.2 | §4.3, §4.4, §8.2, §9.5, Appendix C |
| D-238 | 8851 | §8.2 | §6.1, §8.2, §9.5 |
| D-239 | 8891 | §8.3 | §8.3, §8.4, §13.1, Appendix C |
| D-249 | 9344 | §8.2 | §8.2, §8.5, §8.6, … |
| D-254 | 9639 | §8.7 | §8.7, §9.2, §10.5, … |

D-146 is untouched while E2 is open. The four stale §8.1 and §8.3 entries are
left for the owner (D-039, D-145, D-179, D-182).

## Step 4. Outside chapter 8

- K24, spec 9710 (§13.7). Old: `**The passthrough helpers take a
  predicate.** `select` is the third`. New: `The passthrough helpers take a
  predicate. `select` is the third`. §8.8 keeps its bold.
- K26, spec 12046 (Appendix C, `TierUnreadable`). Old: `([§8.2][s8-2],
  [§8.5][s8-5])`. New: `([§8.2][s8-2])`.
- K26, spec 12050 (`StatelessWithoutOutputs`). Old: `([§8.2][s8-2],
  [§8.5][s8-5])`. New: `([§8.2][s8-2], [§8.3][s8-3])`.
- K26, spec 12236 (`ArgumentInvalid`). Old: `([§8.7][s8-7], [§11.6][s11-6],`.
  New: `([§10.5][s10-5], [§11.6][s11-6],`. The three `src/diagnostics.jl`
  docstrings are left for the owner.
- K27, spec 7406 (§11.6). Old: `implementation detail behind its contract
  ([§8.3][s8-3])`. New: `… ([§8.5][s8-5])`.
- K27, spec 12857–12858 (glossary, *nominal*). Old: `demands exact type match
  ([§8.2][s8-2],` / `[§9.4][s9-4], [§9.5][s9-5]).` New: `demands exact type
  match ([§9.4][s9-4],` / `[§9.5][s9-5]).` Spec 7134 is left for chapter 11.
- K28, ext 286. Old: `declarations *evaluated at the activation scalar*`. New:
  `declarations *retyped at the activation scalar by the leaf walk*`. The line
  is not rewrapped.
- K30, spec 13375–13376 (glossary, *seam*). The list ends: `… the phase-body
  seams of the compiled executor ([§9.7][s9-7]), the generic seams of an` /
  `assembly tree ([§8.8][s8-8]).`

Left per the Status: K16 (owner's list), K21, K22, K23, K25 (their chapters'
rewrites), K29 (owner).

## Step 5. Battery

The edit script read the three files and asserted all 70 matches, each found
exactly once, before it wrote anything. `git diff --stat` then showed only
`decisions.md`, `extensions.md` and `spec.md`. `linkify.jl` ran, then:

- `check_refs.jl`: OK — every citation and every anchor resolves.
- `check_rows.jl`: OK — every decision citation names an existing entry.
  Newly cited by the spec: D-295 to D-299. Coverage shrank nowhere.
- `check_glossary.jl --strict`: OK, 170 entries.
- `check_bold.jl`: OK. Chapter 8 has 67 bold spans and 632 bold words,
  unchanged. Chapters 9 and 10 are unchanged.

The second `linkify.jl` run changed nothing, and the diff was byte-identical
before and after it.
