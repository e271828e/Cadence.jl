# Chapter 7: rulings on the chapter pass and the inbound check

The orchestrator's rulings on `chapter_pass.md` (E1–E18, K1–K7) and
`inbound_check.md`. Each item is accepted, modified or deferred, with its
reason.

## Editorial fixes

- **E1 accepted.** The opening becomes "This chapter fixes where data lives
  and how each home holds its values.", followed by its remaining sentences,
  and "The allocation policy closes the chapter." goes: the roadmap names
  §7.5 two lines later. Supersedes R18's first half.
- **E2 to E12 accepted** as written. E3 is a declared addition; `X` is used
  from §7.1 on and the spec never introduces it (checked by grep). E10 moves
  text with no word changes.
- **E13 accepted.** §7.5's "tiers" become "budgets". The glossary's *tier*
  entry says bare "tier" means only the continuous or discrete side.
- **E14 accepted.** §9.7 calls the phase bodies "the §7.5 measurement seam"
  (spec 4871), and the glossary entry is *measurement seam / phase bodies*.
- **E15 to E18 accepted.** For E17's `#g-view` link, take the gloss from the
  glossary's *view* entry, not the chapter pass's wording, if they differ.
  E16's glosses drop wherever a sentence would carry two parentheticals.

## Ruling items

- **K1 accepted.** "classes" for walked, pinned and exempt in §7.2 and the
  companion paragraph, as the glossary's *tier* and *walked / pinned /
  exempt* entries rule. Link `[tier](#g-tier)` at its first use in §7.2's
  sense, with the gloss "(the continuous or discrete side)". D-011's
  "three-tier scoping" is log vocabulary and is not imported.
- **K2: no edit beyond E9 and E17.** The glossary note is not needed.
- **K3 accepted.** Old line 458 becomes "The reference fields add no
  per-boundary allocation either way." R5's sentence states §11.2's one
  snapshot allocation per boundary; the old sentence's context is the
  reference fields, so the narrowing removes a contradiction and claims
  nothing new.
- **K4 accepted.** "Bulk data and text do not", matching §8.2's message
  (spec 2619, "text and bulk data belong on the component instance"). A
  `Symbol` label is admitted state six lines earlier.
- **K5 accepted.** "never touch the buffer". The glossary separates the
  buffer from the integrator buffers (integration intermediates); the
  sentence's subject is the state vector, as §7.3's opening sentence says.
- **K6 accepted.** The lead becomes "Against that pattern and the Flight.jl
  code around it, this design buys five things." R17 moved bullet 5 off
  FlightCore.
- **K7 deferred to track 2.** The glossary (spec 12432), §8.2 (spec 2686)
  and `src/build.jl` 188 make `m_init` continuous-only; D-231's Position
  says "any leaf's `m`". Spec plus the later entries (D-112, D-249) win, so
  D-231 gets an annotation; nothing in chapter 7 changes.

## Inbound check

- **`extensions.md` 334, COMPANION.** At landing, "§7.2's mechanical
  parametrization of the walked payload list" becomes "§7.2's mechanical
  parametrization of the walked class, whose FlightPhysics payload list
  `companions/migration_outline.md` gives under 'The parametrization
  pass'". "class" follows K1.
- **The four MISSING rows** (spec 4766, 12067, 12549; D-203 Rejected 7349)
  were wrong before the rewrite. Track 2.
- **The 23 VAGUE rows** are pre-existing. Track 2 reviews the "carve-out"
  and "model sweep" wordings against §7.5's new scope sentences.
