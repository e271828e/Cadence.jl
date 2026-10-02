import json, os
H = os.path.dirname(os.path.abspath(__file__))
DEC = "docs/design/decisions.md"
C = []
def c(old, new, cites=(), newcites=None, tag="F", where="new", ruling=None):
    e = {"id": f"E1-{len(C)+1:03d}", "old": old, "new": new, "where": where,
         "cites": list(cites)}
    if newcites is not None: e["newcites"] = list(newcites)
    e["tag"] = tag
    if ruling: e["ruling"] = ruling
    C.append(e)

c("### 8.6 Paths, wiring and faces", "### 8.6 Paths, wiring and faces", tag="X")
c("Paths are slash-separated strings, relative to the assembly or model root they are read from, with no leading slash.",
  "Paths are slash-separated strings, relative to the assembly or model root they are read from, with no leading slash (D-040).",
  newcites=["D-040"], tag="C")
c("There is one canonical form, shared verbatim by declarations, error messages, device/trace addressing (§11.3) and the HDF5 log tree.",
  "There is one canonical form. Declarations, error messages, device/trace addressing (§11.3) and the HDF5 log tree share it verbatim.",
  ["§11.3"])
c("Container children (§8.5) add index and key segments, `\"aircraft/2\"` and `\"aircraft/red\"`, which are ordinary segments resolved against the container field.",
  "Container children (the elements of a `Tuple` or `NamedTuple` field holding only components, §8.5) add index and key segments, `\"aircraft/2\"` and `\"aircraft/red\"` (D-085). These are ordinary segments, resolved against the container field.",
  ["§8.5"], ["§8.5", "D-085"], tag="C")
c("A container declared name-transparent (§8.5) adds no segment of its own, and its elements go by bare key.",
  "A container declared name-transparent (§8.5) adds no segment of its own, and its elements go by bare key (D-211).",
  ["§8.5"], ["§8.5", "D-211"], tag="C")
c("Instance navigation, tuples of symbols and dotted paths were all rejected (D-040).",
  "Instance navigation, tuples of symbols and dotted paths were all rejected (D-040).",
  ["D-040"], tag="R", ruling="R4")
c("A path-tracking proxy remains addable sugar.",
  "Instance navigation: `===`-identical symmetric siblings make path-from-instance unrecoverable — proxies remain sugar.",
  where=DEC, tag="R", ruling="R4")
c("The three wiring declarations use only the short case of that form, one child segment and one face name (§6.1).",
  "The three wiring declarations use only the short case of that form, one child segment and one face name (§6.1, D-207).",
  ["§6.1"], ["§6.1", "D-207"], tag="C")
c("The read side walks the full depth (`\"systems/ldg/left/trn\"` in a snapshot or the log tree).",
  "The read side walks the full depth, as `\"systems/ldg/left/trn\"` does in a snapshot (the immutable per-boundary publication) or the log tree.")
c("That read side is the inspection side and `resolve` as the inspection primitive (§13.3).",
  "That read side is the inspection side. It resolves a path with `resolve` under the instance walk (§13.3).",
  ["§13.3"], tag="R", ruling="R7")
c("One fact from that adjudication is relied on downstream.",
  "One fact behind the rejection of instance navigation is relied on downstream.")
c("Symmetric immutable siblings are `===`-identical, so a path is unrecoverable from an instance.",
  "Symmetric immutable siblings are `===`-identical, so a path is unrecoverable from an instance.")
c("That is why the helpers (§8.8) name the child by path.",
  "That is why the helpers (§8.8) name the child by path.", ["§8.8"])
c("`inner_connections(::A)` is an ordered collection of `\"src/face\" => \"dst/face\"` pairs, strictly from a child face to a child face.",
  "`inner_connections(::A)` is an ordered collection of `\"src/face\" => \"dst/face\"` pairs. Every pair runs strictly from a child face to a child face (D-170).",
  newcites=["D-170"], tag="C")
c("The rules (§6.1) apply: one wire per input, and every endpoint an immediate child and one of its faces, container key segments included.",
  "The wiring rules apply (§6.1). There is one wire per input, and every endpoint is an immediate child and one of its faces, container key segments included.",
  ["§6.1"])
c("The assembly's boundary is declared by two further methods, one per direction.",
  "The assembly's boundary is declared by two further methods, one per direction (D-170).",
  newcites=["D-170"], tag="C")
c("`u_connections(::A)` is an ordered collection of pairs, face name => internal endpoint path, or a tuple of paths for an input face routed to several immediate children (fan-out through the boundary), as in `\"trn\" => (\"left/trn_field\", \"right/trn_field\", …)`.",
  "`u_connections(::A)` is an ordered collection of pairs, face name => internal endpoint path. An input face routed to several immediate children takes a tuple of paths instead, as in `\"trn\" => (\"left/trn_field\", \"right/trn_field\", …)`. This is fan-out through the boundary.")
c("Every entry routes to at least one internal endpoint.",
  "Every entry routes to at least one internal endpoint (D-210).", newcites=["D-210"], tag="C")
c("An empty tuple is a declaration error, because a face feeding nothing declares nothing (D-210).",
  "An empty tuple is a declaration error, because a face feeding nothing declares nothing (D-210).", ["D-210"])
c("`y_connections(::A)` runs the other way, internal source path => face name (`\"aircraft/pose\" => \"view_pose\"`), so that its pairs, like every other pair in the three declarations, read along the flow.",
  "`y_connections(::A)` runs the other way, internal source path => face name (`\"aircraft/pose\" => \"view_pose\"`), so that its pairs, like every other pair in the three declarations, read along the flow.")
c("Face names are arbitrary strings with two build-checked invariants.",
  "Face names are arbitrary strings with two build-checked invariants (D-046).", newcites=["D-046"], tag="C")
c("The first is that a face name contains no `/` (reserved for structural paths).",
  "The first is that a face name contains no `/`, which is reserved for structural paths.")
c("The second is uniqueness across the union of the two boundary declarations' face names.",
  "The second is uniqueness across the union of the two boundary declarations' face names (D-170).",
  newcites=["D-170"], tag="C")
c("Every other naming choice (separators, grouping prefixes like `\"pilot.throttle_axis\"`) is author convention, not framework law.",
  "Every other naming choice is author convention, not framework law. Separators and grouping prefixes like `\"pilot.throttle_axis\"` are such choices.")
c("The `input_passthrough` helper's defaults (§8.8) document the house style without legislating it.",
  "The `input_passthrough` helper's defaults (§8.8) document the house style without legislating it.", ["§8.8"])
c("At the root the uniqueness invariant follows the root's class (D-210).",
  "At the root the uniqueness invariant follows the root's class (D-210).", ["D-210"], tag="R", ruling="R6")
c("A primitive root declares no boundary methods, so its face set is the union of its `u_types` and `y_types` keys, and a key declared in both is the same build error a duplicate face name is.",
  "A primitive root declares no boundary methods. Its face set is therefore the union of its `u_types` and `y_types` keys. A key declared in both is the same build error a duplicate face name is.")
c("The root is where those two declarations first share an address space.",
  "The root is where those two declarations first share an address space.")
c("A root input places a cell the periphery writes (§11.3), so a collision would put two cells at one name.",
  "A root input places a cell the periphery writes (§11.3), so a collision would put two cells at one name.", ["§11.3"])
c("Below the root nothing collides, because a primitive's input faces alias their producers' cells and place nothing.",
  "Below the root nothing collides, because a primitive's input faces alias their producers' cells and place nothing.")
c("Non-root leaves are left alone.", "Non-root leaves are left alone.")
c("The two-notation rule this rests on is directional.", "The two-notation rule this rests on is directional.")
c("It separates structure from derived contract, not read from write.",
  "It separates structure from derived contract, not read from write (D-129).", newcites=["D-129"], tag="C")
c("Slash is structure: endpoint paths walking real children and ports, and the inspection side's snapshot and log addressing.",
  "Slash is structure. It covers endpoint paths walking real children and ports, and the inspection side's snapshot and log addressing.")
c("Face names are opaque derived-contract tokens.", "Face names are opaque derived-contract tokens.")
c("The periphery's write side (input devices, mappings, the trace, the GUI write path) speaks face names exclusively (§11.3).",
  "The periphery (everything outside the loop that exchanges data with it) has a write side, made of input devices, mappings, the trace and the GUI write path. That write side speaks face names exclusively (§11.3).",
  ["§11.3"])
c("The read side speaks them wherever it wants meaning that outlives the build, in integration bindings (`get_face`, §11.2) and service reads (§14.4).",
  "The read side speaks them wherever it wants meaning that outlives the build. It does so in integration bindings (`get_face`, §11.2) and service reads (§14.4).",
  ["§11.2", "§14.4"])
c("The three declarations return pairs of strings rather than NamedTuples (D-046).",
  "The three declarations return pairs of strings rather than NamedTuples (D-046).", ["D-046"])
c("One invariant spans all three declarations.", "The reason is one invariant that spans all three declarations.", tag="R", ruling="R6")
c("Every pair's arrow points the way the signal flows, with the left side a producer or entry point and the right side a consumer, and every right side is fed exactly once.",
  "Every pair's arrow points the way the signal flows. The left side is a producer or entry point, the right side is a consumer, and every right side is fed exactly once.",
  tag="R", ruling="R6")
c("Direction is therefore declared by the method, not inferred.",
  "Direction is declared by the method, not inferred (D-170).", newcites=["D-170"], tag="C")
c("The resolved endpoints only cross-check it, and an entry whose endpoint resolves to a port of the wrong direction is a build error naming the method, the entry and the resolved port's actual direction.",
  "The resolved endpoints only cross-check the direction. An entry whose endpoint resolves to a port of the wrong direction is a build error. The error names the method, the entry and the resolved port's actual direction.")
c("A mixed entry is not expressible, because the single list that made that error class possible does not exist.",
  "A mixed entry is not expressible, because the single list that made that error class possible does not exist.")
c("Two entries producing the same output face remain the ordinary two-producers error.",
  "Two entries producing the same output face remain the ordinary two-producers error (§6.1).",
  newcites=["§6.1"], tag="C")
c("Face types and tiers are derived from the internal endpoints, which is the blessed derivation-from-declarations (§8.2).",
  "Face types and tiers are derived from the internal endpoints (D-041). A tier is the continuous or discrete side of the hybrid formalism. This derivation is the blessed (explicitly sanctioned) derivation-from-declarations (§8.2).",
  ["§8.2"], ["D-041", "§8.2"], tag="C")
c("The derivation is forced, not merely convenient (D-041).",
  "The derivation is forced, not merely convenient.", ["D-041"])
c("An assembly is tier-neutral, exporting continuous-sourced and discrete-sourced ports side by side, and a face's cells follow the producer's own declaration (§8.5), evaluated at the activation scalar on the continuous tier and pinned on the discrete.",
  "An assembly is tier-neutral. It exports continuous-sourced and discrete-sourced ports side by side. A face's cells (entries of the signal table) follow the producer's own declaration (§8.2). They are retyped at the activation scalar by the leaf walk (the framework's derivation of per-activation types) on the continuous tier, and pinned on the discrete.",
  ["§8.5"], ["§8.2"], tag="R", ruling="K6")
c("Three alternative spellings are rejected (D-041, D-170)",
  "Three alternative spellings are rejected (D-041).", ["D-041", "D-170"], ["D-041"], tag="R", ruling="R4")
c("routing values under the leaf names `u_types`/`y_types`",
  "Routing values under leaf `inputs`/`outputs` names: name-level pun", where=DEC, tag="R", ruling="R4")
c("leaf-style typed faces with face wires inside `inner_connections`",
  "Leaf-style typed faces + face wires in `connections`: no `outputs` signature fits a tier-neutral assembly",
  where=DEC, tag="R", ruling="R4")
c("and routing-as-wires with derived types and no face list.",
  "Wires-only with implicit facehood: publicity never implicit.", where=DEC, tag="R", ruling="R4")
c("Publicity is never implicit (§8.3).", "Publicity is never implicit (§8.3).", ["§8.3"])
c("Root inputs fall out with no vocabulary.", "Root inputs fall out with no vocabulary of their own.", tag="R", ruling="R6")
c("At every non-root level an input face declared through `u_connections` is fed by the parent's wire.",
  "At every non-root level an input face declared through `u_connections` is fed by the parent's wire.", tag="R", ruling="R6")
c("At the root there is no parent, and the root component's input faces are the write surface, the set of faces a writer's batch entries may reach (§11.3).",
  "At the root there is no parent. There the root component's input faces are the write surface, the set of faces a writer's batch entries may reach (§11.3).",
  ["§11.3"], tag="R", ruling="R6")
c("Which declaration supplies them follows the root's class, `u_connections` keys for an assembly and `u_types` keys for a primitive (§8.2), and nothing downstream distinguishes the two.",
  "Which declaration supplies them follows the root's class (D-208). Class is a component's primitive-versus-assembly status. An assembly root supplies its `u_connections` keys, and a primitive root its `u_types` keys (§8.2). Nothing downstream distinguishes the two.",
  ["§8.2"], ["D-208", "§8.2"], tag="C")
c("The whole-tree obligation model (§6.1) states the complementary error rule.",
  "The whole-tree obligation model (§6.1) states the complementary error rule.", ["§6.1"], tag="R", ruling="R6")
c("An assembly never declares its external connections.",
  "An assembly never declares its external connections.", tag="R", ruling="R6")
c("Those live in the parent that instantiates it, exactly as a leaf's do.",
  "Those live in the parent that instantiates it, exactly as a leaf's do.", tag="R", ruling="R6")
c("A worked assembly.", "#### A worked assembly: the strapdown IMU", tag="R", ruling="R6")
c("The strapdown IMU of §3.4, spelled in full.",
  "The strapdown IMU of §3.4 is spelled here in full, as a worked example (a full spelling of a mechanism against a concrete case).",
  ["§3.4"])
c("It is a mixed-tier assembly exercising paths, faces and sample times together:",
  "It is a mixed-tier assembly. It exercises paths, faces and sample times together:")
# The IMU block, verbatim, in the pieces the paragraph splitter gives.
for piece in [
  "struct IMU <: AbstractComponent integrals::IMUIntegrals # continuous — cumulative Θ, q, Υ, V sampler::IMUSampler # discrete — integrate-and-difference latches errors::IMUErrorModel # discrete — scale/bias/noise on the sample end",
  "inner_connections(::IMU) = ( \"integrals/Θ\" => \"sampler/Θ\", \"integrals/q\" => \"sampler/q\", \"integrals/Υ\" => \"sampler/Υ\", \"integrals/V\" => \"sampler/V\", \"sampler/sample\" => \"errors/sample\", )",
  "u_connections(imu::IMU) = ( input_passthrough(imu, \"integrals\")..., # kinematic-truth inputs pass through )",
  "y_connections(::IMU) = ( \"sampler/sample\" => \"sample\", # ideal increments \"errors/sample_meas\" => \"sample_meas\", # measured increments (the error # model's output port) )",
  "sample_times(::IMU) = (sampler = Relative(1), errors = Relative(1))"]:
    c(piece, piece)
c("Two spellings are worth reading closely.", "Two spellings are worth reading closely.")
c("`input_passthrough` enumerates the child's input faces and nothing else (§8.8), which is why the pass-through of the integrals' kinematic-truth inputs (`q_eb`, `r_eb_e`, `ω_eb_b`, `a_ib_b`, `α_ib_b`) is a bare splat with nothing to say about direction.",
  "First, `input_passthrough` enumerates the child's input faces and nothing else (§8.8). That is why the pass-through of the integrals' kinematic-truth inputs (`q_eb`, `r_eb_e`, `ω_eb_b`, `a_ib_b`, `α_ib_b`) is a bare splat with nothing to say about direction.",
  ["§8.8"])
c("And the measured-increment face sources `errors/sample_meas`, the error model's output port, not the `errors/sample` input the sampler already feeds.",
  "Second, the measured-increment face sources `errors/sample_meas`, the error model's output port. It does not source `errors/sample`, the input the sampler already feeds.")
c("Listing `errors/sample` in `y_connections` would fail the direction cross-check, and listing it in `u_connections` while it is wired is the two-producers error of §8.8.",
  "Listing `errors/sample` in `y_connections` would fail the direction cross-check. Listing it in `u_connections` while it is wired is the two-producers error of §8.8.",
  ["§8.8"])
c("Three facts the example carries.", "The example carries two more facts.", tag="R", ruling="R7")
c("The assembly is tier-neutral.", "The first is that the assembly is tier-neutral.")
c("Every face's type and tier derive from its internal endpoint, and a `sample_times` key on `integrals`, the continuous child, would be a §8.7 build error.",
  "Every face's type and tier derive from its internal endpoint, and a `sample_times` key on `integrals`, the continuous child, would be a build error (§8.7).",
  ["§8.7"])
c("The two discrete children default to `Relative(1)` anyway, so this `sample_times` declaration is declaratory, and their absolute rate arrives from the enclosing scope at deployment (§8.7).",
  "The second is that the two discrete children default to `Relative(1)` anyway, so this `sample_times` declaration is declaratory. Their absolute rate arrives from the enclosing scope at deployment (§8.7).",
  ["§8.7"])
c("And the latch-back wire (below), where the integrals consume the sampler's published latch, joins `inner_connections` as one more ordinary pair.",
  "The latch-back wire (below, under \"The boundary-sampling contract\"), where the integrals consume the sampler's published latch, would join `inner_connections` as one more ordinary pair.",
  tag="R", ruling="R7")

ADDED = [
  "An assembly (a component of pure composition, with no dynamics of its own) wires its children and names its boundary with strings.",
  "This section fixes the path form, the three wiring declarations and the direction invariant they share, face names, root inputs (the root component's own input faces), and face uniqueness at the root.",
  "It then spells out a worked assembly, the strapdown IMU, and its leaves.",
  "It closes with the boundary-sampling contract.",
  "(the elements of a `Tuple` or `NamedTuple` field holding only components,",
  "A face is the name a port (one declared input or output) wears on its component's boundary.",
  "A device is any attached participant outside the loop, and the trace is the primary record of a session.",
  "(the immutable per-boundary publication)",
  "A tier is the continuous or discrete side of the hybrid formalism.",
  "(explicitly sanctioned)",
  "(entries of the signal table)",
  "(everything outside the loop that exchanges data with it)",
  "Class is a component's primitive-versus-assembly status.",
  "(a full spelling of a mechanism against a concrete case)",
]
json.dump({"claims": C, "added": ADDED}, open(os.path.join(H, "inventory.json"), "w"),
          ensure_ascii=False, indent=1)
