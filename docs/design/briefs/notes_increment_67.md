# Notes: increment 67, the run of 2026-10-08

The coordinator's rulings, each with its reason, and the open points left
for the user. Nothing here is pushed.

## The arc

| commit | what |
| --- | --- |
| 1c7b234 | the brief rebased at increment 66's tip |
| f913f57 | stage 1: `Child`, `LevelEntry`, `levels`, `terminal_producer`, `face_routes`, `membership`, beside the tables |
| 7ab9782 | D-315 annotated: the alias pass enters assembly output faces only (ruling 4) |
| ab2f5f0 | stage 2: every reader a call; the primitive root's row; the output-only alias pass |
| 5c03276 | stage 3: the tables, `root`, `child_lists` and `conns` gone; the fourth specialization case; the bullet retired |
| 187edda | the stale `show.jl` comment, landed by the coordinator |
| d6ffacf | `pending.md`: the `UnconnectedInput` hand-up chain, the user's request |
| d16bb80 | `pending.md`: the §6.1 build refusal, the review's finding 1 |
| 90cd479 | the review fixes |

Routed subsets green at stage 1 (1926) and after the fix (1983); the whole
suite green at stages 2 and 3 (5543, 5427); the cold reviewer's gate green at
d6ffacf (5427) and at 90cd479 (5429), Julia 1.13.1; the docs battery green
after every docs edit. Ten of the brief's mutants went red on a scratch copy;
the reviewer's two extra mutants survived until the fix. The equivalence
sweep at f913f57 covered 167 models and 370 faces with no disagreement.

**What is left for you:** the diff review of the arc (1c7b234..90cd479) and
the push.

## Rulings made

### The rebase (1c7b234)

1. **Only two anchors moved.** Increments 65 and 66 touched no source file,
   spec section or log entry the brief cites; the `pending.md` bullet moved
   to lines 16 to 26 and the devices register line to 398. The fixture rename
   to `DiscreteAccumulator` kept its lines.

### Stage 1 (f913f57)

2. **A `Group`'s child rows carry the field `:children`**, membership
   `:transparent`, since a `Group` keeps its children in its name-transparent
   field. The brief's literal `[("pair", :pair)]` was wrong; the test asserts
   the real values.
3. **`terminal_producer` on a face nothing feeds returns the face itself**,
   a primitive's port or a root input, never `nothing`; a reader that must
   tell an unknown face from an unfed one checks existence first.
   Stage 1's choice, kept.
4. **The two functions sit in their own section** after `_check_root_faces`,
   since their `::Structure` signatures need the struct, which the brief's
   resolvers' section precedes.
5. **`DECLARATION_LAYER` grew in stage 2, not stage 1**: the coordinator's
   stage 1 file list omitted `test/test_build.jl`.

### Before stage 2 (7ab9782)

6. **The root always has a level row**, a primitive root's with no children
   and no wires, seeded in the constructor when the walk entered no level.
   D-315 and §9.1 say "one row per assembly, the root included" and "the root
   is the first row's instance" without exception, and stage 2's readers
   start from the first row. `face_routes` returns `[[face]]` for a childless
   row.
7. **The alias pass enters assembly output faces only.** Stage 2 stopped
   before editing: `Layout.addr` is keyed by `(path, name)` and D-210 lets a
   non-root primitive share one key between `u_types` and `y_types`
   (`RootCollision` under `fed`, asserted legal), so storing the input face
   would overwrite the output port's cell silently. `in_group` reads
   `addr[terminal_producer(…)]` and no input address is stored. Rejected:
   extending D-210's uniqueness to every primitive, which reverses a ruling
   and restricts leaf authors; a second dictionary or a direction in the key,
   structure for one reader. The spec's "the layout is that home for address
   facts" stays true; the annotation on D-315 is the ruling. The stage 2
   agent was resumed rather than replaced, having read everything and edited
   nothing.

### Stage 2 (ab2f5f0)

8. **`port_views` derives its input faces from the wires**, the root inputs
   plus each level's boundary producers and foreign consumers, not from
   `decls`: the handle holds none. A probe over 43 fixtures matched the old
   `in_faces` key set and producers exactly.
9. **Readers fetch `decls` from the nominal activation** and `_feedthrough`
   takes them from `_lines`, since neither holds an activation.
10. **The service-walk register bullet was rewritten in stage 2**, where
    `resolve_authored` switched, not in stage 3 as the brief said.
11. **The `RootCollision` assertions live in `test_assembly.jl`**, where the
    fixture is defined; the input is read through the root input's cell,
    since an input face's key is no longer stored.

### Stage 3 (5c03276)

12. **`SCALAR_FREE_LAYER` excludes five entries, not three.** `at_component`
    and `invoke_declaration` grow at a new scalar through a thunk closing over
    `T`, with no `::Type{T}` in their signatures. The reviewer verified the
    deltas are identical at 1c7b234, so the exclusion hides nothing this
    increment introduced.
13. **`wire!` became a local inside `_check_wires`**, which returns the root
    types; the constructor is `Structure(draft, root_types)`.
14. **The equivalence sweep testset was removed outright**, its oracle being
    the table; the routes testset asserts the literal answers and the levels
    testset gains the aliasing producer.
15. **A comprehension over `zip(paths, instances)` was rewritten by index**:
    it dispatched on the instance and failed the declaration-layer case.

### The cold review and the fix commit

The reviewer's verdict: pass with nits, nothing blocking.

16. **The §6.1 double declaration is queued for a build refusal** (d16bb80),
    beside the user's `UnconnectedInput` bullet: at the tip `port_views`
    throws a `KeyError` on the unwired face where it used to return a view.
    The spec already names the error; the bullet records what the code owes.
17. **Two tests added for the surviving mutants**: the printed routes of
    `FannedLoops(2)` once each, and `face_routes` on a primitive root's face.
18. **The docstring reads "under a primitive's or an assembly's input face"**,
    since root inputs are placed under `("", face)`.
19. **The gate after the fix was run by the reviewer**, not the fixer; the
    coordinator's fixer brief omitted it.

## Open points for the user

- The brief is left as written: its alias-pass clause, its stage 1
  `DECLARATION_LAYER` item and its `routed_pair` child literal are superseded
  by rulings 2, 5 and 7.
- The pending order: the two new bullets sit ahead of the inspector, as the
  work queue's "first bullet next" reads them; reorder if the inspector comes
  first.
- A primitive root's input face is a root input and is placed under
  `("", face)`; the docstring's "a primitive's input face" reads as the
  non-root case, as D-210's does.
- `face` names a `(path, face)` tuple in the two function signatures and a
  `Symbol` elsewhere in `assembly.jl`; the brief mandated the signature.
