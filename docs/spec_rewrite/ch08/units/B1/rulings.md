# Unit B1 (§8.2 opening and the stores): rulings

Log line numbers are `docs/design/decisions.md` lines in the working tree on
2026-10-02. Old spec lines are at the base commit `084d6f0`.

Order applied (survey part C, R6): the `Engine` block; the roadmap sentence;
the criterion paragraph (old 2216–2230), moved to open the section, its three
conventions set as a list, with glosses for the walk (`#g-leaf-walk`) and
`Pinned`; then `#### The stores` (old "State, modes, discrete state").

Ruled edits applied:

- **R7 F22.** Old 2216: "Every declaration of a structural fact but the
  allocator takes the component alone", bold, cited to D-263.
- **R7 F3.** Old 2187–2188: "and a one-field store publishes its field as the
  port of that name (§5.3)" deleted (D-252 Position, log 9445–9447).
- **R4.** Old 2201–2203 becomes "Stores declared by type, with synthesized
  initial values, were rejected (D-073)". The cut details, `u_types`-style and `probe_value`
  (§9.3), map to D-073 Rejected, log 2112: "`init_*` as types +
  `probe_value` synthesis". The log span is richer (log 2112–2124).

## Corrections proposed

None beyond the ruled edits.

## Citations added or replaced

All are additions. None replaces an old citation.

- **D-033**, at "`x_init` on the continuous tier, `s_init` on the discrete,
  and `m_init` declare by initial value", now bold. Position (log 1011–1012):
  "`init_*` by value (type derived — nothing to drift)". D-033 is
  half-superseded elsewhere (its `localize` flag and `local_types`), not in
  this clause.
- **D-247**, at "The value is a `NamedTuple`, one named field per leaf", now
  bold. Position (log 9153–9155): "returns a `NamedTuple` with one named field
  per leaf, and no other form is admitted". The old text cited D-247 two
  sentences later; that citation stays.
- **D-263**, repeated at "Every leaf declares exactly one of `x_init` and
  `s_init`", now bold. Position bullet 5 (log 10192–10194): "Every leaf
  declares exactly one of `init_x` and `init_s`, and a stateless leaf declares
  it empty". The old text cited D-263 two sentences later; that stays.
- **D-077 and D-263**, at "It is declared by allocation, as
  `ws_init(::C, ::Type{T})` on both tiers". D-077 Position (log 2228–2230):
  "the method *is* the allocator"; its annotation (log 2241–2244) and D-263
  Position bullet 4 (log 10189–10191): "keeps its scalar and takes it on
  **both** tiers". Not bold, since §7.3 1715 holds the rule.
- **D-079**, at "Partials enter through per-invocation seeding, never through
  initialization". Rationale only, below. Rationale (log 2316): "per-invocation
  seeding, never typing"; and for "never through initialization", Rationale
  (log 2309–2310): "declared `Float64` initial values embedding as
  zero-partial constants".

## Rationale-only rulings

- **D-079, Rationale (log 2316, 2309–2310).** "differentiation participation =
  per-invocation seeding, never typing", and "declared `Float64` initial
  values embedding as zero-partial constants". Survey part E, "Rulings that need an
  entry stating them in a Position", item 3. Not bold. The log owes a live
  Position.
- **D-263, Rationale (log 10207–10212)**, for "The criterion, not uniformity,
  is the rule. A `T` in a signature means the framework could not have
  supplied it." Item 3 again. No citation added: the paragraph's bold sentence
  cites D-263 already.

## Bold on the same entry elsewhere

Checked against the other units' `new.md` as of this writing.

- **D-263**: B1 bolds Position sentence 1 (the criterion, F22 wording) and
  bullet 5 (exactly one store). B2 bolds bullet 2 rulings and B3 a bullet 3
  ruling. No double. B4's "Tier is declared by the store" and D's "Every
  declaration of a structural fact takes the component alone" are unbolded;
  they must stay so.
- **D-033**: B1 bolds the `init_*` by-value clause; A bolds the Rationale's
  "functions of the type"; B4 bolds the stage-membership clause. Each is a
  separate semicolon-chained ruling of the Position. No double.
- **D-079**: B3 bolds the constructibility obligation; B1 bolds nothing on it.

## Inbound citations affected

None. Nothing leaves §8.2. Log 2252 (D-077 Rejected) calls the
"probe-value barrier" a §8.2 by-value argument; §8.2 did not state it before
R4 either (only D-073 Rejected, log 2116–2117, does). Track 2.

## Open questions

- **Paragraph order in the stores block.** The old field-name reason (2185–2189)
  explains the `NamedTuple` rule (2163–2167; D-247 Rationale, log 9175–9186),
  but it sits after the mandatory-store reason. The rewrite keeps the order
  and opens it with "The store names each leaf because". Proposed: move it to
  follow the `NamedTuple` rule directly.
- **`TierUnreadable` unbolded here.** D-263 Position bullet 6 rules it with
  `StatelessWithoutOutputs`; B4's completeness block states both together, so
  B4 is the natural place for that bold.
- **`init_*`** at the asymmetry paragraph: closed. It stays as written,
  since the spec uses that family name in several chapters, chapter 9
  included.
- **Display block added**: `x_init(::Gain) = (;)` and `s_init(::Sampler) =
  (;)` set as display code (survey part C, "Code blocks", lists the stateless
  forms as a candidate). Declared in `inventory.json`'s `added` list.
