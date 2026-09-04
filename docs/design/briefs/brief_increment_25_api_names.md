# Increment 25 — rename the component-authoring family: words for the stage, update, projection, event and workspace declarations

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `74d5f99`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

**Numbering.** This increment lands *before* the collecting/fail-fast
increment whose brief is already drafted as `brief_increment_25.md`. That
brief edits `classify_tier` and `classify`, which this rename also touches,
so the rename goes first and the collecting increment becomes 26 and takes
D-221. This brief's decision entry is D-220.

**Read, all in `docs/design/spec.md`:** §2.1 (197–229) — gains one sentence;
§5.2 in full (535–685) — the signature block and the closed-set paragraph are
rewritten; §5.3's "Stage roles: the letters" and "what each stage may see"
(693–751) — the first is rewritten, the second swept; §7.3's Workspace block
(1431–1498); §8.2's opening inventory and "State, modes, discrete state"
(1779–1872); Appendix A (9623–9752), Appendix B (9753–10068), Appendix C
(10069–10226) and Appendix D (10227–end) for the sweep. In
`docs/design/decisions.md`: D-074, D-075, D-077, D-173, D-195, D-196 — the
last is the template for a rename entry.

**Routed reading in `docs/design/implementation.md`** — do not read the whole
file, it is ~280 lines:

- "Running the suite" (12–32).
- The file-table rows for `src/declare.jl` (70), `src/assembly.jl` (71),
  `src/build.jl` (74), and the rows for `src/executor.jl`, `src/sim.jl`,
  `src/diagnostics.jl`, `src/trace.jl` — find them by name in the table
  (60–91).
- **"Authoring caveats" in full (221–278)** — always. The second paragraph
  ("Extending a declaration without importing it is silent on 1.12") is
  rewritten by this increment; the *Register edits* section below gives the
  replacement.

**Stance: conservative reading.** This is a rename. Build what the table
below says, nothing more. Where the spec's prose is ambiguous between a
mathematical symbol and an API name, the policy below decides; where it does
not, stop and say so in the report rather than improvising. Where the spec
and this brief disagree, the report wins over the edit.

**The design documents and the implementation are peers, neither subservient
to the other.** The spec is written before the code, not instead of it, and
the two are kept mutually consistent. A deviation that improves the design is
raised in your report, not kept as a liberty.

Run the suite in the **foreground** with a 600 s timeout, never in the
background: `julia --project=test test/runtests.jl` from the repository root
(the first run after an `src/` edit pays a ~15 s precompile). While
iterating, `julia --project=test test/runtests.jl declare build` runs those
files alone; gate each commit on the full suite. One commit per stage, suite
green at each. Commit subject: one sentence, no body, no attribution. Do not
push.

---

## The problem

The component-authoring family uses single letters and bare nouns as method
names: `f`, `g`, `h_x`, `h_xu`, `h_s`, `h_su`, `project`, `events`,
`workspace`. On Julia 1.12 a declaration written without `import Cadence: …`
creates a fresh local generic, silently, and the build sees a component that
declares nothing (the authoring caveat). When the user already owns a
function of that name — and `f` is the most common throwaway name in any
REPL, `g` is gravity in a flight package, `update` and `project` are
ordinary user verbs — the definition silently adds a method to *their*
function, and no diagnostic can tell a forgotten import from a legitimate
user function. The work queue's proposed shadowed-declaration diagnostic
would have to hedge on every one of these names.

The fix is at the root: distinctive, self-describing names, so a foreign
binding of a family name in the component's module is unambiguous evidence
of a forgotten import. The names also drop the underscored suffixes, which
read as subscripts and suggest partial derivatives, and make the two output
stages — machinery shared by both tiers — one pair of names instead of two.

## The table

Every rename in this increment, and nothing else is renamed:

| old | new | note |
|---|---|---|
| `f` | `state_derivative` | continuous update law |
| `g` | `state_update` | discrete update law |
| `h_x`, `h_s` | `output_state` | stage 1, both tiers |
| `h_xu`, `h_su` | `output_direct` | stage 2, both tiers; "direct" as in direct feedthrough |
| `project` | `state_projection` | positional, unchanged shape |
| `events` | `state_events` | the declaration |
| `Event` | `StateEvent` | the guard/handler pair type; `Base.Event` is exported from Base |
| `workspace` | `init_workspace` | arity unchanged: `(::C, ::Type{T})` continuous, `(::C)` discrete |

**What stays.** Every bundle field: `x, s, m, u, y, y_x, y_s, t, Δt, ws`.
The `guard`/`handler` halves and the word "event" in prose. `init_x`, `init_s`,
`init_m`, `input_types`, `output_types`, `sample_times`, the connection
declarations. The stage-numbered sweep names of D-196 (`sweep_1`,
`sweep_2`, `rhs`, `ticks`). The executor's *phase* symbol `:project`
(see *Symbols and strings* below). Diagnostic kind names, `EventHalfMissing`
included. `Period`, `Relative`, `Absolute`.

**No aliases, no deprecation shims.** There are no external users. A
half-renamed surface is the ambiguity this increment removes.

## The policy: mathematical symbols versus API names

The spec keeps `f`, `g` and `h` as mathematical symbols in prose and
formulas — `ẋ = f(x, m, u, t)`, `y = h(x, u)`, the flow/jump pair of the
hybrid-systems literature, the `h(x)`/`h(x, u)` dependence classes of
control. Anything that names a *Julia method* — a fenced code block, an
inline code span naming a method an author defines or the framework calls,
a did-you-mean message, an Appendix C payload value — uses the new words.

The test for a prose instance: would an author type this into a component
definition? If yes, it is API and renames. If it is a symbol in an equation
or a name for a mathematical object ("the flow `f`"), it stays. When unsure,
prefer the equation reading for §2–§3 and §7, the API reading for §5, §8,
§9, §13, §15 and the appendices, and list every instance you were unsure
about in the report.

Two consequences: §5.3's "Bare `h` denotes the integration step size only"
caveat is deleted, since no API name uses `h` any longer; and the §5.3
paragraph titled "Stage roles: the letters" becomes the paragraph that
states this policy.

## The design core

Four points are not mechanical. The docs stage settles each in the spec and
the log; the code stage conforms.

### 1. One pair of output-stage names across both tiers

D-195 gave each tier its own output-stage spellings so that a stage name
alone carried the tier, buying two things: the output-stage member of
`DeclarationOnWrongTier` (a discrete leaf declaring `h_x`), and per-function
closed bundle-name sets "with no tier qualifier". Both retire, and the
state-letter split of D-195 stands untouched.

- The tier is still fully determined without the output stages: `init_x`
  versus `init_s`, `state_derivative` versus `state_update`, and the
  `T`-form arity of `input_types`/`output_types`/`init_workspace`. A leaf
  declaring `state_derivative` beside `init_s` is still `StoreWithoutUpdate`
  or a tier disagreement, exactly as today.
- `output_state`'s legal bundle set is now tier-dependent: `x, m, t [, ws]`
  on the continuous tier, `s, t, Δt [, ws]` on the discrete. So is
  `output_direct`'s. §5.2's closed-set paragraph says "per function, per
  tier" again, which is what `bundle_names(fn, c, t::Tier, …)` already
  computes. The three-level funnel sentence (stage name ⊇ bundle ⊇ reads)
  survives with "stage name at its tier".
- §5.3's "a leaf mixing the families — `h_x` beside `g`, `h_s` beside `f` —
  is a build error" becomes "a leaf mixing the update laws, or declaring a
  store of one tier and the update law of the other, is a build error".
  The output stages drop out of that sentence.

### 2. `init_workspace` keeps the port contracts' arity

D-077 rejected `init_workspace` because "a workspace is not memory that
conditions overlay" and "the poison overwrites" it. D-183 removed
poisoning, and the remaining leg does not hold: `init` in this API already
means *establish* (the device contract's `init!`), not *initial value*, and
`init_x`'s own value is a default that conditions overlay. D-077's
*position* — declaration by allocation, called per activation and per
scratch-store set — stands unchanged.

The one visible consequence: `init_workspace` follows the tier split of the
port contracts (`(::C, ::Type{T})` continuous, `(::C)` discrete) while
`init_x`/`init_s`/`init_m` take the component alone on every tier. §7.3
states that in one sentence beside the allocator's signature block, with
the reason: the state re-scalars through reconstruction, so `init_x` never
needs `T`, while scratch is part of the `T`-generic surface itself. A
one-argument `init_workspace` on a continuous leaf is already a loud tier
disagreement at `classify_tier`; the message need not change.

§8.2's rule "`init_x`, `init_s` and `init_m` declare by initial value: the
type is derived from the value" gains the clause that `init_workspace`
alone declares by allocation and nothing downstream derives from its type.
§7.3's "declaration by allocation, never by initial value" stays true and
stops leaning on the method's name.

### 3. `state_events` and the time-event / state-event split

§2.1 gains one sentence after its two-policy list, in the hybrid-systems
vocabulary the section already lives in: the discrete tier's ticks, declared
by `sample_times`, are *time events*, whose instants are known in advance
and scheduled; everything declared through `StateEvent(guard, handler)` is a
*state event*, whose instant is unknown and must be detected — by boundary
check or by localization — which is why the declaration is `state_events`.
Note in the same sentence that the criterion is detection versus scheduling,
not which bundle fields a guard reads: a guard over an input is still a
state event. Appendix D gets `state event` and `time event` entries.

### 4. `StateEvent` is the pair type, and "event" stays the word

`Base.Event` is exported from Base, so a forgotten import of the pair type
gives a `MethodError` naming `Base.Event` — loud, but misleading. The type
renames to `StateEvent`, the same qualifier §2.1 now introduces, so the
declaration reads `state_events(::C) = (start = StateEvent(guard, handler),
…)` and the type name and the declaration name teach one word. The prose
vocabulary is untouched: "an event", "the event fires", "event handler"
remain correct throughout, and only code blocks, the appendices and the
import list change. The diagnostic kind `EventHalfMissing` keeps its name,
since kinds are not being renamed. D-220 records the rejected type names:
`Transition` (the spec already uses "transition" for the crossing itself),
`Jump` (spent on the discrete update law's lineage in §3.2, and stochastic
in the ecosystem), `Callback` (a hook rather than a modeled event, and
DiffEq's continuous/discrete callbacks use the tier words for the detection
policy).

## Spec and log edits (the docs stage)

Read `tools/spec_style.md` before touching the spec and
`tools/decisions_style.md` before touching the log.

1. **§5.2's signature block (542–557).** Rewrite with the new names. The
   block currently has one comment per tier stating each function's maximal
   legal set; keep that shape, since the sets differ by tier for the shared
   output names. Suggested form:

   ```julia
   # continuous component — maximal legal view set of each bundle in comments
   y_x = output_state(comp, args)       # x, m, t [, ws] — no-feedthrough stage
   y_xu = output_direct(comp, args)     # x, m, u, y_x, t [, ws]
   ẋ = state_derivative(comp, args)     # x, m, y, u, t [, ws]

   # discrete component — the same two stage names over its own state letter
   y_s = output_state(comp, args)       # s, t, Δt [, ws]
   y_su = output_direct(comp, args)     # s, u, y_s, t, Δt [, ws]
   s⁺ = state_update(comp, args)        # s, y, u, t, Δt [, ws]
   ```

   and the event block with `state_projection`. The hand-off example
   (`f(c::LowPassFilter, (; x, u))`, `h_su(c::PID, …)`) and the "`project`
   alone stays positional" sentence rename in place.
2. **§5.2's closed-set paragraph (615–625) and the did-you-mean example
   (600–604).** Per point 1 of the design core. The example message becomes
   "`state_derivative` of `Foo` destructures `m`, but `Foo` declares no
   `init_m`".
3. **§5.3 "Stage roles: the letters" (693–715).** Retitle "Stage roles: the
   names". First paragraph: the policy — the spec's formulas keep `f`, `g`,
   `h` with their lineage (Goebel–Sanfelice–Teel flow/jump, `y = h(x, u)`),
   the API spells them as words, and the table of correspondences. Delete
   the bare-`h` sentence. The suffix rule ("a stage suffix names the
   dependence class") becomes: the stage *name* states the dependence
   class, `output_state` for `y = h(x)` and `output_direct` for
   `y = h(x, u)`, so "no `direct` in the name" is the no-feedthrough
   property. D-075's point that modes fold under the state and ambient
   facts ride unnamed survives verbatim. The closing "stage names carry the
   tier" paragraph is rewritten per design point 1.
4. **§5.3 "what each stage may see" (717–751), "The schedule", "Why
   derivatives may read outputs", §5.4–§5.6.** Sweep.
5. **§2.1.** The sentence of design point 3.
6. **§7.3 Workspace (1431–1498).** `init_workspace`; the arity sentence of
   design point 2; the by-allocation sentence reworded.
7. **§8.2 (1779–1872).** The inventory example renames (`output_direct`,
   `state_derivative`, `state_events`); the "State, modes, discrete state"
   rule gains the `init_workspace` clause; the `events(::C)` block heading at
   2094 becomes `state_events(::C)`; the `Event(...)` constructor calls in
   the inventory example (1811–1813) and under that heading (2097) become
   `StateEvent(...)`; "No stage tags anywhere" and "Completeness of the
   declaration set" swept. The remaining `Event(` spans are at 3779 (§10.4)
   and 9766 (Appendix B).
8. **§8.1, §8.5 (class by declaration shape), §8.7, §9.3, §9.5, §9.7, §10.4,
   §12.5, §13.2, §13.7, §14.1, §15.2, §15.3, §15.5.** Sweep by grep for the
   `h_*` names and `project`/`events`/`workspace` code spans; then a reading
   pass for prose `f`/`g` under the policy. The counts are a guide: 71
   `h_*` hits in the spec, concentrated in §5, §8, §15 and the appendices;
   33 `project` spans, 14 `events`, 18 `workspace`.
9. **Appendix A** (the author-facing index — every entry naming a method),
   **Appendix B** (synopsis; the signature lines at 9762–9796), **Appendix
   C** (payload columns whose values are declaration or stage names:
   `StoreWithoutUpdate` 10140, `DeclarationOnWrongTier` 10145, and the
   `ConformanceFailure`/`UndeclaredReturnField` rows whose `what`/`stage`
   payloads carry a stage name as a string), **Appendix D** (glossary:
   entries for *flow*, *stage*, *bundle*, *function family*, *projection*,
   *auto-published port*; the new *state event* / *time event* entries).
10. **Companions and `extensions.md`.** `companions/frozen_discrete_walkthrough.md`
    (9 hits), `companions/event_visibility_walkthrough.md` (6),
    `companions/trim_environment_walkthrough.md` (1),
    `companions/sample_time_proposal.md` (1), `extensions.md` (4). Sweep the
    same way; the spec wins over them where they disagree.
11. **D-220.** Title: "Rename the authoring family to words: stage, update,
    projection, event and workspace declarations". Position: the table
    above, as a bulleted list of rulings, plus what stays. Spec: the swept
    sections, sorted. Rationale: the 1.12 silent-shadowing mechanism and why
    distinctive names make the forgotten-import diagnostic decidable; the
    subscript reading of the underscored names; the two output stages as
    shared machinery. State explicitly which earlier rulings this entry
    retires — D-195's output-stage split and its "no tier qualifier"
    bundle sets, D-077's rejection of `init_workspace` — and that both
    entries' positions otherwise stand. Rejected: keeping the letters with a
    shadowing diagnostic instead (the diagnostic cannot distinguish a user's
    `f`); `derivative`/`update` unprefixed (`derivative` is exported by
    DifferentiationInterface, Polynomials and others; `update` is a common
    user function); `event_list`, `event_table`, `transitions` for the
    events declaration; `Transition`, `Jump` and `Callback` for the pair type
    (design point 4); keeping `Event` against `Base.Event`; `alloc_workspace`
    (a third prefix for one function). D-195 and D-077 keep `ratified` —
    the log has no partial status, and neither position is replaced.
    Add D-220's row to the index table at the top of the log.
12. **Tools.** Run `check_refs.jl`, `check_rows.jl`, `check_glossary.jl` and
    `linkify.jl` from `docs/design/` after the edits; they take names
    relative to that directory, and each one's roster is in its own header
    comments.

## Code and test edits (the code stage)

### Methods

In `src/declare.jl`: the six `function … end` declarations at 224–229 become
four (`output_state`, `output_direct`, `state_derivative`, `state_update`);
`function project end` (202) becomes `state_projection`; `events` (193)
becomes `state_events`; `workspace` (46) becomes `init_workspace`. Update
each docstring and the block comment at 208–220 (it explains the D-195
per-tier pairs; it now explains one pair over both tiers, with the
tier-dependent bundle sets).

`stage1_of` and `stage2_of` (262–263) become constants and are deleted;
every caller names `output_state`/`output_direct` directly. `update_of`
stays. `bundle_names` (280) needs no logic change beyond the deleted
helpers; fix its docstring's D-195 sentence. `_declares_workspace` (303)
renames its target.

### The tier classifier and the leaf family

`classify_tier` (`build.jl:56`): the four output-stage votes (62–65) are
deleted — the shared names no longer vote. The `f`/`g` votes and the
`:workspace` loop entry rename. The decider's `first(v) === :f || … :g`
(77) follows.

`leaf_declarations` (`assembly.jl:25–31`) and the `LEAF_FAMILY` string
(13–15) list the family by name; both rename, and the stage list shrinks to
five entries.

### Symbols and strings — the checklist a grep misses

Every place a name is a *value* rather than a binding. Do each explicitly;
do not trust the suite alone, since several are printed, not compared.

- `CursorFrame.fn` symbols (`executor.jl:17`, set at 150, 159, 219, 319):
  `:f` → `:state_derivative`, `:g` → `:state_update`, `:project` →
  `:state_projection`, and the stage symbols the sweep sets (grep `cursor.fn
  =` in `executor.jl` and `build.jl`) → `:output_state` / `:output_direct`.
  The comment on line 17 lists the legal set; rewrite it.
- `CursorFrame.phase` symbol `:project` (`executor.jl:18`, `sim.jl:351, 369,
  392`, `diagnostics.jl:167`) **stays**. It names the schedule phase of
  §5.3's "integrate → project → sweep", a verb in prose, not the method.
- `DeclarationOnWrongTier.declaration` values: `:project` (`build.jl:566,
  571`) → `:state_projection`; the `:events` vote → `:state_events`; the
  `:workspace` vote → `:init_workspace`.
- `ConditionResolution.role` `:workspace` (`conditions.jl:452`,
  `diagnostics.jl:987, 998`) — a role, not a declaration name. **Stays.**
- The pair type: `struct Event{G,H}` at `declare.jl:182` and its docstrings
  (176, 188) → `StateEvent`; the `ev isa Event` check at `build.jl:407`; the
  message text quoting `Event(guard, handler)` at `diagnostics.jl:366`.
  `EventHalfMissing` keeps its name.
- String payloads carrying a stage name: `ConformanceFailure.what` and
  `UndeclaredReturnField.stage` (grep `what = "` and `stage = "` in
  `build.jl`; `"project"` at `build.jl:575`). These become the new names.
- Message text: `diagnostics.jl:345, 352` (`init_x` without `f`…), and every
  `showerror` that quotes a family name — grep the backticked names across
  `diagnostics.jl`.
- Comments and docstrings quoting the family (`build.jl:5, 10, 42–50, 105,
  542–543, 954–955, 1064`; `sim.jl:322, 339, 345, 383, 573`; `trim.jl:346,
  354`; `executor.jl:61, 73, 156, 345, 368`; `declare.jl:214`). Under the
  policy, a comment that reads as an equation may keep the letter; one that
  names the method renames. Most of these name the method.

### Tests

- `test/CadenceTests.jl`'s `import Cadence:` list (6–): swap every renamed
  name. A fixture reusing a framework name collides loudly here, which is
  the point.
- `test/fixtures.jl` and every `test_*.jl` defining stages: rename the
  definitions, and every `Event(guard, handler)` construction (`fixtures.jl`
  278, 297, 318 and any in the test files) → `StateEvent`. Fixtures stay at
  top level.
- Payload assertions: `test_diagnostics.jl:263–267, 297–304`,
  `test_failures.jl:28, 37, 96, 102, 162, 174, 256`, `test_events.jl:95, 99`,
  `test_build.jl:163–164`, `test_conditions.jl:169` (the `:workspace` role —
  unchanged). Update the values to the new symbols and strings.
- **Deleted cases.** The wrong-letter output-stage fixture (`WrongLetter`
  with `:h_x` at `test_build.jl:164`) tests a refusal that no longer exists.
  Delete it and any sibling that declares an output stage of the wrong
  tier. List every deleted test in the report by name. The
  `:continuous_only` / `:no_manifold` cases for `state_projection` and the
  `:tier_form` cases for the contract declarations stay.
- Trace and replay tests comparing printed frames: grep `test_trace.jl`,
  `test_failures.jl` and `test_readers.jl` for the old symbols in strings.

### Register edits (`implementation.md`)

- File-table rows: `src/declare.jl` (70) if it names the family; check the
  others read true.
- Replace the second authoring-caveat paragraph (238–249) with:

  > **Extending a declaration without importing it is silent on 1.12.**
  > `using Cadence` followed by a bare `output_state(::MyComp, …)` definition
  > creates a local generic — no error, no warning, and whether or not the
  > name is exported. Julia ≤1.11 raised "must be explicitly imported to be
  > extended"; 1.12's binding partitions removed that, measured on 1.12.7.
  > Only `using Cadence: output_state` errors. The build then sees the same
  > declares-nothing component as above, and for an *optional* declaration —
  > `state_events`, `state_projection`, `init_m`, `init_workspace`,
  > `sample_times`, the connection declarations — the build succeeds with the
  > feature silently absent. The family's names are distinctive by design
  > (D-220), so a binding of one of them in the component's module that is
  > not Cadence's is unambiguous evidence of a forgotten import; the lever
  > is a diagnostic checking `parentmodule(typeof(c))` for such bindings and
  > naming them — proposed and not yet designed.

- The stand-ins table: none expected. Add a row in the same commit if the
  code lands anywhere short of the spec.

## Verification (both stages, and the reviewer)

1. The suite is green under the full run.
2. The test tally equals the pre-increment tally minus the deleted
   wrong-letter cases, which the report lists by name. Nothing else is added
   or removed.
3. From the repository root, this returns hits **only** in
   `docs/design/decisions.md` (historical entries keep their vocabulary) and
   in `docs/design/briefs/`:

   ```
   rg -n "\b(h_x|h_xu|h_s|h_su)\b" docs src test
   rg -n "\b(project|events|workspace)\(" src test
   rg -n "\bEvent\b" docs/design/spec.md docs/design/companions docs/design/extensions.md docs/design/implementation.md src test
   rg -n "\`(f|g|project|events|workspace)\`" docs/design/spec.md docs/design/companions docs/design/extensions.md docs/design/implementation.md
   ```

   The third command may leave prose hits for `f` and `g` that the policy
   keeps as mathematical symbols; the docs stage lists each survivor with a
   one-word reason (equation / lineage / API-missed) in its report.
4. `check_refs.jl`, `check_rows.jl`, `check_glossary.jl` and `linkify.jl`
   report clean.

## Stages

- **Stage 1 (Opus) — docs, first.** Doc amendments go docs-commit-first,
  then the increment conforms. Items 1–12 of *Spec and log edits*. No
  `src/` or `test/` edits. If the spec sweep alone fills the context, commit
  the spec and the log and hand the companions, `extensions.md` and the
  appendix re-check to a second Opus docs stage with the same brief; say so
  in the report. Commit: "Rename the authoring family to words and record
  the math-versus-API naming policy".
- **Stage 2 (Sonnet) — code, tests, register.** Everything under *Code and
  test edits*. Mechanical, guided by the checklist; where a comment's letter
  is an equation rather than the method, leave it and list it. Commit:
  "Conform the code and tests to the renamed authoring family".
- Cold review (Opus) over `74d5f99..HEAD`: the reviewer's primary job is
  the *Symbols and strings* checklist and verification item 3, then the
  four design points against the spec text. Then the fixer, then the
  reviewer's delta check.

## After it lands (the coordinator, not a stage)

- The work-queue item on the shadowed-declaration diagnostic is reworded to
  the forgotten-import check described in the new caveat paragraph.
- `brief_increment_25.md` is renumbered to 26, its decision to D-221, and
  its tip hash refreshed.

## Report format (every stage)

Commit hash; files touched; the suite's final tally against the
pre-increment tally, with deleted tests named; every deviation from this
brief with its reason; every prose instance whose math-versus-API reading
you were unsure of, with the reading you chose; friction (a spec sentence
that resisted, a name that fought a file); what the next stage must know.

Friction reports are evidence and have reversed briefs before. In
particular, say so if a bundle-set or wrong-tier sentence in the spec turns
out to depend on the output-stage names carrying the tier in a way design
point 1 does not cover, or if `init_workspace`'s arity trips a check other
than the tier vote.
