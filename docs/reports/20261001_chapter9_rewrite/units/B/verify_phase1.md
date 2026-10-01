# Unit B (spec §9.3), phase 1: blind assertion list from new.md

V1. The build calls each user function once, as a probe, to catch malformed code early.
V2. Each call needs argument values; not every argument has a producer.
V3. (Pointer) The section covers probe-everything scope, argument sourcing and its two checks, root-input synthesis, probe scoping, and totality. — transition
V4. [bold] The nominal activation probes every user function once, at the initial state, with real values. [D-050]
V5. The probed set is the stages, `x_deriv`, `s_update`, guards, handlers and `x_projection`.
V6. The probe checks shape and type conformance and discards the results.
V7. All probed functions are pure; cost is one evaluation each.
V8. The principle "fails loudly at build time where possible" decides this. [§8.1]
V9. A malformed `x_deriv` return must not wait for the first integrator step.
V10. Probes see only the initial state's branch.
V11. So the marginal coverage is earliness, not completeness.
V12. The always-on check is the completeness backstop. [§9.5]
V13. `x`/`s`/`m` probe args come from `init_*` declarations, which declare by value.
V14. Stage-1 hand-down (`y_x`, `y_s` on the discrete tier) comes from the stage-1 probes' returns.
V15. Those returns are every stage-1 port there is. [§5.2]
V16. Wired inputs come from upstream products.
V17. Real values are available because the stage-2 chain is probed in topological order.
V18. So every consumer is probed against the same value it will receive at run time.
V19. Two checks ride the same pass.
V20. First check: the return's shape; a stage returning other than a `NamedTuple` fails here.
V21. Second check: the dead-stage rule.
V22. [bold] A stage returning bare `(;)` produces no ports and is `DeadStage`, fail-fast. [D-194]
V23. The bundle law's two remaining fields are `ws` and `t`. [§5.2]
V24. `t` is a clock value, sourced below with `Δt`.
V25. [bold] `ws` comes from invoking the component's `ws_init` allocator at the probing scalar, before the nominal evaluation's probes that need it. [D-115]
V26. It runs that early because the allocator reads only the instance and the scalar [D-077] and derives nothing from layouts.
V27. Exactly one kind of terminal has no producer: root inputs.
V28. [bold] The build synthesizes root-input values via `probe_value(::Type)`. [D-051]
V29. Framework methods cover `Real` (`zero(T)`), `Bool` (`false`), enums (first instance).
V30. Ultimate fallback is the zero-argument constructor `T()`.
V31. That is where well-behaved constrained types already put their valid default.
V32. `RQuat()` is the identity.
V33. The `@kwdef` convention supplies zero-arg constructors broadly.
V34. `probe_value` is overridable; a type whose valid default is not reachable that way declares its own method.
V35. That method is also the seam a walked type uses to state a constrained default.
V36. No method is a build error, in the didactic style, naming the face and type and asking for one of the two fixes (example message given).
V37. Synthesis never meets an abstract type.
V38. Root inputs are concrete by the tight-bound rule. [§8.2]
V39. The root-input type is the consuming entry evaluated at `Float64`.
V40. Abstract entries occur only on component-fed inputs, which the probe sources from upstream products.
V41. Physically silly values are acceptable by construction.
V42. The probe checks types; return types depending on input values are type instabilities, banned by the branch-shape rule.
V43. The §4.3 write-side granularity rule keeps root inputs predominantly scalar, so the surface is small. [§4.3]
V44. [bold] Probe values are strictly probe-scoped. [D-051]
V45. Everything the probe writes is garbage once the build finishes.
V46. Probe values never double as initial root-input values, because that would smuggle in default semantics that entry (D-051) rejects.
V47. The same doctrine covers the clock.
V48. [bold] `t` is probe-scoped `0.0`. [D-115]
V49. Deployment binds no clock and `t₀` post-dates even deployment. [§14.5]
V50. So `t` is a fabricated, probe-scoped value, like `Δt`.
V51. `Δt` in seconds does not exist until `Simulation` binds `Δt_base`, since deployment post-dates the build.
V52. So discrete-tier probes supply a placeholder period (`1.0`) in the bundle; fabricated, probe-scoped.
V53. The probe checks types, not physics.
V54. `Simulation` must not reach its first boundary with uninitialized root inputs.
V55. [bold] Enforcement is the pre-write `UninitializedInputs` check carried by every complete-world application: `init!`, trim setup, trim commit. [§14.6, D-149]
V56. Silly values are acceptable because the author is obliged to accept them; that is the author's side of the bargain.
V57. [bold] Stage code must be total over type-valid inputs. [D-142]
V58. Every probed user function (list) evaluates without throwing on any input satisfying its declared types.
V59. The domain is type-validity, not the probe's synthesized values.
V60. Branch-shape rule bans value-dependent return types, so types are the only domain the framework can speak of.
V61. The probe is the enforcement moment, not the reason.
V62. Two consequence sites, same throw at both.
V63. At build: a `UserCodeFraming`-wrapped build failure [§13.1]; its diagnostic points at code "correct" on every trajectory it has seen.
V64. At runtime: `StepError`, run ends `errored`. [§13.4]
V65. Exceptions from model code are always abnormal. [§13.5, D-060]
V66. Three habits of shipped code have sanctioned spellings.
V67. [bold] A plausibility check meaning "stop the run" is a published `Bool` output face plus `stop_on`. [§13.5, D-142]
V68. A strut throwing on touchdown overload is one such check.
V69. The face and `stop_on` are machinery already there.
V70. [bold] A self-consistency assert (e.g. contact algebra cancelling a velocity component to hard tolerance) is a regression test about that algebra; its home is the test suite. [D-142]
V71. It is the most probe-fragile of the three: near-degenerate synthesized geometry can keep cancellation algebraically exact while missing an absolute tolerance in floating point.
V72. Third habit: defensive exhaustiveness branch; examples `else error("unrecognized surface type")` over a closed enum, coefficient constructor asserting argument ordering when run per step inside a stage.
V73. Such a branch is not banned validation but mislocated validation.
V74. Totality over a closed enum means handling every instance; `else error` admits the function is partial.
V75. [bold] Parameter validation belongs where user-controlled data enters. [D-142]
V76. That place is constructors of parameter and instance values, which run before the build, where asserts are legitimate.
V77. Parameter validation never belongs inside a stage, on probe-fed data.

Bold sentences: V4 (D-050), V22 (D-194), V25 (D-115), V28 (D-051), V44 (D-051), V48 (D-115), V55 (D-149), V57, V67, V70, V75 (D-142).
