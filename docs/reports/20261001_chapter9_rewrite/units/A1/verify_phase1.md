# A1 verify, phase 1 (blind read of new.md)

## Intro (§9)
V1. The build consumes a root component instance and produces the runnable artifact.
V2. The artifact consists of resolved wires, typed signal table, execution order, absolute rate divisors, flat state layout, root inputs.
V3. §8 states what is declared and must hold; ch.9 states when each fact is checked, against what, with which failure.
V4. §8.4 walkthroughs plus error rules (§6.1) are ch.9's acceptance tests.
V5. Error-reporting policy settled in §13.1: declarative checking passes collect, user-code evaluation fails fast.
V6. Chapter roadmap §9.1–§9.7 (pointer).

## §9.1 lead
V7. Three ordering constraints are forced by settled decisions.
V8. Face derivation is bottom-up because an assembly's interface connections evaluate against child contracts (§8.8).
V9. Unconnected-input obligation check and cross-level two-producers detection are global; decidable only at the root after every assembly's wires and faces are in hand (§6.1).
V10. Stage membership derived by probing stage-1 functions (§8.2), so evaluation interleaves with graph construction at exactly one blessed spot.
V11. Pipeline therefore inherently heterogeneous.
V12. BOLD: pipeline runs as the steps, each consuming one artifact and producing the next, each a barrier (D-259).
V13. A step that produced any error throws before the next begins (§13.1).
V14. Table: structure step: root instance -> Structure; runs declaration bodies only.
V15. Table: nominal evaluation: Structure -> Outputs, Events, nominal Float64 activation; runs stage functions, guards, handlers at Float64.
V16. Table: activation at T: Structure, Outputs, nominal activation, scalar T -> Activation{T}; runs continuous tier's functions at T.
V17. Table: deployment: Build, grid params -> Deployment with Schedule; no user code.
V18. Table: materialization: Deployment, scalar T -> Simulation{T}; no user code.
V19. First three are the build; build(world) runs them; Build bundles their products (§9.2).
V20. Last two are Deployment constructor and Simulation constructor (§9.2).

## Structure step
V21. BOLD: structure step is pure declaration reading (D-048).
V22. No user stage code executes in it (D-259).
V23. u_connections, y_connections, input_passthrough bodies are declaration code (§8.8).
V24. Tree walk from root, in order: collect components by path; read class (primitive vs assembly) off declaration shape (§8.5); collect leaf contracts (u_types, y_types, init_*, state_events); bottom-up face derivation recording at every level input/output faces declared and chain each routes through; then global wiring resolution to absolute leaf terminals.
V25. Resolution checks: one-writer-per-input; did-you-mean typo (offending name + list) against destination's input list; two wiring type clauses (§6.1, §8.2); whole-tree obligation check; store form (§8.2); closed leaf vocabulary (§7.1).
V26. Store form: every x_init, s_init, m_init value is a NamedTuple.
V27. BOLD: store form checked before classifier and vocabulary checks read the value (D-247).
V28. A primitive failing store form is read no further in this step.
V29. Closed leaf vocabulary checked on every x_init, because the §8.2 walk rests on it.
V30. s_init pins wholesale and answers to isbits rule of §7.3 instead.
V31. BOLD: isbits rule checked on s_init and m_init field by field (D-231).
V32. BOLD: root inputs fall out here too, as root component's input faces (D-208, §8.2).
V33. Bound check is first type clause; applies at nominal faces.
V34. BOLD: producer's declaration at Float64 must be <: entry at Float64 (D-078).
V35. Equality is the concrete degenerate case.
V36. Abstract-at-root detected here (D-236).
V37. Walk-compatibility clause is second; applies to continuous consumers only.
V38. BOLD: decided by retyping both declarations at a marker scalar and comparing per leaf (D-263, D-236).
V39. Diagnostic WalkingFaceAtFrozenEntry.
V40. Clause stays inside step's charter because both sides are plain declarations the walk retypes; declarations read, no user stage code runs.
V41. Step also checks declaration-completeness rules (§8.2): store without update; leaf declaring no store; event missing guard or handler method; leaf mixing tier families; stateless leaf with no output contract.
V42. BOLD: sample_times validation is the structure step's too (D-185).
V43. Part 1: per-entry validity against §10.5 constraints: wrapper-typed values, K≥1, 0≤Φ<K, T>0, 0≤τ<T, keys naming discrete or scope children; violations collected with path attribution.
V44. Part 2: compilation into (anchor, m, c) triples; triple carries a discrete component's divisor and phase in tick units of its anchor, the exact (T,τ) pair an Absolute entry establishes.
V45. BOLD: compilation is a fold down the tree, one rule per case (D-186).
V46. Root scope -> (A0,1,0), anchor 0 = base grid (T,τ)=(Δt_base,0).
V47. Relative(K,φ) under scope (a,mₛ,cₛ) -> (a, K·mₛ, cₛ+φ·mₛ).
V48. Absolute(q,τ) under any scope severs and re-seeds: fresh anchor Aₖ=(period(q),τ), subtree continues at (Aₖ,1,0).
V49. Anchor 0 symbolic until deployment.
V50. Relative case is the affine law (§10.5) in anchor-tick units.
V51. Canonical residue c<m holds within each anchor's subtree by the same induction.
V52. Everything except binding Δt_base (deployment's) happens in structure step.
V53. Final divisors for anchored entries genuinely cannot exist until Δt_base binds.
V54. BOLD: structure step returns Structure (artifact holding everything the instance alone fixes), and that is its whole product (D-253).
V55. Structure carries: instances by path; tier of each; resolved wires; two-sided face table with routing chains; root inputs; per component rate chain of Relative/Absolute links; for each assembly an explicit sample_times key names, its scope triple.
V56. Class and contracts read off instance on demand.
V57. Nothing in Structure depends on a scalar type.

## Nominal evaluation
V58. BOLD: nominal evaluation is a function of Structure, returns three artifacts Outputs, Events, nominal Float64 activation (D-253, D-259).
V59. It is the single evaluation-feeds-structure step.
V60. Outputs (port classification and order) carries per component stage-1 and stage-2 output names, and the execution order over components.
V61. BOLD: feedthrough graph the order is computed over is not carried (D-261).
V62. It is derived from Structure's connections and producers' stage-2 names wherever shown.
V63. Events carries per component event names, detection policies, bundle names.
V64. Order: workspace (component-declared mutable scratch as ws bundle field) allocated at probing scalar (§9.3).
V65. Stage-1 probes run at Float64 on x_init/s_init/m_init values; well-founded because no-feedthrough stage takes no inputs.
V66. Ports classified over y_types alone into two classes, stage-1 names and stage-2 remainder (§8.3, D-252).
V67. Feedthrough graph built from wires carrying stage-2 ports; topological order follows; §5.5 cycle rejection applies.
V68. Event declarations read last, after stage probes; become Events; a consumer of the execution order therefore never carries the event tables (D-253).
V69. Both products structural: names only, T-independent, branch-protected by branch-shape rule plus always-on check (§9.5).
V70. BOLD: nominal evaluation fixes structure and Float64 typing at once (D-253, D-259).
V71. Nominal activation is its product beside Outputs and Events; assembled from same probe chain, never a separate pass.
V72. That is why no product of this step changes across activations.

## Activation
V73. BOLD: activation at scalar T takes Structure, Outputs, nominal activation, completes Activation{T} (D-253, D-259).
V74. Step holds everything type-shaped; retypes cells and walked state type at T, lays out buffers (§9.4).
V75. Probe chain runs in topological order (§9.3); observed compared against declared.
V76. Nominal Float64 activation runs at build; other activations re-run only this step (§9.4).

Bold count: V12, V21, V27, V31, V32, V34, V38, V42, V45, V54, V58, V61, V70, V73 = 14.
