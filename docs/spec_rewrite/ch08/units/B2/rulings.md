# Unit B2: rulings and findings

Old lines are `spec.md` lines at `084d6f0`. Log lines are `decisions.md`.

## Corrections proposed

- **`RootInputTypeConflict` unnamed.** 2329–2330: "Two different concrete
  declarations remain an error." Appendix C 11736 cites §8.2 for
  `RootInputTypeConflict`, and D-236 Position bullet 3 (log 8680–8681) names it.
  §8.2 never names the kind. Proposed text: "Two different concrete
  declarations remain an error, `RootInputTypeConflict` ([D-236][d-236])."
  Left as written.

## Citations added or replaced

- **D-263** at 2234 (`u_types` form). Position: "Every contract declaration
  takes the component alone on both tiers, is written at nominal `Float64`,
  and is retyped by the framework."
- **D-263** at 2241 (discrete wholesale pin, `DeclarationOnWrongTier`).
  Bullet 1: "On the discrete tier the declarations pin wholesale, as before,
  and a `Pinned` entry there is `DeclarationOnWrongTier`."
- **D-263 replaces D-167** at 2244 (R9). Bullet 2: "The permissive reading of
  `input_types` ([D-167]) stands with the marker as its spelling".
- **D-078** added at 2244. Position: "Input entries are face constraints".
- **D-266** added after 2264 (R7, F20). Position: "`Pinned` records that a
  leaf carries no partials, not that an implementation cannot take them",
  with bullets 1 and 2 for the local rule (§14.10) and the `Freeze{V}` block
  (§13.7). The brief's one sentence is written as three, with nothing beyond
  the Position. They sit in `added`, because no old span holds them.
- **D-078** at 2266 (abstract entries). Rationale only, below.
- **D-033** at 2274 stays as a one-clause pointer (R4): "[D-033] records the
  rejected names-only contracts." The cut claim maps to D-033 Rejected log
  1045–1046: "Names-only input contracts: lose wiring-time type errors and
  standalone checkability."
- **D-263, D-236** at 2280 (R2). D-263 bullet 2: "Both wire clauses of §6.1
  stand, decided at the marker scalar by retyping the declarations instead of
  calling them." D-236 Position: "Both clauses of §6.1 are this relation,
  decided in Stratum A by evaluating the contract declarations at a marker
  scalar".
- **D-078** at 2282 (the bound check). Position: "wiring check `producer_face
  <: entry` at nominal faces — one uniform rule, exact equality the concrete
  degenerate."
- **D-263** at 2293 (tier scope, R9). Rationale only, below.
- **D-167 dropped** at 2300 (R9). "The unscoped variant is rejected" now
  stands uncited. See Rationale-only rulings.
- **D-054** at 2303 and 2307. Position: "Producers determine activation
  types, consumers accept — consumer obligation is genericity, checked by
  the `Dual` probe."
- **D-263** at 2308 (the obligation's scope, R9). Rationale only, below.
- **D-078** at 2309 ("declarations record choices"). Rationale only, below.
- **2313–2314** (R4, R9). D-263 stays at "the operative one" (bullet 2).
  The rejection clause becomes "The log rejects both ([D-054], [D-078])" and
  maps to D-078 Rejected log 2285–2287 ("Symmetric `T` as genericity
  envelope: … zero information …; the predictive reading remains impossible
  per D-054") and D-054 Rationale log 1555–1556 ("The envelope reading … is
  also rejected — zero information"). D-167 is dropped (R9). **D-033 is
  dropped too.** Its own text holds neither reading. Only superseded D-167's
  Rejected list ties it in ("[D-033] upheld").
- **D-078** at 2322 (tight bound). Rationale only, below.
- **D-236** at 2325 (abstract-at-root). Bullet 3: "A root input whose entries
  are all abstract is `AbstractAtRoot`."
- **D-208** at the merged 2607 ("the uniform root doctrine below does not
  relax it"). Bullet 3: "Abstract-at-root is unchanged: a primitive with an
  abstract input entry still cannot be built bare, and the component test rig
  (§13.7) keeps its stubbing role".
- **D-120** at the merged 2610–2611 (the rig and the stub child). Position:
  "A component with abstract input entries is rigged with a concrete stub
  child … wired to the abstract face"; Rationale: "`AbstractAtRoot` gains
  the remedy hint (wire a concrete producer; in a rig, a stub child)."
- **D-236** at 2327 (fan-out uniqueness). Bullet 3: "Its concrete entries
  must agree at `Float64` (`RootInputTypeConflict`); abstract co-consumers
  are checked by the bound clause."
- **D-263** at 2332 (seedability, R9). Rationale only, below. Bullet 1 also
  carries the walk of the root inputs: "the leaf walk that types `init_x`
  and the root inputs".
- **D-168** at 2357 (the meet's cost at a tap). Rationale only, below.
- **D-210** at 2605 (a key in both declarations at the root). Bullet 1: "a
  primitive root's face set is the union of its `input_types` and
  `output_types` keys, and a key declared in both is the same build error a
  duplicate face name is."

## Rationale-only rulings

Each owes a live Position.

- **D-263 cited for the walk clause's tier scope** (2293, bold). The only
  statement is superseded D-167, Rationale log 5848–5853 and annotation log
  5874–5877.
- **D-263 cited for the genericity obligation's scope to unpinned entries**
  (2308, bold). Only superseded D-167, Rationale log 5865–5868.
- **D-263 cited for seedability schema-visible** (2332, bold). Only
  superseded D-167, Rationale log 5862–5863.
- **"The unscoped variant is rejected"** (2300). Only superseded D-167,
  Rejected log 5890–5892. It is uncited now, since no live entry holds it.
- **D-078, abstract entries as structural substitutability** (2266, bold).
  Rationale log 2273–2275.
- **D-078, "declarations record choices, and obligations are checked"**
  (2309, bold). Rationale log 2279.
- **D-078, the tight bound at the root** (2322, plain). Rationale log
  2275–2277. Its abstract-at-root half is bold with D-236's Position.
- **D-168, the tap rejection naming the pinning consumer** (2357, plain).
  Rationale log 5916–5920. It is left unbolded, as written. See Open
  questions.

## Bold on the same entry elsewhere

- **D-263 bullet 2** carries two of my bolds. "Entries are face bounds, not
  cell types, and the reading is permissive" and "Two clauses check a wire"
  both rest on it. The second is also D-236's Position, which is why I kept
  it bold. If one bold per bullet is read strictly, unbold "Two clauses
  check a wire".
- **D-263 bullet 1** (walked on the continuous tier, wholesale pin and
  `DeclarationOnWrongTier` on the discrete) is plain here with a citation.
  B3's `y_types` block states the same bullet. No other unit's `new.md`
  bolds it yet.
- **D-266**: §14.10 (spec 11034) bolds "An implementation that cannot take
  `Dual`s has a third move", which is bullet 1. My bold is the Position's
  first sentence, a different ruling.
- **D-208**: §13.7 (9609) and §9.1 (3494) state it plain. E1's "Root inputs
  fall out" paragraph does not bold it (checked in `units/E1/new.md`).
- **D-210 bullet 1**: E1 bolds "At the root the uniqueness invariant follows
  the root's class". I cite D-210 plain at 2605.
- **Seedability**: §14.10 (10905) bolds "declaredly unseedable" as a bold
  word in an unrewritten chapter.
- **D-078 bound check**: §9.1 (3481) bolds "The producer's declaration at
  `Float64` must be `<:` the entry at `Float64`" with D-078. Mine is plain.
- **D-263/D-236 marker-scalar decision**: §9.1 (3485) bolds it. Mine is
  plain.

## Inbound citations affected

None. These rows were checked and still hold: spec 1277, 3466, 11719 and
11722 (the two clauses stay in §8.2, R2); 3494, 9609 and 9616 (any
component may be root); 3948, 11733 and 12083 (the tight bound,
`AbstractAtRoot`); 11739 (the meet); 4037 (the permissive reading); 10900
and 10911 (root-input cells, the meet's cost); D-264 Rationale log 10351 ("§8.2's substitution
promise") and 10366 (the obligation checked by the probe); D-168 Rationale
log 5910 ("§8.2's FFI door"); D-208 log 7446 (the tight-bound rule).

## Open questions

- **The meet's cost.** D-168's tap rejection naming the pinning consumer
  (2356–2358) is a ruling stated only in a Rationale, and §14.10 states it
  too. I left it plain, as written. Bold it in one of the two places.
- **Table bold.** The table's bold on "tolerant" and "demanding frozen" is
  dropped. Both are term bolds, and the checker refuses a bold without a
  D-citation. The normalized table is unchanged.
- **Links dropped by the section rule.** `tier`, `cell`, `contract`,
  `component` and `activation` are linked in B1's text, so B2 does not link
  them. The table keeps its `activation` link, because the table is carried
  verbatim. `component` is unlinked in B1 too, so §8.2 may carry no
  `#g-component` link. That is for B1 or the assembler to settle.
