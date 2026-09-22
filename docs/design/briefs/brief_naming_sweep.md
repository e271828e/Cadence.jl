# The naming sweep — descriptive names across `src/`

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`. Line
numbers in the survey's tables are those of `2844584`; `src/` is unchanged
since, and each stage's prompt names the tip it starts from. Never `cd`
elsewhere (`cd` is aliased to zoxide in the user's shell); use absolute
paths.

**Standing.** `pending.md:43–51` is the bullet this sweep retires: since
2026-09-21 a function parameter or a binding that outlives a few lines
carries a descriptive name, and single letters stay for the spec's
symbols, for a binding visible in one glance and for the component index
`ci`. Increment 48 applied the rule to what it touched. The naming survey
(`docs/reports/20260922_naming_survey/`, six slices at `2844584`, brief
`brief_naming_survey.md`) tabulated every single-letter parameter and body
binding in `src/`: 868 rows, 219 renames, 564 glance, 85 survivors, plus
the dispatch conventions covering about 170 more parameters. Its `merge.md`
fixes the tree-wide words where the slices differed and answers their
questions. **The sweep decides nothing.** Every new name is a survey row as
`merge.md` amends it, or a convention the survey states, or `merge.md`'s
own table. A name the tables do not give is not applied; it is reported.

**Six stages, one commit each, sequential**, in the order below, each a
fresh Sonnet agent over one slice's files. The stages share no file, so
each starts from the previous stage's tip. One Opus cold reviewer over the
whole arc at the end.

| stage | files | survey report | routed subset (`implementation.md`, "Running the suite") |
| --- | --- | --- | --- |
| A | `diagnostics.jl` | `a_diagnostics.md` | all of it (`diagnostics.jl` beyond a new kind) |
| D | `assembly.jl`, `declare.jl`, `leaves.jl`, `tracer.jl`, `show.jl`, and the fold | `d_authoring.md` | all of it (`leaves`) |
| F | `conditions.jl`, `readers.jl`, `trim.jl` | `f_services.md` | `readers conditions trim` |
| E | `dataplane.jl`, `roster.jl`, `bindings.jl`, `devices.jl`, `trace.jl` | `e_periphery.md` | `dataplane roster bindings devices trace lifecycle log` |
| B | `build.jl`, `executor.jl`, `store.jl`, `stepper.jl` | `b_build.md` | all of it (`compile`) |
| C | `sim.jl`, `localization.jl`, `deployment.jl`, and the bookkeeping | `c_loop.md` | all of it (`sim`, `deployment`) |

`implementation.md`'s "Running the suite" (125–178) is the one home of
test policy; this brief does not restate it. The gate is the reviewer's.

**Read, every stage:** `merge.md` in full, first; then your slice's report
in full; `pending.md:43–51`; `implementation.md`'s "Authoring caveats"
(63–124) and "Running the suite" (125–178); the file-table rows for your
files (16–42, your rows only). Read `spec.md:578–594` (the bundle letters)
if a survivor's status is in doubt. Nothing else in the docs.

---

## What a stage does

For each file in the slice, in the report's table order:

1. **Apply every `rename` row**, with the name `merge.md`'s tree-wide table
   substitutes where it names the role (a `c` component instance is `comp`
   whatever the row says; a `b::Build` is `build`; a `d::Decls` is `decl`;
   an exception is `err`; a count is `<thing>_count`; the snapshot log is
   `log`; the warnings list is `warnings`). Where `merge.md`'s "Questions
   answered" names a site, it wins over the row.
2. **Apply every convention** the report states as a rename (`diagnostic`
   for the `severity`/`path`/`message` family and the helpers a `message`
   body calls, `err` for the carrier accessors and `showerror`, `entry`,
   `rest`, `gated`, `chunk`, `body`, `stepper`, `bundle`/`addr`, `selector`
   for `_resolve_selector` and the two long `_resolve_read` methods). A
   convention the report classes as glance (`io`, the tracer's operand
   letters, `_exact`'s `v`, `==`'s `a`/`b`, `hash`'s `h`) is left alone.
3. **Touch no survivor and no glance row.** A glance row that sits inside a
   function you are editing stays a single letter. The one exception is
   `merge.md`'s own list (`_tarjan`'s outer `v`, `stepper.jl`'s `t₀`, the
   `at` helper's `S`).
4. **Rename every use, not the definition alone**: the body's reads and
   writes, string interpolations (`"$d"` becomes `"$(diagnostic)"`, `$(d.path)`
   becomes `$(diagnostic.path)`), keyword shorthand (`(; d)`), a closure that
   captures the binding, a quoted expression inside a `@generated` body or an
   `@eval` (`:( $d ... )`). Rename nothing in another scope that happens to
   use the same letter; a same-letter binding two functions down is its own
   row or its own glance.
5. **Update the prose that names the parameter**: a docstring or a comment
   that says `severity(d)`, `path(d)`, `message(d)` (the `Diagnostic`
   docstring at `diagnostics.jl:19–22` among them) says `diagnostic` after.
   Grep each file for the old letter inside backticks and parentheses in
   comments before committing.
6. **Leave alone**: struct fields, keyword-argument names, type parameters,
   exported names and everything in `test/imports.jl`, `test/`, and the
   multi-letter neighbours `merge.md` lists. A keyword call site `f(; d)`
   whose keyword is a parameter you renamed is not a keyword rename: the
   keyword name stays and the local changes (`f(; d = diagnostic)`).

**Stage D also folds `_at`**: delete `assembly.jl:72`; its six callers
(`300, 321, 378, 391, 400, 1163`) call `_at_path`; `diagnostics.jl:69`'s
parameter was renamed by stage A. After the fold `grep -n "_at(" src/*.jl`
returns only `declared_at(`, `path_at(`, `_walk_at(`, `_frame_at(`,
`_cells_at(` and their kin, never a bare `_at(`.

**Stage C also does the bookkeeping**: delete `pending.md:43–51` whole
(the "Naming sweeps" bullet; the "provenance" bullet after it loses its
last sentence, "After the naming sweep above."). Add to
`implementation.md`'s "Authoring caveats" one bullet, after the existing
last one:

> - **names.** A function parameter or a binding that outlives a few lines
>   carries a descriptive name. Single letters stay for the spec's symbols
>   (§5.2's bundle letters, the schedule's `D`, `Φ`, `h`, Appendix B's `K`,
>   `q`, `T`, `τ`, their decorated forms `t₀`, `h′`, `y_x`, `y_s`), for a
>   binding used within about five lines, and for `ci` and `io`. The tree's
>   words: `comp` the component instance, `decl` one component's `Decls`
>   beside the vector `decls`, `diagnostic` a diagnostic value, `err` an
>   exception, `entry` a structure's or an executor's entry, `build`,
>   `deployment`, `warnings` for those, shadowing the functions of the same
>   name where the body never calls them. The survey that fixed them is
>   `docs/reports/20260922_naming_survey/`.

Run `julia docs/design/tools/check_refs.jl` and `julia
docs/design/tools/check_rows.jl` after (read each tool's header for its
invocation). Grep `implementation.md`'s file table for `_at` and amend the
`assembly.jl` row if it names the deleted function.

## Rules for every stage

- Run the routed subset in the foreground with a 600 s timeout, under the
  sandbox flags "Running the suite" gives; never in the background. Never
  stash, reset or check out the working tree. Baselines come from `git
  show <tip>:<file>`.
- Edit with the tools, never with a blind `sed` over a file: a letter is a
  substring of every word. Each rename is a read of the function and an
  edit of its scope.
- A row whose site does not hold as described (the line moved, the letter
  is not there, the type differs) is not applied; it goes in the report
  with what was there instead. A single-letter binding you meet that is in
  no row and outlives a glance is likewise reported, not renamed.
- A stage that finds the suite red on a file it did not touch stops and
  reports the failing testset's name.
- Commit subject, one sentence: what changed. No body, no trailers.

## Report format

The commit hash and subject; the count of rows applied and of convention
methods renamed; every row not applied, with the reason; every
single-letter binding met that no row covers; the suite's result line and
wall time; handoff notes for the reviewer, one line each.

## For the reviewer

Opus, over `git diff <tip before stage A>..<tip after stage C>`, with
`--word-diff` per file. The gate as "Running the suite" gives it. Then:

1. Every changed token pair is an old letter and the word a row, a
   convention or `merge.md` gives it, or the fold, or the two bookkeeping
   edits. Anything else is a finding.
2. No survivor row and no glance row was renamed, except `merge.md`'s three.
3. Every rename reached every use: grep each renamed function's body for
   the old letter as a whole word (`\bd\b`) and read the hits; a leftover
   is a `UndefVarError` the suite may not reach.
4. Prose: `grep -n '\`d\`\|(d)\|\`e\`\|(e)\|\`c\`\|\`b\`' src/*.jl` and read
   the hits for a docstring or comment still naming the old parameter.
5. `grep -n "_at(" src/*.jl` returns no bare `_at(`; `assembly.jl` defines
   no `_at`.
6. `pending.md`'s bullet is gone whole; the caveat bullet is verbatim;
   `check_refs.jl` and `check_rows.jl` are OK.
7. One probe script in the scratchpad that builds `MultiRate`,
   `feedback_model` and `Pendulum()`, runs each a few frames through
   `Simulation`, and compares `repr("text/plain", build(...))` against the
   same at the pre-sweep tip (`git show <tip>:src/show.jl` is not needed;
   the rendering constants in `test/test_show.jl` are the reference). A
   rename changes no output.
