# Unit A rulings: the chapter heading, the new opening and §7.1

Line numbers are `spec.md` lines at `8032ff2` unless marked `log`
(`decisions.md`). Claim ids are `inventory.json`'s.

## Corrections proposed

None new. Applied as ruled: R1 (the opening), R2 (A-008, A-052, A-056),
R17 (A-065, the mapping layer is Flight.jl's), R18 (the opening's last
clause, and A-006's pointer "§8.2 shows the kind's messages"), R4 (A-030, D-190 plain), R6 (A-037 to A-043), R8 F9 (A-052, A-056),
F16 (A-019), F17 (A-006). R10 keeps A-049 whole.

- **F4 has no sentence left in §7.1.** R6 M2 cuts "The buffer holds `x`, the
  stores hold `s` and `m`, and the table holds produced signals" to the
  pointer, so F4's corrected wording ("the `s` and `m` stores hold `s` and
  `m`") has nowhere to land in §7.1. A-042 maps the cut sentence to §5.2 822,
  which carries the same stale wording, as does the glossary's *one home per
  datum* (12532). Carry note for chapter 5 and track 2: apply F4's wording
  there.
- **F15 untouched** (1584–1585, "OrdinaryDiffEq or custom", "HDF5
  logging"). Left as written, as ruled.

## Citations added or replaced

| claim | entry | words that rule it |
|---|---|---|
| A-003, state declared by value | D-033 Position, log 1020 | "`init_*` by value (type derived — nothing to drift)". §8.2 2217 holds the bold; this is plain |
| A-004, the declaration is a `NamedTuple` | D-247 Position | "Every by-value store declaration … returns a `NamedTuple` with one named field per leaf, and no other form is admitted" |
| A-004/A-005, the closed vocabulary (now bold) | D-094 Position | "State leaf vocabulary closed (§7.1): … leaves are plain real scalars and `SArray`s at the common eltype — no domain wrapper types". Moved from 1512 to the vocabulary sentence; 1512's citation now sits on the flat-declaration sentence (A-010), so D-094 is at both rulings |
| A-010, the declaration is flat (now bold) | D-094 Annotation 2026-09-14 | "the declaration is also flat … the check that enforces the vocabulary refuses nesting with the rest". Listed below |
| A-006 (F17), `IllegalStateLeaf` | §9.1, §8.2 (pointers) | Appendix C 12001 lists the kind under §7.1 and §8.2; §8.2 2604–2617 gives the messages; §9.1 3728–3731 places the check in the structure step |
| A-015, the value passed to every function receiving state views | D-035 Position | "every component function receives zero-copy views of the stores it genuinely reads" |
| A-020, projection written back at the two positions | D-111 Position | "its return is written back to the buffer wholesale at both §7.1 schedule positions" |
| A-031, the buffer is authoritative, typed values ephemeral (bold) | D-010 Position | "Structured immutable state over a framework-owned flat `Vector{T}`." D-010 is cited nowhere else in the spec. Its link definition is new; `linkify.jl` generates it |
| A-039, CSE over views rebuilt per call | D-288 Position bullet 2 | "Views are rebuilt per call. Hoisting is the code generator's common-subexpression elimination, and the framework maintains none." The legality condition is Rationale only, listed below |
| A-041, one home per datum | D-035 Position | "the table holds produced signals only, never transported ones (one home per datum)" |
| A-044, ports returned from `y_state` | D-252 Position | "A component exposes a state or mode field by returning it from `output_state`" (renamed `y_state` by D-267) |
| A-065, the mapping layer deleted | D-072 Position bullet 1 | "The `get_*_ss`/`assign_*_ss!` shuttle layer is deleted, discharging §7.1" |

The opening's §7.1 to §7.5 and §5.2 are pointers. The executor's glossary
link left with the cut M1 text; §7.1 no longer names the executor.

## Rationale-only rulings

| claim | entry | field | log line |
|---|---|---|---|
| A-010, the declaration is flat (bold) | D-094 | Annotation 2026-09-14 | 2780–2784 |
| A-040, the buffer-unchanged-within-a-sweep rule is the CSE's legality condition | D-288 | Rationale ("whose legality condition is the staleness rule") | 11994–11995; also D-086 Rationale 2559–2560 |
| A-045 to A-055, why the vocabulary is closed, the explicit cast, where invariants live | D-094 | Rationale | 2771–2778 |
| A-027 to A-029, derivative completeness is structural | D-190 | Rationale | 6837–6840 |

D-094 owes a Position stating the flat declaration. No entry words "the
buffer is authoritative" (survey part E), and no entry states
"`Int`s, enums and `Bool`s belong in modes".

## Bold on the same entry elsewhere

None. §7.1's three bolds are D-094 Position (A-004), D-094 Annotation
(A-010) and D-010 (A-031). Chapters 8 to 10 cite D-094 once, plain (§8.2
2605), and D-010 nowhere. Units B, C and D's `new.md` cite neither. D-190
stays bold at §9.5 4560 only (R4).

## Inbound citations affected

- Spec 4764 (§9.7), "§7.1's buffer-unchanged-within-a-sweep rule": holds;
  A-040 states the rule in §7.1's words and keeps the phrase.
- Spec 4766 (§9.7), "per-call by topological necessity (§7.1)": §7.1 never
  said it, before or after. Track 2, as in survey part D.
- Glossary 12534 (*one home per datum*, §5.2 and §7.1): holds; A-044 keeps
  the state-cells clause. Glossary 12482 and 12587 (*buffer*, *view*): hold.
- Appendix C 12001 (`IllegalStateLeaf`, §7.1): now named in §7.1 (A-006).
- Appendix C 12067 (`IllegalPortType`, §7.1): still wrong; §4.3 547–549
  states it. Track 2.
- Spec 2599 and D-295 Position, "§7.1 admits no pinned state leaf": "of a
  common eltype `T`" kept word for word; D-295 not cited.
- Spec 3279 ("§7.1's explicit cast"), 2303, 2480, 3255 ("domain wrapper
  type"), 10184 ("never on state views"), `migration_outline.md` 25 and 109
  (`RQuat`, `Ranged`), D-072 and spec 4653, 11127 (the mapping layer): hold.

## Open questions

- F4, above: whether the orchestrator wants the enumeration kept in §7.1
  with F4's wording instead of the M2 pointer. The rewrite follows R6.
- A-021 drops the bold lead-in "What `Ẋ` is." and keeps its one-line framing
  as a plain topic sentence. A-024 unwinds "paying rent" to "This is what the
  closed vocabulary buys".
- A-050: "Invariant-carrying leaves are closed" now reads "excluded from the
  vocabulary", to separate it from the "closed vocabulary" sense.
