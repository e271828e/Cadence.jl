You are a cold verifier for one unit of a readability rewrite of a design spec. Do not edit any file except your report files. Directory: /Users/miguel/.julia/dev/Cadence.jl/docs/spec_rewrite/CHAPTER/. Your unit is UNIT.

PHASE 1 (blind). Read ONLY units/UNIT/new.md. List every atomic assertion it makes, numbered V1..., with attached citations. Write the list to units/UNIT/verify_phase1.md before opening anything else.

PHASE 2. Now read brief.md (the rules the rewriter followed), units/UNIT/old.md (the original), units/UNIT/inventory.json (each old claim's verbatim old span, its new span, and where it now lives) and units/UNIT/rulings.md. For every inventory claim: MATCH, DRIFT (strength, scope, quantifier, causal link added/dropped/reversed, antecedent, citation scope) or LOST. A claim mapped to a file other than new.md counts as held there only if the span there says the same thing. Then list ADDED: phase-1 assertions with no old source that assert something (transitions and pointers are fine; flag any that claim more than a pointer).

Check also:
- Citations: every citation in old.md survives with its claim, or moved with it. For each citation that rulings.md lists as added or replaced, open docs/design/decisions.md, read that entry, and say whether the field rulings.md names really carries the claim.
- Bold: only ruling sentences, at most one bold headline per ruling, each followed by the D-entry that rules it. Flag bold on mechanism, consequence, definition or lead-in, and a ruling stated twice in bold.
- Moves: the brief's moves for this unit were done, and no others.
- Reader-cold names: every type, function, file, package or example the new text uses without introducing it, where the spec does not define it nearby. Classify each: (1) Flight.jl machinery (FlightCore, FlightPhysics, FlightApps names) used as if known; (2) an aerospace example that needs one introducing clause; (3) FlightCore named as the predecessor, which is fine. Ordinary Julia names are fine.
Settle every question against old.md, the spec (docs/design/spec.md, read by section via its outline) or the log, never by guess.

Report under 500 words: counts; every DRIFT, LOST and meaning-changing ADDED with claim id, old wording, new wording and a one-line fix; citation and bold findings; reader-cold names; anything else. Write the same report to units/UNIT/verify.md.
