# Conformance audit — spec.md Parts I–IV and Appendices A/B/C against `src/`

An audit, not an increment. Nothing is built. Seven agents read one slice of
`docs/design/spec.md` each, cross-check it against the code, and write one
report to `reports/` at the repository root.

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip at
launch `2c02afb`. Never `cd` elsewhere (`cd` is aliased to zoxide in the
user's shell; use absolute paths).

## Why this is being done

`docs/design/implementation.md` already carries a self-reported account of
what is absent and what deviates. Self-reported is the weakness: it records
the deviations somebody wrote down. This audit exists to find the ones nobody
did. Your report is worth most where it disagrees with a register you are not
allowed to read, so an honest independent reading beats a confident one.

Spec and code are peers here. Neither is subservient. A deviation is not
automatically a defect in the code; it may be a defect in the spec. Do not
adjudicate that. Record what each says and let the coordinator decide.

## Hard rules

1. **Do not read `docs/design/implementation.md`.** Not any part of it. It is
   the register this audit is meant to test, and reading it destroys the
   value of your report. If a grep hit lands you in it, back out. `src/` and
   `test/` comments cite it by name; that is fine, keep reading the comment,
   do not open the file.
2. **Read-only outside `reports/`.** Do not edit `src/`, `test/` or `docs/`.
   Write exactly one file, your report, at the path named in your assignment.
   Scratch work goes in your session scratchpad directory.
3. **Do not run the test suite.** It costs five minutes and tells you nothing
   the source does not. Do not start a Julia process at all unless you have a
   specific one-line question that only the runtime can answer, and say in
   the report that you did.
4. **Stay inside your slice.** Observations about another agent's sections go
   in the report's "Observed outside my slice" section, unadjudicated. Do not
   audit them.
5. Read `spec.md` by section using the line ranges below and the heading
   outline. Never read it whole; it is 11413 lines.

## Orientation

The package is `src/`, 18 files:

```
   24  src/Cadence.jl      the module: dependencies and include order
  216  src/leaves.jl       the leaf walk
 1423  src/diagnostics.jl  diagnostic kinds, carrier, rendering
  331  src/declare.jl      the declaration layer
  790  src/assembly.jl     assemblies, paths, faces, the flatten pass
  105  src/store.jl        cell stores, the bundle, the clock
  446  src/executor.jl     entries, the compiled walk, the event set
 1077  src/build.jl        the build pipeline, Build, compile
  368  src/readers.jl      read selectors, Reader, gather
 1550  src/sim.jl          Simulation, the frame loop, run!/step!/replay!
  133  src/stepper.jl      RK4, Heun, dense output
  212  src/localization.jl the localization frame loop
  690  src/dataplane.jl    writers, staging, drain, snapshots, the log
  472  src/trace.jl        the input trace and replay feed
  248  src/roster.jl       device/binding traits, roster, claims
  218  src/bindings.jl     TableBinding, map_input
  497  src/devices.jl      the device contract, handles, tasks
  847  src/conditions.jl   the condition algebra, plans, capture
  579  src/trim.jl         TrimProblem, solve seam, trim!, TrimReport
```

The suite is `test/`, 23 test files plus `fixtures.jl` (928 lines, user-side
material) and `CadenceTests.jl` (the module, includes and `import Cadence:`
list). Every testset name states its property and cites the spec section it
answers to, so `rg '§' test/` is a cheap section-to-test index. `test/` is
evidence, not authority: a testset citing §N does not mean §N is complete,
and the absence of one does not mean §N is unimplemented. `src/` decides.

`test/` does not mirror `src/` and is not meant to. Several files assert
emergent properties owned by no single source file. Do not report the
asymmetry as a finding.

## The decisions log

`docs/design/decisions.md` is 8073 lines, one `### D-nnn — Title` entry per
decision. It frequently refines, narrows or supersedes the spec's letter, and
the code cites `D-nnn` in comments at the sites where it does.

**Before writing any `deviation` finding, check the log.** Grep for the
`D-nnn` the code cites at that site, and grep for the section number. Then
say in the finding whether a decision covers the divergence and which one.
A ratified divergence is still worth reporting, but it is a different animal
from an unratified one, and mislabelling wastes the coordinator's time.

Do not read the log front to back. Grep it.

## The report

One file, Markdown, at the path in your assignment. Three parts.

### 1. Summary

Half a page of prose. The slice's overall standing, the shape of what is
missing, and the two or three findings you would raise first. State plainly
if a section defeated you.

### 2. The table

One row per spec obligation. Granularity is the spec's own numbered
subsection, or a distinct obligation within one where the subsection carries
several. Not per paragraph: Part II would produce four hundred rows and none
of them would be read. Aim for the tens per section, not the hundreds.

| col | content |
| --- | --- |
| `anchor` | `§N.M` plus the `spec.md` line range, e.g. `§9.3 (3106–3201)` |
| `obligation` | one sentence, quoted or tightly paraphrased. What the spec requires |
| `verdict` | `accurate` / `partial` / `deviation` / `pending` |
| `where` | `file.jl:line`, or for `pending` the searches that came back empty |
| `notes` | for `deviation` and `partial`: what the code does instead, and whether a `D-nnn` ratifies it. Otherwise brief or blank |
| `test` | `test_x.jl` and the testset name, or `none` |
| `conf` | `high` / `medium` / `low` |

Verdict meanings, and hold to them:

- `accurate` — the code does what the spec says. You found it and read it.
- `partial` — the shape exists and does less than the spec asks. Say what is
  missing.
- `deviation` — the code does something the spec does not describe, or
  describes differently. Includes a construct whose payload, signature or
  arity is short of the spec's.
- `pending` — you believe nothing implements it.

### 3. Two lists

**Observed outside my slice** — anything you noticed in another part's
territory. One line each, no adjudication.

**Spec problems** — places where the spec is ambiguous, internally
inconsistent, or where the code's shape looks better than the spec's. The
design is not privileged over the implementation. These are as valuable as
the gap findings.

## The failure mode to guard against

An agent that cannot find something concludes it is absent. That error
manufactures gaps, and every one of them costs adjudication time downstream.

- Every `pending` row lists the actual grep patterns that came back empty.
  Not "I searched". The patterns.
- Search by concept, not by the spec's spelling. The code often names a thing
  differently from the prose. Try the type name, the field name, the
  diagnostic kind, the section number in comments, and the `D-nnn`.
- `low` confidence is a respectable answer and is cheaper than a wrong
  `pending`. Use it.
- The opposite error also counts: do not mark `accurate` because a
  same-named function exists. Read the body.

A verification pass will re-check every `pending` and every low-confidence
row against the code. Write for that reader.

## Julia traps you may misread

These are real behaviours of the language and of this codebase. They exist so
you do not report a non-finding.

- **Declarations in a local scope never reach the framework.** Inside a
  `let`, a function body or a `@testset`, `h_x(::MyComp, (; x)) = …` binds a
  new local function, not a method of the global `h_x`. The same holds for
  the periphery traits and the device contract functions. This is why test
  fixtures live at top level. A fixture that looks oddly placed is usually
  placed that way for this reason.
- **On Julia 1.12, extending a declaration without importing it is silent.**
  `using Cadence` then a bare `h_x(::MyComp, …)` creates a local generic with
  no error and no warning. Only `using Cadence: h_x` errors. `f` and `g` in
  particular are deliberately not exported.
- **A type's printed form depends on the printing module.** Payload fields
  and labels naming a user type go through `_typename` in `diagnostics.jl`,
  which is `nameof`. `string(typeof(...))` left in place names a framework
  type on purpose.
- **The init-service keyword is `t0` while the concept and the `Clock` field
  are `t₀`.** `clock.t₀ = t0` is that split, not a typo.

---

# Assignments

Each agent reads only its own section below, plus everything above.

## Agent A — Part I, Foundations

Slice: `spec.md` lines 127–1590.

```
§1  Purpose and method                    145–181
§2  Formalism                             182–249    (2.1 events 197, 2.2 exclusions 230)
§3  Component taxonomy                    250–315    (3.1 254, 3.2 280, 3.3 305)
§4  Ports and signals                     316–524    (4.1 318, 4.2 350, 4.3 366, 4.4 456)
§5  Evaluation order and feedthrough      525–989    (5.1 527, 5.2 535, 5.3 686, 5.4 830,
                                                      5.5 898, 5.6 917)
§6  Composition                           990–1255   (6.1 997, 6.2 1113)
§7  State and data representation         1256–1590  (7.1 1258, 7.2 1340, 7.3 1401,
                                                      7.4 1504, 7.5 1546)
```

Report: `reports/part1_foundations.md`.

Primary code: `leaves.jl`, `store.jl`, `declare.jl`, `assembly.jl`,
`executor.jl`, `build.jl`. Not a boundary, follow the obligation.

**This slice is different from the others and needs saying.** Much of Part I
is formalism rather than feature. §2 and §3 are not implemented at a site;
they are embodied across the build, and "where does it live" may have no
answer sharper than a handful of files. Do not force those into `pending`.
Where an obligation is structural, judge whether the code's shape *satisfies*
it and say so, citing the two or three places that carry it. Reserve
`pending` for obligations that name a concrete construct nothing provides.

§5.2's hand-off laws, §5.3's stage roles and step boundaries, §7.1's flat
backing, §7.2's eltype genericity and §7.5's allocation policy are the
concrete end of your slice and should be audited hard. §7.4 is lineage and
prior art; it asks nothing of the code, note that and move on.

§5.5 and §5.6 concern algebraic-loop rejection and feedthrough tracing.
Check both the detection and the diagnostic payload against the prose. Agent
F owns the Appendix C kind set; you own what §5.6 itself demands.

## Agent B — Part II, Authoring and build

Slice: `spec.md` lines 1591–3609.

```
§8  The declaration layer                 1610–2797  (8.1 1618, 8.2 1779, 8.3 2198,
                                                      8.4 2254, 8.5 2278, 8.6 2473,
                                                      8.7 2617, 8.8 2638)
§9  The build pipeline                    2798–3609  (9.1 2809, 9.2 2995, 9.3 3106,
                                                      9.4 3202, 9.5 3293, 9.6 3416,
                                                      9.7 3449)
```

Report: `reports/part2_authoring_build.md`.

Primary code: `declare.jl`, `assembly.jl`, `build.jl`, `store.jl`,
`executor.jl`, `conditions.jl` (§9.5), `trim.jl` (§9.6).

The largest slice by obligation count. §8.2's declaration inventory is the
densest page in the spec: every name family, arity and law in it is a
checkable obligation, and it deserves a row per family rather than one row
for the section. Same for §8.5's class-by-declaration-shape rules and §8.6's
path and face resolution.

Watch the ratio of what a construct *is* to what it *carries*. A declaration
family that exists with the right name but the wrong arity, or a build
artifact missing a field the spec lists, is `partial` or `deviation`, not
`accurate`. Read the struct definitions field by field against the spec's.

§9.5's conformance check and §9.6's stopped-sim clients both reach into Part
IV territory. Audit what §9 itself requires and leave the service internals
to Agent E.

## Agent C — §10, Time and execution

Slice: `spec.md` lines 3610–4661.

```
§10.1 Loop ownership                      3631–3648
§10.2 The stepper seam                    3649–3728
§10.3 Signal-table consistency            3729–3736
§10.4 Localization mechanics              3737–4063
§10.5 Multi-rate tick scheduling          4064–4364
§10.6 Event iteration at boundaries       4365–4578
§10.7 Real-time pacing                    4579–4661
```

Report: `reports/part3a_time_execution.md`.

Primary code: `sim.jl` (1550 lines, the frame loop and the macro-sequence),
`stepper.jl`, `localization.jl`, `executor.jl`.

The smallest spec slice and one of the densest code slices. §10.4 and §10.5
are algorithmic: the ITP bracketing, the arrival sweep, the trial evaluation
protocol, the tick gate arithmetic and the rate-scope fold. Audit the
*arithmetic*, not just the presence of a function. A gate computed over the
wrong quantity is a `deviation` even when every name matches.

§10.6's budget and quiescence semantics and §10.2's dense output are the
other two places where a plausible-looking implementation can be subtly
wrong. Read them closely.

`sim.jl` answers to some twenty spec sections. Much of it belongs to Agent
D's §11–12 and to §13. Stay on your obligations.

## Agent D — §11–12, Runtime periphery

Slice: `spec.md` lines 4662–6869.

```
§11.1 Staged writes, snapshot reads       4679–4778
§11.2 Outbound: snapshot publication      4779–4976
§11.3 Inbound: root inputs, claims,       4977–5159
      the frozen roster
§11.4 Inbound: staging and the drain      5160–5342
§11.5 Inbound: the input trace            5343–5446
§11.6 Devices: the authoring contract     5447–5801
§11.7 The GUI write path                  5802–5895
§11.8 Diagnostics and liveness            5896–6016
§12.1 Control plane                       6024–6049
§12.2 Loop scheduling and thread budget   6050–6123
§12.3 The next-snapshot wait              6124–6184
§12.4 Shutdown protocol                   6185–6462
§12.5 Scripts and mid-run mutation        6463–6529
§12.6 Run lifecycle and partial advance   6530–6661
§12.7 Replay                              6662–6869
```

Report: `reports/part3b_periphery.md`.

Primary code: `dataplane.jl`, `devices.jl`, `roster.jl`, `bindings.jl`,
`trace.jl`, `sim.jl` (lifecycle, attach/detach, staging, publication,
replay).

This is the concurrency slice, and the one where an obligation most often
holds only under a condition the code does not enforce. §11.1's no-shared-
mutable-model claim, §11.4's newest-wins merge and masked scatter, §12.3's
wait protocol and §12.4's shutdown ordering are all properties of the
*sequence*, not of any one function. Where the spec states an invariant,
check what actually guarantees it and say what would break it. An unguarded
edge is a finding even when the happy path is exact.

§11.8's per-writer cell has both a data half and a presentation half; audit
them separately. §12.7's replay obligations run across `trace.jl` and
`sim.jl` both.

## Agent E — Part IV, Failure and services

Slice: `spec.md` lines 6870–8796.

```
§13.1 Reporting policy                    6898–6937
§13.2 Diagnostics: values and carrier     6938–7063
§13.3 Build primitives: resolve, faces    7064–7146
§13.4 Runtime failures: catch, cursor     7147–7248
§13.5 Termination is a state              7249–7385
§13.6 Abnormal shutdown                   7386–7439
§13.7 Tooling consequences                7440–7590
§14.1 Conditions as overlays              7632–7681
§14.2 Fragment composition                7682–7769
§14.3 Resolution: flatten, validate       7770–7838
§14.4 Two application registers           7839–7963
§14.5 Boundary zero                       7964–8058
§14.6 Root-input totality                 8059–8109
§14.7 The trim problem                    8110–8256
§14.8 The trim service                    8257–8530
§14.9 Mounting                            8531–8612
§14.10 Linearization                      8613–8796
```

Report: `reports/part4_failure_services.md`.

Primary code: `diagnostics.jl` (1423 lines), `conditions.jl`, `readers.jl`,
`trim.jl`, `sim.jl` (the catch site and termination), `assembly.jl` (§13.3).

**Appendix C is not yours.** Agent F audits the diagnostic kind set row by
row: existence, payload fields, severity, collection policy, rendering. You
own §13's *mechanism and policy* instead — that the collect-versus-fail-fast
rule of §13.1 is what the code actually does, that §13.2's carrier and
rendering machinery works as described, that §13.4's catch site and cursor
are as specified. Where you need a kind as evidence, cite it; do not
enumerate the set. You and F will overlap on §13.2, deliberately: you audit
the rendering machinery, F audits whether each kind renders to the spec's
words. Do not coordinate, and do not soften a finding because you expect F
to reach the same one.

§14.9 and §14.10 are the two largest single obligations in your slice. Check
them first, because if they are absent that is quick and the time is better
spent on §14.1–§14.8 where the interesting divergences will be.

## Agent F — Appendix C, the diagnostic kind set

Slice: `spec.md` lines 10069–10226, plus §13.2 (6938–7063) as the rendering
rules Appendix C's rows are judged against, and Appendix C's own preamble.

Report: `reports/appendix_c_diagnostics.md`.

Primary code: `diagnostics.jl` (1423 lines) for the kinds themselves, and the
throw sites, which are scattered across `assembly.jl`, `build.jl`,
`declare.jl`, `conditions.jl`, `trim.jl`, `sim.jl`, `dataplane.jl`,
`devices.jl`, `bindings.jl`, `roster.jl` and `trace.jl`.

**You own Appendix C for the whole audit.** Every other agent has been told
to defer the kind set to you and to audit only the mechanism behind it. This
is a narrow spec slice and a wide code sweep, which is why it is its own job.

One row per Appendix C kind. For each, four separate questions, and a kind
can pass one and fail another:

1. **Existence.** Is there a struct for it, at what `file:line`. A kind whose
   mechanism is absent may still have a struct, and a kind with a struct may
   have no site that throws it — check both, and say which.
2. **Payload.** Does the struct carry every field the payload column names,
   field by field. A kind carrying less than its column is a `deviation`, and
   the row says exactly which fields are missing. This is the highest-value
   column in your report; be exhaustive.
3. **Policy.** Does its severity match, and does its collection policy match
   — a kind whose column reads `collected` but which is thrown at the first
   violation is a `deviation`, and you will need to read the call site to
   tell. §13.1 is the rule these are judged against.
4. **Rendering.** Does it render per §13.2's rules.

Then the reverse sweep, which matters as much: **a diagnostic kind defined in
`diagnostics.jl` that Appendix C does not list.** Enumerate those too. They
belong in "Spec problems", one line each, with the site that throws them.

Where a kind's *mechanism* lives in another agent's part, the kind is still
yours and the mechanism is theirs. You are not auditing whether the check
fires correctly; you are auditing whether the diagnostic it produces is the
one Appendix C specifies. Say plainly when a kind exists but you could not
find anything that constructs it — that is a finding, not a gap in your work.

Note the two `string(typeof(...))` calls left in `trim.jl`: those name a
framework type deliberately, parameters and all. Every payload field naming a
*user* type should go through `_typename`. A field that does not is a finding.

## Agent G — Appendices A and B (Sonnet, mechanical)

Slice: `spec.md` lines 9623–9752 (Appendix A, taught contracts) and
9753–10068 (Appendix B, API synopsis).

Report: `reports/appendix_ab_api.md`.

A signature conformance sweep, not a design audit. For every entry point,
function, type and keyword Appendix B lists:

- does the name exist in `src/`, and at what `file:line`
- does the signature match: positional arguments, their order, the keyword
  names, the defaults, the return type where the appendix states one
- is it exported, and does that match what the appendix implies

Same treatment for Appendix A's taught contracts: every contract it indexes
should resolve to something in the code, and the index entry should be
accurate about where the obligation lives.

Use the same table format as the other agents, with `anchor` as the appendix
row rather than a section number. Verdicts: `accurate`, `partial` (exists,
signature differs in a stated way), `deviation`, `pending` (no such name).

Be exhaustive and be literal. A keyword spelled differently is a finding. A
default value that differs is a finding. Do not judge whether the difference
matters; record it. Where a name resolves to something whose behaviour you
cannot check cheaply, mark `conf: low` and say so rather than guessing.

Two traps that will otherwise generate false findings: the init-service
keyword is `t0` while the `Clock` field is `t₀`, deliberately; and `f` and
`g` are deliberately unexported.
