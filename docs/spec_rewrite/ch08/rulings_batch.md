# Chapter 8 rewrite: rulings batch — 2026-10-02

This batch gathers every open item of chapter 8's rewrite: the nine units'
`rulings.md`, the leftovers in their `verify.md` files and re-checks, the
partly applied items and track-2 notes of `chapter_fixes.md`, the 23
PREEXISTING rows of `inbound_check.tsv` with `inbound_check.md`'s notes, and
the survey's parts D and E. An item that several sources raise appears once
and names every source. Rulings already made are not reopened: R1 to R14
(`brief.md`), P43 to P48 (`chapter_rulings.md`), the coordinator's rulings
recorded in the units' files, and escalations E1 and E2 (`escalations.md`).
Items that a later fix resolved, or whose claim did not hold at its line, are
listed at the end under "Dropped".

Locations:

- `N` is a line of `chapter_new.md`. It matches the units' `new.md` files as
  they stand, with one blank line between units. A unit's own line is `N`
  minus its offset: A 0, B1 234, B2 374, B3 545, B4 717, D 905, E1 1101,
  E2 1267, F 1459.
- `spec` and `log` are `docs/design/spec.md` and `docs/design/decisions.md`
  at HEAD (`cf9c45c`). Neither file has changed since the base commit
  `084d6f0`, so spec lines equal the old lines the units cite.
- `old` is a line of `chapter_old.md`; old spec line = `old` + 1900.

Each item ends with a recommendation: **accept** (apply as proposed),
**leave** (no edit), or **discuss** (a choice the owner should make).

## Status: the orchestrator's rulings on the blocking items

- **K1, K9: accepted.** Landing edits, applied at step 7.
- **K2, K3, K5, K6: accepted as proposed.** Ruled edits before step 6b.
  K2 was checked against `src/diagnostics.jl`: each kind's docstring states
  the condition the proposed sentence carries.
- **K4: left as written, (a).** The sentence goes to the owner's list as an
  unsourced claim. In passing, `ContainerMixed`'s message in
  `src/diagnostics.jl` (around line 548) reads "a container holds components
  only addresses one component", a garbled clause; that is a loose code fix
  for the owner.
- **K7, K8: accepted, no edit.**
- **SERIOUS: none new.** The two sentences that rest on `Group`'s rate field
  (N1098–1099 and N1487–1488) join escalation E1's scope.
- **K10 to K30:** track 2 and outside items, ruled after landing (step 8).

## Summary

| group | items |
|---|---|
| 1. BLOCKING | 9 (K1–K9) |
| 2. TRACK 2 | 11 (K10–K20) |
| 3. OUTSIDE | 10 (K21–K30) |
| 4. SERIOUS | 0 beyond E1 and E2 |
| **total** | **30** |

The Contents block needs no change: every `##` and `###` title in
`chapter_new.md` is identical to the old one (checked against spec 39–47 and
1901–3390). No inbound row needs a retarget: the inbound check found 427 OK
rows and 23 PREEXISTING ones, all wrong before the rewrite (K19, K20,
K26–K28).

## 1. BLOCKING

### K1. Update the two Spec fields that M3 changed

- **Sources:** survey part D, "Log entries whose Spec field would change"
  (M3); survey part E, "Stale entry text and Spec fields" (D-085 lacks §8.5);
  unit F rulings, "Inbound citations affected"; unit E1 rulings, open
  question 2 (D-085 lacks §8.6).
- **Evidence:** M3 moved the rate-key sugar from §8.5 to §8.7 (old
  2769–2773 → N1484–1490). §8.7 now cites D-085 at N1486 ("`sample_times`
  needs no rule change for them ([D-085][d-085])"), and says "a
  name-transparent container keeps it unchanged" (N1487–1488), the
  container form D-211 rules. log 2482, D-085: "**Spec.** [§8.8][s8-8],
  [§14.9][s14-9]". §8.5 cites D-085 five times (N975, N979, N1015, N1018,
  N1022) and §8.6 once (N1119); both gaps predate the rewrite. log 7541,
  D-211: "**Spec.** [§6.1][s6-1], [§8.5][s8-5], [§8.6][s8-6]".
- **Proposal:**
  - log 2482 → "**Spec.** [§8.5][s8-5], [§8.6][s8-6], [§8.7][s8-7],
    [§8.8][s8-8], [§14.9][s14-9]"
  - log 7541 → "**Spec.** [§6.1][s6-1], [§8.5][s8-5], [§8.6][s8-6],
    [§8.7][s8-7]"
- **Recommendation:** accept, at landing (recipe step 7.3). The §8.5 and
  §8.6 additions to D-085 are track-2 repairs on the same line, so they ride
  along. §8.7 does not cite D-211; the field gains §8.7 because the moved
  sentence states D-211's name-transparent container. Other Spec fields wait
  for K20.

### K2. Name `ClassMixed`, `ContainerMixed` and `TransparentContainerUnknown` in §8.5

- **Sources:** unit D rulings, "Corrections proposed"; inbound_check.md,
  "Appendix C kinds" (the nineteen kinds unnamed in their cited section);
  chapter_rulings P46 (named the other two §8.5 kinds on the same terms).
- **Evidence:** Appendix C cites §8.5 alone for each: spec 11762
  (`ClassMixed`, "the `inner_connections` declaration and the offending
  leaf declarations"), 11764 (`ContainerMixed`, "offending element
  keys/indices, their types"), 11800 (`TransparentContainerUnknown`, "the
  field `transparent_container` names, the type's container fields").
  `src/diagnostics.jl` 532–551 and 755–768 define the three with docstrings
  citing §8.5. §8.5 states each condition exactly and names none:
  - N949–950: "`inner_connections` plus any leaf declaration on one type is
    a build error as well."
  - N1014–1015: "A container mixing component and non-component elements
    is a build error in this section's did-you-mean family ([D-085][d-085])."
  - N1041–1043: "`transparent_container` must name a container field of the
    type, and declaring two transparent containers on one type is a
    declaration error ([D-211][d-211], [D-215][d-215])." Only the first
    clause is the kind's condition (`src/diagnostics.jl` 755: "naming no
    container field of the type").
  After P46, §8.5 names `ClassUnreadable` (N945) and `ChildNameCollision`
  (N1029) but not these three, so a reader of Appendix C finds two of five
  §8.5 kinds by name.
- **Proposal:**
  - N950: "… is a build error as well, `ClassMixed`."
  - N1015: after the sentence, "The error is `ContainerMixed`."
  - N1041–1043: "`transparent_container` must name a container field of the
    type, and a name that matches none is `TransparentContainerUnknown`.
    Declaring two transparent containers on one type is a declaration error
    ([D-211][d-211], [D-215][d-215])." Both citations cover both sentences
    as before; if the split reads as narrowing them, cite the pair on each.
- **Recommendation:** accept. It adds names, not claims, and closes §8.5's
  kind set. The other fourteen unnamed kinds sit in other units' sections
  with no pointer sending a reader there; leave them.

### K3. Finish P5: link `executor` at its first use

- **Sources:** chapter_fixes "Partly applied", P5; chapter_pass P5.
- **Evidence:** N85: "The reason is how executor entries are typed
  ([§9.7][s9-7])." The link and gloss come two sentences later, N87–88: "An
  entry of the [executor](#g-executor), the compiled form of the stage
  execution order, carries …". The fixer skipped P5's primary text because
  its gloss ("one step of the stage execution order") describes an entry,
  which the glossary does not say. The first use is still unlinked.
- **Proposal:** N85 → "The reason is how entries of the
  [executor](#g-executor) (the compiled form of the stage execution order)
  are typed ([§9.7][s9-7])." N87–88 → "An executor entry carries what
  selects code in type parameters and what is plain data in fields." The
  gloss is the glossary's, moved; nothing else changes.
- **Recommendation:** accept.

### K4. "The didactic style says exactly that" has no source

- **Sources:** unit B4 rulings, open question 2; unit B4 verify, "Reader-cold
  names" ("the didactic style" unexplained); found again while checking
  `src/`.
- **Evidence:** N761–762: "An unupdated discrete store is a parameter in
  disguise, and parameters are plain struct fields. The didactic style says
  exactly that." Carried verbatim (old 653). `StoreWithoutUpdate`'s message,
  `src/diagnostics.jl` 481–483, says "declares `s_init` but defines neither
  `x_deriv` nor `s_update` — a store needs its update (§8.2)". It says
  nothing about parameters or struct fields. P32 now defines a didactic
  diagnostic at N678, so the term reads, but the claim is false of the
  message the code emits.
- **Proposal:** (a) leave the sentence and list it for the owner as an
  unsourced claim; (b) cut it, which needs a ruling, since the brief bars
  unruled cuts; (c) change the message in `src/` to say it.
- **Recommendation:** discuss; (a) if no one rules. (c) is a code change
  outside the rewrite.

### K5. Put the store's field-name reason beside the `NamedTuple` rule

- **Sources:** unit B1 rulings, open question 1.
- **Evidence:** N314–315 bolds "The value is a `NamedTuple`, one named field
  per leaf" (D-247). Its reason, "The store names each leaf because every
  service reaches a leaf by its field name …" (N342–346; D-247 Rationale log
  9175–9186), comes after the mandatory-store paragraphs (N320–341). The
  next paragraph, "Because the type is derived from the value …" (N348),
  goes back to the by-value rule of N312–313.
- **Proposal:** move N342–346 to follow N318 (after `StoreNotNamedTuple`),
  before "**Every leaf declares exactly one of `x_init` and `s_init`**". No
  words change.
- **Recommendation:** accept. Leaving it is harmless; the old text had the
  same order.

### K6. §8.6 says face cells are "evaluated at" the activation scalar

- **Sources:** inbound_check.md, side note on row 420; survey F29 (the same
  vocabulary in `extensions.md`, K28).
- **Evidence:** N1167–1169: "A face's [cells] … follow the producer's own
  declaration ([§8.2][s8-2]). They are evaluated at the [activation] scalar
  on the continuous tier and [pinned] on the discrete." "Evaluated at" is
  D-166's vocabulary; D-166's annotation (log 5790–5792) retires the
  two-argument form. §8.2 says the cell types are "that declaration retyped
  at the activation's `T` by the leaf walk" (N560–561; D-263). The old text
  had the same words (old 1054).
- **Proposal:** N1168 → "They are retyped at the [activation](#g-activation)
  scalar by the leaf walk on the continuous tier, and [pinned](#g-walked) on
  the discrete."
- **Recommendation:** accept. The sentence points to §8.2, and §8.2 states
  the retyping.

### K7. Confirm four no-edit decisions on bold

- **Sources:** unit A rulings, open question 1; unit B2 rulings, open
  question 2; unit B1 rulings, open question 2; unit B3 verify, "Bold"
  (borderline).
- **Evidence:**
  - N42–43: "Every inconsistency fails loudly, at build time where possible
    and at first execution otherwise" lost its old bold. It states the "+"
    clause of D-032's schema-authority ruling, bold at "Declarations
    *define* the model's structure" (§8.1). Unit A's verifier agreed.
  - N393–397: the table's old bold on "tolerant" and "demanding frozen"
    (old 350–351) is gone. Both were term bolds with no D-citation; the
    table is otherwise verbatim.
  - N331–332 and N799–802: `TierUnreadable` and `StatelessWithoutOutputs`
    (D-263 Position bullet 6) are plain, as in the old text (old 274,
    686–690). P44 cut Completeness's copy of `TierUnreadable`, so B1's
    suggestion to bold it in B4 has no site.
  - N673: "**The first bug lurks, but is never silent**" reads as a
    consequence; its ruling is D-286 bullet 2 and survey row 102 accepts
    it.
- **Proposal:** no text change.
- **Recommendation:** accept.

### K8. Confirm the glosses that rest on code or on a name alone

- **Sources:** unit B3 verify re-check (`GearContact`); unit E2 rulings,
  open question 1, and E2 verify (`Attitude.dt`, `RVec`, `IMUSample`);
  unit F verify re-check (`EAS_ref`).
- **Evidence:** N627–628 "Here `GearContact` is a landing-gear contact" (no
  source beyond the name; the coordinator directed it). N1341–1343
  "`Attitude.dt` gives the coning bullet's quaternion derivative, and `RVec`
  turns the interval rotation `Δq` into the vector the sample carries.
  `IMUSample` …" (glossed from the code block at N1366, N1382–1383).
  `EAS_ref` is "the equivalent-airspeed reference" (no doc spells EAS out).
  Each gloss claims nothing beyond what its code or name shows.
- **Proposal:** no text change. The alternative the E2 rewriter offered,
  naming the Flight.jl library these come from or moving them to a
  companion, is larger than the rewrite.
- **Recommendation:** accept.

### K9. Six link definitions arrive with `linkify.jl`

- **Sources:** unit E1 rulings, open question 1 (`d-085`, `d-129`); checked
  by script for every label the chapter uses.
- **Evidence:** `chapter_new.md` uses `[d-085]`, `[d-112]`, `[d-120]`,
  `[d-129]`, `[d-178]` and `[d-215]`, and `spec.md`'s definitions block has
  none of them. `linkify.jl` regenerates each file's block from the labels
  it uses (header, step 2).
- **Proposal:** no edit. After recipe step 7.6, check that the six
  definitions exist and that `linkify.jl`'s second run is a no-op.
- **Recommendation:** accept.

## 2. TRACK 2

These items wait until the chapter has landed (recipe step 8). K10 to K15
group what the chapter cites from a Rationale, a Rejected list, an
annotation or a superseded entry into new entries that state it in a
Position. The ids D-295 onward assume nothing else claims them first (the
log ends at D-294). Each draft takes the log's usual fields, and its
Rationale says where each clause was recorded before, in the "(as recorded
in D-nnn)" form of D-290 to D-294. A new entry restates only what an
existing entry records; K16 lists what no entry records. Once an entry is
ratified, the chapter's citations listed with it gain it beside the old
entry.

### K10. New entry for the rulings whose only home is superseded D-166 or D-167

- **Sources:** unit B2 rulings, "Rulings no live entry states (R9)"; unit B2
  verify (R9 and re-check); unit B3 rulings, open questions 4 and 5, and B3
  verify (B3-068); survey part E, "Rulings that need an entry stating them
  in a Position" 5 (the first track-2 item); brief R9.
- **Evidence:** four §8.2 rulings cite D-263, which states none of them in
  any field (B2 verify, R9). Their record:
  - N450 "**Discrete consumers take the bound check only**" (bold): D-167
    Rationale, log 5848–5853.
  - N455–456 "The unscoped variant is rejected." (uncited): D-167 Rejected,
    log 5890–5892.
  - N465–466 "**The obligation is scoped to the unpinned entries**" (bold):
    D-167 Rationale, log 5865–5868.
  - N503–504 "**That retyping makes seedability schema-visible**" (bold):
    D-167 Rationale, log 5860–5863.
  - D-167's annotation (log 5874–5877) says "the permissive reading, the
    walk-compatibility clause, its tier scope and the root-slot rules all
    stand".
  - N691 "The stores are walked by the same rule, with no marker" (cites
    D-263, whose bullet 1 carries only the `x_init` walk) and N694–695
    "`Pinned` has no place in a store, because [§7.1][s7-1] admits no pinned
    state leaf": D-166 Rejected, log 5807–5808 ("[§7.1] admits no pinned
    state leaf").
- **Proposal:** D-295, "The walk clause's tier scope, the obligation's
  scope, seedability and the unmarked stores". Position bullets, one per
  ruling above: the walk-compatibility clause binds continuous consumers
  only, and the unscoped clause is rejected; the genericity obligation binds
  unpinned input entries only; a root input's cells follow its entry
  retyped at `T`, so a `Pinned` entry is declaredly unseedable; stores are
  walked with no marker, and `Pinned` has no place in a store. Rationale:
  "(as recorded in D-167's Rationale, Rejected list and annotation, and
  D-166's Rejected list)". Spec: §6.1, §8.2, §14.10.
- **Recommendation:** accept. These are live rulings stated twice in the
  spec (§8.2, §6.1 1284) whose only home is a superseded entry. Then
  N450, N456, N466, N503 and N691 cite D-295 beside D-263; N694 gains
  D-295.

### K11. New entry for §8.2's input-contract rulings stated in D-078 and D-168

- **Sources:** unit B2 rulings, "Rulings stated only in a Rationale or a
  Rejected list" and open question 1; survey part E, items 4 and 12.
- **Evidence:**
  - N420–421 "**Abstract entries state structural substitutability**"
    (bold, D-078) and N467–468 "**Declarations record choices, and
    obligations are checked**" (bold, D-078): D-078 Rationale, log
    2273–2279 ("Abstract entries = structural substitutability"; "doctrine:
    declarations record choices, obligations are checked").
  - N482–483, only a *tight* bound determines a root input's type (plain,
    D-078): the same Rationale, log 2275–2277.
  - N530–532, a tap on an unseedable root input "is rejected naming the
    *pinning consumer*" (plain, D-168): D-168 Rationale, log 5916–5920.
    §14.10 states it too (spec 10906–10908).
- **Proposal:** D-296, "Abstract entries, the record-and-check doctrine, the
  tight root bound and the tap's pinning consumer", one Position bullet per
  ruling. Spec: §8.2, §14.10.
- **Recommendation:** accept. Two of the four are bold today on a Rationale.

### K12. New entry for the store, walk and contract-shape rulings of §8.1 and §8.2

- **Sources:** unit A rulings, "Rationale-only rulings"; unit B1 rulings,
  same; unit B3 rulings, same; unit B4 rulings, same (the bundle letter);
  survey part E, items 1, 3, 6, 7, 8 and 13.
- **Evidence:**
  - N73–76 "**A leaf's contract declarations must be determined by the
    component's type** … never by its field *values*" (bold, D-033): D-033
    Rationale, log 1023–1028 ("a rule authors keep, not a check the build
    can run"; `workspace` exempt).
  - N293 "Partials enter through per-invocation seeding, never through
    initialization" and N663–664 "chosen by seeding …, never by typing"
    (D-079): D-079 Rationale, log 2316. N645–647 "That is semantically
    exact" (frozen discrete outputs) and N695–697 (declared `Float64`
    initial values embed as zero-partial constants): log 2307–2316.
  - N307–308 "The criterion, not uniformity, is the rule": D-263 Rationale,
    log 10207–10212. N666–668 (a participating leaf cannot be pinned by
    habit) and N687–689 ("one convention"): D-263 Rationale, log
    10219–10231. N332–333 and N802–803 (an empty store puts no letter in
    the bundle): D-263 Rationale, log 10242–10244.
  - N620–621 "every `Float64` position follows the scalar" reads the
    declaration as written (D-265): D-265 Rationale, log 10425–10428.
- **Proposal:** D-297, "Contracts by type, seeding not typing, frozen-exact
  discrete outputs and one walk convention", one Position bullet per ruling.
  Spec: §8.1, §8.2.
- **Recommendation:** accept. D-178's residual at N199–200 (an optional
  declaration shadowed in a local scope drops its feature) stays cited to
  D-178's Rationale: it records a limitation, not a ruling (unit A rulings).

### K13. "Publicity is never implicit" has no Position

- **Sources:** unit B4 rulings, "Rationale-only rulings"; survey part E,
  item 14.
- **Evidence:** the chapter says it twice, uncited at N835 ("Publicity is
  never implicit. Even the minimal component writes …") and pointing to §8.3
  at N1170. Only D-034 Rejected (log 1070, "implicit publicity") and D-041
  Rejected (log 1240, "publicity never implicit") state it. N867–868,
  "Probe-observed expected types remain rejected ([D-034], [D-194])", is a
  rejection the cited Rejected lists already carry.
- **Proposal:** D-298 states "publicity is never implicit: a port is public
  only by declaration" in a Position, as recorded in D-034's and D-041's
  Rejected lists. Spec: §8.3, §8.6. N835 and N1170 cite it. No entry for the
  probe-observed rejection.
- **Recommendation:** accept. It may also fold into K12's entry as one more
  bullet.

### K14. New entry for §8.5 and §8.6 rulings stated in Rationales and Rejected lists

- **Sources:** unit D rulings, "Rationale-only rulings"; unit E1 rulings,
  same; survey part E, items 9, 10, 11 and 19.
- **Evidence:**
  - N1013–1022, the container edges (mixing is an error, no nesting in the
    first cut, empty containers legal), cited to D-085: D-085 Rationale,
    log 2484–2491.
  - N1087 "**The builder (`Assembly()` plus `add!`/`connect!`) is
    rejected**" (bold, D-039): D-039 Rejected, log 1197–1199.
  - N1082–1085, what `Group` gives up relative to a named type (uncited;
    no unit listed it): D-184 Rationale, log 6521–6522 ("gives up
    dispatchable identity, which exploratory/programmatic composition does
    not want").
  - N1131–1132, symmetric siblings are `===`-identical: D-040 Rejected,
    log 1216–1217.
  - N1181–1182 "**It separates structure from derived contract, not read
    from write**" (bold, D-129): the Position states the directional rule;
    "never read vs. write" is D-129 Rejected, log 3874–3875.
  - N1212–1213, below the root a primitive's input faces alias their
    producers' cells, so nothing collides: D-210 Rejected, log 7515–7516.
- **Proposal:** D-299, "Container edges, the builder rejection, `Group`'s
  trade, the `===` fact, and root-only face uniqueness", one Position bullet
  per ruling. N1082–1085 gains a citation of it. Spec: §8.5, §8.6.
- **Recommendation:** accept, restricted to the constructive rulings and
  the two bolds (builder, not read from write). The `===` fact and the
  below-root aliasing are facts behind rejections; they may stay cited to
  the Rejected lists.

### K15. New entry for §8.7 and §8.8 rulings stated in Rationales and Rejected lists

- **Sources:** unit F rulings, "Rationale-only rulings" (ten items) and F
  verify (D-039); survey part E, items 15–18.
- **Evidence:**
  - N1501–1505, the declaration belongs to the type, not the instance:
    D-042 Rejected, log 1255–1256.
  - N1484–1488, element names as rate keys and the field-name sugar: D-085
    Rationale, log 2490–2491.
  - N1656–1657 "structure kept in two artifacts ([D-039])": D-039
    Rejected, log 1197–1198.
  - N1610 "What computation does *not* do is auto-bubble" (D-043): D-043
    Rejected, log 1272–1273.
  - N1571–1572 "There is no `rename` hook" (D-046): D-046 Rejected, log
    1377.
  - N1693 "Adding an actuator channel is then one edit" (D-145) and the
    feed-list doctrine: D-145 Rationale, log 4879–4890. N1714–1715
    "**… authored data, never inferred structure**" (bold): D-145 Rejected,
    log 4896–4904.
  - N1615 and N1643, the helpers come in pairs because the name carries the
    direction, two helpers rather than one keyword (D-171): D-171
    Rationale, log 6024–6030.
  - N1632–1634, one-level routing as `output_passthrough`'s consumer
    (D-209): D-209 Rationale, log 7475–7478.
  - N1726, scalar faces make partial scripting compose (D-207): D-207
    Rejected, log 7430–7432.
- **Proposal:** D-300, "Rate scopes by type, the feed-list doctrine and the
  helper pair", stating the constructive rulings: type not instance; one
  edit per channel and authored data, never inferred structure; the helpers
  paired by direction; one-level routing as the output helper's consumer;
  scalar faces at a root input. Spec: §8.7, §8.8.
- **Recommendation:** accept, restricted as in K14: the bare rejections
  (auto-bubbling, `rename` hooks, two artifacts) stay cited to their
  Rejected lists, which carry them.

### K16. Rulings no entry records: the owner's list

- **Sources:** survey part E, "Rulings with no entry at all"; unit D
  rulings, open question 3; unit F rulings, "Corrections proposed" and open
  question 1; unit B3 rulings, open question 4; chapter_rulings P47; K4.
- **Evidence:** each sentence below is stated in the chapter, and no entry
  records it in any field:
  - N755–757, a non-empty store without its update law is
    `StoreWithoutUpdate` (D-263 rules only the empty-store scope).
  - N764, `m_init` owes no update.
  - N768–770, an event needs both halves (D-215 names only the kind).
  - N1023–1025, element types follow "the same concreteness discipline as
    plain fields".
  - N964–966, every assembly declaration takes the component alone.
  - N1487–1488, the field-name sugar survives a name-transparent container
    (D-211's Position spells a `Group` entry by bare key, `(ctl =
    Relative(2),)`, log 7535; it does not state the sugar).
  - N1509–1510, `u_connections` and `y_connections` are ordinary functions
    evaluated at build; N1568, computed entries mix freely with
    hand-written ones (D-043's Rationale is "Recorded only through the
    rejections below").
  - N1596–1597, `EmptyFaceSelection`'s payload; N1637–1640, the default
    `prefix` folds the slash into `sep`, and an explicit `prefix` is used
    verbatim.
  - N762, "The didactic style says exactly that" (K4); N872, "its
    satellite-function representation" (P47).
  - Descriptions of a status quo: N918 `Cessna172X{K, A}`; N1202–1203 "An
    assembly never declares its external connections"; N1332 the precision
    figure; the §7.2 scoping restated at N626–631.
  - `Group`'s rate declaration (E1).
- **Proposal:** none. Each stays in the spec as written, uncited.
- **Recommendation:** leave, and list them in the chapter's closing report
  for the owner. Ratifying any of them would be a design decision.

### K17. §8.2 does not state `EventHalfMissing`'s third arm

- **Sources:** chapter_fixes P48; chapter_rulings P48.
- **Evidence:** `src/diagnostics.jl` 485–497: `EventHalfMissing` has reasons
  `:guard`, `:handler` and `:not_an_event`, the last for "a `state_events`
  entry that is not a `StateEvent`". Appendix C (spec 11751–11754) lists
  the same three. D-215's Position bullet (log 7722–7723) says
  "`EventHalfMissing`'s reason admits an entry that is not an `Event`".
  §8.2 says entries are "`StateEvent(guard, handler)`, with no detection
  keyword" (N721–722) and states only the two missing halves as the error
  (N768–769).
- **Proposal:** after N769's sentence, "An entry that is not a
  `StateEvent` is `EventHalfMissing` too ([D-215][d-215])."
- **Recommendation:** accept. D-215 records the arm, so the sentence states
  nothing new.

### K18. Annotate stale Positions

- **Sources:** survey part E, "Superseded and half-superseded citations" and
  "Stale entry text and Spec fields"; survey F19; unit B3 rulings,
  "Corrections proposed" (F19).
- **Evidence:** each Position below carries text a later entry retired, and
  none has an annotation saying so:
  - D-033, log 1016–1017: `events(::C)` "per-event `localize` flag"
    (removed by D-179) and `local_types` (deleted by D-165).
  - D-034, log 1054–1055: intermediates "declared via strict `local_types`
    … presentation-filtered" (retired by D-194).
  - D-055, log 1568–1572: the whole Position is the `local_types`
    mechanism (D-165, log 5672). Status "ratified". The chapter still cites
    its Rejected list (N871).
  - D-041, log 1226–1228: the single `exports(::A)` (D-170 Rationale, log
    5999, "Supersedes D-041's single-method shape").
  - D-042, log 1247–1248: "`Δt_base`/`h` fixed only at `Simulation`
    construction" (moved to the `Deployment` by D-254 and D-256; the
    chapter says "deployment", N1497–1498).
  - D-164, log 5591–5593: the declares-nothing build error, which `src/`
    raises as `ClassUnreadable` (N188).
  - D-171 Rejected, log 6037–6038: `output_passthrough` "stays guarded";
    D-209's Position (log 7468–7469) says it annotates D-171.
  - D-184, log 6510–6525: "zero new declaration rules" and
    `child_connections`/`input_connections`/`output_connections`, which
    D-211 (log 7537–7538) and D-170/D-279 amended.
  - D-166 Rationale "Semantics are **literal**" against the spec's new
    sense of "literal" (N567; F19). D-166 is superseded, and its annotation
    already retires the literal semantics (log 5790–5792).
- **Proposal:** one annotation per entry naming the amending entry and what
  stands, in the form of chapter 10's K18: D-033, D-034, D-055 ("amended
  by D-165 and D-194; the Rejected list stands"), D-041, D-042, D-164,
  D-171 and D-184. No annotation on D-166.
- **Recommendation:** accept for the eight; leave D-166, whose annotation
  already says the old sense went.

### K19. Log text that points at chapter-8 content it does not hold

- **Sources:** inbound_check PREEXISTING rows 206, 207, 274, 311, 315, 323,
  325, 319, 374, 377; survey part D, "Citations that already rely on content
  chapter 8 does not hold"; survey F25, F26; unit B1 rulings, "Inbound
  citations affected" (log 2252); unit F rulings (log 4877).
- **Evidence:**
  - log 1201, D-039 Rejected: "kind is an implementation detail per
    [§8.3]". §8.5 says it (N933–935, citing §8.3); §8.3 does not.
  - log 6257, D-177 Position: "the [§8.3]-hidden implementation class".
    Same.
  - log 6273, D-177 Rationale: "[§8.1]'s reflection class". §8.1 holds the
    `isdefined`/`!==` test (N154) and names no reflection class.
  - log 4877, D-145 Rationale: "[§8.1]'s and [D-039]'s 'structure kept in
    two artifacts'". §8.1 has no such phrase; §8.8 says it citing D-039
    alone (N1656–1657, R7 F7).
  - log 1198, D-039 Rejected: "[§8.1]'s disease at assembly scale". §8.1
    accepts redundancy under fail-loud (N41–43).
  - log 6378, D-179 Rejected, and log 6469, D-182 Rejected: "no-introspection"
    and "the introspection [§8.1] forbids". §8.1 forbids macros (N36–55) and
    inference-by-evaluation (N877, N959); "introspection" appears nowhere.
  - log 2252, D-077 Rejected: "no [§8.2] by-value argument (condition
    overlay base, probe-value barrier)". §8.2 holds the overlay base
    (N362–365), never the probe-value barrier, which is D-073's.
- **Proposal:** annotations on D-039 and D-177 retargeting the §8.3
  pointers to §8.5, on D-177 reading "§8.1's shadowing check" for "the
  reflection class", and on D-145 dropping "§8.1's".
- **Recommendation:** accept those four; leave the rest. "Disease" and
  "introspection" are a Rejected list's judgments about §8.1's stance, not
  pointers to a sentence, and log 2252 names a pair of arguments that
  existed when it was written. Rows 319 (log 6323), 374 (log 9273) and 377
  (log 9290) are history that D-249's annotation (log 9312–9314) already
  covers; see "Dropped".

### K20. Spec fields stale before the rewrite or missing a newly cited section

- **Sources:** survey part E, "Stale entry text and Spec fields"; inbound
  check PREEXISTING rows 202, 203, 270, 322, 324 and 375; unit E1 rulings;
  checked by script for every entry `chapter_new.md` cites.
- **Evidence:** the chapter cites each entry below in a section its field
  lacks. Newly cited by the rewrite: D-032 §8.3 (field log 984), D-046 §8.8
  (1367), D-078 §8.2 (2271), D-094 §8.2 (2732), D-179 §8.2 (6359), D-194
  §8.2 (6886), D-215 §8.5 (7727), D-238 §8.2 (8793), D-239 §8.3 (8833),
  D-249 §8.2 (9286), D-254 §8.7 (9581). Cited before the rewrite too: D-079
  §8.2 (2305), D-146 §8.1 (4938), D-170 §8.1 (5996), D-171 §8.1 (6022),
  D-226 §8.1 (8275), D-237 §8.2 (8738). Fields naming a chapter-8 section
  that holds nothing of the entry, old and new: D-039 §8.1 and §8.3 (1192),
  D-145 §8.1 (4873), D-179 §8.1 (6359), D-182 §8.1 (6455). D-085 and D-211
  are in K1.
- **Proposal:** add each missing section in its field's numeric place,
  following the field's own order. Remove nothing; the four stale §8.1 and
  §8.3 entries go to the owner with K19.
- **Recommendation:** accept the additions. D-146's addition waits on E2,
  since §8.1's semantic-axis paragraph may change.

## 3. OUTSIDE

Problems in other chapters, the glossary, Appendix C, companions and `src/`,
met while checking chapter 8. None blocks landing. Chapters 3, 5, 6, 13 and
14 are not yet rewritten (`check_bold.jl`'s `REWRITTEN` is `[9, 10]`), so
`check_bold.jl` does not flag the doubles in K21 to K25.

### K21. §6.1 bolds the walk clause's tier scope that §8.2 bolds

- **Sources:** unit B2 rulings, "Bold on the same entry elsewhere"; unit B2
  verify, "Bold".
- **Evidence:** spec 1284: "Beside it, and **for a continuous consumer
  only**, stands the **walk-compatibility clause**." N450: "**Discrete
  consumers take the bound check only** ([D-263][d-263])." One ruling, two
  bolds; old 2293 bolded it too.
- **Proposal:** chapter 6's rewrite unbolds "for a continuous consumer only".
  Survey q2 left the clauses' home to that rewrite; if it makes §6.1 the
  home, §8.2's bold moves there instead.
- **Recommendation:** leave until chapter 6's rewrite, and put it in that
  chapter's survey.

### K22. §14.10 bolds seedability and states the tap rejection that §8.2 states

- **Sources:** unit B2 rulings, "Bold on the same entry elsewhere" and open
  question 1.
- **Evidence:** spec 10905: "A root input whose entry is declared `Pinned`
  is **declaredly unseedable**", then the tap rejection (10906–10908). N503:
  "**That retyping makes seedability schema-visible**"; N530–532 the tap
  rejection naming the pinning consumer, plain.
- **Proposal:** chapter 14's rewrite unbolds "declaredly unseedable" and
  points to §8.2; §8.2's tap sentence stays plain.
- **Recommendation:** leave until chapter 14's rewrite.

### K23. §3.4's lead-in bolds D-056's first bullet

- **Sources:** unit E2 rulings, "Bold on the same entry elsewhere"
  (coordinator ruling); unit E2 verify, "Bold".
- **Evidence:** spec 414: "**Algebra removes the reset.** Every
  interval-relative integral becomes a cumulative one …", with no citation.
  N1273–1274 bolds "Every interval-relative integral becomes a *cumulative*
  one" with D-056. §3.4 points to §8.6 for the idiom.
- **Proposal:** chapter 3's rewrite drops the lead-in bold.
- **Recommendation:** leave until chapter 3's rewrite.

### K24. §13.7 bolds D-251's selector ruling that §8.8 bolds

- **Sources:** unit F rulings, "Bold on the same entry elsewhere"; unit F
  verify, "Bold".
- **Evidence:** spec 9469: "**The passthrough helpers take a predicate.**
  `select` is the third selector … ([§8.8][s8-8], [D-251][d-251])". N1585:
  "**The selectors are exclusive** ([D-251][d-251])". Both rest on D-251's
  first Position sentence, and D-251's Spec field names §8.8, not §13.7.
- **Proposal:** spec 9469, unbold the lead-in and keep its §8.8 pointer.
- **Recommendation:** accept, at chapter 13's rewrite or now; the edit is
  two asterisk pairs.

### K25. §5.3 states D-252 under a **Rule.** label that §8.3 bolds

- **Sources:** unit B4 rulings, "Bold on the same entry elsewhere"; unit B4
  verify.
- **Evidence:** spec 879: "**Rule.** A declared output is produced by stage
  1 or by stage 2, and by nothing else ([D-252][d-252])." N839: "**A
  declared port must be produced by exactly one stage**".
- **Proposal:** chapter 5's rewrite folds the label and leaves its sentence
  plain.
- **Recommendation:** leave until chapter 5's rewrite.

### K26. Appendix C cites a chapter-8 section that holds neither the kind nor the rule

- **Sources:** inbound_check PREEXISTING rows 153, 155, 162; survey F27;
  chapter_rulings P46 (`TierUnreadable`); unit B4 rulings (spec 11807).
- **Evidence:**
  - spec 11803, `TierUnreadable` ([§8.2], [§8.5]): §8.5 never held it; §8.2
    names it at N332.
  - spec 11807, `StatelessWithoutOutputs` ([§8.2], [§8.5]): §8.5 never held
    it; §8.2 names it at N801, and §8.3 now does too (R7 F23).
  - spec 11993, `ArgumentInvalid` ([§8.7], …): §8.7 holds no argument
    check. The float-argument error is §10.5 (spec 5349–5352); §8.7 now
    points there (N1476).
  - `src/diagnostics.jl` 769 and 781 carry the same "§8.2, §8.5" in their
    docstrings, and 1950 "§8.7".
- **Proposal:** spec 11803 → "([§8.2][s8-2])"; 11807 → "([§8.2][s8-2],
  [§8.3][s8-3])"; 11993, replace "[§8.7][s8-7]" with "[§10.5][s10-5]" in
  the field's numeric place. The three docstrings follow.
- **Recommendation:** accept for the spec; the docstrings are code, for the
  owner.

### K27. Two §11.6 pointers and the glossary's *nominal* point at the wrong chapter-8 section

- **Sources:** inbound_check PREEXISTING rows 75, 78, 186; survey part D;
  survey F25, F28.
- **Evidence:**
  - spec 7134: "That is the reflection class ([§8.1][s8-1]), where the
    shadowing check is an `isdefined`/`!==` pair." §8.1 has the test (N154)
    and names no reflection class.
  - spec 7163: "a component's class is implementation detail behind its
    contract ([§8.3][s8-3])". §8.5 says it (N933–935); §8.3 does not.
  - spec 12613–12615, glossary *nominal*: "the one where the conformance
    check demands exact type match ([§8.2][s8-2], [§9.4][s9-4],
    [§9.5][s9-5])". §8.2 never states it; §9.5 holds the exact check (D-286
    gives it to pinned leaves). The entry's "its evaluation at `Float64`"
    (12612) is D-166's vocabulary.
- **Proposal:** 7134 → "That is the reflection technique of §8.1's
  shadowing check, an `isdefined`/`!==` pair ([§8.1][s8-1])." 7163,
  "([§8.3][s8-3])" → "([§8.5][s8-5])". 12614, drop "[§8.2][s8-2], ".
- **Recommendation:** accept 7163 and 12614. Discuss 7134's wording, which
  belongs to chapter 11's rewrite; leave the glossary's "evaluation" phrase
  with K28.

### K28. `extensions.md` says cell types are "evaluated at" the activation scalar

- **Sources:** inbound_check PREEXISTING row 420; survey F29.
- **Evidence:** `extensions.md` 286: "Cell types and the `x`-buffer eltype
  are declarations *evaluated at the activation scalar* ([§7.2][s7-2],
  [§8.2][s8-2])". §8.2 retypes plain declarations by the leaf walk
  (N560–561; D-263); "evaluated at" is D-166's vocabulary. K6 is the same
  fix inside the chapter.
- **Proposal:** "are declarations *retyped at the activation scalar by the
  leaf walk*".
- **Recommendation:** accept, with K6.

### K29. The glossary's *store* covers `m` and a discrete `s`, not `x`

- **Sources:** unit B1 verify, "Hazard checks" (store gloss).
- **Evidence:** spec 12295: "**store** — the typed home of `m` and of a
  discrete leaf's `s`, isbits or `Symbol` field by field." Chapter 8 calls
  `x_init` a store throughout: N312–313 ("`x_init` on the continuous tier,
  `s_init` on the discrete, and `m_init` declare by initial value"),
  N320–321, N328 ("The [store](#g-store) … is the tier marker"), and
  `TierUnreadable` (`src/diagnostics.jl` 769, "the store every leaf
  declares its tier by"). The link at N328 sends a reader to a definition
  that excludes `x`. The old text had the same mismatch.
- **Proposal:** (a) widen the glossary entry to "the declared home of a
  leaf's `x`, `s` or `m`", keeping the isbits sentence for `s` and `m`
  (D-231); (b) keep the entry and say in §8.2 that `x_init`'s value is a
  store only in the declaration sense.
- **Recommendation:** discuss. (a) matches how chapter 8 and D-263 use the
  word, but the entry's other sentences (overwritten by a handler, never
  arithmetic-touched) describe `s` and `m` only.

### K30. The glossary's *seam* lists no generic seam

- **Sources:** unit F rulings, open question 2.
- **Evidence:** N1651 links "generic [seam](#g-seam)" with the glossary's
  gloss. Spec 13129–13132 lists the stepper, backend, measurement and
  phase-body seams. spec 1265 and D-207 Rationale (log 7414) also say
  "generic seam".
- **Proposal:** append "the generic seams of an assembly tree
  ([§8.8][s8-8])" to the entry's list.
- **Recommendation:** accept. It adds an instance §8.8 already states.

## 4. SERIOUS

No new item qualifies. E1 (`Group`'s rate field) and E2 (the semantic axis)
stay with the owner, unruled. The candidates examined:

- The completeness rules and the other no-entry sentences (K16): the prototype
  built them and the spec states them, and nothing contradicts them. They
  are a gap in the log, not a defect in the design.
- "The didactic style says exactly that" against `StoreWithoutUpdate`'s
  message (K4): a prose claim about a message, fixable in either.
- The glossary's *store* against chapter 8's use (K29): a terminology
  mismatch with no rule at stake.
- D-055's ratified Position for a deleted mechanism and the other stale
  Positions (K18): later entries settle each, and the spec and `src/`
  follow them.

Two sentences rest on E1's rate field and should join its scope:
N1098–1099, "a `Group`'s wiring and rate declarations read exactly like a
named assembly's" (unit D rulings, open question 2), and N1487–1488, the
field-name sugar surviving a name-transparent container, where D-211's
Position spells the `Group` entry by bare key (unit F rulings). Both are
carried as written under R1.

## Dropped

Items a source raised that no longer hold, were already settled, or need no
action.

- Line-length leftovers (unit A, B3, D, E1, E2 re-checks; chapter_pass P38,
  P39): no prose line of `chapter_new.md` exceeds 80 rendered columns
  (measured, links collapsed). N1289 and N1299 are display math, exempt.
  The short line at N626 (P39, "Partly applied") is layout only.
- Unit B3 re-check, the broken antecedent after the `RQuat` gloss: P35 moved
  the gloss below the table (N399) and to the end of the bullet (N575–576);
  "they never take it" (N574) follows "Value parameters" again.
- Unit F re-check, F-062's antecedent ("Its consumer is one-level
  routing"): N1632 reads "`output_passthrough`'s consumer is one-level
  routing".
- Unit E2 re-check, "It is there for exactly this kind": the sentence no
  longer reads that way; the R12 fix stands with its antecedent.
- Unit E2 rulings, `#g-boundary` in the assembly sense: the link sits at
  N1400 on "the initialization boundary", the time sense the glossary
  defines.
- Unit E2 and E1 rulings, `port` and `component` unlinked in §8.6, and unit
  B2's `component` unlinked in §8.2: P8, P9 and P14 linked them.
- Unit B1 rulings, `init_*` at the asymmetry paragraph: P1 replaced it.
- Unit B4 rulings, "decoder" unglossed and FlightCore named twice: P31 and
  P40.
- Unit B4 re-check, R13's residual in Completeness: P43 cut the sentence to
  "No arity carries a tier (above)" (N783–784).
- Unit B4 rulings, naming `StoreWithoutUpdate` and `EventHalfMissing` in
  §8.2: P48 named both (N758, N769). The third arm is K17.
- Unit D rulings and chapter_pass P46, `ClassUnreadable` and
  `ChildNameCollision` in §8.5: P46 (N945, N1029). The other three are K2.
- Unit A verify, R8's consequence-axis wording and the E2 tension: R8 was
  withdrawn, and `escalations.md` E2 names D-267.
- Unit A rulings, open question 2 (the roadmap), and unit E1's roadmap and
  latch-back pointer: fixed in the re-checks and P26.
- Unit A verify, `Engine` before §8.2 and `pending.md` named without an
  introduction: the `Engine` pointer is at N79; "the exported-name audit in
  `pending.md`" (N115, N233) says what the file holds.
- Unit B2 open question and verify, two bolds on D-263 bullet 2: P45 ruled
  both stay.
- Unit B4 rulings, D-032's schema-authority bold at N861 and the inspection
  path at N831: the coordinator ruled both plain, and the re-check agreed.
- Unit E2 verify, "the equivalence survives discretization" bold: the
  coordinator kept all six D-056 bolds (chapter_pass header).
- Unit E1 open questions, HDF5 and `q_eb` and the other kinematic-truth
  names: accepted as written by the coordinator.
- Unit D verify, "fly-by-wire" for `Cessna172X`: optional; the gloss is
  accurate without it.
- Unit B3 open question 1, a label "The stores' walk": R6 fixed the labels
  from survey part C, which lists none.
- Unit B4 rulings and chapter_pass P47, "its satellite-function
  representation": P47 left it and sent it to the owner (listed in K16).
- Unit F rulings, spec 11993 (`ArgumentInvalid`, §8.7) as an inbound effect
  of the rewrite: it was already unsupported before (K26).
- Unit F rulings, log 4877's "§8.1's": K19.
- Survey part E, D-178's Rationale against old 2027 (F24): R7 scoped the
  spec sentence to a shadowed stage (N195–200), so the residual D-178 records
  now matches the spec.
- Survey part E, D-266's Spec field listing §8.2, which held none of it:
  F20 added D-266's sentences to §8.2 (R7).
- Inbound rows 319 (log 6323, D-178 Rationale), 374 (log 9273, D-249
  Position) and 377 (log 9290, D-249 Rationale): history of what §8.5 said
  before D-263. D-249's annotation (log 9312–9314) records the retirement.
  Row 375 (D-249's Spec field) is in K20.
- Inbound rows 202, 203, 270, 322 and 324 (Spec fields naming a section
  that holds nothing of the entry): K20.
- Survey F14 to F16, F18 and F19: the brief ruled them for the rewrite
  (introducing clauses; F18's messages illustrative; F19's "literal" kept).
  F19's log side is in K18 (left).
