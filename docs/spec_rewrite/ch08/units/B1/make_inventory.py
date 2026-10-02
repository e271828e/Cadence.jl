import json, re, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "checks"))
from norm import norm, units
CITE = re.compile(r'§\d+(?:\.\d+)?|D-\d{3}|Appendix [A-D]')
O = norm(open(os.path.join(HERE, "old.md")).read())
NU = units(open(os.path.join(HERE, "new.md")).read())

claims = []
def c(old, new, tag="F", where="new", newcites=None, ruling=None):
    d = {"id": f"B1-{len(claims)+1:03d}", "old": old, "new": new, "where": where,
         "cites": sorted(set(CITE.findall(old)))}
    if newcites is not None and sorted(set(newcites)) != d["cites"]:
        d["newcites"] = sorted(set(newcites))
    d["tag"] = tag
    if ruling: d["ruling"] = ruling
    claims.append(d)

c("### 8.2 The declaration inventory", "### 8.2 The declaration inventory", "X")
c("One continuous primitive, declared end to end:", "One continuous primitive, declared end to end, shows them together:", "X")
# the Engine block, chunk by chunk (new.md splits it into paragraphs at its blank lines)
for u in NU:
    if u.startswith("```julia struct Engine") or (u.startswith("#") and not u.startswith("##")) or u.startswith("function y_direct") or u.startswith("x_deriv(eng"):
        s = u.removeprefix("```julia ").removesuffix(" ```")
        assert s in O, s[:60]
        c(s, s, "F")
c("The blocks below take that inventory declaration by declaration, and record where each schema fact gets its authority.",
  "This section takes the declarations of a component (the unit of modeling, leaf or assembly) one by one, and records where each schema fact gets its authority.", "X")
c("#### State, modes, discrete state", "#### The stores", "X")
c("Rule. `x_init` on the continuous tier, `s_init` on the discrete, and `m_init`, declare by initial value.",
  "`x_init` on the continuous tier, `s_init` on the discrete, and `m_init` declare by initial value (D-033).", "C", newcites=["D-033"])
c("The type is derived from the value.", "The type is derived from the value.")
c("The value is a `NamedTuple`, one named field per leaf, and no other form is admitted.",
  "The value is a `NamedTuple`, one named field per leaf, and no other form is admitted (D-247).", "C", newcites=["D-247"])
c("A bare leaf such as `x_init(::C) = 0.0` or `s_init(::C) = zeros(SVector{3})` is refused.",
  "A bare leaf such as `x_init(::C) = 0.0` or `s_init(::C) = zeros(SVector{3})` is refused.")
c("The structure step reports it as `StoreNotNamedTuple`, and the message spells the wrap (§9.1, Appendix C, D-247).",
  "The structure step (the build's first step, declaration reading only) reports it as `StoreNotNamedTuple`, and the message spells the wrap (§9.1, Appendix C, D-247).")
c("Rule. Every leaf declares exactly one of `x_init` and `s_init`,",
  "Every leaf declares exactly one of `x_init` and `s_init`,", "C", newcites=["D-263"])
c("and a stateless leaf declares it empty,", "and a stateless leaf declares it empty (D-263):")
c("`x_init(::Gain) = (;)` or `s_init(::Sampler) = (;)`.", "`x_init(::Gain) = (;) s_init(::Sampler) = (;)`")
c("The store is the tier marker,", "The store (the model's memory, declared by initial value) is the tier marker.")
c("so it is mandatory even when empty, exactly as `inner_connections` is mandatory even when empty because it is the class marker (§8.5, D-263).",
  "It is therefore mandatory even when empty, exactly as `inner_connections` is mandatory even when empty because it is the class marker (§8.5, D-263).")
c("A primitive declaring neither store is `TierUnreadable`, and its message spells the empty form.",
  "A primitive declaring neither store is `TierUnreadable`, and its message spells the empty form.")
c("An empty store owes no update law, since it has nothing to integrate or advance,",
  "An empty store owes no update law, since it has nothing to integrate or advance.")
c("and it puts no letter in the bundle (§5.2).", "It puts no letter in the bundle (§5.2).")
c("Why. A continuous component's state may be empty (§3.1), so a stateless continuous leaf is honestly a continuous leaf with zero state fields.",
  "A continuous component's state may be empty (§3.1), so a stateless continuous leaf is honestly a continuous leaf with zero state fields.")
c("Spelling that out puts every leaf's tier on the page in one place, stateful or not, with no tier by omission.",
  "Spelling that out puts every leaf's tier on the page in one place, stateful or not, with no tier by omission.")
c("It also closes a trap.", "It also closes a trap.")
c("A store lost to a local scope or to a forgotten import (§8.1) fails loud as a leaf declaring no store, where an optional marker would have dropped silently.",
  "A store lost to a local scope or to a forgotten import (§8.1) fails loud as a leaf declaring no store, where an optional marker would have dropped silently.")
c("Why. Every service reaches a leaf by its field name.", "every service reaches a leaf by its field name.")
c("The condition overlay merges on it (§14.1),", "A condition, the path-addressed sparse overlay that sets a build's state, merges on it (§14.1).")
c("readers and the trace spell it (§14.4),", "Readers and the trace spell it (§14.4).")
c("and a one-field store publishes its field as the port of that name (§5.3).", "", "R", newcites=[], ruling="R7")
c("The name a one-state component is asked for is the name every service then uses.",
  "The name a one-state component is asked for is the name every service then uses.")
c("There is consequently no second artifact to drift and no separate type declaration to check.",
  "Because the type is derived from the value, there is no second artifact to drift and no separate type declaration to check.")
c("The workspace (component-declared mutable scratch arriving as the `ws` bundle field)",
  "the workspace (component-declared mutable scratch), which is described below. The workspace arrives as the `ws` bundle field")
c("is the exception to that convention.", "The workspace is the exception to that convention.")
c("It is declared by allocation, as `ws_init(::C, ::Type{T})` on both tiers,",
  "It is declared by allocation, as `ws_init(::C, ::Type{T})` on both tiers (D-077, D-263).", "C", newcites=["D-077", "D-263"])
c("and the method itself is the allocator.", "The method itself is the allocator.")
c("A workspace earns the exception because it is not memory and none of the by-value arguments below cover it (§7.3).",
  "A workspace earns the exception because it is not memory and none of the by-value arguments below cover it (§7.3).")
c("`ws_init` alone declares by allocation, and nothing downstream derives from the type of what it returns.",
  "`ws_init` alone declares by allocation, and nothing downstream derives from the type of what it returns.")
c("This is the boundary of legitimate derivation.", "This is the boundary of legitimate derivation.")
c("Deriving from another declaration is sound, and deriving from evaluated user code is not.",
  "Deriving from another declaration is sound, and deriving from evaluated user code is not.")
c("Declaring types here too, `u_types`-style, with `probe_value` (§9.3) synthesizing the initial values, was rejected (D-073).",
  "Stores declared by type, with synthesized initial values, were rejected (D-073).", "R", newcites=["D-073"], ruling="R4")
c("`u_types`-style, with `probe_value` (§9.3) synthesizing the initial values",
  "`init_` as types + `probe_value` synthesis", "R", where="docs/design/decisions.md", ruling="R4")
c("Why. The declared values are the base layer of the condition substrate",
  "The declared values are the base layer of the condition substrate.")
c("(a condition is the path-addressed sparse overlay that sets a build's state).",
  "A condition, the path-addressed sparse overlay that sets a build's state,")
c("The overlays (§14.1) fall back to them leaf by leaf, and the compiled store writers bake `merge(defaults, overlay)`,",
  "The overlays (§14.1) fall back to the declared values leaf by leaf, and the compiled store writers bake `merge(defaults, overlay)`.")
c("so there must be an authored value under every leaf.", "There must therefore be an authored value under every leaf.")
c("The asymmetry against `u_types`/`y_types` is one of kind, not style.",
  "The asymmetry against `u_types`/`y_types` is one of kind, not style.")
c("Contracts describe table cells,",
  "Contracts (a component's declared interfaces) describe table cells (the signal table's typed entries). There is one cell per output port")
c("which are recomputed from scratch every sweep, and so need only types.",
  "Cells are recomputed from scratch every sweep (one pass through the execution order), so contracts need only types.")
c("`init_` describe stores, the model's memory, which must have contents before the first sweep can run.",
  "`x_init`, `s_init` and `m_init` describe stores, which must have contents before the first sweep can run.")
c("Every declaration but the allocator takes the component alone,",
  "Every declaration of a structural fact but the allocator takes the component alone (D-263).", "R", newcites=["D-263"], ruling="R7")
c("and the criterion is the declaration convention it lives in (D-263).",
  "The criterion is the convention each declaration lives in.", "F", newcites=["D-263"])
c("It is stated once here, and the blocks below refer back to it.", "It is stated once here, and the blocks below refer back to it.")
c("A by-value declaration states nominal physics, and its types walk by rule (the derivation of per-activation types from a declared nominal type).",
  "A by-value declaration states nominal physics, and its types walk by rule (the derivation of per-activation types from a declared nominal type).")
c("§7.1 forces every state leaf to follow the activation scalar (the build's typed products at a given scalar type),",
  "§7.1 forces every state leaf to follow the scalar of the activation (the build's typed products at a given scalar type).")
c("so nothing is left for a signature to record.", "Nothing is therefore left for a signature to record.")
c("Partials enter through per-invocation seeding, never through initialization.",
  "Partials enter through per-invocation seeding, never through initialization (D-079).", "C", newcites=["D-079"])
c("A by-type declaration walks by the same rule,", "A by-type declaration walks by the same rule.")
c("and where a leaf must not follow the scalar the author says so at the leaf, with `Pinned`,",
  "Where a leaf must not follow the scalar, the author says so at the leaf with `Pinned` (the leaf marker `Pinned{P}`, which yields `P` at every activation).")
c("which is why `u_types` and `y_types` take the component alone too.", "That is why `u_types` and `y_types` take the component alone too.")
c("A by-allocation declaration is the exception.", "A by-allocation declaration is the exception.")
c("It builds values the framework may not rebuild, so the scalar can come from nowhere but its own argument,",
  "It builds values the framework may not rebuild, so the scalar can come from nowhere but its own argument.")
c("and `ws_init(c, T)` takes it on both tiers (D-077).",
  "`ws_init(c, T)` takes it on both tiers, the continuous and the discrete (D-077).")
c("The criterion, not uniformity, is the rule.", "The criterion, not uniformity, is the rule.")
c("A `T` in a signature means the framework could not have supplied it.", "A `T` in a signature means the framework could not have supplied it.")

added = [
  "The store names each leaf because",
  "`ws_init` allocates",
  "which is described below.",
  "Because the type is derived from the value",
  "`x_init(::Gain) = (;) s_init(::Sampler) = (;)`",
  "(the unit of modeling, leaf or assembly)",
  "shows them together",
  "(the build's first step, declaration reading only)",
  "(the `NamedTuple` of views a component function receives)",
  "(one declared input or output)",
]
json.dump({"claims": claims, "added": added}, open(os.path.join(HERE, "inventory.json"), "w"), indent=1, ensure_ascii=False)
print(len(claims), "claims")
