# Unit C2: rulings

Unit C2 is §10.5 from "Declaring a sample time" (old spec 5293–5469), plus
"Coincidence and stagger" (5262–5279, M7). No R-ruling of the brief touches
this unit. The moves applied are M7 (stagger block after the example,
absorbing 5406–5409) and M8 (the mid-tree anchor doctrine after the `Absolute`
block). `build_inventory.py` is a scratch script that writes
`inventory.json`.

## Corrections proposed

None. No new factual problem was found in this unit.

## Citations added or replaced

Every added citation sits at a rule the old text left uncited or cited a
paragraph away.

- D-185 at "The entry declares one (period, phase) pair …" (old 5296–5298;
  the citation was 30 lines on). Position: "a `sample_times` entry … declares
  one (period, phase) pair as an explicit wrapper type naming the unit
  system".
- D-185 at "The wrappers are the whole vocabulary" (5315). Position: "the
  wrappers the whole value vocabulary, an unlisted discrete child defaulting
  to `Relative(1)`".
- D-185 moved from "The constructors themselves are plain data carriers"
  (5324–5325) into the validation sentence of the same paragraph. That
  sentence is plain: §9.1 (spec 3504) already bolds the same ruling. Position: "validation Stratum A's with path
  attribution and the constructors plain data carriers".
- D-019 and D-185 at "Multipliers compose multiplicatively and phases affinely
  down the tree" (5329). D-019 Position: "integer multipliers $K \ge 1$
  composing down the tree". D-185 Rationale: "multipliers multiplicative,
  phases affine (`D = K·Dₛ`, `Φ = Φₛ + φ·Dₛ`)".
- D-185 at "`K = 1` therefore admits no stagger" (5305). Rationale: "`K = 1`
  admits no stagger — same-rate siblings stagger one level down, the scope
  declared at twice their rate".
- D-185 at "A relative phase never refines the base grid" (5347–5349).
  Rationale: "relative phases never refine the base grid and cannot leave the
  scope grid".
- D-186 at "An `Absolute` entry may appear in any scope's `sample_times`"
  (5355; the citation was at 5414). Position: "Absolute declarations become
  legal in any scope … the `(T, τ)` pair an `Absolute` entry establishes is an
  **anchor**, severing its child from the enclosing scope's grid".
- D-186 at "Three corollaries follow" (5360). Position: "`K ≥ 1` reads 'a child
  cannot tick faster than the scope it is *relative* to' … the fastest-member
  convention counts relative members only, and anchored-vs-relative phase
  relationships are deployment-emergent, the printable bound schedule the way
  to audit them".
- D-186 at "Relative children of an anchored subtree compose against the
  anchor" (5370). Rationale: "`Relative(K, φ)` step `(a, K·mₛ, cₛ + φ·mₛ)`,
  `Absolute` severs and re-seeds `(Aₖ, 1, 0)`, nested anchors just seeding
  again".
- D-283 beside D-186 at the same sentence. Position bullet 1: "`Absolute`
  severs and re-seeds `(Aₖ, 1, 0)`, and a nested anchor seeds again".
- D-186 at "Absolute periods and nonzero offsets jointly constrain the base
  grid" (5374). Rationale: "the **constraint pool** is every anchor period plus
  every nonzero offset".
- D-283 beside D-186 at the same bold sentence. Position bullet 5:
  "Admissibility is exact GCD arithmetic over the constraint pool, every
  anchor period plus every nonzero anchor offset". D-283's Spec field lacks
  §10.5 (track 2).
- D-186 at the library-type rule (5417–5419). Rationale: "an absolute
  declaration inside a library type is legitimate when the rate is **a fact
  about the modeled system, not a preference about the simulation**".
- D-186 at "Anchoring leaves the never-cache-`Δt` argument below fully intact"
  (5434). Rationale: "never-cache-`Δt` fully intact (the pinning sits in the
  enclosing assembly's `sample_times`, the same site the multiplier lives; the
  component type stays rate-agnostic and consumes the bundle's `Δt`)".
- D-187 and D-254 at "`Δt` has a single source of truth, the deployment's
  `Schedule`", the old heading at 5440 made a sentence. D-187 Position: "the
  **bound schedule** … the single source of truth for `Δt`". D-187's
  annotation: "amended by D-254. The bound schedule is the `Schedule`, and it
  lives on the `Deployment`". D-254 Position: "`Deployment` … carries the
  `Schedule`".
- D-019 at "Each discrete component's effective period arrives read-only as
  the `Δt` field" (5442; the citation was at 5455). Position: "`Δt` arrives as
  a discrete-bundle field ([D-074][d-074]), single source of truth".
- D-019 at the author rule (5457; the citation was at 5455). Position: "no
  stored `Δt`-derived parameters". The sentence is plain: it is the same
  chained Position item as the bold bundle-field rule before it.
- D-185 at "The bundle's `Δt` is still `D·Δt_base`" (5466). Rationale: "`Δt`
  semantics explicitly unchanged (`D·Δt_base`; a phase shifts firing instants,
  never the period)".

## Rationale-only rulings

Each is cited and, where bold, kept bold. The log owes a Position that states
it.

- D-185, Rationale (log 6493–6496): affine phase composition, the canonical
  residue, one `(D, Φ)` pair per component (bold on the composition rule).
- D-185, Rationale (log 6505–6507): `K = 1` admits no stagger; same-rate
  siblings stagger one level down.
- D-185, Rationale (log 6505–6506): relative phases never refine the base
  grid and cannot leave the scope grid (bold).
- D-185, Rationale (log 6503–6504): phases leave `Δt` at `D·Δt_base` (bold).
- D-186, Rationale (log 6544–6551): the doctrinal line for library types, the
  exposed-multiplier idiom, "the framework cannot police the distinction"
  (bold on the doctrinal line).
- D-186, Rationale (log 6551–6553): never-cache-`Δt` intact under anchoring
  (bold).
- D-186, Rejected (log 6578–6579): absolute pinning from outside a subtree's
  contract. Plain, as before; D-186 is cited in the same section.
- D-019, Rejected (log 689): `Δt` readable in the stages. Plain now, as an
  elaboration of the bold bundle-field rule beside it.

## Inbound citations affected

None. No file links a `####` anchor of chapter 10. Rows checked against the
new text: spec 3124 and 3774 ("`Δt` … single source of truth", now the first
sentence under "`Δt` in the bundle"), 3194 (the missing-field error on
continuous bundles), 3523 (the affine law), 3777 (the worked example and its
code block), 3855 (a scope declared finer than its fastest member to buy
stagger room), 12205 (composition against the anchor), 12335, and
`sample_time_proposal.md` 227, 240, 760 and 779. Each fact is still in §10.5.

## Open questions

1. **Bold dropped where no entry rules, or where a clause elaborates another
   bold.** "a scope's base rate is its fastest relative member" (5344) has no
   entry (survey row 112, N); D-186 Position only presupposes it. It is now
   plain. Should the log record the convention so it can carry bold? Also
   plain now: "Validation belongs to the structure step" (bold in §9.1, spec
   3504), the author rule (one chained D-019 Position item with the bold
   bundle-field rule), "one `(D, Φ)` pair per discrete component" (elaborates the
   composition rule), "It must be readable in the *stages*" (elaborates the
   bundle-field rule), "Relative declaration structurally enforces that rule"
   (a consequence of D-019, no entry), and the bold terms **anchor** and
   **deployment-emergent**.
2. **The frame link.** The stagger block keeps its `[frame](#g-frame)` link.
   §10.5 uses "frame" earlier, in unit C1's "Two indices", unlinked in the old
   text. If C1 links frame at that first use, this link should go, since a
   term takes one link per section.
3. **D-019 cited beside phases.** The composition rule cites D-019 for the
   multipliers and D-185 for the phases. D-019's Rejected list still carries
   "Phase offsets: no demonstrated use", which D-185 reversed, and its
   Position says "compiled to absolute divisors", stale since D-186 (survey
   part E). D-019 is not superseded, so the citation stands; the log wants an
   annotation in track 2.
4. **D-187 Spec field** lacks §10.5, which now cites it (survey part E).
   Track 2.
5. **Glosses added** under "Introduce every reader-cold name": `fcs` as a
   flight control system (FCS) scope and `gnss` as a satellite-navigation
   (GNSS) component, following §9.2's "flight-control scope" and "discrete
   GNSS component"; ADC expanded; "a bus schedule" as "a data bus's
   transmission schedule"; "a PID's" and "a LeadLag's" as "a PID
   controller's" and "a lead-lag compensator's", so no FlightPhysics type
   name remains; `contract` and `sample_time_proposal.md`
   glossed. Each is in the inventory's `added` list.
