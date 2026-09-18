# Step 1b: cold-review findings and their adjudication

The independent review of `5502e1a` (the spec conformance commit), read
against D-250 through D-258. Verdict: no invented rule, no lost norm, fit to
push after the fixes below. Line numbers are at `5502e1a`; the spec is
unchanged since. The fixer lands every item as one commit, "Fix step 1b's
review findings". Item 1 follows the 2026-09-18 ruling recorded in D-256's
last bullet (`a85f5e5`).

1. **Appendix B 10674–10694 and Appendix C 11188–11194.** The `Deployment`
   constructor's signature drops `join_timeout`, `trace`, `log`,
   `log_every`, `log_max`. They become keywords of `Simulation(deployment,
   T)` and of the two convenience forms; the recording flags are carried to
   `init!`, which builds the run. Appendix B's `Simulation` entries and
   keyword table say so; the note at 10715 about `join_timeout` goes with
   it. `DeploymentInvalid`'s parameter list drops `t_end` (and its §13.5
   citation) and the five keywords; add a sentence that the
   materialization's keywords validate under `ArgumentInvalid`, and add
   `Simulation` to `ArgumentInvalid`'s call list (11280–11284).
2. **§12.7 7336–7338, 7346, 7380–7385.** The schema list is the trace's
   `schemas` list, not header content: "against the trace's `schemas`
   list" at 7346; the table retitled "The dispositions, by trace content";
   the schema row qualified "(on the trace's `schemas` list)".
3. **§15.4 9887.** Drop `t_end = 1000` from the `Simulation(world; …)`
   call; if the walkthrough needs the bound, put it on its `run!` line.
4. **§12.6 7034.** "the stop policy, with its `t_end` and stop faces, the
   log and the trace are the run's".
5. **Appendix C 11186–11189, `StopFaceInvalid`.** Binding site "(`run!`,
   `replay!` or `step!`)".
6. **§12.1 6489–6491.** "Beside pause, pace and `margin`, `Control` keeps
   the stop word, the lifecycle state, the wait and the shutdown tail's
   `join_timeout`."
7. **§9.1 3154.** "the grid parameters, the algorithm, the three event
   parameters, …".
8. **Appendix C 10972.** The service stage: "`attach!`/`Deployment`/
   `Simulation`/`run!`".
9. **Glossary links at first use per section.** Link and gloss
   `Structure`, `Dataflow`, `Events`, `Deployment`, `Schedule`, `Run` and
   `StopPolicy` at their first prose use in §9.2 (3237, 3256, 3257, 3288),
   §9.7 (3731), §11.5 (5790), §12.6 (7026), §12.7 (7361), §13.4 (7755),
   §13.7 (8134), §14.1 (8496) and Appendix B. One link per type per
   section, 5–10 word gloss, per `spec_style.md` "Terms".
10. **§11.8 6329–6332.** Add the clause: the device's task does not exist
    until `run!`, so the cell has no other writer yet.
11. **§12.4 6901–6903.** "A run with no finite `t_end` and no `stop_on`
    faces is the configuration `UnboundedRun` names."
12. **Appendix C 11339–11344 and 10994.** `UnboundedRun`'s payload is the
    effective `t_end` and the `stop_on` set; `pace` goes. The `logged`
    policy drops its §14.5 citation.
13. **`tools/gloss_table.md`, the D.8 `stop_on` row.** Gloss "the
    per-advance keyword naming the faces the loop reads".
14. **§9.1 3088 and the glossary at 11928.** "and, for each assembly that
    declares one, its scope triple under that `sample_times` key".
15. **`pending.md` 36 and 46.** Left as is; the second `UnboundedRun`
    mention retires at increment 47.
16. **Rows baseline.** Left as regenerated; recorded here that the
    regeneration also swept in 59 rows the spec already cited.
