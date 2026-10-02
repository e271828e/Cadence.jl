# Unit E verify, phase 1 (blind assertion list from new.md)

V1. §10.7 covers pacing (#g-pacing), the waits that hold a run to wall-clock time; three parts.
V2. Pacing is outside the semantics [D-021] (bold); this is the section's invariant.
V3. The pacer inserts waits between completed frames (#g-frame, iterations of the loop).
V4. It never reorders, skips or alters the boundary (#g-boundary) sequence.
V5. Paced and unpaced runs with identical input traces (#g-trace, records of each frame's drained inputs) produce bit-identical trajectories.
V6. So deterministic replay (#g-replay) [§2.2] extends over pace.
V7. Interactive runs differ only because their inputs differ.
V8. Detection policy is inside the semantics.
V9. Event localization runs identically paced or unpaced [§10.4, D-080] (bold).
V10. Its sweep (#g-sweep) cost is absorbed as debt (#g-pacing; wall time later frames repay) like any other expensive frame.
V11. Degrading to boundary detection under pacing was rejected [D-080].
V12. The wall-clock map is piecewise affine, re-anchored at every knee [D-021] (bold).
V13. Map formula tau(t) = tau_anchor + (t - t_anchor)/p, anchor pair is reference point.
V14. A live pace change re-establishes the anchor at current (t, tau), so new slope applies only forward [D-021].
V15. Un-pause re-anchors for the same reason.
V16. Debt is cleared at re-anchor.
V17. A deliberate user action is a natural sync point.
V18. The counters record what was forgiven.
V19. The frame following an anchor has no wait, because its deadline is the anchor itself.
V20. The run's first anchor is taken when its loop starts, so first frame runs at once [D-269].
V21. Deadline law is an absolute schedule with bounded debt [D-021] (bold).
V22. Frame deadlines come from the map.
V23. A frame exceeding its wall budget h/p leaves debt.
V24. Subsequent frames repay it by running short or without waiting.
V25. Long-run rate therefore exact; ms-scale hiccups from GC/scheduler invisible.
V26. Debt beyond 5 frames' budget (5·h/p) is forgiven by re-anchor plus warning [D-133] (bold).
V27. As a result, long stalls (debugger, laptop sleep) do not trigger catch-up bursts.
V28. Five frames' worth sits above ms-scale hiccups and far below seconds-to-minutes stalls; neither lands near threshold.
V29. p = ∞ is pacer-off, not a limit value [D-021] (bold).
V30. Unpaced mode is explicit absence of deadlines: no waits, no debt, no warnings.
V31. By the invariant, it is the same execution with waits deleted.
V32. Wait mechanism is hybrid sleep-then-spin with one knob [D-021] (bold).
V33. Non-realtime OSes guarantee only a lower bound on sleep; thread runnable no earlier than requested.
V34. Wake-up best-effort, subject to timer granularity, scheduler load, macOS timer coalescing; no hard upper bound.
V35. Measured (dev machine, idle, 2 ms requests, 2026-07): Julia sleep overshoots ~1.4 ms median; Libc.systemsleep ~0.5 ms.
V36. Behind the sleep figure are libuv's ms-granularity timers; sub-ms requests accepted and rounded up.
V37. Spikes under load unbounded.
V38. Pacer therefore sleeps toward deadline − margin and spins the remainder (code: coarse phase runs at most once; spin µs-precise, CPU cost bounded by margin; GC.safepoint, never a yield, GC and signals get through).
V39. margin is a single constant calibrated to cover primitive's granularity plus typical overshoot [D-021].
V40. No second threshold; resolution floor absorbed into calibration.
V41. A margin below primitive's granularity defeats the spin phase's purpose.
V42. Default margin is 2 ms [D-133] (bold), the value the measurements imply.
V43. It covers libuv ms granularity and sleep's ~1.4 ms median overshoot.
V44. Anything larger merely spends more core in spin.
V45. The knob spans the whole design space [D-021].
V46. margin = 0 is pure sleep, cheapest CPU; bursty spacing but exact average rate via debt repayment; spin buys regularity, never rate correctness.
V47. margin = 2 ms hybrid default: sleeps ~90% of 20 ms budget, lands within µs at a few percent of one core.
V48. margin = ∞ pure busy-wait, FlightCore's behavior, max regularity at one pinned core; "best attempt at real time" is the knob's endpoint, not separate mechanism.
V49. When frame budget ≤ margin (e.g. h = 0.01, p = 5, 2 ms), hybrid degenerates to pure spin by construction.
V50. Rare wake-ups past the deadline are overruns, absorbed as debt.
V51. Coarse-phase primitive choice settled in §12.2.
V52. Coarse phase uses task-yielding sleep, margin absorbing overshoot [D-027].
V53. Wait sits at frame top, after control plane consulted [D-269] (bold).
V54. A control change during a wait is observed at next frame top, at most one frame budget h/p later [§12.1, D-269].
V55. The wait is an unmask point [§12.4, D-132] for the operator interrupt (#g-operator-interrupt, Ctrl-C).
V56. The interrupt raises out of the coarse phase's sleep.
V57. Overrun count, current/peak debt, forgiven-debt events, wait statistics are published as framework status (#g-framework-status; frozen diagnostics value each snapshot carries beside the table) for GUI and logs.
V58. Record carries pace (Inf where no frame waits); debt, peak_debt in seconds; overruns; reanchors (every re-anchor after the first); forgiven (seconds cleared by those re-anchors); waits and waited [D-269].
V59. Deliberate re-anchor (pace change, un-pause) is counted, raises no warning.
V60. Forgiveness re-anchor is counted and reports DebtReanchor [Appendix C].
V61. Live switch to p = ∞ is a pace change like any other; re-anchors; cleared debt counted as forgiven [D-269].
V62. Wait interval is natural staging slot for externally injected inputs, drained at next frame top.
V63. Staging rules belong to §11 and §12, as does the concurrency model generally.
V64. §10.3 constrains the concurrency model but does not decide it.
