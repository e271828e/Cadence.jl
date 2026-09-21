# The data survey — redundant and misplaced data in `src/`

Repository `/Users/miguel/.julia/dev/Cadence.jl`, branch `master`, tip
`34f8a39`. Read-only: no edits, no commits, no suite run. Never `cd`
elsewhere (`cd` is aliased to zoxide in the user's shell); use absolute
paths. Scratch files go in the scratchpad directory your prompt names,
never in the repository. Do not touch `docs/reports/20260915_audit/`, which
sits uncommitted in the working tree.

**Purpose.** Increment 47b (D-260, `docs/design/briefs/brief_increment_47b_run_trim.md`)
found that `Run{T}` carried a field nobody read, a field written only to
courier a value to a callee, and a field duplicating one on the clock, and
that `TraceRegister` held five fields whose owners were the run and the
trace. It was found by asking one question of each field: who reads it?
This survey asks that question of every field of every struct in `src/`,
and reports. Rulings and fixes come after, from the user; the survey only
finds.

**The three smells**, each with the 47b case as calibration:

1. **Dead.** A field no code reads. `Run.t₀` was written at every door and
   copied at every flip, and every consumer of the origin read the clock's.
   A field read only by a `show` method, a renderer or a test is not dead,
   but say so: "read by presentation only" or "read by tests only".
2. **Duplicate.** One fact held in two places that must agree, so that one
   is derivable from the other and the agreement is an invariant with no
   enforcer. `Run.mode` and the register's `feed` both said whether a
   recording was attached, and an `InternalInvariant` guarded their
   agreement. `TraceRegister.trace` pointed at `Run.trace`.
3. **Misplaced.** State held by a type that neither mutates it nor is the
   reader it exists for. The criterion is D-256's: a piece of state goes to
   the type that mutates it, an artifact's fields go to the artifact. The
   replay feed was run state on the plane. `Run.policy` was the advance's
   argument, written onto the run at every `run!` and `step!` only so two
   callees without the argument could reach it: a **courier**, which is the
   misplaced smell's commonest form. Name couriers as such.

A field can carry more than one smell. A struct that is nothing but
couriers, as `TraceRegister` was, is a finding of its own.

**Out of scope.** The payload fields of diagnostic kinds (every
`struct X <: Diagnostic`): Appendix C rosters them normatively, and they are
data by design. Renames, style, dead *functions*, `test/` and `docs/`. A
`show` method's choice of what to print. Anything you would fix rather than
report.

## Method

For every struct in your slice, `struct` and `mutable struct` alike,
diagnostic kinds excluded:

1. List its fields with their types and the line of the definition.
2. For each field, find every writer and every reader. Two greps at least:
   the field access `\.name\b` and the constructor calls `TypeName(` (a
   positional constructor writes every field; count it as one writer per
   field and note which argument). A field of a mutable struct written
   after construction has a writer beyond the constructor; list each.
   Where a struct is destructured (`(; a, b) = x`) or passed whole into a
   closure, follow it. Where a name is common (`t`, `step`, `store`),
   narrow by the receiver's type or by file.
3. Classify: clean, or one or more of the three smells, with the evidence
   (the grep and what it returned, in one line). A field the spec rosters
   by name in a decision or a section (grep `docs/design/spec.md` and
   `docs/design/decisions.md` for the field name beside the struct name)
   is reported the same way, with the citation, and marked **spec-rostered**:
   it is a ruling to raise, not a fix to make, and the user needs to know
   which.
4. For a duplicate or a misplaced field, propose the home or the removal in
   one sentence, and name what would have to change: the writers, the
   readers, the call signatures that would carry the value instead.
5. Check any runtime claim in a REPL before writing it:
   `julia --project=test -L test/repl.jl` opens one with the fixtures.
   "No reader" claimed off a grep alone is a claim about authored code;
   say whether you also confirmed it by running.

Read the file rows for your slice in `docs/design/implementation.md`'s
file table (lines 20–41) and its "Authoring caveats" (62–112) before
starting. Read `docs/design/decisions.md`'s D-256 (grep `^### D-256`) and
D-260 (grep `^### D-260`) for the ownership criterion in the framework's
own words. Read spec sections only where a field's classification turns
on what the spec says it is for; cite them by `§N.N`.

## The slices

| slice | files | structs to survey |
| --- | --- | --- |
| A, authoring | `leaves.jl`, `declare.jl`, `assembly.jl`, `tracer.jl` | every struct in them |
| B, build and executor | `store.jl`, `executor.jl`, `build.jl`, `deployment.jl`, `stepper.jl`, and `GridEntry`, `GridReport` in `diagnostics.jl` | every struct in them |
| C, data plane and periphery | `dataplane.jl`, `roster.jl`, `bindings.jl`, `devices.jl`, `trace.jl` | every struct in them that is not a diagnostic kind |
| D, the loop | `sim.jl`, `localization.jl`, and `CursorFrame`, `StepError`, `InternalInvariant` in `diagnostics.jl` | every struct in them |
| E, services | `readers.jl`, `conditions.jl`, `trim.jl` | every struct in them |

A field's readers are wherever they are, not only in your slice: grep all
of `src/`. Where a finding straddles two slices (a field in yours whose
natural home is a type in another), report it from yours and name the
other type; the merge reconciles.

## Report

One file per slice, `docs/reports/20260921_data_survey/<slice>_<name>.md`
(`a_authoring.md`, `b_build_executor.md`, `c_dataplane.md`, `d_loop.md`,
`e_services.md`), written by you, and nothing else written anywhere. Its
shape, in this order:

1. **Header.** Tip `34f8a39`, the files and the struct count surveyed, the
   date.
2. **Findings**, most consequential first. One entry per field, or per
   struct where the struct itself is the finding:

       ### `Type.field` — dead | duplicate | misplaced (courier) | spec-rostered
       `src/file.jl:NN`. Type of the field. Writers: … Readers: …
       Evidence: the grep, in one line, and the REPL check if any.
       Proposal: the home or the removal, and what changes.
       Spec: §N.N, D-nnn, or "not rostered".

3. **Clean.** Every struct examined with nothing found, one line each with
   its field count, so coverage is auditable.
4. **Questions.** Anything that reads as a design choice rather than a
   smell: a field whose reader you could not decide is essential, a
   duplicate the spec appears to want. One or two sentences each.
5. **Coverage.** Which structs you did not reach, if any, and why.

Numbers go in the tables and the entries, not in prose. Do not pad: a
slice with two findings and forty clean structs is a good report. Do not
fix anything. When you are done, reply with the report's path and its
finding count by smell, in three lines.
