# Notes: increment 66, the run of 2026-10-08

The coordinator's rulings, each with its reason, and the open points left
for the user. Nothing here is pushed.

## The arc

| commit | what |
| --- | --- |
| 0d72ee4 | the brief rebased at increment 65's tip |
| 3f37aa5 | stage 1: `pack`, `Pack{V, N}`, `Unpack{V, N}` with `unpack_names` |
| 6b8f391 | stage 2: `Switch{V}`, `Source{V}(f)`; the tranche bullet of `pending.md` retired |
| f65824d | the review fixes (rulings 11 and 12) |

Routed subsets green at both stages (1370 and 1456 assertions) and after the
fix (1458); the cold reviewer's gate green at 6b8f391 (5396, Julia 1.13.1);
docs battery green after every docs edit. All seven of the brief's mutants
went red on a scratch copy; every re-probed number matched the brief.

**What is left for you:** the diff review of the arc (0d72ee4..f65824d) and
the push, together with increment 65's eight unpushed commits.

## Rulings made

### The rebase (0d72ee4)

1. **The generated helper is `unpack_names`, not `output_names`.** At rebase
   time "Naming" forbade a local sharing any package function's name, and
   `output_names` is a local of `src/assembly.jl` twice. The rule was then
   scoped to the functions a module sees (6ea5cce, landed between the brief
   and stage 1), which would have freed `output_names`; the more specific
   name stays.
2. **Increment 65's `fed_by(src, c)` replaces two of the brief's models**, the
   unpack model and both source-into-integrator models, which were that exact
   shape under other child names. Reason: the 65 reviewer flagged the same
   duplicate.
3. **The time source's section sits after the noise source's**, before the
   continuous dynamics, so the two sources sit together. Increment 65 had
   inserted two sections where the brief said "after the leaf blocks".

### Stage 1 (3f37aa5)

4. **The test file's header comment names the pack and the unpack.** The
   brief did not ask; the list would otherwise have gone stale.
5. **The round trip's `Dual` build is asserted**, which the brief's probed
   values claim and its test list omitted.

### Stage 2 (6b8f391)

6. **The inventory's port-name sentence** ends "and `out1…outN` where a
   block splits one port into `N` alike". The brief's "for a block with
   several outputs" was loose: `LimitedIntegrator` publishes `out` and
   `saturation`.
7. **The allocation testset is named for the sources too**, "the structure
   blocks' and the time source's phase bodies allocate nothing".
8. **`has_stage` is asserted on `Switch` and `Source`**, the reviewer's stage
   dimension made a test; the flip model's `Dual` build likewise.
9. **The cycle model's fold is `v -> v > 0`**, since `x` is the state letter
   in `test_blocks.jl`.
10. **The stepped read of `Source(t -> 2t)` is not asserted**; the exact
    `out == sin(1.0)` covers stepped time.

### The cold review and the fix commit

The reviewer's verdict: pass, three nits, nothing blocking.

11. **`has_stage` is asserted on `Pack` and `Unpack` too**, completing the
    reviewer's "stage of each" dimension. Landed by the coordinator.
12. **The inventory sentence reads "into `N` ports alike"**, the reviewer's
    plainer wording for ruling 6. Landed by the coordinator.
13. **`Source`'s docstring keeps "under every activation"** although a nested
    `Dual` activation, which no shipped activation is, would hand `f` an
    inner `Dual`. `Freeze` strips one level under the same wording, so the
    claim matches the precedent.
14. **The `### src/blocks.jl` row's "Spec:" line gains neither §5.3 nor
    §11.3**, which the new docstrings cite. The line names the sections the
    constructs answer to, not the docstrings' cross-references; the file's
    docstrings already cite §5.3 ten times with the line leaving it out.

## Open points for the user

- The brief's "Names" bullet still calls `output_names` forbidden; the
  Naming amendment 6ea5cce made it legal in `Blocks`. Briefs stay untouched
  until the first release, so it is left as is.
- `test/test_blocks.jl`'s header comment lists the blocks in an order that
  follows neither the testsets nor `src/`; it predates the increment.
- `pending.md`'s "The library's remaining candidates" names only
  `Delay{V, K}`; the struct `Freeze` is covered by its "whatever of the
  inventory is unbuilt" clause, not by name.
