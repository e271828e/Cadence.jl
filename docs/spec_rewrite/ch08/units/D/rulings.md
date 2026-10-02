# Unit D (§8.5): rulings and findings

Applied: R1 (the `Group` block verbatim, nothing bolded or fixed about its
rate declaration), R5 (one arity trimmed), R6 (order: opening; "Class by
declaration shape"; "One arity on both tiers"; "Container children";
"`Group`: the on-the-fly assembly", with the builder rejection folded in
beside D-184's reach), R7 (F13 deleted; F22 "Every declaration of a
structural fact"). M3: the rate-key sugar is unit F's; the ambiguity sentence
joins the bare-key collision bullet and names the sugar with a pointer to
§8.7. M4: the "The builder is rejected" heading is gone; its sentences sit
before "The reach of the builder rejection is fixed by D-184". F15:
`Cessna172X{K, A}` is introduced as "Flight.jl's Cessna 172 model", and "In
an aircraft library, for example" introduces `AbstractAircraft` and the
engine families at the domain-hierarchies sentence.

## Corrections proposed

- **§8.5 names none of the class and container kinds Appendix C cites it
  for.** Appendix C 11759–11800 cites §8.5 for `ClassUnreadable`,
  `ClassMixed`, `ContainerMixed`, `ChildNameCollision` and
  `TransparentContainerUnknown`; §8.5 names only `ContainerNested`. Unit A
  now names `ClassUnreadable` with a pointer to §8.5 (F12), so a reader
  arriving here finds the rule but not the name. Evidence: Appendix C rows
  above; `src/diagnostics.jl` 513, 524; D-215 Position bullet 1. Proposed:
  "… is a build error naming both families (`ClassUnreadable`)"; "… on one
  type is a build error as well (`ClassMixed`)"; "(`ContainerMixed`)" after
  the mixing bullet's first sentence; "(`ChildNameCollision`)" after the
  collision bullet's bold clause; "(`TransparentContainerUnknown`)" after
  "must name a container field of the type". Not applied: no ruling orders
  it.

## Citations added or replaced

- D-039 at "An assembly is a plain struct" (Position: "Assembly declaration
  is type-based: plain struct, children = component-typed fields, parameters
  = the rest").
- D-039 at "`inner_connections` is the marker" (Position: "`connections`
  mandatory-even-empty as the kind marker"; the marker's name is today's,
  D-170).
- D-085 at the container rule (Position: "`Tuple`/`NamedTuple` fields with
  all-component elements unpack as children (`"field/1"`/`"field/key"` path
  segments, declaration-order layout)").
- D-085 at "Containers are transparent grouping, not assemblies" (Position:
  "containers are transparent grouping — no contract, no `connections`, no
  rate scope").
- D-085 at the mixing, nesting and empty-container bullets (Rationale:
  "mixed component/non-component elements = build error, zero-component
  containers = inert data, no container nesting (first cut), empty
  containers legal"). Rationale-only, below.
- D-211 at the name-transparent rule's first sentence, moved from the
  following sentence, which keeps its own D-211 (Position: "may declare at
  most one of its container fields **name-transparent**").
- D-211 at the collision bullet (Position: "A bare key colliding with any
  sibling child name is a build error naming both").
- D-211 at "`transparent_container` must name a container field of the type,
  and declaring two … is a declaration error" (Position: "at most one of its
  container fields"). Appendix C 11800 cites D-211 for
  `TransparentContainerUnknown` too.
- D-215 beside D-211 at the same sentence (Position bullet 1, "Build,
  collected: … `TransparentContainerUnknown`", the kind that refuses a
  `transparent_container` naming no container field of the type).
- D-212 at the shadow refusal and at "An empty field reserves nothing", the
  old citation having sat at the bullet's later sentence (Position: "a
  name-transparent element's bare key equal to the name of a sibling
  container field that contributes children is a build error naming both
  parties"; "An empty field reserves nothing").
- D-215 at the own-field-name ambiguity (Position bullet 1:
  "`ChildNameCollision` (a bare container key against the `sample_times`
  sugar or a sibling field, or two children with one name)").
- D-184 at "`Group` expresses it as a single library component" (Position:
  "`Group` is folded into the spec — the on-the-fly assembly as an ordinary
  library component … every ad-hoc topology a value of one type, defined
  once").
- §13.7 at the model-assembler gloss (spec 9514–9517: "`Group` serves the
  model assembler, for whom topology is data rather than a named type").
- §8.7 at the ambiguity sentence, the pointer the brief asks for. The
  sentence says the sugar "leaves only one ambiguity", keeping the old "the
  one ambiguity".

## Rationale-only rulings

- D-085, Rationale (log 2488–2490): the mixing error, no nesting in the
  first cut, empty containers legal. Cited, unbolded as before; the log owes
  a Position.
- D-039, Rejected (log 1197): "The builder … is rejected" is now a bold
  headline clause in place of its heading. The log owes a Position.

## Bold on the same entry elsewhere

None. Grepped every other unit's `new.md` for bold clauses citing D-039,
D-085, D-184, D-211, D-212, D-215 and D-263. D-263's arity ruling is bold in
B1 only; §8.5's restatement stays plain.

## Inbound citations affected

- spec 7158 ("§8.5 refuses a class supertype for two reasons"): both reasons
  kept, now introduced as "Two reasons rule out a supertype for class".
- spec 7224 and log 4665, `migration_outline.md` 60 (declarations as ordinary
  code, functions of the instance): kept in the `Group` subsection.
- log 6528 (D-184 Rejected, "§8.5's standing rejection"): kept.
- spec 11769 (`DeclarationOnWrongTier`) and spec 12525 (tier "read off the
  store every leaf declares"): both kept under R5.
- spec 11796 (`ChildNameCollision`, "a bare container key against the
  `sample_times` sugar"): the collision bullet keeps the ambiguity.
- log 9273, 9290 (D-249, "three signature violations §8.5 names"): already
  stale; R5 now drops "no signature-shape violation to name", so §8.5 says
  nothing about signature shape. Track 2 may annotate D-249.
- log 10195, 10245 (D-263, the class marker in §8.5): kept.

## Open questions

- **R5's keep list, one clause beyond it.** I kept "The one exception, the
  allocator's scalar, is the same on both tiers (§7.3, D-263)". Without it,
  "Every declaration of a structural fact takes the component alone"
  overstates. B1's bold reads "Every declaration of a structural fact but the
  allocator", so the allocator counts as such a declaration. The cut claims
  map to B1, B4 and the log as the inventory shows. "There is consequently no
  signature-shape violation to name" maps to D-263's Position bullet in
  `docs/design/decisions.md`, "`TierSignatureMismatch` retires with all three
  arms". The walk clause maps to B1's span through "A `T` in a signature
  means the framework could not have supplied it."
- **R1 reaches one more sentence.** The `Group` subsection's last sentence
  says "a `Group`'s wiring and rate declarations read exactly like a named
  assembly's". That also presumes a rate declaration the sketch lacks
  (escalation E1). Carried as written.
- "the same concreteness discipline as plain fields" (container bullet 4)
  names a discipline no entry and no other section states under that name
  (survey row 163). Carried as written.
