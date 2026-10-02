# Unit A: rulings, citations and open items

Order of §8.1 (R6): opening; "Plain Julia, not a macro DSL"; "Declarations
are the schema authority"; "Contracts are functions of the type"; "The
namespace"; "Names". The chapter intro gains two roadmap sentences naming
§8.1 to §8.8 by subject.

Ruled edits applied: R4 (1997–1999), R6, R7 (F2, F12, F17, F24), R8.

## Corrections proposed

None new. Ruled corrections applied:

- F2 (1941–1942). Deleted "The obvious candidate is the `where {T <: Real}`
  ceremony of a continuous `y_types` ([§8.2][s8-2])." Inventory A-026/A-027.
- F12 (2018–2021). Added "The refusal is `ClassUnreadable` ([§8.5][s8-5])."
- F17 (1917–1921). "Four questions" became "Five questions … one per
  subsection", in the new subsection order, with a fifth question for
  "Names".
- F24 (2027). Scoped to "when only a stage is shadowed", and added "An
  optional declaration shadowed in a local scope, such as `state_events` or
  `ws_init`, drops its feature silently ([D-178][d-178])."
- R8 / F1 (2052–2054). Restored "A declaration names the *consequence* it
  has, not its *content* ([D-146][d-146])". `rg` over `docs/` outside
  `spec_rewrite/` finds no other text relying on the inverted reading.

## Citations added or replaced

- D-032 replaces D-166 at "never required to author a component" (1941).
  Position: "convenience macros addable a posteriori, never essential".
- D-032 at "There is no macro DSL" (moved from the old **Why.** sentence to
  the rule; the reason sentence keeps the adjacency). Position: "declarative
  trait layer in plain Julia"; Rejected: "Macro DSL as substrate".
- D-032 at "Every inconsistency fails loudly, at build time where possible
  and at first execution otherwise". Position: "schema authority —
  declarations define, probe evaluation checks (build probe with real values
  + free always-on conformance)".
- D-032 at "A convenience macro remains addable a posteriori". Position:
  "convenience macros addable a posteriori, never essential".
- D-032 at "Declarations *define* the model's structure" (was cited two
  sentences later). Position: "declarations define, probe evaluation checks".
- D-033 at the contracts-by-type rule and at "`ws_init` is the one
  exception". Rationale only (see below).
- D-117 at "extended, not called". Position: "The declaration and stage
  family is extended, not called, and enters a component module through
  explicit per-name `import`".
- D-117 at the first mitigation. Position: "normative authoring surface
  stated in [§8.1]".
- D-117 at the R4 pointer "A re-export submodule is not an alternative".
  Rejected: "A re-export submodule as the ergonomic fix: `using
  Cadence.Declarations` carries identical silent-shadowing semantics —
  per-name `import` is the only extension idiom the language provides". The
  old text's "*unqualified*" is narrower than the log's "only extension
  idiom"; the new text keeps it through "Julia admits that only through an
  explicit per-name `import`, or through a qualified … definition".
- D-164 at "A component that declares nothing and defines no stage is
  rejected at build time" and at "Declarations live at module top level"
  (was cited only at the paragraph's head). Position: "A component that
  declares nothing and defines no stage is a build error; the authoring rule
  is that declarations live at module top level."
- D-246 repeated at "the build throws `DeclarationShadowed` alone" after the
  split. Position sentence 2: "A parent module holding a binding of any
  family name distinct from the framework's function throws
  `DeclarationShadowed` alone".
- D-178 at the F24 addition. Rationale only (see below).
- D-146 at the restored semantic axis (R8). Rationale only (see below).
- §11.7 at the `GUI.draw!` precedent (F14's introducing clause). §11.7:
  "Panels remain per-component extensions in FlightCore's style, such as
  `GUI.draw!(ctx, ::LowPassFilter)`".
- §8.2 at the `StoreWithoutUpdate` gloss and §8.5 at the `ClassUnreadable`
  gloss (survey part A asks for a gloss or pointer). Appendix C 11747 and
  11759 cite these sections for the two kinds; D-263 Position:
  "`StoreWithoutUpdate` applies to a non-empty store only".

## Rationale-only rulings

- D-033, Rationale, log 1024–1028: contract declarations are functions of
  the type, never of field values; `workspace` explicitly exempt; "a rule
  authors keep, not a check the build can run". Bold kept on the rule; the
  log owes a live Position.
- D-146, Rationale, log 4941–4945: the semantic axis, consequence-named over
  content-named (R8). Bold on the restored rule; the log owes a Position.
  Also in `escalations.md` for the owner's audit.
- D-178, Rationale, log 6336–6340: partial local-scope shadowing of optional
  feature declarations "still builds silently with fewer features" (F24).
  Not bolded: the log records it as a residual, not a ruling.

## Bold on the same entry elsewhere

None found. Grep of the other units' `new.md` on 2026-10-02: B1 and B4 bold
rulings citing D-033 (the by-value stores; derived stage membership), which
are D-033 Position rulings distinct from this unit's contracts-by-type
ruling (D-033 Rationale). E1 bolds D-170 rulings; this unit cites D-170
unbolded. No other unit bolds D-032, D-117, D-144, D-146, D-164, D-178 or
D-246.

Within this unit, D-032 carries three bolds, one per Position ruling (plain
Julia trait layer; schema authority; macros addable a posteriori). "Every
inconsistency fails loudly" lost its bold because it states the "+" clause
of the schema-authority ruling, which is bold at "Declarations *define* the
model's structure". D-164 carries two bolds, one per semicolon ruling. D-246
carries two, one per Position sentence.

## Inbound citations affected

- spec 3892, 4167 quote "at build time where possible" and "at first
  execution otherwise": kept word for word.
- glossary 12193 repeats "Types come by declaration, values by execution,
  and conformance by comparison": kept word for word.
- spec 787 ("the inert-component check (§8.1)"): "inert component" kept.
- spec 3459, Appendix C 11755 (shadowing check, `DeclarationShadowed`,
  §8.1): kept.
- log 3696 (D-123 Rejected, "§8.1's condition for accepting redundancy"):
  kept.
- No row names a §8.1 subheading, so the reorder and the retitles break
  nothing.

## Open questions

- "Every inconsistency fails loudly" was a bold-words ruling in the old text.
  It is now plain, cited to D-032, under the one-bold-per-ruling test above.
  If the owner reads it as a ruling of its own, it takes the bold back and
  the schema block's bold goes plain.
- The roadmap sentences summarize each section by its title. "§8.4 gives the
  five failure walkthroughs that ground error locality" follows the glossary
  entry for *error locality* (13039–13042).
