# Chapter 8: whole-chapter pass

Read: `chapter_new.md` whole (1,770 lines), against `chapter_old.md`, the
brief's R1 to R14, each unit's `rulings.md` and `verify.md`, and
`spec_style.md`. Line numbers are `chapter_new.md` lines. R1 (`Group`'s rate
declaration), R8 (the semantic axis) and the coordinator's D-056 ruling (all
six bolds stay) are not reopened.

Mechanical results:

- Glossary links: one duplicate within a section (P7). No other section
  links a term twice.
- Bold: 67 spans. Every multi-bold entry was checked against its Position:
  D-032, D-039, D-085, D-164, D-170, D-210, D-211, D-212, D-246, D-251 and
  D-145 each bold distinct rulings. One open double remains (P45), and one bold
  states a consequence (P24).
- Long lines: 12 prose lines over 80 rendered columns (P38), plus two display
  math lines carried verbatim (1318, 1328), which are exempt.

## EDIT items

### Names

**P1.** Line 371, unit B1. EDIT.
`init_*` is the log's retired spelling. The chapter's names are `x_init`,
`s_init` and `m_init` everywhere else. The same sentence also glosses "store"
a second time in §8.2 ("the model's memory"; first at 328).
Fix: "`x_init`, `s_init` and `m_init` describe stores, which must have
contents before the first sweep can run."

**P2.** Line 1337, unit E2. EDIT.
§8.6 links the flow function as "[RHS](#g-flow)" and then calls it "the flow"
at 1477. §8.2 calls it "flow" (765). The glossary bolds both names. The
chapter should still use one.
Fix: "Every evaluation of the [flow](#g-flow) (`x_deriv`, the continuous
derivative function) applies …".

**P3.** Line 916, unit B4. EDIT.
"is the completeness pass's error" names an error by a pass that does not
hold it. §8.2's "Completeness" block lists three other rules. The error is
`DeclaredNotProduced`, which §8.3 (859) names.
Fix: "… on a component whose returns are all declared, is
`DeclaredNotProduced`, with the stage-product and state-field lists in hand
([§8.3][s8-3])."

**P4.** Line 1101, unit D. EDIT.
"the two-producer check". Lines 1185, 1284 and 1614 call it "the
two-producers error".
Fix: "… did-you-mean errors and the two-producers error all run at build …".

**P5.** Lines 84–88, unit A. EDIT. Made worse.
"The entry typing decides it ([§9.7][s9-7])" was the body of an old
**Why.** label. Without the label, "it" has no antecedent, and the paragraph
opens on a riddle rather than a findable claim. "Entry" is also used here
for an executor entry before the text says so. §8.2 uses "entry" for a
contract entry 300 lines later.
Fix: "The reason is how the [executor](#g-executor) types its entries
([§9.7][s9-7]). A component's [bundle](#g-bundle) is … An executor entry, the
compiled form of one step of the stage execution order, carries …". If the
gloss on executor should stay where it is, at least replace the first
sentence with "The reason is how executor entries are typed
([§9.7][s9-7])."

**P6.** Lines 147 and 154, unit A. EDIT.
"a binding of a family name (a name in the import list above)" and "the
family's names" use "family" for the import list. §8.5 (960, 966) and §8.2
(818) use "family" for the leaf and assembly declaration families. The
glossary's "function family" is a third sense. In the same paragraphs,
"binding" means a Julia binding (147, 155, 184), while 214 links
[binding](#g-binding) in the device sense.
Fix: 147 "looks for a binding of a declaration name (a name in the import
list above)"; 154 "test on those names. Those names are distinctive by
design". The device sense keeps its gloss at 214, which is enough.

### Glossary links

**P7.** Line 397, unit B2. EDIT.
Duplicate link: [activation](#g-activation) is linked at 292 (B1) and again
in the table at 397.
Fix: unlink at 397, "the activation scalar or a frozen `Float64`".

**P8.** Lines 369 and 391, units B1 and B2. EDIT.
"port" is first used in §8.2 at 369 ("one per output port"), unlinked. The
link and gloss sit at 391.
Fix: link at 369, "one per output [port](#g-port) (one declared input or
output)"; at 391 write the plain "port".

**P9.** Lines 285 and 305, unit B1. EDIT.
§8.2 never links [component](#g-component) (24 uses, first at 285, "takes the
component alone") or [bundle](#g-bundle) (four uses, first at 305, "the `ws`
bundle field").
Fix: 285 "takes the [component](#g-component) (the unit of modeling, leaf or
assembly) alone"; 305 "arriving as the `ws` [bundle](#g-bundle) field (the
`NamedTuple` of views a component function receives)".

**P10.** Lines 1547 and 1754, unit F. EDIT.
"generic holding" is first used in §8.8 at 1547, unlinked. The link sits at
1754, inside a bold, with no gloss.
Fix: 1547 "and [generic holding](#g-generic-holding) (a parent holding a child
through a non-concrete field type), in that order"; 1754 plain "**Generic
holding is an imposed derived contract**".

**P11.** Lines 67, 133, 135 and 208, unit A. EDIT.
§8.1 is the home of schema authority, but it never links it. The only link is
§8.3's (877). §8.1 also leaves [store](#g-store) (133), [class](#g-class)
(135) and [assembly](#g-assembly) (208) unlinked at their only uses.
Fix: 67 "Inference-by-evaluation as
[schema authority](#g-schema-authority) (the source that defines structure)
is rejected …". 133 and 135 sit inside parenthetical glosses, so link
without a second gloss: "a non-empty [store](#g-store) without its update
law" and "no declaration to read a [class](#g-class) from". 208 "An
[assembly](#g-assembly)'s boundary declarations".

**P12.** Lines 823 and 851, unit B4. EDIT.
"component" is first used in §8.3 at 823. The link sits at 851, with no
gloss.
Fix: link at 823, "which of a [component](#g-component)'s values are public";
plain at 851.

**P13.** Lines 926 and 945, unit D. EDIT.
"component" is first used in §8.5 at 926 ("assembles components"). The link
sits at 945.
Fix: link at 926; plain "a component's primitive-vs-assembly status" at 945.

**P14.** §8.6 and §8.8, units E1 and F. EDIT.
§8.6 never links [port](#g-port) (nine uses, first at 1128),
[component](#g-component) (first at 1126, inside the assembly gloss) or
[store](#g-store) (1304). §8.8 never links port (1554),
component (1554) or [condition](#g-condition) (1741).
Fix: link each at its first use. 1128 "the name a [port](#g-port) (one
declared input or output) wears"; 1304 "the only new [store](#g-store)";
1554 "the names [ports](#g-port) wear"; 1741 "for
[conditions](#g-condition) (the data that set a build's state) to cover".

**P15.** Links with no gloss, several units. EDIT.
These first links in their sections carry no gloss: [probe](#g-probe) at 62
(§8.1); probe at 904 and [port](#g-port) at 905 (§8.4);
[assembly](#g-assembly) at 924 (§8.5); [device](#g-device) and
[trace](#g-trace) at 1138 (§8.6); assembly at 1494 and
[component](#g-component) at 1508 (§8.7); assembly at 1553 (§8.8).
Fix: add the glossary's gloss in parentheses at each. Examples: 62 "probes
(the build's single evaluation of a user function)"; 924 "an assembly (a
component of pure composition)".

**P16.** Lines 316 and 447, units B1 and B2. EDIT.
"the structure step" is first used in §8.2 at 316. Its gloss "(the build's
first step, declaration reading only)" sits at 447.
Fix: move the gloss to 316. At 447 write the plain "in the structure step".

### Facts stated twice

**P17.** Lines 297–298 and 379–381, units B1 and B2. EDIT.
§8.2 glosses `Pinned` twice. B1's moved criterion gives "the leaf wrapper
`Pinned{P}`, which yields `P` at every activation". B2 then introduces it
again: "the `Pinned{P}` marker. The marker wraps a leaf type to say that the
leaf never follows the activation scalar." It is one thing under two names,
"wrapper" and "marker".
Fix: 379–381 "The one piece of framework vocabulary it admits is the
`Pinned{P}` marker (above). It wraps the whole entry, and **a marker below
the top of an entry is `IllegalPortType`** ([D-265][d-265])." At 297 write
"the leaf marker `Pinned{P}`".

**P18.** Lines 485–486 and 493–494, unit B2. EDIT. Made worse.
"a root input must resolve to a concrete declaration" appears twice, nine
lines apart. M1 moved the abstract-at-root block (old 707–711) next to the
root-input opening, which already says it.
Fix: 493–494 "… still cannot be built bare. `AbstractAtRoot` names the face
and the remedy …". Drop the "because" clause; 485–486 carries it.

**P19.** Lines 963–964 and 1034–1035, unit D. EDIT. Made worse.
§8.5 glosses did-you-mean twice, with two wordings. Unit D moved the link and
gloss to 963 ("a name-shaped failure that carries the list-in-hand"). The
bullet at 1034 kept the old gloss as a sentence: "The error carries the
offending name plus the list-in-hand it should have matched."
Fix: delete the sentence at 1034–1035. To match §8.2–§8.4, 963 may read "(the
offending name plus the list-in-hand it should have matched)".

**P20.** Lines 937 and 1020, unit D. EDIT.
`transparent_container`'s default `nothing` is stated in the opening (937)
and again in "Container children" (1020).
Fix: at 1020, cut "and its default is `nothing`. That field's" to "That
field's". Keep the opening's mention, which comes first.

**P21.** Lines 1640 and 1689, unit F. EDIT.
"At the scale of Flight.jl's C172X demo" is used twice, and 1640 uses "the
feed list" before §8.8 has introduced one.
Fix: 1640 "`select` exists for feed lists, the idiom of "One authored feed
list" below. There the feed list already computes the `except` tuple."
1689 keeps the introducing clause.

### Pointers

**P22.** Line 1194, unit E1. EDIT. Pre-existing.
"a face's cells follow the producer's own declaration ([§8.5][s8-5])". The
next clause says the cells are walked on the continuous tier and pinned on
the discrete one. That reading of a producer's declaration is §8.2's
`y_types` block (564–569). §8.5 says only that an assembly has no contract of
its own.
Fix: "([§8.2][s8-2])".

**P23.** Line 867, unit B4. EDIT.
"The forgotten-branch walkthrough holds." names §8.4's walkthrough 3 without
a pointer. The sentence just before cites walkthrough 1 by number.
Fix: "[§8.4][s8-4]'s walkthrough 3, the forgotten branch field, holds."

### Bold

**P24.** Line 1178, unit E1. EDIT. Pre-existing.
"**Direction is therefore declared by the method**". `spec_style.md` says a
"so" before a rule demotes it to a consequence, and "therefore" sits inside
the bold. D-170 states it as a chained ruling ("direction is *declared by the
method*").
Fix: "**Direction is declared by the method**, not inferred
([D-170][d-170]). Every pair's arrow points the way the signal flows …". Put
the bold sentence first and the invariant after it as its reason. Or keep
the order and drop "therefore".

**P25.** Lines 672–678, unit B3. EDIT.
The bold headline "**The first bug lurks, but is never silent**" depends on a
"first bug" the text never numbers. Lines 675–676 give two cases in one
sentence ("writes `Pinned` at a leaf that really participates, or omits it at
one that really does not"). The reader must work out which is first. 683
then names "the second bug".
Fix: 674–676 "What remains is deliberate, and it comes in two bugs. The first
writes `Pinned` at a leaf that really participates. The second omits it at
one that really does not." Keep the bold as is.

### Intro, roadmap and section openings

**P26.** Lines 5–14, unit A. EDIT.
The roadmap says "component side" twice in a row ("§8.1–§8.4 cover the
component side … On the component side, §8.1 …"), and "assembly side" the
same way. Its §8.5 entry names only assembly declaration and class reading.
Container children and `Group` take more than half of §8.5 (988–1122). Line
14 runs to 82 rendered columns.
Fix: "The first four sections cover the component side. [§8.1][s8-1] lays
the foundations of the declaration layer, [§8.2][s8-2] lists the declaration
inventory, [§8.3][s8-3] says what a contract makes visible, and
[§8.4][s8-4] gives the five failure walkthroughs that ground error locality.
The last four cover the [assembly](#g-assembly) side. [§8.5][s8-5] covers
assembly declaration, how a type's class is read, container children and
`Group`. [§8.6][s8-6] covers …" (rest unchanged), rewrapped.

**P27.** Line 238, unit B1. EDIT.
§8.2 opens on a code block with no context sentence. The sentence that says
what the section does comes after the block (282–283). Every other section
of the chapter opens with context.
Fix: move 282–283 above the block and fold the lead-in into it: "This
section takes a component's declarations one by one, and records where each
schema fact gets its authority. One continuous primitive, declared end to
end, shows them together:". Then delete 282–283.

**P28.** Lines 893–896, unit B4. EDIT.
§8.4's opening, "The five mistakes below decided declaration-vs-inference",
uses a coined compound a cold reader cannot expand. It also does not point to
§8.1, where the choice is made, or link error locality, the section's
subject. Line 894 runs to 90 rendered columns.
Fix: "The five mistakes below decided the choice between declaration and
inference-by-evaluation as the schema authority ([§8.1][s8-1]). They ground
[error locality](#g-error-locality) (the property that a mistake fails at the
site of the mistake). The list gives each with its failure site under this
layer. Each was traced under inference-by-evaluation too, …".

**P29.** Lines 924–926, unit D. EDIT.
§8.5's context sentence names its parts but skips "One arity on both tiers"
(977).
Fix: "… how a type's declarations mark it as an assembly or a primitive, what
arity those declarations take, how container fields contribute children, and
how `Group` assembles components on the fly."

**P30.** Lines 1494–1496, unit F. EDIT.
§8.7 is titled "Rate scopes", but its body never uses or links the term. The
only gloss is §8.5's (997). A reader arriving at §8.7 cold cannot tie the
title to `sample_times`.
Fix: "An [assembly](#g-assembly) (a component of pure composition) schedules
its children through one declaration, `sample_times`, its
[rate scope](#g-rate-scope)." This also covers P15's missing gloss at 1494.

### Reader-cold names

**P31.** Line 750, unit B4. EDIT. Pre-existing.
"The "decoder takes no inputs" property" uses log vocabulary. "Decoder"
means stage 1 (`y_state`), and nothing in the chapter says so. B4's verifier
flagged it.
Fix: "The property that stage 1 takes no inputs is exactly what makes the
derivation well-founded."

**P32.** Lines 682, 709 and 769, units B3 and B4. EDIT. Pre-existing.
"the didactic hint" (682), "the didactic style" (709, 769). The term is
defined in §13.2 ("Every diagnostic states the fix or the lists-in-hand").
§8.2 never points there.
Fix: at 682, "The message carries the didactic hint (a diagnostic that states
its fix, [§13.2][s13-2]) …". At 709 and 769 the bare term then reads.

**P33.** Line 801, unit B4. EDIT. Pre-existing.
"the mixed-store cases the split state letters restore". Nothing in the
chapter says what the split letters are.
Fix: "the mixed-store cases that the split state letters (`x` for continuous
state, `s` for discrete, [D-195][d-195]) restore".

**P34.** Line 818, unit B4. EDIT. Pre-existing.
"Members of both families, or of neither, are the §8.5 class errors." §8.2
never introduces the families. They are §8.5's leaf and assembly declaration
families.
Fix: "A type declaring both the leaf and the assembly families of
declarations, or neither, meets the class errors of [§8.5][s8-5]."

**P35.** Lines 397 and 579–580, units B2 and B3. EDIT.
`RQuat` appears in B2's table at 397. It is introduced at 579–580 ("`RQuat`
and `Ranged` are domain wrapper types (§7.1)"), 180 lines later. This breaks
define-before-use.
Fix: add the clause at the first use, after the table: "(`RQuat` is a domain
wrapper type, [§7.1][s7-1].)". Or move 579–580's sentence to follow the
table and leave 579 with "`Ranged` is a domain wrapper type too".

**P36.** Line 1067, unit D. EDIT. Pre-existing.
"The *immutable* version of "grouping components by plain calls"" puts the
phrase in quotes, but no text in the chapter says it.
Fix: drop the quotation marks: "The *immutable* version of grouping
components by plain calls needs no builder …".

**P37.** Lines 1762–1765, unit F. EDIT. Made worse.
"A guidance scenario component … wires two of the faces. They are `mode_req`
and `EAS_ref` …". "The faces" has no referent. The old sentence named the two
faces at once and had no such gap.
Fix: "A guidance [scenario component](#g-scenario-component) (the home of a
sim-time script) wires only `mode_req` and `EAS_ref`, the
equivalent-airspeed reference. The remaining faces stay exported for GUI or
defaults."

### Wrapping

**P38.** Lines over 80 rendered columns, several units. EDIT.
With link markup collapsed, these prose lines run past 80:
14 (82, A), 79 (119, A), 353 (92, B1), 420 (81, B2), 727 (85, B4),
847 (83, B4), 849 (82, B4), 894 (90, B4), 949 (87, D), 1292 (107, E1),
1373 (90, E2), 1607 (89, F). Each is an inserted clause that was not
rewrapped. 79 and 1292 are the worst. 79 holds the added "(`Engine` is the
example component of §8.2)". 1292 holds the added label pointer "(below,
under "The boundary-sampling contract")".
Fix: rewrap each paragraph to 80 rendered columns. 14 and 894 are rewrapped
by P26 and P28.

**P39.** Short lines and blank lines left by edits, several units. EDIT.
These source lines stop well short, although the next word fits:
838 (27 columns, "interface) are connectable,", B4) and 1141 (27, "[§8.5][s8-5])
add index and", E1) are the worst. Others: 137 (A), 351 (B1), 630 (B3), 850
(B4), 991, 1009 (D), 1172, 1221 (E1), 1447, 1465 (E2), 1507, 1521, 1544, 1603,
1765 (F). Lines 373–374 and 819–820 are double blank lines at unit seams,
B1/B2 and B4/§8.3.
Fix: rewrap the paragraphs holding them, and collapse each double blank line
to one.

### Made worse in other ways

**P40.** Lines 848–850, unit B4. EDIT. Made worse.
"FlightCore is the precedent, where an intermediate was inspected by putting
it in FlightCore's model output and no other way." The sentence names
FlightCore twice, and "and no other way" trails the clause it limits. The old
text said "the `Model` output", once.
Fix: "FlightCore is the precedent. There an intermediate could be inspected
only by putting it in the model's output."

**P41.** Line 1286, unit E1. EDIT.
"Two facts the example carries." is a verbless fragment used as a topic
sentence. The old text had the same fragment with "Three".
Fix: "The example carries two more facts."

**P42.** Line 377, unit B2. EDIT. Pre-existing.
"An `u_types` declaration". `u_types` is read "you-types".
Fix: "A `u_types` declaration".

## RULING items

**P43.** Lines 285–287 and 794–796, units B1 and B4. RULING.
§8.2 states the arity criterion twice. B1's moved criterion paragraph has the
bold "**Every declaration of a structural fact but the allocator takes the
component alone**" and says "It is stated once here, and the blocks below
refer back to it". B4's Completeness block then restates it in R13's
wording: "No arity carries a tier. Every declaration of a structural fact
takes the component alone, except `ws_init`, which takes the scalar on both
tiers ([D-263][d-263])." §8.5 (980–983) states it a third time, as R5's
pointer. R13 fixed the wording at old 2574, not whether it stays once the
criterion opens the section.
Options: (a) cut 794–796's two sentences to "No arity carries a tier
(above)"; (b) keep them and change 287 to "It is stated in full here".
Recommendation: (a). The claim survives at 285, and 287 stays true.

**P44.** Lines 320–334 against 771 and 781–783, 805–809, units B1 and B4.
RULING. Pre-existing.
§8.2 states the store-as-tier-marker rule twice, about 450 lines apart. "The
stores" (B1) has every leaf declaring exactly one of `x_init` and `s_init`,
the empty spellings `x_init(::Gain) = (;)`/`s_init(::Sampler) = (;)`,
`TierUnreadable`, and "An empty store owes no update law". "Completeness"
(B4) states each again: 771 "An empty store … owes nothing"; 781–783 "Every
leaf declares `x_init` or `s_init`, and the two are disjoint"; 805–809 the
two empty spellings and `TierUnreadable`. The old text had both, in two
blocks a reader met apart. Now both sit in one section.
Options: (a) reduce Completeness' copies to pointers ("Tier is declared by
the store (above)") and keep only what is new there: the update-law
announcement, `StatelessWithoutOutputs` and the bundle note; (b) keep both.
Recommendation: (a). The brief bars cuts not ordered by a ruling, so this
needs one.

**P45.** Lines 389 and 435, unit B2. RULING.
Two bolds may state one ruling. "**Entries are face bounds, not cell types,
and the reading is permissive**" and "**Two clauses check a wire**" both rest
on D-263's bullet 2 ("The permissive reading … stands … Both wire clauses of
§6.1 stand"). B2 kept the second because D-236's Position also states it,
and listed the double as open. No ruling followed.
Options: (a) unbold "Two clauses check a wire" and keep its citations; (b)
rule that the D-236 Position makes it a distinct ruling.
Recommendation: (b). D-236's Position ("Both clauses of §6.1 are this
relation") states the clause pair as its own ruling. §8.2 is where it is
stated.

**P46.** Lines 136, 188 and 960–966, units A and D. RULING.
R7's F12 points §8.1 at §8.5 for `ClassUnreadable` twice (136, 188).
Appendix C (spec 11759) cites §8.5 for it too. But §8.5 states the rule
("It is a build error naming both families", 961–962) and never names the
kind. Appendix C also cites §8.5 for `ChildNameCollision` (spec 11796) and
`TierUnreadable` (spec 11803). §8.5 names neither. `TierUnreadable` is
named only in §8.2. A reader following either pointer finds the rule with no
name.
Options: (a) name `ClassUnreadable` at 961–962 and `ChildNameCollision` at
the collision bullet (1047–1052), with no change of claim; (b) leave §8.5 as
is and record the Appendix C pointers for the inbound-citation pass.
Recommendation: (a) for `ClassUnreadable`, since this rewrite's own pointers
send the reader there. Settle the other two in the inbound pass.

**P47.** Line 889, unit B4. RULING.
After R4's cut, the pointer names "the `unlisted` flag ([§4.2][s4-2]) and its
satellite-function representation". Neither the chapter, §4.2 nor the log
explains "satellite-function representation". The word "satellite" appears in
no entry, and D-016's Rejected list, which holds the `unlisted` convention,
does not use it. The phrase cannot be glossed from a source.
Options: (a) drop "and its satellite-function representation" and keep "the
`unlisted` flag ([§4.2][s4-2])"; (b) the owner supplies a source, and the
phrase gets a gloss from it.
Recommendation: (a), unless the owner can source it.
