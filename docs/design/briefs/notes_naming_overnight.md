# Notes: the naming passes, overnight run of 2026-09-24

Decisions the coordinator made alone while the user was away, in order,
each with its reason. The user reads this file first in the morning.

1. **Nothing is pushed.** Every commit lands locally; the push follows the
   user's diff review of the arc, as the pipeline has it.
2. **The docs commit landed as the brief specifies**, with no change to the
   text the user saw in the brief, after the three doc tools ran green.
3. **The `test/` survey brief was drafted while wave 1 ran**
   (`brief_naming_test_inventory.md`), to be launched after the `src/`
   remainder is reviewed and fixed, as the user's plan says. Its agents are
   Sonnet, not the `src/` inventory's Opus: the rules and rulings are now
   settled and the remaining judgment is classification against them, which
   the user's standing guidance routes to Sonnet. The brief tables only the
   rename, collision and roster rows and counts the keeps, to halve the
   report volume; arguable keeps are still tabled.
4. **Wave 1 landed as tabled** (f0968fa, bf1b606, 0830d49; total 3175
   before and after). Two things left for the cold review rather than
   fixed by hand: the renamed field lines keep their comment's old start
   column, so the comments no longer align with sibling fields; and the
   `Resolved` docstring reflowed from four lines to five, which the brief's
   rewrap clause allows.
5. **Wave 2 landed** (d02e01c, 641f3fa; gates green, total 3175). The
   agent found four call and docs sites the brief's table missed (`sim.jl`'s
   replay-header `scatter!`, a `devices.jl` docstring, two more
   `frame_walkthrough.md` lines) and renamed them the same way.
6. **The handle's `gather` is back at the spec's name** (the commit "Keep
   the handle's gather at the spec's name", gate green, 3175). The brief
   and the docs commit treated `gather(handle, snapshot)` as a private
   homonym, but §11.6 and the appendix's handle-capability list name it
   (`running`, `latest`, `wait_next_snapshot`, `stage!`, `binding`,
   `gather`, `report!`), and §11.6's `loop` example calls it. Renaming it
   is a spec change, which is the user's ruling, not a sweep's. The code
   conforms instead: the handle keeps `gather`, the reader-level method
   keeps `gather_reads`, the store level keeps `gather_cell`; `test/imports.jl`
   lists all three. The brief's premise, "one meaning, two dispatch
   types", still holds and is the argument if the user wants to rule the
   other way later (spec §11.6, the appendix list, D-244's entry, the
   diagnostic's message). The Naming section's example list
   (`gather_cell`, `gather_reads`, …) stays true as written.
7. **Wave 3 landed** (714635c, 9f00bff, a2ab1f0; gate green, total 3175).
   The brief's table missed a functional read site: `test/test_leaves.jl`'s
   `mgather`/`mscatter` helpers hardcode the symbols the mixed builders
   emit (`:buf1`, `:buf2`, `:offs`), so the store commit had to carry that
   test file too; the agent found it by the gate erroring, which is the
   check the brief relied on. `scatter_cell!`'s own parameter `v` was left
   as is, the table having scoped the value rename to `flatten!` and
   `flatten_state!`; a reviewer's call whether it should follow.
8. **A loose-fix candidate the sweep left**: `trim.jl` binds a local `off`
   for the out-of-tolerance residuals (lines 589, 592 at a2ab1f0), an
   abbreviation not on the roster that the `src/` sweep did not table. Not
   touched tonight; it belongs to a loose fix or the test wave's tail.
9. **The cold review** (Opus, at a2ab1f0): gate green, 3175, verdict "a
   sound pure rename". Findings sent to the fixer: a fourth
   `frame_walkthrough.md` line (239) still naming `run!(g.e, …)`; the
   field comments' columns (wave 1) and the continuation alignment under
   the lengthened calls (wave 2), both judged drift rather than the
   rewrap clause; `scatter_cell!`'s `v` following `flatten!`'s to `value`
   (ruling b, the reviewer's reasoning: R8 lists it, its builder changed).
   Left as is on the reviewer's advice: about thirty lines that grew past
   92 columns without exceeding their file's existing maximum; the next
   brief states the width in numbers. Rulings (a) and (c) confirmed: the
   handle's `gather` is spec-named and the final state is coherent; no
   spec-named field was renamed.
10. **Attribution trailers.** The eight wave commits carry a "Generated
    with AI" body and a Co-Authored-By trailer, added by the agents against
    the prompt's instruction (a harness reminder in their context asks for
    them). The user's rule forbids them. Nothing is pushed, so after the
    fixer lands the coordinator rewrites the local messages with
    `git filter-branch --msg-filter` over c07c201..HEAD, subject lines
    unchanged; the old tips stay in the reflog.
11. **A question the new function bullet raises, for the user**: the
    underscore twins `_gather(read_gather, snapshot)` (`bindings.jl`),
    `_report!`, `_stage!`, `_drain!`, `_reads` share an API name behind a
    prefix. Whether "never shares an API function's name" covers a
    prefixed twin is unruled; if it does, `_gather` appends its target.
    Not touched tonight.
12. **The fixer landed** all four fixes in one commit (gate green, 3175);
    seven files, not the six the prompt miscounted. The local history was
    then rewritten with `git filter-branch --msg-filter` to drop the
    trailers: trees identical (`git diff pre-reword HEAD` is empty),
    subjects unchanged, the old tip kept as the local tag `pre-reword`
    (delete it after the push). The hashes in entries 4–9 are the
    pre-reword ones; the reworded increment is c07c201..87f8798: cd46055,
    a435d73, 8f637c2 (fields), 7cec387, f596bc4 (functions), 83be85a (the
    handle's `gather`), 7f10e84, 424a14f, 3840294 (generators), 87f8798
    (the fix).
13. **`pending.md`'s bullet rewritten** to the `test/` wave alone, carrying
    the three loose ends tonight surfaced (the unnamed short fields,
    `trim.jl`'s `off`, the prefixed twins) so nothing lives only in this
    file.
14. **The reviewer's delta check** found one whitespace remainder in the
    fix, two continuation lines of `trace.jl`'s schedule-key diff call;
    landed by the coordinator as its own commit ("Align the schedule
    diff's remaining continuation lines", routed subset 678 green). The
    `src/` remainder is complete and verified at that commit.
15. **The `test/` survey launched** from that tip: eight Sonnet agents in
    parallel over the groups of `brief_naming_test_inventory.md`, reports
    in `docs/reports/20260924_naming_inventory_test/`.
16. **The survey landed** (27 reports, 2157 flagged, 519 renames, 10
    collisions) and was adjudicated in the test README's T1–T13. The
    rulings made alone, each with its reason in the README: `build` takes
    a qualifier wherever the scope calls `build` (Julia forbids the
    shadow); spec letters are never borrowed even for a glance; the device
    contract spells `dev`/`handle` everywhere; a sequential diagnostic or
    exception reuses `d`/`err` and numbered names collapse; `cond` never
    joins (`LinearAlgebra.cond` is live, as `diag` is) and a condition
    value is `authored`/`captured`/`plan` by role; `ref` is `reference`;
    a role suffix is a word. Three brief errata are recorded there, the
    largest being that the "fifteen `condition` locals" were keyword
    arguments.
17. **The sweep launched** in four sequential Sonnet waves per
    `brief_naming_test_sweep.md`, one commit per file, the gate on the
    shared files and once per wave.
18. **Sweep wave 1 landed** (3cd6429, 3a7b0c4, cfb326b, 75be96d, 8db9a36,
    4bb4352; gate 3175). T1 was amended in the README: a local assigned
    from `build(…)` can never be `build`, single call or not, because the
    assignment makes the name local for the whole scope. The agent also
    replaced `first`/`repeat` (Base names the package calls) with
    `initial`/`repeated` for two diagnostics compared together.
19. **Sweep wave 2 landed** (4c7bfc5, d8efeff, 2209d91, d3ed442, 4d73fc2;
    gate 3175). Two items handed to the cold review: `test_failures.jl`
    keeps an unflagged `simr` that T7 reaches, and one trailing comment
    moved to its own line where no split point existed. The agent also
    reverted its own over-reach: an ordinary `h = attach!(…)` local is
    judged by the glance clause, T3 covering contract signatures only.
20. **Sweep wave 3 landed** (544a855, aa39d42, bb55683, 6075c7c, 0f4e627,
    0da74bb; gate 3175). Beyond the rulings, the agent found and fixed two
    stale references the reports missed (a `resolve_condition(n, …)` call
    after `n` was renamed, a `warnings(d)` after `d` became `deployment`),
    and left `simp`/`simt`/`simb`/`simq` since T7's example list named
    only four letters. Wave 4 and the fixer sweep every `sim<letter>`
    under T7's principle. One comment was re-flowed over three lines to
    stay under 92 columns after a rename; for the reviewer.
21. **Sweep wave 4 landed** (732710f … 72fb355, ten commits; gate 3175 on
    each of the three shared files). No trailers on any of the 27 sweep
    commits. About a dozen `sim<letter>` locals survive across four files
    from every wave, T7's example list having been read as exhaustive; the
    cold review lists them for the fixer.
22. **The cold review of the test sweep launched** (Opus, range
    10620a4..72fb355).
23. **The test sweep's cold review** (Opus, at 72fb355): gate green, 3175,
    verdict "a clean pure rename" needing one fix commit. Findings: three
    tabled rows missed (`paths` in conditions, four `r` rows in discrete,
    one `m` in diagnostics); T4 applied unevenly in `test_failures.jl` and
    `test_build.jl` (numbered `err`s and role names for sequential
    values); `fb`/`cb` kept role names against T13; the `sim<letter>`
    sites of every wave; T2 sites the waves read as glance (`m` for a
    model, `m` for a rendered message, `h = attach!`); `ref` once; a
    dozen continuation lines not realigned and four formatting slips.
    Two questions the reviewer raised were ruled here: `s` for a snapshot
    in comprehensions and `r` for a trace record rename under T2 as
    written ("glance or not"), and the cross-file spellings unify
    (`no_policy`/`no_addrs`, `*_diagnostic`, `snapshots`). The agents'
    reading of the rewrap clause (a line already over 92 stays one line)
    is accepted going forward, wave 1's extra rewraps left as they are.
    The fixer is running with the full list.
24. **The fixer landed** all eight findings in one commit (0b28836, gate
    3175, nineteen test files). Two of its own slips it reports catching
    before the commit: a replace-all that briefly produced "snapshotshot"
    in comments, and a missed `s` comprehension in `test_trace.jl`; the
    reviewer's delta check covers both. `pending.md`'s bullet retired to
    the three loose ends (c910481).
25. **The reviewer's delta check** found five remainders in the fix, landed
    by the coordinator (e881761, gate 3175): the do-block `s` in
    `CadenceTests.jl` back to `s` (T8 keeps it; the fixer's prompt had
    overridden T8 by mistake); the two residue generators in
    `test_devices.jl` named `residue`, since `record` is the termination
    record in that file and the entries are not trace records; one
    continuation column and five over-long lines in `test_diagnostics.jl`;
    six continuation lines in `test_build.jl` one column right of their
    opener after the `err` collapse.
26. **Done.** The reviewer verified e881761 clean. Both increments are
    complete, reviewed and fixed; the gate is green at 3175 at the tip.
    Tonight's arc is c07c201..e881761, forty-eight commits; `git log
    origin/master..HEAD` shows 81 unpushed, the rest being the `src/`
    sweep from before this session. Nothing is pushed. For the morning:
    diff-review the arc, delete the local tag `pre-reword` after the
    push, and rule on the three loose ends the `pending.md` bullet now
    holds and on the handle's `gather` (entry 6) if the spec should move
    instead.
