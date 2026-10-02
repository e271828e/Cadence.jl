### 8.7 Rate scopes

An [assembly](#g-assembly) schedules its children through one declaration,
`sample_times`. This section gives its spelling and its keys, then what it
never holds and why it belongs to the type.

The declaration maps each child name to a `Relative` or `Absolute` entry, as
in this one.

```julia
sample_times(::A) = (nav = Relative(5), gnss = Absolute(Hz(10)))
```

These are the two forms that [§10.5][s10-5] defines ([D-185][d-185]).
Relative entries compose affinely down the tree, absolute entries anchor, and
all are compiled to one `(D, Φ)` pair per discrete
[component](#g-component). [§10.5][s10-5] also holds the wrappers'
definitions, their validation and the default for an unlisted discrete child.
The declaration is optional, and so is any given key ([D-042][d-042]). Under
that default, only multiplied, phased or anchored children need appear.

**Keys are immediate child names only** ([D-042][d-042]). A deep key would
edit another type's design from outside, and the composition rule guarantees
an author never needs to.

Container elements ([§8.5][s8-5]) are immediate children, so
`"aircraft/red"` is a legal key, and `sample_times` needs no rule change for
them ([D-085][d-085]). The bare field name is sugar for a uniform declaration
across all elements. It applies one declaration to every element. The sugar
keys on the *field*, not on a path segment, so a name-transparent container
keeps it unchanged. `(children = Relative(2),)` is the uniform spelling for a
`Group`.

A `sample_times` key on a continuous child is a build error
([D-042][d-042]). It is the declaration-time side of a run-time fact. A
continuous bundle carries no `Δt` ([§10.5][s10-5]).

`Δt_base`, `h` and `N_base` appear in no declaration. They are deployment
decisions fixed at deployment ([D-254][d-254]). [§9.2][s9-2] gives the three
sources for `Δt_base`.

The declaration belongs to the assembly type, not to the child instance
([D-042][d-042]). The reason is that a sample time is a design ratio or a
modeled instrument's intrinsic rate ([§10.5][s10-5]), never a per-instance
value. An instance wrapper in the style of FlightCore's `Subsampled` is
rejected ([D-042][d-042]).

### 8.8 Computed connections and generic holding

`u_connections` and `y_connections` are ordinary functions evaluated at build
against the concrete instance ([D-043][d-043]). They may therefore *compute*
entries from child [contracts](#g-contract) (each child's declared
interface). That is derivation from declarations, which [§8.2][s8-2] blesses.
The section covers the passthrough helpers, the single authored feed list and
generic holding, in that order.

#### The passthrough helpers

The framework helper `input_passthrough` is sketched below. The sketch ends
with a `World` [assembly](#g-assembly) that passes up the input [faces](#g-face) (the names
ports wear on component boundaries) of its `aircraft` and `atmosphere`
children.

```julia
# the two shapes of `declaration_error` used below:
declaration_error(path::AbstractString, why::Symbol)      # e.g. :multiple_selectors
declaration_error(path::AbstractString, unknown, legal)   # did-you-mean against the legal set

function input_passthrough(assembly, child_path::AbstractString;
                     sep::AbstractString = ".",
                     prefix::AbstractString =               # "" → no prefixing
                         replace(child_path, "/" => sep),
                     except::Tuple = (), only::Tuple = (),  # one selector per call
                     select = nothing)                      # predicate over face names

    child = resolve(assembly, child_path)      # getfield walk along "/" segments
    names = input_faces(child)            # the leaf's u_types keys,
                                          # entries of u_connections(c) for an assembly
    given = !isempty(except) + !isempty(only) + (select !== nothing)
    given ≤ 1 ||
        declaration_error(child_path, :multiple_selectors)  # exclusivity enforced, not documented
    unknown = setdiff((except..., only...), names)
    isempty(unknown) || declaration_error(child_path, unknown, names)  # list in hand
    wanted = !isempty(only)     ? only :
             select !== nothing ? filter(select, names) :
                                  setdiff(names, except)
    # `given == 1` with an empty `wanted` is EmptyFaceSelection, a build warning
    # through §9.2's channel; a bare call over a faceless child is silent
    label(n) = isempty(prefix) ? n : string(prefix, sep, n)
    return Tuple(label(n) => string(child_path, "/", n) for n in wanted)
end

u_connections(w::World) = (
    input_passthrough(w, "aircraft"; except = ("atm", "trn"))...,   # "aircraft.pilot.throttle_axis"
    input_passthrough(w, "atmosphere"; prefix = "env", sep = "_")..., # "env_wind_N"
)

y_connections(w::World) = (
    "aircraft/pose" => "view_pose",
)
```

The child is named by path and never passed as an instance, because the `===`
problem ([§8.6][s8-6]) makes a path unrecoverable from an instance. A face
name containing dots is a legal final path segment on the internal-endpoint
side ([D-046][d-046]). That holds precisely because slash is the only structural
separator.

Computed entries mix freely with hand-written ones in either declaration
([D-043][d-043]). `resolve` and `input_faces` are build-pipeline primitives
needed anyway, and `input_passthrough` is a thin composition. That is what
keeps the helper sugar rather than machinery. There is no `rename` hook,
because the boundary declarations are ordinary code ([D-046][d-046]). An
author renames by mapping over the pairs. Normative signatures for both primitives are in
[§13.3][s13-3].

Every error stays first-class.

- An `except` face the assembly then fails to wire is an ordinary
  unconnected input.
- A face both wired and passed through is a two-producers error
  ([D-145][d-145]).
- `except` or `only` naming a nonexistent face errors with the child's face
  list in hand.
- A `prefix = ""` collision is caught by the build's uniqueness check like
  any hand-written duplicate.

**The selectors are exclusive** ([D-251][d-251]). A call takes `except`,
`only` or `select`, one of the three and no more. `select` is a predicate
over the child's face names, and the helper keeps the names it accepts. More
than one selector given is `UnknownFaceSelection` with reason
`:multiple_selectors`, "more than one selector given", its payload naming the
selectors given.

**A call that gives a selector and keeps nothing raises
`EmptyFaceSelection`**, a warning on the `Build`'s list ([§9.2][s9-2],
[D-251][d-251]). A bare call over a faceless child is silent, because passing
nothing through is what it asked for. The payload names the helper, the child
path, the selector given with its names, and the child's face list.

The warning exists because an empty selection is almost always a typo the
unknown-names check cannot see. An `only` may name faces that exist while a
`select` matches none, or an `except` may list every face. It warns rather
than errors because a level may legitimately pass nothing through under one
configuration of a generic child.

`select` exists for feed lists. At the scale of Flight.jl's C172X demo, the
feed list below already computes the `except` tuple. A closure over the same
list says the same thing without building the tuple.

The effective face list is plain printable data, the inspectable derived
contract of this instantiation. What computation does *not* do is auto-bubble
([D-043][d-043]). The author wrote down "every input face of this child that
I don't feed, I expose under this prefix", explicit at the type level and
evaluated at build.

The helpers come in pairs, because the name carries the direction
([D-171][d-171]). `input_passthrough` reads `input_faces(child)`, and the
selector filters *face names* within that set. The helper exists for the
pass-through case, where an assembly hands a child's unfed requirements up
one level. **`output_passthrough` is its sibling** ([D-209][d-209]). It is
splatted into `y_connections`, reads `output_faces(child)`, and has the same
`prefix`/`sep` surface, the same three exclusive selectors and the same
declaration-time error set.

```julia
y_connections(sys::Systems) = (
    output_passthrough(sys, "ldg"; only = ("damaged",))...,   # "ldg.damaged"
    "aero/wrench" => "wrench",
)
```

Its consumer is one-level routing ([§6.1][s6-1], [D-209][d-209]). Every
level re-exports the outputs it surfaces, so the output side needs the
computed spelling the input side already has.

Both helpers take `child_path` naming an immediate child, container key
segments included ([D-207][d-207]). The default `prefix` folds the path's
slash into `sep`, so `"gear/1"` labels its faces `"gear.1.…"` and the default
stays a legal face name for every blessed `child_path`. An explicit `prefix`
is used verbatim. A deeper path meets `resolve`'s one-level rejection like any
other wiring endpoint ([§13.3][s13-3], [D-207][d-207]).

There are two helpers rather than one keyword ([D-171][d-171]). The boundary
declarations split by direction into `u_connections` and `y_connections`, and
after that split a single call cannot emit entries into two different
declarations.

#### One authored feed list

The `World` example's two-entry `except` understates the real shape. Every
level of a realistic tree is a generic [seam](#g-seam) (a narrow, named
interface kept deliberately thin). An assembly that feeds some of a child's
input faces while passing the rest up must name the fed ones in `except`. At
the scale of Flight.jl's C172X demo, that is four seams and roughly ten names
at the innermost one. Each `except` tuple restates the wire list sitting in
the same assembly's `inner_connections`. That is structure kept in two
artifacts ([D-039][d-039]), the shape this design refuses elsewhere.

**Removing the duplication needs no vocabulary** ([D-145][d-145]). Declaration
bodies are ordinary code ([§8.5][s8-5]), so the author writes the feed list
*once* and both declarations compute their share of it. In the block below,
`Systems` holds an actuator child `act` whose output faces feed its `aero`
and `ldg` children.

```julia
# one authored artifact: actuator output face => destination child input face
const ACT_FEEDS = (
    "e"          => "aero/e",
    "a"          => "aero/a",
    "r"          => "aero/r",
    "brake_left" => "ldg/left.brake",
    …                                            # ~10 entries for the C172X
)

# the face names of `child` the feed list targets
fed_faces(feeds, child) = Tuple(chopprefix(dst, child * "/")
                                for (_, dst) in feeds
                                if startswith(dst, child * "/"))

inner_connections(::Systems) = (
    (("act/" * src) => dst for (src, dst) in ACT_FEEDS)...,
    "aero/wrench" => "wr_sum/in1",               # non-feed wires unchanged
    …
)

u_connections(sys::Systems) = (
    input_passthrough(sys, "aero"; except = fed_faces(ACT_FEEDS, "aero"))...,
    input_passthrough(sys, "ldg";  except = fed_faces(ACT_FEEDS, "ldg"))...,
    …
)
```

Adding an actuator channel is then one edit ([D-145][d-145]). The new pair
simultaneously creates the wire and removes the face from the input face
surface. The two declarations cannot drift, because neither holds the shared
names. Both are projections of the authored list, so the drift class is
removed rather than detected.

Every misspelling stays loud. A mistyped destination is an unknown-face error
with the child's face list in hand, whether the wire or the `except` entry
meets it first.

One asymmetry is stated openly. A pair *omitted* from the list is not an
error but a structural change. The face leaves the `except` set and joins the
input face surface, ultimately a [root input](#g-root-input) (the root
component's own input face) for conditions to cover ([§14.6][s14-6]). What the
idiom preserves, and the helper below surrenders, is that the feed statement
exists to be reviewed. An omission is legible in one authored artifact, not
defined away as the complement of the wire list.

The line not to cross is deriving `except` from `inner_connections` itself.
A helper spelled `except = fed(sys, "aero")`, reading the assembly's own wire
list, would cross it. That is auto-bubbling under another name
([D-043][d-043], [D-145][d-145]). **The single source must be authored data,
never inferred structure** ([D-145][d-145]).

#### Generic holding

**[Generic holding](#g-generic-holding) is an imposed derived contract**
([D-043][d-043]). A parent holding a child generically constrains it exactly
through the faces its wires and interface connections reference. Build a
`World` whose concrete aircraft lacks a referenced face, and the error names
the `World` entry. That is build-time structural typing with no new
vocabulary. A formal required-faces declaration on domain abstract types
remains possible sugar ([D-251][d-251]).

Scalar faces make partial scripting compose ([D-207][d-207]). A guidance
[scenario component](#g-scenario-component) (the home of a sim-time script)
wires two of the faces, `mode_req` and `EAS_ref`. The remaining faces stay
exported for GUI or defaults. That is impossible with a bundled face, under
the write-side rule of [§4.3][s4-3].

---
