# Unit B (§9.3): rulings for the user

Old lines are `units/B/old.md` lines; new lines are `units/B/new.md` lines.
Spec and log lines are those of the working tree at `d598755`.

## Corrections proposed

1. **Survey F11.** Old line 3, new line 9: "The nominal activation probes every
   user function once". The nominal *evaluation* runs the probes, and the
   nominal activation is its product. Evidence: §9.1's steps table (spec 3420)
   lists the nominal `Float64` activation as a product of the nominal
   evaluation; spec 3548 ("The nominal evaluation fixes the structure and the
   `Float64` typing"); this section's own "the nominal evaluation's probes
   that need it" (old line 30); v4 §9.4 "precedes the nominal evaluation's
   probes". Proposed: "**The nominal evaluation probes every user function
   once, at the initial state, with real values** ([D-050][d-050])." The
   `activation` glossary link would then have no first use in §9.3 and goes.
2. **Survey F12.** Old line 57, new line 84: "`Δt` in seconds does not exist
   until `Simulation` binds `Δt_base`". The `Deployment` constructor binds
   `Δt_base`. Evidence: spec 3575–3579 ("It binds the grid parameters");
   D-254 Position bullet 1 ("`Deployment` is the build plus `h`, `N_base`,
   `Δt_base`, …"). The sentence's own reason, "since deployment post-dates the
   build", already points at deployment. Proposed: "`Δt` in seconds does not
   exist until the `Deployment` constructor binds `Δt_base`, since deployment
   post-dates the build."
3. **A clarification.** Old line 15, new line 24: "The stage-1 hand-down,
   `y_x` and `y_s` on the discrete tier". It can read as both names belonging
   to the discrete tier. Spec 685–691 and 734 make `y_x` the continuous
   spelling and `y_s` the discrete one. Proposed: "The stage-1 hand-down,
   `y_x` on the continuous tier and `y_s` on the discrete, …".

## Citations added or replaced

- **D-050** at the probe-everything rule (new line 9, bold). Position: "All
  user functions — the `h_*` stages, `f`, `g`, guards, handlers and `project`
  — are probed once, at the initial state and nominal `T`." Log vocabulary;
  the spec's names are kept.
- **D-194** at the dead-stage rule (new line 35, bold). Position bullet 5:
  "`DeadStage`'s ground simplifies: a stage returning `(;)` produces no ports
  and is dead ([§9.3])." "Fail-fast" and "build error" were stated by D-165
  ("a dead-stage build error (`DeadStage`)"), superseded by D-194, which does
  not restate them. Listed per the brief.
- **D-115** at `ws` (new line 39, bold). Position: "`ws` comes from invoking
  the component's `workspace` allocator at the probing scalar before the
  Stratum B probes, sound because D-077's allocator reads only the instance
  and the scalar, deriving nothing from layouts". D-077 stays cited for the
  reason, as the old text had it.
- **D-115** at `t` (new line 81, bold). Position: "`t` is probe-scoped `0.0` —
  deployment binds no clock and `t₀` post-dates even deployment, D-051's
  strict probe-scoping applied to the clock".
- **D-051** at root-input synthesis (new line 45, bold). Position: "Probe input
  synthesis via `probe_value(::Type)`: `zero(T)`/`false`/first enum
  instance/`T()` fallback chain, overridable, missing-method error names face
  + type".
- **D-051** at probe scoping (new line 76, bold). Position: "probe values
  strictly probe-scoped (never initial slot values)". The old text cited D-051
  only on the rejected-alternatives sentence that M10 deletes.
- **D-149** at the `UninitializedInputs` check (new line 91, bold). Position:
  "Slot totality is checked at every application that establishes a complete
  world over virgin stores — `init!`, trim setup, trim commit". The kind's
  name comes from D-206 ("`UninitializedSlots` → `UninitializedInputs`"),
  which is not cited.
- **D-142** moved from "the probe is the enforcement moment, not the reason"
  (old line 74) to the bold totality rule (new line 97). Position: "stage code
  must be total over type-valid inputs". The old sentence spells out the same
  Position's mechanism, so it stays plain.
- **D-142** at "Parameter validation belongs where user-controlled data enters"
  (new line 133, bold). Position: "Parameter validation is not banned but
  mislocated: it belongs where user-controlled data enters".
- **D-060** at "Exceptions from model code are always abnormal" (new line 111,
  plain, beside §13.5). Position: "exceptions from model code always
  abnormal". Plain because §13.5 states the rule; §9.3 uses it as a reason.
- **"rejected above" became "that D-051 rejects"** (new line 79), since M10
  deletes the list "above" referred to. D-051 Rejected: "*Inputs declared by value à la
  `init_x`:* reads as an unwired-input default".

## Rationale-only rulings

- **D-142, Rationale (i)**, log 4618–4620: plausibility termination "migrates
  to a published `Bool` output face plus `stop_on`, §13.5's existing
  machinery". At new line 116 the sentence is plain and cites §13.5 and
  D-060, whose Position ("publication as an exported `Bool` face, policy as
  `stop_on` root faces") it applies, at the coordinator's ruling.
- **D-142, Rationale (ii)**, log 4621–4626: a self-consistency assert "is a
  regression test living in stage code, and its legitimate home is the test
  suite". Cited plain at new line 121.

Both are survey part E item 7: they need an entry that states them in a
Position.

## Inbound citations affected

None. M9 and M10 stay inside §9.3. Of the 46 inbound §9.3 rows in
`inbound.tsv`, none relies on the deleted list of D-051's rejected
alternatives. D-068's Rejected "the §9.3 probe-value leak" relies on the
probe-scoping rule, which stays (new line 76). Unit A1 maps §9.1's workspace
passage (M8) to old lines 24–30; that passage stays, as new lines 38–43.
D-142's Rationale says "The statement lands as one §9.3 paragraph"; it now
spans several paragraphs. That is log history and needs no edit.

## Open questions

1. **M10 needs your ruling.** The deleted sentence (old lines 51–53) is mapped
   to D-051's Rejected field. The spec named the first alternative "à la
   `x_init`"; the log says "à la `init_x`", the vocabulary of its day.
2. **Rulings with no current entry.** "A stage returning something other than
   a `NamedTuple` fails here" (new line 34) has none; D-165, superseded, held
   a related probe error. The hand-down sourcing (new line 24) was D-169's,
   superseded by D-252, which does not restate it. Both stay plain and
   uncited.
3. **Topological probing** (new line 29). D-048's Position names "probe chain"
   and "topo/cycle" in Stratum B/C vocabulary. Whether it rules the
   probe-in-topological-order sentence is borderline (survey row 74). Left
   uncited.
4. **The `Δt = 1.0` placeholder** (new line 86). D-115's Position calls it
   "the settled `Δt = 1.0` placeholder". The entry that settled it was not
   found. Left plain, without a citation.
5. **Two D-115 bold sentences.** D-115 rules `t` and `ws` in one Position.
   M9 puts them in different paragraphs, so each carries its own bold and
   citation. Same for D-051 (synthesis, probe scoping) and D-142 (totality,
   parameter validation).
6. **The diagnostic message stays inline** (new lines 61–64). It contains an
   em dash, kept verbatim as a quoted message. The survey suggested display
   blocks for the message, the fallback methods and the override signature.
   None is Julia code the old text spells out, so the fallback chain became a
   bullet list instead and no display block was added.
7. **No `####` labels.** The section is 1069 words, about v4's length. The
   context paragraph ends with a sentence naming its parts.
