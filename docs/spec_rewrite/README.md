# The spec's readability rewrite

Work in progress on rewriting `docs/design/spec.md`, chapter by chapter, for
readability with no loss of content. The steps are in
[recipe.md](recipe.md), and the convention is in
`docs/design/tools/spec_style.md`.

- `checks/` holds the tools every chapter shares.
- A chapter's working files live in `chNN/` and are committed as the work
  goes.
- Once the chapter has landed and its second track is done, its lessons go
  into the recipe and a commit deletes `chNN/`. The table records the last
  commit that held the files, so any of them comes back with

  ```
  git show <commit>:docs/spec_rewrite/chNN/<file>
  ```

- When the whole spec is done, one report goes to `docs/reports/` and this
  directory is deleted.

## Status

| part | state | landed in | files |
|---|---|---|---|
| Front matter and Part roadmaps | not started | | |
| 1. Introduction | not started | | |
| 2. Formalism | not started | | |
| 3. Component taxonomy | not started | | |
| 4. Ports and signals | not started | | |
| 5. Evaluation order and feedthrough | not started | | |
| 6. Composition: connections, aggregation and hierarchy | not started | | |
| 7. State and data representation | done | `1cb6716` | |
| 8. The declaration layer: components and assemblies | done | `ef7f5dd` | `d268d39` |
| 9. The build pipeline | done | `9a7d84f` | `docs/reports/20261001_chapter9_rewrite/` |
| 10. Time and execution | done | `3d72f03` | `0f9ce8a` |
| 11. Runtime periphery: the data plane | not started | | |
| 12. Runtime periphery: lifecycle and orchestration | not started | | |
| 13. Error discipline | not started | | |
| 14. Stopped-sim services | not started | | |
| Appendices A to D | not started | | |

## Carried to later chapters

Doubles and pointers chapters 7 and 8 found in chapters not yet rewritten. Each
chapter's rewrite settles its own:

- **Chapter 3.** §3.4's lead-in "Algebra removes the reset." bolds D-056's
  first bullet, which §8.6 bolds.
- **Chapter 3.** §3.1 calls continuous state "an isbits struct of real
  scalars" and §3.2 calls discrete state "any isbits value", both citing §7.
  §7.1 states a flat NamedTuple of real scalars and `SArray`s, and §7.3 a
  value whose fields are isbits or a `Symbol` (D-231).
- **Chapter 5.** §5.3 states D-252 under a **Rule.** label; §8.3 bolds it.
- **Chapter 6.** §6.1 bolds "for a continuous consumer only", the walk
  clause's tier scope that §8.2 bolds (D-295).
- **Chapter 11.** §11.6 calls §8.1's shadowing check "the reflection class",
  a name §8.1 never uses.
- **Chapter 11.** §11.8 scopes the zero-allocation invariant to "the model
  sweep", where §7.5 says "the stepping loop" (D-305).
- **Chapter 14.** §14.4 says a discrete `s` field "is any isbits value"
  (§3.2). §7.3 admits isbits or `Symbol` fields (D-231).
- **Chapter 14.** §14.10 bolds seedability and states the tap rejection,
  both of which §8.2 states (D-295, D-296).

Chapter 9 predates this directory. Its files stay in its report, with the
§9.4 trial in `docs/reports/20261001_spec_rewrite_sample/`.
