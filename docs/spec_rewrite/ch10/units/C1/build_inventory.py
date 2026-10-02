import json, os
H = os.path.dirname(os.path.abspath(__file__))
DEC = "docs/design/decisions.md"
R = []  # (old, new, tag, cites, newcites, where, ruling)
def c(old, new, tag="F", cites=(), newcites=None, where="new", ruling=None):
    R.append((old, new, tag, list(cites), newcites, where, ruling))

c("### 10.5 Multi-rate tick scheduling", "### 10.5 Multi-rate tick scheduling", "X")
c("A model runs several clocks at once.", "A model runs several clocks at once.")
c("The integrator advances on the continuous step `h`.", "The integrator advances on the continuous step `h`.")
c("An inner control loop samples at one rate, an outer loop at another, and a receiver at a third.", "An inner control loop samples at one rate, an outer loop at another, and a receiver at a third.")
c("Each of those must hold its outputs steady between its own firings.", "Each of those must hold its outputs steady between its own firings.")
c("Three things have to be fixed for that to be well-defined: the time lattice every rate shares, the test that decides which components run at a given boundary, and the surface an author declares a rate on.",
  "For that to be well-defined, three things have to be fixed. They are the time lattice every rate shares, the test that decides which components run at a given boundary (a published consistency point), and the surface an author declares a rate on.")
c("This section fixes all three, in that order.", "This section fixes all three, in that order.")
c("#### The base grid, and the pair every rate compiles to", "#### The base grid and the gate", "X")
c("Rule. Every discrete component's period is an integer multiple of a base tick period `Δt_base`.",
  "Every discrete component's period is an integer multiple of a base tick period `Δt_base` (D-019).", newcites=["D-019"])
c("`Δt_base` is itself an integer multiple of the continuous step, with `N_base` steps per base tick ($\\Delta t_{\\mathrm{base}} = N_{\\mathrm{base}} \\cdot h$, $N_{\\mathrm{base}} \\ge 1$).",
  "`Δt_base` is itself an integer multiple of the continuous step, with `N_base` steps per base tick ($\\Delta t_{\\mathrm{base}} = N_{\\mathrm{base}} \\cdot h$, $N_{\\mathrm{base}} \\ge 1$).")
c("That is the harmonic grid.", "That is the harmonic grid.")
c("Ticks therefore land on step boundaries, which is the only place anything discrete ever happens (D-019).",
  "Ticks therefore land on step boundaries, which is the only place anything discrete ever happens.", cites=["D-019"])
c("Two indices. Frames are counted by the frame index `k`.", "Frames (iterations of the loop) are counted by the frame index `k`.")
c("The frame top at `t = k·h` is a base tick exactly when `k` is a multiple of `N_base`.",
  "The frame top at `t = t₀ + k·h` is a base tick exactly when `k` is a multiple of `N_base`.", "R", ruling="R8-F7")
c("Its tick index is then `tick = k ÷ N_base`.", "Its tick index is then `tick = k ÷ N_base`.")
c("A frame top that is no base tick has no tick index, and neither does a `t` boundary.",
  "A frame top that is no base tick has no tick index, and neither does a boundary at a localized event time `t` (§10.4, D-185).", "C", newcites=["§10.4", "D-185"])
c("One pair per component. However an author declares a rate, and however deeply the declaration is nested, the build compiles it to two integers per discrete component.",
  "However an author declares a rate, and however deeply the declaration is nested, the build compiles it to two integers per discrete component (D-185).", "C", newcites=["D-185"])
c("The divisor `D` is the component's period in base ticks.", "The divisor `D` is the component's period in base ticks.")
c("The phase `Φ` is its offset in base ticks.", "The phase `Φ` is its offset in base ticks.")
c("The pair is kept in the canonical residue `0 ≤ Φ < D`, so the component's ticks fall at base-tick indices `Φ`, `Φ + D`, `Φ + 2D`, and so on.",
  "The pair is kept in the canonical residue `0 ≤ Φ < D`, so the component's ticks fall at base-tick indices `Φ`, `Φ + D`, `Φ + 2D`, and so on.")
c("The gate. A component is due at a boundary when `(tick − Φ) % D == 0`, where `tick` is the boundary's tick index.",
  "A component is due at a boundary when `(tick − Φ) % D == 0`, where `tick` is the boundary's tick index (D-185).", "C", newcites=["D-185"])
c("That subtraction and remainder are the whole admission test.", "That subtraction and remainder are the whole admission test.")
c("It costs one subtraction more than a phase-free test would, over a lattice fixed at build time.", "It costs one subtraction more than a phase-free test would, over a lattice fixed at build time.")
c("The declaration surface below says where a component's `(D, Φ)` comes from.", "The declaration surface below says where a component's `(D, Φ)` comes from.")
c("#### Discrete stages run only at their own ticks", "#### Zero-order hold and the two sweep variants", "X")
c("Rule. A discrete component's `y_state`/`y_direct` run only at its own ticks.",
  "A discrete component's `y_state`/`y_direct` run only at its own ticks (D-019).", newcites=["D-019"])
c("Its cells hold in between.", "Its cells (its entries in the signal table) hold in between.")
c("This is zero-order hold (ZOH), stated in sweep terms.", "This is zero-order hold (ZOH), stated in sweep terms.")
c("Why. Re-running a discrete component's stages at every boundary would un-sample a sampled-data controller (D-019).",
  "The reason for the hold is that re-running a discrete component's stages at every boundary would un-sample a sampled-data controller.", cites=["D-019"])
c("Delivering that hold takes two statically distinct sweep variants, compiled from one entry list.",
  "Delivering that hold takes two statically distinct sweep variants, compiled from one entry list (D-147).", newcites=["D-147"])
c("Discreteness is a build-time fact, so the split is static rather than a runtime test (D-147).",
  "Discreteness is a build-time fact, so the split is static rather than a runtime test.", cites=["D-147"])
c("The interior sweep walks continuous entries only.", "The interior sweep walks continuous entries only (D-147).", "C", newcites=["D-147"])
c("RK stage evaluations (§10.3) and localization guard trial evaluations (§10.4) run this variant.",
  "RK stage evaluations (§10.3) and localization guard trial evaluations (§10.4) run this variant.", cites=["§10.3", "§10.4"])
c("The ZOH therefore holds mid-step by construction.", "The ZOH therefore holds mid-step by construction.")
c("Discrete entries are not gated out at runtime.", "Discrete entries are not gated out at runtime.")
c("They are absent from the walk at compile time, so the hot path carries no gating test at all.", "They are absent from the walk at compile time, so the hot path carries no gating test at all.")
c("The boundary sweep walks the full list, with discrete entries gated by `(tick − Φ) % D` against the boundary's tick index.",
  "The boundary sweep walks the full list, with discrete entries gated by `(tick − Φ) % D` against the boundary's tick index (D-147).", "C", newcites=["D-147"])
c("It is the variant the §10.6 macro-sequence runs.", "It is the variant the §10.6 macro-sequence runs.", cites=["§10.6"])
c("It is not one fixed list either, because different boundaries run different subsets of the execution order.",
  "It is not one fixed list either, because different boundaries run different subsets of the execution order.")
c("The split applies to both sweep blocks.", "The split applies to both sweep blocks (D-147).", "C", newcites=["D-147"])
c("The discrete tier's `y_state` entries are absent from the interior stage-1 walk, exactly as its `y_direct` entries are absent from the interior stage-2 walk.",
  "The discrete tier's `y_state` entries are absent from the interior stage-1 walk, exactly as its `y_direct` entries are absent from the interior stage-2 walk.")
c("The two sweep variants surface in the phase-body signatures: interior bodies take no arguments, boundary bodies take the tick index (§9.7).",
  "The two sweep variants surface in the phase-body signatures: interior bodies take no arguments, boundary bodies take the tick index (§9.7).", cites=["§9.7"])
c("#### The due set is a property of the boundary", "#### Due sets", "X")
c("Rule. The due set is computed once for the boundary and reused by every re-sweep of its quiescence iteration (the fixed point where a round of handlers fires nothing, §10.6).",
  "The due set is computed once for the boundary and reused by every re-sweep of its quiescence iteration (D-147). Quiescence is the fixed point where a round of handlers fires nothing (§10.6).",
  "C", cites=["§10.6"], newcites=["D-147", "§10.6"])
c("It is a property of the boundary, not of the sweep call.", "The due set is a property of the boundary, not of the sweep call.")
c("Why. A due component is at its tick instant for the whole boundary, not for one round of it.",
  "That holds because a due component is at its tick instant for the whole boundary, not for one round of it.")
c("Each kind of boundary has its own due set:", "Each kind of boundary has its own due set:")
c("At a tick frame top (every `N_base`-th frame top), the due set is every discrete component whose gate admits the tick index.",
  "At a tick frame top (every `N_base`-th frame top), the due set is every discrete component whose gate admits the tick index.")
c("These are the `(D, Φ)` pairs with `(tick − Φ) % D == 0`.", "These are the `(D, Φ)` pairs with `(tick − Φ) % D == 0`.")
c("At an off-tick frame top (a frame top with `N_base > 1` that is no base tick), the due set is empty.",
  "At an off-tick frame top (a frame top with `N_base > 1` that is no base tick), the due set is empty.")
c("The tick counter has not advanced, so no component is at a tick instant.", "The tick counter has not advanced, so no component is at a tick instant.")
c("At a `t` boundary, the due set is empty for the same reason.", "At a `t` boundary, the due set is empty for the same reason.")
c("A modulo test against the unadvanced index would wrongly re-admit the previous tick's due set.", "A modulo test against the unadvanced index would wrongly re-admit the previous tick's due set.")
c("At boundary zero (the initialization boundary: the ordinary macro-sequence with an empty integrate), the due set is everything with `Φ = 0`.",
  "At boundary zero (the initialization boundary, which runs the ordinary macro-sequence with an empty integrate), the due set is everything with `Φ = 0` (D-185, D-205).",
  "C", newcites=["D-185", "D-205"])
c("At tick index 0 the gate reads `(0 − Φ) % D == 0`.", "At tick index 0 the gate reads `(0 − Φ) % D == 0`.")
c("Under the canonical residue `0 ≤ Φ < D` that holds if and only if `Φ = 0`.", "Under the canonical residue `0 ≤ Φ < D` that holds if and only if `Φ = 0`.")
c("Nothing implements this rule.", "Nothing implements this rule.")
c("It falls out of the ordinary gate.", "It falls out of the ordinary gate.")
c("Dueness at boundary zero governs the `s_update` calls alone.", "Dueness at boundary zero governs the `s_update` calls alone.")
c("Output stages publish due or not (D-205), as §14.5 specifies.", "Output stages publish due or not (D-205), as §14.5 specifies.", cites=["D-205", "§14.5"])
c("An offset component's first tick is at `Φ·Δt_base`.", "An offset component's first tick is at `Φ·Δt_base`.")
c("Until then its cells hold its boundary-zero publication.", "Until then its cells hold its boundary-zero publication.")
c("Its output stages run at `t₀` due or not, evaluated from the authored world (D-205, §14.5).",
  "Its output stages run at `t₀` due or not, evaluated from the authored world (D-205, §14.5).", cites=["D-205", "§14.5"])
c("The probe's synthesized values (§9.3) reach no published cell.", "The probe's synthesized values reach no published cell.", cites=["§9.3"])
c("The \"tick at `t₀⁻`\" story they once told held only in the build's own world, because the probe runs before any condition exists.",
  "§10.5's content defense (\"what a tick at `t₀⁻` would have produced\") held only in the build's own world, the probe running before any condition exists.",
  "R", newcites=[], where=DEC, ruling="R7")
c("In a phase-free model every `Φ` is 0, so at boundary zero everything is due and the distinction is empty.",
  "In a phase-free model every `Φ` is 0, so at boundary zero everything is due and the distinction is empty.")
c("#### Simultaneous ticks are already well-defined", "#### Simultaneous ticks", "X")
c("Several components can be due at one boundary, and settled machinery already orders them.", "Several components can be due at one boundary, and settled machinery already orders them.")
c("All due components run their output stages in topological order within the sweep.", "All due components run their output stages in topological order within the sweep.")
c("All due `s_update` calls run after the sweep, in any order.", "All due `s_update` calls run after quiescence, in any order.", "R", ruling="R10")
c("Each one reads the table and writes only its own `s` store.", "Each one reads the table and writes only its own `s` store.")
c("The FCS cascade's intra-tick ordering is therefore a sweep property, not an update-order property.",
  "The intra-tick ordering of the FCS cascade (a flight control system's outer loops feeding its inner loop) is therefore a sweep property, not an update-order property.",
  "R", ruling="R8-F14")
c("#### Assemblies: virtual for execution, rate scopes for declaration", "#### Assemblies and rate scopes", "X")
c("An assembly is virtual for execution.", "An assembly is virtual for execution (D-019).", newcites=["D-019"])
c("Its children are scheduled individually, and the assembly itself never runs as a unit.", "Its children are scheduled individually, and the assembly itself never runs as a unit.")
c("For declaration, a rate scope is an assembly's `sample_times` declaration against the enclosing scope.", "For declaration, a rate scope is an assembly's `sample_times` declaration against the enclosing scope.")
c("There are no atomic assemblies, and no opt-in variant (D-019).", "There are no atomic assemblies, and no opt-in variant (D-019).", cites=["D-019"])
c("Why no coarsening is needed. The signal table makes interleaving semantically invisible.",
  "No coarsening is needed, because the signal table makes interleaving semantically invisible.")
c("Consumers read cells whose freshness is guaranteed by topological order rather than by contiguity.",
  "Consumers read cells whose freshness is guaranteed by topological order rather than by contiguity.")

claims = []
for i, (old, new, tag, cites, newcites, where, ruling) in enumerate(R, 1):
    d = {"id": f"C1-{i:03d}", "old": old, "new": new, "where": where, "cites": cites}
    if newcites is not None and newcites != cites: d["newcites"] = newcites
    d["tag"] = tag
    if ruling: d["ruling"] = ruling
    claims.append(d)
added = [
    "a published consistency point",
    "iterations of the loop",
    "its entries in the signal table",
    "A sweep is one pass through the execution order.",
    "a boundary at a localized event time",
    "a flight control system's outer loops feeding its inner loop",
    "The probe is the build's single evaluation of a user function with real values (§9.3).",
]
json.dump({"claims": claims, "added": added}, open(os.path.join(H, "inventory.json"), "w"), ensure_ascii=False, indent=1)
