# Unit E (§10.7) cold verification

## Counts

The blind pass found 64 assertions (V1–V64, in `verify_phase1.md`). The inventory has 82 claims: 81 MATCH (E-079 is the ruled F11 edit), 1 DRIFT (minor), 0 LOST. There are 8 ADDED items: 2 intro sentences, 2 `####` labels and 4 glosses. None changes meaning. The glosses match the glossary entries for g-frame, g-trace, g-pacing and g-operator-interrupt. `check_unit.py` reports 0 failures.

## DRIFT

- **E-010, citation scope.** The old sentence "Event localization runs identically paced or unpaced, and its sweep cost is absorbed as debt like any other expensive frame (§10.4)" put §10.4 over both clauses. The new text splits it, so §10.4 and D-080 now cover only the first sentence: "Event localization runs identically paced or unpaced (§10.4, D-080). Its sweep cost is absorbed as debt …". D-080's Position carries both clauses, so the adjacent citation still covers the second. Fix: none required. Optionally repeat "(D-080)" after "expensive frame".

## F11 and other facts

"applied at the next boundary" became "which are drained at the next frame top". D-022's Position ("staged inputs drained at frame top") and base spec lines 5064–5066 support it. This is the only change of fact. Rewordings such as "its deadline being" to "because its deadline is" and "so" to "As a result" keep each link's direction, and every antecedent resolves the same way.

## Citations

No old citation is lost. Each added citation was checked against `decisions.md`.

- **D-021, five additions.** Its Position states four of them directly: pacing outside the semantics, the piecewise-affine map, the hybrid wait with one knob, and the knob's 0/∞ endpoints. At "`margin` is a single constant calibrated to …" the Position carries only "single knob". "No second threshold" is carried by Rejected. The calibration target is description. That is acceptable, but `rulings.md` lists the Rejected support under "Citations added", not under "Rationale-only rulings".
- **D-080.** Its Position states pace-independence, which carries the claim.
- **D-133, twice.** Its Position states both the `5·h/p` threshold and the 2 ms default. D-198 amends D-133 only for the join timeout.
- **D-027.** Its Position states the claim.
- **D-132.** Only its Rationale names the wait as an unmask point. This is correctly listed as rationale-only.
- **D-269, at the bold "The wait sits at the frame top, after the control plane is consulted".** Position bullet 3 says the control plane is consulted at frame top alone. No field says that the wait sits at the frame top. The citation is weak. The log owes a Position sentence for it, and `rulings.md` admits this only for the ordering.

## Bold

There are 9 bold headlines, each followed by its D-entry. None marks a mechanism, consequence, definition or lead-in. No ruling is bolded twice.

- **The new D-080 bold.** D-080's Position states the ruling. It is bold nowhere else: base §10.4, `B1/new.md` and `B2/new.md` cite D-080 plainly, and §2's sentence is plain. The bold is justified.
- **The old list-item bolds** (`margin = 0` and the others) were lead-ins. Removing them is correct.
- **The forgiveness sentence** is now bold in full. The old text bolded only "five frames' worth of budget, `5·h/p`". The added words are acceptable but heavier.

## Glossary links

"pacing" and "debt" both point to `#g-pacing`, as in the old text. The glossary entry is "pacing / pacer debt". The debt link moved to the first use of "debt", which is correct.

## Moves

The three optional labels are used. F11 is applied, F12 is left as written, and the D-268/D-269 conflict is listed in `rulings.md`. No other moves were made. One placement issue: the old "Forward pointers" paragraph (staging slot, §11/§12, §10.3) now sits under "#### Diagnostics", where it does not belong. Fix: give it its own label or a lead-in. Alternatively, accept it and say so in `rulings.md`.

## Reader-cold names

- **(3) FlightCore**, named as the predecessor ("FlightCore's behavior"). Fine.
- **No (1) or (2) cases.** `libuv`, `sleep`, `Libc.systemsleep` and `GC.safepoint` are Julia names. `DebtReanchor` points to Appendix C.
- **Pre-existing, kept from the old text:**
  - `p`, `τ` and `t_anchor` are never introduced. Suggest "with `p` the pace and `τ` wall-clock time" at the map.
  - "control plane" has no glossary link. `#g-control-plane` exists.
  - "the table" in the framework-status gloss means the signal table.

## Re-check

I checked each fix against `old.md`, the log and the current `new.md`, `inventory.json` and `rulings.md`. `check_unit.py` reports 0 failures. The fixes broke nothing: no clause is dropped and every antecedent still resolves.

- **D-080 after "expensive frame".** D-080's Position carries the clause. E-010 is now MATCH.
- **The wait-placement sentence.** It is now plain and uncited. D-269 stays on the next sentence, which its bullet 3 carries. The old text bolded this sentence. No log field rules it, and `rulings.md` records that the log owes a Position sentence. Whether it stays plain is the owner's call.
- **The D-021 margin support.** It is now listed under "Rationale-only rulings" as Rejected support.
- **The forgiveness bold.** Only the headline clause is bold now. The D-133 citation is still in the sentence.
- **The new label.** It fits the paragraph, and the intro names four parts. Bookkeeping: E-077 maps "Forward pointers." to the staging sentence, while the label is listed under `added`. Fix: map E-077 to the label and drop the label from `added`.
- **The new glosses.** The p, τ and anchor-pair glosses claim nothing beyond the formula. The control-plane gloss is a subset of `#g-control-plane`. "signal table" matches the glossary.
- **Line lengths.** Two prose lines run past 80 columns: new.md line 29 (100 characters) and line 116 (83). Fix: reflow them.
