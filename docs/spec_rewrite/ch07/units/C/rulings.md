# Unit C (§7.3): rulings and flags

Rulings applied: R4 (three D-231 bolds), R6 (M6), R7 (labels "Stores:
discrete state and modes", "Workspace", new "Idioms"; M7's double-buffering
sentence at the end of the stores block, citing D-013), R8 (F1, F2, F3, F5).

## Corrections proposed

None new. Left as written and flagged:

- F13, old 1785 (unit line 133): "It is optionally enforceable by an
  op-forbidding `ValueSnapshot{N,T}` wrapper". The sentence was split in two
  ("That wrapper is an `NTuple` …") with no change of claim. No such type
  exists in `src/`, the log or the rest of the spec. Owner's list.
- Survey F1's two unruled notes stand: `Xoshiro` has a fifth field, `s4`,
  which the example leaves untouched; D-231 Rationale (log 8588–8589) says
  the spec "stays silent on the generator's internals", while the example
  names `s0` to `s3`. Only the `s_init` line changed (R8 F1).

## Citations added or replaced

- D-013 at "Discrete state … live in typed stores" (the bold), at "A
  workspace is component-declared mutable scratch", and at the Kalman idiom.
  Position: "Immutable `z` in cells + workspace + snapshot idiom." The
  Position's `z` and "cells" are old vocabulary (D-195, D-121), not imported.
- D-302 beside D-013 at the stores bold, after verification: D-013's
  Position names `z` (now `s`) and not `m`. D-302 Position: "A store is the
  framework-owned home of one of a component's state letters, `x`, `s` or
  `m`."
- D-302 at "The vocabulary of §4.1 never counts a store as a cell". Position:
  "Stores are not cells (D-121)."
- D-231 at the field rule (bold): Position sentence 1, "Every field of a store
  value … is isbits or a `Symbol`". At the latitude sentence (bold): sentence
  2, "The frozen-reference latitude of §4.1 stays with signals." At the PRNG
  sentence (bold): sentence 3, "A PRNG object is workspace; the values that
  determine its next draw are the state."
- D-074 at "`x_projection` is positional and receives none". Position:
  "`project(comp, x)` alone stays positional" (old name, not imported).
- D-183 at "It must carry no information between calls" and at "The framework
  never inspects or mutates a workspace" (bold; moved from the paragraph's
  last sentence, which keeps it by adjacency). Position: "the framework never
  inspects or mutates a workspace … no information carried between calls".
- D-077 at "A workspace is declared by allocation" (bold) and at "The
  allocator is called once per activation … and once per scratch-store set".
  Position: "Workspace by allocation … the method *is* the allocator, called
  per activation and per scratch-store set."
- D-263 at "`ws_init(::C, ::Type{T})` takes the activation scalar on both
  tiers" (bold). Position bullet 4: "keeps its scalar and takes it on
  **both** tiers; the framework passes `Float64` to a discrete allocator at
  every activation."

Not cited: D-194 for `ws` as the mutable-scratch channel, because its Position
points to §7.3 for it (lesson 16). D-121 for the store vocabulary, because
D-302 amends it and cites it.

## Rationale-only rulings

None added. Citations the old text already carried, kept, where only a
Rationale, Rejected list or annotation carries the claim:

- D-013 Rejected (log 545), "*Double-buffering:* deferred", for the deferral
  sentence (M7).
- D-220 Rationale (log 8111–8113) and annotation (log 8133) for "The `init`
  in `ws_init` means *establish*".
- D-231 Rationale (log 8584–8588) and Rejected (log 8605–8606) for the
  rematerializing sentence.
- D-077 Rejected (log 2284–2287) and D-263 Rationale (log 10348–10357) for
  the allocator's reason paragraph.

## Bold on the same entry elsewhere

- D-231: §9.1 (spec 3728) bolds "The isbits rule is checked on `s_init` and
  `m_init` field by field". §7.3 bolds the field rule. Two rulings joined by
  "and" in Position sentence 1, per R4 and the brief's recorded reading.
  D-231 sentences 2 and 3 are bold nowhere else.
- D-263: chapter 8 bolds sentence 1 (spec 2189) and other bullets (2231,
  2292, 2338, 2354, 2367, 2406, 2499), and chapter 9 one at 3742. None is
  bullet 4, which §7.3 bolds. No overlap.
- D-013, D-077, D-183: bold nowhere in chapters 8–10 or in units A, B, D.

## Inbound citations affected

None. Checked: spec 2007 (§8.1, the `KF` allocator, carried verbatim); spec
545 and D-243 ("interned, immutable and never freed", the nesting sentence,
both kept); spec 2606, 3733 ("the isbits rule of §7.3"); glossary *blessed*
(the workspace-plus-snapshot idiom); glossary *workspace* and *store*; D-231
Rationale 8576 (the opening's "governed by contract rather than by checks",
kept word for word). No row names a `####` label of §7.3.

Pre-existing, unchanged by the rewrite: `src/diagnostics.jl` 1043,
`src/executor.jl` 383, `src/build.jl` 1619, `test/test_store.jl` 176 and
`test/test_failures.jl` 722 cite §7.3 for "a discrete successor is the
store's own type exactly", which §9.5 states and §7.3 does not. Track 2.

## Open questions

- The glossary links: one `[ticks](#g-tick)` link dropped (the second in the
  section); `[stores](#g-store)` added at the first use, in the context
  paragraph's closing sentence. Glosses added at first use for buffer, store,
  tick, replay, probe, boundary and blessed. The `activation` link moved
  into the bold rule, its first use. After verification, its old gloss moved
  there too, as a sentence after the bold that also glosses *tier*: "An
  activation is the build's typed products at a given scalar type, and a
  tier is the continuous or the discrete side." Inventory claim C-082 maps
  the moved gloss.
- "not snapshotted, not replayed" (row 50) and the `SArray` codegen claim (row
  65) have no entry stating them (survey part E). Stated as written.
