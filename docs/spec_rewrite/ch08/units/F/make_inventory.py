"""Builds inventory.json for unit F. Run from docs/spec_rewrite."""
import json, re, sys
sys.path.insert(0, "checks")
from norm import norm, units

U = "ch08/units/F"
O = norm(open(f"{U}/old.md").read())
NEWRAW = open(f"{U}/new.md").read()
CITE = re.compile(r'§\d+(?:\.\d+)?|D-\d{3}|Appendix [A-D]')
SPEC = "docs/design/spec.md"

C = []
def c(old, new, tag="F", newcites=None, where="new", ruling=None):
    d = {"id": f"F-{len(C)+1:03d}", "old": old, "new": new, "where": where,
         "cites": sorted(set(CITE.findall(old))), "tag": tag}
    if newcites is not None: d["newcites"] = newcites
    if ruling: d["ruling"] = ruling
    C.append(d)

# code blocks: one claim per blank-line chunk of each block
def code_claims(first_line):
    i = NEWRAW.index(first_line)
    start = NEWRAW.rindex("```julia\n", 0, i) + len("```julia\n")
    end = NEWRAW.index("\n```", start)
    for chunk in re.split(r'\n\s*\n', NEWRAW[start:end]):
        t = norm(chunk)
        assert t in O, t[:60]
        c(t, t)

# §8.7
c("### 8.7 Rate scopes", "### 8.7 Rate scopes")
c("The declaration is `sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))`, mapping each child name to a `Relative` or `Absolute` entry.",
  "The declaration maps each child name to a `Relative` or `Absolute` entry, as in this one.")
c("`sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))`", "`sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))`")
c("These are the two forms of §10.5.", "These are the two forms that §10.5 defines (D-185).", "C", ["§10.5", "D-185"])
c("Relative entries compose affinely down the tree, absolute entries anchor, and all are compiled to one `(D, Φ)` pair per discrete component.",
  "Relative entries compose affinely down the tree, absolute entries anchor, and all are compiled to one `(D, Φ)` pair per discrete component", "R", ruling="R3")
c("The wrappers are the whole value vocabulary, so a bare integer or bare quantity is a declaration error.",
  "The wrappers are the whole vocabulary (D-185). A bare integer or bare quantity is a declaration error.", "R", where=SPEC, ruling="R3")
c("The declaration is optional, and so is any given key.", "The declaration is optional, and so is any given key (D-042).", "C", ["D-042"])
c("An unlisted discrete child defaults to `Relative(1)`", "Since an unlisted discrete child defaults to `Relative(1)` (§10.5),", "F", ["§10.5"])
c(", so only multiplied, phased or anchored children need appear.", "only multiplied, phased or anchored children need appear.")
c("Keys are immediate child names only.", "Keys are immediate child names only (D-042).", "C", ["D-042"])
c("A deep key would edit another type's design from outside, and the composition rule guarantees you never need to.",
  "A deep key would edit another type's design from outside, and the composition rule guarantees an author never needs to.")
c("Container elements (§8.5) are immediate children, so `\"aircraft/red\"` is a legal key,",
  "Container elements (§8.5) are immediate children, so `\"aircraft/red\"` is a legal key,")
c("and the bare field name applies one declaration to every element.", "The bare field name is sugar that applies one uniform declaration across all elements.")
c("A `sample_times` key on a continuous child is a build error", "A `sample_times` key on a continuous child is a build error (D-042).", "C", ["D-042"])
c("(the Δt-on-continuous error at declaration time, §10.5).",
  "It is the declaration-time side of a run-time fact. A continuous bundle (the `NamedTuple` of views a component function receives) carries no `Δt` (§10.5).", "R", ruling="R7")
c("`Δt_base`, `h` and `N_base` appear in no declaration.", "`Δt_base`, `h` and `N_base` appear in no declaration.")
c("They are deployment decisions fixed at deployment", "They are deployment decisions fixed at deployment (D-254).", "C", ["D-254"])
c("(the three sources for `Δt_base`, §9.2).", "§9.2 gives the three sources for `Δt_base`.")
c("The declaration belongs to the assembly type, not to the child instance,",
  "The declaration belongs to the assembly type, not to the child instance (D-042).", "C", ["D-042"])
c("because a sample time is a design ratio or a modeled instrument's intrinsic rate (§10.5), never a per-instance value.",
  "The reason is that a sample time is a design ratio or a modeled instrument's intrinsic rate (§10.5), never a per-instance value.")
c("The FlightCore-`Subsampled`-style instance wrapper is rejected in D-042.",
  "An instance wrapper in the style of FlightCore's `Subsampled` is rejected (D-042).")

# §8.8
c("### 8.8 Computed connections and generic holding", "### 8.8 Computed connections and generic holding")
c("`u_connections` and `y_connections` are ordinary functions evaluated at build against the concrete instance,",
  "`u_connections` and `y_connections` are ordinary functions evaluated at build against the concrete instance.")
c("so they may compute entries from child contracts.", "They may therefore compute entries from child contracts")
c("That is derivation from declarations, which §8.2 blesses.", "That is derivation from declarations, which §8.2 blesses.")
c("The framework helper, sketched:", "The framework helper `input_passthrough` is sketched below.")
code_claims("# the two shapes of `declaration_error`")
c("The child is named by path and never passed as an instance, because the `===` problem (§8.6) makes a path unrecoverable from an instance.",
  "The child is named by path and never passed as an instance, because the `===` problem (§8.6) makes a path unrecoverable from an instance.")
c("A face name containing dots is a legal final path segment on the internal-endpoint side,",
  "A face name containing dots is a legal final path segment on the internal-endpoint side (D-046).", "C", ["D-046"])
c("precisely because slash is the only structural separator.", "That holds precisely because slash is the only structural separator.")
c("Computed entries mix freely with hand-written ones in either declaration.",
  "Computed entries mix freely with hand-written ones in either declaration.")
c("`resolve` and `input_faces` are build-pipeline primitives needed anyway, and `input_passthrough` is a thin composition. That is what keeps the helper sugar rather than machinery.",
  "`resolve` and `input_faces` are build-pipeline primitives needed anyway, and `input_passthrough` is a thin composition. That is what keeps the helper sugar rather than machinery.")
c("There is no `rename` hook, because the boundary declarations are ordinary code",
  "There is no `rename` hook, because the boundary declarations are ordinary code (D-046).", "C", ["D-046"])
c("(map over the pairs).", "An author renames by mapping over the pairs.")
c("Normative signatures for both primitives are in §13.3.", "Normative signatures for both primitives are in §13.3.")
c("Every error stays first-class.", "Every error stays first-class.")
c("An `except` face the assembly then fails to wire is an ordinary unconnected input.",
  "An `except` face the assembly then fails to wire is an ordinary unconnected input.")
c("A face both wired and passed through is a two-producers error.",
  "A face both wired and passed through is a two-producers error (D-145).", "C", ["D-145"])
c("`except` or `only` naming a nonexistent face errors with the child's face list in hand.",
  "`except` or `only` naming a nonexistent face errors with the child's face list in hand.")
c("A `prefix = \"\"` collision is caught by the build's uniqueness check like any hand-written duplicate.",
  "A `prefix = \"\"` collision is caught by the build's uniqueness check like any hand-written duplicate.")
c("Rule. The selectors are exclusive.", "The selectors are exclusive (D-251).", "F", ["D-251"])
c("A call takes `except`, `only` or `select`, one of the three and no more (D-251).",
  "A call takes `except`, `only` or `select`, one of the three and no more.", "F", [])
c("`select` is a predicate over the child's face names, and the helper keeps the names it accepts. More than one selector given is `UnknownFaceSelection` with reason `:multiple_selectors`, \"more than one selector given\", its payload naming the selectors given.",
  "`select` is a predicate over the child's face names, and the helper keeps the names it accepts. More than one selector given is `UnknownFaceSelection` with reason `:multiple_selectors`, \"more than one selector given\", its payload naming the selectors given.")
c("Rule. A call that gives a selector and keeps nothing raises `EmptyFaceSelection`, a warning on the `Build`'s list (§9.2, D-251).",
  "A call that gives a selector and keeps nothing raises `EmptyFaceSelection`, a warning on the `Build`'s list (§9.2, D-251).")
c("A bare call over a faceless child is silent, because passing nothing through is what it asked for. The payload names the helper, the child path, the selector given with its names, and the child's face list.",
  "A bare call over a faceless child is silent, because passing nothing through is what it asked for. The payload names the helper, the child path, the selector given with its names, and the child's face list.")
c("Why. An empty selection is almost always a typo the unknown-names check cannot see.",
  "The warning exists because an empty selection is almost always a typo the unknown-names check cannot see.")
c("An `only` may name faces that exist while a `select` matches none, or an `except` may list every face. It warns rather than errors because a level may legitimately pass nothing through under one configuration of a generic child.",
  "An `only` may name faces that exist while a `select` matches none, or an `except` may list every face. It warns rather than errors because a level may legitimately pass nothing through under one configuration of a generic child.")
c("Why `select` exists.", "`select` exists for feed lists, the idiom of \"One authored feed list\" below.", "X")
c("At C172X scale", "At the scale of Flight.jl's C172X demo", "M")
c("the feed list below already computes the `except` tuple.", "There the feed list already computes the `except` tuple.")
c("A closure over the same list says the same thing without building the tuple.",
  "A closure over the same list says the same thing without building the tuple.")
c("The effective face list is plain printable data, the inspectable derived contract of this instantiation.",
  "The effective face list is plain printable data, the inspectable derived contract of this instantiation.")
c("What computation does not do is auto-bubble.", "What computation does not do is auto-bubble (D-043).", "C", ["D-043"])
c("The author wrote down \"every input face of this child that I don't feed, I expose under this prefix\", explicit at the type level and evaluated at build.",
  "The author wrote down \"every input face of this child that I don't feed, I expose under this prefix\", explicit at the type level and evaluated at build.")
c("The name carries the direction, so the helpers come in pairs.",
  "The helpers come in pairs, because the name carries the direction (D-171).", "C", ["D-171"])
c("`input_passthrough` reads `input_faces(child)`, and the selector filters face names within that set. The helper exists for the pass-through case, where an assembly hands a child's unfed requirements up one level.",
  "`input_passthrough` reads `input_faces(child)`, and the selector filters face names within that set. The helper exists for the pass-through case, where an assembly hands a child's unfed requirements up one level.")
c("`output_passthrough` is its sibling (D-209). It is splatted into `y_connections`, reads `output_faces(child)`, and has the same `prefix`/`sep` surface, the same three exclusive selectors and the same declaration-time error set.",
  "`output_passthrough` is its sibling (D-209). It is splatted into `y_connections`, reads `output_faces(child)`, and has the same `prefix`/`sep` surface, the same three exclusive selectors and the same declaration-time error set.")
code_claims("output_passthrough(sys, \"ldg\"")
c("Its consumer is one-level routing (§6.1).", "`output_passthrough`'s consumer is one-level routing (§6.1, D-209).", "C", ["§6.1", "D-209"])
c("Every level re-exports the outputs it surfaces, so the output side needs the computed spelling the input side already has.",
  "Every level re-exports the outputs it surfaces, so the output side needs the computed spelling the input side already has.")
c("Both helpers take `child_path` naming an immediate child, container key segments included.",
  "Both helpers take `child_path` naming an immediate child, container key segments included (D-207).", "C", ["D-207"])
c("The default `prefix` folds the path's slash into `sep`, so `\"gear/1\"` labels its faces `\"gear.1.…\"` and the default stays a legal face name for every blessed `child_path`. An explicit `prefix` is used verbatim.",
  "The default `prefix` folds the path's slash into `sep`, so `\"gear/1\"` labels its faces `\"gear.1.…\"` and the default stays a legal face name for every blessed `child_path`. An explicit `prefix` is used verbatim.")
c("A deeper path meets `resolve`'s one-level rejection like any other wiring endpoint (§13.3).",
  "A deeper path meets `resolve`'s one-level rejection like any other wiring endpoint (§13.3, D-207).", "C", ["§13.3", "D-207"])
c("There are two helpers rather than one keyword,", "There are two helpers rather than one keyword (D-171).", "C", ["D-171"])
c("because after the boundary split a single call cannot emit entries into two different declarations.",
  "and after that split a single call cannot emit entries into two different declarations.")
c("One authored list, two declarations.", "#### One authored feed list", "X")
c("The `World` example's two-entry `except` understates the real shape.", "The `World` example's two-entry `except` understates the real shape.")
c("Every level of a realistic tree is a generic seam,", "Every level of a realistic tree is a generic seam")
c("and an assembly that feeds some of a child's input faces while passing the rest up must name the fed ones in `except`.",
  "An assembly that feeds some of a child's input faces while passing the rest up must name the fed ones in `except`.")
c("At C172X scale that is four seams and roughly ten names at the innermost one,",
  "At the scale of Flight.jl's C172X demo, that is four seams and roughly ten names at the innermost one.")
c("restating in each `except` tuple the wire list sitting in the same assembly's `inner_connections`.",
  "Each `except` tuple restates the wire list sitting in the same assembly's `inner_connections`.")
c("That is \"structure kept in two artifacts\" (§8.1; D-039),", "That is structure kept in two artifacts (D-039),", "R", ["D-039"], ruling="R7")
c("the shape this design refuses elsewhere.", "the shape this design refuses elsewhere.")
c("It needs no vocabulary.", "Removing the duplication needs no vocabulary (D-145).", "C", ["D-145"])
c("Declaration bodies are ordinary code (§8.5), so the author writes the feed list once and both declarations compute their share of it.",
  "Declaration bodies are ordinary code (§8.5), so the author writes the feed list once and both declarations compute their share of it.")
code_claims("# one authored artifact")
c("Adding an actuator channel is then one edit.", "Adding an actuator channel is then one edit (D-145).", "C", ["D-145"])
c("The new pair simultaneously creates the wire and removes the face from the input face surface. The two declarations cannot drift, because neither holds the shared names. Both are projections of the authored list, so the drift class is removed rather than detected.",
  "The new pair simultaneously creates the wire and removes the face from the input face surface. The two declarations cannot drift, because neither holds the shared names. Both are projections of the authored list, so the drift class is removed rather than detected.")
c("Every misspelling stays loud. A mistyped destination is an unknown-face error with the child's face list in hand, whether the wire or the `except` entry meets it first.",
  "Every misspelling stays loud. A mistyped destination is an unknown-face error with the child's face list in hand, whether the wire or the `except` entry meets it first.")
c("One asymmetry is stated openly. A pair omitted from the list is not an error but a structural change. The face leaves the `except` set and joins the input face surface, ultimately a root input",
  "One asymmetry is stated openly. A pair omitted from the list is not an error but a structural change. The face leaves the `except` set and joins the input face surface, ultimately a root input")
c("for conditions to cover (§14.6). What the idiom preserves, and the helper below surrenders, is that the feed statement exists to be reviewed. An omission is legible in one authored artifact, not defined away as the complement of the wire list.",
  "for conditions, the data that set a build's state, to cover (§14.6). What the idiom preserves, and the helper below surrenders, is that the feed statement exists to be reviewed. An omission is legible in one authored artifact, not defined away as the complement of the wire list.")
c("The line not to cross is deriving `except` from `inner_connections` itself,",
  "The line not to cross is deriving `except` from `inner_connections` itself.")
c("for instance a helper spelled `except = fed(sys, \"aero\")` that reads the assembly's own wire list.",
  "A helper spelled `except = fed(sys, \"aero\")`, reading the assembly's own wire list, would cross it.")
c("That is auto-bubbling under another name (D-043, D-145).", "That is auto-bubbling under another name (D-043, D-145).")
c("The single source must be authored data, never inferred structure.",
  "The single source must be authored data, never inferred structure (D-145).", "C", ["D-145"])
c("Generic holding is an imposed derived contract.", "Generic holding is an imposed derived contract (D-043).", "C", ["D-043"])
c("A parent holding a child generically constrains it exactly through the faces its wires and interface connections reference. Build a `World` whose concrete aircraft lacks a referenced face, and the error names the `World` entry.",
  "A parent holding a child generically constrains it exactly through the faces its wires and interface connections reference. Build a `World` whose concrete aircraft lacks a referenced face, and the error names the `World` entry.")
c("That is build-time structural typing with no new vocabulary", "That is build-time structural typing with no new vocabulary.")
c("(a formal required-faces declaration on domain abstract types remains possible sugar).",
  "A formal required-faces declaration on domain abstract types remains possible sugar (D-251).", "C", ["D-251"])
c("Scalar faces make partial scripting compose.", "Scalar faces make partial scripting compose (D-207).", "C", ["D-207"])
c("A guidance scenario component wires `mode_req` and `EAS_ref`", "A guidance scenario component")
c("`mode_req` and `EAS_ref`", "wires `mode_req` and `EAS_ref`")
c("while the remaining faces stay exported for GUI or defaults,", "The remaining faces stay exported for GUI or defaults.")
c("which is impossible with a bundled face (§4.3 write-side rule).",
  "That is impossible with a bundled face, under the write-side rule of §4.3.")
c("---", "---")

# the moved-in sugar paragraph (M3), merged into §8.7's container paragraph
c("`sample_times` needs no rule change.", "and `sample_times` needs no rule change for them (D-085).", "C", ["D-085"])
c("Element names are immediate child names, hence legal keys,", "Container elements (§8.5) are immediate children, so `\"aircraft/red\"` is a legal key,", "M")
c("and the bare field name is sugar for a uniform declaration across all elements.",
  "The bare field name is sugar that applies one uniform declaration across all elements.")
c("The sugar keys on the field, not on a path segment, so a name-transparent container keeps it unchanged.",
  "The sugar keys on the field, not on a path segment, so a name-transparent container keeps it unchanged.")
c("`(children = Relative(2),)` is the uniform spelling for a `Group`.",
  "`(children = Relative(2),)` is the uniform spelling for a `Group`.", "R", ruling="R1")

ADDED = [
    "An assembly (a component of pure composition) schedules its children through one declaration, `sample_times`, its rate scope. This section gives its spelling and its keys, then what it never holds and why it belongs to the type.",
    "§10.5 also holds the wrappers' definitions and their validation.",
    "(each child's declared interface)",
    "The section covers the passthrough helpers, the single authored feed list and generic holding (a parent holding a child through a non-concrete field type), in that order.",
    "#### The passthrough helpers",
    "The sketch ends with a `World` assembly, a component of pure composition. It passes up the input faces (the names ports wear on component boundaries) of its `aircraft` and `atmosphere` children.",
    "(a narrow, named interface kept deliberately thin).",
    "In the block below, `Systems` is an assembly whose children include `aero` and `ldg`.",
    "In the block below, `Systems` also holds an actuator child `act` whose output faces feed `aero` and `ldg`.",
    "The boundary declarations split by direction into `u_connections` and `y_connections`,",
    ", the equivalent-airspeed reference.",
    "(the root component's own input face)",
    "#### Generic holding",
    "(the home of a sim-time script)",
    ", the data that set a build's state,",
    "(the `NamedTuple` of views a component function receives)",
]

json.dump({"claims": C, "added": ADDED}, open(f"{U}/inventory.json", "w"), ensure_ascii=False, indent=1)
print(len(C), "claims")
