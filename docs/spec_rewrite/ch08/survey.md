# Survey of spec chapter 8 before its readability rewrite — 2026-10-02

Scope: `docs/design/spec.md` lines 1901–3390, "## 8. The declaration layer:
components and assemblies", at commit `084d6f0` (the working tree's `spec.md`
equals it), 12,392 words. The convention is `docs/design/tools/spec_style.md`;
the method is `docs/spec_rewrite/recipe.md` step 1; the model is chapter 10's
survey (`git show 0f9ce8a:docs/spec_rewrite/ch10/survey.md`).

Line numbers are `spec.md` lines unless marked `log` (`decisions.md`) or given
with a file name. Entry claims rest on the entry's Position as read, with its
log line given where the point sits outside the Position's first sentence.
Every entry a rule is classified under was read in full: the 47 the chapter
cites and 33 more that rule its content or list it in their Spec field
(copies in `scratch_survey/entries/`). Entries named only as the source of an
inbound row or of a mechanism were read at the cited lines. The code in `src/`
was read where a name or a claim about code was in doubt.

Classification codes used in part A:

- **C** cited, and ruled by the cited entry's Position (at the spot or in the
  same paragraph, marked "adjacent").
- **U** ruled by an entry's Position that the section does not cite at that
  spot.
- **S** cited to a superseded entry.
- **R** ruled only in an entry's Rationale, Rejected list or annotation.
- **N** no entry found. Where the sentence reads as a description of an
  inherited status quo rather than a ruling, the row says so.
- **B** borderline; both readings are given.

"Marking" is how the spec marks the rule now: **Rule.**/**Why.** label, bold
sentence, bold lead-in (a bold phrase opening a paragraph, used as a heading),
bold words, or plain. The chapter carries 13 **Rule.** labels, 10 **Why.**
labels and one **Why `select` exists.** label.

Section sizes (words, `wc -w` over the line ranges): chapter heading and intro
71 (1901–1909); 8.1 1,599 (1910–2109); 8.2 4,572 (2110–2611); 8.3 470
(2612–2667); 8.4 241 (2668–2693); 8.5 1,387 (2694–2879); 8.6 2,456
(2880–3178); 8.7 224 (3179–3201); 8.8 1,372 (3202–3390, the closing `---`
included). Subsection sizes are in `scratch_survey/wc.sh`'s output and in
part C.

Rows that are reasons, mechanisms, examples, pointers or code are kept in the
tables for the rewriters but left out of the tally (part A, "Tally").

## A. Per section

### Chapter intro (1901–1909, 71 words)

Purpose: says what the chapter covers (how an author spells a component, where
structural facts live, what the build takes as authoritative) and splits it
into the component side (§8.1–§8.4) and the assembly side (§8.5–§8.8), with
pointers to §9 and §14.

It already has a context paragraph and a roadmap. Two points for the rewrite:

- 1907–1908 "The concrete syntax below is near-final in shape but still
  illustrative in spelling." This is a standing caveat on every code block in
  the chapter. It stays, and it bears on F6 (part E): the `Group` sketch is
  "near-final in shape" but lacks a field `src/` has.
- The roadmap names the two halves but not their subjects. A roadmap sentence
  naming the eight sections would serve a returning reader (part C).

No rules. No display-block candidates.

### §8.1 Position: a declarative trait layer in plain Julia, no macros (1910–2109, 1,599 words)

Purpose: the foundations of the declaration layer. No macro DSL; how an
author's methods reach the framework (the namespace trap and its two checks);
the four naming classes; declarations as schema authority; contracts as
functions of the type.

Subheadings (`####`): "Plain Julia, not a macro DSL" (1923, 159 words), "The
namespace: declarations are extended, not called" (1946, 702), "Names: four
classes by role" (2032, 238), "Declarations are the schema authority" (2063,
87), "Contracts are functions of the type, not of the instance" (2077, 293).
The opening paragraph (1912–1921, 120 words) announces four questions
(macros, namespace, schema, type) and omits the fifth subsection, "Names"
(F17). Labels: **Rule.** 1925, 1948, 2034, 2065, 2079; **Why.** 1927, 2089.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 1 | 1912–1916 | "A component is authored in ordinary Julia. Its stage functions … are ordinary multiple-dispatch methods, on the `GUI.draw!` precedent. Its structural facts are declared through a small set of well-known functions returning plain values" | plain | D-032 Position ("well-known functions returning plain values; stage functions ordinary methods") | U (D-032 first cited 1928); "`GUI.draw!` precedent" is reader-cold (F14) |
| 2 | 1925 | "**Rule.** There is no macro DSL." | **Rule.** label | D-032 Position ("convenience macros addable a posteriori, never essential"); Rejected log 1002–1003 | C (adjacent, 1928) |
| 3 | 1927–1928 | "**Why.** The debugging, tooling and comprehension criterion (§1) decides it (D-032)." | **Why.** label | D-032 Rejected log 1002–1003 | reason |
| 4 | 1930–1932 | "Redundancy between declarations and function bodies is accepted deliberately, under one non-negotiable condition. **Every inconsistency fails loudly**, at build time where possible and at first execution otherwise." | bold words | D-032 Position ("build probe with real values + free always-on conformance") | B: U by D-032 for the mechanism; N for the "non-negotiable condition" as worded. spec 3892 and 4167 quote "at build time where possible" and "at first execution otherwise" (part F) |
| 5 | 1934–1936 | "A macro can only ever *lower to* a layer like this one. A convenience macro therefore remains addable a posteriori as pure sugar, on the `@kwdef` precedent, and never becomes essential." | plain | D-032 Position; Rejected log 1002–1003 ("only ever lowers to the trait layer") | U |
| 6 | 1938–1941 | "A macro generating the well-known declarations is admissible sugar *on top of* the plain-Julia forms. It is never a replacement for them and never required to author a component (D-166)." | plain | cited D-166, superseded → D-263 (log 5720); the live ruling is D-032 Position | S |
| 7 | 1941–1942 | "The obvious candidate is the `where {T <: Real}` ceremony of a continuous `y_types` (§8.2)." | plain | none; the ceremony was retired by D-263 Position (log 10171–10173) | N; stale (F2) |
| 8 | 1942–1944 | "Every rule in this part is stated over the generated methods, so a macro that lowers to them adds convenience and no semantics." | plain | D-032 Rejected log 1002–1003 | description |
| 9 | 1948–1950 | "**Rule.** The framework's extensible functions are extended, not called. Authoring a component means adding methods to framework-owned generic functions." | **Rule.** label | D-117 Position | U (D-117 first cited 1967) |
| 10 | 1952–1955 | "Julia admits that only through an explicit per-name `import`, or through a qualified `Cadence.x_deriv(…) = …` definition. The latter is the `Base.show` idiom …" | plain | D-117 Position ("qualified definition … the recorded alternative for the extension-only periphery") | U |
| 11 | 1955–1962 | "A component module therefore opens with" + the `import Cadence: …` block | code | D-117 Position ("normative authoring surface stated in §8.1"); the 17 names equal `DECLARATION_FAMILY`, `src/declare.jl` 254–258, in the same order | code |
| 12 | 1964 | "**The explicit list is needed because `using Cadence` alone is a silent trap.**" | bold sentence | D-117 Position (per-name import); Rejected log 3498–3501 (the trap) | B: U by D-117 for the rule; R for the trap |
| 13 | 1966–1967 | "The declarations are deliberately unexported (D-117)." | plain | D-117 Rationale log 3493–3495; D-226 Position bullet 3 (log 8272–8273) | B: R by D-117; U by D-226 |
| 14 | 1977–1978 | "Two mitigations, both normative. The first is that the import list above is authoring surface, stated wherever a component file is first shown." | plain | D-117 Position | U |
| 15 | 1978–1985 | "The second is a **shadowing check** in the structural walk (§9.1), run on every component before its class is read (D-246). … the build throws `DeclarationShadowed`, alone, naming the module, the foreign names and the missing import" | bold term | D-246 Position | C |
| 16 | 1985–1988 | "The check is a two-line `isdefined`/`!==` test on the family's names. Those names are distinctive by design (D-220)" | plain | D-246 Rationale log 9126–9128; D-220 Rationale log 7991–8002 | mechanism |
| 17 | 1988–1994 | "The check throws alone because nothing the module declares can be trusted. … It runs on every component rather than only where an absence is noticed" | plain | D-246 Rationale log 9100–9124 | reason |
| 18 | 1996–1997 | "A convenience macro expanding to the import list remains addable a posteriori as sugar, per this section's macro doctrine." | plain | D-117 Rejected log 3505–3506 | R |
| 19 | 1997–1999 | "A re-export submodule is not an alternative, because per-name `import` is the only *unqualified* extension mechanism the language provides (D-117)." | plain | D-117 Rejected log 3502–3504 | R; adversarial (part G q4) |
| 20 | 2001–2006 | "**The same trap has a local-scope sibling** (D-164). Written inside a `let`, a function body or a `@testset` …" | bold lead-in | D-164 Rationale log 5597–5611 | C for the citation; the trap's account is R |
| 21 | 2018–2021 | "**A component that declares nothing and defines no stage is rejected at build time**, because an inert component is unwritable on purpose." | bold sentence | D-164 Position | C (adjacent, 2001); the refusal is `ClassUnreadable`, unnamed here (F12) |
| 22 | 2023–2025 | "The authoring rule is one line. Declarations live at module top level." | plain | D-164 Position | C (adjacent) |
| 23 | 2027–2030 | "The net holds under a *partially* shadowed component too … reads as 'declared but not produced' (§8.3)" | plain | none | description |
| 24 | 2034–2035 | "**Rule.** Every name on the framework's surface belongs to one of four classes, and its class fixes its grammatical shape (D-144)." | **Rule.** label | D-144 Position | C |
| 25 | 2037–2044 | "**Declarations** are noun phrases naming what they return, prefixed by the bundle field they define where one exists (D-267). An assembly's boundary declarations take `u` and `y` too … (D-279)" | numbered list, bold term | D-267 Position bullet 3; D-279 Position bullet 2; D-220 | C |
| 26 | 2045–2048 | classes 2–4: "**Value selectors** carry `get_`", "**Lifecycle and mutating actions** are verbs", "**Build primitives** are plain verbs (§13.3)" | bold terms | D-144 Position | C (adjacent) |
| 27 | 2050 | "A name in the wrong class is a rename candidate on that ground alone." | plain | D-144 Position | C (adjacent) |
| 28 | 2052–2058 | "**The convention also has a semantic axis.** … A declaration names its *content*, never the *consequence* the declaration has. … The `*_connections` family names content deliberately … That is a recorded choice, not class drift." | bold lead-in | D-146 Rationale log 4941–4945; D-170 Rejected log 6009–6011 | R; the rule as written inverts the log (F1, serious by the letter) |
| 29 | 2060–2061 | "Which names the module exports is a separate question. It stays open until the exported-name audit in `pending.md` runs (D-226)." | plain | D-226 Position | C |
| 30 | 2065–2066 | "**Rule.** Declarations *define* the model's structure. Evaluation *checks* conformance against them, never the reverse." | **Rule.** label | D-032 Position ("declarations define, probe evaluation checks") | C (adjacent, 2074) |
| 31 | 2068–2071 | "The build probes user functions with real values, with no reliance on compiler inference … The same comparison then runs on every subsequent evaluation for free" | plain | D-032 Position | C (adjacent) |
| 32 | 2073–2075 | "Inference-by-evaluation as schema authority is rejected on three counts, established by walkthrough (§8.4) and litigated in D-032. Types come by declaration, values by execution, and conformance by comparison." | plain | D-032 Rejected log 989–1001 | R; glossary 12193 repeats the last sentence nearly word for word |
| 33 | 2079–2082 | "**Rule.** A leaf's contract declarations (…) must be determined by the component's **type**, its type parameters included, and never by its field *values*." | **Rule.** label | D-033 Rationale log 1023–1028 | R |
| 34 | 2084–2087 | "The value-discarding signature `u_types(::Engine)` is the visible form of the rule. The idiom for a contract that genuinely varies is the type parameter …" | plain | D-033 Rationale | example |
| 35 | 2089–2099 | "**Why.** The entry typing decides it (§9.7). …" | **Why.** label | D-033 Rationale ("because §9.7's entry typing derives the bundle key set from the type") | reason |
| 36 | 2101–2103 | "This is a rule authors keep, not a check the build can run." | plain | D-033 Rationale log 1027–1028 | R |
| 37 | 2105–2109 | "**`ws_init` is the one exception**, and explicitly so. It is the by-allocation convention (D-077) … It legitimately takes sizes from the instance" | bold lead-in | D-077 Position (by allocation), Rationale log 2234 (sizes from the instance); the exemption is D-033 Rationale log 1025–1026 | B: C by D-077; R for the exemption |

Descriptions that read like rules: row 8 (a claim about how the part is
written); row 23 (a consequence of rows 21 and §8.3, no entry). Row 4's
"non-negotiable condition" has no Position wording; D-032 states the mechanism
(probe plus always-on check), not the condition. The phrase is quoted from
outside (spec 3892, 4167), so it is wording the rewrite must keep.

The namespace subsection names two diagnostics before any definition:
`StoreWithoutUpdate` and `ClassUnreadable` (1971), as the counterfactual of a
shadowed module. Each needs a gloss or a pointer (§8.2, §8.5).

Display-block candidates: the shadowing message at 1983–1985 stays verbatim
inline, as a quoted diagnostic. The one-line authoring rule "Declarations live
at module top level" could stand as its own short paragraph. No new code
blocks are needed.

### §8.2 The declaration inventory (2110–2611, 4,572 words)

Purpose: the leaf declarations one by one, with the source of authority for
each schema fact: the stores by value, the contracts by type, the workspace by
allocation; then the event declaration, stage membership, custom port types
and the four completeness rules.

Subheadings (`####`): "State, modes, discrete state" (2159, 695 words),
"`u_types(::C)`" (2232, 1,205), "`y_types(::C)`" (2360, 1,299),
"`state_events(::C)`" (2501, 89), "No stage tags anywhere" (2513, 116),
"Custom structs as port types" (2527, 130), "Completeness of the declaration
set" (2541, 718). The opening (2110–2158, 320 words) is the `Engine` block and
one roadmap sentence. Labels: **Rule.** 2161, 2169; **Why.** 2178, 2185, 2205,
2296, 2349, 2445. Bold lead-ins act as headings throughout: 2216, 2280, 2293,
2313, 2320, 2336, 2402, 2457, 2471, 2478, 2546, 2557, 2563, 2597.

#### Opening and stores (2110–2231)

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 38 | 2112–2154 | "One continuous primitive, declared end to end:" + the `Engine` block | code | — | code; its comments cite §14.2, §8.3, §5.2, §5.3, §10.6, §2.1, §12.5, all checked |
| 39 | 2156–2157 | "The blocks below take that inventory declaration by declaration, and record where each schema fact gets its authority." | plain | — | roadmap |
| 40 | 2161–2163 | "**Rule.** `x_init` on the continuous tier, `s_init` on the discrete, and `m_init`, declare *by initial value*. The type is derived from the value." | **Rule.** label | D-033 Position ("`init_*` by value (type derived — nothing to drift)"); D-073 Position ("declaration-by-initial-value upheld") | U |
| 41 | 2163–2167 | "The value is a `NamedTuple`, one named field per leaf, and no other form is admitted. A bare leaf … is refused. The structure step reports it as `StoreNotNamedTuple` … (§9.1, Appendix C, D-247)." | plain | D-247 Position | C |
| 42 | 2169–2173 | "**Rule.** Every leaf declares exactly one of `x_init` and `s_init`, and a stateless leaf declares it empty … The store is the tier marker, so it is mandatory even when empty … (§8.5, D-263)." | **Rule.** label | D-263 Position bullet 5 | C |
| 43 | 2173–2175 | "A primitive declaring neither store is `TierUnreadable`, and its message spells the empty form." | plain | D-263 Position bullet 6; D-215 Position bullet 1 | C (adjacent) |
| 44 | 2175–2176 | "An empty store owes no update law … and it puts no letter in the bundle (§5.2)." | plain | D-263 Position bullet 5 ("`StoreWithoutUpdate` applies to a non-empty store only"); bundle clause D-263 Rationale log 10242–10244 | C (adjacent) |
| 45 | 2178–2183 | "**Why.** A continuous component's state may be empty (§3.1) … with no tier by omission. It also closes a trap." | **Why.** label | D-263 Rationale log 10238–10257 | reason |
| 46 | 2185–2189 | "**Why.** Every service reaches a leaf by its field name. … and a one-field store publishes its field as the port of that name (§5.3)." | **Why.** label | D-247 Rationale log 9175–9186 | reason; the publication clause is stale since D-252 (F3) |
| 47 | 2191–2198 | "The workspace … is declared *by allocation*, as `ws_init(::C, ::Type{T})` on both tiers, and the method itself is the allocator. … `ws_init` alone declares by allocation" | plain | D-077 Position; D-263 Position bullet 4 | U (D-077 cited only at 2229) |
| 48 | 2195–2196 | "A workspace earns the exception because it is not memory and none of the by-value arguments below cover it (§7.3)." | plain | D-077 Rejected log 2251–2254 | reason |
| 49 | 2200–2203 | "Deriving from another declaration is sound, and deriving from evaluated user code is not. Declaring types here too, `u_types`-style, with `probe_value` (§9.3) synthesizing the initial values, was rejected (D-073)." | plain | D-073 Rejected log 2112–2123; D-032 Position for the first sentence | R; the second sentence is adversarial (part G q4) |
| 50 | 2205–2209 | "**Why.** The declared values are the base layer of the condition substrate … so there must be an authored value under every leaf." | **Why.** label | D-073 Rejected log 2114–2117 | reason |
| 51 | 2211–2214 | "The asymmetry against `u_types`/`y_types` is one of kind, not style." | plain | D-073 Rejected | reason |
| 52 | 2216–2218 | "**Every declaration but the allocator takes the component alone**, and the criterion is the declaration convention it lives in (D-263)." | bold sentence | D-263 Position first sentence ("Every contract declaration takes the component alone"), bullet 4 | C; "every declaration" reads past the stages and update laws, which take a bundle too (F22) |
| 53 | 2218–2226 | "A *by-value* declaration states nominal physics, and its *types* walk by rule … Partials enter through per-invocation seeding, never through initialization. A *by-type* declaration walks by the same rule … with `Pinned`" | plain | D-263 Position bullet 1 (the walk); D-079 Rationale log 2316 (seeding) | B: U by D-263; R by D-079 for the seeding clause |
| 54 | 2226–2229 | "A *by-allocation* declaration is the exception. … `ws_init(c, T)` takes it on both tiers (D-077)." | plain | D-263 Position bullet 4; D-077 annotation log 2241–2244 | C |
| 55 | 2229–2230 | "The criterion, not uniformity, is the rule. A `T` in a signature means the framework could not have supplied it." | plain | D-263 Rationale log 10207–10212; D-166 Rejected and annotation (superseded) | R |

#### `u_types(::C)` (2232–2359)

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 56 | 2234–2236 | "An `u_types` declaration is a bare `NamedTuple` of types, written at nominal `Float64` and taking the component alone on both tiers." | plain | D-263 Position | U |
| 57 | 2236–2239 | "The one piece of framework vocabulary it admits is the `Pinned{P}` marker … a marker below the top of an entry is `IllegalPortType` (D-265)." | plain | D-263 Position bullet 1; D-265 Position | C |
| 58 | 2239–2242 | "On a continuous consumer the declaration is walked … On a discrete consumer it pins wholesale, and a `Pinned` entry there says nothing and is `DeclarationOnWrongTier` (§8.5)." | plain | D-263 Position bullet 1 | U |
| 59 | 2244–2246 | "Entries are **face bounds, not cell types**, and the reading is **permissive** (D-167)." | bold words | cited D-167, superseded → D-263 (log 5820); D-263 Position bullet 2 states it; D-078 Position (face constraints) | S |
| 60 | 2248–2252 | the three-row table: tolerant, demanding frozen, as it always was | table | D-263 Position bullet 2 (with D-167's content) | table; carry verbatim |
| 61 | 2254–2256 | "An unpinned entry is what a promoting consumer writes … A walking producer, a frozen discrete producer and a root input are all admissible behind it, so substitution stays intact." | plain | D-263 Position bullet 2; D-264 Rationale log 10351–10352 calls it "§8.2's substitution promise" | U |
| 62 | 2258–2263 | "A `Pinned` entry is the **FFI door**. This input must never carry partials. A component whose internals cannot propagate `Dual`s … declares it" | bold words | D-263 Rationale log 10221–10224; D-266 Position (uncited) qualifies it | B: R by D-263; D-266 owed (F20) |
| 63 | 2265–2272 | "Abstract entries state **structural substitutability** … They are still never the tool for eltype genericity." | bold words | D-078 Rationale log 2273–2275 | R |
| 64 | 2274–2278 | "Names-only contracts were rejected (D-033). Inputs are the component's *requirements*." | plain | D-033 Rejected log 1045–1046 | R; adversarial (part G q4) |
| 65 | 2280–2284 | "**Two clauses check a wire** (§6.1). The **nominal bound check** is stated at nominal. … must be `<:` the entry at `Float64`. … degenerates to exact equality for a concrete entry" | bold lead-in, bold words | D-078 Position; D-236 Position | U |
| 66 | 2284–2288 | "the **tier-scoped walk-compatibility clause**. For a *continuous* consumer, a walking producer leaf … requires an unpinned entry, while a pinned producer leaf satisfies either … An opaque leaf … is admitted at an unpinned entry as the producer's cell (D-264)." | bold words | D-263 Position bullet 2 ("Both wire clauses of §6.1 stand"); D-236 Position; D-264 Position | C for the opaque clause; U for the walk clause |
| 67 | 2288–2291 | "the clause is decidable in the structure step … by retyping them at a marker scalar. No user stage code runs (§9.1), and a violation is `WalkingFaceAtFrozenEntry`." | plain | D-263 Position bullet 2; D-236 Position | U; the kind's name is stated only in superseded D-167's Rationale (log 5844) and Appendix C |
| 68 | 2293–2294 | "**Discrete consumers take the bound check only**, and that scope is a correctness rule rather than tidiness." | bold lead-in | D-167 Rationale log 5848–5853 and annotation log 5874–5877 (superseded entry); D-263 bullet 2 only by reference to §6.1 | R; the log owes a live Position (part E) |
| 69 | 2296–2300 | "**Why.** A discrete stage reads exclusively at real ticks in the nominal world … The unscoped variant is rejected in D-167." | **Why.** label | D-167 Rejected log 5890–5892 (superseded) | reason; superseded citation |
| 70 | 2302–2304 | "Because entries are bounds, nothing is ever 'overwritten'. Cell types are single-sourced from the producer side per activation (§9.4)" | plain | D-054 Position | U |
| 71 | 2305–2309 | "The code-level complement is the **genericity obligation** … checked by the `Dual` probe, never declared, and it is **scoped to the unpinned entries**." | bold words | D-054 Position (obligation, checked by the probe); scope: D-167 Rationale log 5865–5868 (superseded) | B: U by D-054; R for the scope |
| 72 | 2309–2311 | "So **declarations record choices, and obligations are checked**." | bold words | D-078 Rationale log 2279 | R |
| 73 | 2313–2318 | "**The permissive reading is the operative one, and the two readings it escapes are rejected** (D-033, D-054, D-167, D-263)." | bold sentence | D-263 Position bullet 2 (operative); D-054 Rationale log 1555–1556, D-078 Rejected log 2285–2287, D-167 Rejected (the rejections) | B: C by D-263; R for the rejections; one superseded entry in the list |
| 74 | 2320–2327 | "**Root inputs are the one place an entry types a cell.** … The **root-input type** is the entry at `Float64`, markers stripped, and only a *tight* bound determines one. … Abstract-at-root is a build error, and `AbstractAtRoot` names the face and the remedy" | bold lead-in, bold words | D-236 Position bullet 3 (`AbstractAtRoot`); D-120 Position and Rationale (the remedy); D-078 Rationale log 2275–2277 (tight bound) | B: U by D-236 and D-120; R by D-078 for the tight bound |
| 75 | 2327–2330 | "Under fan-out the root-input type is the unique concrete declaration among its consumers, and abstract co-consumers are checked against it. Two different concrete declarations remain an error." | plain | D-236 Position bullet 3 (`RootInputTypeConflict`) | U |
| 76 | 2330–2334 | "The **root-input cells** at an activation follow the root-input type by retyping that same entry at the activation's `T`. This makes **seedability schema-visible**." | bold words | D-263 Position bullet 1 ("the leaf walk that types `init_x` and the root inputs"); seedability: D-167 Rationale log 5860–5863 and annotation (superseded) | B: U by D-263; R for seedability |
| 77 | 2336–2342 | "**Fan-out combines tolerance by a meet, not by agreement** (D-168). … A mixture of pins across leaves therefore pins the whole root input (D-236)." | bold lead-in | D-168 Position; D-236 Position bullet 2 | C |
| 78 | 2342–2347 | "Two consumers of one root input may agree at nominal and still differ in tolerance. … That mixture is a legitimate model rather than a mistake." | plain | D-168 Position; Rationale log 5908–5910 | C (adjacent) |
| 79 | 2349–2354 | "**Why.** The direction of the meet is forced by embedding." | **Why.** label | D-168 Rationale | reason |
| 80 | 2356–2358 | "What the mixture costs is stated where it is paid. Such a root input is unseedable, and a tap selecting it is rejected naming the *pinning consumer*" | plain | D-168 Rationale log 5916–5920 | R |

Two clauses in rows 66–68 duplicate §6.1 1275–1326 near-verbatim (part B,
other chapters). Rows 59, 68, 69, 71, 76 and 73 lean on D-167, superseded:
three citations name it, and three rulings (the tier scope, the obligation's
scope, seedability) live only in its Rationale and annotation.

#### `y_types(::C)` (2360–2500)

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 81 | 2362–2366 | "`y_types` declares the public port contract, and declares it **by type**. … Where the input side is read permissively, though, this one is read **literally**." | bold words | D-263 Position (walked, plain); "literal" is D-166's word, whose annotation says "The literal semantics … go" (log 5791–5792) | B: U by D-263; terminology hazard (F19) |
| 82 | 2368–2372 | "On a **continuous producer** … the cell types at an activation are that declaration retyped at the activation's `T` by the leaf walk (D-079, D-263). On a **discrete producer** the same spelling pins wholesale" | bold words | D-263 Position bullet 1; D-079 Position | C |
| 83 | 2373–2374 | "Which reading applies is decided by the leaf's tier, declared by its store (above and below), never by the contract's shape." | plain | D-263 Position (the tier never spelled in a signature; the store is the marker) | C (adjacent) |
| 84 | 2376–2378 | "Semantics are **literal** once the walk has run. The cell type is the retyped declaration, with nothing inferred. Participation is therefore authored **per leaf**" | bold words | D-263 Position; D-079 Rejected log 2327–2328 ("Probe-inferred participation") | U |
| 85 | 2379–2383 | "**`Float64`, alone or as a type parameter** … means the leaf **participates**. … Value parameters are structure rather than number and never take it" | bold words | D-263 Position bullet 3; D-079 Position (value parameters pin) | U |
| 86 | 2384–2391 | "**`Pinned{P}`** means the leaf is **deliberately pinned** … Declare `Pinned{Float64}` and strip with `ForwardDiff.value` inside the stage … The marker sits at the top of the entry and nowhere below it (D-265)." | bold words | D-263 Position bullet 1; D-286 Position bullet 3 (the strip idiom); D-265 Position | B: C by D-265; U by D-286 |
| 87 | 2392–2397 | "**`Int`/`Bool`/enum leaves and reference-typed fields** pin as they always did. … A handle carrying a scalar *parameter* walks like any type, and one built from build-time data is declared `Pinned` (D-237)." | bold words | D-079 Position; D-263 Position bullet 3; D-237 annotation log 8764–8768 | B: U by D-263, whose Position states it; the cited D-237 states it only in an annotation |
| 88 | 2398–2400 | "**A mutable type's parameters** pin by rule. No stage can produce a `Vector{Dual}` inside a handle without copying the grid at every evaluation" | bold words | D-263 Position bullet 3; Rationale log 10275–10278 | U |
| 89 | 2402–2405 | "**A handle keeps its bulk at `Float64` and its activation-dependent part in the parameter.**" | bold sentence | D-263 Position bullet 3 | U |
| 90 | 2407–2413 | the `DeckField{T}` block | code | — | code |
| 91 | 2415–2419 | "Inside a query nothing converts the grid. … A `Matrix{T}` grid would give the same numbers at the cost of a copy per evaluation" | plain | D-263 Rationale | mechanism |
| 92 | 2419–2422 | "The producer pins the handle when it is built from build-time data alone, a static terrain, and leaves it walking when its parameters come from state, a moving deck." | plain | D-263 Position bullet 3 | U |
| 93 | 2422–2425 | "A field that must never follow the scalar is typed concretely in its struct, `b::Float64` beside `a::T` … a pin on one parameter of one declaration is not offered (D-265)." | plain | D-265 Position | C |
| 94 | 2425–2427 | "The rule 'every `Float64` position follows the scalar' reads the declaration as written, so a concretely typed field is frozen without appearing in the contract." | plain | D-265 Rationale log 10425–10428 | R |
| 95 | 2428–2429 | "`handle_walk_walkthrough.md` works a static terrain and a moving deck through one consumer." | plain | — | pointer |
| 96 | 2431–2434 | "The companion obligation is **constructibility at `T`**. … The `Dual` probe enforces it by construction." | bold words | D-079 Position log 2301–2303 | U |
| 97 | 2436–2442 | "During a generic sweep, gated-off discrete producers hold their `Float64` values … A frozen discrete output is a constant with zero partials … The frozen cell is not an AD limitation on the signal path." | plain | D-079 Rationale log 2309–2311; D-073 Rejected log 2124–2126 | R |
| 98 | 2442–2443 | "What makes the mixing safe is the **embedding guarantee** (§9.5), keyed on **walking leaves** (D-033)." | bold words | the cited D-033 does not state it; D-238 Position (log 8788–8791) does | U by D-238; wrong entry cited (F4) |
| 99 | 2445–2449 | "**Why.** A `Float64` observed at a walking leaf under a non-nominal activation implies no `Dual` entered its computation" | **Why.** label | D-079 Rationale log 2313–2316 | reason |
| 100 | 2451–2455 | "Piecewise branches returning literal constants … are legal as written … Which *invocation* carries partials is still chosen by seeding (§14.10), never by typing." | plain | D-194 Position bullet 4 log 6874–6875 (branches); D-079 Rationale log 2316 (seeding) | B: U by D-194; R by D-079 |
| 101 | 2457–2460 | "**The misplaced-pin account, stated openly.** A leaf that really participates cannot be declared frozen by habit, because the habitual spelling, a bare `Float64`, walks." | bold lead-in | D-263 Rationale log 10229–10236 | R |
| 102 | 2462–2469 | "The first bug **lurks, but is never silent**. … The message carries the didactic hint ('if `F` participates in differentiation, remove its `Pinned`') … The second fails … at the identity comparison on an opaque leaf" | bold words | D-286 Position bullet 2 (the hint); D-263 Rationale log 10229–10236 | U; the hint is quoted verbatim in D-286 |
| 103 | 2471–2474 | "Both lurks are contained by policy rather than machinery. **The test suite builds a `Dual` activation of every component**, which is the exhaustive set §9.4 defines." | bold words | D-280 Position | U |
| 104 | 2474–2476 | "What the plain form buys in exchange is **one convention**." | bold words | D-263 Rationale log 10213–10216, 10224–10227 | R |
| 105 | 2478–2484 | "**The stores are walked by the same rule, with no marker.** … `m_init` and `s_init` pin wholesale … `Pinned` has no place in a store … Declared `Float64` initial values embed as zero-partial constants" | bold lead-in | D-263 Position bullet 1 (the `x_init` walk); D-079 Rationale log 2307–2311; "no place": D-166 Rejected log 5807–5808 (superseded) | B: U by D-263; R by D-079 |
| 106 | 2486–2489 | "Walking `x_init` presupposes the closed leaf vocabulary §7.1 fixes … On the discrete tier, the stores answer to the isbits rule of §7.3, checked field by field. The structure step checks both vocabularies (§9.1)" | plain | D-094 Position; D-231 Position | U |
| 107 | 2490–2499 | the four quoted messages | quoted messages | `src/diagnostics.jl` 844–870 | description; one wording differs from `src/` (F18) |

#### `state_events(::C)`, stage tags, custom structs (2501–2540)

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 108 | 2503–2509 | "`state_events` declares an ordered, named collection of guard/handler pairs, spelled `StateEvent(guard, handler)` with no detection keyword. Detection policy is declared by the guard's return type instead." | plain | D-179 Position; D-220 Position bullet 4 | U (D-179 cited nowhere in the chapter) |
| 109 | 2509–2511 | "Order is semantics. It is the declaration order used by §5.3 and the priority order, with re-decision, used by §10.6. Nothing here is inferrable." | plain | D-033 Position ("`events(::C)` ordered") | U |
| 110 | 2515–2517 | "Which stage produces which port stays invisible in the contract, preserving §4.2. Moving a port between stages is non-breaking for consumers." | plain | D-033 Position ("no stage tags"); Rejected log 1047 | U |
| 111 | 2517–2522 | "Membership is *derived* instead, with no chicken-and-egg. … The 'decoder takes no inputs' property is exactly what makes the derivation well-founded." | plain | D-033 Position ("stage membership derived (inputless `h_x` probes first, remainder is stage 2)") | U |
| 112 | 2522–2525 | "A leaf's declarations do carry its tier (D-195, D-220), and that is a different fact." | plain | D-263 Position (the store); D-195 bullet 3; D-220 Rationale | C |
| 113 | 2529–2532 | "A custom struct is a first-class port type … under the scoping §7.2 establishes. That scoping requires a struct parametric in its real-scalar leaves, with constructors inferring the scalar and no pinned fields on the continuous path." | plain | D-079 Position; §7.2 1617–1625 | N; "no pinned fields" conflicts with 2422–2425 and D-265 Position (F5) |
| 114 | 2532–2537 | "A participating struct leaf is declared with `Float64` in its parameter position … A struct with a hardcoded `Float64` field offers no such position … a pinned leaf by shape, and `Pinned{GearContact}` says so on the page." | plain | D-263 Position bullet 3; D-238 Position | U |
| 115 | 2537–2539 | "Any `Dual`-carrying construction then detonates inside the stage with an `InexactError` … That is the §7.2 CI invariant" | plain | §7.2 consumer 4 (1596–1598) | description |

#### Completeness of the declaration set (2541–2611)

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 116 | 2543–2544 | "Four rules the build checks in the structure step (§9.1), stated here because they are properties of the declarations, not of the wiring." | plain | — | roadmap; the count changes under M1 (part C) |
| 117 | 2546–2549 | "**A non-empty store needs its update.** `x_init` with fields and no `x_deriv` method, or `s_init` with fields and no `s_update` method, is a build error." | bold lead-in | D-263 Position bullet 5 (the non-empty scope); the base rule has no entry (D-117 Rationale names `StoreWithoutUpdate` in passing) | B: U by D-263 for the scope; N for the rule |
| 118 | 2549–2553 | "The framework will not silently supply `ẋ = 0`, which is a model, not a default. An unupdated discrete store is a parameter in disguise" | plain | none | reason |
| 119 | 2554–2555 | "`m_init` carries no such obligation. Modes are written by handlers" | plain | none | N |
| 120 | 2557–2561 | "**An event needs both halves.** A `state_events` entry whose guard or handler has no method … is a build error, caught by method lookup at declaration-reading time" | bold lead-in | D-215 Position bullet 3 names `EventHalfMissing`'s reason only | N |
| 121 | 2563–2566 | "**Tier is declared by the store.** Every leaf declares `x_init` or `s_init`, the two are disjoint … (D-195, D-263). A stateful leaf announces it in the update law as well" | bold lead-in | D-263 Position bullet 5; D-195 | C |
| 122 | 2567–2568 | "The two output stages are one pair of names shared by both tiers, so they announce nothing and cast no vote (D-220)." | plain | D-220 Position bullet 2 | C |
| 123 | 2568–2572 | "The remaining tier-implying declarations must agree. `m_init`, `state_events` and `x_projection` are continuous-only" | plain | D-112 Position (events); D-249 Position bullet 1 log 9274–9276 | U |
| 124 | 2572–2575 | "A `Pinned` entry in a contract is continuous-only … No arity carries a tier. Every declaration takes the component alone, and `ws_init` takes the scalar on both tiers (D-263)." | plain | D-263 Position | C |
| 125 | 2575–2581 | "Disagreement is `DeclarationOnWrongTier` … It covers declaring both `x_deriv` and `s_update`, a `Pinned` entry on a discrete leaf, and the mixed-store cases" | plain | D-112 Rationale log 3326–3328 (kind, payload); D-195 bullet 3; D-263 bullet 1; D-249 annotation log 9312–9314 | U |
| 126 | 2583–2590 | "A **stateless** leaf is a leaf whose store is empty … A primitive declaring neither store is `TierUnreadable` … refused as `StatelessWithoutOutputs`" | bold word | D-263 Position bullets 5–6 | C (adjacent, 2575); repeats 2169–2175 |
| 127 | 2590–2592 | "The stage bundles follow the tier … with no `x` or `s` field, because the bundle law puts a store's letter in the bundle only when the store is non-empty (§5.2)." | plain | D-263 Rationale log 10242–10244 | R |
| 128 | 2593–2595 | "§13.7 records why … Members of both families, or of neither, are the §8.5 class errors." | plain | — | pointer |
| 129 | 2597–2602 | "**Any component may be the root of a build, and the model's root inputs are the root's own input faces** (D-208). For an assembly those are the faces declared through `u_connections` … For a primitive they are its `u_types` keys directly" | bold sentence | D-208 Position | C |
| 130 | 2602–2604 | "The type derivation is one rule across both cases, the tight bound at the ultimate consuming entry, above." | plain | D-208 Position bullet 2 | C (adjacent) |
| 131 | 2604–2605 | "At the root the two contract declarations share one face namespace, so a key declared in both is a build error (§8.6)." | plain | D-210 Position bullet 1 | U; repeats §8.6 2922–2929 |
| 132 | 2607–2611 | "Abstract-at-root is what the uniform doctrine does not relax. … The component test rig (§13.7) is the idiom for that case." | plain | D-208 Position bullet 3; D-120 Position | U; repeats 2325–2327 |

Descriptions that read like rules: row 113 restates §7.2's scoping in words
§7.2 does not use ("no pinned fields on the continuous path"); row 115 is
§7.2's CI invariant; rows 118 and 119 have no entry and read as the inherited
FlightCore completeness checks, which the log never recorded as rulings. Row
117's base rule is the same: D-263 rules its scope, nothing rules the rule.

The stores block (2159–2231) states its organizing criterion last (2216–2230)
and calls it "stated once here, and the blocks below refer back to it". It
uses the walk, `Pinned` and the by-type convention before `u_types` and
`y_types` introduce them. Part C moves nothing for it; the rewriter glosses.

Display-block candidates: the two stateless forms, `x_init(::Gain) = (;)` and
`s_init(::Sampler) = (;)` (2170–2171); the refused bare leaf,
`x_init(::C) = 0.0` (2164); the root-input fan-out pair
`SVector{3, Float64}` / `Pinned{SVector{3, Float64}}` (2343) as a two-line
contrast. The table (2248–2252) and the `DeckField` block stay as written.

### §8.3 Visibility: the contract is the interface (2612–2667, 470 words)

Purpose: what is public (everything declared in `y_types`, and nothing else),
why intermediates are declared ports, and the conformance rules that keep the
table exactly the declared set.

Subheadings: none. Label: **Rule.** 2614. Four bold lead-in bullets (2636,
2651, 2654, 2662).

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 133 | 2614–2619 | "**Rule.** Visibility is decided by *where the value goes*: a field declared in `y_types` is public; a field returned in `y` … and declared nowhere is a build error; a component with no `y_types()` method has no outputs." | **Rule.** label | D-034 Position | U (D-034 first cited 2647); the third bullet needs §8.2's stateless exception (F23) |
| 134 | 2621–2624 | "Ports in the contract are connectable, GUI-listed, snapshot-carried and log-exported. The table is public throughout … nothing anywhere needs a presentation filter." | plain | D-194 Position bullet 6; D-034 Position's "presentation-filtered" intermediates are the retired shape | U |
| 135 | 2625–2626 | "Visibility is binary, with no third class between the two. A value a later function reads travels as a declared port like any other (§5.2)." | plain | D-194 Position, bullet 6 | U |
| 136 | 2628–2630 | "The inspection path for an intermediate is therefore **declaration**. One line in `y_types` makes it public, checked and visible everywhere at once (D-194)." | bold word | D-194 Position | C |
| 137 | 2630–2631 | "FlightCore is the precedent, where an intermediate was inspected by putting it in the `Model` output and no other way." | plain | D-194 Rationale log 6893–6896 | reason |
| 138 | 2631–2634 | "Publicity is never implicit. Even the minimal component writes `y_types(::LowPassFilter) = (x = Float64,)`" | plain | D-034 Rejected log 1070; D-041 Rejected log 1240 | R |
| 139 | 2636–2639 | "**Conformance.** A declared port must be produced by exactly one stage, stage 1 or stage 2 (D-252). … Stage membership is derived over `y_types` alone (§9.1)." | bold lead-in | D-252 Position; D-033 Position (membership) | C |
| 140 | 2640–2643 | "Declared-but-unproduced and produced-by-two-stages are build errors. A declared port no stage produces is `DeclaredNotProduced` … the remedy is returning the name from `y_state`" | plain | D-252 Position and Rationale log 9467–9469 | C (adjacent) |
| 141 | 2643–2647 | "A *returned port field* declared nowhere is a build error at probe, with did-you-mean … That is the return-side analogue of §8.4 walkthrough 1 (D-034, D-055)." | plain | D-034 Position; D-239 Position (`UndeclaredReturnField`); D-055 is half-superseded (part E) | C |
| 142 | 2647–2650 | "The forgotten-branch walkthrough holds. … Missing from an *untaken* branch, it fails loudly at that branch's first execution via the always-on check." | plain | D-032 Position ("free always-on conformance") | U |
| 143 | 2651–2653 | "**Branch-shape rule.** Stage returns must have the same `NamedTuple` shape on every branch." | bold lead-in | D-034 Position ("branch-shape-stable returns") | U |
| 144 | 2654–2661 | "**Schema authority is total over the table** … return typos cannot silently define new cells. … Probe-observed expected types remain rejected (D-034, D-055, D-194)." | bold lead-in | D-055 Position ("schema authority total"); D-034, D-055, D-194 Rejected | B: C by D-055, half-superseded; R for the rejection |
| 145 | 2662–2666 | "**What this rules out** (D-016, D-034, D-055, D-194). The `unlisted` flag (§4.2) …; identity publication by default …; **probe-observed private cells**; the `Private(T)` fallback; and the opt-in variant with a `Float64`-under-`Dual` diagnostic." | bold lead-in | D-016 Rejected log 591–595; D-034 Rejected; D-055 Rejected log 1582–1585; D-194 Rejected | R; adversarial (part G q4) |

Descriptions that read like rules: row 134's list of what a public port is
(connectable, GUI-listed, snapshot-carried, log-exported) is a description of
the periphery's reach, with no entry. Row 137 is lineage.

The third bullet of row 133 and §8.2 2587–2590 meet at a stateless leaf: "a
component with no `y_types()` method has no outputs" holds for a stateful
leaf, while a stateless one without `y_types` is refused
(`StatelessWithoutOutputs`). The bullet also spells `y_types()` with empty
parentheses, a call shape no declaration has.

Display-block candidates: none. `y_types(::LowPassFilter) = (x = Float64,)`
can stay inline.

### §8.4 Failure walkthroughs (the error-locality grounding) (2668–2693, 241 words)

Purpose: the five authoring mistakes that decided declaration over inference,
each with its failure site under this layer.

Subheadings: none. A numbered list with bold lead-ins.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 146 | 2670–2673 | "The five mistakes that decided declaration-vs-inference … in every case the failure surfaced inside *correct* code, later, or never. D-032 carries the traces." | plain | D-032 Rejected log 989–1001 | R |
| 147 | 2675–2676 | "**Typo'd wire** (`:throtle`). A build error at the connection, 'no input `throtle`; did you mean `throttle`?'" | bold lead-in | D-113 Position bullet 1 (`UnknownPort`) | U |
| 148 | 2677–2678 | "**Forgotten wire** (`fuel_available`, read only by a guard). The §6.1 unconnected-input error at build." | bold lead-in | D-043 Rejected log 1272–1273 | R |
| 149 | 2679–2680 | "**Forgotten branch field** … A probe or first-execution error naming the declared port." | bold lead-in | D-032 Position; D-034 Position | U |
| 150 | 2681–2682 | "**Type mismatch** (a `Float64` fraction wired into a `Bool` input). A wiring-time error naming both endpoints and both faces." | bold lead-in | D-078 Position; D-236 Position | U |
| 151 | 2683–2693 | "**Typo'd return field** … That one error is the whole report. The probe chain stops at the port check (§13.1, D-239) … An intermediate a later function reads is declared like any other output and typo'd like any other output (§8.3)." | bold lead-in | D-239 Position; D-252; D-194 | C |

Item 5's tail (2688–2693) restates §8.3's conformance bullet and 2625–2626
(part B, item 6). Item numbers are cited from outside ("§8.4 w1", "w2", "w4",
"w5" in Appendix C 11709–11839; "walkthrough 1", "walkthrough 2",
"walkthrough 5" in the log), so the list order and numbering must survive.

Display-block candidates: none.

### §8.5 Assembly declaration: type-based, class by declaration shape (2694–2879, 1,387 words)

Purpose: what an assembly is (a plain struct whose component-typed fields are
children), container children and name-transparency, the builder rejection
and `Group`, class read off declaration shape, and the arity rule seen from
the class side.

Subheadings (`####`): "Container children" (2708, 586 words), "The builder is
rejected" (2777, 40), "`Group`: the on-the-fly assembly" (2785, 322), "Class
by declaration shape" (2835, 221), "One arity on both tiers" (2867, 126). The
opening is 92 words. Labels: **Rule.** 2696, 2710, 2730; **Why.** 2840.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 152 | 2696–2698 | "**Rule.** An assembly is a plain struct. Fields whose type is `<: AbstractComponent` are its children, and all other fields are inert parameters." | **Rule.** label | D-039 Position | U (D-039 first cited 2779) |
| 153 | 2700–2701 | "Field names are path segments. Substitutability and variants use ordinary parametric fields, exactly today's `Cessna172X{K, A}` shape." | plain | D-040 Position (paths); none for "variants" | B: U by D-040; N for the second sentence, a Flight.jl status quo in the present tense (F15) |
| 154 | 2701–2706 | "`inner_connections(::A)`, mandatory even when empty, plus `u_connections(::A)`, `y_connections(::A)` and `sample_times(::A)`. One more is optional, `transparent_container(::A)`, default `nothing`." | plain | D-039 Position (marker); D-170, D-279 (names); D-211 Position | U |
| 155 | 2710–2711 | "**Rule.** A field whose type is a `Tuple` or `NamedTuple` with *every* element `<: AbstractComponent` contributes its elements as container children." | **Rule.** label | D-085 Position | U (D-085 cited nowhere in the chapter) |
| 156 | 2713–2720 | "They are path-named `\"field/1\"…\"field/N\"` (tuples) or `\"field/key\"` … Containers are **transparent grouping, not assemblies**. … Anything wanting its own wiring or faces declares itself an assembly." | bold words | D-085 Position; Rationale log 2484; Rejected log 2501–2502 | U |
| 157 | 2722–2728 | "The payoff is parametric composition. `struct Formation{NT <: NamedTuple}; aircraft::NT; … end` … The swarm worlds (§14.9) consume it directly, and so does mounting" | plain | D-085 Rationale log 2484–2488 | R (example) |
| 158 | 2730–2735 | "**Rule.** A component may declare at most one of its container fields **name-transparent**, by `transparent_container(::MyType) = :field` … (D-211)" | **Rule.** label | D-211 Position | C |
| 159 | 2737–2740 | "Naming is the only thing the declaration changes." | plain | D-211 Position | C (adjacent) |
| 160 | 2744–2747 | "A container mixing component and non-component elements is a build error in this section's did-you-mean family … zero-component elements are inert parameter data." | plain | D-085 Rationale log 2488–2489 | R |
| 161 | 2748–2750 | "Containers of containers are rejected in the first cut … (`ContainerNested`)." | plain | D-085 Rationale log 2489 | R |
| 162 | 2751–2752 | "Empty containers are legal and contribute zero children" | plain | D-085 Rationale log 2490 | R |
| 163 | 2753–2756 | "Abstract element types follow the same concreteness discipline as plain fields. … That is the generic holding … that §8.8 allows." | plain | D-043 Position ("generic holding = imposed contract checked per instantiation") | B: U by D-043; N for the concreteness discipline |
| 164 | 2757–2758 | "A bare key from a name-transparent container colliding with any sibling child name is a build error naming both." | plain | D-211 Position | C (adjacent) |
| 165 | 2758–2765 | "A bare key equal to the name of a sibling *container field* that contributes children is refused the same way. … The judgment is therefore per-instantiation, like every wiring judgment (D-212)." | plain | D-212 Position | C |
| 166 | 2765–2767 | "`transparent_container` must name a container field of the type, and declaring two transparent containers on one type is a declaration error." | plain | D-211 Position ("at most one"); D-215 Position bullet 1 (`TransparentContainerUnknown`) | U |
| 167 | 2769–2773 | "`sample_times` needs no rule change. Element names are immediate child names, hence legal keys, and the bare field name is sugar … `(children = Relative(2),)` is the uniform spelling for a `Group`." | plain | D-085 Rationale log 2490–2491; D-211 Position (rate keys go bare); no entry gives `Group` a rate declaration (F6) | B: R by D-085; N for the `Group` spelling |
| 168 | 2773–2775 | "The one ambiguity this leaves, a transparent element's bare key equal to its own field's name, joins the bare-key collision error above." | plain | D-215 Position bullet 1 (`ChildNameCollision`, "a bare container key against the `sample_times` sugar") | U |
| 169 | 2779 | "The builder (`Assembly()` plus `add!`/`connect!`) is rejected (D-039)." | plain | D-039 Rejected log 1197–1199 | R |
| 170 | 2781–2783 | "Its one real advantage, programmatic generation, survives intact in the type-based form. A declaration is an ordinary function body" | plain | D-039 Rejected; D-184 Rationale | R; spec 7224 cites §8.5 for "the idiom" of ordinary declaration bodies |
| 171 | 2787–2792 | "The *immutable* version of 'grouping components by plain calls' needs no builder. … name-transparent so they go by bare key (D-211), and declarations are ordinary functions of the *instance*" | plain | D-184 Position; D-211 Position | C (D-211); U by D-184 |
| 172 | 2794–2813 | the `Group` block | code | D-184 Position; `src/assembly.jl` 287–312 has a fifth field `rates` and `sample_times(g::Group) = g.rates` (F6) | code |
| 173 | 2815–2819 | "One type, defined once, and every ad-hoc topology is a *value* of it. … Wiring validation, did-you-mean errors and the two-producer check all run at build against the instance" | plain | D-184 Position; Rationale log 6519–6521 | U |
| 174 | 2821–2824 | "What is given up relative to a named type is exactly what named types are *for* … The exploratory and programmatic composition `Group` serves does not want it anyway." | plain | D-184 Rationale log 6521–6522 | R |
| 175 | 2826–2830 | "The reach of the builder rejection is fixed by D-184. It targets mutable recipes, not type-based *semantics*. … riding one opt-in declaration, `transparent_container` (D-211)." | plain | D-184 Rationale log 6523–6525; D-211 Position ("amending … D-184's zero-new-declaration-rules framing") | C |
| 176 | 2831–2833 | "What that declaration buys is that a `Group`'s wiring and rate declarations read exactly like a named assembly's, child and face, with no `children/` boilerplate." | plain | D-211 Rationale log 7555–7557 | R |
| 177 | 2837–2838 | "**There is no `AbstractAssembly`, only one root `AbstractComponent`** (D-039)." | bold sentence | D-039 Position | C |
| 178 | 2840–2843 | "**Why.** The domain hierarchies (`AbstractAircraft`, the engine families) have to carry both classes." | **Why.** label | D-039 Rejected log 1200–1201; D-178 Rationale | reason |
| 179 | 2845–2851 | "Class … is declared instead by *which* well-known declarations a type defines. `inner_connections` is the marker, mandatory even when empty (the `LowPassFilter` precedent) … Any leaf declaration makes a **primitive**" | bold words | D-039 Position; D-170 Position (the marker role transfers) | C (adjacent, 2838); "the `LowPassFilter` precedent" has no referent for the marker (F13) |
| 180 | 2853–2857 | "The rule is total. A `<: AbstractComponent` type declaring neither family has no class to read. It is a build error naming both families" | plain | D-039 Position | C (adjacent) |
| 181 | 2857–2861 | "`inner_connections` plus any leaf declaration on one type is a build error as well. Assemblies have no state of their own … They have no contract of their own either. An assembly's faces are derived from its children (§8.6)." | plain | D-039 Position (by totality); D-041 Position (faces derived) | U |
| 182 | 2863–2865 | "Reading which declarations exist is reading declarations. It is the same move as visibility-by-declaration-site (§8.3), not the banned inference-by-evaluation (§8.1)." | plain | D-039 Rejected log 1202 | reason |
| 183 | 2869–2873 | "Class fixes *which* declarations a type may define, and nothing about their shape. Every declaration takes the component alone, on a leaf of either tier and on an assembly alike … (§7.3, D-263)." | plain | D-263 Position (contract declarations); assemblies: no entry | C; scope (F22) |
| 184 | 2873–2879 | "A signature therefore never spells the tier. … There is consequently no signature-shape violation to name. A declaration on the wrong tier is `DeclarationOnWrongTier` … `Pinned` on a discrete leaf, is the same kind." | plain | D-263 Position; D-249 annotation log 9312–9314 | C (adjacent) |

Descriptions that read like rules: row 153's "exactly today's
`Cessna172X{K, A}` shape" is Flight.jl's status quo stated as Cadence's;
row 163's "same concreteness discipline as plain fields" names a discipline
no entry and no other section states under that name (§13.3's
generic-holding rule is the nearest).

The section names few of its diagnostic kinds. It names `ContainerNested`
alone, while Appendix C cites §8.5 for `ClassUnreadable`, `ClassMixed`,
`ContainerMixed`, `ChildNameCollision`, `TransparentContainerUnknown`,
`TierUnreadable` and `StatelessWithoutOutputs` (11759–11807). The first five
match content §8.5 holds; the last two do not (part D).

"One arity on both tiers" (2867–2879) restates §8.2 2216–2230 and 2572–2581
almost clause for clause (part B, item 1).

Display-block candidates: `transparent_container(::MyType) = :field` (2731);
`struct Formation{NT <: NamedTuple}; aircraft::NT; … end` (2722–2723), as a
three-line block. The `Group` block stays verbatim pending part G q1.

### §8.6 Paths, wiring and faces (2880–3178, 2,456 words)

Purpose: the path form; the three wiring declarations and their invariants;
face names and the two-notation rule; root inputs; then a worked mixed-tier
assembly, the strapdown IMU, with its leaves, its exactness argument and the
boundary-sampling contract.

Subheadings (`####`): "The IMU's leaves: integrate-and-difference" (3020, 301
words), "Exactness condition, stated once" (3058, 600, of which the
`IMUIntegrals`/`IMUSampler` block and the assembly prose 3078–3132 are about
half), "Why `u.V` is fresh: the line that would silently zero" (3134, 154),
"Sampling at `t_k` is a taught contract" (3152, 223). The unheaded part
(2880–3019, 1,178 words) carries eight bold lead-ins (2882, 2899, 2903, 2910,
2914, 2922, 2961, 2972). No labels.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 185 | 2882–2885 | "**Paths are slash-separated strings**, relative to the assembly or model root they are read from, with no leading slash. There is one canonical form, shared verbatim by declarations, error messages, device/trace addressing (§11.3) and the HDF5 log tree." | bold words | D-040 Position | C (adjacent, 2889) |
| 186 | 2885–2889 | "Container children (§8.5) add index and key segments … A container declared name-transparent (§8.5) adds no segment of its own" | plain | D-085 Position; D-211 Position | U |
| 187 | 2889–2890 | "Instance navigation, tuples of symbols and dotted paths were all rejected (D-040). A path-tracking proxy remains addable sugar." | plain | D-040 Rejected log 1215–1220 | R; adversarial (part G q4) |
| 188 | 2890–2892 | "The three wiring declarations use only the short case of that form, one child segment and one face name (§6.1)." | plain | D-207 Position | U |
| 189 | 2892–2894 | "The read side walks the full depth … That read side is the inspection side and `resolve` as the inspection primitive (§13.3)." | plain | D-207 Position bullet 3; D-242 Position bullet 3 | U; the second sentence has no verb and misstates `resolve` (F8) |
| 190 | 2894–2897 | "One fact from that adjudication is relied on downstream. Symmetric immutable siblings are `===`-identical, so a path is unrecoverable from an instance." | plain | D-040 Rejected log 1216–1217 | R |
| 191 | 2899–2902 | "**`inner_connections(::A)`** is an ordered collection of `\"src/face\" => \"dst/face\"` pairs, strictly from a child face to a child face. The rules (§6.1) apply: one wire per input, and every endpoint an immediate child and one of its faces" | bold term | D-170 Position; D-207 Position; D-279 (name) | U |
| 192 | 2902–2907 | "The assembly's **boundary** is declared by two further methods, one per direction. **`u_connections(::A)`** is an ordered collection of pairs, face name => internal endpoint path, or a tuple of paths" | bold words | D-170 Position | U |
| 193 | 2907–2909 | "Every entry routes to **at least one** internal endpoint. An empty tuple is a declaration error, because a face feeding nothing declares nothing (D-210)." | bold words | D-210 Position bullet 2 | C |
| 194 | 2910–2912 | "**`y_connections(::A)`** runs the other way, internal source path => face name … so that its pairs … read along the flow." | bold term | D-170 Position | U |
| 195 | 2914–2918 | "**Face names are arbitrary strings with two build-checked invariants.** The first is that a face name contains no `/` … The second is uniqueness across the union of the two boundary declarations' face names." | bold sentence | D-046 Position; D-170 Position (uniqueness spans both) | U |
| 196 | 2918–2920 | "Every other naming choice … is author convention, not framework law. The `input_passthrough` helper's defaults (§8.8) document the house style" | plain | D-046 Position ("dot-prefix *defaults* (convention, not law)") | U |
| 197 | 2922–2926 | "**At the root the uniqueness invariant follows the root's class** (D-210). A primitive root declares no boundary methods, so its face set is the union of its `u_types` and `y_types` keys" | bold sentence | D-210 Position bullet 1 | C |
| 198 | 2926–2929 | "A root input places a cell the periphery writes … Below the root nothing collides … Non-root leaves are left alone." | plain | D-210 Position ("Non-root primitives are untouched"); Rejected log 7515–7518 (the reason) | C (adjacent) |
| 199 | 2931–2935 | "The two-notation rule this rests on is directional. … **Slash is structure** … **Face names are opaque derived-contract tokens.**" | bold words | D-129 Position; D-046 Position | U (D-129 cited nowhere in the chapter) |
| 200 | 2935–2938 | "The periphery's write side … speaks face names exclusively (§11.3). The read side speaks them wherever it wants meaning that outlives the build" | plain | D-129 Position | U |
| 201 | 2938–2939 | "The three declarations return pairs of strings rather than NamedTuples (D-046)." | plain | D-046 Position | C |
| 202 | 2941–2944 | "One invariant spans all three declarations. Every pair's arrow points the way the signal flows … **Direction is therefore declared by the method**, not inferred." | bold words | D-170 Position | U |
| 203 | 2944–2949 | "The resolved endpoints only *cross-check* it … A mixed entry is not expressible … Two entries producing the same output face remain the ordinary two-producers error." | plain | D-170 Position | U |
| 204 | 2949–2955 | "Face *types and tiers* are derived from the internal endpoints … The derivation is forced, not merely convenient (D-041). An assembly is tier-neutral" | plain | D-041 Position | C |
| 205 | 2955–2959 | "Three alternative spellings are rejected (D-041, D-170) … Publicity is never implicit (§8.3)." | plain | D-041 Rejected log 1234–1240; D-170 Rejected | R; adversarial (part G q4) |
| 206 | 2961–2967 | "**Root inputs fall out with no vocabulary.** … At the root there is no parent, and the root component's input faces *are* the write surface … nothing downstream distinguishes the two." | bold lead-in | D-208 Position; D-043 Position ("root slots = the root's exported input faces") | U |
| 207 | 2967–2970 | "The whole-tree obligation model (§6.1) states the complementary error rule. An assembly never declares its external connections." | plain | none | N; description |
| 208 | 2972–2974 | "**A worked assembly.** The strapdown IMU of §3.4, spelled in full." | bold lead-in | D-056 | pointer |
| 209 | 2975–2999 | the `IMU` block | code | D-056 Position | code |
| 210 | 3001–3009 | "Two spellings are worth reading closely. `input_passthrough` enumerates the child's **input** faces and nothing else (§8.8) …" | bold word | D-171; D-170 Position | mechanism; uses §8.8's helper before §8.8 defines it |
| 211 | 3011–3018 | "Three facts the example carries. … And the latch-back wire (below) … joins `inner_connections` as one more ordinary pair." | plain | D-041, D-042, D-185 Positions | mechanism; the third "fact" is a variant the example does not carry (F11) |
| 212 | 3022–3026 | "Algebra can eliminate the reset, with no approximation. Every interval-relative integral becomes a *cumulative* one. The sampler differences against the previous sample, held in its `s`." | plain | D-056 Position bullet 1 | U (D-056 cited nowhere in the chapter) |
| 213 | 3028–3056 | the raw-increment, coning and sculling bullets, with the display formula at 3045–3048 | math | D-056 Position bullet 2 | mechanism; reader-cold `q_c_cc` and "the direct formulation" at 3056 (F16) |
| 214 | 3060–3064 | "Interval-relative integrals factor into cumulative ones whenever the interval dependence enters through a *left action by the interval-start value of a cumulatively-integrable quantity*." | italic | D-056 Position bullet 2 | U |
| 215 | 3064–3071 | "Two provisos apply. First, the cumulative attitude must be integrated with the **inertial** rate … Second, the equivalence survives discretization." | bold word | D-056 Position bullet 2 ("inertial-rate anchoring required; RK-exact by linearity of the kinematics") | U |
| 216 | 3071–3076 | "Never resetting has numerical consequences. … After an hour of flight that loss is of order $10^{-11}\ \mathrm{m/s}$ per sample" | plain | none | N; a measurement against Flight.jl's direct formulation (F16) |
| 217 | 3078–3118 | the `IMUIntegrals`/`IMUSampler` block | code | — | code; F9 and F10 sit in its comments |
| 218 | 3120–3125 | "The `IMU` assembly wires the four integral ports across … The parent sets the IMU's rate (§8.7). `Δt` in the stage bundle … is the §10.5 single source of truth" | plain | D-187, D-254 (via §10.5) | mechanism |
| 219 | 3126–3132 | "Initialization consistency also holds. … boundary zero discharges the rest. … That dependence is a condition-authoring obligation under trim (§14.5)." | plain | D-067 Position bullet 1 | U |
| 220 | 3136–3150 | "The sculling line is correct only because a due tick samples the *completed* boundary. … The guarantee is the §10.6 macro-sequence, not a scheduling accident." | plain | D-067; chapter 10's D-154 | mechanism |
| 221 | 3154–3159 | "The clean implementation leans on the author *knowing* that 'sampling at `t_k`' means post-integration, post-projection, stage-1-fresh state. That knowledge must be part of the framework's taught contract … (Appendix A)" | plain | D-056 Position bullet 5 | U |
| 222 | 3159–3162 | "The failure mode of not knowing it is instructive." | plain | — | reason |
| 223 | 3164–3177 | "**When the coupling is genuinely two-way, the latch becomes a wire back.** … The feedthrough stage is the right one because `y_direct` reads `u` … An `y_state`-published latch would be one period stale." | bold sentence | D-056 Position bullet 3 | U |

Descriptions that read like rules: row 207's "An assembly never declares its
external connections" (no entry; it restates §6.1's obligation model); row
216, a measurement with no entry. The "HDF5 log tree" (2885) names a storage
format the chapter does not otherwise introduce.

The heading "Exactness condition, stated once" covers the condition (3060–3076)
and then the leaves' code and the assembly prose (3078–3132), which are not
about exactness. The worked assembly (2972) has no heading of its own (part
C). The three `####` headings after it are claims, not topic labels.

Display-block candidates: the fan-out entry
`"trn" => ("left/trn_field", "right/trn_field", …)` (2907); the display formula
(3045–3048) stays as written.

### §8.7 Rate scopes (3179–3201, 224 words)

Purpose: the `sample_times` declaration on an assembly: its spelling, which
children it may key, its default, and why it belongs to the type.

Subheadings: none. One paragraph. No labels.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 224 | 3181–3183 | "The declaration is `sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))`, mapping each child name to a `Relative` or `Absolute` entry. These are the two forms of §10.5." | plain | D-185 Position | U (D-185 cited nowhere in the chapter) |
| 225 | 3183–3185 | "Relative entries compose affinely down the tree, absolute entries anchor, and all are compiled to one `(D, Φ)` pair per discrete component." | plain | D-185 Rationale log 6555–6558; D-186 Position (anchors) | B: R by D-185; U by D-186 |
| 226 | 3185–3186 | "The wrappers are the whole value vocabulary, so a bare integer or bare quantity is a declaration error." | plain | D-185 Position | U |
| 227 | 3186–3188 | "The declaration is optional, and so is any given key. An unlisted discrete child defaults to `Relative(1)`" | plain | D-042 Position (optional); D-185 Position (default) | U |
| 228 | 3189–3190 | "Keys are **immediate child names only**. A deep key would edit another type's design from outside, and the composition rule guarantees you never need to." | bold words | D-042 Position; Rejected log 1257 | U |
| 229 | 3191–3192 | "Container elements (§8.5) are immediate children, so `\"aircraft/red\"` is a legal key, and the bare field name applies one declaration to every element." | plain | D-085 Rationale log 2490–2491 | R; repeats §8.5 2769–2771 |
| 230 | 3193–3194 | "A `sample_times` key on a continuous child is a build error (the Δt-on-continuous error at declaration time, §10.5)." | plain | D-042 Position ("`K` on a continuous child = error") | U; §10.5 names no such error (5509–5510 calls the run-side case a missing field) |
| 231 | 3194–3196 | "`Δt_base`, `h` and `N_base` appear in no declaration. They are deployment decisions fixed at deployment (the three sources for `Δt_base`, §9.2)." | plain | D-254 Position bullet 1; D-256 Position bullet 1; D-186 Rationale (the three sources); D-042 Position still says "at `Simulation` construction" | U |
| 232 | 3196–3200 | "The declaration belongs to the assembly type, not to the child instance, because a sample time is a design ratio or a modeled instrument's intrinsic rate (§10.5) … The FlightCore-`Subsampled`-style instance wrapper is rejected in D-042." | plain | D-042 Rejected log 1255–1256 | R |

Rows 224–227 repeat §10.5's "The two declaration forms" (5329–5360), which
chapter 10's survey made the home for the forms (part B, other chapters;
part G q3). Row 228 and rows 230–232 are §8.7's own.

Display-block candidates: the `sample_times(::A)` spelling at 3181.

### §8.8 Computed connections and generic holding (3202–3390, 1,372 words)

Purpose: computing boundary entries from child contracts with the two
passthrough helpers, their selectors and errors; the single-authored feed
list; the line between authored and inferred structure; generic holding as an
imposed contract.

Subheadings: none. Labels: **Rule.** 3264, 3271; **Why.** 3277; **Why
`select` exists.** 3283. Bold lead-ins at 3293, 3297, 3320, 3373, 3379.

| # | line | quote | marking | entry | class |
|---|---|---|---|---|---|
| 233 | 3204–3207 | "`u_connections` and `y_connections` are ordinary functions evaluated at build against the concrete instance, so they may *compute* entries from child contracts. That is derivation from declarations, which §8.2 blesses." | plain | D-043 Position | U (D-043 cited only at 3375) |
| 234 | 3209–3246 | the `input_passthrough` sketch with `World` | code | D-251 Position; matches `src/assembly.jl` 572–640 in signature and check order | code |
| 235 | 3248–3249 | "The child is named by path and never passed as an instance, because the `===` problem (§8.6) makes a path unrecoverable from an instance." | plain | D-040 Rejected log 1216–1217 | R |
| 236 | 3249–3251 | "A face name containing dots is a legal final path segment on the internal-endpoint side, precisely because slash is the only structural separator." | plain | D-046 Position | U |
| 237 | 3251–3255 | "Computed entries mix freely with hand-written ones in either declaration. `resolve` and `input_faces` are build-pipeline primitives needed anyway" | plain | D-043 Position | U |
| 238 | 3255–3256 | "There is no `rename` hook, because the boundary declarations are ordinary code (map over the pairs)." | plain | D-046 Rejected log 1377 | R |
| 239 | 3256–3257 | "Normative signatures for both primitives are in §13.3." | plain | — | pointer |
| 240 | 3257–3262 | "Every error stays first-class. An `except` face the assembly then fails to wire is an ordinary unconnected input. A face both wired and passed through is a two-producers error. … A `prefix = \"\"` collision is caught by the build's uniqueness check" | plain | D-145 Position (two producers); D-113 Position bullet 5; D-251 Position; D-046 Position | U |
| 241 | 3264–3269 | "**Rule.** The selectors are exclusive. A call takes `except`, `only` or `select`, one of the three and no more (D-251). … `UnknownFaceSelection` with reason `:multiple_selectors`" | **Rule.** label | D-251 Position bullet 1 | C |
| 242 | 3271–3275 | "**Rule.** A call that gives a selector and keeps nothing raises `EmptyFaceSelection`, a warning on the `Build`'s list (§9.2, D-251). A bare call over a faceless child is silent … The payload names the helper, the child path, the selector given with its names, and the child's face list." | **Rule.** label | D-251 Position bullet 2 | C; the payload sentence has no entry |
| 243 | 3277–3281 | "**Why.** An empty selection is almost always a typo the unknown-names check cannot see." | **Why.** label | D-251 Rationale | reason |
| 244 | 3283–3285 | "**Why `select` exists.** At C172X scale the feed list below already computes the `except` tuple." | label | D-251 Rationale | reason; "C172X" reader-cold (F15) |
| 245 | 3287–3291 | "The effective face list is plain printable data … What computation does *not* do is auto-bubble." | plain | D-043 Rejected log 1272–1273 | R |
| 246 | 3293–3296 | "**The name carries the direction, so the helpers come in pairs.** `input_passthrough` reads `input_faces(child)`" | bold sentence | D-171 Position and Rationale | U |
| 247 | 3297–3300 | "**`output_passthrough` is its sibling** (D-209). It is splatted into `y_connections` … the same three exclusive selectors" | bold words | D-209 Position; D-251 Position | C |
| 248 | 3302–3307 | the `output_passthrough` example | code | — | code |
| 249 | 3309–3311 | "Its consumer is one-level routing (§6.1). Every level re-exports the outputs it surfaces" | plain | D-209 Rationale log 7475–7478 | R |
| 250 | 3311–3312 | "Both helpers take `child_path` naming an **immediate** child, container key segments included." | bold word | D-207 Position | U |
| 251 | 3312–3315 | "The default `prefix` folds the path's slash into `sep` … An explicit `prefix` is used verbatim." | plain | none; `src/assembly.jl` 556–559 docstring | N |
| 252 | 3315–3316 | "A deeper path meets `resolve`'s one-level rejection like any other wiring endpoint (§13.3)." | plain | D-207 Position | U |
| 253 | 3316–3318 | "There are two helpers rather than one keyword, because after the boundary split a single call cannot emit entries into two different declarations." | plain | D-171 Rationale log 6024–6030 | R |
| 254 | 3320–3329 | "**One authored list, two declarations.** … That is 'structure kept in two artifacts' (§8.1; D-039), the shape this design refuses elsewhere. … the author writes the feed list *once*" | bold lead-in | D-145 Position | U (D-145 cited only at 3376); the quoted phrase is not in §8.1 (F7) |
| 255 | 3331–3357 | the `ACT_FEEDS` block | code | D-145 Position; D-251 bullet 4 (a test transcribes it) | code |
| 256 | 3359–3371 | "Adding an actuator channel is then one edit. … One asymmetry is stated openly. A pair *omitted* from the list is not an error but a structural change." | plain | D-145 Rationale log 4879–4890 | R |
| 257 | 3373–3377 | "**The line not to cross** is deriving `except` from `inner_connections` itself … (D-043, D-145). The single source must be **authored data, never inferred structure**." | bold lead-in, bold words | D-145 Rejected log 4896–4904 | R |
| 258 | 3379–3384 | "**Generic holding is an imposed derived contract.** … the error names the `World` entry. That is build-time structural typing with no new vocabulary (a formal required-faces declaration on domain abstract types remains possible sugar)." | bold lead-in | D-043 Position; D-251 Position bullet 3 (required faces) | U |
| 259 | 3384–3387 | "Scalar faces make partial scripting compose. … impossible with a bundled face (§4.3 write-side rule)." | plain | D-207 Rejected log 7430–7432 | R |

Descriptions that read like rules: row 251 (the default prefix) is the
helper's behavior as built, recorded in no entry; row 242's payload sentence
likewise.

Display-block candidates: the anti-example `except = fed(sys, "aero")`
(3374) could be a two-line block beside the idiom it forbids. The four code
blocks stay verbatim.

### Tally

| section | rules | C | U | S | R | N | B |
|---|---|---|---|---|---|---|---|
| §8.1 | 29 | 12 | 5 | 1 | 6 | 1 | 4 |
| §8.2 | 76 | 20 | 28 | 1 | 12 | 3 | 12 |
| §8.3 | 12 | 4 | 5 | 0 | 2 | 0 | 1 |
| §8.4 | 6 | 1 | 3 | 0 | 2 | 0 | 0 |
| §8.5 | 30 | 11 | 8 | 0 | 8 | 0 | 3 |
| §8.6 | 30 | 6 | 19 | 0 | 3 | 2 | 0 |
| §8.7 | 9 | 0 | 6 | 0 | 2 | 0 | 1 |
| §8.8 | 21 | 3 | 9 | 0 | 8 | 1 | 0 |
| total | 213 | 57 | 83 | 2 | 43 | 7 | 21 |

The count leaves out the 46 rows that are reasons, mechanisms, examples,
descriptions, pointers, roadmaps, code or tables (3, 8, 11, 16, 17, 23, 34,
35, 38, 39, 45, 46, 48, 50, 51, 60, 69, 79, 90, 91, 95, 99, 107, 115, 116,
118, 128, 137, 172, 178, 182, 208, 209, 210, 211, 213, 217, 218, 220, 222,
234, 239, 243, 244, 248, 255), and classes each row by its first code.

Against chapter 10 (C 35, U 58, S 0, R 35, N 12, B 14 of 154): chapter 8 is
better cited at its spots (57 C of 213) but has more uncited rulings (83 U):
whole entries that rule large blocks are cited nowhere in the chapter (D-056,
D-085, D-129, D-179, D-185, D-280, D-286) or only once far from the rules
they hold (D-043, D-145, D-263 in `u_types`). One rule in five lives only in a
Rationale, Rejected list or annotation (43), about as in chapter 10. Two
superseded entries are cited four times (D-166 once, D-167 three times), and
three rulings live only in superseded D-167.

Bold weight now: 123 bold spans outside code blocks, of which 24 are labels
(13 **Rule.**, 10 **Why.**, one **Why `select` exists.**); the other 99 carry
442 words. Most are bold terms (FFI door, root-input type, face bounds,
participates) and lead-ins acting as headings (about 35), neither of which
the convention allows.

## B. Overlaps

### Inside the chapter

1. **The tier, the store and the arity rule.** §8.2 2169–2176 (the store is
   the tier marker; `TierUnreadable`), 2216–2230 (every declaration but the
   allocator takes the component alone), 2563–2595 (tier declared by the
   store; agreement; the stateless leaf, `TierUnreadable` again at 2587), and
   §8.5 2867–2879 ("One arity on both tiers"). "Takes the component alone" is
   stated five times (2216, 2234–2235, 2363–2364, 2574–2575, 2870–2872);
   "`Pinned` on a discrete leaf is `DeclarationOnWrongTier`" four times
   (2241–2242, 2572–2573, 2578, 2877–2879). Home: §8.2's stores block for the
   rule, its completeness block for agreement. §8.5 keeps its own sentence
   (class fixes which declarations, not their shape; assemblies take the
   component alone too) and points back (part C, M5; part G q5).
2. **Root inputs.** §8.2 2320–2358 (the root-input type, fan-out, the meet),
   2597–2611 (any component may be root; abstract-at-root again), §8.6
   2922–2929 (uniqueness at the root) and 2961–2970 (root inputs fall out).
   2604–2605 repeats 2922–2929, 2607–2611 repeats 2325–2327, and 2597–2602
   repeats 2961–2967 from the declaration side. Home: §8.2 for the types,
   gathered in one block (M1); §8.6 for the faces and the write surface.
3. **The declares-nothing refusal.** §8.1 2016–2021 ("A component that
   declares nothing and defines no stage is rejected at build time") and §8.5
   2853–2857 (a type declaring neither family "has no class to read") are the
   same check, `ClassUnreadable` (`src/build.jl` 135–136; `src/diagnostics.jl`
   513, 524). §8.1 1971 names `ClassUnreadable` only for the whole-inventory
   shadow. Home: §8.5 for the rule; §8.1 keeps the local-scope trap and points
   (F12).
4. **Container keys and the rate sugar.** §8.5 2769–2775 and §8.7 3191–3192
   both say container elements are legal `sample_times` keys and the bare
   field name applies one entry to every element. Path segments for
   containers appear at §8.5 2713–2714 and §8.6 2885–2889 (and §6.1
   1238–1241). Home: §8.7 for keys (M3); §8.5 for the naming; §8.6 points.
5. **The `===` problem.** §8.6 2894–2897 states it; §8.8 3248–3249 points
   back. No change needed.
6. **Visibility and the return-side errors.** §8.3 2636–2650 (conformance,
   `DeclaredNotProduced`, the forgotten branch), §8.4 items 3 and 5
   (2679–2680, 2683–2693), §8.1 2027–2030 (the partial shadow reads as
   declared-but-unproduced). §8.4 item 5's tail (2688–2693) restates §8.3
   2625–2626 and 2640–2643. Home: §8.3. §8.4's items stay whole and numbered,
   because Appendix C and the log cite them by number.
7. **The builder rejection.** §8.5 2777–2783 (its own `####`, 40 words) and
   2826–2830 (D-184 fixes its reach). One place serves (M4).
8. **The macro door.** §8.1 1934–1944 and 1996–1997. Both stay: the second
   applies the first to the import list in one sentence.
9. **Class markers listed twice.** §8.5 2702–2706 (the assembly
   declarations) and 2845–2851 (both families), with the full roster at §8.1
   1958–1961. Distinct jobs; no change.
10. **Stage membership derived.** §8.2 2515–2522 (how) and §8.3 2638–2639
    (over `y_types` alone). Both stay; §8.3 points.
11. **The embedding guarantee and frozen discrete outputs.** §8.2 2349–2354
    (the meet's direction), 2436–2449 (mixing is exact), 2483 (state
    defaults embed), §8.3 2658–2660. Each applies one guarantee (§9.5) to a
    different case; each keeps one sentence and the pointer.
12. **The passthrough helper before its section.** §8.6 2918–2920 and
    3001–3009 use `input_passthrough`, which §8.8 defines. The uses are
    self-explaining with a pointer; no move.
13. **"Publicity is never implicit."** §8.3 2631–2632 and §8.6 2959. Both
    stay; §8.6's is the pointer.
14. **The did-you-mean gloss.** 2276–2278 (§8.2), 2644–2645 (§8.3),
    2684–2685 (§8.4), 2745–2746 (§8.5). One gloss per section is the
    convention; §8.4's and §8.3's sit 40 lines apart and could share one if
    the rewriter judges §8.4 a continuation of §8.3. No ruling needed.

### Other chapters

| content | chapter 8 | elsewhere | home |
|---|---|---|---|
| the two wire clauses, their tier scope, the opaque-leaf admission, `WalkingFaceAtFrozenEntry` | §8.2 2280–2300 | §6.1 1275–1326, near-verbatim ("a correctness rule, not tidiness" at 1313, "a correctness rule rather than tidiness" at 2293–2294), with the kinds, both remedies, D-236 and D-264 | open: §6.1 says "Two clauses type-check a wire (§8.2)" (1277) and points back, so neither is the declared home (part G q2) |
| the failure asymmetry of input and output pins | §8.2 2457–2476 (output side) | §6.1 1320–1325 (both sides, "It lurks loudly, never silently (§8.2)") | §8.2 for the output lurk; §6.1 for the asymmetry |
| one-level path reach | §8.6 2890–2892; §8.8 3311–3316 | §6.1 1231–1273 (D-207) | §6.1 |
| unconnected inputs, the whole-tree obligation model | §8.6 2967–2970; §8.4 item 2 | §6.1 1338–1350 | §6.1 |
| one wire per input across levels, two producers | §8.6 2948–2949, 3008–3009; §8.8 3259 | §6.1 1327–1336 | §6.1 |
| the state-leaf vocabulary and the store isbits rule | §8.2 2486–2499 | §7.1; §7.3 1658ff | §7.1 and §7.3 for the vocabularies; §8.2 for the check and its messages |
| the workspace by allocation, its scalar on both tiers | §8.1 2105–2109; §8.2 2191–2198, 2226–2229 | §7.3 1686ff, **Rule.** at 1715 | §7.3 for the workspace; §8.2 for its place in the inventory |
| the walk and per-leaf participation | §8.2 2362–2400 | §7.2 1606–1614 (points to §8.2) | §8.2 |
| frozen discrete outputs are exact | §8.2 2436–2442 | §7.2 1602–1605; §14.10 10700, 10901, 10966–10971 | §7.2 (with `frozen_discrete_walkthrough.md`); §8.2 one sentence |
| the bundle law, no letter for an empty store | §8.2 2176, 2590–2592 | §5.2 721ff | §5.2 |
| the stage names and their dependence classes | §8.1 2037–2044 | §5.3 832–860 (D-220's table) | §5.3 for the names; §8.1 for the four classes |
| tier agreement of a stateful leaf | §8.2 2563–2581 | §5.3 858–862 (points to §8.2) | §8.2 |
| stage membership invisible to consumers | §8.2 2513–2525 | §4.2 472–489 | §4.2 for the principle; §8.2 for the derivation |
| exposing state by returning it from `y_state` | §8.2 2132 (comment), 2187–2188 (stale, F3) | §5.3 | §5.3 |
| integrate-and-dump and the IMU | §8.6 2972–3177 | §3.4 363–435 ("The hardest case: integrate-and-dump", 392); spec 416 says "§8.6 spells that idiom" | §3.4 for the problem; §8.6 for the worked spelling |
| sampling at `t_k` as a taught contract | §8.6 3152–3162 | Appendix A 11117–11125; spec 10138 ("sibling to the boundary-sampling line (§8.6)") | Appendix A indexes; §8.6 holds the worked case |
| the `sample_times` forms, wrappers, default, composition | §8.7 3181–3188 | §10.5 5329–5389 | §10.5 (chapter 10's survey, part B) |
| `Δt` as a single source | §8.6 3123–3125 | §10.5 5503–5510 | §10.5 |
| `Group` | §8.5 2785–2833 | §13.7 9516 ("its declaration-layer treatment lives in §8.5") | §8.5 |
| `resolve` and the face-list accessors | §8.8 3209–3256 | §13.3 8985–9030 | §13.3 for the signatures and the client table |
| abstract-at-root and the component test rig | §8.2 2325–2327, 2607–2611 | §13.7 9609–9616 | §13.7 for the rig |
| the write surface is the root's input faces | §8.6 2961–2967 | §11.3 6309–6323 | §11.3 |
| the shadowing check's place in the structure step | §8.1 1978–1994 | §9.1 3459 | §8.1 (§9.1 points) |
| completeness checks run in the structure step | §8.2 2541–2595 | §9.1 3466–3500 | §8.2 (§9.1 lists) |
| seedability and the meet's cost | §8.2 2330–2334, 2356–2358 | §14.10 10900–10914 | §14.10 for taps; §8.2 for the meet |
| the `Freeze` block and the local derivative rule for AD-opaque code | absent from §8.2 (F20) | §6.1 1304–1306; §13.7 9506–9508, 9574–9581; §14.10 11041–11059 (D-266) | §13.7 and §14.10; §8.2 owes one pointer at the FFI door |
| the five walkthroughs as acceptance tests | §8.4 | §9.1 3399; §13 8739, 8818, 8889; glossary 13041–13042 | §8.4 |

## C. Proposed structure

No section is renumbered. A renumbering inside the chapter would cost far
more than it buys: 450 rows of `inbound.tsv` point at chapter 8, §8.2 137 of
them, §8.6 66, §8.5 65, §8.1 49, §8.8 47, §8.3 37, §8.4 29, §8.7 14, §8 6. No
file links a `####` anchor of chapter 8 (checked with `rg` over `docs/`), so
retitling subheadings is free, and several claim-headings should become topic
labels (`spec_style.md`, "Subheadings only for entry points"). The `###`
titles stay; §8.1's "Position:" prefix and §8.4's parenthetical are
retitle candidates the rewrite does not need.

### Moves

| move | content | from | to | needs a ruling |
|---|---|---|---|---|
| M1 | "Any component may be the root of a build" and abstract-at-root | §8.2 2597–2611 (166 words) | §8.2, a new "Root inputs" block after 2358, with 2607–2611 merged into 2325–2327; 2543's "Four rules" becomes "Three rules" | no |
| M2 | "Custom structs as port types" | §8.2 2527–2540 (130 words) | §8.2 `y_types`, after the handle rule (2402–2429) and before constructibility at `T` (2431), which it leads into | no |
| M3 | the rate-key sugar for containers | §8.5 2769–2773 (about 50 words, to "for a `Group`.") | §8.7, merged with 3191–3192; 2773–2775 (the own-field-name ambiguity) joins §8.5's bare-key collision bullet (2757–2767) | no |
| M4 | "The builder is rejected" | §8.5 2777–2783 (40 words, its own `####`) | the `Group` block, beside 2826–2830 where D-184 fixes the rejection's reach | no |
| M5 | "One arity on both tiers" | §8.5 2867–2879 (126 words) | trimmed to its class-side sentence and the assembly clause, with a pointer to §8.2 2216–2230 and 2563–2581 | yes, part G q5 |
| M6 | the forms, composition, wrappers and default of `sample_times` | §8.7 3181–3188 (94 words) | one sentence and a pointer to §10.5 5329–5360; §8.7 keeps the spelling, the key rules, the deployment sentence and the type-not-instance rule | yes, part G q3 |
| M7 | the two wire clauses | §8.2 2280–2300 (207 words) | per part G q2; nothing moves without that ruling | yes |
| M8 | adversarial passages | 1997–1999, 2200–2203, 2274–2278, 2313–2318, 2662–2666, 2889–2890, 2955–2959 | per part G q4 | yes |

M2 and M3 cross unit boundaries (see "Rewrite units"); each moved block
belongs to its destination unit, so every move stays inside one unit. M1
crosses from B4 into B2.

### Order within each section

Define-before-use was checked for each order below against the terms each
block uses.

- **Chapter intro.** Keep the context paragraph. Add one roadmap sentence
  naming the eight sections by subject.
- **§8.1.** The opening names five subjects, not four (F17). Proposed order:
  "Plain Julia, not a macro DSL"; "Declarations are the schema authority";
  "Contracts are functions of the type"; "The namespace"; "Names". The three
  D-032 rulings (trait layer, schema authority, macros) then sit together
  and the two naming subjects (D-117, D-246, D-164, D-144) follow. Checked:
  the schema block needs only *probe* (glossary) and a forward pointer to
  §8.4; the contracts block glosses *bundle*, *executor* and *chunking*
  already; the namespace block names `StoreWithoutUpdate` and
  `ClassUnreadable`, which need a gloss or a pointer in any order. Today's
  order also passes define-before-use, so this is part G q6.
- **§8.2.** Opening (`Engine`, roadmap). Then `####` labels: "The stores"
  (2159–2215), with the criterion paragraph (2216–2230, 182 words) moved to
  open the section after the `Engine` block, as the section's organizing
  context (by value, by type, by allocation), since 2217–2218 calls it the
  rule "the blocks below refer back to"; "Input contracts: `u_types`"
  (2232–2318); "Root inputs" (2320–2358 with M1); "Output contracts:
  `y_types`" (2360–2499 with M2); "Events: `state_events`"; "Stage
  membership" (today's "No stage tags anywhere"); "Completeness" (three
  rules). Checked: the moved criterion paragraph uses the walk (glossary
  `#g-leaf-walk`), `Pinned` and the by-type convention before the contract
  blocks; each takes a five-to-ten-word gloss, as today's paragraph needs
  anyway. The `u_types` block uses "walking producer leaf" and "pinned
  producer leaf" before `y_types` defines participation; 2285–2286 glosses
  both in place, which suffices. The root-input block uses faces and
  `u_connections` (§8.6), already pointed.
- **§8.3.** Unchanged. A context sentence first (what "visibility" decides),
  then the rule, then the four bullets, which may become paragraphs.
- **§8.4.** Unchanged, numbering kept (cited as "w1"–"w5").
- **§8.5.** Opening rule and declarations; "Class by declaration shape"
  (2835–2866) moved up, then "One arity on both tiers" (M5); then "Container
  children" (2708–2776, less M3); then "`Group`" (2785–2833, with M4).
  Checked: class needs only the leaf family (§8.2) and the marker (opening);
  containers need *did-you-mean* (glossed in place) and generic holding
  (§8.8, pointed); `Group` needs the container rule and
  `transparent_container`, both before it. Today's order puts the
  containers before the rule that says what an assembly is; the reorder is
  part G q6.
- **§8.6.** Paths (2882–2897); the three declarations (2899–2912); the
  direction invariant (2941–2959, moved up: it concerns all three
  declarations); face names and the two-notation rule (2914–2920,
  2931–2939); root inputs (2961–2970, moved before 2922–2929, since
  uniqueness at the root presupposes them); uniqueness at the root
  (2922–2929). Then `####` labels for the worked case: "A worked assembly:
  the strapdown IMU" (2972–3018, new); "The leaves: integrate-and-difference"
  (3020–3056); "The exactness condition" (3058–3076); "The leaves in code"
  (3078–3132, today under the exactness heading); "Freshness at the sample"
  (3134–3150); "The boundary-sampling contract" (3152–3177). Checked: the
  two-notation paragraph says "The two-notation rule this rests on", so it
  follows face names; the direction invariant uses the two-producers error
  (§6.1, pointed) and nothing from face names. The IMU's
  `input_passthrough` stays a forward pointer to §8.8.
- **§8.7.** The spelling and a pointer to §10.5 for the forms (M6); keys
  (immediate children, container elements and the field-name sugar with
  M3); the continuous-child error; the deployment sentence; type, not
  instance. Optional at 224 words: no subheadings.
- **§8.8.** Unchanged order. Three `####` labels would serve a returning
  reader: "The passthrough helpers" (3204–3318), "One authored feed list"
  (3320–3377), "Generic holding" (3379–3387).

### Rewrite units

| unit | lines (original) | moves in | moves out | words |
|---|---|---|---|---|
| A | 1901–2109: heading, intro, §8.1 | — | — | 1,670 |
| B1 | 2110–2231: §8.2 opening, `Engine`, the stores | — | — | 1,015 |
| B2 | 2232–2359: §8.2 `u_types`, the wire clauses, root inputs | M1 (2597–2611) | — | 1,371 |
| B3 | 2360–2500: §8.2 `y_types`, the stores' walk, the vocabulary | M2 (2527–2540) | — | 1,429 |
| B4 | 2501–2693: §8.2 events, stage membership, completeness; §8.3; §8.4 | — | M1, M2 | 1,468 |
| D | 2694–2879: §8.5 | — | M3 | about 1,337 |
| E1 | 2880–3019: §8.6 paths, wiring, faces, root inputs, the IMU assembly | — | — | 1,178 |
| E2 | 3020–3178: §8.6 the IMU's leaves, exactness, freshness, the sampling contract | — | — | 1,278 |
| F | 3179–3390: §8.7, §8.8 | M3 (2769–2773) | — | about 1,646 |

Total 12,392 words. Every unit falls between 1,000 and 1,700. B1 is the
smallest; it could take §8.2's `u_types` opening (2232–2279, 420 words) from
B2 to reach 1,435 and leave B2 at 951, but the permissive reading belongs
with the wire clauses that apply it, so the cut stays at 2232. B4 joins
§8.2's tail with §8.3 and §8.4 because the three share one subject, the
declared set's completeness and its failure sites (`DeclaredNotProduced`,
`UndeclaredReturnField`, the walkthroughs); the only cross-reference out of
B4 is the root-input block M1 removes. E1 and E2 split §8.6 where the worked
assembly ends and its leaves begin; E2 refers back to E1 only through
"(below)" at 3016–3017. F joins §8.7 and §8.8, two assembly-side
declarations of 224 and 1,372 words.

If part G q5 or q6 is ruled against, no unit changes. If q3 is ruled against,
F loses nothing. If q2 trims §8.2's wire clauses to a pointer, B2 falls to
about 1,200.

### Code blocks

The chapter carries ten `julia` blocks (1957–1962, 2008–2014, 2114–2154,
2407–2413, 2794–2813, 2975–2999, 3078–3118, 3209–3246, 3302–3307,
3331–3357), one table (2248–2252), one display formula (3045–3048), and inline
math at 3028–3043, 3052, 3054 and 3075.

- **Carry every block verbatim**, each as one claim. `checks/norm.py` folds a
  ```` ```julia ```` block into one code span, so a one-character edit makes
  the whole block differ. Comment edits inside a block are ruled edits only:
  F9 and F10 (part E) are two, and part G q7 rules them.
- **The `Group` block (2794–2813)** waits on part G q1 (F6); carry it
  verbatim until ruled.
- **Inline math stays as written**: `$…$` passes `norm.py` as text and the
  verifier compares it literally.
- **New display blocks** are the candidates in part A (the stateless forms,
  `transparent_container(::MyType) = :field`, `Formation`, the fan-out
  entry, the `sample_times` spelling, the `fed` anti-example). Each is an
  addition the inventory declares.

## D. Inbound citations

The full list is `inbound.tsv` (beside this file): 450 rows, one per "§8" or
"§8.N" occurrence outside chapter 8 (1901–3390) and outside the Contents
block, plus every `#8N-…` anchor; for `decisions.md` rows the `entry` and
`field` columns are filled. The script is `scratch_survey/inbound.py`. Link
definitions are excluded.

By file: `spec.md` 191, `decisions.md` 226 (Spec 132, Rationale 37, Position
29, Rejected 26, Annotation 1, Divergence 1), `implementation.md` 12,
`extensions.md` 4, `handle_walk_walkthrough.md` 4, `migration_outline.md` 3,
`flight_case_studies.md` 2, `linearization_walkthrough.md` 2, `pending.md` 2,
and one each in `event_visibility_walkthrough.md`,
`frozen_discrete_walkthrough.md`, `inbound_periphery_walkthrough.md` and
`sample_time_proposal.md`. By target: §8 6, §8.1 49, §8.2 137, §8.3 37, §8.4
29, §8.5 65, §8.6 66, §8.7 14, §8.8 47. Ranges count their ends only:
`implementation.md` 94 and 303 ("§8.5–§8.8", "§8.5–§8.7") and spec 11240
("§8.5–§8.7") also cover the sections between.

### Citations relying on moved content

M1 and M2 move content inside §8.2, so no row retargets. Rows that rely on
the moved text: spec 3494, 9609 and 9616 (any component may be root; stays
§8.2); spec 3948, 12083 and Appendix C 11733 (the tight bound,
`AbstractAtRoot`; stay §8.2); `handle_walk_walkthrough.md` 4 and 19 (the
handle shape rule; stays §8.2). spec 3496–3502 (§9.1) lists five
completeness checks, none of them the root rule, so "Three rules" after M1
agrees with §9.1 better than today's "Four".

M3, the rate-key sugar (§8.5 → §8.7):

| file:line | fact relied on | after |
|---|---|---|
| spec 11796 (Appendix C, `ChildNameCollision`) | "a bare container key against the `sample_times` sugar" (§8.5) | stays §8.5: the collision bullet keeps 2773–2775 |
| `src/assembly.jl` 113–116 (docstring) | "the bare field name applying one entry to every element of a container (§8.7)" | §8.7, which M3 makes true in one place |

No other row relies on 2769–2773. D-211's Spec field (log 7541) gains §8.7;
D-085's (log 2482) already lacks §8.5 and would gain §8.5 and §8.7 (part E).

M4, the builder rejection, stays in §8.5: spec 7224 ("`claims` bodies are
ordinary code (the idiom, §8.5; comprehensions included)") relies on
2781–2783, and log 6528 (D-184 Rejected, "§8.5's standing rejection") on
2779. Both keep their target.

M5, "One arity on both tiers" trimmed:

| file:line | fact relied on | after |
|---|---|---|
| spec 11769 (Appendix C, `DeclarationOnWrongTier`) | the kind (§5.2, §8.2, §8.5) | §8.2 holds it; the trimmed §8.5 paragraph should keep the kind's name so the §8.5 cite stays true |
| spec 12525 (glossary, *tier*) | tier "read off the store every leaf declares" (§8.2, §8.5) | keep 2873–2874's clause in §8.5, or the §8.5 cite goes vague |
| log 10195, 10245 (D-263) | "as `child_connections` is the class marker (§8.5)" | unaffected; the class block stays |

M6, the `sample_times` forms trimmed from §8.7:

| file:line | fact relied on | after |
|---|---|---|
| spec 12188 (glossary, *sample time*) | "All are compiled to one `(D, Φ)` pair per discrete component (§8.7, §10.5)" | §10.5 holds it; §8.7 must keep the compile clause or the §8.7 cite goes vague |
| log 6981 (D-195 Rejected) | "`D` is already the compiled sample-rate divisor (§8.7, Appendix D)" | same: keep the `(D, Φ)` clause in §8.7 |
| spec 11791 (Appendix C, `RatesViolation`) | `K` on a continuous child (§10.5, §8.7) | stays: §8.7 keeps the continuous-child error |
| log 6119 (D-173 Rejected) | "§8.7's rates-on-continuous error" | stays |

So M6 keeps the one sentence "Relative entries compose affinely down the
tree, absolute entries anchor, and all are compiled to one `(D, Φ)` pair per
discrete component" and trims the vocabulary and default sentences to the
pointer.

M7, the wire clauses (only if part G q2 trims §8.2): spec 1277 (§6.1, "Two
clauses type-check a wire (§8.2)"), 1325, 3466 (§9.1), 11719 and 11722
(Appendix C), `handle_walk_walkthrough.md` 4 ("§8.2 (the `Pinned` marker
…)", §6.1 "the two wire clauses"). §6.1 1277 would then point at a pointer
back to §6.1, the circle lesson 16 forbids.

M8, the adversarial passages: no inbound row relies on 1997–1999, 2200–2203,
2274–2278, 2313–2318 or 2955–2959. Two rows rely on nearby reasons that must
survive: spec 7158 ("§8.5 refuses a class supertype for two reasons") needs
both reasons of 2840–2843 (the domain hierarchies; class behind the
contract), and spec 9000 relies on 2914–2916 (no `/` in a face name), which
stays. log 1571 (D-055 Position) "adds §8.4 walkthrough 5" and log 8835
(D-239) rely on §8.4 item 5, which stays.

The §8.1 and §8.5 reorders and the §8.6 reorder move content within their
sections; no row names a subheading.

### Citations that already rely on content chapter 8 does not hold

The inbound check will flag these whatever the rewrite does; they belong to
track 2 or to the other chapter's rewrite.

| file:line | claim | what chapter 8 says |
|---|---|---|
| spec 7134 (§11.6); log 6273 (D-177 Rationale) | "That is the reflection class (§8.1), where the shadowing check is an `isdefined`/`!==` pair" | §8.1 has the `isdefined`/`!==` test (1985) but names no "reflection class"; no version of §8.1 since `8e2505c` did |
| log 6378 (D-179 Rejected); log 6469 (D-182 Rejected) | "§8.1's no-macros/no-introspection foundations"; "the introspection §8.1 forbids" | §8.1 forbids macros, not introspection; the word appears nowhere in the chapter |
| spec 3326 (§8.8, inside the chapter); log 4877 (D-145 Rationale) | "'structure kept in two artifacts' (§8.1; D-039)" | §8.1 has no such phrase; 1930 accepts redundancy under fail-loud (F7) |
| log 1198 (D-039 Rejected) | "§8.1's disease at assembly scale" | §8.1 names no disease; the drift argument is D-039's own |
| spec 11803, 11807 (Appendix C) | `TierUnreadable` and `StatelessWithoutOutputs` cite §8.5 | §8.5 holds neither; both are §8.2 (2173–2174, 2583–2590) |
| spec 11993 (Appendix C) | `ArgumentInvalid` cites §8.7 for "build in a `sample_times` declaration" and "a period constructor" | §8.7 holds no argument check; the float-argument error is §10.5 5349–5350 |
| spec 12614 (glossary, *nominal*) | "the one where the conformance check demands exact type match (§8.2, §9.4, §9.5)" | §8.2 never states the nominal exact match; D-286 gives the exact check to pinned leaves, and §9.5 holds the rest |
| spec 7163 (§11.6) | "a component's class is implementation detail behind its contract (§8.3)" | §8.3 does not say it; §8.5 2842–2843 does, citing §8.3 |
| log 9273, 9290 (D-249) | "`TierSignatureMismatch` owns all three signature violations §8.5 names" | §8.5 names none since D-263; D-249 carries the annotation (log 9312–9314) |
| `extensions.md` 286 | "Cell types … are declarations *evaluated at the activation scalar* (§7.2, §8.2)" | §8.2 retypes plain declarations by the walk (D-263); "evaluated at" is D-166's vocabulary |
| spec 3892, 4167 (§9.3, §9.5) | quote §8.1: "Fails loudly at build time where possible"; "at first execution otherwise" | 1931–1932 holds both phrases; the rewrite must keep them word for word |

Rows that record history and stay true as history: log 6056 (D-172, "§8.2
'a primitive root has no faces' → no root slots"), log 7446–7447 (D-208,
"§8.2's primitive-root refusal is retired"), log 5812 (D-166 Rejected).

### Log entries whose Spec field would change

- Under M3: D-211 gains §8.7; D-085 gains §8.5 and §8.7 (it lacks §8.5
  today, part E).
- Under M5 and M6: none, if the trims keep the clauses part D names above.
- Under M1, M2, M4 and the reorders: none.
- Under part G q2 (b): none in the log; spec 1277 changes, which is chapter
  6's.

The recipe updates the Spec fields a move changes at landing (step 7). The
stale Spec fields part E lists are track 2 either way.

## E. Log repairs and factual problems

Log repairs go to the second track, after landing (recipe step 8). The
rewrite only adds citations; it states no repair. Factual problems stay as
written and go to the units' `rulings.md`, unless part G pre-rules them.

### Entries to cite at the rule

From part A's U rows, by entry: D-032 (1, 5, 142, 149), D-033 (40, 109–111),
D-034 (133, 143), D-039 (152, 154, 181), D-040 (153), D-041 (181), D-042
(228, 230), D-043 (163, 206, 233, 237, 258), D-046 (195, 196, 236), D-054
(70, 71), D-056 (212, 214, 215, 221, 223), D-067 (219), D-073 (40), D-078
(65, 150), D-079 (85, 96), D-085 (155, 156, 186), D-094 (106), D-112 (123),
D-113 (147), D-117 (9, 10, 14), D-120 (74, 132), D-129 (199, 200), D-145
(240, 254), D-170 (191, 192, 194, 202, 203), D-171 (246), D-179 (108), D-184
(171, 173), D-185 (224, 226, 227), D-186 (225), D-194 (100, 134, 135), D-207
(188, 189, 250, 252), D-208 (132, 206), D-210 (131), D-211 (154, 186), D-215
(166, 168), D-226 (13), D-231 (106), D-236 (65, 67, 74, 75), D-238 (98, 114),
D-249 (123, 125), D-251 (258), D-254 and D-256 (231), D-263 (47, 53, 56, 58, 61, 66, 67,
76, 81, 84, 85, 87–89, 92, 105, 114, 117), D-266 (62), D-280 (103), D-286
(86, 102).

Cited nowhere in the chapter today, though each rules a block of it: D-056
(the IMU idiom), D-085 (container children), D-094 (the state-leaf
vocabulary), D-129 (the two-notation rule), D-179 (detection policy by return
type), D-185 (the `sample_times` forms), D-215 (four of the chapter's kinds),
D-231 (store isbits), D-238 (embed-accept), D-280 (the CI `Dual` policy),
D-286 (the pinned leaf's exact check and hint).

### Superseded and half-superseded citations

- 1941 cites D-166 (superseded → D-263) for the macro door. D-032's Position
  states it ("convenience macros addable a posteriori, never essential"); cite
  D-032. The sentence after it is stale (F2).
- 2244, 2300 and 2314 cite D-167 (superseded → D-263). At 2244 the live
  statement is D-263 Position bullet 2 ("The permissive reading of
  `input_types` (D-167) stands with the marker as its spelling"). At 2300
  ("The unscoped variant is rejected in D-167") no live entry states the
  rejection; D-167's annotation (log 5874–5877) says the tier scope stands.
  At 2314 D-167 sits in a list of four and can drop out.
- Half-superseded entries the chapter cites, none annotated:
  - D-055 (cited 2647, 2660, 2662). Its Position is the `local_types`
    mechanism, deleted by D-165 (log 5672, "`local_types` is deleted with its
    satellites") and not restored by D-194, which keeps D-034/D-055 "closed"
    only as rejections (log 6879). For "schema authority total" (2654) and
    the return-side error (2643), D-034 Position and D-239 Position serve.
  - D-034 (cited 2647, 2660, 2662). Its Position's "intermediates declared
    via strict `local_types` … presentation-filtered" (log 1054–1055) is the
    retired shape; "declared = public; absent `output_types()` = no outputs;
    branch-shape-stable returns; undeclared stage-return fields = build
    error" stand.
  - D-033 (cited 2274, 2314, 2443). Its Position's per-event `localize` flag
    (log 1016–1017) was removed by D-179; `local_types` by D-165/D-194.
  - D-041 (cited 2952, 2956). D-170 Rationale (log 5999) "Supersedes D-041's
    single-method shape"; the type and tier derivation the chapter cites it
    for stands.
  - D-042 (cited 3200). Its Position's "`Δt_base`/`h` fixed only at
    `Simulation` construction" (log 1247–1248) is stale since D-254 and
    D-256 moved both to the `Deployment`; the chapter (3194–3196) already
    says "deployment".
- D-016 (cited 2662) is annotated "superseded in part" (log 586–588); its
  Rejected list, which the chapter cites, is history and stands.

### Rulings that need an entry stating them in a Position

1. Contracts are functions of the type; a rule authors keep; `ws_init`
   exempt (rows 33, 36, 37): D-033 Rationale log 1023–1028.
2. The semantic axis of the naming convention (row 28): D-146 Rationale log
   4941–4945 only, and the spec states it inverted (F1).
3. The signature criterion and "partials enter through seeding" (rows 53,
   55): D-263 Rationale log 10207–10212; D-079 Rationale log 2316.
4. Abstract entries as structural substitutability; "declarations record
   choices, obligations are checked"; the tight bound at the root (rows 63,
   72, 74): D-078 Rationale log 2273–2279.
5. **The tier scope of the walk-compatibility clause, the genericity
   obligation's scope to unpinned entries, and seedability (rows 68, 71,
   76): only superseded D-167's Rationale (log 5848–5868) and its annotation
   (log 5874–5877).** This is the first track-2 item: three live rulings,
   stated twice in the spec (§8.2, §6.1), whose only home is a superseded
   entry. D-263 Position bullet 2 reaches them only through "Both wire
   clauses of §6.1 stand".
6. Frozen discrete outputs are exact; seeding picks the invocation; the
   stores' walk and their zero-partial embedding (rows 97, 100, 105): D-079
   Rationale log 2307–2316.
7. The misplaced-pin containment and "one convention" (rows 101, 104): D-263
   Rationale log 10213–10236.
8. "Every `Float64` position follows the scalar" reads the declaration as
   written (row 94): D-265 Rationale log 10425–10428.
9. The container edges (mixed, nested, empty), parametric rosters and
   element names as rate keys (rows 157, 160–162, 167, 229): D-085 Rationale
   log 2484–2491.
10. What `Group` gives up, and what `transparent_container` buys it (rows
    174, 176): D-184 Rationale log 6521–6522; D-211 Rationale log 7555–7557.
11. The path rejections and the `===` fact (rows 187, 190, 235): D-040
    Rejected log 1215–1220.
12. The meet's cost at a tap (row 80): D-168 Rationale log 5916–5920.
13. The bundle letter of an empty store (row 127): D-263 Rationale log
    10242–10244.
14. "Publicity is never implicit" (row 138): D-034 Rejected log 1070; D-041
    Rejected log 1240.
15. One-level routing as `output_passthrough`'s consumer; two helpers, not a
    keyword (rows 249, 253): D-209 Rationale log 7475–7478; D-171 Rationale
    log 6024–6030.
16. The feed-list doctrine and the line not to cross (rows 256, 257): D-145
    Rationale log 4879–4890 and Rejected log 4896–4904.
17. Scalar faces and partial scripting (row 259): D-207 Rejected log
    7430–7432.
18. A sample time belongs to the type, not the instance (row 232): D-042
    Rejected log 1255–1256.
19. The builder rejection itself (rows 169, 170): D-039 Rejected log
    1197–1199. A rejection the spec states as its own heading.

Rows 19, 32, 49, 64, 73, 144, 145, 146, 148, 205 are rejections or pointers
to rejections. They are adversarial (part G q4) and need no Position.

### Rulings with no entry at all

The base completeness rule, a non-empty store without its update law is a
build error (row 117; D-263 rules only its scope); `m_init` owes no update
(119); an event needs both halves, caught by method lookup (120; D-215 names
only the kind's reason); `EmptyFaceSelection`'s payload (242); the default
`prefix` folding the slash into `sep`, and an explicit `prefix` used verbatim
(251); the concreteness discipline for container element types (163); every
assembly declaration taking the component alone (183); `Group`'s rate
declaration (167, F6). Some are descriptions of an inherited status quo:
the §7.2 scoping restated (113), Flight.jl's `Cessna172X{K, A}` (153), "an
assembly never declares its external connections" (207), the precision
measurement (216). The completeness rules (117, 119, 120) read as
FlightCore-era checks the log never recorded; the rest are rulings the
prototype built and the log never recorded.

### Stale entry text and Spec fields

- D-033 Position (log 1011–1018): `events(::C)` "ordered + per-event
  `localize` flag" (removed by D-179) and `local_types` (deleted by D-165).
  No annotation.
- D-034 Position (log 1053–1056): intermediates "declared via strict
  `local_types` … presentation-filtered", retired by D-194. No annotation.
- D-055, whole Position (log 1568–1572): the `local_types` mechanism. Status
  "ratified", no annotation.
- D-041 Position (log 1226–1228): the single `exports(::A)`, whose shape
  D-170 superseded. No annotation on D-041.
- D-042 Position (log 1246–1248): "`Δt_base`/`h` fixed only at `Simulation`
  construction". No annotation.
- D-164 Position (log 5591–5593): the declares-nothing build error, with no
  note that it is `ClassUnreadable` (the refusal `src/` raises).
- D-171 Rejected (log 6037–6038): "Building `output_passthrough` now: stays
  guarded". D-209's Position says it annotates D-171 (log 7468–7469); D-171
  carries no annotation.
- D-184 Position and Rationale (log 6510–6525): "zero new declaration
  rules", which D-211 Position (log 7537–7538) says it amends; and a `Group`
  with three connection declarations and no rate declaration (F6). No
  annotation on D-184.
- D-166 Rationale (log 5731) "Semantics are **literal**" with the annotation
  "The literal semantics … go" (log 5791–5792), while the spec keeps
  "literal" in a new sense (F19).
- D-178 Rationale (log 6336–6340): "partial local-scope shadowing of
  *optional* feature declarations (`events`, `workspace`) still builds
  silently" — the residual the spec's 2027 sentence overstates (F24).
- Spec fields that lack the chapter-8 section holding the entry's content:
  D-079 (log 2305; lacks §8.2, cited at 2371), D-085 (log 2482; lacks §8.5),
  D-146 (log 4938; lacks §8.1, cited at 2055), D-226 (log 8275; lacks §8.1,
  cited at 2061), D-237 (log 8738; lacks §8.2, cited at 2397), D-239 (log
  8833; lacks §8.3, whose 2643 states it).
- Spec fields naming a chapter-8 section that holds nothing of the entry:
  D-179 (log 6359) and D-182 (log 6455) list §8.1; D-179's content is
  §8.2 2503–2509, D-182's is chapter 10's. D-266 (log 10462) lists §8.2,
  which holds none of it until F20 is ruled. D-145 (log 4873) lists §8.1.

### Factual problems in chapter 8

Two findings meet the recipe's test for **serious** (a defect in the design
or its sources, not in the prose): F1 by the letter of the test, F6 plainly.
They are marked; the rest are prose, citation or vocabulary problems.

- **F1 (serious by the letter).** 2052–2054: "A declaration names its
  *content*, never the *consequence* the declaration has." The log says the
  opposite. D-146 Rationale (log 4941–4945): the binding names "sat in the
  right class … but were content-named where the spec's own `exports`
  precedent is consequence-named, naming the role the declaration plays
  rather than the material it returns". D-170 Rejected (log 6009–6011) calls
  the consequence-named family "convention-purist". The paragraph's own last
  sentence (2056–2058) calls the content-named `*_connections` family "a
  recorded choice, not class drift", which only reads under the consequence
  rule. History: the text read "A bare-noun declaration names the
  *consequence* a declaration has rather than its *content*" in spec §16
  until `12db329` moved it, unchanged in sense, to `pending.md`; commit
  `c512ee6` (2026-09-23), moving it from `pending.md` into §8.1, inverted
  it. Serious by the letter, because the convention has no
  Position (D-144's Position states the four classes, not the axis) and the
  spec and the log contradict each other. The history makes it a
  transcription slip; part G q8 asks whether the orchestrator rules it as a
  correction or escalates it.
- **F2.** 1941–1942: "The obvious candidate is the `where {T <: Real}`
  ceremony of a continuous `y_types` (§8.2)." D-263 Position (log
  10171–10173) retired the ceremony: every contract declaration "takes the
  component alone on both tiers"; §8.2 2362–2364 says the same, and no
  `where {T` appears in §8.2. The sentence cites superseded D-166 (1941).
  Part G q7.
- **F3.** 2187–2188: "a one-field store publishes its field as the port of
  that name (§5.3)". D-252 Position (log 9445–9451) removed auto-publishing:
  "A component exposes a state or mode field by returning it from
  `output_state`". The clause comes from D-247's Rationale (log 9180–9181),
  written before D-252. The spec's own `Engine` comment (2132) says
  "exposing a state field is one line (§5.3)". Part G q7.
- **F4.** 2442–2443: "the **embedding guarantee** (§9.5), keyed on
  **walking leaves** (D-033)". D-033 (log 1011–1018) says nothing about
  embedding. The citation survives from "keyed on **declared-`T` leaves**
  (D-033)", which `0c1ab4f` (D-263) re-worded without re-citing. The ruling
  is D-238 Position (log 8788–8791). Part G q7.
- **F5.** 2530–2532: §7.2's scoping "requires … no pinned fields on the
  continuous path". 2422–2425 and D-265 Position (log 10394–10396) allow
  exactly that: "A field that must not follow the scalar is typed concretely
  in its struct (`b::Float64` beside `a::T`)". §7.2 (1587–1648) forbids
  `Float64`-pinned intermediates and `::SomeType{Float64}` return
  annotations, not concrete fields. Part G q7.
- **F6 (serious).** The `Group` sketch (2794–2813) has four fields and three
  connection declarations. `src/assembly.jl` 287–312 has a fifth field,
  `rates::R <: NamedTuple`, a `rates = (;)` keyword and
  `sample_times(g::Group) = g.rates`; the suite uses it (`test/test_discrete.jl`
  115–161, `test/test_show.jl` 17). §8.5 2772–2773 relies on it: "`(children
  = Relative(2),)` is the uniform spelling for a `Group`", which the spec's
  own `Group` cannot express, having no `sample_times` method. No entry
  records a rate declaration for `Group`: D-184 Position (log 6510–6515)
  names the three connection declarations; D-279 (log 11497–11499) keeps
  "`Group`'s keywords `wires`, `inputs` and `outputs`". Serious: the spec
  sketch and the code disagree on a library type's shape, and either fix
  records a ruling no entry holds (lesson 17) or changes what the framework
  does. The bare-`Pair` convenience `_entries` (`src/assembly.jl` 296–303)
  is the same kind of gap, smaller. Part G q1.
- **F7.** 3326: "That is 'structure kept in two artifacts' (§8.1; D-039)".
  §8.1 holds no such phrase (`rg` finds it only at 3326); 1930 says the
  opposite of a disease, "Redundancy … is accepted deliberately". The idea
  is D-039 Rejected (log 1197–1198, "dispatch type and structure recipe
  drift apart"). Part G q7.
- **F8.** 2893–2894: "That read side is the inspection side and `resolve`
  as the inspection primitive (§13.3)." The sentence has no verb, and §13.3
  (8985–9024) makes `resolve` one primitive for three clients (wiring,
  service, inspection; D-242 Position), the inspection client resolving "by
  the instance walk". Part G q7.
- **F9.** 3105–3107, comments in the IMU leaves block: "discrete class:
  plain form, bound check only" and "discrete class: cells pin
  (frozen-exact)". *Class* is primitive-versus-assembly (D-122 Position log
  3628–3635; glossary `#g-class`); the tier is meant. "Plain form" names the
  contrast with the two-argument forms D-263 retired; every form is plain
  now. Comment edits are ruled edits. Part G q7.
- **F10.** 3097: `# [§7.1][s7-1]'s explicit cast`, a reference-style link
  inside a fenced block, which renders literally. The other in-block
  pointers are plain ("(§5.3)" at 2132, 3088, 3092). Part G q7.
- **F11.** 3011–3018: "Three facts the example carries. … And the
  latch-back wire (below), where the integrals consume the sampler's
  published latch, joins `inner_connections` as one more ordinary pair."
  The IMU has no latch-back wire: 3165 says "The IMU's coupling is
  one-directional", and the wire back is the two-way variant (D-056 Position
  bullet 3, log 1603–1604). "Joins" should be "would join". Part G q7.
- **F12.** 2018–2021, the declares-nothing refusal, is `ClassUnreadable`,
  the same check as §8.5 2853–2857 (`src/build.jl` 135–136: "a component
  that declares nothing at all has no *class* to read, which §8.5 settles";
  `src/diagnostics.jl` 524, "declares neither family"). §8.1 names no kind
  for it, and 1971 offers `ClassUnreadable` only for the whole-inventory
  shadow. Naming the kind and pointing to §8.5 is the fix.
- **F13.** 2847: "mandatory even when empty (the `LowPassFilter`
  precedent)". The chapter's one `LowPassFilter` (2633) illustrates a
  one-line `y_types`, not an empty mandatory declaration; the referent is
  unclear. Delete the parenthetical, or point to 2633 with what it shows.
- **F14.** 1915: "on the `GUI.draw!` precedent". Flight.jl machinery used as
  if known; the spec's only other `GUI.draw!` is §11.7 7286, a periphery
  extension. It needs an introducing clause or a pointer
  (`spec_style.md`, "Introduce every reader-cold name").
- **F15.** Aerospace and Flight.jl names without an introducing clause:
  2701 "exactly today's `Cessna172X{K, A}` shape" (present tense, Flight.jl's
  type); 3283 and 3323–3324 "At C172X scale … four seams and roughly ten
  names" (a Flight.jl measurement, D-145 Rationale log 4878 cites
  `c172.jl:697-713`); 2840–2842 `AbstractAircraft`, `AbstractEngine`,
  `PistonEngine`, "a composite turbofan assembly"; 3385–3386 "A guidance
  scenario component wires `mode_req` and `EAS_ref`"; the `World`,
  `Systems` and actuator names in the §8.8 blocks (3238–3245, 3302–3356).
- **F16.** 3056 "exactly as the direct formulation applies its current
  `q_c_cc`", 3072–3073 "the direct formulation's `normalization = false`
  plus reset", 3074–3076 "After an hour of flight …": the direct
  formulation is Flight.jl's IMU, never introduced. The IMU code also uses
  `RQuat`, `RVec`, `Attitude.dt`, `FrameTransform` and `IMUSample` as
  known; §7.1 introduces `RQuat` only.
- **F17.** 1917–1921: "Four questions about that layer are settled here" —
  macros, namespace, schema, type. §8.1 has five subsections; "Names: four
  classes by role" (2032–2061) is not announced.
- **F18.** 2492–2493 quotes the message "cast where rotation semantics are
  wanted"; `src/diagnostics.jl` 855 says "cast where the domain semantics
  are wanted", and `src/` appends section pointers to all four messages.
  2489 introduces them as "the didactic style", so they illustrate rather
  than quote; leave as written.
- **F19.** 2365–2366 "this one is read **literally**" and 2376 "Semantics
  are **literal** once the walk has run". D-166's annotation (log
  5791–5792) records that under D-263 "The literal semantics and the
  two-argument form go". The spec reuses the word in a new sense (an entry
  states what the cell carries, nothing inferred), which a reader of D-166
  will misread. Keep the spec's sense; track 2 may annotate.
- **F20.** 2258–2263, the FFI door: "A component whose internals cannot
  propagate `Dual`s … declares it". D-266 Position (log 10447–10449):
  "`Pinned` records that a leaf carries no partials, not that an
  implementation cannot take them", with two doors, the local derivative
  rule under a tolerant entry and the `Freeze{V}` block. D-266 Rejected (log
  10508–10510) rejects "Reading a pinned entry as the only door for an
  AD-opaque implementation". §8.2 does not say "only", but it offers no
  other door, and D-266's Spec field lists §8.2. Part G q7.
- **F21.** 3193–3194: "(the Δt-on-continuous error at declaration time,
  §10.5)". §10.5 names no such error; 5509–5510 says `Δt` "is absent from
  continuous bundles, so touching it on the wrong tier is a missing-field
  error rather than a rule". The parenthetical needs rewording to what
  §10.5 says, or dropping.
- **F22.** 2216 "**Every declaration but the allocator takes the component
  alone**" and 2870–2871 "Every declaration takes the component alone".
  The stages, update laws, guards, handlers and `x_projection` take a bundle
  or a state as well (2132–2153, 3100), and §8.1's class 1 counts them as
  declarations (2041–2043). D-263's Position says "Every *contract*
  declaration". The scope needs one qualifying word (part G q7).
- **F23.** 2619: "a component with no `y_types()` method has no outputs".
  True of a stateful leaf; a stateless leaf without `y_types` is refused,
  `StatelessWithoutOutputs` (2587–2590; D-263 Position bullet 6). The
  bullet should say so or point. `y_types()` with empty parentheses is no
  declaration's call shape.
- **F24.** 2027: "The net holds under a *partially* shadowed component too,
  because `y_types` is still a declaration." True for a stage whose ports
  are declared, as the next sentence shows. D-178 Rationale (log
  6336–6340) records the residual: local-scope shadowing of an *optional*
  declaration (`state_events`, `ws_init`) "still builds silently with fewer
  features". The sentence should be scoped to the stage case.

Outside chapter 8, met while checking citations:

- **F25.** spec 7134 (§11.6) and log 6273 (D-177 Rationale): "the
  reflection class (§8.1)". §8.1 has never named one.
- **F26.** log 6378 (D-179 Rejected) and log 6469 (D-182 Rejected):
  "§8.1's no-macros/no-introspection foundations", "the introspection §8.1
  forbids". §8.1 forbids macros only.
- **F27.** spec 11803, 11807 (Appendix C) cite §8.5 for `TierUnreadable`
  and `StatelessWithoutOutputs`, which §8.2 holds; spec 11993 cites §8.7 for
  `ArgumentInvalid`, which §10.5 5349–5350 holds.
- **F28.** spec 12614 (glossary, *nominal*) cites §8.2 for the nominal
  exact-match check, which §8.2 does not state.
- **F29.** `extensions.md` 286: "declarations *evaluated at the activation
  scalar* (§7.2, §8.2)", D-166's vocabulary; under D-263 they are retyped by
  the walk.

## F. Difficulty per section

| unit | difficulty | reason |
|---|---|---|
| A (intro, §8.1) | medium | 1,670 words in five subsections; the reorder (q6); F1 waits on q8 and sits in a bold lead-in; F2, F12, F14, F17, F24; the D-166 citation goes; three phrases quoted from outside must survive word for word |
| B1 (§8.2 opening, stores) | medium | three **Why.** labels to fold; the criterion paragraph moves to the front and needs glosses for the walk and `Pinned`; F3, F22; two display blocks to add |
| B2 (`u_types`, wire clauses, root inputs) | high | the densest argument in the chapter: permissive reading, two clauses, tier scope, obligation, root-input type, meet; three D-167 citations and three rulings that live only in D-167 (q9); the §6.1 duplicate (q2); M1's merge; F20 |
| B3 (`y_types`, custom structs) | high | 1,429 words of per-leaf rules nearly all U by D-263; D-280 and D-286 uncited; F4, F5, F19; the handle rule and its block; the misplaced-pin account; M2 in |
| B4 (events, completeness, §8.3, §8.4) | medium | three completeness rules with no entry (N); "Four rules" becomes three; §8.3's four bold bullets; §8.4's numbering is cited from outside and stays; F23 |
| D (§8.5) | medium | reorder (q6); `Group` waits on q1 (F6, serious); M3, M4, M5; eight R rows from D-085, cited nowhere; F13, F15 |
| E1 (§8.6 rules, IMU assembly) | medium | reorder of six blocks (q6); D-129, D-170 uncited; F8; the IMU block and its two-spellings note |
| E2 (§8.6 IMU leaves to the sampling contract) | medium | math carried literally; F9, F10 (comment edits, q7), F11, F16; three claim-headings to retitle |
| F (§8.7, §8.8) | medium | M6 (q3) and M3 in; two **Rule.** and two **Why** labels; F7, F15, F21; four code blocks verbatim |

Warnings for the rewriters:

- **Terms of art stay verbatim**: declaration; by value, by type, by
  allocation; walk, walked, walking, pinned, tolerant, demanding frozen;
  participates; permissive reading, predictive reading, envelope reading;
  face bound; nominal bound check; walk-compatibility clause; genericity
  obligation; embedding guarantee; root input, root-input type, root-input
  cells; tight bound; seedability; FFI door, freeze door; misplaced pin;
  constructibility at `T`; opaque leaf; handle; class, tier, primitive,
  assembly; container children; name-transparent; bare key; inert parameter;
  generic holding; imposed derived contract; face, port, write surface;
  two-notation rule; two-producers error; schema authority; error locality;
  didactic style; did-you-mean; list in hand; inert component; shadowing
  check; structure step; stage 1, stage 2; integrate-and-difference; latch;
  latch-back wire; left action; inertial rate; anchor change; taught
  contract; boundary sampling; auto-bubbling; feed list.
- **Distinctions the log fought for.** "a meet, not … agreement"; "face
  bounds, not cell types"; "declarations record choices, and obligations are
  checked"; "lurks, but is never silent"; "extended, not called";
  "Declarations *define* … Evaluation *checks* …, never the reverse";
  "transparent grouping, not assemblies"; "authored data, never inferred
  structure"; "the criterion, not uniformity, is the rule". A paraphrase that
  drops one half changes the rule.
- **Phrases quoted from outside.** "at build time where possible" and "at
  first execution otherwise" (1931–1932; spec 3892, 4167); "Types come by
  declaration, values by execution, and conformance by comparison" (2075;
  glossary 12193); the hint "if `F` participates in differentiation, remove
  its `Pinned`" (2465–2466; D-286 quotes it); "a face feeding nothing
  declares nothing" (2909; D-210 Rationale). Keep each word for word.
- **Quoted diagnostic messages stay verbatim**: 1983–1985, 2465–2466,
  2490–2499, 2675–2676, 2856–2857 ("holds components but declares no
  `inner_connections`"), 3268 ("more than one selector given").
- **Counts are rulings or are cited.** "four classes", "at most one"
  transparent container, "exactly one of `x_init` and `s_init`", "exactly
  one stage", "two clauses", "two mitigations", "one wire per input", "at
  least one internal endpoint", "two build-checked invariants", "five
  mistakes" (the numbering w1–w5 is cited), "two reasons" (spec 7158 cites
  §8.5's class-supertype refusal "for two reasons"), "Three alternative
  spellings". "Four rules" becomes "Three rules" under M1; "Three facts"
  waits on q7 (F11).
- **The log's vocabulary is old.** D-033, D-034, D-039, D-041–D-046, D-055,
  D-079, D-085, D-117 and D-144 say `init_x`, `input_types`,
  `output_types`, `local_types`, `workspace`, `events`, `connections`,
  `exports`, `rates`, `faces`, `passthrough`, `h_x`, `f`, `g`, `project`,
  `child_connections`, `input_connections`, "kind", "root slot", "Stratum
  A", "Tier-1". Never import them when citing an entry.
- **Never cite D-166 or D-167.** Where they hold the only statement, follow
  q9.
- **"As it always was."** 2252, 2265–2266 and 2392–2393 say leaves "stand as
  they always were" or "pin as they always did", history relative to the
  retired two-argument forms. Say what they do; keep the rule.
- **Kind names cited from outside.** Appendix C cites a chapter-8 section
  for 33 kinds (11709–11993), every section from §8.1 to §8.8. Where a section names a kind today, keep the
  name in that section.
- **The chapter cites by adjacency.** Many C rows have their citation one
  paragraph away. A split or a move that separates a rule from that paragraph
  needs the citation repeated.
- **Glossary links reset per section.** The chapter links 54 distinct
  anchors; one link per term per section, at first use.
- **Bold lead-ins are headings.** About 35 across the chapter. Each becomes a
  `####` label, a plain topic sentence, or a bold headline clause with its
  D-citation. Count before and after.
- **Code and math**: part C, "Code blocks". `Group`'s block is frozen pending
  q1.
- **Aerospace and Flight.jl names** (F14–F16) take one introducing clause
  that claims nothing beyond its source; "today's" and "the current" become
  Flight.jl's.

## G. Decisions at checkpoint 1

Settled for every chapter and not asked again: log repair rides track 2, and
bold marks one headline clause per ruling (recipe step 1, checkpoint 1).

**q1. `Group`'s rate declaration (F6, serious).** The spec's `Group` has no
`rates` field and no `sample_times` method; `src/` has both and the suite
uses them; §8.5 2772–2773 already relies on them; no entry records them.
Options: (a) escalate: the block (2794–2813) and 2772–2773 stay as written,
the unit D rewriter carries both verbatim and flags them, and the owner
decides between recording the built shape (an entry, then the sketch gains
the field, the keyword and the method) and removing it from `src/`; (b) rule
the sketch's update now from `src/`. Recommendation: (a). The recipe
reserves serious findings to the owner, and (b) would state a ruling no
entry holds (lesson 17). Recommendation to the owner: record the built shape,
since the rate scope is what makes `(children = Relative(2),)` and every
`Group`-hosted discrete test work.

**q2. The home of the two wire clauses (§8.2 2280–2300 against §6.1
1275–1326).** §6.1 is the fuller statement (the kinds, both remedies, D-236,
D-264, the failure asymmetry) and says "Two clauses type-check a wire
(§8.2)"; §8.2 states them over the declarations. Options: (a) keep both now;
§8.2 cites D-263 and D-236 at the clauses, adds a pointer to §6.1 for the
kinds and remedies, and the duplicate goes on record for chapter 6's
rewrite; (b) trim §8.2 to the permissive reading plus a pointer to §6.1 now,
and change §6.1 1277's pointer in the same landing, an outside edit; (c)
make §8.2 the home and trim §6.1 in chapter 6's turn. Recommendation: (a).
It moves nothing outside the chapter, keeps §6.1 1277's pointer true, and
leaves the home to the chapter whose subject is the wire. My lean for that
later ruling is §6.1 for the clauses and kinds, §8.2 for the reading of an
entry.

**q3. §8.7's restatement of the `sample_times` forms (M6).** Chapter 10's
survey made §10.5 the home of the forms and their validation, §8.7 the home
of the key rules. Options: (a) trim 3181–3188 to the spelling, the sentence
"Relative entries compose affinely down the tree, absolute entries anchor,
and all are compiled to one `(D, Φ)` pair per discrete component" (spec
12188 and log 6981 rely on it), and a pointer to §10.5 for the wrappers and
the default; (b) keep it whole. Recommendation: (a).

**q4. Adversarial rationale.** `spec_style.md` sends "why alternative X
loses" to the log. Candidates, with the entry that already carries each:
1997–1999, the re-export submodule (D-117 Rejected log 3502–3504);
2201–2203, types with `probe_value` synthesis (D-073 Rejected log
2112–2123, richer than the spec); 2274, "Names-only contracts were rejected
(D-033)" (D-033 Rejected log 1045–1046); 2313–2318's rejection clause (D-054
Rationale, D-078 Rejected); 2662–2666, "What this rules out" (D-016,
D-034, D-055, D-194 Rejected hold all five items); 2889–2890, the rejected
path forms (D-040 Rejected); 2955–2959, three rejected spellings (D-041 and
D-170 Rejected hold all three). Options: (a) cut each to a one-clause
pointer at its entry; (b) keep all; (c) cut only the pure lists
(2662–2666, 2955–2959). Recommendation: (a), keeping the constructive halves
that sit beside them: 2274–2278's "Inputs are the component's
*requirements*" and what it makes definable, 2315–2318's "The permissive
reading predicts nothing … That is what makes the marker carry information
here", and 2073–2075's last sentence (the glossary repeats it). 3373–3377,
"the line not to cross", stays: it forbids an authoring move, it does not
litigate a design.

**q5. "One arity on both tiers" (M5).** Options: (a) trim 2867–2879 to the
class sentence ("Class fixes *which* declarations a type may define, and
nothing about their shape"), the assembly clause, the clause "The tier is
read from the store every leaf declares (§8.2)" (glossary 12525), the
`DeclarationOnWrongTier` name (Appendix C 11769) and a pointer to §8.2; (b)
keep it whole; (c) delete the subsection and fold one sentence into "Class
by declaration shape". Recommendation: (a).

**q6. Orders and labels.** The reorders of part C: §8.1 (schema authority
and contracts before the namespace and names), §8.2 (the criterion paragraph
to the front; topic labels; "Root inputs" as its own label), §8.5 (class
before containers; one arity after class; the builder into `Group`), §8.6
(the direction invariant up; root inputs before root uniqueness; a heading
for the worked IMU; topic labels for the three claim-headings), §8.8 (three
labels). Options: (a) all of them; (b) labels only, orders as today; (c)
none. Recommendation: (a). Each stays inside one unit, no inbound row names a
subheading, and each was checked for define-before-use.

**q7. Clear factual corrections, ruled before writing.**

1. F2 (1941–1942): delete "The obvious candidate is the `where {T <: Real}`
   ceremony of a continuous `y_types` (§8.2)." Cite D-032 for 1938–1941 in
   place of D-166. Evidence: D-263 Position log 10171–10173; no `where {T`
   in §8.2.
2. F3 (2187–2188): delete "and a one-field store publishes its field as the
   port of that name (§5.3)". Evidence: D-252 Position log 9445–9451.
   Replacing it with a `y_state` clause would claim more than D-252 says
   about port names, so deletion is the safe fix.
3. F4 (2443): cite D-238 in place of D-033. Evidence: D-238 Position log
   8788–8791; D-033 log 1011–1018 says nothing on embedding.
4. F5 (2531–2532): drop "and no pinned fields on the continuous path".
   Evidence: D-265 Position log 10394–10396; 2422–2425. §7.2 states no such
   requirement.
5. F7 (3326): "That is structure kept in two artifacts (D-039)", without the
   quotation marks and without "§8.1;". Evidence: §8.1 holds no such phrase;
   D-039 Rejected log 1197–1198.
6. F8 (2893–2894): "That read side is the inspection side, which resolves
   paths by the instance walk (§13.3)." Evidence: §13.3 9015–9024; D-242
   Position bullet 3.
7. F9 (3105, 3107, comments): "discrete tier: bound check only" and
   "discrete tier: cells pin (frozen-exact)". Evidence: D-122 Position log
   3628–3635 (class is primitive-versus-assembly); D-263 (every form plain).
8. F10 (3097, comment): `# §7.1's explicit cast`. Evidence: the other
   in-block pointers are plain (2132, 3088, 3092).
9. F11 (3016–3018): "a latch-back wire (below) … would join
   `inner_connections`", and the sentence that counts the facts must not
   count it as a fact the example carries. Evidence: 3165; D-056 Position
   bullet 3.
10. F12 (2018–2021): name the refusal `ClassUnreadable` and point to §8.5.
    Evidence: `src/build.jl` 135–136, `src/diagnostics.jl` 524; Appendix C
    11759.
11. F13 (2847): delete "(the `LowPassFilter` precedent)". Evidence: the
    only `LowPassFilter` in the chapter (2633) shows a one-line `y_types`.
12. F17 (1917–1921): the opening names five subjects, "Names" included.
13. F20 (after 2263): one sentence, citing D-266: `Pinned` records that a
    leaf carries no partials, not that an implementation cannot take them;
    an AD-opaque implementation that must participate keeps its entry
    tolerant and supplies a local derivative rule (§14.10), and a walking
    producer feeds a pinned entry through the `Freeze` block (§13.7).
    Evidence: D-266 Position log 10447–10460; §13.7 9506–9508; §14.10 11041.
14. F21 (3193–3194): replace "(the Δt-on-continuous error at declaration
    time, §10.5)" with a pointer to what §10.5 says, that a continuous
    bundle carries no `Δt` (§10.5). Evidence: §10.5 5509–5510.
15. F22 (2216, 2870–2871): "Every declaration of a structural fact" in place
    of "Every declaration", or an equivalent qualifier, since the stages,
    update laws and `x_projection` take a bundle or a state. Evidence: D-263
    Position ("Every contract declaration"); 2132–2153, 3100.
16. F23 (2619): write `y_types(::C)`, and add that a stateless leaf without
    one is refused (§8.2). Evidence: D-263 Position bullet 6.
17. F24 (2027): scope the sentence to a shadowed stage, and say that an
    optional declaration shadowed in a local scope drops its feature
    silently (D-178). Evidence: D-178 Rationale log 6336–6340.

Leave as written, flagged: F18 (illustrative messages), F19 ("literal",
track 2). F14–F16 need no ruling: `spec_style.md` ("Introduce every
reader-cold name") governs them, with "today's" and "the current" reading
as Flight.jl's.

**q8. F1, the inverted semantic axis.** By the letter of the recipe it is
serious: the spec and the log contradict each other and no Position states
the axis. Options: (a) treat it as serious: 2052–2054 stays as written, the
unit A rewriter carries it unbolded and flags it, and it goes to
`escalations.md`; (b) rule it a transcription correction, restoring the
reading the text had in §16 and `pending.md` before `c512ee6` ("A
bare-noun declaration names the *consequence* a declaration has rather than
its *content*"), citing D-146, and still list it in `escalations.md` for
the owner's audit. Recommendation: (b). The
paragraph contradicts itself as written (2056–2058), D-146 and D-170 agree
with the restored reading, and `git show c512ee6` shows the inversion
happening in a move that otherwise kept the paragraph's content.
Nothing in the design changes. If the orchestrator reads the test strictly,
(a).

**q9. Rulings whose only home is superseded D-167, and the half-superseded
citations.** The tier scope of the walk clause (2293), the obligation's
scope (2308) and seedability (2332) live only in D-167's Rationale and
annotation; 2244, 2300 and 2314 cite D-167. D-055 is cited three times for
a retired mechanism. Options: (a) cite D-263 at 2244 and at the three
rulings (its Position bullet 2 keeps the permissive reading and "Both wire
clauses of §6.1 stand"), keep their bold, drop D-167 from 2300 and 2314,
cite D-034 and D-239 where 2647 and 2660 cite D-055, and flag track 2 to
state the three rulings in a live Position; (b) keep the citations as
written until track 2. Recommendation: (a). `spec_style.md` forbids citing
a superseded entry, and D-263 is the entry that kept these rules alive.

**q10. The units.** Nine units as in part C: A 1,670, B1 1,015, B2 1,371,
B3 1,429, B4 1,468, D about 1,337, E1 1,178, E2 1,278, F about 1,646.
Options: (a) as proposed; (b) move §8.2's `u_types` opening (2232–2279) from
B2 into B1 to even them. Recommendation: (a), since the permissive reading
belongs with the clauses that apply it.
