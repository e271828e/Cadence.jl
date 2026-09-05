# Agent B — §8, the declaration layer

**Slice.** `docs/design/spec.md` §8, lines 1648–2846 (§8.1 position, §8.2 the
declaration inventory, §8.3 visibility, §8.4 failure walkthroughs, §8.5
assembly declaration and class, §8.6 paths/wiring/faces, §8.7 rate scopes,
§8.8 computed connections).

**Tip.** `70672d1`. Julia 1.12.7.

**Probes.** Eight, all foreground `julia --project=.` from the repository root,
scripts in the session scratchpad: the D-168 fan-out meet at a `Dual`
activation (both consumer orders), abstract entries and abstract-at-root, the
untaken-branch shape and type drift under a running simulation, an `init_x`
with an `Int` leaf, a container of containers, auto-publication of a state
field, and §8.4's walkthrough 5.

**Forbidden reads.** None. I read `docs/design/spec.md` (my range plus the
cited §5.2, §6.1, §7.1 passages for meaning), all of `src/` and `test/`, the
"What is real here" file table in `docs/design/implementation.md`, and the
`D-167` and `D-168` entries of `docs/design/decisions.md`.

## Summary

The declaration layer is the most faithfully built part of the package I
looked at. The seventeen well-known functions all exist with the spec's
arities and registers; class-by-declaration-shape, tier-by-declaration-shape,
container children with the full D-211/D-212 collision family, `Group`, the
one-level path rule, the two face-name invariants, the direction cross-check,
the rate fold and both passthrough helpers are built, diagnosed and tested,
usually more precisely than the prose. §8.5–§8.8 are close to clean.

The gaps cluster in two places, and both are in §8.2–§8.3.

The first is **the activation-scalar side of the contract**. Three obligations
that the spec places in Stratum A, at the nominal build, are either absent or
deferred to a lazily materialized non-nominal activation. There is no
walk-compatibility clause and no `WalkingFaceAtFrozenEntry`: a walking
producer wired into a `Float64` entry builds without complaint and only fails
if someone asks for a `Dual` activation, which nothing forces. The D-168
fan-out meet is not implemented at all — the root-input type at a non-nominal
activation is the *first* consumer's entry in flatten order, so the same model
builds or fails depending on which consumer the walk reaches first, and when
the tolerant consumer comes first the build delivers `Dual`s to an entry that
declared it cannot take them. That is the "join semantics" alternative D-168
explicitly rejects. And abstract reference-typed entries — the field handles
§8.2 names as the demonstrated client — are refused: the bound check is
structural equality, never `<:`, so a concrete producer at an
`AbstractTerrainField` entry is a `WireTypeMismatch`, and the same entry at
the root escapes into a bare `ArgumentError: type does not have a definite
number of fields` with no path, no face and no remedy where `AbstractAtRoot`
should be.

The second is **the always-on conformance register**. Auto-publication does
not exist: §8.2's own worked `Engine`, whose `output_types` declares `ω` for a
state field no stage produces, does not build. The always-on `NamedTuple`-type
check does not exist either; what stands in its place is the per-port
`getfield` inside `scatter_group!`, which catches a *missing* declared key
loudly (wrapped in a `StepError` naming the component and the stage — good)
but silently drops an undeclared extra field and silently converts a
wrong-typed one. A stage that returns `a = 7` where `a = T` is declared runs to
completion and writes `7.0`.

Three smaller absences are worth naming. §8.1's shadowing check — the
normative mitigation for the missing-`import` trap, promised on both
`StoreWithoutUpdate` and `ClassUnreadable` — is nowhere in `src/`. §8.2's
`init_x` continuous-vocabulary check is nowhere either, so `init_x =
(gear_count = 3, ω = 0.0)` builds and the `Int` silently becomes a `Float64`
in the flat buffer. And a container of containers, which §8.5 says is
rejected, is silently classified as inert parameter data: my probe built a
`Nested` holding three real components and got a model with zero components in
it.

`TierSignatureMismatch` does not exist as a kind. The check it names is built
and tested, under `DeclarationOnWrongTier(reason = :tier_form)`, with a
payload that reports the two *tiers* rather than the two *forms*, and it is
collected within one component but fail-fast across components.

What surprised me, in the other direction: the D-212 bare-key collision
family, the empty-route refusal, the `_pin_hint` didactic message and the
`_check_root_faces` primitive-root invariant are all built exactly as written,
each with a test that asserts the payload and not just the throw.

## Findings

| § | claim | verdict | location | test | note |
| --- | --- | --- | --- | --- | --- |
| §8 1648–1655 | part preamble, forward references | n/a | — | — | not an obligation |
| §8.1 1670–1675 | no macro DSL; authoring is ordinary Julia | accurate | `src/declare.jl:1-329` | no test | the whole authoring surface is plain functions |
| §8.1 1676–1691 | redundancy accepted, macro door left open (D-032, D-166) | n/a | — | — | rationale |
| §8.1 1693–1700 | framework-owned generics are extended, not called | accurate | `src/declare.jl:22-227` | whole suite | fallbacks on `::Any`, methods added per type |
| §8.1 1702–1710 | the 17-name import list exists as framework functions | accurate | `src/declare.jl:22,30,37,46,55,68,82,89,95,108,171,193,202,224-227` | — | package is `Cadence`, not `Flight` |
| §8.1 1712–1723 | why a bare `using` is a silent trap | n/a | — | — | rationale |
| §8.1 1725–1735 | the two diagnostics run a shadowing check naming the missing import | absent | — | — | see 4.1 |
| §8.1 1737–1752 | the local-scope sibling (D-164) | n/a | — | — | rationale |
| §8.1 1756–1758 | a component declaring nothing and defining no stage is rejected at build | accurate | `src/assembly.jl:40-50` | `test_assembly.jl:40` | `ClassUnreadable` |
| §8.1 1764–1770 | a partially shadowed component reads as declared-but-unproduced | accurate | `src/build.jl:529-536` | `test_build.jl:32` | `DeclaredNotProduced`; no shadowing note attached |
| §8.1 1771–1776 | declarations define structure, evaluation only checks it | accurate | `src/build.jl:114-131,483-521` | `test_build.jl:28` | probes real values, no inference |
| §8.1 1777–1779 | the same comparison runs on every evaluation, a `NamedTuple`-type check | stand-in | `src/store.jl:81-88`, `src/executor.jl:144-148` | none | see 4.8 |
| §8.1 1780–1784 | inference-by-evaluation rejected (D-032) | n/a | — | — | rejected alternative |
| §8.1 1786–1795 | contract declarations discard the instance's values (the `::Type{T}` form) | accurate | `src/declare.jl:55,68` | — | the signature shape is built |
| §8.1 1796–1806 | the rule is one authors keep, not a check the build runs | n/a | — | — | spec states no check is possible |
| §8.1 1808–1814 | `init_workspace` is the one exception, sized from the instance | accurate | `src/declare.jl:46`, `src/build.jl:462-465` | `fixtures.jl:151` | |
| §8.2 1821–1867 | the worked `Engine` inventory | n/a | — | — | example; its `ω` claim is scored under §8.3 |
| §8.2 1869–1876 | `init_x`/`init_s`/`init_m` declare by initial value, types derived | accurate | `src/declare.jl:22,30,37`, `src/build.jl:34-38` | `test_declare.jl:35` | |
| §8.2 1877–1885 | the workspace is the by-allocation exception, arity split by tier | accurate | `src/declare.jl:46`, `src/build.jl:462-465` | `test_declare.jl:35` | |
| §8.2 1886–1889 | declaring `init_*` by type was rejected (D-073) | n/a | — | — | rejected alternative |
| §8.2 1890–1897 | the declared values are the base layer every overlay falls back to | accurate | `src/build.jl:811-826` | `test_conditions.jl` | `establish_defaults!` |
| §8.2 1899–1903 | contracts need types, stores need contents | n/a | — | — | rationale |
| §8.2 1905–1914 | the by-value declarations stay one-argument (D-166 criterion) | accurate | `src/declare.jl:22,30,37` | — | no two-argument form exists |
| §8.2 1916–1921 | `input_types` two-argument continuous, plain discrete; class fixes the form | accurate | `src/declare.jl:55`, `src/build.jl:66-70`, `src/assembly.jl:332-333` | `test_build.jl:145` | |
| §8.2 1922–1924 | either violation is `TierSignatureMismatch` | stand-in | `src/build.jl:89-96`, `src/diagnostics.jl:406-422` | `test_build.jl:161` | see 4.9 |
| §8.2 1926–1936 | entries are face bounds read permissively; `T` tolerant, `Float64` demanding frozen | accurate | `src/build.jl:179-190,1032-1035` | `test_build.jl:201` | |
| §8.2 1938–1948 | the `Float64` FFI door moves the failure to a named wiring error at build | short | `src/build.jl:1032-1035` | none | the refusal fires at a non-nominal activation, not at the nominal build; see 4.4 |
| §8.2 1950–1956 | abstract reference-typed entries state structural substitutability | absent | `src/build.jl:179-190` | none | see 4.5 |
| §8.2 1957–1962 | names-only contracts rejected; did-you-mean = name + list-in-hand | accurate | `src/diagnostics.jl:232-247` | `test_assembly.jl:668` | |
| §8.2 1963–1968 | the nominal bound check: producer declaration at `Float64` `<:` the entry | short | `src/build.jl:179-190` | `test_build.jl:28` | `_accepts` is structural equality plus embedding; the `<:` case is unbuilt (4.5) |
| §8.2 1968–1975 | the walk-compatibility clause, decidable in Stratum A, `WalkingFaceAtFrozenEntry` | absent | — | none | see 4.4 |
| §8.2 1977–1985 | discrete consumers take the bound check only | accurate | `src/build.jl:471-481,505` | `test_discrete.jl:73` | holds by construction: discrete stages are not probed off nominal |
| §8.2 1986–1995 | the genericity obligation is checked by the `Dual` probe, scoped to `T` entries | accurate | `src/build.jl:429-434,444-458` | `test_build.jl:241` | |
| §8.2 1997–2004 | the root-input type is the consuming entry evaluated at `Float64` | accurate | `src/build.jl:318-332` | `test_build.jl:90` | |
| §8.2 2005–2008 | abstract-at-root is a build error, `AbstractAtRoot` naming the remedy | absent | `src/build.jl:275-287` | none | see 4.5 |
| §8.2 2009–2013 | under fan-out the unique concrete declaration; abstract co-consumers checked against it | short | `src/build.jl:318-332` | `test_build.jl:90` | any `!==` difference is a conflict; no concrete-vs-abstract arm |
| §8.2 2013–2014 | root-input cells follow the entry at the activation's `T` | accurate | `src/build.jl:293-297` | `test_build.jl:241` | |
| §8.2 2015–2029 | fan-out combines tolerance by a meet: pin if any consumer pins (D-168) | stand-in, **rejected D-168** | `src/build.jl:318-332` | none | see 4.3 |
| §8.2 2030–2033 | the cost is paid at §14.10 (unseedable, tap names the pinning consumer) | n/a | — | — | deferred to §14.10 |
| §8.2 2035–2042 | `output_types` two-argument continuous, plain discrete, mandated | accurate | `src/declare.jl:68`, `src/build.jl:66-70` | `test_build.jl:145` | |
| §8.2 2043–2050 | `TierSignatureMismatch` names a producer whose form and tier disagree | stand-in | `src/build.jl:89-96` | `test_build.jl:161` | see 4.9 |
| §8.2 2051–2064 | literal semantics: cell types are the declaration evaluated at `T`, participation per leaf | accurate | `src/build.jl:28-39` | `test_build.jl:201`, `test_store.jl:65` | no output-side leaf walk |
| §8.2 2065–2069 | constructibility at `T`, enforced by the probe building real values | accurate | `src/build.jl:114-131,483-521` | `test_build.jl:241` | |
| §8.2 2070–2088 | frozen discrete cells mix safely; the embedding guarantee keyed on declared-`T` leaves | accurate | `src/build.jl:170-207,467-481` | `test_discrete.jl:73` | |
| §8.2 2089–2093 | piecewise branches returning literal constants are legal as written | accurate | `src/build.jl:203-207` | `test_build.jl:201` | |
| §8.2 2095–2107 | the per-leaf forgotten-`T` fails at that activation's Stratum-C compile with a didactic hint | accurate | `src/build.jl:193-195` | `test_build.jl:212-267` | |
| §8.2 2108–2111 | the test suite builds a `Dual` activation of every component | short | `test/test_continuous.jl:50` | — | one model (`feedback_model`) plus scattered fixtures, not every component |
| §8.2 2112–2117 | reader honesty | n/a | — | — | rationale |
| §8.2 2118–2126 | `init_x` walks to the activation scalar; `init_m`/`init_s` pin wholesale | accurate | `src/build.jl:34-38,450`, `src/leaves.jl:181-195` | `test_leaves.jl:167` | |
| §8.2 2127–2136 | Stratum A checks `init_x` against §7.1's closed continuous vocabulary | absent | — | none | see 4.6 |
| §8.2 2137–2148 | `state_events`: ordered named `StateEvent(guard, handler)`, no detection keyword | accurate | `src/declare.jl:182-193` | `test_events.jl:72` | |
| §8.2 2141–2145 | detection policy declared by the guard's return type | accurate | `src/build.jl:615-639`, `src/declare.jl:205-206` | `test_events.jl:108` | |
| §8.2 2145–2147 | declaration order is semantics (priority, re-decision) | accurate | `src/build.jl:979-995` | `test_events.jl:153` | |
| §8.2 2149–2162 | no stage tags; membership derived by probing stage 1 first | accurate | `src/build.jl:100-131,216-249,483-521` | `test_build.jl:44` | |
| §8.2 2163–2175 | custom structs are first-class port types, participating through their scalar parameter | accurate | `src/build.jl:186-189`, `src/leaves.jl:16-27` | `test_store.jl:65` | |
| §8.2 2181–2190 | a store needs its update: `init_x` without `state_derivative`, `init_s` without `state_update` | accurate | `src/build.jl:73-77` | `test_build.jl:37` | `StoreWithoutUpdate` |
| §8.2 2188–2190 | `init_m` carries no such obligation | accurate | `src/build.jl:73` | — | modes cast a tier vote only |
| §8.2 2191–2196 | an event needs both halves, by method lookup at declaration-reading time | accurate | `src/build.jl:398-418` | `test_events.jl:74` | |
| §8.2 2197–2214 | tier declared by store and update law; output stages cast no vote (D-220) | accurate | `src/build.jl:58-98` | `test_build.jl:145` | |
| §8.2 2205–2213 | `init_m`/`state_events`/`state_projection` continuous-only; workspace and contract arities split the tiers | accurate | `src/build.jl:62-70,558-572` | `test_events.jl:96` | |
| §8.2 2213–2219 | `DeclarationOnWrongTier` covers both-updates, mixed-arity and mixed-store cases | accurate | `src/build.jl:85-96`, `src/diagnostics.jl:406-422` | `test_build.jl:161` | |
| §8.2 2220–2230 | a stateless leaf's tier is decided by contract arity, `output_types` the decider | accurate | `src/build.jl:78-83` | `test_build.jl:145` | `TierUnreadable` when absent |
| §8.2 2232–2236 | any component may be the root; root inputs are the root's own input faces (D-208) | accurate | `src/assembly.jl:682-692,734-739` | `test_assembly.jl:62` | |
| §8.2 2237–2239 | at the root the two contract declarations share one namespace; a key in both is an error | accurate | `src/assembly.jl:787-792` | `test_assembly.jl:437` | |
| §8.2 2240–2245 | abstract-at-root is not relaxed; the test rig is the idiom | absent | — | none | see 4.5 |
| §8.3 2248–2251 | declared → public; returned and undeclared → build error; no `output_types` → no outputs | accurate | `src/build.jl:152-168`, `src/declare.jl:68` | `test_build.jl:30` | |
| §8.3 2253–2262 | the table is public throughout, no presentation filter | n/a | — | — | an obligation on §11's data plane |
| §8.3 2263–2270 | publicity is never implicit; one line in `output_types` is the inspection path | accurate | `src/build.jl:529-536` | `test_build.jl:32` | |
| §8.3 2271–2274 | a declared port is produced by exactly one stage **or by auto-publication** | short | `src/build.jl:516-536` | `test_build.jl:32` | the one-stage half only; see 4.2 |
| §8.3 2272–2274 | auto-publication covers declared names matching state or mode fields | absent | — | none | see 4.2 |
| §8.3 2276–2278 | declared-but-unproduced and produced-by-two-stages are build errors | accurate | `src/build.jl:516-536` | `test_build.jl:32` | |
| §8.3 2278–2280 | the unproduced error carries both the stage-product and the state-field lists | short | `src/diagnostics.jl:599-608` | `test_build.jl:32` | the product list only; there is no state-field list because auto-publication is absent |
| §8.3 2280–2283 | a returned field declared nowhere is a probe error with did-you-mean | accurate | `src/build.jl:155-158`, `src/diagnostics.jl:611-620` | `test_build.jl:30` | |
| §8.3 2283–2284 | missing from an untaken branch fails loudly at that branch's first execution | short | `src/store.jl:81-88` | none | loud, but through a raw `FieldError`; see 4.8 |
| §8.3 2285–2288 | branch-shape rule, made a stated rule with a good error | short | `src/store.jl:81-88` | none | no dedicated diagnostic; a type drift is not caught at all (4.8) |
| §8.3 2289–2296 | schema authority total over the table; expected types fully declaration-derived | accurate | `src/build.jl:267-304` | `test_store.jl` | every cell traces to a declaration |
| §8.3 2297–2301 | what this rules out (`unlisted`, `Private(T)`, probe-observed private cells) | n/a | — | — | rejected alternatives |
| §8.4 2304–2307 | w1 typo'd wire: build error at the connection with did-you-mean | accurate | `src/assembly.jl:479-491`, `src/diagnostics.jl:232-247` | `test_assembly.jl:668` | |
| §8.4 2308–2309 | w2 forgotten wire: unconnected-input error at build | accurate | `src/assembly.jl:642-651` | `test_assembly.jl:551` | |
| §8.4 2310–2311 | w3 forgotten branch field: probe or first-execution error naming the port | accurate | `src/build.jl:529-536`, `src/store.jl:81-88` | `test_build.jl:32` | the runtime half is 4.8's stand-in |
| §8.4 2312–2313 | w4 type mismatch naming both endpoints and both faces | accurate | `src/build.jl:1032-1035`, `src/diagnostics.jl:271-280` | `test_diagnostics.jl:247` | |
| §8.4 2314–2321 | w5 typo'd return: did-you-mean **plus** the unproduced error with both lists | short | `src/build.jl:152-168` | `test_build.jl:30` | see 4.10 |
| §8.5 2328–2332 | an assembly is a plain struct; component-typed fields are children, the rest inert | accurate | `src/assembly.jl:114-122` | `test_assembly.jl:29` | |
| §8.5 2333–2339 | the four declarations alongside the struct; `child_connections` mandatory; `transparent_container` optional, default `nothing` | accurate | `src/declare.jl:82,89,95,108,171` | `test_assembly.jl:29` | |
| §8.5 2340–2348 | container children path-named `field/1`/`field/key`, declaration order governing | accurate | `src/assembly.jl:120-151` | `test_assembly.jl:103` | |
| §8.5 2345–2350 | containers are transparent grouping: no contract, no wiring, no rate scope | accurate | `src/assembly.jl:160-162` | `test_assembly.jl:103` | never walked as components |
| §8.5 2352–2360 | parametric composition payoff (`Formation`) | n/a | — | — | rationale |
| §8.5 2362–2370 | at most one name-transparent container; bare keys everywhere a child name appears | accurate | `src/declare.jl:108`, `src/assembly.jl:129-148` | `test_assembly.jl:195` | |
| §8.5 2371–2374 | naming is the only thing the declaration changes | accurate | `src/assembly.jl:129-151` | `test_assembly.jl:195` | |
| §8.5 2377–2381 | a mixed container is a build error in the did-you-mean family | accurate | `src/assembly.jl:123-128` | `test_assembly.jl:120,134` | `ContainerMixed` |
| §8.5 2382–2384 | containers of containers are rejected | absent | `src/assembly.jl:120-122` | none | see 4.7 |
| §8.5 2385–2386 | empty containers are legal, contributing zero children | accurate | `src/assembly.jl:122` | `test_assembly.jl:195` | |
| §8.5 2387–2391 | abstract element types follow the concreteness discipline | n/a | — | — | an authoring discipline, no check stated |
| §8.5 2392–2400 | the three-arm bare-key collision family (sibling child, own field name, sibling container field) | accurate | `src/assembly.jl:136-146,178-186` | `test_assembly.jl:218,234,245` | D-212's per-instantiation judgment built as written |
| §8.5 2400–2403 | `transparent_container` must name a container field; two of them is a declaration error | accurate | `src/assembly.jl:166-172`, `src/declare.jl:108` | `test_assembly.jl:267` | "two" is unrepresentable: one `Symbol` or `nothing` |
| §8.5 2405–2409 | `sample_times` needs no rule change; the field-name sugar survives transparency | accurate | `src/assembly.jl:584-592` | `test_discrete.jl:149` | |
| §8.5 2410–2416 | the builder (`add!`/`connect!`) is rejected (D-039) | n/a | — | — | rejected alternative; nothing of the kind exists |
| §8.5 2418–2468 | `Group`: children by the container rule, four declarations off the instance, name-transparent | accurate | `src/assembly.jl:190-234` | `test_assembly.jl:271` | carries a fifth field, `rates`, which §8.7 requires it to have |
| §8.5 2470–2480 | no `AbstractAssembly`; one root `AbstractComponent` | accurate | `src/declare.jl:12` | whole suite | |
| §8.5 2481–2490 | class by declaration shape: `child_connections` the assembly marker, any leaf declaration a primitive | accurate | `src/assembly.jl:11-50` | `test_assembly.jl:29` | |
| §8.5 2491–2495 | the rule is total: neither family is an error naming both, sharpened when it holds components | accurate | `src/assembly.jl:48-49,55-59` | `test_assembly.jl:40,45` | |
| §8.5 2495–2496 | `child_connections` plus a leaf declaration is a build error | accurate | `src/assembly.jl:42-45` | `test_assembly.jl:53` | `ClassMixed` |
| §8.5 2496–2499 | assemblies own no state and no contract; their faces derive from children | accurate | `src/assembly.jl:42-45`, `src/build.jl:299-301` | `test_assembly.jl:496` | |
| §8.5 2501–2510 | class mandates both contract signature shapes per tier | accurate | `src/build.jl:66-96` | `test_build.jl:145` | |
| §8.5 2511–2515 | `TierSignatureMismatch` reports path, declaration, announced tier, form found vs mandated | short | `src/diagnostics.jl:406-422` | `test_build.jl:161` | see 4.9 |
| §8.5 2516–2517 | the check is Stratum A and collected | short | `src/build.jl:96,383` | `test_build.jl:161` | collected within a component, fail-fast across components; see 4.9 |
| §8.6 2524–2531 | paths slash-separated, relative, no leading slash, one canonical form | accurate | `src/assembly.jl:236-241,257-265` | `test_assembly.jl:325` | |
| §8.6 2528–2531 | container children add index/key segments; a transparent container adds none | accurate | `src/assembly.jl:273-290` | `test_assembly.jl:195,325` | the two-segment lookahead |
| §8.6 2531–2534 | instance navigation, symbol tuples and dotted paths rejected (D-040) | n/a | — | — | rejected alternatives |
| §8.6 2534–2540 | the wiring declarations use the short case only; the read side walks full depth | accurate | `src/assembly.jl:273-290` | `test_assembly.jl:351,665` | `PathResolution(:reaches_past)` |
| §8.6 2540–2544 | `===`-identity makes a path unrecoverable, so the helpers name the child by path | accurate | `src/assembly.jl:382-389,404-411` | `test_assembly.jl:672` | |
| §8.6 2545–2548 | `child_connections` is ordered child-face → child-face pairs | accurate | `src/assembly.jl:711-717` | `test_assembly.jl:475` | |
| §8.6 2548–2556 | `input_connections`: face => endpoint or tuple of endpoints; at least one endpoint (D-210) | accurate | `src/assembly.jl:722-733` | `test_assembly.jl:444` | |
| §8.6 2556–2560 | `output_connections` runs the other way, reading along the flow | accurate | `src/assembly.jl:741-744` | `test_assembly.jl:496` | |
| §8.6 2561–2567 | face names: no `/`, unique across the two boundary declarations | accurate | `src/assembly.jl:766-778` | `test_assembly.jl:413` | |
| §8.6 2568–2578 | at the root the uniqueness invariant follows the class (D-210) | accurate | `src/assembly.jl:780-792` | `test_assembly.jl:437` | |
| §8.6 2579–2590 | slash is structure, face names are opaque derived-contract tokens | accurate | `src/assembly.jl:236-241` | `test_trace.jl` | |
| §8.6 2591 | the three declarations return pairs of strings (D-046) | accurate | `src/declare.jl:70-95` | `test_assembly.jl:475` | |
| §8.6 2593–2600 | direction declared by the method; a wrong-direction endpoint names method, entry and actual direction | accurate | `src/assembly.jl:478-491` | `test_assembly.jl:399` | |
| §8.6 2600–2606 | face types and tiers are derived from the internal endpoint | accurate | `src/assembly.jl:439-469`, `src/build.jl:299-301` | `test_assembly.jl:496` | |
| §8.6 2607–2610 | three alternative face spellings rejected (D-041, D-170) | n/a | — | — | rejected alternatives |
| §8.6 2611–2620 | root inputs fall out with no vocabulary; the supplying declaration follows the class | accurate | `src/assembly.jl:682-692,734-739` | `test_assembly.jl:62` | |
| §8.6 2621–2665 | the worked IMU | n/a | — | — | example |
| §8.7 2668–2670 | `sample_times`: immediate child name => `Relative`/`Absolute` | accurate | `src/declare.jl:143-171` | `test_discrete.jl:199` | |
| §8.7 2670–2672 | the wrappers are the whole value vocabulary; a bare integer is a declaration error | accurate | `src/assembly.jl:557-560` | `test_discrete.jl:111` | |
| §8.7 2673–2675 | the declaration and any key are optional; unlisted discrete children default to `Relative(1)` | accurate | `src/declare.jl:171`, `src/assembly.jl:596-603` | `test_discrete.jl:199` | |
| §8.7 2675–2679 | keys are immediate child names only; container elements legal; the bare field name is uniform sugar | accurate | `src/assembly.jl:572-574,584-592` | `test_discrete.jl:130,149` | |
| §8.7 2679–2681 | a key on a continuous child is a build error | accurate | `src/assembly.jl:702-707` | `test_discrete.jl:140` | |
| §8.7 2681–2683 | `Δt_base`, `h`, `n` appear in no declaration | accurate | `src/build.jl:693-792` | `test_discrete.jl:228,270` | |
| §8.7 2683–2686 | the declaration belongs to the assembly type, never a per-instance value; `Subsampled` rejected (D-042) | n/a | `src/declare.jl:164-171` | — | no check exists, and the docstring blesses reading a multiplier off the instance |
| §8.8 2689–2712 | `input_passthrough`: `sep`/`prefix`/`except`/`only`, exclusivity enforced, unknown names with the list in hand | accurate | `src/assembly.jl:367-389,415-430` | `test_assembly.jl:694` | |
| §8.8 2713–2720 | computed entries mix freely with hand-written ones; `resolve`/`input_faces` are the primitives | accurate | `src/assembly.jl:292-354` | `test_assembly.jl:647,672` | |
| §8.8 2721–2724 | a face name containing dots is a legal final path segment | accurate | `src/assembly.jl:257-265` | `test_assembly.jl:672` | split on `/` only |
| §8.8 2724–2727 | no `rename` hook | accurate | — | — | correctly absent; declarations are ordinary code |
| §8.8 2727–2735 | every error stays first-class (unconnected, two-producers, unknown face, prefix collision) | accurate | `src/assembly.jl:418-430,754-763,766-778` | `test_assembly.jl:741` | |
| §8.8 2736–2740 | computation does not auto-bubble | accurate | `src/assembly.jl:356-365` | — | the helper reads faces, never wires |
| §8.8 2741–2751 | `output_passthrough` is the sibling with the same surface (D-209) | accurate | `src/assembly.jl:391-411` | `test_assembly.jl:672` | |
| §8.8 2752–2760 | both helpers take an immediate `child_path`; the default prefix folds the slash into `sep`; deeper paths meet `resolve`'s rejection | accurate | `src/assembly.jl:384-385,406-407,413` | `test_assembly.jl:738,758` | |
| §8.8 2762–2800 | the one-authored-list idiom (`ACT_FEEDS`, `fed_faces`) | n/a | — | — | an idiom in ordinary code |
| §8.8 2801–2806 | the line not to cross: no `except` derived from `child_connections` | accurate | — | — | correctly absent |
| §8.8 2807–2814 | generic holding: a missing referenced face names the holding entry | accurate | `src/assembly.jl:273-290,748-749` | `test_assembly.jl:665` | `PathResolution.entry` carries the declaring method and entry |

## Deviations in detail

### 4.1 The shadowing check is absent (§8.1, 1725–1735)

The spec: "Two mitigations, both normative. … The second: the two diagnostics
run a **shadowing check**. If the component's parent module defines a
same-named function distinct from the framework's, the message says so and
names the missing import: '`MyEngine`'s module defines its own
`state_derivative`, distinct from `Flight.state_derivative` — add `import
Flight: state_derivative`'. The check is a two-line `isdefined`/`!==` test on
names the build already looks up."

Nothing in `src/` performs it. `grep -rn "isdefined\|parentmodule"` over
`src/` returns no hits outside comments about container shadowing.
`StoreWithoutUpdate`'s message (`src/diagnostics.jl:351-353`) and
`ClassUnreadable`'s (`src/diagnostics.jl:377-381`) carry no import remedy and
no mention of a foreign binding. The trap the check exists to defuse is
therefore fully live: a component whose module defines its own
`state_derivative` after a bare `using` reports "declares `init_x` but defines
neither `state_derivative` nor `state_update`", pointing away from the missing
`import` line. `implementation.md`'s authoring-caveats list records the trap
as unwarned-about, which is consistent with what I found in the code.

### 4.2 Auto-publication does not exist (§8.2 1841, §8.3 2271–2274)

The spec: "a declared port must be produced, by exactly one stage or by
**auto-publication**. Auto-publication covers declared names matching state or
mode fields that no stage produces (§5.3)." §8.2's worked `Engine` relies on
it directly — the inventory's comment at line 1841 reads "`ω` names a state
field no stage produces → auto-published at stage 1 (§5.3)".

`probe_stage2` computes `missing_ports = setdiff(keys(decls[ci].outs),
keys(products[ci]))` (`src/build.jl:530`) and raises `DeclaredNotProduced` for
anything a stage did not return. No pass consults `init_x`, `init_m` or
`init_s` for a matching name, and `grep -rn "auto.publi"` over `src/` and
`test/` is empty.

Probe: a component with `init_x = (ω = 0.0,)`, `init_m = (phase = 1,)` and
`output_types = (M = T, ω = T, phase = Int)` whose `output_direct` returns only
`M` fails with

```
BuildError: DeclaredNotProduced: `e`: declared port(s) ω, phase produced by no
stage — either a stage returns them or `output_types` drops them; the stages
return `M`
```

So the spec's own §8.2 example does not build, and the only way to publish a
state field is to write a stage that copies it. This also explains the short
row on the diagnostic's payload: §8.3 asks for a message with "both lists in
hand", "not produced by any stage and not a state field", and
`DeclaredNotProduced` (`src/diagnostics.jl:599-608`) carries only the
stage-product list, there being no state-field list to carry.

### 4.3 The D-168 fan-out meet is not implemented (§8.2 2015–2029)

The spec: "**Fan-out combines tolerance by a meet, not by agreement**
(D-168): the root input pins at every activation if *any* consumer's entry
pins, and follows the scalar only when every consumer tolerates. … That
mixture is a legitimate model rather than a mistake."

`_root_input_type` (`src/build.jl:318-332`) returns `first(declared)` — the
entry of whichever consumer `flat.conns` reaches first, which is flatten order,
which is field declaration order. The type conflict check is gated on
`check`, set only at the nominal activation, so at a non-nominal activation
nothing compares the entries at all and the first one simply wins.

Probe, at `Dual{Nothing,Float64,1}`, over a `Group` fanning one root input
into a `T`-entry consumer `a` and a `Float64`-entry consumer `b`:

- children declared `(a = tolerant, b = pinned)`: nominal build succeeds, and
  the `Dual` activation fails with
  `WireTypeMismatch: `b`.u declared Float64, fed from root input
  `in`::ForwardDiff.Dual{…} — if this leaf participates in differentiation,
  declare it `T``;
- children declared `(a = pinned, b = tolerant)`: both build.

Two facts follow. The assignment is order-dependent, so the same model is
legal or illegal depending on the order its fields are written in. And in the
first order the implementation takes exactly the *join* — "the slot walks if
any consumer tolerates" — which D-168 records as rejected, "unsound in the
direction that matters — it delivers `Dual`s to an entry that declared it
cannot take them". The one saving grace is that the delivery is caught by
`_probe_input` rather than reaching user math; the cost is that D-168's
legitimate configuration (a command consumed by a promoting leaf and by an
AD-opaque table, the FFI door in use) is refused, and the message blames the
pinned consumer for a wiring choice it did not make.

`test_build.jl:105` asserts only `build(_fanned_root(RealEntry(),
PinnedEntry())) isa Build` — the nominal half — so the meet is untested in
both directions.

### 4.4 No walk-compatibility clause, and `WalkingFaceAtFrozenEntry` does not exist (§8.2 1968–1975)

The spec: "Beside it sits the **tier-scoped walk-compatibility clause**: for a
*continuous* consumer, a walking producer leaf — the producer declared `T`
there — requires a `T` entry, while a pinned producer leaf satisfies either …
Both sides are declaration functions of `T`, so the clause is decidable in
Stratum A by evaluating them at a marker scalar. No user stage code runs
(§9.1), and a violation is `WalkingFaceAtFrozenEntry`." D-167 adds the payload
(consumer path + entry, producer path + face, the leaf, both declared leaf
types, both remedies) and the timing: "input-side forgotten-`T` … fails **at
first nominal build, at the wire, both endpoints named**".

`grep -rn WalkingFaceAtFrozenEntry src/` is empty, and no pass in
`src/build.jl` compares a producer declaration against a consumer entry at a
marker scalar. What exists is `_probe_input` (`src/build.jl:1024-1037`), which
compares the *observed producer value* against the entry with `_accepts` at
whatever activation is being built.

Probe: a walking producer (`output_types = (y = T,)`) wired into a continuous
consumer declaring `input_types = (u = Float64,)` builds cleanly at Stratum A
and only fails when a `Dual` activation is materialized, with
`WireTypeMismatch` rather than `WalkingFaceAtFrozenEntry`. Non-nominal
activations are lazy (`src/build.jl:429-434`), so unless the author passes
`activations = (Dual…,)` or a service requests one, the model ships with the
violation undetected. The deferral also runs user stage code to reach the
verdict, which the spec says the clause exists to avoid.

The clause's tier scoping is nevertheless honoured, if only incidentally: at a
non-nominal activation a discrete component is frozen (`src/build.jl:471-481`)
and its stages are not probed, so continuous → discrete wires are
unconditionally legal. My probe confirmed that a `Walker` → `DiscreteSink`
model builds and activates at `Dual`.

### 4.5 Abstract entries are refused, and abstract-at-root escapes as a raw `ArgumentError` (§8.2 1950–1956, 1963–1968, 2005–2008, 2240–2245)

Three connected claims fail together.

The bound check "is stated over evaluations: the producer's declaration at
`Float64` must be `<:` the entry at `Float64`. It is one uniform rule,
degenerating to exact equality for a concrete entry". `_accepts`
(`src/build.jl:179-190`) implements the degenerate case only: for a
non-`Real`, non-`StaticArray` declaration it requires `P.name === V.name`,
equal `fieldcount` and per-field acceptance. An abstract `P` and a concrete
`V <: P` fail at the typename comparison.

So "abstract reference-typed entries stand as they always were … The field
handles (§4.4) are the demonstrated client — `terrain = AbstractTerrainField`"
is not built. Probe: a `TerrainSrc` declaring `output_types = (terrain =
FlatTerrain,)` wired to a `TerrainUser` declaring `input_types = (terrain =
AbstractTerrain,)` fails with

```
BuildError: WireTypeMismatch: `usr`.terrain declared AbstractTerrain,
fed from `src`.terrain::FlatTerrain
```

And "Abstract-at-root is a build error, and `AbstractAtRoot` names the remedy
with the face" is absent in both halves. `grep -rn AbstractAtRoot src/` is
empty. The same `TerrainUser` as a root consumer reaches `place!`
(`src/build.jl:275-287`), which calls `leaf_types(AbstractTerrain)`; that
walks `fieldtypes` on an abstract type and throws

```
ArgumentError: type does not have a definite number of fields
```

— a bare Julia error, outside the `BuildError` carrier, with no path, no face
and no remedy. `IllegalPortType`, which `place!` was written to raise for a
leafless declaration, is never reached because the `ArgumentError` fires
first.

The knock-on is on §8.2's fan-out rule "abstract co-consumers are checked
against it": `_root_input_type` compares with `!==`, so an abstract entry
beside a concrete one is reported as a `RootInputTypeConflict` rather than
checked for substitutability.

### 4.6 The `init_x` continuous-vocabulary check is absent (§8.2 2127–2136)

The spec: "Stratum A therefore checks the continuous vocabulary (§9.1) and
reports a failure in the didactic register: '`init_x` field `gear_count::Int`
is not a continuous state — integers, `Bool`s and enums belong in `init_m`';
'`init_x` field `q_nb::RQuat` is not a state leaf — declare the `SVector{4}`
backing and cast where rotation semantics are wanted'."

No such check exists. `src/diagnostics.jl:564` mentions an `IllegalStateLeaf`
kind in a docstring — "the port twin of `IllegalStateLeaf`" — but the kind
itself is not defined anywhere, and `grep -rn IllegalStateLeaf src/ test/`
finds only that comment.

Probe: a component with `init_x(::IntState) = (gear_count = 3, ω = 0.0)` and a
matching `state_derivative` builds without complaint. It is not harmless: the
state buffer is `Vector{Float64}` (`src/build.jl:898`), `retype_value`
(`src/leaves.jl:192`) walks the declared `Int` to the activation scalar, and
`_check_derivative` compares leaf *counts* only, so the author's declared
`Int` silently becomes a `Float64` in every bundle. The failure the spec wants
at build time never arrives at all.

### 4.7 Containers of containers are silently dropped, not rejected (§8.5 2382–2384)

The spec: "Containers of containers are rejected in the first cut, deeper
grouping being what assemblies are for."

`_children` (`src/assembly.jl:120-128`) classifies a `Tuple`/`NamedTuple`
field by counting elements that are `isa AbstractComponent`. A tuple of tuples
has zero, so it takes the `n == 0 && continue` branch at line 122 — the
"inert data; an empty container too" path — and contributes nothing.

Probe: an assembly `Nested(((Tiny(), Tiny()), (Tiny(),)))` with
`child_connections(::Nested) = ()` builds successfully, and `b.flat.paths` is
`String[]`. Three declared components vanish from the model with no
diagnostic, and the resulting simulation is an empty one. A rejection is what
the spec asks for; silence is the one outcome the section's loudness doctrine
rules out, and it is the same class of failure the D-212 collision family was
built to prevent one paragraph earlier.

### 4.8 The always-on conformance check is the scatter's `getfield` (§8.1 1777–1779, §8.3 2283–2288)

The spec: "The same comparison then runs on every subsequent evaluation for
free: a `NamedTuple`-type check that constant-folds away when conformant"
(§8.1), and "missing from an *untaken* branch, it fails loudly at that
branch's first execution via the always-on check … stage returns must have the
same `NamedTuple` shape on every branch … the framework merely makes it a
stated rule with a good error" (§8.3).

There is no such check. `run!(e::StageEntry, …)` (`src/executor.jl:144-148`)
calls the stage and hands the return straight to `scatter_group!`
(`src/store.jl:81-88`), a generated function that emits one
`getfield(y, name)` per *declared address*. Three consequences, two of them
probed on a running simulation:

- a declared key missing from an untaken branch fails loudly, which the spec
  asks for, but through a raw `FieldError` carried as the `cause` of §13.4's
  `StepError`: "in `c` output_state, event round 1 of the frame from boundary
  4 (t = 0.5): … cause: FieldError: type NamedTuple has no field `b`,
  available fields: `a`, `c`". The framing is good; the message is Julia's,
  not the framework's, and no diagnostic kind names the branch-shape rule;
- a *type* drift on an untaken branch is not caught at all. A stage declaring
  `(a = T,)` and returning `a = 7` on its late branch ran to `t_end` and wrote
  `7.0` into the cell. The declaration-derived expected type §8.3 promises is
  never compared;
- an extra field returned only on an untaken branch is silently ignored, the
  scatter reading declared names only.

### 4.9 `TierSignatureMismatch` is `DeclarationOnWrongTier`, and collection is per component (§8.2 1922–1924, §8.5 2511–2517)

The spec names `TierSignatureMismatch` three times and fixes its payload: "The
diagnostic reports the component path, the declaration at fault, the tier its
other declarations announce, and the form found versus the form mandated. The
check is Stratum A and collected."

The check is built and tested. `classify_tier` (`src/build.jl:58-98`) collects
one vote per tier-implying declaration, picks the decider by §8.2's two cases,
and raises `DeclarationOnWrongTier(reason = :tier_form, found, announced)` for
every dissenter. `test_build.jl:145-180` exercises all four disagreement
shapes.

Two gaps. The kind name is different, and its payload reports the two *tiers*
("`output_types` is declared in the discrete-tier form, but this component's
other declarations announce the continuous tier") rather than the two *forms*
— the reader is told which tier is wrong, not that the mandated spelling is
`output_types(::C, ::Type{T}) where {T <: Real}`. And "collected" holds only
within one component: `build` calls `classify_tier` inside a comprehension
(`src/build.jl:383`), and the first offending component's `BuildError` ends
the pass, so a second component's mismatch is never reported.

### 4.10 Walkthrough 5 delivers one of its two diagnostics (§8.4 2314–2321)

The spec: "**Typo'd return field** (`P_shft = …` for a declared `P_shaft`): a
probe error with did-you-mean … against `output_types`, **plus** the
unproduced-`P_shaft` error with both the stage-product and state-field lists
in hand."

`_check_ports` (`src/build.jl:152-168`) collects per port within one stage and
then throws, so the `DeclaredNotProduced` pass at `src/build.jl:528-536` never
runs for that model. Probe, on a component declaring `(M = T, P_shaft = T)`
whose stage returns `(M = 1.0, P_shft = 2.0)`:

```
BuildError: UndeclaredReturnField: `c`: output_state returns `P_shft`, which
`output_types` does not declare — declare it, or drop it from the return; the
declared ports are `M`, `P_shaft`
```

The unproduced-`P_shaft` half is absent, so the author fixes the typo and
learns about the second half only on the next build. (The two are asserted
separately, on two different fixture components, at `test_build.jl:30` and
`:32`.) Even when it does fire it carries one list rather than two, per 4.2.

## Tally

| verdict | count |
| --- | --- |
| accurate | 97 |
| short | 11 |
| stand-in | 4 |
| absent | 8 |
| n/a | 21 |
| **total** | **141** |

Ratification markers used: **rejected D-168** on the fan-out meet row. No row
is ratified by a decision-log entry; the two entries I read (D-167, D-168)
both confirm the spec's shape rather than the implemented one.

## Friction

- The spec's import list and error messages say `Flight`, and the package is
  `Cadence`. Harmless, but it means no message in `src/` can be compared
  verbatim against §8.1's quoted text.
- §8.5's "Containers of containers are rejected in the first cut" admits two
  readings: "diagnosed" or merely "not supported". I scored it as an absence
  because the section's other edge cases all name their diagnostic and because
  the implemented behaviour is silent deletion of declared components, which
  the design refuses everywhere else. A reader who takes "rejected" as "out of
  scope" would score it n/a.
- The line between §8.2's wiring clauses and §6.1's is soft. §8.2 states both
  the bound check and the walk-compatibility clause in full and names
  `WalkingFaceAtFrozenEntry`, but cites §6.1 for both; agent A may score the
  same two obligations.
- §8.2's "the test suite builds a `Dual` activation of every component" is an
  obligation on `test/`, not on `src/`, and it has no artifact to point at —
  no suite-wide sweep exists, and I could only check that the one model
  `test_continuous.jl:50` covers is not "every component". A reader could
  reasonably call it absent rather than short.
- `_probe_input`'s comparison is against observed *values*, while §8.2 states
  the bound check over *declarations*. They coincide only because
  `_embed_ports` rewrites every product to its declared type
  (`src/build.jl:203-207`). I traced that before scoring the row, but the
  equivalence is not stated anywhere in the code.
