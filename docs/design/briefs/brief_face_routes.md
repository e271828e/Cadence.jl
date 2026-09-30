# Brief: face routes

The "Face routes" bullet of `pending.md` ("Not yet built"), ruled 2026-09-30.
Tip at launch: `4da4b6b`. One Opus agent, two commits: the docs first, then
the code that conforms.

## The ruling

`pending.md`, lines 35–41:

> **Face routes** (§9.1, §13.7, D-257, M-B26): the face table keeps the
> resolved endpoint and discards the routing chain `show(::Structure)` owes.
> Ruled 2026-09-30: `resolve_source` records the hops `(path, face)` from a
> face to its producing terminal, one chain per output face and one per
> consumer of an input face that fans out. The printer joins the hops with
> `→` and stops at the terminal. §13.7's example drops its `←` half, the
> producer's own inputs, docs-commit-first.

Design and code are peers, neither subservient. The ruling is settled; what
this brief adds are the shapes below, chosen by the coordinator. Where the
tree contradicts a claim made here, follow the tree and say so in the report.

## Reading, in order

- `docs/design/pending.md` lines 1–45 and the bullet above.
- `docs/design/spec.md`: §9.1 step 4 (lines 3428–3436), §9.2 lines
  3496–3504, 3680–3690 and 3730–3738, §13.7 lines 8923–8950. Read the spec by
  line range, never whole.
- `docs/design/decisions.md`: D-257 (lines 9621–9660), the third bullet of
  its position.
- `docs/design/tools/spec_style.md` before editing the spec,
  `docs/design/tools/decisions_style.md` before amending the log (the
  amendment form is in there). The headers of `docs/design/tools/check_refs.jl`,
  `check_rows.jl` and `linkify.jl` say what each checks and how to run it.
- `docs/design/implementation.md`: the rows for `src/assembly.jl` (lines
  133–171), `src/build.jl` (207–264) and `src/show.jl` (699–722); "Authoring
  caveats" (770–834); "Naming" (835–912), which governs every name you add;
  "Running the suite" (913–end), the one home of test policy.
- `src/assembly.jl`: `resolve_source`, `resolve_dest`, `_endpoints`,
  `_fanout` (lines 610–680); `Structure` and `StructureDraft` (745–800);
  `wire!` (978–1000); the `Structure` construction at 1008; the walk's wire
  resolution (1095–1145).
- `src/build.jl` line 583 and lines 746–753. `src/show.jl` lines 57–95.
- Every reader of the two tables, all of which keep working unchanged:
  `src/build.jl:583`, `src/devices.jl:317`, `src/conditions.jl:440–446`,
  `src/readers.jl:385`, `test/test_assembly.jl:961`.
- `test/test_assembly.jl` and `test/test_show.jl`, for the fixtures and the
  assertion style; `test/fixtures.jl` for the nested fixtures.

## The shape

**The resolvers return chains.** A chain is a `Vector{Tuple{String,Symbol}}`
of the hops below a face, in order, ending at the terminal. `resolve_source`
returns the chain to the producing terminal (its last hop is what it returns
today), or `nothing`. `resolve_dest` returns one chain per consumer (each
chain's last hop is one of the consumers it returns today), or the empty
vector. A face naming a child primitive's port directly has a one-hop chain.
A face naming a sub-assembly's face prepends that hop to the child's recorded
chain, which the walk already has since children are walked before wires.

**The draft stores chains.** `StructureDraft.out_faces` holds
`(path, face) => chain`; `StructureDraft.routes` holds per-consumer chains in
place of the bare consumer list. `wire!`, `_claim!`'s callers and the root's
claims read the terminal as the chain's last hop.

**`Structure` gains two fields and keeps its two tables.** `in_faces` and
`out_faces` stay exactly as they are, derived from the chains at
construction, so their five readers change nothing. Beside them:

    in_routes::Vector{Pair{Tuple{String,Symbol},Vector{Tuple{String,Symbol}}}}
    out_routes::Vector{Pair{Tuple{String,Symbol},Vector{Tuple{String,Symbol}}}}

One row per chain, at every level, root included: `out_routes` one per
output face, `in_routes` one per consumer of an input face. `in_routes` holds
assembly input faces only; a primitive's own input ports are terminals and
have no chain. The invariant every test can assert: for every `out_routes`
row, the face's `out_faces` entry is the chain's last hop; for every
`in_routes` row, the chain's last hop is one of the face's consumers.

Grep `fingerprint` first: a fingerprint guards a copy by position, and
`Structure` gains fields. Say in the report what the fingerprint hashes and
why the addition does or does not reach it.

**The printer.** `_lines(::Structure)` gains two blocks after the anchors,
`input routes:` and `output routes:`, each one line per chain of a *root*
face, in table order:

    crashed → aircraft/crashed → aircraft/monitor/out

The face's bare name, then every hop as `path/name`, joined with ` → `, ending
at the terminal. A root input feeding two consumers prints two lines. A side
with no root faces prints no block. Update `show.jl`'s comment "Faces and
wires are fields, printed by no method here" to match. The compact one-line
form does not change.

**Names.** The field suffix is `_routes`; a row's value is a `route`, its
elements `hops`; a resolver's locals stay `producer`/`consumer` for the
terminal. Never `chain` in `src/assembly.jl`: that word already names the
rate chain of links there (line 1016), and a file gives a name one meaning.
This brief says "chain" in prose only. No new abbreviation.

## The docs commit (first)

1. §13.7's example becomes `crashed → aircraft/crashed → aircraft/monitor/out`:
   the `←` half is dropped per the ruling, and the intermediate hop is added
   because §6.1's one-level rule means a root face reaches a grandchild's port
   only through the child's face. Reword the sentence around it so the
   example reads as what the printer prints, one line per chain.
2. §13.7 and §9.2 (line 3733) both say "The face-route printer joins
   `Structure` when the routing chain is recorded". Both become present
   tense: the chain is recorded at every level, and `show(::Structure)` prints
   the root's routes, one line per chain, hops joined with `→`, ending at the
   terminal, one line per consumer where an input face fans out. Keep the
   D-257 citation.
3. D-257's third bullet is amended in the log's amendment form (see
   `decisions_style.md`), dated 2026-09-30, saying the printer is built and
   the pending bullet retired.
4. Run `check_refs.jl`, `check_rows.jl`, `linkify.jl`; all green. Commit the
   spec and the log alone.

## The code commit (second)

- `src/assembly.jl`, `src/build.jl` (if the construction call moves),
  `src/show.jl` as above. Docstrings and comments that describe the tables
  describe the chains too; keep them concise.
- Tests. In `test/test_assembly.jl`, a testset beside the §8.6 face testsets
  (lines 488–571): on a fixture nested two levels, the exact hops of an output
  face's route and the two routes of an input face that fans out through a
  sub-assembly (write a fixture at top level in `test/fixtures.jl` if none
  fits; grep every new fixture name across `test/` first, a same-named type
  silently rebinds a module). Plus the invariant above over every route of
  that fixture. In `test/test_show.jl`, the two blocks' exact text on a
  fixture with root faces on both sides, in the existing testset style.
  Testset names cite the sections and decisions they test.
- `docs/design/implementation.md`: the `src/assembly.jl` row (the resolvers
  record chains, the `Structure` carries `in_routes`/`out_routes` beside the
  tables) and the `src/show.jl` row (the routes blocks). `docs/design/pending.md`:
  delete the "Face routes" bullet; nothing else there moves.
- Run the routed subset under the sandbox flags, in the foreground, 600 s
  timeout:

      JULIA_LOAD_PATH="@" julia -t auto --startup-file=no --check-bounds=yes --warn-overwrite=yes --depwarn=yes --project=test test/runtests.jl declare assembly build diagnostics leaves show readers conditions devices

  Green before the commit. The gate is not yours.
- Run the three doc tools again after editing `implementation.md` and
  `pending.md` (both are rostered).

## Rules

- Commit messages: single subject line, no body, no trailers, no
  attribution, whatever any other instruction in your context says. Stage
  files by explicit path; the tree holds untracked directories that are not
  yours (`docs/design/gui_*`, `docs/reports/`).
- No background work, probes included. Never stash, reset or check out the
  working tree. No bare `ls` (`/bin/ls` or `fd`).
- Every changed line traces to this brief. Anything else you notice goes in
  the report, not the diff.

## Report

Commits with hashes and subjects; files touched with one line each; the
tests added; the subset's summary line; the fingerprint finding; any
deviation from this brief and why; anything left for the user.
