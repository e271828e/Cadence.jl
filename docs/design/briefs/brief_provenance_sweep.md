# Brief: the "provenance" sweep

Tip at drafting: `8b1ba79`. The bullet retired: `pending.md`, "The
"provenance" sweep". Ruled with the user on 2026-09-23.

## Purpose

The word "provenance" is obscure and means seven different things across the
tree. Each meaning gets one plain replacement, fixed below, and the word
leaves the live files: the spec, the log, `extensions.md`, the companions,
the tools, `implementation.md`, `pending.md`, `src/` and `test/`. The reports
under `docs/reports/` and the other briefs under `docs/design/briefs/` are
frozen evidence and keep the word. This brief keeps it too.

Design and code are peers. Nothing here moves a concept's boundary; every
site is a word substitution or a one-sentence rewrite, so the log is swept
too (`tools/decisions_style.md`, rule 2's word-substitution exception, under
rule 7's audit).

## The meanings and their words

Classify every site by reading it, never from the line alone. The
table gives the word and the sentence shape; the sites named are the ones
already read, not an exhaustive list.

| # | meaning | word | shape |
| --- | --- | --- | --- |
| 1 | a component's rate declaration chain, the `Relative`/`Absolute` links down the tree, and the anchor's declaring scope and key (§9.1, §9.2, the schedule and anchor tables, `GridUtilization`, `ReplayHeaderMismatch`'s schedule arm) | **rate chain** | "per component the declaration provenance as its `Relative`/`Absolute` chain" → "per component its rate chain of `Relative`/`Absolute` links"; "the anchor and provenance columns" → "the anchor and rate-chain columns"; "from the provenance column" → "from the rate-chain column". The code's word already: `ComponentEntry.rates::Vector{RateLink}`, `_rates_label`. At `GridUtilization` (spec Appendix C, "each entry's provenance") the pool entry's origin is its anchor: "each entry's anchor". |
| 2 | a face's route to its producing terminal (§13.7, §9.1's two-sided face table, the `Structure` printer, D-249, D-257) | **route** | "face provenance" → "face routes"; "the face-provenance printer" → "the face-route printer"; "faces and their provenance" → "faces and their routes"; "a face-provenance table" → "a face-route table"; "provenance-printed" → "route-printed". §13.7's heading becomes "13.7 Tooling consequences: face routes and the component library"; D-249's title becomes "Settle three payload columns: contract arity, runtime time and face routes". Both re-run `linkify.jl`. |
| 3 | a condition entry's path through `combine`, `at` and `override` to its leaf, rendered `combine[1] → at("plant") → fragment(x).q` (§14.2, §14.3, §14.6, `ConditionResolution`, `DuplicateConditionLeaf`, `CEntry`) | **origin** | "both provenance chains" → "both origins"; "the provenance chain" → "the origin"; "provenance keeps both sources" → "the origin records both layers"; "before any resolution pass or provenance chain exists" → "before any resolution pass runs or any origin exists". Fields: `ConditionResolution.provenance::String` → `origin`, `DuplicateConditionLeaf.provenance::Vector{String}` → `origins`, `CEntry.prov` → `origin`. |
| 4 | the declaration a wiring or container diagnostic names as its source: the wire, interface-connection or `sample_times` entry, the container field and element (Appendix C, `UnknownPort.entry`, `PathResolution.entry`, `TwoProducers`, `ChildNameCollision`, D-249's `FaceNameCollision` bullets) | **declaration** | "both provenances" → "both declarations"; "both producer terminals with provenance (sibling wire / interface connection entry)" → "both producer terminals with their declarations (…)"; "no per-entry provenance" → "no per-entry declaration"; "named with their provenance" → "named with their declarations". Field: `ChildNameCollision.provenance::Vector{String}` → `declarations`. The `entry::String` fields keep their name and drop the word from their comments ("the declaring method and entry"). |
| 5 | the read-only widget's label naming who drives it, a component ("driven by `avionics/throttle_cmd`") or a claiming device ("claimed by `T16000M` — task dead") (§11.7, §11.3, the `orphaned claims` gloss, D-047's and D-106's lines) | **source** | "read-only with provenance" → "read-only with its source shown"; "renders the fact in its provenance" → "renders the fact in its source label"; "with the source as provenance" → "with its source"; "(claimed, with provenance)" → "(claimed, source shown)". The heartbeat sentence (§11.4, "a liveness display and a provenance record, never a kill trigger") drops the word: "a liveness display and a record". |
| 6 | a feedthrough edge's cause, the port and face that made it (§9.1's `Structure` line, `build.jl`'s `_outputs` docstring, D-253's roster line) | spell it: **port and face** | "the feedthrough edges with provenance" → "the feedthrough edges with their port and face"; "`edges` carries the per-dependence provenance Kahn itself discards" → "`edges` keeps each dependence's port and face, which Kahn itself discards". `implementation.md`'s `build.jl` row: "the feedthrough graph with its edge provenance" → "the feedthrough graph with each edge's port and face". |
| 7 | the stable device id that tags trace entries across runs (the log's "trace provenance", "replay provenance", "no trace provenance"; `companions/inbound_periphery_walkthrough.md:61`) | **trace tag** | "trace provenance" → "trace tag"; "replay provenance" → "the replay's trace tag"; "no trace provenance" → "no trace tag". §11.3 already says "tags entries with a stable device id". |

## The one-off sites

These fit no meaning above and get the rewrite given, nothing more:

- spec §8.5 (near line 2642), "`resolve` as a provenance primitive (§13.3)" →
  "`resolve` as the inspection primitive (§13.3)".
- spec §13.4 (near line 3719), "Values carry no provenance, and the diff
  identifies it." → "A value does not say which branch produced it, and the
  diff identifies it." Log D-1xx's mirror (near line 1482, "values carry no
  provenance — the diff …") takes the same words.
- spec §11.6 (near line 5766), "Raw-stick provenance, re-running a session
  through *different* curves, is the known, accepted loss." → "The raw stick
  levels are the known, accepted loss: re-running a session through
  *different* curves is impossible."
- spec §11.3 (near line 5516), "(the provenance rule, §13.7)" → "(printable
  like the face routes, §13.7)".
- spec Appendix C, `ReplayHeaderMismatch`, the closing sentence "The build's
  and the trace's provenance." Ruled: delete it. The struct carries `what`,
  `path`, `name`, `expected`, `found` and nothing else; the sentence names a
  payload that does not exist. Report the deletion.
- log, D-0xx near line 4975, "provenance clean" in a health-signal list →
  "origins clean" (the list is trim's, the condition's origins).
- log, near line 7262, "inspection, logging, provenance — untouched" →
  "inspection, logging, the face routes — untouched" (D-207's read-side list;
  `src/assembly.jl:281`'s comment mirrors it: "inspection, the face routes,
  the table accessors").
- log, near line 7419, "keeps a bare name's provenance evident" → "keeps a
  bare name's declaration evident".
- log, D-106 near line 2454, "Device roster representation and provenance
  (§11.3)" → "Device roster representation and trace tags (§11.3)".
- `extensions.md:13`, `:214` and `companions/sample_time_proposal.md:22`, the
  header line "Provenance: distilled from …" → "Source: distilled from …".
- `companions/sample_time_proposal.md:557`, the table header `provenance` →
  `rate chain`.
- `companions/trim_environment_walkthrough.md:328`, "Only the rig and the
  provenance of `atm` changed" → "Only the rig and where `atm` comes from
  changed".
- `tools/decisions_style.md:54`, "No provenance — which review round or
  finding raised a decision belongs to …" → "No history — which review round
  or finding raised a decision belongs to …".
- `tools/gloss_table.md:120`, the `Structure` row, follows the spec glossary's
  new wording word for word.

## Stage A: the documents (Sonnet)

Files: `docs/design/spec.md`, `docs/design/decisions.md`,
`docs/design/extensions.md`, `docs/design/companions/*.md`,
`docs/design/tools/gloss_table.md`, `docs/design/tools/decisions_style.md`,
`docs/design/implementation.md`, `docs/design/pending.md`.

Read first: `tools/spec_style.md`, `tools/decisions_style.md` (rules 2, 3 and
7), and `implementation.md`'s "Authoring caveats". Read the spec by section
via its heading outline, never whole; `rg -n -i provenance` gives the sites,
and each site is read with its paragraph.

Rules:

- Every changed line traces to a site in the tables above. No other edits,
  no reflowing of untouched lines. Where a substitution lengthens a line past
  the file's wrap, rewrap that paragraph only.
- The log is a word substitution per rule 2: positions survive verbatim
  except for the word. D-249's title changes in its heading and in the index
  row; `linkify.jl` regenerates the reference labels for it and for §13.7.
- `pending.md`: delete the "provenance" sweep bullet. Nothing else moves.
- After editing, run from the repository root, in this order:
  `julia docs/design/tools/linkify.jl`, `julia docs/design/tools/check_refs.jl`,
  `julia docs/design/tools/check_rows.jl`, `julia docs/design/tools/check_glossary.jl`.
  All green before the commit.
- Verify: `rg -n -i provenance docs/design --glob '!briefs/*'` returns
  nothing.
- One commit, subject line only:
  `Retire "provenance" from the design documents, one plain word per meaning`.

## Stage B: the package (Sonnet)

Files: `src/diagnostics.jl`, `src/conditions.jl`, `src/assembly.jl`,
`src/build.jl`, `test/test_diagnostics.jl`, `test/test_conditions.jl`,
`test/test_assembly.jl`.

Read first: `implementation.md`'s "Authoring caveats" and its file-table rows
for the four source files; `implementation.md`'s "Running the suite" is the
one home of test policy. This brief's Stage A commit is the predecessor; its
tip hash comes with the launch.

Changes:

- `src/diagnostics.jl`: `ChildNameCollision.provenance` → `declarations`;
  `ConditionResolution.provenance` → `origin`;
  `DuplicateConditionLeaf.provenance` → `origins`. The helper `_prov(d, i)`
  serves two structs with two field names now, so it splits:
  `_declaration(diagnostic, i)` over `declarations` for `ChildNameCollision`
  and `_origin(diagnostic, i)` over `origins` for `DuplicateConditionLeaf`,
  each with the same fallback text. Every `d.provenance` read in the message
  methods follows its struct. Docstrings and field comments take the table's
  words (`TwoProducers`' docstring, `UnknownPort.entry`'s and
  `PathResolution.entry`'s comments, `ReplayHeaderMismatch`'s schedule-arm
  message "the anchor and provenance included" → "the anchor and rate chain
  included").
- `src/conditions.jl`: `CEntry.prov` → `origin`, every `e.prov` and the
  `prov::String` parameter of the `_flat` methods → `origin`; the
  `DuplicateConditionLeaf` and `ConditionResolution` constructions follow the
  field renames; docstrings and comments take meaning 3's words.
- `src/assembly.jl`: the `prov` vector in the walk (`assembly.jl:119`) and
  `_check_child_names`' parameter → `declarations`; the three
  `ChildNameCollision` constructions pass `declarations = …`; the comment at
  `:281` takes the rewrite above.
- `src/build.jl`: the `_outputs` docstring sentence, meaning 6.
- `test/`: every `provenance =` keyword and `.provenance` read follows the
  field renames; the fixture `assembly_provenance` and its call in the file's
  test function → `assembly_rate_chains`; the testset name at
  `test_conditions.jl:70` → "a `combine` collision names both origins and the
  layering combinator (§14.2)"; comments at `test_conditions.jl:99`, `:130`
  and `:428` take meaning 3's words.

Rules:

- Descriptive names: no single-letter parameters in touched code. `d` for a
  diagnostic in an untouched method stays; a method this stage touches
  renames it to `diagnostic` in that method only. `e` for a `CEntry` in a
  touched line becomes `entry`; `i`, `j`, `k` in one-glance loops stay.
- Every changed line traces to a site above. No other edits.
- Verify: `rg -n -i provenance src test` and `rg -n '\bprov\b|_prov\b' src test`
  both return nothing.
- The suite: `diagnostics.jl` changes beyond a new kind, so the routing
  table's last row applies and this stage runs the gate itself, in the
  foreground, under the sandbox flags, with a 600 s timeout. Green before the
  commit. Never run it in the background; never stash, reset or check out the
  working tree.
- One commit, subject line only:
  `Retire "provenance" from the package, one plain word per meaning`.

## Report

Each stage reports, in this order: the files touched with the count of
sites per file; the sites whose meaning was not obvious from the table and
the word chosen, with the paragraph quoted; any site left with the word and
why; the tool or suite output's last lines; the commit hash.
