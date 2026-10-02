# Unit A, phase 1 (blind assertion list from new.md)

Intro
- V1. Chapter 10 owns time. (none)
- V2. It takes the execution order (§5.3) and the compiled executor (§9.7) as given and states how the loop runs them through time. [§5.3, §9.7]
- V3. Roadmap: §10.1 loop ownership + frame/boundary; §10.2 stepper seam; §10.3 signal-table consistency; §10.4 localization mechanics; §10.5 multi-rate tick scheduling; §10.6 event iteration at boundaries; §10.7 real-time pacing. [pointers]

§10.1
- V4. The loop has two units, frame and boundary; they recur through the chapter and mean different things. (none)
- V5. A frame is one grid step [tₙ, tₙ₊₁]; it is the unit of scheduling. (none)
- V6. Three things are keyed to the frame: input drain, pacer deadlines, tick eligibility. [§11.4, §10.7, §10.5]
- V7. Drain = frame-top swap publishing staged device writes into the root inputs. [§11.4]
- V8. A boundary is a published consistency point. (none)
- V9. The §10.6 macro-sequence completes at a boundary, and a snapshot goes out there. [§10.6]
- V10. Snapshot = immutable per-boundary publication. (none)
- V11. Every grid point is a boundary; not every boundary is a grid point. (none)
- V12. BOLD: localized event time t* is a boundary but not a frame top. [D-081]
- V13. t* is an event's crossing instant inside a step, bracketed by root-finding. [§10.4]
- V14. Boundary zero (initialization boundary at t₀) is a boundary and not a frame top. [§14.5]
- V15. The loop has six activities: boundary sequence, tick dispatch, event handling, logging, input staging, pacing. [§5.3]
- V16. Pacing = waits inserted between completed frames, never altering the boundary sequence. (none)
- V17. BOLD: all six are framework code, unconditionally. [D-017]
- V18. The framework writes the loop itself, not assembled from callbacks registered with a third-party solver. (none; D-017 nearby)
- V19. Reason: the step-boundary contract (§10.6), the central invariant of the design. [§10.6]
- V20. Only a loop the framework owns can enforce that contract by construction rather than convention. (none)
- V21. D-017 records the rejected foreign-loop alternative. [D-017]
- V22. BOLD: OrdinaryDiffEq is dropped as a dependency of the new core. [D-017]

§10.2
- V23. Loop ownership stops at one operation: advancing continuous state from t by h. (none)
- V24. BOLD: the framework delegates that operation across a narrow internal interface, the stepper seam. [D-017]
- V25. The seam exists so the integration method can be replaced without the loop changing. (none)
- V26. Seam contract has four clauses. (none)
- V27. Backend advances by arbitrary h; loop needs this anyway (landing on tick boundaries, resuming from localized event time). (none)
- V28. Localized event time = crossing instant bracketed by root-finding over trial sweeps. (none)
- V29. Backend provides dense output on demand over the last completed step; only event localization needs it, so backend constructs it lazily. [§10.4]
- V30. One-step methods only; event handlers reset state discontinuously and a one-step method restarts for free; multistep excluded. [D-017]
- V31. The seam carries what a backend needs across a frame top through a checkpoint hook, empty for a single-step method. [§12.6, D-274]
- V32. A model with no continuous state is legal. [D-156]
- V33. Nothing in §8.2 requires an x block of any component. [§8.2]
- V34. Such a model still has to be run. (none)
- V35. BOLD: the seam is never entered empty. [D-156]
- V36. The framework short-circuits the empty case; integrate step degenerates to advancing t to next boundary; stepper not called. (none)
- V37. No backend faces N = 0; no backend contract must say what it does there. (none)
- V38. Loop ownership (§10.1) pays off structurally here; under a foreign solver loop, an empty state pays a dummy-[0.0] tax. [§10.1, D-017]
- V39. Here the tax is gone at the root: both buffer and step disappear. (none)
- V40. Buffer = contiguous vector backing all continuous state. (none)
- V41. Everything else about such a model is ordinary; sweeps, events, ticks run unchanged. (none)
- V42. BOLD: first cut ships in-house fixed-step RK4 and Heun over the flat state buffer. [D-017]
- V43. Together they are about a hundred lines. (none)
- V44. Trivially zero-allocation, so auditable against the CI invariant. [§7.5]
- V45. Trivially T-generic; genericity not required of the stepper, because linearization and the feedthrough tracer drive the sweep, never the integrator. [§5.6]
- V46. Feedthrough tracer = build diagnostic classifying dependence cycles. [§5.6]
- V47. BOLD: RK4 is the default of the two. [D-227]
- V48. The algorithm keyword selects the backend by type on the Deployment. (none; D-227 nearby)
- V49. Deployment = scalar-free artifact the grid parameters fix. (none)
- V50. Materialization at Simulation construction binds the stepper against the state buffer, on the executor. [Appendix B, §9.2, D-227]
- V51. The step h has no default; required of caller; a domain rate is not a framework default. (none)
- V52. An OrdinaryDiffEq-backed stepper can exist later as a package extension if an offline study demands adaptive or stiff methods. [D-017]
- V53. It is a guarded addition (admitted, not built), so not built until then. (none)
- V54. The domain argument is decisive for the whole axis; three claims. (none)
- V55. Closed-loop ticks cap the step: every application beyond bare propagation runs periodic avionics with ZOH commands. (none)
- V56. Integrating past a tick with stale commands is wrong; the integrator must land on every tick boundary regardless of method. (none)
- V57. Adaptive/high-order methods pay off when steps stretch; execution model forbids the stretch by construction. (none)
- V58. Piecewise-smooth RHS starves high order: interpolated tables (C¹-kinked at knots), clamps, friction blends, mode branches deny error estimators and Newton iterations the smoothness they assume. (none)
- V59. RHS = continuous derivative function. (none)
- V60. Stiffness remedy ladder in order: shrink h (RHS costs microseconds; 500 Hz real-time unremarkable), subcycle against tick grid, only then implicit via the OrdinaryDiffEq extension. (none)
- V61. If that day comes, eltype genericity supplies exact ForwardDiff Jacobians through the sweep for free. [§7.2]
- V62. The Flight.jl evidence for these claims lives in section 5 of companions/flight_case_studies.md. (pointer)

§10.3
- V63. During a step, RK stages evaluate the interior sweep at internal stage states. [D-147]
- V64. Interior sweep = sweep variant over continuous entries only. [§10.5]
- V65. While they do, the signal table is transiently integrator scratch. (none)
- V66. The boundary sweep in the §5.3 sequence restores consistency at each accepted boundary. [§5.3]
- V67. BOLD: external readers (GUI, logging, network output) observe the signal table only at step boundaries. [D-023]
- V68. Mid-step contents carry no meaning. (none)
- V69. This rule binds the periphery (everything outside the loop that exchanges data with it). [§11]
- V70. The rule extends naturally to the boundary sequence: readers observe the table only after it completes. [§10.6]
