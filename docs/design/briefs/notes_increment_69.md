# Notes: increment 69, the run of 2026-10-08 and 2026-10-09

The coordinator's rulings, each with its reason, and the open points left
for the user. Nothing here is pushed; increment 68's arc 9d9f78f..0b4f9e5
sits beneath this one, equally unpushed.

## The arc

| commit | what |
| --- | --- |
| cfdc14e | the brief rebased at 0b4f9e5 (ruling 1) |
| 64d8350 | stage 0: the companion's section 10 and amended sections 4, 6 and 9, the inventory rows, the pending bullet |
| a7f6fbb | the brief amended: the merge-order mutant dropped (ruling 2) |
| 643658f | stage 1: `PID{V, Hold, Track}` and `DiscretePID` over static vectors, `saturation_type` shared |
| b36d5a3 | stage 2: `AsPort`, `PID_PARAMETERS`, `fixed::Fixed`, `parameters`, the weights `b` and `c` |
| 8d1a4f7 | docs: the schedule-from-own-output cycle classified (ruling 6, corrected at 794a9d7) |
| 6aeb368 | stage 3: `Delay{V, K}` over a ring store, the pending bullet retired |
| 6376404 | the ring field renamed from `buf` (ruling 8) |
| 794a9d7 | docs: the review's F1 and F4, the cycle classification per parameter and the merge's run-time order |
| 9e12735 | the review fixes, F1 to F7 |
| e1102a2 | docs: the discrete tier's reason is structural tracing; two paragraphs reflowed |

Gate on the real tree at 9e12735: 5859 of 5859 on Julia 1.13.1.

## Rulings made

1. **The brief was rebased at 0b4f9e5 without recounting.** 68's fix
   changed only in-place lines outside every cited range, and the blocks
   source, its tests, the fixtures, the companions and `pending.md` were
   byte-identical to a682407. One correction: the Blocks import line spans
   77 to 81.
2. **The merge-order mutant was dropped.** Stage 0 showed that the
   selection `NamedTuple{PID_PARAMETERS}(merge(c.fixed, u))` picks by name
   and no port name is a parameter name, so both merge orders give the
   same tuple. Replaced by a scheduled `Kp` read from a default.
3. **Stage 0's deviations stand.** The PID left the inventory's list of
   blocks whose ports are fixed by what they are, since its port set now
   depends on the scheduled set; the broadcast-to-one-shape sentence is
   scoped to the PID, since the other vector blocks still promote; sections
   7 and 9 of the companion keep their scalar text as a dated record under
   section 10's dated superseding note.
4. **Stage 1's deviations stand.** The shape sum is converted with
   `Float64.(…)` so an all-integer spelling still gives `V = Float64`; a
   vector `Step` needs a vector `before` since that block promotes;
   `pid_single_loop` took a `level` keyword, `pid_root_model` carries
   `V`, and `pid_gain_sets` and `pid_law` live at top level; the loop
   comparison runs 20 s.
5. **Stage 2's deviations stand.** A private `fixed_parameters(given)`
   helper serves both constructors; `pid_linearization`,
   `scheduled_pid_root(…; frozen)`, `scheduled_pid_cycle` and
   `scheduled_pid_loop` live at top level; `DiscretePID`'s `yf` update
   keeps the old operation order so the old literals hold to the bit.
6. **A schedule from the block's own output closes a real cycle for the
   seven parameters the direct law reads, and an artificial one for `Ki`
   and `Tt` on the continuous tier; all nine are real on the discrete
   tier,** where a member traces structurally. The brief had the cycle
   test reuse the artificial-cycle assertions; the reviewer probed all
   nine names on both tiers. The companion and the `PID` docstring say
   this; a `Ki` cycle test pins the artificial case.
7. **`Delay` is float-only.** The brief contradicted itself: the settled
   struct, the inventory row and the constructor convention describe `V`
   from `float(v0)` bound to `Real` or a static array, while three test
   claims assumed an unconstrained line like `UnitDelay`. The struct won.
   The tick counter feeds the line through a `float` junction, the
   `K = 1` comparison with `UnitDelay` is by `==`, and a vector `v0` is a
   `TypeError` at construction rather than `IllegalStoreField` at build.
8. **The store fields are `ring` and `cursor`.** The brief's `buf` is
   off the abbreviation roster and `k` is a single letter on a field that
   holds a cursor. Neither name was a design ruling.
9. **The `Delay` docstring makes no constant-cost claim.** `Base.setindex`
   rebuilds the whole `SVector` and the store is written back whole, so
   the tick body grows from 3.4 ns at `K = 2` to 66 ns at `K = 200` and
   919 ns at `K = 2000`; first build plus a step is 0.42 s at `K = 2` and
   0.51 s at `K = 200`, 3.4 s at `K = 2000`. The brief's line 174 claims
   both constant and stays as written, a brief being a record.
10. **A default-read test was added** for every scheduled parameter above
    `u_max` and below `u_min` in both tiers, since the brief's second
    pass scheduled `u_min` on rows that only hit the upper limit and no
    row scheduled `Kd`, `τd`, `u_max`, `b` or `c`.

## Open points for the user

- The weight keyword `c` shares a letter with the component binding `c`
  across `src/blocks.jl`; it is reached as `p.c` and never bound bare. You
  ruled on `b` and `c`; the reviewer noted it without a finding.
- The reviewer measured `step!` allocating about 816 KB per 1000 frames
  on every model, the pre-existing `UnitDelay` one included. The phase
  bodies allocate nothing; the cost is older than this increment and is
  not in `pending.md`.
- A delay of large `K` pays per tick in proportion to `K` (ruling 9). A
  mutable ring is not an option under the isbits store rule (D-231); if a
  long line is ever wanted, that is the trade to revisit.
- Both arcs await your diff review before any push.
