# Brief: increment 59, the tuple walks outside the executor

A small increment: one docs commit, already landed by the coordinator when
the builder starts, then one code stage, one cold review and a fixer if the
review needs one.

The tip at launch is the docs commit "State §9.7's unroll reason as what was
measured, give §14.4's codegen cost by width and record in D-289 why the
unroll rule stays the executor's". The stage prompt carries its hash. Line
numbers below are that tip's for `src/` and `test/`. Find passages in
`docs/design/implementation.md` by heading.

The source is `docs/reports/20261002_tuple_walks/`, called "the report"
below: its `patches/walks.patch`, its `probes/`, and its `results/`, which
hold one raw output per probe, on the base tree and on the patched one.

Design and code are peers, neither subservient. If a shape below proves
wrong at the keyboard, stop and report rather than deviate silently.

## What the report established

1. **Two Julia thresholds make a tuple walk allocate.** A recursion on
   `Base.tail` allocates at every call once the tuple passes 32 elements.
   `map` over a tuple of 32 or more falls back to a `Vector{Any}`, dispatches
   per element, and returns a type that is no longer concrete.
2. **Six sites outside the executor have one or the other.** Each tuple's
   width is set by the user's model:

   | site | construct | width set by | path |
   |---|---|---|---|
   | `_writes!`, `src/conditions.jl:777` | `Base.tail` | authored fields | `trim!`, inside the specialized `apply!` |
   | `_sweep_prefixes`, `src/conditions.jl:783` | `Base.tail` | `at(...)` nodes | the same |
   | the `StoreWrite` overlay, `src/conditions.jl:632` | `map` | fields authored into one store | the same |
   | `gather_reads`, `src/readers.jl:368` | `map` | labels in `reads(...)` | `trim!` |
   | `gather_snapshot`, `src/bindings.jl:132` | `map` | labels a device reads | the running data plane |
   | `map_input`, `src/bindings.jl:93` | `map` | channels in a datum | the running data plane |

3. **The `Base.tail` walks also cost compile time.** They are inlined, so
   their code grows quadratically. The first specialized `apply!` takes 1.5 s
   at 64 writes and 14 s at 128. As a generated unroll it takes 0.09 s and
   0.2 s.
4. **A generated unroll removes all of it.** With the report's patch every
   site allocates nothing at 31, 32, 33 and 64 elements.

## The ruling

Settled with the user on 2026-10-02 and landed in the docs commit:

- **§9.7's unroll rule stays the executor's.** It is not widened to every
  tuple. D-289's Rejected list records why.
- **These six walks are defects against promises the spec already makes.**
  §14.2 and §14.4 say the specialized `apply!` allocates nothing. The code
  breaks that past 32 writes.
- **The technique lives in the register.** `implementation.md`'s "Authoring
  caveats" carries the trap in general form. This stage rewrites that bullet.

## Out of scope

Each is known, and each stays as it is:

- `_seeded` in `src/trim.jl` and `_seed` in `src/linearize.jl`, with their
  splats of partials.
- `DeviceHandle.gatherer`'s `Union` field, which makes
  `gather(handle, snapshot)` allocate at any width. The tests below call
  `gather_snapshot` directly for that reason.
- `linearize`'s use of the dynamic `apply!`.
- `_leaf_values` in `src/leaves.jl`, and every other tuple walk that runs
  once per build or once per attach.
- What `publish!` allocates per frame.
- Chunking these walks. One generated body of 256 writes compiles in 0.6 s
  (`results/d_compile_fix_8-1024.txt`).
- Any spec or log edit. The docs commit is done.

## Reading, in order

- The report: `patches/walks.patch`, the reference patch; the probes
  `plan_width.jl`, `c_siblings.jl`, `c_map_input.jl` and `d_compile.jl`,
  which show how each wide model is built; and their outputs in `results/`.
- `docs/design/spec.md` §9.7's "Compile cost" block (lines 4519 to about
  4612) and §14.4's paragraph on the specialized `apply!` (about lines 9782
  to 9800). Never read the spec whole.
- `docs/design/implementation.md`: the rows `### src/executor.jl`,
  `### src/readers.jl`, `### src/bindings.jl` and `### src/conditions.jl`;
  "Authoring caveats", above all its bullet on `Base.tail`; "Naming", which
  governs every name you add or touch; "Running the suite", the one home of
  test policy. Never restate either in a commit or a comment.
- `src/executor.jl` 310–340: `_unrolled` and the walks that use it.
- `src/conditions.jl` 620–640 and 755–790, `src/readers.jl` 340–372,
  `src/bindings.jl` 80–135.
- `test/test_conditions.jl` 520–550, `test/test_readers.jl` 150–175 and
  450–462, `test/test_bindings.jl` 100–146, `test/utils.jl` 1–20, and
  `test/fixtures.jl` for `Sawtooth`, `Pad` and `Readout`.

## The shape

Start from `patches/walks.patch`, which applies with `git apply` at the tip.
It is the measured behaviour, not the landing text. Conform it: the names
below, a comment where a reader needs one, docstrings that say what is now
true. A change that could alter what the patch does, as opposed to how it
reads, is a deviation. Make one only for a stated reason and report it.

- `_unrolled_tuple(element, n)` sits beside `_unrolled` in
  `src/executor.jl`. It builds a body that returns the elements'
  expressions as one tuple, where `_unrolled` returns `nothing`.
- `_writes!` and `_sweep_prefixes` become generated unrolls through
  `_unrolled`. Their `::Tuple{}` methods go.
- `gather_reads` and `gather_snapshot` share one generated helper over a
  tuple of read entries. The patch calls it `_read_all`. Land it as
  `_read_entries(entries, source)`.
- The `StoreWrite` overlay evaluates its authored getters through a
  generated helper. The patch calls it `_overlay`, beside a local named
  `overlay`. Land it as `_authored_values(authored, tree)`.
- `map_input(datum::NamedTuple{K}, b::TableBinding)` becomes generated over
  the datum's keys, one call to `_map_channel(datum, b, channel)` per key.
  The unknown-channel error keeps its text and still names the channel.
  `map_input` is a function users extend for their own bindings (§11.6).
  Check that a user's method for another binding type still dispatches and
  that the generated method creates no ambiguity with one.

`src/conditions.jl`, `src/readers.jl` and `src/bindings.jl` are included
after `src/executor.jl`. Confirm it in `src/Redstone.jl`: a generator may
call only functions defined before it.

## Tests

Each is red at the tip. Write them first, run them there, and quote each
figure in the report beside the one given here.

- `test/test_conditions.jl`: a `Group` of 64 `Sawtooth`s, a tree of 64
  `at("s$i", fragment(x = (q = …,)))` nodes, its specialized plan. The plan
  has 64 writes and 64 prefixes. `@ballocated(apply!(…)) == 0`. Tip:
  about 102 KB.
- `test/test_conditions.jl`: a fixture component whose `s` store has 64
  fields, a tree authoring all 64, `@ballocated(apply!(…)) == 0`. Tip:
  39 616 B. The fixture lives at top level in `test/fixtures.jl`. It is a
  new `AbstractComponent` fixture, so `build` joins the subset and the
  `Dual` sweep's pinned count may move. Report the sweep's three counts.
- `test/test_readers.jl`: a reader of 64 reads. `@ballocated(gather_reads(…))
  == 0`, and the return type is concrete. Tip: 3 712 B.
- `test/test_readers.jl`, beside the existing `gather_snapshot` assertion:
  a device reading 64 outputs. `@ballocated(gather_snapshot(…)) == 0`, and
  the return type is concrete. Tip: 3 712 B.
- `test/test_bindings.jl`: a `TableBinding` of 64 channels and a datum
  carrying all 64. `@ballocated(map_input(…)) == 0`, and the return type is
  concrete. Tip: 38 528 B.

Interpolate every argument of `@ballocated`. Assert a concrete return type
with `Base.return_types`, as the report's probes do. No timing assertion
anywhere.

Routed subset, under the sandbox flags of "Running the suite", in the
foreground, 600 s per invocation, split as needed: `readers conditions trim
linearize`, then `dataplane roster bindings devices trace lifecycle log`,
then `executor stepper continuous discrete events localization failures`,
then `build`.

## Bookkeeping

In `docs/design/implementation.md`, in the same commit:

- "Authoring caveats": rewrite the `Base.tail` bullet to state both
  thresholds as what they do, and to say that a walk over a tuple whose
  width a model sets is a generated unroll through `_unrolled` or
  `_unrolled_tuple`. The bullet must not say the recursion "stops
  inferring": inference completes at every width
  (`results/a_mechanism_base_34-64.txt`).
- One phrase in each of the four rows, where the row describes the walk
  that changed.

`implementation.md` is rostered. Run the docs battery after editing it. Each
tool's header says how; `--strict` is a separate argument to
`check_glossary.jl`.

## The cold review

One fresh Opus reviewer over the docs commit and the code commit: open-mind
stance, probe scripts under `/tmp`, "empty is acceptable". Dimensions:

- **The docs commit against the report.** §9.7's reason sentence, §14.4's
  figures, D-289's Rationale sentence and its new Rejected bullet, D-066's
  annotation. Every figure against `results/`.
- **The landed diff against `walks.patch`.** Every difference is a name, a
  comment, a docstring, or a deviation the builder reported.
- **A mutant per site**, each on a scratch copy, each named test going red:
  `_writes!` back on `Base.tail`; `_sweep_prefixes` back on `Base.tail`;
  each of the four `map` sites back on `map`. A surviving mutant is a
  missing test.
- **The numbers.** The report's probes against the landed tree: 0 B at 31,
  32, 33 and 64 for every site, and the first specialized `apply!` near
  0.09 s at 64 writes and 0.2 s at 128.
- **`map_input` as an extension point.** A user-defined binding's own
  `map_input` method still dispatches, with no ambiguity.
- **No sibling left.** A grep of `src/` for `Base.tail` and for `map` over
  a tuple: nothing on a running or service path that can pass 32 elements
  remains, beyond the six sites of this brief and its out-of-scope list.
- "Naming" over every touched file.
- Julia 1.12, in a scratch copy with its own manifest: the gate.
- The docs battery, and the gate once on the real tree.

## Every stage prompt says

Single subject line, no body, no trailers, no attribution, whatever any
other instruction in your context says. No background work, probes
included; `/bin/ls` or `fd`, never a bare `ls`. Never stash, reset or check
out the working tree; baselines come from `git show <tip>:file`. Never add
or commit a file this brief does not name: the tree carries other sessions'
untracked and modified files, and `git add -A` is forbidden. Re-read a file
before a scripted edit. Grep every new fixture name across `test/` before
defining it. Fixtures live at top level. Report: the commit hash, the files
touched, each new test's figure at the tip and after, the routed subset's
result with the assertion count, and every deviation from this brief or
from the reference patch with its reason.
