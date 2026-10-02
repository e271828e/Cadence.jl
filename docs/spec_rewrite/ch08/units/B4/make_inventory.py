# Scratch: builds inventory.json for unit B4. Run from this directory.
import json

LOG = "docs/design/decisions.md"
C = []


def c(old, new=None, tag="F", cites=(), newcites=None, where="new", ruling=None, note=None):
    d = {"id": f"B4-{len(C) + 1:03d}", "old": old, "new": new if new is not None else old,
         "where": where, "cites": list(cites)}
    if newcites is not None:
        d["newcites"] = list(newcites)
    d["tag"] = tag
    if ruling:
        d["ruling"] = ruling
    if note:
        d["note"] = note
    C.append(d)


# §8.2, events
c("#### `state_events(::C)`", "#### Events: `state_events`", "R", ruling="R6")
c("`state_events` declares an ordered, named collection of guard/handler pairs")
c("spelled `StateEvent(guard, handler)` with no detection keyword.",
  "A pair is spelled `StateEvent(guard, handler)`, with no detection keyword.")
c("Detection policy is declared by the guard's return type instead.",
  "Detection policy is declared by the guard's return type instead (D-179).", "C", newcites=["D-179"])
c("A `Bool` guard makes the event boundary-detected, checked for edges at step boundaries only, with no root-finding.")
c("A guard returning the nominal scalar makes it localized, with the crossing instant bracketed by root-finding over trial sweeps (§10.4).",
  cites=["§10.4"])
c("Order is semantics.")
c("It is the declaration order used by §5.3 and the priority order, with re-decision, used by §10.6.",
  cites=["§5.3", "§10.6"])
c("Nothing here is inferrable.")

# §8.2, stage membership
c("#### No stage tags anywhere", "No port carries a stage tag", "R", ruling="R6",
  note="the claim-heading becomes the bold topic sentence; the label '#### Stage membership' is added")
c("Which stage produces which port stays invisible in the contract, preserving §4.2.", cites=["§4.2"])
c("Moving a port between stages is non-breaking for consumers.")
c("Membership is derived instead", "stage membership is derived (D-033)", "C", newcites=["D-033"])
c("with no chicken-and-egg", "The derivation has no chicken-and-egg")
c("Stage-1 functions (`y_state`) structurally receive no inputs, so the build probes them first, observes their contract ports",
  "Stage-1 functions (`y_state`) structurally receive no inputs, so the build probes them first and observes their contract ports")
c("assigns the remainder to stage 2, builds the graph, and probes the stage-2 chain in topological order with real upstream values.",
  "It assigns the remainder to stage 2, builds the graph, and probes the stage-2 chain in topological order with real upstream values.")
c("The \"decoder takes no inputs\" property is exactly what makes the derivation well-founded.",
  "The property that stage 1 takes no inputs is exactly what makes the derivation well-founded.")
c("A leaf's declarations do carry its tier (D-195, D-220), and that is a different fact.", cites=["D-195", "D-220"])
c("The tag this subsection refuses is the stage tag on a port, which stays invisible either way.",
  "The tag refused here is the stage tag on a port, which stays invisible either way.")

# §8.2, completeness
c("#### Completeness of the declaration set", "#### Completeness", "R", ruling="R6")
c("Four rules the build checks in the structure step (§9.1)",
  "The build checks three rules in the structure step (§9.1)", "M", cites=["§9.1"],
  note="the count follows M1, which moved the root-input rule (old 2597-2611) to unit B2")
c("stated here because they are properties of the declarations, not of the wiring.",
  "They are stated here because they are properties of the declarations, not of the wiring.")
c("A non-empty store needs its update.")
c("`x_init` with fields and no `x_deriv` method, or `s_init` with fields and no `s_update` method, is a build error.",
  "`x_init` with fields and no `x_deriv` method, or `s_init` with fields and no `s_update` method, is a build error, `StoreWithoutUpdate`.",
  "R", ruling="P48", note="names the kind; Appendix C cites §8.2 for StoreWithoutUpdate")
c("An empty store is a stateless leaf's tier marker (above)",
  "The store is the tier marker. It is therefore mandatory even when empty",
  "R", where="units/B1/new.md", ruling="P44")
c("and owes nothing.", "An empty store owes nothing (above).", "R", ruling="P44",
  note="kept as a pointer; B1 holds 'An empty store owes no update law'")
c("The first is continuous state with no flow, the second a discrete store nothing updates.",
  "The first case is continuous state with no flow (the continuous derivative function, `x_deriv`), the second a discrete store nothing updates.")
c("The framework will not silently supply `ẋ = 0`, which is a model, not a default.")
c("An unupdated discrete store is a parameter in disguise, and parameters are plain struct fields.")
c("The didactic style says exactly that.")
c("`m_init` carries no such obligation.", "`m_init` carries no such obligation either.")
c("Modes are written by handlers, and a component may legitimately declare modes no event of its own transitions.")
c("An event needs both halves.")
c("A `state_events` entry whose guard or handler has no method for the component type is a build error",
  "A `state_events` entry whose guard or handler has no method for the component type is a build error, `EventHalfMissing`.",
  "R", ruling="P48", note="names the kind; its third arm, a non-StateEvent entry, is not stated in §8.2")
c("caught by method lookup at declaration-reading time rather than as a `MethodError` at the first firing.",
  "Method lookup catches it at declaration-reading time, rather than as a `MethodError` at the first firing.")
c("An event that fires only in a corner of the envelope would otherwise hide the omission indefinitely.")
c("Tier is declared by the store.", "Tier is declared by the store, as \"The stores\" above states (D-195, D-263).",
  "R", newcites=["D-195", "D-263"], ruling="P44")
c("Every leaf declares `x_init` or `s_init`, the two are disjoint,",
  "Every leaf declares exactly one of `x_init` and `s_init`, and a stateless leaf declares it empty (D-263):",
  "R", where="units/B1/new.md", ruling="P44")
c("and so every leaf announces its tier in one place (D-195, D-263).",
  "Spelling that out puts every leaf's tier on the page in one place, stateful or not, with no tier by omission.",
  "R", cites=["D-195", "D-263"], where="units/B1/new.md", ruling="P44",
  note="the citations stay on the pointer sentence")
c("A stateful leaf announces it in the update law as well, `x_deriv` beside `x_init` and `s_update` beside `s_init`.")
c("The two output stages are one pair of names shared by both tiers, so they announce nothing and cast no vote (D-220).",
  cites=["D-220"])
c("The remaining tier-implying declarations must agree.",
  "The remaining tier-implying declarations must agree (D-112, D-249).", "C", newcites=["D-112", "D-249"])
c("`m_init`, `state_events` and `x_projection` are continuous-only, because the event system is continuous-side only (§5.2, §3.2, §14.1) and projection's one manifold is the continuous state's (§2.2).",
  cites=["§5.2", "§3.2", "§14.1", "§2.2"])
c("A `Pinned` entry in a contract is continuous-only, because the discrete tier pins wholesale and the marker there says nothing.")
c("No arity carries a tier.", "No arity carries a tier (above).", "R", ruling="P43")
c("Every declaration takes the component alone,",
  "Every declaration of a structural fact but the allocator takes the component alone (D-263).",
  "R", where="units/B1/new.md", ruling="P43", note="R13's wording, held by B1's criterion paragraph")
c("and `ws_init` takes the scalar on both tiers (D-263).",
  "`ws_init(c, T)` takes it on both tiers, the continuous and the discrete (D-077).",
  "R", cites=["D-263"], where="units/B1/new.md", ruling="P43", note="B1's bold headline above cites D-263")
c("Disagreement is `DeclarationOnWrongTier` (Appendix C)", cites=["Appendix C"])
c("reported as the offending declaration with the tier the leaf's other declarations announce.",
  "It is reported as the offending declaration, with the tier the leaf's other declarations announce.")
c("It covers declaring both `x_deriv` and `s_update`, a `Pinned` entry on a discrete leaf, and the mixed-store cases the split state letters restore",
  "It covers declaring both `x_deriv` and `s_update`, a `Pinned` entry on a discrete leaf, and the mixed-store cases that the split state letters (`x` for continuous state, `s` for discrete, D-195) restore.",
  "F", newcites=["D-195"])
c("namely both stores on one leaf, an `x_init` on a leaf whose update law is `s_update` and an `s_init` on one whose update law is `x_deriv`.",
  "Those are both stores on one leaf, an `x_init` on a leaf whose update law is `s_update`, and an `s_init` on one whose update law is `x_deriv`.")
c("A stateless leaf is a leaf whose store is empty, and it declares its tier the same way.")
c("`x_init(::C) = (;)` makes it continuous, the tier §13.7 steers stateless leaves to", cites=["§13.7"])
c("`s_init(::C) = (;)` makes it discrete, one that runs at its ticks and holds its outputs between them.")
c("A primitive declaring neither store is `TierUnreadable` (Appendix C).",
  "A primitive declaring neither store is `TierUnreadable`, and its message spells the empty form.",
  "R", cites=["Appendix C"], where="units/B1/new.md", ruling="P44")
c("`y_types` stays mandatory on a stateless leaf.")
c("A leaf with an empty store and no output contract produces nothing and stores nothing, and it is refused as `StatelessWithoutOutputs` (Appendix C).",
  "A leaf with an empty store and no output contract produces nothing and stores nothing, and it is refused as `StatelessWithoutOutputs` (Appendix C, D-263).",
  "C", cites=["Appendix C"], newcites=["Appendix C", "D-263"])
c("The stage bundles follow the tier like any other leaf's, with no `x` or `s` field, because the bundle law puts a store's letter in the bundle only when the store is non-empty (§5.2).",
  cites=["§5.2"])
c("§13.7 records why one stateless continuous leaf already serves consumers on both tiers.", cites=["§13.7"])
c("Members of both families, or of neither, are the §8.5 class errors.",
  "A type declaring both the leaf and the assembly families of declarations, or neither, meets the class errors of §8.5.", cites=["§8.5"])

# §8.3
c("### 8.3 Visibility: the contract is the interface", tag="X")
c("Rule. Visibility is decided by where the value goes:",
  "Visibility is decided by where the value goes (D-034):", "C", newcites=["D-034"],
  note="the Rule. label goes; the headline is bold")
c("a field declared in `y_types` is public;")
c("a field returned in `y` (a stage's own published signals) and declared nowhere is a build error;")
c("a component with no `y_types()` method has no outputs.",
  "a component with no `y_types(::C)` method has no outputs, and a stateless leaf without one is refused as `StatelessWithoutOutputs` (§8.2, D-263).",
  "R", newcites=["§8.2", "D-263"], ruling="R7")
c("That is the same move as class-by-declaration-shape.",
  "That is the same move as class-by-declaration-shape (§8.5).", "C", newcites=["§8.5"])
c("Ports in the contract are connectable, GUI-listed, snapshot-carried and log-exported.",
  "Ports in the contract (a component's declared interface) are connectable, GUI-listed, snapshot-carried and log-exported.")
c("The table is public throughout, with every cell a declared port, so nothing anywhere needs a presentation filter.")
c("Visibility is binary, with no third class between the two.")
c("A value a later function reads travels as a declared port like any other (§5.2).", cites=["§5.2"])
c("The inspection path for an intermediate is therefore declaration.",
  "The inspection path for an intermediate is declaration (D-194). That follows from the visibility rule above.",
  "F", newcites=["D-194"], note="D-194 moves one sentence earlier; unbolded, as the next sentence makes it a consequence")
c("One line in `y_types` makes it public, checked and visible everywhere at once (D-194).",
  "One line in `y_types` makes it public, checked and visible everywhere at once.",
  cites=["D-194"], newcites=[])
c("FlightCore is the precedent, where an intermediate was inspected by putting it in the `Model` output and no other way.",
  "FlightCore is the precedent. There an intermediate could be inspected only by putting it in the model's output.")
c("Publicity is never implicit.")
c("Even the minimal component writes `y_types(::LowPassFilter) = (x = Float64,)`, one line, in exchange for \"public\" always meaning someone wrote it down.")
c("- Conformance. A declared port must be produced by exactly one stage, stage 1 or stage 2 (D-252).",
  "A declared port must be produced by exactly one stage, stage 1 or stage 2 (D-252).", cites=["D-252"],
  note="bold lead-in 'Conformance.' becomes a bold headline clause")
c("Those two classes are the whole classification, and the framework produces no port of its own.")
c("Stage membership is derived over `y_types` alone (§9.1).", cites=["§9.1"])
c("Declared-but-unproduced and produced-by-two-stages are build errors.")
c("A declared port no stage produces is `DeclaredNotProduced`, which names the port, the stage products and the store fields; the remedy is returning the name from `y_state` (§5.3).",
  "A declared port no stage produces is `DeclaredNotProduced`, which names the port, the stage products and the store fields. Its remedy is returning the name from `y_state` (§5.3).",
  cites=["§5.3"])
c("A returned port field declared nowhere is a build error at probe, with did-you-mean (the offending name plus the list-in-hand it should have matched) against `y_types`.",
  "A returned port field declared nowhere is a build error at probe (the build's single evaluation of a user function). The error carries a did-you-mean (the offending name plus the list-in-hand it should have matched) against `y_types`.")
c("That is the return-side analogue of §8.4 walkthrough 1 (D-034, D-055).",
  "That is the return-side analogue of §8.4 walkthrough 1 (D-034, D-239).", "R",
  cites=["§8.4", "D-034", "D-055"], newcites=["§8.4", "D-034", "D-239"], ruling="R9")
c("The forgotten-branch walkthrough holds.", "Walkthrough 3 of §8.4, the forgotten branch field, holds.", newcites=["§8.4"])
c("A declared `P` missing from the taken branch's return fails at probe.")
c("Missing from an untaken branch, it fails loudly at that branch's first execution via the always-on check.")
c("- Branch-shape rule. Stage returns must have the same `NamedTuple` shape on every branch.",
  "Stage returns must have the same `NamedTuple` shape on every branch, the branch-shape rule (D-034).",
  "C", newcites=["D-034"], note="bold lead-in becomes a bold headline clause; the term stays")
c("Julia's type-stability discipline already demands that for performance.")
c("The framework merely makes it a stated rule with a good error.")
c("- Schema authority is total over the table",
  "Schema authority is total over the table (D-032, D-034)", "R", newcites=["D-032", "D-034"], ruling="R9",
  note="R9 puts D-034 and D-239 where 2660 cited D-055; D-034 Position carries the headline")
c("(declarations define structure; evaluation only checks conformance).",
  "Schema authority means declarations define structure and evaluation only checks conformance.")
c("Every cell traces to an authored declaration, the always-on check's expected type for `y` is fully declaration-derived",
  "Every cell traces to an authored declaration, and the always-on check's expected type for `y` is fully declaration-derived.")
c("and return typos cannot silently define new cells.",
  "Return typos cannot silently define new cells (D-239).", "R", newcites=["D-239"], ruling="R9")
c("Protection against silently dropped partials rests on the embedding guarantee (§9.5).", cites=["§9.5"])
c("Promotion is airtight, so an observed `Float64` is a true constant.")
c("Probe-observed expected types remain rejected (D-034, D-055, D-194).",
  "Probe-observed expected types remain rejected (D-034, D-194).", "R",
  cites=["D-034", "D-055", "D-194"], newcites=["D-034", "D-194"], ruling="R9")
c("- What this rules out (D-016, D-034, D-055, D-194).",
  "This section's rules exclude several designs the log rejects (D-016, D-034, D-055, D-194)", "R",
  cites=["D-016", "D-034", "D-055", "D-194"], ruling="R4")
c("The `unlisted` flag (§4.2) and its satellite-function representation;",
  "among them the `unlisted` flag (§4.2) and its satellite-function representation.", "R",
  cites=["§4.2"], ruling="R4",
  note="kept: the log carries the unlisted flag (D-016, D-034 Rejected) but not its satellite-function representation")
c("identity publication by default (§7.4 step 4);",
  "Superseded position — identity publication of state and modes as the default", "R",
  cites=["§7.4"], where=LOG, ruling="R4", note="D-016 Rejected, log 591-592; D-034 Rejected log 1070 'Identity-public on missing outputs()'")
c("probe-observed private cells;",
  "private intermediates recognized by probe observation", "R", where=LOG, ruling="R4",
  note="D-034 Rejected, log 1063; also D-194 Rejected 'Cells with probe-observed types', log 6925")
c("the `Private(T)` fallback;",
  "`Private(T)` contract entries: ceremony without a demonstrated customer — fallback on record.", "R",
  where=LOG, ruling="R4", note="D-034 Rejected, log 1071-1072; D-194 Rejected log 6928-6931")
c("and the opt-in variant with a `Float64`-under-`Dual` diagnostic.",
  "Opt-in `locals` + `Float64`-under-`Dual` diagnostic: legislates an ambiguity strictness dissolves.", "R",
  where=LOG, ruling="R4", note="D-055 Rejected, log 1584-1585")

# §8.4
c("### 8.4 Failure walkthroughs (the error-locality grounding)", tag="X")
c("The five mistakes that decided declaration-vs-inference, with their failure sites under this layer.",
  "The five mistakes below decided the choice between declaration and inference-by-evaluation as the schema authority (§8.1). They ground error locality (the property that a mistake fails at the site of the mistake). The list gives each with its failure site under this layer.",
  newcites=["§8.1"])
c("Each was traced under inference-by-evaluation too, and in every case the failure surfaced inside correct code, later, or never.")
c("D-032 carries the traces.", cites=["D-032"])
c("1. Typo'd wire (`:throtle`). A build error at the connection, \"no input `throtle`; did you mean `throttle`?\"",
  "1. A typo'd wire (`:throtle`) is a build error at the connection, \"no input `throtle`; did you mean `throttle`?\"")
c("2. Forgotten wire (`fuel_available`, read only by a guard). The §6.1 unconnected-input error at build.",
  "2. A forgotten wire, such as `fuel_available` read only by a guard (the declared function defining an event's predicate), fails as the §6.1 unconnected-input error at build.",
  cites=["§6.1"])
c("3. Forgotten branch field (`P` returned by one branch only). A probe or first-execution error naming the declared port.",
  "3. A forgotten branch field, such as `P` returned by one branch only, fails as a probe or first-execution error naming the declared port (one declared input or output). A probe is the build's single evaluation of a user function.")
c("4. Type mismatch (a `Float64` fraction wired into a `Bool` input). A wiring-time error naming both endpoints and both faces.",
  "4. A type mismatch, such as a `Float64` fraction wired into a `Bool` input, fails as a wiring-time error naming both endpoints and both faces (the names ports wear on their component's boundary).")
c("5. Typo'd return field (`P_shft = …` for a declared `P_shaft`). A probe error with did-you-mean (the offending name plus the list-in-hand it should have matched) against `y_types`.",
  "5. A typo'd return field, such as `P_shft = …` for a declared shaft power `P_shaft`, fails as a probe error with did-you-mean (the offending name plus the list-in-hand it should have matched) against `y_types`.")
c("That one error is the whole report.")
c("The probe chain stops at the port check (§13.1, D-239), and an unproduced-`P_shaft` error would only restate it from the other side, since renaming the field produces the port.",
  cites=["§13.1", "D-239"])
c("A declared port no stage returns, on a component whose returns are all declared, is the completeness pass's error, with the stage-product and state-field lists in hand (§8.3).",
  "A declared port no stage returns, on a component whose returns are all declared, is `DeclaredNotProduced`, with the stage-product and state-field lists in hand (§8.3).",
  cites=["§8.3"])
c("Every returned field is a declared port, so this one error form is the whole case.")
c("An intermediate a later function reads is declared like any other output and typo'd like any other output (§8.3).",
  cites=["§8.3"])

ADDED = [
    "(a guard is the declared function defining an event's predicate)",
    "#### Stage membership",
    "This section decides which of a component's values are public.",
    "It states the visibility rule, then the inspection path for an intermediate, then the checks that hold stage returns and declarations to each other.",
    "A snapshot is the immutable per-boundary publication.",
    "The return side is checked too.",
    "`StoreWithoutUpdate`",
    "`EventHalfMissing`",
    "(`x` for continuous state, `s` for discrete, D-195)",
    "the choice between declaration and inference-by-evaluation as the schema authority (§8.1)",
    "They ground error locality (the property that a mistake fails at the site of the mistake).",
    "(one declared input or output)",
    "A probe is the build's single evaluation of a user function.",
]

json.dump({"claims": C, "added": ADDED}, open("inventory.json", "w"), ensure_ascii=False, indent=1)
print(len(C), "claims")
